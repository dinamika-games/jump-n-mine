"""
Render the music of the game, assets/music/<slug>.mid, into
assets/music/<slug>.ogg, as listed in dev/music/sources.json.

We synthesize the instruments ourselves, so that no sound font (and no license
of one) is needed: the piano with its harmonics fading, the plucked strings
(Karplus-Strong), the brass, the reeds, the flutes, the strings and the
organs as tones of harmonics, the bells, and the timpani. A short reverb puts
the music in a cave, and every song is brought to the same loudness.

You need numpy (in dev/requirements.txt) and sox with the Vorbis format (e.g.,
"apt install sox libsox-fmt-all"):

    venv/bin/python dev/music/render_music.py [slug ...]
"""

import argparse
import json
import pathlib
import subprocess
import sys
from typing import Callable, Dict, Final, List

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import midi  # noqa: E402

REPO: Final[pathlib.Path] = pathlib.Path(__file__).resolve().parents[2]
SOURCES: Final[pathlib.Path] = REPO / "dev" / "music" / "sources.json"
MUSIC: Final[pathlib.Path] = REPO / "assets" / "music"

RATE: Final[int] = 32000

# The loudness (RMS) of every song and the most its peak may reach, in dBFS.
LOUDNESS_DB: Final[float] = -20.0
PEAK_DB: Final[float] = -1.0

# How much of the reverb is mixed in, and how long it rings, in seconds.
REVERB_WET: Final[float] = 0.22
REVERB_LENGTH: Final[float] = 1.6

# The silence at the end of a song, in seconds, after its last note rang out.
TAIL: Final[float] = 1.0

Instrument = Callable[[float, float, float, np.random.Generator], np.ndarray]


def frequency(pitch: float) -> float:
    return 440.0 * 2.0 ** ((pitch - 69.0) / 12.0)


def times(count: int) -> np.ndarray:
    return np.arange(count, dtype=np.float64) / RATE


def adsr(count: int, held: float, attack: float, decay: float, sustain: float, release: float):
    """An envelope: up in the attack, down to the sustain in the decay, and
    down to zero in the release after the note is held."""
    t = times(count)
    envelope = np.where(
        t < attack,
        t / max(attack, 1e-6),
        sustain + (1.0 - sustain) * np.exp(-(t - attack) / max(decay, 1e-6)),
    )
    level_at_release = np.interp(held, t, envelope) if count else 0.0
    after = t >= held
    envelope[after] = level_at_release * np.maximum(0.0, 1.0 - (t[after] - held) / release)
    return envelope


def vibrato_phase(base: float, count: int, depth: float, rate: float, delay: float) -> np.ndarray:
    """The phase (in cycles) of a tone with a vibrato coming in after the delay."""
    t = times(count)
    swell = np.clip((t - delay) / 0.4, 0.0, 1.0)
    instantaneous = base * (1.0 + depth * swell * np.sin(2.0 * np.pi * rate * t))
    return np.cumsum(instantaneous) / RATE


def harmonics(phase: np.ndarray, amplitudes: List[float]) -> np.ndarray:
    out = np.zeros_like(phase)
    for number, amplitude in enumerate(amplitudes, start=1):
        if amplitude:
            out += amplitude * np.sin(2.0 * np.pi * number * phase)
    return out / sum(abs(amplitude) for amplitude in amplitudes)


def limited(base: float, amplitudes: List[float]) -> List[float]:
    """The harmonics below the Nyquist frequency."""
    return [a if base * (i + 1) < 0.45 * RATE else 0.0 for i, a in enumerate(amplitudes)]


def piano(base: float, held: float, velocity: float, rng: np.random.Generator) -> np.ndarray:
    # NOTE (mristin):
    # A low string rings longer than a high one, and the upper harmonics fade
    # faster than the fundamental; the dampers stop the string when the key
    # is let go.
    ring = float(np.clip(2.5 * (261.6 / base) ** 0.6, 0.35, 6.0))
    count = int((min(held, 3.0 * ring) + 0.15) * RATE)
    t = times(count)
    out = np.zeros(count)
    brightness = 0.5 + 0.5 * velocity
    for number in range(1, 11):
        partial = base * number * np.sqrt(1.0 + 0.0004 * number * number)
        if partial > 0.45 * RATE:
            break
        amplitude = brightness ** (number - 1) / number**1.1
        out += amplitude * np.sin(2.0 * np.pi * partial * t) * np.exp(-t * number**0.7 / ring)
    hammer = rng.uniform(-1.0, 1.0, count) * np.exp(-t / 0.004) * 0.15
    damper = np.where(t < held, 1.0, np.exp(-(t - held) / 0.05))
    attack = np.minimum(1.0, t / 0.002)
    return (out * 0.5 + hammer) * damper * attack


