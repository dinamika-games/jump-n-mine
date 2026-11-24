"""
Cut the sheets of the mole (mole_sprites_corrected/) and of the evil miner
(evil_miner_sprites/), see dev/pictures/prompts/moles_and_rival.md: we remove
the bits of the neighbouring cells, and scale the evil miner to the dwarves.

Usage:

    python3 dev/pictures/cut_sprites/cut_moles_and_evil_miner.py <folder with the sheets>
"""

import sys
from typing import Final, List, Set, Tuple

from PIL import Image

from common import Sheets, cells, run, save
from cut_dwarves import DWARF_CELL


#: The poses of the mole, in the cells of its sheet (see
#: dev/pictures/prompts/moles_and_rival.md).
MOLE_POSES: Final[List[str]] = ["dig_1", "dig_2", "peek_1", "peek_2", "cry_1", "cry_2"]


#: The sheet of the mole, 6 cells of 400 x 300 px in a row.
MOLE_SHEET: Final[str] = "mole_sprites_corrected/assets/pictures/mole/mole_sheet.png"


#: The painter left this margin (in px) at the left and the right of each cell
#: of the sheet of the mole; what overflows its cell starts at the margin of the
#: next cell.
MOLE_MARGIN: Final[int] = 30


def patches(cell: Image.Image) -> List[List[Tuple[int, int]]]:
    """Find the opaque patches of the cell, each a list of its pixels."""
    alpha = cell.getchannel("A").load()
    width, height = cell.size
    seen: Set[Tuple[int, int]] = set()
    result = []
    for start_x in range(width):
        for start_y in range(height):
            if (start_x, start_y) in seen or alpha[start_x, start_y] <= 16:
                continue
            patch = [(start_x, start_y)]
            seen.add((start_x, start_y))
            k = 0
            while k < len(patch):
                x, y = patch[k]
                k += 1
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in seen:
                            if alpha[nx, ny] > 16:
                                seen.add((nx, ny))
                                patch.append((nx, ny))
            result.append(patch)
    return result


def without_neighbours(cell: Image.Image) -> Image.Image:
    """
    Remove the bits of the neighbouring cell from the cell of the mole.

    The tears and the sniffing streaks of a pose sometimes reach over the right
    edge of its cell, and show as slivers at the left margin of the next cell:
    we remove the small patches (not the mole) which start within 30 px of
    that margin. The tears and the crumbs of the pose itself lie further
    inside, and stay.
    """
    found = patches(cell)
    mole = max(found, key=len)
    result = cell.copy()
    pixels = result.load()
    for patch in found:
        if patch is mole or min(x for x, _ in patch) > MOLE_MARGIN + 30:
            continue
        for x, y in patch:
            pixels[x, y] = (0, 0, 0, 0)
    return result


def cut_moles(load: Sheets) -> None:
    """Cut the sheet of the mole into its poses, without the bits of the neighbours."""
    for pose, cell in zip(MOLE_POSES, cells(load(MOLE_SHEET), len(MOLE_POSES), 1)):
        save(without_neighbours(cell), f"mole/{pose}.png")


#: The poses of the evil miner, in the cells of his sheet (4 x 4 cells of
#: 640 x 600 px, see dev/pictures/intro/make_evil_miner_sheet.py).
EVIL_POSES: Final[List[str]] = [
    "idle",
    "walk_1",
    "walk_2",
    "walk_3",
    "walk_4",
    "walk_5",
    "walk_6",
    "raised",
    "swing",
    "hit_down",
    "hit_down_b",
    "dizzy",
    "under_water",
    "side_back",
    "side_hit",
    "side_recoil",
]


#: The sheet of the evil miner.
EVIL_SHEET: Final[str] = "evil_miner_sprites/evil_miner_sheet.png"


#: In a cell of the sheet of the evil miner, his feet stand on this line, and
#: the middle of his boots stands at this x (in idle).
EVIL_FEET: Final[Tuple[int, int]] = (284, 557)


#: The poses in which he stands upright, so that his helmet is as high as in
#: idle; the painter drew some of them smaller, and we scale them back.
EVIL_UPRIGHT: Final[List[str]] = [
    "idle",
    "walk_1",
    "walk_2",
    "walk_3",
    "walk_4",
    "walk_5",
    "walk_6",
    "under_water",
    "side_hit",
    "side_recoil",
]


#: In a picture of a dwarf (250 x 250 px), the middle of the boots of the red
#: dwarf in idle stands here, and the dwarf is this tall from the helmet to the
#: feet (see assets/pictures/dwarves/red/idle.png).
DWARF_PICTURE_FEET: Final[Tuple[int, int]] = (129, 227)
DWARF_PICTURE_TALL: Final[int] = 169


def helmet_top(cell: Image.Image) -> int:
    """Find the top of the dark grey helmet of the evil miner in the cell."""
    pixels = cell.load()
    width, height = cell.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            grey = max(r, g, b) - min(r, g, b) <= 22
            if a > 200 and grey and 45 <= r <= 115 and 40 <= g <= 110 and 45 <= b <= 120:
                return y
    return 0


def cut_evil_miner(load: Sheets) -> None:
    """
    Cut the sheet of the evil miner into his poses, in the format of the dwarves.

    His pictures are 250 x 250 px like the dwarves', with his boots and his
    height where the red dwarf has them, so that ``Art.dwarf`` draws him as big
    as the dwarves. The upright poses which the painter drew smaller are scaled
    to the height of idle, around the feet.
    """
    sheet = cells(load(EVIL_SHEET), 4, 4)
    tops = {pose: helmet_top(cell) for pose, cell in zip(EVIL_POSES, sheet)}
    tall = EVIL_FEET[1] - tops["idle"]
    for pose, cell in zip(EVIL_POSES, sheet):
        scale = DWARF_PICTURE_TALL / tall
        if pose in EVIL_UPRIGHT:
            scale *= tall / (EVIL_FEET[1] - tops[pose])
        size = DWARF_CELL / scale
        left = EVIL_FEET[0] - DWARF_PICTURE_FEET[0] / scale
        top = EVIL_FEET[1] - DWARF_PICTURE_FEET[1] / scale
        box = (round(left), round(top), round(left + size), round(top + size))
        save(
            cell.crop(box).resize((DWARF_CELL, DWARF_CELL), Image.LANCZOS),
            f"dwarves/evil/{pose}.png",
        )


def cut_moles_and_evil_miner(load: Sheets) -> None:
    """Cut the mole and the evil miner."""
    cut_moles(load)
    cut_evil_miner(load)


if __name__ == "__main__":
    sys.exit(run(__doc__, cut_moles_and_evil_miner))
