using System;

using JumpNMine.Vision;
using Xunit;

namespace JumpNMine.Tests
{
    public class JumpGaugeTests
    {
        private const double _dt = 1.0 / 30.0;
        private const float _standing = 200f;
        private const float _size = 80f;

        /// <summary>Feed the gauge with the head height of the function over the duration; count the new jumps.</summary>
        private static int Feed(JumpGauge gauge, ref double t, double duration, Func<double, float> headY, float size = _size)
        {
            int jumps = 0;
            double end = t + duration;
            double start = t;
            for (; t < end; t += _dt)
            {
                if (gauge.Observe(t, headY(t - start), size) > 0f)
                {
                    jumps++;
                }
            }
            return jumps;
        }

        /// <summary>A jump of the given height (in head sizes) lasting about half a second.</summary>
        private static Func<double, float> Jump(float height, double duration = 0.5)
        {
            return s => s >= duration
                ? _standing
                : _standing - height * _size * (float)Math.Sin(Math.PI * s / duration);
        }

        [Fact]
        public void Test_that_standing_still_is_no_jump()
        {
            var gauge = new JumpGauge();
            double t = 0.0;
            Assert.Equal(0, Feed(gauge, ref t, 5.0, _ => _standing));
        }

        [Fact]
        public void Test_that_a_jump_counts_once()
        {
            var gauge = new JumpGauge();
            double t = 0.0;
            Feed(gauge, ref t, 2.0, _ => _standing);
            Assert.Equal(1, Feed(gauge, ref t, 1.0, Jump(1.2f)));
            Assert.Equal(1, gauge.Jumps);
        }

        [Fact]
        public void Test_that_jumps_in_a_row_count_each()
        {
            var gauge = new JumpGauge();
            double t = 0.0;
            Feed(gauge, ref t, 2.0, _ => _standing);
            int jumps = 0;
            for (int i = 0; i < 10; i++)
            {
                jumps += Feed(gauge, ref t, 0.8, Jump(1.0f));
            }
            Assert.Equal(10, jumps);
        }

        [Fact]
        public void Test_that_a_small_jump_counts()
        {
            var gauge = new JumpGauge();
            double t = 0.0;
            Feed(gauge, ref t, 2.0, _ => _standing);
            Assert.Equal(1, Feed(gauge, ref t, 1.0, Jump(0.5f, 0.4)));
        }

        [Fact]
        public void Test_that_a_jump_seen_at_a_low_frame_rate_counts()
        {
            // NOTE (mristin):
            // On a slow laptop, the vision sees about ten frames a second.
            var gauge = new JumpGauge();
            int jumps = 0;
            for (double t = 0.0; t < 6.0; t += 0.1)
            {
                double s = t - 2.0;
                float y = s > 0.0 && s < 0.45 ? _standing - 0.6f * _size * (float)Math.Sin(Math.PI * s / 0.45) : _standing;
                if (gauge.Observe(t, y, _size) > 0f)
                {
                    jumps++;
                }
            }
            Assert.Equal(1, jumps);
        }

        [Fact]
        public void Test_that_a_low_jump_is_a_weak_one()
        {
            var gauge = new JumpGauge();
            double t = 0.0;
            Feed(gauge, ref t, 2.0, _ => _standing);
            float strength = 0f;
            for (double end = t + 1.0; t < end; t += _dt)
            {
                double s = 1.0 - (end - t);
                float y = s < 0.4 ? _standing - 0.27f * _size * (float)Math.Sin(Math.PI * s / 0.4) : _standing;
                strength += gauge.Observe(t, y, _size);
            }
            Assert.Equal(gauge.WeakStrength, strength);
        }

        [Fact]
        public void Test_that_a_full_jump_hits_fully_when_the_player_lands()
        {
            var gauge = new JumpGauge();
            double t = 0.0;
            Feed(gauge, ref t, 2.0, _ => _standing);
            double landed = double.NaN;
            float strength = 0f;
            for (double end = t + 1.0; t < end; t += _dt)
            {
                double s = 1.0 - (end - t);
                float y = s < 0.5 ? _standing - 0.8f * _size * (float)Math.Sin(Math.PI * s / 0.5) : _standing;
                float now = gauge.Observe(t, y, _size);
                if (now > 0f)
                {
                    strength = now;
                    landed = s;
                }
            }
            Assert.Equal(1f, strength);
            Assert.InRange(landed, 0.35, 0.55);
        }

        [Fact]
        public void Test_that_standing_on_the_toes_is_no_jump()
        {
            var gauge = new JumpGauge();
            double t = 0.0;
            Feed(gauge, ref t, 2.0, _ => _standing);
            Assert.Equal(0, Feed(gauge, ref t, 3.0, _ => _standing - 0.3f * _size));
        }

        [Fact]
        public void Test_that_a_nod_is_no_jump()
        {
            var gauge = new JumpGauge();
            double t = 0.0;
            Feed(gauge, ref t, 2.0, _ => _standing);
            Assert.Equal(0, Feed(gauge, ref t, 1.0, Jump(0.1f)));
        }

        [Fact]
        public void Test_that_coming_up_from_a_crouch_is_no_jump()
        {
            var gauge = new JumpGauge();
            double t = 0.0;
            Feed(gauge, ref t, 2.0, _ => _standing);

            // NOTE (mristin):
            // The player crouches for two seconds (the standing height follows her
            // down) and stands up again.
            Feed(gauge, ref t, 2.0, _ => _standing + 1.5f * _size);
            Assert.Equal(0, Feed(gauge, ref t, 2.0, _ => _standing));
        }

        [Fact]
        public void Test_that_stepping_closer_is_followed()
        {
            var gauge = new JumpGauge();
            double t = 0.0;
            Feed(gauge, ref t, 2.0, _ => _standing);

            // NOTE (mristin):
            // The player steps closer over a second: her head grows and rises a
            // little in the picture.
            int jumps = 0;
            for (double end = t + 1.0; t < end; t += _dt)
            {
                float k = (float)(1.0 - (end - t));
                if (gauge.Observe(t, _standing - 30f * k, 80f + 40f * k) > 0f)
                {
                    jumps++;
                }
            }
            jumps += Feed(gauge, ref t, 6.0, _ => _standing - 30f, 120f);
            Assert.Equal(0, jumps);
            Assert.InRange(gauge.HeadSize, 115f, 121f);
            Assert.Equal(1, Feed(gauge, ref t, 1.0, s => s >= 0.5 ? _standing - 30f : _standing - 30f - 120f * (float)Math.Sin(Math.PI * s / 0.5), 120f));
        }

        [Fact]
        public void Test_that_after_a_gap_the_gauge_starts_afresh()
        {
            var gauge = new JumpGauge();
            double t = 0.0;
            Feed(gauge, ref t, 2.0, _ => _standing);
            t += 5.0;

            // NOTE (mristin):
            // Another player steps in, standing higher in the picture.
            Assert.Equal(0, Feed(gauge, ref t, 2.0, _ => _standing - 100f));
            Assert.InRange(gauge.StandingTop, _standing - 101f, _standing - 99f);
        }
    }
}
