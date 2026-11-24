"""
Read and write Standard MIDI files: just the notes, their instruments (the
General MIDI programs) and the tempo map, which is all the music of the game
needs.
"""

import bisect
import pathlib
import struct
from typing import Dict, Final, List, Optional, Tuple

# The ticks per quarter note of the files we write.
TICKS: Final[int] = 480


class Note:
    """A note, in seconds; the track is its part in the file (0, 1, ...)."""

    def __init__(
        self,
        track: int,
        channel: int,
        program: int,
        pitch: int,
        velocity: int,
        start: float,
        end: float,
    ) -> None:
        self.track = track
        self.channel = channel
        self.program = program
        self.pitch = pitch
        self.velocity = velocity
        self.start = start
        self.end = end


class Song:
    """The notes of a MIDI file, the names of its tracks, and its length in
    seconds."""

    def __init__(self, notes: List[Note], track_names: List[str], length: float) -> None:
        self.notes = notes
        self.track_names = track_names
        self.length = length


class TempoMap:
    """Turns ticks into seconds, over the changes of the tempo."""

    def __init__(self, division: int, changes: List[Tuple[int, int]]) -> None:
        # NOTE (mristin):
        # The changes are (tick, microseconds per quarter note); the default
        # tempo is 120 quarters per minute.
        self.division = division
        changes = sorted(changes)
        if not changes or changes[0][0] != 0:
            changes.insert(0, (0, 500_000))
        self.ticks: List[int] = []
        self.micros: List[int] = []
        self.seconds: List[float] = []
        elapsed = 0.0
        for tick, micros in changes:
            if self.ticks:
                elapsed += (tick - self.ticks[-1]) * self.micros[-1] / 1e6 / division
                if tick == self.ticks[-1]:
                    self.micros[-1] = micros
                    continue
            self.ticks.append(tick)
            self.micros.append(micros)
            self.seconds.append(elapsed)

    def time(self, tick: int) -> float:
        i = bisect.bisect_right(self.ticks, tick) - 1
        return self.seconds[i] + (tick - self.ticks[i]) * self.micros[i] / 1e6 / self.division


def _variable(data: bytes, at: int) -> Tuple[int, int]:
    """Read a variable-length quantity; return it and the position after it."""
    value = 0
    while True:
        byte = data[at]
        at += 1
        value = (value << 7) | (byte & 0x7F)
        if byte < 0x80:
            return value, at


def read(path: pathlib.Path) -> Song:
    """Read the notes of the MIDI file (format 0 or 1)."""
    data = path.read_bytes()
    if data[:4] != b"MThd":
        raise ValueError(f"{path} is no MIDI file")
    _, track_count, division = struct.unpack(">HHH", data[8:14])
    if division & 0x8000:
        raise ValueError(f"{path} counts in SMPTE frames, which we do not read")

    # (tick, order, track, kind, channel, a, b); the order puts the program
    # changes before the notes, and the ends of notes before their starts.
    events: List[Tuple[int, int, int, str, int, int, int]] = []
    tempo_changes: List[Tuple[int, int]] = []
    track_names: List[str] = []
    last_tick = 0
    at = 14
    for track in range(track_count):
        if data[at : at + 4] != b"MTrk":
            raise ValueError(f"Expected a track at {at} in {path}")
        (size,) = struct.unpack(">I", data[at + 4 : at + 8])
        cursor = at + 8
        end = cursor + size
        at = end
        tick = 0
        status = 0
        name = ""
        while cursor < end:
            delta, cursor = _variable(data, cursor)
            tick += delta
            byte = data[cursor]
            if byte == 0xFF:
                kind = data[cursor + 1]
                length, cursor = _variable(data, cursor + 2)
                if kind == 0x51:
                    tempo_changes.append((tick, int.from_bytes(data[cursor : cursor + 3], "big")))
                elif kind == 0x03 and not name:
                    name = data[cursor : cursor + length].decode("latin-1").strip("\0 ")
                cursor += length
                continue
            if byte in (0xF0, 0xF7):
                length, cursor = _variable(data, cursor + 1)
                cursor += length
                continue
            if byte & 0x80:
                status = byte
                cursor += 1
            high = status & 0xF0
            channel = status & 0x0F
            if high in (0xC0, 0xD0):
                if high == 0xC0:
                    events.append((tick, 0, track, "program", channel, data[cursor], 0))
                cursor += 1
                continue
            a, b = data[cursor], data[cursor + 1]
            cursor += 2
            if high == 0x90 and b > 0:
                events.append((tick, 2, track, "on", channel, a, b))
            elif high == 0x80 or (high == 0x90 and b == 0):
                events.append((tick, 1, track, "off", channel, a, 0))
        track_names.append(name)
        last_tick = max(last_tick, tick)

    tempo = TempoMap(division, tempo_changes)
    events.sort(key=lambda event: (event[0], event[1]))
    programs = [0] * 16
    started: Dict[Tuple[int, int, int], List[Tuple[int, int, int]]] = {}
    notes: List[Note] = []
    for tick, _, track, kind, channel, a, b in events:
        if kind == "program":
            programs[channel] = a
        elif kind == "on":
            started.setdefault((track, channel, a), []).append((tick, b, programs[channel]))
        else:
            pending = started.get((track, channel, a))
            if pending:
                start, velocity, program = pending.pop(0)
                notes.append(
                    Note(
                        track,
                        channel,
                        program,
                        a,
                        velocity,
                        tempo.time(start),
                        tempo.time(max(tick, start + 1)),
                    )
                )
    notes.sort(key=lambda note: (note.start, note.pitch))
    return Song(notes, track_names, tempo.time(last_tick))


