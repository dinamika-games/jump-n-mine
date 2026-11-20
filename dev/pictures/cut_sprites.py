#!/usr/bin/env python3
"""
Cut the painted sprite sheets into the pictures of the game, assets/pictures/.

The sheets were painted from the prompts in dev/pictures/prompts/ (see
CONTRIBUTING.md). Unpack them into one folder (the helmets into helmets/, the
walk cycles into walk/, the sideways strikes into side/) and run:

    python3 dev/pictures/cut_sprites.py <folder with the sheets>

Every sheet is a grid of equal cells. We cut the cells, scale them to twice
their size in the game (the game draws them at half), and keep their
transparency. The dwarves keep their whole cells, so that their feet stay on
the same baseline in every pose; the items and the dragon are cut to their
common bounding box.
"""

import argparse
import pathlib
import sys

from PIL import Image

REPO = pathlib.Path(__file__).resolve().parents[2]
OUTPUT = REPO / "assets" / "pictures"

DWARF_POSES = [
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

DWARF_SHEETS = {
    "red": "jump_n_mine_three_dwarves/jump_n_mine_dwarf_red.png",
    "blue": "jump_n_mine_redesigned_sprites/a_clean_transparent_png_sprite_sheet_cartoon_game.png",
    "green": "jump_n_mine_three_dwarves/jump_n_mine_dwarf_green.png",
    "yellow": "jump_n_mine_three_dwarves/jump_n_mine_dwarf_yellow.png",
}

WORLDS = ["copper_hills", "sunken_halls", "dragon_deeps"]

# The size of a block on the screen is 80 px; we keep twice as many pixels.
BLOCK = 160

# A dwarf cell of the sheet (362 px) becomes this many pixels; the game draws
# it at half, so that the dwarf is about 1.05 blocks tall.
DWARF_CELL = 250

# The frames of the sideways strike (see dev/pictures/prompts/side_strike.md).
SIDE_POSES = ["side_back", "side_hit", "side_recoil"]

# The feet of the dwarves stand on this line of a 362 px cell (the bottom of
# their boots, where the boots are nearly opaque).
DWARF_FEET = 327

# The standing dwarf is this tall in a 362 px cell, from the helmet to the boots.
DWARF_STANDING = 230


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


def cut_walk_cycles(load) -> None:
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


def cut_side_strikes(load) -> None:
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


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", help="the folder with the unpacked sheets")
    args = parser.parse_args()
    source = pathlib.Path(args.folder)

    def load(relative: str) -> Image.Image:
        return Image.open(source / relative).convert("RGBA")

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

    item_names = [
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
    for name, cell in zip(item_names, cells(load("items.png"), 4, 3)):
        box = cell.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox()
        save(fit(cell.crop(box), 128 if not name.startswith("gem") else 96), f"items/{name}.png")

    dragon = cells(load("jump_n_mine_dragon_consistent/dragon_sheet_consistent.png"), 4, 1)
    box = common_box(dragon)
    for k, frame in enumerate(dragon):
        save(fit(frame.crop(box), 420), f"dragon/frame_{k + 1}.png")
    fire = cells(load("jump_n_mine_dragon_consistent/fire_sheet.png"), 3, 1)
    box = common_box(fire)
    for k, frame in enumerate(fire):
        save(fit(frame.crop(box), 140), f"dragon/fire_{k + 1}.png")

    # NOTE (mristin):
    # The miner's helmets over the players in the camera picture; the bottom of
    # the brim lies at 75 % of the height of each picture.
    for color in ["red", "blue", "green", "yellow", "white"]:
        helmet = load(f"helmets/helmet_{color}_front.png")
        save(helmet.resize((256, 256), Image.LANCZOS), f"helmets/{color}.png")

    title = Image.open(source / "jump_n_mine_title/jump_n_mine_title_1920x1080.png").convert("RGB")
    save(title, "title.png")
    return 0


if __name__ == "__main__":
    sys.exit(main())
