#!/usr/bin/env bash
#
# Bring the Brindle 3D workshop's scenes into this project, then import them.
#
#   tools/vendor_workshop.sh          after cloning, and after each delivery of his
#
# Two steps because they are two programs: the copy is tools/vendor_workshop.gd, and
# the textures and scenes it copies are nothing to Godot until imported. Generated,
# never committed; CI runs this before the suite.
set -euo pipefail

GODOT="${GODOT:-}"
if [[ -z "$GODOT" ]]; then
  for candidate in godot /Applications/Godot.app/Contents/MacOS/Godot; do
    if command -v "$candidate" >/dev/null 2>&1 || [[ -x "$candidate" ]]; then
      GODOT="$candidate"; break
    fi
  done
fi
[[ -z "$GODOT" ]] && { echo "no Godot binary found. Set GODOT=/path/to/godot." >&2; exit 1; }

"$GODOT" --headless --path . -s tools/vendor_workshop.gd
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
echo "imported."
