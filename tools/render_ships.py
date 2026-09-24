#!/usr/bin/env python3
"""Renders ship sprites for Second Dawn without any 3D software: low-poly models, a tiny z-buffer
rasterizer, Factorio-like oblique view (ground seen from above, heights shifted up), light from the
north-west, and a separate shadow layer. Pure Python (zlib + struct only).

    python3 tools/render_ships.py            # all ships -> graphics/entity/<ship>/, graphics/icons/
    python3 tools/render_ships.py tug        # one ship

Each sheet: 64 directions, 8 x 8 frames, frame 0 facing north, clockwise. Rendered at 2x and box-filtered.
"""
import math
import os
import struct
import sys
import zlib

PPT = 32            # pixels per tile in the sheet (scale 1; 64 would take an hour in pure Python)
SS = 2              # supersampling factor
K = 0.75            # screen height of one tile of elevation, in tiles
DIRECTIONS = 64
LINE = 8
LIGHT = (-0.55, -0.55, 0.63)   # towards the light: north-west and up
AMBIENT = 0.42
OUT = os.path.join(os.path.dirname(__file__), "..", "graphics")


def norm(v):
    l = math.sqrt(sum(c * c for c in v)) or 1
    return tuple(c / l for c in v)


LIGHT = norm(LIGHT)


# ---------- models: lists of (polygon [(x, y, z)...], rgb) in tiles, bow towards -y ----------

def prism(poly2d, z0, z1, top, side, bottom=None):
    """Vertical prism over a convex/concave-safe outline (outline given clockwise seen from above)."""
    faces = []
    n = len(poly2d)
    faces.append(([(x, y, z1) for x, y in poly2d], top))
    for i in range(n):
        (ax, ay), (bx, by) = poly2d[i], poly2d[(i + 1) % n]
        faces.append(([(ax, ay, z0), (bx, by, z0), (bx, by, z1), (ax, ay, z1)], side))
    if bottom:
        faces.append(([(x, y, z0) for x, y in reversed(poly2d)], bottom))
    return faces


def box(x0, y0, x1, y1, z0, z1, top, side):
    return prism([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], z0, z1, top, side)


def cylinder_z(cx, cy, r, z0, z1, top, side, n=10):
    return prism([(cx + r * math.cos(2 * math.pi * i / n), cy + r * math.sin(2 * math.pi * i / n)) for i in range(n)],
                 z0, z1, top, side)


def cylinder_y(cx, cz, r, y0, y1, color, n=12):
    """A tank lying along the ship."""
    faces = []
    pts = [(cx + r * math.cos(2 * math.pi * i / n), cz + r * math.sin(2 * math.pi * i / n)) for i in range(n)]
    for i in range(n):
        (ax, az), (bx, bz) = pts[i], pts[(i + 1) % n]
        faces.append(([(ax, y0, az), (ax, y1, az), (bx, y1, bz), (bx, y0, bz)], color))
    faces.append(([(x, y0, z) for x, z in pts], color))
    faces.append(([(x, y1, z) for x, z in reversed(pts)], color))
    return faces


def hull(length, width, height, bow, hull_color, deck_color, stripe=None):
    """Hull outline with a pointed bow and a rounded stern, flared sides, a deck on top."""
    h, w = length / 2, width / 2
    outline = [(0, -h), (w * 0.55, -h + bow * 0.45), (w, -h + bow), (w, h - 0.5), (w * 0.8, h - 0.1), (w * 0.35, h),
               (-w * 0.35, h), (-w * 0.8, h - 0.1), (-w, h - 0.5), (-w, -h + bow), (-w * 0.55, -h + bow * 0.45)]
    faces = prism(outline, 0, height, deck_color, hull_color)
    if stripe:  # a band along the waterline
        faces += prism([(x * 1.01, y * 1.003) for x, y in outline], 0, height * 0.25, stripe, stripe)
    return faces


