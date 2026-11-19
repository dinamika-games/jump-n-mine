using System;

// NOTE (mristin):
// The files in core/ must not depend on Godot so that we can unit-test the
// vision outside of the engine. See tests/JumpNMine.Tests.

namespace JumpNMine.Vision
{
    /// <summary>
    /// Count the jumps of one player from the height of her head over time.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A jump counts when the head rises <see cref="JumpHeight"/> head sizes
    /// above the height where the player stands (<see cref="StandingTop"/>), and
    /// the next jump counts once the head came back down to
    /// <see cref="Rearm"/> head sizes above it. We measure in head sizes, so that
    /// it does not matter how close to the camera the player stands.
    /// </para>
    /// <para>
    /// The standing height follows the head slowly, so that the player may step
    /// closer or back, but a crouch or a jump hardly moves it. It does not
    /// follow the head during a jump at all.
    /// </para>
    /// <para>
    /// The heights are in pixels of the camera frame, growing downwards.
    /// </para>
    /// </remarks>
    public sealed class JumpGauge
    {
        /// <summary>
        /// A jump counts when the head rises this far above the standing height,
        /// in head sizes (the box of the head, with the hair, is about 22 cm
        /// high, so this is about 15 cm).
        /// </summary>
        public float JumpHeight = 0.7f;

        /// <summary>The next jump counts once the head came back down to this far above standing, in head sizes.</summary>
        public float Rearm = 0.35f;

        /// <summary>Two jumps are at least this many seconds apart.</summary>
        public double MinInterval = 0.3;

        /// <summary>
        /// The time constant (s) with which the standing height follows a head
        /// which goes down: slowly, so that standing up after a crouch of a
        /// couple of seconds is no jump, but the player may step back.
        /// </summary>
        public double FollowDownTau = 4.0;

        /// <summary>The time constant (s) with which the standing height follows a head which goes up.</summary>
        public double FollowUpTau = 4.0;

        /// <summary>The time constant (s) of smoothing the head size.</summary>
        public double SizeTau = 1.0;

        /// <summary>After a gap longer than this (s), e.g., the player left the picture, we start afresh.</summary>
        public double ResetAfter = 1.0;

        /// <summary>The height of the head when the player stands, NaN before the head was seen.</summary>
        public float StandingTop { get; private set; } = float.NaN;

        /// <summary>The smoothed size of the head, NaN before the head was seen.</summary>
        public float HeadSize { get; private set; } = float.NaN;

        /// <summary>The height of the head as last observed, NaN before.</summary>
        public float HeadY { get; private set; } = float.NaN;

        /// <summary>The line which the head must rise above for a jump; NaN before the head was seen.</summary>
        public float JumpLine =>
            float.IsNaN(StandingTop) || float.IsNaN(HeadSize)
                ? float.NaN
                : StandingTop - JumpHeight * HeadSize;

        /// <summary>How high the head is above standing, in head sizes (negative below); 0 before.</summary>
        public float Rise =>
            float.IsNaN(StandingTop) || float.IsNaN(HeadSize) || HeadSize <= 0f
                ? 0f
                : (StandingTop - HeadY) / HeadSize;

        /// <summary>Whether the player is in a jump now.</summary>
        public bool IsJumping { get; private set; }

        /// <summary>How many jumps were counted.</summary>
        public int Jumps { get; private set; }

        private double _lastObserved = double.NaN;
        private double _lastJump = double.NegativeInfinity;

        /// <summary>
        /// Observe the height of the head and its size (both in frame pixels) at
        /// the time <paramref name="t"/> (in seconds); return whether a new jump
        /// started.
        /// </summary>
        public bool Observe(double t, float headY, float headSize)
        {
            if (float.IsNaN(headY) || float.IsNaN(headSize) || headSize <= 0f)
            {
                return false;
            }

            if (float.IsNaN(StandingTop) || double.IsNaN(_lastObserved)
                || t - _lastObserved > ResetAfter)
            {
                StandingTop = headY;
                HeadSize = headSize;
                HeadY = headY;
                IsJumping = false;
                _lastObserved = t;
                return false;
            }

            double dt = Math.Max(0.0, t - _lastObserved);
            _lastObserved = t;
            HeadY = headY;

            if (!IsJumping)
            {
                // NOTE (mristin):
                // The size of the head grows when the player comes closer, but
                // it also changes a little in a jump (the head tilts), so we
                // follow it only while she stands.
                HeadSize += (headSize - HeadSize) * Follow(dt, SizeTau);

                double tau = headY > StandingTop ? FollowDownTau : FollowUpTau;
                StandingTop += (headY - StandingTop) * Follow(dt, tau);
            }

            bool started = false;
            if (!IsJumping && headY <= JumpLine && t - _lastJump >= MinInterval)
            {
                IsJumping = true;
                Jumps++;
                _lastJump = t;
                started = true;
            }
            else if (IsJumping && headY >= StandingTop - Rearm * HeadSize)
            {
                IsJumping = false;
            }

            return started;
        }

        /// <summary>Forget the player, e.g., when she left the picture.</summary>
        public void Reset()
        {
            StandingTop = float.NaN;
            HeadSize = float.NaN;
            HeadY = float.NaN;
            IsJumping = false;
            _lastObserved = double.NaN;
        }

        private static float Follow(double dt, double tau)
        {
            return tau <= 0.0 ? 1f : (float)(1.0 - Math.Exp(-dt / tau));
        }
    }
}
