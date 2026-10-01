extends TestCase

## The player in layers (group A): his brother's traveller split into the parts a person
## is dressed in, by `tools/draw_player_layers.gd`, and stacked again by a shader.
##
## The one claim that makes the layers trustworthy is checked here: **stacked in
## `PaperDoll.ORDER`, his parts give his traveller back, pixel for pixel** — so a player who
## changes nothing on the creation screen is the character his brother drew, and anything
## else is a change somebody chose.

const SLOW: bool = false


func _base() -> Image:
	var texture: Texture2D = load(World3d.OUR_FIGHT_FRAMES) as Texture2D
	if texture == null:
		return null
	var img: Image = texture.get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _part(part: StringName) -> Image:
	var path: String = PaperDoll.sheet_path(part)
	if not ResourceLoader.exists(path):
		return null
	var img: Image = (load(path) as Texture2D).get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _his_frames() -> SpriteFrames:
	return load(World3d.HIS_FRAMES) as SpriteFrames if ResourceLoader.exists(World3d.HIS_FRAMES) else null


## His parts, in the order the shader stacks them.
func _stacked_order() -> Array[StringName]:
	var out: Array[StringName] = []
	for layer: StringName in PaperDoll.ORDER:
		for part: StringName in PaperDoll.HIS_PARTS:
			if part == layer or (layer == &"hair" and part == &"hair_spiky"):
				out.append(part)
	return out


func test_every_part_is_a_sheet_his_size() -> void:
	var base: Image = _base()
	assert_not_null(base, "his sheet with our fight cells")
	for part: StringName in PaperDoll.HIS_PARTS:
		var img: Image = _part(part)
		assert_not_null(img, "%s is there — run tools/draw_player_layers.gd" % part)
		if img != null and base != null:
			assert_eq(img.get_size(), base.get_size(), "%s has his sheet's size" % part)
	assert_eq(_stacked_order().size(), PaperDoll.HIS_PARTS.size(), "every part of him has its place in the order")


func test_his_parts_stacked_are_his_traveller() -> void:
	var frames: SpriteFrames = _his_frames()
	var base: Image = _base()
	if frames == null or base == null:
		debt("his workshop is not copied in; run tools/vendor_workshop.sh")
		return
	var parts: Array[Image] = []
	for part: StringName in _stacked_order():
		parts.append(_part(part))
	if parts.has(null):
		assert_true(false, "a part is missing — run tools/draw_player_layers.gd")
		return
	# His four idle frames, and three of our cells — a blow, a wind-up and a flinch.
	var rects: Array[Rect2i] = []
	for way: String in ["down", "left", "right", "up"]:
		rects.append(Rect2i((frames.get_frame_texture(StringName("idle_" + way), 0) as AtlasTexture).region))
	var below: int = base.get_height() - World3d.OUR_CELL.y * World3d.OUR_WAYS.size()
	for cell: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(3, 2)]:
		rects.append(Rect2i(cell.x * World3d.OUR_CELL.x, below + cell.y * World3d.OUR_CELL.y, World3d.OUR_CELL.x, World3d.OUR_CELL.y))
	var made: GDScript = load("res://tools/draw_cast_looks.gd") as GDScript
	for rect: Rect2i in rects:
		var differ: int = 0
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				var top := Color(0, 0, 0, 0)
				for img: Image in parts:
					var c: Color = img.get_pixel(x, y)
					if c.a > 0.0:
						top = c
				var his: Color = base.get_pixel(x, y)
				if made.visible(his):
					if not top.is_equal_approx(his):
						differ += 1
				elif top.a > 0.0:
					differ += 1
		assert_eq(differ, 0, "%s: his parts stacked are his traveller, pixel for pixel" % rect)


