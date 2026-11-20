extends Node

## The sounds of the game (the autoload Sounds): the pickaxe on the earth and
## the rock, the breaking blocks, the gems, the fuses and the explosions, the
## water and the dragons.
##
## The sounds are cut out of CC0 recordings from Freesound into
## [code]assets/sounds/<name>.ogg[/code] (see dev/sounds/sources.json); a sound
## without a recording is synthesized from its recipe in [constant _RECIPES].
##
## Play a sound with [code]Sounds.play("gem")[/code], and keep a loop going
## with [code]Sounds.loop("water_pour", true)[/code].
## M mutes the game, and so does [code]-- --mute[/code] at the start.

const _RATE := 22050

## How many sounds play at the same time at most.
const _VOICES := 10

## The sounds: each a list of tones, each tone with its "wave" ("sine",
## "square", "noise" or "triangle"), its frequencies at the start and the end
## ("from", "to", in Hz), its "start" and "length" in seconds, and its "volume".
const _RECIPES := {
    "swing":
    [{"wave": "noise", "from": 900.0, "to": 300.0, "start": 0.0, "length": 0.12, "volume": 0.15}],
    "hit_soft":
    [
        {"wave": "noise", "from": 500.0, "to": 150.0, "start": 0.0, "length": 0.12, "volume": 0.5},
        {"wave": "sine", "from": 140.0, "to": 80.0, "start": 0.0, "length": 0.1, "volume": 0.4},
    ],
    "hit_hard":
    [
        {"wave": "square", "from": 900.0, "to": 700.0, "start": 0.0, "length": 0.05, "volume": 0.2},
        {"wave": "noise", "from": 2000.0, "to": 600.0, "start": 0.0, "length": 0.1, "volume": 0.4},
        {"wave": "sine", "from": 220.0, "to": 120.0, "start": 0.0, "length": 0.12, "volume": 0.3},
    ],
    "break":
    [
        {"wave": "noise", "from": 1200.0, "to": 100.0, "start": 0.0, "length": 0.35, "volume": 0.6},
        {"wave": "sine", "from": 120.0, "to": 50.0, "start": 0.0, "length": 0.3, "volume": 0.5},
    ],
    "gem":
    [
        {
            "wave": "sine",
            "from": 1319.0,
            "to": 1319.0,
            "start": 0.0,
            "length": 0.12,
            "volume": 0.35
        },
        {
            "wave": "sine",
            "from": 1760.0,
            "to": 1760.0,
            "start": 0.08,
            "length": 0.14,
            "volume": 0.35
        },
        {
            "wave": "sine",
            "from": 2637.0,
            "to": 2637.0,
            "start": 0.16,
            "length": 0.25,
            "volume": 0.3
        },
    ],
    "booster":
    [
        {
            "wave": "triangle",
            "from": 523.0,
            "to": 523.0,
            "start": 0.0,
            "length": 0.1,
            "volume": 0.4
        },
        {
            "wave": "triangle",
            "from": 659.0,
            "to": 659.0,
            "start": 0.09,
            "length": 0.1,
            "volume": 0.4
        },
        {
            "wave": "triangle",
            "from": 784.0,
            "to": 784.0,
            "start": 0.18,
            "length": 0.1,
            "volume": 0.4
        },
        {
            "wave": "triangle",
            "from": 1047.0,
            "to": 1047.0,
            "start": 0.27,
            "length": 0.3,
            "volume": 0.4
        },
    ],
    "fuse":
    [{"wave": "noise", "from": 6000.0, "to": 4000.0, "start": 0.0, "length": 0.6, "volume": 0.25}],
    "explosion":
    [
        {"wave": "noise", "from": 800.0, "to": 40.0, "start": 0.0, "length": 0.9, "volume": 0.9},
        {"wave": "sine", "from": 90.0, "to": 30.0, "start": 0.0, "length": 0.7, "volume": 0.8},
    ],
    "splash":
    [{"wave": "noise", "from": 3000.0, "to": 500.0, "start": 0.0, "length": 0.4, "volume": 0.35}],
    "blub":
    [
        {"wave": "sine", "from": 300.0, "to": 700.0, "start": 0.0, "length": 0.08, "volume": 0.3},
        {"wave": "sine", "from": 350.0, "to": 800.0, "start": 0.1, "length": 0.08, "volume": 0.25},
    ],
    "sealed":
    [
        {"wave": "square", "from": 400.0, "to": 400.0, "start": 0.0, "length": 0.08, "volume": 0.2},
        {"wave": "sine", "from": 600.0, "to": 900.0, "start": 0.06, "length": 0.2, "volume": 0.35},
    ],
    "dragon":
    [
        {"wave": "square", "from": 110.0, "to": 70.0, "start": 0.0, "length": 0.6, "volume": 0.2},
        {"wave": "noise", "from": 400.0, "to": 200.0, "start": 0.0, "length": 0.6, "volume": 0.25},
    ],
    "spit":
    [{"wave": "noise", "from": 2500.0, "to": 300.0, "start": 0.0, "length": 0.5, "volume": 0.45}],
    "fizzle":
    [{"wave": "noise", "from": 7000.0, "to": 3000.0, "start": 0.0, "length": 0.4, "volume": 0.3}],
    "dizzy":
    [
        {
            "wave": "triangle",
            "from": 900.0,
            "to": 300.0,
            "start": 0.0,
            "length": 0.25,
            "volume": 0.3
        },
        {
            "wave": "triangle",
            "from": 700.0,
            "to": 250.0,
            "start": 0.2,
            "length": 0.25,
            "volume": 0.3
        },
    ],
    "shielded":
    [{"wave": "sine", "from": 1500.0, "to": 1500.0, "start": 0.0, "length": 0.3, "volume": 0.3}],
    "rope":
    [{"wave": "triangle", "from": 600.0, "to": 300.0, "start": 0.0, "length": 0.4, "volume": 0.25}],
    "select":
    [{"wave": "sine", "from": 700.0, "to": 700.0, "start": 0.0, "length": 0.05, "volume": 0.2}],
    "click":
    [
        {"wave": "sine", "from": 880.0, "to": 880.0, "start": 0.0, "length": 0.07, "volume": 0.35},
        {
            "wave": "sine",
            "from": 1320.0,
            "to": 1320.0,
            "start": 0.06,
            "length": 0.1,
            "volume": 0.35
        },
    ],
    "won":
    [
        {
            "wave": "triangle",
            "from": 523.0,
            "to": 523.0,
            "start": 0.0,
            "length": 0.18,
            "volume": 0.4
        },
        {
            "wave": "triangle",
            "from": 659.0,
            "to": 659.0,
            "start": 0.18,
            "length": 0.18,
            "volume": 0.4
        },
        {
            "wave": "triangle",
            "from": 784.0,
            "to": 784.0,
            "start": 0.36,
            "length": 0.18,
            "volume": 0.4
        },
        {
            "wave": "triangle",
            "from": 1047.0,
            "to": 1047.0,
            "start": 0.54,
            "length": 0.6,
            "volume": 0.4
        },
        {"wave": "sine", "from": 523.0, "to": 523.0, "start": 0.54, "length": 0.6, "volume": 0.25},
    ],
    "flooded":
    [
        {
            "wave": "triangle",
            "from": 392.0,
            "to": 392.0,
            "start": 0.0,
            "length": 0.3,
            "volume": 0.4
        },
        {
            "wave": "triangle",
            "from": 330.0,
            "to": 330.0,
            "start": 0.3,
            "length": 0.3,
            "volume": 0.4
        },
        {
            "wave": "triangle",
            "from": 262.0,
            "to": 250.0,
            "start": 0.6,
            "length": 0.7,
            "volume": 0.4
        },
        {"wave": "noise", "from": 1500.0, "to": 300.0, "start": 0.0, "length": 1.2, "volume": 0.2},
    ],
}

