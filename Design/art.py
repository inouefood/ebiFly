#!/usr/bin/env python3
"""ebiFly 2.0 illustration generator.

- Builds every illustration as an SVG <symbol> (single source of truth)
- Writes standalone SVGs to Design/illustrations/ (for PNG export to Assets.xcassets)
- Injects the symbols + old images into preview.template.html -> ebiFly-preview.html
"""
import base64
import math
import pathlib
import random
import re

ROOT = pathlib.Path(__file__).resolve().parent
INK = "#3a2418"
SW = 5  # standard outline width


def bumpy(r=40.0, a1=1.7, k1=13, a2=1.2, k2=5, pts=96):
    out = []
    for i in range(pts):
        t = 2 * math.pi * i / pts
        rr = r + a1 * math.sin(k1 * t) + a2 * math.sin(k2 * t + 1)
        out.append(f"{rr * math.cos(t):.1f},{rr * math.sin(t):.1f}")
    return "M" + " L".join(out) + "Z"


def blob(cx, cy, r, rng, n=6):
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n + rng.uniform(-0.3, 0.3)
        rr = r * rng.uniform(0.6, 1.0)
        pts.append(f"{cx + rr * math.cos(t):.1f},{cy + rr * math.sin(t):.1f}")
    return " ".join(pts)


rng = random.Random(7)
SEG = bumpy()

# ---------------------------------------------------------------- symbols
S = {}

crumbs = []
for _ in range(11):
    a = rng.uniform(0, 2 * math.pi)
    d = rng.uniform(4, 28)
    crumbs.append(
        f'<polygon points="{blob(d * math.cos(a), d * math.sin(a), rng.uniform(3, 5.5), rng)}" '
        f'fill="var(--crumb,#c06f1c)"/>'
    )
S["seg"] = ("-50 -50 100 100", f"""
<path d="{SEG}" fill="var(--crust,#efa53a)"/>
<g clip-path="url(#segclip)"><circle cx="12" cy="16" r="36" fill="#5a2a0a" opacity=".13"/></g>
{''.join(crumbs)}
<ellipse cx="-15" cy="-17" rx="12" ry="6.5" transform="rotate(-35 -15 -17)" fill="#fff" opacity=".45"/>
<path d="{SEG}" fill="none" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
""")

lobe = 'rx="14" ry="31" fill="#ec5a3c" stroke="{0}" stroke-width="{1}"'.format(INK, SW)
S["tail-normal"] = ("-50 -50 100 100", f"""
<ellipse cx="-17" cy="-6" {lobe} transform="rotate(-30 -17 -6)"/>
<ellipse cx="17" cy="-6" {lobe} transform="rotate(30 17 -6)"/>
<ellipse cx="0" cy="-13" {lobe}/>
<path d="M0 -36 L0 8 M-26 -26 L-10 10 M26 -26 L10 10" stroke="#b8361f" stroke-width="3" stroke-linecap="round" opacity=".7"/>
<ellipse cx="0" cy="30" rx="17" ry="11" fill="#d9472e" stroke="{INK}" stroke-width="{SW}"/>
""")

S["tail-heart"] = ("-50 -50 100 100", f"""
<path d="M0 38 C-40 12 -47 -20 -25 -31 C-13 -37 -3 -29 0 -20 C3 -29 13 -37 25 -31 C47 -20 40 12 0 38Z"
 fill="#ff7ba6" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<ellipse cx="-17" cy="-17" rx="7" ry="4.5" transform="rotate(-30 -17 -17)" fill="#fff" opacity=".55"/>
<path d="M0 -12 L0 26" stroke="#e0557f" stroke-width="3" stroke-linecap="round"/>
""")

S["tail-crown"] = ("-50 -50 100 100", f"""
<path d="M-34 32 L-39 -22 L-17 0 L0 -38 L17 0 L39 -22 L34 32Z" fill="#f5b82e" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<rect x="-34" y="16" width="68" height="16" fill="#e39a16" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<circle cx="0" cy="24" r="5" fill="#ec5a3c" stroke="{INK}" stroke-width="2.5"/>
<circle cx="-20" cy="24" r="4" fill="#4bb3e6" stroke="{INK}" stroke-width="2.5"/>
<circle cx="20" cy="24" r="4" fill="#4bb3e6" stroke="{INK}" stroke-width="2.5"/>
<circle cx="0" cy="-38" r="5" fill="#fff4c2" stroke="{INK}" stroke-width="2.5"/>
<circle cx="-39" cy="-22" r="4.5" fill="#fff4c2" stroke="{INK}" stroke-width="2.5"/>
<circle cx="39" cy="-22" r="4.5" fill="#fff4c2" stroke="{INK}" stroke-width="2.5"/>
""")

