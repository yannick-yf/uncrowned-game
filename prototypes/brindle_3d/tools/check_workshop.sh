#!/usr/bin/env bash
# Import and check this independent Godot project from any working directory.
# Scan stderr as well as the exit code: GDScript runtime errors can leave a
# function early without recording a failed assertion.
set -uo pipefail

GODOT="${GODOT:-godot}"
WORKSHOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

"$GODOT" --headless --editor --path "$WORKSHOP" --import --quit >"$LOG" 2>&1
CODE=$?
if [[ $CODE -ne 0 ]] || grep -qE 'SCRIPT ERROR|(^|[[:space:]])ERROR:' "$LOG"; then
  cat "$LOG"
  echo "FAILED: workshop import"
  exit 1
fi

"$GODOT" --headless --path "$WORKSHOP" --fixed-fps 60 --script res://tools/verify_river_crossings.gd >"$LOG" 2>&1
CODE=$?
cat "$LOG"
if [[ $CODE -ne 0 ]] || grep -qE 'SCRIPT ERROR|(^|[[:space:]])ERROR:' "$LOG" || ! grep -q 'RIVER_INTEGRATION PASS' "$LOG"; then
  echo "FAILED: river and bridge verification"
  exit 1
fi

"$GODOT" --headless --path "$WORKSHOP" --fixed-fps 60 --script res://tools/verify_ironworks_town.gd >"$LOG" 2>&1
CODE=$?
cat "$LOG"
if [[ $CODE -ne 0 ]] || grep -qE 'SCRIPT ERROR|(^|[[:space:]])ERROR:' "$LOG" || ! grep -q 'IRONWORKS_TOWN_CHECK PASS' "$LOG"; then
  echo "FAILED: ironworks settlement verification"
  exit 1
fi

"$GODOT" --headless --path "$WORKSHOP" --fixed-fps 60 --script res://tools/verify_ironworks_coherence.gd >"$LOG" 2>&1
CODE=$?
cat "$LOG"
if [[ $CODE -ne 0 ]] || grep -qE 'SCRIPT ERROR|(^|[[:space:]])ERROR:' "$LOG" || ! grep -q 'IRONWORKS_COHERENCE PASS' "$LOG"; then
  echo "FAILED: ironworks asset coherence verification"
  exit 1
fi

"$GODOT" --headless --path "$WORKSHOP" --fixed-fps 60 --script res://tools/verify_sawmill.gd >"$LOG" 2>&1
CODE=$?
cat "$LOG"
if [[ $CODE -ne 0 ]] || grep -qE 'SCRIPT ERROR|(^|[[:space:]])ERROR:' "$LOG" || ! grep -q 'SAWMILL_CHECK PASS' "$LOG"; then
  echo "FAILED: sawmill asset kit verification"
  exit 1
fi

"$GODOT" --headless --path "$WORKSHOP" --fixed-fps 60 --script res://tools/verify_sawmill_town.gd >"$LOG" 2>&1
CODE=$?
cat "$LOG"
if [[ $CODE -ne 0 ]] || grep -qE 'SCRIPT ERROR|(^|[[:space:]])ERROR:' "$LOG" || ! grep -q 'SAWMILL_TOWN_CHECK PASS' "$LOG"; then
  echo "FAILED: sawmill village verification"
  exit 1
fi

"$GODOT" --headless --path "$WORKSHOP" --fixed-fps 60 --script res://tools/verify_royal_city.gd >"$LOG" 2>&1
CODE=$?
cat "$LOG"
if [[ $CODE -ne 0 ]] || grep -qE 'SCRIPT ERROR|(^|[[:space:]])ERROR:' "$LOG" || ! grep -q 'ROYAL_CITY_CHECK PASS' "$LOG"; then
  echo "FAILED: royal city and castle verification"
  exit 1
fi

"$GODOT" --headless --path "$WORKSHOP" --script res://tools/verify_workshop.gd >"$LOG" 2>&1
CODE=$?
cat "$LOG"
if [[ $CODE -ne 0 ]] || grep -qE 'SCRIPT ERROR|(^|[[:space:]])ERROR:' "$LOG" || ! grep -q 'WORKSHOP_CHECK_RESULT PASS failures=0' "$LOG"; then
  echo "FAILED: workshop verification"
  exit 1
fi
