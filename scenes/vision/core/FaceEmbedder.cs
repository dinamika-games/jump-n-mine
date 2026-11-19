using System;
using System.Linq;

using Microsoft.ML.OnnxRuntime;

// NOTE (mristin):
// The files in core/ must not depend on Godot so that we can unit-test the
// vision outside of the engine. See tests/JumpNMine.Tests.

namespace JumpNMine.Vision
{
    /// <summary>
    /// Recognize the faces of the players, so that a player who leaves the
    /// picture and comes back gets her dwarf back.
    /// </summary>
    /// <remarks>
    /// <para>
    /// In the box of a head which YOLOX found, YuNet finds the five landmarks of
    /// the face (the eyes, the nose and the corners of the mouth). We align the
    /// face with them to the template of ArcFace (112 x 112 pixels) by a
    /// similarity transform, and SFace (MobileFaceNet trained with the SFace
    /// loss) gives its embedding, 128 numbers which we normalize to the unit
    /// length. The faces of the same person lie close: compare them by the
    /// cosine of their embeddings (see <see cref="Embeddings.CosineSimilarity"/>).
    /// </para>
    /// <para>
    /// A face which looks away (no landmarks) gets no embedding; the tracker
    /// then follows the head by its motion alone.
    /// </para>
    /// <para>The instance is not thread-safe; use it from a single thread only.</para>
    /// </remarks>
    public sealed class FaceEmbedder : IDisposable
    {
        /// <summary>The side of the aligned face, in pixels.</summary>
        public const int Size = 112;

        /// <summary>
        /// Where the five landmarks lie in the aligned face of ArcFace (as in
        /// OpenCV's FaceRecognizerSF): the eye on the left of the picture, the one
        /// on the right, the nose, and the corners of the mouth on the left and the
        /// right of the picture.
        /// </summary>
        private static readonly float[,] _template =
        {
            { 38.2946f, 51.6963f },
            { 73.5318f, 51.5014f },
            { 56.0252f, 71.7366f },
            { 41.5493f, 92.3655f },
            { 70.7299f, 92.2041f },
        };

        private readonly YuNetFaceLandmarker _landmarker;
        private readonly InferenceSession _session;
        private readonly RunOptions _runOptions = new();
        private readonly string[] _inputNames;
        private readonly string[] _outputNames;
        private readonly float[] _input = new float[3 * Size * Size];
        private readonly OrtValue _inputValue;

        public FaceEmbedder(byte[] yunetModel, byte[] sfaceModel, int threads = 1)
        {
            OnnxRuntimePrivacy.DisableTelemetry();
            _landmarker = new YuNetFaceLandmarker(yunetModel, 160, threads);
            try
            {
                using var options = new SessionOptions
                {
                    GraphOptimizationLevel = GraphOptimizationLevel.ORT_ENABLE_ALL,
                    LogSeverityLevel = OrtLoggingLevel.ORT_LOGGING_LEVEL_ERROR,
                    ExecutionMode = ExecutionMode.ORT_SEQUENTIAL,
                    IntraOpNumThreads = threads,
                    InterOpNumThreads = 1,
                };
                options.AddSessionConfigEntry("session.intra_op.allow_spinning", "0");
                _session = new InferenceSession(sfaceModel, options);
                _inputNames = new[] { _session.InputMetadata.Keys.First() };
                _outputNames = new[] { _session.OutputMetadata.Keys.First() };
                _inputValue = OrtValue.CreateTensorValueFromMemory(
                    _input, new long[] { 1, 3, Size, Size }
                );
            }
            catch
            {
                _landmarker.Dispose();
                throw;
            }
        }

        /// <summary>
        /// Compute the embedding of the face in the head, given as a detection in
        /// the normalized, <em>mirrored</em> coordinates of YOLOX; null if no face
        /// was found in it.
        /// </summary>
        public float[]? Embed(Frame frame, Detection head)
        {
            // NOTE (mristin):
            // The detections are mirrored, the frame is not.
            var box = new BoundingBox(
                (1f - head.X2) * frame.Width,
                head.Y1 * frame.Height,
                (1f - head.X1) * frame.Width,
                head.Y2 * frame.Height
            );
            return Embed(frame, box);
        }

