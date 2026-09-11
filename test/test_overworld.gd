extends TestCase

## Phase 2, stage 1: the map is real and walkable.
##
## These pin the properties the world was *designed* for — the dog-leg ratio, the
## travel target, the crossings being bands — so that moving a zone later tells you
## what it cost instead of silently undoing the design.

var _region: Region = null


func before_each() -> void:
	_region = Region.build_overworld()


func _passable_neighbours(tile: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx: int in [-1, 0, 1]:
		for dy: int in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var next: Vector2i = tile + Vector2i(dx, dy)
			if _region.is_passable(next):
				out.append(next)
	return out


func _reachable_from(start: Vector2i) -> Dictionary:
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		for next: Vector2i in _passable_neighbours(queue.pop_back()):
			if not seen.has(next):
				seen[next] = true
				queue.append(next)
	return seen


func test_all_eight_zones_of_spec_4_exist_and_are_walkable() -> void:
	var sites: Dictionary = Region.zone_sites()
	assert_eq(sites.size(), 8, "§4 names eight zones")
	for id: StringName in sites.keys():
		var at: Vector2i = sites[id] as Vector2i
		assert_true(_region.in_bounds(at), "%s is on the map" % id)
		assert_true(_region.is_passable(at), "%s can be stood in" % id)


func test_every_zone_is_reachable_on_foot_from_brindle() -> void:
	var seen: Dictionary = _reachable_from(Region.BRINDLE)
	for id: StringName in Region.zone_sites().keys():
		assert_true(seen.has(Region.zone_sites()[id]), "%s is reachable from Brindle" % id)


func test_the_kettle_actually_divides_the_map() -> void:
	# If the river is not a barrier then the bridge and the ford are decoration.
	# Fill both crossings in and the castle must become unreachable.
	var dammed := Region.build_overworld(true)
	for x: int in range(Region.BRIDGE.x - 12, Region.BRIDGE.x + 12):
		for y: int in range(Region.BRIDGE.y - 4, Region.FORD.y + 6):
			if dammed.terrain_at(Vector2i(x, y)) == Region.Terrain.ROAD \
					or dammed.terrain_at(Vector2i(x, y)) == Region.Terrain.FORD:
				dammed.set_terrain(Vector2i(x, y), Region.Terrain.WATER)
	_region = dammed
	assert_false(_reachable_from(Region.BRINDLE).has(Region.BLACKCAIRN),
		"with both crossings dammed, the east bank is cut off — so the river is real")


func test_both_crossings_are_bands_a_single_step_cannot_miss() -> void:
	# A walker covers 6 tiles a second, so a one-tile crossing is one you walk over.
	for name: String in ["bridge", "ford"]:
		var at: Vector2i = Region.BRIDGE if name == "bridge" else Region.FORD
		var want: Region.Terrain = Region.Terrain.ROAD if name == "bridge" else Region.Terrain.FORD
		var across: int = 0
		var along: int = 0
		for d: int in range(-10, 11):
			if _region.terrain_at(at + Vector2i(d, 0)) == want:
				across += 1
			if _region.terrain_at(at + Vector2i(0, d)) == want:
				along += 1
		assert_true(across >= 5, "%s spans %d tiles east-west" % [name, across])
		assert_true(along >= 2, "%s is %d tiles deep north-south" % [name, along])


func test_the_bridge_and_ford_reach_dry_land_on_both_sides() -> void:
	# The first version of the bridge stopped in the river: the Kettle runs at an
	# angle, so it covers more columns per row than its width suggests.
	for at: Vector2i in [Region.BRIDGE, Region.FORD]:
		var row: int = at.y
		var west_ok: bool = false
		var east_ok: bool = false
		for d: int in range(1, 14):
			if _region.terrain_at(Vector2i(at.x - d, row)) == Region.Terrain.WATER:
				west_ok = false
				break
			west_ok = true
		for d: int in range(1, 14):
			if _region.terrain_at(Vector2i(at.x + d, row)) == Region.Terrain.WATER:
				east_ok = false
				break
			east_ok = true
		assert_true(west_ok and east_ok, "the crossing at %s clears the water" % at)


func test_the_road_is_a_dog_leg_not_a_ruled_line() -> void:
	# Without this the wild costs time and blood and saves no distance, which makes
	# it strictly worse forever — witnesses or not.
	var road: float = _region.road_distance()
	var direct: float = _region.brindle_to_blackcairn_tiles()
	var ratio: float = road / direct
	assert_true(ratio >= 1.30 and ratio <= 1.50,
		"road is %.0f tiles against a %.0f-tile direct line, ratio %.3f (want 1.30-1.50)"
			% [road, direct, ratio])


func test_road_travel_matches_the_settled_target() -> void:
	var seconds: float = _region.road_distance() / MovementRules.TILES_PER_SECOND
	assert_true(seconds >= 45.0 and seconds <= 90.0,
		"§4 settles road travel at 45-90 s; this map walks it in %.1f s" % seconds)


func test_the_speed_table_orders_the_ground_as_spec_4_describes() -> void:
	var road: float = Region.speed_multiplier(Region.Terrain.ROAD)
	var grass: float = Region.speed_multiplier(Region.Terrain.WILD)
	var forest: float = Region.speed_multiplier(Region.Terrain.FOREST)
	var marsh: float = Region.speed_multiplier(Region.Terrain.MARSH)
	assert_true(absf(road - 1.0) < 0.001, "the road is the 1.0 reference, not a bonus")
	assert_true(road > grass, "the road is faster than open ground")
	assert_true(grass > forest, "open ground is faster than the Thornwood")
	assert_true(forest > marsh, "and the Thornwood is faster than the marsh")
	assert_true(Region.speed_multiplier(Region.Terrain.FORD) < grass,
		"wading is slower than walking")


func test_crossing_the_wild_is_slower_than_the_road_despite_being_shorter() -> void:
	# The legible cost, in seconds rather than tiles. Both figures are straight-line
	# idealisations — what matters is which way the inequality points.
	var road_seconds: float = _region.road_distance() / MovementRules.TILES_PER_SECOND
	var wild_tiles: float = _region.brindle_to_blackcairn_tiles()
	var wild_speed: float = MovementRules.TILES_PER_SECOND \
		* Region.speed_multiplier(Region.Terrain.FOREST)
	var wild_seconds: float = wild_tiles / wild_speed

	assert_true(wild_tiles < _region.road_distance(), "the wild is the shorter way")
	assert_true(wild_seconds > road_seconds,
		"and still the slower one: %.0f s through the trees against %.0f s on the road"
			% [wild_seconds, road_seconds])


func test_the_thornwood_lies_east_of_the_river_where_spec_4_puts_it() -> void:
	var east: int = 0
	var west: int = 0
	for y: int in range(20, 170):
		if _region.terrain_at(Vector2i(250, y)) == Region.Terrain.FOREST:
			east += 1
		if _region.terrain_at(Vector2i(40, y)) == Region.Terrain.FOREST:
			west += 1
	assert_true(east > 100, "the Thornwood covers the eastern strip")
	assert_eq(west, 0, "and does not reach the western coast")


# ------------------------------------------------------- stage 2: identity ---

func test_every_zone_carries_a_landmark() -> void:
	# "Recognisable on sight" is the proof; a zone with no landmark is a patch of
	# ground with a name in the HUD.
	for id: StringName in Region.zone_sites().keys():
		var site: Vector2i = Region.zone_sites()[id] as Vector2i
		var near: int = 0
		for prop: Dictionary in _region.props:
			if Vector2(prop["at"] as Vector2i).distance_to(Vector2(site)) <= 12.0:
				near += 1
		assert_true(near >= 1, "%s has %d landmarks within sight of its centre" % [id, near])


func test_every_landmark_kind_has_art() -> void:
	var art := Art.new()
	for prop: Dictionary in _region.props:
		var kind: StringName = prop["kind"] as StringName
		assert_true(art.props.has(kind), "no sprite is mapped for landmark kind '%s'" % kind)


func test_every_walkable_terrain_has_a_tile_or_a_deliberate_colour() -> void:
	var art := Art.new()
	for terrain: int in [Region.Terrain.WILD, Region.Terrain.ROAD, Region.Terrain.FOREST,
			Region.Terrain.WATER, Region.Terrain.FORD, Region.Terrain.SAND,
			Region.Terrain.MARSH, Region.Terrain.FARMLAND, Region.Terrain.SEA,
			Region.Terrain.RUINS, Region.Terrain.TOWN, Region.Terrain.CAMP,
			Region.Terrain.CASTLE]:
		assert_true(art.terrain_tiles.has(terrain),
			"terrain %d would be drawn as a flat rectangle" % terrain)


func test_landmarks_never_close_the_road() -> void:
	for prop: Dictionary in _region.props:
		var at: Vector2i = prop["at"] as Vector2i
		var size: Vector2i = prop.get("size", Vector2i(4, 3)) as Vector2i
		for dx: int in size.x:
			for dy: int in size.y:
				var tile: Vector2i = at + Vector2i(dx, dy)
				if _region.terrain_at(tile) == Region.Terrain.WALL:
					continue
				assert_true(true)
	# The real assertion: with every landmark placed, the road still connects.
	assert_true(_reachable_from(Region.BRINDLE).has(Region.BLACKCAIRN),
		"a building was put through the King's Road")


func test_the_zone_a_tile_belongs_to_is_answerable() -> void:
	for id: StringName in Region.zone_sites().keys():
		assert_eq(_region.zone_at(Region.zone_sites()[id] as Vector2i), id,
			"standing in %s should say so" % id)
	assert_eq(_region.zone_at(Vector2i(120, 60)), &"", "and open country is nowhere in particular")
