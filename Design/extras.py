"""Batter coats and sauces exchanged for points on the make screen (cosmetic only).

- coat-<key>:   overlay drawn on top of a body ball (same "-50 -50 100 100" box as `seg`), so the
                fry colour underneath still shows through. Ends with the ball outline so it stays crisp.
- bottle-<key>: the bottle shaken in the sauce step ("0 0 100 220", spout at the top like `sauce`).
- drop-<key>:   what falls out of it ("-10 -15 20 27" like `sauce-drop`).
- fuel-<key>:   the refuel pickup while flying, with this bottle in it (like `fuel`).

The default coat (plain) and sauce (sauce) use the existing seg / sauce / sauce-drop / fuel art.
"""
import math
import random

INK = "#3a2418"
SW = 5

COAT_KEYS = ["sesame", "nori", "cheese", "curry", "matcha", "cornflake", "sprinkle", "charcoal", "gold"]
SAUCE_KEYS = ["mayo", "ketchup", "tartar", "soy", "salt", "lemon", "curry", "choco", "honey"]


def _scatter(rng, n, rmax=30, rmin=0):
    out = []
    for _ in range(n):
        a = rng.uniform(0, 2 * math.pi)
        d = math.sqrt(rng.uniform((rmin / rmax) ** 2, 1)) * rmax
        out.append((d * math.cos(a), d * math.sin(a), rng.uniform(0, 180)))
    return out


def _poly(cx, cy, r, rng, n=6):
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n + rng.uniform(-0.3, 0.3)
        rr = r * rng.uniform(0.6, 1.0)
        pts.append(f"{cx + rr * math.cos(t):.1f},{cy + rr * math.sin(t):.1f}")
    return " ".join(pts)


