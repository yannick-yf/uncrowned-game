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


# --------------------------------------------------------------- the way in (F2) ---
#
# F1 built a fight that nothing could reach: `fight_began` was submitted by tests and
# by nothing else, and no key was bound to a blow. Yannick walked to the works looking
# for a fight, found nobody to fight and no way to start one, and that is what these
# check. The sparring partner belongs to no side and no quest on purpose — the fight
# has to be playable and retunable long before the quest exists.

func _stand_by(sim: Sim, who: StringName) -> Array[String]:
	var world := sim.store(&"world") as WorldState
	world.player_pos = (sim.store(&"cast") as Cast).get_npc(who).centre()
	sim.submit(&"talk", {"npc": String(who)})
	sim.advance(2)
	var out: Array[String] = []
	for option: DialogueOption in world.options:
		out.append(String(option.intent))
	return out


func test_somebody_near_the_start_will_fight_you() -> void:
	var sim: Sim = Game.build()
	var cast := sim.store(&"cast") as Cast
	var bram: Npc = cast.get_npc(&"bram")
	assert_not_null(bram, "the sparring partner exists")

	# Within a short walk of where a new run wakes up: the clearing, per
	# `WorldState`'s respawn rule. A fight nobody can reach is what F1 shipped.
	var world := sim.store(&"world") as WorldState
	var woke_at: Vector2 = world.region().clearing_centre()
	var tiles: float = woke_at.distance_to(bram.centre())
	assert_true(tiles < 60.0,
		"and he is a short walk from where the game starts: %.0f tiles" % tiles)

	var offered: Array[String] = _stand_by(sim, &"bram")
	assert_true(offered.has("ask_bram_spar"),
		"and one of the things you may say to him starts a fight: %s" % str(offered))


func test_a_fight_begins_because_you_said_so() -> void:
	# **A fight is something you say.** Not something you walk into — that is the king's
	# on-contact death, which is the oldest debt in the project and not the design.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var fight: Fight = _fight(sim)
	_stand_by(sim, &"bram")
	assert_true(world.in_dialogue(), "you are talking to him")
	assert_false(fight.on(), "and nobody is fighting yet")

	sim.submit(&"choose_intent", {"intent": "ask_bram_spar"})
	sim.advance(4)
	assert_true(fight.on(), "saying it squares the two of you up")
	assert_eq(fight.opponent, &"bram", "against him and nobody else")
	assert_false(world.in_dialogue(),
		"and the conversation is over — a dialogue box open behind a fight would read "
		+ "the player's blows as menu choices")


func test_you_can_ask_him_again() -> void:
	# The whole reason he exists: the fight will be retuned many times, and a sparring
	# partner you can only fight once is a sparring partner who is no use after Tuesday.
	var sim: Sim = Game.build()
	var fight: Fight = _fight(sim)
	_stand_by(sim, &"bram")
	sim.submit(&"choose_intent", {"intent": "ask_bram_spar"})
	sim.advance(4)
	sim.submit(&"fight_left", {})
	sim.advance(2)
	assert_false(fight.on(), "the first one is over")

	var again: Array[String] = _stand_by(sim, &"bram")
	assert_true(again.has("ask_bram_spar"), "and he will go again: %s" % str(again))


func test_the_fight_you_talked_your_way_into_replays() -> void:
	# The log holds the line you chose, not the fight: `fight_began` is *derived*, so
	# replay recomputes it from the intent. If that were submitted instead, a replayed
	# log would start two fights.
	var sim: Sim = Game.build()
	_stand_by(sim, &"bram")
	sim.submit(&"choose_intent", {"intent": "ask_bram_spar"})
	sim.advance(4)
	var fight: Fight = _fight(sim)
	_play(sim, fight, 400)

	var replayed: Sim = Game.replay(sim)
	assert_eq((replayed.store(&"fight") as Fight).fingerprint(), fight.fingerprint(),
		"the same fight, rebuilt from the conversation alone")
	assert_eq((replayed.store(&"world") as WorldState).player_hp,
		(sim.store(&"world") as WorldState).player_hp, "and the same wounds")


