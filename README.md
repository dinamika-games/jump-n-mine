# Jump 'n' Mine

![Jump 'n' Mine: choosing an expedition and a mine, then digging down for the gems, past a mole](docs/jump-n-mine.gif)

**Jump 'n' Mine is a free digging game for children, played by jumping in front of a webcam, alone or with up to three friends who come and go as they like.**

You are a dwarf in a mine.
Step left and right, and your dwarf walks with you; jump, and your dwarf swings its pickaxe down at the block under its feet; punch to the side, and it swings at the block beside it.
Three or four hits break a block, which cracks more with every hit.
Dig down through the earth and the rock, gather the gems, step away from the exploding gas, wade through the water of the springs (or hammer them shut), dodge the dragons' fire, open the iron gates with the stone plates (together, when your friends are there), leave the friendly moles alone, and find the treasure at the bottom before the evil miner of Queen Treacher does (bonk him with your pickaxe!).
Spend the gems on boosters for the next levels, and build up the dwarves' house, fifty improvements in all.
Nobody dies: the water only slows the dwarves down, and the springs run dry.

Whoever steps in front of the camera gets a dwarf, with a miner's helmet over her head in the camera picture; whoever leaves takes her dwarf along, and gets it back when she returns, since the game recognizes her face.

There are fifteen levels in three worlds (The Copper Hills, The Sunken Halls and The Dragon Deeps), each three to five minutes of jumping.
See [DESIGN.md](DESIGN.md) for the whole design.

**No network access.**
The game runs entirely on your computer and works offline.
The webcam images and the faces are processed locally, in memory, and are never saved or sent anywhere.

## Download

Download the game for Linux, Windows or macOS from the [releases].
Unzip the package and start the game.

[releases]: https://github.com/mristin/jump-n-mine/releases

You need a webcam which supports 640x480.
Stand about two to three meters from it, so that it sees you from the head to the waist, and leave room to jump.

| System | With the webcam | With the keyboard |
|---|---|---|
| **Linux** (x86_64) | ✅ | ✅ |
| **macOS 11 or later** (Apple Silicon and Intel) | ✅ (macOS asks for the permission on the first start) | ✅ |
| **macOS 10.15** (Intel) | ❌ (the head tracking needs macOS 11) | ✅ |
| **Windows** (x86_64) | 🧪 experimental, see below | ✅ |

Godot 4.6 has no camera on Windows, so the Windows package brings [CameraServerExtension] along.
Virtual cameras (e.g., the one of OBS Studio) do not work there.
If the camera does not work, play with the keyboard: the first dwarf walks with Left and Right and jumps with Up (or Space), the second with A, D and W, the third with J, L and I, and the fourth with 4, 6 and 8 of the keypad. M switches the sound off and on.

[CameraServerExtension]: https://github.com/j20001970/godot-cameraserver-extension

The macOS app is not notarized: open it the first time with a right click and Open.

## Acknowledgments

We follow the players with the following models (each model directory contains its license):

* [YOLOX-Body-Head-Hand-Face] (nano, 256x320, Apache-2.0) finds the heads, on every camera frame.
* [YuNet] (MIT) finds the landmarks of the faces in the heads.
* [SFace] (int8, Apache-2.0) recognizes the faces, so that the players get their dwarves back when they return.
* [RTMPose] (tiny, 256x192, Apache-2.0) finds the poses of the players, so that the helmets tilt with their heads.

The pictures were painted with an image generator from our prompts (`dev/pictures/prompts/`).

The sounds are recordings under CC0 from [Freesound], by Alex_hears_things, benzix2, BMacZero, CamoMano, derplayer, f3bbbo, Godowan, kwahmah_02, magnuswaker, MPierluissi, Mr._Fritz_, plasterbrain, qubodup, Reitanna, renatalmar, roman_cgr, swordofkings128, the_semen_incident, YoshikaMiyafuji and Za-Games. Thank you!

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for all the components and their licenses.

[YOLOX-Body-Head-Hand-Face]: https://github.com/PINTO0309/PINTO_model_zoo/tree/main/434_YOLOX-Body-Head-Hand-Face
[YuNet]: https://github.com/opencv/opencv_zoo/tree/main/models/face_detection_yunet
[SFace]: https://github.com/opencv/opencv_zoo/tree/main/models/face_recognition_sface
[RTMPose]: https://github.com/open-mmlab/mmpose/tree/main/projects/rtmpose
[Freesound]: https://freesound.org

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

The game is licensed under the MIT License; see [LICENSE](LICENSE).
