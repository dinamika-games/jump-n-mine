"""
Read a tune in ABC notation (the common subset of folk transcriptions: one
voice, the notes and the rests with their lengths, the accidentals, the keys
and modes, the ties, the broken rhythms, the triplets, the chords, the repeats
with the first and second endings, the inline fields) into MIDI parts.

The melody is one part; the guitar chords ("Am", "D7", ...) become a second
part, plucked at each change and at the start of each bar.

A tune without guitar chords gets a soft drone on its tonic and fifth instead.

The instruments are set with the directives of abc2midi: "%%MIDI program <n>"
for the melody, "%%MIDI chordprog <n>" for the chords and "%%MIDI droneprog
<n>" for the drone.
"""

import fractions
import re
from typing import Dict, List, Optional, Tuple

import midi

Fraction = fractions.Fraction

STEPS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
SHARPS = "FCGDAEB"
MODES = {"": 0, "maj": 0, "ion": 0, "mix": 1, "dor": 2, "m": 3, "min": 3, "aeo": 3}
MODES.update({"phr": 4, "loc": 5, "lyd": -1})
MAJOR_KEYS = {"C": 0, "G": 1, "D": 2, "A": 3, "E": 4, "B": 5, "F#": 6, "C#": 7}
MAJOR_KEYS.update({"F": -1, "Bb": -2, "Eb": -3, "Ab": -4, "Db": -5, "Gb": -6, "Cb": -7})
CHORDS = {
    "": [0, 4, 7],
    "m": [0, 3, 7],
    "min": [0, 3, 7],
    "7": [0, 4, 7, 10],
    "m7": [0, 3, 7, 10],
    "maj7": [0, 4, 7, 11],
    "dim": [0, 3, 6],
    "aug": [0, 4, 8],
    "+": [0, 4, 8],
    "sus4": [0, 5, 7],
    "sus2": [0, 2, 7],
    "6": [0, 4, 7, 9],
    "m6": [0, 3, 7, 9],
    "9": [0, 4, 7, 10],
}


class Tune:
    """The parts of the tune and its tempo changes as (tick, quarters per
    minute)."""

    def __init__(self, parts: List[midi.Part], tempi: List[Tuple[int, float]]) -> None:
        self.parts = parts
        self.tempi = tempi


def key_signature(text: str) -> Dict[str, int]:
    """The accidentals of the key, e.g., "D", "Em", "Ador", "Bbmix"."""
    match = re.match(r"\s*([A-G])([#b]?)\s*([A-Za-z]*)", text)
    if match is None or text.strip().lower() in ("", "none"):
        return {}
    tonic = match.group(1) + match.group(2)
    mode = match.group(3).lower()[:3] if match.group(3).lower() not in ("m",) else "m"
    # The number of sharps of the major key with the same tonic, moved by the
    # mode (e.g., A dorian has the sharps of G major).
    tonic_major = MAJOR_KEYS.get(tonic)
    if tonic_major is None:
        raise ValueError(f"Unknown key {text!r}")
    sharps = tonic_major - MODES.get(mode, 0)
    signature: Dict[str, int] = {}
    if sharps > 0:
        for step in SHARPS[:sharps]:
            signature[step] = 1
    else:
        for step in reversed(SHARPS[len(SHARPS) + sharps :]):
            signature[step] = -1
    return signature


def parse_fraction(text: str) -> Fraction:
    if "/" in text:
        numerator, denominator = text.split("/")
        return Fraction(int(numerator), int(denominator))
    return Fraction(int(text))


def parse_meter(text: str) -> Fraction:
    text = text.strip()
    if text in ("C", "C|"):
        return Fraction(1) if text == "C" else Fraction(2, 2)
    if text.lower() == "none":
        return Fraction(1)
    return parse_fraction(text)


def parse_tempo(text: str, unit: Fraction) -> float:
    """The quarters per minute of the field Q, e.g., "1/4=120", "3/8=60", "100"."""
    text = re.sub(r'"[^"]*"', "", text).strip()
    if "=" in text:
        beat, bpm = text.split("=", 1)
        beat_length = sum((parse_fraction(part) for part in beat.split()), Fraction(0))
        return float(bpm) * float(beat_length) * 4.0
    return float(text) * float(unit) * 4.0


