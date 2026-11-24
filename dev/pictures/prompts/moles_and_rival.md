# Jump 'n' Mine: the moles and the evil miner

Until these are painted, the game draws the moles in code and the evil miner as a red dwarf in the shadows with the badge of Queen Treacher (`scenes/art/art.gd`). Cut the sheets into:

* `assets/pictures/dwarves/evil/<pose>.png`, the 16 poses of the sheet below (`idle`, `walk_1` to `walk_6`, `raised`, `swing`, `hit_down`, `hit_down_b`, `dizzy`, `under_water`, `side_back`, `side_hit`, `side_recoil`); `Art.dwarf` takes them as soon as they are there.
* `assets/pictures/mole/` (to draw them in `Art.mole`): `dig_1`, `dig_2`, `peek_1`, `peek_2`, `cry_1`, `cry_2`.

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

Reference: `dwarf_red_*.png`, and the sketch of the sheet, written by `python3 dev/pictures/intro/make_evil_miner_sheet.py <folder>`.

> **Sheet: the evil miner of Queen Treacher, 16 poses.** Follow the attached sketch `sketch_evil_miner_sheet.png`: a grid of **4 columns x 4 rows**, each cell **640 x 600 px**, transparent background, no grid lines and **no text** (the labels in the sketch are only for you). In every cell he stands with his feet on the same baseline (40 px above the bottom of the cell, the dotted line in the sketch), in the middle, facing **right**, about 300 px tall, exactly as big as the dwarves in the attached `dwarf_red_*.png`.
>
> He is a dwarf like the others, but sneaky and grumpy: a **dark violet-grey tunic #3a2a48**, a **grey beard**, bushy frowning eyebrows, a **black helmet without a lamp**, brown boots, a steel pickaxe with a wooden handle, and on his chest the **badge of Queen Treacher: a black crown on a purple circle** (it must show in every pose, not hidden by the beard). Funny, never scary.
>
> The poses, row by row, as in the sketch and like the matching pictures of the red dwarf:
> 1. **idle**: standing, the pickaxe held in front of him, its head up to the right;
> 2.–7. **walk_1** to **walk_6**: a walk cycle of six frames, the legs stepping as in the sketch, the pickaxe held as in idle;
> 8. **raised**: the pickaxe raised high over his head, ready to strike;
> 9. **swing**: mid-swing, the pickaxe coming down in front, a motion streak;
> 10. **hit_down**: the pickaxe hitting the ground in front of his feet, crumbs of earth flying;
> 11. **hit_down_b**: the next moment, the pickaxe deeper in the ground, sparks and crumbs;
> 12. **dizzy**: knocked out, eyes as little X's, three yellow stars circling over his helmet, the pickaxe hanging down;
> 13. **under_water**: wading in water up to his chest, a few bubbles rising;
> 14. **side_back**: the pickaxe wound back over his shoulder, ready to strike sideways;
> 15. **side_hit**: the pickaxe striking **sideways** to the right at chest height, with an impact flash;
> 16. **side_recoil**: the pickaxe bouncing back from the sideways strike, a few chips flying.

## 3. Sheet: the mole

Reference: the first attempt, which painted a front view cut off at the bottom, a star-shaped nose and dirt on its head; the prompt below fixes them.

**Redo of the mole sheet.** I attached your last sheet (`mole_sheet_previous.png`). The style is lovely, but it does not work in the game. Please fix these points:

1. **Side view, whole body.** In the game the mole crawls **sideways through a tunnel**, so draw it **from the side, its whole body visible**: a round, plump body, a short pink tail, four short pink legs with big digging claws on the front paws, standing on the bottom of the cell. **No** front view and **no** body cut off at the bottom as if it pokes out of a hole.
2. **A plain round nose.** A small, round, **pink button nose** at the tip of a short pointed snout, and a few thin whiskers. **No star-shaped nose.**
3. **No dirt on its head.** Clean, soft fur; at most a few crumbs of earth flying around the claws while it digs.
4. **Readable in a dark cave.** The cave behind it is dark violet (#241a33), so make the fur a **warm light cocoa** (#9a7058) with a creamy belly (#e8c8a8) and a soft warm rim light on its back, with the dark outline (#1a1016) around it.
5. **Always facing right**, with the same size and the feet on the same baseline in every cell; the mole fills its cell (about 340 px long, 200 px tall, 30 px margin).

> **Sheet: a friendly mole, 6 cells in a row**, each 400 x 300 px, transparent background, side view facing right, as above. Cute and soft, like a plush toy, with tiny closed or dot eyes:
> 1. **dig_1:** crawling forward, front claws stretched ahead and scooping, a few crumbs flying ahead;
> 2. **dig_2:** the next step of crawling: front claws pulled back, hind legs pushing, crumbs flying;
> 3. **peek_1:** standing still, looking back over its shoulder, head turned towards the viewer;
> 4. **peek_2:** standing still, snout raised, sniffing the air, whiskers twitching;
> 5. **cry_1:** sitting back on its hind legs, eyes squeezed shut, mouth open, big blue tears flying from both eyes;
> 6. **cry_2:** sitting back, rubbing one eye with a front paw, a single tear on its cheek, sniffling.
