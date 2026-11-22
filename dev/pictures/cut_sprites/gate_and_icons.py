"""
Cut the sheet of the iron gate with its stone plates (gate/gate_sheet.png) and
the sheet of the icons of the menu cards (icons/icon_sheet.png); their sketches
are written by dev/pictures/make_gate_and_icon_sketches.py.

Usage:

    python3 dev/pictures/cut_sprites/gate_and_icons.py <folder with gate/ and icons/>
"""

import sys
from typing import Final, Sequence, Tuple

from PIL import Image

from common import Sheets, cells, fit, run, save


#: The gate sheet: the gate tile spans from the middle of its first bar to the
#: middle of its fifth bar (four spaces between the bars), so that the tiles
#: in a row meet in the middle of a bar and the row repeats seamlessly. The
#: plates are the bedrock tiles next to it, cut at the dark seams between them.
GATE_BOXES: Final[Sequence[Tuple[str, Tuple[int, int, int, int]]]] = (
    ("gate", (109, 2, 709, 718)),
    ("plate_waiting", (754, 1, 1424, 718)),
    ("plate_pressed", (1424, 5, 2120, 714)),
)


#: The size of a tile of the gate sheet; the game squeezes it into a cell.
GATE_TILE: Final[int] = 256


#: The icons of the menu cards, row by row on a 4 x 2 sheet.
ICONS: Final[Sequence[str]] = (
    "question",
    "quit",
    "back",
    "next",
    "again",
    "ok",
    "trash",
    "lock",
)


#: The size of an icon; the game draws it at about half.
ICON: Final[int] = 256


def cut_gate_and_icons(load: Sheets) -> None:
    """Cut the gate and plates of the puzzles and the icons of the menu cards."""
    sheet = load("gate/gate_sheet.png")
    for name, box in GATE_BOXES:
        tile = sheet.crop(box).resize((GATE_TILE, GATE_TILE), Image.LANCZOS)
        save(tile, f"blocks/{name}.png")

    for name, cell in zip(ICONS, cells(load("icons/icon_sheet.png"), 4, 2)):
        icon = cell.crop(cell.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox())
        icon = fit(icon, ICON - 8)
        square = Image.new("RGBA", (ICON, ICON), (0, 0, 0, 0))
        square.paste(icon, ((ICON - icon.width) // 2, (ICON - icon.height) // 2))
        save(square, f"icons/{name}.png")


if __name__ == "__main__":
    sys.exit(run(__doc__, cut_gate_and_icons))
