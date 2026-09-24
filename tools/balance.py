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
    "blast-furnace": 2.0, "electric-chamber": 1.0, "assembler-2": 0.75,
    "chemical-plant": 1.0, "refinery": 1.0, "electric-furnace": 2.0, "plantation": 1.0,
    "rocket-silo": 1.0,
}
CATEGORY_MACHINE = {
    "firing": "kiln", "campfire": "campfire", "crafting": "workbench", "distillation": "alembic", "fermenting": "fermentation-vat",
    "growing": "garden", "awakening": "chamber", "hand": "hand",
    "grinding": "millstone", "smelting": "bloomery", "glassmaking": "glassworks",
    "blast": "blast-furnace", "awakening-electric": "electric-chamber",
    "chemistry": "chemical-plant", "oil-processing": "refinery", "electric-smelting": "electric-furnace",
    "plantation": "plantation",
    "rocket-building": "rocket-silo",
}
# mined items: mining time; miners: digger 0.25 (soft only), pick digger 0.2, bronze drill 0.4 (soft + hard)
RAW = {"wood", "stone", "clay", "shells", "saltpeter", "fruit", "copper-ore", "tin-ore", "coal", "iron-ore",
       "meat", "hide", "bones",
       "sulfur", "tungsten-ore", "crude-oil", "water"}  # epoch 4: sulfur and oil in the south, tungsten in the north  # animals: hunting from the start
MINERS = {"digger": 0.25, "pick-digger": 0.2, "bronze-drill": 0.4, "electric-drill": 0.5}
MINING_TIME = {"stone": 1, "clay": 1, "shells": 1, "saltpeter": 1.5, "copper-ore": 1, "tin-ore": 1, "coal": 1, "iron-ore": 1}

