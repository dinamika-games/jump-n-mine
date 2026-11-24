using Godot;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;

using JumpNMine.Vision;

/// <summary>
/// Follow the heads of the players in the webcam feed, count their jumps, and
/// recognize their faces when they come back.
/// </summary>
/// <remarks>
/// <para>
/// We detect the heads with YOLOX on every camera frame, follow them with the
/// <see cref="MultiHeadTracker"/> and count the jumps of each head with its own
/// <see cref="JumpGauge"/>. All of this runs on a background thread, so that the
/// game stays smooth; the main thread only emits the signals.
/// </para>
/// <para>
/// The positions are normalized to [0, 1] of the <em>mirrored</em> camera
/// picture, so that a player who steps to her right moves to the right of the
/// screen, as in a mirror.
/// </para>
/// </remarks>
public partial class HeadVision : Node
{
    /// <summary>Signal that a new head entered the picture.</summary>
    [Signal]
    public delegate void HeadAppearedEventHandler(int id, Vector2 position, float size);

    /// <summary>
    /// Signal that a head moved: its position and size normalized to the picture,
    /// how high it is above standing (in head sizes), the line which it must rise
    /// above for a jump (normalized to the picture; NaN before it is known),
    /// whether the player is in a jump now, and the tilt of the head (radians,
    /// clockwise in the mirrored picture, from the eyes; 0 while unknown).
    /// </summary>
    /// <remarks>Everything is smoothed with 1€ filters (see <see cref="Track"/>).</remarks>
    [Signal]
    public delegate void HeadMovedEventHandler(
        int id, Vector2 position, float size, float rise, float jumpLine, bool jumping, float roll
    );

    /// <summary>Signal that a head left the picture.</summary>
    [Signal]
    public delegate void HeadLostEventHandler(int id);

    /// <summary>
    /// Signal that the player of the head jumped and landed: the strength is 1
    /// for a full jump and less for a low one (see <see cref="JumpGauge"/>).
    /// </summary>
    [Signal]
    public delegate void HeadJumpedEventHandler(int id, float strength);

    /// <summary>
    /// Signal that the player of the head swung a fist to the side: -1 to
    /// the left of the mirrored picture, 1 to the right (see <see cref="SwingGauge"/>).
    /// </summary>
    [Signal]
    public delegate void HeadSwungEventHandler(int id, int side);

    /// <summary>
    /// Signal where the wrists of the player of the head are, for the
    /// recordings: the left wrist across the body and above its shoulder, then
    /// the right one (in head sizes; NaN where unknown, see
    /// <see cref="SwingGauge.Arms"/>).
    /// </summary>
    [Signal]
    public delegate void HeadArmsEventHandler(int id, Vector4 arms);

    [Export]
    public int MaxHeads = 8;

    /// <summary>Lower means smoother, but laggier, when the head is slow.</summary>
    [Export]
    public float MinCutoff = 1.5f;

    /// <summary>Higher means less lag, but more jitter, when the head is fast.</summary>
    [Export]
    public float Beta = 0.01f;

    /// <summary>
    /// Remove a head after it has not been seen for this many seconds; a jump
    /// may carry the head out of the top of the picture for a moment.
    /// </summary>
    [Export]
    public float LostTimeout = 0.8f;

    private const string _modelPath = (
        "res://scenes/vision/yolox/model/yolox_n_body_head_hand_face_post_1x3x256x320.onnx"
    );

    private const string _yunetPath = (
        "res://scenes/vision/yunet/model/face_detection_yunet_2023mar_dynamic.onnx"
    );

    private const string _rtmposePath = (
        "res://scenes/vision/rtmpose/model/rtmpose_t_body7_256x192.onnx"
    );

    private const string _sfacePath = (
        "res://scenes/vision/sface/model/face_recognition_sface_2021dec_int8.onnx"
    );

    /// <summary>
    /// A head which comes back takes over the dwarf of a lost player only if
    /// their faces are at least this similar (the cosine of the embeddings of
    /// SFace: the same face gives about 0.95, different people below 0.4).
    /// </summary>
    [Export]
    public float ReIdThreshold = 0.45f;

    /// <summary>Remember the faces of the players who left for this many seconds.</summary>
    [Export]
    public float ReIdMemory = 1800f;

