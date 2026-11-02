#!/usr/bin/env python3
"""Game Center leaderboard artwork (1024 x 1024, no alpha) for the "ebifly.distance.v2" leaderboard.

Three fried shrimp on a winners' podium under a starry sky. Built from the same symbols as the app art.

    python3 Design/leaderboard.py   ->  Design/store/leaderboard-1024.png
"""
import math
import subprocess
from pathlib import Path

import art

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "store"
BUILD = ROOT / "build" / "leaderboard"
INK = art.INK

rays = "".join(
    f'<path d="M512 470 L{512 + 1100 * math.cos(math.radians(a)):.0f} {470 + 1100 * math.sin(math.radians(a)):.0f} '
    f'L{512 + 1100 * math.cos(math.radians(a + 10)):.0f} {470 + 1100 * math.sin(math.radians(a + 10)):.0f}Z" fill="#fff6c8" opacity=".16"/>'
    for a in range(0, 360, 20)
)
stars = "".join(
    f'<use href="#star" x="{x}" y="{y}" width="{s}" height="{s}"/>'
    for x, y, s in [(110, 120, 46), (230, 60, 30), (820, 90, 50), (900, 230, 30), (70, 300, 28), (760, 300, 26), (300, 230, 22)]
)
sparkles = "".join(
    f'<use href="#star" x="{x}" y="{y}" width="{s}" height="{s}"/>'
    for x, y, s in [(372, 150, 54), (606, 120, 64), (650, 260, 36), (350, 300, 34)]
)


def shrimp(x, y, scale, n, tail):
    # rotated 180°: head up, tail fan at the bottom (standing on the podium)
    return (f'<g transform="translate({x} {y}) rotate(180) scale({scale})" style="--crust:#efa53a;--crumb:#c06f1c">'
            f'{art.shrimp_group(n, tail)}</g>')


def block(x, y, w, h, fill, label, size):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="22" fill="{fill}" stroke="{INK}" stroke-width="12"/>'
            f'<rect x="{x + 20}" y="{y + 18}" width="{w - 40}" height="16" rx="8" fill="#fff" opacity=".35"/>'
            f'<text x="{x + w / 2}" y="{y + h / 2 + size * 0.36}" text-anchor="middle" font-family="\'Dela Gothic One\',\'Hiragino Sans\',sans-serif" '
            f'font-weight="900" font-size="{size}" fill="#fff" stroke="{INK}" stroke-width="10" paint-order="stroke">{label}</text>')


art.S["leaderboard"] = ("0 0 1024 1024", f"""
<defs>
 <linearGradient id="lbSky" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#1f4fb0"/><stop offset=".55" stop-color="#4fb0f0"/><stop offset="1" stop-color="#bfe8ff"/>
 </linearGradient>
</defs>
<rect width="1024" height="1024" fill="url(#lbSky)"/>
{rays}
{stars}
<use href="#cloud" x="-120" y="760" width="460" height="258"/>
<use href="#cloud" x="680" y="790" width="460" height="258"/>
{block(112, 700, 260, 240, "#d9dde6", "2", 120)}
{block(652, 750, 260, 190, "#e0965a", "3", 110)}
{block(362, 600, 300, 340, "#f6c445", "1", 150)}
{shrimp(242, 700 - 104 * 1.0, 1.0, 4, "heart")}
{shrimp(782, 750 - 104 * 0.95, 0.95, 3, "normal")}
{shrimp(512, 600 - 104 * 1.2, 1.2, 5, "crown")}
{sparkles}
<rect x="0" y="940" width="1024" height="84" fill="#e8c79a"/>
<rect x="0" y="936" width="1024" height="10" fill="{INK}"/>
""")


def main():
    OUT.mkdir(exist_ok=True)
    BUILD.mkdir(parents=True, exist_ok=True)
    svg = BUILD / "leaderboard.svg"
    png = BUILD / "leaderboard.png"
    svg.write_text(art.standalone("leaderboard", 1024, 1024))
    (BUILD / "jobs.txt").write_text(f"{svg}\t{png}\t1024\t1024")
    subprocess.run(["swift", str(ROOT / "tools" / "render.swift"), str(BUILD / "jobs.txt")], check=True)
    # App Store Connect wants a flattened image: round-trip through JPEG to drop the alpha channel
    jpg = BUILD / "leaderboard.jpg"
    subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "best", str(png), "--out", str(jpg)], check=True, capture_output=True)
    final = OUT / "leaderboard-1024.png"
    subprocess.run(["sips", "-s", "format", "png", str(jpg), "--out", str(final)], check=True, capture_output=True)
    print(final)


if __name__ == "__main__":
    main()
