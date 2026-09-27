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
and, with --ground, a patch of scorched earth to stand on (<name>-ground.png).
    python3 tools/import_art.py sd-clay 2.5 --pieces
        # a resource: separate lumps on one picture (2.5 tiles wide) -> vanilla's 8 x 8 ore sheet
        # graphics/entity/sd-clay/sd-clay-stages.png
    python3 tools/import_art.py sd-rope 0 --icon
        # an item icon: art/incoming/icons/sd-rope.png -> graphics/icons/sd-rope.png (64 x 64);
        # --pips 3 adds three dots along the bottom (tiers); --size 128 for a crafting tab (item group)
    python3 tools/import_art.py sd-bow 0 --tech
        # a technology: art/incoming/tech/sd-bow.png -> graphics/technology/sd-bow.png (256 x 256)
    python3 tools/import_art.py sd-wolf 1.2 --unit
        # an animal seen from above, head up -> 16 turned frames (a stand-in until walking animations)"""
import os
import statistics
import sys

from PIL import Image

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


def feather(w, h, px, radius):
    """Soft edges for things lying on the ground (lairs): the outline is pulled in and fades out over about
    `radius` pixels instead of ending in a hard cut."""
    soft = blur([[p[3] / 255 for p in row] for row in px], w, h, radius)
    return [[(r, g, b, int(a * min(1, max(0, (s - 0.5) * 2)))) for (r, g, b, a), s in zip(row, srow)]
            for row, srow in zip(px, soft)]


def pieces(w, h, px):
    """Separate pieces of a picture: connected areas of solid pixels, each cut out with its soft edge.
    Returns (w, h, px) of every piece bigger than a crumb, biggest first."""
    seen = [[False] * w for _ in range(h)]
    found = []
    for y0 in range(h):
        for x0 in range(w):
            if seen[y0][x0] or px[y0][x0][3] < 64:
                continue
            stack, cells = [(x0, y0)], []
            seen[y0][x0] = True
            while stack:
                x, y = stack.pop()
                cells.append((x, y))
                for X, Y in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= X < w and 0 <= Y < h and not seen[Y][X] and px[Y][X][3] >= 64:
                        seen[Y][X] = True
                        stack.append((X, Y))
            if len(cells) < 12:
                continue
            xs, ys = [c[0] for c in cells], [c[1] for c in cells]
            x1, y1, x2, y2 = max(0, min(xs) - 1), max(0, min(ys) - 1), min(w - 1, max(xs) + 1), min(h - 1, max(ys) + 1)
            mine = set(cells)
            near = lambda x, y: any((x + dx, y + dy) in mine for dx in (-1, 0, 1) for dy in (-1, 0, 1))
            found.append((len(cells), [[px[y][x] if near(x, y) else (0, 0, 0, 0) for x in range(x1, x2 + 1)]
                                       for y in range(y1, y2 + 1)]))
    found.sort(key=lambda f: -f[0])
    return [(len(p[0]), len(p), p) for _, p in found]