    /// <summary>
    /// Estimate the poses of at most this many players per frame (in one batch),
    /// those whose poses are the oldest.
    /// </summary>
    /// <remarks>
    /// On a laptop CPU (an i7-6600U), the poses cost 17 ms for one player, 31
    /// for two and 46 for four, next to 26 ms of the detector. With one pose per
    /// frame in turns, the players who played together lost the swings of their
    /// arms: replayed with every fourth pose (as for four players), the
    /// recordings of single players lose a third of their swings. With all four
    /// poses in every frame, the frames come about a third less often, which
    /// loses about 5 % of the jumps in the recordings.
    /// </remarks>
    [Export]
    public int PoseBudget = 4;

    private enum EventKind
    {
        Appeared,
        Moved,
        Lost,
        Jumped,
        Swung,
        Arms,
    }

    private readonly struct HeadEvent
    {
        public readonly EventKind Kind;
        public readonly int Id;
        public readonly Vector2 Position;
        public readonly float Size;
        public readonly float Rise;
        public readonly float JumpLine;
        public readonly bool Jumping;
        public readonly float Roll;

        public HeadEvent(
            EventKind kind,
            int id,
            Vector2 position,
            float size,
            float rise,
            float jumpLine = float.NaN,
            bool jumping = false,
            float roll = 0f
        )
        {
            Kind = kind;
            Id = id;
            Position = position;
            Size = size;
            Rise = rise;
            JumpLine = jumpLine;
            Jumping = jumping;
            Roll = roll;
        }
    }

    private CameraFeed? _cameraFeed;
    private CameraTexture? _cameraTexture;

    /// <summary>
    /// The chroma plane of a feed which delivers its frames as two planes (Y and
    /// CbCr, e.g., on macOS); <see cref="_cameraTexture"/> then holds the Y plane.
    /// </summary>
    private CameraTexture? _cbcrTexture;

    /// <summary>The frames of a two-plane feed converted to RGB, for the preview.</summary>
    private ImageTexture? _ycbcrPreview;

    /// <summary>Convert the two-plane frames down to at most this width.</summary>
    private const int _maxYcbcrWidth = 640;

    /// <summary>Try to activate the feed again at this time, see <see cref="RetryActivation"/>.</summary>
    private double _nextActivationAttempt = double.NaN;

    /// <summary>Try to activate an inactive feed again every this many seconds.</summary>
    private const double _activationRetryPeriod = 3.0;

    private readonly System.Diagnostics.Stopwatch _clock = (
        System.Diagnostics.Stopwatch.StartNew()
    );

    private readonly object _latestFrameLock = new object();
    private Frame? _latestFrame;

    // NOTE (mristin):
    // Unlike the frames, we must not drop any events, so we queue them all.
    private readonly ConcurrentQueue<HeadEvent> _events = new ConcurrentQueue<HeadEvent>();

    private volatile bool _inferenceRunning = false;
    private System.Threading.Thread? _inferenceThread;

    private volatile string _status = "The camera is off.";
    private volatile float _inferenceMs = 0f;

    /// <summary>What the vision does now, for the players (e.g., "Loading...").</summary>
    public string Status => _status;

    /// <summary>How long the last detection took, in milliseconds.</summary>
    public float InferenceMs => _inferenceMs;

    /// <summary>Whether the camera runs.</summary>
    public bool IsStarted => _cameraFeed != null;

    /// <summary>
    /// The camera picture, not mirrored; draw it mirrored (flip_h) so that it
    /// matches the positions of the heads. Null before the start.
    /// </summary>
    public Texture2D? GetPreview()
    {
        if (_ycbcrPreview != null)
        {
            return _ycbcrPreview;
        }

        if (_cameraFeed != null && _cameraFeed.GetDatatype() == CameraFeed.FeedDataType.YcbcrSep)
        {
            return null;
        }

        return _cameraTexture;
    }

