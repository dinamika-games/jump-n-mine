"""
Cut the sheet of the items (items.png): the gems, the boosters, the chest, the
pickaxe and the stars, each to its own outline.

Usage:

    python3 dev/pictures/cut_sprites/items.py <folder with the sheets>
"""

import sys
from typing import Final, List

from common import Sheets, cells, fit, run, save


#: The items, row by row on a 4 x 3 sheet.
ITEMS: Final[List[str]] = [
    "gem_0",
    "gem_1",
    "gem_2",
    "gem_3",
    "booster_gold_pick",
    "booster_helmet",
    "booster_pump",
    "booster_boots",
    "chest",
    "pickaxe",
    "star_filled",
    "star_empty",
]


def cut_items(load: Sheets) -> None:
    """Cut the gems, the boosters, the chest, the pickaxe and the stars."""
    for name, cell in zip(ITEMS, cells(load("items.png"), 4, 3)):
        box = cell.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox()
        save(fit(cell.crop(box), 128 if not name.startswith("gem") else 96), f"items/{name}.png")


if __name__ == "__main__":
    sys.exit(run(__doc__, cut_items))
