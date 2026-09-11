extends TestCase

## Phase 2, stage 3: the wild is dangerous.
##
## The point of these is the *difference* between the two routes. With the ground
## no longer slowing anyone, the road's only virtue is that nothing on it wants to
## eat you, and that has to be true by test rather than by intention.

var _sim: Sim = null
var _world: WorldState = null
var _wild: Wildlife = null


func before_each() -> void:
	_sim = Game.build()
	_world = _sim.store(&"world") as WorldState
	_wild = _sim.store(&"wildlife") as Wildlife


func _walk_to(target: Vector2i, max_seconds: float) -> bool:
	var deadline: int = _sim.step + int(max_seconds * float(Sim.STEPS_PER_REAL_SECOND))
	var route: Array[Vector2] = Navigation.waypoints(_world.region(), _world.player_tile(), target)
	if route.is_empty():
		return false
	for point: Vector2 in route:
		while _sim.step < deadline:
			var delta: Vector2 = point - _world.player_pos
			if delta.length() <= 1.0:
				break
			var dir := Vector2i.ZERO
			if absf(delta.x) >= 0.5:
				dir.x = 1 if delta.x > 0.0 else -1
			if absf(delta.y) >= 0.5:
				dir.y = 1 if delta.y > 0.0 else -1
			_sim.submit(&"move_intent", {"x": dir.x, "y": dir.y})
			_sim.advance(Sim.STEPS_PER_REAL_SECOND / 10)
		if _sim.step >= deadline:
			return false
	return true


## Steer straight through a list of points, without pathfinding. Used for the road
## because a shortest path between two corners cuts the bend onto the verge.
func _follow(points: Array[Vector2i], max_seconds: float) -> bool:
	var deadline: int = _sim.step + int(max_seconds * float(Sim.STEPS_PER_REAL_SECOND))
	for point: Vector2i in points:
		var target: Vector2 = Vector2(point) + Vector2(0.5, 0.5)
		while _sim.step < deadline:
			var delta: Vector2 = target - _world.player_pos
			if delta.length() <= 1.0:
				break
			var dir := Vector2i.ZERO
			if absf(delta.x) >= 0.5:
				dir.x = 1 if delta.x > 0.0 else -1
			if absf(delta.y) >= 0.5:
				dir.y = 1 if delta.y > 0.0 else -1
			_sim.submit(&"move_intent", {"x": dir.x, "y": dir.y})
			_sim.advance(Sim.STEPS_PER_REAL_SECOND / 10)
		if _sim.step >= deadline:
			return false
	return true


## Health lost on a journey, counting a death as the full ten it cost you.
func _blood_price(before_hp: int, before_deaths: int) -> int:
	var deaths: int = _world.deaths - before_deaths
	return before_hp - _world.player_hp + deaths * WorldState.MAX_HP


func test_beasts_are_all_slower_than_you() -> void:
	# A predator you cannot outrun is a tax, not a risk.
	for kind: StringName in BeastRules.KINDS:
		assert_true(BeastRules.speed_for(kind) < MovementRules.TILES_PER_SECOND,
			"%s runs at %.1f against your %.1f" % [
				kind, BeastRules.speed_for(kind), MovementRules.TILES_PER_SECOND])


func test_nothing_lives_on_the_road_or_in_a_town() -> void:
	assert_false(BeastRules.is_wild_ground(Region.Terrain.ROAD), "§4 calls the road patrolled")
	assert_false(BeastRules.is_wild_ground(Region.Terrain.TOWN))
	assert_false(BeastRules.is_wild_ground(Region.Terrain.CAMP))
	assert_false(BeastRules.is_wild_ground(Region.Terrain.CASTLE))
	assert_true(BeastRules.is_wild_ground(Region.Terrain.FOREST))
	assert_true(BeastRules.is_wild_ground(Region.Terrain.WILD))


func test_beasts_never_stand_on_the_road_however_long_you_wait() -> void:
	var region: Region = _world.region()
	_world.player_pos = Vector2(200.5, 140.5)
	_world.player_tile_last = _world.player_tile()
	_sim.advance(Sim.STEPS_PER_REAL_SECOND * 40)
	assert_true(_wild.count() > 0, "the wood is inhabited")
	for beast: Beast in _wild.beasts:
		var terrain: Region.Terrain = region.terrain_at(beast.tile())
		assert_true(BeastRules.is_wild_ground(terrain),
			"a %s is standing on terrain %d" % [beast.kind, terrain])
		assert_eq(region.zone_at(beast.tile()), &"", "and not inside a settlement")


