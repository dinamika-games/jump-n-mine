"""
Write the sketches of the sheets of the puzzle gate and of the menu icons.

The sketches tell the image generator where to paint each piece, so that
``cut_sprites.py`` can cut the pieces apart by their boxes:

* ``sketch_gate_sheet.svg``: the iron gate tile and the stone plate, up and
  pressed, as square tiles of the mine.
* ``sketch_icon_sheet.svg``: the icons of the menu cards that are still drawn
  by code.

Usage:

    python3 dev/pictures/make_gate_and_icon_sketches.py <output folder>
"""

import argparse
import pathlib
import shutil
import subprocess
import sys
from typing import Final, List, Optional, Sequence

#: The color of the guides in the sketches (never in the pieces).
GUIDE: Final[str] = "#c0306a"

#: The color of the faint drawing which hints at the piece in its box.
HINT: Final[str] = "#b8b8c8"


class Cell:
    """A cell of a sheet, with the label and the hint drawn in its box."""

    def __init__(self, label: str, hint: Sequence[str]) -> None:
        """Initialize with the given values."""
        self.label = label
        self.hint = hint


class Sheet:
    """A sheet of square boxes in a grid, each with a label band above it."""

    def __init__(self, columns: int, box: int, label_band: int, margin: int) -> None:
        """Initialize with the given values."""
        self.columns = columns
        self.box = box
        self.label_band = label_band
        self.margin = margin

    @property
    def cell_width(self) -> int:
        """Return the width of a cell."""
        return self.box + 2 * self.margin

    @property
    def cell_height(self) -> int:
        """Return the height of a cell."""
        return self.label_band + self.box + self.margin


#: The gate sheet: tiles of 320 px, like the sheets of the blocks.
GATE_SHEET: Final[Sheet] = Sheet(columns=3, box=320, label_band=70, margin=40)

#: The icon sheet: icons of 256 px, like the sheet of the items.
ICON_SHEET: Final[Sheet] = Sheet(columns=4, box=256, label_band=60, margin=32)


def _gate_hint(box: int) -> List[str]:
    """Hint at the bars of the gate, which run to both edges of the tile."""
    parts = []
    bar = box / 5.0
    for k in range(5):
        x = (k + 0.5) * bar
        parts.append(
            f'<line x1="{x}" y1="0" x2="{x}" y2="{box}" stroke="{HINT}" stroke-width="18"/>'
        )
    for y in (box * 0.2, box * 0.8):
        parts.append(
            f'<line x1="0" y1="{y}" x2="{box}" y2="{y}" stroke="{HINT}" stroke-width="12"/>'
        )
    parts.append(
        f'<text x="{box / 2}" y="{box / 2 + 12}" font-family="sans-serif" font-size="30" '
        f'fill="{GUIDE}" text-anchor="middle">&#8592; repeats &#8594;</text>'
    )
    return parts


def _plate_hint(box: int, pressed: bool) -> List[str]:
    """Hint at the stone slab on top of the bedrock tile."""
    sink = box * 6 / 174 if pressed else 0.0
    top = box * 4 / 174 + sink
    height = box * 18 / 174 * 1.6
    inset = box * 6 / 174
    parts = [
        f'<rect x="{inset}" y="{top}" width="{box - 2 * inset}" height="{height}" rx="10" '
        f'fill="none" stroke="{HINT}" stroke-width="6"/>',
        f'<circle cx="{box / 2}" cy="{top + height / 2}" r="{height * 0.32}" '
        f'fill="{"#7cf04f" if pressed else "#ffcf3a"}" fill-opacity="0.6"/>',
        f'<text x="{box / 2}" y="{box * 0.66}" font-family="sans-serif" font-size="28" '
        f'fill="{GUIDE}" text-anchor="middle">bedrock below</text>',
    ]
    return parts


