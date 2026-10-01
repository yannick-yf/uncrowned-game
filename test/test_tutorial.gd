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


# ------------------------------------------------- the bow (O9), redone in T5 ---

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


## The bow drill as T5 has it (2026-09-29): Bram comes at you, you hold a bow of your
## own, and three arrows that land on him are the lesson — begun from where the game
## starts, so it replays from the log.
func _bow_drill() -> Sim:
	var sim: Sim = Game.build()
	sim.facts.add_source(DuelRules.THE_BOW, &"wren")
	sim.submit(&"duel_began", {"opponent": "bram", "by": "bram", "spar": true, "drill": "bow"})
	sim.advance(1)
	return sim


func test_asking_for_the_bow_puts_one_in_your_hands() -> void:
	var sim: Sim = Game.build()
	sim.facts.add_source(&"drilled:sword", &"test")
	assert_false(sim.facts.has(DuelRules.THE_BOW), "you have no bow of your own")
	_ask(sim, "drill_bow")
	var duel: Duel = _duel(sim)
	assert_true(sim.facts.has(DuelRules.THE_BOW), "and the lesson begins with one")
	assert_eq(duel.drill, &"bow", "the bow drill")
	assert_not_null(duel.get_fighter(&"wren"), "with Wren in front of you (Yannick, 2026-10-01)")
	assert_null(duel.get_fighter(&"bram"), "and not Bram, who came to contact and followed")


func test_in_the_bow_lesson_wren_keeps_her_distance_and_shoots_too() -> void:
	# Yannick, 2026-10-01: Bram came to contact after the first arrow and followed every
	# step. Wren is an archer: she never comes next to you, and a newcomer who only stands
	# and shoots passes in a few turns.
	var sim: Sim = Game.build()
	sim.facts.add_source(&"drilled:sword", &"test")
	_ask(sim, "drill_bow")
	var duel: Duel = _duel(sim)
	var closest: int = 99
	var her_arrows: int = 0
	var turns: int = 0
	for _step: int in 20000:
		if not duel.on():
			break
		var me: DuelFighter = duel.me()
		var her: DuelFighter = duel.get_fighter(&"wren")
		if me != null and her != null:
			closest = mini(closest, DuelRules.apart(me.at, her.at))
			if duel.waiting_on_player():
				turns += 1
				var shoot: bool = DuelRules.reaches(DuelRules.BOW, me.at, her.at)
				sim.submit(&"duel_turn", {"who": "player", "to_x": me.at.x, "to_y": me.at.y,
					"action": "strike" if shoot else "wait", "target": "wren" if shoot else "", "weapon": "bow"})
		sim.advance(1)
	for event: SimEvent in sim.events.all():
		if event.type == &"blow_landed" and String(event.data.get("target", "")) == String(DuelRules.PLAYER) \
				and String(event.data.get("move", "")) == "arrow":
			her_arrows += 1
	sim.advance(DuelRules.beat_steps() + 5)
	assert_true(closest >= DuelRules.bow_min_tiles(), "she never comes next to you: %d tiles at the closest" % closest)
	assert_true(sim.facts.has(&"drilled:bow"), "standing and shooting passes it")
	assert_true(turns <= 5, "in a few turns: %d" % turns)
	assert_true(her_arrows >= 1, "and she shoots too: %d arrows" % her_arrows)


