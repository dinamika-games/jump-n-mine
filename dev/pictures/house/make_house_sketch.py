#!/usr/bin/env python3
"""
Write the sketches of the dwarves' house (SVGs, and PNGs next to them if Inkscape
is there), to attach to the prompts in dev/pictures/prompts/house.md.

``sketch_house_base`` follows the stage of ``HouseArt`` (scenes/house/house_art.gd), 1200 x
520, drawn at twice the size (2400 x 1040): the meadow, the hill of the mine,
and the shack of grey planks in the middle. The dashed areas are where the
improvements will come later (see ``Economy.HOUSE_PARTS``); the painter keeps
them free.

``sketch_walls_sheet`` lays out the sheet of the six stages of the walls (the
planks of the painted shack, and the five stages which the players build): the
front wall of each in the same box, the openings of the windows and the door
(which are laid over the wall) dotted. ``sketch_roof_sheet`` lays out the six
stages of the roof the same way, its eaves on the baseline, with the walls under
it dotted, and ``sketch_door_sheet`` the six stages of the door in narrower
cells. The labels are for the image generator only.

    python3 dev/pictures/house/make_house_sketch.py <output folder>
"""

import argparse
import pathlib
import shutil
import subprocess
import sys
from typing import Callable, Final, List, Optional, Sequence

OUTLINE: Final[str] = "#1a1016"
SKY: Final[str] = "#9fd2f0"
SUN: Final[str] = "#fff2b0"
HILL_NEAR: Final[str] = "#79b85a"
HILL_FAR: Final[str] = "#6aa84e"
MEADOW: Final[str] = "#5c9c45"
EARTH: Final[str] = "#9a7a56"
EARTH_DARK: Final[str] = "#8a6a4a"
HOLE: Final[str] = "#1b1218"
PLANK: Final[str] = "#8c8378"
PLANK_DARK: Final[str] = "#6e665c"
ROOF: Final[str] = "#7a7268"
DOOR: Final[str] = "#6a5a4a"
PATH: Final[str] = "#c8b48a"
ZONE: Final[str] = "#c0306a"

#: How much bigger the sketch is than the stage of ``HouseArt``.
SCALE: Final[int] = 2

#: The stage of ``HouseArt``, and where the ground is on it.
WIDTH: Final[int] = 1200
HEIGHT: Final[int] = 520
GROUND: Final[int] = 440


class Zone:
    """An area which the painter keeps free for later improvements."""

    #: The label of the zone (for the image generator only).
    label: Final[str]

    #: The left, the top, the width and the height of the zone on the stage.
    x: Final[float]
    y: Final[float]
    width: Final[float]
    height: Final[float]

    def __init__(self, label: str, x: float, y: float, width: float, height: float) -> None:
        self.label = label
        self.x = x
        self.y = y
        self.width = width
        self.height = height


ZONES: Final[Sequence[Zone]] = (
    Zone("TOWER (later)", 800, 20, 120, 420),
    Zone("VILLAGE SQUARE (later)", 975, 250, 215, 255),
    Zone("GARDEN (later)", 255, 415, 150, 95),
    Zone("FENCE (later)", 415, 470, 370, 40),
    Zone("CHIMNEY", 680, 140, 90, 70),
)


def _scaled(value: float) -> str:
    return f"{value * SCALE:g}"


def _rect(x: float, y: float, width: float, height: float, fill: str, extra: str = "") -> str:
    return (
        f'<rect x="{_scaled(x)}" y="{_scaled(y)}" width="{_scaled(width)}" '
        f'height="{_scaled(height)}" fill="{fill}" stroke="{OUTLINE}" '
        f'stroke-width="{4 * SCALE}" {extra}/>'
    )


def _polygon(points: Sequence[Sequence[float]], fill: str) -> str:
    joined = " ".join(f"{_scaled(x)},{_scaled(y)}" for x, y in points)
    return (
        f'<polygon points="{joined}" fill="{fill}" stroke="{OUTLINE}" '
        f'stroke-width="{4 * SCALE}" stroke-linejoin="round"/>'
    )