    /// <summary>Start the camera and the tracking of the heads.</summary>
    public void Start(CameraFeed cameraFeed)
    {
        if (_cameraFeed != null)
        {
            throw new InvalidOperationException("HeadVision has already been started.");
        }

        _cameraFeed = cameraFeed;

        _cameraTexture = new CameraTexture
        {
            CameraFeedId = _cameraFeed.GetId(),
            CameraIsActive = true
        };

        _cbcrTexture = new CameraTexture
        {
            CameraFeedId = _cameraFeed.GetId(),
            WhichFeed = CameraServer.FeedImage.CbcrImage,
            CameraIsActive = true
        };

        _nextActivationAttempt = _clock.Elapsed.TotalSeconds + _activationRetryPeriod;

        _cameraFeed.FrameChanged += OnFrameChanged;

        if (!FileAccess.FileExists(_modelPath))
        {
            _status = $"The model is missing: {_modelPath}";
            GD.PushError(_status);
            return;
        }

        byte[] model = FileAccess.GetFileAsBytes(_modelPath);
        GD.Print($"Loaded {_modelPath}, size: {model.Length / 1024.0 / 1024.0:F2} MB");

        // NOTE (mristin):
        // Without the face models, we follow the heads by their motion alone.
        byte[]? yunet = FileAccess.FileExists(_yunetPath) ? FileAccess.GetFileAsBytes(_yunetPath) : null;
        byte[]? sface = FileAccess.FileExists(_sfacePath) ? FileAccess.GetFileAsBytes(_sfacePath) : null;

        // NOTE (mristin):
        // Without the pose model, the helmets do not tilt.
        byte[]? rtmpose = FileAccess.FileExists(_rtmposePath) ? FileAccess.GetFileAsBytes(_rtmposePath) : null;

        var tracker = new MultiHeadTracker
        {
            MaxHeads = MaxHeads,
            MinCutoff = MinCutoff,
            Beta = Beta,
            LostTimeout = LostTimeout,
            ReIdThreshold = ReIdThreshold,
            ReIdMemory = ReIdMemory,
        };

        _status = "Loading the head detector...";

        _inferenceRunning = true;
        _inferenceThread = new System.Threading.Thread(() => InferenceLoop(model, yunet, sface, rtmpose, tracker))
        {
            IsBackground = true,
            Name = "Head tracking"
        };
        _inferenceThread.Start();
    }

    public override void _ExitTree()
    {
        if (_cameraFeed != null)
        {
            _cameraFeed.FrameChanged -= OnFrameChanged;
        }

        _inferenceRunning = false;
        _inferenceThread?.Join();
        _inferenceThread = null;
    }

    /// <summary>
    /// Activate the feed again if it did not start, which happens on macOS on the
    /// first start: the feed asks for the permission and stays off even when the
    /// players grant it.
    /// </summary>
    /// <remarks>
    /// While the system still asks, every attempt asks again, so we try only every
    /// few seconds; Godot keeps the capture session once there is one.
    /// </remarks>
    private void RetryActivation()
    {
        double now = _clock.Elapsed.TotalSeconds;
        if (_cameraFeed == null || _cameraFeed.FeedIsActive
            || double.IsNaN(_nextActivationAttempt) || now < _nextActivationAttempt)
        {
            return;
        }

        _nextActivationAttempt = now + _activationRetryPeriod;
        GD.Print(
            "The camera did not start; trying again "
            + "(maybe the camera permission was just granted)."
        );
        _cameraFeed.FeedIsActive = true;

        if (_cameraTexture != null)
        {
            _cameraTexture.CameraIsActive = true;
        }

        if (_cbcrTexture != null)
        {
            _cbcrTexture.CameraIsActive = true;
        }
    }

    private void OnFrameChanged()
    {
        if (_cameraTexture == null || _cameraFeed == null)
        {
            return;
        }

        byte[] rgb;
        int width;
        int height;

        if (_cameraFeed.GetDatatype() == CameraFeed.FeedDataType.YcbcrSep)
        {
            // NOTE (mristin):
            // A two-plane feed (e.g., on macOS) has no RGB texture, so we convert
            // it ourselves, and show the converted frame in the preview.
            Image? luma = _cameraTexture.GetImage();
            Image? chroma = _cbcrTexture?.GetImage();
            if (luma == null || luma.IsEmpty() || chroma == null || chroma.IsEmpty())
            {
                return;
            }

            if (luma.GetFormat() != Image.Format.R8)
            {
                luma.Convert(Image.Format.R8);
            }

            if (chroma.GetFormat() != Image.Format.Rg8)
            {
                chroma.Convert(Image.Format.Rg8);
            }

            (rgb, width, height) = YcbcrConverter.ToRgb(
                luma.GetData(), luma.GetWidth(), luma.GetHeight(),
                chroma.GetData(), chroma.GetWidth(), chroma.GetHeight(),
                _maxYcbcrWidth
            );

            var preview = Image.CreateFromData(width, height, false, Image.Format.Rgb8, rgb);
            if (_ycbcrPreview == null || _ycbcrPreview.GetSize() != preview.GetSize())
            {
                _ycbcrPreview = ImageTexture.CreateFromImage(preview);
            }
            else
            {
                _ycbcrPreview.Update(preview);
            }
        }
        else
        {
            Image? image = _cameraTexture.GetImage();
            if (image == null || image.IsEmpty())
            {
                return;
            }

            if (image.GetFormat() != Image.Format.Rgb8)
            {
                image.Convert(Image.Format.Rgb8);
            }

            rgb = image.GetData();
            width = image.GetWidth();
            height = image.GetHeight();
        }

        // NOTE (mristin):
        // We copy the raw bytes on the main thread so that the inference thread
        // never touches any engine objects.
        var frame = new Frame(rgb, width, height, _clock.Elapsed.TotalSeconds);

        lock (_latestFrameLock)
        {
            _latestFrame = frame;
        }
    }

