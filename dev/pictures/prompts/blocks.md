# Jump 'n' Mine: blocks

## 1. Style brief (send first)

> I'm making **Jump 'n' Mine**, a 2D side-view game for children of about 6–10, played by jumping in front of a webcam. Each child is a dwarf in a mine. Stepping left and right walks the dwarf, and each real jump swings its pickaxe at a block. Blocks crack and break after 3–4 hits. One to four dwarves dig together in one mine, down to a treasure chest at the bottom. There are gems, boosters, explosive blocks, springs that flood the mine with water, and dragons that fly in above and spit fire. Nobody dies: a dwarf hit by fire or an explosion is only dizzy for a moment.
>
> I attached screenshots of the current game and the current figures. Their layout, proportions and colors are correct, but the drawing is flat and plain. I want you to **redraw the art at a much higher quality, in the same layout**.
>
> **Style:** a bright, friendly, hand-painted cartoon look, like a modern children's picture book or a cozy indie game. Clean bold dark outlines (about 3 px at the game size, color #1a1016), soft shading with a light source from the top left, chunky readable shapes, slightly rounded corners. No realism, no gore, nothing scary. The dragons are mischievous, not menacing.
>
> **Readability rules (very important):** the game is seen from 2–3 meters away on a laptop or a projector.
> - The **cave background is always dark and cool** (violet / navy / near-black), and the **blocks are always light and warm** (sand, ochre, copper, tan), so that open cave and solid block can never be confused.
> - **Granite** (unbreakable) is cool grey with silver specks and a harder, more angular look than the earth.
> - **Explosive blocks** are unmistakable: a red crate with yellow-and-black hazard stripes and a black round bomb with a fuse.
> - **Springs** are blue, set in the dark side walls.
> - **Gems and boosters** glow and sparkle so they pop out of the blocks.
> - Each dwarf is told apart by its **tunic color**: red #e04848 (Brakka), blue #3f8ee8 (Odda), green #3fbf5a (Grumli), yellow #f2b630 (Tilda). Everything else about the four dwarves is the same: steel helmet with a yellow lamp, big cream beard, brown boots, a wooden-handled steel pickaxe.
>
> **Technical:** every sprite on a **fully transparent background** (PNG with alpha), no drop shadow outside the sprite, no text, no watermark. When I ask for a sheet, lay the sprites out on an exact grid of equal cells with transparent gaps, so that I can cut them apart by code. Blocks are square tiles that must sit **edge to edge** in a grid without gaps. Draw at 2x or 4x the game size given; I scale down.
>
> Then draw the sheet below.

---

## 3. Sheet: the blocks of the three worlds

Reference: `<world>_earth_after_<n>_hits.png`, `<world>_rock_after_<n>_hits.png`, `<world>_granite.png`, `<world>_cave_background.png`, `<world>_sky_and_grass.png`, and the screens `screen_level_world_1/2/3.png`. A block is 80 x 80 px in the game.

> **Sheet: block tiles for three worlds.** A grid of 6 columns x 3 rows, each cell exactly 320 x 320 px (4x the game size). Each tile is a square block of a mine, seen from the side, **fills its cell edge to edge** so tiles sit together seamlessly in a grid, chunky and hand-painted with a dark outline, light from the top left. Draw each tile **without cracks**; I'll ask for the cracks separately.
>
> Row 1, **The Copper Hills** (sunny, warm): (1) soft sandy earth #d99a52 with a few pebbles; (2) a second variation of the same earth; (3) hard copper-brown rock #a8653a, with darker stones and a glint of copper ore; (4) a second variation of the rock; (5) granite, cool grey #7d8794 with silver specks, angular, clearly harder than everything else; (6) the top earth block with a lush green grass edge #5cb84a.
> Row 2, **The Sunken Halls** (an old mine under a lake, damp): the same six tiles with earth #cdb38a (pale sandstone), rock #9a8466 (grey-brown, with a little moss and water drips), granite #5f6b78, grass #4fa36b.
> Row 3, **The Dragon Deeps** (warm, volcanic): the same six tiles with earth #d4a57a (light tan), rock #a3705a (reddish, with faint glowing ember veins), granite #6e6a78, grass #8a9a3c (dry).

> **Sheet: cracks.** A row of 3 cells, each 320 x 320 px, transparent background: dark crack overlays (#1a1016 with a thin light edge) to lay over any block: (1) a small crack from one point, (2) bigger branching cracks, (3) the block nearly shattered, with chips missing at the edges. They must not cover the whole tile; the block should still show through.

> **Sheet: cave backgrounds.** Three wide images, 1280 x 960 px each, **seamlessly tileable** horizontally and vertically: the far wall of a cave, dark and cool so the light blocks stand out: (1) violet #241a33 with darker #31243f rocks, faint crystals; (2) deep navy #121c2b with #1b2a3d rocks, drips and faint glowing moss; (3) near black red #1f0f14 with #2e161d rocks and faint embers. Low contrast, no bright spots, nothing that looks like a solid block.

> **Sheet: skies.** Three images 1920 x 400 px for above the mine, each with distant hills along the bottom: (1) bright blue sky #7ec8f0 to #d8f0ff, green hills; (2) misty blue #8fb4d9 to #e2ecf5 over a lake with far hills; (3) warm evening #e8916b to #f8d9a8 with distant volcanoes and a dragon silhouette.

---

---

The attached pictures show the game as it looks now: `screen_*.png` are screenshots, the others are the current figures at 2x their size in the game (transparent background). Keep their layout, proportions and colors, and make them much more beautiful.
