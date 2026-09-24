"""Second Dawn balance model: flows, machine counts, research totals and tech-tree checks per epoch.

    python3 tools/balance.py            # all epochs
    python3 tools/balance.py 2          # up to epoch 2, tables for epoch 2

Numbers here must match the prototypes; tests/scenarios/tree.lua checks the real tree in the game.
"""
import math
import sys

# machine: (speed, category) — mining machines use RESOURCES' mining time
MACHINES = {
    "hand": 1.0, "campfire": 0.5, "kiln": 1.0, "workbench": 0.5, "alembic": 1.0, "fermentation-vat": 1.0,
    "garden": 1.0, "chamber": 1.0,
    "millstone": 0.5, "bloomery": 1.0, "glassworks": 1.0,
}
CATEGORY_MACHINE = {
    "firing": "kiln", "crafting": "workbench", "distillation": "alembic", "fermenting": "fermentation-vat",
    "growing": "garden", "awakening": "chamber", "hand": "hand",
    "grinding": "millstone", "smelting": "bloomery", "glassmaking": "glassworks",
}
# mined items: mining time; miners: digger 0.25 (soft only), pick digger 0.2, bronze drill 0.4 (soft + hard)
RAW = {"wood", "stone", "clay", "shells", "saltpeter", "fruit", "copper-ore", "tin-ore", "coal"}
MINERS = {"digger": 0.25, "pick-digger": 0.2, "bronze-drill": 0.4}
MINING_TIME = {"stone": 1, "clay": 1, "shells": 1, "saltpeter": 1.5, "copper-ore": 1, "tin-ore": 1, "coal": 1}

# name: (epoch, category, seconds, {inputs}, {outputs}, unlocked_by or None)
RECIPES = {
    # epoch 1
    "charcoal":      (1, "firing", 3.2, {"wood": 3}, {"charcoal": 1}, None),
    "fiber":         (1, "hand", 1, {"wood": 1}, {"fiber": 2}, None),
    "rope":          (1, "crafting", 1, {"fiber": 3}, {"rope": 1}, None),
    "clay-tablet":   (1, "crafting", 8, {"clay": 2, "charcoal": 1}, {"tablet": 2}, None),
    "brick":         (1, "firing", 3.2, {"clay": 2}, {"brick": 1}, "pottery"),
    "jug":           (1, "firing", 4, {"clay": 3}, {"jug": 1}, "pottery"),
    "quicklime":     (1, "firing", 3.2, {"shells": 2}, {"quicklime": 1}, "quicklime"),
    "mortar":        (1, "crafting", 1, {"quicklime": 1, "stone": 2}, {"mortar": 2}, "quicklime"),
    "grow-fruit":    (1, "growing", 60, {"fruit": 2}, {"fruit": 6}, "fermentation"),
    "mash":          (1, "fermenting", 30, {"jug": 1, "fruit": 4}, {"mash-jug": 1}, "fermentation"),
    "spirit":        (1, "distillation", 8, {"mash-jug": 2}, {"spirit-jug": 1, "jug": 1}, "distillation"),
    "nitric-acid":   (1, "distillation", 10, {"jug": 1, "saltpeter": 4, "charcoal": 1}, {"acid-jug": 1}, "distillation"),
    # charcoal 30 = chamber fuel (200 kW x 600 s), modelled as an ingredient
    "charge-1":      (1, "awakening", 600, {"acid-jug": 10, "spirit-jug": 10, "charcoal": 30}, {"charge-1": 1, "jug": 20}, "awakening"),
    # epoch 2
    "sand":          (2, "grinding", 2, {"stone": 1}, {"sand": 2}, "millstone"),
    "ash":           (2, "firing", 3.2, {"wood": 4}, {"ash": 2}, "potash"),
    "potash":        (2, "firing", 6.4, {"ash": 4}, {"potash": 1}, "potash"),
    "copper":        (2, "smelting", 3.2, {"copper-ore": 1}, {"copper": 1}, "smelting"),
    "tin":           (2, "smelting", 3.2, {"tin-ore": 1}, {"tin": 1}, "smelting"),
    "bronze":        (2, "smelting", 6.4, {"copper": 3, "tin": 1}, {"bronze": 4}, "bronze"),
    "glass":         (2, "glassmaking", 6.4, {"sand": 4, "potash": 1, "quicklime": 1}, {"glass": 2}, "glass"),
    "bottle":        (2, "glassmaking", 2, {"glass": 1}, {"bottle": 1}, "glass"),
    "glass-flask":   (2, "crafting", 6, {"glass": 1, "bronze": 1}, {"flask": 1}, "glass-flask"),
    "rectified":     (2, "distillation", 10, {"spirit-jug": 2, "bottle": 1}, {"rectified-bottle": 1, "jug": 2}, "rectification"),
    "conc-acid":     (2, "distillation", 12, {"acid-jug": 2, "bottle": 1}, {"conc-acid-bottle": 1, "jug": 2}, "rectification"),
    # coal 45 = chamber fuel (200 kW x 900 s = 180 MJ / 4 MJ)
    "charge-2":      (2, "awakening", 900, {"rectified-bottle": 10, "conc-acid-bottle": 10, "coal": 45},
                      {"charge-2": 1, "bottle": 20}, "second-awakening"),
}
# item -> recipe that makes it (byproducts are credited separately)
PRODUCER = {out: name for name, r in RECIPES.items() for out in r[4]
            if not (out == "jug" and name != "jug") and not (out == "bottle" and name != "bottle")
            and not (out == "fruit" and name == "grow-fruit")}
