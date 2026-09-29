extends TestCase

## **Bram calls you over** (O16, 2026-09-29) — Yannick's « dresseur Pokémon »: walk into
## the ground at the village's edge and the man who teaches the sword sees you, a beat,
## the player is held, he walks over, and the conversation opens without the player
## asking for it. Once. The whole of it is simulation — a store, a system, facts and
## events — so it replays, saves and loads like everything else.
##
## The store is handed its row here rather than read from `content/places.json`, so what
## is checked is the hail and not the content; the list itself is checked by the tests
## that build the game as it ships (O17).

const SAVE_UNDER_TEST: String = "user://save_under_test_hail.json"


func _rows() -> Array[Dictionary]:
	return [HailRules.row(&"bram", &"brindle_hail")]


func _build(rows: Array[Dictionary] = _rows()) -> Sim:
	var sim: Sim = Game.build()
	sim.add_store(&"hail", Hail.new(rows))
	return sim


func _replay_rows(rows: Array, p_seed: int, final_step: int) -> Sim:
	var stores: Dictionary = Game.fresh_stores()
	stores[&"hail"] = Hail.new(_rows())
	return Sim.replay(rows, p_seed, Game.build_systems(), final_step, stores)


func _hail(sim: Sim) -> Hail:
	return sim.store(&"hail") as Hail


func _world(sim: Sim) -> WorldState:
	return sim.store(&"world") as WorldState


func _zone() -> Vector2i:
	return _rows()[0]["at"] as Vector2i


## Walk toward the hail's ground by a path, holding directions as a keyboard does,
## until `done` says so or the budget runs out.
func _walk_until(sim: Sim, done: Callable, budget: int = 4000) -> bool:
	var world: WorldState = _world(sim)
	var route: Array[Vector2] = Navigation.waypoints(world.region(), world.player_tile(), _zone())
	var next: int = 0
	var held := Vector2i.ZERO
	for _i: int in budget:
		if bool(done.call()):
			return true
		while next < route.size() and world.player_pos.distance_to(route[next]) <= 1.0:
			next += 1
		var wanted := Vector2i.ZERO
		if next < route.size():
			var gap: Vector2 = route[next] - world.player_pos
			wanted = Vector2i(signi(int(round(gap.x))) if absf(gap.x) > 0.4 else 0,
				signi(int(round(gap.y))) if absf(gap.y) > 0.4 else 0)
		if wanted != held:
			held = wanted
			sim.submit(&"move_intent", {"x": held.x, "y": held.y})
		sim.advance(1)
	return bool(done.call())


func _coming(sim: Sim) -> Callable:
	return func() -> bool: return _hail(sim).phase == Hail.COMING


## Into his walk: two tiles past the '!', where the checks named for his coming are made
## (the review found three of them made inside the beat, before he had moved at all).
func _well_on_his_way(sim: Sim) -> void:
	_walk_until(sim, _coming(sim))
	sim.advance(WalkerRules.steps_per_tile() * 2)


func _spotted(sim: Sim) -> Callable:
	return func() -> bool: return _hail(sim).phase != Hail.IDLE


func _talking(sim: Sim) -> Callable:
	return func() -> bool: return _world(sim).talking_to == &"bram"


func _count(sim: Sim, type: StringName) -> int:
	return sim.events.of_type(type).size()


# ------------------------------------------------------------------ the hail ---

func test_walking_into_his_ground_is_one_hail_and_the_fact_is_written() -> void:
	var sim: Sim = _build()
	assert_eq(_hail(sim).phase, Hail.IDLE, "nobody is calling when you wake")
	assert_true(_walk_until(sim, _spotted(sim)), "walking toward the village, he sees you")
	assert_true(HailRules.in_sight(_rows()[0], _world(sim).player_tile()), "inside his ground")
	assert_true(sim.facts.has(&"hailed:bram"), "the hail is a fact")
	sim.advance(1)
	assert_eq(_count(sim, &"hailed"), 1, "raised once, as the world's answer to the step")
	assert_eq(_hail(sim).who, &"bram", "and it is Bram calling")


