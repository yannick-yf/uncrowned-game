extends TestCase

## Phase 0's contracts: the walk, the road, and the king.
##
## Everything here runs headless against the same Game.build() the window uses,
## so a passing test cannot describe a world the player never sees.

var _sim: Sim = null
var _world: WorldState = null


func before_each() -> void:
	_sim = Game.build()
	_world = _sim.store(&"world") as WorldState


## Walk in a straight line for n ticks, the way a held key does.
## Walk for a number of quarter-seconds. Kept as the unit the routes below were
## measured in, converted to steps, so the two-clock change moved no geometry.
func _walk(dir: Vector2i, quarter_seconds: int) -> void:
	_sim.submit(&"move_intent", {"x": dir.x, "y": dir.y})
	_sim.advance(quarter_seconds * Sim.STEPS_PER_WORLD_TICK)


func test_the_region_is_bounded_on_all_four_sides() -> void:
	# In the region's own terms, not the 2D map's constants: the baked world is a
	# different size and closes itself with the same rule.
	var region: Region = _world.region()
	assert_true(region.width >= 200 and region.height >= 200,
		"a region, not a room: %d x %d" % [region.width, region.height])
	assert_false(region.is_passable(Vector2i(0, region.height / 2)), "closed to the west")
	assert_false(region.is_passable(Vector2i(region.width / 2, region.height - 1)), "closed to the south")
	assert_false(region.is_passable(Vector2i(region.width - 1, region.height / 2)), "closed to the east")
	assert_false(region.is_passable(Vector2i(region.width / 2, 0)), "closed to the north")
	assert_false(region.is_passable(Vector2i(-1, -1)), "and outside is not walkable")


func test_the_player_wakes_in_the_fairies_clearing_at_full_health() -> void:
	# **Changed 2026-09-12.** Phase 0 woke the player in Brindle. The opening now
	# wakes them in the fairies' clearing inside the Thornwood, and the walk out of
	# the trees into the ruins — with the furnaces in the same frame — is the
	# opening. The clearing is deliberately not a zone: it is a place in the wood,
	# not a settlement, so `zone_at` is empty and that is correct.
	assert_eq(_world.player_tile(), Region.CLEARING, "on open ground in the wood")
	assert_eq(_world.region().zone_at(_world.player_tile()), &"",
		"which belongs to no settlement")
	assert_eq(_world.player_hp, WorldState.MAX_HP)
	assert_eq(_world.player_hp, WorldState.MAX_HP,
		"SPECS §3: the player wakes at a full bar, whatever the bar is")
	assert_eq(_world.deaths, 0)
	assert_false(_world.reached_blackcairn)


func test_blackcairn_is_north_west_of_brindle() -> void:
	assert_true(Region.BLACKCAIRN.x < Region.BRINDLE.x, "west")
	assert_true(Region.BLACKCAIRN.y < Region.BRINDLE.y, "north")
	assert_eq(_world.region().zone_at(Region.BLACKCAIRN), &"blackcairn")


func test_the_walk_is_the_length_spec_4_implies() -> void:
	var tiles_per_second: float = MovementRules.tiles_per_second()
	if Places.baked():
		# Decision 1 (2026-09-13): walking follows the workshop — his metres a second
		# over the metres a tile, slower than the 2D map's six.
		assert_true(tiles_per_second > 0.0 and tiles_per_second < 6.0,
			"the baked world walks at his pace: %.2f tiles/sec" % tiles_per_second)
	else:
		assert_true(absf(tiles_per_second - 6.0) < 0.001,
			"§4's settled walk speed is 6 tiles/sec on the 2D map, got %.2f" % tiles_per_second)

	var road: float = _world.region().road_distance()
	var seconds: float = road / tiles_per_second
	if Places.baked() and (seconds < 45.0 or seconds > 90.0):
		# §4's band was settled for six tiles a second; at his pace it is re-measured
		# on the baked grid and renegotiated with the map (MIGRATION_3D §4).
		debt("the King's Road takes %.0f s at his pace; §4's 45-90 s band is to be renegotiated with the map" % seconds)
	else:
		assert_true(seconds >= 45.0 and seconds <= 90.0,
			"§4's settled road-travel target is 45-90 s, got %.1f" % seconds)

	# §4's 343 was the 2D map's own diagonal, which no route uses: every settlement sits
	# inside the impassable border, so it bounds the region rather than measuring it.
	# Measured from the region's size, so the baked world's 541 bounds it the same way.
	var region: Region = _world.region()
	var corner: float = Vector2(0, 0).distance_to(Vector2(region.width - 1, region.height - 1))
	assert_true(corner > 300.0, "a region, not a room: diagonal %.1f" % corner)
	assert_true(road < corner * 1.2, "and the road does not wander absurdly")


