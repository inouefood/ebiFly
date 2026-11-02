#!/usr/bin/env python3
"""App Store search-result artwork (5244x2950 / 3840x2560 / 1920x1280, opaque PNG).

Big catch copy on the left; on the right three fried shrimp blast out of the frying pot (fry -> fly),
drawn with the app's own SVG symbols (art.py). Kept bold and simple so it reads at thumbnail size.

    python3 Design/store_search.py   ->  Design/store/search-<w>x<h>.png
"""
import math
import random
import subprocess
from pathlib import Path

import art
from store_header import shrimp, use

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "store"
WORK = ROOT / "build" / "search"
INK = art.INK
W = 1920  # design width; height follows the aspect ratio (1080 for 16:9, 1280 for 3:2)
SIZES = [(5244, 2950), (3840, 2560), (1920, 1280)]


def scene(dh):
    rng = random.Random(9)
    c = 0.86 if dh < 1200 else 1.0  # 16:9 is shorter: shrink the shrimp so the lead one clears the top edge
    px, top = 1400, dh - 400          # pot centre x / top edge of the pot symbol
    pw, ph = 340 * 2.0, 180 * 2.0
    rim = top + 40 * 2.0              # y of the oil surface
    cx, cy = px, rim - 260            # sunburst centre, behind the shrimp
    rays = "".join(
        f'<path d="M{cx} {cy} L{cx + 2600 * math.cos(math.radians(a)):.0f} {cy + 2600 * math.sin(math.radians(a)):.0f} '
        f'L{cx + 2600 * math.cos(math.radians(a + 9)):.0f} {cy + 2600 * math.sin(math.radians(a + 9)):.0f}Z" fill="#fff" opacity=".16"/>'
        for a in range(0, 360, 18)
    )
    stars = "".join(use("star", x, y, z, z) for x, y, z in
                    [(80, 60, 50), (560, 40, 36), (980, 90, 44), (1840, 70, 46), (1880, 420, 30), (70, dh - 330, 34)])
    # oil splashing out of the pot
    splash = []
    for i in range(12):
        a = math.radians(rng.uniform(-160, -20))
        d = rng.uniform(260, 470)
        x, y = px + math.cos(a) * d * 1.3, rim + math.sin(a) * d * 0.75
        z = rng.uniform(32, 54)
        splash.append(f'<use href="#oil-drop" x="{x - z / 2:.0f}" y="{y - z / 2:.0f}" width="{z:.0f}" height="{z * 1.35:.0f}" '
                      f'transform="rotate({math.degrees(a) + 90:.0f} {x:.0f} {y:.0f})"/>')
    lines = "".join(f'<path d="M{px + dx} {rim - 40} L{px + dx * 1.25} {rim - 40 - ln}"/>'
                    for dx, ln in [(-250, 160), (-120, 260), (130, 260), (260, 160)])
    return f"""
<defs>
 <linearGradient id="srSky" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#2a63c8"/><stop offset=".45" stop-color="#5cc2ff"/><stop offset=".8" stop-color="#bfe8ff"/><stop offset="1" stop-color="#ffe9a8"/>
 </linearGradient>
 <radialGradient id="srGlow" cx="{cx / W}" cy="{cy / dh}" r=".5"><stop offset="0" stop-color="#fff3b0" stop-opacity=".95"/><stop offset="1" stop-color="#fff3b0" stop-opacity="0"/></radialGradient>
</defs>
<rect width="{W}" height="{dh}" fill="url(#srSky)"/>
<rect width="{W}" height="{dh}" fill="url(#srGlow)"/>
{rays}
{stars}
{use("cloud", -170, dh - 210, 560, 314)}
{use("cloud", 560, dh - 150, 400, 224)}
{use("cloud", 1640, dh - 330, 460, 258)}
{use("bird", 1760, 230, 80, 55)}
<g stroke="#fff" stroke-width="20" stroke-linecap="round" opacity=".85">{lines}</g>
{use("pot-back", px - pw / 2, top, pw, ph)}
{''.join(splash)}
{shrimp(px - 230, rim - 330 * c, -28, 1.05 * c, 4, "heart")}
{shrimp(px + 250, rim - 330 * c, 28, 1.05 * c, 4, "crown")}
{shrimp(px, rim - 470 * c, 0, 1.45 * c, 5, "normal")}
{use("pot-front", px - pw / 2, top, pw, ph)}
"""


def page(width, height):
    dh = round(W * height / width)
    k = width / W
    fonts = (ROOT / "fonts").as_uri()
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
@font-face {{ font-family: Dela; src: url('{fonts}/DelaGothicOne-Regular.ttf'); }}
@font-face {{ font-family: ZenBlack; src: url('{fonts}/ZenMaruGothic-Black.ttf'); }}
html, body {{ margin: 0; width: {width}px; height: {height}px; overflow: hidden; background: #5cc2ff; }}
.stage {{ position: absolute; left: 0; top: 0; width: {W}px; height: {dh}px; transform: scale({k}); transform-origin: 0 0; }}
.stage > svg {{ position: absolute; inset: 0; }}
.copy {{ position: absolute; left: 70px; top: {dh / 2 - 300:.0f}px; width: 960px; text-align: center; }}
.head {{ font-family: Dela; font-size: 148px; line-height: 1.22; color: #f6c445; white-space: nowrap;
  -webkit-text-stroke: 18px {INK}; paint-order: stroke fill; text-shadow: 13px 13px 0 {INK}; }}
.head .w {{ color: #fff; }}
.sub {{ display: inline-block; margin-top: 44px; padding: 14px 48px; border-radius: 999px; background: {INK}; color: #fff;
  font-family: ZenBlack; font-size: 52px; letter-spacing: .03em; }}
</style></head><body><div class="stage">
{art.symbols_block()}
<svg viewBox="0 0 {W} {dh}" width="{W}" height="{dh}">{scene(dh)}</svg>
<div class="copy">
 <div class="head"><span class="w">揚げて</span>、<br>空まで飛ばせ！</div>
 <div class="sub">ふって・かたむけて遊ぶアクション</div>
</div>
</div></body></html>"""


def main():
    OUT.mkdir(exist_ok=True)
    WORK.mkdir(parents=True, exist_ok=True)
    for w, h in SIZES:
        html = WORK / f"search-{w}x{h}.html"
        html.write_text(page(w, h))
        png = WORK / f"search-{w}x{h}.png"
        subprocess.run(["swift", str(ROOT / "tools" / "pageshot.swift"), str(html), str(png), str(w), str(h)], check=True)
        # PNG without alpha at the exact size: resample, flatten via JPEG, back to PNG
        jpg = WORK / f"search-{w}x{h}.jpg"
        subprocess.run(["sips", "-z", str(h), str(w), "-s", "format", "jpeg", "-s", "formatOptions", "best", str(png), "--out", str(jpg)],
                       check=True, capture_output=True)
        final = OUT / f"search-{w}x{h}.png"
        subprocess.run(["sips", "-s", "format", "png", str(jpg), "--out", str(final)], check=True, capture_output=True)
        print(final)


if __name__ == "__main__":
    main()
