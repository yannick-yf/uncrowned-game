extends TestCase

## The fight, with no screen (F1).
##
## The rules of a fight are the same whatever it is drawn on, which is why this could be
## built before the question of the arena was settled. Every test here runs headless:
## nobody draws anything, and a fight is a few integers changing sixty times a second.

## **In the fast suite on purpose.** A fight is a few integers a frame and no map at
## all, so thirteen of them cost nothing measurable: 12.2 s either way. The fight is the
## thing that will be retuned most often in this project, and a balance change you have
## to remember to check is a balance change nobody checks.
const SLOW: bool = false


func _fight(sim: Sim) -> Fight:
	return sim.store(&"fight") as Fight


func _start(sim: Sim) -> Fight:
	sim.submit(&"fight_began", {"opponent": "halgrave"})
	sim.advance(1)
	return _fight(sim)


## **A competent player, so the tests fight rather than flail.**
##
## The first draft of these tests pressed attack on a fixed rhythm and lost, which said
## nothing about the mechanic and everything about the rhythm. This is the loop a person
## plays: close the distance, hit him while he is open, hold the guard the rest of the
## time. It submits only when what is held changes, so the log stays one event per change.
func _play(sim: Sim, fight: Fight, steps: int) -> void:
	var held: Dictionary = {}
	for _step: int in steps:
		if not fight.on():
			return
		var want: Dictionary = _wants(fight)
		if want != held:
			sim.submit(&"fight_input", want)
			held = want
		sim.advance(1)


func _wants(fight: Fight) -> Dictionary:
	if not CombatRules.reaches(fight.player_at_mm, fight.opponent_at_mm, CombatRules.STRIKE):
		return {"walk": 1, "attack": false, "guard": false}
	var open: bool = fight.opponent_stun > 0 or fight.opponent_move == &""
	if fight.player_free() and open:
		return {"walk": 0, "attack": true, "guard": false}
	return {"walk": 0, "attack": false, "guard": true}


# ------------------------------------------------------------------- the data ---

func test_the_frame_data_is_the_whole_of_the_balance() -> void:
	# Every number that decides how the fight feels is in content/moves.json, in steps,
	# because the simulation's step is already a fighting game's frame.
	assert_true(CombatRules.has_move(CombatRules.STRIKE), "the player has a blow")
	assert_true(CombatRules.has_move(CombatRules.SWING), "and so does he")
	assert_eq(CombatRules.length(CombatRules.STRIKE),
		CombatRules.of(CombatRules.STRIKE, "startup")
			+ CombatRules.of(CombatRules.STRIKE, "active")
			+ CombatRules.of(CombatRules.STRIKE, "recovery"),
		"a move is its three parts and nothing else")


func test_his_blow_is_slow_enough_to_be_answered() -> void:
	# **The finding that most shapes this fight.** Human reaction is about 265 ms, which
	# is 16 frames. A Street Fighter jab is 4 — it exists to be guessed at, between two
	# people. Against one opponent the player must be able to learn the tell and answer
	# it, so his wind-up sits in the 18-28 band. Street Fighter's feel at a quarter of
	# its speed.
	var startup: int = CombatRules.of(CombatRules.SWING, "startup")
	assert_true(startup >= 18, "his wind-up can be seen: %d frames" % startup)
	assert_true(startup <= 28, "and it does not take a week: %d frames" % startup)
	assert_true(startup > CombatRules.of(CombatRules.STRIKE, "startup"),
		"and yours is the faster of the two")


func test_swinging_into_a_raised_guard_is_punished() -> void:
	# The rule that makes a guard worth holding: blockstun is shorter than hitstun, so
	# a blow that is blocked leaves the swinger owing frames.
	assert_true(CombatRules.advantage_on_hit(CombatRules.STRIKE) > 0,
		"landing it is your turn: %d" % CombatRules.advantage_on_hit(CombatRules.STRIKE))
	assert_true(CombatRules.advantage_on_block(CombatRules.STRIKE) < 0,
		"having it blocked is his: %d" % CombatRules.advantage_on_block(CombatRules.STRIKE))
	assert_true(CombatRules.advantage_on_block(CombatRules.SWING)
			< CombatRules.advantage_on_block(CombatRules.STRIKE),
		"and his heavy blow is the worse thing to have blocked")


