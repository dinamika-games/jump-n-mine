using System;

// NOTE (mristin):
// This file must not depend on Godot so that we can unit-test the head tracking
// outside of the engine. See tests/JumpNMine.Tests.

namespace JumpNMine.Vision
{
    /// <summary>
    /// Compare the appearance embeddings of the heads, see
    /// <see cref="Track.Embedding"/>.
    /// </summary>
    /// <remarks>
    /// The embeddings come from the faces, see <see cref="FaceEmbedder"/>.
    /// </remarks>
    public static class Embeddings
    {
        /// <summary>Scale the vector to the unit length in place.</summary>
        public static void Normalize(float[] vector)
        {
            double sum = 0.0;
            foreach (var v in vector)
            {
                sum += v * v;
            }

            float norm = (float)Math.Sqrt(sum);
            if (norm < 1e-12f)
            {
                return;
            }

            for (int i = 0; i < vector.Length; i++)
            {
                vector[i] /= norm;
            }
        }

        /// <summary>Compute the cosine similarity of two L2-normalized embeddings.</summary>
        public static float CosineSimilarity(float[] a, float[] b)
        {
            if (a.Length != b.Length)
            {
                throw new ArgumentException(
                    $"Expected embeddings of the same size, but got {a.Length} " +
                    $"and {b.Length}."
                );
            }

            float dot = 0f;
            for (int i = 0; i < a.Length; i++)
            {
                dot += a[i] * b[i];
            }
            return dot;
        }
    }
}
