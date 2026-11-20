# Jump 'n' Mine: Design

**Jump 'n' Mine is a digging game for children, played by jumping in front of a webcam, alone or with up to three friends who come and go as they like.**
You are a dwarf in a mine.
Step left and right, and your dwarf walks with you; jump, and your dwarf swings its pickaxe down at the block under its feet; punch to the side, and it swings at the block beside it.
Dig down through the earth and the rock, gather the gems, open the iron gates with the stone plates, mind the gas and the dragons' fire, keep the water out, and find the treasure at the bottom of the mine.
Nobody dies: when the water floods the mine, the dwarves climb out, wet but happy, and start the level again.

Each level takes three to five minutes, and most of it is jumping.

# Game design

## 1. Pillars

1. **The exercise is the controller.** The players only step left and right, jump, and punch to the side. Every swing of the pickaxe is a jump or a punch. The game never says "do jumps"; it shows the dwarf swinging, and the blocks crack.
2. **Friends dig together, whenever they like.** Up to four players, each with a dwarf, in one mine. A player who steps in front of the camera gets a dwarf, and a player who leaves takes her dwarf along; the puzzles adapt on the fly to who is there. There is no race: the gems and the treasure belong to all.
3. **Nobody gets hurt.** The fire and the explosions only make a dwarf dizzy for a moment. The flood ends the level, but the dwarves simply climb out and try again.
4. **Clear at a glance.** The cave is dark and cool, the blocks are warm and bright, and what is special looks special: the glowing green gas, the blue springs in the walls, the iron gates and their stone plates, the gems and the boosters.

## 2. Controls: stepping and jumping

* **Walking:** the dwarf walks to where its player stands: the player's head in the mirrored camera picture, from 30 % to 70 % of its width, maps to the whole width of the mine, so that a player reaches the walls of the mine in the middle of the room, where she still sees the screen and a short step moves her dwarf, and still punches inside the picture. The dwarf always stands in the middle of a block, never between two: it steps to the next block only once the head was 0.5 blocks beyond the edge of its block for 0.1 s (`Level.BLOCK_MARGIN`, `Level.STEP_HOLD`), and walks block by block, so that it stays on the block it digs while its player sways and jumps, and a glitch of the tracking does not move it. A dwarf does not walk through blocks; it stops at them.
* **Jumping:** a jump is measured from the lowest point of the head in the 0.8 s before it (where the player stands, or her knees bent to jump or after the last landing) to its peak, in head sizes (`JumpGauge`), so that it does not matter how close to the camera the player stands, and nothing drifts while she jumps in a row. A jump counts fully from 0.3 head sizes (about 9 cm), and as a weak one (half a hit) from 0.18; it counts when the head comes back down, and two jumps are at least 0.3 s apart. A head which goes up and stays up for a second (standing up from a crouch, on the toes, or stepping closer) is no jump. The thresholds come from recordings of an adult (see `--record`) and are to tune with recordings of children.
* **The swing:** each jump swings the pickaxe **down** at the block under the dwarf's feet. The only exception is a spring: a dwarf who stands right next to an open spring in the wall hammers it shut with its jumps.
* **The swing to the side:** a player who moves a fist quickly to the left or to the right (the wrist travels 0.6 head sizes across the body within 0.4 s and ends at least 1.4 head sizes on that side of the middle of the body, beyond the shoulder, or reaches the edge of the picture, about at the height of the chest, `SwingGauge`) swings the pickaxe **sideways** at the block on that side, without a hop; every punch is a hit, so a player who walks into a wall punches it open. Pulling the fist back to the body, walking, arms raised over the head in a jump, or both fists apart at once do not count. Leaning against a block and jumping still hits only down. The thresholds are first guesses, to tune with recordings of children; without the pose (the keyboard, or no pose model), the dwarves dig staircases as before.
* **The hop:** a jump while the dwarf walks, or leans against a block beside its feet, hops it 1.25 blocks up, so that it climbs onto a step of one block, and jumps over a hole. A jump while the dwarf stands still only bobs it a little, so that it stays on the block it digs. To go sideways deeper down, the dwarves dig staircases: dig the block underfoot, hop onto the next one, dig it, and so on.
* **Hits:** the soft earth breaks after 3 hits, the hard rock after 4; each hit shows bigger cracks.
* **The keyboard** (without a camera, and for testing): the first dwarf walks with Left and Right and jumps with Up (or Space), the second with A, D and W, the third with J, L and I, the fourth with 4, 6 and 8 of the keypad; the first key of a player brings her dwarf. Escape pauses, and M switches the sound off and on.

