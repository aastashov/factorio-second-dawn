#!/usr/bin/env python3
"""Preview of an imported building on vanilla grass at the game's scale, next to the vanilla lab (3x3) for
comparison: idle state, then the working state. -> art/preview/<name>.png
    python3 tools/art_preview.py sd-scholar-desk"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
import png_io

ROOT = os.path.join(os.path.dirname(__file__), "..")
GAME = os.path.expanduser("~/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data/base/graphics")
T = 64
name = sys.argv[1]
d = os.path.join(ROOT, "graphics", "entity", name)


def load(path):
    return png_io.read(path)[2] if os.path.exists(path) else None


grass = png_io.read(os.path.join(GAME, "terrain", "grass-1.png"))[2]
lab = [r[0:194] for r in png_io.read(os.path.join(GAME, "entity", "lab", "lab.png"))[2][0:174]]
states = [s for s in ("idle", "unlit") if os.path.exists(os.path.join(d, f"{name}-{s}.png"))]
idle = load(os.path.join(d, f"{name}-{states[0]}.png")) if states else None
main, shadow, ground = (load(os.path.join(d, f"{name}{s}.png")) for s in ("", "-shadow", "-ground"))
shift = (0, 0)
m = re.search(r'\["%s"\] = \{shift = \{([-\d.]+), ([-\d.]+)\}' % re.escape(name), open(os.path.join(ROOT, "prototypes", "art.lua")).read())
if m:
    shift = (float(m.group(1)) * T, float(m.group(2)) * T)

panels = [("lab", None)] + ([("idle", idle)] if idle else []) + [("working", main)]
P = 5 * T
W, H = P * len(panels), P
img = [[grass[y % T][x % T][:3] for x in range(W)] for y in range(H)]


def paste(px, cx, cy):
    if not px:
        return
    h, w = len(px), len(px[0])
    x0, y0 = int(cx - w / 2), int(cy - h / 2)
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[y][x]
            X, Y = x0 + x, y0 + y
            if a and 0 <= X < W and 0 <= Y < H:
                A = a / 255
                o = img[Y][X]
                img[Y][X] = tuple(int(c * A + oc * (1 - A)) for c, oc in zip((r, g, b), o))


for k, (kind, px) in enumerate(panels):
    cx, cy = k * P + P / 2, P / 2
    if kind == "lab":
        paste(lab, cx, cy)
    else:
        paste(ground, cx + shift[0], cy + shift[1])
        paste(shadow, cx + shift[0], cy + shift[1])
        paste(idle or main, cx + shift[0], cy + shift[1])
        if kind == "working" and idle:
            paste(main, cx + shift[0], cy + shift[1])
    for y in range(H):
        img[y][k * P] = (25, 25, 25)
os.makedirs(os.path.join(ROOT, "art", "preview"), exist_ok=True)
out = os.path.join(ROOT, "art", "preview", name + ".png")
png_io.write(out, W, H, img, alpha=False)
print(out)
