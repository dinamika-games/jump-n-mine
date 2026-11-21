#!/usr/bin/env python3
"""
Write the sketch of the sheet of Queen Treacher's evil miner (an SVG, and a PNG
next to it if Inkscape is there), to attach to the prompt in
dev/pictures/prompts/moles_and_rival.md.

The sheet has the 16 poses which the game draws (see ``Art.dwarf``), on a grid
of 4 x 4 cells of 640 x 600 px, the feet on the same baseline in every cell,
facing right. Each cell is labelled with the file name of its pose; the labels
are for the image generator only.

    python3 dev/pictures/intro/make_evil_miner_sheet.py <output folder>
"""

import argparse
import math
import pathlib
import shutil
import subprocess
import sys
from typing import Final, List, Optional, Sequence, Tuple

OUTLINE: Final[str] = "#1a1016"
TUNIC: Final[str] = "#3a2a48"
BEARD: Final[str] = "#8a8a94"
SKIN: Final[str] = "#e0bca0"
HELMET: Final[str] = "#232028"
STEEL: Final[str] = "#b9c3cf"
WOOD: Final[str] = "#8a5a32"
BOOTS: Final[str] = "#4a3426"

CELL_WIDTH: Final[int] = 640
CELL_HEIGHT: Final[int] = 600
COLUMNS: Final[int] = 4

#: Where the feet stand in a cell, from its top left corner.
FEET: Final[Tuple[int, int]] = (320, 560)


class Pose:
    """A pose of the evil miner on the sheet."""

    #: The name of the pose, and of its picture (``<name>.png``).
    name: Final[str]

    #: Where the left and the right foot stand, along the ground (in px).
    feet: Final[Tuple[float, float]]

    #: How high the left and the right foot are lifted (in px).
    lifts: Final[Tuple[float, float]]

    #: Where the hands hold the pickaxe, from the feet (in px, y up is negative).
    hands: Final[Tuple[float, float]]

    #: Where the pickaxe points from the hands, in degrees (0 to the right,
    #: -90 up, 90 down); its head is at that end.
    pick: Final[float]

    #: How far the body leans forward, in degrees.
    lean: Final[float]

    #: What else the pose shows: "stars", "water", "crumbs", "arc", "impact".
    extras: Final[Sequence[str]]

    def __init__(
        self,
        name: str,
        hands: Tuple[float, float],
        pick: float,
        feet: Tuple[float, float] = (-24.0, 24.0),
        lifts: Tuple[float, float] = (0.0, 0.0),
        lean: float = 0.0,
        extras: Sequence[str] = (),
    ) -> None:
        """Initialize with the given values."""
        self.name = name
        self.hands = hands
        self.pick = pick
        self.feet = feet
        self.lifts = lifts
        self.lean = lean
        self.extras = extras


def _walk(step: int) -> Pose:
    """Return the frame of the walk cycle (1 to 6)."""
    phase = (step - 1) / 6.0 * 2.0 * math.pi
    stride = 32.0 * math.sin(phase)
    lift = 22.0 * max(0.0, math.cos(phase))
    other = 22.0 * max(0.0, -math.cos(phase))
    return Pose(
        f"walk_{step}",
        hands=(55.0, -100.0),
        pick=-45.0,
        feet=(-stride, stride),
        lifts=(lift, other),
        lean=6.0,
    )


#: The poses, in the order of the cells (row by row).
POSES: Final[List[Pose]] = [
    Pose("idle", hands=(55.0, -100.0), pick=-45.0),
    _walk(1),
    _walk(2),
    _walk(3),
    _walk(4),
    _walk(5),
    _walk(6),
    Pose("raised", hands=(12.0, -262.0), pick=-125.0),
    Pose("swing", hands=(46.0, -205.0), pick=-25.0, lean=8.0, extras=["arc"]),
    Pose("hit_down", hands=(70.0, -120.0), pick=55.0, lean=16.0, extras=["crumbs"]),
    Pose(
        "hit_down_b",
        hands=(80.0, -115.0),
        pick=70.0,
        lean=20.0,
        extras=["crumbs", "impact"],
    ),
    Pose("dizzy", hands=(40.0, -120.0), pick=105.0, extras=["stars"]),
    Pose("under_water", hands=(55.0, -100.0), pick=-45.0, extras=["water"]),
    Pose("side_back", hands=(-28.0, -205.0), pick=-130.0, lean=-6.0),
    Pose("side_hit", hands=(84.0, -140.0), pick=0.0, lean=10.0, extras=["impact"]),
    Pose("side_recoil", hands=(64.0, -126.0), pick=22.0, lean=4.0, extras=["crumbs"]),
]


