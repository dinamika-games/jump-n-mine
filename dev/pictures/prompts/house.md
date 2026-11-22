# Jump 'n' Mine: the dwarves' house

The game draws the dwarves' house in code (`scenes/house/house_art.gd`), flat and plain. We paint it step by step: first the house itself (the shack before any improvement, in its landscape), and once that is painted, the 50 improvements (`Economy.HOUSE_PARTS`, ten parts of five stages each) as transparent layers on the same canvas, so that the game lays them over the shack without fitting them.

The sketch of the house is written by `python3 dev/pictures/house/make_house_sketch.py <folder>`. It follows the stage of `HouseArt` (1200 x 520) at twice the size, 2400 x 1040.

Attach to the prompt:

* `sketch_house_base.png`, the layout to follow;
* `now_house_empty.png` and `now_house_full.png`, the house as the game draws it now, before any improvement and with all 50 (screenshots of `dev/pictures/take_screenshots.py --only house_empty house_full`, cut to the picture of the house);
* `title.png` (`assets/pictures/title.png`) and `dwarf_red_idle.png` (`assets/pictures/dwarves/red/idle.png`), for the style.

## 1. Style brief (send first)

> I'm making **Jump 'n' Mine**, a 2D game for children of about 6–10, played by jumping in front of a webcam. Each child is a dwarf who digs down through a mine to a treasure. With the gems they find, the dwarves build up **their house**, step by step, from a shabby little shack to a small palace with a tower, a garden, a fence, a decorated mine entrance and a village square — like the palace in Civilization III. The house is shown on a screen between the levels; the children look at it from 2–3 meters away on a laptop or a projector.
>
> I attached the title painting (`title.png`) and a dwarf (`dwarf_red_idle.png`) of the game: **paint in exactly their style.** A bright, friendly, hand-painted cartoon look, like a modern children's picture book or a cozy indie game. Clean bold dark outlines (color #1a1016), soft shading with the light from the top left, chunky readable shapes, slightly rounded corners, warm and cheerful colors. No realism, nothing scary.
>
> I also attached how the game draws the house now (`now_house_empty.png`, before any improvement, and `now_house_full.png`, with all of them). Their layout is right, but the drawing is flat and plain. **Redraw it at a much higher quality, in the same layout.**
>
> **Technical:** no text, no watermark, no signature. Keep **exactly** the layout of the sketch I attach with each request: the same canvas size, the same positions and sizes of every part, the same horizon, so that later pictures can be laid exactly over this one.
>
> Then draw the picture below.

## 2. The house before any improvement

> **The dwarves' house before any improvement: a shack in a meadow.** One picture of **2400 x 1040 px**, landscape, following the attached sketch `sketch_house_base.png` exactly (the magenta dashed areas and the labels in the sketch are only for you — **do not draw them**).
>
> * **The landscape:** a soft blue sky with a pale sun at the top right and a few light clouds; two gentle green hills behind; a flat green meadow from the horizon (at 85 % of the height, as in the sketch) down to the bottom. Calm, so that the house stands out.
> * **The shack, in the middle,** exactly where the sketch puts it (the walls from x = 840 to 1560, from y = 520 down to the meadow at y = 880; the roof up to its tip at y = 240): small, shabby, but cozy and loved, so that the children want to improve it. **Walls of weathered grey wooden planks**, standing upright, some a bit crooked, a knot here and there. A **saggy roof of grey boards** with a patched board nailed on crooked. **Two empty window holes** (dark, no glass, no shutters) and a **rough door of four grey-brown boards** in the middle, with a simple latch. A worn **sandy path** from the door down to the bottom of the picture.
> * **The mine on the left:** a round earthen hill with a dark, arched hole into the mine, exactly as in the sketch; plain earth, without any timber, rails or lamps yet.
> * **Keep the dashed areas free**, plain sky and meadow: the tower to the right of the shack, the chimney on the right half of the roof, the village square on the right, the garden left of the path, and the fence in front of the shack. **No** chimney, tower, fence, garden, flowers, furniture, dwarves or animals: they come later, one by one.
> * The parts must look like **separate pieces** (the walls, the roof, the door, the two windows), each with its own clear outline, since they will be replaced one by one: the plank walls by logs, a timber frame, stone and marble, the board roof by straw, shingles, tiles and gold, and so on (see `now_house_full.png`).