def _coats(seg):
    outline = f'<path d="{seg}" fill="none" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>'
    shine = '<ellipse cx="-15" cy="-17" rx="12" ry="6.5" transform="rotate(-35 -15 -17)" fill="#fff" opacity=".35"/>'

    def tint(color, op):
        return f'<path d="{seg}" fill="{color}" opacity="{op}"/>'

    def clip(body):
        return f'<g clip-path="url(#segclip)">{body}</g>'

    C = {}
    rng = random.Random(21)
    C["sesame"] = clip("".join(
        f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="3.4" ry="1.8" transform="rotate({r:.0f} {x:.1f} {y:.1f})" '
        f'fill="{"#2a1a10" if i % 4 == 0 else "#fff4d6"}" stroke="#8a5a2a" stroke-width=".6"/>'
        for i, (x, y, r) in enumerate(_scatter(rng, 22, 32)))) + outline

    rng = random.Random(22)
    C["nori"] = clip("".join(
        f'<polygon points="{_poly(x, y, rng.uniform(2, 3.6), rng, 5)}" fill="{rng.choice(["#2e7d32", "#3f8f2a", "#1f5e26"])}"/>'
        for x, y, _ in _scatter(rng, 26, 33))) + outline

    rng = random.Random(23)
    C["cheese"] = clip(
        "".join(f'<path d="M{x - 9:.1f} {y:.1f} Q{x:.1f} {y - 9:.1f} {x + 9:.1f} {y:.1f} Q{x + 7:.1f} {y + 10:.1f} {x + 3:.1f} {y + 5:.1f} '
                f'Q{x:.1f} {y + 13:.1f} {x - 3:.1f} {y + 5:.1f} Q{x - 7:.1f} {y + 8:.1f} {x - 9:.1f} {y:.1f}Z" fill="#ffd23f" stroke="#e8a317" stroke-width="1.4"/>'
                for x, y in [(-14, -22), (12, -16), (-20, 6), (8, 10), (24, 0), (-4, 24)])
        + "".join(f'<circle cx="{x}" cy="{y}" r="1.6" fill="#fff" opacity=".7"/>' for x, y in [(-17, -24), (9, -18), (-22, 4), (5, 8)])
    ) + outline

    rng = random.Random(24)
    C["curry"] = tint("#e8a812", 0.58) + clip("".join(
        f'<polygon points="{_poly(x, y, rng.uniform(1.6, 3), rng, 5)}" fill="{rng.choice(["#a0461c", "#c9661c", "#7a3a14"])}"/>'
        for x, y, _ in _scatter(rng, 20, 32))) + shine + outline

    rng = random.Random(25)
    C["matcha"] = tint("#7cb342", 0.5) + clip("".join(
        f'<polygon points="{_poly(x, y, rng.uniform(2, 3.4), rng, 6)}" fill="{rng.choice(["#4e7d22", "#5f8f2a"])}"/>'
        for x, y, _ in _scatter(rng, 14, 32))) + shine + outline

    rng = random.Random(26)
    C["cornflake"] = clip("".join(
        f'<polygon points="{_poly(x, y, rng.uniform(6, 9), rng, 7)}" fill="{rng.choice(["#f3c25a", "#eeb043", "#f7d27a"])}" '
        f'stroke="#b8761c" stroke-width="1.6" stroke-linejoin="round"/>'
        for x, y, _ in _scatter(rng, 10, 28))) + outline

    rng = random.Random(27)
    colors = ["#ec5a3c", "#4bb3e6", "#6cc04a", "#ffd84d", "#ff7ba6", "#9a6ad6", "#fff"]
    C["sprinkle"] = clip("".join(
        f'<rect x="{x - 4:.1f}" y="{y - 1.4:.1f}" width="8" height="2.8" rx="1.4" transform="rotate({r:.0f} {x:.1f} {y:.1f})" fill="{colors[i % len(colors)]}"/>'
        for i, (x, y, r) in enumerate(_scatter(rng, 26, 33)))) + outline

    rng = random.Random(28)
    C["charcoal"] = tint("#2b2522", 0.72) + clip("".join(
        f'<polygon points="{_poly(x, y, rng.uniform(2.4, 4.4), rng, 6)}" fill="{rng.choice(["#6b625c", "#57504b", "#7d746e"])}"/>'
        for x, y, _ in _scatter(rng, 14, 30))) + \
        '<ellipse cx="-15" cy="-17" rx="12" ry="6.5" transform="rotate(-35 -15 -17)" fill="#fff" opacity=".18"/>' + outline

    rng = random.Random(29)
    spark = lambda x, y, r: (f'<path d="M{x} {y - r} Q{x} {y} {x + r} {y} Q{x} {y} {x} {y + r} Q{x} {y} {x - r} {y} Q{x} {y} {x} {y - r}Z" '
                             f'fill="#fff"/>')
    C["gold"] = tint("#ffd54a", 0.18) + clip("".join(
        f'<polygon points="{_poly(x, y, rng.uniform(8, 11), rng, 5)}" fill="#ffd54a" stroke="#b8820f" stroke-width="1.6" stroke-linejoin="round"/>'
        f'<polygon points="{_poly(x - 2, y - 2, 3.5, rng, 4)}" fill="#fff4c2"/>'
        for x, y, _ in _scatter(rng, 5, 24))) + spark(-20, -8, 6) + spark(18, -22, 5) + spark(10, 22, 4.5) + outline
    return C


# ------------------------------------------------------------------ bottles
def _label(text, color, size=15, y=132, sub=None, sub_color=None):
    s = (f'<text x="50" y="{y}" text-anchor="middle" font-family="\'Dela Gothic One\',\'Hiragino Sans\',sans-serif" '
         f'font-size="{size}" fill="{color}">{text}</text>')
    if sub:
        s += (f'<text x="50" y="{y + 20}" text-anchor="middle" font-family="\'Zen Maru Gothic\',\'Hiragino Maru Gothic ProN\',sans-serif" '
              f'font-weight="700" font-size="9" fill="{sub_color or color}">{sub}</text>')
    return s