func test_his_hair_is_its_own_layer_and_a_head_is_under_it() -> void:
	# Take his hair away, and there is a head: the skull painted under it, only where his
	# hair was, in his skin's colour, with his dark outline.
	var frames: SpriteFrames = _his_frames()
	var hair: Image = _part(&"hair_spiky")
	var skin: Image = _part(&"skin")
	if frames == null or hair == null or skin == null:
		debt("his workshop or the layers are missing")
		return
	var region := Rect2i((frames.get_frame_texture(&"idle_down", 0) as AtlasTexture).region)
	var hair_px: int = 0
	var under: int = 0
	for y: int in range(region.position.y, region.end.y):
		for x: int in range(region.position.x, region.end.x):
			if hair.get_pixel(x, y).a > 0.0:
				hair_px += 1
				if skin.get_pixel(x, y).a > 0.0:
					under += 1
	assert_true(hair_px > 3000, "his hair is a layer of its own: %d pixels" % hair_px)
	assert_true(under > hair_px / 4, "and a head stands under it: %d of its pixels" % under)


func test_the_default_appearance_is_his_traveller_unrecoloured() -> void:
	var slots: Dictionary = PaperDoll.slots_for(PaperDoll.default_appearance())
	assert_eq(slots[&"hair"]["part"], &"hair_spiky", "his own hair")
	for slot: StringName in slots.keys():
		assert_eq((slots[slot]["recolour"] as Array).size(), 0, "%s shows his own pixels" % slot)
	assert_false(slots.has(&"beard"), "and no beard")
	for slot: StringName in slots.keys():
		assert_true(PaperDoll.ORDER.has(slot), "%s is a slot of the order" % slot)


func test_a_choice_recolours_its_slot_and_no_other() -> void:
	var blond: Dictionary = PaperDoll.default_appearance()
	blond[&"hair_colour"] = &"blond"
	blond[&"skin"] = &"dark"
	blond[&"clothes"] = &"moss"
	var slots: Dictionary = PaperDoll.slots_for(blond)
	assert_eq(slots[&"hair"]["recolour"], PaperDoll.recolour_of(&"hair_colour", &"blond"), "the hair, blond")
	assert_eq(slots[&"skin"]["recolour"], PaperDoll.recolour_of(&"skin", &"dark"), "the skin, dark")
	assert_eq(slots[&"tunic"]["recolour"], PaperDoll.recolour_of(&"clothes", &"moss"), "the tunic, moss")
	assert_eq((slots[&"trousers"]["recolour"] as Array).size(), 0, "the trousers untouched")
	for choice: StringName in PaperDoll.CHOICES:
		assert_true(PaperDoll.options(choice).size() >= 4, "%s offers its options: %s" % [choice, PaperDoll.options(choice)])
		assert_eq(PaperDoll.options(choice)[0], PaperDoll.default_appearance()[choice], "%s's first option is his" % choice)


func test_the_three_shaders_compile_with_the_slots() -> void:
	for path: String in [PaperDoll.WORLD_SHADER, PaperDoll.GHOST_SHADER, PaperDoll.CANVAS_SHADER]:
		var shader: Shader = load(path) as Shader
		assert_not_null(shader, "%s loads" % path)
		if shader != null:
			var names: Array = []
			for u: Dictionary in shader.get_shader_uniform_list():
				names.append(String(u["name"]))
			for i: int in PaperDoll.ORDER.size():
				assert_true(names.has("doll_l%d" % i) and names.has("doll_r%d" % i), "%s has slot %d" % [path, i])
			assert_true(names.has("doll_head_mask"), "%s has the head gear's mask" % path)
	# **The world recolours the painted colours, not the light** (A7): a 3D shader reads its
	# textures in linear light, and the recipes' numbers are about the painted colours. The
	# first in-game frames showed a brown skin yellow while the creation screen showed it
	# brown. The world's two shaders convert; the screens' does not need to.
	for path: String in [PaperDoll.WORLD_SHADER, PaperDoll.GHOST_SHADER]:
		assert_true((load(path) as Shader).code.contains("#define DOLL_LINEAR"), "%s recolours in sRGB" % path)
	assert_false((load(PaperDoll.CANVAS_SHADER) as Shader).code.contains("DOLL_LINEAR"),
		"the screens' shader already works on the painted colours")


