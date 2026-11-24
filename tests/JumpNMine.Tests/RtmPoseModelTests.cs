using System;
using System.Collections.Generic;

using JumpNMine.Vision;
using Xunit;

namespace JumpNMine.Tests
{
    public class RtmPoseModelTests
    {
        /// <summary>Rotate the frame about its point by the angle (radians, counterclockwise as seen).</summary>
        private static Frame Rotate(Frame frame, float cx, float cy, float angle)
        {
            var rgb = new byte[frame.Rgb.Length];
            float cos = MathF.Cos(angle);
            float sin = MathF.Sin(angle);
            for (int y = 0; y < frame.Height; y++)
            {
                for (int x = 0; x < frame.Width; x++)
                {
                    // NOTE (mristin):
                    // The picture is y-down: a feature at q lands at
                    // c + R(-angle) (q - c), so we sample at c + R(angle) (p - c).
                    float dx = x - cx;
                    float dy = y - cy;
                    int sx = (int)MathF.Round(cx + cos * dx - sin * dy);
                    int sy = (int)MathF.Round(cy + sin * dx + cos * dy);
                    if (sx < 0 || sy < 0 || sx >= frame.Width || sy >= frame.Height)
                    {
                        continue;
                    }
                    Array.Copy(frame.Rgb, (sy * frame.Width + sx) * 3, rgb, (y * frame.Width + x) * 3, 3);
                }
            }
            return new Frame(rgb, frame.Width, frame.Height, frame.Timestamp);
        }

        private static (Pose Pose, Detection Head) Estimate(Frame frame)
        {
            using var detector = new YoloxModel(TestData.LoadModel(TestData.Yolox));
            using var model = new RtmPoseModel(TestData.LoadModel(TestData.RtmPose));

            var result = detector.Detect(frame);
            var head = Assert.Single(result.Heads);
            var box = Pose.PlayerBox(head, result.Bodies, frame.Width, frame.Height);
            return (model.Estimate(frame, box), head);
        }

        [Fact]
        public void Test_the_pose_of_the_astronaut()
        {
            var (pose, head) = Estimate(TestData.LoadFrame("astronaut_640x480.png"));

            foreach (int k in new[] { Pose.Nose, Pose.LeftEye, Pose.RightEye })
            {
                Assert.True(pose.Score[k] >= Pose.MinScore, $"Expected the keypoint {k} sure, got {pose.Score[k]:F2}.");
                Assert.True(head.Contains(pose.X[k], pose.Y[k]), $"Expected the keypoint {k} in the head.");
            }

            // NOTE (mristin):
            // The picture is mirrored: her left eye is on the left.
            Assert.True(pose.X[Pose.LeftEye] < pose.X[Pose.Nose]);
            Assert.True(pose.X[Pose.Nose] < pose.X[Pose.RightEye]);

            Assert.True(pose.Y[Pose.LeftShoulder] > head.Y2);
            Assert.True(pose.Y[Pose.RightShoulder] > head.Y2);

            float roll = pose.Roll(TestData.Width, TestData.Height);
            Assert.True(MathF.Abs(roll) < 0.15f, $"Expected her head upright, got the tilt {roll:F2}.");
        }

        [Theory]
        [InlineData(0.4f)]
        [InlineData(-0.4f)]
        public void Test_that_the_tilt_follows_the_head(float angle)
        {
            // NOTE (mristin):
            // The frame turns counterclockwise as seen, so the mirrored picture
            // turns clockwise: the tilt is the angle.
            var frame = Rotate(TestData.LoadFrame("astronaut_640x480.png"), 370f, 110f, angle);

            var (pose, _) = Estimate(frame);

            float roll = pose.Roll(TestData.Width, TestData.Height);
            Assert.True(
                MathF.Abs(roll - angle) < 0.15f,
                $"Expected the tilt {angle:F2}, got {roll:F2}."
            );
        }

        [Fact]
        public void Test_that_a_batch_estimates_the_same_poses_as_one_by_one()
        {
            var frame = TestData.LoadFrame("crew_of_six_640x480.png");
            using var detector = new YoloxModel(TestData.LoadModel(TestData.Yolox));
            using var model = new RtmPoseModel(TestData.LoadModel(TestData.RtmPose));

            var result = detector.Detect(frame);
            Assert.True(result.Heads.Count >= 2, $"Expected the crew, got {result.Heads.Count} heads.");
            var boxes = new List<BoundingBox>();
            foreach (var head in result.Heads)
            {
                boxes.Add(Pose.PlayerBox(head, result.Bodies, frame.Width, frame.Height));
            }

            var batch = model.EstimateMany(frame, boxes);
            Assert.Equal(boxes.Count, batch.Length);
            for (int i = 0; i < boxes.Count; i++)
            {
                var single = model.Estimate(frame, boxes[i]);
                for (int k = 0; k < Pose.Count; k++)
                {
                    Assert.True(MathF.Abs(single.X[k] - batch[i].X[k]) < 1e-3f, $"Player {i}, keypoint {k}: x differs.");
                    Assert.True(MathF.Abs(single.Y[k] - batch[i].Y[k]) < 1e-3f, $"Player {i}, keypoint {k}: y differs.");
                    Assert.True(MathF.Abs(single.Score[k] - batch[i].Score[k]) < 1e-3f, $"Player {i}, keypoint {k}: the score differs.");
                }
            }
        }
    }
}