def _line(x1: float, y1: float, x2: float, y2: float, color: str, width: float) -> str:
    return (
        f'<line x1="{_scaled(x1)}" y1="{_scaled(y1)}" x2="{_scaled(x2)}" y2="{_scaled(y2)}" '
        f'stroke="{color}" stroke-width="{width * SCALE:g}" stroke-linecap="round"/>'
    )


def _ellipse(cx: float, cy: float, rx: float, ry: float, fill: str) -> str:
    return (
        f'<ellipse cx="{_scaled(cx)}" cy="{_scaled(cy)}" rx="{_scaled(rx)}" '
        f'ry="{_scaled(ry)}" fill="{fill}"/>'
    )


def _text(x: float, y: float, text: str, size: float, color: str = ZONE) -> str:
    return (
        f'<text x="{_scaled(x)}" y="{_scaled(y)}" font-family="sans-serif" '
        f'font-weight="bold" font-size="{_scaled(size)}" fill="{color}" '
        f'text-anchor="middle">{text}</text>'
    )


def _landscape() -> List[str]:
    """The sky, the hills, the meadow and the hill of the mine."""
    parts = [
        f'<rect width="{WIDTH * SCALE}" height="{HEIGHT * SCALE}" fill="{SKY}"/>',
        f'<circle cx="{_scaled(1080)}" cy="{_scaled(80)}" r="{_scaled(42)}" fill="{SUN}"/>',
        _ellipse(300, GROUND + 30, 420, 120, HILL_NEAR),
        _ellipse(950, GROUND + 40, 480, 110, HILL_FAR),
        f'<rect y="{_scaled(GROUND)}" width="{WIDTH * SCALE}" '
        f'height="{_scaled(HEIGHT - GROUND)}" fill="{MEADOW}"/>',
        # The path from the door to the bottom of the picture.
        _polygon([(570, GROUND), (630, GROUND), (680, HEIGHT), (520, HEIGHT)], PATH),
        # The hill of the mine, with its dark hole.
        _ellipse(150, GROUND, 170, 150, EARTH_DARK),
        _ellipse(150, GROUND, 150, 132, EARTH),
        _ellipse(150, GROUND - 70, 52, 60, HOLE),
        f'<rect x="{_scaled(98)}" y="{_scaled(GROUND - 70)}" width="{_scaled(104)}" '
        f'height="{_scaled(70)}" fill="{HOLE}"/>',
    ]
    return parts


def _shack() -> List[str]:
    """The shack of grey planks: the walls, the roof, two window holes and a door."""
    parts = [_rect(420, 260, 360, GROUND - 260, PLANK)]
    for x in range(450, 780, 45):
        parts.append(_line(x, 264, x, GROUND - 4, PLANK_DARK, 3))
    parts.append(_polygon([(392, 268), (808, 268), (600, 120)], ROOF))
    for k in range(1, 5):
        y = 120 + k * 30
        half = (y - 120) / 148 * 208
        parts.append(_line(600 - half + 6, y, 600 + half - 6, y, PLANK_DARK, 3))
    parts.append(_polygon([(530, 210), (575, 205), (578, 240), (532, 243)], PLANK_DARK))
    for x in (448, 678):
        parts.append(_rect(x, 300, 74, 70, HOLE))
    parts.append(_rect(563, 340, 72, 100, DOOR))
    for x in (581, 599, 617):
        parts.append(_line(x, 344, x, GROUND - 4, OUTLINE, 2))
    return parts


def _zones() -> List[str]:
    """The dashed areas which stay free for the later improvements."""
    parts = []
    for zone in ZONES:
        parts.append(
            f'<rect x="{_scaled(zone.x)}" y="{_scaled(zone.y)}" '
            f'width="{_scaled(zone.width)}" height="{_scaled(zone.height)}" '
            f'fill="none" stroke="{ZONE}" stroke-width="{3 * SCALE}" '
            f'stroke-dasharray="{12 * SCALE},{8 * SCALE}"/>'
        )
        size = 15 if zone.width > 140 else 11
        parts.append(_text(zone.x + zone.width / 2, zone.y + zone.height / 2 + 5, zone.label, size))
    parts.append(_text(150, 270, "MINE ENTRANCE (keep as it is)", 15))
    parts.append(_text(600, 100, "THE SHACK", 18))
    parts.append(_text(390, 40, "keep the dashed areas free: plain sky and meadow", 16))
    return parts