RAW |= {"fiber"}  # also from trees

# name: (epoch, count, seconds per unit, packs, prerequisites)
T, F = ("tablet",), ("tablet", "flask")
TECHS = {
    "pottery":          (1, 10, 10, T, []),
    "workbench":        (1, 15, 10, T, ["pottery"]),
    "levers":           (1, 20, 10, T, ["pottery"]),
    "digger":           (1, 20, 10, T, ["pottery"]),
    "quicklime":        (1, 15, 10, T, ["pottery"]),
    "fermentation":     (1, 25, 15, T, ["pottery"]),
    "distillation":     (1, 30, 15, T, ["fermentation", "quicklime"]),
    "awakening":        (1, 50, 20, T, ["distillation"]),
    "mining":           (2, 50, 15, T, ["awakening"]),
    "smelting":         (2, 60, 15, T, ["mining"]),
    "millstone":        (2, 40, 15, T, ["awakening"]),
    "potash":           (2, 40, 15, T, ["awakening"]),
    "glass":            (2, 75, 20, T, ["millstone", "potash"]),
    "bronze":           (2, 75, 20, T, ["smelting"]),
    "glass-flask":      (2, 100, 20, T, ["glass", "bronze"]),
    "bronze-tools":     (2, 100, 25, F, ["glass-flask"]),
    "logistics-2":      (2, 75, 25, F, ["glass-flask"]),
    "rectification":    (2, 100, 25, F, ["glass-flask"]),
    "second-awakening": (2, 150, 30, F, ["rectification"]),
}
PACK_ITEM = {"tablet": "tablet", "flask": "flask"}

# per-epoch tables: (item, per minute, label)
TARGETS = {
    1: [("tablet", 6, "табличка 6/мин"), ("charge-1", 1 / 30, "заряд I за 30 мин")],
    2: [("flask", 4, "колба 4/мин"), ("bronze", 6, "бронза 6/мин"), ("charge-2", 1 / 45, "заряд II за 45 мин")],
}


def closure(t, seen=None):
    seen = set() if seen is None else seen
    for p in TECHS[t][4]:
        if p not in seen:
            seen.add(p)
            closure(p, seen)
    return seen


