extends TestCase

## Health comes back on its own.
##
## The Phase 3 stopgap that made the wild survivable: six calm seconds, then a point
## at a time, faster in a town. These four lived in the wildlife suite because the
## beasts were what did the hurting; the beasts are gone (2026-09-13, §4) and the
## king still is not, so the mending stays and the tests move here.

var _sim: Sim = null
var _world: WorldState = null


func before_each() -> void:
	_sim = Game.build()
	_world = _sim.store(&"world") as WorldState


func test_nothing_mends_while_you_are_still_being_hurt() -> void:
	_world.player_hp = 4
	_world.last_hurt_step = _sim.step
	_sim.advance(RecoveryRules.calm_steps() - 2)
	assert_eq(_world.player_hp, 4, "still bleeding, still hurt")


func test_health_comes_back_slowly_in_the_open() -> void:
	_world.player_pos = alone_on_the_road()
	_world.player_tile_last = _world.player_tile()
	_world.player_hp = 5
	_world.last_hurt_step = _sim.step
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


func test_a_full_recovery_in_the_open_is_minutes_not_an_afternoon() -> void:
	# **Mends, not points.** A rest restores `MEND_PER_REST` of the bar, so the time to
	# fill it is the number of mends and not the number of points — which is what this
	# claim always meant, and what it stopped saying the day the bar went from ten to a
	# hundred (2026-09-24). Written this way it holds at any size of bar.
	var mends: float = float(WorldState.MAX_HP) / float(WorldState.MEND_PER_REST)
	assert_true(RecoveryRules.WILD_SECONDS_PER_POINT * mends < 240.0,
		"a full recovery in the open is minutes, not a lost afternoon")
