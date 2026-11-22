#!/usr/bin/env python3
"""
Write the sketches of the sheets of the parts of the dwarves' house which are
not painted yet (the windows, the chimney, the tower, the fence, the garden,
the mine entrance and the village square), and the layout of all their pieces
over the painted landscape, to attach to the prompts in
dev/pictures/prompts/house.md.

Every piece has its place on the stage of ``HouseArt`` (1200 x 520, the ground
at 440), where the game draws it. On the sheet, each piece gets a cell with a
box of the same proportions as its place, standing on the baseline of the cell,
as big as the cell allows; the game scales the painted piece into its place.

    python3 dev/pictures/house/make_part_sheets.py <landscape.png> <output folder>

The landscape is the painting without the shack; the layout is drawn over it.
It writes one folder per part, with the sketch of its sheet, and
``layout_of_the_pieces.svg`` (and the PNGs, if Inkscape is there).
"""

import argparse
import base64
import pathlib
import shutil
import subprocess
import sys
from typing import Final, List, Optional, Sequence

OUTLINE: Final[str] = "#1a1016"
LABEL: Final[str] = "#c0306a"

#: The stage of ``HouseArt``.
STAGE_WIDTH: Final[int] = 1200
STAGE_HEIGHT: Final[int] = 520

#: The layout is drawn at twice the size of the stage.
LAYOUT_SCALE: Final[int] = 2

#: The cells of the sheets, the baseline in them, and how big a box may be.
CELL: Final[int] = 500
BASELINE: Final[int] = 460
BOX_WIDTH: Final[int] = 400
BOX_HEIGHT: Final[int] = 360
COLUMNS: Final[int] = 3

#: The fence is wide: its cells are twice as wide, and its box may be this wide.
WIDE_CELL: Final[int] = 1000
WIDE_BOX_WIDTH: Final[int] = 900

#: The tower is tall: its cells are twice as high.
TALL_CELL_HEIGHT: Final[int] = 1000
TALL_BASELINE: Final[int] = 960
TALL_BOX_HEIGHT: Final[int] = 840


class Piece:
    """A painted piece of a part of the house, and its place on the stage."""

    #: The name of the piece, and of its picture (``<name>.png``).
    name: Final[str]

    #: The left, the top, the width and the height of its place on the stage.
    x: Final[float]
    y: Final[float]
    width: Final[float]
    height: Final[float]

    def __init__(self, name: str, x: float, y: float, width: float, height: float) -> None:
        self.name = name
        self.x = x
        self.y = y
        self.width = width
        self.height = height


class Part:
    """A part of the house: its sheet of pieces."""

    #: The id of the part (see ``Economy.HOUSE_PARTS``), and the name of its folder.
    id: Final[str]

    #: The pieces on its sheet, in the order of the cells.
    pieces: Final[Sequence[Piece]]

    #: Whether the pieces replace each other, stage by stage (and share their
    #: place), or each stage adds its piece at its own place.
    replacing: Final[bool]

    #: Whether the cells are tall (for the tower) or wide (for the fence).
    tall: Final[bool]
    wide: Final[bool]

    def __init__(
        self,
        id: str,
        pieces: Sequence[Piece],
        replacing: bool,
        tall: bool = False,
        wide: bool = False,
    ) -> None:
        self.id = id
        self.pieces = pieces
        self.replacing = replacing
        self.tall = tall
        self.wide = wide


