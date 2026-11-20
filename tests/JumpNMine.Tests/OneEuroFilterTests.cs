using System;
using System.Numerics;

using JumpNMine.Vision;
using Xunit;

namespace JumpNMine.Tests
{
    public class OneEuroFilterTests
    {
        private const float _dt = 1f / 30f;

        [Fact]
        public void Test_that_the_filter_smooths_jitter_while_the_signal_stands()
        {
            var filter = new OneEuroFilter(minCutoff: 1.5f, beta: 0.01f);
            var random = new Random(0);

            // NOTE (mristin):
            // The jitter is uniform in ±5, so its standard deviation is 2.9.
            double sum = 0.0;
            int count = 0;
            for (int i = 0; i < 300; i++)
            {
                float raw = 100f + (float)(random.NextDouble() * 10.0 - 5.0);
                float filtered = filter.Filter(raw, i == 0 ? 0f : _dt);
                if (i > 30)
                {
                    sum += (filtered - 100.0) * (filtered - 100.0);
                    count++;
                }
            }
            double deviation = Math.Sqrt(sum / count);

            Assert.True(deviation < 1.2, $"Expected the jitter smoothed, got the deviation {deviation:F2}.");
        }

        [Fact]
        public void Test_that_the_fast_filter_keeps_the_top_of_a_jump()
        {
            // NOTE (mristin):
            // A head of 100 px rises by one head size and comes down in 0.4 s.
            var filter = new OneEuroFilter(Track.JumpMinCutoff, Track.JumpBeta);
            float top = 0f;
            for (int i = 0; i < 60; i++)
            {
                float t = i * _dt - 0.5f;
                float rise = t >= 0f && t <= 0.4f ? 100f * MathF.Sin(MathF.PI * t / 0.4f) : 0f;
                float filtered = filter.Filter(300f - rise, i == 0 ? 0f : _dt);
                top = Math.Max(top, 300f - filtered);
            }

            Assert.True(top > 80f, $"Expected the jump to keep most of its top of 100 px, got {top:F1}.");
        }

        [Fact]
        public void Test_that_the_derivative_follows_the_speed()
        {
            var filter = new OneEuroFilter(minCutoff: 1.5f, beta: 0.01f);
            for (int i = 0; i < 120; i++)
            {
                filter.Filter(60f * i * _dt, i == 0 ? 0f : _dt);
            }

            Assert.InRange(filter.Derivative, 55f, 65f);
        }

        [Fact]
        public void Test_that_the_tilt_follows_the_face_and_eases_back_without_it()
        {
            var track = new Track(1, new Vector2(320f, 240f), 100f, 0.0, 1.5f, 0.01f);

            double t = 0.0;
            for (int i = 0; i < 60; i++)
            {
                t += _dt;
                track.ObserveRoll(0.3f, t);
            }
            Assert.InRange(track.Roll, 0.28f, 0.31f);

            // NOTE (mristin):
            // The face is lost for a moment: the helmet keeps its tilt.
            t += _dt;
            track.ObserveRoll(float.NaN, t);
            Assert.InRange(track.Roll, 0.28f, 0.31f);

            for (int i = 0; i < 60; i++)
            {
                t += _dt;
                track.ObserveRoll(float.NaN, t);
            }
            Assert.True(Math.Abs(track.Roll) < 0.05f, $"Expected the helmet upright again, got {track.Roll:F3}.");
        }
    }
}
