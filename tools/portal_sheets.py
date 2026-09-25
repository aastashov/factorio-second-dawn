#!/usr/bin/env python3
"""Pictures for the mod portal that a screenshot cannot take (the game leaves its tech tree and crafting menu
out of take_screenshot): the tech tree and the recipes of epoch 1, drawn from the mod's own data as a page
styled like the game's GUI and rendered to PNG by a headless Chromium browser.
    python3 tools/portal_sheets.py /tmp/sd-test/data/script-output/data-raw-dump.json
        -> docs/img/shots/tech-tree.png, docs/img/shots/recipes.png
The dump comes from `factorio --dump-data` (see docs/ART-HANDOFF.md). Names are Russian, like the portal."""
import html
import json
import os
import subprocess
import sys
import tempfile

ROOT = os.path.join(os.path.dirname(__file__), "..")
GAME = os.path.expanduser("~/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/data")
BROWSER = "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
EPOCH_1_PACK = "sd-clay-tablet"


def locale():
    names = {}
    for path in (os.path.join(GAME, "base", "locale", "ru", "base.cfg"), os.path.join(ROOT, "locale", "ru", "second-dawn.cfg")):
        section = None
        for line in open(path, encoding="utf-8"):
            line = line.strip()
            if line.startswith("["):
                section = line[1:-1]
            elif "=" in line and section and section.endswith("-name"):
                key, value = line.split("=", 1)
                names[(section[:-5], key)] = value
    return names


def icon_file(proto):
    icons = proto.get("icons") or [{"icon": proto.get("icon")}]
    path = icons[0].get("icon") or ""
    for mod, folder in (("__second-dawn__", ROOT), ("__base__", os.path.join(GAME, "base")),
                        ("__core__", os.path.join(GAME, "core"))):
        if path.startswith(mod):
            return "file://" + os.path.abspath(folder + path[len(mod):])
    return ""


def icon(url, size, tint=None):
    # vanilla icons carry mipmaps on the right: show the first square only
    return (f'<span class="icon" style="width:{size}px;height:{size}px;background-image:url(\'{url}\');'
            f'background-size:auto {size}px"></span>')


CSS = """
body { margin: 0; background: #242324; font: 15px 'Titillium Web', 'Helvetica Neue', Arial, sans-serif; color: #e8e2d8; }
.frame { background: #313031; border: 2px solid #1b1a1b; box-shadow: inset 0 0 0 2px #403f40; padding: 14px 18px 18px; }
h1 { font-size: 22px; font-weight: 600; color: #ffe6c0; margin: 0 0 12px; }
h2 { font-size: 16px; font-weight: 600; color: #ffe6c0; margin: 14px 0 6px; }
.icon { display: inline-block; background-repeat: no-repeat; background-position: left top; vertical-align: middle; }
.card { position: absolute; width: 148px; background: #414041; border: 2px solid #1b1a1b; box-shadow: inset 0 2px 0 #5a585a;
        text-align: center; padding: 6px 4px 5px; box-sizing: border-box; }
.card .name { font-size: 13px; line-height: 15px; margin-top: 4px; color: #e8e2d8; min-height: 30px; }
.card.goal { background: #5b4a2c; }
.slot { display: inline-block; position: relative; width: 34px; height: 34px; background: #8e8c8e;
        box-shadow: inset 0 0 0 2px #6b696b; border-radius: 2px; margin: 1px; vertical-align: middle; }
.slot .icon { position: absolute; left: 3px; top: 3px; }
.slot .n { position: absolute; right: 2px; bottom: 0; font-size: 12px; font-weight: 700; color: #fff;
           text-shadow: 0 0 2px #000, 0 0 2px #000; }
.row { display: flex; align-items: center; gap: 4px; background: #3b3a3b; padding: 2px 8px; margin: 2px 0; break-inside: avoid; }
.row .rname { width: 190px; font-size: 14px; }
.arrow { color: #ffe6c0; font-size: 18px; margin: 0 4px; }
.cols { column-count: 3; column-gap: 18px; }
.group h2 { break-after: avoid; }
.group h2 .icon { margin-right: 6px; }
"""


def render(page, out, width, height):
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False, encoding="utf-8") as f:
        f.write(page)
    subprocess.run([BROWSER, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                    f"--window-size={width},{height}", f"--screenshot={os.path.abspath(out)}", "file://" + f.name],
                   check=True, capture_output=True)
    os.remove(f.name)
    print(out)


def epoch_1(d):
    techs = {}
    for name, t in d["technology"].items():
        if not name.startswith("sd-"):
            continue
        packs = {(i[0] if isinstance(i, list) else i.get("name")) for i in (t.get("unit") or {}).get("ingredients", [])}
        if packs <= {EPOCH_1_PACK}:
            techs[name] = t
    return techs


def tech_name(n, names):
    """Levelled technologies (sd-arrowheads-1) are named by their base name plus the level."""
    if ("technology", n) in names:
        return names[("technology", n)]
    base, _, lvl = n.rpartition("-")
    return f"{names.get(('technology', base), base)} {lvl}" if lvl.isdigit() else n


