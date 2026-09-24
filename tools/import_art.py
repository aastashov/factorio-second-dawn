#!/usr/bin/env python3
"""Imports a generated picture (art/incoming/<name>.png, object on a flat magenta background) into the mod:
cuts the background out (soft edge without a magenta fringe; a darker magenta cast shadow becomes a soft
black shadow),
crops to the object and writes the entity sprite and the 64 px icon.
    python3 tools/import_art.py sd-campfire 1.35        # sprite 1.35 tiles wide
    python3 tools/import_art.py sd-campfire 1.35 --state unlit
        # also art/incoming/sd-campfire-unlit.png (the same picture edited: another state of the building),
        # cropped with the same box so the states line up: graphics/entity/sd-campfire/sd-campfire-unlit.png
Sprites are stored at 128 px per tile and drawn with scale 0.25 (see lib.art_sprite in prototypes/lib.lua)."""
import os
import statistics
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(__file__))
import png_io

ROOT = os.path.join(os.path.dirname(__file__), "..")
PX_PER_TILE = 128


def key(path):
    w, h, px = png_io.read(path)
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


def crop(out, box):
    x0, y0, x1, y1 = box
    return x1 - x0 + 1, y1 - y0 + 1, [r[x0:x1 + 1] for r in out[y0:y1 + 1]]


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
for st in states:
    keyed["-" + st], other = key(os.path.join(incoming, name + "-" + st + ".png"))
    box = [min(box[0], other[0]), min(box[1], other[1]), max(box[2], other[2]), max(box[3], other[3])]
os.makedirs(os.path.join(ROOT, "graphics", "entity", name), exist_ok=True)
for suffix, img in keyed.items():
    w, h, px = crop(img, box)
    sw, sh, spx = resized(w, h, px, round(tiles * PX_PER_TILE))
    png_io.write(os.path.join(ROOT, "graphics", "entity", name, name + suffix + ".png"), sw, sh, spx)
    print(f"{name}{suffix}: sprite {sw}x{sh} ({tiles} tiles wide)")
    if suffix == "":
        iw, ih, ipx = resized(*square(w, h, px), 64, 64)
        png_io.write(os.path.join(ROOT, "graphics", "icons", name + ".png"), iw, ih, ipx)
