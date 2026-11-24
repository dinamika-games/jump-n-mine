#!/usr/bin/env python3
"""
Write the sketches of the six frames of the story (1920 x 1080 SVG) to
assets/pictures/intro/frame_<n>.svg.

The game shows the sketches until the painted frames are there
(assets/pictures/intro/frame_<n>.png, see dev/pictures/prompts/intro.md); the
sketches give the image generator the composition of each frame.
"""

import pathlib
import sys
from typing import Final, Mapping

REPO: Final[pathlib.Path] = pathlib.Path(__file__).resolve().parent.parent.parent.parent

OUTLINE: Final[str] = "#1a1016"
TUNICS: Final[Mapping[str, str]] = {
    "red": "#c8402e",
    "blue": "#3a6ad0",
    "green": "#3f9a3a",
    "yellow": "#e0b020",
}
EVIL: Final[str] = "#3a2a48"


def svg(body: str, sky_top: str, sky_bottom: str) -> str:
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080">
<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{sky_top}"/><stop offset="1" stop-color="{sky_bottom}"/>
  </linearGradient>
  <radialGradient id="glow"><stop offset="0" stop-color="#fff3b0" stop-opacity="0.9"/>
    <stop offset="1" stop-color="#ffd040" stop-opacity="0"/></radialGradient>
</defs>
<rect width="1920" height="1080" fill="url(#sky)"/>
{body}
</svg>
"""


def mountains(color: str = "#6a5a7a", snow: bool = True) -> str:
    peaks = [
        (0, 700, 300, 260, 640, 700),
        (420, 720, 860, 180, 1320, 720),
        (1100, 720, 1560, 300, 1920, 680),
    ]
    out = []
    for x1, y1, xp, yp, x2, y2 in peaks:
        out.append(
            f'<polygon points="{x1},{y1} {xp},{yp} {x2},{y2}" fill="{color}" stroke="{OUTLINE}" stroke-width="6"/>'
        )
        if snow:
            out.append(
                f'<polygon points="{xp - 70},{yp + 90} {xp},{yp} {xp + 70},{yp + 90} {xp + 30},{yp + 70} {xp},{yp + 100} {xp - 30},{yp + 70}" fill="#f4f0ff"/>'
            )
    return "\n".join(out)


def ground(color: str = "#5c9c45", top: int = 700) -> str:
    return f'<rect x="0" y="{top}" width="1920" height="{1080 - top}" fill="{color}"/>'


def dwarf(
    x: float,
    y: float,
    scale: float = 1.0,
    tunic: str = "#c8402e",
    facing: int = 1,
    pick_up: bool = False,
    evil: bool = False,
    carry: str = "",
) -> str:
    """A dwarf standing with its feet at (x, y), 260 px tall at scale 1."""
    beard = "#6a6a72" if evil else "#e8e0d0"
    skin = "#d8b8a0" if evil else "#f2c8a0"
    hat = "#141018" if evil else "#e8a030"
    pick_rot = -60 if pick_up else 30
    badge = ""
    if evil:
        badge = (
            '<circle cx="0" cy="-120" r="22" fill="#6a2a8a" stroke="#1a1016" stroke-width="5"/>'
            '<polygon points="-14,-112 -14,-130 -7,-120 0,-134 7,-120 14,-130 14,-112" fill="#141018"/>'
        )
    load = ""
    if carry == "gems":
        load = (
            '<g transform="translate(-130,90)">'
            '<rect x="-60" y="-200" width="120" height="70" rx="10" fill="#8a5a32" stroke="#1a1016" stroke-width="5"/>'
            '<polygon points="-40,-200 -25,-230 -10,-200" fill="#3ee6f0" stroke="#1a1016" stroke-width="3"/>'
            '<polygon points="0,-200 15,-238 30,-200" fill="#f04fd0" stroke="#1a1016" stroke-width="3"/>'
            '<polygon points="30,-200 42,-222 54,-200" fill="#ffd23e" stroke="#1a1016" stroke-width="3"/>'
            "</g>"
        )
    return f"""<g transform="translate({x},{y}) scale({facing * scale},{scale})">
  <ellipse cx="0" cy="0" rx="70" ry="12" fill="#000" opacity="0.25"/>
  <rect x="-45" y="-60" width="30" height="60" rx="8" fill="#4a3426" stroke="{OUTLINE}" stroke-width="5"/>
  <rect x="15" y="-60" width="30" height="60" rx="8" fill="#4a3426" stroke="{OUTLINE}" stroke-width="5"/>
  <path d="M-60,-60 Q-70,-170 0,-175 Q70,-170 60,-60 Z" fill="{EVIL if evil else tunic}" stroke="{OUTLINE}" stroke-width="6"/>
  <rect x="-62" y="-80" width="124" height="16" fill="#3a2418" stroke="{OUTLINE}" stroke-width="4"/>
  {badge}
  <g transform="translate(50,-120) rotate({pick_rot})">
    <rect x="-6" y="-110" width="12" height="130" fill="#8a5a32" stroke="{OUTLINE}" stroke-width="4"/>
    <path d="M-60,-110 Q0,-140 60,-110 L50,-100 Q0,-120 -50,-100 Z" fill="#b9c3cf" stroke="{OUTLINE}" stroke-width="5"/>
  </g>
  <circle cx="0" cy="-205" r="42" fill="{skin}" stroke="{OUTLINE}" stroke-width="6"/>
  <path d="M-40,-200 Q-45,-120 0,-110 Q45,-120 40,-200 Q20,-180 0,-185 Q-20,-180 -40,-200 Z" fill="{beard}" stroke="{OUTLINE}" stroke-width="5"/>
  <circle cx="14" cy="-215" r="6" fill="{OUTLINE}"/>
  <path d="M-48,-225 Q0,-290 48,-225 Z" fill="{hat}" stroke="{OUTLINE}" stroke-width="6"/>
  <rect x="-55" y="-232" width="110" height="14" rx="6" fill="{hat}" stroke="{OUTLINE}" stroke-width="5"/>
  {'' if evil else '<circle cx="0" cy="-250" r="12" fill="#fff3b0" stroke="#1a1016" stroke-width="4"/>'}
  {load}
