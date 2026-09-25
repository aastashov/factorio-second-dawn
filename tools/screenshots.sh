#!/usr/bin/env bash
# Screenshots for the mod portal: builds the scenes of tests/scenarios/shots.lua on a fresh map in an
# isolated Factorio (its own data folder, never the player's), opens it WITH graphics for a minute, lets the
# scenario take the pictures, closes it, and copies them to docs/img/shots/.
#   tools/screenshots.sh
set -euo pipefail
cd "$(dirname "$0")/.."
export SD_TEST_DIR=${SD_TEST_DIR:-/tmp/sd-shots}
dir=$SD_TEST_DIR
bin=${FACTORIO_BIN:-"$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio"}
# Creates the map with the scenario (headless, a few ticks: nothing is pictured there).
bash tests/run-scenario.sh shots 2 > /dev/null
out="$dir/data/script-output/second-dawn-shots"
rm -rf "$out"
# SteamAppId: the game runs directly instead of asking Steam to restart it (Steam may not, or may ask first).
SteamAppId=427520 SteamGameId=427520 "$bin" --config "$dir/config.ini" --load-game "$dir/data/saves/shots.zip" \
  --disable-audio > "$dir/graphic.log" 2>&1 &
# Steam restarts the game through itself (with the same arguments), so the process to wait for and close is
# found by its isolated config, not by the pid started here.
running() { ps -axo pid=,command= | grep "[M]acOS/factorio" | grep -- "--config $dir/config.ini" | awk '{print $1}'; }
for _ in $(seq 1 240); do
  [ -f "$out/done.txt" ] && break
  sleep 1
done
for p in $(running); do kill "$p" 2>/dev/null || true; done
wait 2>/dev/null || true
mkdir -p docs/img/shots
ls "$out"/*.png >/dev/null 2>&1 || { echo "no pictures; see $dir/data/factorio-current.log"; exit 1; }
for f in "$out"/*.png; do sips -s format jpeg -s formatOptions 85 "$f" --out "docs/img/shots/$(basename "${f%.png}").jpg" >/dev/null; done
ls docs/img/shots
