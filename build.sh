#!/usr/bin/env bash
# Packs the mod into dist/<factorio version>/second-dawn_<version>.zip.
# Only factorio_version in info.json differs between targets; 2.0 is the tested one.
#
#   ./build.sh            # builds for 2.0
#   ./build.sh 2.0 2.1
set -euo pipefail
cd "$(dirname "$0")"

name=$(python3 -c 'import json; print(json.load(open("info.json"))["name"])')
version=$(python3 -c 'import json; print(json.load(open("info.json"))["version"])')
targets=("$@")
[ $# -eq 0 ] && targets=(2.0)

for fv in "${targets[@]}"; do
  out="dist/$fv"
  tmp=$(mktemp -d)
  dir="$tmp/${name}_${version}"
  mkdir -p "$dir" "$out"
  cp -R info.json data.lua data-final-fixes.lua settings.lua control.lua changelog.txt prototypes scripts locale "$dir/"
  python3 - "$dir/info.json" "$fv" <<'PY'
import json, sys
path, fv = sys.argv[1], sys.argv[2]
info = json.load(open(path))
info["factorio_version"] = fv
json.dump(info, open(path, "w"), indent=2, ensure_ascii=False)
PY
  rm -f "$out/${name}_${version}.zip"
  (cd "$tmp" && zip -qr "$OLDPWD/$out/${name}_${version}.zip" "${name}_${version}")
  rm -rf "$tmp"
  echo "$out/${name}_${version}.zip"
done
