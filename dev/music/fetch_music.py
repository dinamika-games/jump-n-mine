"""
Fetch the music of the game, as listed in dev/music/sources.json, into
assets/music/<slug>.mid:

* a MIDI file is downloaded and copied unmodified;
* a MusicXML score is downloaded and converted (dev/music/musicxml.py);
* our own transcription of a melody in the public domain,
  dev/music/melodies/<slug>.abc, is converted (dev/music/abc.py).

The downloads are kept in .cache/music/. A file from Wikimedia Commons is
checked to be still under its license, and so is a page of the Mutopia
Project. Afterwards, render the music with dev/music/render_music.py.

    venv/bin/python dev/music/fetch_music.py [slug ...]
"""

import argparse
import json
import pathlib
import shutil
import sys
import time
import urllib.parse
import urllib.request
from typing import Final

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import abc_notation  # noqa: E402
import midi  # noqa: E402
import musicxml  # noqa: E402

REPO: Final[pathlib.Path] = pathlib.Path(__file__).resolve().parents[2]
SOURCES: Final[pathlib.Path] = REPO / "dev" / "music" / "sources.json"
MELODIES: Final[pathlib.Path] = REPO / "dev" / "music" / "melodies"
CACHE: Final[pathlib.Path] = REPO / ".cache" / "music"
MUSIC: Final[pathlib.Path] = REPO / "assets" / "music"

USER_AGENT: Final[str] = "jump-n-mine-dev (music of the game)"

# The General MIDI programs of the instruments named in the parts of a score.
PROGRAMS: Final[dict] = {"Voice": 73, "Piano": 0}


def fetch(url: str) -> bytes:
    """Fetch the URL, waiting when the server asks us to slow down."""
    for attempt in range(6):
        request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.read()
        except urllib.error.HTTPError as error:
            if error.code != 429 or attempt == 5:
                raise
            time.sleep(10.0 * (attempt + 1))
    raise AssertionError("unreachable")


def commons(title: str, expected_license: str) -> str:
    """The URL of the file on Wikimedia Commons, after checking its license."""
    query = urllib.parse.urlencode(
        {
            "action": "query",
            "prop": "imageinfo",
            "iiprop": "url|extmetadata",
            "format": "json",
            "titles": title,
        }
    )
    answer = json.loads(fetch(f"https://commons.wikimedia.org/w/api.php?{query}"))
    info = next(iter(answer["query"]["pages"].values()))["imageinfo"][0]
    license_name = info["extmetadata"]["LicenseShortName"]["value"]
    if license_name != expected_license:
        raise RuntimeError(f"{title} is not under {expected_license}, but {license_name}")
    return info["url"]


def check_mutopia(page: str) -> None:
    text = fetch(page).decode("utf-8", "replace")
    if "Public Domain" not in text:
        raise RuntimeError(f"The Mutopia page {page} no longer says Public Domain")


def download(source: dict) -> pathlib.Path:
    """Download the file of the source into the cache, once."""
    url = source.get("download")
    if "commons" in source:
        url = commons(source["commons"], source["license"])
    elif "mutopiaproject.org" in source["page"]:
        check_mutopia(source["page"])
    suffix = pathlib.PurePosixPath(urllib.parse.urlparse(url).path).suffix.lower()
    path = CACHE / f"{source['slug']}{suffix}"
    if not path.exists():
        CACHE.mkdir(parents=True, exist_ok=True)
        path.write_bytes(fetch(url))
        time.sleep(2.0)
    return path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("slugs", nargs="*", help="fetch only these songs (default: all)")
    args = parser.parse_args()

    sources = json.loads(SOURCES.read_text(encoding="utf-8"))["songs"]
    MUSIC.mkdir(parents=True, exist_ok=True)
    for source in sources:
        if args.slugs and source["slug"] not in args.slugs:
            continue
        out = MUSIC / f"{source['slug']}.mid"
        kind = source["format"]
        if kind == "midi":
            shutil.copyfile(download(source), out)
        elif kind == "musicxml":
            parts, tempi = musicxml.read(download(source), PROGRAMS)
            if "tempo" in source:
                tempi = [(0, float(source["tempo"]))]
            midi.write(out, parts, tempi, source["title"], source["credit"])
        elif kind == "abc":
            tune = abc_notation.read((MELODIES / f"{source['slug']}.abc").read_text("utf-8"))
            midi.write(out, tune.parts, tune.tempi, source["title"], source["credit"])
        else:
            raise ValueError(f"Unknown format {kind} of {source['slug']}")
        print(f"{out.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
