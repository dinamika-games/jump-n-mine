"""
Copy the title painting (jump_n_mine_title/) into the pictures of the game.

Usage:

    python3 dev/pictures/cut_sprites/cut_title.py <folder with the sheets>
"""

import sys

from PIL import Image

from common import Sheets, run, save


def cut_title(load: Sheets) -> None:
    """Copy the title painting, without its transparency."""
    source = load.folder
    title = Image.open(source / "jump_n_mine_title/jump_n_mine_title_1920x1080.png").convert("RGB")
    save(title, "title.png")


if __name__ == "__main__":
    sys.exit(run(__doc__, cut_title))
