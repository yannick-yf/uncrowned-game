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
	# papers — so the window has fires to put embers over. In this process the anchors
	# resolve against the 2D places, which is fine for a window that only has to stand.
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
		assert_true(window.overlay_chunks > 0,
			"the bake's roads and towns lie over his ground: %d overlay chunks" % window.overlay_chunks)
		assert_eq(window.his_props_skipped, 6, "his six ruins are his meshes, not our sprites")
	else:
		assert_true(window.chunk_count >= 60, "his ground is built in chunks: %d" % window.chunk_count)
		assert_true(window.water_triangles > 1000, "his water is a surface: %d triangles" % window.water_triangles)
	assert_true(window.tree_count > 1000, "the wood stands: %d billboards" % window.tree_count)
	assert_true(window.prop_count() >= 100, "every prop has a sprite: %d" % window.prop_count())

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
		"tents": 6, "crowd": 4, "free": {&"cinderworks": true}, "shuttered": false, "escort": 10,
		"extra_guards": 0, "witnesses": ["maddox", "bell"], "now": 3.2,
	}, 1.0 / 60.0)
	assert_true(window.people_count() >= 30, "the cast stands in the window: %d" % window.people_count())
	assert_eq(window.marks_shown(), 2, "two marks, over the two who can see")
	assert_true(window.embers_lit() > 0, "the fires glow: %d embers" % window.embers_lit())
	assert_eq(window.embers_lit(), window.ember_count() - window.kiln_embers(),
		"and a freed Cinderworks is cold: its kilns' embers are out")
	assert_eq(world.fingerprint(), before, "the window read the world and wrote nothing")
	window.free()
