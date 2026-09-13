extends TestCase

## Phase D — the crown as a play (§3, §5, §11, 2026-09-13).
##
## Rank is derived from crown standing, exactly as the escort is derived from army
## strength: nothing stores "you are a chamberlain", the title is what the court calls
## somebody at that standing, and it falls as well as rises. It changes how you are
## greeted and what you are offered, and it **never gates** — the guard knowing your
## face is one of three ways through the gate. High standing removes no ending; a
## player loyal all game can still turn, and Deposed at the crown's last rank is the
## throne reading, not a sixth ending. And the opening points two ways: the king's
## argument is audible at the works in the first hour, in Halgrave's mouth.


func _sim() -> Sim:
	return Game.build()


func _did(sim: Sim, deed: StringName, where: StringName = &"harrowgate") -> void:
	var world := sim.store(&"world") as WorldState
	Deeds.perform(sim, deed, where, world.player_pos)
	sim.advance(2)


func _events_of(sim: Sim, kind: StringName) -> int:
	var count: int = 0
	for event: SimEvent in sim.events.all():
		if event.type == kind:
			count += 1
	return count


# ------------------------------------------------------------------- rank ---

func test_rank_is_derived_from_crown_standing_and_falls_as_well_as_rises() -> void:
	var sim: Sim = _sim()
	var mine := sim.store(&"allegiance") as Allegiance
	var standing := sim.store(&"standing") as Standing
	sim.submit(&"join", {"side": "crown"})
	sim.advance(2)
	assert_eq(mine.rank_with(standing), 0, "a king's man, at the bottom")
	_did(sim, DeedRules.DEED_INFORM)
	assert_eq(mine.rank_with(standing), 1, "a clerk, for what you carried to him")
	_did(sim, DeedRules.DEED_ENFORCE_GRANTS, &"wide_acres")
	_did(sim, DeedRules.DEED_HAND_OVER_DESERTERS, &"muster")
	assert_eq(mine.rank_with(standing), 2, "an officer: %.0f" % standing.with_faction(DeedRules.FACTION_CROWN))
	_did(sim, DeedRules.DEED_BRING_CREDITORS, &"cairnwell")
	assert_eq(mine.rank_with(standing), 3, "the chamberlain: the castle door")
	assert_true(mine.door_is_open(standing), "and the guard knows your face")
	_did(sim, DeedRules.DEED_SABOTAGE, &"cinderworks")
	assert_eq(mine.rank_with(standing), 2, "and not after you put his furnace out")
	assert_false(mine.door_is_open(standing), "the door is one of three ways in, and it shut")


func test_the_court_announces_a_rise_and_a_fall() -> void:
	var sim: Sim = _sim()
	sim.submit(&"join", {"side": "crown"})
	sim.advance(2)
	_did(sim, DeedRules.DEED_INFORM)
	assert_eq(_events_of(sim, &"rose"), 1, "the clerk's title, announced once")
	_did(sim, DeedRules.DEED_SABOTAGE, &"cinderworks")
	assert_eq(_events_of(sim, &"fell"), 1, "and its loss, once")


func test_the_last_rank_is_reachable_because_standing_clamps() -> void:
	# v1's 110 was a tally's threshold and a standing never reaches it: the door would
	# never have opened. The line sits inside the clamp, and well above the officer's.
	var last: Dictionary = (FactionRules.RANKS[FactionRules.CROWN] as Array).back()
	assert_true(float(last["needs"]) <= Standing.BEST, "reachable")
	assert_true(float(last["needs"]) >= 80.0, "and not cheap: %.0f" % float(last["needs"]))


func test_rank_never_gates_a_fact() -> void:
	# Invariant 4 at the point most likely to break it. A rank may change a greeting
	# or an offer; no fact and no deed may sit behind one, so every line that leans on
	# a rank teaches nothing and causes nothing.
	var cast: Cast = Cast.shared()
	var leaning: int = 0
	for npc: Npc in cast.named():
		for option: DialogueOption in npc.options:
			if not String(option.requires_condition).begins_with("crown_rank"):
				continue
			leaning += 1
			assert_eq(option.teaches, &"", "%s's %s puts a fact behind a rank" % [npc.id, option.intent])
			assert_eq(option.causes, &"", "%s's %s puts a deed behind a rank" % [npc.id, option.intent])
		for alt: Dictionary in npc.alt_greetings:
			if String(alt.get("when", "")).begins_with("crown_rank"):
				leaning += 1
	assert_true(leaning >= 3, "and rank is read somewhere: %d lines" % leaning)


