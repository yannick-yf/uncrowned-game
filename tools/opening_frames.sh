#!/bin/zsh
# The opening's key frames, in each language, for a review (O21, 2026-09-29).
#
#   tools/opening_frames.sh [out_dir] [languages...]
#   tools/opening_frames.sh /tmp/opening fr en      # the default
#   ONLY='inventory' tools/opening_frames.sh /tmp/o  # only the frames whose name matches
#
# Forty-two frames a language, from the title to the works' gate and the fight there, and what
# you carry and what it does in play, each through the debug tools CLAUDE.md lists
# (UNCROWNED_TALK, _AT, _HAIL, _DUEL, _VIEW, _WORLD, _GEAR, _LOOK), then
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
  # A made run, as every run is since creation (A, E): his start kit and no sword. The
  # default look, so the picture is of the game and not of a choice; a frame may ask another.
  env UNCROWNED_LOOK=hair_style=spiky "$@" UNCROWNED_SHOT="$OUT/$LANG_ID/$name.png" UNCROWNED_SCREEN="$screen" godot --path . > "$OUT/$LANG_ID/$name.log" 2>&1
  rm -f "$DATA/save.json"
  echo "$LANG_ID/$name $(grep -c 'SCRIPT ERROR' "$OUT/$LANG_ID/$name.log")"
}
# Past the graves he has picked up the sword lying there, as a player does (E3).
ARMED=UNCROWNED_GEAR=short_sword
PLATE=royal_helm,royal_breastplate,royal_leggings,short_sword,hunting_bow
CARRIED=leather_cap,ochre_gambeson,royal_breastplate,cloth_tunic,royal_leggings,cloth_trousers,short_sword,hunting_bow
for LANG_ID in $LANGS; do
  mkdir -p "$OUT/$LANG_ID"
  printf '[player]\n\nlanguage="%s"\n' $LANG_ID > "$DATA/settings.cfg"
  shoot 01_title title
  shoot 02_creation creation
  shoot 02b_creation_talents creation:talents
  shoot 03_wake play
  shoot 04_fairy play UNCROWNED_TALK=fairy
  shoot 05_rest_prompt play UNCROWNED_AT=282,334
  shoot 05b_sword_prompt play UNCROWNED_AT=277,331
  shoot 06_path play $ARMED UNCROWNED_AT=277,326
  shoot 07_hail_mark play $ARMED UNCROWNED_HAIL=bram:6
  shoot 08_hail_walk play $ARMED UNCROWNED_HAIL=bram:100
  shoot 09_hail_talk play $ARMED UNCROWNED_HAIL=bram:400
  shoot 10_sword_first play $ARMED UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:sword:67
  shoot 11_sword_blow play $ARMED UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:sword:160:press
  # The same lesson for somebody who walked past the sword: fists (the review of group E).
  shoot 11b_sword_fists play UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:sword:160:press
  shoot 12_sword_end play $ARMED UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:sword:700:press
  shoot 13_bow_first play $ARMED UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:bow:47
  shoot 13b_bow_in_hand play $ARMED UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:bow:153:bow
  shoot 14_bow_arrow play $ARMED UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:bow:60:bow
  shoot 15_bow_end play $ARMED UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:bow:900:bow
  shoot 16_magic_first play $ARMED UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:magic:47
  shoot 17_magic_spell play $ARMED UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:magic:220:cast
  shoot 18_magic_end play $ARMED UNCROWNED_AT=281,318 UNCROWNED_DUEL=drill:magic:900:cast
  shoot 19_journal_quests journal:quests $ARMED
  shoot 20_journal_standing journal:standing $ARMED
  # The wolves before the bridge (R2): their sight on the ground, from outside it; then the
  # step they see you, the '!' over them and the fight where they stood.
  shoot 21_wolves play $ARMED UNCROWNED_AT=306,268
  shoot 21b_wolves_seen play $ARMED UNCROWNED_AT=306,266
  # Behind them, unseen, a bow on his back (R3): K's prompt, then the arrow, doubled.
  shoot 21c_wolves_behind play UNCROWNED_GEAR=short_sword,hunting_bow UNCROWNED_AT=306,257
  shoot 21d_surprise play UNCROWNED_GEAR=short_sword,hunting_bow UNCROWNED_AT=306,257 UNCROWNED_DUEL=ambush:0:25
  # The chance to miss (R4): a blow the dice made miss, then the chance before the next blow.
  shoot 21e_miss play $ARMED UNCROWNED_AT=306,270 UNCROWNED_DUEL=wolf:119:press
  shoot 21f_chance play $ARMED UNCROWNED_AT=306,270 UNCROWNED_DUEL=wolf:96:press
  shoot 22_works_gate play $ARMED UNCROWNED_AT=317,208
  shoot 23_map map $ARMED
  shoot 24_flat_bake play $ARMED UNCROWNED_VIEW=2d
  shoot 25_procedural_start play $ARMED UNCROWNED_WORLD=procedural
  shoot 26_pause pause $ARMED
  shoot 27_gate_fight play $ARMED UNCROWNED_AT=316,208 UNCROWNED_DUEL=gatekeeper@1:340:press
  # What you carry (E5): a works' guard's leavings and the king's, some worn and some in the
  # bag — an item listed after another of its slot puts the first back in the bag.
  shoot 28_inventory inventory UNCROWNED_GEAR=$CARRIED
  shoot 29_inventory_bag inventory:bag UNCROWNED_GEAR=$CARRIED
  # Seen in play (E6): the king's guards' set worn on the road and in a fight, where the card
  # says what it takes off; a works' guard beaten, and what he left said once it is over;
  # and Bram's hail to somebody who walked past the sword.
  shoot 30_gear_world play UNCROWNED_AT=281,318 UNCROWNED_GEAR=$PLATE
  shoot 31_gear_fight play UNCROWNED_AT=281,318 UNCROWNED_GEAR=$PLATE UNCROWNED_DUEL=bram
  shoot 32_loot play UNCROWNED_AT=317,208 UNCROWNED_GEAR=short_sword UNCROWNED_DUEL=works_guard:340:press
  shoot 33_hail_unarmed play UNCROWNED_HAIL=bram:400
done
echo "frames in $OUT"
