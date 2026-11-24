using System;
using System.Collections.Generic;

// NOTE (mristin):
// This file must not depend on Godot so that we can unit-test the swings
// outside of the engine. See tests/JumpNMine.Tests.

namespace JumpNMine.Vision
{
    /// <summary>
    /// Count the swings of a player's fists to the side: each time a fist moves
    /// quickly to the left or to the right, the dwarf swings its pickaxe at the
    /// block on that side.
    /// </summary>
    /// <remarks>
    /// <para>
    /// We follow each wrist across the body, from the middle between the
    /// shoulders, in head sizes, so that it neither matters how close to the
    /// camera the player stands nor whether she walks; the poses are smoothed
    /// with 1€ filters. A swing is a wrist which travels at least
    /// <see cref="Travel"/> sideways within <see cref="Window"/> and ends on that
    /// side of the body, at least <see cref="EndReach"/> from its middle: a fist
    /// pulled back to the body after a swing does not count as a swing the other
    /// way. A fist which reaches the edge of the picture is out as far as it
    /// goes. The fist must be about at the height of the chest: arms raised over
    /// the head (as children do in a jump) or hanging down do not count.
    /// </para>
    /// <para>The thresholds are first guesses, to tune with recordings (see scenes/level/recorder.gd).</para>
    /// </remarks>
    public sealed class SwingGauge
    {
        /// <summary>
        /// How far a wrist travels sideways for a swing (in head sizes). In a
        /// recording, a player held her fist about 1.1 head sizes out from the
        /// middle of her body and punched it out to about 2.
        /// </summary>
        public float Travel = 0.6f;

        /// <summary>The wrist travels <see cref="Travel"/> within this many seconds.</summary>
        public double Window = 0.4;

        /// <summary>
        /// The wrist ends at least this far on the side of the swing, from the
        /// middle of the body, well beyond the shoulder (in head sizes), so that
        /// a fist pulled back to the body or held at the chest does not swing.
        /// </summary>
        public float EndReach = 1.4f;

        /// <summary>
        /// A wrist this close to the left or the right edge of the picture
        /// (as a fraction of its width) is out to that side as far as it goes:
        /// the pose puts a wrist which left the picture at the edge.
        /// </summary>
        public float Edge = 0.04f;

        /// <summary>A wrist which ends at the edge of the picture travels at least this far for a swing (in head sizes).</summary>
        public float EdgeTravel = 0.4f;

        /// <summary>The wrist may be at most this far above its shoulder (in head sizes).</summary>
        public float MaxRise = 1.5f;

        /// <summary>The wrist may be at most this far below its shoulder (in head sizes).</summary>
        public float MaxDrop = 1.5f;

        /// <summary>Two swings of the same fist are at least this far apart (s).</summary>
        public double MinInterval = 0.25;

        /// <summary>
        /// The arms at the last observation, for the recordings: the left wrist
        /// across the body and above its shoulder, then the right one (in head
        /// sizes, positive to the right and upwards); NaN where unknown.
        /// </summary>
        public readonly float[] Arms = { float.NaN, float.NaN, float.NaN, float.NaN };

        private readonly Queue<(double T, float Across)>[] _history =
        {
            new Queue<(double, float)>(),
            new Queue<(double, float)>(),
        };

        private readonly double[] _lastSwing = { double.NegativeInfinity, double.NegativeInfinity };

        /// <summary>
        /// Observe the pose (normalized to the mirrored picture) and the size of
        /// the head (in pixels) at the time <paramref name="t"/> (in seconds);
        /// return the side of the swing which ended now: -1 to the left of the
        /// mirrored picture, 1 to the right, 0 for none.
        /// </summary>
        public int Observe(double t, Pose pose, float headSize, float frameWidth, float frameHeight)
        {
            Array.Fill(Arms, float.NaN);
            if (headSize <= 0f
                || pose.Score[Pose.LeftShoulder] < Pose.MinScore
                || pose.Score[Pose.RightShoulder] < Pose.MinScore)
            {
                // NOTE (mristin):
                // We do not know where the body is: the fists start anew.
                Forget();
                return 0;
            }

            float middle = (pose.X[Pose.LeftShoulder] + pose.X[Pose.RightShoulder]) * 0.5f;

            int result = 0;
            bool conflict = false;
            for (int slot = 0; slot < 2; slot++)
            {
                int shoulder = slot == 0 ? Pose.LeftShoulder : Pose.RightShoulder;
                int wrist = slot == 0 ? Pose.LeftWrist : Pose.RightWrist;
                var history = _history[slot];

                if (pose.Score[wrist] < Pose.MinScore)
                {
                    history.Clear();
                    continue;
                }

                float across = (pose.X[wrist] - middle) * frameWidth / headSize;
                float rise = (pose.Y[shoulder] - pose.Y[wrist]) * frameHeight / headSize;
                Arms[2 * slot] = across;
                Arms[2 * slot + 1] = rise;

                if (rise > MaxRise || rise < -MaxDrop)
                {
                    history.Clear();
                    continue;
                }

                while (history.Count > 0 && t - history.Peek().T > Window)
                {
                    history.Dequeue();
                }
                history.Enqueue((t, across));

                bool atLeft = pose.X[wrist] <= Edge;
                bool atRight = pose.X[wrist] >= 1f - Edge;
                int side = 0;
                foreach (var (_, before) in history)
                {
                    if ((across >= EndReach && across - before >= Travel) || (atRight && across - before >= EdgeTravel))
                    {
                        side = 1;
                        break;
                    }
                    if ((across <= -EndReach && before - across >= Travel) || (atLeft && before - across >= EdgeTravel))
                    {
                        side = -1;
                        break;
                    }
                }

                if (side == 0 || t - _lastSwing[slot] < MinInterval)
                {
                    continue;
                }

                _lastSwing[slot] = t;
                history.Clear();
                history.Enqueue((t, across));
                if (result != 0 && result != side)
                {
                    conflict = true;
                }
                result = side;
            }

            // NOTE (mristin):
            // If the fists swing apart at once, the player does not choose a
            // side; we take none.
            return conflict ? 0 : result;
        }

        /// <summary>Forget the arms, e.g., when the player left the picture.</summary>
        public void Reset()
        {
            Forget();
            _lastSwing[0] = double.NegativeInfinity;
            _lastSwing[1] = double.NegativeInfinity;
        }

        private void Forget()
        {
            _history[0].Clear();
            _history[1].Clear();
        }
    }
}  // namespace JumpNMine.Vision