func test_the_player_is_held_while_he_comes() -> void:
	var sim: Sim = _build()
	_walk_until(sim, _spotted(sim))
	assert_true(_hail(sim).holds_player(), "held from the moment he sees you")
	var at: Vector2 = _world(sim).player_pos
	sim.submit(&"move_intent", {"x": -1, "y": 0})
	sim.advance(30)
	assert_eq(_hail(sim).phase, Hail.SPOTTED, "the '!' still up")
	assert_eq(_world(sim).player_pos, at, "a held key moves nobody")
	_well_on_his_way(sim)
	assert_eq(_hail(sim).phase, Hail.COMING, "he is walking over")
	assert_eq(_world(sim).player_pos, at, "and you have not moved")
	assert_true(_hail(sim).holds_player(), "still held while he walks")


func test_he_walks_over_within_the_tables_time_and_the_talk_opens_itself() -> void:
	var sim: Sim = _build()
	_walk_until(sim, _spotted(sim))
	var spotted: int = sim.step
	assert_true(_walk_until(sim, _talking(sim), HailRules.budget_steps() + 5),
		"he reaches you within %d steps" % HailRules.budget_steps())
	assert_true(sim.step - spotted <= HailRules.budget_steps(), "and the talk opens: %d steps" % (sim.step - spotted))
	for event: SimEvent in sim.events.of_type(&"talk"):
		assert_true(event.derived, "nobody pressed a key to start it")
	var bram: Npc = (sim.store(&"cast") as Cast).get_npc(&"bram")
	var walkers := sim.store(&"walkers") as Walkers
	assert_false(walkers.path.has(bram.id), "and not setting off home while he talks (the review)")
	var beside: Vector2i = walkers.where(bram)
	var here: Vector2i = _world(sim).player_tile()
	assert_true(maxi(absi(beside.x - here.x), absi(beside.y - here.y)) <= 1, "he is beside you: %s and %s" % [beside, here])


func test_his_first_words_are_the_hail_and_later_ones_are_not() -> void:
	var sim: Sim = _build()
	_walk_until(sim, _talking(sim))
	var first: String = _world(sim).current_line
	assert_true(first != "", "he says something")
	sim.submit(&"end_talk")
	sim.advance(2)
	assert_false(_hail(sim).holds_player(), "leaving frees you")
	sim.submit(&"talk", {"npc": "bram"})
	sim.advance(1)
	assert_ne(_world(sim).current_line, first,
		"a later conversation does not open with the hail again — the phase says so, not the fact")


func test_leaving_and_coming_back_is_no_second_hail() -> void:
	var sim: Sim = _build()
	_walk_until(sim, _talking(sim))
	sim.submit(&"end_talk")
	sim.advance(1)
	var walker := OpeningPlayer.new()
	assert_true(walker.walk_to(sim, where_the_game_starts(), 3000), "back to the graves: %s" % walker.report)
	assert_true(walker.walk_to(sim, _zone(), 3000), "and into his ground again: %s" % walker.report)
	sim.advance(120)
	assert_eq(_count(sim, &"hailed"), 1, "he called once")
	assert_eq(walker.left, [] as Array[StringName], "and nobody opened a conversation the second time")


func test_he_goes_home_when_the_talk_is_over() -> void:
	var sim: Sim = _build()
	_walk_until(sim, _talking(sim))
	sim.submit(&"end_talk")
	sim.advance(1)
	var bram: Npc = (sim.store(&"cast") as Cast).get_npc(&"bram")
	var walkers := sim.store(&"walkers") as Walkers
	assert_true(walkers.is_displaced(bram.id), "he is where he walked to")
	sim.advance(WalkerRules.linger_steps() + 60 * WalkerRules.steps_per_tile())
	assert_false(walkers.is_displaced(bram.id), "and then back at his post")
	assert_eq(_hail(sim).phase, Hail.IDLE, "and the hail is over")


# ----------------------------------------------------------- nobody else calls ---

