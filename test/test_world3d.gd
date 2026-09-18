extends TestCase

## The 3D window (MIGRATION_3D §6, M2a), built headless: no frame is drawn, but every
## mesh, sprite and light is made, which is where a script error would be.
##
## Slow, because it builds his whole landscape and stands a sprite on every tree tile
## of the baked world. It runs in the default process — the window is handed the baked
## region and his landscape directly — because what it checks is that the window
## stands on his ground, not which world the process plays.

const SLOW: bool = true


func test_the_window_stands_on_his_ground() -> void:
	var landscape: Dictionary = RegionBake.read_landscape()
	assert_false(landscape.is_empty(), "his landscape is at %s" % RegionBake.LANDSCAPE)
	if landscape.is_empty():
		return
	assert_true(FileAccess.file_exists(Places.BAKED_PATH), "the baked world is there")
	if not FileAccess.file_exists(Places.BAKED_PATH):
		return
	# Loaded as the game loads it — grid, props, and the content's fires, stalls and
	# papers — so the window has fires to put embers over. The anchors resolve against
	# whichever world this process plays, which is fine for a window that has to stand.
	var region: Region = Region.load_baked()
	var sim: Sim = Game.build()
	var window := World3d.new()
	window.build(region, landscape, Art.new(), sim)

	# With his scenes vendored (tools/vendor_workshop.sh) the window stands on his map
	# plate and lays only the simulation's ground over it; without them it builds the
	# bake's ground itself. CI vendors first, so here the first is the rule.
	assert_true(window.his_present(),
		"his scenes stand in the window — run tools/vendor_workshop.sh if %s is missing" % World3d.HIS_MAP)
	if window.his_present():
		assert_eq(window.chunk_count, 0, "the bake's ground is not built under his")
		var delivered: int = 0
		for prop: Dictionary in region.props:
			if bool(prop.get("his", false)):
				delivered += 1
		assert_eq(window.his_props_skipped, delivered, "every delivered mesh replaces its placeholder")
		assert_true(window.get_node_or_null("HisWorld/Decor/Acierie") != null, "his ironworks scene is present")
		for bridge: Dictionary in (landscape["meta"] as Dictionary)["crossings"]:
			var centre: Array = bridge["center_xyz"]
			assert_true(window.height_at(float(centre[0]), float(centre[2])) >= float(centre[1]) - 0.1,
				"%s carries the walker above the river on its deck" % bridge["id"])
		assert_true(window.his_kit_count > 20,
			"the kit's houses, barns, wells and barrels stand as his library's pieces: %d" % window.his_kit_count)
		assert_true(window.figures_are_his(), "every person is his traveller, not a pack sprite")
	else:
		assert_true(window.chunk_count >= 60, "his ground is built in chunks: %d" % window.chunk_count)
		assert_true(window.water_triangles > 1000, "his water is a surface: %d triangles" % window.water_triangles)
	# Nothing of the 2D game's art stands here (Yannick, 2026-09-14): what his library
	# lacks is a plain block, and a block is what the kilns, the stalls and the fires are.
	assert_true(window.block_count > 0, "what he has not drawn stands as a block: %d" % window.block_count)
	assert_true(window.wall_count > 50,
		"the castle's ramparts stand as blocks you can see: %d" % window.wall_count)
	assert_true(window.prop_count() >= 100, "every prop stands as something: %d" % window.prop_count())

	# His Brindle centre is at 24.95 m in his descriptor; the window agrees with him.
	var brindle: float = window.height_at(175.0, 255.0)
	assert_true(absf(brindle - 24.95) < 0.6, "Brindle stands at his height: %.2f m" % brindle)
	var sea: float = window.height_at(-370.0, 370.0)
	assert_true(sea < 0.0, "and the sea floor is below the sea: %.2f m" % sea)

	# A frame from the clearing: the player, the cast and the guards are placed, and
	# nothing in the simulation moved to do it.
	var world := sim.store(&"world") as WorldState
	var before: String = world.fingerprint()
	window.sync({
		"player": Vector2(292.5, 287.5), "facing": Vector2i(0, 1), "camera": Vector2(292.5, 287.5),
		"tents": 6, "crowd": 4, "free": {}, "shuttered": false, "escort": 10,
		"towns": {&"cinderworks": {"allegiance": 6, "richesse": 0}},
		"extra_guards": 0, "witnesses": ["maddox", "bell"], "now": 3.2,
	}, 1.0 / 60.0)
	assert_true(window.people_count() >= 30, "the cast stands in the window: %d" % window.people_count())
	assert_eq(window.marks_shown(), 2, "two marks, over the two who can see")
	assert_true(window.embers_lit() > 0, "the fires glow: %d embers" % window.embers_lit())
	# **Richesse is what burns** (M2, 2026-09-18). It used to be the freed/held flag, and
	# a works could only be working or dead; now a works at the floor is cold, and the
	# campfires around it are not — somebody still has to eat in a town that has stopped.
	assert_eq(window.embers_lit(), window.ember_count() - window.kiln_embers(),
		"a works with nothing left burns nothing: its furnaces' embers are out")
	if window.his_present():
		var smoke: Array[Node] = window.get_node("HisWorld/Decor/Acierie").find_children("*", "CPUParticles3D", true, false)
		assert_true(smoke.size() > 0, "the delivered active furnaces carry smoke")
		for effect: CPUParticles3D in smoke:
			assert_false(effect.emitting, "a works at the floor stops %s" % effect.get_parent().name)
			assert_false(effect.visible, "old smoke is hidden immediately")
		window.sync({"towns": {&"cinderworks": {"allegiance": 6, "richesse": 10}}}, 1.0 / 60.0)
		for effect: CPUParticles3D in smoke:
			assert_true(effect.emitting and effect.visible, "a works at its ceiling burns everything")

		# And the reading the quest actually starts on: going badly, not dead. Two of
		# his six furnaces, and it must look like neither of the other two states.
		window.sync({"towns": {&"cinderworks": {"allegiance": 6, "richesse": 4}}}, 1.0 / 60.0)
		var middling: int = window.embers_lit()
		window.sync({"towns": {&"cinderworks": {"allegiance": 6, "richesse": 10}}}, 1.0 / 60.0)
		assert_true(middling < window.embers_lit(), "fewer fires than a works that is working")
		window.sync({"towns": {&"cinderworks": {"allegiance": 6, "richesse": 0}}}, 1.0 / 60.0)
		assert_true(middling > window.embers_lit(), "and more than one that has stopped")
	# **The light a place stands in** (M3). Standing in the works, the light is warm
	# while the king holds it and cold when it has turned; the wild has no opinion and
	# keeps the light this window had before there were two numbers.
	# The region the window was built on, not `Places` — on the procedural world those
	# are two different maps, and the window is always over the baked one here.
	var works: Vector2 = Vector2(region.sites[&"cinderworks"] as Vector2i) + Vector2(0.5, 0.5)
	_settle(window, {"player": works, "camera": works,
		"towns": {&"cinderworks": {"allegiance": 9, "richesse": 7}}})
	assert_true(window.light_warmth() > 0.9, "a works the king still holds stands in warm light")
	_settle(window, {"player": works, "camera": works,
		"towns": {&"cinderworks": {"allegiance": 3, "richesse": 1}}})
	assert_true(window.light_warmth() < 0.1, "and one that has turned stands in cold")
	_settle(window, {"player": Vector2(292.5, 287.5), "camera": Vector2(292.5, 287.5),
		"towns": {&"cinderworks": {"allegiance": 3, "richesse": 1}}})
	assert_true(absf(window.light_warmth() - 0.5) < 0.1,
		"the wild has no opinion about the king: %.2f" % window.light_warmth())

	# **What a poor place stops putting out** (P3). The carts, the bundled bars, the
	# firewood stacked ready. Never a building, and never anything standing on ground
	# the simulation already refuses — hiding one of those leaves a wall nobody can see.
	assert_true(window.fading_count() > 0,
		"the works has work in progress to stop putting out: %d pieces" % window.fading_count())
	# Every place at once, so the count is about the rule and not about which fixture
	# happens to name which town.
	var rich: Dictionary = {}
	var poor: Dictionary = {}
	for id: StringName in (Game.build().store(&"towns") as TownState).ids():
		rich[id] = {"allegiance": 6, "richesse": 7}
		poor[id] = {"allegiance": 6, "richesse": 1}
	window.sync({"player": works, "camera": works, "towns": rich}, 1.0 / 60.0)
	assert_eq(window.faded_count(), 0, "a place that is working puts its work out")
	window.sync({"player": works, "camera": works, "towns": poor}, 1.0 / 60.0)
	# Only a place that carries the two numbers can go poor. A piece standing in Brindle
	# or in the capital is in no place's keeping and stays put whatever happens.
	var can_go: int = 0
	for tile: Vector2i in window.fading_tiles():
		if rich.has(region.zone_at(tile)):
			can_go += 1
	assert_true(can_go > 0, "the works has work in progress to stop putting out: %d" % can_go)
	assert_eq(window.faded_count(), can_go,
		"a place that has stopped puts none of its work out, and nowhere else changes")
	for tile: Vector2i in window.fading_tiles():
		assert_true(region.is_passable(tile),
			"%s can be hidden because it never stopped anybody" % tile)

	assert_eq(world.fingerprint(), before, "the window read the world and wrote nothing")
	window.free()


## A second of frames, so an eased value has arrived. The light settles rather than
## switching, because a hard flip at a zone's edge reads as a bug rather than a mood.
func _settle(window: World3d, frame: Dictionary) -> void:
	for _i: int in 90:
		window.sync(frame, 1.0 / 60.0)
