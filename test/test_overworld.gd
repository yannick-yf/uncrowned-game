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
	# On the baked map the bridge follows his diagonal deck, whose narrowest width
	# still exceeds a simulation step. The old row/column band is the 2D ford.
	if Places.baked():
		var meta: Dictionary = RegionBake.read_landscape()["meta"] as Dictionary
		for bridge: Dictionary in meta["crossings"]:
			assert_true(float(bridge["clear_width_m"]) > MovementRules.TILES_PER_SECOND *
				BakeRules.METRES_PER_TILE / float(Sim.STEPS_PER_REAL_SECOND),
				"%s cannot be stepped over in one simulation step" % bridge["id"])
	for name: String in (["ford"] if Places.baked() else ["bridge", "ford"]):
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


## The first version of the bridge stopped in the river; the first ford on his rivers
## v4 covered half the width (2026-09-14). The old test walked the crossing's row and
## wanted no water within 13 tiles either side — true of a river running north-south,
## false of his, which runs at 45° there. The claim itself, whatever the angle: **a
## crossing joins two shores** — dam it, and the dry ground you could reach from it
## falls into at least two pieces.
const CROSSING_WINDOW: int = 20


func test_the_bridge_and_ford_connect_the_two_banks() -> void:
	for at: Vector2i in [Region.BRIDGE, Region.FORD]:
		var band: Region.Terrain = _region.terrain_at(at)
		assert_true(band == Region.Terrain.ROAD or band == Region.Terrain.FORD,
			"the crossing at %s stands on its band, not in the river (%d)" % [at, band])
		var shore: Dictionary = _dry_ground_from(at)
		assert_true(shore.size() > 20, "%s: dry ground on the shores, %d tiles" % [at, shore.size()])
		var pieces: int = _pieces_once_dammed(at, shore)
		assert_true(pieces >= 2,
			"%s: dam the crossing and its shores fall into %d piece(s); a crossing joins two" % [at, pieces])


## Everything passable you can walk to from the crossing inside its window, minus
## the band itself: the dry ground of both shores.
func _dry_ground_from(at: Vector2i) -> Dictionary:
	var seen: Dictionary = {at: true}
	var queue: Array[Vector2i] = [at]
	var dry: Dictionary = {}
	while not queue.is_empty():
		var here: Vector2i = queue.pop_back()
		if not _is_band(here):
			dry[here] = true
		for dx: int in [-1, 0, 1]:
			for dy: int in [-1, 0, 1]:
				var next := Vector2i(here.x + dx, here.y + dy)
				if seen.has(next) or not _in_window(at, next) or not _region.is_passable(next):
					continue
				seen[next] = true
				queue.append(next)
	return dry


## How many pieces that dry ground falls into once every tile of the band in the
## window is impassable — two shores, if the crossing was doing its job.
func _pieces_once_dammed(at: Vector2i, dry: Dictionary) -> int:
	var seen: Dictionary = {}
	var pieces: int = 0
	for start: Vector2i in dry.keys():
		if seen.has(start):
			continue
		pieces += 1
		seen[start] = true
		var queue: Array[Vector2i] = [start]
		while not queue.is_empty():
			var here: Vector2i = queue.pop_back()
			for dx: int in [-1, 0, 1]:
				for dy: int in [-1, 0, 1]:
					var next := Vector2i(here.x + dx, here.y + dy)
					if seen.has(next) or not dry.has(next):
						continue
					seen[next] = true
					queue.append(next)
	return pieces


func _is_band(tile: Vector2i) -> bool:
	var terrain: Region.Terrain = _region.terrain_at(tile)
	return terrain == Region.Terrain.ROAD or terrain == Region.Terrain.FORD


func _in_window(centre: Vector2i, tile: Vector2i) -> bool:
	return _region.in_bounds(tile) and absi(tile.x - centre.x) <= CROSSING_WINDOW \
		and absi(tile.y - centre.y) <= CROSSING_WINDOW


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
	var seconds: float = _region.road_distance() / MovementRules.tiles_per_second()
	if Places.baked() and (seconds < 45.0 or seconds > 90.0):
		# Settled for six tiles a second; at his pace the band is renegotiated with the
		# map, not defended (MIGRATION_3D §4).
		debt("the King's Road takes %.0f s at his pace; §4's 45-90 s band is to be renegotiated with the map" % seconds)
		return
	assert_true(seconds >= 45.0 and seconds <= 90.0,
		"§4 settles road travel at 45-90 s; this map walks it in %.1f s" % seconds)


func test_the_ground_slows_you_or_not_as_the_switch_says() -> void:
	# Switched on 2026-09-13 (§4): with the beasts gone, tiring is the price of the
	# wild. Off again 2026-09-14 (Yannick, on his brother's map): at his pace the wild
	# was a crawl, and the 2D game's layers come off while the 3D world is tested.
	# Either way, the rule agrees with the switch.
	if not Region.TERRAIN_SLOWS_YOU:
		for terrain: int in Region.Terrain.values():
			assert_true(absf(Region.speed_multiplier(terrain as Region.Terrain) - 1.0) < 0.001,
				"with the switch off every ground walks at the world's pace: %d" % terrain)
		off("terrain speeds are off for now (Yannick, 2026-09-14): the wild costs no time")
		return
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
	assert_true(Region.speed_table(Region.Terrain.FOREST) < Region.speed_table(Region.Terrain.ROAD),
		"and the wood is slower per tile than the road, in the table the switch turns on")



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
		# A building his data stands, or a piece of his catalogue the bake placed (G1):
		# either way his scene draws it, from the vendored copy.
		if prop.has("scene") and (bool(prop.get("his", false)) or prop.has("piece")):
			assert_true(ResourceLoader.exists(String(prop["scene"]).replace("res://", "res://view3d/workshop/")),
				"his scene draws %s" % prop.get("source_id", prop.get("piece", kind)))
		else:
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
	# §6 budgeted twenty-five named people for the whole region on 2026-09-11, and
	# **Yannick moved it to twenty-seven on 2026-09-19** — the two the demo needs and
	# the budget did not foresee, because the demo did not exist when it was approved:
	# `bram`, the sparring partner, and `tom`, the quest's one genuinely new person.
	# Both are named in §6 rather than absorbed.
	#
	# What this line is really for is that the *crowd* never joins the roster by
	# degrees, so the number stays a tripwire: it fails on the twenty-eighth.
	assert_true(cast.named().size() <= 27,
		"the named cast is inside §6's budget of 27: %d" % cast.named().size())
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