def _pickaxe(hands: Tuple[float, float], angle: float) -> str:
    """Draw the pickaxe held at the hands, pointing at the angle."""
    a = math.radians(angle)
    direction = (math.cos(a), math.sin(a))
    normal = (-direction[1], direction[0])
    start = (hands[0] - direction[0] * 28, hands[1] - direction[1] * 28)
    end = (hands[0] + direction[0] * 110, hands[1] + direction[1] * 110)
    head = []
    for t in (-1.0, -0.5, 0.0, 0.5, 1.0):
        bend = -14.0 * (1.0 - t * t)
        head.append(
            (
                end[0] + normal[0] * 62 * t + direction[0] * bend,
                end[1] + normal[1] * 62 * t + direction[1] * bend,
            )
        )
    head_path = " ".join(f"{x:.1f},{y:.1f}" for x, y in head)
    return (
        f'<line x1="{start[0]:.1f}" y1="{start[1]:.1f}" x2="{end[0]:.1f}" y2="{end[1]:.1f}" '
        f'stroke="{OUTLINE}" stroke-width="18" stroke-linecap="round"/>'
        f'<line x1="{start[0]:.1f}" y1="{start[1]:.1f}" x2="{end[0]:.1f}" y2="{end[1]:.1f}" '
        f'stroke="{WOOD}" stroke-width="10" stroke-linecap="round"/>'
        f'<polyline points="{head_path}" fill="none" stroke="{OUTLINE}" stroke-width="22" '
        f'stroke-linecap="round"/>'
        f'<polyline points="{head_path}" fill="none" stroke="{STEEL}" stroke-width="13" '
        f'stroke-linecap="round"/>'
        f'<circle cx="{hands[0]:.1f}" cy="{hands[1]:.1f}" r="15" fill="{SKIN}" '
        f'stroke="{OUTLINE}" stroke-width="5"/>'
    )


def _miner(pose: Pose) -> str:
    """Draw the evil miner in the pose, with his feet at (0, 0)."""
    parts: List[str] = ['<ellipse cx="0" cy="4" rx="80" ry="12" fill="#000" opacity="0.2"/>']
    for x, lift in zip(pose.feet, pose.lifts):
        parts.append(
            f'<line x1="{x * 0.5:.1f}" y1="-70" x2="{x:.1f}" y2="{-20 - lift:.1f}" '
            f'stroke="{OUTLINE}" stroke-width="34" stroke-linecap="round"/>'
            f'<line x1="{x * 0.5:.1f}" y1="-70" x2="{x:.1f}" y2="{-20 - lift:.1f}" '
            f'stroke="{TUNIC}" stroke-width="24" stroke-linecap="round"/>'
            f'<rect x="{x - 26:.1f}" y="{-34 - lift:.1f}" width="56" height="34" rx="12" '
            f'fill="{BOOTS}" stroke="{OUTLINE}" stroke-width="5"/>'
        )
    body = (
        f'<g transform="rotate({pose.lean} 0 -60)">'
        f'<path d="M-62,-62 Q-74,-178 0,-182 Q74,-178 62,-62 Z" fill="{TUNIC}" '
        f'stroke="{OUTLINE}" stroke-width="6"/>'
        f'<rect x="-64" y="-84" width="128" height="18" fill="#2a1a14" stroke="{OUTLINE}" '
        f'stroke-width="4"/>'
        f'<circle cx="18" cy="-112" r="20" fill="#6a2a8a" stroke="{OUTLINE}" stroke-width="5"/>'
        f'<polygon points="6,-105 6,-121 12,-113 18,-126 24,-113 30,-121 30,-105" fill="#141018"/>'
        f'<circle cx="14" cy="-218" r="48" fill="{SKIN}" stroke="{OUTLINE}" stroke-width="6"/>'
        f'<path d="M-30,-212 Q-38,-140 14,-134 Q62,-142 58,-212 Q36,-196 14,-198 '
        f'Q-8,-196 -30,-212 Z" fill="{BEARD}" stroke="{OUTLINE}" stroke-width="5"/>'
        f'<ellipse cx="48" cy="-214" rx="13" ry="10" fill="#d89a80" stroke="{OUTLINE}" '
        f'stroke-width="4"/>'
    )
    if "stars" in pose.extras:
        body += f'<path d="M22,-238 l12,12 M34,-238 l-12,12" stroke="{OUTLINE}" stroke-width="5"/>'
    else:
        body += (
            f'<circle cx="30" cy="-230" r="6" fill="{OUTLINE}"/>'
            f'<path d="M18,-246 L42,-240" stroke="{OUTLINE}" stroke-width="7" '
            f'stroke-linecap="round"/>'
        )
    body += (
        f'<path d="M-36,-236 Q14,-300 64,-236 Z" fill="{HELMET}" stroke="{OUTLINE}" '
        f'stroke-width="6"/>'
        f'<rect x="-44" y="-244" width="116" height="16" rx="7" fill="{HELMET}" '
        f'stroke="{OUTLINE}" stroke-width="5"/>'
        "</g>"
    )
    parts.append(body)
    parts.append(_pickaxe(pose.hands, pose.pick))
    if "stars" in pose.extras:
        for k in range(3):
            angle = k * 2.0 * math.pi / 3.0
            x = 14 + 70 * math.cos(angle)
            y = -300 + 16 * math.sin(angle)
            parts.append(_star(x, y, 18))
    if "water" in pose.extras:
        parts.append(
            '<rect x="-120" y="-170" width="240" height="190" rx="20" fill="#3f8ee8" '
            'opacity="0.45"/>'
            '<path d="M-120,-170 Q-60,-185 0,-170 T120,-170" fill="none" stroke="#cfe8ff" '
            'stroke-width="6"/>'
        )
        for x, y, r in ((60, -260, 10), (80, -300, 7), (44, -330, 5)):
            parts.append(
                f'<circle cx="{x}" cy="{y}" r="{r}" fill="none" stroke="#8fd0ff" stroke-width="4"/>'
            )
    if "crumbs" in pose.extras:
        for x, y in ((150, -10), (170, -40), (130, -50), (185, -15)):
            parts.append(
                f'<rect x="{x}" y="{y}" width="14" height="12" rx="3" fill="#d99a52" '
                f'stroke="{OUTLINE}" stroke-width="3"/>'
            )
    if "impact" in pose.extras:
        end_x = pose.hands[0] + 110 * math.cos(math.radians(pose.pick))
        end_y = pose.hands[1] + 110 * math.sin(math.radians(pose.pick))
        for k in range(-2, 3):
            a = math.radians(pose.pick + k * 25)
            parts.append(
                f'<line x1="{end_x + 50 * math.cos(a):.1f}" y1="{end_y + 50 * math.sin(a):.1f}" '
                f'x2="{end_x + 80 * math.cos(a):.1f}" y2="{end_y + 80 * math.sin(a):.1f}" '
                f'stroke="#ffb020" stroke-width="6" stroke-linecap="round"/>'
            )
    if "arc" in pose.extras:
        parts.append(
            '<path d="M-40,-330 Q120,-330 190,-180" fill="none" stroke="#8fb8ff" '
            'stroke-width="8" opacity="0.7"/>'
        )
    return "\n".join(parts)


