#!/usr/bin/env python3
"""App Store screenshots: a big, easy-to-read headline over each app screen in a device frame.

Inputs are raw simulator captures in Design/build/raw/<device>_<screen>.png
(iPhone 17 Pro 1206x2622, iPad Pro 13" 2064x2752, iPhone Duo outer display 1398x2034).

    python3 Design/store_screenshots.py   ->  Design/store/screenshots/<device>/NN_<screen>.jpg
"""
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "build" / "raw"
ART = ROOT.parent / "ebiFly" / "Assets.xcassets"
OUT = ROOT / "store" / "screenshots"
WORK = ROOT / "build" / "screenshots"

INK = "#3a2418"

# device: canvas size, how wide the device frame is, where it starts, headline size
DEVICES = {
    "iphone": dict(w=1206, h=2622, frame=0.70, top=690, head=128, sub=54, radius=0.13, bezel=22),
    "ipad": dict(w=2064, h=2752, frame=0.67, top=780, head=168, sub=70, radius=0.06, bezel=30),
    "duo": dict(w=1398, h=2034, frame=0.68, top=560, head=120, sub=50, radius=0.08, bezel=22),
}

# screen, headline (\n = line break), sub line, background, headline colour, decorations
SLIDES = [
    ("title", "エビフライを\n空まで飛ばせ！", "ふって・かたむけて遊ぶアクション",
     "linear-gradient(180deg,#5cc2ff,#bfe8ff 60%,#ffe9a8)", "#f6c445", ["cloud-l", "cloud-r"]),
    ("make", "好きなエビを\nつくろう", "しっぽとからだの長さを選べる",
     "radial-gradient(circle at 50% 30%,#fff7dc,#ffe7a3)", "#ffffff", ["crumbs"]),
    ("batter", "パン粉を\nキャッチ！", "金のパン粉は3こぶん！",
     "linear-gradient(180deg,#ffd76a,#f6dc95)", "#ffffff", ["crumbs", "drops"]),
    ("fry", "きつね色に\n揚げよう", "メーターをタイミングよくストップ",
     "linear-gradient(180deg,#24323a,#3c4a52)", "#f6c445", ["bubbles"]),
    ("shake", "ふって\nソースをかけろ！", "ふるほど上昇スピードアップ",
     "linear-gradient(180deg,#ffb59e,#ffe0d2)", "#ffffff", ["sauce"]),
    ("fly", "障害物を\nよけて飛べ！", "ボトルを取って燃料ほきゅう",
     "linear-gradient(180deg,#1f4fb0,#4fb0f0 55%,#bfe8ff)", "#ffffff", ["stars", "plane"]),
    ("result", "宇宙まで\n飛ばせるか！？", "ランキングで飛距離をきそおう",
     "radial-gradient(circle at 50% 25%,#fff3b0,#f6c445 70%)", "#ffffff", ["stars-ink"]),
]


def asset(name):
    return (ART / f"{name}.imageset" / f"{name}.png").as_uri()


def decorations(kinds, d):
    w, h, s = d["w"], d["h"], d["w"] / 1206
    parts = []

    def img(name, x, y, width, rot=0, op=1):
        parts.append(f'<img src="{asset(name)}" style="position:absolute;left:{x}px;top:{y}px;width:{width}px;'
                     f'transform:rotate({rot}deg);opacity:{op}">')

    for k in kinds:
        if k == "cloud-l":
            img("cloud", -90 * s, h * 0.42, 420 * s)
        elif k == "cloud-r":
            img("cloud", w - 330 * s, h * 0.62, 440 * s)
        elif k == "crumbs":
            for x, y, sz, r in [(70, 520, 70, 20), (1060, 560, 60, -30), (40, 1500, 56, 40), (1100, 1300, 64, 10), (1080, 2100, 70, -15), (60, 2300, 60, 30)]:
                img("crumb", x * s - 30 * s, y * h / 2622, sz * s, r)
        elif k == "drops":
            for x, y, sz in [(1090, 900, 58), (50, 1100, 52), (1100, 1800, 56)]:
                img("water-drop", x * s - 30 * s, y * h / 2622, sz * s)
        elif k == "bubbles":
            for x, y, r in [(80, 760, 30), (1110, 900, 40), (60, 1700, 44), (1120, 2000, 30), (110, 2350, 24)]:
                parts.append(f'<div style="position:absolute;left:{x * s - r * s}px;top:{y * h / 2622}px;width:{r * 2 * s}px;height:{r * 2 * s}px;'
                             f'border-radius:50%;border:{6 * s}px solid rgba(255,255,255,.55)"></div>')
        elif k == "sauce":
            img("sauce-drop", 60 * s, h * 0.36, 70 * s)
            img("sauce-drop", w - 120 * s, h * 0.5, 64 * s)
            img("sauce-drop", 80 * s, h * 0.8, 56 * s)
        elif k == "stars":
            for x, y, sz in [(70, 80, 70), (1080, 120, 60), (200, 560, 40), (1000, 600, 46), (60, 1300, 44)]:
                img("star", x * s, y * h / 2622, sz * s)
        elif k == "plane":
            img("plane", w - 300 * s, h * 0.83, 330 * s)
        elif k == "stars-ink":
            for x, y, sz, r in [(60, 90, 90, -12), (1060, 110, 80, 14), (90, 1400, 60, 20), (1090, 1700, 70, -10)]:
                img("star", x * s, y * h / 2622, sz * s, r)
    return "".join(parts)