        /// <summary>
        /// Compute the embedding of the face in the head box (in pixels of the
        /// frame, not mirrored); null if no face was found in it.
        /// </summary>
        public float[]? Embed(Frame frame, BoundingBox head)
        {
            var face = _landmarker.DetectOne(frame, head);
            if (face == null)
            {
                return null;
            }

            var source = new float[,]
            {
                { face.RightEyeX, face.RightEyeY },
                { face.LeftEyeX, face.LeftEyeY },
                { face.NoseX, face.NoseY },
                { face.MouthRightX, face.MouthRightY },
                { face.MouthLeftX, face.MouthLeftY },
            };

            // NOTE (mristin):
            // The transform maps the aligned face to the frame, so that we can
            // sample the frame for each pixel of the aligned face.
            var (a, b, tx, ty) = Similarity(_template, source);
            Warp(frame, a, b, tx, ty, _input);

            using var outputs = _session.Run(
                _runOptions, _inputNames, new[] { _inputValue }, _outputNames
            );
            float[] embedding = outputs[0].GetTensorDataAsSpan<float>().ToArray();
            Embeddings.Normalize(embedding);
            return embedding;
        }

        /// <summary>
        /// Find the similarity transform (a rotation with scaling, and a
        /// translation) which maps the points <paramref name="from"/> best onto
        /// <paramref name="to"/> in the least squares (Umeyama, 1991): x' = a x - b
        /// y + tx, y' = b x + a y + ty.
        /// </summary>
        public static (float A, float B, float Tx, float Ty) Similarity(
            float[,] from, float[,] to
        )
        {
            int n = from.GetLength(0);
            double fx = 0, fy = 0, tx = 0, ty = 0;
            for (int i = 0; i < n; i++)
            {
                fx += from[i, 0];
                fy += from[i, 1];
                tx += to[i, 0];
                ty += to[i, 1];
            }
            fx /= n;
            fy /= n;
            tx /= n;
            ty /= n;

            double dot = 0, cross = 0, norm = 0;
            for (int i = 0; i < n; i++)
            {
                double ux = from[i, 0] - fx;
                double uy = from[i, 1] - fy;
                double vx = to[i, 0] - tx;
                double vy = to[i, 1] - ty;
                dot += ux * vx + uy * vy;
                cross += ux * vy - uy * vx;
                norm += ux * ux + uy * uy;
            }

            if (norm < 1e-9)
            {
                return (1f, 0f, (float)(tx - fx), (float)(ty - fy));
            }

            double a = dot / norm;
            double b = cross / norm;
            return (
                (float)a,
                (float)b,
                (float)(tx - (a * fx - b * fy)),
                (float)(ty - (b * fx + a * fy))
            );
        }

        /// <summary>
        /// Sample the frame through the transform (from the aligned face to the
        /// frame) into the planar RGB input of SFace, in [0, 255].
        /// </summary>
        private static void Warp(Frame frame, float a, float b, float tx, float ty, float[] target)
        {
            int plane = Size * Size;
            for (int y = 0; y < Size; y++)
            {
                for (int x = 0; x < Size; x++)
                {
                    float sx = a * x - b * y + tx;
                    float sy = b * x + a * y + ty;
                    int i = y * Size + x;
                    if (sx < 0f || sy < 0f || sx > frame.Width - 1 || sy > frame.Height - 1)
                    {
                        target[i] = 0f;
                        target[plane + i] = 0f;
                        target[2 * plane + i] = 0f;
                        continue;
                    }

                    target[i] = frame.Sample(sx, sy, 0);
                    target[plane + i] = frame.Sample(sx, sy, 1);
                    target[2 * plane + i] = frame.Sample(sx, sy, 2);
                }
            }
        }

        public void Dispose()
        {
            _inputValue.Dispose();
            _runOptions.Dispose();
            _session.Dispose();
            _landmarker.Dispose();
        }
    }
}  // namespace JumpNMine.Vision