# name: (epoch, category, seconds, {inputs}, {outputs}, unlocked_by or None)
RECIPES = {
    # epoch 1
    "charcoal":      (1, "firing", 3.2, {"wood": 3}, {"charcoal": 1}, None),
    "fiber":         (1, "hand", 1, {"wood": 1}, {"fiber": 2}, None),
    "rope":          (1, "crafting", 1, {"fiber": 3}, {"rope": 1}, None),
    "clay-tablet":   (1, "crafting", 8, {"clay": 2, "charcoal": 1}, {"tablet": 2}, None),
    "brick":         (1, "firing", 3.2, {"clay": 2}, {"brick": 1}, None),   # campfire from the start
    "jug":           (1, "firing", 4, {"clay": 3}, {"jug": 1}, "pottery"),
    "quicklime":     (1, "firing", 3.2, {"shells": 2}, {"quicklime": 1}, "quicklime"),
    "mortar":        (1, "crafting", 1, {"quicklime": 1, "stone": 2}, {"mortar": 2}, "quicklime"),
    "grow-fruit":    (1, "growing", 60, {"fruit": 2}, {"fruit": 6}, "fermentation"),
    "mash":          (1, "fermenting", 30, {"jug": 1, "fruit": 4}, {"mash-jug": 1}, "fermentation"),
    "spirit":        (1, "distillation", 8, {"mash-jug": 2}, {"spirit-jug": 1, "jug": 1}, "distillation"),
    "nitric-acid":   (1, "distillation", 10, {"jug": 1, "saltpeter": 4, "charcoal": 1}, {"acid-jug": 1}, "distillation"),
    # charcoal 30 = chamber fuel (200 kW x 600 s), modelled as an ingredient
    "charge-1":      (1, "awakening", 600, {"acid-jug": 10, "spirit-jug": 10, "charcoal": 30}, {"charge-1": 1, "jug": 20}, "awakening"),
    # hunting (release 0.4)
    "bow":           (1, "crafting", 3, {"wood": 5, "rope": 2}, {"bow": 1}, None),
    "stone-arrows":  (1, "crafting", 1, {"wood": 1, "stone": 1}, {"stone-arrows": 5}, None),
    "bone-arrows":   (1, "crafting", 1, {"wood": 1, "bones": 1}, {"bone-arrows": 5}, "hunting"),
    "palisade":      (1, "crafting", 1, {"wood": 6, "rope": 1}, {"palisade": 2}, "hunting"),
    "cooked-meat":   (1, "campfire", 5, {"meat": 1}, {"cooked-meat": 1}, "hunting"),
    "leather":       (1, "fermenting", 20, {"hide": 2, "quicklime": 1}, {"leather": 2}, "tanning"),
    "leather-jacket": (1, "crafting", 5, {"leather": 10, "rope": 5}, {"leather-jacket": 1}, "tanning"),
    "arrows":        (2, "crafting", 2, {"wood": 1, "bronze": 1, "fiber": 2}, {"arrows": 10}, "bow"),
    "crossbow":      (2, "crafting", 5, {"bronze": 10, "wood": 10, "rope": 5, "leather": 2}, {"crossbow": 1}, "crossbow"),
    "bone-meal":     (2, "grinding", 2, {"bones": 1}, {"bone-meal": 3}, "bone-meal"),
    "fertilized-fruit": (2, "growing", 60, {"fruit": 2, "bone-meal": 2}, {"fruit": 10}, "bone-meal"),
    # climate (release 0.6)
    "brazier":       (1, "crafting", 1, {"brick": 5, "stone": 5}, {"brazier": 1}, "brazier"),
    "fur-coat":      (1, "crafting", 5, {"leather": 20, "hide": 10, "rope": 5}, {"fur-coat": 1}, "warm-clothing"),
    "light-cloak":   (1, "crafting", 5, {"fiber": 40, "leather": 5}, {"light-cloak": 1}, "light-clothing"),
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
    # epoch 3 (release 0.5)
    "bloomery-iron": (3, "smelting", 6.4, {"iron-ore": 2, "coal": 1}, {"iron": 1}, "wrought-iron"),
    "iron-gear":     (3, "crafting", 0.5, {"iron": 2}, {"gear": 1}, "ironworking"),
    "pipe":          (3, "crafting", 0.5, {"iron": 1}, {"pipe": 1}, "fluid-handling"),
    "offshore-pump": (3, "crafting", 1, {"pipe": 2, "gear": 1, "bronze": 2}, {"offshore-pump": 1}, "fluid-handling"),
    "boiler":        (3, "crafting", 1, {"pipe": 4, "brick": 10}, {"boiler": 1}, "steam-power"),
    "steam-engine":  (3, "crafting", 2, {"gear": 8, "pipe": 5, "iron": 10}, {"steam-engine": 1}, "steam-power"),
    "copper-cable":  (3, "crafting", 0.5, {"copper": 1}, {"cable": 2}, "electricity"),
    "small-pole":    (3, "crafting", 0.5, {"wood": 1, "cable": 2}, {"small-pole": 2}, "electricity"),
    "blast-furnace": (3, "crafting", 3, {"brick": 20, "iron": 10}, {"blast-furnace": 1}, "blast-furnace"),
    "iron-plate":    (3, "blast", 3.2, {"iron-ore": 1}, {"iron": 1}, "blast-furnace"),
    "steel":         (3, "blast", 16, {"iron": 5}, {"steel": 1}, "blast-furnace"),
    "electric-drill": (3, "crafting", 2, {"gear": 5, "cable": 6, "iron": 10}, {"electric-drill": 1}, "electromechanics"),
    "inserter":      (3, "crafting", 0.5, {"gear": 1, "cable": 2, "iron": 1}, {"inserter": 1}, "electromechanics"),
    "assembler-1":   (3, "crafting", 0.5, {"gear": 5, "cable": 6, "iron": 9}, {"assembler-1": 1}, "electromechanics"),
    "lab":           (3, "crafting", 2, {"gear": 10, "cable": 10, "glass": 10}, {"lab": 1}, "electromechanics"),
    "mechanism":     (3, "crafting", 8, {"gear": 2, "cable": 2, "steel": 1}, {"mechanism": 1}, "mechanism"),
    "radiator":      (3, "crafting", 2, {"pipe": 10, "iron": 10, "copper": 5}, {"radiator": 1}, "steam-heating"),
    "cooler":        (3, "crafting", 2, {"pipe": 10, "gear": 5, "cable": 10, "iron": 10}, {"cooler": 1}, "cooling"),
    "landfill":      (3, "crafting", 1, {"stone": 20}, {"landfill": 1}, "land-reclamation"),
    "deep-landfill": (3, "crafting", 1, {"stone": 150, "steel": 5, "mortar": 10}, {"deep-landfill": 1}, "deep-landfill"),
    "pitch":         (3, "distillation", 15, {"wood": 10}, {"pitch": 2, "charcoal": 3}, "pitch"),
    "waterway":      (3, "crafting", 1, {"wood": 2, "rope": 1, "iron": 1}, {"waterway": 2}, "shipbuilding"),
    "tug":           (3, "crafting", 10, {"steel": 20, "gear": 20, "pipe": 10, "wood": 50, "pitch": 20}, {"tug": 1}, "shipbuilding"),
    "barge":         (3, "crafting", 5, {"wood": 60, "steel": 10, "pitch": 20}, {"barge": 1}, "shipbuilding"),
    "pier":          (3, "crafting", 2, {"wood": 20, "steel": 5, "cable": 5}, {"pier": 1}, "shipbuilding"),
    "buoy":          (3, "crafting", 1, {"wood": 5, "cable": 2, "glass": 1}, {"buoy": 1}, "buoys"),
    "fluid-barge":   (3, "crafting", 5, {"steel": 30, "pipe": 20, "pitch": 20}, {"fluid-barge": 1}, "fluid-barges"),
    "briquettes":    (3, "crafting", 2, {"coal": 5, "pitch": 1}, {"briquettes": 4}, "briquettes"),
    "feed":          (3, "grinding", 4, {"fruit": 4, "fiber": 4}, {"feed": 4}, "domestication"),
    "net":           (3, "crafting", 2, {"rope": 10, "leather": 2, "bronze": 2}, {"net": 1}, "domestication"),
    "electrode":     (3, "crafting", 3, {"copper": 2, "glass": 1}, {"electrode": 1}, "third-awakening"),
    # 2 MW x 1200 s is electric, not modelled
    "charge-3":      (3, "awakening-electric", 1200, {"rectified-bottle": 15, "conc-acid-bottle": 15, "electrode": 5},
                      {"charge-3": 1, "bottle": 30}, "third-awakening"),
    # epoch 4 (release 0.9); fluids in units
    "sulfuric-acid": (4, "chemistry", 1, {"sulfur": 5, "iron": 1, "water": 100}, {"sulfuric-acid": 50}, "sulfur-processing"),
    "oil-processing": (4, "oil-processing", 5, {"crude-oil": 100, "water": 50}, {"heavy-oil": 30, "light-oil": 45, "petroleum": 55}, "oil-processing"),
    "latex":         (4, "plantation", 60, {"water": 100}, {"latex": 6}, "rubber"),
    "rubber":        (4, "chemistry", 5, {"latex": 4, "sulfur": 1}, {"rubber": 2}, "rubber"),
    "reactive":      (4, "chemistry", 10, {"bottle": 1, "sulfuric-acid": 20, "rubber": 1}, {"reactive": 2}, "reactive"),
    "tungsten":      (4, "electric-smelting", 6.4, {"tungsten-ore": 2}, {"tungsten": 1}, "tungsten"),
    "navigation":    (4, "crafting", 10, {"tungsten": 1, "glass": 2, "mechanism": 1}, {"navigation": 1}, "navigation"),
    "heavy-cracking": (4, "chemistry", 2, {"heavy-oil": 40, "water": 30}, {"light-oil": 30}, "cracking"),
    "light-cracking": (4, "chemistry", 2, {"light-oil": 30, "water": 30}, {"petroleum": 20}, "cracking"),
    "fuel-oil":      (4, "chemistry", 2, {"light-oil": 10}, {"fuel-oil": 1}, "fuel-oil"),
    "ether":         (4, "chemistry", 5, {"spirit-jug": 2, "sulfuric-acid": 10, "bottle": 1}, {"ether-bottle": 1, "jug": 2}, "ether"),
    "tungsten-electrode": (4, "crafting", 3, {"tungsten": 1, "glass": 1}, {"tungsten-electrode": 1}, "tungsten-electrodes"),
    "charge-4":      (4, "awakening-electric", 1500, {"rectified-bottle": 20, "conc-acid-bottle": 20, "ether-bottle": 10,
                      "tungsten-electrode": 5}, {"charge-4": 1, "bottle": 50}, "fourth-awakening"),
    # epoch 5 (release 0.10)
    "plastic":       (5, "chemistry", 1, {"petroleum": 20, "coal": 1}, {"plastic": 2}, "plastics"),
    "circuit":       (5, "crafting", 0.5, {"plastic": 1, "cable": 3, "iron": 1}, {"circuit": 1}, "electronics"),
    "board":         (5, "crafting", 10, {"circuit": 3, "plastic": 2, "tungsten": 1}, {"board": 2}, "instrument-board"),
    "rocket-fuel":   (5, "chemistry", 10, {"light-oil": 10, "fuel-oil": 1}, {"rocket-fuel": 1}, "rocket-fuel"),
    "low-density":   (5, "crafting", 10, {"steel": 2, "copper": 5, "plastic": 2}, {"low-density": 1}, "light-structures"),
    "control-unit":  (5, "crafting", 10, {"circuit": 5, "tungsten": 1, "plastic": 1}, {"control-unit": 1}, "control-units"),
    "rocket-part":   (5, "rocket-building", 3, {"low-density": 2, "rocket-fuel": 2, "control-unit": 2}, {"rocket-part": 1}, "rocket-silo"),
    "spacesuit":     (5, "crafting", 20, {"rubber": 30, "glass": 20, "tungsten": 10, "circuit": 10, "leather": 10}, {"spacesuit": 1}, "spacesuit"),
    "oxygen-tank":   (5, "crafting", 5, {"steel": 2, "rubber": 1}, {"oxygen-tank": 1}, "spacesuit"),
    "charge-5":      (5, "awakening-electric", 1800, {"rectified-bottle": 25, "conc-acid-bottle": 25, "ether-bottle": 15,
                      "control-unit": 5}, {"charge-5": 1, "bottle": 65}, "fifth-awakening"),
    "charge-2":      (2, "awakening", 900, {"rectified-bottle": 10, "conc-acid-bottle": 10, "coal": 45},
                      {"charge-2": 1, "bottle": 20}, "second-awakening"),
}
# item -> recipe that makes it (byproducts are credited separately)
PRODUCER = {out: name for name, r in RECIPES.items() for out in r[4]
            if not (out == "jug" and name != "jug") and not (out == "bottle" and name != "bottle")
            and not (out == "fruit" and name in ("grow-fruit", "fertilized-fruit"))
            and not (out == "light-oil" and name == "heavy-cracking") and not (out == "petroleum" and name == "light-cracking")
            and not (out in ("heavy-oil", "petroleum") and name == "oil-processing" and False)}
