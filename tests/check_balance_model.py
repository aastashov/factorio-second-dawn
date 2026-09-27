#!/usr/bin/env python3
"""tools/balance.py must describe the real game: machine speeds, miner speeds, energy use and fuel of every
machine it counts, and every recipe it models, against the prototype dump (--dump-data).
    python3 tests/check_balance_model.py <data-raw-dump.json>"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "tools"))
import balance  # noqa: E402

d = json.load(open(sys.argv[1]))


def proto(name):
    for t in ("assembling-machine", "furnace", "lab", "mining-drill", "rocket-silo"):
        if name in d.get(t, {}):
            return d[t][name]


def kw(s):
    m = re.match(r"([\d.]+)\s*([kMG]?)W", s or "0kW")
    return float(m.group(1)) * {"k": 1, "M": 1000, "G": 1e6, "": 0.001}[m.group(2)]


problems = []
for machine, (name, power, fuel) in balance.POWER.items():
    p = proto(name)
    if not p:
        problems.append(f"{machine}: no prototype {name}")
        continue
    es = p.get("energy_source", {})
    real_fuel = {"void": None, "electric": "electric"}.get(es.get("type"))
    if es.get("type") == "burner":
        real_fuel = "charcoal" if es.get("fuel_categories") == ["sd-charcoal"] else "wood"
    real_kw = 0 if real_fuel is None else kw(p.get("energy_usage"))
    if abs(real_kw - power) > 0.5 or real_fuel != fuel:
        problems.append(f"{machine} ({name}): model {power} kW {fuel}, game {real_kw:g} kW {real_fuel}")
    speed = p.get("crafting_speed", p.get("mining_speed", p.get("researching_speed")))
    model = balance.MACHINES.get(machine, balance.MINERS.get(machine))
    if model is not None and speed is not None and abs(model - speed) > 1e-6:
        problems.append(f"{machine} ({name}): model speed {model}, game {speed}")

# Every recipe the model knows has the game's time, ingredients and products (model names are short).
ALIAS = {"tablet": "sd-clay-tablet", "flask": "sd-glass-flask", "iron": "iron-plate", "copper": "copper-plate",
         "steel": "steel-plate", "gear": "iron-gear-wheel", "cable": "copper-cable", "petroleum": "petroleum-gas",
         "circuit": "electronic-circuit", "plastic": "plastic-bar", "low-density": "low-density-structure",
         "piercing-rounds": "piercing-rounds-magazine", "small-pole": "small-electric-pole",
         "blast-furnace": "steel-furnace", "electric-drill": "electric-mining-drill", "assembler-1": "assembling-machine-1",
         "assembler-2": "assembling-machine-2", "medium-pole": "medium-electric-pole"}
for n in ("charge-1", "charge-2", "charge-3", "charge-4", "charge-5"):
    ALIAS[n] = "sd-revival-" + n


def game_name(n):
    if n in ALIAS:
        return ALIAS[n]
    for cand in ("sd-" + n, n):
        for t in ("item", "tool", "capsule", "gun", "ammo", "armor", "fluid", "item-with-entity-data", "repair-tool",
                  "rail-planner"):
            if cand in d.get(t, {}):
                return cand
    return n


def amounts(lst):
    return {x["name"]: x.get("amount", 1) for x in (lst or [])}


for r, (_, _, time, ins, outs, _) in balance.RECIPES.items():
    real = d["recipe"].get("sd-" + r)
    if not real:
        continue
    if abs(real.get("energy_required", 0.5) - time) > 1e-6:
        problems.append(f"recipe {r}: model {time} s, game {real.get('energy_required', 0.5)} s")
    for kind, model, game in (("in", ins, amounts(real.get("ingredients"))), ("out", outs, amounts(real.get("results")))):
        m = {game_name(k): v for k, v in model.items()}
        if m != game:
            problems.append(f"recipe {r} {kind}: model {m}, game {game}")
for p in problems:
    print("MODEL", p)
print(f"{len(problems)} differences between tools/balance.py and the game")
sys.exit(1 if problems else 0)