func test_the_two_keys_are_bound() -> void:
	# The third thing missing on 2026-09-19: the fight could not be reached, and if it
	# had been there was no key to hit anybody with. K and O, as **physical** keycodes,
	# so the pair sits in the same place on AZERTY and on QWERTY.
	for action: StringName in [&"strike", &"guard"]:
		assert_true(InputMap.has_action(action), "%s is a key" % action)
		assert_true(InputMap.action_get_events(action).size() > 0,
			"%s has something bound to it" % action)


# ------------------------------------------------- the fight stands somewhere (F3) ---
#
# Until F3 a fight moved two numbers and the player stood stock still in the world,
# which is why there was nothing for a camera to frame. These check the join: the line
# becomes ground, the ground is bounded, and only one hand moves the player.

func _square_up(sim: Sim) -> Fight:
	_stand_by(sim, &"bram")
	sim.submit(&"choose_intent", {"intent": "ask_bram_spar"})
	sim.advance(4)
	return _fight(sim)


func test_a_fight_happens_where_you_were_standing() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	_stand_by(sim, &"bram")
	var stood_at: Vector2 = world.player_pos
	var fight: Fight = _square_up(sim)

	assert_eq(fight.origin_tiles, stood_at, "the arena is put down where you were")
	assert_true(absi(fight.toward) == 1, "and it runs east or west, never north")
	# The two profiles a fight needs are the two the traveller already has, and that is
	# only true while the line is the world's east-west axis.
	assert_eq(fight.at_tiles(0).y, stood_at.y, "nobody moves up or down the map")
	assert_eq(fight.at_tiles(CombatRules.start_apart_mm()).y, stood_at.y, "neither of them")
	assert_true(absf(fight.centre_tiles().x - stood_at.x) > 0.1,
		"and the middle of it is between the two of you, not under your feet")


func test_the_line_is_ground_under_the_players_feet() -> void:
	# The whole of F3 in one assertion: move along the fight's line, move in the world.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var fight: Fight = _square_up(sim)
	var began_at: Vector2 = world.player_pos
	assert_eq(began_at, fight.origin_tiles, "you start where the arena was put down")

	sim.submit(&"fight_input", {"walk": 1})
	sim.advance(30)
	assert_true(world.player_pos.x != began_at.x, "walking the line walks the world")
	assert_eq(world.player_pos.y, began_at.y, "and only ever sideways")
	assert_eq(world.player_pos, fight.at_tiles(fight.player_at_mm),
		"the two agree to the millimetre, every step")
	assert_eq(world.player_facing, Vector2i(fight.toward, 0),
		"and you are looking at him, not at where you are walking")


func test_you_cannot_walk_out_of_a_fight() -> void:
	# **Yannick, 2026-09-19: no fleeing in the demo.** Backing away for ten seconds is
	# not a way out of a fight you started by saying so.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var fight: Fight = _square_up(sim)
	var centre: Vector2 = fight.centre_tiles()
	var wall: float = fight.arena_tiles()

	sim.submit(&"fight_input", {"walk": -1})
	var furthest: float = 0.0
	for _step: int in 600:
		if not fight.on():
			break
		sim.advance(1)
		furthest = maxf(furthest, absf(world.player_pos.x - centre.x))
	assert_true(furthest <= wall + 0.001,
		"the wall holds: %.2f tiles out of %.2f" % [furthest, wall])
	assert_true(furthest > wall - 0.2,
		"and it was actually reached, or this test proves nothing: %.2f" % furthest)
	assert_true(fight.on() or fight.outcome != &"left",
		"walking into the wall for ten seconds never ends the fight by leaving")


func test_he_cannot_be_knocked_out_of_the_ring_either() -> void:
	var sim: Sim = Game.build()
	var fight: Fight = _square_up(sim)
	var low: int = CombatRules.arena_centre_mm() - CombatRules.arena_radius_mm()
	var high: int = CombatRules.arena_centre_mm() + CombatRules.arena_radius_mm()
	for _step: int in 1200:
		if not fight.on():
			break
		_play(sim, fight, 1)
		assert_true(fight.player_at_mm >= low and fight.player_at_mm <= high,
			"the player stayed in: %d" % fight.player_at_mm)
		assert_true(fight.opponent_at_mm >= low and fight.opponent_at_mm <= high,
			"and so did he: %d" % fight.opponent_at_mm)