# byproducts are not producers: charcoal comes from charcoal burning, not pitch; sulfur is mined
PRODUCER.update({"charcoal": "charcoal", "jug": "jug", "bottle": "bottle"})
PRODUCER.pop("sulfur", None)
RAW |= {"fiber"}  # also from trees

# name: (epoch, count, seconds per unit, packs, prerequisites)
T, F, M = ("tablet",), ("tablet", "flask"), ("tablet", "flask", "mechanism")
R, N = M + ("reactive",), M + ("reactive", "navigation")
B = N + ("board",)
TECHS = {
    "pottery":          (1, 10, 10, T, []),
    "workbench":        (1, 15, 10, T, ["pottery"]),
    "levers":           (1, 20, 10, T, ["pottery"]),
    "digger":           (1, 20, 10, T, ["pottery"]),
    "quicklime":        (1, 15, 10, T, ["pottery"]),
    "fermentation":     (1, 25, 15, T, ["pottery"]),
    "distillation":     (1, 30, 15, T, ["fermentation", "quicklime"]),
    "awakening":        (1, 50, 20, T, ["distillation"]),
    "hunting":          (1, 15, 10, T, []),
    "tanning":          (1, 25, 15, T, ["quicklime", "fermentation"]),
    "brazier":          (1, 20, 10, T, ["pottery"]),
    "warm-clothing":    (1, 30, 10, T, ["tanning"]),
    "light-clothing":   (1, 30, 10, T, ["tanning"]),
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
    "bow":              (2, 60, 20, T, ["bronze"]),
    "crossbow":         (2, 75, 25, F, ["bow", "glass-flask", "tanning"]),
    "bone-meal":        (2, 40, 15, T, ["millstone"]),
    "wrought-iron":     (3, 75, 25, F, ["bronze-tools"]),
    "ironworking":      (3, 75, 25, F, ["wrought-iron"]),
    "fluid-handling":   (3, 100, 25, F, ["ironworking"]),
    "steam-power":      (3, 100, 30, F, ["fluid-handling"]),
    "electricity":      (3, 100, 30, F, ["steam-power"]),
    "blast-furnace":    (3, 120, 30, F, ["ironworking"]),
    "electromechanics": (3, 150, 30, F, ["electricity", "blast-furnace"]),
    "mechanism":        (3, 150, 30, F, ["electromechanics"]),
    "logistics-3":      (3, 150, 30, M, ["mechanism"]),
    "automation-2":     (3, 150, 30, M, ["mechanism"]),
    "domestication":    (3, 150, 30, M, ["mechanism", "tanning"]),
    "electric-chamber": (3, 200, 40, M, ["mechanism"]),
    "third-awakening":  (3, 250, 45, M, ["electric-chamber", "rectification"]),
    "steam-heating":    (3, 100, 30, F, ["steam-power"]),
    "cooling":          (3, 100, 30, F, ["fluid-handling", "electricity"]),
    "land-reclamation": (3, 100, 30, F, ["fluid-handling"]),
    "deep-landfill":    (3, 150, 30, M, ["mechanism", "land-reclamation"]),
    "pitch":            (3, 75, 20, F, ["distillation", "glass-flask"]),
    "shipbuilding":     (3, 200, 40, M, ["mechanism", "steam-power", "pitch"]),
    "buoys":            (3, 100, 30, M, ["shipbuilding"]),
    "fluid-barges":     (3, 150, 30, M, ["shipbuilding", "fluid-handling"]),
    "briquettes":       (3, 100, 30, M, ["shipbuilding"]),
    "sulfur-processing": (4, 200, 30, M, ["mechanism", "fluid-handling"]),
    "oil-extraction":   (4, 200, 30, M, ["electromechanics", "fluid-barges"]),
    "oil-processing":   (4, 250, 30, M, ["oil-extraction"]),
    "rubber":           (4, 200, 30, M, ["sulfur-processing"]),
    "reactive":         (4, 250, 30, M, ["rubber"]),
    "tungsten":         (4, 200, 30, M, ["mechanism"]),
    "navigation":       (4, 250, 30, R, ["tungsten", "reactive"]),
    "cracking":         (4, 250, 30, R, ["oil-processing", "reactive"]),
    "fuel-oil":         (4, 200, 30, R, ["oil-processing", "reactive"]),
    "screw-steamer":    (4, 300, 45, N, ["shipbuilding", "rubber", "navigation"]),
    "ether":            (4, 250, 30, R, ["reactive", "rectification"]),
    "tungsten-electrodes": (4, 250, 30, N, ["navigation", "third-awakening"]),
    "fourth-awakening": (4, 400, 60, N, ["ether", "tungsten-electrodes"]),
    "plastics":         (5, 200, 30, N, ["oil-processing", "navigation"]),
    "electronics":      (5, 200, 30, N, ["plastics"]),
    "radio":            (5, 150, 30, N, ["electronics"]),
    "instrument-board": (5, 250, 30, N, ["electronics", "tungsten"]),
    "rocket-fuel":      (5, 250, 30, B, ["instrument-board", "fuel-oil"]),
    "light-structures": (5, 250, 30, B, ["instrument-board"]),
    "control-units":    (5, 250, 30, B, ["instrument-board"]),
    "rocket-silo":      (5, 400, 60, B, ["rocket-fuel", "light-structures", "control-units"]),
    "spacesuit":        (5, 300, 30, B, ["instrument-board", "rubber", "tanning"]),
    "fifth-awakening":  (5, 400, 60, B, ["control-units", "fourth-awakening"]),
    "lab-glassware-1":  (3, 150, 30, M, ["mechanism"]),
    "lab-glassware-2":  (4, 250, 30, R, ["lab-glassware-1", "reactive"]),
}
PACK_ITEM = {"tablet": "tablet", "flask": "flask", "mechanism": "mechanism", "reactive": "reactive", "navigation": "navigation",
             "board": "board"}

# per-epoch tables: (item, per minute, label)
TARGETS = {
    1: [("tablet", 6, "табличка 6/мин"), ("charge-1", 1 / 30, "заряд I за 30 мин")],
    2: [("flask", 4, "колба 4/мин"), ("bronze", 6, "бронза 6/мин"), ("charge-2", 1 / 45, "заряд II за 45 мин")],
    3: [("mechanism", 6, "механизм 6/мин"), ("steel", 3, "сталь 3/мин"), ("charge-3", 1 / 60, "заряд III за час")],
    5: [("board", 3, "приборная плата 3/мин"), ("rocket-part", 1, "часть ракеты 1/мин (30 на ракету)"),
        ("charge-5", 1 / 60, "заряд V за час")],
    4: [("reactive", 4, "реактив 4/мин"), ("navigation", 2, "морская карта 2/мин"), ("charge-4", 1 / 60, "заряд IV за час")],
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
    credit(acc, "bottle", ["charge-2", "charge-3", "charge-4", "charge-5"])
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
