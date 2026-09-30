extends TestCase

## **Attack the gatekeeper, and the guards keep coming** (T9, 2026-09-29).
##
## Yannick's answer to QUEST_CINDERWORKS §9's third question — *what does the guard on the
## gate do if the player simply attacks him* — was: other guards come and must be fought,
## and the fight cannot be won. A guard joins from the yard every round for as long as it
## lasts. Each one can be killed, so nobody is made invulnerable (SPECS §1); it ends when
## the player falls or leaves. And killing the gatekeeper opens nothing: the gate is a
## fact (`WardRules`), never a man.

func after_each() -> void:
	DuelRules.forget()


func _duel(sim: Sim) -> Duel:
	return sim.store(&"duel") as Duel


func _gatekeeper(sim: Sim) -> Npc:
	for npc: Npc in (sim.store(&"cast") as Cast).npcs.values():
		if npc.kind == &"gatekeeper":
			return npc
	return null


## Standing in front of him and saying the line, as the game does.
func _attack(sim: Sim) -> void:
	var world := sim.store(&"world") as WorldState
	past_the_hail(sim)
	var him: Npc = _gatekeeper(sim)
	# From the street in front of the gate — the tile beside him outside the yard — and
	# not from inside its wall, which is where the first draft of this suite stood (T10's
	# review).
	var outside: Vector2i = world.region().open_near(him.tile + Vector2i(-1, 0))
	assert_true(world.region().is_passable(outside), "the player stands on open ground: %s" % outside)
	world.player_pos = Vector2(outside) + Vector2(0.5, 0.5)
	sim.submit(&"talk", {"npc": String(him.id)})
	sim.advance(2)
	sim.submit(&"choose_intent", {"intent": "attack_gatekeeper"})
	sim.advance(3)


func _play(sim: Sim, policy: StringName, steps: int) -> void:
	var hands := DuelPlayer.new(policy)
	var duel: Duel = _duel(sim)
	for _step: int in steps:
		if not duel.on():
			return
		hands.play(sim, duel)
		sim.advance(1)


func test_the_gatekeeper_can_be_attacked() -> void:
	var sim: Sim = Game.build()
	_attack(sim)
	var duel: Duel = _duel(sim)
	assert_true(duel.on(), "saying it is a fight")
	assert_not_null(duel.get_fighter(_gatekeeper(sim).id), "against him")
	assert_false(duel.spar, "and a real one")
	assert_eq(duel.reinforced_by, &"works_guard", "which the yard answers")


func test_a_guard_joins_every_round_and_never_too_many_at_once() -> void:
	var sim: Sim = Game.build()
	(sim.store(&"world") as WorldState).unkillable = true
	_attack(sim)
	var duel: Duel = _duel(sim)
	var most: int = int(DuelRules.reinforcement(&"gatekeeper").get("most_at_once", 0))
	assert_true(most > 0, "the yard sends a limited number at once")
	var joined_by_round: Dictionary = {}
	var hands := DuelPlayer.new(DuelPlayer.STAND)
	for _step: int in 6000:
		if not duel.on():
			break
		hands.play(sim, duel)
		sim.advance(1)
		joined_by_round[duel.round_number] = sim.events.of_type(&"duel_joined").size()
		assert_true(duel.foes_of(DuelRules.PLAYER).size() <= most + 1,
			"no more than %d guards beside the gatekeeper" % most)
	assert_true(sim.events.of_type(&"duel_joined").size() >= 2, "guards came: %d" % sim.events.of_type(&"duel_joined").size())
	var first: SimEvent = sim.events.of_type(&"duel_joined")[0] as SimEvent
	assert_true(String(first.data.get("who", "")).begins_with("works_guard"), "a works guard: %s" % first.data)


func test_each_one_can_be_killed_and_it_is_never_won() -> void:
	# Unkillable (G), pressing for a long time: guards go down, and the fight is never won.
	var sim: Sim = Game.build()
	(sim.store(&"world") as WorldState).unkillable = true
	_attack(sim)
	_play(sim, DuelPlayer.PRESS, 30000)
	var downs: int = 0
	for row: SimEvent in sim.events.of_type(&"duel_down"):
		if String(row.data.get("who", "")) != "player":
			downs += 1
	assert_true(downs >= 3, "they fall: %d down" % downs)
	for row: SimEvent in sim.events.of_type(&"duel_decided"):
		assert_ne(String(row.data.get("how", "")), "won", "and the fight is never won")