# ------------------------------------------------------------------ the fight ---

func test_a_fight_begins_with_the_two_of_them_apart() -> void:
	# The distance is not asserted to the millimetre, because he starts walking on the
	# first frame and a test that pinned it would be measuring his first step instead.
	# What matters is that neither can hit the other by standing still.
	var apart: int = CombatRules.start_apart_mm()
	assert_false(CombatRules.reaches(0, apart, CombatRules.STRIKE),
		"your blow does not cross the opening: %d mm" % apart)
	assert_false(CombatRules.reaches(apart, 0, CombatRules.SWING),
		"and neither does his")

	var sim: Sim = Game.build()
	var fight: Fight = _start(sim)
	assert_true(fight.on(), "somebody is fighting")
	assert_eq(fight.opponent, &"halgrave")
	assert_true(fight.apart_mm() > apart - CombatRules.walk_mm_per_step() * 2,
		"and the opening is still there a frame in: %d mm" % fight.apart_mm())


func test_a_blow_lands_in_range_and_misses_out_of_it() -> void:
	var sim: Sim = Game.build()
	var fight: Fight = _start(sim)
	var hp: int = fight.opponent_hp

	# Swung from where they start, it reaches nothing. His wind-up is longer than the
	# whole of the player's blow, so nothing of his disturbs the measurement.
	sim.submit(&"fight_input", {"attack": true})
	sim.advance(CombatRules.length(CombatRules.STRIKE) + 2)
	assert_eq(fight.opponent_hp, hp, "a blow swung at nothing costs him nothing")

	# The same blow, played properly, costs him.
	sim.submit(&"fight_input", {"attack": false})
	_play(sim, fight, 240)
	assert_true(fight.opponent_hp < hp,
		"close the distance and it lands: %d of %d" % [fight.opponent_hp, hp])


func test_one_blow_cannot_land_twice() -> void:
	# The standard bug of the genre: a hitbox out for three frames hitting three times.
	var sim: Sim = Game.build()
	var fight: Fight = _start(sim)
	sim.submit(&"fight_input", {"walk": 1})
	sim.advance(60)
	sim.submit(&"fight_input", {"walk": 0, "attack": true})
	var hp: int = fight.opponent_hp
	sim.advance(CombatRules.length(CombatRules.STRIKE) + CombatRules.hitstop(CombatRules.STRIKE) + 2)
	assert_eq(hp - fight.opponent_hp, CombatRules.of(CombatRules.STRIKE, "damage"),
		"one blow, one lot of damage, however many frames it was out for")


func test_a_guard_costs_less_than_taking_it() -> void:
	var guarded: int = CombatRules.damage_through(CombatRules.SWING, true)
	var bare: int = CombatRules.damage_through(CombatRules.SWING, false)
	assert_true(guarded < bare, "a guard is worth raising: %d against %d" % [guarded, bare])
	assert_true(guarded > 0, "and it is not free — nothing about a guard is free")


func test_holding_a_guard_means_holding_no_blow() -> void:
	var sim: Sim = Game.build()
	var fight: Fight = _start(sim)
	sim.submit(&"fight_input", {"walk": 1})
	sim.advance(60)
	sim.submit(&"fight_input", {"walk": 0, "guard": true, "attack": true})
	sim.advance(CombatRules.length(CombatRules.STRIKE) + 4)
	assert_eq(fight.opponent_hp, CombatRules.opponent_hp(),
		"a fighter behind their guard swings at nobody")


func test_he_swings_on_his_own_and_it_costs_the_player() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var fight: Fight = _start(sim)
	var hp: int = world.player_hp
	# Walk into his reach and stand there.
	sim.submit(&"fight_input", {"walk": 1})
	sim.advance(120)
	assert_true(world.player_hp < hp,
		"stand in front of him and he hits you: %d of %d" % [world.player_hp, hp])


