# Contributing

Thank you for helping with Jump 'n' Mine!

## Overview

The game is made with [Godot] 4.6 (.NET), written in GDScript and C#:

* The vision runs in C# (`scenes/vision/`).
  YOLOX finds the heads on every camera frame through ONNX Runtime, the `MultiHeadTracker` follows them, a `JumpGauge` for each head counts the jumps, `RtmPoseModel` finds the poses of up to four players on every frame (in one batch), and the `FaceEmbedder` (YuNet and SFace) recognizes the faces of the players who come back.
  The core (`scenes/vision/core/`, and `scenes/vision/yolox/`) does not depend on Godot, so we unit-test it with plain .NET in `tests/JumpNMine.Tests/`.
  The node `HeadVision` runs it all in the game; the autoload `Vision` finds the camera and keeps the heads.
* The game is in GDScript (`scenes/`).
  `Mine` (`scenes/level/mine.gd`, with `MineWater` and `MinePuzzles`) is the whole mine and its rules, without drawing or input, so that the bots (`MineBot`) can play it headless and fast.
  The levels are data in `scenes/levels/level_catalog.gd`; a level is generated from its seed.
  The pictures are painted sprites in `assets/pictures/`, drawn by `scenes/art/art.gd`; the gas and the explosions are shaders in `scenes/effects/`.
  The sounds are CC0 recordings from Freesound, cut into `assets/sounds/` by `python3 dev/sounds/cut_sounds.py` (you need `sox` with the Vorbis format, e.g., `apt install sox libsox-fmt-all`).
  To add or change a sound, list its recording and its cut in `dev/sounds/sources.json` and in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md), and run the script, which checks that the recording is still under CC0; `scenes/sound/sounds.gd` plays `assets/sounds/<name>.ogg`, and synthesizes the sound only if there is no recording.
* The development tools live in `dev/`, which Godot ignores.

[Godot]: https://godotengine.org

## Setting up the development environment

You need [Git] with [Git LFS] (the model and the test photos are in LFS), the [.NET 8 SDK], the **.NET** build of [Godot 4.6.2], and [Python] 3.10 or newer.

[Git]: https://git-scm.com
[Git LFS]: https://git-lfs.com
[.NET 8 SDK]: https://dotnet.microsoft.com/download/dotnet/8.0
[Godot 4.6.2]: https://godotengine.org/download/archive/4.6.2-stable/
[Python]: https://www.python.org/downloads/

```
git lfs install
git clone https://github.com/mristin/jump-n-mine.git
cd jump-n-mine
git lfs pull

export GODOT=~/apps/Godot_v4.6.2-stable_mono_linux_x86_64/Godot_v4.6.2-stable_mono_linux.x86_64

dotnet restore JumpNMine.sln
dotnet build JumpNMine.sln

python3 -m venv venv
venv/bin/pip install -r dev/requirements.txt
touch venv/.gdignore
```

**Do not skip the `.gdignore`!**
Godot would otherwise try to import the files of the virtual environment.

## Running the game

Open the project in the Godot editor and press F5, or run `$GODOT --path .`.

The arguments after `--`:

* `--no-camera`: play with the keyboard,
* `--mute`: start without sound (M switches the sound off and on anytime),
* `--camera=<n>`: use the n-th camera which supports 640x480,
* `--bots` (or `--bots=3`): bots play one dwarf (or as many), to watch a level,
* `--all-levels`: open all the levels,
* `--record`: record the heads, the jumps and the dwarves of each level played to `user://recordings/` (see `scenes/level/recorder.gd`), to tune the steering,
* `--settings=user://other.cfg`: keep the settings in another file and the expeditions in `user://other_saves/`.

The pictures are painted sprite sheets (made with an image generator from the prompts in `dev/pictures/prompts/`), cut into `assets/pictures/` by the cutters in `dev/pictures/cut_sprites/`, one per kind of picture (`dwarves.py`, `moles_and_evil_miner.py`, `blocks.py`, `items.py`, `dragon.py`, `title.py`, `house.py` and `gate_and_icons.py`), each run as `python3 dev/pictures/cut_sprites/<cutter>.py <folder with the sheets>`; see the docstring of each cutter for the sheets it expects. What they share (loading, cutting the grid, fitting, and clearing a painted checkerboard, a flat magenta or a haze from the background) is in `dev/pictures/cut_sprites/common.py`. `scenes/art/art.gd` draws them; only the water, the particles and the effects are drawn in code and with shaders.

