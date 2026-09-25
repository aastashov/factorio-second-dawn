#!/usr/bin/env python3
"""Factoriopedia shows the mod as it is: every item of the mod is there, no recipe is a second entry next
to the item it makes, nothing lands in "Unsorted", and no vanilla thing the game doesn't have is shown.
    python3 tests/check_factoriopedia.py <data-raw-dump.json>"""
import json
import sys

d = json.load(open(sys.argv[1]))
ITEM = ["item", "tool", "capsule", "gun", "ammo", "armor", "item-with-entity-data", "rail-planner", "repair-tool", "module"]
groups = {n: p.get("group") for n, p in d["item-subgroup"].items()}


def shown(p):
    return not p.get("hidden") and not p.get("hidden_in_factoriopedia") and not p.get("parameter")


items = {n: p for t in ITEM for n, p in d.get(t, {}).items()}
used = set()
for n, r in d["recipe"].items():
    if n.startswith("sd-"):
        for x in (r.get("ingredients") or []) + (r.get("results") or []):
            used.add(x["name"])
# What the world gives by hand is real too: fish, wood, stone from rocks.
for t in ("fish", "tree", "simple-entity", "resource"):
    for e in d.get(t, {}).values():
        m = e.get("minable") or {}
        if m.get("result"):
            used.add(m["result"])
        for r in m.get("results") or []:
            used.add(r["name"])
problems = []
for n, p in items.items():
    if n.startswith("sd-") and not shown(p):
        problems.append(f"item {n} of the mod is not in Factoriopedia")
    if not n.startswith("sd-") and shown(p) and n not in used:
        problems.append(f"vanilla item {n} is shown but no recipe of the mod uses or makes it")
for n, r in d["recipe"].items():
    if not shown(r):
        continue
    if not n.startswith("sd-"):
        problems.append(f"vanilla recipe {n} is shown")
        continue
    results = r.get("results") or []
    product = r.get("main_product") or (results[0]["name"] if len(results) == 1 else None)
    if product and product != n and product in items and len(results) == 1:
        problems.append(f"recipe {n} is a second entry next to item {product}")
    sub = r.get("subgroup") or (items.get(product, {}).get("subgroup") if product else None)
    if not sub or groups.get(sub) is None:
        problems.append(f"recipe {n} lands in Unsorted")
# Every item of the mod sits in a row of the menu tabs (prototypes/tabs.lua), not in an old catch-all row.
TAB_ROWS_OF_OLD = {"sd-hunting", "sd-production", None}
for n, p in items.items():
    if n.startswith("sd-") and shown(p) and p.get("subgroup") in TAB_ROWS_OF_OLD:
        problems.append(f"item {n} has no row in prototypes/tabs.lua (subgroup {p.get('subgroup')})")
# Every item of the mod sits in a row of the menu tabs (prototypes/tabs.lua), not in an old catch-all row.
OLD_ROWS = {"sd-hunting", "sd-production", None}
for n, p in items.items():
    if n.startswith("sd-") and shown(p) and p.get("subgroup") in OLD_ROWS:
        problems.append(f"item {n} has no row in prototypes/tabs.lua (subgroup {p.get('subgroup')})")
for p in problems:
    print("FACTORIOPEDIA", p)
print(f"{len(problems)} Factoriopedia problems")
sys.exit(1 if problems else 0)
