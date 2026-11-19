# Jump 'n' Mine: special blocks

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

## 4. Sheet: special blocks

Reference: `bedrock.png`, `explosive.png`, `explosive_lit.png`, `spring_open.png`, `spring_sealed.png`.

> **Sheet: special blocks.** A grid of 5 cells in a row, each 320 x 320 px, tiles fill their cells edge to edge: (1) **bedrock**, the unbreakable wall and floor of the mine: very dark #2a2228 with diagonal strata, heavy and ancient; (2) **explosive block**: a red #d8231c wooden crate, yellow-and-black hazard stripes along the top and bottom, a round black bomb with a short fuse in the middle; (3) the same explosive block **lit**: brighter red-orange, the fuse sparking, a glow around it; (4) a **spring** set into the dark side wall: a blue #2f7fd8 crack in the rock with clear water gushing out to the right; (5) the same spring **sealed** with a round stone plug and a little cork.

---

> **Sheet: cracks.** A row of 3 cells, each 320 x 320 px, transparent background: dark crack overlays (#1a1016 with a thin light edge) to lay over any block: (1) a small crack from one point, (2) bigger branching cracks, (3) the block nearly shattered, with chips missing at the edges. They must not cover the whole tile; the block should still show through.

---

The attached pictures show the game as it looks now: `screen_*.png` are screenshots, the others are the current figures at 2x their size in the game (transparent background). Keep their layout, proportions and colors, and make them much more beautiful.
