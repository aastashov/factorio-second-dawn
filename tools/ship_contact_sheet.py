#!/usr/bin/env python3
"""Contact sheet of the rendered ships: every ship in 8 of its 64 directions, with its shadow, on water.
    python3 tools/ship_contact_sheet.py      # -> docs/img/ships.png
"""
import os
import struct
import zlib

ROOT = os.path.join(os.path.dirname(__file__), "..")
SHIPS = ["tug", "barge", "fluid-barge", "screw-steamer"]
FRAME, LINE, SHOW = 256, 8, [0, 8, 16, 24, 32, 40, 48, 56]
CROP = 32  # trim the empty margin of each frame
WATER = (38, 66, 86)


def read_rgba(path):
    d = open(path, "rb").read()
    pos, idat = 8, b""
    while pos < len(d):
        n, typ = struct.unpack(">I4s", d[pos:pos + 8])
        body = d[pos + 8:pos + 8 + n]
        pos += 12 + n
        if typ == b"IHDR":
            w, h = struct.unpack(">II", body[:8])
        elif typ == b"IDAT":
            idat += body
    raw, stride, rows, prev, i = zlib.decompress(idat), w * 4, [], bytearray(w * 4), 0
    for _ in range(h):
        f, line = raw[i], bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            a = line[x - 4] if x >= 4 else 0
            b, c = prev[x], (prev[x - 4] if x >= 4 else 0)
            if f == 1: line[x] = (line[x] + a) & 255
            elif f == 2: line[x] = (line[x] + b) & 255
            elif f == 3: line[x] = (line[x] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(bytes(line))
        prev = line
    return w, rows


def write_rgb(path, w, h, rows):
    raw = b"".join(b"\x00" + bytes(r) for r in rows)
    def chunk(t, b):
        return struct.pack(">I", len(b)) + t + b + struct.pack(">I", zlib.crc32(t + b))
    open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                          + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


cell = FRAME - 2 * CROP
W, H = cell * len(SHOW), cell * len(SHIPS)
out = [bytearray(WATER * W) for _ in range(H)]
for si, ship in enumerate(SHIPS):
    base = os.path.join(ROOT, "graphics", "entity", ship, ship)
    _, img = read_rgba(base + ".png")
    _, shadow = read_rgba(base + "-shadow.png")
    for ci, d in enumerate(SHOW):
        fx, fy = (d % LINE) * FRAME, (d // LINE) * FRAME
        for y in range(cell):
            srow, irow, orow = shadow[fy + CROP + y], img[fy + CROP + y], out[si * cell + y]
            for x in range(cell):
                sx = (fx + CROP + x) * 4
                ox = (ci * cell + x) * 3
                r, g, b = orow[ox], orow[ox + 1], orow[ox + 2]
                sa = srow[sx + 3] / 255 * 0.55
                r, g, b = r * (1 - sa), g * (1 - sa), b * (1 - sa)
                a = irow[sx + 3] / 255
                r, g, b = irow[sx] * a + r * (1 - a), irow[sx + 1] * a + g * (1 - a), irow[sx + 2] * a + b * (1 - a)
                orow[ox], orow[ox + 1], orow[ox + 2] = int(r), int(g), int(b)
os.makedirs(os.path.join(ROOT, "docs", "img"), exist_ok=True)
write_rgb(os.path.join(ROOT, "docs", "img", "ships.png"), W, H, out)
print("docs/img/ships.png", W, "x", H)
