# Jump 'n' Mine: dragon

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

## 6. Sheet: the dragon and its fire

Reference: `dragon_glow_0.png`, `dragon_glow_1.png`, `fire.png`.

> **Sheet: the dragon.** A grid of 4 cells in a row, each 800 x 600 px, transparent background, facing **right**, seen from the side while flying: a chubby, mischievous purple #8a3fd0 dragon with an orange-yellow #f0b04f belly, small horns, big friendly eyes, bat wings. (1) wings up; (2) wings down; (3) about to spit: cheeks puffed, mouth glowing orange; (4) spitting a burst of fire downwards.
>
> **Sheet: fire.** A row of 3 cells, 200 x 360 px, transparent: a ball of fire falling **down** (the bright yellow-white core at the bottom, orange flames trailing upward), in three animation frames.

---

---

The attached pictures show the game as it looks now: `screen_*.png` are screenshots, the others are the current figures at 2x their size in the game (transparent background). Keep their layout, proportions and colors, and make them much more beautiful.
