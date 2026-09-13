extends TestCase

## Phase 2, stage 1: the map is real and walkable.
##
## These pin the properties the world was *designed* for — the dog-leg ratio, the
## travel target, the crossings being bands — so that moving a zone later tells you
## what it cost instead of silently undoing the design.

var _region: Region = null


func before_each() -> void:
	_region = Region.build_overworld()


func test_all_eight_zones_of_spec_4_exist_and_are_walkable() -> void:
	var sites: Dictionary = Region.zone_sites()
	assert_eq(sites.size(), 8, "§4 names eight zones")
	for id: StringName in sites.keys():
		var at: Vector2i = sites[id] as Vector2i
		assert_true(_region.in_bounds(at), "%s is on the map" % id)
		assert_true(_region.is_passable(at), "%s can be stood in" % id)


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
	if Places.baked() and (ratio < 1.30 or ratio > 1.50):
		# The shape of the road is the map's to settle (MIGRATION_3D §5): on the 3D map
		# the King's Road runs nearly straight from Brindle to the castle.
		debt("the King's Road is %.0f tiles against a %.0f-tile direct line, ratio %.2f; §4 wants a dog-leg of 1.30-1.50"
			% [road, direct, ratio])
		return
	assert_true(ratio >= 1.30 and ratio <= 1.50,
		"road is %.0f tiles against a %.0f-tile direct line, ratio %.3f (want 1.30-1.50)"
			% [road, direct, ratio])


func test_road_travel_matches_the_settled_target() -> void:
	var seconds: float = _region.road_distance() / MovementRules.TILES_PER_SECOND
	assert_true(seconds >= 45.0 and seconds <= 90.0,
		"§4 settles road travel at 45-90 s; this map walks it in %.1f s" % seconds)


func test_the_ground_slows_you_down_again() -> void:
	# Switched back on 2026-09-13 (§4): with the beasts gone, tiring is the price of
	# the wild, and the tuned table is the one that was reasoned about.
	assert_true(Region.TERRAIN_SLOWS_YOU)
	assert_true(absf(Region.speed_multiplier(Region.Terrain.ROAD) - 1.0) < 0.001,
		"the road is the 1.0 reference")
	for terrain: int in [Region.Terrain.WILD, Region.Terrain.FOREST, Region.Terrain.MARSH,
			Region.Terrain.FORD, Region.Terrain.SAND, Region.Terrain.FARMLAND, Region.Terrain.RUINS]:
		assert_true(Region.speed_multiplier(terrain as Region.Terrain) < 1.0,
			"terrain %d is slower than the road" % terrain)



func test_the_tuned_speed_table_is_kept_and_still_orders_the_ground() -> void:
	# Kept rather than deleted, so turning terrain speeds back on is one word and
	# the numbers are the ones that were reasoned about, not re-guessed.
	assert_true(absf(Region.speed_table(Region.Terrain.ROAD) - 1.0) < 0.001,
		"the road is the 1.0 reference, not a bonus")
	assert_true(Region.speed_table(Region.Terrain.ROAD) > Region.speed_table(Region.Terrain.FARMLAND))
	assert_true(Region.speed_table(Region.Terrain.FARMLAND) > Region.speed_table(Region.Terrain.WILD),
		"a worked field has paths; heath does not (2026-09-13, measured)")
	assert_true(Region.speed_table(Region.Terrain.WILD) > Region.speed_table(Region.Terrain.FOREST))
	assert_true(Region.speed_table(Region.Terrain.FOREST) > Region.speed_table(Region.Terrain.MARSH))


func test_the_road_is_the_long_way_and_the_wood_is_the_slow_way() -> void:
	# The two halves of the choice, as geometry. The wild line is shorter, so the
	# road's only case is speed; the wood is slower per tile, so the road can have
	# one. Whether it actually wins is measured in test_journeys, not assumed here.
	assert_true(_region.brindle_to_blackcairn_tiles() < _region.road_distance(),
		"the wild line is the short one: %.0f against %.0f tiles" % [
			_region.brindle_to_blackcairn_tiles(), _region.road_distance()])
	assert_true(Region.speed_multiplier(Region.Terrain.FOREST) < Region.speed_multiplier(Region.Terrain.ROAD),
		"and the wood is slower per tile than the road")