S["crumb"] = ("-12 -12 24 24", f"""
<polygon points="{blob(0, 0, 10, random.Random(3), 7)}" fill="#f0c25a" stroke="{INK}" stroke-width="2.4" stroke-linejoin="round"/>
<circle cx="-2" cy="-3" r="2" fill="#fff" opacity=".6"/>
""")

S["oil-drop"] = ("-10 -15 20 27", f"""
<path d="M0 -13 C6 -4 9 1 9 5 A9 9 0 0 1 -9 5 C-9 1 -6 -4 0 -13Z" fill="#f6c445" stroke="{INK}" stroke-width="2.4"/>
<circle cx="-3" cy="4" r="2" fill="#fff" opacity=".7"/>
""")

S["sauce-drop"] = ("-10 -15 20 27", f"""
<path d="M0 -13 C6 -4 9 1 9 5 A9 9 0 0 1 -9 5 C-9 1 -6 -4 0 -13Z" fill="#5a2a14" stroke="{INK}" stroke-width="2.4"/>
<circle cx="-3" cy="4" r="2" fill="#fff" opacity=".45"/>
""")

S["sauce"] = ("0 0 100 220", f"""
<path d="M38 24 L38 42 Q14 52 14 80 L14 196 Q14 212 30 212 L70 212 Q86 212 86 196 L86 80 Q86 52 62 42 L62 24Z"
 fill="#4a2614" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<rect x="34" y="4" width="32" height="24" rx="6" fill="#ec5a3c" stroke="{INK}" stroke-width="{SW}"/>
<rect x="22" y="100" width="56" height="70" rx="9" fill="#fff3d6" stroke="{INK}" stroke-width="3"/>
<text x="50" y="132" text-anchor="middle" font-family="'Dela Gothic One','Hiragino Sans',sans-serif" font-size="15" fill="#4a2614">ソース</text>
<text x="50" y="152" text-anchor="middle" font-family="'Zen Maru Gothic','Hiragino Maru Gothic ProN',sans-serif" font-weight="700" font-size="9" fill="#a0522d">EBI FRY</text>
<rect x="22" y="66" width="7" height="120" rx="3.5" fill="#fff" opacity=".22"/>
""")

cloud_c = [(50, 72, 30), (88, 50, 38), (132, 58, 33), (162, 78, 24), (28, 86, 18)]
S["cloud"] = ("0 0 200 112", "".join(
    f'<circle cx="{x}" cy="{y}" r="{r}" fill="#fff" stroke="{INK}" stroke-width="{SW * 2}"/>' for x, y, r in cloud_c
) + f'<rect x="26" y="70" width="140" height="34" rx="17" fill="#fff" stroke="{INK}" stroke-width="{SW * 2}"/>' + "".join(
    f'<circle cx="{x}" cy="{y}" r="{r}" fill="#fff"/>' for x, y, r in cloud_c
) + '<rect x="26" y="70" width="140" height="34" rx="17" fill="#fff"/>'
  '<path d="M60 94 L150 94" stroke="#cfe6f5" stroke-width="6" stroke-linecap="round"/>')

S["bird"] = ("0 0 64 44", f"""
<ellipse cx="30" cy="26" rx="20" ry="13" fill="#fff" stroke="{INK}" stroke-width="3.5"/>
<path d="M22 22 Q30 2 42 18" fill="#dff1ff" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>
<path d="M49 24 L60 27 L49 31Z" fill="#f5b82e" stroke="{INK}" stroke-width="2.5" stroke-linejoin="round"/>
<circle cx="42" cy="23" r="2.4" fill="{INK}"/>
""")

S["plane"] = ("0 0 170 80", f"""
<path d="M70 40 L40 74 L58 74 L100 44Z" fill="#dfe8f2" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>
<path d="M18 30 L8 8 L24 8 L42 28Z" fill="#ec5a3c" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>
<rect x="10" y="26" width="150" height="26" rx="13" fill="#fff" stroke="{INK}" stroke-width="3.5"/>
<path d="M14 44 L156 44" stroke="#ec5a3c" stroke-width="4"/>
{''.join(f'<circle cx="{x}" cy="36" r="3.2" fill="#4bb3e6"/>' for x in range(60, 140, 14))}
<path d="M142 30 Q156 32 158 39 L142 39Z" fill="#4bb3e6"/>
""")