def ore_sheet(parts, seed=1):
    """Vanilla's ore sheet from separate pieces: 8 variations (rows) x 8 stages (columns, richest first),
    128 px cells (2 tiles at scale 0.5, overlapping the neighbours like vanilla ore). Each variation scatters
    pieces around the tile centre with a soft contact shadow; poorer stages keep the smaller pieces."""
    import random
    C, counts = 128, [14, 12, 10, 8, 7, 5, 4, 3]
    parts = [p for p in parts if 12 <= max(p[0], p[1]) <= C - 16] or parts  # no crumbs (noise), no lumps
    # that stuck together into one piece too big for a cell
    sheet = [[(0, 0, 0, 0)] * (C * 8) for _ in range(C * 8)]

    def put(cx, cy, w, h, px, dark=None):
        for y in range(h):
            for x in range(w):
                a = px[y][x][3] / 255 * (dark or 1)
                if a <= 0:
                    continue
                X, Y = cx + x, cy + y
                r, g, b, oa = sheet[Y][X]
                src = (0, 0, 0) if dark else px[y][x][:3]
                na = a + oa / 255 * (1 - a)
                mix = [int((sv * a + ov * oa / 255 * (1 - a)) / na) for sv, ov in zip(src, (r, g, b))]
                sheet[Y][X] = (*mix, int(na * 255))

    for v in range(8):
        rnd = random.Random(seed * 100 + v)
        chosen = sorted((rnd.randrange(len(parts)) for _ in range(counts[0])), key=lambda i: parts[i][0] * parts[i][1])
        placed = []  # smallest first: the last to be mined out
        for i in chosen:
            w, h, _ = parts[i]
            for _ in range(40):
                x = int(C / 2 + rnd.uniform(-40, 40) - w / 2)
                y = int(C / 2 + rnd.uniform(-34, 34) - h / 2)
                if all(max(0, min(x + w, px_ + pw) - max(x, px_)) * max(0, min(y + h, py + ph) - max(y, py)) < 0.25 * w * h
                       for px_, py, pw, ph, *_ in placed):
                    break
            x, y = max(2, min(C - w - 4, x)), max(2, min(C - h - 4, y))
            solid = [p for row in parts[i][2] for p in row if p[3] > 200] or [(90, 70, 50, 255)]
            tone = tuple(int(sum(p[c] for p in solid) / len(solid) * 0.55) for c in range(3))
            dust = [(int(x + rnd.uniform(-6, w + 6)), int(y + rnd.uniform(-4, h + 6)), rnd.choice((1, 1, 2)))
                    for _ in range(w * h // 40 + 6)]  # crumbs and dirt around the piece
            placed.append((x, y, w, h, i, tone, dust))
        for s, n in enumerate(counts):
            keep = sorted(placed[:n], key=lambda p: p[1] + p[3])  # back to front
            ox, oy = s * C, v * C
            for x, y, w, h, i, tone, dust in keep:
                for dx, dy, d in dust:
                    if 1 <= dx < C - 3 and 1 <= dy < C - 3:
                        put(ox + dx, oy + dy, d, d, [[(*tone, 170)] * d] * d)
            for x, y, w, h, i, *_ in keep:
                put(ox + x + 3, oy + y + 2, w, h, parts[i][2], dark=0.45)
            for x, y, w, h, i, *_ in keep:
                put(ox + x, oy + y, w, h, parts[i][2])
    return C * 8, C * 8, sheet


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
    if height is None:  # sips --resampleWidth: scale height to match, keeping the aspect ratio
        height = int(h * width / w + 0.5)  # round half up, like sips (Python's round() is half-to-even)
    img = Image.new("RGBA", (w, h))
    img.putdata([p for row in px for p in row])
    data = img.resize((width, height), Image.LANCZOS).get_flattened_data()
    return width, height, [data[y * width:(y + 1) * width] for y in range(height)]


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
def rotated(n, px, angle):
    """A square picture turned clockwise by `angle` degrees around its centre (bilinear)."""
    import math
    c, s_ = math.cos(math.radians(angle)), math.sin(math.radians(angle))
    half = (n - 1) / 2
    out = []
    for y in range(n):
        row = []
        for x in range(n):
            u, v = c * (x - half) + s_ * (y - half) + half, -s_ * (x - half) + c * (y - half) + half
            x0, y0 = int(math.floor(u)), int(math.floor(v))
            if not (0 <= x0 < n - 1 and 0 <= y0 < n - 1):
                row.append((0, 0, 0, 0))
                continue
            fx, fy = u - x0, v - y0
            q = [px[y0][x0], px[y0][x0 + 1], px[y0 + 1][x0], px[y0 + 1][x0 + 1]]
            wts = [(1 - fx) * (1 - fy), fx * (1 - fy), (1 - fx) * fy, fx * fy]
            a = sum(w * p[3] for w, p in zip(wts, q))
            rgb = [int(sum(w * p[i] * p[3] for w, p in zip(wts, q)) / a) if a else 0 for i in range(3)]
            row.append((*rgb, int(a)))
        out.append(row)
    return out


if "--unit" in sys.argv:  # an animal seen from above, head up: art/incoming/<name>.png -> 16 turned frames (a
    # stand-in without walking frames), <name>-run.png, and the same for its shadow, <name>-run-shadow.png
    px, box = key(os.path.join(incoming, name + ".png"))
    w, h, px = crop(px, box)
    n, _, px = square(w, h, grade(px))
    side = round(tiles * PX_PER_TILE)
    _, _, px = resized(n, n, px, side, side)
    pad = side // 3
    big = [[(0, 0, 0, 0)] * (side + 2 * pad) for _ in range(side + 2 * pad)]
    for y in range(side):
        big[pad + y][pad:pad + side] = px[y]
    n = side + 2 * pad
    frames = [rotated(n, big, k * 22.5) for k in range(16)]
    out_dir = os.path.join(ROOT, "graphics", "entity", name)
    os.makedirs(out_dir, exist_ok=True)
    sheet = [[p for f in frames[r * 8:(r + 1) * 8] for p in f[y]] for r in range(2) for y in range(n)]
    png_io.write(os.path.join(out_dir, name + "-run.png"), n * 8, n * 2, sheet)
    sp = PX_PER_TILE // 8  # the shadow canvas is sp larger on every side: cut back to the frame
    shadows = [[r[sp:sp + n] for r in shadow(n, n, [[(0, 0, 0, p[3]) for p in row] for row in f], PX_PER_TILE // 10,
                                             PX_PER_TILE // 20, sp, strength=0.5)[2][sp:sp + n]] for f in frames]
    sheet = [[p for f in shadows[r * 8:(r + 1) * 8] for p in f[y]] for r in range(2) for y in range(n)]
    png_io.write(os.path.join(out_dir, name + "-run-shadow.png"), n * 8, n * 2, sheet)
    record_sizes({name + "-run": (n, n)})
    print(f"{name}: 16 directions of {n}x{n}")
    sys.exit(0)
if "--tech" in sys.argv:  # a technology picture: art/incoming/tech/<name>.png -> graphics/technology/<name>.png
    px, box = key(os.path.join(incoming, "tech", name + ".png"))
    w, h, px = crop(px, box)
    n, _, px = square(w, h, px)
    pad = n // 24
    big = [[(0, 0, 0, 0)] * (n + 2 * pad) for _ in range(n + 2 * pad)]
    for y in range(n):
        big[pad + y][pad:pad + n] = px[y]
    tw, th, tpx = resized(n + 2 * pad, n + 2 * pad, big, 256, 256)
    os.makedirs(os.path.join(ROOT, "graphics", "technology"), exist_ok=True)
    png_io.write(os.path.join(ROOT, "graphics", "technology", name + ".png"), tw, th, tpx)
    record_sizes({name + "-technology": (tw, th)})
    print(f"{name}: technology {tw}x{th}")
    sys.exit(0)
if "--icon" in sys.argv:  # an item icon: art/incoming/icons/<name>.png -> graphics/icons/<name>.png, 64 x 64
    px, box = key(os.path.join(incoming, "icons", name + ".png"))
    w, h, px = crop(px, box)
    n, _, px = square(w, h, px)
    pad = n // 30  # a thin margin like vanilla icons
    big = [[(0, 0, 0, 0)] * (n + 2 * pad) for _ in range(n + 2 * pad)]
    for y in range(n):
        big[pad + y][pad:pad + n] = px[y]
    size = int(sys.argv[sys.argv.index("--size") + 1]) if "--size" in sys.argv else 64  # 128: a crafting tab
    iw, ih, ipx = resized(n + 2 * pad, n + 2 * pad, big, size, size)
    if "--pips" in sys.argv:  # --pips N: N light dots along the bottom edge, e.g. the tier of a charge
        count = int(sys.argv[sys.argv.index("--pips") + 1])
        for k in range(count):
            cx, cy = 32 + (k - (count - 1) / 2) * 7, 59.5
            for y in range(55, 64):
                for x in range(int(cx) - 5, int(cx) + 6):
                    d = ((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2) ** 0.5
                    if d < 3.6:  # a dark rim, then the light dot
                        col = (245, 240, 225) if d < 2.4 else (30, 28, 26)
                        a = 255 if d < 3.1 else int(255 * (3.6 - d) / 0.5)
                        o = ipx[y][x]
                        A = a / 255
                        ipx[y][x] = tuple(int(c * A + oc * (1 - A)) for c, oc in zip(col, o[:3])) + (max(o[3], a),)
    png_io.write(os.path.join(ROOT, "graphics", "icons", name + ".png"), iw, ih, ipx)
    print(f"{name}: icon {iw}x{ih}")
    sys.exit(0)
main, box = key(os.path.join(incoming, name + ".png"))
keyed = {"": main}
fire = "fire" in states
states = [st for st in states if st != "fire"]
for st in states:
    keyed["-" + st], other = key(os.path.join(incoming, name + "-" + st + ".png"))
    box = [min(box[0], other[0]), min(box[1], other[1]), max(box[2], other[2]), max(box[3], other[3])]
# --flat <px>: lies on the ground (lairs): soft edges over <px> sprite pixels and a faint, close shadow.
flat = int(sys.argv[sys.argv.index("--flat") + 1]) if "--flat" in sys.argv else 0
os.makedirs(os.path.join(ROOT, "graphics", "entity", name), exist_ok=True)
if "--pieces" in sys.argv:  # a resource: a picture of separate pieces -> <name>-stages.png, vanilla's ore sheet
    w, h, px = crop(main, box)
    sw, sh, spx = resized(w, h, grade(px), round(tiles * PX_PER_TILE))
    parts = pieces(sw, sh, spx)
    W, H, sheet = ore_sheet(parts)
    for old in os.listdir(os.path.join(ROOT, "graphics", "entity", name)):
        os.remove(os.path.join(ROOT, "graphics", "entity", name, old))
    png_io.write(os.path.join(ROOT, "graphics", "entity", name, name + "-stages.png"), W, H, sheet)
    print(f"{name}-stages: {len(parts)} pieces, biggest {parts[0][0]}x{parts[0][1]} px, sheet {W}x{H}")
    record_sizes({name + "-stages": (W, H)})
    sys.exit(0)
for old in os.listdir(os.path.join(ROOT, "graphics", "entity", name)):
    os.remove(os.path.join(ROOT, "graphics", "entity", name, old))
out_dir = os.path.join(ROOT, "graphics", "entity", name)
silhouette, sizes = None, {}
for suffix, img in keyed.items():
    w, h, px = crop(img, box)
    sw, sh, spx = resized(w, h, grade(px), round(tiles * PX_PER_TILE))
    if flat:
        spx = feather(sw, sh, spx, flat)
    png_io.write(os.path.join(out_dir, name + suffix + ".png"), sw, sh, spx)
    sizes[name + suffix] = (sw, sh)
    print(f"{name}{suffix}: sprite {sw}x{sh} ({tiles} tiles wide)")
    if suffix == "" and not os.path.exists(os.path.join(incoming, "icons", name + ".png")):  # else its own icon
        iw, ih, ipx = resized(*square(w, h, grade(px)), 64, 64)
        png_io.write(os.path.join(ROOT, "graphics", "icons", name + ".png"), iw, ih, ipx)
    if silhouette is None:
        silhouette = [[(0, 0, 0, a) for (_, _, _, a) in row] for row in spx]
    else:  # the shadow of all states together
        silhouette = [[(0, 0, 0, max(p[3], q[3])) for p, q in zip(r1, r2)] for r1, r2 in zip(silhouette, spx)]
pad = PX_PER_TILE // 4
if flat:
    W, H, spx = shadow(sw, sh, silhouette, PX_PER_TILE // 16, PX_PER_TILE // 32, pad, strength=0.3)
else:
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