## The recordings of the sounds.
const _RECORDINGS := "res://assets/sounds/%s.ogg"

## The sounds which repeat while something goes on.
const _LOOPS := ["water_pour", "fuse"]

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _loops := {}


func _ready() -> void:
    if "--mute" in OS.get_cmdline_user_args():
        set_muted(true)
    for i in range(_VOICES):
        var player := AudioStreamPlayer.new()
        add_child(player)
        _players.append(player)


func _exit_tree() -> void:
    stop_all()
    for player in _players:
        player.stream = null
    for sound in _loops:
        _loops[sound].stream = null
    _streams.clear()


## Whether the game is silent.
func is_muted() -> bool:
    return AudioServer.is_bus_mute(0)


## Silence the game, or let it sound again.
func set_muted(muted: bool) -> void:
    AudioServer.set_bus_mute(0, muted)


## M switches the sound off and on, anywhere in the game.
func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
        set_muted(not is_muted())
        get_viewport().set_input_as_handled()


## Play the sound of the name (see [constant _RECIPES]), a little higher or
## lower by the pitch.
func play(sound: String, pitch := 1.0, volume_db := 0.0) -> void:
    # NOTE (mristin):
    # The dummy driver (headless, and the tests) never mixes, so the sounds
    # would never let go of their streams; nobody hears them anyway.
    if AudioServer.get_driver_name() == "Dummy":
        return
    var stream := _stream(sound)
    if stream == null:
        return
    var player := _players[_next]
    _next = (_next + 1) % _players.size()
    player.stream = stream
    player.pitch_scale = pitch
    player.volume_db = volume_db
    player.play()