The sketches of the story (`assets/pictures/intro/frame_<n>.svg`) are written by `python3 dev/pictures/intro/make_storyboard.py`; paint the frames from them with the prompts in `dev/pictures/prompts/intro.md`, and save them as `assets/pictures/intro/frame_<n>.png`, which the game takes over the sketches.

The sketch of the dwarves' house (`sketch_house_base.svg`, before any improvement) is written by `python3 dev/pictures/house/make_house_sketch.py <folder>`; paint the house from it with the prompts in `dev/pictures/prompts/house.md`. The sketches of the sheets of the other parts, and the layout of their pieces over the painted landscape, are written by `python3 dev/pictures/house/make_part_sheets.py <landscape.png> <folder>`; `python3 dev/pictures/cut_sprites/house.py <folder>` cuts the painted sheets.

The sketches of the iron gate with its stone plates and of the icons of the menu cards are written by `python3 dev/pictures/make_gate_and_icon_sketches.py <folder>` (into `gate/` and `icons/`); put the painted sheets next to them as `gate/gate_sheet.png` and `icons/icon_sheet.png`, and `python3 dev/pictures/cut_sprites/gate_and_icons.py <folder>` cuts them.

To review the shaders of the gas and the explosions, run `$GODOT --audio-driver Dummy --path . --windowed --resolution 1920x1080 --script dev/pictures/effects_preview.gd -- <folder>`; to review where the miner's helmets sit on the heads, `dev/pictures/hat_preview.gd` (see its docstring).

To review all the screens at once (the intro, the story, the shop, the house, how to play and levels which bots play), take their screenshots on a virtual display, so that no window opens and no sound plays:

```
python3 dev/pictures/take_screenshots.py <output folder> [--only house_full level_02]
```

It needs Xvfb (e.g., `sudo apt install xvfb`), which is optional: without it, the script says how to install it and stops. Without Xvfb (and on macOS and Windows), take a screenshot of one screen, as it shows on a 1080p display, in a window:

```
$GODOT --audio-driver Dummy --path . --windowed --resolution 1920x1080 \
    --script dev/pictures/screenshot.gd -- res://scenes/level/level.tscn shot.png 20 \
    --level=4 --bots=3 --no-camera --settings=user://shot.cfg
```

## Tuning the levels

`tests/godot/level_playthrough.gd` lets bots play the levels and prints how long they took, how many gems they found and how full the mine got:

```
$GODOT --headless --path . --script tests/godot/level_playthrough.gd -- --only=07 --players=2
```

A level should take one bot dwarf about six minutes (between 4 and 8), which is three to five minutes for a player who jumps about once a second; the depth of the level is the main knob.
The bots play against the evil miner of Queen Treacher, who must never win against them.

To check the prices of the shop and the house, simulate the purse of an expedition (bots play every level, and players of three kinds spend the gems greedily):

```
$GODOT --headless --audio-driver Dummy --path . --script dev/economy_simulation.gd
```

## Checks before a pull request

```
venv/bin/python dev/continuous_integration/precommit.py
```

It checks the formatting (add `--overwrite` to fix it), lints, runs the .NET tests, builds, imports, type-checks every GDScript and runs the Godot tests (`tests/godot/test_*.gd`; the levels take a few minutes).

## Releasing

The workflow `.github/workflows/publish.yaml` packages the game for Linux, Windows and macOS when a release is published on GitHub, and attaches the packages to the release (`jump-n-mine-<version>-<platform>.zip`, for the tag `v<version>`, e.g., `v1.0.0-rc1` for the first release candidate). You can also start it by hand on the Actions tab: without a tag, it only tries out the packaging (the packages are then the artifacts of the run); with the tag of an existing release, it attaches the packages to that release.

To release:

1. Set the version in `project.godot` (`config/version`, e.g., `1.0.0-rc1`), and the numeric part in the macOS preset of `export_presets.cfg` (`application/short_version` and `application/version`, e.g., `1.0.0`; macOS takes only numbers there). The workflow refuses a tag which does not match `config/version`.
2. Merge to `main`, then publish a release on GitHub with the tag `v<version>` (mark a release candidate as a pre-release).

The workflow checks that the game and the tests use the same ONNX Runtime, and that it is 1.19 (the last one whose macOS libraries run on macOS 11 on both the Intel and the Apple Silicon Macs, see `JumpNMine.csproj`); that the exports report no errors; that every package carries the native libraries of that ONNX Runtime (in the macOS app, for both the Apple Silicon and the Intel Macs); and it puts CameraServerExtension next to the executable of the Windows package, since Godot 4.6 implements no camera on Windows (see `scenes/vision/camera_extension.gd`).