def tech_tree(d, names):
    techs = epoch_1(d)
    depth = {}

    def level(n):
        if n not in depth:
            pre = [p for p in techs[n].get("prerequisites", []) if p in techs]
            depth[n] = 1 + max((level(p) for p in pre), default=-1)
        return depth[n]
    for n in techs:
        level(n)
    cols = {}
    for n in sorted(techs, key=lambda n: (techs[n].get("order", ""), n)):
        cols.setdefault(depth[n], []).append(n)
    # order each column by the average row of its prerequisites, so arrows cross less
    row = {}
    for c in sorted(cols):
        def key(n):
            pre = [row[p] for p in techs[n].get("prerequisites", []) if p in row]
            return sum(pre) / len(pre) if pre else 0
        cols[c].sort(key=key)
        for i, n in enumerate(cols[c]):
            row[n] = i
    W, H, gx, gy = 148, 128, 210, 150
    pos = {n: (20 + c * gx, 60 + i * gy) for c in cols for i, n in enumerate(cols[c])}
    width = 40 + max(x for x, _ in pos.values()) + W
    height = 80 + max(y for _, y in pos.values()) + H
    lines = []
    for n, t in techs.items():
        for p in t.get("prerequisites", []):
            if p in pos:
                x1, y1 = pos[p][0] + W, pos[p][1] + H / 2
                x2, y2 = pos[n][0], pos[n][1] + H / 2
                mx = (x1 + x2) / 2
                lines.append(f'<path d="M{x1},{y1} C{mx},{y1} {mx},{y2} {x2},{y2}" />')
    cards = []
    for n, (x, y) in pos.items():
        url = "file://" + os.path.abspath(os.path.join(ROOT, "graphics", "technology", n + ".png"))
        cards.append(f'<div class="card{" goal" if n == "sd-awakening" else ""}" style="left:{x}px;top:{y}px">'
                     f'{icon(url, 88)}<div class="name">{html.escape(tech_name(n, names))}</div></div>')
    page = (f'<html><head><meta charset="utf-8"><style>{CSS}</style></head><body>'
            f'<div class="frame" style="position:relative;width:{width}px;height:{height}px;box-sizing:border-box">'
            f'<h1>Дерево технологий за глиняные таблички: эпоха 1 «Огонь и глина»</h1>'
            f'<svg width="{width}" height="{height}" style="position:absolute;left:0;top:0">'
            f'<g fill="none" stroke="#c9a15a" stroke-width="3" opacity="0.8">{"".join(lines)}</g></svg>'
            f'{"".join(cards)}</div></body></html>')
    render(page, os.path.join(ROOT, "docs", "img", "shots", "tech-tree.png"), width, height)


def recipes(d, names):
    techs = epoch_1(d)
    unlocked = {e["recipe"] for t in techs.values() for e in t.get("effects", []) if e.get("type") == "unlock-recipe"}
    chosen = [r for n, r in d["recipe"].items() if n.startswith("sd-") and not r.get("hidden")
              and (n in unlocked or r.get("enabled", True)) and not n.startswith("sd-alt-")]
    makers = {}
    for t in ("assembling-machine", "furnace"):
        for n, e in d.get(t, {}).items():
            if n.startswith("sd-"):
                for c in e.get("crafting_categories", []):
                    makers.setdefault(c, []).append(n)
    protos = {}
    for t, group in d.items():
        if t in ("item", "tool", "capsule", "gun", "ammo", "armor", "item-with-entity-data", "fluid", "rail-planner",
                 "repair-tool", "assembling-machine", "furnace", "lab"):
            for n, p in group.items():
                protos.setdefault(n, p)

    def slot(p):
        proto = protos.get(p["name"], {})
        n = p.get("amount", p.get("amount_max", 1))
        n = int(n) if float(n).is_integer() else n
        return f'<span class="slot" title="{html.escape(p["name"])}">{icon(icon_file(proto), 28)}<span class="n">{n}</span></span>'

    def label(r):
        res = (r.get("results") or [{}])[0].get("name", "")
        return (names.get(("recipe", r["name"])) or names.get(("item", res)) or names.get(("entity", res))
                or names.get(("fluid", res)) or res)
    groups = {}
    for r in chosen:
        groups.setdefault(r.get("category", "crafting"), []).append(r)
    blocks = []
    for cat in sorted(groups, key=lambda c: (c != "crafting", c)):
        who = makers.get(cat, [])
        title = ", ".join(names.get(("entity", m), m) for m in who) or cat
        if cat == "crafting":
            title = "Руками и на верстаке"
        head = "".join(icon(icon_file(protos.get(m, {})), 28) for m in who[:3])
        rows = "".join(f'<div class="row"><span class="rname">{html.escape(label(r))}</span>'
                       f'{"".join(slot(i) for i in r.get("ingredients", []))}<span class="arrow">→</span>'
                       f'{"".join(slot(o) for o in r.get("results", []))}</div>'
                       for r in sorted(groups[cat], key=lambda r: r.get("order", r["name"])))
        blocks.append(f'<div class="group"><h2>{head}{html.escape(title)}</h2>{rows}</div>')
    page = (f'<html><head><meta charset="utf-8"><style>{CSS}</style></head><body><div class="frame">'
            f'<h1>Рецепты эпохи 1 «Огонь и глина»</h1><div class="cols">{"".join(blocks)}</div></div></body></html>')
    render(page, os.path.join(ROOT, "docs", "img", "shots", "recipes.png"), 1920, 1060)


if __name__ == "__main__":
    data = json.load(open(sys.argv[1]))
    n = locale()
    tech_tree(data, n)
    recipes(data, n)
