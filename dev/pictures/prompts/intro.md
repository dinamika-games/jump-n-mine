# Jump 'n' Mine: the story (intro frames)

The story shows before the first Play (`scenes/story/story.gd`): six frames, each with a caption which the game writes in a band over the bottom third. Until the painted frames are there, the game shows the sketches `assets/pictures/intro/frame_<n>.svg` (made by `dev/pictures/intro/make_storyboard.py`). Save each painted frame as `assets/pictures/intro/frame_<n>.png` (1920 x 1080); the game takes the PNG over the SVG.

Attach the sketch of each frame (`frame_<n>.svg`, or a PNG of it), the title painting (`title.png`) for the style, and the dwarves (`dwarf_*.png`) and the items (`chest.png`, `gem_*.png`, `helmet_*.png`) for the figures.

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


**For the story frames:** each frame is one **1920 x 1080 painting**, not a sprite: opaque, no transparency, no text, no letters on the signs (the game writes the captions). Keep the **bottom third calm and darker**, since the caption lies over it. Follow the composition of the attached sketch: where the figures stand and how big they are. The good dwarves wear tunics in red #e04848, blue #3f8ee8, green #3fbf5a and yellow #f2b630, steel helmets with glowing yellow lamps and big cream beards. **Queen Treacher** is a tall, thin, grumpy queen in a dark violet gown with pointed shoulders, a pale face and a black spiky crown with one red stone: a villain from a picture book, haughty and sulky, never frightening. **Her evil miners** look like the dwarves but in dark violet-grey tunics (#3a2a48), grey beards, black helmets without lamps, and her badge on the chest: a black crown on a purple circle; they look sneaky and grumpy, not scary.

## 2. The frames

**Frame 1: the miners share.** Sketch: `frame_1.svg`.
> A sunny valley before snowy violet mountains, with the dark entrance of a mine in the hillside. Three good dwarves (red, blue and green tunics) come out of the mine with crates of glittering gems and hand them happily to the villagers (a woman and a child in simple clothes). Warm, joyful, golden light.
> Caption: "Deep in the mountains, the miner dwarves dig for the treasures of the earth, and share them with all the people."

**Frame 2: the people want better lives.** Sketch: `frame_2.svg`.
> A village street with small houses and red roofs. Villagers march peacefully with blank signs held high (no letters), children among them; two dwarves (red and yellow tunics) march along with them, pickaxes over their shoulders. Hopeful evening light.
> Caption: "The people want better lives: fair work, warm bread and a school for every child. The miners stand with them."

**Frame 3: Queen Treacher.** Sketch: `frame_3.svg`.
> Night. A dark castle with two pointed towers and a violet flag in front of dark mountains, a pale moon. In front, Queen Treacher frowns with her arms crossed, her pointed shoulders and spiky black crown against the castle. Cold violet and blue light, a little gloomy but not scary.
> Caption: "But in her cold castle, Queen Treacher frowns. She wants to crush the miners and silence the people."

**Frame 4: her plan.** Sketch: `frame_4.svg`.
> Inside the castle, by candlelight: Queen Treacher leans over a long table with a rolled-out map, pointing at the mountains, with toy-like grey helmets and a small pile of gems on the table; behind her, on the wall, the shadow of crossed swords. Mischievous, scheming; nothing violent.
> Caption: "Her plan: grab the treasures, buy weapons and start a war, so that nobody asks for a better life any more."

**Frame 5: the evil miners.** Sketch: `frame_5.svg`.
> A dusky red evening. A line of four evil miners marches out of the castle gate (small, in the back left) towards a mine entrance in the mountain on the right, pickaxes raised, sneaky and grumpy.
> Caption: "She sends out her evil miners, with her black crown on their chests, to dig up the treasures first."

**Frame 6: your turn.** Sketch: `frame_6.svg`.
> A cross-section of the mine like in the game: a dark violet cave, warm sandy blocks. Three good dwarves leap and swing their pickaxes, digging down eagerly; one evil miner digs behind them on the left, glancing over jealously; at the bottom right a treasure chest glows with gems. Bright, energetic, a call to action.
> Caption: "Now it is up to you! Jump to swing your pickaxe, be faster than Treacher's miners, and bring the treasure to the people!"