## 3. Players who come and go

The players have no names and no fixed number:

* **Joining:** a head which appears in the camera picture gets a dwarf of a free color (red, blue, green or yellow, the first free one), let down into the mine on a rope to the deepest dwarf (or, at the start, standing on the grass). The camera picture lies dimly over the whole mine (`CameraOverlay`), zoomed so that the lamp of each player lies right above the block of her dwarf, and every player wears a **miner's helmet with a glowing lamp** in it, the brim in the color of her dwarf; the helmet tilts with her head, and **a dim beam of light** shines from its lamp down to her dwarf (`scenes/effects/beam.gdshader`), so that each child sees which dwarf is hers and where it stands. In the menus, the beam shines on the card where she stands.
* **Leaving:** a dwarf whose head left the picture waits for 4 seconds, and then leaves the mine.
* **Coming back:** the vision recognizes the players by their faces (section 8): a player who comes back gets her identity, and while her dwarf still waits, her dwarf. A new face is a new player, with a dwarf of its own.
* **Staying together:** a dwarf left above the screen for 2.5 s is let down on a rope to the deepest dwarf. The screen follows the dwarves and keeps the deepest in view.

## 4. The mine

The mine is 11 blocks wide (the outer columns are its walls), with the sky and the grass at the top and the treasure hall at the bottom; the screen shows about 5.7 rows. The blocks are big, so that a child hits the block she stands on even if she sways a little. There is nothing a pickaxe can not break below the dwarves (apart from the gates of the puzzles), since a dwarf can only dig down: anything unbreakable underfoot would trap it.

* **Earth and rock** (3 and 4 hits). The deeper, the more rock; some levels have bands of rock across the mine and clumps of rock.
* **Caves**, where the dwarves drop a few rows at once.
* **Gems**, inside the blocks (they sparkle through) and lying in the caves. Breaking the block gives the gem to the dwarf; the gems count for everybody.
* **Boosters**, glowing inside the blocks:
  * the **golden pickaxe**: every hit counts twice, for 20 s;
  * the **fire helmet**: the fire and the explosions do not make the dwarf dizzy, for 30 s;
  * the **spring boots**: the dwarf hops 2.3 blocks high, for 25 s, so that it can climb back up;
  * the **pump**: 70 % of the water in the mine disappears at once.
* **Gas pockets:** blocks with green gas glowing in them (an animated shader, `scenes/effects/gas.gdshader`). One hit opens the pocket: the block is gone, and a cloud of gas swirls there for 2.4 s, turning orange and flickering faster, until the lamps of the dwarves set it on fire. The explosion (`scenes/effects/explosion.gdshader`: a flash, a fireball which burns out to smoke, and a shockwave ring) breaks the blocks around it (two up, down and to the sides, one diagonally), opens the gas pockets in reach (which explode right after, a chain), and makes the dwarves nearby dizzy for 2.5 s. The dragons' fire sets the gas on fire at once. Dangerous and useful: after digging a gas pocket, step away!
* **Springs** (blue, in the walls on the left and the right): a spring is closed until a dwarf digs next to it; then it pours water into the mine. The water falls and spreads; dwarves are heavy, so they wade along the bottom, slower, with bubbles, and still swing. Three jumps next to a spring hammer it shut. **The flood:** when the water in the mine reaches the level's limit (the meter at the top right), the mine is flooded, and the level starts again.
* **Dragons** fly in above the mine, circle over a dwarf for 1.8 s while a red glow shows the column where the fire will fall, and spit. The fire falls straight down; it stops at the first block (and cracks it), goes out in the water, sets gas on fire, and makes a dwarf it hits dizzy for 2.5 s (unless it wears the fire helmet).
* **The treasure:** a chest in the hall at the bottom. A dwarf who reaches it finishes the level.
* **Stars:** one for the treasure, two when the dwarves gathered half of the gems, three for 80 % of them.