func test_a_man_you_have_met_or_killed_does_not_call() -> void:
	for fact: StringName in [&"met:bram", &"killed:bram"]:
		var sim: Sim = _build()
		sim.facts.add_source(fact, &"witnessed")
		var walker := OpeningPlayer.new(OpeningPlayer.STOP)
		assert_true(walker.walk_to(sim, _zone(), 3000), "%s: you walk straight in: %s" % [fact, walker.report])
		sim.advance(60)
		assert_eq(_hail(sim).phase, Hail.IDLE, "%s: nobody calls" % fact)
		assert_false(sim.facts.has(&"hailed:bram"), "%s: and nothing is written" % fact)


func test_an_empty_list_holds_nobody_ever() -> void:
	# **The one-change check** (W4's lesson): the hail is on because a list has a row in
	# it, and off when it has none — emptying `hails` in places.json takes it out whole.
	var sim: Sim = _build([] as Array[Dictionary])
	var walker := OpeningPlayer.new(OpeningPlayer.STOP)
	assert_true(walker.walk_to(sim, Region.BRINDLE, 4000), "the graves to the village's heart: %s" % walker.report)
	assert_false(sim.facts.has(&"hailed:bram"), "nobody called")
	assert_eq(_count(sim, &"hailed"), 0, "and nothing was raised")


func test_the_game_as_it_ships_calls_you_over() -> void:
	# O17: the list is filled, and a new run walking up from the graves is called.
	assert_eq(Places.shared().hails().size(), 2, "his two discs in the content")
	var sim: Sim = Game.build()
	var walker := OpeningPlayer.new(OpeningPlayer.STOP)
	assert_false(walker.walk_to(sim, Region.BRINDLE, 4000), "the walk into the village is interrupted")
	assert_eq(_world(sim).talking_to, &"bram", "by Bram: %s" % walker.report)
	assert_true(sim.facts.has(&"hailed:bram"), "who called")


func test_never_in_the_middle_of_a_conversation() -> void:
	var sim: Sim = _build()
	var world: WorldState = _world(sim)
	sim.submit(&"talk", {"npc": String(OpeningRules.FAIRY)})
	sim.advance(1)
	assert_true(world.in_dialogue(), "she is talking")
	world.player_pos = Vector2(_zone()) + Vector2(0.5, 0.5)
	sim.advance(30)
	assert_eq(_hail(sim).phase, Hail.IDLE, "he waits for her to finish")
	sim.submit(&"end_talk")
	sim.advance(2)
	assert_ne(_hail(sim).phase, Hail.IDLE, "and calls when she has")


func test_never_in_the_middle_of_a_fight() -> void:
	var sim: Sim = _build()
	var world: WorldState = _world(sim)
	world.player_pos = Vector2(_zone()) + Vector2(0.5, 0.5)
	sim.submit(&"talk", {"npc": String(OpeningRules.FAIRY)})
	sim.advance(1)
	var duel := sim.store(&"duel") as Duel
	# A pack squaring up, as the wood does: the world's own event, raised here by hand.
	sim.derive(&"duel_began", {"opponents": ["wolf"], "by": "wolf", "asked_by": "the_wood"})
	sim.submit(&"end_talk")
	sim.advance(2)
	assert_true(duel.on(), "a fight is on")
	sim.advance(30)
	assert_eq(_hail(sim).phase, Hail.IDLE, "and nobody calls across it")


func test_while_he_comes_you_can_speak_to_nobody_else() -> void:
	var sim: Sim = _build()
	_walk_until(sim, _spotted(sim))
	sim.submit(&"talk", {"npc": "wren"})
	sim.advance(1)
	assert_ne(_world(sim).talking_to, &"wren", "the man calling you has the floor")
	_well_on_his_way(sim)
	assert_eq(_hail(sim).phase, Hail.COMING, "he is walking over")
	sim.submit(&"talk", {"npc": "wren"})
	sim.advance(1)
	assert_ne(_world(sim).talking_to, &"wren", "and keeps it while he walks")


