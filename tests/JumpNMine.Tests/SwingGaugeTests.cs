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
        /// A player in the middle of the picture, her shoulders a head below her
        /// head; her arms reach out by the given head sizes and rise by the given
        /// head sizes above the shoulders (negative below).
        /// </summary>
        private static Pose Player(float leftReach, float rightReach, float leftRise = 0f, float rightRise = 0f)
        {
            var pose = new Pose();
            for (int k = 0; k < Pose.Count; k++)
            {
                pose.Score[k] = 0.9f;
                pose.X[k] = 0.5f;
                pose.Y[k] = 0.5f;
            }

            float shoulderY = (120f + 1.5f * _head) / _height;
            void Arm(int shoulder, int elbow, int wrist, int side, float reach, float rise)
            {
                float shoulderX = 0.5f + side * 0.6f * _head / _width;
                pose.X[shoulder] = shoulderX;
                pose.Y[shoulder] = shoulderY;
                pose.X[wrist] = shoulderX + side * reach * _head / _width;
                pose.Y[wrist] = shoulderY - rise * _head / _height;
                pose.X[elbow] = (pose.X[shoulder] + pose.X[wrist]) * 0.5f;
                pose.Y[elbow] = (pose.Y[shoulder] + pose.Y[wrist]) * 0.5f;
            }

            Arm(Pose.LeftShoulder, Pose.LeftElbow, Pose.LeftWrist, -1, leftReach, leftRise);
            Arm(Pose.RightShoulder, Pose.RightElbow, Pose.RightWrist, 1, rightReach, rightRise);
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
        public void Test_that_waving_an_arm_out_counts_each_wave()
        {
            var gauge = new SwingGauge();
            var down = Player(0.2f, 0.2f, -1.5f, -1.5f);
            var leftOut = Player(2.5f, 0.2f, 0f, -1.5f);

            var sides = Feed(
                gauge,
                down, leftOut, leftOut, down, down, down, down, leftOut, down,
                Player(0.2f, 2.5f, -1.5f, 0f)
            );

            Assert.Equal(new[] { 0, -1, 0, 0, 0, 0, 0, -1, 0, 1 }, sides);
        }

        [Fact]
        public void Test_that_arms_up_in_a_jump_do_not_swing()
        {
            var gauge = new SwingGauge();
            var sides = Feed(
                gauge,
                Player(0.2f, 0.2f, -1.5f, -1.5f),
                Player(1.6f, 1.6f, 2.5f, 2.5f),
                Player(1.6f, 0.2f, 2.5f, -1.5f)
            );

            Assert.Equal(new[] { 0, 0, 0 }, sides);
        }

        [Fact]
        public void Test_that_both_arms_out_choose_no_side()
        {
            var gauge = new SwingGauge();
            var sides = Feed(gauge, Player(0.2f, 0.2f, -1.5f, -1.5f), Player(2.5f, 2.5f));

            Assert.Equal(new[] { 0, 0 }, sides);
        }

        [Fact]
        public void Test_that_a_jittery_wrist_at_the_threshold_swings_once()
        {
            var gauge = new SwingGauge();
            var sides = Feed(
                gauge,
                Player(1.0f, 0.2f, 0f, -1.5f),
                Player(1.6f, 0.2f, 0f, -1.5f),
                Player(1.4f, 0.2f, 0f, -1.5f),
                Player(1.6f, 0.2f, 0f, -1.5f),
                Player(1.4f, 0.2f, 0f, -1.5f),
                Player(1.6f, 0.2f, 0f, -1.5f)
            );

            Assert.Equal(new[] { 0, -1, 0, 0, 0, 0 }, sides);
        }
    }
}
