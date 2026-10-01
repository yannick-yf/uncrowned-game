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


## **A pixel that keeps its paint** under its layer's recolouring, by its alpha (2026-10-01):
## every pixel of every layer is opaque, so a layer that is mostly the player's colour —
## the king's surcoat made his — marks the iron that must stay iron at this alpha, and the
## shader recolours only what is fully opaque. 200 of 255: above the shader's half, below
## its 0.9.
const KEEPS_PAINT: float = 200.0 / 255.0


## **His skin without the shadow of his fringe** (the review of group E): worn with every
## cut but his own, under which his shading read as an orange line across the forehead.
const BARE_SKIN: StringName = &"skin_bare"


static func sheet_path(part: StringName) -> String:
	return DIR + String(part) + ".png"


const APPEARANCE: String = "res://content/appearance.json"
const WORLD_SHADER: String = "res://view3d/layers/paper_doll_world.gdshader"
const GHOST_SHADER: String = "res://view3d/layers/paper_doll_ghost.gdshader"
const CANVAS_SHADER: String = "res://view3d/layers/paper_doll_canvas.gdshader"
## The five choices of the creation screen, in its order.
const CHOICES: Array[StringName] = AppearanceRules.ALL

static var _table: Dictionary = {}
static var _sheets: Dictionary = {}


static func _read() -> Dictionary:
	if _table.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(APPEARANCE))
		_table = parsed as Dictionary if parsed is Dictionary else {}
	return _table


static func _list_of(choice: StringName) -> String:
	return AppearanceRules.list_name(choice)


## The options of one choice, in the order the creation screen offers them.
static func options(choice: StringName) -> Array[StringName]:
	return AppearanceRules.options(choice)


## His traveller, exactly: what a player who changes nothing looks like.
static func default_appearance() -> Dictionary:
	return AppearanceRules.default_appearance()


## A recolouring from the table, or `[]` for his own pixels.
static func recolour_of(choice: StringName, option: StringName) -> Array:
	var held: Variant = _read().get(_list_of(choice), {})
	if held is Dictionary and (held as Dictionary).get(String(option)) is Array:
		return (held as Dictionary)[String(option)] as Array
	return []


## **What fills each slot of `ORDER`**: the part's sheet and how it is recoloured, for an
## appearance (group A) and what he wears (group E). `worn` is the inventory's slots — or
## `null` for a run never made, which is drawn as before the inventory: his tunic, his
## trousers, his boots, nothing in his hands. `in_hand` is what a fight has him striking
## with, `&""` outside one: the sword comes out of its scabbard, and the bow off his back,
## for the length of the fight, and a bow is put away while a sword is out.
static func slots_for(appearance: Dictionary, worn: Variant = null, in_hand: StringName = &"") -> Dictionary:
	var hair_colour: Array = recolour_of(&"hair_colour", appearance.get(&"hair_colour", &"") as StringName)
	var skin: Array = recolour_of(&"skin", appearance.get(&"skin", &"") as StringName)
	var clothes: Array = recolour_of(&"clothes", appearance.get(&"clothes", &"") as StringName)
	var slots: Dictionary = {
		&"body": {"part": &"body", "recolour": []},
		&"skin": {"part": &"skin", "recolour": skin},
		&"trousers": {"part": &"trousers", "recolour": []},
		&"boots": {"part": &"boots", "recolour": []},
		&"tunic": {"part": &"tunic", "recolour": clothes},
		&"pack": {"part": &"pack", "recolour": []},
	}
	var hair := StringName("hair_" + String(appearance.get(&"hair_style", &"spiky")))
	if sheet(hair) == null:
		hair = &"hair_spiky"
	slots[&"hair"] = {"part": hair, "recolour": hair_colour}
	if hair != &"hair_spiky" and sheet(BARE_SKIN) != null:
		slots[&"skin"] = {"part": BARE_SKIN, "recolour": skin}
	var beard := StringName("beard_" + String(appearance.get(&"beard", &"none")))
	if sheet(beard) != null:
		slots[&"beard"] = {"part": beard, "recolour": hair_colour}
	if worn is Dictionary:
		_wear(slots, worn as Dictionary, in_hand, clothes, skin)
	return slots


