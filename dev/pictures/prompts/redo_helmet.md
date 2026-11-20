# Jump 'n' Mine: the miner's helmet, worn on the head

I'm making Jump 'n' Mine, a 2D game for children of 6-10, played by jumping in front of a webcam. In the camera picture, every child wears a **miner's helmet drawn over her head**, with the brim in the color of her dwarf.

The attached `reference_helmet_red.png` is the helmet I have now, and it is exactly right: the style, the steel dome, the rivets, the big glowing lamp, the colored brim. **Please keep that helmet as it is** and change only one thing.

The attached `current_helmet_on_a_player.png` shows how the game wears it: the helmet sits over the hair, and the game paints the child's forehead over the middle of the brim, so that the head is inside the helmet. It still looks a little like a sticker, since the helmet has no inside.

**The one change: show the dark inside of the helmet at the back.**

- Seen from the front and slightly from above, we would see a little of the **inside of the back rim**, behind the head: a thin, dark crescent (dark grey-brown inside of the shell, about #2a2030, softly shaded, with the same bold dark outline) **right under the front brim**, as wide as the brim.
- The crescent is **thickest in the middle** (about 40 px of 512) and thins out toward both ends of the brim, where it meets the brim.
- The front brim stays in front of it, unchanged: its **bottom edge still lies on a horizontal line at 75 % of the height** (y = 384). The crescent hangs below that line (down to about y = 424 in the middle).
- In the game, the child's face covers the middle of the crescent, so only its two ends show beside the head, as the back of the helmet behind the hair.
- Still no face, no head, no hair, no text: only the helmet.

**Five versions, identical except the color of the brim:** red #e04848, blue #3f8ee8, green #3fbf5a, yellow #f2b630, and white #ffffff (with its shading in grey).

**Technical (as before):**

- Each helmet on its own **512 x 512 px PNG with a fully transparent background (real alpha, not a painted checkerboard)**.
- The helmet fills the width (about 480 px wide), centered; the bottom edge of the front brim at y = 384, the dome and the glow of the lamp above it, the dark crescent below it.
- The same size, position and lamp in all five, so that they swap without jumping.
- No drop shadow outside the helmet.

Please name the files `helmet_<color>_front.png` (e.g., `helmet_red_front.png`).
