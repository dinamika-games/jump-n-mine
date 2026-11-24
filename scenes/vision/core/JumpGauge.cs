using System;
using System.Collections.Generic;

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
    /// We measure each jump from the lowest point of the head shortly before it
    /// (<see cref="StandingTop"/>, over <see cref="TroughWindow"/>): the height
    /// where the player stands, or the knees bent to jump or after landing, to
    /// the peak. A jump starts when the head rises <see cref="LowJumpHeight"/>
    /// head sizes above that point, and counts when the head came back down
    /// (the pickaxe hits when the player lands). Its strength is 1 if
    /// the head rose <see cref="JumpHeight"/> head sizes, and
    /// <see cref="WeakStrength"/> for a lower jump, so that the children who can
    /// not jump high still dig, only slower. We measure in head sizes, so that
    /// it does not matter how close to the camera the player stands.
    /// </para>
    /// <para>
    /// The gauge needs no standing height which follows the head over time: in
    /// recordings, such a height drifted halfway up between the knees bent on
    /// landing and the peaks while the player jumped in a row, so that her
    /// jumps had to be ever higher, and it lagged for seconds behind a player
    /// who walked into place, so that her first jumps did not count.
    /// </para>
    /// <para>
    /// A head which goes up and stays up (the player stands up from a crouch,
    /// stands on her toes or steps closer) is no jump. The heights are in pixels
    /// of the camera frame, growing downwards.
    /// </para>
    /// </remarks>
    public sealed class JumpGauge
    {
        /// <summary>
        /// A jump counts fully when the head rises this far above its lowest
        /// point before, in head sizes. The head box of YOLOX reaches well above
        /// the hair (it is about 30 cm high for a head of 22 cm), so this is about
        /// 9 cm. In recordings of an adult, the jumps rose 0.2 to 1 head sizes
        /// from the lowest point, most of them 0.35 to 0.6.
        /// </summary>
        public float JumpHeight = 0.3f;

        /// <summary>
        /// A lower jump counts as a weaker one from this rise on, in head sizes
        /// (about 5 cm), well above a nod or the sway of a standing head.
        /// </summary>
        public float LowJumpHeight = 0.18f;

        /// <summary>The strength of a jump below <see cref="JumpHeight"/>.</summary>
        public float WeakStrength = 0.5f;

        /// <summary>The lowest point of the head before a jump is taken over this many seconds.</summary>
        public double TroughWindow = 0.8;

        /// <summary>A jump counts once the head came back down by this fraction of its rise, ...</summary>
        public float Fall = 0.5f;

        /// <summary>
        /// ... or by this many head sizes from its peak: a player who jumps off
        /// bent knees lands higher than she took off.
        /// </summary>
        public float Descent = 0.12f;

        /// <summary>
        /// A head which stays up longer than this (in seconds) did not jump, the
        /// player stands higher (e.g., on her toes, or up from a crouch).
        /// </summary>
        public double LongestJump = 1.0;

        /// <summary>Two jumps are at least this many seconds apart.</summary>
        public double MinInterval = 0.3;

        /// <summary>The time constant (s) of smoothing the head size.</summary>
        public double SizeTau = 1.0;

        /// <summary>
        /// The player steps closer or back while her head is this much larger or
        /// smaller (as a fraction) than its smoothed size; a jump changes it
        /// only by about 5 %. A head which rises while the player steps is no
        /// jump.
        /// </summary>
        public float StepSize = 0.12f;

        /// <summary>The time constant (s) with which the head size follows a player who steps closer or back.</summary>
        public double FollowStepTau = 0.3;

        /// <summary>After a gap longer than this (s), e.g., the player left the picture, we start afresh.</summary>
        public double ResetAfter = 1.0;

        /// <summary>
        /// The lowest point of the head shortly before (see
        /// <see cref="TroughWindow"/>), or the one of the current jump, from
        /// which the jump is measured; NaN before the head was seen.
        /// </summary>
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

        /// <summary>How high the head is above <see cref="StandingTop"/>, in head sizes; 0 before.</summary>
        public float Rise =>
            float.IsNaN(StandingTop) || float.IsNaN(HeadSize) || HeadSize <= 0f
                ? 0f
                : (StandingTop - HeadY) / HeadSize;

        /// <summary>The highest rise of the current (or the last) jump, in head sizes.</summary>
        public float PeakRise { get; private set; }

        /// <summary>Whether the player is in a jump now.</summary>
        public bool IsJumping { get; private set; }

        /// <summary>How many jumps were counted.</summary>
        public int Jumps { get; private set; }

        private readonly Queue<(double T, float Y)> _history = new Queue<(double, float)>();
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

            if (float.IsNaN(HeadSize) || double.IsNaN(_lastObserved) || t - _lastObserved > ResetAfter)
            {
                HeadSize = headSize;
                Restart(t, headY);
                _lastObserved = t;
                return 0f;
            }

            double dt = Math.Max(0.0, t - _lastObserved);
            _lastObserved = t;
            HeadY = headY;

            if (IsJumping)
            {
                PeakRise = Math.Max(PeakRise, Rise);
                if (t - _lastJump > LongestJump)
                {
                    // NOTE (mristin):
                    // The head stays up: no jump, the player stands higher now.
                    Restart(t, headY);
                    return 0f;
                }

                if (Rise <= PeakRise * Fall || PeakRise - Rise >= Descent)
                {
                    Restart(t, headY);
                    Jumps++;
                    return PeakRise >= JumpHeight ? 1f : WeakStrength;
                }
                return 0f;
            }

            // NOTE (mristin):
            // The size of the head grows when the player comes closer, but it
            // also changes a little in a jump (the head tilts), so we follow it
            // only while she stands, and quickly while she steps.
            bool stepping = Math.Abs(headSize - HeadSize) > StepSize * HeadSize;
            HeadSize += (headSize - HeadSize) * Follow(dt, stepping ? FollowStepTau : SizeTau);
            if (stepping)
            {
                Restart(t, headY);
                return 0f;
            }

            while (_history.Count > 0 && t - _history.Peek().T > TroughWindow)
            {
                _history.Dequeue();
            }
            _history.Enqueue((t, headY));
            float lowest = headY;
            foreach (var (_, y) in _history)
            {
                lowest = Math.Max(lowest, y);
            }
            StandingTop = lowest;

            if (Rise >= LowJumpHeight && t - _lastJump >= MinInterval)
            {
                IsJumping = true;
                PeakRise = Rise;
                _lastJump = t;
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
            _history.Clear();
            _lastObserved = double.NaN;
        }

        /// <summary>Measure the next jumps from the head as it is now.</summary>
        private void Restart(double t, float headY)
        {
            IsJumping = false;
            HeadY = headY;
            StandingTop = headY;
            _history.Clear();
            _history.Enqueue((t, headY));
        }

        private static float Follow(double dt, double tau)
        {
            return tau <= 0.0 ? 1f : (float)(1.0 - Math.Exp(-dt / tau));
        }
    }
}  // namespace JumpNMine.Vision
