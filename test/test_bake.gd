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


# ------------------------------------------- his final ground round Brindle (O11) ---
#
# Yannick, 2026-09-29: the bake learns his coast, around Brindle only. Inside the brief's
# box the bake reads the ground his own runtime makes — relief stamps, earthworks, the
# coast's edits, the rock repainted over it all — and not his raw files.

func _brindle_coast() -> Region:
	var data: Dictionary = _baked()
	if data.is_empty():
		return null
	return RegionBake.read(data)


func test_his_cliffs_south_of_brindle_are_rock() -> void:
	var region: Region = _brindle_coast()
	assert_not_null(region, "the baked world is there")
	if region == null:
		return
	# Tiles his raw paint calls grass and his runtime paints as cliff: before O11 they
	# could be walked up while the window drew a rock face.
	for tile: Vector2i in [Vector2i(229, 333), Vector2i(238, 333), Vector2i(331, 333), Vector2i(232, 336)]:
		assert_eq(region.terrain_at(tile), Region.Terrain.MOUNTAIN, "%s is his cliff" % tile)


func test_his_coastal_paths_are_road() -> void:
	var region: Region = _brindle_coast()
	if region == null:
		assert_true(false, "the baked world is there")
		return
	var coast: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		RegionBake.WORKSHOP + "planning/coastline.json")) as Dictionary
	var trails: Array = (coast.get("trails", []) as Array) + (coast.get("approach_grading", []) as Array)
	assert_eq(trails.size(), 3, "his two trails and his graded approach")
	for entry: Variant in trails:
		var trail: Dictionary = entry as Dictionary
		for point: Variant in trail["profile_xzy"] as Array:
			var p: Array = point as Array
			var tile: Vector2i = BakeRules.tile_for(float(p[0]), float(p[1]), Vector2(-384, -384), 2.0)
			assert_eq(region.terrain_at(tile), Region.Terrain.ROAD, "%s is walkable at %s" % [trail["id"], tile])


func test_the_southern_shore_is_a_pocket_whose_one_way_out_is_his_approach() -> void:
	# The funnel Yannick asked for, already drawn by his brother: the cove and the cape
	# below Brindle reach the rest of the world only up his graded approach.
	var region: Region = _brindle_coast()
	if region == null:
		assert_true(false, "the baked world is there")
		return
	var coast: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		RegionBake.WORKSHOP + "planning/coastline.json")) as Dictionary
	var dam: Dictionary = {}
	var grading: Array = ((coast["approach_grading"] as Array)[0] as Dictionary)["profile_xzy"] as Array
	for i: int in grading.size() - 1:
		var from: Vector2 = Vector2(BakeRules.tile_for(float(grading[i][0]), float(grading[i][1]), Vector2(-384, -384), 2.0))
		var to: Vector2 = Vector2(BakeRules.tile_for(float(grading[i + 1][0]), float(grading[i + 1][1]), Vector2(-384, -384), 2.0))
		for s: int in 21:
			var centre: Vector2i = Vector2i(from.lerp(to, float(s) / 20.0).round())
			for dx: int in range(-3, 4):
				for dy: int in range(-3, 4):
					dam[centre + Vector2i(dx, dy)] = true
	var brindle: Vector2i = region.zone_sites()[&"brindle"] as Vector2i
	for start: Vector2i in [Vector2i(238, 348), Vector2i(290, 356)]:
		assert_true(region.is_passable(start), "%s is ground" % start)
		assert_true(_reach(region, start, {}).has(brindle), "from %s you can walk to Brindle" % start)
		var sealed: Dictionary = _reach(region, start, dam)
		assert_false(sealed.has(brindle), "but not without his approach, from %s" % start)
		assert_true(sealed.size() < 400, "the shore below is a pocket: %d tiles from %s" % [sealed.size(), start])


func test_his_coast_is_part_of_what_a_stale_bake_is_measured_against() -> void:
	var source: Dictionary = _baked().get("source", {}) as Dictionary
	for file: String in ["planning/coastline.json", "assets/coastline/terrain_edits.f32",
			"scripts/flat_ground.gd", "scenes/relief_godot.tscn", "scripts/coastal_terrain.gd"]:
		assert_true(source.has(file), "%s is hashed into the bake" % file)


