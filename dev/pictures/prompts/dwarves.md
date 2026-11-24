# Jump 'n' Mine: dwarves

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

## 2. Sheet: the dwarves (one sheet per dwarf color, or all four)

Reference: `dwarf_*_*.png` (160 x 150 at 2x; in the game the dwarf is 76 px tall, feet at the bottom middle, facing right).

> **Sheet: the dwarf, in 12 poses.** A grid of 4 columns x 3 rows, each cell 640 x 600 px (4x the game size), transparent background. The dwarf stands with its feet on the bottom middle of each cell at the same height in every cell, facing **right**, about 300 px tall. Short, stocky and cute (big head, about 2.5 heads tall), steel miner's helmet with a glowing yellow lamp, big fluffy cream-white beard covering the chest, tunic in **red #e04848** with a dark brown belt and a gold buckle, brown boots, a pickaxe with a wooden handle and a steel head.
>
> Row 1: (1) idle, pickaxe resting on the shoulder; (2) walking, left foot forward; (3) walking, right foot forward; (4) pickaxe raised high over the head, ready to strike.
> Row 2: (5) mid-swing; (6) the pickaxe hitting **down** at the ground in front of the feet; (7) the pickaxe hitting **sideways** at head-to-waist height to the right; (8) dizzy: eyes as little X's, three yellow stars circling over the helmet, slightly sooty.
> Row 3: (9) wading under water, a few bubbles rising; (10) holding a **golden** sparkling pickaxe; (11) wearing a glowing blue protective bubble (fire helmet booster); (12) with green springy boots (spring boots booster).
>
> Then make the same sheet three more times, identical except the tunic: **blue #3f8ee8**, **green #3fbf5a**, **yellow #f2b630**.

---

---

The attached pictures show the game as it looks now: `screen_*.png` are screenshots, the others are the current figures at 2x their size in the game (transparent background). Keep their layout, proportions and colors, and make them much more beautiful.