func test_every_style_and_beard_is_drawn_where_it_shows() -> void:
	# A4: five more hair styles and three beards, painted from his hair's texture. Each hair
	# style stands on the head in all four facings; a beard shows from the front and the
	# side, and from behind there is none to see.
	var frames: SpriteFrames = _his_frames()
	if frames == null:
		debt("his workshop is not copied in; run tools/vendor_workshop.sh")
		return
	for part: StringName in PaperDoll.STYLE_PARTS:
		var img: Image = _part(part)
		assert_not_null(img, "%s is there — run tools/draw_player_layers.gd" % part)
		if img == null:
			continue
		for way: String in ["down", "left", "right", "up"]:
			var region := Rect2i((frames.get_frame_texture(StringName("idle_" + way), 0) as AtlasTexture).region)
			var used: int = 0
			for y: int in range(region.position.y, region.end.y):
				for x: int in range(region.position.x, region.end.x):
					if img.get_pixel(x, y).a > 0.0:
						used += 1
			var beard: bool = String(part).begins_with("beard_")
			if beard and way == "up":
				assert_eq(used, 0, "%s: no beard seen from behind" % part)
			else:
				assert_true(used > (40 if beard else 800), "%s stands on him seen %s: %d pixels" % [part, way, used])
	for style: StringName in PaperDoll.options(&"hair_style"):
		assert_true(PaperDoll.sheet(StringName("hair_" + String(style))) != null, "the %s style has its layer" % style)
	for beard: StringName in PaperDoll.options(&"beard"):
		if beard != &"none":
			assert_true(PaperDoll.sheet(StringName("beard_" + String(beard))) != null, "the %s beard has its layer" % beard)


# ------------------------------------------------------------------- what he wears (E4) ---

func test_every_item_is_drawn_and_every_head_gear_has_its_mask() -> void:
	var base: Image = _base()
	for item: StringName in ItemRules.items():
		var row: Dictionary = ItemRules.row(item)
		for key: String in ["layer", "fighting_layer"]:
			if not row.has(key):
				continue
			var layer := StringName(String(row[key]))
			assert_true(PaperDoll.sheet(layer) != null, "%s is drawn in %s" % [item, layer])
			var img: Image = _part(layer)
			if img != null and base != null:
				assert_eq(img.get_size(), base.get_size(), "%s has his sheet's size" % layer)
		if bool(row.get("hides_hair", false)):
			assert_true(PaperDoll.sheet(StringName(String(row["layer"]) + "_mask")) != null,
				"%s hides the hair with a mask" % item)


func test_what_he_wears_fills_its_slot() -> void:
	var his: Dictionary = AppearanceRules.default_appearance()
	var kit: Dictionary = PaperDoll.start_kit_worn()
	var dressed: Dictionary = PaperDoll.slots_for(his, kit)
	assert_eq(dressed[&"tunic"]["part"], &"tunic", "the cloth tunic is his own tunic")
	assert_eq(dressed[&"tunic"]["recolour"], PaperDoll.recolour_of(&"clothes", his[&"clothes"]),
		"in the colour chosen at creation")
	assert_false(dressed.has(&"weapon"), "nothing in his hands at the start")
	var armed: Dictionary = kit.duplicate()
	armed[ItemRules.WEAPON] = &"short_sword"
	armed[ItemRules.BOW] = &"hunting_bow"
	armed[ItemRules.HEAD] = &"royal_helm"
	var walking: Dictionary = PaperDoll.slots_for(his, armed)
	assert_eq(walking[&"weapon"]["part"], &"item_sword_belt", "the sword at his belt, walking")
	assert_eq(walking[&"back"]["part"], &"item_bow", "the bow on him")
	assert_eq(walking[&"head"]["part"], &"item_royal_helm", "the helm on his head")
	assert_true(walking.has(&"head_mask"), "hiding his hair")
	var fighting: Dictionary = PaperDoll.slots_for(his, armed, DuelRules.SWORD)
	assert_eq(fighting[&"weapon"]["part"], &"item_sword_hand", "the sword in his hand, fighting with it")
	assert_false(fighting.has(&"back"), "and the bow put away")
	var shooting: Dictionary = PaperDoll.slots_for(his, armed, DuelRules.BOW)
	assert_eq(shooting[&"weapon"]["part"], &"item_sword_belt", "the sword back at the belt, shooting")
	assert_eq(shooting[&"back"]["part"], &"item_bow_hand", "and the bow in his hand, in use")
	assert_eq(PaperDoll.slots_for(his, armed)[&"back"]["part"], &"item_bow", "walking, on his back (the review of group E)")
	var with_fists: Dictionary = PaperDoll.slots_for(his, {ItemRules.BOW: &"hunting_bow"}, DuelRules.FISTS)
	assert_eq(with_fists[&"back"]["part"], &"item_bow", "and fists leave it on his back")
	var bare: Dictionary = PaperDoll.slots_for(his, {})
	assert_eq(bare[&"tunic"]["part"], &"tunic", "with nothing on, his linen")
	assert_true((bare[&"boots"]["recolour"] as Array).size() == 4, "and bare feet")
	assert_false(PaperDoll.slots_for(his).has(&"weapon"), "a run never made is drawn as before")


