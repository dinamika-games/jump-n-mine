using System;
using System.Linq;

using Microsoft.ML.OnnxRuntime;

// NOTE (mristin):
// This file must not depend on Godot so that we can unit-test the pose
// estimation outside of the engine. See tests/JumpNMine.Tests.

namespace JumpNMine.Vision
{
    /// <summary>
    /// Estimate the pose of a player with RTMPose-t (top-down, on a crop around
    /// the player) through ONNX Runtime.
    /// </summary>
    /// <remarks>
    /// <para>
    /// See: https://github.com/open-mmlab/mmpose/tree/main/projects/rtmpose; we use
    /// the ONNX export of rtmpose-t_simcc-body7_pt-body7_420e-256x192 unmodified.
    /// </para>
    /// <para>
    /// A player costs about 10 to 16 ms on a laptop CPU, so the caller spreads
    /// the players over the frames.
    /// </para>
    /// <para>The instance is not thread-safe; use it from a single thread only.</para>
    /// </remarks>
    public sealed class RtmPoseModel : IDisposable
    {
        public const int InputWidth = 192;
        public const int InputHeight = 256;

        /// <summary>The crop is this much larger than the box of the player (as in MMPose).</summary>
        public const float Padding = 1.25f;

        /// <summary>The model locates the keypoints in this many bins per input pixel (SimCC).</summary>
        private const float _splitRatio = 2f;

        private static readonly float[] _mean = { 123.675f, 116.28f, 103.53f };
        private static readonly float[] _std = { 58.395f, 57.12f, 57.375f };

        private readonly InferenceSession _session;
        private readonly RunOptions _runOptions = new();
        private readonly string[] _inputNames;
        private readonly string[] _outputNames = { "simcc_x", "simcc_y" };
        private readonly float[] _input = new float[3 * InputWidth * InputHeight];
        private readonly OrtValue _inputValue;

        public RtmPoseModel(byte[] model, int threads = 2)
        {
            OnnxRuntimePrivacy.DisableTelemetry();
            using var options = new SessionOptions
            {
                GraphOptimizationLevel = GraphOptimizationLevel.ORT_ENABLE_ALL,
                LogSeverityLevel = OrtLoggingLevel.ORT_LOGGING_LEVEL_ERROR,
                ExecutionMode = ExecutionMode.ORT_SEQUENTIAL,
                IntraOpNumThreads = threads,
                InterOpNumThreads = 1,
            };
            options.AddSessionConfigEntry("session.intra_op.allow_spinning", "0");
            _session = new InferenceSession(model, options);

            try
            {
                if (_session.InputMetadata.Count != 1)
                {
                    throw new InvalidOperationException(
                        $"Expected RTMPose to have one input, but got {_session.InputMetadata.Count}."
                    );
                }
                foreach (string name in _outputNames)
                {
                    if (!_session.OutputMetadata.ContainsKey(name))
                    {
                        throw new InvalidOperationException(
                            $"Expected RTMPose to have the output {name}, but got: " +
                            string.Join(", ", _session.OutputMetadata.Keys)
                        );
                    }
                }

                _inputNames = new[] { _session.InputMetadata.Keys.First() };
                _inputValue = OrtValue.CreateTensorValueFromMemory(
                    _input, new long[] { 1, 3, InputHeight, InputWidth }
                );
            }
            catch
            {
                _session.Dispose();
                throw;
            }
        }

        /// <summary>
        /// Estimate the pose of the player in the box (normalized to the mirrored
        /// picture, like the detections).
        /// </summary>
        public Pose Estimate(Frame frame, BoundingBox mirroredPlayer)
        {
            var crop = Crop(frame, mirroredPlayer);
            Preprocess(frame, crop, _input);

            using var outputs = _session.Run(_runOptions, _inputNames, new[] { _inputValue }, _outputNames);
            return Decode(
                outputs[0].GetTensorDataAsSpan<float>(),
                outputs[1].GetTensorDataAsSpan<float>(),
                crop,
                frame.Width,
                frame.Height
            );
        }

        /// <summary>
        /// The crop of the model around the player (in pixels of the frame, not
        /// mirrored): padded and widened to the aspect of the input, as in MMPose.
        /// </summary>
        public static BoundingBox Crop(Frame frame, BoundingBox mirroredPlayer)
        {
            float x1 = (1f - mirroredPlayer.X2) * frame.Width;
            float x2 = (1f - mirroredPlayer.X1) * frame.Width;
            float y1 = mirroredPlayer.Y1 * frame.Height;
            float y2 = mirroredPlayer.Y2 * frame.Height;

            float width = (x2 - x1) * Padding;
            float height = (y2 - y1) * Padding;
            const float aspect = (float)InputWidth / InputHeight;
            if (width > height * aspect)
            {
                height = width / aspect;
            }
            else
            {
                width = height * aspect;
            }

            return BoundingBox.FromCenter((x1 + x2) * 0.5f, (y1 + y2) * 0.5f, width, height);
        }