def _star(x: float, y: float, size: float) -> str:
    """Draw a yellow star with its middle at (x, y)."""
    points = []
    for k in range(10):
        r = size if k % 2 == 0 else size * 0.45
        a = -math.pi / 2 + k * math.pi / 5
        points.append(f"{x + r * math.cos(a):.1f},{y + r * math.sin(a):.1f}")
    return (
        f'<polygon points="{" ".join(points)}" fill="#ffe066" stroke="{OUTLINE}" stroke-width="3"/>'
    )


def sheet() -> str:
    """Return the SVG of the whole sheet."""
    rows = (len(POSES) + COLUMNS - 1) // COLUMNS
    width = CELL_WIDTH * COLUMNS
    height = CELL_HEIGHT * rows
    cells: List[str] = []
    for i, pose in enumerate(POSES):
        x = (i % COLUMNS) * CELL_WIDTH
        y = (i // COLUMNS) * CELL_HEIGHT
        cells.append(
            f'<rect x="{x}" y="{y}" width="{CELL_WIDTH}" height="{CELL_HEIGHT}" fill="none" '
            f'stroke="#9a90a8" stroke-width="2" stroke-dasharray="12 10"/>'
            f'<line x1="{x + 20}" y1="{y + FEET[1]}" x2="{x + CELL_WIDTH - 20}" y2="{y + FEET[1]}" '
            f'stroke="#c8b8d8" stroke-width="2" stroke-dasharray="4 8"/>'
            f'<text x="{x + 16}" y="{y + 34}" font-family="sans-serif" font-size="26" '
            f'fill="#5a5068">{i + 1}. {pose.name}</text>'
            f'<g transform="translate({x + FEET[0]},{y + FEET[1]})">{_miner(pose)}</g>'
        )
    body = "\n".join(cells)
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}">\n'
        f'<rect width="{width}" height="{height}" fill="#f4f0f8"/>\n{body}\n</svg>\n'
    )


def main(argv: Optional[Sequence[str]] = None) -> int:
    """Execute the main routine."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", help="the folder to write the sketch to")
    args = parser.parse_args(argv)

    output = pathlib.Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    path = output / "sketch_evil_miner_sheet.svg"
    path.write_text(sheet(), encoding="utf-8")
    print(f"Wrote {path}")

    inkscape = shutil.which("inkscape")
    if inkscape is None:
        print("Inkscape is not installed, so we wrote no PNG of the sketch; the SVG is enough.")
        return 0
    png = path.with_suffix(".png")
    subprocess.run(
        [inkscape, str(path), "--export-type=png", f"--export-filename={png}"],
        check=True,
        capture_output=True,
    )
    print(f"Wrote {png}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
