#!/usr/bin/env python3
"""Every name the player sees must have a translation. Reads the prototype dump (--dump-data) and the mod's
and vanilla locales, and lists what would show up as "Unknown key" in the game.
    python3 tests/check_locale_keys.py <data-raw-dump.json>"""
import glob
import json
import os
import re
import sys

GAME = os.path.expanduser("~/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data")
MOD = os.path.join(os.path.dirname(__file__), "..")


def keys(paths):
    out, section = set(), None
    for path in paths:
        for line in open(path, encoding="utf-8"):
            line = line.strip()
            m = re.match(r"^\[(.+)\]$", line)
            if m:
                section = m.group(1)
            elif "=" in line and not line.startswith(";"):
                out.add((section + "." if section else "") + line.split("=", 1)[0])
    return out


mod_keys = {lang: keys(glob.glob(os.path.join(MOD, "locale", lang, "*.cfg"))) for lang in ("en", "ru")}
vanilla = {lang: keys(glob.glob(os.path.join(GAME, "*", "locale", lang, "*.cfg"))) for lang in ("en", "ru")}
dump = json.load(open(sys.argv[1]))

ITEM_TYPES = {"item", "tool", "capsule", "gun", "ammo", "armor", "item-with-entity-data", "rail-planner"}
NON_ENTITY = ITEM_TYPES | {"recipe", "technology", "fluid", "tile", "autoplace-control", "item-group", "item-subgroup",
                           "recipe-category", "custom-input", "damage-type", "fuel-category", "ammo-category",
                           "resource-category", "noise-expression", "animation", "sprite", "planet"}
CATEGORY_SECTION = {"fuel-category": "fuel-category-name", "ammo-category": "ammo-category-name",
                    "resource-category": "resource-category-name", "damage-type": "damage-type-name",
                    "item-group": "item-group-name", "custom-input": "controls", "tile": "tile-name",
                    "technology": "technology-name", "fluid": "fluid-name"}


def resolves(ls, lang):
    """Does a localised name resolve in `lang`? Handles {"?", ...} fallbacks and concatenations."""
    have = mod_keys[lang] | vanilla[lang]
    if isinstance(ls, str):
        return ls in have or not re.match(r"^[a-z-]+\.[\w-]+$", ls)
    if isinstance(ls, list) and ls:
        head = ls[0]
        if head == "?":
            return any(resolves(x, lang) for x in ls[1:])
        if head == "":
            return all(resolves(x, lang) for x in ls[1:] if not isinstance(x, str) or "." in x and " " not in x)
        return head in have
    return True


problems = []
for type_name, protos in dump.items():
    for name, p in protos.items():
        if not name.startswith("sd-") or p.get("hidden"):
            continue
        if type_name in ("recipe-category", "noise-expression", "animation", "item-subgroup", "planet"):
            continue
        if "localised_name" in p:
            want = [p["localised_name"]]
        elif type_name in ITEM_TYPES:
            want = [["?", ["item-name." + name], ["entity-name." + p.get("place_result", name)]]]
        elif type_name in CATEGORY_SECTION:
            want = [[CATEGORY_SECTION[type_name] + "." + name]]
        elif type_name == "recipe":
            want = [["recipe-name." + name]]
        elif type_name not in NON_ENTITY:
            want = [["entity-name." + name]]
        else:
            continue
        for lang in ("en", "ru"):
            for w in want:
                if not resolves(w, lang):
                    problems.append(f"{lang} {type_name}/{name}: {json.dumps(w, ensure_ascii=False)}")
# Descriptions: every item of the mod and every building placed by one says what it is for.
for type_name, protos in dump.items():
    if type_name not in ITEM_TYPES:
        continue
    for name, p in protos.items():
        if not name.startswith("sd-") or p.get("hidden") or "localised_description" in p:
            continue
        want = ["item-description." + name, "entity-description." + p.get("place_result", name)]
        for lang in ("en", "ru"):
            if not any(w in mod_keys[lang] for w in want):
                problems.append(f"{lang} {type_name}/{name}: no description")
for p in sorted(problems):
    print("UNKNOWN", p)
print(f"{len(problems)} names without translation")
sys.exit(1 if problems else 0)