class Part:
    """A part to write: its name, its General MIDI program, and its notes as
    (start tick, length in ticks, pitch, velocity)."""

    def __init__(self, name: str, program: int) -> None:
        self.name = name
        self.program = program
        self.notes: List[Tuple[int, int, int, int]] = []


def _encode_variable(value: int) -> bytes:
    out = [value & 0x7F]
    value >>= 7
    while value:
        out.insert(0, (value & 0x7F) | 0x80)
        value >>= 7
    return bytes(out)


def _track(events: List[Tuple[int, bytes]]) -> bytes:
    body = bytearray()
    tick = 0
    for at, event in sorted(events, key=lambda pair: pair[0]):
        body += _encode_variable(at - tick) + event
        tick = at
    body += _encode_variable(0) + bytes([0xFF, 0x2F, 0])
    return b"MTrk" + struct.pack(">I", len(body)) + bytes(body)


def write(
    path: pathlib.Path,
    parts: List[Part],
    tempo_changes: List[Tuple[int, float]],
    title: str,
    copyright_notice: Optional[str] = None,
) -> None:
    """Write the parts as a MIDI file of the format 1, with [TICKS] per quarter
    note; the tempo changes are (tick, quarters per minute)."""
    conductor: List[Tuple[int, bytes]] = []
    text = title.encode("utf-8")
    conductor.append((0, bytes([0xFF, 0x03]) + _encode_variable(len(text)) + text))
    if copyright_notice:
        notice = copyright_notice.encode("utf-8")
        conductor.append((0, bytes([0xFF, 0x02]) + _encode_variable(len(notice)) + notice))
    for tick, bpm in tempo_changes:
        micros = int(round(60_000_000 / bpm))
        conductor.append((tick, bytes([0xFF, 0x51, 3]) + micros.to_bytes(3, "big")))
    tracks = [_track(conductor)]
    for i, part in enumerate(parts):
        channel = i if i < 9 else i + 1
        events: List[Tuple[int, bytes]] = []
        name = part.name.encode("utf-8")
        events.append((0, bytes([0xFF, 0x03]) + _encode_variable(len(name)) + name))
        events.append((0, bytes([0xC0 | channel, part.program])))
        # NOTE (mristin):
        # The ends come before the starts at the same tick (the 0 and 1 in the
        # key of the sort), so that repeated notes do not swallow each other.
        timed: List[Tuple[int, int, bytes]] = []
        for start, length, pitch, velocity in part.notes:
            timed.append((start, 1, bytes([0x90 | channel, pitch, velocity])))
            timed.append((start + max(1, length), 0, bytes([0x80 | channel, pitch, 0])))
        timed.sort(key=lambda event: (event[0], event[1]))
        events += [(at, event) for at, _, event in timed]
        tracks.append(_track(events))
    header = b"MThd" + struct.pack(">IHHH", 6, 1, len(tracks), TICKS)
    path.write_bytes(header + b"".join(tracks))
