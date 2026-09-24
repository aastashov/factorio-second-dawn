"""Epoch 1 balance model for Second Dawn: rates, machine counts, tech-tree sanity checks."""
import math

# machine: (speed, categories)
MACHINES = {
    "hand":      (1.0,  {"hand", "crafting"}),
    "campfire":  (0.5,  {"firing"}),
    "kiln":      (1.0,  {"firing"}),
    "workbench": (0.5,  {"crafting"}),
    "still":     (1.0,  {"distillation"}),
    "fermenter": (1.0,  {"fermenting"}),
    "garden":    (1.0,  {"growing"}),
    "chamber":   (1.0,  {"awakening"}),
}
MINERS = {"hand-mine": 0.5, "digger": 0.25}
RESOURCES = {  # mining time per unit
    "wood": 0.5,  # tree: 4 wood per tree mined (vanilla), effective per unit
    "stone": 1.0, "clay": 1.0, "shells": 1.0, "saltpeter": 1.5,
}

# name: (category, time, {inputs}, {outputs}, unlocked_by)
RECIPES = {
    "charcoal":  ("firing", 3.2, {"wood": 3}, {"charcoal": 1}, None),
    "rope":      ("crafting", 1, {"fiber": 3}, {"rope": 1}, None),
    "fiber":     ("hand", 1, {"wood": 1}, {"fiber": 2}, None),
    "tablet":    ("crafting", 8, {"clay": 2, "charcoal": 1}, {"tablet": 2}, None),
    "brick":     ("firing", 3.2, {"clay": 2}, {"brick": 1}, "pottery"),
    "jug":       ("firing", 4, {"clay": 3}, {"jug": 1}, "pottery"),
    "lime":      ("firing", 3.2, {"shells": 2}, {"lime": 1}, "lime"),
    "mortar":    ("crafting", 1, {"lime": 1, "stone": 2}, {"mortar": 2}, "lime"),
    "fruit-grow": ("growing", 60, {"fruit": 2}, {"fruit": 6}, "fermentation"),
    "brew":      ("fermenting", 30, {"jug": 1, "fruit": 4}, {"brew-jug": 1}, "fermentation"),
    "spirit":    ("distillation", 8, {"brew-jug": 2}, {"spirit-jug": 1, "jug": 1}, "distillation"),
    "acid":      ("distillation", 10, {"jug": 1, "saltpeter": 4, "charcoal": 1}, {"acid-jug": 1}, "distillation"),
    # charcoal 30 here is the chamber's fuel (200 kW x 600 s = 120 MJ), modelled as an ingredient
    "charge-1":  ("awakening", 600, {"acid-jug": 10, "spirit-jug": 10, "charcoal": 30}, {"charge-1": 1, "jug": 20}, "awakening"),
}
RAW = set(RESOURCES) | {"fruit"}  # fruit: from fruit trees (30% chance) until gardens

TECHS = {  # name: (cost in tablets, time per unit s, prereqs)
    "pottery":      (10, 10, []),
    "lime":         (15, 10, ["pottery"]),
    "workbench":    (15, 10, ["pottery"]),
    "logistics-0":  (20, 10, ["pottery"]),
    "digger":       (20, 10, ["pottery"]),
    "fermentation": (25, 15, ["pottery"]),
    "distillation": (30, 15, ["fermentation", "lime"]),
    "awakening":    (50, 20, ["distillation"]),
}

PRODUCER = {"charcoal": "charcoal", "rope": "rope", "fiber": "fiber", "tablet": "tablet", "brick": "brick",
            "jug": "jug", "lime": "lime", "mortar": "mortar", "brew-jug": "brew", "spirit-jug": "spirit",
            "acid-jug": "acid", "charge-1": "charge-1"}

def check_tree():
    """Every recipe's ingredients are producible with recipes unlocked by the tech or its prereqs; no cycles."""
    def closure(t, seen=None):
        seen = set() if seen is None else seen
        for p in TECHS[t][2]:
            if p in seen: continue
            seen.add(p); closure(p, seen)
        return seen
    errs = []
    for r, (_, _, ins, _, tech) in RECIPES.items():
        avail = {None} | ({tech} | closure(tech) if tech else set())
        producible = set(RAW)
        for r2, (_, _, _, outs2, t2) in RECIPES.items():
            if t2 in avail: producible |= set(outs2)
        for i in ins:
            if i not in producible: errs.append(f"{r}: {i} not producible at {tech}")
    return errs

def rates(item, per_min, acc):
    """Accumulate machine-seconds per minute needed for `per_min` of item (naive single-recipe tree)."""
    if item in RAW:
        acc.setdefault(("raw", item), 0); acc[("raw", item)] += per_min; return
    rname = PRODUCER[item]
    cat, time, ins, outs, _ = RECIPES[rname]
    # net output (jug from spirit is a byproduct, handled as credit below)
    crafts = per_min / outs[item]
    acc.setdefault(("recipe", rname), 0); acc[("recipe", rname)] += crafts
    for i, n in ins.items():
        rates(i, crafts * n, acc)

def machine_for(cat):
    return {"firing": "kiln", "crafting": "workbench", "distillation": "still", "fermenting": "fermenter",
            "growing": "garden", "awakening": "chamber", "hand": "hand"}[cat]

def table(item, per_min):
    acc = {}
    rates(item, per_min, acc)
    # byproduct credit: jugs returned by spirit and chamber
    back = sum(acc.get(("recipe", r), 0) * RECIPES[r][3].get("jug", 0) for r in ("spirit", "charge-1"))
    if ("recipe", "jug") in acc and back > 0:
        saved = min(back, acc[("recipe", "jug")])
        credit = {}
        rates("jug", saved, credit)  # what those saved jug crafts would have consumed
        for k, v in credit.items():
            acc[k] -= v
        print(f"  jugs returned {back:.2f}/min, net new jugs {acc[('recipe', 'jug')]:.2f}/min")
    rows = []
    for (kind, name), v in acc.items():
        if kind == "recipe":
            cat, time, _, _, _ = RECIPES[name]
            m = machine_for(cat); sp = MACHINES[m][0]
            n = v * time / 60 / sp
            rows.append((name, f"{v:.2f} крафт/мин", m, f"{n:.2f}", math.ceil(n - 1e-9)))
        else:
            rows.append((name, f"{v:.2f}/мин", "сырьё", "", ""))
    rows = [r for r in rows if not r[1].startswith(("0.00", "-"))]
    return rows

if __name__ == "__main__":
    print("tree errors:", check_tree() or "none")
    tot = sum(c for c, _, _ in TECHS.values()); lab_s = sum(c * t for c, t, _ in TECHS.values())
    print(f"E1 techs: {tot} tablets, {lab_s} lab-s = {lab_s/60:.1f} min on 1 lab, {lab_s/120:.1f} on 2")
    for item, pm in [("tablet", 2), ("tablet", 6), ("charge-1", 1/30)]:
        print(f"\n## {item} {pm:.3f}/min")
        for r in table(item, pm): print(r)