S["moon"] = ("0 0 120 120", f"""
<circle cx="60" cy="60" r="50" fill="#fff2b0" stroke="{INK}" stroke-width="{SW}"/>
<circle cx="38" cy="38" r="9" fill="#f0dd8a"/><circle cx="84" cy="80" r="12" fill="#f0dd8a"/><circle cx="80" cy="34" r="5" fill="#f0dd8a"/>
<path d="M40 62 Q46 67 52 62 M68 62 Q74 67 80 62" fill="none" stroke="{INK}" stroke-width="3.2" stroke-linecap="round"/>
<path d="M55 78 Q60 82 65 78" fill="none" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>
""")


def star_path(r1=17, r2=7.5):
    pts = []
    for i in range(10):
        r = r1 if i % 2 == 0 else r2
        t = -math.pi / 2 + i * math.pi / 5
        pts.append(f"{r * math.cos(t):.1f},{r * math.sin(t):.1f}")
    return " ".join(pts)


S["star"] = ("-20 -20 40 40",
             f'<polygon points="{star_path()}" fill="#ffd84d" stroke="{INK}" stroke-width="2.6" stroke-linejoin="round"/>')

S["meteor"] = ("0 0 80 80", f"""
<ellipse cx="56" cy="18" rx="12" ry="26" transform="rotate(40 56 18)" fill="#ff9a2e" opacity=".55"/>
<polygon points="{blob(40, 44, 28, random.Random(11), 9)}" fill="#8d8396" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<circle cx="32" cy="40" r="7" fill="#6f6578"/><circle cx="50" cy="54" r="5" fill="#6f6578"/><circle cx="46" cy="32" r="3.5" fill="#6f6578"/>
<path d="M22 34 Q28 24 38 22" stroke="#fff" opacity=".45" stroke-width="4" fill="none" stroke-linecap="round"/>
""")

S["pot-back"] = ("-20 -10 340 180", f"""
<ellipse cx="150" cy="30" rx="130" ry="22" fill="#e9a92c" stroke="{INK}" stroke-width="{SW}"/>
<ellipse cx="150" cy="27" rx="112" ry="14" fill="#f8cf55"/>
<ellipse cx="110" cy="24" rx="40" ry="5" fill="#fff3b0" opacity=".7"/>
""")
S["pot-front"] = ("-20 -10 340 180", f"""
<rect x="-14" y="46" width="44" height="18" rx="9" fill="#3a3f4b" stroke="{INK}" stroke-width="{SW}"/>
<rect x="270" y="46" width="44" height="18" rx="9" fill="#3a3f4b" stroke="{INK}" stroke-width="{SW}"/>
<path d="M20 30 A130 22 0 0 0 280 30 L266 142 Q264 156 250 156 L50 156 Q36 156 34 142Z" fill="#59606f" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M52 66 L60 140" stroke="#fff" stroke-width="10" stroke-linecap="round" opacity=".16"/>
<path d="M20 30 A130 22 0 0 0 280 30" fill="none" stroke="#8a91a1" stroke-width="4" opacity=".7"/>
""")


# ---------------------------------------------------------------- shrimp composite (mirrors JS shrimpSVG)
def shrimp_group(n=4, tail="normal", face_rot=0):
    sp = 56
    parts = [f'<use href="#tail-{tail}" x="-53" y="-108" width="106" height="106"/>']
    for i in range(n):
        s = 0.82 + 0.26 * (i / (n - 1) if n > 1 else 1)
        w = 100 * s
        parts.append(f'<use href="#seg" x="{-w / 2:.1f}" y="{i * sp - w / 2:.1f}" width="{w:.1f}" height="{w:.1f}"/>')
    return "".join(parts)


rays = "".join(
    f'<path d="M512 560 L{512 + 1200 * math.cos(math.radians(a)):.0f} {560 + 1200 * math.sin(math.radians(a)):.0f} '
    f'L{512 + 1200 * math.cos(math.radians(a + 11)):.0f} {560 + 1200 * math.sin(math.radians(a + 11)):.0f}Z" fill="#fff" opacity=".2"/>'
    for a in range(0, 360, 22)
)
drops = "".join(
    f'<use href="#oil-drop" x="{x}" y="{y}" width="{s}" height="{s * 1.35:.0f}" transform="rotate({r} {x + s / 2} {y + s / 2})"/>'
    for x, y, s, r in [(120, 800, 70, -30), (210, 870, 52, -10), (60, 700, 44, -45), (300, 900, 40, 5), (40, 880, 60, -20)]
)
S["icon"] = ("0 0 1024 1024", f"""
<rect width="1024" height="1024" fill="url(#icoBg)"/>
{rays}
<use href="#cloud" x="600" y="760" width="420" height="235"/>
<use href="#cloud" x="-90" y="880" width="380" height="213"/>
<g stroke="#fff" stroke-width="26" stroke-linecap="round" opacity=".85">
 <path d="M250 640 L120 770"/><path d="M330 720 L230 820"/><path d="M190 560 L90 660"/>
</g>
{drops}
<g transform="translate(560 470) rotate(-135) scale(1.75) translate(0 -80)" style="--crust:#efa53a;--crumb:#c06f1c">
 {shrimp_group(4, "normal", 135)}
</g>
""")

