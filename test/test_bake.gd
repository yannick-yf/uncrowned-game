extends TestCase

## The bake (MIGRATION_3D §6, M1b): his ground becomes our terrain by rules that can
## be read, and the baked file loads into a world every anchor can stand in.
##
## These run on the default world. The baked world is a whole process
## (`tools/run_tests.sh --baked`), because `Region`'s sites are read once; what can be
## checked here is the file and the rules, which is what breaks first.

const BAKED: String = "res://content/region.json"


func test_water_over_ground_is_water_and_the_sea_is_the_sea() -> void:
	assert_eq(BakeRules.terrain_for(20.0, 40.0, 0.0, 0.0), Region.Terrain.WATER, "a lake at 40 m")
	assert_eq(BakeRules.terrain_for(-0.5, 0.0, 0.0, 0.0), Region.Terrain.SEA, "the seabed under sea level")
	assert_eq(BakeRules.terrain_for(1.0, 0.3, 0.0, 0.0), Region.Terrain.WILD, "a bank the water does not reach")
	assert_eq(BakeRules.terrain_for(30.0, 30.02, 0.0, 0.0), Region.Terrain.WILD, "a film thinner than the depth rule is ground")
	assert_eq(BakeRules.terrain_for(10.0, 12.0, 0.9, 0.9), Region.Terrain.WATER, "water wins over rock and sand")


func test_rock_is_mountain_and_sand_is_sand() -> void:
	assert_eq(BakeRules.terrain_for(120.0, 0.0, 0.9, 0.0), Region.Terrain.MOUNTAIN, "his rock paint, at its steepest")
	assert_eq(BakeRules.terrain_for(120.0, 0.0, 0.6, 0.0), Region.Terrain.WILD,
		"a steep bank is walkable — his character climbs it, and a wall nobody sees is a bug")
	assert_eq(BakeRules.terrain_for(2.0, 0.0, 0.0, 0.8), Region.Terrain.SAND, "the beach")
	assert_eq(BakeRules.terrain_for(2.0, 0.0, 0.9, 0.8), Region.Terrain.MOUNTAIN, "a cliff over the beach is rock first")
	assert_eq(BakeRules.terrain_for(30.0, 0.0, 0.0, 0.0), Region.Terrain.WILD, "grass")


func test_two_metres_to_a_tile_and_back() -> void:
	var origin := Vector2(-384.0, -384.0)
	assert_eq(BakeRules.tile_for(-384.0, -384.0, origin), Vector2i(0, 0), "the north-west corner")
	assert_eq(BakeRules.tile_for(383.9, 383.9, origin), Vector2i(383, 383), "the south-east corner")
	assert_eq(BakeRules.tile_for(175.0, 255.0, origin), Vector2i(279, 319), "his Brindle")
	assert_eq(BakeRules.tile_for(-1.0, 0.0, origin), Vector2i(191, 192), "either side of the origin")
	var back: Vector2 = BakeRules.metres_for(Vector2i(279, 319), origin)
	assert_eq(back, Vector2(175.0, 255.0), "a tile's centre is where his metres were")
	assert_eq(BakeRules.tile_for(back.x, back.y, origin), Vector2i(279, 319), "and it rounds trip")


func test_a_row_of_runs_reads_back_exactly() -> void:
	var row := PackedByteArray()
	for i: int in 40:
		row.append(Region.Terrain.SEA if i < 5 else (Region.Terrain.WILD if i < 30 else Region.Terrain.MOUNTAIN))
	row[17] = Region.Terrain.ROAD
	var text: String = BakeRules.encode_row(row)
	assert_eq(text, "4x5 0x12 1x1 0x12 5x10", "runs, in Terrain order")
	assert_eq(BakeRules.decode_row(text, 40), row, "and back")
	assert_eq(BakeRules.decode_row("0x3", 6).slice(3), PackedByteArray([5, 5, 5]),
		"a short row is closed with mountain, never opened with ground")
	assert_eq(BakeRules.decode_row("0x10", 4).size(), 4, "a long row is cut to the width")
	assert_eq(BakeRules.encode_row(PackedByteArray()), "", "an empty row is nothing")


func _baked() -> Dictionary:
	if not FileAccess.file_exists(BAKED):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BAKED))
	return parsed as Dictionary if parsed is Dictionary else {}


