using System;

// NOTE (mristin):
// This file must not depend on Godot so that we can unit-test it outside of
// the engine. See tests/JumpNMine.Tests.

namespace JumpNMine.Vision
{
    /// <summary>Filter a signal with an exponential moving average.</summary>
    public sealed class LowPassFilter
    {
        private float? _value;

        public float Filter(float value, float alpha)
        {
            _value = _value.HasValue
                ? _value.Value + alpha * (value - _value.Value)
                : value;

            return _value.Value;
        }
    }

    /// <summary>
    /// Smooth a noisy signal while keeping the lag low on fast movements.
    /// </summary>
    /// <remarks>
    /// <para>
    /// See: Casiez et al., "1€ Filter: A Simple Speed-based Low-pass Filter for
    /// Noisy Input in Interactive Systems", CHI 2012.
    /// </para>
    /// <para>
    /// We smooth everything which we follow over the frames with it (the heads,
    /// their sizes, their tilts and the heights for the jumps), each with its
    /// own parameters.
    /// </para>
    /// </remarks>
    public sealed class OneEuroFilter
    {
        private readonly float _minCutoff;
        private readonly float _beta;
        private readonly float _derivativeCutoff;

        private readonly LowPassFilter _value = new LowPassFilter();
        private readonly LowPassFilter _derivative = new LowPassFilter();
        private float? _previousRaw;
        private float _previousFiltered;

        /// <param name="minCutoff">
        /// The cutoff frequency (Hz) while the signal stands still; lower means
        /// smoother, but laggier.
        /// </param>
        /// <param name="beta">
        /// How much the cutoff rises with the speed of the signal (per unit of the
        /// signal per second); higher means less lag on fast movements.
        /// </param>
        /// <param name="derivativeCutoff">The cutoff frequency (Hz) of the speed.</param>
        public OneEuroFilter(float minCutoff, float beta, float derivativeCutoff = 1f)
        {
            _minCutoff = minCutoff;
            _beta = beta;
            _derivativeCutoff = derivativeCutoff;
        }

        /// <summary>The last filtered value, NaN before the first one.</summary>
        public float Value => _previousRaw.HasValue ? _previousFiltered : float.NaN;

        /// <summary>The smoothed speed of the signal (per second), 0 before.</summary>
        public float Derivative { get; private set; }

        /// <summary>Filter the value which came <paramref name="dt"/> seconds after the last one.</summary>
        public float Filter(float value, float dt)
        {
            if (!_previousRaw.HasValue)
            {
                _previousRaw = value;
                _previousFiltered = _value.Filter(value, 1f);
                return _previousFiltered;
            }

            if (dt <= 0f)
            {
                return _previousFiltered;
            }

            float rawDerivative = (value - _previousRaw.Value) / dt;
            Derivative = _derivative.Filter(
                rawDerivative,
                Alpha(dt, _derivativeCutoff)
            );

            float cutoff = _minCutoff + _beta * Math.Abs(Derivative);

            _previousRaw = value;
            _previousFiltered = _value.Filter(value, Alpha(dt, cutoff));
            return _previousFiltered;
        }

        private static float Alpha(float dt, float cutoff)
        {
            float tau = 1f / (2f * MathF.PI * cutoff);
            return 1f / (1f + tau / dt);
        }
    }
}
