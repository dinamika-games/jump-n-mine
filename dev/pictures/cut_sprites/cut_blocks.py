"""
Cut the sheets of the blocks, the caves and the skies of the three worlds
(jump_n_mine_blocks/), and the cracks, the bedrock and the springs
(jump_n_mine_gassy_blocks/).

Usage:

    python3 dev/pictures/cut_sprites/cut_blocks.py <folder with the sheets>
"""

import sys
from typing import Final, List

from PIL import Image

from common import Sheets, cells, run, save


#: The folders of the three worlds, by their index.
WORLDS: Final[List[str]] = ["copper_hills", "sunken_halls", "dragon_deeps"]


#: The size of a block on the screen is 80 px; we keep twice as many pixels.
BLOCK: Final[int] = 160


def cut_blocks(load: Sheets) -> None:
    """Cut the blocks, the caves, the skies, the cracks, the bedrock and the springs."""
    source = load.folder
    blocks = cells(load("jump_n_mine_blocks/blocks_6x3_320px.png"), 6, 3)
    for w, world in enumerate(WORLDS):
        row = blocks[w * 6 : (w + 1) * 6]
        names = ["earth_1", "earth_2", "rock_1", "rock_2", None, "grass"]
        for name, block in zip(names, row):
            if name is not None:
                save(block.resize((BLOCK, BLOCK), Image.LANCZOS), f"blocks/{world}/{name}.png")
        cave = Image.open(source / f"jump_n_mine_blocks/{world}_cave_background_1280x960.png")
        # NOTE (mristin):
        # The caves were made repeatable by mirroring their top left quarter,
        # with a light line left at the seams. We take the clean quarter and
        # mirror it ourselves.
        cave = cave.convert("RGB")
        quarter = cave.crop((6, 6, cave.width // 2 - 6, cave.height // 2 - 6))
        tile = Image.new("RGB", (quarter.width * 2, quarter.height * 2))
        mirrored = quarter.transpose(Image.FLIP_LEFT_RIGHT)
        tile.paste(quarter, (0, 0))
        tile.paste(mirrored, (quarter.width, 0))
        tile.paste(quarter.transpose(Image.FLIP_TOP_BOTTOM), (0, quarter.height))
        tile.paste(mirrored.transpose(Image.FLIP_TOP_BOTTOM), (quarter.width, quarter.height))
        cave = tile
        save(cave.resize((640, 480), Image.LANCZOS), f"blocks/{world}/cave.png")
        sky = Image.open(source / f"jump_n_mine_blocks/{world}_sky_1920x400.png")
        save(sky.convert("RGB"), f"blocks/{world}/sky.png")

    for k in range(1, 4):
        crack = load(f"jump_n_mine_gassy_blocks/crack_{k}.png")
        save(crack.resize((BLOCK, BLOCK), Image.LANCZOS), f"blocks/crack_{k}.png")
    for name in ["bedrock", "spring_open", "spring_sealed"]:
        block = load(f"jump_n_mine_gassy_blocks/{name}.png")
        save(block.resize((BLOCK, BLOCK), Image.LANCZOS), f"blocks/{name}.png")


if __name__ == "__main__":
    sys.exit(run(__doc__, cut_blocks))