## 3. Sheet: the walls

The painted shack (`house_base.png`, 1905 x 825) kept the layout of the sketch. From here on, every part is painted as a sheet of sprites on a transparent background, one cell per stage, since an image generator does not keep the layout over 50 repaints exactly: the game scales each sprite into the rectangle of its part. The walls come first; their sheet has the planks of the shack as its first cell, so that the game can lay any stage over the landscape without the shack.

Attach `house_base.png` (the painted shack), `sketch_walls_sheet.png` (written by `make_house_sketch.py`), `now_walls_stages.png` (the six stages as the game draws them now, cut from screenshots with `--house=0` to `--house=5`) and `title.png`. Send the style brief first, with the first paragraph below in place of its second and third ones, and the second in place of its last two:

> I attached the painting of the dwarves' house before any improvement (`house_base.png`). **Its style is exactly right: paint everything in exactly that style**, with the same outlines, the same light and the same colors, so that the new pieces fit into it seamlessly. I also attached how the game draws the parts now (flat and plain): they show what each stage is, but redraw them at the quality of the painting.

> **Technical:** no text, no watermark, no signature. Keep **exactly** the grid and the boxes of the sketch I attach, so that I can cut the pieces apart by code and fit them into the painting.
>
> **Transparency (very important):** deliver a PNG with a **real alpha channel**, where the background pixels are fully transparent. **Do not paint a grey-and-white checkerboard** to suggest transparency: a painted checkerboard is opaque pixels, and I cannot use it. If you cannot make real transparency, fill the whole background with **one flat, pure magenta (#FF00FF)**, with no gradient, no checkerboard, no shadow and no glow on it, and use no magenta in the pieces themselves.
>
> Then draw the sheet below.

> **Sheet: the front wall of the dwarves' house in six stages.** Follow the attached sketch `sketch_walls_sheet.png`: a grid of **3 columns x 2 rows**, each cell **1000 x 500 px**, on a **fully transparent background** (see the transparency above), no grid lines and **no text** (the labels in the sketch are only for you).
>
> In every cell, paint **only the front wall** of the house, seen straight from the front like in `house_base.png`: **exactly the dashed box** of the sketch, **800 x 370 px**, its bottom edge standing on the dotted baseline 40 px above the bottom of the cell, the same size and place in every cell. **No roof, no door, no windows, no chimney, no ground, no grass, no shadow** outside the wall: they are separate pieces. The dotted grey areas are where the windows and the door will be laid over the wall later: **paint the wall straight through them**, as plain wall.
>
> The stages, from left to right and top to bottom; each looks richer than the one before, so that the children see their house grow:
> 1. **planks:** the weathered grey upright planks of the shack in `house_base.png`, exactly as painted there (some crooked, knots, nails);
> 2. **log walls:** warm brown round logs lying one on the other, with their round sawn ends showing at both corners (inside the box);
> 3. **timber frame:** cream plaster between dark brown wooden beams (a beam along the bottom and the top, posts at the corners and in between, a few diagonal braces);
> 4. **stone walls:** sturdy grey stone blocks of different sizes, neatly fitted, with lighter corner stones;
> 5. **carved stone:** smooth, light sandstone blocks, with carved pillars at the corners and a carved band of little gems and pickaxes along the top;
> 6. **marble and gold:** gleaming white marble with golden pilasters at the corners, a golden band along the top and the bottom, and a few small sparkling gems set into the gold.

## 4. Sheet: the roof

The painted walls (`walls_sheet.png`) kept their boxes; the game takes them as `assets/pictures/house/walls/<stage>.png` (`python3 dev/pictures/cut_sprites.py --house <folder>`). The roof follows the same pattern: its sheet has the grey boards of the shack as its first cell, and its eaves sit on the baseline of its cells, so that it can be laid onto the walls.

Attach `house_base.png`, `sketch_roof_sheet.png` (written by `make_house_sketch.py`), `walls_sheet_painted.png` (the painted walls), `now_roof_stages.png` (the six stages as the game draws them now, cut from screenshots with `--house=0` to `--house=5`; the rose window of the golden roof belongs to the windows, and the chimneys are a part of their own) and `title.png`. Send the style brief of the walls (section 3) first, then:

> **Sheet: the roof of the dwarves' house in six stages.** Follow the attached sketch `sketch_roof_sheet.png`: a grid of **3 columns x 2 rows**, each cell **1000 x 500 px**, on a **fully transparent background** (see the transparency above), no grid lines and **no text** (the labels in the sketch are only for you).
>
> In every cell, paint **only the roof** of the house, seen straight from the front like in `house_base.png`: a gable roof filling **exactly the dashed triangle** of the sketch, **880 px wide** from eave to eave and **345 px high**, its straight bottom edge (the eaves) lying on the dotted baseline 40 px above the bottom of the cell, its tip in the middle, the same size, slope and place in every cell. The dotted grey ticks below the baseline show where the walls stand under it: the roof overhangs them by about 60 px on each side. The roof sits on top of the walls in the attached `walls_sheet_painted.png`, which I already have, so match their style and their outlines.
>
> **No walls, no chimney, no windows** (apart from the dormer of stages 5 and 6), **no sky, no smoke, no shadow** outside the roof: they are separate pieces. Keep the roof inside the triangle; only on the golden roof may a small ornament on the tip rise up to 30 px above it.
>
> The stages, from left to right and top to bottom; each looks richer than the one before, so that the children see their house grow:
> 1. **boards:** the saggy roof of weathered grey boards of the shack in `house_base.png`, exactly as painted there, with the crooked patch nailed on;
> 2. **straw roof:** a thick, cozy thatched roof of golden straw, its edges trimmed, a bit shaggy at the eaves;
> 3. **wooden shingles:** neat rows of warm brown wooden shingles, overlapping like fish scales, with a wooden ridge along the top;
> 4. **red tiles:** rows of rounded terracotta-red clay tiles, with a ridge of tiles along the top;
> 5. **slate and dormer:** dark blue-grey slate tiles, with a small **dormer** (a little gabled window with white frames and light blue glass) in the right half of the roof, as in the stage of the game I attached;
> 6. **golden roof:** gleaming golden tiles with a shine, a golden ridge, a small golden star or gem ornament on the tip, and the dormer of stage 5 in gold and white.

## 5. The landscape without the shack

The roofs came back on a painted checkerboard instead of a transparent background; `cut_sprites.py` floods it away from the edges of the cells (it stops at the dark outlines), and the transparency paragraph in the style brief of section 3 now asks for real transparency, or a flat magenta background, which the script removes the same way.

The game lays the painted parts over the landscape, so it needs the landscape of the painted shack without the shack. Attach `house_base.png` and `title.png`, and send the style brief of section 2 (the picture, not the sheets) first, then:

> **The same picture without the shack.** Repaint the attached `house_base.png` **exactly**: the same size (1905 x 825 px), the same sky, sun, clouds, hills, meadow, mine hill and path, all at the same places, in the same style. Only **remove the shack** completely: where it stood, continue the meadow and the hills behind it, as if the shack had never been there, with no shadow, no marks and no foundation left. The sandy path stays and ends where the door was. Add nothing else.

## 6. Sheet: the door

The doors are laid over the walls, so they are painted like the walls, in their own sheet. Attach `house_base.png`, `sketch_door_sheet.png` (written by `make_house_sketch.py`), `walls_sheet_painted.png` (the painted walls, which the door sits on), `now_door_stages.png` (the six stages as the game draws them now) and `title.png`. Send the style brief of section 3 first, then:

> **Sheet: the front door of the dwarves' house in six stages.** Follow the attached sketch `sketch_door_sheet.png`: a grid of **3 columns x 2 rows**, each cell **500 x 500 px**, on a **fully transparent background** (see the transparency above), no grid lines and **no text** (the labels in the sketch are only for you).
>
> In every cell, paint **only the door** with its frame, seen straight from the front like in `house_base.png`: filling **exactly the dashed box** of the sketch, **276 x 360 px**, its bottom edge standing on the dotted baseline 40 px above the bottom of the cell, the same size and place in every cell (an arched door fills the box up to the top of its arch; the corners beside the arch stay transparent). **No wall around the door, no steps, no ground, no shadow** outside the door: the door is laid over the walls of the attached `walls_sheet_painted.png`, so it must look good on all of them.
>
> The stages, from left to right and top to bottom; each looks richer than the one before, so that the children see their house grow:
> 1. **shack door:** the rough door of four grey-brown boards with the simple iron latch, exactly as painted in `house_base.png`;
> 2. **plank door:** a sturdy, neat door of straight light-brown planks, held by two cross battens and a diagonal brace, with a wooden handle;
> 3. **oak door:** a solid door of dark oak with four carved panels and a round brass knob, in a wooden frame;
> 4. **iron-bound door:** the oak door with black iron bands and rivets across it, big iron hinges and an iron ring as the handle;
> 5. **arched gate:** a tall double door with a **rounded arched top**, iron bands, two iron ring handles, in an arched frame of light stone;
> 6. **gem-studded gate:** the arched gate with golden bands and hinges, a golden arched frame, and colorful sparkling gems (red, blue, green, yellow) set into the gold.

## 7. Sheets of the other parts

The painted landscape (`landscape.png`) kept the layout, and the doors came back with real transparency. The other seven parts are painted the same way, each on a sheet of its own. Their sketches and `layout_of_the_pieces.png` (where every piece stands on the landscape, and how big it is there) are written by `python3 dev/pictures/house/make_part_sheets.py <landscape.png> <folder>`; the places of the pieces in that script are where the game will draw them.

The windows, the chimney, the tower and the fence change from stage to stage (each stage replaces the piece before); the garden, the mine entrance and the village square grow (each stage adds a piece at its own place).

For every sheet, attach the sketch, `layout_of_the_pieces.png`, `house_base.png`, `landscape.png`, the references named below and `title.png`, and send the style brief of section 3 first (the version with the transparency), then the sheet. Every sheet starts like this, with its grid and its cells from the sketch:

> **Sheet: {title}.** Follow the attached sketch `{sketch}`: a grid of **3 columns x 2 rows**, each cell **{cell} px**, on a **fully transparent background** (see the transparency above), no grid lines and **no text** (the labels in the sketch are only for you). Paint in each cell **only the piece named there**, filling **exactly the dashed box** of its cell (the boxes have the proportions of the places of the pieces), standing on the dotted baseline; leave a cell without a box empty. The attached `layout_of_the_pieces.png` shows where each piece will stand on the painted landscape, and how big it will be there, so keep the pieces **bold and simple enough to read at that size**. No ground, no grass and no shadow outside the pieces, unless I ask for them.

### 7.1 The windows

References: `walls_sheet_painted.png` (the windows are laid over the walls), `now_windows_stages.png`.

> **Sheet: the window of the dwarves' house in five stages, and a rose window.** {start}
>
> The game puts the window twice into the front wall, left and right of the door, over any of the walls in `walls_sheet_painted.png`. The **dotted grey square** in the sketch is the window opening: keep it at **exactly the same size and place in every stage**; the shutters reach out left and right of it, and the flower box hangs below it, inside the dashed box.
> 1. **hole:** the empty dark window hole of the shack in `house_base.png`, with its rough frame of boards — only the square, nothing beside or below it;
> 2. **shutters:** a simple wooden window frame without glass, dark inside, with two green wooden shutters opened to the sides;
> 3. **glass windows:** a white wooden frame with four panes of light blue glass with a shine, the green shutters open beside it;
> 4. **flower boxes:** the glass window with its shutters, and a wooden flower box below it, full of red, yellow and pink flowers;
> 5. **stained glass:** the window with colorful stained glass panes (red, blue, yellow, green) between lead lines, in a carved stone frame, with the flower box;
> 6. **rose window:** a round rose window of stained glass (a wheel of colorful petals in a golden ring), which sits high in the front of the roof; it fills the whole box.

### 7.2 The chimney

References: the painted roofs (`roof_sheet_painted.png`, the chimney stands behind them), `now_chimney_stages.png`.

> **Sheet: the chimney of the dwarves' house in five stages.** {start}
>
> The chimney stands on the roof: the roof hides its lower part (about the lower 40 % of the box), so it just continues straight down there. **No smoke**: the game draws the smoke. Each chimney fills the height of the box, and may be narrower than it.
> 1. **clay pipe:** a thin, slightly crooked pipe of reddish clay, about a third as wide as the box, with a little cap;
> 2. **brick chimney:** a square chimney of red bricks, with a darker band at the top;
> 3. **stone chimney:** a chimney of grey fieldstones with a stone slab on top;
> 4. **twin chimneys:** a proud chimney of cut light stone with a decorative crown at the top (the game draws it twice, on both sides of the roof);
> 5. **forge chimney:** a dark chimney of iron and black bricks with a little iron hood, orange embers glowing in its mouth.

### 7.3 The tower

References: `now_tower_stages.png`.

> **Sheet: the tower beside the dwarves' house in five stages.** {start}
>
> The tower stands on the ground beside the house, behind its right corner. The stages share the baseline and the middle of the box; the first two do not need the whole height.
> 1. **lookout post:** a wooden lookout on four tall stilts, with a ladder and a little pointed roof of boards, about two thirds of the height of the box;
> 2. **stone tower:** a round tower of grey stones with battlements and a few small windows, about three quarters of the height;
> 3. **tower with a flag:** the stone tower at the full height, with a pointed red roof and a red flag with a golden star on top;
> 4. **clock tower:** the tower with a big round clock face (white with black hands, no numbers) below its roof;
> 5. **crystal spire:** the clock tower crowned with a tall, sparkling light blue crystal spire instead of the roof, glowing softly, the flag on its tip.

### 7.4 The fence

References: `now_fence_stages.png`.

> **Sheet: the fence in front of the dwarves' house in five stages.** {start}
>
> The fence runs straight across the front of the house, seen from the front. The sandy path goes through it: leave an **opening in the middle, a ninth of the width**, with a post on both sides (an open little gate in it is fine). The low stages may be lower than the box; all stand on the baseline.
> 1. **stick fence:** crooked wooden sticks tied to a rail, low and wobbly;
> 2. **picket fence:** a neat white picket fence with pointed tops;
> 3. **stone wall:** a low wall of grey fieldstones with flat cap stones;
> 4. **iron fence:** black iron bars with golden spear tips, between square stone posts;
> 5. **hedge with arches:** a trimmed green hedge with little pink flowers, and a green leafy arch over the opening, as high as the box.

### 7.5 The garden

References: `now_house_full.png` (the house as the game draws it now with everything built).

> **Sheet: the garden of the dwarves' house, five pieces.** {start}
>
> Each stage adds a piece at its own place (see `layout_of_the_pieces.png`); they all stay.
> 1. **flowers:** a strip of colorful flowers (tulips, daisies, bluebells) in a little bed;
> 2. **vegetable beds:** two wooden raised beds with carrots, cabbages and a pumpkin, seen slightly from above;
> 3. **mushroom patch:** a cluster of cute red mushrooms with white dots, big and small;
> 4. **pond:** a small oval pond seen slightly from above, blue water with a shine, water lilies, round stones around it;
> 5. **fountain:** a stone fountain with a round basin on a pillar and arcs of water falling down; it stands in the middle of the pond, so paint only the fountain, without the pond.

### 7.6 The mine entrance

References: `now_house_full.png`.

> **Sheet: the entrance of the mine, five pieces.** {start}
>
> Each stage adds a piece around the dark mine entrance in the hill on the left of `landscape.png` (see `layout_of_the_pieces.png`); they all stay. Where a piece frames the entrance, **its inside stays transparent**, so that the painted dark hole shows through.
> 1. **timber props:** a frame of thick wooden beams around the arched entrance: two posts and a beam across the top, the inside transparent;
> 2. **rails:** two iron rails on wooden sleepers, coming out of the mine towards the viewer and down to the right, transparent between the sleepers;
> 3. **mine cart:** a wooden mine cart with iron bands and four wheels, full of sparkling gems, seen from the side;
> 4. **lantern:** an iron oil lantern hanging from a hook, glowing warm yellow (the game hangs it on both sides of the entrance);
> 5. **gem gate:** a golden arch studded with colorful gems, which frames the entrance over the timber props, the inside transparent.

### 7.7 The village square

References: `now_house_full.png`.

> **Sheet: the village square, five pieces.** {start}
>
> Each stage adds a piece at its own place on the right of the house (see `layout_of_the_pieces.png`); they all stay.
> 1. **bench:** a wooden bench with iron legs;
> 2. **market stall:** a wooden market stall with a red-and-white striped awning, gems and baskets of vegetables on its counter;
> 3. **well:** a round stone well with a little wooden roof, a crank and a bucket;
> 4. **bandstand:** a white wooden bandstand (an open round pavilion) on a low platform, with a green pointed roof;
> 5. **statue of the miners:** a golden statue of a dwarf miner holding his pickaxe high, on a stone pedestal.
