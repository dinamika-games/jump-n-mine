"""
Cut the sheets of the water pouring from the springs (see
dev/pictures/prompts/water.md): the empty pipe in the wall (pipe_empty.png),
and the six frames of the water pouring out of it
(water_pouring_6_frames.png), both on a flat magenta background.

Usage:

    python3 dev/pictures/cut_sprites/cut_water.py <folder with the sheets>
"""

import sys
from typing import Final

from PIL import Image

from common import Sheets, cells, common_box, run, save, without_checkerboard


#: The size of a block on the screen is 80 px; we keep twice as many pixels.
BLOCK: Final[int] = 160

#: The frames of the pouring water are this tall; the game scales them to the
#: fall of the water.
POUR_HEIGHT: Final[int] = 320

#: The cells of the sheet of the pouring water are framed by thin dark lines,
#: which we cut away.
GRID_LINE: Final[int] = 4


def cut_water(load: Sheets) -> None:
    """Cut the empty pipe and the frames of the pouring water."""
    pipe = without_checkerboard(load("pipe_empty.png"))
    pipe = pipe.crop(pipe.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox())
    save(pipe.resize((BLOCK, BLOCK), Image.LANCZOS), "blocks/spring_empty.png")

    frames = []
    for cell in cells(load("water_pouring_6_frames.png"), 3, 2):
        inner = cell.crop((GRID_LINE, GRID_LINE, cell.width - GRID_LINE, cell.height - GRID_LINE))
        frames.append(without_checkerboard(inner))
    # NOTE (mristin):
    # One box for all the frames, so that the water leaves the pipe at the same
    # pixel in every frame (the top left corner of the frame).
    box = common_box(frames)
    for k, frame in enumerate(frames):
        frame = frame.crop(box)
        width = round(frame.width * POUR_HEIGHT / frame.height)
        save(frame.resize((width, POUR_HEIGHT), Image.LANCZOS), f"water/pour_{k + 1}.png")


if __name__ == "__main__":
    sys.exit(run(__doc__, cut_water))
