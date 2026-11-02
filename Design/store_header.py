#!/usr/bin/env python3
"""App Store header / promotional artwork (App Store Connect header / search-result sizes, opaque PNG).

Logo + catch copy on the left, a big fried shrimp blasting off on the right, built from the same
SVG symbols as the app art (art.py).
On iPhone the App Store shows only the centre ~53% of the width and the top ~63% of the height of a
16:9 header, with the status bar and back/share buttons over the top. So the logo, copy and hero shrimp
all sit inside SAFE; everything outside it is decoration that only iPad/Mac show.

    python3 Design/store_header.py   ->  Design/store/header-<w>x<h>.png for each size in SIZES
"""
import math
import random
import subprocess
from pathlib import Path

import art

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "store"
WORK = ROOT / "build" / "header"
INK = art.INK
W, H = 1920, 1080  # reference layout (16:9); other aspect ratios widen the canvas and rescale around it
# sizes App Store Connect accepts: header 5244x2950 / 3840x1646, search results 5244x2950 / 3840x2560 / 1920x1280
SIZES = [(5244, 2950), (3840, 1646), (3840, 2560), (1920, 1280)]
# iPhone-visible box for key content, in the 1920x1080 reference layout (x0, y0, x1, y1), with a margin
SAFE = (540, 260, 1380, 640)


def use(sym, x, y, w, h, extra=""):
    return f'<use href="#{sym}" x="{x}" y="{y}" width="{w}" height="{h}" {extra}/>'


def shrimp(x, y, angle, scale, n, tail):
    # art.shrimp_group points the head down (+y); rotate so the head points along `angle` (deg, 0 = up)
    return (f'<g transform="translate({x} {y}) rotate({180 + angle}) scale({scale}) translate(0 -80)" '
            f'style="--crust:#efa53a;--crumb:#c06f1c">{art.shrimp_group(n, tail)}</g>')


def scene(dw, dh, s, tx, ty):
    # dw x dh: canvas in design units; the shrimp group is drawn in 1920x1080 coordinates, scaled by s and moved by (tx, ty)
    cx, cy = tx + 960 * s, ty + 450 * s  # centre of the sunburst, behind the logo
    rays = "".join(
        f'<path d="M{cx} {cy} L{cx + 2200 * math.cos(math.radians(a)):.0f} {cy + 2200 * math.sin(math.radians(a)):.0f} '
        f'L{cx + 2200 * math.cos(math.radians(a + 9)):.0f} {cy + 2200 * math.sin(math.radians(a + 9)):.0f}Z" fill="#fff" opacity=".13"/>'
        for a in range(0, 360, 18)
    )
    rng = random.Random(5)
    stars = "".join(use("star", x * dw / W, y * dh / H, z, z) for x, y, z in
                    [(90, 70, 54), (640, 50, 38), (900, 140, 30), (1040, 60, 44), (60, 420, 30)])
    # hero: flying up-right; the trail of fuel drops and speed lines runs back down-left from the tail
    hx, hy, ang = 1250, 345, 62
    back = math.radians(ang + 180)
    dx, dy = math.sin(back), -math.cos(back)  # unit vector pointing from head towards the tail
    drops = []
    for i in range(7):
        d = 150 + i * 26 + rng.uniform(-10, 10)
        side = rng.uniform(-40, 40) * (0.4 + i / 7)
        px, py = hx + dx * d - dy * side, hy + dy * d + dx * side
        z = max(22, 44 - i * 3) * rng.uniform(.8, 1.1)
        drops.append(f'<use href="#oil-drop" x="{px - z / 2:.0f}" y="{py - z / 2:.0f}" width="{z:.0f}" height="{z * 1.35:.0f}" '
                     f'transform="rotate({ang + 180 + rng.uniform(-20, 20):.0f} {px:.0f} {py:.0f})" opacity="{max(.35, 1 - i * .09):.2f}"/>')
    lines = []
    for off, ln, d0 in [(-45, 120, 190), (0, 170, 170), (45, 110, 200)]:
        x1, y1 = hx + dx * d0 - dy * off, hy + dy * d0 + dx * off
        lines.append(f'<path d="M{x1:.0f} {y1:.0f} L{x1 + dx * ln:.0f} {y1 + dy * ln:.0f}"/>')
    return f"""
<defs>
 <linearGradient id="hdSky" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#2a63c8"/><stop offset=".5" stop-color="#5cc2ff"/><stop offset=".85" stop-color="#bfe8ff"/><stop offset="1" stop-color="#ffe9a8"/>
 </linearGradient>
 <radialGradient id="hdGlow" cx="{cx / dw}" cy="{cy / dh}" r=".45"><stop offset="0" stop-color="#fff3b0" stop-opacity=".9"/><stop offset="1" stop-color="#fff3b0" stop-opacity="0"/></radialGradient>
</defs>
<rect width="{dw}" height="{dh}" fill="url(#hdSky)"/>
<rect width="{dw}" height="{dh}" fill="url(#hdGlow)"/>
{rays}
{stars}
<g transform="translate({tx:.0f} {ty:.0f}) scale({s:.4f})">
{use("star", 1600, 130, 40, 40)}{use("star", 1700, 300, 30, 30)}
{use("moon", 1740, 40, 120, 120)}
{use("plane", 180, 230, 200, 94)}
{use("bird", 1560, 420, 80, 55)}
{use("bird", 380, 620, 70, 48, 'transform="scale(-1 1) translate(-830 0)"')}
</g>
{use("cloud", -160, dh - 180, 520, 291)}
{use("cloud", 600 * dw / W, dh - 120, 380, 213)}
{use("cloud", dw - 420, dh - 260, 560, 314)}
{use("cloud", 1060 * dw / W, dh - 150, 420, 235)}
<g transform="translate({tx:.0f} {ty:.0f}) scale({s:.4f})">
<g stroke="#fff" stroke-width="16" stroke-linecap="round" opacity=".85">{''.join(lines)}</g>
{''.join(drops)}
{shrimp(270, 560, 25, 0.9, 3, "heart")}
{shrimp(1680, 640, 40, 0.9, 3, "crown")}
{shrimp(hx, hy, ang, 0.85, 5, "normal")}
{use("fuel", 1700, 230, 110, 110)}
</g>
"""


