#!/usr/bin/env bash
# Desync check: runs a scenario on a headless server with heavy mode on (the game is saved, loaded and
# compared every tick) and reports any mismatch. Uses the instance of tests/run-scenario.sh.
#
#   tests/run-heavy.sh desync 40
#   SD_TEST_DIR=/tmp/a SD_PORT=34298 tests/run-heavy.sh desync 40   # several at once: own folder and port
set -euo pipefail
cd "$(dirname "$0")/.."
name=$1; seconds=${2:-40}
dir=${SD_TEST_DIR:-/tmp/sd-test}
bin=${FACTORIO_BIN:-"$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio"}
tests/run-scenario.sh "$name" 1 >/dev/null   # builds the instance and the save
python3 - "$(dirname "$bin")/../data/server-settings.example.json" "$dir/server-settings.json" <<'PY'
import json, sys
s = json.load(open(sys.argv[1]))
s.update(name="sd heavy", visibility={"public": False, "lan": False}, require_user_verification=False, auto_pause=False)
json.dump(s, open(sys.argv[2], "w"))
PY
rm -rf "$dir/data/desync-report"* "$dir/in"; mkfifo "$dir/in"
"$bin" --config "$dir/config.ini" --start-server "$dir/data/saves/$name.zip" --server-settings "$dir/server-settings.json" \
  --port "${SD_PORT:-34297}" < "$dir/in" > "$dir/server.log" 2>&1 &
server=$!
exec 3> "$dir/in"            # keep the server's stdin open
sleep 3; echo "/toggle-heavy-mode" >&3
sleep "$seconds"
kill -INT "$server"; wait "$server" || true
exec 3>&-
grep -h "SD-TEST" "$dir/data/factorio-current.log" | sed "s/.*SD-TEST /  /" || true
echo "  heavy mode ran to $(grep -o 'Heavy mode - tick [0-9]*' "$dir/server.log" | tail -1)"
problems=$(grep -vE "Heavy mode - tick [0-9]+ finished|\.zip" "$dir/server.log" | grep -E "Heavy mode|[Dd]esync|Error while running" || true)
[ -n "$problems" ] && echo "$problems" | head -20
if ls -d "$dir/data/desync-report"* >/dev/null 2>&1 || [ -n "$problems" ]; then echo "FAIL: desync"; exit 1; fi
echo "no desync"
