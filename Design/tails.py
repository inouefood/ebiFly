"""Extra tail designs exchanged for points on the make screen.

Every tail lives in the same "-50 -50 100 100" box as tail-normal: it fans upward and its base
sits around y = 25..38 so it tucks under the first body ball (whose top edge is near y = 21).

`add_tails(S)` adds a `tail-<key>` symbol for each key in TAIL_KEYS.
"""
import math

INK = "#3a2418"
SW = 5


def _lobes(colors, vein="#000", vein_op=0.18, base="#d9472e", pattern=""):
    """The classic three-lobe fan (tail-normal) in other colours. colors: (left, right, middle)."""
    l, r, m = colors
    lobe = f'rx="14" ry="31" stroke="{INK}" stroke-width="{SW}"'
    return f"""
<ellipse cx="-17" cy="-6" {lobe} fill="{l}" transform="rotate(-30 -17 -6)"/>
<ellipse cx="17" cy="-6" {lobe} fill="{r}" transform="rotate(30 17 -6)"/>
<ellipse cx="0" cy="-13" {lobe} fill="{m}"/>
{pattern}
<path d="M0 -36 L0 8 M-26 -26 L-10 10 M26 -26 L10 10" stroke="{vein}" stroke-width="3" stroke-linecap="round" opacity="{vein_op}"/>
<ellipse cx="0" cy="30" rx="17" ry="11" fill="{base}" stroke="{INK}" stroke-width="{SW}"/>
"""


def _clip_lobes():
    """clipPath of the three lobes, used to paint stripes / dots inside them."""
    return """<clipPath id="lobeclip">
<ellipse cx="-17" cy="-6" rx="14" ry="31" transform="rotate(-30 -17 -6)"/>
<ellipse cx="17" cy="-6" rx="14" ry="31" transform="rotate(30 17 -6)"/>
<ellipse cx="0" cy="-13" rx="14" ry="31"/></clipPath>"""


def _star_points(r1, r2, n=5, rot=-90, cx=0, cy=0):
    pts = []
    for i in range(n * 2):
        r = r1 if i % 2 == 0 else r2
        a = math.radians(rot + i * 180 / n)
        pts.append(f"{cx + r * math.cos(a):.1f},{cy + r * math.sin(a):.1f}")
    return " ".join(pts)


def _stub(fill="#d9472e"):
    """Small rounded base that joins a tail shape to the body."""
    return f'<ellipse cx="0" cy="32" rx="15" ry="9" fill="{fill}" stroke="{INK}" stroke-width="{SW}"/>'


def _shine(cx, cy, rx=7, ry=4.5, rot=-30, op=0.5):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" transform="rotate({rot} {cx} {cy})" fill="#fff" opacity="{op}"/>'


T = {}

# ------------------------------------------------------------------ colour variants of the fan
T["blue"] = _lobes(("#4bb3e6", "#4bb3e6", "#5cc4f2"), base="#2f8fc4")
T["purple"] = _lobes(("#9a6ad6", "#9a6ad6", "#ad80e6"), base="#7a4cb8")
T["gold"] = _lobes(("#f5c13a", "#f5c13a", "#ffd65a"), vein="#b8820f", vein_op=0.6, base="#e39a16") + \
    _shine(-4, -30, 4, 9, 0, 0.6)
T["silver"] = _lobes(("#c9d2dc", "#c9d2dc", "#dde4ec"), vein="#7d8896", vein_op=0.6, base="#a3aebb") + \
    _shine(-4, -30, 4, 9, 0, 0.7)