#: The places of the pieces. The windows and the walls of the shack are where the
#: painting has them (the walls from x 405 to 780, the window openings 73 px
#: wide at 297 px from the top, the ground at 440); the windows reach beyond
#: their openings for the shutters and the flower boxes.
PARTS: Final[Sequence[Part]] = (
    Part(
        "windows",
        (
            Piece("hole", 410, 297, 136, 96),
            Piece("shutters", 410, 297, 136, 96),
            Piece("glass_windows", 410, 297, 136, 96),
            Piece("flower_boxes", 410, 297, 136, 96),
            Piece("stained_glass", 410, 297, 136, 96),
            Piece("rose_window", 560, 165, 64, 64),
        ),
        replacing=True,
    ),
    Part(
        "chimney",
        (
            Piece("clay_pipe", 700, 75, 48, 120),
            Piece("brick_chimney", 700, 75, 48, 120),
            Piece("stone_chimney", 700, 75, 48, 120),
            Piece("twin_chimneys", 700, 75, 48, 120),
            Piece("forge_chimney", 700, 75, 48, 120),
        ),
        replacing=True,
    ),
    Part(
        "tower",
        (
            Piece("lookout_post", 800, 20, 120, 420),
            Piece("stone_tower", 800, 20, 120, 420),
            Piece("tower_with_a_flag", 800, 20, 120, 420),
            Piece("clock_tower", 800, 20, 120, 420),
            Piece("crystal_spire", 800, 20, 120, 420),
        ),
        replacing=True,
        tall=True,
    ),
    Part(
        "fence",
        (
            Piece("stick_fence", 400, 440, 400, 75),
            Piece("picket_fence", 400, 440, 400, 75),
            Piece("stone_wall", 400, 440, 400, 75),
            Piece("iron_fence", 400, 440, 400, 75),
            Piece("hedge_with_arches", 400, 440, 400, 75),
        ),
        replacing=True,
        wide=True,
    ),
    Part(
        "garden",
        (
            Piece("flowers", 285, 405, 120, 40),
            Piece("vegetable_beds", 270, 455, 130, 45),
            Piece("mushroom_patch", 20, 478, 60, 30),
            Piece("pond", 805, 462, 160, 42),
            Piece("fountain", 855, 395, 60, 85),
        ),
        replacing=False,
    ),
    Part(
        "mine",
        (
            Piece("timber_props", 56, 296, 160, 145),
            Piece("rails", 110, 425, 150, 90),
            Piece("mine_cart", 165, 440, 90, 62),
            Piece("lantern", 222, 300, 30, 50),
            Piece("gem_gate", 50, 285, 170, 156),
        ),
        replacing=False,
    ),
    Part(
        "square",
        (
            Piece("bench", 1080, 470, 80, 35),
            Piece("market_stall", 975, 430, 100, 85),
            Piece("well", 925, 357, 60, 85),
            Piece("bandstand", 1000, 270, 140, 170),
            Piece("statue_of_the_miners", 1145, 335, 50, 110),
        ),
        replacing=False,
    ),
)

#: The pieces which the game draws twice, and where the second one goes (x, y).
SECOND_PLACES: Final[Sequence[Piece]] = (
    Piece("windows: the right window", 640, 297, 136, 96),
    Piece("chimney: the second of the twin chimneys", 452, 75, 48, 120),
    Piece("mine: the second lantern", 20, 300, 30, 50),
)


def _cell_box(piece: Piece, part: "Part") -> List[float]:
    """The box of the piece in its cell: its proportions, as big as fits."""
    box_height = TALL_BOX_HEIGHT if part.tall else BOX_HEIGHT
    box_width = WIDE_BOX_WIDTH if part.wide else BOX_WIDTH
    cell_width = WIDE_CELL if part.wide else CELL
    baseline = TALL_BASELINE if part.tall else BASELINE
    scale = min(box_width / piece.width, box_height / piece.height)
    width = piece.width * scale
    height = piece.height * scale
    return [(cell_width - width) / 2, baseline - height, width, height]