def pluck(base: float, held: float, velocity: float, rng: np.random.Generator) -> np.ndarray:
    """A plucked string (Karplus-Strong), damped when the note ends."""
    period = max(2, int(round(RATE / base)))
    count = int((min(held, 4.0) + 0.1) * RATE)
    blocks = count // period + 2
    out = np.empty(blocks * period)
    line = rng.uniform(-1.0, 1.0, period)
    # A softer pluck is a duller one.
    for _ in range(int(3 - 2 * velocity)):
        line = 0.5 * (line + np.roll(line, -1))
    held_samples = held * RATE
    for block in range(blocks):
        out[block * period : (block + 1) * period] = line
        decay = 0.996 if block * period < held_samples else 0.85
        line = decay * 0.5 * (line + np.roll(line, -1))
    return out[:count]


def bass(base: float, held: float, velocity: float, rng: np.random.Generator) -> np.ndarray:
    count = int((held + 0.1) * RATE)
    phase = base * times(count)
    tone = harmonics(phase, limited(base, [1.0, 0.5, 0.2, 0.1]))
    return tone * adsr(count, held, 0.01, 0.4, 0.5, 0.08)


def brass(base: float, held: float, velocity: float, rng: np.random.Generator) -> np.ndarray:
    count = int((held + 0.12) * RATE)
    phase = vibrato_phase(base, count, 0.003, 5.0, 0.2)
    amplitudes = [1.0 / n**1.4 * (0.6 + 0.4 * velocity) ** (n - 1) for n in range(1, 9)]
    return harmonics(phase, limited(base, amplitudes)) * adsr(count, held, 0.04, 0.6, 0.75, 0.12)


def reed(base: float, held: float, velocity: float, rng: np.random.Generator) -> np.ndarray:
    """A clarinet: mostly the odd harmonics."""
    count = int((held + 0.08) * RATE)
    phase = vibrato_phase(base, count, 0.002, 5.0, 0.3)
    amplitudes = [1.0, 0.05, 0.4, 0.03, 0.2, 0.02, 0.1]
    return harmonics(phase, limited(base, amplitudes)) * adsr(count, held, 0.03, 0.5, 0.85, 0.08)


def flute(base: float, held: float, velocity: float, rng: np.random.Generator) -> np.ndarray:
    count = int((held + 0.1) * RATE)
    phase = vibrato_phase(base, count, 0.004, 5.0, 0.25)
    tone = harmonics(phase, limited(base, [1.0, 0.2, 0.06]))
    breath = np.convolve(rng.uniform(-1.0, 1.0, count), np.ones(8) / 8.0, mode="same") * 0.04
    return (tone + breath) * adsr(count, held, 0.06, 0.4, 0.85, 0.1)


def strings(base: float, held: float, velocity: float, rng: np.random.Generator) -> np.ndarray:
    """A soft ensemble: two saw-like tones a little apart, swelling in."""
    count = int((held + 0.3) * RATE)
    amplitudes = limited(base, [1.0 / n for n in range(1, 9)])
    a = harmonics(vibrato_phase(base * 1.002, count, 0.003, 5.5, 0.2), amplitudes)
    b = harmonics(vibrato_phase(base * 0.998, count, 0.003, 4.7, 0.2), amplitudes)
    return 0.5 * (a + b) * adsr(count, held, 0.15, 1.0, 0.9, 0.3)


def organ(base: float, held: float, velocity: float, rng: np.random.Generator) -> np.ndarray:
    count = int((held + 0.08) * RATE)
    phase = base * times(count)
    tone = harmonics(phase, limited(base, [1.0, 0.6, 0.0, 0.3, 0.0, 0.0, 0.0, 0.15]))
    return tone * adsr(count, held, 0.02, 1.0, 1.0, 0.08)


def bell(base: float, held: float, velocity: float, rng: np.random.Generator) -> np.ndarray:
    """A music box or a glockenspiel: inharmonic partials, ringing out."""
    count = int(2.0 * RATE)
    t = times(count)
    out = np.zeros(count)
    for ratio, amplitude, ring in [(1.0, 1.0, 0.9), (2.76, 0.4, 0.4), (5.4, 0.2, 0.2)]:
        if base * ratio < 0.45 * RATE:
            out += amplitude * np.sin(2.0 * np.pi * base * ratio * t) * np.exp(-t / ring)
    return out * np.minimum(1.0, t / 0.002) * 0.6


def timpani(base: float, held: float, velocity: float, rng: np.random.Generator) -> np.ndarray:
    """A drum tuned to the note: a sine which falls a little, and a thump."""
    count = int(1.2 * RATE)
    t = times(count)
    phase = np.cumsum(base * (1.0 + 0.05 * np.exp(-t * 30.0))) / RATE
    tone = np.sin(2.0 * np.pi * phase) * np.exp(-t * 3.5)
    thump = rng.uniform(-1.0, 1.0, count) * np.exp(-t * 60.0) * 0.5
    return (tone + thump) * np.minimum(1.0, t / 0.002)


