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
		if CastLooks.fights_armed(look):
			var armed: String = CastLooks.fight_sheet_path(look)
			assert_true(ResourceLoader.exists(armed), "%s has a sheet to fight in" % look)
			var fighting: Texture2D = load(armed) as Texture2D if ResourceLoader.exists(armed) else null
			if fighting != null and base != null:
				assert_eq(Vector2i(fighting.get_size()), base.get_size(), "%s's fight sheet has his size too" % look)


func test_every_piece_a_recipe_names_is_one_the_tool_draws() -> void:
	var methods: Dictionary = {}
	for row: Dictionary in _tool().get_script_method_list():
		methods[String(row["name"])] = true
	var regions: Array = ["shirt", "skin", "hair", "trousers", "leather"]
	for look: String in CastLooks.looks().keys():
		var recipe: Dictionary = CastLooks.looks()[look] as Dictionary
		for step: Variant in (recipe.get("pieces", []) as Array) + (recipe.get("fight_pieces", []) as Array):
			var piece: String = String((step as Array)[0])
			assert_true(methods.has("_piece_" + piece), "%s wears %s, which the tool draws" % [look, piece])
		for region: String in (recipe.get("recolour", {}) as Dictionary).keys():
			assert_true(regions.has(region), "%s recolours %s, which is a region of him" % [look, region])
			assert_eq(((recipe["recolour"] as Dictionary)[region] as Array).size(), 4,
				"%s's %s: hue, saturation scale, saturation floor, value scale" % [look, region])


func test_the_armed_ones_are_armed() -> void:
	# L9 (Yannick, 2026-09-30): the king's guards carry a sword, *bien sûr*; Bram and the
	# watch draw theirs when they fight, and wear it at the belt otherwise.
	var pieces := func(look: String, key: String) -> Array:
		var out: Array = []
		for step: Variant in (CastLooks.looks()[look] as Dictionary).get(key, []) as Array:
			out.append(String((step as Array)[0]))
		return out
	assert_true(pieces.call("kings_guard", "pieces").has("sword_in_hand"), "the king's guards, sword in hand")
	for look: String in ["bram", "watch"]:
		assert_true(pieces.call(look, "pieces").has("scabbard"), "%s wears his sword at the belt" % look)
		assert_false(pieces.call(look, "pieces").has("sword_in_hand"), "%s does not walk about with it drawn" % look)
		assert_true(pieces.call(look, "fight_pieces").has("sword_in_hand"), "%s draws it in a fight" % look)
		assert_eq(CastLooks.fight_recipe(StringName(look))["pieces"], (CastLooks.looks()[look] as Dictionary)["fight_pieces"],
			"%s fights in his fight's pieces" % look)
	assert_false(CastLooks.fights_armed(&"villager_a"), "a villager has no second sheet")


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
	# Widened against widened, as the tool checks: two rooms that overlap would have one
	# frame's plume written over another's boots.
	for a: Rect2i in regions:
		for b: Rect2i in regions:
			if a != b:
				assert_false(CastLooks.with_room(a, room).intersects(CastLooks.with_room(b, room)),
					"%s and %s widened by %d overlap — a frame would show its neighbour's pixels" % [a, b, room])
	# And every frame's margin gives the room back, so a widened frame is exactly as large.
	for named: StringName in frames.get_animation_names():
		for i: int in frames.get_frame_count(named):
			var slice := frames.get_frame_texture(named, i) as AtlasTexture
			assert_true(slice.margin.position.x >= room and slice.margin.position.y >= room
				and slice.margin.size.x >= room * 2 and slice.margin.size.y >= room,
				"%s %d's margin %s has room for %d" % [named, i, slice.margin, room])


func test_the_tool_reads_ours_and_writes_beside_the_window() -> void:
	var made: Dictionary = _tool().get_script_constant_map()
	assert_eq(made.get("BASE_SHEET", ""), "view3d/fight/traveler_sheet.png",
		"it dresses his sheet with our fight frames under it, so a look can fight")
	assert_true(CastLooks.DIR.begins_with("res://view3d/"), "the looks live beside the 3D window, not in assets/")


# ------------------------------------------------------------------- who wears what (L2) ---

