#!/usr/bin/env python3
"""Export the SVG illustrations (art.py) into ebiFly/Assets.xcassets as PNG imagesets.

usage: python3 Design/export_assets.py
"""
import json
import pathlib
import re
import shutil
import subprocess

import art

ROOT = pathlib.Path(__file__).resolve().parent
XCASSETS = ROOT.parent / "ebiFly" / "Assets.xcassets"
BUILD = ROOT / "build"


def hex2rgb(h):
    return [int(h[i:i + 2], 16) for i in (1, 3, 5)]


def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    A, B = hex2rgb(a), hex2rgb(b)
    return "#" + "".join(f"{round(x + (y - x) * t):02x}" for x, y in zip(A, B))


FRY_STOPS = [(0, "#f6e7bd", "#e2c98a"), (0.5, "#efa53a", "#c06f1c"), (0.85, "#6d3a1a", "#3d1f0d"), (1, "#3a1d0c", "#1e0e05")]


def fry_colors(v):
    for i in range(1, len(FRY_STOPS)):
        if v <= FRY_STOPS[i][0] or i == len(FRY_STOPS) - 1:
            a, b = FRY_STOPS[i - 1], FRY_STOPS[i]
            t = (v - a[0]) / (b[0] - a[0])
            return mix(a[1], b[1], t), mix(a[2], b[2], t)


def batter_colors(t):
    return mix("#f7a48d", "#f6e7bd", t), mix("#e2836b", "#e2c98a", t)


def svg_for(key, w, h, crust=None, crumb=None):
    if crust is None:
        return art.standalone(key, w, h)
    else:
        # rebuild with explicit colours instead of the var() fallbacks
        vb = art.S[key][0]
        body = art.S[key][1].replace("var(--crust,#efa53a)", crust).replace("var(--crumb,#c06f1c)", crumb)
        defs = art.DEFS + "".join(
            f'<symbol id="{k}" viewBox="{v[0]}" overflow="visible">{v[1].strip()}</symbol>' for k, v in art.S.items() if k != key)
        x, y, vw, vh = vb.split()
        s = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" width="{w}" height="{h}"><defs>{defs}'
             f'<symbol id="{key}" viewBox="{vb}" overflow="visible">{body.strip()}</symbol></defs>'
             f'<use href="#{key}" x="{x}" y="{y}" width="{vw}" height="{vh}"/></svg>')
        s = re.sub(r"var\(--[\w-]+,\s*(#[0-9a-fA-F]+)\)", r"\1", s)
    return s


JOBS = {  # asset name -> (symbol, px w, px h, colours)
    "tail-normal": ("tail-normal", 318, 318, None),
    "tail-heart": ("tail-heart", 318, 318, None),
    "tail-crown": ("tail-crown", 318, 318, None),
    "crumb": ("crumb", 96, 96, None),
    "oil-drop": ("oil-drop", 80, 108, None),
    "sauce-drop": ("sauce-drop", 80, 108, None),
    "sauce": ("sauce", 300, 660, None),
    "cloud": ("cloud", 600, 336, None),
    "bird": ("bird", 192, 132, None),
    "plane": ("plane", 510, 240, None),
    "moon": ("moon", 360, 360, None),
    "star": ("star", 120, 120, None),
    "meteor": ("meteor", 240, 240, None),
    "pot-back": ("pot-back", 680, 360, None),
    "pot-front": ("pot-front", 680, 360, None),
    "bento": ("bento", 600, 420, None),
    "icon": ("icon", 1024, 1024, None),
}
for i in range(6):
    JOBS[f"seg-b{i}"] = ("seg", 300, 300, batter_colors(i / 5))
for i in range(11):
    JOBS[f"seg-f{i:02d}"] = ("seg", 300, 300, fry_colors(i / 10))


def main():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / "svg").mkdir(parents=True)
    (BUILD / "png").mkdir()
    lines = []
    for name, (key, w, h, colors) in JOBS.items():
        svg = svg_for(key, w, h, *(colors or (None, None)))
        sp = BUILD / "svg" / f"{name}.svg"
        sp.write_text(svg)
        lines.append(f"{sp}\t{BUILD / 'png' / (name + '.png')}\t{w}\t{h}")
    (BUILD / "jobs.txt").write_text("\n".join(lines))
    subprocess.run(["swift", str(ROOT / "tools" / "render.swift"), str(BUILD / "jobs.txt")], check=True)

    # replace every imageset in the catalog
    for p in XCASSETS.glob("*.imageset"):
        shutil.rmtree(p)
    for name in JOBS:
        if name == "icon":
            continue
        d = XCASSETS / f"{name}.imageset"
        d.mkdir()
        shutil.copy(BUILD / "png" / f"{name}.png", d / f"{name}.png")
        (d / "Contents.json").write_text(json.dumps({
            "images": [{"filename": f"{name}.png", "idiom": "universal"}],
            "info": {"author": "xcode", "version": 1}}, indent=2))

    icon_dir = XCASSETS / "AppIcon.appiconset"
    if icon_dir.exists():
        shutil.rmtree(icon_dir)
    icon_dir.mkdir()
    # App Store icons must not have an alpha channel: round-trip through JPEG
    tmp = BUILD / "icon.jpg"
    subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "best", str(BUILD / "png" / "icon.png"), "--out", str(tmp)], check=True, capture_output=True)
    subprocess.run(["sips", "-s", "format", "png", str(tmp), "--out", str(icon_dir / "icon-1024.png")], check=True, capture_output=True)
    (icon_dir / "Contents.json").write_text(json.dumps({
        "images": [{"filename": "icon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
        "info": {"author": "xcode", "version": 1}}, indent=2))
    print("exported", len(JOBS), "assets")


if __name__ == "__main__":
    main()
