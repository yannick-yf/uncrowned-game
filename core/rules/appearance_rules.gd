class_name AppearanceRules
extends RefCounted

## **What the player may look like** (group A, `docs/CREATION_AND_GEAR.md`).
##
## Five choices made once at creation — hair style, hair colour, skin, beard, the colour
## of the clothes he starts in — each one of the options `content/appearance.json` lists.
## The simulation does nothing with them but keep them: they are data a replay rebuilds,
## so a save shows the same person, and they gate nothing (invariant 4). How each looks is
## the window's (`PaperDoll`).

const FILE: String = "res://content/appearance.json"
const HAIR_STYLE: StringName = &"hair_style"
const HAIR_COLOUR: StringName = &"hair_colour"
const SKIN: StringName = &"skin"
const BEARD: StringName = &"beard"
const CLOTHES: StringName = &"clothes"
## In the order the creation screen offers them.
const ALL: Array[StringName] = [HAIR_STYLE, HAIR_COLOUR, SKIN, BEARD, CLOTHES]

static var _table: Dictionary = {}


static func _read() -> Dictionary:
	if _table.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		_table = parsed as Dictionary if parsed is Dictionary else {}
	return _table


static func list_name(choice: StringName) -> String:
	match choice:
		HAIR_STYLE:
			return "hair_styles"
		HAIR_COLOUR:
			return "hair_colours"
		SKIN:
			return "skin_tones"
		BEARD:
			return "beards"
		CLOTHES:
			return "clothes_colours"
	return ""


## The options of one choice, in the table's order; the first is his traveller's.
static func options(choice: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var held: Variant = _read().get(list_name(choice), [])
	var names: Array = (held as Dictionary).keys() if held is Dictionary else held as Array
	for name: Variant in names:
		out.append(StringName(String(name)))
	return out


## His brother's traveller exactly: what anybody looks like who chose nothing — a save
## from before group A, a test that does not care.
static func default_appearance() -> Dictionary:
	var out: Dictionary = {}
	var held: Dictionary = _read().get("default", {}) as Dictionary
	for choice: StringName in ALL:
		out[choice] = StringName(String(held.get(String(choice), String(options(choice)[0]))))
	return out


## `wanted` with every choice it does not name taken from the default.
static func completed(wanted: Dictionary) -> Dictionary:
	var out: Dictionary = default_appearance()
	for choice: StringName in ALL:
		var given: Variant = wanted.get(choice, wanted.get(String(choice), null))
		if given != null and String(given) != "":
			out[choice] = StringName(String(given))
	return out


## The reason an appearance cannot be chosen, or `&""`.
static func why_not(wanted: Dictionary) -> StringName:
	var whole: Dictionary = completed(wanted)
	for choice: StringName in ALL:
		if not options(choice).has(whole[choice] as StringName):
			return &"creation.no_such_look"
	return &""


static func is_legal(wanted: Dictionary) -> bool:
	return why_not(wanted) == &""