def tug():
    f = hull(6.2, 2.3, 0.55, 1.6, (0.12, 0.12, 0.14), (0.55, 0.40, 0.25), stripe=(0.55, 0.12, 0.10))
    f += box(-0.75, -0.3, 0.75, 1.6, 0.55, 1.35, (0.85, 0.83, 0.76), (0.90, 0.88, 0.80))      # cabin
    f += box(-0.55, -0.1, 0.55, 0.9, 1.35, 1.75, (0.35, 0.35, 0.38), (0.80, 0.78, 0.72))      # wheelhouse
    f += cylinder_z(0, 1.9, 0.32, 1.0, 2.5, (0.08, 0.08, 0.08), (0.12, 0.12, 0.12))           # funnel
    f += cylinder_z(0, 1.9, 0.34, 2.05, 2.3, (0.6, 0.1, 0.08), (0.6, 0.12, 0.09))            # funnel band
    f += box(-0.25, -2.2, 0.25, -1.6, 0.55, 0.75, (0.3, 0.3, 0.3), (0.25, 0.25, 0.25))        # winch
    return f


def barge():
    f = hull(6.2, 2.4, 0.45, 0.9, (0.30, 0.22, 0.15), (0.50, 0.37, 0.22), stripe=(0.2, 0.15, 0.1))
    crate = [((0.62, 0.48, 0.28), (0.55, 0.40, 0.22)), ((0.55, 0.45, 0.30), (0.48, 0.38, 0.24))]
    i = 0
    for y in (-1.9, -0.7, 0.5, 1.7):
        for x in (-0.55, 0.55):
            top, side = crate[i % 2]
            f += box(x - 0.45, y - 0.5, x + 0.45, y + 0.5, 0.45, 1.05 + 0.1 * (i % 3), top, side)
            i += 1
    return f


def fluid_barge():
    f = hull(6.2, 2.4, 0.45, 0.9, (0.18, 0.20, 0.24), (0.35, 0.36, 0.38), stripe=(0.55, 0.45, 0.10))
    f += cylinder_y(0, 1.05, 0.62, -2.2, 2.2, (0.82, 0.78, 0.66))
    for y in (-1.5, 0, 1.5):
        f += box(-0.7, y - 0.08, 0.7, y + 0.08, 0.45, 0.8, (0.3, 0.3, 0.32), (0.25, 0.25, 0.28))   # saddles
    return f


def steamer():
    f = hull(6.4, 2.3, 0.6, 1.9, (0.18, 0.24, 0.32), (0.62, 0.60, 0.55), stripe=(0.8, 0.8, 0.78))
    f += box(-0.8, -0.8, 0.8, 1.9, 0.6, 1.3, (0.80, 0.80, 0.76), (0.88, 0.88, 0.84))
    f += box(-0.6, -0.6, 0.6, 0.4, 1.3, 1.75, (0.3, 0.32, 0.36), (0.82, 0.82, 0.78))
    for y in (0.7, 1.6):
        f += cylinder_z(0, y, 0.28, 1.2, 2.55, (0.08, 0.08, 0.08), (0.12, 0.12, 0.12))
        f += cylinder_z(0, y, 0.30, 2.15, 2.35, (0.85, 0.7, 0.2), (0.85, 0.7, 0.2))
    return f


MODELS = {"tug": tug, "barge": barge, "fluid-barge": fluid_barge, "screw-steamer": steamer}


# ---------- rendering ----------

def rotate(p, a):
    x, y, z = p
    c, s = math.cos(a), math.sin(a)
    return (x * c - y * s, x * s + y * c, z)


def face_normal(pts):
    (ax, ay, az), (bx, by, bz), (cx, cy, cz) = pts[0], pts[1], pts[2]
    ux, uy, uz = bx - ax, by - ay, bz - az
    vx, vy, vz = cx - ax, cy - ay, cz - az
    return norm((uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx))


def raster_tri(buf, zb, w, h, a, b, c, color, depth):
    """a, b, c: screen (x, y, depth) in pixels. Fills color where closer (larger depth wins)."""
    minx, maxx = max(0, int(min(a[0], b[0], c[0]))), min(w - 1, int(max(a[0], b[0], c[0])) + 1)
    miny, maxy = max(0, int(min(a[1], b[1], c[1]))), min(h - 1, int(max(a[1], b[1], c[1])) + 1)
    area = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
    if abs(area) < 1e-9:
        return
    for py in range(miny, maxy + 1):
        fy = py + 0.5
        row = py * w
        for px in range(minx, maxx + 1):
            fx = px + 0.5
            w0 = ((b[0] - fx) * (c[1] - fy) - (b[1] - fy) * (c[0] - fx)) / area
            w1 = ((c[0] - fx) * (a[1] - fy) - (c[1] - fy) * (a[0] - fx)) / area
            w2 = 1 - w0 - w1
            if w0 < 0 or w1 < 0 or w2 < 0:
                continue
            d = w0 * a[2] + w1 * b[2] + w2 * c[2] if depth else 0
            i = row + px
            if depth and d <= zb[i]:
                continue
            zb[i] = d
            buf[i] = color