func test_shooting_passes_the_bow_drill() -> void:
	var sim: Sim = _bow_drill()
	var world := sim.store(&"world") as WorldState
	_play(sim, DuelPlayer.BOW, 20000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_true(sim.facts.has(&"drilled:bow"), "three arrows that land is the lesson learnt")
	assert_eq(world.player_hp, WorldState.MAX_HP, "and he mends you")


func test_the_bow_you_are_given_and_the_arrows_you_shoot_replay_from_the_log() -> void:
	# The whole way, from the line: the sword passed, the bow asked for and handed over,
	# three arrows. Nothing is written outside the log, so a replay shoots them too.
	# From where the game starts, and nothing set outside the log: the sword begun as its
	# line begins it, and Bram walking over to speak when it is passed.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	sim.submit(&"duel_began", {"opponent": "bram", "by": "bram", "spar": true, "drill": "sword"})
	sim.advance(1)
	_play(sim, DuelPlayer.PRESS, 6000)
	for _step: int in 4000:
		if world.talking_to == &"bram":
			break
		sim.advance(1)
	assert_eq(world.talking_to, &"bram", "he speaks when the sword is passed")
	assert_true(_intents(sim).has(&"drill_bow"), "and offers the bow")
	sim.submit(&"choose_intent", {"intent": "drill_bow"})
	sim.advance(3)
	_play(sim, DuelPlayer.BOW, 20000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_true(sim.facts.has(&"drilled:bow"), "passed")
	var replayed: Sim = Game.replay(sim)
	assert_true(replayed.facts.has(DuelRules.THE_BOW), "a replay is handed the bow")
	assert_true(replayed.facts.has(&"drilled:bow"), "and passes it too")
	assert_eq((replayed.store(&"world") as WorldState).fingerprint(),
		(sim.store(&"world") as WorldState).fingerprint(), "to the same world")


func test_the_sword_is_not_the_bow_lesson() -> void:
	# The goal is the arrows. Since the review of O21 nobody falls in a drill, so pressing
	# in with the sword cannot end it: it is decided by the arrows, or by the rounds.
	var sim: Sim = _bow_drill()
	var world := sim.store(&"world") as WorldState
	var duel: Duel = _duel(sim)
	_play(sim, DuelPlayer.PRESS, 20000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_eq(sim.events.of_type(&"duel_yielded").size() + sim.events.of_type(&"duel_down").size(), 0,
		"he never goes down, however hard you press")
	assert_eq(duel.outcome, &"failed", "not yet")
	assert_false(sim.facts.has(&"drilled:bow"), "and nothing is written")
	assert_eq(world.deaths, 0, "nobody died")


# --------------------------------------------------------------- the spell (O10) ---

func test_her_last_word_gives_the_gift() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	sim.submit(&"talk", {"npc": "fairy"})
	sim.advance(2)
	for _line: int in 9:
		if world.options.is_empty():
			break
		sim.submit(&"choose_intent", {"intent": String(world.options[0].intent)})
		sim.advance(2)
	assert_true(sim.facts.has(OpeningRules.FACT_LAST_WORD), "she asked")
	assert_true(sim.facts.has(OpeningRules.GIFT), "and gave you a sliver of what raised you")


func test_the_magic_drill_needs_the_bow_and_the_gift() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	world.player_pos = (sim.store(&"cast") as Cast).get_npc(&"bram").centre()
	sim.facts.add_source(&"drilled:sword", &"test")
	sim.facts.add_source(&"drilled:bow", &"test")
	sim.submit(&"talk", {"npc": "bram"})
	sim.advance(2)
	assert_false(_intents(sim).has(&"drill_magic"), "no gift, no lesson in it")
	sim.submit(&"end_talk")
	sim.advance(2)
	sim.facts.add_source(OpeningRules.GIFT, &"fairy")
	sim.submit(&"talk", {"npc": "bram"})
	sim.advance(2)
	assert_true(_intents(sim).has(&"drill_magic"), "with it, and after the bow, it is offered")


func test_casting_passes_the_magic_drill() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	sim.facts.add_source(OpeningRules.GIFT, &"fairy")
	sim.submit(&"duel_began", {"opponent": "wren", "by": "wren", "spar": true, "drill": "magic"})
	sim.advance(1)
	_play(sim, DuelPlayer.CAST, 20000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_true(sim.facts.has(&"drilled:magic"), "two spells that land is the lesson")
	assert_eq(world.player_hp, WorldState.MAX_HP, "and he mends you")


# ------------------------------------------------ found by the review of O7-O9 ---

func test_stepping_back_on_your_first_turn_does_not_end_the_drill() -> void:
	# His opening walk leaves you six apart, which is "out of reach"; counting that as a
	# round away ended the drill as walked out of when you stepped back once.
	var sim: Sim = Game.build()
	sim.submit(&"duel_began", {"opponent": "bram", "by": "bram", "spar": true, "drill": "sword"})
	sim.advance(1)
	var duel: Duel = _duel(sim)
	for _step: int in 2000:
		if duel.waiting_on_player():
			break
		sim.advance(1)
	var mine: DuelFighter = duel.me()
	var away: Vector2i = mine.at + (mine.at - duel.foe().at).sign() * 2
	sim.submit(&"duel_turn", {"who": "player", "to_x": away.x, "to_y": away.y, "action": "wait", "target": ""})
	sim.advance(2)
	_play(sim, DuelPlayer.PRESS, 6000)
	assert_ne(duel.outcome, &"left", "one step back is not leaving the lesson")


func test_the_master_speaks_only_to_somebody_beside_him() -> void:
	# The magic drill is Wren's fight; Bram watches from his post, and may be far off. He
	# does not open a conversation from across the village as the lesson ends.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	sim.facts.add_source(OpeningRules.GIFT, &"fairy")
	sim.submit(&"duel_began", {"opponent": "wren", "by": "wren", "spar": true, "drill": "magic"})
	sim.advance(1)
	_play(sim, DuelPlayer.CAST, 20000)
	sim.advance(DuelRules.beat_steps() + 5)
	var bram: Npc = (sim.store(&"cast") as Cast).get_npc(&"bram")
	var walkers := sim.store(&"walkers") as Walkers
	var apart: float = world.player_pos.distance_to(Walkers.centre_of(bram, walkers))
	if apart > DrillSystem.SPEAKS_WITHIN:
		assert_false(world.talking_to == &"bram", "he is %.0f tiles off and says nothing" % apart)
	else:
		assert_eq(world.talking_to, &"bram", "beside him, he speaks")


func test_the_arrow_that_decides_it_is_the_last() -> void:
	# The drill is passed on the step the third arrow lands, and nothing is thrown after it.
	var sim: Sim = _bow_drill()
	_play(sim, DuelPlayer.BOW, 20000)
	var mine: Array[SimEvent] = []
	for row: SimEvent in sim.events.of_type(&"blow_landed"):
		if String(row.data.get("by", "")) == "player" and String(row.data.get("move", "")) == "arrow":
			mine.append(row)
	assert_true(mine.size() >= DuelRules.drill_count(&"bow"), "the drill was passed")
	if mine.size() >= DuelRules.drill_count(&"bow"):
		var deciding: SimEvent = mine[DuelRules.drill_count(&"bow") - 1]
		for row: SimEvent in sim.events.of_type(&"blow_landed"):
			assert_true(row.step <= deciding.step,
				"no blow after the arrow that passed it (at %d, passed at %d)" % [row.step, deciding.step])


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


# ------------------------------------------------------- the review of O21 ---

func test_a_passed_lesson_is_not_a_man_beaten() -> void:
	# The sword's third blow took Bram's fifteen to nothing; he yielded, and the lesson
	# counted as beating him — so he offered a fight to the death straight after it.
	var sim: Sim = Game.build()
	_ask(sim, "drill_sword")
	_play(sim, DuelPlayer.PRESS, 6000)
	sim.advance(5)
	assert_true(sim.facts.has(&"drilled:sword"), "the lesson is passed")
	assert_false(sim.facts.has(&"bested:bram"), "and nobody was beaten")
	assert_eq(sim.events.of_type(&"duel_yielded").size(), 0, "nobody yielded")
	var world := sim.store(&"world") as WorldState
	if not world.in_dialogue():
		sim.submit(&"talk", {"npc": "bram"})
		sim.advance(2)
	assert_false(_intents(sim).has(&"fight_bram_for_real"), "so no fight to the death is offered after a lesson")


func test_a_spell_is_not_the_sword_lesson() -> void:
	# With the gift in hand, the sword lesson could be passed from three tiles away.
	var sim: Sim = Game.build()
	sim.facts.add_source(OpeningRules.GIFT, &"fairy")
	_ask(sim, "drill_sword")
	var duel: Duel = _duel(sim)
	var hands := DuelPlayer.new(DuelPlayer.CAST)
	var spells: int = 0
	for _step: int in 20000:
		if not duel.on():
			break
		hands.play(sim, duel)
		sim.advance(1)
		var struck: int = 0
		spells = 0
		for blow: SimEvent in sim.events.of_type(&"blow_landed"):
			if String(blow.data.get("by", "")) != String(DuelRules.PLAYER):
				continue
			if String(blow.data.get("move", "")) == String(DuelRules.STRIKE):
				struck += 1
			else:
				spells += 1
		if duel.on():
			assert_eq(duel.tally, struck, "the lesson counts sword blows only")
	assert_true(spells > 0, "and spells were cast in it, so the check meant something")


func test_in_wrens_lessons_bram_stands_and_nobody_walks_onto_him() -> void:
	var sim: Sim = Game.build()
	sim.facts.add_source(OpeningRules.GIFT, &"fairy")
	sim.submit(&"duel_began", {"opponent": "wren", "by": "wren", "spar": true, "drill": "magic"})
	sim.advance(1)
	var duel: Duel = _duel(sim)
	var walkers := sim.store(&"walkers") as Walkers
	var bram: Npc = (sim.store(&"cast") as Cast).get_npc(&"bram")
	var stands: Vector2i = walkers.where(bram)
	assert_eq(duel.master_at, stands, "the lesson knows where he watches from")
	var hands := DuelPlayer.new(DuelPlayer.CAST)
	for _step: int in 20000:
		if not duel.on():
			break
		assert_eq(walkers.where(bram), stands, "he does not walk off mid-lesson")
		var me: DuelFighter = duel.me()
		if me != null:
			assert_ne(me.at, stands, "and nobody stands on him")
		hands.play(sim, duel)
		sim.advance(1)


func _first_words(sim: Sim) -> String:
	return (sim.store(&"world") as WorldState).current_line


func test_after_each_lesson_he_speaks_to_it() -> void:
	# The review of O21: after every lesson he opened with his everyday greeting.
	var cast: Cast = Cast.shared()
	var bram: Npc = cast.get_npc(&"bram")
	var sim: Sim = Game.build()
	sim.facts.add_source(OpeningRules.GIFT, &"fairy")
	_ask(sim, "drill_sword")
	_play(sim, DuelPlayer.PRESS, 6000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_eq(_first_words(sim), bram.alt_greeting_for({&"just_passed_sword": true}), "the way on to the bow")
	sim.submit(&"choose_intent", {"intent": "drill_bow"})
	sim.advance(3)
	_play(sim, DuelPlayer.BOW, 20000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_eq(_first_words(sim), bram.alt_greeting_for({&"just_passed_bow": true}), "the way on to the gift")
	sim.submit(&"choose_intent", {"intent": "drill_magic"})
	sim.advance(3)
	_play(sim, DuelPlayer.CAST, 20000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_true(sim.facts.has(&"drilled:magic"), "the last lesson passed")
	assert_eq((sim.store(&"world") as WorldState).talking_to, &"bram", "and he speaks after it")
	assert_eq(_first_words(sim), bram.alt_greeting_for({&"just_passed_magic": true}), "his farewell, north")
	assert_true(_intents(sim).has(&"ask_bram_way_on"), "and the way on can be asked again")


func test_a_failed_lesson_is_a_not_yet() -> void:
	var sim: Sim = Game.build()
	_ask(sim, "drill_sword")
	_play(sim, DuelPlayer.STAND, 20000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_eq(_first_words(sim), Cast.shared().get_npc(&"bram").alt_greeting_for({&"just_failed_a_lesson": true}),
		"not yet")


func test_without_the_gift_the_bow_is_the_last_lesson() -> void:
	var sim: Sim = Game.build()
	sim.facts.add_source(&"drilled:sword", &"test")
	_ask(sim, "drill_bow")
	_play(sim, DuelPlayer.BOW, 20000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_eq(_first_words(sim), Cast.shared().get_npc(&"bram").alt_greeting_for({&"just_passed_bow_without_gift": true}),
		"a farewell, not a lesson he cannot give")


func test_at_the_hail_the_post_waits() -> void:
	var bram: Npc = Cast.shared().get_npc(&"bram")
	var at_the_hail: Array[DialogueOption] = DialogueRules.available(bram, FactBase.new(), {&"called_out": true})
	var later: Array[DialogueOption] = DialogueRules.available(bram, FactBase.new(), {})
	var intents: Callable = func(options: Array[DialogueOption]) -> Array[StringName]:
		var out: Array[StringName] = []
		for option: DialogueOption in options:
			out.append(option.intent)
		return out
	assert_false((intents.call(at_the_hail) as Array).has(&"ask_bram_post"), "nobody has spoken of a post at the hail")
	assert_true((intents.call(later) as Array).has(&"ask_bram_post"), "after his greeting, it can be asked")


func test_a_lesson_that_ends_far_from_him_brings_him_over() -> void:
	# The review of O21: the magic lesson ended nine tiles from him, in silence, and the
	# farewell north was never said. Now he walks over — the hail's walk, without its '!'.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	sim.facts.add_source(OpeningRules.GIFT, &"fairy")
	sim.facts.add_source(&"drilled:sword", &"test")
	sim.facts.add_source(&"drilled:bow", &"test")
	var bram: Npc = (sim.store(&"cast") as Cast).get_npc(&"bram")
	world.player_pos = bram.centre() + Vector2(-7.0, -7.0)
	sim.submit(&"duel_began", {"opponent": "wren", "by": "wren", "spar": true, "drill": "magic"})
	sim.advance(1)
	_play(sim, DuelPlayer.CAST, 20000)
	var hail := sim.store(&"hail") as Hail
	var came: bool = false
	for _step: int in 2000:
		if world.talking_to == &"bram":
			break
		if hail.phase == Hail.COMING:
			came = true
			assert_true(hail.holds_player(), "you wait for him")
			assert_false(hail.called_out(&"bram"), "and he is not calling you out")
		sim.advance(1)
	assert_true(sim.facts.has(&"drilled:magic"), "the lesson passed")
	assert_eq(sim.events.of_type(&"summon").size(), 1, "far from him, he was sent for")
	assert_true(came, "and he walked over")
	assert_eq(world.talking_to, &"bram", "and speaks")
	assert_eq(world.current_line, bram.alt_greeting_for({&"just_passed_magic": true}), "his farewell, north")


func test_what_he_says_as_a_lesson_begins_is_kept_for_the_first_round() -> void:
	# The review of O21: the conversation closes on the step the fight begins, so his
	# answer to "A lesson. The sword." — the lesson's instruction — was never on screen.
	var sim: Sim = Game.build()
	_ask(sim, "drill_sword")
	var duel: Duel = _duel(sim)
	var option: DialogueOption = DialogueRules.find(Cast.shared().get_npc(&"bram"), &"drill_sword")
	assert_true(duel.said.ends_with(option.reply), "the fight keeps his answer: %s" % duel.said)
	assert_eq(duel.said_by, &"bram", "and who said it")
