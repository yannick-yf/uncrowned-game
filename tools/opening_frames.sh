#!/bin/zsh
# The opening's key frames, in each language, for a review (O21, 2026-09-29).
#
#   tools/opening_frames.sh [out_dir] [languages...]
#   tools/opening_frames.sh /tmp/opening fr en      # the default
#   ONLY='inventory' tools/opening_frames.sh /tmp/o  # only the frames whose name matches
#
# Thirty frames a language, from the title to the works' gate and the fight there, and what
# you carry, each through the debug tools CLAUDE.md lists (UNCROWNED_TALK, _AT, _HAIL, _DUEL,
# _VIEW, _WORLD, _GEAR), then
# one line per frame: its name and how many SCRIPT ERRORs its run printed — which has to
# be 0, and which says nothing about whether the picture is right: look at them.
#
# **It borrows the player's own files and gives them back.** A shot plays the run on
# disk, and the language is a setting on disk, so the save (`save.json`) is moved aside —
# every frame is then of a fresh run, standing where the game starts — and the settings
# (`settings.cfg`) are rewritten once per language. Both are copied first and put back on
# exit, even an interrupted one; a save the run wrote where there was none is removed.
# The tiles are the baked world's, and frames 07-09 need a run nobody has hailed yet.
set -u
cd "${0:A:h}/.."
OUT="${1:-/tmp/opening}"
shift $(( $# > 0 ? 1 : 0 ))
LANGS=("$@")
(( ${#LANGS} )) || LANGS=(fr en)
DATA="$HOME/Library/Application Support/Godot/app_userdata/Uncrowned"
KEEP="$(mktemp -d)"
restore() {
  if [[ -f "$KEEP/settings.cfg" ]]; then cp -p "$KEEP/settings.cfg" "$DATA/settings.cfg"; else rm -f "$DATA/settings.cfg"; fi
  if [[ -f "$KEEP/save.json" ]]; then cp -p "$KEEP/save.json" "$DATA/save.json"; else rm -f "$DATA/save.json"; fi
  echo "restored the settings and the save (copies kept in $KEEP)"
}
mkdir -p "$DATA"
[[ -f "$DATA/settings.cfg" ]] && cp -p "$DATA/settings.cfg" "$KEEP/"
[[ -f "$DATA/save.json" ]] && cp -p "$DATA/save.json" "$KEEP/"
trap restore EXIT
trap 'exit 130' INT TERM
rm -f "$DATA/save.json"

shoot() { # name, screen, env...
  local name=$1 screen=$2; shift 2
  [[ -n "${ONLY:-}" && ! "$name" =~ $ONLY ]] && return
  env "$@" UNCROWNED_SHOT="$OUT/$LANG_ID/$name.png" UNCROWNED_SCREEN="$screen" godot --path . > "$OUT/$LANG_ID/$name.log" 2>&1
  rm -f "$DATA/save.json"
  echo "$LANG_ID/$name $(grep -c 'SCRIPT ERROR' "$OUT/$LANG_ID/$name.log")"
}
CARRIED=leather_cap,ochre_gambeson,royal_breastplate,cloth_tunic,royal_leggings,cloth_trousers,short_sword,hunting_bow
for LANG_ID in $LANGS; do
  mkdir -p "$OUT/$LANG_ID"
  printf '[player]\n\nlanguage="%s"\n' $LANG_ID > "$DATA/settings.cfg"
  shoot 01_title title
  shoot 02_creation creation
  shoot 03_wake play
  shoot 04_fairy play UNCROWNED_TALK=fairy
  shoot 05_rest_prompt play UNCROWNED_AT=282,334
  shoot 06_path play UNCROWNED_AT=277,326
  shoot 07_hail_mark play UNCROWNED_HAIL=bram:6
  shoot 08_hail_walk play UNCROWNED_HAIL=bram:100
  shoot 09_hail_talk play UNCROWNED_HAIL=bram:400
  shoot 10_sword_first play UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:sword:67
  shoot 11_sword_blow play UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:sword:160:press
  shoot 12_sword_end play UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:sword:700:press
  shoot 13_bow_first play UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:bow:47
  shoot 13b_bow_in_hand play UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:bow:153:bow
  shoot 14_bow_arrow play UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:bow:60:bow
  shoot 15_bow_end play UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:bow:900:bow
  shoot 16_magic_first play UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:magic:47
  shoot 17_magic_spell play UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:magic:220:cast
  shoot 18_magic_end play UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:magic:900:cast
  shoot 19_journal_quests journal:quests
  shoot 20_journal_standing journal:standing
  shoot 21_wolves play UNCROWNED_AT=306,263
  shoot 22_works_gate play UNCROWNED_AT=317,208
  shoot 23_map map
  shoot 24_flat_bake play UNCROWNED_VIEW=2d
  shoot 25_procedural_start play UNCROWNED_WORLD=procedural
  shoot 26_pause pause
  shoot 27_gate_fight play UNCROWNED_AT=316,208 UNCROWNED_DUEL=gatekeeper@1:340:press
  # What you carry (E5): a works' guard's leavings and the king's, some worn and some in the
  # bag — an item listed after another of its slot puts the first back in the bag.
  shoot 28_inventory inventory UNCROWNED_GEAR=$CARRIED
  shoot 29_inventory_bag inventory:bag UNCROWNED_GEAR=$CARRIED
done
echo "frames in $OUT"
