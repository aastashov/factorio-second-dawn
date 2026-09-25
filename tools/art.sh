#!/usr/bin/env bash
# Puts pictures from art/incoming into the mod in one go (docs/PROMPTS.md):
#   tools/art.sh sd-scholar-desk 3.2      # art/incoming/sd-scholar-desk.png (+ -idle.png), 3.2 tiles wide
#   tools/art.sh sd-rope icon             # art/incoming/icons/sd-rope.png -> item icon graphics/icons/sd-rope.png
#   tools/art.sh sd-bow tech              # art/incoming/tech/sd-bow.png -> graphics/technology/sd-bow.png
#   tools/art.sh                          # re-import everything listed in art/manifest.txt
# Any format sips reads works (webp, jpg, png). Writes the sprites, shadow, icon, prototypes/art-sizes.lua,
# and a preview on grass next to vanilla buildings: art/preview/<name>.png. Buildings are wired by
# prototypes/art.lua (add a line to EXTRAS there for a shift or a light).
set -euo pipefail
cd "$(dirname "$0")/.."
in=art/incoming
for f in "$in"/*.webp "$in"/*.jpg "$in"/*.jpeg "$in"/icons/*.webp "$in"/icons/*.jpg "$in"/icons/*.jpeg "$in"/tech/*.webp "$in"/tech/*.jpg "$in"/tech/*.jpeg; do
  [ -e "$f" ] || continue
  sips -s format png "$f" --out "${f%.*}.png" >/dev/null && rm "$f"
done
if [ $# -ge 2 ]; then
  # a name can have both a picture and an icon line: replace only the line of the same kind
  if [ "$2" = icon ] || [ "$2" = tech ]; then same="^$1 $2"; else same="^$1 [^it]"; fi
  grep -v "$same" art/manifest.txt > art/manifest.tmp || true
  echo "$*" >> art/manifest.tmp && mv art/manifest.tmp art/manifest.txt
  list=$(grep "$same" art/manifest.txt)
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
  if [ "$tiles" = tech ]; then  # art/incoming/tech/<name>.png: a technology picture
    python3 tools/import_art.py "$name" 0 --tech
    continue
  fi
  if [ "$tiles" = icon ]; then  # art/incoming/icons/<name>.png: an item icon
    python3 tools/import_art.py "$name" 0 --icon $opts
    continue
  fi
  python3 tools/import_art.py "$name" "$tiles" ${states[@]+"${states[@]}"} $opts
  case " $opts " in *" --unit "*) continue;; esac  # animals: no preview on grass yet
  python3 tools/art_preview.py "$name"
done <<< "$list"
python3 tools/render_icons.py --sheet > /dev/null  # also docs/img/icons.png: all icons on one sheet