func test_a_mask_hides_the_head_under_a_helm() -> void:
	# What the helm's piece took away from his head when it was baked — hair, ears, their
	# outline, the head painted under his hair — so the body's and the skin's slots too.
	var code: String = FileAccess.get_file_as_string("res://view3d/layers/paper_doll.gdshaderinc")
	for i: int in [0, 1, 6, 7]:
		assert_true(code.contains("c = doll_over(c, doll_l%d, doll_r%d, uv, masked);" % [i, i]),
			"slot %d hides under the head gear's mask" % i)
	for i: int in [2, 3, 4, 5, 8, 9, 10]:
		assert_true(code.contains("c = doll_over(c, doll_l%d, doll_r%d, uv, false);" % [i, i]),
			"slot %d does not" % i)



func test_every_cut_but_his_wears_the_skin_without_his_fringe_s_shadow() -> void:
	# The review of group E: his shading under the fringe read as an orange line across
	# the forehead of every other cut. His own cut keeps his own skin, pixel for pixel.
	var his: Dictionary = PaperDoll.default_appearance()
	assert_eq(PaperDoll.slots_for(his)[&"skin"]["part"], &"skin", "his cut, his skin")
	for style: StringName in AppearanceRules.options(&"hair_style"):
		if style == &"spiky":
			continue
		var looks: Dictionary = his.duplicate()
		looks[&"hair_style"] = style
		assert_eq(PaperDoll.slots_for(looks)[&"skin"]["part"], PaperDoll.BARE_SKIN, "%s: the bare skin" % style)
	var bare: Texture2D = PaperDoll.sheet(PaperDoll.BARE_SKIN)
	var own: Texture2D = PaperDoll.sheet(&"skin")
	assert_not_null(bare, "the bare skin is drawn — run tools/draw_player_layers.gd")
	if bare != null and own != null:
		assert_eq(bare.get_size(), own.get_size(), "the same sheet, his size")


func test_the_king_s_surcoat_on_the_player_is_his_colour_and_the_iron_stays_iron() -> void:
	# Yannick, 2026-10-01: in the king's set the player looked exactly like a king's guard.
	# His surcoat takes the colour chosen; the iron keeps its paint, marked in its alpha.
	var row: Dictionary = ItemRules.row(&"royal_breastplate")
	assert_eq(String(row.get("recolour", "")), "clothes", "the breastplate is recoloured as the tunic is")
	var looks: Dictionary = PaperDoll.default_appearance()
	looks[&"clothes"] = &"wine"
	var worn: Dictionary = PaperDoll.slots_for(looks, {ItemRules.TORSO: &"royal_breastplate"})
	assert_eq(worn[&"tunic"]["recolour"], PaperDoll.recolour_of(&"clothes", &"wine"), "in the colour chosen")
	var path: String = PaperDoll.sheet_path(&"item_royal_breastplate")
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path(path)) if FileAccess.file_exists(path) else null
	assert_not_null(img, "the breastplate is drawn — run tools/draw_player_layers.gd")
	if img == null:
		return
	var keeps: int = 0
	var takes: int = 0
	for y: int in range(0, img.get_height(), 2):
		for x: int in range(0, img.get_width(), 2):
			var a: float = img.get_pixel(x, y).a
			if a > 0.9:
				takes += 1
			elif a > 0.5:
				keeps += 1
	assert_true(keeps > 0, "the iron keeps its paint: %d pixels" % keeps)
	assert_true(takes > 0, "the surcoat takes the colour: %d pixels" % takes)
