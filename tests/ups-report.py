#!/usr/bin/env python3
"""Summarises `--benchmark-verbose all` output: average ms per tick after warm-up.
   python3 tests/ups-report.py <bench.log> [from_tick]"""
import sys

path, start = sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 600
header, rows = None, []
for line in open(path):
    if line.startswith("tick,"):
        header = line.strip().rstrip(",").split(",")
    elif header and line.startswith("t") and line[1].isdigit():
        cells = line.strip().rstrip(",").split(",")
        if int(cells[0][1:]) >= start:
            rows.append(dict(zip(header, cells)))
for col in ("wholeUpdate", "entityUpdate", "scriptUpdate"):
    vals = [int(r[col]) for r in rows]
    print(f"{col:14s} avg {sum(vals) / len(vals) / 1e6:.4f} ms  max {max(vals) / 1e6:.3f} ms  ({len(vals)} ticks)")
