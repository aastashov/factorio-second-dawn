"""Stitch NxN small PNG tiles (RGB/RGBA, 8 bit, no interlace) into one PNG. Pure Python."""
import sys, zlib, struct
def read_png(path):
    d = open(path, 'rb').read()
    pos, idat, w = 8, b'', None
    while pos < len(d):
        n, typ = struct.unpack('>I4s', d[pos:pos + 8]); body = d[pos + 8:pos + 8 + n]; pos += 12 + n
        if typ == b'IHDR': w, h, depth, ctype = struct.unpack('>IIBB', body[:10])
        elif typ == b'IDAT': idat += body
    bpp = {2: 3, 6: 4}[ctype]
    raw, stride, rows, prev = zlib.decompress(idat), w * bpp, [], bytearray(w * bpp)
    i = 0
    for _ in range(h):
        f = raw[i]; line = bytearray(raw[i + 1:i + 1 + stride]); i += 1 + stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0; b = prev[x]; c = prev[x - bpp] if x >= bpp else 0
            if f == 1: line[x] = (line[x] + a) & 255
            elif f == 2: line[x] = (line[x] + b) & 255
            elif f == 3: line[x] = (line[x] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c; pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(bytes(line[j] for k in range(w) for j in range(k * bpp, k * bpp + 3))); prev = line
    return w, h, rows
n, out, paths = int(sys.argv[1]), sys.argv[2], sys.argv[3:]
tiles = [read_png(p) for p in paths]
tw, th = tiles[0][0], tiles[0][1]
rows = []
for ty in range(n):
    for y in range(th):
        rows.append(b''.join(tiles[ty * n + tx][2][y] for tx in range(n)))
raw = b''.join(b'\x00' + r for r in rows)
def chunk(t, b): return struct.pack('>I', len(b)) + t + b + struct.pack('>I', zlib.crc32(t + b))
png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', tw * n, th * n, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')
open(out, 'wb').write(png)