## 5. The puzzles

The puzzles are played only by stepping and jumping (`MinePuzzles`): a hall, three rows high and as wide as the mine, whose floor is an **iron gate** which no pickaxe breaks. **Stone plates** in the floor open it; a dwarf presses a plate by standing on it. Next to each plate, the floor is stone, so that a dwarf on a plate stands safe while the gate opens. Lamps over the hall show how many plates must be pressed now, and light up as they are pressed.

* **Timer gates:** the gate opens while a dwarf stands on its plate, and stays open for 4.5 s after she steps off (a bar shows the time): run off the plate and drop through.
* **Twin gates** (two plates far apart): the gate opens for good once enough plates are pressed at the same time. **How many are enough follows the dwarves who dig right now:** one dwarf alone needs one plate; two or more dwarves need both plates, each with a dwarf on it, so that the friends work together. When a player leaves, the gate asks for fewer at once, so that nobody is ever stuck.

The levels have no puzzles at first, a timer gate from level 3, twin gates from level 5, and up to three halls in the last levels.

## 6. The levels

Each level is generated from its data and its seed (`scenes/levels/level_catalog.gd`), so it is the same every time. The tests let bots play every level, jumping every 1.6 s like a child, alone and three together (`tests/godot/test_levels_world_<n>.gd`), and check that the level can be finished (the puzzles, too), that one dwarf takes between 11 and 20 minutes (the last calibration: 13.6 to 17.4 minutes), and that more dwarves are not slower. The mine does not grow with the number of players, since they come and go: friends who dig together finish sooner.

### World 1: The Copper Hills

Warm sandy earth and copper rock in a violet cave, under a blue sky. Digging, gems and boosters, and the first surprises.

| # | Level | What is new |
|---|---|---|
| 1 | The First Swing | Mostly earth, caves and many gems, two golden pickaxes. |
| 2 | Copper Veins | More rock, and the spring boots. |
| 3 | The Mushroom Grotto | Bands of rock, many caves, and the first timer gate. |
| 4 | Barrels of Thunder | The gas pockets, sometimes two or three together, and the fire helmet. |
| 5 | The Dripping Gallery | The first spring and the flood meter, the pump, and the first twin gate. |

### World 2: The Sunken Halls

Pale sandstone and mossy rock in a deep blue cave, under the lake. The water comes from the left and the right.

| # | Level | What is new |
|---|---|---|
| 6 | The Well of Whispers | Springs on both sides; a timer gate and a twin gate. |
| 7 | The Flooded Stairs | Many springs, close to each other. |
| 8 | The Pump Room | Stronger springs, and more pumps. |
| 9 | The Crystal Lake | Many caves and many gems, with springs all the way down. |
| 10 | The Waterfall Mine | Strong springs, and in the lower half the first dragons. |

### World 3: The Dragon Deeps

Light tan earth and rock with glowing ember veins in a dark red cave, under an evening sky. The dragons spit fire from the start.

| # | Level | What is new |
|---|---|---|
| 11 | Smoke in the Shaft | Dragons from the start, and fire helmets to find. |
| 12 | The Ember Seam | More dragons, more rock, and a spring. |
| 13 | The Thunder Halls | Many gas pockets and dragons together. |
| 14 | The Dragons' Larder | Dragons, springs and gas, and three halls with gates. |
| 15 | The Heart of the Mountain | Everything: the deepest mine, the most gems, three halls. |

