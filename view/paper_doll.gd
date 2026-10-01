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
## **Painted, not his** (A4): the other hair styles and the beards, made from his own
## hair's texture by the same tool, on the head it paints under his hair.
const STYLE_PARTS: Array[StringName] = [
	&"hair_short", &"hair_long", &"hair_tied", &"hair_braided", &"hair_shaved",
	&"beard_stubble", &"beard_short", &"beard_full",
]


static func sheet_path(part: StringName) -> String:
	return DIR + String(part) + ".png"


const APPEARANCE: String = "res://content/appearance.json"
const WORLD_SHADER: String = "res://view3d/layers/paper_doll_world.gdshader"
const GHOST_SHADER: String = "res://view3d/layers/paper_doll_ghost.gdshader"
const CANVAS_SHADER: String = "res://view3d/layers/paper_doll_canvas.gdshader"
## The five choices of the creation screen, in its order.
const CHOICES: Array[StringName] = [&"hair_style", &"hair_colour", &"skin", &"beard", &"clothes"]

static var _table: Dictionary = {}
static var _sheets: Dictionary = {}


static func _read() -> Dictionary:
	if _table.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(APPEARANCE))
		_table = parsed as Dictionary if parsed is Dictionary else {}
	return _table


static func _list_of(choice: StringName) -> String:
	match choice:
		&"hair_style":
			return "hair_styles"
		&"hair_colour":
			return "hair_colours"
		&"skin":
			return "skin_tones"
		&"beard":
			return "beards"
		&"clothes":
			return "clothes_colours"
	return ""


## The options of one choice, in the order the creation screen offers them.
static func options(choice: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var held: Variant = _read().get(_list_of(choice), [])
	var names: Array = (held as Dictionary).keys() if held is Dictionary else held as Array
	for name: Variant in names:
		out.append(StringName(String(name)))
	return out


## His traveller, exactly: what a player who changes nothing looks like.
static func default_appearance() -> Dictionary:
	var out: Dictionary = {}
	var held: Dictionary = _read().get("default", {}) as Dictionary
	for choice: StringName in CHOICES:
		out[choice] = StringName(String(held.get(String(choice), "")))
	return out


## A recolouring from the table, or `[]` for his own pixels.
static func recolour_of(choice: StringName, option: StringName) -> Array:
	var held: Variant = _read().get(_list_of(choice), {})
	if held is Dictionary and (held as Dictionary).get(String(option)) is Array:
		return (held as Dictionary)[String(option)] as Array
	return []


## **What fills each slot of `ORDER`** for an appearance: the part's sheet and how it is
## recoloured. A slot not named is empty. Gear (group E) will name the head, the weapon
## and the back, and may put an item where the tunic or the trousers are.
static func slots_for(appearance: Dictionary) -> Dictionary:
	var hair_colour: Array = recolour_of(&"hair_colour", appearance.get(&"hair_colour", &"") as StringName)
	var slots: Dictionary = {
		&"body": {"part": &"body", "recolour": []},
		&"skin": {"part": &"skin", "recolour": recolour_of(&"skin", appearance.get(&"skin", &"") as StringName)},
		&"trousers": {"part": &"trousers", "recolour": []},
		&"boots": {"part": &"boots", "recolour": []},
		&"tunic": {"part": &"tunic", "recolour": recolour_of(&"clothes", appearance.get(&"clothes", &"") as StringName)},
		&"pack": {"part": &"pack", "recolour": []},
	}
	var hair := StringName("hair_" + String(appearance.get(&"hair_style", &"spiky")))
	if sheet(hair) == null:
		hair = &"hair_spiky"
	slots[&"hair"] = {"part": hair, "recolour": hair_colour}
	var beard := StringName("beard_" + String(appearance.get(&"beard", &"none")))
	if sheet(beard) != null:
		slots[&"beard"] = {"part": beard, "recolour": hair_colour}
	return slots


static func sheet(part: StringName) -> Texture2D:
	if not _sheets.has(part):
		var path: String = sheet_path(part)
		_sheets[part] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _sheets[part] as Texture2D


## Whether the player can be drawn in layers at all: his parts were baked.
static func ready() -> bool:
	return sheet(&"body") != null


## A material for the player in one of the three shaders, with `slots` in it.
static func material(shader_path: String, slots: Dictionary) -> ShaderMaterial:
	var paint := ShaderMaterial.new()
	paint.shader = load(shader_path) as Shader
	apply(paint, slots)
	return paint


static func apply(paint: ShaderMaterial, slots: Dictionary) -> void:
	for i: int in ORDER.size():
		var slot: Dictionary = slots.get(ORDER[i], {}) as Dictionary
		var texture: Texture2D = sheet(slot.get("part", &"") as StringName) if not slot.is_empty() else null
		paint.set_shader_parameter("doll_l%d" % i, texture)
		var r: Array = slot.get("recolour", []) as Array
		paint.set_shader_parameter("doll_r%d" % i, Vector4(float(r[0]) / 360.0, float(r[1]), float(r[2]), float(r[3]))
			if r.size() == 4 else Vector4.ZERO)
	var mask: Texture2D = slots.get(&"head_mask", null) as Texture2D
	paint.set_shader_parameter("doll_head_mask", mask)
	paint.set_shader_parameter("doll_has_mask", 1.0 if mask != null else 0.0)