func test_everybody_the_demo_shows_wears_a_look_of_the_table() -> void:
	var names: Array[StringName] = CastLooks.names()
	var sim: Sim = Game.build()
	var cast := sim.store(&"cast") as Cast
	var region: Region = (sim.store(&"world") as WorldState).region()
	# **Named in the table, not fallen back on** (the review of group L): `of_person` gives
	# anybody unlisted a villager, which always resolves — so the check is that nobody
	# the cast names, and no trade a stranger has, relies on it.
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CastLooks.FILE)) as Dictionary
	var people: Dictionary = table.get("people", {}) as Dictionary
	var strangers: Dictionary = table.get("strangers", {}) as Dictionary
	var dressed: int = 0
	for id: StringName in cast.npcs.keys():
		var npc: Npc = cast.npcs[id] as Npc
		if id == OpeningRules.FAIRY:
			continue
		if npc.generic:
			assert_true(strangers.has(String(npc.kind)), "a %s stranger has a look of his trade" % npc.kind)
		else:
			assert_true(people.has(String(id)), "%s is dressed by name in content/looks.json" % id)
		var look: StringName = CastLooks.of_person(npc.id, npc.kind, region.zone_at(npc.tile))
		assert_true(names.has(look), "%s wears %s, which is a look" % [id, look])
		dressed += 1
	assert_true(dressed >= 30, "the cast and its strangers: %d" % dressed)


func test_the_named_ones_the_demo_needs_wear_their_own() -> void:
	assert_eq(CastLooks.of_person(&"bram", &"", &"brindle"), &"bram", "Bram")
	assert_eq(CastLooks.of_person(&"wren", &"", &"brindle"), &"wren", "Wren")
	for worker: StringName in [&"tom", &"sena", &"harry"]:
		assert_true(String(CastLooks.of_person(worker, &"", &"cinderworks")).begins_with("worker_"),
			"%s works the furnaces and dresses for it" % worker)
	assert_eq(CastLooks.of_person(&"gatekeeper@1", &"gatekeeper", &"cinderworks"), &"works_guard",
		"the works' gatekeeper wears its livery")
	assert_eq(CastLooks.of_person(&"watchman@1", &"watchman", &"cinderworks"), &"works_guard",
		"the works dress their own watchmen")
	assert_eq(CastLooks.of_person(&"watchman@3", &"watchman", &"wide_acres"), &"watch",
		"and everywhere else a watchman is the king's")


func test_the_works_watchmen_where_they_stand_wear_its_livery() -> void:
	# The place comes from their own tiles, not from a name written into the test.
	var sim: Sim = Game.build()
	var cast := sim.store(&"cast") as Cast
	var region: Region = (sim.store(&"world") as WorldState).region()
	var at_the_works: int = 0
	for npc: Npc in cast.npcs.values():
		if npc.kind != &"watchman":
			continue
		var place: StringName = region.zone_at(npc.tile)
		var look: StringName = CastLooks.of_person(npc.id, npc.kind, place)
		if place == &"cinderworks":
			at_the_works += 1
			assert_eq(look, &"works_guard", "%s stands in the works and wears its livery" % npc.id)
		else:
			assert_eq(look, &"watch", "%s stands in %s and is the king's" % [npc.id, place])
	assert_eq(at_the_works, 2, "the works' two watchmen stand in the works")


func test_a_fighter_s_look_follows_his_kind() -> void:
	# Heavy plate means unbeatable, and nothing else wears it among the fighters.
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/duel.json")) as Dictionary
	for kind: String in (table["fighters"] as Dictionary).keys():
		if kind.begins_with("_") or not DuelRules.is_person(StringName(kind)):
			continue
		var look: StringName = CastLooks.of_fighter(StringName(kind))
		assert_true(CastLooks.names().has(look), "a %s fights in a look: %s" % [kind, look])
	assert_eq(CastLooks.of_fighter(&"kings_guard"), &"kings_guard", "the king's guards in plate")
	assert_eq(CastLooks.of_fighter(&"works_guard"), &"works_guard", "the quest's swordsman")
	assert_eq(CastLooks.of_fighter(&"works_archer"), &"works_archer", "and its archers")
	assert_eq(CastLooks.of_fighter(&"wolf"), &"", "a wolf is not a man")
	assert_eq(CastLooks.escort(), &"kings_guard", "the escort is the king's guards")


func test_every_look_is_worn_by_somebody() -> void:
	var table: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CastLooks.FILE)) as Dictionary
	var worn: Dictionary = {}
	for section: String in ["people", "strangers", "fighters"]:
		for who: String in (table.get(section, {}) as Dictionary).keys():
			worn[String((table[section] as Dictionary)[who])] = true
	for place: String in (table.get("strangers_by_place", {}) as Dictionary).keys():
		for look: Variant in ((table["strangers_by_place"] as Dictionary)[place] as Dictionary).values():
			worn[String(look)] = true
	for pool: String in ["crowd", "workers"]:
		for look: Variant in table.get(pool, []) as Array:
			worn[String(look)] = true
	worn[String(table.get("escort", ""))] = true
	for look: StringName in CastLooks.names():
		assert_true(worn.has(String(look)), "%s is worn by somebody, or it is a sheet for nothing" % look)
	for look: String in worn.keys():
		assert_true(CastLooks.names().has(StringName(look)), "%s, worn, is a look with a recipe" % look)


