#!/usr/bin/env bash
#
# The sanctioned way to run the suite. Not a convenience — part of the check.
#
# A GDScript runtime error does not unwind: it prints to stderr and abandons the
# function. The runner catches the common case by failing any test that records
# no assertions, but it cannot see its own stderr, so a test that crashes *after*
# an assertion would still report "ok". This script is what closes that.
#
#   tools/run_tests.sh              the fast suite — run it after every change
#   tools/run_tests.sh --all        everything, including the map walks and the pack
#   tools/run_tests.sh --procedural the same suite on the 2D map v1 and v2 were built
#                                   on, which is not the game any more (M4, 2026-09-13)
#                                   but keeps its tests; combine with --all
#
# The world baked from the 3D workshop is the default since the cut-over. --baked is
# accepted and means nothing, so an old habit does not fail.
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
for arg in "$@"; do
  case "$arg" in
    --all) MODE="--everything"; LABEL="whole suite" ;;
    --procedural) export UNCROWNED_WORLD=procedural; LABEL="$LABEL, the 2D map" ;;
    --baked) export UNCROWNED_WORLD=baked ;;
  esac
done

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