def _squeeze(body, cap, panel, text, text_color, size=15, extra=""):
    """Soft squeeze bottle with a pointed nozzle."""
    return f"""
<path d="M24 52 Q14 60 14 84 L14 196 Q14 212 30 212 L70 212 Q86 212 86 196 L86 84 Q86 60 76 52Z"
 fill="{body}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M22 54 L78 54 L72 34 L28 34Z" fill="{cap}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M42 34 L50 4 L58 34Z" fill="{cap}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<rect x="22" y="100" width="56" height="70" rx="9" fill="{panel}" stroke="{INK}" stroke-width="3"/>
{_label(text, text_color, size)}
{extra}
<rect x="22" y="70" width="7" height="116" rx="3.5" fill="#fff" opacity=".3"/>
"""


def _classic(body, cap, panel, text, text_color, size=15, sub=None):
    """Glass bottle like the default sauce."""
    return f"""
<path d="M38 24 L38 42 Q14 52 14 80 L14 196 Q14 212 30 212 L70 212 Q86 212 86 196 L86 80 Q86 52 62 42 L62 24Z"
 fill="{body}" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<rect x="34" y="4" width="32" height="24" rx="6" fill="{cap}" stroke="{INK}" stroke-width="{SW}"/>
<rect x="22" y="100" width="56" height="70" rx="9" fill="{panel}" stroke="{INK}" stroke-width="3"/>
{_label(text, text_color, size, sub=sub)}
<rect x="22" y="66" width="7" height="120" rx="3.5" fill="#fff" opacity=".22"/>
"""


def _bottles():
    B = {}
    B["mayo"] = _squeeze("#fff6d8", "#e8553a", "#fff", "マヨ", "#e8553a", 18,
                         '<path d="M26 176 L74 176 M26 186 L74 186" stroke="#e8553a" stroke-width="3" opacity=".5"/>')
    B["ketchup"] = _squeeze("#d9312b", "#fff", "#fff3d6", "ケチャ", "#d9312b", 16,
                            '<circle cx="50" cy="156" r="6" fill="#6cc04a" stroke="#3a2418" stroke-width="2"/>')
    B["tartar"] = _squeeze("#f4f1e0", "#6cc04a", "#fff", "タルタル", "#3f8f2a", 13,
                           "".join(f'<circle cx="{x}" cy="{y}" r="2" fill="#6cc04a"/>' for x, y in [(30, 80), (62, 76), (46, 88), (70, 192), (28, 196)]))
    B["soy"] = _classic("#2a1208", "#d7263d", "#fff3d6", "しょうゆ", "#2a1208", 13)
    B["curry"] = _squeeze("#c98a1a", "#7a3a14", "#fff3d6", "カレー", "#a0461c", 15)
    B["choco"] = _squeeze("#5b3a29", "#f5c13a", "#fff3d6", "チョコ", "#5b3a29", 15)
    B["honey"] = _squeeze("#f5b82e", "#fff4c2", "#fff8e0", "はちみつ", "#b8761c", 13,
                          "".join(f'<polygon points="{" ".join(f"{cx + 5 * math.cos(math.radians(a)):.1f},{cy + 5 * math.sin(math.radians(a)):.1f}" for a in range(0, 360, 60))}" '
                                  f'fill="none" stroke="#e39a16" stroke-width="1.6"/>' for cx, cy in [(40, 158), (50, 158), (60, 158)]))
    # salt: glass shaker with a domed lid full of holes
    B["salt"] = f"""
<rect x="18" y="56" width="64" height="156" rx="14" fill="#eef6fb" stroke="{INK}" stroke-width="{SW}"/>
<rect x="24" y="96" width="52" height="110" rx="10" fill="#fff"/>
{''.join(f'<rect x="{x}" y="{y}" width="3" height="3" fill="#d6e2ea" transform="rotate(20 {x} {y})"/>' for x, y in [(30, 110), (44, 128), (60, 104), (36, 150), (56, 168), (66, 140), (40, 186), (62, 192)])}
<path d="M16 58 L84 58 L84 40 Q84 8 50 8 Q16 8 16 40Z" fill="#c9d2dc" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
{''.join(f'<circle cx="{x}" cy="{y}" r="2.6" fill="{INK}"/>' for x, y in [(50, 16), (38, 22), (62, 22), (30, 34), (50, 30), (70, 34)])}
<rect x="22" y="120" width="56" height="44" rx="8" fill="#fff3d6" stroke="{INK}" stroke-width="3"/>
{_label("しお", "#4b6d8a", 18, y=150)}
<rect x="24" y="66" width="7" height="130" rx="3.5" fill="#fff" opacity=".8"/>
"""
    # lemon: a whole lemon, the pointed end (top) is where the juice comes out
    B["lemon"] = f"""
<path d="M50 6 C56 14 60 22 70 30 C92 50 94 110 86 150 C78 192 62 212 50 212 C38 212 22 192 14 150 C6 110 8 50 30 30 C40 22 44 14 50 6Z"
 fill="#ffe14d" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M30 70 Q24 110 32 160" stroke="#fff" stroke-width="7" stroke-linecap="round" fill="none" opacity=".45"/>
{''.join(f'<circle cx="{x}" cy="{y}" r="1.6" fill="#e8c21a"/>' for x, y in [(60, 70), (70, 100), (56, 130), (72, 150), (48, 180), (64, 190), (40, 100)])}
<path d="M50 210 C40 222 30 220 26 214 C34 206 44 206 50 210Z" fill="#6cc04a" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>
"""
    return B


