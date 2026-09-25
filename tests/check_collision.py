#!/usr/bin/env python3
"""A character walks between any two buildings of the mod placed side by side: every building leaves at
least 0.25 tiles free on each side of its collision box (vanilla assemblers leave 0.3; the character is
0.4 wide). Walls, belts, inserters, rails and the like are meant to block and are not checked.
    python3 tests/check_collision.py <data-raw-dump.json>"""
import json
import sys

d = json.load(open(sys.argv[1]))
BUILDINGS = ("assembling-machine", "furnace", "lab", "mining-drill", "ammo-turret", "reactor", "boiler", "radar",
             "generator", "offshore-pump", "storage-tank", "rocket-silo")


def box(b):
    g = lambda v, i: v[i] if isinstance(v, list) else v["xy"[i]]
    return g(b[0], 0), g(b[0], 1), g(b[1], 0), g(b[1], 1)


problems = []
for t in BUILDINGS:
    for n, p in d.get(t, {}).items():
        if not n.startswith("sd-") or "collision_box" not in p or "selection_box" not in p:
            continue
        c, s = box(p["collision_box"]), box(p["selection_box"])
        margin = min(c[0] - s[0], c[1] - s[1], s[2] - c[2], s[3] - c[3])
        if margin < 0.25:
            problems.append(f"{t}/{n}: {margin:.2f} tiles free at the edge, a character can't pass between two")
for p in problems:
    print("COLLISION", p)
print(f"{len(problems)} buildings too tight to walk between")
sys.exit(1 if problems else 0)