func test_the_wolves_wait_while_you_are_held() -> void:
	var sim: Sim = _build()
	_well_on_his_way(sim)
	assert_eq(_hail(sim).phase, Hail.COMING, "he is walking over")
	var standing: Dictionary = (sim.store(&"wild") as Wild).standing(_world(sim).region())
	assert_false(standing.is_empty(), "the wood has a pack")
	# Put the held player beside one — a fixture, not a walk — which the wood would
	# answer on the next step.
	var pack: Vector2i = standing.keys()[0] as Vector2i
	_world(sim).player_pos = Vector2(pack + Vector2i(1, 0)) + Vector2(0.5, 0.5)
	sim.advance(10)
	assert_true(_hail(sim).holds_player(), "still held")
	assert_false((sim.store(&"duel") as Duel).on(), "and nothing sets on a player the hail is holding")


func test_a_spar_is_still_an_ordinary_talk_away() -> void:
	var sim: Sim = _build()
	_walk_until(sim, _talking(sim))
	sim.submit(&"end_talk")
	sim.advance(2)
	sim.submit(&"talk", {"npc": "bram"})
	sim.advance(1)
	var offered: Array[StringName] = []
	for option: DialogueOption in _world(sim).options:
		offered.append(option.intent)
	assert_true(offered.has(&"ask_bram_spar"), "the spar is on offer: %s" % str(offered))


# ------------------------------------------------------------ it is the log ---

func test_a_replay_taken_mid_approach_is_the_same_walk_and_the_same_talk() -> void:
	var sim: Sim = _build()
	_walk_until(sim, func() -> bool: return _hail(sim).phase == Hail.COMING)
	sim.advance(WalkerRules.steps_per_tile() * 2 + 3)
	assert_eq(_hail(sim).phase, Hail.COMING, "mid-approach")
	var again: Sim = _replay_rows(sim.events.external_rows(), sim.rng_seed, sim.step)
	assert_eq(_hail(again).fingerprint(), _hail(sim).fingerprint(), "the same hail")
	assert_eq((again.store(&"walkers") as Walkers).fingerprint(), (sim.store(&"walkers") as Walkers).fingerprint(),
		"the same man, the same tile, the same stride")
	assert_eq(_world(again).fingerprint(), _world(sim).fingerprint(), "the same world")
	var talk_at: Array[int] = []
	for run: Sim in [sim, again]:
		for _i: int in HailRules.budget_steps():
			if _world(run).talking_to == &"bram":
				break
			run.advance(1)
		assert_eq(_world(run).talking_to, &"bram", "the talk opens")
		talk_at.append(run.step)
	assert_eq(talk_at[0], talk_at[1], "and on the same step")


func test_a_save_taken_mid_approach_loads_into_the_same_walk() -> void:
	# Through the real file and the real loader, on the game as it ships (O17).
	var sim: Sim = Game.build()
	_walk_until(sim, func() -> bool: return _hail(sim).phase == Hail.COMING)
	sim.advance(7)
	assert_eq(_hail(sim).phase, Hail.COMING, "saved mid-approach")
	var was: String = SaveFile.path
	SaveFile.path = SAVE_UNDER_TEST
	assert_true(SaveFile.write(sim), "saved")
	var loaded: Sim = SaveFile.read()
	SaveFile.discard()
	SaveFile.path = was
	assert_not_null(loaded, "and loaded")
	if loaded == null:
		return
	assert_eq(_hail(loaded).fingerprint(), _hail(sim).fingerprint(), "the file carries the hail")
	assert_eq((loaded.store(&"walkers") as Walkers).fingerprint(), (sim.store(&"walkers") as Walkers).fingerprint(),
		"and where he had got to")


func test_three_hundred_steps_at_once_are_three_hundred_steps() -> void:
	var one: Sim = _build()
	var many: Sim = _build()
	for run: Sim in [one, many]:
		_walk_until(run, _spotted(run))
	assert_eq(one.step, many.step, "the same walk in")
	one.advance(300)
	for _i: int in 300:
		many.advance(1)
	assert_eq(_hail(one).fingerprint(), _hail(many).fingerprint(), "the same hail")
	assert_eq((one.store(&"walkers") as Walkers).fingerprint(), (many.store(&"walkers") as Walkers).fingerprint(),
		"the same walk")
	assert_eq(_world(one).fingerprint(), _world(many).fingerprint(), "the same world")