## 7. The screens

1. **The intro:** the title painting, and Play, Expeditions, How to play and Quit.
2. **The expeditions** (the sessions of the game): Play asks once each start which expedition goes on. **Continue** the last one (its name and its stars), start a **New expedition**, or go on with one of the two other most recent ones. **Delete** removes an expedition for good in three steps, so that nobody deletes one by chance: Delete, then the card of the expedition, then Delete again (or Keep). Without any expedition, Play goes straight to naming the first one. An expedition does not keep who plays, since the players come and go.
3. **Naming:** a new expedition is named first; the name starts as the date and the time (e.g., "2026-11-19 14:05"), so that jumping on OK is enough. The keyboard (or the keys on the screen, with the mouse) changes it; the first key replaces it.
4. **How to play** (the first time of an expedition, and from the intro): a little mine where a dwarf does what a player does, with one short line each: stepping, jumping, the staircase, waving an arm to hit the block beside the dwarf, the cracks and the gems, the gas and the springs, the dragons and the treasure.
5. **The mines and the levels:** the three worlds with their stars; then the five levels of the world. Finishing a level opens the next; the levels not open yet show a lock.
6. **The level**, with its bar at the top (the name, the gems, how deep the dwarves came, and how full of water the mine is) and the camera picture in the corner, with a miner's helmet on every player. A tip explains a thing the first time it happens (the first gas, dragon, water, booster, plate, gate and rope).
7. **The end:** "Treasure found!" with the gems and the stars (Next level, Again, Levels), or "The mine is flooded!" (Try again, Levels). Escape pauses (Go on, Start again, Levels).

**Every menu is a row of at most six big cards, played like the game:** behind the cards, the title painting and the camera picture show dimly, mirrored and zoomed as in the mine, each player wears a helmet, and the beam of light of her lamp shines on the card where she stands (the middle 40 % of the picture spans the cards, as it spans the mine, `Vision.HEAD_RANGE`). Stepping left and right moves the beam; like a dwarf on its block, it stays on its card until the head is a quarter of a card beyond its edge for 0.1 s, so that a sway or a jump does not move it. A jump presses the card, once the head stood on it for 0.3 s (the card then shows "Jump!"). The mouse and the keys (Left, Right, Enter or Space, Escape) work, too.

## 8. Saving

Every expedition is JSON in `user://saves/<id>.json`, with a format version (so that later versions can convert old saves), the name, the times it was created and updated, the stars of each level and whether the players saw how to play. The id is the date and the time of its creation. A save is written to a temporary file first and then renamed, so that a crash never destroys the last good save; it is written whenever something changes. `user://settings.cfg` keeps the last expedition. A broken or newer save is skipped.

## 9. Art and sound

* **The pictures are painted sprites** (`assets/pictures/`): the dwarves in their four colors, their poses and a walk cycle of six frames, the miner's helmets over the players, the blocks, the caves and the skies of the three worlds, the cracks, the springs, the gems, the boosters, the chest, the dragon and its fire, and the title painting. They were made with an image generator from the prompts in `dev/pictures/prompts/`, and cut by `dev/pictures/cut_sprites.py`; `scenes/art/art.gd` draws them.
* **The effects are shaders** (`scenes/effects/`): the gas, the explosions and the warning where a dragon's fire will fall; the water, the particles, the gates and the plates are drawn in code.
* **The sounds** are CC0 recordings from Freesound, cut by `dev/sounds/cut_sounds.py` (`dev/sounds/sources.json`): the pickaxe on the earth and on the rock, the breaking blocks, the gems, the gas and the explosions, the water, the dragons and the jingles. The water pours as long as a spring is open, and the gas hisses as long as it floats. `scenes/sound/sounds.gd` synthesizes a sound only if its recording is missing.

# Software architecture

## 10. Technical outline