def _drop(color, extra="", shine=0.45):
    return (f'<path d="M0 -13 C6 -4 9 1 9 5 A9 9 0 0 1 -9 5 C-9 1 -6 -4 0 -13Z" fill="{color}" stroke="{INK}" stroke-width="2.4"/>'
            f'<circle cx="-3" cy="4" r="2" fill="#fff" opacity="{shine}"/>{extra}')


def _drops():
    D = {
        "mayo": _drop("#fff6d8", shine=0.9),
        "ketchup": _drop("#d9312b"),
        "tartar": _drop("#f4f1e0", '<circle cx="2" cy="2" r="1.4" fill="#6cc04a"/><circle cx="-1" cy="7" r="1.2" fill="#6cc04a"/>', 0.9),
        "soy": _drop("#2a1208", shine=0.35),
        "lemon": _drop("#fff176", shine=0.9),
        "curry": _drop("#c98a1a"),
        "choco": _drop("#4e2a18"),
        "honey": _drop("#f5b82e", shine=0.7),
        # salt: a pinch of crystals instead of a drop
        "salt": "".join(f'<rect x="{x - 2.6}" y="{y - 2.6}" width="5.2" height="5.2" rx=".6" fill="#fff" stroke="{INK}" stroke-width="1.4" '
                        f'transform="rotate({r} {x} {y})"/>' for x, y, r in [(-4, -6, 15), (3, -1, 40), (-3, 5, 70), (5, 8, 25)]),
    }
    return D


def add_extras(S, seg):
    for k, body in _coats(seg).items():
        S[f"coat-{k}"] = ("-50 -50 100 100", body)
    for k, body in _bottles().items():
        S[f"bottle-{k}"] = ("0 0 100 220", body)
    for k, body in _drops().items():
        S[f"drop-{k}"] = ("-10 -15 20 27", body)


def add_fuels(S):
    """Call after S["fuel"] exists: same pickup, holding each sauce's bottle."""
    vb, body = S["fuel"]
    for k in SAUCE_KEYS:
        S[f"fuel-{k}"] = (vb, body.replace('href="#sauce"', f'href="#bottle-{k}"'))