func test_the_world_clock_stops_while_they_fight() -> void:
	# SPECS §8. Thirty seconds of fighting would otherwise be two in-game hours of grain
	# drifting, rumours travelling and armies moving.
	var sim: Sim = Game.build()
	sim.advance(Sim.STEPS_PER_WORLD_TICK * 4)
	var before: int = sim.tick
	assert_true(before > 0, "the clock was running")
	var fight: Fight = _start(sim)
	# **Checked every frame, not at the end.** The fight is played out rather than stood
	# through, and a played fight *finishes* — after which the clock is supposed to run
	# again, so an assertion made afterwards would be measuring the wrong thing.
	var held: Dictionary = {}
	var frames: int = 0
	for _step: int in Sim.STEPS_PER_WORLD_TICK * 40:
		if not fight.on():
			break
		var want: Dictionary = _wants(fight)
		if want != held:
			sim.submit(&"fight_input", want)
			held = want
		sim.advance(1)
		frames += 1
		assert_eq(sim.tick, before, "the clock stood still on frame %d" % frames)
	assert_true(frames > Sim.STEPS_PER_WORLD_TICK * 4,
		"and it was a long enough fight to have moved the clock: %d frames" % frames)
	sim.advance(Sim.STEPS_PER_WORLD_TICK * 4)
	assert_true(sim.tick > before, "and started again when they were done")


func test_a_fight_ends_when_somebody_is_down() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var fight: Fight = _start(sim)
	_play(sim, fight, 2000)
	assert_false(fight.on(), "somebody went down")
	assert_eq(fight.outcome, &"won", "and it was not the player")
	# **And winning is not free.** A fight the player walks away from untouched is the
	# sign that his blow can be pre-empted for ever, which is what the first build did.
	assert_true(world.player_hp < WorldState.MAX_HP,
		"he landed something on the way down: %d of %d left" % [world.player_hp, WorldState.MAX_HP])
	assert_eq(world.deaths, 0, "and a competent player is still standing")


func test_leaving_is_an_outcome_too() -> void:
	var sim: Sim = Game.build()
	var fight: Fight = _start(sim)
	sim.submit(&"fight_left", {})
	sim.advance(2)
	assert_false(fight.on())
	assert_eq(fight.outcome, &"left")
	assert_false(sim.ticks_held, "and the world is allowed to run again")


func test_the_same_inputs_replay_to_the_same_frame() -> void:
	# The whole reason a fight lives in the simulation. A save here IS the event log.
	var sim: Sim = Game.build()
	_start(sim)
	sim.submit(&"fight_input", {"walk": 1})
	sim.advance(70)
	sim.submit(&"fight_input", {"walk": 0, "attack": true})
	sim.advance(30)
	sim.submit(&"fight_input", {"attack": false, "guard": true})
	sim.advance(90)
	var fight: Fight = _fight(sim)
	assert_true(fight.on() or fight.outcome != &"", "something happened")

	var replayed: Sim = Game.replay(sim)
	assert_eq((replayed.store(&"fight") as Fight).fingerprint(), fight.fingerprint(),
		"the same fight, rebuilt from the log alone")
	assert_eq((replayed.store(&"world") as WorldState).player_hp,
		(sim.store(&"world") as WorldState).player_hp, "and the same wounds")


func test_how_the_caller_chunks_its_steps_changes_nothing() -> void:
	# `Sim.advance(n)` promises exactly n steps however they are asked for. A fight is
	# the first thing in the game fast enough for that promise to matter.
	var one: Sim = Game.build()
	var many: Sim = Game.build()
	for sim: Sim in [one, many]:
		sim.submit(&"fight_began", {"opponent": "halgrave"})
		sim.submit(&"fight_input", {"walk": 1})
	one.advance(200)
	for _i: int in 200:
		many.advance(1)
	assert_eq((one.store(&"fight") as Fight).fingerprint(),
		(many.store(&"fight") as Fight).fingerprint(),
		"two hundred steps at once and one at a time are the same two hundred steps")
