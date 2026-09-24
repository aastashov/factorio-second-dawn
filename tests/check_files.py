#!/usr/bin/env python3
"""Every graphics/sound file referenced by the mod's prototypes must exist. The headless game never loads
graphics, so a wrong path only shows up when a player starts the game; this catches it offline.
    python3 tests/check_files.py <data-raw-dump.json>
Checks every string "__mod__/path" in prototypes whose name starts with "sd-" and in vanilla prototypes the
mod changed (it walks everything, but vanilla files are all present anyway)."""
import json
import os
import sys

GAME = os.path.expanduser("~/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data")
MOD = os.path.join(os.path.dirname(__file__), "..")
dump = json.load(open(sys.argv[1]))
missing, checked = {}, 0


def resolve(path):
    mod, rest = path[2:].split("__/", 1)
    if mod == "second-dawn":
        return os.path.join(MOD, rest)
    return os.path.join(GAME, mod, rest)


def walk(node, where):
    global checked
    if isinstance(node, dict):
        for k, v in node.items():
            walk(v, where)
    elif isinstance(node, list):
        for v in node:
            walk(v, where)
    elif isinstance(node, str) and node.startswith("__") and "__/" in node and node.rsplit(".", 1)[-1] in ("png", "ogg", "wav", "jpg"):
        checked += 1
        if not os.path.exists(resolve(node)):
            missing.setdefault(node, set()).add(where)


for type_name, protos in dump.items():
    for name, proto in protos.items():
        walk(proto, f"{type_name}/{name}")
# only what the mod's own prototypes use: vanilla builds some file names from patterns the dump can't show
missing = {p: u for p, u in missing.items() if any(x.split("/", 1)[1].startswith("sd-") for x in u)}
for path, users in sorted(missing.items()):
    print("MISSING", path, "used by", ", ".join(sorted(users)[:4]))
print(f"{checked} file references, {len(missing)} missing")
sys.exit(1 if missing else 0)
