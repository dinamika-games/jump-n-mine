# Jump 'n' Mine: the dwarf strikes the block beside it

I'm making Jump 'n' Mine, a 2D side-view game for children of 6-10, played by jumping in front of a webcam. Each child is a dwarf miner. There are four dwarves, one per player, the same dwarf in four tunic colors. The attached `reference_<color>_idle.png` and `reference_<color>_poses.png` (standing, the pickaxe raised, swinging, hitting down, hitting forward) for red, blue, green and yellow show them and the style: **keep them exactly** (the same dwarf, proportions, outlines, colors, lamp and painting style).

**The problem:** the dwarf can only hit the block **under** its feet. Now a child can also wave an arm to the side, and the dwarf should hit the block **beside** it. `current_side_hit_does_not_work.png` shows what I have: the dwarf reuses the frame that hits low and forward, and it looks like it pokes the air in front of its belly instead of striking the wall.

**`side_strike_motion.png` is a rough diagram of the motion** (simple shapes, NOT the style to copy): the three frames, and on the right all three on top of each other with the path of the point of the pickaxe (blue) and the bounce (red). The pickaxe swings from high behind the dwarf's shoulder, over the front, and its point chops into the wall at chest height, the handle pointing up and forward at about 45 degrees, the hands low in front of the belly. Paint the dwarf of the references in exactly these poses.

**Please paint a sideways strike of 3 frames**, the dwarf facing **right**, seen from the side (like the references), striking a wall of rock right in front of it:

1. **wind-up:** the dwarf leans back, both hands on the handle above and behind its head, the pickaxe raised **high behind its shoulder**, the head of the pickaxe up and behind it, the weight on the back foot, a determined face.
2. **strike:** the dwarf has swung the pickaxe **over and forward** with both hands, leaning in, the arms stretched down in front of its belly, the handle pointing **up and forward at about 45 degrees**, the weight on the front foot, the eyes squeezed shut with effort. The **point of the pickaxe hits the wall at about the height of the dwarf's chest** (see the yellow circle in `where_the_block_is.png`). Add a small burst of impact lines and a few chips of rock at the point, in the style of the impact lines of the `hit_down` frame.
3. **recoil:** the pickaxe bounces back a little from the wall, the point a short way in front of it, the arms bent, a few chips still falling.

- The strike must **clearly read as a chop into a wall in front of the dwarf**, not down at the ground and not in the air: the point of the pickaxe stuck in the wall's surface at chest height.
- **The wall is not in the picture**: only the dwarf, its pickaxe and the chips. `where_the_block_is.png` shows where the wall stands in the game, for the reach (the brown bar is NOT to be painted).
- **The point of the pickaxe in the strike frame reaches x = 315 px of the 362 px cell, at y = 210** (the wall's surface), and never goes beyond x = 350.
- The pickaxe head, the dwarf and the impact lines all **stay inside their cell**; the wind-up may reach to the left edge of the cell, not beyond.
- The feet **always rest on the same baseline** (y = 328 of each cell), and the dwarf is **the same size and position as in the cells of the `reference_<color>_poses.png`** (about 245 px tall, the body centered horizontally).

**Four sheets, one for each of the four dwarves, identical except the tunic (match each to its `reference_<color>_poses.png`):** red #e04848, blue #3f8ee8, green #3fbf5a, yellow #f2b630. Name them `dwarf_side_red.png`, `dwarf_side_blue.png`, `dwarf_side_green.png` and `dwarf_side_yellow.png`.

**Technical:** each sheet **1086 x 362 px: one row of 3 cells of exactly 362 x 362 px**, **fully transparent background (real alpha, not a painted checkerboard)**, no shadow outside the dwarf, no ground, no wall, no text.
