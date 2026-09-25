#!/usr/bin/env bash
# Runs a scenario from tests/scenarios in an isolated headless Factorio instance and prints its SD-TEST
# log lines. The instance lives in $SD_TEST_DIR (default: /tmp/sd-test), never in the user's Factorio data.
#
#   tests/run-scenario.sh tree 600
#   SD_TEST_MODS=my-mod tests/run-scenario.sh smoke    # also enable mods already in $SD_TEST_DIR/data/mods
#   SD_SEED=123 tests/run-scenario.sh sea 5            # a fixed map seed (default: random)
set -euo pipefail
cd "$(dirname "$0")/.."
name=$1; ticks=${2:-600}
dir=${SD_TEST_DIR:-/tmp/sd-test}
bin=${FACTORIO_BIN:-"$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio"}
mkdir -p "$dir/data/mods/sd-test" "$dir/data/saves"
printf '[path]\nread-data=__PATH__system-read-data__\nwrite-data=%s\n' "$dir/data" > "$dir/config.ini"
# A copy, not a symlink: the game must never see files change under it.
rm -rf "$dir/data/mods/second-dawn"
mkdir -p "$dir/data/mods/second-dawn"
cp -R info.json data.lua data-final-fixes.lua settings.lua control.lua prototypes scripts locale graphics "$dir/data/mods/second-dawn/"
cat > "$dir/data/mods/mod-list.json" <<JSON
{"mods":[{"name":"base","enabled":true},{"name":"elevated-rails","enabled":false},{"name":"quality","enabled":false},{"name":"space-age","enabled":false},{"name":"second-dawn","enabled":true},{"name":"sd-test","enabled":true}]}
JSON
echo '{"name":"sd-test","version":"0.0.1","title":"sd test","author":"t","factorio_version":"2.0","dependencies":["second-dawn"]}' > "$dir/data/mods/sd-test/info.json"
cp "tests/scenarios/$name.lua" "$dir/data/mods/sd-test/control.lua"
rm -f "$dir/data/saves/$name.zip"
# --create exits non-zero even on success, so the save file is the success signal.
seed=(); [ -n "${SD_SEED:-}" ] && seed=(--map-gen-seed "$SD_SEED")
"$bin" --config "$dir/config.ini" --create "$dir/data/saves/$name.zip" ${seed[@]+"${seed[@]}"} > "$dir/create.log" 2>&1 || true
if [ ! -f "$dir/data/saves/$name.zip" ]; then
  grep -E "Error|error" -A12 "$dir/create.log" | head -40; exit 1
fi
verbose=(); [ -n "${SD_BENCH_VERBOSE:-}" ] && verbose=(--benchmark-verbose all)
"$bin" --config "$dir/config.ini" --benchmark "$dir/data/saves/$name.zip" --benchmark-ticks "$ticks" --benchmark-runs 1 ${verbose[@]+"${verbose[@]}"} > "$dir/bench.log" 2>&1 || true
grep -h "SD-TEST" "$dir/data/factorio-current.log" | sed "s/.*SD-TEST /  /" || true
grep -E "Error while running|non-recoverable" -A6 "$dir/bench.log" | head -20 || true
grep -E "avg:" "$dir/bench.log" || true