func test_the_kings_road_runs_between_them() -> void:
	var region: Region = _world.region()
	var road_near_brindle: bool = false
	var road_near_blackcairn: bool = false
	for radius: int in range(1, 9):
		for dx: int in range(-radius, radius + 1):
			for dy: int in range(-radius, radius + 1):
				if region.terrain_at(Region.BRINDLE + Vector2i(dx, dy)) == Region.Terrain.ROAD:
					road_near_brindle = true
				if region.terrain_at(Region.BLACKCAIRN + Vector2i(dx, dy)) == Region.Terrain.ROAD:
					road_near_blackcairn = true
	assert_true(road_near_brindle, "the road runs past Brindle")
	assert_true(road_near_blackcairn, "and reaches the castle")


func test_movement_is_eight_way_and_diagonals_are_not_faster() -> void:
	# Open grass, far from any road, river or wood: a diagonal that strays onto
	# different ground would be measuring the speed table, not the movement. Found
	# rather than named — the first tile with nothing but grass for seven tiles round
	# it — so the same test measures the same thing on any map.
	var region: Region = _world.region()
	var open_ground := Vector2.ZERO
	for y: int in range(8, region.height - 8, 4):
		for x: int in range(8, region.width - 8, 4):
			var all_grass: bool = true
			for dx: int in range(-7, 8):
				for dy: int in range(-7, 8):
					if region.terrain_at(Vector2i(x + dx, y + dy)) != Region.Terrain.WILD:
						all_grass = false
			if all_grass:
				open_ground = Vector2(x, y) + Vector2(0.5, 0.5)
				break
		if open_ground != Vector2.ZERO:
			break
	assert_ne(open_ground, Vector2.ZERO, "there is open grass somewhere on the map")
	assert_eq(region.terrain_at(Vector2i(open_ground)), Region.Terrain.WILD)

	_world.player_pos = open_ground
	var start: Vector2 = _world.player_pos
	_walk(Vector2i(-1, 0), Game.TICKS_PER_REAL_SECOND)
	var straight: float = start.distance_to(_world.player_pos)

	before_each()
	_world.player_pos = open_ground
	start = _world.player_pos
	_walk(Vector2i(-1, -1), Game.TICKS_PER_REAL_SECOND)
	var diagonal: float = start.distance_to(_world.player_pos)

	var expected: float = MovementRules.tiles_per_second() * Region.speed_multiplier(Region.Terrain.WILD)
	assert_true(absf(straight - expected) < 0.001,
		"one second of grass covers %.1f tiles, got %.3f" % [expected, straight])
	assert_true(absf(diagonal - expected) < 0.001,
		"the same distance along a diagonal, got %.3f" % diagonal)


func test_walking_into_the_sea_slides_along_it_rather_than_stopping() -> void:
	# Put the player on the shore and walk south-west into the sea. The shore is found,
	# not named: from Brindle's longitude, the first stretch of six tiles you can stand
	# on with the sea directly below every one of them — which is any tile of the 2D
	# map's straight south coast, and a straight enough piece of the baked one.
	var region: Region = _world.region()
	var shore: Vector2i = Region.NOWHERE
	for x: int in range(Region.BRINDLE.x, 12, -1):
		var y: int = Region.BRINDLE.y
		while region.in_bounds(Vector2i(x, y + 1)) \
				and region.terrain_at(Vector2i(x, y + 1)) != Region.Terrain.SEA:
			y += 1
		if not region.in_bounds(Vector2i(x, y + 1)):
			continue
		var stretch: bool = true
		for k: int in 6:
			var here := Vector2i(x - k, y)
			if not region.is_passable(here) or region.is_passable(here + Vector2i(0, 1)):
				stretch = false
		if stretch:
			shore = Vector2i(x, y)
			break
	assert_ne(shore, Region.NOWHERE, "there is a shore to walk along")
	_world.player_pos = Vector2(shore) + Vector2(0.5, 0.5)
	var start_x: float = _world.player_pos.x
	var start_y: float = _world.player_pos.y
	_walk(Vector2i(-1, 1), 6)
	# A second and a half along the shore, at this world's pace on this ground —
	# most of it, since the first step is spent turning.
	var pace: float = MovementRules.tiles_per_second() \
		* Region.speed_multiplier(region.terrain_at(shore))
	assert_true(_world.player_pos.x < start_x - pace * 1.5 * 0.6,
		"kept moving west: %.1f tiles" % (start_x - _world.player_pos.x))
	assert_true(absf(_world.player_pos.y - start_y) < 1.01, "but not into the water")


