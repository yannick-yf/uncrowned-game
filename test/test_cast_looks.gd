extends TestCase

## The cast's looks (group L, 2026-09-30): his traveller dressed as each kind of person
## the demo shows, by `tools/draw_cast_looks.gd`, from the recipes in `content/looks.json`.
##
## What a machine can say about them is said here: every look named has a recipe the tool
## can follow and a sheet the window can load; the tool measures his frames the way the
## recipes assume; a look keeps his outline; and the room kept round his frames never
## reaches another frame. Whether a look is any *good* is a question for
## `docs/frames/cast/looks.png` and a pair of eyes — `--headless` never draws.

const SLOW: bool = false

const TOOL: String = "res://tools/draw_cast_looks.gd"


func _tool() -> GDScript:
	return load(TOOL) as GDScript


func _base() -> Image:
	var texture: Texture2D = load(World3d.OUR_FIGHT_FRAMES) as Texture2D
	return texture.get_image() if texture != null else null


func _his_frames() -> SpriteFrames:
	return load(World3d.HIS_FRAMES) as SpriteFrames if ResourceLoader.exists(World3d.HIS_FRAMES) else null


func test_every_look_has_a_sheet_the_size_of_his() -> void:
	var names: Array[StringName] = CastLooks.names()
	assert_true(names.size() >= 10, "the demo's kinds of people: %s" % str(names))
	var base: Image = _base()
	assert_not_null(base, "the sheet the looks are made from")
	for look: StringName in names:
		var path: String = CastLooks.sheet_path(look)
		assert_true(ResourceLoader.exists(path), "%s has a sheet — run tools/draw_cast_looks.gd" % look)
		if not ResourceLoader.exists(path):
			continue
		var sheet: Texture2D = load(path) as Texture2D
		assert_not_null(sheet, "%s loads" % look)
		if sheet != null and base != null:
			assert_eq(Vector2i(sheet.get_size()), base.get_size(),
				"%s has his sheet's size, so every frame lands where it did" % look)


func test_every_piece_a_recipe_names_is_one_the_tool_draws() -> void:
	var methods: Dictionary = {}
	for row: Dictionary in _tool().get_script_method_list():
		methods[String(row["name"])] = true
	var regions: Array = ["shirt", "skin", "hair", "trousers", "leather"]
	for look: String in CastLooks.looks().keys():
		var recipe: Dictionary = CastLooks.looks()[look] as Dictionary
		for step: Variant in recipe.get("pieces", []) as Array:
			var piece: String = String((step as Array)[0])
			assert_true(methods.has("_piece_" + piece), "%s wears %s, which the tool draws" % [look, piece])
		for region: String in (recipe.get("recolour", {}) as Dictionary).keys():
			assert_true(regions.has(region), "%s recolours %s, which is a region of him" % [look, region])
			assert_eq(((recipe["recolour"] as Dictionary)[region] as Array).size(), 4,
				"%s's %s: hue, saturation scale, saturation floor, value scale" % [look, region])


func test_the_king_s_guards_stand_taller_and_nobody_else_does() -> void:
	# Half of what makes them look unbeatable; anybody else drawn larger would read as
	# one of them.
	assert_eq(CastLooks.scale_of(&"kings_guard"), 1.2, "a fifth over everybody")
	for look: StringName in CastLooks.names():
		if look != &"kings_guard":
			assert_eq(CastLooks.scale_of(look), 1.0, "%s stands at a man's height" % look)


