extends TestCase

## Phase 5, stage 1: the king can fall out of the world.
##
## §3 — the goal is not to kill him, it is that he stops being king. The ending is a
## predicate over the tracked quantities and never a completed route, so any
## combination of acts that reaches one of those states finishes the game and
## nothing has required steps.
##
## The two rules that matter are both here as tests, because both are the kind that
## quietly stop being true: **drift may move the world, only the player may end it**,
## and **a number that decides the game is on the page the player can read**.


## Lean on purpose: an ending is a question about numbers, and wildlife and
## travellers cost steps without moving any of them. Thirty in-game days through the
## full build took twenty-five seconds; through this it takes under one.
func _quiet() -> Sim:
	var sim := Sim.new()
	sim.add_store(&"world", Game.build_world())
	sim.add_store(&"worldtick", WorldTick.new())
	sim.add_system(WorldTickSystem.new())
	sim.add_system(GrainSystem.new())
	sim.add_system(EndingSystem.new())
	return sim


func _world() -> Sim:
	var sim: Sim = _quiet()
	sim.facts.add_source(ArmyRules.FACT_PAY_FRAUD, &"ossa")
	return sim


func _days(sim: Sim, count: float) -> void:
	sim.advance_world_ticks(int(float(Game.TICKS_PER_IN_GAME_DAY) * count))


# ------------------------------------------------------------- the guardrail ---

func test_a_world_nobody_touches_never_ends() -> void:
	var sim: Sim = _quiet()
	_days(sim, 12.0)
	assert_eq((sim.store(&"world") as WorldState).reign_ended, &"",
		"a fortnight of weather is not a revolution")


func test_drift_cannot_end_a_reign_even_at_the_threshold() -> void:
	# The sharp version. Put the numbers exactly where an ending wants them, the
	# way drift would — by assignment, leaving no fingerprints — and nothing
	# happens. Without this the player is a spectator at their own story.
	var sim: Sim = _quiet()
	var ticked := sim.store(&"worldtick") as WorldTick
	ticked.crown_treasury = 0.0
	ticked.bank_confidence = 0.0
	ticked.army_strength = 0.0
	ticked.faction_tension = 100.0
	_days(sim, 2.0)

	assert_eq((sim.store(&"world") as WorldState).reign_ended, &"",
		"every line crossed and nobody's hand on any of it")
	for row: Dictionary in EndRules.what_holds_him_up(ticked, null, sim.facts):
		assert_eq(float(row["yours"]), 0.0, "%s is nobody's doing" % row["name"])


func test_the_same_numbers_end_it_when_they_are_yours() -> void:
	# The control, and the whole of the difference: identical world state, reached
	# through push() instead of assignment.
	var sim: Sim = _quiet()
	var ticked := sim.store(&"worldtick") as WorldTick
	ticked.push(&"crown_treasury", -100.0)
	ticked.push(&"bank_confidence", -100.0)
	_days(sim, 1.0)
	assert_eq((sim.store(&"world") as WorldState).reign_ended, EndRules.RUINED,
		"the same numbers, and this time somebody emptied them")


func test_a_reign_ends_once() -> void:
	var sim: Sim = _quiet()
	var world := sim.store(&"world") as WorldState
	var ticked := sim.store(&"worldtick") as WorldTick
	ticked.push(&"crown_treasury", -100.0)
	ticked.push(&"bank_confidence", -100.0)
	_days(sim, 1.0)
	var when: int = world.reign_ended_tick
	# Money comes back and the army collapses; he is still no longer king.
	ticked.push(&"crown_treasury", 100.0)
	ticked.push(&"army_strength", -100.0)
	ticked.push(&"faction_tension", 100.0)
	_days(sim, 5.0)
	assert_eq(world.reign_ended, EndRules.RUINED, "it was ruin, and it stays ruin")
	assert_eq(world.reign_ended_tick, when, "and it happened when it happened")


# ---------------------------------------------------------------- legibility ---

func test_every_number_that_ends_the_game_is_on_the_page() -> void:
	# §15, as a structural guarantee rather than a promise. The endings and the
	# page walk the same table, so this fails the moment somebody writes a
	# predicate over something the player has no way to see.
	var sim: Sim = _quiet()
	var shown: Array[String] = []
	for row: Dictionary in EndRules.what_holds_him_up(
			sim.store(&"worldtick") as WorldTick, sim.store(&"world") as WorldState, sim.facts):
		shown.append(String(row["reading"]))
		assert_true(String(row["name"]).length() > 0, "and it is in words, not a field name")

	for ending: Dictionary in EndRules.endings():
		for need: Dictionary in (ending["needs"] as Array):
			assert_true(shown.has(String(need["reading"])),
				"'%s' decides the '%s' ending and is nowhere the player can read it"
					% [need["reading"], ending["id"]])


func test_the_page_never_gives_advice() -> void:
	# State and attribution only. The moment it says what to do next, the game is
	# telling the player their own story back to them (§8).
	var sim: Sim = _world()
	var forbidden: Array[String] = ["should", "try ", "next", "you must", "in order to", "tip"]
	for row: Dictionary in EndRules.what_holds_him_up(
			sim.store(&"worldtick") as WorldTick, sim.store(&"world") as WorldState, sim.facts):
		for phrase: String in forbidden:
			assert_false(String(row["name"]).to_lower().contains(phrase),
				"the page says \"%s\"" % row["name"])


# ------------------------------------------------------------- the endings ---

func test_no_ending_is_unreachable_by_construction() -> void:
	# Every row in the table can be satisfied. A predicate nobody can meet is a
	# dead end dressed as content, and the one that cannot is named rather than
	# quietly broken.
	for ending: Dictionary in EndRules.endings():
		var id: StringName = ending["id"] as StringName
		if id == EndRules.DEAD:
			continue  # Needs the combat screen. Phase 4, deliberately.
		var sim: Sim = _quiet()
		var ticked := sim.store(&"worldtick") as WorldTick
		for need: Dictionary in (ending["needs"] as Array):
			_force(sim, ticked, need)
		_days(sim, 1.0)
		assert_eq((sim.store(&"world") as WorldState).reign_ended, id,
			"'%s' cannot be reached even with every reading forced" % id)


func test_the_dead_ending_waits_for_combat() -> void:
	# Written with the other four on purpose, and unreachable on purpose: it is
	# what makes deferring Phase 4 cost one ending rather than the climax.
	var sim: Sim = _quiet()
	assert_eq((sim.store(&"world") as WorldState).king_hp, 1000,
		"§10 gives him a thousand and no way yet to take any of it")
	_days(sim, 6.0)
	assert_eq((sim.store(&"world") as WorldState).reign_ended, &"", "so nothing kills him")


## Drive one reading to where an ending wants it, with a handprint on it.
func _force(sim: Sim, ticked: WorldTick, need: Dictionary) -> void:
	var reading: StringName = need["reading"] as StringName
	var line: float = float(need["line"])
	match reading:
		&"facts_public":
			for i: int in int(line):
				sim.facts.add_source(StringName("public:%d" % i), &"witnessed")
			ticked.credit(&"facts_public", EndRules.HANDPRINT_NEEDED)
		&"towns_turned", &"town_sentiment_at_blackcairn":
			for town: StringName in Region.ZONE_ORDER:
				ticked.push_sentiment(town, -WorldTick.BASELINE)
		&"kings_escort":
			ticked.push(&"army_strength", -WorldTick.BASELINE)
		_:
			var now: float = ticked.get_quantity(reading)
			ticked.push(reading, (line - now) + (1.0 if int(need["direction"]) == EndRules.UP else -1.0))