INSTRUMENTS: Final[Dict[str, Instrument]] = {
    "piano": piano,
    "pluck": pluck,
    "bass": bass,
    "brass": brass,
    "reed": reed,
    "flute": flute,
    "strings": strings,
    "organ": organ,
    "bell": bell,
    "timpani": timpani,
}

# How loud each instrument plays against the others.
GAINS: Final[Dict[str, float]] = {
    "piano": 1.0,
    "pluck": 0.8,
    "bass": 0.7,
    "brass": 0.6,
    "reed": 0.6,
    "flute": 0.7,
    "strings": 0.45,
    "organ": 0.45,
    "bell": 0.5,
    "timpani": 0.8,
}


def instrument_of(program: int) -> str:
    """The instrument for the General MIDI program."""
    if program == 47:
        return "timpani"
    families = [
        "piano",  # 0-7: pianos
        "bell",  # 8-15: chromatic percussion
        "organ",  # 16-23
        "pluck",  # 24-31: guitars
        "bass",  # 32-39
        "strings",  # 40-47
        "strings",  # 48-55: ensembles and voices
        "brass",  # 56-63
        "reed",  # 64-71
        "flute",  # 72-79
    ]
    return families[program // 8] if program < 80 else "strings"


def reverb(dry: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    """Mix in a reverb: the dry signal convolved with a decaying, dull noise."""
    count = int(REVERB_LENGTH * RATE)
    t = times(count)
    response = rng.normal(0.0, 1.0, count) * np.exp(-t * 6.9 / REVERB_LENGTH)
    response = np.convolve(response, np.ones(6) / 6.0, mode="same")
    response[: int(0.02 * RATE)] = 0.0
    response /= np.sqrt(np.sum(response**2))
    size = 1 << int(np.ceil(np.log2(len(dry) + count)))
    wet = np.fft.irfft(np.fft.rfft(dry, size) * np.fft.rfft(response, size), size)
    wet = wet[: len(dry)]
    return dry + REVERB_WET * wet * np.sqrt(np.mean(dry**2) / max(np.mean(wet**2), 1e-12))


def render(source: dict, song: midi.Song) -> np.ndarray:
    """Mix the notes of the song with the instruments of its source."""
    overrides: Dict[str, str] = source.get("instruments", {})
    transpose = float(source.get("transpose", 0))
    tempo = float(source.get("tempo_scale", 1.0))
    repeat = int(source.get("repeat", 1))
    length = song.length / tempo
    total = int((length * repeat + REVERB_LENGTH + TAIL + 5.0) * RATE)
    mix = np.zeros(total)
    rng = np.random.default_rng(7)
    end = 0
    for round_ in range(repeat):
        offset = round_ * length
        for note in song.notes:
            name = song.track_names[note.track] if note.track < len(song.track_names) else ""
            instrument = (
                overrides.get(name)
                or overrides.get(str(note.track))
                or overrides.get("*")
                or instrument_of(note.program)
            )
            if instrument == "mute":
                continue
            held = (note.end - note.start) / tempo
            base = frequency(note.pitch + transpose)
            samples = INSTRUMENTS[instrument](base, held, note.velocity / 127.0, rng)
            gain = GAINS[instrument] * (0.35 + 0.65 * note.velocity / 127.0)
            start = int((offset + note.start / tempo) * RATE)
            stop = min(total, start + len(samples))
            mix[start:stop] += gain * samples[: stop - start]
            end = max(end, stop)
    mix = mix[: min(total, end + int((REVERB_LENGTH + TAIL) * RATE))]
    mix = reverb(mix, rng)
    rms = np.sqrt(np.mean(mix**2))
    gain = 10.0 ** (LOUDNESS_DB / 20.0) / rms
    peak = np.max(np.abs(mix)) * gain
    if peak > 10.0 ** (PEAK_DB / 20.0):
        gain *= 10.0 ** (PEAK_DB / 20.0) / peak
    fade = min(len(mix), int(TAIL * RATE))
    mix[-fade:] *= np.linspace(1.0, 0.0, fade)
    return (mix * gain).astype(np.float32)


def encode(samples: np.ndarray, path: pathlib.Path) -> None:
    """Write the samples as Ogg Vorbis."""
    command = ["sox", "-t", "f32", "-c", "1", "-r", str(RATE), "-", "-C", "3", str(path)]
    subprocess.run(command, check=True, input=samples.tobytes())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("slugs", nargs="*", help="render only these songs (default: all)")
    args = parser.parse_args()

    sources = json.loads(SOURCES.read_text(encoding="utf-8"))["songs"]
    for source in sources:
        if args.slugs and source["slug"] not in args.slugs:
            continue
        song = midi.read(MUSIC / f"{source['slug']}.mid")
        samples = render(source, song)
        path = MUSIC / f"{source['slug']}.ogg"
        encode(samples, path)
        print(f"{path.relative_to(REPO)}: {len(song.notes)} notes, {len(samples) / RATE:.1f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