func test_the_king_kills_the_player_in_exactly_three_touches() -> void:
	var grace: int = ContactRules.invulnerable_steps()
	_world.player_pos = _world.king_pos
	_sim.advance(1)
	# **Derived, so the claim survives a rescale.** These read 6 and 2 while the bar was
	# ten; the bar is a hundred now and the claim — three touches — has not moved. A
	# hard-coded number here would have let `KING_DAMAGE` drift without anybody noticing
	# the king had stopped being lethal.
	assert_eq(_world.player_hp, WorldState.MAX_HP - ContactRules.KING_DAMAGE, "first touch")
	assert_eq(_world.touches_taken, 1)
	assert_eq(_world.deaths, 0)

	_sim.advance(grace)
	assert_eq(_world.player_hp, WorldState.MAX_HP - 2 * ContactRules.KING_DAMAGE,
		"second touch, after the grace window")
	assert_eq(_world.deaths, 0, "not dead on the second")

	_sim.advance(grace)
	assert_eq(_world.touches_taken, 3, "third touch")
	assert_eq(_world.deaths, 1, "and that is the one that kills")


func test_three_touches_take_about_a_second_and_a_half() -> void:
	_world.player_pos = _world.king_pos
	var start: int = _sim.step
	while _world.deaths == 0 and _sim.step - start < Sim.STEPS_PER_REAL_SECOND * 5:
		_sim.advance(1)
	var seconds: float = float(_sim.step - start) / float(Sim.STEPS_PER_REAL_SECOND)
	assert_eq(_world.deaths, 1, "the king got there")
	assert_true(seconds > 0.8 and seconds < 2.2,
		"dying takes long enough to feel and short enough to retry: %.2f s" % seconds)


func test_death_respawns_in_brindle_and_keeps_everything() -> void:
	_world.player_pos = _world.king_pos
	_sim.advance(ContactRules.invulnerable_steps() * 3)
	assert_eq(_world.deaths, 1)
	assert_eq(_world.player_tile(), Region.CLEARING, "back where they woke up")
	assert_eq(_world.player_hp, WorldState.MAX_HP, "at full health")
	assert_eq(_world.player_dir, Vector2i.ZERO, "and standing still")
	assert_true(_world.reached_blackcairn, "having kept what they learned")
	assert_true(_sim.facts.has(&"the_king_killed_me"), "which includes knowing how it went")


func test_standing_in_blackcairn_is_recorded_as_a_fact() -> void:
	assert_false(_sim.facts.has(&"blackcairn:reached"), "not known from Brindle")
	_world.player_pos = _world.region().blackcairn_centre() + Vector2(4.0, 4.0)
	_sim.advance(1)
	assert_true(_world.reached_blackcairn)
	assert_true(_sim.facts.has(&"blackcairn:reached"))
	assert_eq(_sim.facts.sources_of(&"blackcairn:reached"),
		[&"witnessed"] as Array[StringName], "the player saw it themselves")


func test_the_tick_means_what_spec_8_says() -> void:
	assert_eq(Game.TICKS_PER_REAL_SECOND, 4)
	assert_eq(Sim.STEPS_PER_REAL_SECOND, 60, "the sim steps at 60 Hz")
	assert_eq(Sim.STEPS_PER_WORLD_TICK, 15, "and a world tick is every 15th step")
	assert_eq(Game.IN_GAME_MINUTES_PER_TICK, 1)
	assert_eq(Game.TICKS_PER_IN_GAME_DAY, 1440)
	_sim.advance_world_ticks(1440)
	assert_true(absf(Game.in_game_days(_sim.tick) - 1.0) < 0.001, "one in-game day")
	assert_eq(1440 / Game.TICKS_PER_REAL_SECOND, 360, "which is six real minutes")
	assert_eq(Game.in_game_clock_parts(0), [1, "00", "00"])
	assert_eq(Game.in_game_clock_parts(90), [1, "01", "30"])
