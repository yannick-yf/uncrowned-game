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
	world.player_pos = him.centre() + Vector2(0.0, 1.0)
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
