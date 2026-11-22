"""
Cut the sheets of the dwarves (the poses in jump_n_mine_three_dwarves/ and
jump_n_mine_redesigned_sprites/, the walk cycles in walk/, the sideways strikes
in side/) and of the miner's helmets (helmets/).

Usage:

    python3 dev/pictures/cut_sprites/dwarves.py <folder with the sheets>
"""

import sys
from typing import Dict, Final, List, Optional

from PIL import Image

from common import Sheets, cells, common_box, opaque_height, run, save


DWARF_POSES: Final[List[Optional[str]]] = [
    "idle",
    None,  # the walking frames are replaced by the walk cycles
    None,
    "raised",
    "swing",
    "hit_down",
    "hit_down_b",
    "dizzy",
    "under_water",
    "golden_pickaxe",
    "fire_helmet",
    "spring_boots",
]


DWARF_SHEETS: Final[Dict[str, str]] = {
    "red": "jump_n_mine_three_dwarves/jump_n_mine_dwarf_red.png",
    "blue": "jump_n_mine_redesigned_sprites/a_clean_transparent_png_sprite_sheet_cartoon_game.png",
    "green": "jump_n_mine_three_dwarves/jump_n_mine_dwarf_green.png",
    "yellow": "jump_n_mine_three_dwarves/jump_n_mine_dwarf_yellow.png",
}


#: A dwarf cell of the sheet (362 px) becomes this many pixels; the game draws
#: it at half, so that the dwarf is about 1.05 blocks tall.
DWARF_CELL: Final[int] = 250


#: The frames of the sideways strike (see dev/pictures/prompts/side_strike.md).
SIDE_POSES: Final[List[str]] = ["side_back", "side_hit", "side_recoil"]


#: The feet of the dwarves stand on this line of a 362 px cell (the bottom of
#: their boots, where the boots are nearly opaque).
DWARF_FEET: Final[int] = 327


#: The standing dwarf is this tall in a 362 px cell, from the helmet to the boots.
DWARF_STANDING: Final[int] = 230


def cut_walk_cycles(load: Sheets) -> None:
    """Cut the six frames of the walk cycle of every dwarf."""
    # NOTE (mristin):
    # The walk cycles were painted smaller than the other poses. We scale each
    # sheet as a whole (so that the frames keep their motion) so that the
    # third frame, passing with straight legs and the body at its highest, is
    # as tall as the standing dwarf (230 of 362 px from the helmet to the
    # boots). Every frame stands with its lower foot on the baseline of the
    # other poses.
    for color in DWARF_SHEETS:
        frames = cells(load(f"walk/dwarf_walk_{color}.png"), 6, 1)
        box = common_box(frames)
        scale = DWARF_STANDING / opaque_height(frames[2])
        for k, frame in enumerate(frames):
            dwarf = frame.crop(box)
            dwarf = dwarf.resize(
                (round(dwarf.width * scale), round(dwarf.height * scale)), Image.LANCZOS
            )
            feet = dwarf.getchannel("A").point(lambda a: 255 if a > 200 else 0).getbbox()
            cell = Image.new("RGBA", (362, 362), (0, 0, 0, 0))
            cell.alpha_composite(dwarf, (round(196 - dwarf.width / 2), DWARF_FEET - feet[3]))
            save(
                cell.resize((DWARF_CELL, DWARF_CELL), Image.LANCZOS),
                f"dwarves/{color}/walk_{k + 1}.png",
            )


def cut_side_strikes(load: Sheets) -> None:
    """Cut the frames of the sideways strike of every dwarf."""
    # NOTE (mristin):
    # The sideways strikes were painted at the size of the other poses, but
    # their feet a few pixels too high; we move each sheet as a whole down to
    # the baseline, so that the frames keep their motion.
    for color in DWARF_SHEETS:
        frames = cells(load(f"side/dwarf_side_{color}.png"), 3, 1)
        feet = max(
            frame.getchannel("A").point(lambda a: 255 if a > 200 else 0).getbbox()[3]
            for frame in frames
        )
        for pose, frame in zip(SIDE_POSES, frames):
            cell = Image.new("RGBA", frame.size, (0, 0, 0, 0))
            cell.alpha_composite(frame, (0, DWARF_FEET - feet))
            save(
                cell.resize((DWARF_CELL, DWARF_CELL), Image.LANCZOS), f"dwarves/{color}/{pose}.png"
            )


def cut_dwarves(load: Sheets) -> None:
    """Cut the poses, the walk cycles and the sideways strikes of the dwarves, and the helmets."""
    for color, sheet in DWARF_SHEETS.items():
        for pose, cell in zip(DWARF_POSES, cells(load(sheet), 4, 3)):
            if pose is None:
                # The walking frames of the sheets are replaced by the walk cycles.
                continue
            save(
                cell.resize((DWARF_CELL, DWARF_CELL), Image.LANCZOS), f"dwarves/{color}/{pose}.png"
            )

    cut_walk_cycles(load)
    cut_side_strikes(load)

    # NOTE (mristin):
    # The miner's helmets over the players in the camera picture; the bottom of
    # the brim lies at 75 % of the height of each picture.
    for color in ["red", "blue", "green", "yellow", "white"]:
        helmet = load(f"helmets/helmet_{color}_front.png")
        save(helmet.resize((256, 256), Image.LANCZOS), f"helmets/{color}.png")


if __name__ == "__main__":
    sys.exit(run(__doc__, cut_dwarves))