* **Godot 4.6 (.NET)** with the Compatibility renderer (OpenGL), at 1920 x 1080. The vision is in C#, the game in GDScript.
* **The camera:** Godot's camera on Linux and macOS; on Windows, Godot 4.6 has no camera, so the game brings [CameraServerExtension](https://github.com/j20001970/godot-cameraserver-extension) along (`scenes/vision/camera_extension.gd`). On macOS, the frames come as two planes, which we convert to RGB (`YcbcrConverter`), and the game asks again for the camera once the permission is granted.
* **The vision** (`scenes/vision/`) runs ONNX Runtime 1.19.2 (the last version whose libraries run on macOS 11 on both the Intel and the Apple Silicon Macs) on a background thread:
  * **YOLOX-Body-Head-Hand-Face** (nano, 256 x 320) finds the heads on every camera frame;
  * the **`MultiHeadTracker`** follows them from frame to frame (ByteTrack-like) and keeps the identities of the players who left; everything it follows is smoothed with 1€ filters (`OneEuroFilter`): the position, the size and the speed of each head, its tilt for the helmet, and its height and size for the jumps, the latter with a fast filter which only removes the jitter while the head stands still, so that the jumps keep their tops;
  * a **`JumpGauge`** for each head counts its jumps on the fast-smoothed height;
  * **RTMPose-t** (256 x 192, top-down) finds the 17 keypoints of the body of a player, on a crop around her head (five heads wide, down to the waist, and wider if YOLOX finds her body reaching out further); a pose costs about 10 to 16 ms on a laptop CPU, so the players take turns, one pose per frame. The tilt of her helmet comes from the line through her eyes and her ears (YuNet's landmarks do not follow a tilted head);
  * the **`FaceEmbedder`** recognizes the faces: **YuNet** finds the five landmarks of the face in the head box, we align the face to the ArcFace template (112 x 112) by a similarity transform, and **SFace** (int8) gives its embedding of 128 numbers. A new head takes over the identity of a lost player only if their faces are similar enough (a cosine of at least 0.45: the same face gives about 0.95, different people below 0.4); without a face (looking away), the head takes over the player lost most recently. At most one face is computed per frame, and each player's face is refreshed every second.
  * `HeadVision` (the only part which depends on Godot) emits the heads and the jumps as signals; the autoload `Vision` finds the camera and keeps the heads.
* **The mine** (`Mine`, with `MineWater` and `MinePuzzles`) is the whole game state and its rules, without drawing or input, so that bots play it headless and fast in the tests (`MineBot`: Dijkstra over the places where its dwarf can stand, digging down, walking and hopping, with the cost in jumps; it solves the puzzles, too). `MineView` draws it, with the `EffectLayer`s of the shaders, `Hud` draws the bar and the camera picture, and `Level` binds the heads and the keys to the dwarves.
* **The menus** are `CardMenu`s; `Flow` knows the way through them; the autoload `Session` keeps the expeditions; the autoload `Sounds` plays the sounds.
* **No network access.** The camera pictures and the faces are processed in memory and never saved or sent; the embeddings of the faces live only in memory while the game runs.

## 11. The tests

* .NET (`tests/JumpNMine.Tests/`): the `JumpGauge` (standing, jumps, nods, crouches, stepping closer), the `MultiHeadTracker` (with the threshold for new faces), the 1€ filter, the YOLOX model, the pose and the tilt of the head (RTMPose) and the face recognition on test photos, and the conversion of the camera planes.
* Godot (`tests/godot/`): the rules of the mine and the puzzles (`test_mine.gd`), the expeditions (`test_session.gd`), the way through the screens into a level with the keys and a second player who joins (`test_screens.gd`), and bots playing every level alone and three together (`test_levels_world_<n>.gd`).

## 12. Open questions

1. The thresholds of the jumps wait for recordings of children, and the threshold of the faces for children who come and go.
2. Whether the levels feel like three to five minutes with real children, who pause, miss and wander; the bots jump every 1.6 s without a break.
3. Translations, as in the other games.