def parse_length(text: str) -> Fraction:
    """The multiplier of a note length, e.g., "2", "/2", "/", "//", "3/2"."""
    if not text:
        return Fraction(1)
    if re.fullmatch(r"/+", text):
        return Fraction(1, 2 ** len(text))
    match = re.fullmatch(r"(\d*)(/?)(\d*)", text)
    if match is None:
        raise ValueError(f"Bad note length {text!r}")
    numerator = int(match.group(1)) if match.group(1) else 1
    if match.group(2):
        denominator = int(match.group(3)) if match.group(3) else 2
        return Fraction(numerator, denominator)
    return Fraction(numerator)


class _Item:
    """A note, a chord, a rest, a guitar chord or a bar line in the order of
    the tune."""

    def __init__(self, kind: str, **values) -> None:
        self.kind = kind
        self.__dict__.update(values)


def _tokens(body: str, unit: Fraction, signature: Dict[str, int], meter: Fraction):
    """Turn the body into items, each note with its length in whole notes."""
    items: List[_Item] = []
    bar_accidentals: Dict[Tuple[str, int], int] = {}
    tuplet: Optional[List] = None  # [ratio, notes left]
    broken: Optional[Fraction] = None
    pending_tie = False
    i = 0
    note = re.compile(r"(\^\^|\^|__|_|=)?([A-Ga-g])([',]*)")

    def pitch_of(accidental: Optional[str], letter: str, octaves: str) -> int:
        step = letter.upper()
        octave = 4 if letter.isupper() else 5
        octave += octaves.count("'") - octaves.count(",")
        if accidental:
            alter = {"^^": 2, "^": 1, "=": 0, "_": -1, "__": -2}[accidental]
            bar_accidentals[(step, octave)] = alter
        else:
            alter = bar_accidentals.get((step, octave), signature.get(step, 0))
        return 12 * (octave + 1) + STEPS[step] + alter

    def add_length(item: _Item, multiplier: Fraction) -> None:
        nonlocal broken, tuplet
        length = unit * multiplier
        if broken is not None:
            length *= broken
            broken = None
        if tuplet is not None:
            length *= tuplet[0]
            tuplet[1] -= 1
            if tuplet[1] == 0:
                tuplet = None
        item.length = length

    while i < len(body):
        c = body[i]
        if c in " \t\n\r\\`":
            i += 1
            continue
        if c == "%":
            i = body.find("\n", i) if "\n" in body[i:] else len(body)
            continue
        if c == '"':
            end = body.index('"', i + 1)
            text = body[i + 1 : end]
            match = re.match(r"([A-G])([#b]?)([^/]*)", text)
            if match and match.group(3) in CHORDS:
                root = STEPS[match.group(1)] + {"#": 1, "b": -1, "": 0}[match.group(2)]
                items.append(_Item("guitar", root=root, intervals=CHORDS[match.group(3)]))
            i = end + 1
            continue
        if c == "!" or c == "+":
            end = body.find(c, i + 1)
            i = end + 1 if end > 0 else i + 1
            continue
        if c == "{":
            i = body.index("}", i) + 1
            continue
        if c == "[" and re.match(r"\[[A-Za-z]:", body[i:]):
            end = body.index("]", i)
            field, value = body[i + 1 : end].split(":", 1)
            if field == "K":
                signature = key_signature(value)
            elif field == "L":
                unit = parse_fraction(value.strip())
            elif field == "M":
                meter = parse_meter(value)
                items.append(_Item("meter", meter=meter))
            elif field == "Q":
                items.append(_Item("tempo", bpm=parse_tempo(value, unit)))
            i = end + 1
            continue
        bar = re.match(r"(:*\|[\]|]?:*|:*\[\|:*|::|\[?\d(,\d)*)", body[i:])
        if c in "|:[" and bar and not re.match(r"\[[\^_=A-Ga-gz]", body[i:]):
            token = bar.group(0)
            i += len(token)
            if re.fullmatch(r"\[?\d(,\d)*", token):
                items.append(_Item("ending", numbers=token.lstrip("[").split(",")))
                continue
            # A bar line may carry the number of an ending right after it: "|1", ":|2".
            ending = re.match(r"\s?\[?(\d(,\d)*)", body[i:]) if not token.endswith(":") else None
            items.append(
                _Item(
                    "bar",
                    start_repeat=token.endswith(":"),
                    end_repeat=token.startswith(":"),
                    final=token in ("|]", "||", "[|"),
                )
            )
            bar_accidentals.clear()
            if ending:
                items.append(_Item("ending", numbers=ending.group(1).split(",")))
                i += len(ending.group(0))
            continue
        if c == "(" and i + 1 < len(body) and body[i + 1].isdigit():
            match = re.match(r"\((\d)(?::(\d?))?(?::(\d?))?", body[i:])
            p = int(match.group(1))
            q = int(match.group(2)) if match.group(2) else {2: 3, 3: 2, 4: 3, 6: 2}.get(p, 2)
            r = int(match.group(3)) if match.group(3) else p
            tuplet = [Fraction(q, p), r]
            i += len(match.group(0))
            continue
        if c in "()":
            i += 1
            continue
        if c == "-":
            pending_tie = True
            i += 1
            continue
        if c in "<>":
            match = re.match(r"(<+|>+)", body[i:])
            count = len(match.group(0))
            previous = next(item for item in reversed(items) if item.kind in ("note", "rest"))
            factor = Fraction(1, 2**count)
            if c == ">":
                previous.length *= 2 - factor
                broken = factor
            else:
                previous.length *= factor
                broken = 2 - factor
            i += count
            continue
        if c in "zx":
            match = re.match(r"[zx]([\d/]*)", body[i:])
            item = _Item("rest")
            add_length(item, parse_length(match.group(1)))
            items.append(item)
            i += len(match.group(0))
            continue
        if c == "Z":
            match = re.match(r"Z(\d*)", body[i:])
            bars = int(match.group(1)) if match.group(1) else 1
            items.append(_Item("rest", length=meter * bars))
            i += len(match.group(0))
            continue
        if c == "[":
            end = body.index("]", i)
            pitches = [pitch_of(*m.groups()) for m in note.finditer(body[i + 1 : end])]
            match = re.match(r"[\d/]*", body[end + 1 :])
            item = _Item("note", pitches=pitches, tie=pending_tie)
            pending_tie = False
            add_length(item, parse_length(match.group(0)))
            items.append(item)
            i = end + 1 + len(match.group(0))
            continue
        match = note.match(body, i)
        if match:
            pitches = [pitch_of(*match.groups())]
            i = match.end()
            length = re.match(r"[\d/]*", body[i:]).group(0)
            item = _Item("note", pitches=pitches, tie=pending_tie)
            pending_tie = False
            add_length(item, parse_length(length))
            items.append(item)
            i += len(length)
            continue
        # Decorations (~ . H L M O P S T u v) and anything else we do not play.
        i += 1
    return items


