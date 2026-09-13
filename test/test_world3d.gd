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
	var baked: Variant = JSON.parse_string(FileAccess.get_file_as_string(Places.BAKED_PATH))
	assert_true(baked is Dictionary, "the baked world is there")
	if not (baked is Dictionary):
		return
	var region: Region = RegionBake.read(baked as Dictionary)
	var sim: Sim = Game.build()
	var window := World3d.new()
	window.build(region, landscape, Art.new(), sim)

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
		"tents": 6, "crowd": 4, "free": {}, "shuttered": false, "escort": 10, "extra_guards": 0,
	}, 1.0 / 60.0)
	assert_true(window.people_count() >= 30, "the cast stands in the window: %d" % window.people_count())
	assert_eq(world.fingerprint(), before, "the window read the world and wrote nothing")
	window.free()
