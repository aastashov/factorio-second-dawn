#!/usr/bin/env python3
"""Draws Second Dawn's item icons procedurally: a tiny 2D painter (polygons, shaded blobs lit from the
top left, strokes), a dark outline like vanilla icons, 4x supersampling. Pure Python.

    python3 tools/render_icons.py              # all icons -> graphics/icons/<name>.png (64 x 64)
    python3 tools/render_icons.py fiber rope   # some
    python3 tools/render_icons.py --sheet      # also docs/img/icons.png, all icons on one sheet
"""
import math
import os
import struct
import sys
import zlib

S = 4                  # supersampling
N = 64 * S
OUT = os.path.join(os.path.dirname(__file__), "..", "graphics", "icons")
LIGHT = (-0.5, -0.6, 0.62)


def clamp(v):
    return max(0, min(255, int(v)))


def mix(c, k):
    """Scale a colour's brightness by k (k > 1 lightens towards white)."""
    if k <= 1:
        return tuple(clamp(x * k) for x in c)
    return tuple(clamp(x + (255 - x) * (k - 1)) for x in c)


def hexc(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


class Canvas:
    def __init__(self):
        self.px = [None] * (N * N)   # (r, g, b, a) straight alpha, a 0..1

    def put(self, x, y, rgb, a=1.0):
        if 0 <= x < N and 0 <= y < N and a > 0:
            i = y * N + x
            old = self.px[i]
            if old is None or a >= 1:
                self.px[i] = (rgb[0], rgb[1], rgb[2], a)
                return
            oa = old[3]
            na = a + oa * (1 - a)
            self.px[i] = tuple((rgb[j] * a + old[j] * oa * (1 - a)) / na for j in range(3)) + (na,)

    # ---- shapes (coordinates in icon pixels 0..64) ----
    def poly(self, pts, rgb, shade=0.35, alpha=1.0, flat=False):
        pts = [(x * S, y * S) for x, y in pts]
        minx, maxx = int(min(p[0] for p in pts)), int(max(p[0] for p in pts)) + 1
        miny, maxy = int(min(p[1] for p in pts)), int(max(p[1] for p in pts)) + 1
        w, h = max(1, maxx - minx), max(1, maxy - miny)
        n = len(pts)
        for y in range(max(0, miny), min(N, maxy + 1)):
            fy = y + 0.5
            xs = []
            for i in range(n):
                (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
                if (y0 <= fy < y1) or (y1 <= fy < y0):
                    xs.append(x0 + (fy - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            for k in range(0, len(xs) - 1, 2):
                for x in range(max(0, int(xs[k] + 0.5)), min(N, int(xs[k + 1] + 0.5))):
                    if flat:
                        c = rgb
                    else:
                        t = 0.5 * (x - minx) / w + 0.5 * (y - miny) / h
                        c = mix(rgb, 1 + shade * 0.5 - shade * t)
                    self.put(x, y, c, alpha)

    def rect(self, x0, y0, x1, y1, rgb, **kw):
        self.poly([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], rgb, **kw)

    def blob(self, cx, cy, rx, ry, rgb, spec=0.35, alpha=1.0, rot=0.0):
        """An ellipse shaded like a lit dome."""
        cxs, cys, rxs, rys = cx * S, cy * S, rx * S, ry * S
        c, s = math.cos(rot), math.sin(rot)
        r = max(rxs, rys)
        for y in range(max(0, int(cys - r - 1)), min(N, int(cys + r + 2))):
            for x in range(max(0, int(cxs - r - 1)), min(N, int(cxs + r + 2))):
                dx, dy = x + 0.5 - cxs, y + 0.5 - cys
                u, v = (dx * c + dy * s) / rxs, (-dx * s + dy * c) / rys
                d = u * u + v * v
                if d > 1:
                    continue
                nz = math.sqrt(1 - d)
                lum = 0.45 + 0.75 * max(0, -0.5 * u - 0.6 * v + 0.62 * nz)
                hl = spec * max(0, (-0.45 * u - 0.55 * v + 0.7 * nz)) ** 12
                col = mix(rgb, lum)
                col = tuple(clamp(col[i] + 255 * hl) for i in range(3))
                self.put(x, y, col, alpha)

    def line(self, pts, width, rgb, alpha=1.0):
        """A polyline of round-capped segments; width in icon pixels."""
        r = width * S / 2
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            x0, y0, x1, y1 = x0 * S, y0 * S, x1 * S, y1 * S
            dx, dy = x1 - x0, y1 - y0
            ll = dx * dx + dy * dy or 1
            for y in range(max(0, int(min(y0, y1) - r - 1)), min(N, int(max(y0, y1) + r + 2))):
                for x in range(max(0, int(min(x0, x1) - r - 1)), min(N, int(max(x0, x1) + r + 2))):
                    t = max(0, min(1, ((x + 0.5 - x0) * dx + (y + 0.5 - y0) * dy) / ll))
                    px, py = x0 + t * dx - x - 0.5, y0 + t * dy - y - 0.5
                    if px * px + py * py <= r * r:
                        self.put(x, y, rgb, alpha)

    def arc(self, cx, cy, r, a0, a1, width, rgb, steps=24, alpha=1.0):
        pts = [(cx + r * math.cos(a0 + (a1 - a0) * i / steps), cy + r * math.sin(a0 + (a1 - a0) * i / steps)) for i in range(steps + 1)]
        self.line(pts, width, rgb, alpha)

    # ---- finish: dark outline, downsample, PNG ----
    def finish(self, path, outline=(28, 24, 20)):
        R = int(1.1 * S)
        mask = [p is not None and p[3] > 0.35 for p in self.px]
        ring = [False] * (N * N)
        for y in range(N):
            for x in range(N):
                if mask[y * N + x]:
                    continue
                hit = False
                for dy in range(-R, R + 1):
                    yy = y + dy
                    if not 0 <= yy < N:
                        continue
                    for dx in range(-R, R + 1):
                        xx = x + dx
                        if 0 <= xx < N and dx * dx + dy * dy <= R * R and mask[yy * N + xx]:
                            hit = True
                            break
                    if hit:
                        break
                ring[y * N + x] = hit
        out = bytearray()
        for y in range(64):
            out.append(0)
            for x in range(64):
                r = g = b = a = 0.0
                for dy in range(S):
                    for dx in range(S):
                        i = (y * S + dy) * N + x * S + dx
                        p = self.px[i]
                        if p is not None:
                            pa = p[3]
                            r += p[0] * pa; g += p[1] * pa; b += p[2] * pa; a += pa
                        elif ring[i]:
                            r += outline[0] * 0.85; g += outline[1] * 0.85; b += outline[2] * 0.85; a += 0.85
                k = S * S
                if a:
                    out.extend((clamp(r / a), clamp(g / a), clamp(b / a), clamp(255 * a / k)))
                else:
                    out.extend((0, 0, 0, 0))
        def chunk(t, body):
            return struct.pack(">I", len(body)) + t + body + struct.pack(">I", zlib.crc32(t + body))
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 64, 64, 8, 6, 0, 0, 0))
                    + chunk(b"IDAT", zlib.compress(bytes(out), 9)) + chunk(b"IEND", b""))
        return bytes(out)


# ---------------------------------------------------------------------------------------------------
# Reusable pieces
# ---------------------------------------------------------------------------------------------------

def chunks(c, color, spots=None):
    """A heap of three ore/lump chunks."""
    for cx, cy, rx, ry, rot in ((22, 40, 15, 12, 0.3), (43, 42, 14, 11, -0.2), (32, 24, 14, 11, 0.1)):
        c.blob(cx, cy, rx, ry, color, rot=rot)
    for sx, sy, sr, sc in spots or []:
        c.blob(sx, sy, sr, sr, sc, spec=0.6)


def crystals(c, color):
    for pts in ([(14, 50), (22, 18), (32, 50)], [(26, 52), (36, 10), (46, 52)], [(40, 52), (48, 26), (56, 52)]):
        c.poly(pts, color, shade=0.6)
        (x0, y0), (x1, y1), (x2, y2) = pts
        c.poly([(x1, y1), (x2, y2), ((x0 + x2) / 2, y0)], mix(color, 0.8), shade=0.3)


def pile(c, color, grains=None):
    c.poly([(6, 54), (18, 34), (30, 22), (40, 26), (50, 38), (58, 54)], color, shade=0.45)
    for gx, gy in grains or []:
        c.blob(gx, gy, 1.6, 1.6, mix(color, 0.7), spec=0)


def ingot(c, color):
    c.poly([(8, 44), (18, 30), (56, 30), (50, 44)], mix(color, 1.25), shade=0.2)     # top
    c.poly([(8, 44), (50, 44), (50, 54), (8, 54)], color, shade=0.25)                # front
    c.poly([(50, 44), (56, 30), (56, 40), (50, 54)], mix(color, 0.7), shade=0.2)     # side


def jug(c, liquid=None, body=hexc("b86b42")):
    c.blob(32, 40, 17, 18, body, spec=0.25)
    c.rect(26, 12, 38, 26, mix(body, 0.9))
    c.blob(32, 12, 8, 3, mix(body, 1.15), spec=0)
    c.arc(40, 22, 8, -1.6, 1.4, 3.5, mix(body, 0.8))          # handle
    if liquid:
        c.poly([(18, 36), (46, 36), (48, 44), (16, 44)], liquid, shade=0.2, alpha=0.95)
        c.blob(32, 12, 5, 2, liquid, spec=0)


def bottle(c, liquid=None, glass=hexc("bfe6ee")):
    c.poly([(20, 58), (44, 58), (46, 30), (38, 22), (38, 8), (26, 8), (26, 22), (18, 30)], glass, shade=0.25, alpha=0.55)
    if liquid:
        c.poly([(20, 58), (44, 58), (45, 38), (19, 38)], liquid, shade=0.3)
    c.line([(23, 32), (22, 52)], 2.5, (255, 255, 255), alpha=0.7)
    c.rect(25, 4, 39, 9, hexc("7a5a3a"))                       # cork


def flask(c, liquid):
    c.poly([(8, 58), (56, 58), (40, 28), (40, 8), (24, 8), (24, 28)], hexc("d8f0f4"), shade=0.2, alpha=0.5)
    c.poly([(9, 57), (55, 57), (46, 40), (18, 40)], liquid, shade=0.35)
    c.line([(28, 12), (28, 30), (16, 52)], 2.2, (255, 255, 255), alpha=0.7)
    c.rect(22, 4, 42, 9, hexc("8a8a8a"))


def drop(c, color, dots):
    c.poly([(32, 4), (46, 26), (50, 38), (32, 58), (14, 38), (18, 26)], color, shade=0.5)
    c.blob(32, 40, 16, 16, color, spec=0.5)
    c.blob(26, 34, 4, 6, (255, 255, 255), spec=0, alpha=0.5)
    for i in range(dots):
        x = 32 + (i - (dots - 1) / 2) * 8
        c.blob(x, 60, 3, 3, (250, 250, 250), spec=0)


def garment(c, color, collar=None, hood=False):
    c.poly([(18, 12), (46, 12), (58, 26), (52, 32), (48, 26), (48, 58), (16, 58), (16, 26), (12, 32), (6, 26)], color, shade=0.4)
    c.line([(32, 16), (32, 56)], 1.5, mix(color, 0.6))
    if collar:
        c.blob(24, 14, 9, 6, collar, spec=0.1)
        c.blob(40, 14, 9, 6, collar, spec=0.1)
    if hood:
        c.blob(32, 12, 12, 10, mix(color, 0.9), spec=0.1)
        c.blob(32, 14, 6, 6, mix(color, 0.4), spec=0)


def gear(c, cx, cy, r, color, teeth=10):
    pts = []
    for i in range(teeth * 2):
        a = math.pi * i / teeth
        rr = r if i % 2 == 0 else r * 0.78
        a0, a1 = a - math.pi / teeth / 2, a + math.pi / teeth / 2
        pts += [(cx + rr * math.cos(a0), cy + rr * math.sin(a0)), (cx + rr * math.cos(a1), cy + rr * math.sin(a1))]
    c.poly(pts, color, shade=0.5)
    c.blob(cx, cy, r * 0.28, r * 0.28, mix(color, 0.45), spec=0)


# ---------------------------------------------------------------------------------------------------
# Icons
# ---------------------------------------------------------------------------------------------------
ICONS = {}


def icon(name):
    def reg(f):
        ICONS[name] = f
        return f
    return reg


@icon("sd-clay")
def _(c): chunks(c, hexc("b8633f"))

@icon("sd-shells")
def _(c):
    for cx, cy, s, col in ((22, 38, 1.0, hexc("f2d8c8")), (42, 30, 0.85, hexc("f6e4d4"))):
        pts = [(cx, cy + 16 * s)]
        for i in range(9):
            a = math.pi * (1.1 + 0.8 * i / 8)
            pts.append((cx + 18 * s * math.cos(a) * 1.0, cy + 18 * s * math.sin(a) * 0.9 + 4 * s))
        c.poly(pts, col, shade=0.35)
        for i in range(1, 8):
            a = math.pi * (1.1 + 0.8 * i / 8)
            c.line([(cx, cy + 14 * s), (cx + 16 * s * math.cos(a), cy + 16 * s * math.sin(a) * 0.9 + 4 * s)], 1.2, mix(col, 0.7))

@icon("sd-saltpeter")
def _(c): crystals(c, hexc("e8eef4"))

@icon("sd-fruit")
def _(c):
    for cx, cy, r in ((22, 40, 14), (42, 36, 13)):
        c.blob(cx, cy, r, r, hexc("c8302c"), spec=0.6)
        c.line([(cx, cy - r + 2), (cx + 2, cy - r - 5)], 2, hexc("5a3a1a"))
    c.poly([(44, 22), (56, 14), (52, 24)], hexc("4c9a2a"), shade=0.3)

@icon("sd-fiber")
def _(c):
    col = hexc("b6c46a")
    for i in range(9):
        x0 = 18 + i * 3.6
        c.line([(x0, 58), (x0 + (i - 4) * 0.8, 36), (x0 + (i - 4) * 2.2, 8 + abs(i - 4) * 2)], 2.2, mix(col, 0.85 + 0.05 * (i % 3)))
    c.rect(18, 34, 48, 40, hexc("8a6a3a"))

@icon("sd-rope")
def _(c):
    col = hexc("b89060")
    for i, r in enumerate((22, 16, 10)):
        c.arc(32, 34, r, 0, 2 * math.pi, 6, mix(col, 1.0 - 0.1 * i), steps=40)
    for k in range(18):
        a = 2 * math.pi * k / 18
        x, y = 32 + 22 * math.cos(a), 34 + 22 * math.sin(a)
        c.line([(x - 2, y - 2), (x + 2, y + 2)], 1.2, mix(col, 0.6))
    c.line([(50, 46), (58, 58)], 5, col)

@icon("sd-charcoal")
def _(c):
    for pts in ([(8, 50), (14, 30), (30, 26), (34, 46), (22, 56)], [(28, 48), (34, 22), (52, 18), (58, 40), (44, 54)]):
        c.poly(pts, hexc("2a2622"), shade=0.9)
    c.line([(18, 34), (28, 44)], 1.5, hexc("5a4030"))
    c.line([(40, 26), (50, 40)], 1.5, hexc("5a4030"))

@icon("sd-brick")
def _(c):
    for dy in (0, -14):
        col = hexc("b24a2c")
        c.poly([(8, 42 + dy), (20, 32 + dy), (56, 32 + dy), (46, 42 + dy)], mix(col, 1.2), shade=0.2)
        c.poly([(8, 42 + dy), (46, 42 + dy), (46, 52 + dy), (8, 52 + dy)], col, shade=0.2)
        c.poly([(46, 42 + dy), (56, 32 + dy), (56, 42 + dy), (46, 52 + dy)], mix(col, 0.65), shade=0.1)

@icon("sd-quicklime")
def _(c): pile(c, hexc("f2f0e6"), [(24, 44), (36, 36), (44, 46), (30, 50)])

@icon("sd-mortar")
def _(c):
    c.poly([(10, 58), (54, 58), (48, 30), (16, 30)], hexc("8a7a6a"), shade=0.3)      # tub
    c.blob(32, 30, 16, 5, hexc("b8b2a4"), spec=0.1)                                 # mortar
    c.poly([(36, 30), (56, 8), (60, 12), (40, 32)], hexc("9aa4ac"), shade=0.4)       # trowel

@icon("sd-jug")
def _(c): jug(c)

@icon("sd-mash-jug")
def _(c): jug(c, hexc("b08030"))

@icon("sd-spirit-jug")
def _(c): jug(c, hexc("d8ecff"))

@icon("sd-acid-jug")
def _(c): jug(c, hexc("f0c030"))

@icon("sd-clay-tablet")
def _(c):
    c.poly([(10, 20), (46, 8), (56, 44), (20, 56)], hexc("c8844e"), shade=0.35)
    for i in range(5):
        y = 20 + i * 7
        for j in range(4):
            x = 18 + j * 8 + i * 1.8
            c.poly([(x, y + i * 0.6), (x + 4, y - 1 + i * 0.6), (x + 1, y + 3 + i * 0.6)], hexc("6a3a1e"), flat=True)

@icon("sd-tin-ore")
def _(c): chunks(c, hexc("a8b0b8"), [(20, 38, 2.5, hexc("e8eef4")), (40, 44, 2, hexc("e8eef4"))])

@icon("sd-sand")
def _(c): pile(c, hexc("e2c27a"), [(20, 46), (32, 34), (44, 44), (38, 50), (26, 52)])

@icon("sd-ash")
def _(c): pile(c, hexc("8a8886"), [(24, 46), (36, 38), (44, 48)])

@icon("sd-potash")
def _(c):
    pile(c, hexc("d8d4cc"))
    crystals_small = ((22, 42), (34, 32), (44, 44))
    for x, y in crystals_small:
        c.poly([(x - 4, y + 4), (x, y - 5), (x + 4, y + 4)], hexc("f4f4f0"), shade=0.5)

@icon("sd-tin")
def _(c): ingot(c, hexc("b4bcc4"))

@icon("sd-bronze")
def _(c): ingot(c, hexc("c07a38"))

@icon("sd-tungsten")
def _(c): ingot(c, hexc("6a7078"))

@icon("sd-glass")
def _(c):
    c.poly([(8, 50), (22, 10), (56, 14), (42, 54)], hexc("bfe8f0"), shade=0.3, alpha=0.7)
    c.line([(24, 18), (18, 36)], 2.5, (255, 255, 255), alpha=0.85)
    c.line([(30, 18), (27, 26)], 2, (255, 255, 255), alpha=0.85)

@icon("sd-bottle")
def _(c): bottle(c)

@icon("sd-rectified-bottle")
def _(c): bottle(c, hexc("dff2ff"))

@icon("sd-conc-acid-bottle")
def _(c): bottle(c, hexc("f08a20"))

@icon("sd-ether-bottle")
def _(c):
    bottle(c, hexc("e8e0ff"))
    for x, y in ((46, 14), (50, 8), (42, 6)):
        c.blob(x, y, 3, 3, (240, 240, 255), spec=0, alpha=0.6)

@icon("sd-glass-flask")
def _(c): flask(c, hexc("58c85a"))

@icon("sd-reactive")
def _(c):
    for x, col in ((14, hexc("f0c030")), (30, hexc("e06a2a")), (46, hexc("f0e060"))):
        c.poly([(x, 8), (x + 10, 8), (x + 10, 50), (x + 5, 56), (x, 50)], hexc("d8f0f4"), shade=0.2, alpha=0.5)
        c.poly([(x, 30), (x + 10, 30), (x + 10, 50), (x + 5, 56), (x, 50)], col, shade=0.35)
    c.rect(8, 42, 60, 48, hexc("7a5a3a"))

@icon("sd-navigation")
def _(c):
    c.blob(32, 32, 26, 26, hexc("d8c8a0"), spec=0.2)
    c.blob(32, 32, 20, 20, hexc("f0e8d4"), spec=0.1)
    c.poly([(32, 10), (37, 32), (32, 54), (27, 32)], hexc("c83028"), shade=0.2)
    c.poly([(10, 32), (32, 27), (54, 32), (32, 37)], hexc("405878"), shade=0.2)
    c.blob(32, 32, 3, 3, hexc("303030"), spec=0)

@icon("sd-mechanism")
def _(c):
    gear(c, 26, 28, 20, hexc("9aa0a6"))
    gear(c, 46, 46, 13, hexc("c08a4a"), teeth=8)

@icon("sd-board")
def _(c):
    c.poly([(6, 14), (58, 14), (58, 52), (6, 52)], hexc("2a8a44"), shade=0.3)
    for y in (22, 30, 38, 46):
        c.line([(10, y), (22, y), (28, y - 4), (54, y - 4)], 1.5, hexc("d8b050"))
    c.rect(26, 22, 40, 36, hexc("222222"))
    c.blob(48, 42, 4, 4, hexc("c0c0c0"), spec=0.5)

@icon("sd-control-unit")
def _(c):
    for i in range(6):
        x = 16 + i * 6.4
        c.rect(x, 6, x + 3, 14, hexc("c0c0c0"), flat=True)
        c.rect(x, 50, x + 3, 58, hexc("c0c0c0"), flat=True)
    c.rect(10, 12, 54, 52, hexc("2c2c34"), shade=0.4)
    c.rect(22, 24, 42, 40, hexc("5a8ad0"), shade=0.3)

@icon("sd-electrode")
def _(c):
    c.line([(32, 60), (32, 30)], 5, hexc("c87a3a"))
    c.blob(32, 20, 14, 16, hexc("dff4ff"), spec=0.6, alpha=0.6)
    c.line([(28, 30), (28, 14), (36, 14), (36, 30)], 1.5, hexc("f0a050"))

@icon("sd-tungsten-electrode")
def _(c):
    c.line([(32, 60), (32, 30)], 5, hexc("707880"))
    c.blob(32, 20, 14, 16, hexc("dff4ff"), spec=0.6, alpha=0.6)
    c.line([(28, 30), (28, 14), (36, 14), (36, 30)], 1.5, hexc("fff0a0"))

@icon("sd-meat")
def _(c):
    c.blob(28, 34, 22, 16, hexc("c83a3a"), spec=0.4, rot=0.4)
    c.blob(26, 32, 14, 9, hexc("e87a7a"), spec=0.2, rot=0.4)
    c.line([(44, 44), (58, 56)], 5, hexc("f0e8d8"))
    c.blob(58, 56, 4, 4, hexc("f0e8d8"), spec=0)

@icon("sd-cooked-meat")
def _(c):
    c.blob(28, 30, 20, 16, hexc("8a4a24"), spec=0.5, rot=0.5)
    c.line([(40, 42), (56, 58)], 5, hexc("f0e8d8"))
    c.blob(56, 58, 4, 4, hexc("f0e8d8"), spec=0)
    for x, y in ((20, 24), (30, 34), (24, 38)):
        c.line([(x - 4, y), (x + 4, y - 3)], 1.5, hexc("4a2410"))

@icon("sd-hide")
def _(c):
    c.poly([(10, 14), (22, 20), (42, 20), (54, 14), (50, 30), (56, 50), (42, 46), (32, 58), (22, 46), (8, 50), (14, 30)],
           hexc("a8764a"), shade=0.35)
    c.blob(32, 34, 10, 12, hexc("c09060"), spec=0)

@icon("sd-bones")
def _(c):
    for (x0, y0, x1, y1) in ((12, 50, 52, 14), (12, 14, 52, 50)):
        c.line([(x0, y0), (x1, y1)], 6, hexc("ece4d2"))
        for x, y in ((x0, y0), (x1, y1)):
            c.blob(x - 2, y - 2, 4.5, 4.5, hexc("ece4d2"), spec=0.1)
            c.blob(x + 2, y + 2, 4.5, 4.5, hexc("ece4d2"), spec=0.1)

@icon("sd-leather")
def _(c):
    c.poly([(6, 22), (46, 14), (58, 42), (18, 50)], hexc("8a5230"), shade=0.35)
    c.poly([(18, 50), (58, 42), (56, 50), (18, 58)], hexc("6a3a20"), shade=0.2)
    c.line([(12, 26), (44, 20)], 1.2, hexc("c89060"), alpha=0.6)

@icon("sd-bone-meal")
def _(c):
    c.poly([(12, 58), (52, 58), (56, 30), (44, 18), (20, 18), (8, 30)], hexc("c8b890"), shade=0.35)   # sack
    c.blob(32, 18, 12, 5, hexc("f4f0e8"), spec=0)
    c.line([(20, 22), (44, 22)], 2, hexc("7a6040"))

@icon("sd-feed")
def _(c):
    c.poly([(12, 58), (52, 58), (56, 30), (44, 18), (20, 18), (8, 30)], hexc("b89a5a"), shade=0.35)
    for x, y in ((26, 16), (32, 12), (38, 16), (30, 18), (36, 18)):
        c.blob(x, y, 3, 2, hexc("e0c060"), spec=0.2)
    c.line([(20, 22), (44, 22)], 2, hexc("6a5030"))

@icon("sd-bow")
def _(c):
    c.arc(8, 32, 40, -1.1, 1.1, 5, hexc("8a5a2c"))
    c.line([(8 + 40 * math.cos(-1.1), 32 + 40 * math.sin(-1.1)), (8 + 40 * math.cos(1.1), 32 + 40 * math.sin(1.1))], 1.2, hexc("e8e0c8"))

def arrows(c, tip):
    for i in range(3):
        d = i * 7
        c.line([(10 + d, 56 - d * 0.2), (46 + d * 0.6, 12 + d * 0.2)], 2.2, hexc("a87a4a"))
        tx, ty = 46 + d * 0.6, 12 + d * 0.2
        c.poly([(tx + 7, ty - 7), (tx - 1, ty - 1), (tx + 2, ty + 2)], tip, shade=0.2)
        c.poly([(10 + d, 56 - d * 0.2), (6 + d, 50 - d * 0.2), (14 + d, 54 - d * 0.2)], hexc("e8e8e0"), shade=0.1)

@icon("sd-stone-arrows")
def _(c): arrows(c, hexc("7e7a74"))

@icon("sd-bone-arrows")
def _(c): arrows(c, hexc("f0e8d4"))

@icon("sd-arrows")
def _(c): arrows(c, hexc("c07a38"))

@icon("sd-leather-jacket")
def _(c): garment(c, hexc("8a5230"))

@icon("sd-fur-coat")
def _(c): garment(c, hexc("7a5a40"), collar=hexc("eee8dc"))

@icon("sd-light-cloak")
def _(c): garment(c, hexc("e2d4a8"), hood=True)

@icon("sd-spacesuit")
def _(c):
    garment(c, hexc("e8e8ec"))
    c.blob(32, 16, 13, 12, hexc("e8e8ec"), spec=0.3)
    c.blob(32, 17, 9, 7, hexc("2a3a5a"), spec=0.8)

@icon("sd-oxygen-tank")
def _(c):
    c.rect(20, 14, 44, 58, hexc("4a8ac8"), shade=0.5)
    c.blob(32, 14, 12, 5, hexc("6aa8e0"), spec=0.3)
    c.rect(28, 4, 36, 12, hexc("a0a0a0"))
    c.rect(22, 30, 42, 38, hexc("f0f0f0"), flat=True)

@icon("sd-palisade")
def _(c):
    for i in range(5):
        x = 8 + i * 10
        c.poly([(x, 58), (x + 8, 58), (x + 8, 18 + (i % 2) * 4), (x + 4, 8 + (i % 2) * 4), (x, 18 + (i % 2) * 4)], hexc("9a6a3a"), shade=0.4)
    c.rect(6, 34, 58, 38, hexc("6a4a2a"))

@icon("sd-crossbow")
def _(c):
    c.line([(32, 60), (32, 16)], 5, hexc("7a5030"))
    c.arc(32, 44, 26, -2.4, -0.74, 4, hexc("8a8a8a"))
    c.line([(32 + 26 * math.cos(-2.4), 44 + 26 * math.sin(-2.4)), (32, 34), (32 + 26 * math.cos(-0.74), 44 + 26 * math.sin(-0.74))], 1.2, hexc("e8e0c8"))

@icon("sd-net")
def _(c):
    c.blob(32, 34, 24, 22, hexc("b89060"), spec=0.1, alpha=0.25)
    for i in range(-3, 4):
        c.arc(32 + i * 7, 34, 24, -1.3, 1.3, 1.3, hexc("b89060"), steps=12)
        c.line([(10, 34 + i * 6.5), (54, 34 + i * 6.5)], 1.3, hexc("b89060"))
    c.blob(32, 10, 4, 4, hexc("8a6a3a"), spec=0)

@icon("sd-pitch")
def _(c):
    c.poly([(12, 58), (52, 58), (56, 26), (8, 26)], hexc("6a4a2a"), shade=0.3)        # pot
    c.blob(32, 26, 24, 7, hexc("141210"), spec=0.9)
    c.line([(42, 22), (44, 32), (42, 40)], 3, hexc("141210"))

@icon("sd-briquettes")
def _(c):
    for x, y in ((18, 44), (40, 44), (29, 28)):
        c.blob(x, y, 12, 9, hexc("3a302a"), spec=0.3)
        c.line([(x - 6, y), (x + 6, y)], 1.2, hexc("6a5040"))

@icon("sd-latex")
def _(c):
    c.poly([(8, 60), (20, 60), (20, 4), (8, 4)], hexc("7a5a3a"), shade=0.4)          # bark
    c.line([(20, 20), (34, 26)], 2, hexc("5a3a1a"))
    c.poly([(40, 22), (48, 38), (50, 44), (40, 56), (30, 44), (32, 38)], hexc("f4f4ec"), shade=0.2)

@icon("sd-rubber")
def _(c):
    c.blob(32, 36, 22, 20, hexc("2a2a2c"), spec=0.5)
    c.blob(32, 36, 8, 7, hexc("111111"), spec=0)

@icon("sd-fuel-oil")
def _(c):
    c.poly([(12, 60), (52, 60), (52, 20), (40, 8), (12, 8)], hexc("7a2a24"), shade=0.45)   # jerrycan
    c.rect(40, 4, 50, 12, hexc("303030"))
    c.line([(18, 18), (34, 18)], 3, hexc("5a1e1a"))
    c.line([(20, 30), (44, 50)], 2.5, hexc("5a1e1a"))
    c.line([(44, 30), (20, 50)], 2.5, hexc("5a1e1a"))

@icon("sd-waterway")
def _(c):
    c.line([(4, 44), (60, 20)], 1.5, hexc("d8d0b0"))
    for x, y in ((14, 40), (36, 30), (56, 22)):
        c.blob(x, y, 7, 6, hexc("e84a3a") if x != 36 else hexc("f0f0f0"), spec=0.5)

@icon("sd-pier")
def _(c):
    for i in range(5):
        y = 12 + i * 9
        c.poly([(6, y + 6), (12, y), (58, y), (52, y + 6)], hexc("a07a4a"), shade=0.3)
    for x in (12, 50):
        c.rect(x, 8, x + 5, 60, hexc("6a4a2a"))

@icon("sd-buoy")
def _(c):
    c.poly([(20, 44), (44, 44), (38, 16), (26, 16)], hexc("e84a3a"), shade=0.4)
    c.rect(24, 26, 40, 32, hexc("f0f0f0"), flat=True)
    c.blob(32, 12, 5, 5, hexc("ffe060"), spec=0.8)
    c.blob(32, 48, 20, 6, hexc("3a6a8a"), spec=0.2)

@icon("sd-chain-buoy")
def _(c):
    c.poly([(20, 44), (44, 44), (38, 16), (26, 16)], hexc("3a6ae8"), shade=0.4)
    c.rect(24, 26, 40, 32, hexc("f0f0f0"), flat=True)
    c.blob(32, 12, 5, 5, hexc("ffe060"), spec=0.8)
    c.blob(32, 48, 20, 6, hexc("3a6a8a"), spec=0.2)

@icon("sd-note")
def _(c):
    c.poly([(12, 10), (48, 6), (54, 54), (16, 58)], hexc("efe2c0"), shade=0.25)
    for i in range(6):
        y = 16 + i * 6.5
        c.line([(18, y + 0.5 * i), (44, y - 2 + 0.5 * i)], 1.2, hexc("6a5a40"))

# revival charges: a glowing drop, dots for the tier
for tier, col in enumerate(("7ae8c8", "70c8ff", "c09aff", "ffc070", "ffffff"), start=1):
    ICONS["sd-revival-charge-%d" % tier] = (lambda col, tier: lambda c: drop(c, hexc(col), tier))(col, tier)


def render(names, sheet=False):
    done = []
    for name in names:
        # A picture imported with tools/import_art.py replaces the drawn icon.
        if os.path.exists(os.path.join(os.path.dirname(__file__), "..", "art", "incoming", name + ".png")):
            import png_io
            _, _, px = png_io.read(os.path.join(OUT, name + ".png"))
            done.append((name, b"".join(b"\x00" + bytes(v for p in row for v in p) for row in px)))
            print("icon", name, "(imported art)")
            continue
        c = Canvas()
        ICONS[name](c)
        done.append((name, c.finish(os.path.join(OUT, name + ".png"))))
        print("icon", name)
    if sheet:
        cols = 10
        rows = (len(done) + cols - 1) // cols
        W, H = cols * 72, rows * 72
        img = bytearray((46, 46, 50) * W * H)
        for k, (_, raw) in enumerate(done):
            ox, oy = (k % cols) * 72 + 4, (k // cols) * 72 + 4
            for y in range(64):
                row = raw[y * (64 * 4 + 1) + 1:(y + 1) * (64 * 4 + 1)]
                for x in range(64):
                    r, g, b, a = row[x * 4:x * 4 + 4]
                    i = ((oy + y) * W + ox + x) * 3
                    for j, v in enumerate((r, g, b)):
                        img[i + j] = int(v * a / 255 + img[i + j] * (1 - a / 255))
        raw = b"".join(b"\x00" + bytes(img[y * W * 3:(y + 1) * W * 3]) for y in range(H))
        def chunk(t, body):
            return struct.pack(">I", len(body)) + t + body + struct.pack(">I", zlib.crc32(t + body))
        path = os.path.join(os.path.dirname(__file__), "..", "docs", "img", "icons.png")
        with open(path, "wb") as f:
            f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
                    + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))
        print(path)


def write_list():
    """prototypes/generated-icons.lua: names that have a drawn icon (data-final-fixes.lua uses it)."""
    path = os.path.join(os.path.dirname(__file__), "..", "prototypes", "generated-icons.lua")
    with open(path, "w") as f:
        f.write("-- Written by tools/render_icons.py: prototypes with an icon in graphics/icons/<name>.png.\nreturn {\n")
        root = os.path.join(os.path.dirname(__file__), "..")
        imported = {os.path.splitext(n)[0] for n in os.listdir(os.path.join(root, "art", "incoming"))
                    if n.endswith(".png") and os.path.exists(os.path.join(OUT, n))}
        for n in sorted(set(ICONS) | imported):
            f.write('  "%s",\n' % n)
        f.write("}\n")


if __name__ == "__main__":
    write_list()
    args = [a for a in sys.argv[1:] if a != "--sheet"]
    render([a if a.startswith("sd-") else "sd-" + a for a in args] or list(ICONS), sheet="--sheet" in sys.argv)
