extends TestCase

## **The combat tutorial as drills** (O8, 2026-09-29): Yannick's *Bannerlord* training
## grounds — one workshop a weapon, each with an instruction, an objective and a way on.
## This file is the sword; the bow (O9) and the spell (O10) join it.
##
## A drill is a spar with a lesson in it: its numbers are a row of `content/duel.json`,
## it is started by a line like every fight, it ends passed or failed, and the master
## mends you after either. Nothing here can kill you.

const SLOW: bool = false


func after_each() -> void:
	DuelRules.forget()


func _duel(sim: Sim) -> Duel:
	return sim.store(&"duel") as Duel


## A drill begun the way the game begins it: by saying the line to Bram.
func _ask(sim: Sim, intent: String) -> void:
	var world := sim.store(&"world") as WorldState
	world.player_pos = (sim.store(&"cast") as Cast).get_npc(&"bram").centre()
	sim.submit(&"talk", {"npc": "bram"})
	sim.advance(2)
	sim.submit(&"choose_intent", {"intent": intent})
	sim.advance(3)


func _play(sim: Sim, policy: StringName, steps: int) -> void:
	var hands := DuelPlayer.new(policy)
	var duel: Duel = _duel(sim)
	for _step: int in steps:
		if not duel.on():
			return
		hands.play(sim, duel)
		sim.advance(1)


func _intents(sim: Sim) -> Array[StringName]:
	var world := sim.store(&"world") as WorldState
	var out: Array[StringName] = []
	for option: DialogueOption in world.options:
		out.append(option.intent)
	return out


func test_the_sword_drill_is_a_row_of_the_table() -> void:
	var drill: Dictionary = DuelRules.drill(&"sword")
	assert_false(drill.is_empty(), "content/duel.json describes the sword drill")
	assert_eq(StringName(String(drill.get("master", ""))), &"bram", "Bram teaches it")
	assert_true(DuelRules.drill_stand_off(&"sword") > DuelRules.tiles_per_turn() + DuelRules.reach_tiles(),
		"he stands off further than one turn can close and strike")


func test_saying_the_line_starts_the_sword_drill() -> void:
	var sim: Sim = Game.build()
	_ask(sim, "drill_sword")
	var duel: Duel = _duel(sim)
	assert_true(duel.on(), "the drill is a fight")
	assert_eq(duel.drill, &"sword", "the sword drill")
	assert_true(duel.spar, "and a spar: nobody dies in it")


func test_the_first_turn_needs_a_move() -> void:
	# W3's step two, kept: Bram steps off first, so the first thing the drill teaches
	# is the thing the grid is for.
	var sim: Sim = Game.build()
	_ask(sim, "drill_sword")
	var duel: Duel = _duel(sim)
	for _step: int in 2000:
		if duel.waiting_on_player():
			break
		sim.advance(1)
	assert_true(duel.waiting_on_player(), "your turn came")
	var mine: DuelFighter = duel.me()
	var him: DuelFighter = duel.foe()
	assert_true(DuelRules.apart(mine.at, him.at) > DuelRules.tiles_per_turn() + DuelRules.reach_tiles(),
		"and he stands out of one turn's reach: %d tiles" % DuelRules.apart(mine.at, him.at))