func test_his_idle_frames_are_measured_as_the_recipes_assume() -> void:
	var frames: SpriteFrames = _his_frames()
	var base: Image = _base()
	if frames == null or base == null:
		debt("his workshop is not copied in; run tools/vendor_workshop.sh")
		return
	var made: GDScript = _tool()
	var fig_class: GDScript = made.get_script_constant_map()["Fig"] as GDScript
	for way: String in ["down", "left", "right", "up"]:
		var slice := frames.get_frame_texture(StringName("idle_" + way), 0) as AtlasTexture
		var region := Rect2i(slice.region)
		var img: Image = Image.create(region.size.x, region.size.y, false, Image.FORMAT_RGBA8)
		for y: int in region.size.y:
			for x: int in region.size.x:
				var c: Color = base.get_pixel(region.position.x + x, region.position.y + y)
				img.set_pixel(x, y, c if made.visible(c) else Color(0, 0, 0, 0))
		var fig: Object = fig_class.new(img, StringName(way))
		made._measure(fig, null)
		var neck: int = fig.get("neck")
		var head: Vector4i = fig.get("head")
		assert_true(neck > region.size.y / 2 and neck < region.size.y * 3 / 4,
			"%s: his neck is under his great head (%d of %d)" % [way, neck, region.size.y])
		assert_true(head.y < 12 and head.w < neck, "%s: his head is the top of the frame" % way)
		assert_eq(fig.get("has_face"), way != "up", "%s: a face, unless seen from behind" % way)
		assert_true((fig.get("hands") as Array).size() >= 20, "%s: his hands are found" % way)
		var pack: PackedByteArray = fig.get("pack")
		assert_eq(pack.count(1) > 100, way != "down", "%s: his pack is found where it shows" % way)


func test_a_look_keeps_his_outline() -> void:
	# Recoloured, not repainted: where he drew his dark line, a villager with nothing on
	# his head still has it, pixel for pixel.
	var frames: SpriteFrames = _his_frames()
	var base: Image = _base()
	var path: String = CastLooks.sheet_path(&"villager_c")
	if frames == null or base == null or not ResourceLoader.exists(path):
		debt("his workshop or the looks are missing; run tools/vendor_workshop.sh and tools/draw_cast_looks.gd")
		return
	var look: Image = (load(path) as Texture2D).get_image()
	var region := Rect2i((frames.get_frame_texture(&"idle_down", 0) as AtlasTexture).region)
	var his_ink: int = 0
	var kept: int = 0
	for y: int in range(region.position.y, region.end.y):
		for x: int in range(region.position.x, region.end.x):
			var c: Color = base.get_pixel(x, y)
			if c.a > 0.5 and c.v < 0.13:
				his_ink += 1
				if look.get_pixel(x, y).is_equal_approx(c):
					kept += 1
	assert_true(his_ink > 1000, "his outline is there to keep (%d)" % his_ink)
	assert_true(kept >= his_ink * 95 / 100, "%d of his %d outline pixels kept" % [kept, his_ink])


func test_the_room_round_his_frames_reaches_no_other_frame() -> void:
	var frames: SpriteFrames = _his_frames()
	if frames == null:
		debt("his workshop is not copied in; run tools/vendor_workshop.sh")
		return
	var room: int = CastLooks.room_px()
	var regions: Array[Rect2i] = []
	for named: StringName in frames.get_animation_names():
		for i: int in frames.get_frame_count(named):
			var region := Rect2i((frames.get_frame_texture(named, i) as AtlasTexture).region)
			if not regions.has(region):
				regions.append(region)
	for a: Rect2i in regions:
		for b: Rect2i in regions:
			if a != b:
				assert_false(CastLooks.with_room(a, room).intersects(b),
					"%s widened by %d reaches %s — a frame would show its neighbour's boots" % [a, room, b])
	# And the margins give the room back, so a widened frame is exactly as large.
	for named: StringName in frames.get_animation_names():
		var slice := frames.get_frame_texture(named, 0) as AtlasTexture
		assert_true(slice.margin.position.x >= room and slice.margin.position.y >= room
			and slice.margin.size.x >= room * 2 and slice.margin.size.y >= room,
			"%s's margin %s has room for %d" % [named, slice.margin, room])


func test_the_tool_reads_ours_and_writes_beside_the_window() -> void:
	var made: Dictionary = _tool().get_script_constant_map()
	assert_eq(made.get("BASE_SHEET", ""), "view3d/fight/traveler_sheet.png",
		"it dresses his sheet with our fight frames under it, so a look can fight")
	assert_true(CastLooks.DIR.begins_with("res://view3d/"), "the looks live beside the 3D window, not in assets/")
