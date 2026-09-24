#!/usr/bin/env python3
"""Imports a generated picture (art/incoming/<name>.png, object on a flat magenta background, or already
transparent) into the mod:
cuts the background out (soft edge without a magenta fringe; a darker magenta cast shadow becomes a soft
black shadow),
crops to the object and writes the entity sprite and the 64 px icon.
    python3 tools/import_art.py sd-campfire 1.35        # sprite 1.35 tiles wide
    python3 tools/import_art.py sd-campfire 1.35 --state unlit
        # also art/incoming/sd-campfire-unlit.png (the same picture edited: another state of the building),
        # cropped with the same box so the states line up: graphics/entity/sd-campfire/sd-campfire-unlit.png
Sprites are stored at 64 px per tile and drawn with scale 0.5 like vanilla's high-resolution sprites (see
lib.art_sprite in prototypes/lib.lua). To sit in the game's look, every picture is graded towards the game's
warm, soft palette, and gets a shadow (<name>-shadow.png: the silhouette cast to the lower right, blurred)
and, with --ground, a patch of scorched earth to stand on (<name>-ground.png)."""
import os
import statistics
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(__file__))
import png_io

ROOT = os.path.join(os.path.dirname(__file__), "..")
PX_PER_TILE = 64


def key(path):
    w, h, px = png_io.read(path)
    edge = [px[y][x][3] for y in (0, h - 1) for x in range(0, w, 7)] + [px[y][x][3] for x in (0, w - 1) for y in range(0, h, 7)]
    if sum(1 for a in edge if a < 16) > 0.9 * len(edge):  # already transparent (ChatGPT): keep its alpha
        box = [w, h, 0, 0]
        for y in range(h):
            for x in range(w):
                if px[y][x][3] > 128:
                    box = [min(box[0], x), min(box[1], y), max(box[2], x), max(box[3], y)]
        return [[p if p[3] else (0, 0, 0, 0) for p in row] for row in px], box
    if all(max(p[:3]) - min(p[:3]) < 12 and min(p[:3]) > 200 for p in (px[2][2], px[2][w - 3], px[h - 3][2], px[h - 3][w - 3])):
        return flood(w, h, px)
    border = [px[y][x] for y in (0, h - 1) for x in range(0, w, 7)] + [px[y][x] for x in (0, w - 1) for y in range(0, h, 7)]
    bg = tuple(statistics.median(p[i] for p in border) for i in range(3))
    # Unmixing by chroma: `s` is how much of a pixel is the magenta background. The rest is the object.
    # A darker magenta (a cast shadow drawn by the generator) leaves a dark remainder: a soft black shadow.
    chroma = min(bg[0], bg[2]) - bg[1]
    out, box = [], [w, h, 0, 0]
    for y in range(h):
        row = []
        for x in range(w):
            r, g, b, _ = px[y][x]
            s = max(0.0, min(1.0, (min(r, b) - g) / chroma))
            s = 1.0 if s > 0.92 else s
            a = 1 - s
            if a <= 0.02:
                row.append((0, 0, 0, 0))
                continue
            c = [max(0, min(255, int((v - s * bv) / a))) for v, bv in zip((r, g, b), bg)]
            row.append((c[0], c[1], c[2], int(a * 255)))
            if a > 0.5 and max(c) > 40:  # the object itself, not only its shadow
                box = [min(box[0], x), min(box[1], y), max(box[2], x), max(box[3], y)]
        out.append(row)
    return out, box