func test_walking_the_kings_road_costs_nothing() -> void:
	var hp: int = _world.player_hp
	var deaths: int = _world.deaths
	# Stopping short of the castle gate: the road is safe, but the man standing at
	# the end of it is not, and that is a different test.
	var route: Array[Vector2i] = []
	for point: Vector2i in Region.road_waypoints():
		if Vector2(point).distance_to(Vector2(Region.BLACKCAIRN)) > 14.0:
			route.append(point)
	assert_true(_follow(route, 200.0), "walked the King's Road to the capital")
	assert_eq(_blood_price(hp, deaths), 0, "the long way round is the safe way round")
	assert_true(_world.player_pos.distance_to(Vector2(Region.CAIRNWELL)) < 40.0,
		"and got most of the way across the region")


func test_cutting_through_the_thornwood_draws_blood() -> void:
	var hp: int = _world.player_hp
	var deaths: int = _world.deaths
	# Straight across the wood, which is what the shortest path does.
	assert_true(_walk_to(Vector2i(150, 90), 180.0), "crossed the wild")
	var price: int = _blood_price(hp, deaths)
	assert_true(price > 0, "the wild took nothing, so it is not a choice")
	assert_true(price <= 24,
		"the wild took %d health, which is a wall rather than a risk" % price)
	assert_true(_sim.facts.has(BeastRules.FACT_WILD_IS_DANGEROUS),
		"and you now know it, which is a fact like any other")


func test_the_same_seed_meets_the_same_animals() -> void:
	_world.player_pos = Vector2(200.5, 140.5)
	_world.player_tile_last = _world.player_tile()
	_sim.advance(Sim.STEPS_PER_REAL_SECOND * 20)
	var first: String = _wild.fingerprint()

	var other: Sim = Game.build()
	var other_world := other.store(&"world") as WorldState
	other_world.player_pos = Vector2(200.5, 140.5)
	other_world.player_tile_last = other_world.player_tile()
	other.advance(Sim.STEPS_PER_REAL_SECOND * 20)
	assert_eq((other.store(&"wildlife") as Wildlife).fingerprint(), first,
		"same seed, same wood, same animals in the same places")


func test_a_mauling_replays_from_the_log() -> void:
	assert_true(_walk_to(Vector2i(180, 120), 120.0), "walked into the wood")
	assert_true(_wild.count() > 0)

	var replayed: Sim = Game.replay(_sim)
	assert_eq((replayed.store(&"world") as WorldState).fingerprint(), _world.fingerprint(),
		"the same walk rebuilds the same wounds")
	assert_eq((replayed.store(&"wildlife") as Wildlife).fingerprint(), _wild.fingerprint(),
		"and the same animals, in the same places, hunting or not")


# ------------------------------------------- recovery, a Phase 3 stopgap ---

func test_nothing_mends_while_something_is_biting_you() -> void:
	_world.player_hp = 4
	_world.last_hurt_step = _sim.step
	_sim.advance(RecoveryRules.calm_steps() - 2)
	assert_eq(_world.player_hp, 4, "still bleeding, still hurt")


func test_health_comes_back_slowly_in_the_open() -> void:
	_world.player_pos = Vector2(200.5, 140.5)
	_world.player_tile_last = _world.player_tile()
	_world.player_hp = 5
	_world.last_hurt_step = _sim.step
	# Far from anything with teeth, so the only thing happening is mending.
	_world.zones[WorldState.OVERWORLD] = _world.region()
	var quiet: int = RecoveryRules.calm_steps() \
		+ RecoveryRules.steps_per_point(false) * 2
	for _i: int in quiet:
		_sim.advance(1)
		_world.last_hurt_step = maxi(_world.last_hurt_step, 0)
	assert_true(_world.player_hp > 5, "a quiet minute puts something back")


func test_a_town_mends_you_faster_than_the_country() -> void:
	assert_true(RecoveryRules.steps_per_point(true) < RecoveryRules.steps_per_point(false),
		"four walls and somebody who knows medicine")
	assert_true(RecoveryRules.steps_per_point(false) / RecoveryRules.steps_per_point(true) >= 3,
		"and enough faster that walking back is worth it")


func test_the_wild_is_survivable_now_that_health_returns() -> void:
	# The point of the stopgap: the cost of a crossing stops ratcheting, so a
	# second journey is not strictly more dangerous than the first.
	assert_true(RecoveryRules.WILD_SECONDS_PER_POINT * float(WorldState.MAX_HP) < 240.0,
		"a full recovery in the open is minutes, not a lost afternoon")
