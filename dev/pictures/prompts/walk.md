# Jump 'n' Mine: a real walk cycle for the dwarves

I'm making Jump 'n' Mine, a 2D side-view game for children of 6-10, played by jumping in front of a webcam. Each child is a dwarf miner. The attached dwarves (`reference_red_idle.png`, `reference_blue_idle.png`, `reference_green_idle.png`, `reference_yellow_idle.png`) and the sheet `reference_red_sheet.png` show the dwarf and the style: keep them exactly (the same dwarf, proportions, outlines, colors and painting style).

**The problem:** the dwarf walks with the two walking frames of `current_walk_frames_too_similar.png`: they are almost the same picture, so the legs hardly move, and the pickaxe jumps from the shoulder (standing) to the back (walking).

**Please paint a real walk cycle of 6 frames** for the dwarf, walking to the **right**, seen from the side (like the references):

1. contact: the right foot forward, its heel touching the ground, the left foot back, legs wide apart;
2. down: the right foot flat, the body a little lower, the left knee bent, the left foot passing;
3. passing: the left foot passing the right one, the body at its highest;
4. contact: the left foot forward, its heel touching the ground, the right foot back, legs wide apart;
5. down: the left foot flat, the body a little lower, the right foot passing;
6. passing: the right foot passing the left one, the body at its highest.

- The legs must **clearly alternate** (the near and the far leg distinguishable, the far one a little darker), with big steps, so that the walk reads from far away.
- The arms swing opposite to the legs, gently; the beard and the belt bounce a little.
- **The pickaxe stays on the same shoulder in all six frames**, as in the standing frame (`reference_red_idle.png`), resting on it, the head behind the dwarf.
- The body moves up and down a little between the frames (as listed), but the **feet always rest on the same baseline** (the ground line), except the lifted foot.

**Four sheets, one per tunic color, identical except the tunic:** red #e04848, blue #3f8ee8, green #3fbf5a, yellow #f2b630.

**Technical:** each sheet **2172 x 362 px: one row of 6 cells of exactly 362 x 362 px**, the dwarf at the **same size and position as in the 362 x 362 cells of `reference_red_sheet.png`** (about 245 px tall, the feet on the line at y = 328 of each cell, the body centered horizontally), **fully transparent background (real alpha, not a painted checkerboard)**, no shadow outside the dwarf, no text.
