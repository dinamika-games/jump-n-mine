# Jump 'n' Mine: the miner's helmet for the players

I'm making Jump 'n' Mine, a 2D game for children of 6-10, played by jumping in front of a webcam. Each child in front of the camera is a dwarf miner in the game. In the camera picture (shown in a corner of the screen and dimly behind the menus), every child wears a **miner's helmet drawn over her head**, so that she sees which dwarf is hers: the brim of the helmet has the color of her dwarf's tunic.

The attached `current_hat_on_a_player.png` and `current_hats_on_several_players.png` show the helmet I draw now: a flat grey dome with a colored bar. It is too plain. Please paint a **much nicer miner's helmet** in the style of the attached dwarves (`reference_dwarf_red.png`, `reference_dwarf_blue.png`), the helmet booster (`reference_helmet_booster.png`) and the title painting (`reference_title.png`): bright, friendly, hand-painted cartoon, bold dark outlines (#1a1016), soft shading with the light from the top left.

**The helmet:**

- Seen **from the front**, as the camera sees a child who faces it, slightly from below; symmetric.
- A rounded steel dome (grey-blue steel, a bright highlight, a few rivets), like the dwarves' helmets.
- A **brim** all around, painted in the color of the dwarf (see below), clearly visible, with a dark outline.
- A **big glowing lamp** in the middle of the front: a brass ring, a bright yellow-white glass, and a soft glow around it (the glow may spill over the edges a little).
- No face, no head, no hair, no text: only the helmet, so that it sits on the real child's head.

**Four versions, identical except the color of the brim:** red #e04848, blue #3f8ee8, green #3fbf5a, yellow #f2b630. Please also give a fifth version with a **plain white brim** (#ffffff, with its shading in grey), which I can tint in the game.

**Technical:**

- Each helmet on its own **512 x 512 px PNG with a fully transparent background (real alpha, not a painted checkerboard)**.
- The helmet fills the width (about 480 px wide). The **bottom edge of the brim lies on a horizontal line at about 75 % of the height** (y = 384), centered, so that I can place that line on the child's forehead; the dome and the glow fill the space above it.
- No drop shadow outside the helmet.

Optional, if it is easy: the same five helmets **seen a little from the side** (turned about 30 degrees to the left), for children who turn their heads.