func test_falling_ends_it() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	_attack(sim)
	_play(sim, DuelPlayer.STAND, 40000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_false(_duel(sim).on(), "it ends")
	assert_eq(_duel(sim).outcome, &"lost", "with you down")
	assert_eq(world.deaths, 1, "for real")


func test_leaving_ends_it() -> void:
	var sim: Sim = Game.build()
	_attack(sim)
	_play(sim, DuelPlayer.LEAVE, 40000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_false(_duel(sim).on(), "it ends")
	assert_ne(_duel(sim).outcome, &"won", "and not won")


func test_the_gate_is_a_fact_not_a_man() -> void:
	var sim: Sim = Game.build()
	(sim.store(&"world") as WorldState).unkillable = true
	_attack(sim)
	_play(sim, DuelPlayer.PRESS, 30000)
	assert_false(WardRules.opens(&"cinderworks_gate", sim.facts), "whoever fell, the gate is still shut")


func test_the_fight_at_the_gate_replays_from_the_log() -> void:
	# From where the game starts: attacking him from beside him needs a walk, so the
	# fight is begun as his line begins it, from the log.
	var sim: Sim = Game.build()
	sim.submit(&"unkillable", {"on": true})
	sim.advance(1)
	var him: Npc = _gatekeeper(sim)
	sim.submit(&"duel_began", {"opponent": String(him.id), "asked_by": "attack_gatekeeper"})
	sim.advance(1)
	_play(sim, DuelPlayer.PRESS, 3000)
	assert_true(sim.events.of_type(&"duel_joined").size() > 0, "guards joined")
	var replayed: Sim = Game.replay(sim)
	assert_eq(_duel(replayed).fingerprint(), _duel(sim).fingerprint(), "the same fight, guard for guard")


# ------------------------------------------------------- the review of T9 (T10) ---

func test_whoever_falls_at_the_gate_another_man_stands_in_it() -> void:
	# The review of T9: killing the gatekeeper stopped the window drawing him, and the ward
	# went on refusing his tile — a wall nobody could see. The works keeps its post manned.
	var sim: Sim = Game.build()
	(sim.store(&"world") as WorldState).unkillable = true
	_attack(sim)
	var him: Npc = _gatekeeper(sim)
	var duel: Duel = _duel(sim)
	var hands := DuelPlayer.new(DuelPlayer.PRESS)
	for _step: int in 30000:
		if not duel.on() or sim.facts.has(StringName("killed:%s" % him.id)):
			break
		hands.play(sim, duel)
		sim.advance(1)
	assert_true(sim.facts.has(StringName("killed:%s" % him.id)), "the gatekeeper was killed")
	assert_false(OpeningRules.is_gone(him.id, sim.facts), "and another man stands at the gate")
	assert_false(WardRules.opens(&"cinderworks_gate", sim.facts), "which is still shut")


func test_a_fight_does_not_walk_you_through_a_shut_gate() -> void:
	# Latent, found by the review of T9: the fight's own moves ignored the ward, so a turn
	# could end in the gateway, and a fight left from there left you inside the yard.
	var region: Region = Region.build_overworld()
	if region.wards.is_empty():
		assert_false(Places.baked(), "only the 2D map has no yard, and so no gate to keep")
		return
	var gate: Vector2i = region.wards.keys()[0] as Vector2i
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	past_the_hail(sim)
	var beside: Vector2i = region.open_near(gate + Vector2i(-1, 0))
	world.player_pos = Vector2(beside) + Vector2(0.5, 0.5)
	sim.submit(&"duel_began", {"opponents": ["wolf"], "by": "player"})
	sim.advance(1)
	var duel: Duel = _duel(sim)
	# The wolf is set down beside you, which here is the gateway itself: stand it off to
	# the west, so the gate is free and only the ward can refuse it.
	duel.foe().at = region.open_near(beside + Vector2i(-3, 0))
	assert_ne(duel.foe().at, gate, "the gateway is free")
	assert_true(duel.waiting_on_player(), "your turn, beside the gate")
	assert_false(WardRules.shut_tiles(region, sim.facts).is_empty(), "the gate is shut to you")
	sim.submit(&"duel_turn", {"who": "player", "to_x": gate.x, "to_y": gate.y, "action": "wait", "target": ""})
	sim.advance(200)
	assert_ne(duel.me().at, gate, "and a turn aimed into it ends outside")