    private void InferenceLoop(
        byte[] model, byte[]? yunet, byte[]? sface, byte[]? rtmpose, MultiHeadTracker tracker
    )
    {
        YoloxModel? detector = null;
        FaceEmbedder? faces = null;
        RtmPoseModel? poses = null;
        var gauges = new Dictionary<int, JumpGauge>();
        var swings = new Dictionary<int, SwingGauge>();

        try
        {
            detector = new YoloxModel(model);
            if (yunet != null && sface != null)
            {
                faces = new FaceEmbedder(yunet, sface);
            }
            else
            {
                GD.PushWarning("The face models are missing; the players are not recognized when they come back.");
            }

            if (rtmpose != null)
            {
                poses = new RtmPoseModel(rtmpose);
            }
            else
            {
                GD.PushWarning("The pose model is missing; the helmets do not tilt.");
            }

            GD.Print("The head tracking is ready.");
            _status = "";

            var cameraSize = System.Numerics.Vector2.One;
            double timestamp = 0.0;

            Track? Find(int id)
            {
                foreach (var track in tracker.Tracks)
                {
                    if (track.Id == id)
                    {
                        return track;
                    }
                }
                return null;
            }

            HeadEvent Describe(EventKind kind, int id, JumpGauge? gauge)
            {
                var track = Find(id);
                if (track == null)
                {
                    return new HeadEvent(kind, id, new Vector2(0.5f, 0.5f), 0f, 0f);
                }

                return new HeadEvent(
                    kind,
                    id,
                    new Vector2(track.Position.X / cameraSize.X, track.Position.Y / cameraSize.Y),
                    track.Size / cameraSize.Y,
                    gauge?.Rise ?? 0f,
                    gauge == null ? float.NaN : gauge.JumpLine / cameraSize.Y,
                    gauge?.IsJumping ?? false,
                    track.Roll
                );
            }

            JumpGauge? Observe(int id)
            {
                var track = Find(id);
                if (track == null)
                {
                    return null;
                }

                if (!gauges.TryGetValue(id, out var gauge))
                {
                    gauge = new JumpGauge();
                    gauges[id] = gauge;
                }

                float strength = gauge.Observe(timestamp, track.JumpY, track.JumpSize);
                if (strength > 0f)
                {
                    // NOTE (mristin):
                    // The strength of the jump travels as its rise.
                    _events.Enqueue(new HeadEvent(EventKind.Jumped, id, Vector2.Zero, 0f, strength));
                }

                return gauge;
            }

            tracker.OnAppeared = (id, _) =>
            {
                _events.Enqueue(Describe(EventKind.Appeared, id, Observe(id)));
            };
            tracker.OnMoved = (id, _) =>
            {
                _events.Enqueue(Describe(EventKind.Moved, id, Observe(id)));
            };
            tracker.OnLost = id =>
            {
                gauges.Remove(id);
                swings.Remove(id);
                _events.Enqueue(new HeadEvent(EventKind.Lost, id, Vector2.Zero, 0f, 0f));
            };

            var stopwatch = new System.Diagnostics.Stopwatch();

            while (_inferenceRunning)
            {
                Frame? frame;
                lock (_latestFrameLock)
                {
                    frame = _latestFrame;
                    _latestFrame = null;
                }

                if (frame == null)
                {
                    System.Threading.Thread.Sleep(1);
                    continue;
                }

                cameraSize = new System.Numerics.Vector2(frame.Width, frame.Height);
                timestamp = frame.Timestamp;

                stopwatch.Restart();
                var result = detector.Detect(frame);
                _inferenceMs = (float)stopwatch.Elapsed.TotalMilliseconds;

                EmbedHead? embed = null;
                if (faces != null)
                {
                    var current = frame;
                    embed = head => faces.Embed(current, head);
                }

                tracker.Update(result.Heads, cameraSize, frame.Timestamp, embed);

                if (poses != null)
                {
                    foreach (var track in EstimatePoses(poses, tracker, frame, result))
                    {
                        if (!swings.TryGetValue(track.Id, out var swing))
                        {
                            swing = new SwingGauge();
                            swings[track.Id] = swing;
                        }

                        int side = swing.Observe(
                            frame.Timestamp, track.Pose!, track.Size, frame.Width, frame.Height
                        );
                        // NOTE (mristin):
                        // The left arm travels as the position, the right one as
                        // the size and the rise.
                        _events.Enqueue(
                            new HeadEvent(
                                EventKind.Arms,
                                track.Id,
                                new Vector2(swing.Arms[0], swing.Arms[1]),
                                swing.Arms[2],
                                swing.Arms[3]
                            )
                        );
                        if (side != 0)
                        {
                            // NOTE (mristin):
                            // The side of the swing travels as its rise.
                            _events.Enqueue(new HeadEvent(EventKind.Swung, track.Id, Vector2.Zero, 0f, side));
                        }
                    }
                }
            }
        }
        catch (Exception exception)
        {
            GD.PushError($"The head tracking failed: {exception}");
            _status = $"The head tracking failed:\n{exception.Message}";
        }
        finally
        {
            detector?.Dispose();
            faces?.Dispose();
            poses?.Dispose();
        }

        GD.Print("Left the inference loop.");
    }

