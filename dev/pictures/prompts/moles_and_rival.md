# Jump 'n' Mine: the moles and the evil miner

Until these are painted, the game draws the moles in code and the evil miner as a red dwarf in the shadows with the badge of Queen Treacher (`scenes/art/art.gd`). Cut the sheets into:

* `assets/pictures/dwarves/evil/<pose>.png`, the same 18 poses and cells as the dwarves (see `dwarves.md` and `walk.md`: `idle`, `raised`, `swing`, `hit_down`, `hit_down_b`, `dizzy`, `under_water`, `side_back`, `side_hit`, `side_recoil`, `walk_1` to `walk_6`, and the three booster poses may stay out); `Art.dwarf` takes them as soon as they are there.
* `assets/pictures/mole/` (to draw them in `Art.mole`): `dig`, `peek_1`, `peek_2`, `cry_1`, `cry_2`.

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


## 2. Sheet: the evil miner

Reference: `dwarf_red_*.png`.

> **Sheet: the evil miner of Queen Treacher, in the same poses and the same grid as the dwarf sheet** (4 columns x 3 rows, cells 640 x 600 px, feet on the bottom middle, facing right). He is a dwarf like the others, but sneaky and grumpy: dark violet-grey tunic #3a2a48, a grey beard, bushy eyebrows, a black helmet without a lamp, and on his chest the badge of Queen Treacher: a black crown on a purple circle. In the "dizzy" pose, little yellow stars circle over his head. Funny, never scary.

## 3. Sheet: the mole

> **Sheet: a friendly mole, 5 cells in a row**, each 400 x 300 px, transparent background, facing right, about 260 px long: a round, velvety dark brown body, a pink star-shaped nose, tiny closed eyes, big pink digging paws, a little earth on its head. Cells: (1) digging forward, paws ahead; (2) peeking up, looking left; (3) peeking up, looking right; (4) crying, eyes squeezed shut, big blue tears flying; (5) crying, rubbing its eyes with a paw. Cute and soft, like a plush toy.
