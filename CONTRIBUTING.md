# Contributing

Thank you for helping with Jump 'n' Mine!

## Overview

The game is made with [Godot] 4.6 (.NET), written in GDScript and C#:

* The vision runs in C# (`scenes/vision/`).
  YOLOX finds the heads on every camera frame through ONNX Runtime, the `MultiHeadTracker` follows them, a `JumpGauge` for each head counts the jumps, and the `FaceEmbedder` (YuNet and SFace) recognizes the faces of the players who come back.
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
* `--settings=user://other.cfg`: keep the settings in another file and the expeditions in `user://other_saves/`.

The pictures are painted sprite sheets (made with an image generator from the prompts in `dev/pictures/prompts/`), cut into `assets/pictures/` by `python3 dev/pictures/cut_sprites.py <folder with the sheets>`; see the docstring of the script for the sheets it expects. `scenes/art/art.gd` draws them; only the water, the particles and the effects are drawn in code and with shaders.

To review the shaders of the gas and the explosions, run `$GODOT --audio-driver Dummy --path . --windowed --resolution 1920x1080 --script dev/pictures/effects_preview.gd -- <folder>`; to review where the miner's helmets sit on the heads, `dev/pictures/hat_preview.gd` (see its docstring).

To review a screen, take a screenshot as it shows on a 1080p display:

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

A level should take one dwarf about fifteen minutes (between 11 and 20); the depth of the level is the main knob.

## Checks before a pull request

```
venv/bin/python dev/continuous_integration/precommit.py
```

It checks the formatting (add `--overwrite` to fix it), lints, runs the .NET tests, builds, imports, type-checks every GDScript and runs the Godot tests (`tests/godot/test_*.gd`; the levels take a few minutes).