        /// <summary>
        /// Resize the crop (in frame pixels; it may reach beyond the frame, which
        /// we fill with black) into the planar, normalized RGB input of the model.
        /// </summary>
        public static void Preprocess(Frame frame, BoundingBox crop, float[] target)
        {
            const int plane = InputWidth * InputHeight;
            if (target.Length < 3 * plane)
            {
                throw new ArgumentException(
                    $"Expected the target of length {3 * plane}, but got {target.Length}.",
                    nameof(target)
                );
            }

            byte[] rgb = frame.Rgb;
            int width = frame.Width;
            int height = frame.Height;
            float scaleX = crop.Width / InputWidth;
            float scaleY = crop.Height / InputHeight;

            for (int y = 0; y < InputHeight; y++)
            {
                float sy = crop.Y1 + (y + 0.5f) * scaleY - 0.5f;
                bool insideY = sy >= -0.5f && sy <= height - 0.5f;
                sy = Math.Clamp(sy, 0f, height - 1);
                int y0 = (int)sy;
                int y1 = Math.Min(y0 + 1, height - 1);
                float fy = sy - y0;
                int row0 = y0 * width * 3;
                int row1 = y1 * width * 3;

                for (int x = 0; x < InputWidth; x++)
                {
                    int index = y * InputWidth + x;
                    float sx = crop.X1 + (x + 0.5f) * scaleX - 0.5f;
                    if (!insideY || sx < -0.5f || sx > width - 0.5f)
                    {
                        for (int c = 0; c < 3; c++)
                        {
                            target[c * plane + index] = -_mean[c] / _std[c];
                        }
                        continue;
                    }

                    sx = Math.Clamp(sx, 0f, width - 1);
                    int x0 = (int)sx;
                    int x1 = Math.Min(x0 + 1, width - 1);
                    float fx = sx - x0;
                    for (int c = 0; c < 3; c++)
                    {
                        float p00 = rgb[row0 + x0 * 3 + c];
                        float p01 = rgb[row0 + x1 * 3 + c];
                        float p10 = rgb[row1 + x0 * 3 + c];
                        float p11 = rgb[row1 + x1 * 3 + c];
                        float p0 = p00 + (p01 - p00) * fx;
                        float p1 = p10 + (p11 - p10) * fx;
                        target[c * plane + index] = (p0 + (p1 - p0) * fy - _mean[c]) / _std[c];
                    }
                }
            }
        }

        /// <summary>
        /// Decode the SimCC outputs of a crop into the keypoints of the mirrored
        /// picture: the most likely bin on each axis, and the weaker of the two
        /// as the score (as in MMPose).
        /// </summary>
        public static Pose Decode(
            ReadOnlySpan<float> simccX,
            ReadOnlySpan<float> simccY,
            BoundingBox crop,
            int frameWidth,
            int frameHeight
        )
        {
            int binsX = (int)(InputWidth * _splitRatio);
            int binsY = (int)(InputHeight * _splitRatio);
            if (simccX.Length != Pose.Count * binsX || simccY.Length != Pose.Count * binsY)
            {
                throw new ArgumentException(
                    $"Expected the SimCC outputs of {Pose.Count} x {binsX} and {Pose.Count} x {binsY}, " +
                    $"but got {simccX.Length} and {simccY.Length}."
                );
            }

            var pose = new Pose();
            for (int k = 0; k < Pose.Count; k++)
            {
                var (bx, sx) = ArgMax(simccX.Slice(k * binsX, binsX));
                var (by, sy) = ArgMax(simccY.Slice(k * binsY, binsY));

                float x = crop.X1 + bx / _splitRatio * crop.Width / InputWidth;
                float y = crop.Y1 + by / _splitRatio * crop.Height / InputHeight;

                // NOTE (mristin):
                // We mirror the keypoints so that they match the mirrored overlay.
                pose.X[k] = 1f - x / frameWidth;
                pose.Y[k] = y / frameHeight;
                pose.Score[k] = Math.Min(sx, sy);
            }

            return pose;
        }

        private static (int Index, float Value) ArgMax(ReadOnlySpan<float> values)
        {
            int best = 0;
            for (int i = 1; i < values.Length; i++)
            {
                if (values[i] > values[best])
                {
                    best = i;
                }
            }
            return (best, values[best]);
        }

        public void Dispose()
        {
            _inputValue.Dispose();
            _runOptions.Dispose();
            _session.Dispose();
        }
    }
}  // namespace JumpNMine.Vision