func test_the_baked_file_is_a_closed_world_of_the_stated_size() -> void:
	var data: Dictionary = _baked()
	assert_false(data.is_empty(), "content/region.json exists — run tools/bake_region.gd")
	if data.is_empty():
		return
	var region: Region = RegionBake.read(data)
	assert_eq(region.width, 384, "768 m at 2 m a tile")
	assert_eq(region.height, 384)
	var leaks: int = 0
	for x: int in region.width:
		if region.is_passable(Vector2i(x, 0)) or region.is_passable(Vector2i(x, region.height - 1)):
			leaks += 1
	for y: int in region.height:
		if region.is_passable(Vector2i(0, y)) or region.is_passable(Vector2i(region.width - 1, y)):
			leaks += 1
	assert_eq(leaks, 0, "no walkable tile on the edge")
	var kinds: Dictionary = {}
	for y: int in range(0, region.height, 4):
		for x: int in range(0, region.width, 4):
			kinds[region.terrain_at(Vector2i(x, y))] = true
	assert_true(kinds.has(Region.Terrain.SEA) and kinds.has(Region.Terrain.WATER)
		and kinds.has(Region.Terrain.MOUNTAIN) and kinds.has(Region.Terrain.WILD)
		and kinds.has(Region.Terrain.ROAD) and kinds.has(Region.Terrain.FOREST),
		"sea, river, mountain, grass, road and wood all made it onto the grid")
	var ruins: int = 0
	for prop: Dictionary in region.props:
		if (prop["kind"] as StringName) == &"ruin_house":
			ruins += 1
	assert_eq(ruins, 6, "his six ruins stand as props")


## On his map nothing of ours is drawn, so every tile the simulation refuses has to be
## something the player can see: his water and his rock, his meshes, or a block of ours
## standing on a prop. The kit's ring of thicket was the wall nobody saw (Yannick,
## 2026-09-14), and a footprint wider than his cottage was another.
func test_every_wall_on_his_map_is_something_you_can_see() -> void:
	var data: Dictionary = _baked()
	if data.is_empty():
		assert_true(false, "content/region.json exists — run tools/bake_region.gd")
		return
	var region: Region = RegionBake.read(data)
	var covered: Dictionary = {}
	for prop: Dictionary in region.props:
		var at: Vector2i = prop["at"] as Vector2i
		var size: Vector2i = prop.get("size", Vector2i(1, 1)) as Vector2i
		for dx: int in size.x:
			for dy: int in size.y:
				covered[at + Vector2i(dx, dy)] = true
	var thicket: int = 0
	var bare_walls: int = 0
	for y: int in region.height:
		for x: int in region.width:
			var tile := Vector2i(x, y)
			var terrain: Region.Terrain = region.terrain_at(tile)
			if terrain == Region.Terrain.THICKET:
				thicket += 1
			elif terrain == Region.Terrain.WALL and not covered.has(tile):
				bare_walls += 1
	assert_eq(thicket, 0, "no thicket: the ring is his to plant, and until then the wood is open")
	assert_eq(bare_walls, 0, "every wall tile stands under a prop the window draws: %d do not" % bare_walls)


func test_the_baked_world_has_every_place_and_point_the_content_stands_in() -> void:
	var data: Dictionary = _baked()
	if data.is_empty():
		assert_true(false, "content/region.json exists — run tools/bake_region.gd")
		return
	var world: Places = Places.load_from(Places.PATH)
	world.overlay_world(BAKED)
	assert_eq(world.ids(), Region.ZONE_ORDER, "the eight places, in zone order")
	var region: Region = RegionBake.read(data)
	for id: StringName in Region.ZONE_ORDER:
		var centre: Vector2i = world.centre(id)
		assert_true(region.in_bounds(centre), "%s is on the map" % id)
		assert_true(region.is_passable(centre), "%s's centre %s is ground you can stand on" % [id, centre])
	var content: Places = Places.load_from(Places.PATH)
	var needed: Dictionary = {}
	for id: StringName in content.cast_ids():
		var anchor: Dictionary = content.cast_anchor(id)
		if anchor.has("point"):
			needed[anchor["point"]] = true
	for anchor: Dictionary in content.campfires() + content.strangers() + content.stalls():
		if anchor.has("point"):
			needed[anchor["point"]] = true
	for point: StringName in needed.keys():
		assert_true(world.has_point(point), "the baked world names the point '%s' the content stands at" % point)
	assert_true(world.trunk().size() >= 4, "the King's Road is stated as an order of places")
	for id: StringName in world.trunk():
		assert_ne(world.node(id), Places.NOWHERE, "trunk node '%s' is a place or a point" % id)
	assert_true(world.is_scaffold(&"harrowgate"), "and Harrowgate is honestly a scaffold until he builds it")
	assert_false(world.is_scaffold(&"brindle"), "while Brindle is his")


