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
