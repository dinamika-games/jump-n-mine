"""
Cut the sheets of the dwarves' house (see dev/pictures/prompts/house.md), from a
folder with one folder per sheet: the walls in walls/walls_sheet.png, the roof in
roof/roof_sheet.png, the other parts in <part>/<part>_sheet.png, and the
landscape without the shack in landscape/landscape.png. The image generator
sometimes paints a checkerboard, a flat magenta or a haze instead of a
transparent background; we clear them.

Usage:

    python3 dev/pictures/cut_sprites/house.py <folder with the house sheets>
"""

import sys
from typing import Final, List, Tuple

from PIL import Image

from common import (
    Sheets,
    body_box,
    cells,
    common_box,
    fit,
    piece_box,
    run,
    save,
    without_checkerboard,
    without_haze,
)


#: The stages of the walls of the dwarves' house, in the cells of their sheet
#: (3 x 2 cells, see dev/pictures/house/make_house_sketch.py): the planks of
#: the shack, and the five stages which the players build.
HOUSE_WALLS: Final[List[str]] = [
    "planks",
    "log_walls",
    "timber_frame",
    "stone_walls",
    "carved_stone",
    "marble_and_gold",
]


#: The sheet of the walls, in the folder of the house sheets.
HOUSE_WALLS_SHEET: Final[str] = "walls/walls_sheet.png"


#: The walls are this wide (in px), twice as wide as the game draws them.
HOUSE_WALL_WIDTH: Final[int] = 720


#: The stages of the roof, in the cells of its sheet (3 x 2 cells): the boards of
#: the shack, and the five stages which the players build.
HOUSE_ROOFS: Final[List[str]] = [
    "boards",
    "straw_roof",
    "wooden_shingles",
    "red_tiles",
    "slate_and_dormer",
    "golden_roof",
]


#: The sheet of the roof, in the folder of the house sheets.
HOUSE_ROOF_SHEET: Final[str] = "roof/roof_sheet.png"


#: The roofs are this wide (in px), about twice as wide as the game draws them.
HOUSE_ROOF_WIDTH: Final[int] = 820


class HouseSheet:
    """A sheet of the pieces of a part of the dwarves' house."""

    #: The part (the folder of the sheet, and of its pictures under house/).
    part: Final[str]

    #: The grid of the sheet.
    columns: Final[int]
    rows: Final[int]

    #: The pieces, in the order of the cells.
    pieces: Final[List[str]]

    #: The pieces which share one box (the stages which replace each other, so
    #: that they stay in place against each other); the others are cut to
    #: their own outlines.
    shared: Final[List[str]]

    #: The longest side of the pictures, in px (about twice as long as the game
    #: draws them).
    longest: Final[int]

    def __init__(
        self,
        part: str,
        columns: int,
        rows: int,
        pieces: List[str],
        shared: List[str],
        longest: int,
    ) -> None:
        self.part = part
        self.columns = columns
        self.rows = rows
        self.pieces = pieces
        self.shared = shared
        self.longest = longest


#: The sheets of the parts (see dev/pictures/house/make_part_sheets.py), each in
#: ``<part>/<part>_sheet.png`` of the folder of the house sheets.
HOUSE_SHEETS: Final[List[HouseSheet]] = [
    HouseSheet(
        "door",
        3,
        2,
        _door := [
            "shack_door",
            "plank_door",
            "oak_door",
            "iron_bound_door",
            "arched_gate",
            "gem_studded_gate",
        ],
        _door,
        280,
    ),
    HouseSheet(
        "windows",
        3,
        2,
        ["hole", "shutters", "glass_windows", "flower_boxes", "stained_glass", "rose_window"],
        ["hole", "shutters", "glass_windows", "flower_boxes", "stained_glass"],
        280,
    ),
    HouseSheet(
        "chimney",
        3,
        2,
        _chimney := [
            "clay_pipe",
            "brick_chimney",
            "stone_chimney",
            "twin_chimneys",
            "forge_chimney",
        ],
        _chimney,
        260,
    ),
    HouseSheet(
        "tower",
        3,
        2,
        _tower := [
            "lookout_post",
            "stone_tower",
            "tower_with_a_flag",
            "clock_tower",
            "crystal_spire",
        ],
        _tower,
        880,
    ),
    HouseSheet(
        "fence",
        3,
        2,
        _fence := [
            "stick_fence",
            "picket_fence",
            "stone_wall",
            "iron_fence",
            "hedge_with_arches",
        ],
        _fence,
        820,
    ),
    HouseSheet(
        "garden",
        3,
        2,
        ["flowers", "vegetable_beds", "mushroom_patch", "pond", "fountain"],
        [],
        330,
    ),
    HouseSheet(
        "mine",
        3,
        2,
        ["timber_props", "rails", "mine_cart", "lantern", "gem_gate"],
        [],
        440,
    ),
    HouseSheet(
        "square",
        3,
        2,
        ["bench", "market_stall", "well", "bandstand", "statue_of_the_miners"],
        [],
        360,
    ),
]