def flood(w, h, px):
    """A white or drawn checkerboard "transparent" background (ChatGPT): everything light and grey that is
    connected to the border is background; the pixels next to it get half alpha for a soft edge."""
    def is_bg(p):
        return max(p[:3]) - min(p[:3]) < 14 and min(p[:3]) > 195
    bg = [[False] * w for _ in range(h)]
    stack = [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)]
    while stack:
        x, y = stack.pop()
        if 0 <= x < w and 0 <= y < h and not bg[y][x] and is_bg(px[y][x]):
            bg[y][x] = True
            stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    out, box = [], [w, h, 0, 0]
    for y in range(h):
        row = []
        for x in range(w):
            if bg[y][x]:
                row.append((0, 0, 0, 0))
                continue
            edge = any(0 <= x + dx < w and 0 <= y + dy < h and bg[y + dy][x + dx] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            row.append(px[y][x][:3] + (128 if edge else 255,))
            box = [min(box[0], x), min(box[1], y), max(box[2], x), max(box[3], y)]
        out.append(row)
    return out, box


def fire_sheet(path, cols, rows, width_tiles):
    """A generated grid of flame frames -> an animation sheet: every cell scaled so the flame is
    `width_tiles` wide, the faint haze around the flames dropped. Returns frame size and the sheet."""
    w, h, px = png_io.read(path)
    cw, ch = w // cols, h // rows
    cells = [[r[c * cw:(c + 1) * cw] for r in px[k * ch:(k + 1) * ch]] for k in range(rows) for c in range(cols)]
    widths = []
    for cell in cells:
        xs = [x for row in cell for x, p in enumerate(row) if p[3] > 128]
        widths.append(max(xs) - min(xs) if xs else cw)
    flame_w = sorted(widths)[len(widths) // 2]
    fw = round(cw * width_tiles * PX_PER_TILE / flame_w)
    fh = round(ch * fw / cw)
    frames = []
    for cell in cells:
        clean = [[(r, g, b, 0 if a <= 40 or (a < 230 and (max(r, g, b) - min(r, g, b)) < 0.35 * max(r, g, b, 1)) else a)
                  for r, g, b, a in row] for row in cell]  # no pale haze: only the coloured flame
        frames.append(resized(cw, ch, clean, fw, fh)[2])
    sheet = [[p for f in frames[k * cols:(k + 1) * cols] for p in f[y]] for k in range(rows) for y in range(fh)]
    return fw, fh, sheet


def crop(out, box):
    x0, y0, x1, y1 = box
    return x1 - x0 + 1, y1 - y0 + 1, [r[x0:x1 + 1] for r in out[y0:y1 + 1]]


def grade(px):
    """Warmer and a little darker and less saturated: the generator's colours are colder and brighter
    than Factorio's."""
    out = []
    for row in px:
        o = []
        for r, g, b, a in row:
            if a:
                grey = 0.3 * r + 0.59 * g + 0.11 * b
                r, g, b = (grey + (v - grey) * 0.85 for v in (r, g, b))
                r, g, b = r * 0.9, g * 0.84, b * 0.74
                r, g, b = (max(0, min(255, int(v))) for v in (r, g, b))
            o.append((r, g, b, a))
        out.append(o)
    return out


def blur(alpha, w, h, radius):
    """Box blur (three passes) of a list of alpha rows."""
    for _ in range(3):
        rows = []
        for row in alpha:
            acc, out = 0, []
            pre = [0]
            for v in row:
                pre.append(pre[-1] + v)
            for x in range(w):
                lo, hi = max(0, x - radius), min(w, x + radius + 1)
                out.append((pre[hi] - pre[lo]) / (hi - lo))
            rows.append(out)
        cols = []
        for x in range(w):
            pre = [0]
            for y in range(h):
                pre.append(pre[-1] + rows[y][x])
            cols.append([(pre[min(h, y + radius + 1)] - pre[max(0, y - radius)]) / (min(h, y + radius + 1) - max(0, y - radius)) for y in range(h)])
        alpha = [[cols[x][y] for x in range(w)] for y in range(h)]
    return alpha


def shadow(w, h, px, dx, dy, pad, strength=0.7):
    """The silhouette moved by (dx, dy) and blurred, on a canvas `pad` larger on every side, so that its
    centre stays the sprite's centre."""
    W, H = w + 2 * pad, h + 2 * pad
    alpha = [[0.0] * W for _ in range(H)]
    for y in range(h):
        for x in range(w):
            alpha[pad + dy + y][pad + dx + x] = px[y][x][3] / 255
    alpha = blur(alpha, W, H, max(1, pad // 5))
    return W, H, [[(0, 0, 0, int(min(1, a) * 255 * strength)) for a in row] for row in alpha]


def ground(w, h, cx, seed=7):
    """A patch of scorched earth and ash: a soft, ragged, flattened disc."""
    import math
    import random
    rnd = random.Random(seed)
    waves = [(rnd.uniform(0, 6.3), rnd.randint(3, 9), rnd.uniform(0.04, 0.09)) for _ in range(4)]
    out = []
    for y in range(h):
        row = []
        for x in range(w):
            nx, ny = (x - cx) / (w / 2), (y - h / 2) / (h / 2)
            ang, d = math.atan2(ny, nx), math.hypot(nx, ny)
            edge = 0.92 + sum(amp * math.sin(k * ang + ph) for ph, k, amp in waves)
            a = max(0.0, min(1.0, (edge - d) / 0.35))
            grain = rnd.uniform(-14, 14)
            row.append((int(40 + grain), int(32 + grain * 0.8), int(26 + grain * 0.6), int(a * 235)))
        out.append(row)
    return out


def record_sizes(sizes):
    """prototypes/art-sizes.lua: pixel sizes of the imported sprites, read by lib.art_sprite."""
    import re
    path = os.path.join(ROOT, "prototypes", "art-sizes.lua")
    known = {}
    if os.path.exists(path):
        for m in re.finditer(r'\["([\w-]+)"\] = \{(\d+), (\d+)\}', open(path).read()):
            known[m.group(1)] = (int(m.group(2)), int(m.group(3)))
    building = min(sizes, key=len)  # this import replaces all layers of its building
    known = {k: v for k, v in known.items() if k != building and not k.startswith(building + "-")}
    known.update(sizes)
    with open(path, "w") as f:
        f.write("-- Written by tools/import_art.py: pixel sizes of the sprites in graphics/entity/<building>/.\nreturn {\n")
        for k in sorted(known):
            f.write('  ["%s"] = {%d, %d},\n' % (k, *known[k]))
        f.write("}\n")


def resized(w, h, px, width, height=None):
    with tempfile.TemporaryDirectory() as tmp:
        src, dst = os.path.join(tmp, "a.png"), os.path.join(tmp, "b.png")
        png_io.write(src, w, h, px)
        args = ["-z", str(height), str(width)] if height else ["--resampleWidth", str(width)]
        subprocess.run(["sips", *args, src, "--out", dst], check=True, capture_output=True)
        return png_io.read(dst)


def square(w, h, px):
    n = max(w, h)
    ox, oy = (n - w) // 2, (n - h) // 2
    out = [[(0, 0, 0, 0)] * n for _ in range(n)]
    for y in range(h):
        out[oy + y][ox:ox + w] = px[y]
    return n, n, out


name, tiles = sys.argv[1], float(sys.argv[2])
states = [sys.argv[i + 1] for i, a in enumerate(sys.argv) if a == "--state"]
incoming = os.path.join(ROOT, "art", "incoming")
main, box = key(os.path.join(incoming, name + ".png"))
keyed = {"": main}
fire = "fire" in states
states = [st for st in states if st != "fire"]
for st in states:
    keyed["-" + st], other = key(os.path.join(incoming, name + "-" + st + ".png"))
    box = [min(box[0], other[0]), min(box[1], other[1]), max(box[2], other[2]), max(box[3], other[3])]
os.makedirs(os.path.join(ROOT, "graphics", "entity", name), exist_ok=True)
for old in os.listdir(os.path.join(ROOT, "graphics", "entity", name)):
    os.remove(os.path.join(ROOT, "graphics", "entity", name, old))
out_dir = os.path.join(ROOT, "graphics", "entity", name)
silhouette, sizes = None, {}
for suffix, img in keyed.items():
    w, h, px = crop(img, box)
    sw, sh, spx = resized(w, h, grade(px), round(tiles * PX_PER_TILE))
    png_io.write(os.path.join(out_dir, name + suffix + ".png"), sw, sh, spx)
    sizes[name + suffix] = (sw, sh)
    print(f"{name}{suffix}: sprite {sw}x{sh} ({tiles} tiles wide)")
    if suffix == "":
        iw, ih, ipx = resized(*square(w, h, grade(px)), 64, 64)
        png_io.write(os.path.join(ROOT, "graphics", "icons", name + ".png"), iw, ih, ipx)
    if silhouette is None:
        silhouette = [[(0, 0, 0, a) for (_, _, _, a) in row] for row in spx]
    else:  # the shadow of all states together
        silhouette = [[(0, 0, 0, max(p[3], q[3])) for p, q in zip(r1, r2)] for r1, r2 in zip(silhouette, spx)]
pad = PX_PER_TILE // 4
W, H, spx = shadow(sw, sh, silhouette, PX_PER_TILE // 5, PX_PER_TILE // 10, pad)
png_io.write(os.path.join(out_dir, name + "-shadow.png"), W, H, spx)
sizes[name + "-shadow"] = (W, H)
print(f"{name}-shadow: {W}x{H}")
if "--ground" in sys.argv:
    cx = float(sys.argv[sys.argv.index("--ground") + 1])  # centre of the patch, as a fraction of the width
    gw, gh = round(sw * 1.2), round(sh * 1.1)
    png_io.write(os.path.join(out_dir, name + "-ground.png"), gw, gh, ground(gw, gh, gw * cx))
    sizes[name + "-ground"] = (gw, gh)
    print(f"{name}-ground: {gw}x{gh}")
if fire:  # art/incoming/<name>-fire.png: a 4x4 grid of flame frames
    flame_tiles = float(sys.argv[sys.argv.index("--fire") + 1]) if "--fire" in sys.argv else 0.5
    fw, fh, sheet = fire_sheet(os.path.join(incoming, name + "-fire.png"), 4, 4, flame_tiles)
    png_io.write(os.path.join(out_dir, name + "-fire.png"), fw * 4, fh * 4, sheet)
    sizes[name + "-fire"] = (fw, fh)
    print(f"{name}-fire: 16 frames of {fw}x{fh}")
record_sizes(sizes)