def page(device, slide):
    d = DEVICES[device]
    screen, head, sub, bg, fill, deco = slide
    w, h = d["w"], d["h"]
    raw = RAW / f"{device}_{screen}.png"
    rw, rh = map(int, subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(raw)], capture_output=True, text=True)
                 .stdout.split()[-3::2])
    fw = round(w * d["frame"])
    fh = round(fw * rh / rw)
    bezel = d["bezel"]
    radius = round(fw * d["radius"])
    stroke = round(d["head"] * 0.085)
    shadow = round(d["head"] * 0.07)
    lines = "<br>".join(head.split("\n"))
    fonts = (ROOT / "fonts").as_uri()
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
@font-face {{ font-family: Dela; src: url('{fonts}/DelaGothicOne-Regular.ttf'); }}
@font-face {{ font-family: ZenBlack; src: url('{fonts}/ZenMaruGothic-Black.ttf'); }}
html, body {{ margin: 0; width: {w}px; height: {h}px; overflow: hidden; }}
body {{ position: relative; background: {bg}; font-family: ZenBlack, sans-serif; }}
.head {{ position: absolute; left: 0; right: 0; top: {round(h * 0.045)}px; text-align: center;
  font-family: Dela; font-size: {d['head']}px; line-height: 1.18; color: {fill};
  -webkit-text-stroke: {stroke}px {INK}; paint-order: stroke fill; text-shadow: {shadow}px {shadow}px 0 {INK}; letter-spacing: .01em; }}
.sub {{ position: absolute; left: 50%; transform: translateX(-50%); top: {d['top'] - round(d['sub'] * 2.05)}px; white-space: nowrap;
  padding: {round(d['sub'] * .18)}px {round(d['sub'] * .7)}px; border-radius: 999px; background: {INK}; color: #fff;
  font-size: {d['sub']}px; line-height: 1.3; }}
.device {{ position: absolute; left: {(w - fw) // 2 - bezel}px; top: {d['top']}px; width: {fw}px; height: {fh}px;
  border: {bezel}px solid #1b1210; border-radius: {radius + bezel}px; background: #1b1210;
  box-shadow: 0 0 0 {round(bezel * .35)}px {INK}, {round(bezel * .9)}px {round(bezel * .9)}px 0 {round(bezel * .35)}px {INK}; overflow: hidden; }}
.device img {{ display: block; width: 100%; height: 100%; border-radius: {radius}px; }}
</style></head><body>
{decorations(deco, d)}
<div class="head">{lines}</div>
<div class="sub">{sub}</div>
<div class="device"><img src="{raw.as_uri()}"></div>
</body></html>"""


def main():
    WORK.mkdir(parents=True, exist_ok=True)
    for device, d in DEVICES.items():
        out_dir = OUT / device
        out_dir.mkdir(parents=True, exist_ok=True)
        for i, slide in enumerate(SLIDES, 1):
            name = f"{i:02d}_{slide[0]}"
            html = WORK / f"{device}_{name}.html"
            html.write_text(page(device, slide))
            png = WORK / f"{device}_{name}.png"
            subprocess.run(["swift", str(ROOT / "tools" / "pageshot.swift"), str(html), str(png), str(d["w"]), str(d["h"])], check=True)
            # App Store Connect wants opaque images at the exact size: resample (in case of a Retina snapshot) and save as JPEG
            subprocess.run(["sips", "-z", str(d["h"]), str(d["w"]), "-s", "format", "jpeg", "-s", "formatOptions", "92", str(png),
                            "--out", str(out_dir / f"{name}.jpg")], check=True, capture_output=True)


if __name__ == "__main__":
    main()