#: The pieces which the game draws mirrored, too (the lantern hangs on both
#: sides of the mine entrance, its hook towards the entrance).
HOUSE_MIRRORED: Final[List[Tuple[str, str]]] = [("mine", "lantern")]


def cut_house_sheet(load: Sheets, sheet: HouseSheet) -> None:
    """Cut the sheet of a part of the house into its pieces."""
    path = f"{sheet.part}/{sheet.part}_sheet.png"
    grid = cells(load(path), sheet.columns, sheet.rows)
    found = {
        name: without_haze(without_checkerboard(cell)) for name, cell in zip(sheet.pieces, grid)
    }
    boxes = {name: piece_box(cell) for name, cell in found.items()}
    shared = [boxes[name] for name in sheet.shared if boxes[name] is not None]
    if shared:
        common = (
            min(box[0] for box in shared),
            min(box[1] for box in shared),
            max(box[2] for box in shared),
            max(box[3] for box in shared),
        )
        for name in sheet.shared:
            boxes[name] = common
    for name in sheet.pieces:
        if boxes[name] is None:
            print(f"{path}: the cell of {name} is empty")
            continue
        piece = fit(found[name].crop(boxes[name]), sheet.longest)
        save(piece, f"house/{sheet.part}/{name}.png")
        if (sheet.part, name) in HOUSE_MIRRORED:
            save(piece.transpose(Image.FLIP_LEFT_RIGHT), f"house/{sheet.part}/{name}_mirrored.png")


def cut_house(load: Sheets) -> None:
    """Cut the sheets of the dwarves' house (see dev/pictures/prompts/house.md)."""
    for stage, cell in zip(HOUSE_WALLS, cells(load(HOUSE_WALLS_SHEET), 3, 2)):
        wall = cell.crop(body_box(cell))
        height = round(wall.height * HOUSE_WALL_WIDTH / wall.width)
        save(wall.resize((HOUSE_WALL_WIDTH, height), Image.LANCZOS), f"house/walls/{stage}.png")

    roofs = [without_checkerboard(cell) for cell in cells(load(HOUSE_ROOF_SHEET), 3, 2)]
    # NOTE (mristin):
    # All the roofs share one box, so that their eaves lie on the same line
    # and the ornament of the golden roof does not shrink it.
    box = common_box(roofs)
    for stage, roof in zip(HOUSE_ROOFS, roofs):
        roof = roof.crop(box)
        height = round(roof.height * HOUSE_ROOF_WIDTH / roof.width)
        save(roof.resize((HOUSE_ROOF_WIDTH, height), Image.LANCZOS), f"house/roof/{stage}.png")

    for sheet in HOUSE_SHEETS:
        if sheet.part == "tower" and not (load.folder / "tower/tower_sheet.png").exists():
            print("The tower is not painted yet; the game draws it in code.")
            continue
        cut_house_sheet(load, sheet)

    # NOTE (mristin):
    # The landscape of the painted shack, without the shack, behind all the parts.
    landscape = load("landscape/landscape.png").convert("RGB")
    save(landscape.resize((2400, 1040), Image.LANCZOS), "house/landscape.png")


if __name__ == "__main__":
    sys.exit(run(__doc__, cut_house))
