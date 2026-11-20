using System;
using System.Collections.Generic;

// NOTE (mristin):
// This file must not depend on Godot so that we can unit-test the poses outside
// of the engine. See tests/JumpNMine.Tests.

namespace JumpNMine.Vision
{
    /// <summary>The 17 body keypoints of COCO of a player, in the mirrored picture.</summary>
    public sealed class Pose
    {
        public const int Count = 17;

        public const int Nose = 0;
        public const int LeftEye = 1;
        public const int RightEye = 2;
        public const int LeftEar = 3;
        public const int RightEar = 4;
        public const int LeftShoulder = 5;
        public const int RightShoulder = 6;
        public const int LeftElbow = 7;
        public const int RightElbow = 8;
        public const int LeftWrist = 9;
        public const int RightWrist = 10;
        public const int LeftHip = 11;
        public const int RightHip = 12;

        /// <summary>Trust a keypoint from this score on.</summary>
        public const float MinScore = 0.3f;

        /// <summary>
        /// The keypoints normalized to the <em>mirrored</em> picture, [0, 1], like
        /// the detections; "left" is the left of the player, which is on the left
        /// of the mirrored picture.
        /// </summary>
        public readonly float[] X = new float[Count];
        public readonly float[] Y = new float[Count];

        /// <summary>How sure the model is of each keypoint (about 0 to 1).</summary>
        public readonly float[] Score = new float[Count];

        /// <summary>
        /// The tilt of the head in the mirrored picture (radians, clockwise on the
        /// screen, 0 upright), from the eyes and the ears; NaN if neither pair is
        /// sure.
        /// </summary>
        public float Roll(float frameWidth, float frameHeight)
        {
            float dx = 0f;
            float dy = 0f;
            foreach (var (left, right) in new[] { (LeftEye, RightEye), (LeftEar, RightEar) })
            {
                if (Score[left] < MinScore || Score[right] < MinScore)
                {
                    continue;
                }

                // NOTE (mristin):
                // The left of the player is on the left of the mirrored picture,
                // so the line from her left to her right runs to the right when
                // she stands upright. We add the lines up as unit vectors, so
                // that the eyes and the ears weigh the same.
                float x = (X[right] - X[left]) * frameWidth;
                float y = (Y[right] - Y[left]) * frameHeight;
                float length = MathF.Sqrt(x * x + y * y);
                if (length > 0f && x > 0f)
                {
                    dx += x / length;
                    dy += y / length;
                }
            }

            return dx > 0f ? MathF.Atan2(dy, dx) : float.NaN;
        }

        /// <summary>
        /// The box of the player around her head (both normalized to the mirrored
        /// picture), for the pose estimation: as wide as five heads and down to
        /// her waist, and wider if her body (found by the detector) reaches out
        /// further, e.g., with an arm stretched out.
        /// </summary>
        /// <remarks>
        /// A wider crop makes the head smaller in it, and the tilt from the eyes
        /// less exact; five heads keep it within a few degrees.
        /// </remarks>
        public static BoundingBox PlayerBox(
            Detection head, IReadOnlyList<Detection> bodies, float frameWidth, float frameHeight
        )
        {
            float size = Math.Max(head.Width * frameWidth, head.Height * frameHeight);
            float halfWidth = 2.5f * size / frameWidth;
            float x1 = head.CenterX - halfWidth;
            float x2 = head.CenterX + halfWidth;
            float y1 = head.Y1 - 0.3f * size / frameHeight;
            float y2 = head.Y1 + 5f * size / frameHeight;

            // NOTE (mristin):
            // The body of the player holds her head in its upper half.
            Detection? best = null;
            foreach (var body in bodies)
            {
                if (body.Contains(head.CenterX, head.CenterY)
                    && head.CenterY <= body.Y1 + 0.5f * body.Height
                    && (best == null || body.Score > best.Value.Score))
                {
                    best = body;
                }
            }

            if (best != null)
            {
                x1 = Math.Min(x1, best.Value.X1);
                x2 = Math.Max(x2, best.Value.X2);
            }

            return new BoundingBox(x1, y1, x2, y2);
        }
    }
}  // namespace JumpNMine.Vision