func test_pressing_passes_it_and_the_world_remembers() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	_ask(sim, "drill_sword")
	var duel: Duel = _duel(sim)
	_play(sim, DuelPlayer.PRESS, 6000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_false(duel.on(), "it is over")
	assert_true(sim.facts.has(&"drilled:sword"), "passed")
	assert_eq(world.player_hp, WorldState.MAX_HP, "and he mends you")
	assert_false(sim.facts.has(&"killed:bram"), "nobody died")
	assert_true(world.in_dialogue(), "and he speaks to you again")
	assert_eq(world.talking_to, &"bram", "he does")


func test_his_blows_in_a_drill_cost_one() -> void:
	var sim: Sim = Game.build()
	_ask(sim, "drill_sword")
	_play(sim, DuelPlayer.STAND, 6000)
	var bitten: bool = false
	for row: Variant in sim.events.of_type(&"blow_landed"):
		var blow: SimEvent = row as SimEvent
		if String(blow.data.get("by", "")) == "bram":
			bitten = true
			assert_eq(int(blow.data.get("damage", 0)), DuelRules.drill_damage(&"sword"),
				"a drill's blow costs the drill's figure")
	assert_true(bitten, "he did hit you")


func test_standing_still_fails_it_and_harms_nobody() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	_ask(sim, "drill_sword")
	var duel: Duel = _duel(sim)
	_play(sim, DuelPlayer.STAND, 20000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_false(duel.on(), "the drill ends at its cap")
	assert_eq(duel.outcome, &"failed", "failed")
	assert_false(sim.facts.has(&"drilled:sword"), "and nothing is written")
	assert_eq(world.deaths, 0, "nobody died")
	assert_eq(world.player_hp, WorldState.MAX_HP, "and he mends you all the same")


func test_a_failed_drill_is_offered_again() -> void:
	var sim: Sim = Game.build()
	_ask(sim, "drill_sword")
	_play(sim, DuelPlayer.STAND, 20000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_true(_intents(sim).has(&"drill_sword"), "try again")


func test_the_drill_replays_from_the_log() -> void:
	# From where the game starts, so nothing about it is set outside the log.
	var sim: Sim = Game.build()
	sim.submit(&"duel_began", {"opponent": "bram", "by": "bram", "spar": true, "drill": "sword"})
	sim.advance(1)
	_play(sim, DuelPlayer.PRESS, 6000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_true(sim.facts.has(&"drilled:sword"), "passed")
	var replayed: Sim = Game.replay(sim)
	assert_true(replayed.facts.has(&"drilled:sword"), "and a replay passes it too")
	assert_eq((replayed.store(&"world") as WorldState).fingerprint(),
		(sim.store(&"world") as WorldState).fingerprint(), "to the same world")


func test_the_old_spar_line_still_spars() -> void:
	# Invariant 5: the tutorial starts more than one way.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	world.player_pos = (sim.store(&"cast") as Cast).get_npc(&"bram").centre()
	sim.submit(&"talk", {"npc": "bram"})
	sim.advance(2)
	assert_true(_intents(sim).has(&"ask_bram_spar"), "the spar is still offered")
	assert_true(_intents(sim).has(&"drill_sword"), "beside the lesson")


# ------------------------------------------------------------------ the bow (O9) ---

func test_the_bow_drill_comes_after_the_sword() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	world.player_pos = (sim.store(&"cast") as Cast).get_npc(&"bram").centre()
	sim.submit(&"talk", {"npc": "bram"})
	sim.advance(2)
	assert_false(_intents(sim).has(&"drill_bow"), "not before the sword")
	sim.submit(&"end_talk")
	sim.advance(2)
	sim.facts.add_source(&"drilled:sword", &"test")
	sim.submit(&"talk", {"npc": "bram"})
	sim.advance(2)
	assert_true(_intents(sim).has(&"drill_bow"), "offered once the sword is passed")


func _bow_drill() -> Sim:
	var sim: Sim = Game.build()
	sim.submit(&"duel_began", {"opponent": "wren", "by": "wren", "spar": true, "drill": "bow"})
	sim.advance(1)
	return sim


func test_dodging_passes_the_bow_drill() -> void:
	var sim: Sim = _bow_drill()
	var world := sim.store(&"world") as WorldState
	_play(sim, DuelPlayer.DODGE, 20000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_true(sim.facts.has(&"drilled:bow"), "three arrows dodged is the lesson learnt")
	assert_eq(world.player_hp, WorldState.MAX_HP, "and he mends you")


func test_standing_in_the_arrows_fails_it_and_harms_nobody() -> void:
	var sim: Sim = _bow_drill()
	var world := sim.store(&"world") as WorldState
	var duel: Duel = _duel(sim)
	_play(sim, DuelPlayer.STAND, 20000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_eq(duel.outcome, &"failed", "not yet")
	assert_eq(world.deaths, 0, "nobody died")
	assert_false(sim.facts.has(&"drilled:bow"), "and nothing is written")


func test_beating_her_without_dodging_is_not_the_lesson() -> void:
	# The goal is the dodge: running in and hitting her until she yields is a fight won
	# and a lesson missed.
	var sim: Sim = _bow_drill()
	var duel: Duel = _duel(sim)
	_play(sim, DuelPlayer.PRESS, 20000)
	sim.advance(DuelRules.beat_steps() + 5)
	if duel.tally < DuelRules.drill_count(&"bow"):
		assert_eq(duel.outcome, &"failed", "she yielded before you dodged three")
		assert_false(sim.facts.has(&"drilled:bow"), "so it is not passed")
	else:
		assert_true(sim.facts.has(&"drilled:bow"), "or you dodged three on the way in")


func test_only_bram_reads_what_you_have_drilled() -> void:
	# A drill is a lesson, not a gate: nothing but the master's own next lesson may ask
	# whether you passed the last one (invariant 4).
	for language: String in ["en", "fr"]:
		var sheet: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://content/cast.%s.json" % language)) as Dictionary
		var npcs: Dictionary = sheet.get("npcs", sheet) as Dictionary
		for who: String in npcs.keys():
			if who == "bram":
				continue
			var person: Dictionary = npcs[who] as Dictionary
			for option: Variant in person.get("options", []) as Array:
				var row: Dictionary = option as Dictionary
				for field: String in ["requires", "hides_after"]:
					assert_false(String(row.get(field, "")).begins_with("drilled:"),
						"%s's %s reads a drill (%s)" % [who, row.get("intent", ""), language])
