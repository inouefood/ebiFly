#!/usr/bin/env python3
"""App Store screenshots: a big, easy-to-read headline over each app screen in a device frame.

Inputs are raw simulator captures in Design/build/raw/<locale>/<device>_<screen>.png
(iPhone 17 Pro 1206x2622, iPad Pro 13" 2064x2752, iPhone Duo unfolded 2007x2853).

    python3 Design/store_screenshots.py   ->  Design/store/screenshots/ja/<device>/NN_<screen>.jpg
    python3 Design/store_screenshots.py --locale en
        reads Design/build/raw/en/<device>_<screen>.png
        writes Design/store/screenshots/en/<device>/NN_<screen>.jpg
"""
import argparse
import struct
import subprocess
from html import escape
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "build" / "raw"
ART = ROOT.parent / "ebiFly" / "Assets.xcassets"
OUT = ROOT / "store" / "screenshots"
WORK = ROOT / "build" / "screenshots"
COPY = ROOT / "store_screenshot_copy.tsv"

INK = "#3a2418"

# device: canvas size, how wide the device frame is, where it starts, headline size
DEVICES = {
    "iphone": dict(w=1206, h=2622, frame=0.70, top=690, head=128, sub=54, radius=0.13, bezel=22),
    "ipad": dict(w=2064, h=2752, frame=0.67, top=780, head=168, sub=70, radius=0.06, bezel=30),
    "duo": dict(w=2007, h=2853, frame=0.66, top=800, head=172, sub=72, radius=0.07, bezel=30),
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

ENGLISH_COPY = {
    "title": ("Send Ebi Fry\nSky-High!", "Shake and tilt to play"),
    "make": ("Build Your\nOwn Shrimp", "Choose its tail and body length"),
    "batter": ("Catch the\nPanko!", "Golden panko counts triple!"),
    "fry": ("Fry It\nGolden!", "Stop the meter at just the right time"),
    "shake": ("Shake On\nthe Sauce!", "Shake more to climb faster"),
    "fly": ("Dodge and\nFly!", "Grab bottles to refuel"),
    "result": ("Can You\nReach Space?", "See who can fly the farthest"),
}

RTL = {"ar", "he", "ur"}

FIT_COPY = """<script>
document.fonts.ready.then(() => {
    const headline = document.querySelector(".head");
    const subtitle = document.querySelector(".sub");
    const width = document.body.clientWidth;
    function fit(element, measure, limit) {
        const size = parseFloat(getComputedStyle(element).fontSize);
        const fittedSize = size * Math.min(1, limit / measure());
        element.style.fontSize = Math.floor(fittedSize) + "px";
    }
    fit(headline, () => Math.max(...Array.from(headline.children, line => line.getBoundingClientRect().width)), width * 0.89);
    fit(subtitle, () => subtitle.firstElementChild.getBoundingClientRect().width, width * 0.87);
    window.storeCaptionReady = true;
});
</script>"""


def localized_copy():
    copies = {"en": ENGLISH_COPY}
    screens = [slide[0] for slide in SLIDES]
    for number, line in enumerate(COPY.read_text(encoding="utf-8").splitlines(), 1):
        if not line or line.startswith("#"):
            continue
        locale, *fields = line.split("\t")
        if locale in copies or len(fields) != 2 * len(screens) or any(not field.strip() for field in fields):
            raise ValueError(f"Invalid screenshot copy on line {number}")
        copies[locale] = {
            screen: (head.replace("^", "\n"), subtitle)
            for screen, head, subtitle in zip(screens, fields[::2], fields[1::2])
        }
    return copies


def localized_slide(slide, copy):
    screen, _, _, *design = slide
    return (screen, *copy[screen], *design) if copy else slide


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


def page(device, slide, raw_dir=RAW, locale="ja"):
    d = DEVICES[device]
    screen, head, sub, bg, fill, deco = slide
    w, h = d["w"], d["h"]
    raw = raw_dir / f"{device}_{screen}.png"
    with raw.open("rb") as capture:
        header = capture.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"Expected a PNG capture in {raw}")
    rw, rh = struct.unpack(">II", header[16:24])
    fw = round(w * d["frame"])
    fh = round(fw * rh / rw)
    bezel = d["bezel"]
    radius = round(fw * d["radius"])
    stroke = round(d["head"] * 0.085)
    shadow = round(d["head"] * 0.07)
    lines = "<br>".join(map(escape, head.split("\n")))
    subtitle = escape(sub)
    script = ""
    copy_style = ""
    if locale not in {"ja", "en"}:
        lines = "".join(f'<span>{escape(line)}</span>' for line in head.split("\n"))
        subtitle = f"<span>{subtitle}</span>"
        script = FIT_COPY
        copy_style = """
@font-face { font-family: Dela; font-weight: 900; src: url('FONT_PATH/DelaGothicOne-Regular.ttf'); }
.head { font-family: Dela, system-ui, sans-serif; font-weight: 900; line-height: 1.23;
  -webkit-text-stroke-width: .07em; text-shadow: .06em .06em 0 #3a2418; letter-spacing: normal; }
.head span { display: table; width: max-content; margin: 0 auto; white-space: nowrap; }
.sub { font-family: ZenBlack, system-ui, sans-serif; font-weight: 800; }
.sub span { display: inline-block; }
"""
    fonts = (ROOT / "fonts").as_uri()
    direction = "rtl" if locale in RTL else "ltr"
    return f"""<!doctype html><html lang="{escape(locale)}" dir="{direction}"><head><meta charset="utf-8"><style>
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
{copy_style.replace("FONT_PATH", fonts)}
</style></head><body>
{decorations(deco, d)}
<div class="head">{lines}</div>
<div class="sub">{subtitle}</div>
<div class="device"><img src="{raw.as_uri()}"></div>
{script}
</body></html>"""


def main():
    copies = localized_copy()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--locale", choices=["ja", *copies], default="ja")
    parser.add_argument("--device", choices=DEVICES, action="append", help="Render only the selected device(s)")
    args = parser.parse_args()
    locale = args.locale
    locale_path = Path(locale)
    work_dir = WORK / locale_path
    raw_dir = RAW / locale_path
    work_dir.mkdir(parents=True, exist_ok=True)
    for device in args.device or DEVICES:
        d = DEVICES[device]
        out_dir = OUT / locale_path / device
        out_dir.mkdir(parents=True, exist_ok=True)
        for i, slide in enumerate(SLIDES, 1):
            name = f"{i:02d}_{slide[0]}"
            slide = localized_slide(slide, copies.get(locale))
            html = work_dir / f"{device}_{name}.html"
            html.write_text(page(device, slide, raw_dir, locale), encoding="utf-8")
            png = work_dir / f"{device}_{name}.png"
            subprocess.run(["swift", str(ROOT / "tools" / "pageshot.swift"), str(html), str(png), str(d["w"]), str(d["h"])], check=True)
            # App Store Connect wants opaque images at the exact size: resample (in case of a Retina snapshot) and save as JPEG
            subprocess.run(["sips", "-z", str(d["h"]), str(d["w"]), "-s", "format", "jpeg", "-s", "formatOptions", "92", str(png),
                            "--out", str(out_dir / f"{name}.jpg")], check=True, capture_output=True)


if __name__ == "__main__":
    main()
