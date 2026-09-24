#!/usr/bin/env bash
# Renders an N x N mosaic of map previews (1024 tiles each, shrunk to 128 px) with the mod, using the
# isolated instance of tests/run-scenario.sh. Result: docs/img/map-<seed>.png (1 px ≈ 8 tiles).
#   tools/map-preview.sh 7 777
set -euo pipefail
cd "$(dirname "$0")/.."
n=${1:-7}; seed=${2:-777}
dir=${SD_TEST_DIR:-/tmp/sd-test}
bin=${FACTORIO_BIN:-"$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio"}
tests/run-scenario.sh smoke 1 >/dev/null   # refreshes the instance with the current mod
tmp=$(mktemp -d); list=()
half=$(( (n - 1) / 2 ))
for ((ty = -half; ty <= half; ty++)); do for ((tx = -half; tx <= half; tx++)); do
  f="$tmp/t_${ty}_${tx}.png"
  "$bin" --config "$dir/config.ini" --generate-map-preview "$f" --map-preview-size 1024 \
    --map-preview-offset $((tx * 1024)),$((ty * 1024)) --map-gen-seed "$seed" > /dev/null 2>&1
  sips -z 128 128 "$f" --out "$f" > /dev/null
  list+=("$f")
done; done
mkdir -p docs/img
python3 tools/stitch_png.py "$n" "docs/img/map-$seed.png" "${list[@]}"
rm -rf "$tmp"
echo "docs/img/map-$seed.png"