def write_sheet_svg(part: Part, path: pathlib.Path) -> None:
    """Write the sketch of the sheet of the part to the path."""
    cell_height = TALL_CELL_HEIGHT if part.tall else CELL
    baseline = TALL_BASELINE if part.tall else BASELINE
    cell_width = WIDE_CELL if part.wide else CELL
    rows = (len(part.pieces) + COLUMNS - 1) // COLUMNS
    width = cell_width * COLUMNS
    height = cell_height * rows
    body = [f'<rect width="{width}" height="{height}" fill="#ffffff"/>']
    for i, piece in enumerate(part.pieces):
        dx = (i % COLUMNS) * cell_width
        dy = (i // COLUMNS) * cell_height
        x, y, w, h = _cell_box(piece, part)
        body.append(
            f'<rect x="{dx}" y="{dy}" width="{cell_width}" height="{cell_height}" fill="none" '
            f'stroke="#c8c8c8" stroke-width="2"/>'
        )
        body.append(
            f'<rect x="{dx + x:g}" y="{dy + y:g}" width="{w:g}" height="{h:g}" '
            f'fill="#f2ebe0" stroke="{OUTLINE}" stroke-width="4" stroke-dasharray="16,10"/>'
        )
        if part.id == "windows" and piece.name != "rose_window":
            # The opening of the window, which every stage keeps.
            side = w * 74 / 136
            body.append(
                f'<rect x="{dx + x + (w - side) / 2:g}" y="{dy + y:g}" width="{side:g}" '
                f'height="{side:g}" fill="#e4e4e4" stroke="#a0a0a0" stroke-width="4" '
                f'stroke-dasharray="6,8"/>'
            )
        body.append(
            f'<line x1="{dx + 20}" y1="{dy + baseline}" x2="{dx + cell_width - 20}" '
            f'y2="{dy + baseline}" stroke="{LABEL}" stroke-width="3" stroke-dasharray="4,8"/>'
        )
        body.append(
            f'<text x="{dx + cell_width / 2}" y="{dy + 44}" font-family="sans-serif" '
            f'font-weight="bold" font-size="32" fill="{LABEL}" text-anchor="middle">'
            f"{i + 1}. {piece.name}</text>"
        )
    _write(path, width, height, body)


def write_layout_svg(landscape: pathlib.Path, path: pathlib.Path) -> None:
    """Write the places of all the pieces over the landscape to the path."""
    width = STAGE_WIDTH * LAYOUT_SCALE
    height = STAGE_HEIGHT * LAYOUT_SCALE
    data = base64.b64encode(landscape.read_bytes()).decode("ascii")
    body = [
        f'<image xlink:href="data:image/png;base64,{data}" width="{width}" height="{height}" '
        f'preserveAspectRatio="none"/>',
        # The walls of the shack, which the windows sit in.
        f'<rect x="{405 * LAYOUT_SCALE}" y="{265 * LAYOUT_SCALE}" '
        f'width="{375 * LAYOUT_SCALE}" height="{175 * LAYOUT_SCALE}" fill="#ffffff" '
        f'fill-opacity="0.35" stroke="{OUTLINE}" stroke-width="4"/>',
    ]
    colors = ["#c0306a", "#2a5ad0", "#8a3ac0", "#d06a10", "#1a8a3a", "#a03010", "#106a8a"]
    places = [(part, piece) for part in PARTS for piece in part.pieces]
    seen = set()
    for part, piece in places:
        key = (piece.x, piece.y, piece.width, piece.height)
        if part.replacing and key in seen:
            continue
        seen.add(key)
        color = colors[PARTS.index(part) % len(colors)]
        label = part.id if part.replacing and piece.name != "rose_window" else piece.name
        label = label.replace("_of_the_miners", "")
        body.append(_place(piece, color, label))
    for piece in SECOND_PLACES:
        body.append(_place(piece, "#606060", piece.name.split(":")[0] + " (2nd)"))
    _write(path, width, height, body)


def _place(piece: Piece, color: str, label: str) -> str:
    k = LAYOUT_SCALE
    size = 13 if piece.width >= 90 else 10
    return (
        f'<rect x="{piece.x * k:g}" y="{piece.y * k:g}" width="{piece.width * k:g}" '
        f'height="{piece.height * k:g}" fill="none" stroke="{color}" stroke-width="5" '
        f'stroke-dasharray="14,8"/>'
        f'<text x="{(piece.x + piece.width / 2) * k:g}" y="{(piece.y - 4) * k:g}" '
        f'font-family="sans-serif" font-weight="bold" font-size="{size * k}" '
        f'fill="{color}" stroke="#ffffff" stroke-width="5" paint-order="stroke" '
        f'text-anchor="middle">{label}</text>'
    )


def _write(path: pathlib.Path, width: int, height: int, body: List[str]) -> None:
    svg = (
        f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        f'width="{width}" height="{height}" '
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
    parser.add_argument("landscape", help="the painted landscape without the shack")
    parser.add_argument("output", help="the folder to write the folders of the parts into")
    args = parser.parse_args()

    output = pathlib.Path(args.output)
    svgs = []
    for part in PARTS:
        folder = output / part.id
        folder.mkdir(parents=True, exist_ok=True)
        svg = folder / f"sketch_{part.id}_sheet.svg"
        write_sheet_svg(part, svg)
        svgs.append(svg)
    layout = output / "layout_of_the_pieces.svg"
    write_layout_svg(pathlib.Path(args.landscape), layout)
    svgs.append(layout)
    for svg in svgs:
        print(f"Wrote {svg}")
        png = write_png(svg)
        if png is not None:
            print(f"Wrote {png}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