def write_svg(path: pathlib.Path) -> None:
    """Write the sketch to the path."""
    body = _landscape() + _shack() + _zones()
    svg = (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH * SCALE}" '
        f'height="{HEIGHT * SCALE}" viewBox="0 0 {WIDTH * SCALE} {HEIGHT * SCALE}">\n'
        + "\n".join(f"  {part}" for part in body)
        + "\n</svg>\n"
    )
    path.write_text(svg, encoding="utf-8")


#: The cells of the sheets of the parts, in px, and how many cells a row has.
CELL_WIDTH: Final[int] = 1000
CELL_HEIGHT: Final[int] = 500
COLUMNS: Final[int] = 3

#: The pieces stand on this line of their cells, 40 px above the bottom.
BASELINE: Final[int] = 460

#: The stages of the walls on their sheet: the planks of the painted shack, and
#: the stages of ``Economy.HOUSE_PARTS``.
WALLS_STAGES: Final[Sequence[str]] = (
    "planks",
    "log_walls",
    "timber_frame",
    "stone_walls",
    "carved_stone",
    "marble_and_gold",
)

#: The stages of the roof on its sheet: the grey boards of the painted shack,
#: and the stages of ``Economy.HOUSE_PARTS``.
ROOF_STAGES: Final[Sequence[str]] = (
    "boards",
    "straw_roof",
    "wooden_shingles",
    "red_tiles",
    "slate_and_dormer",
    "golden_roof",
)


class Box:
    """A rectangle in a cell of a sheet, in px from the top left corner of the cell."""

    x: Final[float]
    y: Final[float]
    width: Final[float]
    height: Final[float]

    def __init__(self, x: float, y: float, width: float, height: float) -> None:
        self.x = x
        self.y = y
        self.width = width
        self.height = height


#: Where the front wall sits in its cell: as wide and high as the walls of the
#: painted shack (595 x 275 px of 1905 x 825) scaled by 800 / 595, standing on the
#: baseline.
WALL: Final[Box] = Box(100, 90, 800, 370)

#: Where the windows and the door will be laid over the wall, in the cell (from
#: the painted shack, scaled like the wall).
WALL_OPENINGS: Final[Sequence[Box]] = (
    Box(177, 153, 154, 156),
    Box(677, 153, 156, 156),
    Box(412, 215, 188, 245),
)

#: The roof in its cell: the roof of the painted shack (679 px wide from eave to
#: eave and 266 px high, over walls of 595 px) scaled by 880 / 679, its eaves on
#: the baseline.
ROOF_BOX: Final[Box] = Box(60, BASELINE - 345, 880, 345)

#: Where the walls stand under the roof, from the left of the cell.
ROOF_WALLS: Final[Sequence[float]] = (122, 893)

#: The stages of the door on its sheet: the rough door of the painted shack, and
#: the stages of ``Economy.HOUSE_PARTS``.
DOOR_STAGES: Final[Sequence[str]] = (
    "shack_door",
    "plank_door",
    "oak_door",
    "iron_bound_door",
    "arched_gate",
    "gem_studded_gate",
)

#: The cells of the sheet of the door are this wide (as high as the others).
DOOR_CELL_WIDTH: Final[int] = 500

#: The door in its cell: as high for its width as the door on the sheet of the
#: walls (188 x 245 px), standing on the baseline.
DOOR_BOX: Final[Box] = Box(112, BASELINE - 360, 276, 360)


def _box_svg(box: Box, dx: float, dy: float, stroke: str, dash: str, fill: str = "none") -> str:
    return (
        f'<rect x="{box.x + dx:g}" y="{box.y + dy:g}" width="{box.width:g}" '
        f'height="{box.height:g}" fill="{fill}" stroke="{stroke}" stroke-width="4" '
        f'stroke-dasharray="{dash}"/>'
    )


def _wall_cell(dx: float, dy: float) -> List[str]:
    """The box of the wall in a cell, with the openings dotted."""
    parts = [_box_svg(WALL, dx, dy, OUTLINE, "16,10", fill="#f2ebe0")]
    for opening in WALL_OPENINGS:
        parts.append(_box_svg(opening, dx, dy, "#a0a0a0", "6,8", fill="#e4e4e4"))
    return parts


