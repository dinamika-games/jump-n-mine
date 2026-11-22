"""
Cut the sheets of the dragon and of its fire
(jump_n_mine_dragon_consistent/), each to the common box of its frames, so
that the frames stay in place against each other.

Usage:

    python3 dev/pictures/cut_sprites/dragon.py <folder with the sheets>
"""

import sys

from common import Sheets, cells, common_box, fit, run, save


def cut_dragon(load: Sheets) -> None:
    """Cut the frames of the dragon and of its fire."""
    dragon = cells(load("jump_n_mine_dragon_consistent/dragon_sheet_consistent.png"), 4, 1)
    box = common_box(dragon)
    for k, frame in enumerate(dragon):
        save(fit(frame.crop(box), 420), f"dragon/frame_{k + 1}.png")
    fire = cells(load("jump_n_mine_dragon_consistent/fire_sheet.png"), 3, 1)
    box = common_box(fire)
    for k, frame in enumerate(fire):
        save(fit(frame.crop(box), 140), f"dragon/fire_{k + 1}.png")


if __name__ == "__main__":
    sys.exit(run(__doc__, cut_dragon))
