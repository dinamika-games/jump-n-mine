"""
Cut the painted sprite sheets into the pictures of the game, assets/pictures/:
what the cutters of dev/pictures/cut_sprites/ share.

The sheets were painted from the prompts in dev/pictures/prompts/ (see
CONTRIBUTING.md). Every sheet is a grid of equal cells. We cut the cells, scale
them to twice their size in the game (the game draws them at half), and keep
their transparency. Each cutter takes the folder with the unpacked sheets:

* ``cut_dwarves.py``: the dwarves, their walk cycles and sideways strikes, and the
  miner's helmets;
* ``cut_moles_and_evil_miner.py``: the mole and the evil miner;
* ``cut_blocks.py``: the blocks, the caves, the skies, the cracks and the springs;
* ``cut_items.py``: the gems, the boosters, the chest, the pickaxe and the stars;
* ``cut_dragon.py``: the dragon and its fire;
* ``cut_title.py``: the title painting;
* ``cut_house.py``: the dwarves' house;
* ``cut_gate_and_icons.py``: the iron gate with its stone plates, and the icons of
  the menu cards;
* ``cut_water.py``: the empty pipe of the springs, and the water pouring out of it.

The image generator sometimes paints a checkerboard, a flat magenta or a haze
instead of a transparent background; the cleaners here clear them.
"""

import argparse
import pathlib
from typing import Callable, Final, Optional, Tuple

from PIL import Image, ImageDraw, ImageFilter


#: The root of the repository.
REPO: Final[pathlib.Path] = pathlib.Path(__file__).resolve().parents[3]

#: Where the pictures of the game go.
OUTPUT: Final[pathlib.Path] = REPO / "assets" / "pictures"


class Sheets:
    """Load the sheets from the folder with the unpacked sheets."""

    #: The folder with the unpacked sheets.
    folder: Final[pathlib.Path]

    def __init__(self, folder: pathlib.Path) -> None:
        """Initialize with the given values."""
        self.folder = folder

    def __call__(self, relative: str) -> Image.Image:
        """Load the sheet at the path relative to the folder, with transparency."""
        return Image.open(self.folder / relative).convert("RGBA")


def cells(image: Image.Image, cols: int, rows: int) -> list:
    """Cut the image into a grid of cells, row by row."""
    width, height = image.size
    result = []
    for row in range(rows):
        for col in range(cols):
            box = (
                round(col * width / cols),
                round(row * height / rows),
                round((col + 1) * width / cols),
                round((row + 1) * height / rows),
            )
            result.append(image.crop(box))
    return result


def save(image: Image.Image, relative: str) -> None:
    path = OUTPUT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)
    print(f"{path.relative_to(REPO)}: {image.size[0]} x {image.size[1]}")


def common_box(images: list) -> tuple:
    """The bounding box of the opaque pixels of all the images together."""
    boxes = [
        image.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox() for image in images
    ]
    boxes = [box for box in boxes if box is not None]
    return (
        min(box[0] for box in boxes),
        min(box[1] for box in boxes),
        max(box[2] for box in boxes),
        max(box[3] for box in boxes),
    )


def fit(image: Image.Image, longest: int) -> Image.Image:
    scale = longest / max(image.size)
    return image.resize((round(image.width * scale), round(image.height * scale)), Image.LANCZOS)


def opaque_height(image: Image.Image) -> int:
    """The height of the nearly opaque pixels (without the glow of the lamp)."""
    box = image.getchannel("A").point(lambda a: 255 if a > 200 else 0).getbbox()
    return box[3] - box[1]


#: A pixel of a painted checkerboard is this light (in every channel), and its
#: channels differ by less than this.
CHECKER_LIGHT: Final[int] = 200
CHECKER_GREY: Final[int] = 20


#: A pixel of a flat magenta background (#FF00FF, which the prompts ask for
#: when the image generator cannot make the background transparent) has red and
#: blue above this, and green below that.
MAGENTA_STRONG: Final[int] = 200
MAGENTA_GREEN: Final[int] = 90


#: Pixels more transparent than this are cleared: some sheets come with a faint
#: haze over their transparent background.
HAZE: Final[int] = 40


#: Light grey pixels more transparent than this are a haze, too.
HAZE_LIGHT: Final[int] = 200