def page(width, height):
    fonts = (ROOT / "fonts").as_uri()
    # keep the design height near 1080 for 16:9; wider canvases get extra width and a slightly smaller cast
    # taller (3:2) canvases keep the width and centre the cast vertically
    ratio = width / height
    if ratio < 1.7:
        dw, dh, s = W, round(W / ratio), 1.0
        tx, ty = 0, (dh - H) / 2
    else:
        dh = H if ratio < 2 else 960
        dw = round(dh * ratio)
        s = dh / H
        tx, ty = (dw - W * s) / 2, 0  # keep the reference layout centred so the iPhone crop holds the logo
    k = width / dw
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
@font-face {{ font-family: Dela; src: url('{fonts}/DelaGothicOne-Regular.ttf'); }}
@font-face {{ font-family: ZenBlack; src: url('{fonts}/ZenMaruGothic-Black.ttf'); }}
html, body {{ margin: 0; width: {width}px; height: {height}px; overflow: hidden; background: #5cc2ff; }}
.stage {{ position: absolute; left: 0; top: 0; width: {dw}px; height: {dh}px; transform: scale({k}); transform-origin: 0 0; }}
.stage > svg {{ position: absolute; inset: 0; }}
.copy {{ position: absolute; left: {tx + 960 * s:.0f}px; top: {ty + 465 * s:.0f}px; width: 1100px; text-align: center;
  transform: translate(-50%, -50%) scale({s * .66:.4f}); transform-origin: 50% 50%; }}
.tag {{ display: inline-block; transform: rotate(-4deg); padding: 10px 44px; border-radius: 20px; background: #ec5a3c; color: #fff;
  font-family: Dela; font-size: 64px; margin-right: 440px; border: 9px solid {INK}; box-shadow: 9px 9px 0 {INK}; }}
.logo {{ font-family: Dela; font-size: 200px; line-height: 1.1; white-space: nowrap; color: #f6c445; margin-top: 18px;
  -webkit-text-stroke: 22px {INK}; paint-order: stroke fill; text-shadow: 16px 16px 0 {INK}; letter-spacing: .01em; }}
.sub {{ display: inline-block; margin-top: 40px; padding: 14px 52px; border-radius: 999px; background: {INK}; color: #fff;
  font-family: ZenBlack; font-size: 54px; letter-spacing: .04em; }}
</style></head><body><div class="stage">
{art.symbols_block()}
<svg viewBox="0 0 {dw} {dh}" width="{dw}" height="{dh}">{scene(dw, dh, s, tx, ty)}</svg>
<div class="copy">
 <div class="tag">とべ！</div>
 <div class="logo">えびフライ</div>
 <div class="sub">エビフライを空まで飛ばせ！</div>
</div>
</div></body></html>"""


def main():
    OUT.mkdir(exist_ok=True)
    WORK.mkdir(parents=True, exist_ok=True)
    for w, h in SIZES:
        html = WORK / f"header-{w}x{h}.html"
        html.write_text(page(w, h))
        png = WORK / f"header-{w}x{h}.png"
        subprocess.run(["swift", str(ROOT / "tools" / "pageshot.swift"), str(html), str(png), str(w), str(h)], check=True)
        # App Store Connect only takes PNG here, and no alpha: resample to the exact size and round-trip through JPEG to flatten it
        jpg = WORK / f"header-{w}x{h}.jpg"
        subprocess.run(["sips", "-z", str(h), str(w), "-s", "format", "jpeg", "-s", "formatOptions", "best", str(png), "--out", str(jpg)],
                       check=True, capture_output=True)
        final = OUT / f"header-{w}x{h}.png"
        subprocess.run(["sips", "-s", "format", "png", str(jpg), "--out", str(final)], check=True, capture_output=True)
        print(final)


if __name__ == "__main__":
    main()
