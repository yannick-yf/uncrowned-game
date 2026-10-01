class_name PaperDoll
extends RefCounted

## **The player drawn in layers** (group A, 2026-10-01; `docs/CREATION_AND_GEAR.md` §3).
##
## His brother's traveller, split by `tools/draw_player_layers.gd` into the parts a person
## is dressed in — and the parts he never drew, a head under the hair, the other hair
## styles, the beards, every item — each a sheet in the layout every look already uses, so
## `CastLooks.frames_for` reads them all. A shader stacks them in `ORDER` and colours them
## live (`view3d/layers/paper_doll.gdshaderinc`): a choice on the creation screen changes a
## number, and a helmet put on changes which sheet is on the head.
##
## The cast keeps group L's baked sheets; only the player is layered.

const DIR: String = "res://view3d/layers/"

## **Bottom to top.** A head gear may hide the hair and the beard below it, by a mask in
## its own sheet; nothing else hides anything, because nothing else overlaps.
const ORDER: Array[StringName] = [
	&"body", &"skin", &"trousers", &"boots", &"tunic", &"pack", &"beard", &"hair", &"head",
	&"weapon", &"back",
]

## The layers his traveller is made of, which the tool splits him into. `hair_spiky` is
## his own hair; the other styles and the beards are painted (A4), the items in group E.
const HIS_PARTS: Array[StringName] = [
	&"body", &"skin", &"trousers", &"boots", &"tunic", &"pack", &"hair_spiky",
]


static func sheet_path(part: StringName) -> String:
	return DIR + String(part) + ".png"