func test_only_one_hand_moves_the_player() -> void:
	# `MovementSystem` stands down while a fight is on, exactly as it does mid
	# conversation. Two writers on one position is the bug `Sim.ticks_held` taught once
	# already, and here it would show as the player sliding out of his own fight.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	_stand_by(sim, &"bram")
	# Walking north *before* squaring up, and never letting go of the key.
	sim.submit(&"move_intent", {"x": 0, "y": -1})
	var fight: Fight = _square_up(sim)
	var line_y: float = fight.origin_tiles.y
	sim.advance(120)
	assert_true(fight.on(), "still fighting")
	assert_eq(world.player_pos.y, line_y,
		"a key held down from before the fight does not drag you out of it")


func test_the_camera_never_turns() -> void:
	# The constraint the whole of `docs/COMBAT.md` §1 turns on, kept as a test because
	# it is one number and forgetting it costs his brother eight drawings per character.
	assert_eq(World3d.AZIMUTH_DEGREES, 0.0,
		"the azimuth is the one camera value a fight may not touch")
	assert_true(World3d.FIGHT_TILT_DEGREES < World3d.TILT_DEGREES,
		"the lens drops for a fight: %.0f from %.0f"
		% [World3d.FIGHT_TILT_DEGREES, World3d.TILT_DEGREES])
	assert_true(World3d.FIGHT_TILT_DEGREES >= 20.0,
		"but not so far that his buildings stand in front of it: %.0f"
		% World3d.FIGHT_TILT_DEGREES)


func test_the_arena_fits_in_the_frame() -> void:
	# A wall the camera cannot see is a wall the player walks into for no visible
	# reason. The lens is orthographic and `size` is its *height* in metres, so the
	# width is that times the aspect — and the arena has to fit across it.
	var across_tiles: float = CombatRules.tiles_of(CombatRules.arena_radius_mm() * 2)
	var across_m: float = across_tiles * BakeRules.METRES_PER_TILE
	var frame_m: float = World3d.FIGHT_SIZE_M * (16.0 / 9.0)
	assert_true(across_m < frame_m,
		"the arena is %.1f m across and the frame is %.1f m" % [across_m, frame_m])


# ------------------------------------------------ in, and back out again (F4) ---
#
# A fight has to hand back exactly one result, to whoever asked for it, and leave the
# player somewhere with a health they can believe. The first build read the loss out of
# `WorldState` afterwards — full health, a death on the counter, still in hitstun — and
# every one of those three can be true for another reason.

## Stand there and take it. The shortest way to lose a fight.
func _take_it(sim: Sim, fight: Fight, steps: int) -> void:
	var held: Dictionary = {}
	for _step: int in steps:
		if not fight.on():
			return
		var want: Dictionary = {"walk": 0, "attack": false, "guard": false}
		if want != held:
			sim.submit(&"fight_input", want)
			held = want
		sim.advance(1)


func test_he_stops_when_you_go_down() -> void:
	# Bram says so in his own line, so the code had better agree with the content: a
	# sparring partner who sends you back to the fairies' clearing twelve seconds into
	# the game is not a sparring partner.
	assert_true(CombatRules.spares(&"bram"), "he is written as sparing you")
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var fight: Fight = _square_up(sim)
	var stood_at: Vector2 = world.player_pos
	_take_it(sim, fight, 4000)

	assert_eq(fight.outcome, &"lost", "you lost")
	assert_eq(world.deaths, 0, "but you did not die")
	assert_eq(world.player_hp, 1, "he left you one")
	assert_true(stood_at.distance_to(world.player_pos) < 4.0,
		"and you are still in the village, not back in the clearing: %.1f tiles"
		% stood_at.distance_to(world.player_pos))


