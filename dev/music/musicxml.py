"""
Convert a MusicXML score (.musicxml, or compressed .mxl) into MIDI parts: the
notes of each part with their ticks, the ties joined, the grace notes left
out, the simple repeats and the first and second endings played out.
"""

import io
import pathlib
import xml.etree.ElementTree as ElementTree
import zipfile
from typing import Dict, List, Optional, Tuple

import midi

STEPS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def _root(path: pathlib.Path) -> ElementTree.Element:
    data = path.read_bytes()
    if data[:2] == b"PK":
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            container = ElementTree.fromstring(archive.read("META-INF/container.xml"))
            rootfile = next(
                element for element in container.iter() if element.tag.endswith("rootfile")
            )
            data = archive.read(rootfile.attrib["full-path"])
    return ElementTree.fromstring(data)


def _order(measures: List[ElementTree.Element]) -> List[int]:
    """The indices of the measures in the order they are played, with the
    repeats and the endings played out (no nested repeats)."""
    order: List[int] = []
    start = 0
    passes: Dict[int, int] = {}
    i = 0
    while i < len(measures):
        measure = measures[i]
        ending: Optional[List[str]] = None
        backward = False
        for barline in measure.findall("barline"):
            repeat = barline.find("repeat")
            if repeat is not None and repeat.attrib.get("direction") == "forward":
                start = i
            if repeat is not None and repeat.attrib.get("direction") == "backward":
                backward = True
            element = barline.find("ending")
            if element is not None and element.attrib.get("type") == "start":
                ending = element.attrib.get("number", "1").replace(" ", "").split(",")
        current_pass = passes.get(start, 1)
        if ending is not None and str(current_pass) not in ending:
            i += 1
            continue
        order.append(i)
        times = int(measure.find("barline/repeat").attrib.get("times", "2")) if backward else 0
        if backward and current_pass < times:
            passes[start] = current_pass + 1
            i = start
            continue
        if backward:
            passes[start] = 1
            start = i + 1
        i += 1
    return order


def read(path: pathlib.Path, programs: Dict[str, int]) -> Tuple[List[midi.Part], list]:
    """The parts of the score (named as in its part list, with the programs
    given by those names, else a piano) and the tempo changes as (tick,
    quarters per minute)."""
    root = _root(path)
    names = {
        part.attrib["id"]: (part.findtext("part-name") or part.attrib["id"]).strip()
        for part in root.iter("score-part")
    }
    parts: List[midi.Part] = []
    tempi: Dict[int, float] = {}
    for element in root.findall("part"):
        name = names.get(element.attrib["id"], element.attrib["id"])
        part = midi.Part(name, programs.get(name, 0))
        measures = element.findall("measure")
        divisions = 1
        tick = 0
        # The notes which a tie carries on: pitch -> index in part.notes.
        tied: Dict[int, int] = {}
        for index in _order(measures):
            measure = measures[index]
            measure_start = tick
            cursor = tick
            longest = tick
            last_start = tick
            for child in measure:
                if child.tag == "attributes":
                    text = child.findtext("divisions")
                    if text:
                        divisions = int(text)
                elif child.tag == "sound" or child.tag == "direction":
                    sound = child if child.tag == "sound" else child.find("sound")
                    if sound is not None and "tempo" in sound.attrib:
                        tempi[cursor] = float(sound.attrib["tempo"])
                elif child.tag in ("backup", "forward"):
                    length = int(child.findtext("duration", "0")) * midi.TICKS // divisions
                    cursor += -length if child.tag == "backup" else length
                elif child.tag == "note":
                    if child.find("grace") is not None:
                        continue
                    length = int(child.findtext("duration", "0")) * midi.TICKS // divisions
                    start = last_start if child.find("chord") is not None else cursor
                    pitch_element = child.find("pitch")
                    if pitch_element is not None:
                        pitch = (
                            12 * (int(pitch_element.findtext("octave")) + 1)
                            + STEPS[pitch_element.findtext("step")]
                            + int(float(pitch_element.findtext("alter", "0")))
                        )
                        ties = {tie.attrib.get("type") for tie in child.findall("tie")}
                        if "stop" in ties and pitch in tied:
                            at = tied.pop(pitch)
                            s, _, p, v = part.notes[at]
                            part.notes[at] = (s, start + length - s, p, v)
                            if "start" in ties:
                                tied[pitch] = at
                        else:
                            part.notes.append((start, length, pitch, 80))
                            if "start" in ties:
                                tied[pitch] = len(part.notes) - 1
                    if child.find("chord") is None:
                        last_start = cursor
                        cursor += length
                longest = max(longest, cursor)
            tick = max(longest, measure_start)
        parts.append(part)
    tempo_changes = sorted(tempi.items()) or [(0, 100.0)]
    return parts, tempo_changes