def _play_out(items: List[_Item]) -> List[_Item]:
    """The items in the order they are played, with the repeats and endings."""
    out: List[_Item] = []
    start = 0
    passes = 1
    i = 0
    skipping = False
    while i < len(items):
        item = items[i]
        if item.kind == "ending":
            skipping = str(passes) not in item.numbers
            i += 1
            continue
        if item.kind == "bar":
            if item.end_repeat and not skipping and passes == 1:
                passes = 2
                out.append(item)
                i = start
                continue
            if item.end_repeat or item.start_repeat or item.final:
                if skipping and item.end_repeat:
                    # The end of a first ending which this pass skips.
                    skipping = False
                    i += 1
                    continue
                skipping = False
                # NOTE (mristin):
                # A repeat without its start goes back to the last double
                # bar line, or to the start of the tune.
                passes = 1
                start = i + 1
            if not skipping:
                out.append(item)
            i += 1
            continue
        if not skipping:
            out.append(item)
        i += 1
    return out


def read(text: str) -> Tune:
    """Read the first tune of the ABC text."""
    headers: Dict[str, str] = {}
    body_lines: List[str] = []
    melody_program = 73
    chord_program = 24
    drone_program = 19
    in_body = False
    for line in text.splitlines():
        stripped = line.strip()
        directive = re.match(r"%%MIDI\s+(program|chordprog|droneprog)\s+(\d+)", stripped)
        if directive:
            if directive.group(1) == "program":
                melody_program = int(directive.group(2))
            elif directive.group(1) == "chordprog":
                chord_program = int(directive.group(2))
            else:
                drone_program = int(directive.group(2))
            continue
        if stripped.startswith("%") or not stripped:
            continue
        field = re.match(r"([A-Za-z]):(.*)", stripped)
        if field and (not in_body or field.group(1) in "KLMQ" and len(stripped) > 2):
            key, value = field.group(1), field.group(2).strip()
            if in_body and key in "KLMQ":
                body_lines.append(f"[{key}:{value}]")
                continue
            if key in ("w", "W"):
                continue
            headers.setdefault(key, value)
            if key == "K":
                in_body = True
            continue
        if field and field.group(1) in ("w", "W"):
            continue
        if in_body:
            body_lines.append(re.sub(r"%.*", "", line))

    meter = parse_meter(headers.get("M", "4/4"))
    unit = (
        parse_fraction(headers["L"])
        if "L" in headers
        else (Fraction(1, 16) if meter < Fraction(3, 4) else Fraction(1, 8))
    )
    bpm = parse_tempo(headers["Q"], unit) if "Q" in headers else 100.0
    items = _play_out(_tokens(" ".join(body_lines), unit, key_signature(headers["K"]), meter))

    melody = midi.Part("Melody", melody_program)
    chords = midi.Part("Chords", chord_program)
    tempi: List[Tuple[int, float]] = [(0, bpm)]
    whole = 4 * midi.TICKS
    tick = Fraction(0)
    guitar: Optional[_Item] = None
    chord_started = False
    last_notes: List[int] = []
    bars: List[int] = []

    def strike() -> None:
        # The root low, and the chord above it, held for a bar at most.
        root = 48 + guitar.root if guitar.root < 7 else 36 + guitar.root
        voicing = [root] + [60 + guitar.root % 12 + interval for interval in guitar.intervals]
        for pitch in voicing:
            chords.notes.append((int(tick * whole), int(meter * whole), pitch, 55))

    for item in items:
        if item.kind == "tempo":
            tempi.append((int(tick * whole), item.bpm))
        elif item.kind == "meter":
            meter = item.meter
        elif item.kind == "guitar":
            guitar = item
            strike()
            chord_started = True
        elif item.kind == "bar":
            bars.append(int(tick * whole))
            chord_started = False
        elif item.kind in ("note", "rest"):
            if item.kind == "note" and guitar is not None and not chord_started:
                strike()
                chord_started = True
            if item.kind == "note":
                if item.tie and last_notes:
                    for index in last_notes:
                        s, length, p, v = melody.notes[index]
                        melody.notes[index] = (s, length + int(item.length * whole), p, v)
                else:
                    last_notes = []
                    for pitch in item.pitches:
                        melody.notes.append(
                            (int(tick * whole), int(item.length * whole), pitch, 90)
                        )
                        last_notes.append(len(melody.notes) - 1)
            else:
                last_notes = []
            tick += item.length
    # Trim the chords which ring past the end.
    end = int(tick * whole)
    chords.notes = [(s, min(length, end - s), p, v) for s, length, p, v in chords.notes if s < end]
    parts = [melody] + ([chords] if chords.notes else [])
    if not chords.notes:
        parts.append(_drone(headers["K"], bars, end, drone_program))
    return Tune(parts, tempi)


def _drone(key: str, bars: List[int], end: int, program: int) -> midi.Part:
    """A tune without chords gets a soft drone on its tonic and fifth, struck
    anew at each bar, as a bagpipe or a hurdy-gurdy would play along."""
    drone = midi.Part("Drone", program)
    match = re.match(r"\s*([A-G])([#b]?)", key)
    if match is None:
        return drone
    tonic = STEPS[match.group(1)] + {"#": 1, "b": -1, "": 0}[match.group(2)]
    root = 48 + tonic if tonic < 7 else 36 + tonic
    starts = sorted({tick for tick in bars if tick < end})
    for start, stop in zip(starts, starts[1:] + [end]):
        for pitch in (root, root + 7):
            drone.notes.append((start, stop - start, pitch, 45))
    return drone
