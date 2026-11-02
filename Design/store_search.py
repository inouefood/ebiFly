#!/usr/bin/env python3
"""App Store search-result artwork (5244x2950 / 3840x2560 / 1920x1280, opaque PNG).

Catch copy with three fried shrimp blasting out of the frying pot beside it (fry -> fly), drawn with the
app's own SVG symbols (art.py). The copy and pot are packed into the centre so the iPhone crop keeps them.

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


# The cast (copy + pot + shrimp) is laid out in its own CW x CH frame, then shrunk into the iPhone-visible box.
# On iPhone the App Store shows only the centre ~53% of the width and the top ~63% of the height of a 16:9
# artwork, with the status bar / buttons over the top (see store_header.SAFE); the rest is decoration.
CW, CH = 1700, 860
BOX = (540, 240, 1380, 670)  # target box in the 1920x1080 frame; 3:2 canvases shift it down by (dh - 1080) / 2


def cast_frame():
    px, top = 1370, 500               # pot centre x / top edge of the pot symbol
    pw, ph = 340 * 2.0, 180 * 2.0
    rim = top + 40 * 2.0              # y of the oil surface
    return px, top, pw, ph, rim


def placement(dh):
    x0, y0, x1, y1 = BOX
    oy = (dh - 1080) / 2 if dh > 1080 else 0
    sc = min((x1 - x0) / CW, (y1 - y0) / CH)
    tx = (x0 + x1) / 2 - CW * sc / 2
    ty = oy + (y0 + y1) / 2 - CH * sc / 2
    return sc, tx, ty


def scene(dh):
    rng = random.Random(9)
    sc, tx, ty = placement(dh)
    px, top, pw, ph, rim = cast_frame()
    cx, cy = tx + CW / 2 * sc, ty + CH / 2 * sc  # sunburst centre, behind the cast
    rays = "".join(
        f'<path d="M{cx:.0f} {cy:.0f} L{cx + 2600 * math.cos(math.radians(a)):.0f} {cy + 2600 * math.sin(math.radians(a)):.0f} '
        f'L{cx + 2600 * math.cos(math.radians(a + 9)):.0f} {cy + 2600 * math.sin(math.radians(a + 9)):.0f}Z" fill="#fff" opacity=".16"/>'
        for a in range(0, 360, 18)
    )
    stars = "".join(use("star", x, y, z, z) for x, y, z in
                    [(80, 60, 50), (560, 40, 36), (980, 90, 44), (1840, 70, 46), (1880, 420, 30), (70, dh - 330, 34),
                     (300, 420, 30), (1600, 560, 34)])
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
    c = 0.86
    return f"""
<defs>
 <linearGradient id="srSky" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#2a63c8"/><stop offset=".45" stop-color="#5cc2ff"/><stop offset=".8" stop-color="#bfe8ff"/><stop offset="1" stop-color="#ffe9a8"/>
 </linearGradient>
 <radialGradient id="srGlow" cx="{cx / W}" cy="{cy / dh}" r=".4"><stop offset="0" stop-color="#fff3b0" stop-opacity=".95"/><stop offset="1" stop-color="#fff3b0" stop-opacity="0"/></radialGradient>
</defs>
<rect width="{W}" height="{dh}" fill="url(#srSky)"/>
<rect width="{W}" height="{dh}" fill="url(#srGlow)"/>
{rays}
{stars}
{use("plane", 170, 220, 200, 94)}
{use("moon", 1720, 150, 120, 120)}
{use("bird", 1560, 380, 80, 55)}
{use("bird", 330, 600, 70, 48)}
{use("cloud", -170, dh - 210, 560, 314)}
{use("cloud", 560, dh - 150, 400, 224)}
{use("cloud", 1100, dh - 170, 420, 235)}
{use("cloud", 1640, dh - 330, 460, 258)}
{shrimp(230, dh - 330, -20, 0.9, 3, "heart")}
{shrimp(1700, dh - 380, 25, 0.9, 3, "crown")}
<g transform="translate({tx:.1f} {ty:.1f}) scale({sc:.4f})">
<g stroke="#fff" stroke-width="20" stroke-linecap="round" opacity=".85">{lines}</g>
{use("pot-back", px - pw / 2, top, pw, ph)}
{''.join(splash)}
{shrimp(px - 230, rim - 330 * c, -28, 1.05 * c, 4, "heart")}
{shrimp(px + 250, rim - 330 * c, 28, 1.05 * c, 4, "crown")}
{shrimp(px, rim - 470 * c, 0, 1.45 * c, 5, "normal")}
{use("pot-front", px - pw / 2, top, pw, ph)}
</g>
"""


def page(width, height):
    dh = round(W * height / width)
    k = width / W
    sc, tx, ty = placement(dh)
    fonts = (ROOT / "fonts").as_uri()
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
@font-face {{ font-family: Dela; src: url('{fonts}/DelaGothicOne-Regular.ttf'); }}
@font-face {{ font-family: ZenBlack; src: url('{fonts}/ZenMaruGothic-Black.ttf'); }}
html, body {{ margin: 0; width: {width}px; height: {height}px; overflow: hidden; background: #5cc2ff; }}
.stage {{ position: absolute; left: 0; top: 0; width: {W}px; height: {dh}px; transform: scale({k}); transform-origin: 0 0; }}
.stage > svg {{ position: absolute; inset: 0; }}
.cast {{ position: absolute; left: {tx:.1f}px; top: {ty:.1f}px; width: {CW}px; height: {CH}px; transform: scale({sc:.4f}); transform-origin: 0 0; }}
.copy {{ position: absolute; left: 0; top: {CH / 2 - 290:.0f}px; width: 1060px; text-align: center; }}
.head {{ font-family: Dela; font-size: 148px; line-height: 1.22; color: #f6c445; white-space: nowrap;
  -webkit-text-stroke: 18px {INK}; paint-order: stroke fill; text-shadow: 13px 13px 0 {INK}; }}
.head .w {{ color: #fff; }}
.sub {{ display: inline-block; margin-top: 44px; padding: 14px 48px; border-radius: 999px; background: {INK}; color: #fff;
  font-family: ZenBlack; font-size: 52px; letter-spacing: .03em; white-space: nowrap; }}
</style></head><body><div class="stage">
{art.symbols_block()}
<svg viewBox="0 0 {W} {dh}" width="{W}" height="{dh}">{scene(dh)}</svg>
<div class="cast"><div class="copy">
 <div class="head"><span class="w">揚げて</span>、<br>空まで飛ばせ！</div>
 <div class="sub">ふって・かたむけて遊ぶアクション</div>
</div></div>
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