## Where each of the inventory's slots is drawn in `ORDER`.
const DRAWN_IN: Dictionary = {
	ItemRules.TORSO: &"tunic", ItemRules.LEGS: &"trousers", ItemRules.FEET: &"boots",
	ItemRules.HEAD: &"head", ItemRules.WEAPON: &"weapon", ItemRules.BOW: &"back",
}


static func _wear(slots: Dictionary, worn: Dictionary, in_hand: StringName, clothes: Array, skin: Array) -> void:
	var empty: Dictionary = (ItemRules._read().get("empty", {}) as Dictionary)
	for slot: StringName in ItemRules.SLOTS:
		var item: StringName = worn.get(slot, &"") as StringName
		var drawn: StringName = DRAWN_IN[slot] as StringName
		if item == &"":
			var bare: Dictionary = empty.get(String(slot), {}) as Dictionary
			if bare.is_empty():
				slots.erase(drawn)
			else:
				slots[drawn] = {"part": StringName(String(bare.get("layer", ""))),
					"recolour": _named_recolour(bare.get("recolour", []), clothes, skin)}
			continue
		var row: Dictionary = ItemRules.row(item)
		var layer: String = String(row.get("layer", ""))
		if in_hand != &"" and ItemRules.weapon_of(item) == in_hand:
			layer = String(row.get("fighting_layer", layer))
		elif in_hand == DuelRules.SWORD and slot == ItemRules.BOW:
			# A sword out, the bow is put away; fists leave it where it was (the review of E).
			slots.erase(drawn)
			continue
		slots[drawn] = {"part": StringName(layer), "recolour": _named_recolour(row.get("recolour", []), clothes, skin)}
		if bool(row.get("hides_hair", false)):
			slots[&"head_mask"] = sheet(StringName(layer + "_mask"))


## A recolouring as the items' table names it: numbers, or `"clothes"` — the colour chosen
## at creation — or `"skin"`, for bare feet, his leather moved to the skin chosen.
static func _named_recolour(named: Variant, clothes: Array, skin: Array) -> Array:
	if named is Array:
		return named as Array
	match String(named):
		"clothes":
			return clothes
		"skin":
			var bare: Array = [22.0, 0.45, 0.35, 1.75]
			if skin.size() == 4:
				bare = [float(skin[0]), 0.45 * float(skin[1]), 0.35, 1.75 * float(skin[3])]
			return bare
	return []


## The slots a freshly made character wears: his start kit, nothing in his hands.
static func start_kit_worn() -> Dictionary:
	var worn: Dictionary = {}
	for item: StringName in ItemRules.start_kit():
		worn[ItemRules.slot_of(item)] = item
	return worn


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


## **A colour to show beside a choice** on the creation screen: a representative pixel of
## his — a strand of his hair, his cheek, his shirt — moved by that option exactly as the
## shader moves it. `Color(0, 0, 0, 0)` for a choice that is not a colour.
static func swatch(choice: StringName, option: StringName) -> Color:
	var his: Color
	match choice:
		AppearanceRules.HAIR_COLOUR:
			his = Color8(158, 66, 34)
		AppearanceRules.SKIN:
			his = Color8(250, 200, 168)
		AppearanceRules.CLOTHES:
			his = Color8(46, 96, 176)
		_:
			return Color(0, 0, 0, 0)
	var r: Array = recolour_of(choice, option)
	if r.size() != 4:
		return his
	var s: float = minf(maxf(his.s * float(r[1]), float(r[2])), 1.0)
	var v: float = minf(his.v * float(r[3]), 1.0)
	if v > 0.35 and s < 0.24:
		s = 0.24
	return Color.from_hsv(fposmod(float(r[0]), 360.0) / 360.0, s, v)