func test_the_gate_knows_your_face_at_the_last_rank_in_both_languages() -> void:
	var sim: Sim = _sim()
	var world := sim.store(&"world") as WorldState
	var ticked := sim.store(&"worldtick") as WorldTick
	var standing := sim.store(&"standing") as Standing
	var mine := sim.store(&"allegiance") as Allegiance
	var before: Dictionary = DialogueRules.conditions(world, ticked, standing, mine, sim.tick)
	assert_false(bool(before[&"crown_rank_is_at_least_3"]), "a nobody")
	standing.shift_faction(DeedRules.FACTION_CROWN, Standing.BEST)
	var after: Dictionary = DialogueRules.conditions(world, ticked, standing, mine, sim.tick)
	assert_true(bool(after[&"crown_rank_is_at_least_3"]), "the chamberlain")
	for language: String in ["en", "fr"]:
		var cast: Cast = Cast.load_from(Cast.path_for(language))
		for who: StringName in [&"dray", &"hesper"]:
			var npc: Npc = cast.get_npc(who)
			assert_true(npc.greeting_for(after) != npc.greeting, "%s: %s greets the chamberlain differently" % [language, who])
			assert_eq(npc.greeting_for(before), npc.greeting, "%s: and a nobody as before" % language)


# ------------------------------------------------------------- the opening ---

func test_the_kings_argument_is_audible_at_the_works_in_the_first_hour() -> void:
	# §5: one credible pro-works voice in the first hour, who is not a fool. Halgrave
	# says it to anybody, among the first three things he offers, with the figures.
	var sim: Sim = _sim()
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	world.player_pos = Vector2(cast.get_npc(&"halgrave").tile) + Vector2(0.5, 0.5)
	sim.submit(&"talk", {"npc": "halgrave"})
	sim.advance(2)
	var intents: Array[String] = []
	for option: DialogueOption in world.options:
		intents.append(String(option.intent))
	assert_true(intents.has("ask_the_king"), "offered to a stranger who has done nothing: %s" % [intents])
	var line: DialogueOption = DialogueRules.find(cast.get_npc(&"halgrave"), &"ask_the_king")
	assert_eq(line.costs, &"free", "and he is not ashamed of it")
	assert_true(line.reply.contains("40") and line.reply.contains("4"), "with the figures the works can show")


func test_the_fairy_still_names_no_enemy() -> void:
	# §5's reworked opening leans on her staying exactly this neutral. test_opening
	# walks her lines word by word; this holds the list it walks against.
	for word: String in ["king", "roi", "arthur", "crown", "couronne"]:
		assert_true(OpeningRules.SHE_MAY_NEVER_SAY.has(word), "'%s' is a word she may say" % word)


# ------------------------------------------------------------- the throne ---

func _depose(sim: Sim) -> void:
	var ticked := sim.store(&"worldtick") as WorldTick
	# Deposed: the army hollow and tension high, both with the player's hand in them.
	ticked.push(&"army_strength", -72.0)
	ticked.army_target = ticked.army_strength
	ticked.push(&"faction_tension", 30.0)
	sim.advance_world_ticks(1)


func test_deposed_at_the_crowns_last_rank_is_the_throne() -> void:
	var sim: Sim = _sim()
	var world := sim.store(&"world") as WorldState
	(sim.store(&"standing") as Standing).shift_faction(DeedRules.FACTION_CROWN, Standing.BEST)
	_depose(sim)
	assert_eq(world.reign_ended, EndRules.DEPOSED, "the reign ended")
	assert_eq(world.reign_reading, EndRules.CROWNED, "and the vacancy is yours")


func test_deposed_as_a_nobody_is_a_vacancy_somebody_else_fills() -> void:
	var sim: Sim = _sim()
	var world := sim.store(&"world") as WorldState
	_depose(sim)
	assert_eq(world.reign_ended, EndRules.DEPOSED)
	assert_eq(world.reign_reading, EndRules.VACANCY, "you made a vacancy; somebody else filled it")


func test_the_throne_is_a_reading_of_one_ending_not_a_sixth() -> void:
	assert_eq(EndRules.endings().size(), 5, "five endings, as §3 has it")
	var standing := Standing.new()
	standing.shift_faction(DeedRules.FACTION_CROWN, Standing.BEST)
	assert_eq(EndRules.reading_for(EndRules.RUINED, standing), &"", "ruined is ruined, however the crown regards you")
	assert_eq(EndRules.reading_for(EndRules.DEPOSED, standing), EndRules.CROWNED)


func test_a_loyal_run_keeps_every_ending() -> void:
	# Invariant 7: high crown standing removes no ending. A chamberlain can still
	# empty the vault and the reign is ruined like anybody else's doing.
	var sim: Sim = _sim()
	var world := sim.store(&"world") as WorldState
	var ticked := sim.store(&"worldtick") as WorldTick
	(sim.store(&"standing") as Standing).shift_faction(DeedRules.FACTION_CROWN, Standing.BEST)
	ticked.push(&"crown_treasury", -85.0)
	ticked.push(&"bank_confidence", -80.0)
	sim.advance_world_ticks(1)
	assert_eq(world.reign_ended, EndRules.RUINED, "ruined, by the crown's own chamberlain")
	assert_eq(world.reign_reading, &"", "and there is no throne in a ruin")


func test_the_throne_reading_has_words_in_both_languages() -> void:
	for language: String in ["en", "fr"]:
		var known: Array[String] = Text.keys_for(language)
		for key: String in ["journal.throne.crowned", "journal.throne.vacancy",
				"journal.throne.worse", "journal.throne.better"]:
			assert_true(known.has(key), "%s: %s" % [language, key])