def _write_svg(path: pathlib.Path, sheet: Sheet, cells: Sequence[Cell]) -> None:
    """Write the sketch of the sheet with the cells to the path."""
    rows = (len(cells) + sheet.columns - 1) // sheet.columns
    width = sheet.cell_width * sheet.columns
    height = sheet.cell_height * rows
    body = [f'<rect width="{width}" height="{height}" fill="#ffffff"/>']
    for i, cell in enumerate(cells):
        dx = (i % sheet.columns) * sheet.cell_width
        dy = (i // sheet.columns) * sheet.cell_height
        body.append(
            f'<rect x="{dx}" y="{dy}" width="{sheet.cell_width}" height="{sheet.cell_height}" '
            f'fill="none" stroke="#c8c8c8" stroke-width="2"/>'
        )
        body.append(
            f'<text x="{dx + sheet.cell_width / 2}" y="{dy + sheet.label_band * 0.7}" '
            f'font-family="sans-serif" font-weight="bold" font-size="30" fill="{GUIDE}" '
            f'text-anchor="middle">{i + 1}. {cell.label}</text>'
        )
        bx = dx + sheet.margin
        by = dy + sheet.label_band
        body.append(f'<g transform="translate({bx},{by})">')
        body.extend(f"  {part}" for part in cell.hint)
        body.append(
            f'  <rect x="0" y="0" width="{sheet.box}" height="{sheet.box}" fill="none" '
            f'stroke="{GUIDE}" stroke-width="3" stroke-dasharray="12,8"/>'
        )
        body.append("</g>")
    svg = (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}">\n'
        + "\n".join(f"  {part}" for part in body)
        + "\n</svg>\n"
    )
    path.write_text(svg, encoding="utf-8")


def _icon_hint(symbol: str) -> List[str]:
    """Hint at the icon with a big faint symbol in the middle of its box."""
    return [
        f'<circle cx="{ICON_SHEET.box / 2}" cy="{ICON_SHEET.box / 2}" r="{ICON_SHEET.box * 0.42}" '
        f'fill="none" stroke="{HINT}" stroke-width="3" stroke-dasharray="4,6"/>',
        f'<text x="{ICON_SHEET.box / 2}" y="{ICON_SHEET.box / 2 + 45}" font-family="sans-serif" '
        f'font-weight="bold" font-size="130" fill="{HINT}" text-anchor="middle">{symbol}</text>',
    ]


def _lock_hint() -> List[str]:
    """Hint at a padlock (the font of the sketch has no glyph for it)."""
    middle = ICON_SHEET.box / 2
    return _icon_hint("") + [
        f'<path d="M {middle - 34} {middle} v -30 a 34 34 0 0 1 68 0 v 30" fill="none" '
        f'stroke="{HINT}" stroke-width="16"/>',
        f'<rect x="{middle - 52}" y="{middle - 4}" width="104" height="80" rx="10" fill="{HINT}"/>',
    ]


#: The cells of the gate sheet.
GATE_CELLS: Final[Sequence[Cell]] = (
    Cell("iron gate (tile)", _gate_hint(GATE_SHEET.box)),
    Cell("plate, waiting", _plate_hint(GATE_SHEET.box, pressed=False)),
    Cell("plate, pressed", _plate_hint(GATE_SHEET.box, pressed=True)),
)

#: The cells of the icon sheet.
ICON_CELLS: Final[Sequence[Cell]] = (
    Cell("How to play", _icon_hint("?")),
    Cell("Quit", _icon_hint("&#215;")),
    Cell("Back", _icon_hint("&#9664;")),
    Cell("Next", _icon_hint("&#9654;")),
    Cell("Again", _icon_hint("&#8635;")),
    Cell("OK / Keep", _icon_hint("&#10003;")),
    Cell("Delete", _icon_hint("&#128465;")),
    Cell("Locked", _lock_hint()),
)


def _write_png(svg: pathlib.Path) -> Optional[pathlib.Path]:
    """Render the SVG to a PNG next to it with Inkscape; return None without it."""
    inkscape = shutil.which("inkscape")
    if inkscape is None:
        return None
    png = svg.with_suffix(".png")
    subprocess.run(
        [inkscape, str(svg), "--export-type=png", f"--export-filename={png}"],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return png


def main() -> int:
    """Execute the main routine."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", help="the folder to write the sketches into")
    args = parser.parse_args()

    output = pathlib.Path(args.output)
    for folder, name, sheet, cells in (
        ("gate", "sketch_gate_sheet.svg", GATE_SHEET, GATE_CELLS),
        ("icons", "sketch_icon_sheet.svg", ICON_SHEET, ICON_CELLS),
    ):
        (output / folder).mkdir(parents=True, exist_ok=True)
        svg = output / folder / name
        _write_svg(svg, sheet, cells)
        png = _write_png(svg)
        print(f"Wrote {svg}" + (f" and {png}" if png is not None else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