## Keep the loop of the name (see [constant _LOOPS]) playing, or stop it.
func loop(sound: String, on: bool) -> void:
    if AudioServer.get_driver_name() == "Dummy":
        return
    if not _loops.has(sound):
        if not on:
            return
        var player := AudioStreamPlayer.new()
        player.stream = _stream(sound)
        player.volume_db = -8.0
        add_child(player)
        _loops[sound] = player
    var looping: AudioStreamPlayer = _loops[sound]
    if on and not looping.playing:
        looping.play()
    elif not on and looping.playing:
        looping.stop()


## Stop all the sounds; the audio server lets go of them at its next mix (the
## tests wait for it before they quit, so that nothing stays in use).
func stop_all() -> void:
    for player in _players:
        player.stop()
    stop_loops()


## Stop all the loops, e.g., when the level ends.
func stop_loops() -> void:
    for sound in _loops:
        _loops[sound].stop()


## The stream of the sound: its recording, else its recipe; null if neither.
func _stream(sound: String) -> AudioStream:
    if _streams.has(sound):
        return _streams[sound]
    var stream: AudioStream = null
    var path := _RECORDINGS % sound
    if ResourceLoader.exists(path):
        stream = load(path)
        if stream is AudioStreamOggVorbis:
            stream = stream.duplicate()
            stream.loop = sound in _LOOPS
    elif _RECIPES.has(sound):
        stream = _synthesize(_RECIPES[sound])
    else:
        push_warning("There is no sound %s." % sound)
        return null
    _streams[sound] = stream
    return stream


static func _synthesize(tones: Array) -> AudioStreamWAV:
    var length := 0.0
    for tone in tones:
        length = maxf(length, float(tone["start"]) + float(tone["length"]))
    var count := int(length * _RATE) + 1
    var samples := PackedFloat32Array()
    samples.resize(count)
    samples.fill(0.0)
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    for tone in tones:
        var start := int(float(tone["start"]) * _RATE)
        var n := int(float(tone["length"]) * _RATE)
        var phase := 0.0
        var noise := 0.0
        var noise_phase := 0.0
        for k in range(n):
            var t := float(k) / maxf(1.0, n - 1.0)
            var frequency := lerpf(float(tone["from"]), float(tone["to"]), t)
            phase += frequency / _RATE
            var value := 0.0
            match str(tone["wave"]):
                "sine":
                    value = sin(TAU * phase)
                "square":
                    value = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
                "triangle":
                    value = 4.0 * absf(fmod(phase, 1.0) - 0.5) - 1.0
                "noise":
                    # NOTE (mristin):
                    # A noise which changes at the frequency sounds lower or
                    # higher, like a crumble or a hiss.
                    noise_phase += frequency / _RATE
                    if noise_phase >= 1.0:
                        noise_phase -= floor(noise_phase)
                        noise = rng.randf_range(-1.0, 1.0)
                    value = noise
            # A quick attack and a smooth decay, so that nothing clicks.
            var envelope := minf(1.0, k / (0.005 * _RATE)) * pow(1.0 - t, 1.5)
            var at := start + k
            if at < count:
                samples[at] += value * envelope * float(tone["volume"])
    var data := PackedByteArray()
    data.resize(count * 2)
    for k in range(count):
        data.encode_s16(k * 2, int(clampf(samples[k], -1.0, 1.0) * 30000.0))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = _RATE
    stream.stereo = false
    stream.data = data
    return stream