</g>"""


def person(x: float, y: float, shirt: str, sign: str = "", scale: float = 1.0) -> str:
    sign_svg = ""
    if sign:
        sign_svg = (
            f'<line x1="30" y1="-150" x2="30" y2="-300" stroke="#5e3a1e" stroke-width="8"/>'
            f'<rect x="-50" y="-370" width="160" height="80" rx="8" fill="#fff8e8" stroke="{OUTLINE}" stroke-width="5"/>'
            f'<text x="30" y="-320" font-family="sans-serif" font-size="30" font-weight="bold" text-anchor="middle" fill="{OUTLINE}">{sign}</text>'
        )
    return f"""<g transform="translate({x},{y}) scale({scale})">
  <rect x="-25" y="-90" width="20" height="90" fill="#3a3a5a" stroke="{OUTLINE}" stroke-width="4"/>
  <rect x="5" y="-90" width="20" height="90" fill="#3a3a5a" stroke="{OUTLINE}" stroke-width="4"/>
  <rect x="-40" y="-200" width="80" height="115" rx="20" fill="{shirt}" stroke="{OUTLINE}" stroke-width="5"/>
  <circle cx="0" cy="-235" r="34" fill="#e8b890" stroke="{OUTLINE}" stroke-width="5"/>
  <path d="M-34,-245 Q0,-285 34,-245 Q20,-265 0,-262 Q-20,-265 -34,-245 Z" fill="#5a3a22"/>
  {sign_svg}
</g>"""


def queen(x: float, y: float, scale: float = 1.0) -> str:
    return f"""<g transform="translate({x},{y}) scale({scale})">
  <path d="M-130,0 Q-100,-260 0,-280 Q100,-260 130,0 Z" fill="#2a1a3a" stroke="{OUTLINE}" stroke-width="7"/>
  <path d="M-90,-250 L-150,-330 L-60,-280 Z" fill="#4a2a6a" stroke="{OUTLINE}" stroke-width="6"/>
  <path d="M90,-250 L150,-330 L60,-280 Z" fill="#4a2a6a" stroke="{OUTLINE}" stroke-width="6"/>
  <ellipse cx="0" cy="-340" rx="52" ry="62" fill="#d8c8d8" stroke="{OUTLINE}" stroke-width="7"/>
  <path d="M-30,-350 L-10,-342" stroke="{OUTLINE}" stroke-width="7"/>
  <path d="M30,-350 L10,-342" stroke="{OUTLINE}" stroke-width="7"/>
  <path d="M-22,-305 Q0,-315 22,-305" stroke="{OUTLINE}" stroke-width="6" fill="none"/>
  <polygon points="-56,-390 -56,-440 -28,-410 0,-460 28,-410 56,-440 56,-390" fill="#141018" stroke="#8a50b0" stroke-width="5"/>
  <circle cx="0" cy="-425" r="9" fill="#d0203a"/>
