#!/usr/bin/env bash
# Puts pictures from art/incoming into the mod in one go (docs/PROMPTS.md):
#   tools/art.sh sd-scholar-desk 3.2      # art/incoming/sd-scholar-desk.png (+ -idle.png), 3.2 tiles wide
#   tools/art.sh                          # re-import everything listed in art/manifest.txt
# Any format sips reads works (webp, jpg, png). Writes the sprites, shadow, icon, prototypes/art-sizes.lua,
# and a preview on grass next to vanilla buildings: art/preview/<name>.png. Buildings are wired by
# prototypes/art.lua (add a line to EXTRAS there for a shift or a light).
set -euo pipefail
cd "$(dirname "$0")/.."
in=art/incoming
for f in "$in"/*.webp "$in"/*.jpg "$in"/*.jpeg; do
  [ -e "$f" ] || continue
  sips -s format png "$f" --out "${f%.*}.png" >/dev/null && rm "$f"
done
if [ $# -ge 2 ]; then
  grep -v "^$1 " art/manifest.txt > art/manifest.tmp || true
  echo "$*" >> art/manifest.tmp && mv art/manifest.tmp art/manifest.txt
  list=$(grep "^$1 " art/manifest.txt)
else
  list=$(grep -v "^#" art/manifest.txt)
fi
while read -r name tiles opts; do
  [ -n "$name" ] || continue
  states=()
  for f in "$in/$name"-*.png; do
    [ -e "$f" ] || continue
    s=${f#"$in/$name-"}; states+=(--state "${s%.png}")
  done
  python3 tools/import_art.py "$name" "$tiles" ${states[@]+"${states[@]}"} $opts
  python3 tools/art_preview.py "$name"
done <<< "$list"
python3 tools/render_icons.py > /dev/null
