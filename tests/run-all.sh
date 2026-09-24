#!/usr/bin/env bash
# Every check: offline, all scenarios, heavy mode. Takes a few minutes.
#   SD_TEST_DIR=/path tests/run-all.sh
set -uo pipefail
cd "$(dirname "$0")/.."
tests/run.sh || exit 1
status=0
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
wildlife 44700
capture 5700
climate 20300
sea 5
ships 9100
chain4 90400
chain5 111000
defeat 110
LIST
tests/run-heavy.sh desync 480 | grep -E "heavy mode ran|desync" || status=1
exit $status