</g>"""


def castle(x: float, y: float, scale: float = 1.0) -> str:
    return f"""<g transform="translate({x},{y}) scale({scale})">
  <rect x="-300" y="-380" width="600" height="380" fill="#3a3444" stroke="{OUTLINE}" stroke-width="8"/>
  <rect x="-380" y="-560" width="140" height="560" fill="#2e2838" stroke="{OUTLINE}" stroke-width="8"/>
  <rect x="240" y="-560" width="140" height="560" fill="#2e2838" stroke="{OUTLINE}" stroke-width="8"/>
  <polygon points="-400,-560 -310,-700 -220,-560" fill="#1a1020" stroke="{OUTLINE}" stroke-width="8"/>
  <polygon points="220,-560 310,-700 400,-560" fill="#1a1020" stroke="{OUTLINE}" stroke-width="8"/>
  <path d="M-80,0 L-80,-160 Q0,-240 80,-160 L80,0 Z" fill="#141018"/>
  <rect x="-200" y="-300" width="50" height="80" fill="#d04060" opacity="0.8"/>
  <rect x="150" y="-300" width="50" height="80" fill="#d04060" opacity="0.8"/>
  <line x1="310" y1="-700" x2="310" y2="-800" stroke="{OUTLINE}" stroke-width="6"/>
  <polygon points="310,-800 400,-775 310,-750" fill="#6a2a8a"/>
</g>"""


def gems(x: float, y: float) -> str:
    return (
        f'<polygon points="{x},{y} {x + 25},{y - 45} {x + 50},{y}" fill="#3ee6f0" stroke="{OUTLINE}" stroke-width="5"/>'
        f'<polygon points="{x + 40},{y} {x + 70},{y - 60} {x + 100},{y}" fill="#f04fd0" stroke="{OUTLINE}" stroke-width="5"/>'
        f'<polygon points="{x + 90},{y} {x + 112},{y - 40} {x + 134},{y}" fill="#ffd23e" stroke="{OUTLINE}" stroke-width="5"/>'
    )


def chest(x: float, y: float, scale: float = 1.0) -> str:
    return f"""<g transform="translate({x},{y}) scale({scale})">
  <circle cx="0" cy="-80" r="180" fill="url(#glow)"/>
  <rect x="-110" y="-120" width="220" height="120" rx="10" fill="#8a5a32" stroke="{OUTLINE}" stroke-width="7"/>
  <path d="M-110,-120 Q0,-210 110,-120 Z" fill="#a86a3a" stroke="{OUTLINE}" stroke-width="7"/>
  <rect x="-20" y="-140" width="40" height="50" fill="#ffcf3a" stroke="{OUTLINE}" stroke-width="5"/>
  {gems(-60, -150)}
