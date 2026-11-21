#!/usr/bin/env python3
"""
Take screenshots of the screens of the game, as they show on a 1080p display,
to review them: the intro, the story, the shop, the house (empty, half and
fully built) and levels which bots play (with the moles and the evil miner).

The game renders on a virtual display (Xvfb), so that no window opens on your
screen; it plays no sound and uses no camera. Xvfb is optional for developing
the game: without it, this script tells you how to get it and stops.

    python3 dev/pictures/take_screenshots.py <output folder> [--godot <path>] [--only <name> ...]
"""

import argparse
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
from typing import Final, List, Optional, Sequence

REPO: Final[pathlib.Path] = pathlib.Path(__file__).resolve().parents[2]


class Shot:
    """A screenshot of a screen of the game."""

    #: The name of the screenshot, and of its picture (``<name>.png``).
    name: Final[str]

    #: The scene to show, e.g., ``res://scenes/intro/intro.tscn``.
    scene: Final[str]

    #: How many seconds to wait before the screenshot.
    seconds: Final[float]

    #: More arguments for dev/pictures/screenshot.gd, e.g., ``--level=2``.
    arguments: Final[Sequence[str]]

    def __init__(
        self, name: str, scene: str, seconds: float, arguments: Sequence[str] = ()
    ) -> None:
        """Initialize with the given values."""
        self.name = name
        self.scene = scene
        self.seconds = seconds
        self.arguments = arguments


#: The screenshots, in the order in which we take them.
SHOTS: Final[List[Shot]] = [
    Shot("intro", "res://scenes/intro/intro.tscn", 2.0),
    Shot("story", "res://scenes/story/story.tscn", 2.0),
    Shot("shop", "res://scenes/shop/shop.tscn", 2.0, ["--gems=37", "--boosters=1"]),
    Shot("house_empty", "res://scenes/house/house.tscn", 2.0, ["--gems=12"]),
    Shot("house_half", "res://scenes/house/house.tscn", 2.0, ["--gems=120", "--house=3"]),
    Shot("house_full", "res://scenes/house/house.tscn", 2.0, ["--gems=9", "--house=5"]),
    Shot("instruction", "res://scenes/instruction/instruction.tscn", 38.0),
    Shot("level_02", "res://scenes/level/level.tscn", 45.0, ["--level=2", "--bots=2"]),
    Shot("level_06", "res://scenes/level/level.tscn", 90.0, ["--level=6", "--bots=1"]),
]


def find_godot(explicit: Optional[str]) -> Optional[str]:
    """Find the Godot 4.6 .NET executable in the arguments, environment or path."""
    if explicit:
        return explicit
    if os.environ.get("GODOT"):
        return os.environ["GODOT"]
    for name in ("godot", "godot4", "godot-mono", "godot4-mono"):
        found = shutil.which(name)
        if found:
            return found
    return None


def main() -> int:
    """Execute the main routine."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", help="the folder to write the screenshots to")
    parser.add_argument("--godot", help="the Godot 4.6 .NET executable (else $GODOT)")
    parser.add_argument("--only", nargs="+", help="take only the screenshots of these names")
    args = parser.parse_args()

    xvfb = shutil.which("Xvfb")
    if xvfb is None:
        print(
            "Xvfb is not installed, so there is no virtual display to render the screenshots on.\n"
            "It is optional; install it to take screenshots, e.g.:\n"
            "  Debian/Ubuntu: sudo apt install xvfb\n"
            "  Fedora:        sudo dnf install xorg-x11-server-Xvfb\n"
            "  Arch:          sudo pacman -S xorg-server-xvfb\n"
            "On macOS and Windows there is no Xvfb: run dev/pictures/screenshot.gd directly\n"
            "(see its docstring), which opens a window.",
            file=sys.stderr,
        )
        return 2

    godot = find_godot(args.godot)
    if godot is None:
        print("Godot was not found: pass --godot or set $GODOT.", file=sys.stderr)
        return 2

    output = pathlib.Path(args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)

    shots = [shot for shot in SHOTS if not args.only or shot.name in args.only]
    if not shots:
        print(f"No screenshots match {args.only}; the names are: {[shot.name for shot in SHOTS]}")
        return 2

    with tempfile.TemporaryDirectory() as temporary:
        # NOTE (mristin):
        # Xvfb picks a free display itself and writes its number to the pipe.
        read_end, write_end = os.pipe()
        server = subprocess.Popen(
            [
                xvfb,
                "-displayfd",
                str(write_end),
                "-screen",
                "0",
                "1920x1080x24",
                "-nolisten",
                "tcp",
            ],
            pass_fds=(write_end,),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        os.close(write_end)
        with os.fdopen(read_end) as pipe:
            display = pipe.readline().strip()
        if not display:
            server.kill()
            print("Xvfb did not start; is another X server in the way?", file=sys.stderr)
            return 1

        env = dict(os.environ)
        env["DISPLAY"] = f":{display}"
        # NOTE (mristin):
        # Never fall back to the real display (Wayland), so that no window opens.
        env.pop("WAYLAND_DISPLAY", None)

        failed = 0
        try:
            for shot in shots:
                picture = output / f"{shot.name}.png"
                command = [
                    godot,
                    "--audio-driver",
                    "Dummy",
                    "--display-driver",
                    "x11",
                    "--path",
                    str(REPO),
                    "--windowed",
                    "--resolution",
                    "1920x1080",
                    "--script",
                    "dev/pictures/screenshot.gd",
                    "--",
                    shot.scene,
                    str(picture),
                    str(shot.seconds),
                    "--no-camera",
                    "--mute",
                    f"--settings={pathlib.Path(temporary, 'settings.cfg').as_posix()}",
                    *shot.arguments,
                ]
                result = subprocess.run(
                    command,
                    env=env,
                    capture_output=True,
                    text=True,
                    timeout=shot.seconds + 120,
                )
                if result.returncode != 0 or not picture.exists():
                    failed += 1
                    print(
                        f"FAILED {shot.name}:\n{result.stdout}\n{result.stderr}",
                        file=sys.stderr,
                    )
                else:
                    print(f"Wrote {picture}")
        finally:
            server.terminate()
            server.wait(timeout=10)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