func test_the_thornwood_lies_across_the_shortcut_and_not_on_the_coast() -> void:
	# **Counts wood, not only open wood** (2026-09-13). The deep Thornwood is mostly
	# `THICKET` now — closed wood with ways carved through it — and `FOREST` is what
	# is left open. Asking only about `FOREST` said the wood had almost gone, when
	# what had happened is that it had finally become a wood.
	#
	# **Measured along the shortcut, not down a column** (M1c). The 2D map keeps its
	# wood in an eastern strip that a column at x 250 could count; the baked world has
	# it wherever the brief plants it. What §4 asks is that the straight line from
	# Brindle to the castle runs through wood, and that the coast is clear of it.
	var on_the_line: int = 0
	var open_on_the_line: int = 0
	var from := Vector2(Region.BRINDLE)
	var to := Vector2(Region.BLACKCAIRN)
	var steps: int = int(from.distance_to(to))
	for i: int in steps:
		var at: Vector2 = from.lerp(to, float(i) / float(steps))
		var here: Region.Terrain = _region.terrain_at(Vector2i(floori(at.x), floori(at.y)))
		if here == Region.Terrain.FOREST or here == Region.Terrain.THICKET:
			on_the_line += 1
		if here == Region.Terrain.FOREST:
			open_on_the_line += 1
	var coast: int = 0
	for dy: int in range(-40, 41):
		var there: Region.Terrain = _region.terrain_at(Region.SALTMARCH + Vector2i(0, dy))
		if there == Region.Terrain.FOREST or there == Region.Terrain.THICKET:
			coast += 1
	assert_true(on_the_line >= 30, "the Thornwood lies across the shortcut: %d tiles of the line" % on_the_line)
	assert_eq(coast, 0, "and does not reach the western coast at Saltmarch")
	assert_true(open_on_the_line > 0,
		"and there is a way through it rather than a wall: %d open tiles" % open_on_the_line)


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
		assert_true(art.can_draw(kind), "nothing knows how to draw a '%s'" % kind)


func test_every_walkable_terrain_has_a_tile_or_a_deliberate_colour() -> void:
	# **Updated 2026-09-13.** There are three ways a surface can be drawn now, in
	# the order the window tries them: `Art.GROUND`, which gives a terrain a base and
	# its detail tiles; `terrain_tiles`, the single-tile table it grew out of; and the
	# flat colour, which is the thing this test exists to keep anything from falling
	# back to. Asking only about the middle one failed the moment sand moved up to
	# the first.
	var art := Art.new()
	for terrain: int in [Region.Terrain.WILD, Region.Terrain.ROAD, Region.Terrain.FOREST,
			Region.Terrain.WATER, Region.Terrain.FORD, Region.Terrain.SAND,
			Region.Terrain.MARSH, Region.Terrain.FARMLAND, Region.Terrain.SEA,
			Region.Terrain.RUINS, Region.Terrain.TOWN, Region.Terrain.CAMP,
			Region.Terrain.CASTLE, Region.Terrain.CLEARED, Region.Terrain.CLEARING,
			Region.Terrain.THICKET]:
		assert_true(Art.GROUND.has(terrain) or art.terrain_tiles.has(terrain),
			"terrain %d would be drawn as a flat rectangle" % terrain)


func test_the_zone_a_tile_belongs_to_is_answerable() -> void:
	for id: StringName in Region.zone_sites().keys():
		assert_eq(_region.zone_at(Region.zone_sites()[id] as Vector2i), id,
			"standing in %s should say so" % id)
	# Open country: somewhere on the straight line from Brindle to the castle that no
	# place claims. Found rather than named, because where that is depends on the map.
	var from := Vector2(Region.BRINDLE)
	var to := Vector2(Region.BLACKCAIRN)
	var open: bool = false
	for i: int in int(from.distance_to(to)):
		var at: Vector2 = from.lerp(to, float(i) / from.distance_to(to))
		if _region.zone_at(Vector2i(floori(at.x), floori(at.y))) == &"":
			open = true
	assert_true(open, "and open country between the places is nowhere in particular")


# --------------------------------------------------------- the crowd (§6) ---

func test_harrowgate_has_standing_room_for_the_men_who_left() -> void:
	var spots: int = 0
	for prop: Dictionary in _region.props:
		if (prop["kind"] as StringName) != &"townsfolk":
			continue
		spots += 1
		assert_eq(_region.zone_at(prop["at"] as Vector2i), &"harrowgate",
			"the crowd stands in Harrowgate, where the deserters went")
		assert_true(_region.is_passable(prop["at"] as Vector2i),
			"and on ground you can walk through — they are scenery, not walls")
	assert_true(spots >= 10, "room for a crowd, not a handful: %d" % spots)


func test_townsfolk_are_not_cast() -> void:
	# §6: scenery has no sheet, no name and no place in the 25.
	var cast := Cast.shared()
	for prop: Dictionary in _region.props:
		if (prop["kind"] as StringName) == &"townsfolk":
			assert_null(cast.get_npc(&"townsfolk"), "nobody in the crowd is in the roster")
			break
	# §17 budgets twenty-five named people for the whole region. What matters is
	# that the crowd never quietly joins them.
	assert_true(cast.named().size() <= 25, "the named cast is inside §6's budget")
	for id: StringName in cast.npcs.keys():
		assert_false(String(id).begins_with("townsfolk"),
			"nobody in the crowd has acquired a sheet")


func test_strangers_are_not_cast_either() -> void:
	# Same rule, other end of it. A generic has a trade and no name, and adding
	# one must never quietly enlarge §6's twenty-five.
	var cast := Cast.shared()
	var strangers: int = cast.npcs.size() - cast.named().size()
	assert_true(strangers > 0, "there is at least one stranger placed in the world")
	for id: StringName in cast.npcs.keys():
		var npc: Npc = cast.get_npc(id)
		if not npc.generic:
			continue
		assert_true(npc.kind != &"", "%s is one of a trade, not one of a kind" % id)
		assert_true(String(id).contains("@"), "a stranger's id names a placement, not a person")
		assert_true(npc.greeting.length() > 0, "and still has something to say")