def without_checkerboard(cell: Image.Image) -> Image.Image:
    """
    Make the background of the cell transparent, if the image generator painted
    a light checkerboard (or a flat magenta) instead of leaving it transparent.

    We flood the light grey (or magenta) pixels from the edges of the cell, which stop at the
    dark outline of the piece, so that the light parts inside the piece (e.g.,
    the frames of a window) stay; the pixels at the border of the flood fade
    out, so that the outline keeps its soft edge.
    """
    if cell.getchannel("A").getextrema()[0] < 255:
        return cell
    width, height = cell.size
    rgb = cell.convert("RGB").load()
    light = Image.new("L", cell.size, 0)
    marks = light.load()
    for y in range(height):
        for x in range(width):
            r, g, b = rgb[x, y]
            checker = min(r, g, b) > CHECKER_LIGHT and max(r, g, b) - min(r, g, b) < CHECKER_GREY
            magenta = r > MAGENTA_STRONG and b > MAGENTA_STRONG and g < MAGENTA_GREEN
            if checker or magenta:
                marks[x, y] = 255
    for x, y in [(x, 0) for x in range(width)] + [(x, height - 1) for x in range(width)]:
        if marks[x, y] == 255:
            ImageDraw.floodfill(light, (x, y), 128, thresh=0)
    for x, y in [(0, y) for y in range(height)] + [(width - 1, y) for y in range(height)]:
        if marks[x, y] == 255:
            ImageDraw.floodfill(light, (x, y), 128, thresh=0)
    alpha = light.point(lambda v: 0 if v == 128 else 255).filter(ImageFilter.MinFilter(3))
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.8))
    result = cell.copy()
    result.putalpha(alpha)
    return result


def without_haze(cell: Image.Image) -> Image.Image:
    """
    Clear the nearly transparent pixels of the cell, and the light grey haze:
    the half transparent pixels of a light grey (a piece painted white, like a
    picket fence, is opaque).
    """
    rgb = cell.convert("RGB").load()
    alpha = cell.getchannel("A")
    pixels = alpha.load()
    width, height = cell.size
    for y in range(height):
        for x in range(width):
            a = pixels[x, y]
            if a == 0:
                continue
            r, g, b = rgb[x, y]
            light = min(r, g, b) > CHECKER_LIGHT and max(r, g, b) - min(r, g, b) < CHECKER_GREY
            if a < HAZE or (light and a < HAZE_LIGHT):
                pixels[x, y] = 0
    result = cell.copy()
    result.putalpha(alpha)
    return result


def body_box(cell: Image.Image) -> Tuple[int, int, int, int]:
    """
    The box of the solid body of the cell: the rows and the columns which are
    opaque over a good part of it, without the specks of paint around it.
    """
    alpha = cell.getchannel("A")
    width, height = cell.size
    pixels = alpha.load()
    rows = [y for y in range(height) if sum(pixels[x, y] > 200 for x in range(width)) > width // 8]
    cols = [x for x in range(width) if sum(pixels[x, y] > 200 for y in range(height)) > height // 8]
    # NOTE (mristin):
    # The soft edge of the outline lies outside the solid rows and columns.
    margin = 3
    return (
        max(0, cols[0] - margin),
        max(0, rows[0] - margin),
        min(width, cols[-1] + 1 + margin),
        min(height, rows[-1] + 1 + margin),
    )


def piece_box(cell: Image.Image) -> Optional[Tuple[int, int, int, int]]:
    """
    The box of the piece in the cell: the rows and the columns with at least a
    few opaque pixels, so that a lone speck of paint does not stretch it.
    """
    alpha = cell.getchannel("A").point(lambda a: 1 if a > 64 else 0)
    width, height = cell.size
    pixels = alpha.load()
    rows = [y for y in range(height) if sum(pixels[x, y] for x in range(width)) >= 3]
    cols = [x for x in range(width) if sum(pixels[x, y] for y in range(height)) >= 3]
    if not rows or not cols:
        return None
    return (
        max(0, cols[0] - 2),
        max(0, rows[0] - 2),
        min(width, cols[-1] + 3),
        min(height, rows[-1] + 3),
    )


def run(description: str, cut: Callable[[Sheets], None]) -> int:
    """Parse the arguments of a cutter and cut the sheets of the folder."""
    parser = argparse.ArgumentParser(
        description=description, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("folder", help="the folder with the unpacked sheets")
    args = parser.parse_args()
    cut(Sheets(pathlib.Path(args.folder)))
    return 0