func test_the_delivered_ironworks_replaces_its_scaffold() -> void:
	var data: Dictionary = _baked()
	var town: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		RegionBake.WORKSHOP + "planning/ironworks-town.json")) as Dictionary
	var region: Region = RegionBake.read(data)
	var found: Dictionary = {}
	for prop: Dictionary in data.get("props", []):
		if prop.has("source_id"):
			found[prop["source_id"]] = prop
			var at: Array = prop["at"]
			assert_eq(region.zone_at(Vector2i(int(at[0]), int(at[1]))), &"cinderworks",
				"%s belongs to the Cinderworks, including its new western homes" % prop["source_id"])
	for item: Dictionary in (town["buildings"] as Array) + (town["props"] as Array):
		assert_true(found.has(item["id"]), "his ironworks item %s is in the simulation" % item["id"])
	assert_false(bool(data["places"]["cinderworks"].get("kit_on_his", true)),
		"the Cinderworks has his buildings, so our settlement kit must disappear")
	assert_true((data["source"] as Dictionary).has("planning/ironworks-town.json"),
		"moving a building invalidates the bake")


func test_his_five_bridges_are_named_walkable_crossings() -> void:
	var data: Dictionary = _baked()
	var rivers: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		RegionBake.WORKSHOP + "planning/river-layout-v2.json")) as Dictionary
	var region: Region = RegionBake.read(data)
	for bridge: Dictionary in rivers["crossings"]:
		var id: String = String(bridge["id"])
		assert_true((data["points"] as Dictionary).has(id), "%s is named by the bake" % id)
		if not (data["points"] as Dictionary).has(id):
			continue
		var point: Dictionary = data["points"][id]
		assert_false(bool(point["scaffold"]), "%s is built by the brother" % id)
		var at: Array = point["at"]
		assert_true(region.is_passable(Vector2i(int(at[0]), int(at[1]))), "%s can be crossed" % id)
	assert_true((data["source"] as Dictionary).has("planning/river-routes-v2.json"),
		"the roads now meet his bridge landings")


func test_each_delivered_bridge_joins_its_banks_without_a_detour() -> void:
	var data: Dictionary = _baked()
	var region: Region = RegionBake.read(data)
	var origin := Vector2(float(data["origin_m"][0]), float(data["origin_m"][1]))
	var scale_m: float = float(data["metres_per_tile"])
	for bridge: Dictionary in (RegionBake.read_landscape()["meta"] as Dictionary)["crossings"]:
		var entry: Array = bridge["entry_xyz"]
		var exit: Array = bridge["exit_xyz"]
		var from: Vector2i = BakeRules.tile_for(float(entry[0]), float(entry[2]), origin, scale_m)
		var to: Vector2i = BakeRules.tile_for(float(exit[0]), float(exit[2]), origin, scale_m)
		var path: Array[Vector2i] = Navigation.path(region, from, to)
		assert_false(path.is_empty(), "%s connects both delivered landing markers" % bridge["id"])
		assert_true(path.size() <= ceili(float(bridge["length_m"]) / scale_m) + 4,
			"%s crosses the deck, not a detour to another bridge" % bridge["id"])


func test_the_towns_delivered_door_approaches_are_open() -> void:
	var data: Dictionary = _baked()
	var region: Region = RegionBake.read(data)
	var town: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		RegionBake.WORKSHOP + "planning/ironworks-town.json")) as Dictionary
	var origin := Vector2(float(data["origin_m"][0]), float(data["origin_m"][1]))
	for item: Dictionary in town["buildings"]:
		var approach: Array = (item["approach_xz"] as Array)[0]
		var at: Vector2i = BakeRules.tile_for(float(approach[0]), float(approach[1]), origin,
			float(data["metres_per_tile"]))
		assert_true(region.is_passable(at), "%s's exterior approach remains open" % item["id"])