func test_somebody_who_does_not_spare_you_kills_you() -> void:
	# The other half of the same rule, and the default: anybody not written as sparing
	# you finishes it. `halgrave` is not in `content/moves.json`, so he takes `_default`.
	assert_false(CombatRules.spares(&"halgrave"), "the foreman is nobody's sparring partner")
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	sim.submit(&"fight_began", {"opponent": "halgrave"})
	sim.advance(1)
	var fight: Fight = _fight(sim)
	_take_it(sim, fight, 4000)

	assert_eq(fight.outcome, &"lost", "you lost this one too")
	assert_eq(world.deaths, 1, "and this time you died for it")
	assert_eq(world.player_hp, WorldState.MAX_HP, "woken up whole, as the checkpoint rule says")
	assert_true(world.player_pos.distance_to(world.region().clearing_centre()) < 2.0,
		"back where you first woke, having never rested")


func test_winning_leaves_you_standing_with_your_bruises() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var fight: Fight = _square_up(sim)
	var stood_at: Vector2 = world.player_pos
	_play(sim, fight, 4000)

	assert_eq(fight.outcome, &"won", "he went down")
	assert_eq(world.deaths, 0, "you did not")
	assert_true(world.player_hp < WorldState.MAX_HP, "and it cost you: %d" % world.player_hp)
	assert_true(world.player_hp > 0, "but you are up")
	assert_true(stood_at.distance_to(world.player_pos) <= fight.arena_tiles() + 0.01,
		"and you are inside the arena you fought in")


func test_one_result_to_whoever_asked_and_only_one() -> void:
	# **Nothing is applied twice.** `_end` cannot run again because the first thing it
	# does is put the fight down, and that is worth a test rather than a comment: a
	# quest that applied its outcome twice would move a place's two numbers twice.
	var sim: Sim = Game.build()
	var fight: Fight = _square_up(sim)
	assert_eq(fight.asked_by, &"ask_bram_spar", "the fight remembers the line that started it")
	_play(sim, fight, 4000)

	# Ask it to end again, several ways, after it already has.
	sim.submit(&"fight_left", {})
	sim.advance(4)

	var ended: Array[SimEvent] = []
	for event: SimEvent in sim.events.all():
		if event.type == &"fight_ended":
			ended.append(event)
	assert_eq(ended.size(), 1, "exactly one result came out of one fight")
	assert_eq(String(ended[0].data.get("asked_by", "")), "ask_bram_spar",
		"and it is handed back to whoever asked")
	assert_eq(String(ended[0].data.get("how", "")), "won", "with the answer")
	assert_eq(String(ended[0].data.get("opponent", "")), "bram", "and who it was against")


func test_the_world_starts_again_whichever_way_it_went() -> void:
	for lose: bool in [true, false]:
		var sim: Sim = Game.build()
		var fight: Fight = _square_up(sim)
		var stopped_at: int = sim.tick
		if lose:
			_take_it(sim, fight, 4000)
		else:
			_play(sim, fight, 4000)
		assert_false(fight.on(), "the fight is over")
		assert_eq(sim.tick, stopped_at, "and the world did not move while it ran")
		sim.advance(Sim.STEPS_PER_WORLD_TICK * 3)
		assert_true(sim.tick > stopped_at,
			"and it is running again afterwards (lost: %s)" % lose)


func test_a_blow_costs_what_the_file_says_it_costs() -> void:
	# The grace window in `WorldState.hurt` is *contact's* — it exists because standing
	# inside the king drains ten hit points in three frames. A fight's blows are spaced
	# by frame data and already cannot land twice, so a blow announced is a blow taken.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var fight: Fight = _square_up(sim)
	_take_it(sim, fight, 4000)

	var announced: int = 0
	for event: SimEvent in sim.events.all():
		if event.type == &"blow_landed" and String(event.data.get("by", "")) == "bram":
			announced += 1
	assert_true(announced > 0, "he hit you at all")
	assert_eq(world.touches_taken, announced,
		"every blow the fight announced is a blow the player actually took")

