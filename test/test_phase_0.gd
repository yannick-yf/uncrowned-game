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
	var region: Region = _world.region()
	assert_eq(region.width, 280)
	assert_eq(region.height, 200)
	assert_false(region.is_passable(Vector2i(Region.SEA_WEST - 1, 100)), "sea to the west")
	assert_false(region.is_passable(Vector2i(140, Region.SEA_SOUTH + 1)), "sea to the south")
	assert_false(region.is_passable(Vector2i(Region.MOUNTAIN_EAST + 1, 100)), "mountains to the east")
	assert_false(region.is_passable(Vector2i(140, Region.MOUNTAIN_NORTH - 1)), "mountains to the north")
	assert_false(region.is_passable(Vector2i(-1, -1)), "and outside is not walkable")


func test_the_player_wakes_in_brindle_at_full_health() -> void:
	assert_eq(_world.player_tile(), Region.BRINDLE, "in the ruins of their village")
	assert_eq(_world.region().zone_at(_world.player_tile()), &"brindle")
	assert_eq(_world.player_hp, WorldState.MAX_HP)
	assert_eq(_world.player_hp, 10, "SPECS §3: ten hit points")
	assert_eq(_world.deaths, 0)
	assert_false(_world.reached_blackcairn)


func test_blackcairn_is_north_west_of_brindle() -> void:
	assert_true(Region.BLACKCAIRN.x < Region.BRINDLE.x, "west")
	assert_true(Region.BLACKCAIRN.y < Region.BRINDLE.y, "north")
	assert_eq(_world.region().zone_at(Region.BLACKCAIRN), &"blackcairn")


func test_the_walk_is_the_length_spec_4_implies() -> void:
	var tiles_per_second: float = MovementRules.TILES_PER_SECOND
	assert_true(absf(tiles_per_second - 6.0) < 0.001,
		"§4's settled walk speed is 6 tiles/sec, got %.2f" % tiles_per_second)

	var road: float = _world.region().road_distance()
	var seconds: float = road / tiles_per_second
	assert_true(seconds >= 45.0 and seconds <= 90.0,
		"§4's settled road-travel target is 45-90 s, got %.1f" % seconds)

	# §4's 343 is the map's own diagonal, which no route uses: every settlement sits
	# inside the impassable border, so it bounds the region rather than measuring it.
	var corner: float = Vector2(0, 0).distance_to(Vector2(279, 199))
	assert_true(corner > 340.0 and corner < 345.0, "map diagonal is §4's 343, got %.1f" % corner)
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
	# different ground would be measuring the speed table, not the movement.
	var open_ground := Vector2(60.5, 120.5)
	assert_eq(_world.region().terrain_at(Vector2i(60, 120)), Region.Terrain.WILD)

	_world.player_pos = open_ground
	var start: Vector2 = _world.player_pos
	_walk(Vector2i(-1, 0), Game.TICKS_PER_REAL_SECOND)
	var straight: float = start.distance_to(_world.player_pos)

	before_each()
	_world.player_pos = open_ground
	start = _world.player_pos
	_walk(Vector2i(-1, -1), Game.TICKS_PER_REAL_SECOND)
	var diagonal: float = start.distance_to(_world.player_pos)

	var expected: float = MovementRules.TILES_PER_SECOND * Region.speed_multiplier(Region.Terrain.WILD)
	assert_true(absf(straight - expected) < 0.001,
		"one second of grass covers %.1f tiles, got %.3f" % [expected, straight])
	assert_true(absf(diagonal - expected) < 0.001,
		"the same distance along a diagonal, got %.3f" % diagonal)


func test_walking_into_the_sea_slides_along_it_rather_than_stopping() -> void:
	# Put the player just north of the southern sea and walk south-west into it.
	_world.player_pos = Vector2(140.5, float(Region.SEA_SOUTH) + 0.5)
	var start_x: float = _world.player_pos.x
	var start_y: float = _world.player_pos.y
	_walk(Vector2i(-1, 1), 6)
	assert_true(_world.player_pos.x < start_x - 3.0, "kept moving west")
	assert_true(absf(_world.player_pos.y - start_y) < 1.01, "but not into the water")


func test_the_king_kills_the_player_in_exactly_three_touches() -> void:
	var grace: int = ContactRules.invulnerable_steps()
	_world.player_pos = _world.king_pos
	_sim.advance(1)
	assert_eq(_world.player_hp, 6, "first touch")
	assert_eq(_world.touches_taken, 1)
	assert_eq(_world.deaths, 0)

	_sim.advance(grace)
	assert_eq(_world.player_hp, 2, "second touch, after the grace window")
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
	assert_eq(_world.player_tile(), Region.BRINDLE, "back where they woke up")
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