def render_frame(faces, angle, size, shadow):
    """Returns a list of RGBA tuples (None = transparent) of size*size pixels at SS resolution."""
    n = size * size
    buf, zb = [None] * n, [-1e9] * n
    ppt = PPT * SS
    cx, cy = size / 2, size / 2
    for pts, rgb in faces:
        pts = [rotate(p, angle) for p in pts]
        if shadow:
            # project onto the ground along the light
            proj = [((x - z * LIGHT[0] / LIGHT[2]) * ppt + cx, (y - z * LIGHT[1] / LIGHT[2]) * ppt + cy, 0) for x, y, z in pts]
            color = (0, 0, 0, 170)
            for i in range(1, len(proj) - 1):
                raster_tri(buf, zb, size, size, proj[0], proj[i], proj[i + 1], color, False)
            continue
        nrm = face_normal(pts)
        # back faces: the view direction is towards the south and up: (0, K, 1)
        view = norm((0, K, 1))
        if nrm[0] * view[0] + nrm[1] * view[1] + nrm[2] * view[2] <= 0:
            continue
        lum = AMBIENT + (1 - AMBIENT) * max(0.0, sum(nrm[i] * LIGHT[i] for i in range(3)))
        color = tuple(min(255, int(c * lum * 255)) for c in rgb) + (255,)
        scr = [(x * ppt + cx, (y - K * z) * ppt + cy, K * y + z) for x, y, z in pts]
        for i in range(1, len(scr) - 1):
            raster_tri(buf, zb, size, size, scr[0], scr[i], scr[i + 1], color, True)
    return buf


def downsample(buf, size):
    out, s = [], size // SS
    for y in range(s):
        for x in range(s):
            r = g = b = a = 0
            for dy in range(SS):
                for dx in range(SS):
                    p = buf[(y * SS + dy) * size + x * SS + dx]
                    if p:
                        r += p[0] * p[3]; g += p[1] * p[3]; b += p[2] * p[3]; a += p[3]
            k = SS * SS
            out.append((int(r / a), int(g / a), int(b / a), int(a / k)) if a else (0, 0, 0, 0))
    return out


def write_png(path, w, h, pixels):
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        for x in range(w):
            raw.extend(pixels[y * w + x])
    def chunk(t, b):
        return struct.pack(">I", len(b)) + t + b + struct.pack(">I", zlib.crc32(t + b))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b""))


def render_sheet(name, frame_tiles=8):
    global PPT
    faces = MODELS[name]()
    frame = frame_tiles * PPT
    lines = DIRECTIONS // LINE
    for layer in ("", "-shadow"):
        sheet = [(0, 0, 0, 0)] * (frame * LINE * frame * lines)
        W = frame * LINE
        for d in range(DIRECTIONS):
            px = downsample(render_frame(faces, 2 * math.pi * d / DIRECTIONS, frame * SS, layer == "-shadow"), frame * SS)
            ox, oy = (d % LINE) * frame, (d // LINE) * frame
            for y in range(frame):
                base = (oy + y) * W + ox
                sheet[base:base + frame] = px[y * frame:(y + 1) * frame]
        write_png(os.path.join(OUT, "entity", name, name + layer + ".png"), W, frame * lines, sheet)
    # icon: one three-quarter view, 64 px
    saved, PPT = PPT, 64 // frame_tiles * 1.6
    icon_size = 64
    px = downsample(render_frame(faces, 2 * math.pi * 8 / DIRECTIONS, icon_size * SS, False), icon_size * SS)
    PPT = saved
    write_png(os.path.join(OUT, "icons", name + ".png"), icon_size, icon_size, px)
    print(name, "done", W, "x", frame * lines)


if __name__ == "__main__":
    names = sys.argv[1:] or list(MODELS)
    for n in names:
        render_sheet(n)