S["bento"] = ("0 0 300 210", f"""
<rect x="6" y="6" width="288" height="198" rx="24" fill="#2b1b14" stroke="{INK}" stroke-width="{SW}"/>
<rect x="20" y="20" width="260" height="170" rx="14" fill="#c8372d"/>
<rect x="28" y="28" width="112" height="154" rx="10" fill="#fffaf0"/>
<circle cx="84" cy="104" r="16" fill="#d7263d" stroke="{INK}" stroke-width="3.5"/>
<circle cx="79" cy="98" r="4" fill="#fff" opacity=".6"/>
<path d="M148 34 Q170 24 186 40 Q206 28 224 44 Q246 34 268 50 L268 180 L148 180Z" fill="#7cc95a" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>
<rect x="150" y="128" width="58" height="46" rx="8" fill="#ffd84d" stroke="{INK}" stroke-width="3.5"/>
<path d="M156 146 L202 146 M156 160 L202 160" stroke="#e8b52a" stroke-width="3"/>
""")

DEFS = f"""
<clipPath id="segclip"><path d="{SEG}"/></clipPath>
<radialGradient id="icoBg" cx="50%" cy="55%" r="70%"><stop offset="0" stop-color="#ffe27a"/><stop offset="1" stop-color="#ff9a2e"/></radialGradient>
"""


def symbols_block():
    body = "".join(f'<symbol id="{k}" viewBox="{vb}" overflow="visible">{v.strip()}</symbol>' for k, (vb, v) in S.items())
    return f'<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>{DEFS}{body}</defs></svg>'


def standalone(key, w, h, root_style=""):
    vb = S[key][0]
    raw = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" width="{w}" height="{h}"{root_style}><defs>{DEFS}' + \
          "".join(f'<symbol id="{k}" viewBox="{v[0]}" overflow="visible">{v[1].strip()}</symbol>' for k, v in S.items()) + \
          f'</defs><use href="#{key}" x="{vb.split()[0]}" y="{vb.split()[1]}" width="{vb.split()[2]}" height="{vb.split()[3]}"/></svg>'
    # resolve CSS custom properties to their fallbacks so rasterizers without var() support work
    return re.sub(r"var\(--[\w-]+,\s*(#[0-9a-fA-F]+)\)", r"\1", raw)


def b64(path, mime):
    return f"data:{mime};base64," + base64.b64encode(pathlib.Path(path).read_bytes()).decode()


if __name__ == "__main__":
    import sys

    out = ROOT / "illustrations"
    out.mkdir(exist_ok=True)
    sizes = {"seg": (300, 300), "meteor": (240, 240), "tail-normal": (300, 300), "tail-heart": (300, 300),
             "tail-crown": (300, 300), "crumb": (96, 96), "oil-drop": (80, 108), "sauce-drop": (80, 108),
             "sauce": (300, 660), "cloud": (600, 336), "bird": (192, 132), "plane": (510, 240), "moon": (360, 360),
             "star": (120, 120), "pot-back": (680, 360), "pot-front": (680, 360), "icon": (1024, 1024),
             "bento": (600, 420)}
    for k, (w, h) in sizes.items():
        (out / f"{k}.svg").write_text(standalone(k, w, h))

    old = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else None
    tpl = (ROOT / "preview.template.html").read_text()
    html = tpl.replace("<!--SYMBOLS-->", symbols_block())
    if old:
        for name, file, mime in [("ICON", "icon.jpg", "image/jpeg"), ("EBI", "ebi.png", "image/png"),
                                 ("CLEAR", "clear.png", "image/png"), ("FALL", "fall.png", "image/png"),
                                 ("TALE", "tale.png", "image/png")]:
            html = html.replace(f"{{{{OLD_{name}}}}}", b64(old / file, mime))
    (ROOT / "ebiFly-preview.html").write_text(html)
    print("ok", len(html))
