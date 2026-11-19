using System;
using System.Collections.Generic;
using System.Linq;

using JumpNMine.Vision;
using Xunit;
using Xunit.Abstractions;

namespace JumpNMine.Tests
{
    public class FaceEmbedderTests
    {
        private readonly ITestOutputHelper _output;

        public FaceEmbedderTests(ITestOutputHelper output)
        {
            _output = output;
        }

        private static FaceEmbedder LoadEmbedder()
        {
            return new FaceEmbedder(
                TestData.LoadModel(TestData.YuNet), TestData.LoadModel(TestData.SFace)
            );
        }

        /// <summary>The heads which YOLOX finds in the photo, mirrored and normalized.</summary>
        private static List<Detection> Heads(Frame frame)
        {
            using var yolox = new YoloxModel(TestData.LoadModel(TestData.Yolox));
            return yolox.Detect(frame).Heads.Where(h => h.Score >= 0.5f).ToList();
        }

        private static Detection Shifted(Detection head, float dx, float dy, float grow)
        {
            float w = head.Width * grow;
            float h = head.Height * grow;
            float cx = head.CenterX + dx * head.Width;
            float cy = head.CenterY + dy * head.Height;
            return new Detection(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2, head.Score);
        }

        [Fact]
        public void Test_that_the_similarity_transform_is_recovered()
        {
            var from = new float[,] { { 0, 0 }, { 10, 0 }, { 0, 10 }, { 7, 3 }, { 2, 9 } };
            float a = 1.5f * MathF.Cos(0.3f);
            float b = 1.5f * MathF.Sin(0.3f);
            var to = new float[5, 2];
            for (int i = 0; i < 5; i++)
            {
                to[i, 0] = a * from[i, 0] - b * from[i, 1] + 4f;
                to[i, 1] = b * from[i, 0] + a * from[i, 1] - 2f;
            }

            var (ra, rb, rtx, rty) = FaceEmbedder.Similarity(from, to);
            Assert.InRange(ra, a - 1e-3f, a + 1e-3f);
            Assert.InRange(rb, b - 1e-3f, b + 1e-3f);
            Assert.InRange(rtx, 4f - 1e-3f, 4f + 1e-3f);
            Assert.InRange(rty, -2f - 1e-3f, -2f + 1e-3f);
        }

        [Fact]
        public void Test_that_the_same_face_is_recognized_in_other_head_boxes()
        {
            using var embedder = LoadEmbedder();
            var frame = TestData.LoadFrame("astronaut_640x480.png");
            var head = Assert.Single(Heads(frame));

            var reference = embedder.Embed(frame, head);
            Assert.NotNull(reference);
            float norm = MathF.Sqrt(reference!.Sum(v => v * v));
            Assert.InRange(norm, 0.99f, 1.01f);

            foreach (var other in new[]
            {
                Shifted(head, 0.08f, -0.05f, 1.0f),
                Shifted(head, -0.06f, 0.04f, 1.15f),
                Shifted(head, 0.0f, 0.0f, 0.92f),
            })
            {
                var embedding = embedder.Embed(frame, other);
                Assert.NotNull(embedding);
                float similarity = Embeddings.CosineSimilarity(reference, embedding!);
                _output.WriteLine($"same face: {similarity:F3}");
                Assert.True(similarity > 0.8f, $"Expected the same face, got the similarity {similarity}.");
            }
        }

        [Fact]
        public void Test_that_different_people_are_told_apart()
        {
            using var embedder = LoadEmbedder();
            var astronaut = TestData.LoadFrame("astronaut_640x480.png");
            var reference = embedder.Embed(astronaut, Assert.Single(Heads(astronaut)));
            Assert.NotNull(reference);

            var crew = TestData.LoadFrame("crew_of_six_640x480.png");
            var faces = Heads(crew)
                .Select(h => embedder.Embed(crew, h))
                .Where(e => e != null)
                .Select(e => e!)
                .ToList();
            Assert.True(faces.Count >= 3, $"Expected at least 3 faces in the crew, got {faces.Count}.");

            foreach (var face in faces)
            {
                float similarity = Embeddings.CosineSimilarity(reference!, face);
                _output.WriteLine($"astronaut vs a crew member: {similarity:F3}");
                Assert.True(similarity < 0.4f, $"Expected different people, got the similarity {similarity}.");
            }

            for (int i = 0; i < faces.Count; i++)
            {
                for (int j = i + 1; j < faces.Count; j++)
                {
                    float similarity = Embeddings.CosineSimilarity(faces[i], faces[j]);
                    _output.WriteLine($"crew {i} vs crew {j}: {similarity:F3}");
                    Assert.True(similarity < 0.4f, $"Expected different people, got the similarity {similarity}.");
                }
            }
        }
    }
}
