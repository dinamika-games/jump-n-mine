using JumpNMine.Vision;
using Xunit;

namespace JumpNMine.Tests
{
    public class SwingGaugeTests
    {
        private const float _width = 640f;
        private const float _height = 480f;
        private const float _head = 60f;
        private const double _dt = 1.0 / 15.0;

        /// <summary>
        /// A player whose body is shifted by the given head sizes from the
        /// middle of the picture, her shoulders 0.6 head sizes to either side;
        /// her wrists are the given head sizes across the body (from its middle,
        /// positive to the right) and above the shoulders (negative below).
        /// </summary>
        private static Pose Fists(
            float leftAcross, float rightAcross, float leftRise = 0f, float rightRise = 0f, float shift = 0f
        )
        {
            var pose = new Pose();
            for (int k = 0; k < Pose.Count; k++)
            {
                pose.Score[k] = 0.9f;
                pose.X[k] = 0.5f;
                pose.Y[k] = 0.5f;
            }

            float middle = 0.5f + shift * _head / _width;
            float shoulderY = (120f + 1.5f * _head) / _height;
            void Arm(int shoulder, int wrist, int side, float across, float rise)
            {
                pose.X[shoulder] = middle + side * 0.6f * _head / _width;
                pose.Y[shoulder] = shoulderY;
                pose.X[wrist] = middle + across * _head / _width;
                pose.Y[wrist] = shoulderY - rise * _head / _height;
            }

            Arm(Pose.LeftShoulder, Pose.LeftWrist, -1, leftAcross, leftRise);
            Arm(Pose.RightShoulder, Pose.RightWrist, 1, rightAcross, rightRise);
            return pose;
        }

        private static int[] Feed(SwingGauge gauge, params Pose[] poses)
        {
            var sides = new int[poses.Length];
            for (int i = 0; i < poses.Length; i++)
            {
                sides[i] = gauge.Observe(i * _dt, poses[i], _head, _width, _height);
            }
            return sides;
        }

        [Fact]
        public void Test_that_a_fist_moving_to_the_right_swings_once()
        {
            var sides = Feed(
                new SwingGauge(),
                Fists(-0.4f, 0.2f),
                Fists(-0.4f, 0.6f),
                Fists(-0.4f, 1.2f),
                Fists(-0.4f, 1.5f),
                Fists(-0.4f, 1.5f)
            );

            Assert.Equal(new[] { 0, 0, 0, 1, 0 }, sides);
        }

        [Fact]
        public void Test_that_a_fist_moving_across_the_body_swings_to_where_it_goes()
        {
            var sides = Feed(new SwingGauge(), Fists(-0.4f, 1.0f), Fists(-0.4f, 0f), Fists(-0.4f, -1.5f));

            Assert.Equal(new[] { 0, 0, -1 }, sides);
        }

        [Fact]
        public void Test_that_pulling_a_fist_back_does_not_swing()
        {
            var sides = Feed(
                new SwingGauge(),
                Fists(-0.2f, 0.4f),
                Fists(-0.8f, 0.4f),
                Fists(-1.4f, 0.4f),
                Fists(-1.4f, 0.4f),
                Fists(-0.8f, 0.4f),
                Fists(-0.2f, 0.4f),
                Fists(-0.2f, 0.4f)
            );

            Assert.Equal(new[] { 0, 0, -1, 0, 0, 0, 0 }, sides);
        }

        [Fact]
        public void Test_that_punches_in_a_row_count_each()
        {
            var gauge = new SwingGauge();
            var pose = new System.Collections.Generic.List<Pose>();
            for (int k = 0; k < 3; k++)
            {
                pose.Add(Fists(-0.2f, 0.4f));
                pose.Add(Fists(-0.8f, 0.4f));
                pose.Add(Fists(-1.4f, 0.4f));
                pose.Add(Fists(-0.8f, 0.4f));
                pose.Add(Fists(-0.2f, 0.4f));
            }
            int swings = 0;
            foreach (int side in Feed(gauge, pose.ToArray()))
            {
                Assert.True(side <= 0);
                swings -= side;
            }

            Assert.Equal(3, swings);
        }

        [Fact]
        public void Test_that_a_punch_from_the_chest_swings()
        {
            // NOTE (mristin):
            // As in a recording: the fist rests about a head size out from the
            // middle of the body and punches out to about two.
            var sides = Feed(
                new SwingGauge(),
                Fists(-0.4f, 1.1f),
                Fists(-0.4f, 1.5f),
                Fists(-0.4f, 2.0f),
                Fists(-0.4f, 1.6f),
                Fists(-0.4f, 1.1f),
                Fists(-0.4f, 1.1f),
                Fists(-0.4f, 1.9f)
            );

            Assert.Equal(new[] { 0, 0, 1, 0, 0, 0, 1 }, sides);
        }

        [Fact]
        public void Test_that_a_fist_at_the_chest_does_not_swing()
        {
            var sides = Feed(
                new SwingGauge(),
                Fists(-0.4f, 0f),
                Fists(-0.4f, 0.6f),
                Fists(-0.4f, 1.2f),
                Fists(-0.4f, 0.6f),
                Fists(-0.4f, 0f)
            );

            Assert.All(sides, side => Assert.Equal(0, side));
        }

        [Fact]
        public void Test_that_a_punch_out_of_the_picture_swings()
        {
            // NOTE (mristin):
            // As in a recording: the player stands near the left edge of the
            // picture, and the pose puts her wrist at the edge when her fist
            // leaves the picture, 1.4 head sizes out from the middle of her
            // body.
            float shift = -(0.5f - 0.15f) * _width / _head;
            float edge = -0.15f * _width / _head + 0.1f;
            var sides = Feed(
                new SwingGauge(),
                Fists(-1.0f, 0.4f, 0f, 0f, shift),
                Fists(-1.2f, 0.4f, 0f, 0f, shift),
                Fists(edge, 0.4f, 0f, 0f, shift),
                Fists(edge, 0.4f, 0f, 0f, shift),
                Fists(-1.0f, 0.4f, 0f, 0f, shift)
            );

            Assert.Equal(new[] { 0, 0, -1, 0, 0 }, sides);
        }

        [Fact]
        public void Test_that_a_slow_drift_does_not_swing()
        {
            var poses = new Pose[40];
            for (int i = 0; i < poses.Length; i++)
            {
                poses[i] = Fists(-0.4f, 0.05f * i);
            }

            Assert.All(Feed(new SwingGauge(), poses), side => Assert.Equal(0, side));
        }

        [Fact]
        public void Test_that_walking_does_not_swing()
        {
            var poses = new Pose[10];
            for (int i = 0; i < poses.Length; i++)
            {
                poses[i] = Fists(-0.4f, 0.4f, -1f, -1f, 0.5f * i);
            }

            Assert.All(Feed(new SwingGauge(), poses), side => Assert.Equal(0, side));
        }

        [Fact]
        public void Test_that_arms_up_in_a_jump_do_not_swing()
        {
            var sides = Feed(
                new SwingGauge(),
                Fists(-0.4f, 0.4f, -1f, -1f),
                Fists(-1.6f, 1.6f, 2.5f, 2.5f),
                Fists(-0.4f, 2.0f, -1f, 2.5f)
            );

            Assert.Equal(new[] { 0, 0, 0 }, sides);
        }

        [Fact]
        public void Test_that_both_fists_apart_choose_no_side()
        {
            var sides = Feed(new SwingGauge(), Fists(-0.4f, 0.4f), Fists(-1.6f, 1.6f));

            Assert.Equal(new[] { 0, 0 }, sides);
        }
    }
}