</g>"""


def frame_1() -> str:
    body = mountains() + ground("#5c9c45")
    body += '<path d="M760,700 Q860,560 960,700 Z" fill="#1b1218"/>'
    body += dwarf(620, 900, 1.2, TUNICS["red"], 1, carry="gems")
    body += dwarf(900, 760, 0.9, TUNICS["blue"], 1, pick_up=True)
    body += dwarf(1180, 920, 1.2, TUNICS["green"], -1, carry="gems")
    body += person(1500, 950, "#d08a3a", scale=1.1) + person(1650, 960, "#4a8ad0", scale=0.9)
    body += gems(1360, 900)
    return svg(body, "#7ec8f0", "#d8f0ff")


def frame_2() -> str:
    body = ground("#8a7a6a", 620)
    for k in range(6):
        x = 200 + k * 300
        body += f'<rect x="{x - 120}" y="{300 + (k % 2) * 40}" width="240" height="{320 - (k % 2) * 40}" fill="#c8a880" stroke="{OUTLINE}" stroke-width="6"/>'
        body += f'<polygon points="{x - 140},{300 + (k % 2) * 40} {x},{200 + (k % 2) * 40} {x + 140},{300 + (k % 2) * 40}" fill="#b8452f" stroke="{OUTLINE}" stroke-width="6"/>'
    signs = ["Fair work!", "Bread!", "Schools!", "Share!"]
    for k, sign in enumerate(signs):
        body += person(
            300 + k * 260,
            960 - (k % 2) * 20,
            ["#d08a3a", "#4a8ad0", "#7ac05a", "#d05a8a"][k],
            sign,
        )
    body += dwarf(1400, 980, 1.0, TUNICS["red"], -1)
    body += dwarf(1620, 990, 1.0, TUNICS["yellow"], -1)
    return svg(body, "#f0c890", "#fff0d8")


def frame_3() -> str:
    body = mountains("#2a2234", snow=False) + ground("#2a2a30", 760)
    body += castle(960, 900, 1.0)
    body += '<circle cx="1650" cy="160" r="70" fill="#e8e0f0" opacity="0.7"/>'
    body += queen(960, 1080, 1.3)
    return svg(body, "#1a1428", "#4a3a5a")


def frame_4() -> str:
    body = '<rect x="0" y="0" width="1920" height="1080" fill="#2a1a2a"/>'
    body += '<rect x="200" y="640" width="1520" height="60" fill="#5e3a1e" stroke="#1a1016" stroke-width="6"/>'
    body += '<path d="M200,560 L1720,560 L1720,640 L200,640 Z" fill="#8a5a32" stroke="#1a1016" stroke-width="6"/>'
    body += '<path d="M260,560 Q500,520 780,560" fill="none" stroke="#f4e6c0" stroke-width="40"/>'
    for k in range(5):
        body += f'<polygon points="{900 + k * 60},560 {930 + k * 60},{500 - k * 6} {960 + k * 60},560" fill="#3a3a44" stroke="#1a1016" stroke-width="5"/>'
    body += gems(1320, 560) + gems(1460, 560)
    body += queen(560, 560, 1.0)
    body += '<text x="1300" y="380" font-family="sans-serif" font-size="140" fill="#d0203a" opacity="0.6">⚔</text>'
    return svg(body, "#2a1a2a", "#4a2a3a")


def frame_5() -> str:
    body = mountains("#4a3a4a", snow=False) + ground("#4a3a3a", 760)
    body += castle(260, 760, 0.5)
    for k in range(4):
        body += dwarf(
            700 + k * 280,
            960 - (k % 2) * 30,
            1.0,
            EVIL,
            1,
            pick_up=k % 2 == 0,
            evil=True,
        )
    body += '<path d="M1700,760 Q1800,620 1900,760 Z" fill="#1b1218"/>'
    return svg(body, "#6a3a3a", "#c88a6a")


def frame_6() -> str:
    body = '<rect x="0" y="0" width="1920" height="1080" fill="#241a33"/>'
    for k in range(8):
        y = 600 + (k % 2) * 160
        body += f'<rect x="{k * 240}" y="{y}" width="240" height="{1080 - y}" fill="#d99a52" stroke="#1a1016" stroke-width="5"/>'
    body += chest(1500, 980, 1.1)
    body += dwarf(500, 760, 1.3, TUNICS["red"], 1, pick_up=True)
    body += dwarf(820, 920, 1.3, TUNICS["blue"], 1, pick_up=False)
    body += dwarf(1150, 760, 1.0, TUNICS["green"], 1, pick_up=True)
    body += dwarf(200, 920, 0.9, EVIL, 1, evil=True)
    return svg(body, "#241a33", "#31243f")


def main() -> int:
    out = REPO / "assets" / "pictures" / "intro"
    if len(sys.argv) > 1:
        out = pathlib.Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    for n, frame in enumerate([frame_1, frame_2, frame_3, frame_4, frame_5, frame_6], start=1):
        (out / f"frame_{n}.svg").write_text(frame(), encoding="utf-8")
        print(out / f"frame_{n}.svg")
    return 0


if __name__ == "__main__":
    sys.exit(main())
