# Jump 'n' Mine: the water pouring from the springs

## 1. Style brief (send first)

> I'm making **Jump 'n' Mine**, a 2D side-view game for children of about 6–10, played by jumping in front of a webcam. Each child is a dwarf in a mine. Stepping left and right walks the dwarf, and each real jump swings its pickaxe at a block. One to four dwarves dig together in one mine, down to a treasure chest at the bottom. In the side walls of the mine are **springs**: iron pipes set into the dark rock. When a dwarf digs next to one, water pours out of the pipe into the mine; three jumps next to it hammer it shut with a plug.
>
> I attached a screenshot of the game (`screen_level_with_spring.png`, the open spring is at the top right) and the current pictures of the spring (`spring_open.png` and `spring_sealed.png`, 2x their size in the game, transparent background). The water in `spring_open.png` is painted into the pipe and does not move. I want the **water to flow**: an animation of the water pouring out of the pipe, which loops.
>
> **Style:** exactly like the attached pictures: a bright, friendly, hand-painted cartoon look, like a modern children's picture book or a cozy indie game. Clean bold dark outlines (about 3 px at the game size, color #1a1016), soft shading with a light source from the top left, chunky readable shapes. The water is clear bright blue (#2f7fd8 to #9fd4ff) with white foam, so that it stands out against the dark cave (violet / navy / near-black) and the warm sandy blocks.
>
> **Technical:** paint on a **flat, pure magenta background (#ff00ff)** everywhere outside the sprites, with no shadow, gradient or texture in it, so that I can cut the sprites out by code; do not use magenta or pink anywhere inside the sprites. No text, no watermark, no frame numbers. Lay the frames out on an exact grid of equal cells, every frame in its own cell, nothing crossing into the next cell. The frames of an animation must line up exactly: the pipe (when shown) and the point where the water leaves the pipe stay at the very same pixel in every frame; only the water moves. The last frame must flow seamlessly into the first, so that the animation loops.
>
> Then draw the sheets below, one at a time.

---

## 2. Sheet: the pipe without water

> **Sheet: the pipe.** One cell, 640 x 640 px (a block of the mine is 160 x 160 px at this size, so the cell is 4 x 4 blocks; draw the pipe only in the **top-left block**, 160 x 160 px, the rest of the cell stays magenta). The same iron pipe as in `spring_open.png`, set into the dark rock of the left wall, its round mouth open and facing **right**, at the same place and size as in `spring_open.png`, but **empty**: no water, only a dark inside of the pipe with a wet glint on its rim and a few drops on it.

---

## 3. Sheet: the water pouring out of the pipe

> **Sheet: the pouring water, 6 frames.** A grid of 3 columns x 2 rows, each cell exactly 640 x 640 px; read the frames left to right, top to bottom. Each cell is 4 x 4 blocks of 160 px; the mouth of the pipe would be in the top-left block, as in the pipe sheet above, but **do not draw the pipe**, only the water. In every frame, a thick jet of water leaves the mouth of the pipe at the same point (the right edge of the mouth, in the top-left block), arcs to the right and falls down, curving like a real stream (about one block to the right, then straight down), and splashes at the bottom of the cell into a little crown of foam and droplets. Between the frames, the water **flows**: ripples, bright highlights and white streaks travel along the jet, away from the pipe and down; the droplets fly a little further; the splash rises and falls. The shape of the jet stays almost the same, so that it does not jump from frame to frame. Frame 6 must lead seamlessly back to frame 1.

---

## 4. Sheet: the splash where the water lands

> **Sheet: the splash, 4 frames.** A row of 4 cells, each exactly 320 x 160 px (2 blocks wide, 1 block high): the splash of a stream of water falling into a pool, seen from the side, without the stream and without the pool: a crown of white foam and blue droplets that rises from the bottom middle of the cell and falls back. Frame 4 must lead seamlessly back to frame 1.

---

## 5. Sheet: the surface of the water

> **Sheet: the waves, 4 frames.** A column of 4 cells, each exactly 640 x 160 px (4 blocks wide, 1 block high): the surface of calm water in a mine, seen from the side: a bright light-blue wavy line with a little white foam and highlights along it, with only a thin band (about 30 px) of blue water under it, the rest of the cell magenta. Each strip must **tile seamlessly from left to right** (its left edge continues its right edge). Between the frames, the waves roll a quarter of the strip to the right, so that the 4 frames loop.

---

The attached pictures show the game as it looks now: `screen_level_with_spring.png` is a screenshot, `spring_open.png` and `spring_sealed.png` are the current pictures of the spring at 2x their size in the game (transparent background). Keep their look, proportions and colors.
