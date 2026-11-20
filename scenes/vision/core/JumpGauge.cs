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
    /// A jump starts when the head rises <see cref="LowJumpHeight"/> head sizes
    /// above the height where the player stands (<see cref="StandingTop"/>), and
    /// counts when the head came back down to <see cref="Rearm"/> head sizes
    /// above it (the pickaxe hits when the player lands). Its strength is 1 if
    /// the head rose <see cref="JumpHeight"/> head sizes, and
    /// <see cref="WeakStrength"/> for a lower jump, so that the children who can
    /// not jump high still dig, only slower. We measure in head sizes, so that
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
        /// in head sizes. The head box of YOLOX reaches well above the hair (it
        /// is about 30 cm high for a head of 22 cm), so this is about 11 cm.
        /// </summary>
        public float JumpHeight = 0.35f;

        /// <summary>
        /// A lower jump counts as a weaker one from this rise on, in head sizes
        /// (about 6 cm).
        /// </summary>
        public float LowJumpHeight = 0.2f;

        /// <summary>The strength of a jump below <see cref="JumpHeight"/>.</summary>
        public float WeakStrength = 0.5f;

        /// <summary>
        /// A head which stays up longer than this (in seconds) did not jump, the
        /// player stands higher (e.g., on her toes or a step).
        /// </summary>
        public double LongestJump = 1.0;

        /// <summary>The next jump counts once the head came back down to this far above standing, in head sizes.</summary>
        public float Rearm = 0.1f;

        /// <summary>Two jumps are at least this many seconds apart.</summary>
        public double MinInterval = 0.3;

        /// <summary>
        /// The time constant (s) with which the standing height follows a head
        /// which goes down: slowly, so that standing up after a crouch of a
        /// couple of seconds is no jump, but the player may step back.
        /// </summary>
        public double FollowDownTau = 4.0;

        /// <summary>
        /// The time constant (s) with which the standing height follows a head
        /// far below it (a crouch, more than <see cref="CrouchDepth"/> head sizes):
        /// very slowly, so that standing up again is no jump.
        /// </summary>
        public double FollowCrouchTau = 30.0;

        /// <summary>A head this far below the standing height (in head sizes) crouches.</summary>
        public float CrouchDepth = 0.5f;

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

        /// <summary>The line which the head must rise above for a full jump; NaN before the head was seen.</summary>
        public float JumpLine =>
            float.IsNaN(StandingTop) || float.IsNaN(HeadSize)
                ? float.NaN
                : StandingTop - JumpHeight * HeadSize;

        /// <summary>How high the head is above standing, in head sizes (negative below); 0 before.</summary>
        public float Rise =>
            float.IsNaN(StandingTop) || float.IsNaN(HeadSize) || HeadSize <= 0f
                ? 0f
                : (StandingTop - HeadY) / HeadSize;

        /// <summary>The line which the head must rise above for a weak jump; NaN before the head was seen.</summary>
        public float LowJumpLine =>
            float.IsNaN(StandingTop) || float.IsNaN(HeadSize)
                ? float.NaN
                : StandingTop - LowJumpHeight * HeadSize;

        /// <summary>The highest rise of the current (or the last) jump, in head sizes.</summary>
        public float PeakRise { get; private set; }

        /// <summary>Whether the player is in a jump now.</summary>
        public bool IsJumping { get; private set; }

        /// <summary>How many jumps were counted.</summary>
        public int Jumps { get; private set; }

        private double _lastObserved = double.NaN;
        private double _lastJump = double.NegativeInfinity;

        /// <summary>
        /// Observe the height of the head and its size (both in frame pixels) at
        /// the time <paramref name="t"/> (in seconds); return the strength of the
        /// jump which ended now (the player landed), or 0 if none did.
        /// </summary>
        public float Observe(double t, float headY, float headSize)
        {
            if (float.IsNaN(headY) || float.IsNaN(headSize) || headSize <= 0f)
            {
                return 0f;
            }

            if (float.IsNaN(StandingTop) || double.IsNaN(_lastObserved)
                || t - _lastObserved > ResetAfter)
            {
                StandingTop = headY;
                HeadSize = headSize;
                HeadY = headY;
                IsJumping = false;
                _lastObserved = t;
                return 0f;
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

                double tau = FollowUpTau;
                if (headY > StandingTop)
                {
                    tau = headY - StandingTop > CrouchDepth * HeadSize ? FollowCrouchTau : FollowDownTau;
                }
                StandingTop += (headY - StandingTop) * Follow(dt, tau);
            }

            float rise = (StandingTop - headY) / HeadSize;
            if (!IsJumping)
            {
                if (headY <= LowJumpLine && t - _lastJump >= MinInterval)
                {
                    IsJumping = true;
                    PeakRise = rise;
                    _lastJump = t;
                }
                return 0f;
            }

            PeakRise = Math.Max(PeakRise, rise);
            if (t - _lastJump > LongestJump)
            {
                // NOTE (mristin):
                // The head stays up: no jump, the player stands higher now.
                IsJumping = false;
                StandingTop = headY;
                return 0f;
            }

            if (headY >= StandingTop - Rearm * HeadSize)
            {
                IsJumping = false;
                Jumps++;
                return PeakRise >= JumpHeight ? 1f : WeakStrength;
            }

            return 0f;
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
