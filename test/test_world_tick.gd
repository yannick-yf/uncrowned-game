extends TestCase

## Phase 3, stage 1: the world drifts.
##
## §8's fifth consequence — "I do nothing for a week, and come back to the Muster
## to find fewer tents" — and the structure the other four will hang off.
##
## Most of these run a *bare* simulation: the world-tick store and one system,
## nothing else. A day is 1,440 ticks and a tick is fifteen steps, so a week
## through the whole game is a hundred and fifty thousand steps across eight
## systems, and a test that wants to watch a number ease does not need any of it.
## One test runs the real thing, because the integration is worth proving once.


## Sets the army's target from an *external* event, so that a drift can be
## replayed without walking the whole Phase 1 chain to earn the fact first.
class TargetSystem extends SimSystem:
	func on_event(sim: Sim, event: SimEvent) -> void:
		if event.type != &"set_army_target":
			return
		var ticked := sim.store(&"worldtick") as WorldTick
		ticked.army_target = float(event.data.get("to", 100.0))
		ticked.army_strength = float(event.data.get("from", ticked.army_strength))


func _bare() -> Sim:
	var sim := Sim.new()
	sim.add_store(&"world", Game.build_world())
	sim.add_store(&"worldtick", WorldTick.new())
	sim.add_system(TargetSystem.new())
	sim.add_system(WorldTickSystem.new())
	return sim


func _days(sim: Sim, count: float) -> void:
	sim.advance_world_ticks(int(float(Game.TICKS_PER_IN_GAME_DAY) * count))


# ------------------------------------------------------------- the structure ---

func test_the_twelve_are_indexed_the_way_spec_8_says() -> void:
	var ticked := WorldTick.new()
	assert_eq(ticked.grain_price.size(), Region.ZONE_ORDER.size(), "grain is per town")
	assert_eq(ticked.town_sentiment.size(), Region.ZONE_ORDER.size(), "so is sentiment")
	assert_true(absf(ticked.grain_in(&"harrowgate") - WorldTick.NEUTRAL) < 0.01)
	assert_true(absf(ticked.grain_in(&"cairnwell") - WorldTick.NEUTRAL) < 0.01)
	assert_true(absf(ticked.army_strength - 100.0) < 0.01, "and one army, at full strength")


func test_the_escort_is_read_off_army_strength_not_counted_by_hand() -> void:
	# §3's "roughly one and a half fewer per power base" never worked: six bases at
	# 1.5 leaves one man, and 1.5 is not a person.
	assert_eq(WorldRules.escort_for(100.0), 10, "ten at full strength")
	assert_eq(WorldRules.escort_for(40.0), 5, "five once the fraud is public")
	assert_eq(WorldRules.escort_for(0.0), 2, "a bare handful, never none")
	var middling: int = WorldRules.escort_for(70.0)
	assert_true(middling < 10 and middling > 5, "and everything between is between")


# ------------------------------------------------------------------ the drift ---

func test_a_world_with_no_cause_in_it_does_not_wander() -> void:
	# **Sharpened 2026-09-12.** This used to assert that five days change nothing at
	# all. One thing now changes: the wood the fairies hold gets smaller. That is not
	# the rule breaking — it is the rule working, because there *is* a cause in the
	# world from the first minute and it is the reason the game has a plot. The
	# Cinderworks is running, and the furnaces eat the wood.
	#
	# So the claim is stated the harder way round: stop the furnaces and nothing
	# moves at all. A drift with a cause you can switch off is a drift somebody
	# reasoned about, which is what §8 was protecting against when it refused twelve
	# invented rates.
	var sim: Sim = _bare()
	var ticked := sim.store(&"worldtick") as WorldTick
	ticked.steel_output = 0.0
	var before: String = ticked.fingerprint()
	_days(sim, 5.0)
	assert_eq(ticked.fingerprint(), before, "nothing running, so nothing changed")


func test_the_one_thing_that_moves_on_its_own_is_the_wood() -> void:
	var sim: Sim = _bare()
	var ticked := sim.store(&"worldtick") as WorldTick
	var held: float = ticked.held_ground
	var army: float = ticked.army_strength
	_days(sim, 5.0)
	assert_true(ticked.held_ground < held, "five days of furnaces took some of it")
	assert_eq(ticked.army_strength, army, "and moved nothing else")


func test_the_army_eases_toward_its_target_over_days() -> void:
	var sim: Sim = _bare()
	var ticked := sim.store(&"worldtick") as WorldTick
	sim.submit(&"set_army_target", {"from": 75.0, "to": WorldRules.ARMY_AFTER_FRAUD})
	sim.advance(2)
	assert_eq(ticked.army_strength, 75.0, "the men already on the edge went tonight")

	_days(sim, 1.0)
	assert_true(ticked.army_strength < 75.0, "more left overnight")
	assert_true(ticked.army_strength > WorldRules.ARMY_AFTER_FRAUD, "and it is not over")

	_days(sim, 4.0)
	assert_eq(ticked.army_strength, WorldRules.ARMY_AFTER_FRAUD, "until it is")


func test_the_drift_stops_at_its_target_rather_than_running_past() -> void:
	var sim: Sim = _bare()
	var ticked := sim.store(&"worldtick") as WorldTick
	sim.submit(&"set_army_target", {"from": 45.0, "to": WorldRules.ARMY_AFTER_FRAUD})
	_days(sim, 6.0)
	assert_eq(ticked.army_strength, WorldRules.ARMY_AFTER_FRAUD, "eased to it, not through it")
	assert_eq(ticked.kings_escort(), 5)


func test_a_changing_escort_announces_itself() -> void:
	var sim: Sim = _bare()
	sim.submit(&"set_army_target", {"from": 100.0, "to": 0.0})
	_days(sim, 9.0)
	var announced: int = 0
	for event: SimEvent in sim.events.all():
		if event.type == &"escort_changed":
			announced += 1
			assert_true(event.derived, "the world saying something back, not something done to it")
	assert_true(announced >= 6, "the escort fell in steps and said so each time: %d" % announced)


func test_a_week_of_the_world_running_itself_replays_exactly() -> void:
	var sim: Sim = _bare()
	sim.submit(&"set_army_target", {"from": 75.0, "to": WorldRules.ARMY_AFTER_FRAUD})
	_days(sim, 4.0)
	var ticked := sim.store(&"worldtick") as WorldTick

	var systems: Array[SimSystem] = [TargetSystem.new(), WorldTickSystem.new()]
	var replayed: Sim = Sim.replay(
		sim.events.external_rows(), sim.rng_seed, systems, sim.step,
		{&"world": Game.build_world(), &"worldtick": WorldTick.new()})
	assert_eq((replayed.store(&"worldtick") as WorldTick).fingerprint(), ticked.fingerprint(),
		"days of drift rebuild from one logged event")


# ------------------------------------------------------------ the whole thing ---