func test_a_look_s_frames_keep_his_frames_sizes() -> void:
	# His feet stand where they stood: a look's frame is widened by the room kept round it
	# and its margin gives the room back, so the frame is exactly as large.
	var frames: SpriteFrames = _his_frames()
	var path: String = CastLooks.sheet_path(&"wren")
	if frames == null or not ResourceLoader.exists(path):
		debt("his workshop or the looks are missing; run tools/vendor_workshop.sh and tools/draw_cast_looks.gd")
		return
	var dressed: SpriteFrames = CastLooks.frames_for(frames, load(path) as Texture2D)
	for named: StringName in frames.get_animation_names():
		assert_eq(dressed.get_frame_count(named), frames.get_frame_count(named), "%s: every frame" % named)
		for i: int in frames.get_frame_count(named):
			var his := frames.get_frame_texture(named, i) as AtlasTexture
			var ours := dressed.get_frame_texture(named, i) as AtlasTexture
			assert_eq(ours.get_size(), his.get_size(), "%s %d: the same size" % [named, i])
			assert_eq(ours.region.end.y, his.region.end.y, "%s %d: his feet on the same edge" % [named, i])
			assert_true(ours.atlas != his.atlas, "%s %d: drawn from the look's sheet" % [named, i])


# ------------------------------------------------------------------- fresh sheets ---

func test_the_sheets_were_drawn_from_the_recipes_as_they_stand() -> void:
	# **A recipe edited without the tool rerun** (the review of group L) leaves every
	# other test green and the old look on the screen. The tool's full run writes the
	# recipes it drew from; they have to be the ones in the content.
	assert_true(FileAccess.file_exists(CastLooks.RECIPES_DRAWN), "the tool says what it drew from")
	var drawn: Variant = JSON.parse_string(FileAccess.get_file_as_string(CastLooks.RECIPES_DRAWN))
	assert_true(drawn is Dictionary, "and it reads")
	if not drawn is Dictionary:
		return
	assert_eq(float((drawn as Dictionary).get("room_px", -1)), float(CastLooks.room_px()), "with the same room")
	var then: Dictionary = (drawn as Dictionary).get("looks", {}) as Dictionary
	for look: String in CastLooks.looks().keys():
		assert_true(then.has(look), "%s was drawn — run tools/draw_cast_looks.gd" % look)
		if then.has(look):
			assert_true(then[look] == CastLooks.looks()[look],
				"%s's recipe changed since its sheet was drawn — run tools/draw_cast_looks.gd" % look)
	assert_eq(then.size(), CastLooks.looks().size(), "and no look was drawn that is not in the content")


func test_a_frame_dressed_now_is_the_one_on_disk() -> void:
	# And the tool itself: two frames dressed in memory, the pieces that do the most,
	# held pixel for pixel against the committed sheets.
	var frames: SpriteFrames = _his_frames()
	var base: Image = _base()
	if frames == null or base == null:
		debt("his workshop is not copied in; run tools/vendor_workshop.sh")
		return
	var made: GDScript = _tool()
	var room: int = CastLooks.room_px()
	var region := Rect2i((frames.get_frame_texture(&"idle_left", 0) as AtlasTexture).region)
	var rect: Rect2i = CastLooks.with_room(region, room)
	for look: StringName in [&"kings_guard", &"wren"]:
		var fresh: Image = made.dress_region(base, region, &"left", CastLooks.looks()[String(look)] as Dictionary, room)
		var disk: Image = (load(CastLooks.sheet_path(look)) as Texture2D).get_image()
		disk.convert(Image.FORMAT_RGBA8)
		var differ: int = 0
		for y: int in rect.size.y:
			for x: int in rect.size.x:
				var a: Color = fresh.get_pixel(x, y)
				var b: Color = disk.get_pixel(rect.position.x + x, rect.position.y + y)
				if (a.a > 0.0 or b.a > 0.0) and not a.is_equal_approx(b):
					differ += 1
		assert_eq(differ, 0, "%s idle_left dressed now matches its sheet — run tools/draw_cast_looks.gd" % look)


func test_our_fight_cells_are_not_widened() -> void:
	# `frames_for` widens his frames only; ours have no margin to give the room back.
	var cell := AtlasTexture.new()
	cell.region = Rect2(0, 887, 160, 200)
	var frames := SpriteFrames.new()
	frames.add_animation(&"attack_left")
	frames.add_frame(&"attack_left", cell)
	var dressed: SpriteFrames = CastLooks.frames_for(frames, ImageTexture.new())
	var ours := dressed.get_frame_texture(&"attack_left", 0) as AtlasTexture
	assert_eq(ours.region, cell.region, "a fight cell keeps its rectangle")
	assert_eq(ours.margin, Rect2(), "and has no margin")
