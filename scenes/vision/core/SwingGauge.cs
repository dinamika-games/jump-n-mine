using System;

// NOTE (mristin):
// This file must not depend on Godot so that we can unit-test the swings
// outside of the engine. See tests/JumpNMine.Tests.

namespace JumpNMine.Vision
{
    /// <summary>
    /// Count the swings of a player's arms to the side: each time a wrist goes
    /// out sideways, beyond its shoulder, the dwarf swings its pickaxe at the
    /// block beside it.
    /// </summary>
    /// <remarks>
    /// <para>
    /// We measure in head sizes, so that it does not matter how close to the
    /// camera the player stands, on the poses smoothed with 1€ filters. The arm
    /// must be out to the side, about at the height of the shoulder: arms
    /// raised over the head (as children do in a jump) or hanging down do not
    /// count. The next swing of the arm counts once the wrist came back in.
    /// </para>
    /// <para>The thresholds are first guesses, to tune with recordings of children.</para>
    /// </remarks>
    public sealed class SwingGauge
    {
        /// <summary>The wrist must be this far beyond its shoulder, sideways (in head sizes).</summary>
        public float OutReach = 1.5f;

        /// <summary>The wrist must come back within this (in head sizes) before the arm swings again.</summary>
        public float InReach = 0.8f;

        /// <summary>The wrist may be this far above or below its shoulder (in head sizes).</summary>
        public float MaxRise = 1.2f;

        /// <summary>Two swings of the same arm are at least this far apart (s).</summary>
        public double MinInterval = 0.35;

        private readonly bool[] _out = new bool[2];
        private readonly double[] _lastSwing = { double.NegativeInfinity, double.NegativeInfinity };

        /// <summary>
        /// Observe the pose (normalized to the mirrored picture) and the size of
        /// the head (in pixels) at the time <paramref name="t"/> (in seconds);
        /// return the side of the swing which started now: -1 to the left of the
        /// mirrored picture (the player's left arm), 1 to the right, 0 for none.
        /// </summary>
        public int Observe(double t, Pose pose, float headSize, float frameWidth, float frameHeight)
        {
            if (headSize <= 0f)
            {
                return 0;
            }

            int result = 0;
            foreach (int side in new[] { -1, 1 })
            {
                int shoulder = side < 0 ? Pose.LeftShoulder : Pose.RightShoulder;
                int elbow = side < 0 ? Pose.LeftElbow : Pose.RightElbow;
                int wrist = side < 0 ? Pose.LeftWrist : Pose.RightWrist;
                int slot = side < 0 ? 0 : 1;

                if (pose.Score[shoulder] < Pose.MinScore || pose.Score[wrist] < Pose.MinScore)
                {
                    // NOTE (mristin):
                    // We do not know where the arm is, so it stays as it was.
                    continue;
                }

                // NOTE (mristin):
                // The reach is positive outwards, away from the body.
                float reach = side * (pose.X[wrist] - pose.X[shoulder]) * frameWidth / headSize;
                float rise = Math.Abs(pose.Y[wrist] - pose.Y[shoulder]) * frameHeight / headSize;
                bool elbowOut = pose.Score[elbow] < Pose.MinScore
                    || side * (pose.X[elbow] - pose.X[shoulder]) > 0f;

                if (_out[slot])
                {
                    if (reach < InReach)
                    {
                        _out[slot] = false;
                    }
                    continue;
                }

                if (reach >= OutReach && rise <= MaxRise && elbowOut
                    && t - _lastSwing[slot] >= MinInterval)
                {
                    _out[slot] = true;
                    _lastSwing[slot] = t;

                    // NOTE (mristin):
                    // If both arms go out at once, the player does not choose a
                    // side; we take none.
                    result = result == 0 ? side : 0;
                }
            }

            return result;
        }

        /// <summary>Forget the arms, e.g., when the player left the picture.</summary>
        public void Reset()
        {
            Array.Clear(_out);
            _lastSwing[0] = double.NegativeInfinity;
            _lastSwing[1] = double.NegativeInfinity;
        }
    }
}  // namespace JumpNMine.Vision
