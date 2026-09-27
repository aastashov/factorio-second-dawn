#!/usr/bin/env bash
# Every check: offline, all scenarios, heavy mode. Takes a few minutes.
#   SD_TEST_DIR=/path tests/run-all.sh
set -uo pipefail
cd "$(dirname "$0")/.."
tests/run.sh || exit 1
status=0
# graphics paths: the headless game never loads graphics, so check every referenced file offline
dir=${SD_TEST_DIR:-/tmp/sd-test}
bin=${FACTORIO_BIN:-"$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio"}
tests/run-scenario.sh smoke 1 >/dev/null
"$bin" --config "$dir/config.ini" --dump-data >/dev/null 2>&1
python3 tests/check_files.py "$dir/data/script-output/data-raw-dump.json" || status=1
python3 tests/check_locale_keys.py "$dir/data/script-output/data-raw-dump.json" || status=1
python3 tests/check_factoriopedia.py "$dir/data/script-output/data-raw-dump.json" || status=1
python3 tests/check_collision.py "$dir/data/script-output/data-raw-dump.json" || status=1
python3 tests/check_balance_model.py "$dir/data/script-output/data-raw-dump.json" || status=1
while read -r name ticks; do
  result=$(tests/run-scenario.sh "$name" "$ticks" | grep -E "FAIL|failures|Error" | tr '\n' ' ')
  printf "%-10s %s\n" "$name" "$result"
  [[ "$result" == *"failures: 0"* && "$result" != *FAIL* ]] || status=1
done <<'LIST'
tree 10
chain 73100
chain2 55800
chain3 72400
notes 10
wildlife 47200
climate 20300
sea 5
ships 9100
chain4 90400
chain5 111000
defeat 110
guide 10
statue 130
belts 10
LIST
tests/run-heavy.sh desync 480 | grep -E "heavy mode ran|desync" || status=1
exit $status
