#!/usr/bin/env bash
# Offline checks: Lua syntax, locale consistency, balance model and tech-tree check.
# Scenario tests with the real game: tests/run-scenario.sh <name> [ticks] (see tests/scenarios).
set -euo pipefail
cd "$(dirname "$0")/.."
for f in *.lua prototypes/*.lua prototypes/*/*.lua scripts/*.lua tests/scenarios/*.lua; do luac -p "$f"; done
echo "lua syntax ok"
python3 tests/check_locales.py >/dev/null && echo "locales ok"
python3 tools/balance.py | head -1
python3 tools/balance.py --markdown > docs/BALANCE.md   # the numbers the design doc refers to
