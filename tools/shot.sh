#!/usr/bin/env bash
#
# A picture of a screen, without playing the game.
#
#   tools/shot.sh out.png                     the title
#   tools/shot.sh out.png creation            character creation
#   tools/shot.sh out.png play 241,150        the world, standing at a tile
#   UNCROWNED_FREE=wide_acres tools/shot.sh out.png play 90,151
#                                             the same, with one place freed
#   UNCROWNED_WORLD=baked tools/shot.sh out.png play 292,290
#                                             the baked world, seen in 3D (M2)
#   UNCROWNED_WORLD=baked UNCROWNED_VIEW=2d tools/shot.sh out.png map
#                                             the baked world, flat
#
# The check that "zero script errors" is not. Looking at the output is cheap, and
# every bug the first two nights shipped would have been caught by one of these.
set -uo pipefail

GODOT="${GODOT:-}"
if [[ -z "$GODOT" ]]; then
  for candidate in godot /Applications/Godot.app/Contents/MacOS/Godot; do
    if command -v "$candidate" >/dev/null 2>&1 || [[ -x "$candidate" ]]; then
      GODOT="$candidate"; break
    fi
  done
fi
[[ -z "$GODOT" ]] && { echo "no Godot binary found. Set GODOT=/path/to/godot." >&2; exit 1; }

OUT="${1:?usage: shot.sh out.png [title|creation|play] [x,y]}"
SCREEN="${2:-title}"
AT="${3:-}"

UNCROWNED_SHOT="$OUT" UNCROWNED_SCREEN="$SCREEN" UNCROWNED_AT="$AT" \
  "$GODOT" --path . --quit-after 60 >/dev/null 2>&1
[[ -f "$OUT" ]] || { echo "no image written — the run died before frame 12" >&2; exit 1; }
echo "$OUT"