    /// <summary>
    /// Estimate the poses of the players seen in the frame, in one batch, at
    /// most <see cref="PoseBudget"/> of them, those whose poses are the oldest.
    /// </summary>
    /// <returns>The tracks whose poses were estimated.</returns>
    private List<Track> EstimatePoses(
        RtmPoseModel poses, MultiHeadTracker tracker, Frame frame, DetectionResult result
    )
    {
        var candidates = new List<Track>();
        foreach (var track in tracker.Tracks)
        {
            if (track.Confirmed && track.RawHead.HasValue && track.LastSeen == frame.Timestamp)
            {
                candidates.Add(track);
            }
        }
        candidates.Sort((a, b) => a.PoseTimestamp.CompareTo(b.PoseTimestamp));

        int count = Math.Min(PoseBudget, candidates.Count);
        var chosen = candidates.GetRange(0, count);
        var boxes = new List<BoundingBox>(count);
        foreach (var track in chosen)
        {
            boxes.Add(Pose.PlayerBox(track.RawHead!.Value, result.Bodies, frame.Width, frame.Height));
        }
        var estimated = poses.EstimateMany(frame, boxes);
        for (int i = 0; i < count; i++)
        {
            chosen[i].ObservePose(estimated[i], frame.Timestamp, frame.Width, frame.Height);
        }
        return chosen;
    }

    public override void _Process(double delta)
    {
        RetryActivation();

        while (_events.TryDequeue(out var headEvent))
        {
            switch (headEvent.Kind)
            {
                case EventKind.Appeared:
                    EmitSignal(SignalName.HeadAppeared, headEvent.Id, headEvent.Position, headEvent.Size);
                    break;

                case EventKind.Moved:
                    EmitSignal(
                        SignalName.HeadMoved,
                        headEvent.Id,
                        headEvent.Position,
                        headEvent.Size,
                        headEvent.Rise,
                        headEvent.JumpLine,
                        headEvent.Jumping,
                        headEvent.Roll
                    );
                    break;

                case EventKind.Lost:
                    EmitSignal(SignalName.HeadLost, headEvent.Id);
                    break;

                case EventKind.Jumped:
                    GD.Print($"The head {headEvent.Id} jumped (strength {headEvent.Rise:F1}).");
                    EmitSignal(SignalName.HeadJumped, headEvent.Id, headEvent.Rise);
                    break;

                case EventKind.Swung:
                    GD.Print($"The head {headEvent.Id} swung to the {(headEvent.Rise < 0f ? "left" : "right")}.");
                    EmitSignal(SignalName.HeadSwung, headEvent.Id, (int)headEvent.Rise);
                    break;

                case EventKind.Arms:
                    EmitSignal(
                        SignalName.HeadArms,
                        headEvent.Id,
                        new Vector4(headEvent.Position.X, headEvent.Position.Y, headEvent.Size, headEvent.Rise)
                    );
                    break;
            }
        }
    }
}