func _reach(region: Region, from: Vector2i, dam: Dictionary) -> Dictionary:
	var seen: Dictionary = {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_back()
		for dx: int in [-1, 0, 1]:
			for dy: int in [-1, 0, 1]:
				var next := at + Vector2i(dx, dy)
				if seen.has(next) or dam.has(next) or not region.in_bounds(next) or not region.is_passable(next):
					continue
				seen[next] = true
				queue.append(next)
	return seen


# ------------------------------------------------------- the cemetery (O13) ---
#
# The game begins among graves (O12), and they have to be seen. His pieces only: his
# farm fence and gate, his library's boulder made small for each stone, and his loose
# earth and fallow narrowed over each grave. A yard on a point — dressed, not closed.

func _cemetery(region: Region) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for prop: Dictionary in region.props:
		if String(prop.get("yard", "")) == "cemetery":
			out.append(prop)
	return out


func test_the_cemetery_has_graves_a_fence_and_a_gate_all_his() -> void:
	var data: Dictionary = _baked()
	if data.is_empty():
		assert_true(false, "content/region.json exists — run tools/bake_region.gd")
		return
	var region: Region = RegionBake.read(data)
	var count: Dictionary = {}
	var stones: Dictionary = {}
	for prop: Dictionary in _cemetery(region):
		if String(prop["piece"]) == "boulder_round":
			stones[prop["at"]] = true
	for prop: Dictionary in _cemetery(region):
		count[String(prop["piece"])] = int(count.get(String(prop["piece"]), 0)) + 1
		assert_true(String(prop["scene"]).begins_with("res://assets/")
			or String(prop["scene"]).begins_with(YardRules.LIBRARY),
			"%s is one of his scenes: %s" % [prop["piece"], prop["scene"]])
		var at: Vector2i = prop["at"] as Vector2i
		if String(prop["piece"]) == "boulder_round":
			var scale: Vector3 = prop.get("scale", Vector3.ONE) as Vector3
			assert_true(scale.x < 0.5 and scale.y < 1.0, "a grave's stone is his boulder made small: %s" % scale)
			assert_eq(region.terrain_at(at), Region.Terrain.WALL, "and you walk round it, at %s" % at)
		elif String(prop["role"]) == String(YardRules.ROLE_GROUND):
			# The earth stops nobody; the stone at its head is what the tile is walled for.
			assert_true(region.is_passable(at) or stones.has(at),
				"the earth over a grave closes nothing of its own, at %s" % at)
	assert_true(int(count.get("boulder_round", 0)) >= 5, "five graves at least: %s" % count)
	assert_true(int(count.get("sol_cultive_raccord", 0)) + int(count.get("jachere_irreguliere", 0))
		== int(count.get("boulder_round", 0)), "and every stone has its grave under it: %s" % count)
	assert_true(int(count.get("cloture_rustique_2m", 0)) >= 4, "his meadow fence: %s" % count)
	assert_eq(int(count.get("portail_fermier_ouvert", 0)), 1, "and his gate in it")


func test_nothing_of_the_cemetery_stands_on_his_trail() -> void:
	var data: Dictionary = _baked()
	if data.is_empty():
		assert_true(false, "content/region.json exists — run tools/bake_region.gd")
		return
	var region: Region = RegionBake.read(data)
	var origin := Vector2(float((data["origin_m"] as Array)[0]), float((data["origin_m"] as Array)[1]))
	var metres: float = float(data["metres_per_tile"])
	var checked: int = 0
	for prop: Dictionary in _cemetery(region):
		var xz: Vector2 = prop["xz"] as Vector2
		var under: Vector2i = BakeRules.tile_for(xz.x, xz.y, origin, metres)
		assert_ne(region.terrain_at(under), Region.Terrain.ROAD, "%s at %s is off his trail" % [prop["piece"], under])
		var at: Vector2i = prop["at"] as Vector2i
		var size: Vector2i = prop["size"] as Vector2i
		for dx: int in size.x:
			for dy: int in size.y:
				assert_ne(region.terrain_at(at + Vector2i(dx, dy)), Region.Terrain.ROAD,
					"and so is all it stops")
		checked += 1
	assert_true(checked > 0, "the cemetery stands something to check")


func test_every_piece_of_the_cemetery_is_part_of_what_a_stale_bake_is_measured_against() -> void:
	var data: Dictionary = _baked()
	if data.is_empty():
		assert_true(false, "content/region.json exists — run tools/bake_region.gd")
		return
	var source: Dictionary = data.get("source", {}) as Dictionary
	assert_true(source.has("assets/farming/catalog.json"), "his farming catalogue is hashed")
	for prop: Dictionary in _cemetery(RegionBake.read(data)):
		var relative: String = String(prop["scene"]).trim_prefix("res://")
		assert_true(source.has(relative), "%s's scene is hashed: %s" % [prop["piece"], relative])


func test_a_scaled_piece_reads_back_at_its_scale() -> void:
	var region: Region = RegionBake.read({"width": 1, "height": 1, "rows": ["0x1"], "props": [
		{"kind": "boulder_round", "at": [0, 0], "size": [1, 1], "xz": [1.0, 1.0], "yaw": 5.0,
		 "lift": 0.0, "scale": [0.4, 0.75, 0.2]},
		{"kind": "fence", "at": [0, 0], "size": [1, 1], "xz": [1.0, 1.0], "yaw": 0.0, "lift": 0.0}]})
	assert_eq(region.props[0]["scale"], Vector3(0.4, 0.75, 0.2), "each axis as it was baked")
	assert_false(region.props[1].has("scale"), "and a piece at his size carries none")


func test_his_brother_has_drawn_no_grave() -> void:
	# **A DEBT and not a failure.** Nothing in his library or his catalogues is a grave,
	# a headstone or a cross, so the cemetery's stones are his boulder made small and its
	# mounds his loose earth and fallow narrowed — his, and it shows as makeshift.
	# `docs/POUR_SLOSINIO.md` asks him for a cemetery kit; the day one arrives, this fails
	# and the brief's cemetery is rebuilt from it.
	var found: PackedStringArray = PackedStringArray()
	for folder: String in ["assets", "prototype_3d/assets/library"]:
		var at: String = "res://view3d/workshop/%s" % folder
		if DirAccess.dir_exists_absolute(at):
			for name: String in _files_under(at):
				var lower: String = name.to_lower()
				for word: String in ["grave", "tomb", "stele", "stèle", "croix", "cemetery", "cimetiere", "headstone"]:
					if lower.contains(word):
						found.append(name)
	if found.is_empty():
		debt("his brother has drawn no grave: the cemetery's stones are his boulder made small")
		return
	assert_true(false, "he has drawn one — rebuild the cemetery from it: %s" % ", ".join(found))


func _files_under(path: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var listing: DirAccess = DirAccess.open(path)
	if listing == null:
		return out
	for name: String in listing.get_files():
		out.append(name)
	for sub: String in listing.get_directories():
		out.append_array(_files_under(path + "/" + sub))
	return out


func test_the_cemetery_gate_is_a_way_through() -> void:
	# The review of O13: a third stone stood on the tile behind the gate, and the gate
	# was an alcove off the trail. Walked, not assumed: in one side, out of the other.
	var data: Dictionary = _baked()
	if data.is_empty():
		assert_true(false, "content/region.json exists — run tools/bake_region.gd")
		return
	var region: Region = RegionBake.read(data)
	var origin := Vector2(float((data["origin_m"] as Array)[0]), float((data["origin_m"] as Array)[1]))
	var gate: Dictionary = {}
	for prop: Dictionary in _cemetery(region):
		if String(prop["role"]) == String(YardRules.ROLE_GATE):
			gate = prop
	assert_false(gate.is_empty(), "the cemetery has its gate")
	if gate.is_empty():
		return
	var xz: Vector2 = gate["xz"] as Vector2
	var passage: Vector2i = BakeRules.tile_for(xz.x, xz.y, origin, float(data["metres_per_tile"]))
	var front: Vector2 = CatalogRules.to_world(Vector2(0.0, 1.0), Vector2.ZERO, float(gate["yaw"]))
	var step := Vector2i(roundi(front.x), roundi(front.y))
	var walk: Array[Vector2i] = Navigation.path(region, passage - step, passage + step)
	assert_eq(walk.size(), 3, "from one side of the gate to the other is three tiles, through it: %s" % str(walk))


func test_a_point_yards_piece_on_his_trail_is_refused_and_the_trail_stays() -> void:
	# The check the baked file cannot make: once a piece has stood, the tiles it stops are
	# walls, whatever they were. So the rule is run here on a made-up strip of trail —
	# a point's yard refuses even a road's verge, which a place's wall may take.
	var bake := RegionBake.new()
	bake.region = Region.new(8, 8)
	for x: int in 8:
		for y: int in 8:
			# Two rows wide, so row 3 is the trail's verge: a place's wall may take it.
			bake.region.set_terrain(Vector2i(x, y), Region.Terrain.ROAD if y == 3 or y == 4 else Region.Terrain.WILD)
	bake.origin_m = Vector2.ZERO
	bake.metres_per_tile = 2.0
	bake.points = {&"graves": {"at": Vector2i(4, 5), "scaffold": true}}
	var stone: Array = [[[8.7, 6.7], [9.3, 6.7], [9.3, 7.3], [8.7, 7.3]]]
	var pieces: Array = [
		{"id": "on_the_trail", "piece": "boulder_round", "scene": "res://x.tscn", "xz": Vector2(9.0, 7.0),
		 "yaw": 0.0, "role": YardRules.ROLE_PIECE, "yard": "graves", "obstacles": stone, "scale": Vector3.ONE},
		{"id": "earth_on_it", "piece": "sol", "scene": "res://y.tscn", "xz": Vector2(5.0, 7.0),
		 "yaw": 0.0, "role": YardRules.ROLE_GROUND, "yard": "graves", "obstacles": [], "scale": Vector3.ONE},
		{"id": "beside_it", "piece": "boulder_round", "scene": "res://x.tscn", "xz": Vector2(9.0, 13.0),
		 "yaw": 0.0, "role": YardRules.ROLE_PIECE, "yard": "graves", "obstacles": [], "scale": Vector3.ONE},
	]
	bake._yards({"yards": [{"point": "graves"}]}, pieces)
	var said: String = "\n".join(bake.report)
	assert_true(said.contains("on_the_trail boulder_round") and said.contains("REFUSED"),
		"a stone on the trail is refused by name: %s" % said)
	assert_true(said.contains("earth_on_it"), "and so is earth laid on it")
	assert_true(bake._road_edge(Vector2i(4, 3)), "the stone stood on the verge, which a place's wall may take")
	assert_eq(bake.region.terrain_at(Vector2i(4, 3)), Region.Terrain.ROAD, "the trail stays trail")
	assert_eq(bake.region.terrain_at(Vector2i(2, 3)), Region.Terrain.ROAD, "all of it")
	assert_eq(bake.region.terrain_at(Vector2i(4, 6)), Region.Terrain.WALL, "and a stone off it stands")
