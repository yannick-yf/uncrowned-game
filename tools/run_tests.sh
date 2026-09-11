#!/usr/bin/env bash
#
# The sanctioned way to run the suite. Not a convenience — part of the check.
#
# A GDScript runtime error does not unwind: it prints to stderr and abandons the
# function. The runner catches the common case by failing any test that records
# no assertions, but it cannot see its own stderr, so a test that crashes *after*
# an assertion would still report "ok". This script is what closes that.
#
#   tools/run_tests.sh          the fast suite — run it after every change
#   tools/run_tests.sh --all    everything, including the map walks and the pack
#
set -uo pipefail

GODOT="${GODOT:-}"
if [[ -z "$GODOT" ]]; then
  for candidate in godot /Applications/Godot.app/Contents/MacOS/Godot; do
    if command -v "$candidate" >/dev/null 2>&1 || [[ -x "$candidate" ]]; then
      GODOT="$candidate"; break
    fi
  done
fi
if [[ -z "$GODOT" ]]; then
  echo "FAILED: no Godot binary found. Set GODOT=/path/to/godot." >&2
  exit 1
fi

# Always pass a flag: macOS ships bash 3.2, where "${EMPTY[@]}" under `set -u`
# is an unbound-variable error. The runner ignores anything but --fast.
MODE="--fast"
LABEL="fast suite"
if [[ "${1:-}" == "--all" ]]; then MODE="--everything"; LABEL="whole suite"; fi

OUT=$("$GODOT" --headless --path . -s tools/test_runner.gd -- "$MODE" 2>&1)
CODE=$?
echo "$OUT"

if echo "$OUT" | grep -q "SCRIPT ERROR"; then
  echo
  echo "FAILED ($LABEL): a script error was raised during the run — see above."
  echo "A crashed test can still report 'ok' if it died after its first assertion,"
  echo "which is why this check lives here and not in the runner."
  exit 1
fi
exit $CODE