def check_tree(max_epoch):
    """Every recipe's inputs and every tech's packs are producible with what its tech and prerequisites unlock."""
    errs = []
    for t, (ep, _, _, packs, pre) in TECHS.items():
        if ep > max_epoch:
            continue
        for p in pre:
            if p not in TECHS:
                errs.append(f"{t}: unknown prerequisite {p}")
    for r, (ep, _, _, ins, _, tech) in RECIPES.items():
        if ep > max_epoch:
            continue
        avail = {None} | ({tech} | closure(tech) if tech else set())
        producible = set(RAW)
        for r2, (_, _, _, _, outs2, t2) in RECIPES.items():
            if t2 in avail:
                producible |= set(outs2)
        for i in ins:
            if i not in producible:
                errs.append(f"{r}: {i} not producible at {tech}")
    for t, (ep, _, _, packs, pre) in TECHS.items():
        if ep > max_epoch:
            continue
        avail = {None} | closure(t)
        producible = set(RAW)
        for _, (_, _, _, _, outs2, t2) in RECIPES.items():
            if t2 in avail:
                producible |= set(outs2)
        for p in packs:
            if PACK_ITEM[p] not in producible:
                errs.append(f"tech {t}: pack {p} not producible before it")
    return errs


def rates(item, per_min, acc):
    if item not in PRODUCER:
        acc[("raw", item)] = acc.get(("raw", item), 0) + per_min
        return
    rname = PRODUCER[item]
    _, cat, time, ins, outs, _ = RECIPES[rname]
    crafts = per_min / outs[item]
    acc[("recipe", rname)] = acc.get(("recipe", rname), 0) + crafts
    for i, n in ins.items():
        rates(i, crafts * n, acc)


def credit(acc, container, returners):
    """Containers (jugs, bottles) that come back from recipes need not be made again."""
    back = sum(acc.get(("recipe", r), 0) * RECIPES[r][4].get(container, 0) for r in returners)
    made = acc.get(("recipe", container), 0)
    saved = min(back, made)
    if saved > 0:
        c = {}
        rates(container, saved, c)
        for k, v in c.items():
            acc[k] -= v


def table(item, per_min):
    acc = {}
    rates(item, per_min, acc)
    credit(acc, "jug", ["spirit", "charge-1", "rectified", "conc-acid"])
    credit(acc, "bottle", ["charge-2"])
    rows = []
    for (kind, name), v in acc.items():
        if v < 1e-6:
            continue
        if kind == "recipe":
            cat, time = RECIPES[name][1], RECIPES[name][2]
            m = CATEGORY_MACHINE[cat]
            n = v * time / 60 / MACHINES[m]
            rows.append((name, f"{v:.2f} крафт/мин", m, f"{n:.2f}", math.ceil(n - 1e-9)))
        else:
            miners = ""
            if name in MINING_TIME:
                miners = ", ".join(f"{m} {v * MINING_TIME[name] / 60 / s:.2f}" for m, s in MINERS.items()
                                   if not (m == "digger" and name in ("copper-ore", "tin-ore", "coal")))
            rows.append((name, f"{v:.2f}/мин", "сырьё", miners, ""))
    return rows


def research(epoch):
    units = {}
    lab_s = 0
    for t, (ep, count, sec, packs, _) in TECHS.items():
        if ep == epoch:
            for p in packs:
                units[p] = units.get(p, 0) + count
            lab_s += count * sec
    return units, lab_s


if __name__ == "__main__":
    max_epoch = int(sys.argv[1]) if len(sys.argv) > 1 else max(r[0] for r in RECIPES.values())
    errs = check_tree(max_epoch)
    print("tree errors:", errs or "none")
    for ep in range(1, max_epoch + 1):
        units, lab_s = research(ep)
        print(f"epoch {ep}: packs {units}, {lab_s} lab-s = {lab_s / 60:.0f} min on 1 desk, {lab_s / 180:.0f} on 3")
    for item, pm, label in TARGETS.get(max_epoch, []):
        print(f"\n## {label}")
        for r in table(item, pm):
            print("  ", r)
    sys.exit(1 if errs else 0)