def _roof_cell(dx: float, dy: float) -> List[str]:
    """The outline of the roof in a cell, with the tops of the walls under it dotted."""
    left = (dx + ROOF_BOX.x, dy + BASELINE)
    right = (dx + ROOF_BOX.x + ROOF_BOX.width, dy + BASELINE)
    apex = (dx + ROOF_BOX.x + ROOF_BOX.width / 2, dy + ROOF_BOX.y)
    points = " ".join(f"{x:g},{y:g}" for x, y in (left, apex, right))
    parts = [
        f'<polygon points="{points}" fill="#f2ebe0" stroke="{OUTLINE}" stroke-width="4" '
        f'stroke-dasharray="16,10" stroke-linejoin="round"/>'
    ]
    for x in ROOF_WALLS:
        parts.append(
            f'<line x1="{dx + x:g}" y1="{dy + BASELINE:g}" x2="{dx + x:g}" '
            f'y2="{dy + CELL_HEIGHT:g}" stroke="#a0a0a0" stroke-width="4" '
            f'stroke-dasharray="6,8"/>'
        )
    return parts


def _door_cell(dx: float, dy: float) -> List[str]:
    """The box of the door in a cell."""
    return [_box_svg(DOOR_BOX, dx, dy, OUTLINE, "16,10", fill="#f2ebe0")]


def write_sheet_svg(
    path: pathlib.Path,
    stages: Sequence[str],
    cell: Callable[[float, float], List[str]],
    cell_width: int = CELL_WIDTH,
) -> None:
    """Write the sketch of a sheet of the stages to the path, each cell drawn by ``cell``."""
    rows = (len(stages) + COLUMNS - 1) // COLUMNS
    width = cell_width * COLUMNS
    height = CELL_HEIGHT * rows
    body = [f'<rect width="{width}" height="{height}" fill="#ffffff"/>']
    for i, stage in enumerate(stages):
        dx = (i % COLUMNS) * cell_width
        dy = (i // COLUMNS) * CELL_HEIGHT
        body.append(
            f'<rect x="{dx}" y="{dy}" width="{cell_width}" height="{CELL_HEIGHT}" '
            f'fill="none" stroke="#c8c8c8" stroke-width="2"/>'
        )
        body.extend(cell(dx, dy))
        body.append(
            f'<line x1="{dx + 20}" y1="{dy + BASELINE}" x2="{dx + cell_width - 20}" '
            f'y2="{dy + BASELINE}" stroke="{ZONE}" stroke-width="3" stroke-dasharray="4,8"/>'
        )
        body.append(
            f'<text x="{dx + cell_width / 2}" y="{dy + 60}" font-family="sans-serif" '
            f'font-weight="bold" font-size="40" fill="{ZONE}" text-anchor="middle">'
            f"{i + 1}. {stage}</text>"
        )
    svg = (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}">\n'
        + "\n".join(f"  {part}" for part in body)
        + "\n</svg>\n"
    )
    path.write_text(svg, encoding="utf-8")


def write_png(svg: pathlib.Path) -> Optional[pathlib.Path]:
    """Render the SVG to a PNG next to it with Inkscape; return None without it."""
    inkscape = shutil.which("inkscape")
    if inkscape is None:
        return None
    png = svg.with_suffix(".png")
    subprocess.run(
        [inkscape, str(svg), "--export-type=png", f"--export-filename={png}"],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return png


def main() -> int:
    """Execute the main routine."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", help="the folder to write the sketch into")
    args = parser.parse_args()

    output = pathlib.Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    house = output / "sketch_house_base.svg"
    write_svg(house)
    walls = output / "sketch_walls_sheet.svg"
    write_sheet_svg(walls, WALLS_STAGES, _wall_cell)
    roof = output / "sketch_roof_sheet.svg"
    write_sheet_svg(roof, ROOF_STAGES, _roof_cell)
    door = output / "sketch_door_sheet.svg"
    write_sheet_svg(door, DOOR_STAGES, _door_cell, DOOR_CELL_WIDTH)
    for svg in (house, walls, roof, door):
        print(f"Wrote {svg}")
        png = write_png(svg)
        if png is None:
            print("Inkscape is not there; convert the SVG to a PNG yourself.")
        else:
            print(f"Wrote {png}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