T["rainbow"] = _lobes(("#4bb3e6", "#6cc04a", "#f5c13a"), base="#ec5a3c")
T["stripe"] = _clip_lobes() + _lobes(("#fff4e0",) * 3, base="#d9472e", vein_op=0, pattern=(
    '<g clip-path="url(#lobeclip)" fill="#ec5a3c">'
    + "".join(f'<rect x="-50" y="{y}" width="100" height="6"/>' for y in range(-44, 30, 12))
    + "</g>"
    # outlines again on top so the stripes stay inside the lines
    + f'<g fill="none" stroke="{INK}" stroke-width="{SW}">'
      '<ellipse cx="-17" cy="-6" rx="14" ry="31" transform="rotate(-30 -17 -6)"/>'
      '<ellipse cx="17" cy="-6" rx="14" ry="31" transform="rotate(30 17 -6)"/>'
      '<ellipse cx="0" cy="-13" rx="14" ry="31"/></g>'))
T["dots"] = _clip_lobes() + _lobes(("#ff8fb3",) * 3, base="#e0557f", vein_op=0, pattern=(
    '<g clip-path="url(#lobeclip)" fill="#fff">'
    + "".join(f'<circle cx="{x}" cy="{y}" r="3.6"/>'
              for y in range(-40, 26, 11) for x in range(-40 + (6 if (y // 11) % 2 else 0), 44, 12))
    + "</g>"
    + f'<g fill="none" stroke="{INK}" stroke-width="{SW}">'
      '<ellipse cx="-17" cy="-6" rx="14" ry="31" transform="rotate(-30 -17 -6)"/>'
      '<ellipse cx="17" cy="-6" rx="14" ry="31" transform="rotate(30 17 -6)"/>'
      '<ellipse cx="0" cy="-13" rx="14" ry="31"/></g>'))

# ------------------------------------------------------------------ shapes
T["star"] = f"""
<polygon points="{_star_points(40, 18, cy=-6)}" fill="#ffd84d" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
{_shine(-9, -20, 5, 3.5)}
{_stub("#f2b632")}
"""

petal = "M0 0 C-11 -8 -12 -24 -4 -31 L0 -26 L4 -31 C12 -24 11 -8 0 0Z"
T["sakura"] = f"""
<g transform="translate(0 -8) scale(1.3)">
{''.join(f'<path d="{petal}" transform="rotate({a})" fill="#ffc2d6" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>' for a in range(0, 360, 72))}
<circle r="7" fill="#ff7ba6" stroke="{INK}" stroke-width="3"/>
{''.join(f'<circle cx="{10 * math.sin(math.radians(a)):.1f}" cy="{-10 * math.cos(math.radians(a)):.1f}" r="1.8" fill="#e0557f"/>' for a in range(36, 360, 72))}
</g>
{_stub("#7cc95a")}
"""

T["leaf"] = f"""
<path d="M0 30 C-34 10 -32 -26 0 -42 C32 -26 34 10 0 30Z" fill="#6cc04a" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M0 26 L0 -34 M0 -4 L-14 -16 M0 -4 L14 -16 M0 10 L-15 -1 M0 10 L15 -1 M0 -18 L-10 -28 M0 -18 L10 -28"
 stroke="#3f8f2a" stroke-width="3" stroke-linecap="round" fill="none"/>
{_shine(-13, -14, 5, 9, 20, 0.35)}
{_stub("#4a9a32")}
"""

heart_leaf = "M0 0 C-4 -6 -18 -10 -18 -21 C-18 -29 -8 -32 0 -24 C8 -32 18 -29 18 -21 C18 -10 4 -6 0 0Z"
T["clover"] = f"""
<g transform="translate(0 -6)">
{''.join(f'<path d="{heart_leaf}" transform="rotate({a})" fill="#5cbf4a" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>' for a in (0, 90, 180, 270))}
<circle r="4" fill="#3f8f2a"/>
</g>
<path d="M0 16 Q2 24 0 30" stroke="{INK}" stroke-width="5" fill="none"/>
{_stub("#4a9a32")}
"""

T["ribbon"] = f"""
<path d="M-4 16 L-22 36 L-12 37 L-8 44 L2 20Z M4 16 L22 36 L12 37 L8 44 L-2 20Z" fill="#d7263d" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>
<path d="M0 0 C-14 -22 -44 -30 -42 -6 C-40 14 -14 12 0 0Z" fill="#ff5a78" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M0 0 C14 -22 44 -30 42 -6 C40 14 14 12 0 0Z" fill="#ff5a78" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M-6 -2 C-16 -12 -30 -16 -32 -8 M6 -2 C16 -12 30 -16 32 -8" stroke="#d7263d" stroke-width="3" fill="none" stroke-linecap="round"/>
<rect x="-9" y="-9" width="18" height="18" rx="6" fill="#ff7b93" stroke="{INK}" stroke-width="{SW}"/>
"""

T["fish"] = f"""
<path d="M0 30 C-6 14 -10 0 -40 -30 C-22 -34 -8 -26 0 -14 C8 -26 22 -34 40 -30 C10 0 6 14 0 30Z"
 fill="#4bb3e6" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M0 22 L-26 -24 M0 22 L-12 -22 M0 22 L12 -22 M0 22 L26 -24" stroke="#2f8fc4" stroke-width="2.6" stroke-linecap="round"/>
{_stub("#2f8fc4")}
"""

T["flame"] = f"""
<path d="M0 34 C-30 30 -38 4 -26 -14 C-24 -4 -18 0 -14 -2 C-20 -20 -10 -36 4 -44 C2 -30 12 -24 18 -30 C30 -12 40 18 0 34Z"
 fill="#ff7a2e" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M0 28 C-16 26 -20 12 -12 2 C-10 8 -6 10 -4 8 C-6 -4 0 -14 8 -18 C8 -8 14 -4 16 -8 C22 4 22 22 0 28Z" fill="#ffd84d"/>
<path d="M0 24 C-7 22 -8 14 -4 10 C-2 14 2 12 2 8 C8 12 9 22 0 24Z" fill="#fff4c2"/>
"""

T["bolt"] = f"""
<polygon points="10,-44 -24,0 -4,0 -14,34 26,-12 6,-12 20,-44" fill="#ffd84d" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<polygon points="8,-38 -14,-4 -2,-4" fill="#fff4c2" opacity=".8"/>
{_stub("#f2b632")}
"""

T["moon"] = f"""
<path d="M-8 -42 C-36 -32 -44 6 -20 26 C-4 38 22 34 34 18 C10 22 -12 6 -14 -16 C-15 -28 -12 -36 -8 -42Z"
 fill="#fff2b0" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<circle cx="-24" cy="2" r="4" fill="#f0dd8a"/><circle cx="-12" cy="18" r="3" fill="#f0dd8a"/>
<polygon points="{_star_points(9, 4, cx=20, cy=-22)}" fill="#ffd84d" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>
<polygon points="{_star_points(6, 2.6, cx=30, cy=-2)}" fill="#ffd84d" stroke="{INK}" stroke-width="2.6" stroke-linejoin="round"/>
{_stub("#e8c25a")}
"""

wing = "M0 10 C-6 -8 -20 -30 -46 -34 C-40 -26 -42 -20 -46 -16 C-38 -12 -38 -6 -42 -2 C-32 0 -30 6 -32 10 C-20 10 -10 14 0 10Z"
T["wings"] = f"""
<path d="{wing}" fill="#fff" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="{wing}" transform="scale(-1 1)" fill="#fff" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M-8 2 C-16 -10 -26 -20 -38 -24 M-10 6 C-18 0 -26 -6 -36 -8 M8 2 C16 -10 26 -20 38 -24 M10 6 C18 0 26 -6 36 -8"
 stroke="#cfe6f5" stroke-width="3" fill="none" stroke-linecap="round"/>
{_stub("#fff4c2")}
"""

feather = "M0 30 C-3 10 -16 -10 -10 -30 C-6 -40 6 -40 10 -30 C16 -10 3 10 0 30Z"
T["peacock"] = f"""
{''.join(f'<g transform="rotate({a} 0 30)"><path d="{feather}" fill="#2e9b8f" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>'
         f'<ellipse cx="0" cy="-24" rx="6" ry="8" fill="#4bb3e6" stroke="{INK}" stroke-width="2"/><circle cx="0" cy="-24" r="3" fill="#1b2f7a"/></g>'
         for a in (-50, -25, 25, 50, 0))}
{_stub("#2e9b8f")}
"""

T["rocket"] = f"""
<path d="M-6 24 L-34 36 L-30 6 L-10 -4Z" fill="#ec5a3c" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M6 24 L34 36 L30 6 L10 -4Z" fill="#ec5a3c" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M0 -44 C14 -32 16 -6 12 28 L-12 28 C-16 -6 -14 -32 0 -44Z" fill="#eef2f6" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<circle cx="0" cy="-10" r="7" fill="#4bb3e6" stroke="{INK}" stroke-width="3.5"/>
<circle cx="-2" cy="-12" r="2" fill="#fff" opacity=".8"/>
<path d="M0 -44 C7 -38 10 -32 11 -26 L-11 -26 C-10 -32 -7 -38 0 -44Z" fill="#ec5a3c" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>
"""

ribs = "".join(
    f'<path d="M0 30 L{40 * math.sin(math.radians(a)):.1f} {30 - 62 * math.cos(math.radians(a)) * 0.95:.1f}" stroke="#e0a77a" stroke-width="2.6" stroke-linecap="round"/>'
    for a in (-48, -28, -10, 10, 28, 48))
T["shell"] = f"""
<path d="M0 30 L-42 -6 C-40 -32 -22 -40 0 -40 C22 -40 40 -32 42 -6Z" fill="#ffd9c0" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
{ribs}
{_shine(-14, -24, 7, 4, -15, 0.6)}
<path d="M-12 30 L-18 38 L18 38 L12 30Z" fill="#f2b48c" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>
"""

arm = ("M0 0 L0 -36 M0 -14 L-9 -23 M0 -14 L9 -23 M0 -26 L-7 -33 M0 -26 L7 -33")
T["snow"] = f"""
<g transform="translate(0 -8) scale(1.2)">
<g stroke="{INK}" stroke-width="9" stroke-linecap="round" fill="none">{''.join(f'<path d="{arm}" transform="rotate({a})"/>' for a in range(0, 360, 60))}</g>
<g stroke="#bfe6ff" stroke-width="4.5" stroke-linecap="round" fill="none">{''.join(f'<path d="{arm}" transform="rotate({a})"/>' for a in range(0, 360, 60))}</g>
<polygon points="{_star_points(9, 9, 6, -90)}" fill="#fff" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>
</g>
{_stub("#9fd3f2")}
"""

maple = ("M0 30 L2 18 L22 22 L18 12 L40 -4 L30 -8 L34 -22 L20 -18 L18 -28 L8 -18 L10 -40 L0 -32 L-10 -40 L-8 -18 "
         "L-18 -28 L-20 -18 L-34 -22 L-30 -8 L-40 -4 L-18 12 L-22 22 L-2 18Z")
T["maple"] = f"""
<path d="{maple}" fill="#e8553a" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M0 26 L0 -28 M0 6 L-26 -6 M0 6 L26 -6 M0 -6 L-14 -20 M0 -6 L14 -20" stroke="#b8361f" stroke-width="2.6" stroke-linecap="round" fill="none"/>
{_stub("#b8361f")}
"""

T["ginkgo"] = f"""
<path d="M0 28 C-4 16 -10 8 -40 -14 C-30 -34 -12 -42 -2 -30 L0 -22 L2 -30 C12 -42 30 -34 40 -14 C10 8 4 16 0 28Z"
 fill="#f5c13a" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M0 24 L-28 -16 M0 24 L-16 -30 M0 24 L16 -30 M0 24 L28 -16" stroke="#d99a12" stroke-width="2.4" stroke-linecap="round"/>
{_stub("#d99a12")}
"""

T["butterfly"] = f"""
<path d="M0 0 C-10 -24 -40 -42 -44 -20 C-46 -6 -24 0 0 0Z" fill="#ffb347" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M0 0 C10 -24 40 -42 44 -20 C46 -6 24 0 0 0Z" fill="#ffb347" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M0 2 C-8 14 -32 26 -32 12 C-32 4 -16 2 0 2Z" fill="#ff7ba6" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>
<path d="M0 2 C8 14 32 26 32 12 C32 4 16 2 0 2Z" fill="#ff7ba6" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>
<circle cx="-26" cy="-20" r="5" fill="#fff4c2" stroke="{INK}" stroke-width="2.4"/>
<circle cx="26" cy="-20" r="5" fill="#fff4c2" stroke="{INK}" stroke-width="2.4"/>
<rect x="-4" y="-16" width="8" height="32" rx="4" fill="{INK}"/>
<path d="M-2 -16 Q-8 -28 -14 -32 M2 -16 Q8 -28 14 -32" stroke="{INK}" stroke-width="2.6" fill="none" stroke-linecap="round"/>
{_stub("#3a2418")}
"""

rays = "".join(
    f'<polygon points="{18 * math.cos(math.radians(a - 12)):.1f},{-8 + 18 * math.sin(math.radians(a - 12)):.1f} '
    f'{38 * math.cos(math.radians(a)):.1f},{-8 + 38 * math.sin(math.radians(a)):.1f} '
    f'{18 * math.cos(math.radians(a + 12)):.1f},{-8 + 18 * math.sin(math.radians(a + 12)):.1f}" fill="#ff9a2e" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>'
    for a in range(0, 360, 36))
T["sun"] = f"""
{rays}
<circle cx="0" cy="-8" r="20" fill="#ffd84d" stroke="{INK}" stroke-width="{SW}"/>
<path d="M-9 -10 Q-6 -14 -3 -10 M3 -10 Q6 -14 9 -10" stroke="{INK}" stroke-width="2.6" fill="none" stroke-linecap="round"/>
<path d="M-6 -2 Q0 4 6 -2" stroke="{INK}" stroke-width="2.6" fill="none" stroke-linecap="round"/>
<circle cx="-12" cy="-3" r="2.6" fill="#ff7ba6" opacity=".7"/><circle cx="12" cy="-3" r="2.6" fill="#ff7ba6" opacity=".7"/>
{_stub("#f2b632")}
"""

T["gem"] = f"""
<polygon points="-30,-18 -16,-36 16,-36 30,-18 0,30" fill="#5cc4f2" stroke="{INK}" stroke-width="{SW}" stroke-linejoin="round"/>
<path d="M-30 -18 L30 -18 M-16 -36 L-8 -18 L0 -36 L8 -18 L16 -36 M-8 -18 L0 30 L8 -18" stroke="{INK}" stroke-width="2.6" fill="none" stroke-linejoin="round"/>
<polygon points="-16,-36 -8,-18 -30,-18" fill="#bfe6ff"/>
<polygon points="-8,-18 0,30 -30,-18" fill="#8fd8ff" opacity=".7"/>
<polygon points="{_star_points(6, 2, 4, -90, 22, -30)}" fill="#fff"/>
"""

T["galaxy"] = _lobes(("#2b2f7a", "#2b2f7a", "#3a3f96"), vein_op=0, base="#1b2f7a", pattern="") + "".join(
    f'<polygon points="{_star_points(r, r * 0.42, 4, -90, x, y)}" fill="#fff"/>'
    for x, y, r in [(-20, -12, 4), (14, -20, 3), (2, -34, 4.5), (24, 2, 3), (-6, 0, 2.6), (-28, -28, 2.4), (8, -4, 2)])

# key -> display order is decided on the Swift side (TailKind); this is just the art.
TAIL_KEYS = list(T.keys())


def add_tails(S):
    for key, body in T.items():
        S[f"tail-{key}"] = ("-50 -50 100 100", body)
