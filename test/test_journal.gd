extends TestCase

## Phase 3, stage 5: §8's third feedback register.
##
## IMMEDIATE is the act confirmed as you do it. AMBIENT is the world quietly
## changing its mind. NARRATED is this — the only place in the game that joins the
## two, and the reason a player ever feels a choice mattered. Most systemic games
## ship the first two and skip this one.
##
## Everything here is read from the event log and nothing else, which is what the
## external/derived split was paid for.



## Lean: the journal is read from events, and travellers and movement cost steps
## while raising none of the ones it reads.
func _run() -> Sim:
	var sim := Sim.new()
	sim.add_store(&"world", Game.build_world())
	sim.add_store(&"cast", Cast.shared())
	sim.add_store(&"worldtick", WorldTick.new())
	sim.add_store(&"standing", Standing.new())
	sim.add_store(&"rumours", Rumours.new())
	sim.add_system(ArmySystem.new())
	sim.add_system(WorldTickSystem.new())
	sim.add_system(GrainSystem.new())
	sim.add_system(TellingSystem.new())
	sim.add_system(TheftSystem.new())
	sim.add_system(RumourSystem.new())
	sim.facts.add_source(ArmyRules.FACT_PAY_FRAUD, &"ossa")
	return sim


func _steal_and_wait(sim: Sim, days: float) -> void:
	var world := sim.store(&"world") as WorldState
	world.player_pos = at_a_stall()
	sim.submit(&"steal")
	sim.advance(3)
	sim.advance_world_ticks(int(float(Game.TICKS_PER_IN_GAME_DAY) * days))


func test_nothing_happened_so_there_is_nothing_to_read() -> void:
	var sim: Sim = _run()
	sim.advance(Sim.STEPS_PER_REAL_SECOND)
	assert_eq(Journal.entries(sim.events).size(), 0,
		"a journal that writes itself before you have done anything is a tutorial")


func test_the_act_and_its_consequence_are_both_there_in_order() -> void:
	var sim: Sim = _run()
	_steal_and_wait(sim, 4.0)
	var rows: Array[Dictionary] = Journal.entries(sim.events)
	assert_true(rows.size() >= 2, "the theft, and somewhere hearing about it")
	assert_eq(rows[0]["kind"], Journal.DEED, "the first thing in it is what you did")
	assert_eq(rows[0]["deed"], DeedRules.DEED_THEFT, "and it was the theft")

	var last: int = -1
	for row: Dictionary in rows:
		assert_true(int(row["tick"]) >= last, "the journal runs forwards")
		last = int(row["tick"])


func test_the_journal_names_the_delay_and_the_place() -> void:
	# The whole point of the screen. "Cairnwell has heard about it" on its own is
	# the ambient register again; "three days after you took something, in
	# Harrowgate" is the attribution, and it is the only place it appears.
	var sim: Sim = _run()
	_steal_and_wait(sim, 4.0)
	var found: bool = false
	for row: Dictionary in Journal.entries(sim.events):
		if row["kind"] != Journal.ARRIVAL or row["town"] != &"muster":
			continue
		found = true
		assert_eq(row["origin"], &"harrowgate", "it carries where it started")
		assert_true(float(row["days"]) > 0.0, "and how long the story took")
	assert_true(found, "the camp heard about it within four days")


func test_the_journal_is_pulled_and_never_pushed() -> void:
	# §8: never announce "your actions caused X". The journal explains; it does not
	# accuse, and nothing outside it explains at all.
	var sim: Sim = _run()
	_steal_and_wait(sim, 4.0)
	# The rows carry no prose at all now, so what this guards is that they carry no
	# *scoring* either: no number that is a reputation, no field that accuses.
	for row: Dictionary in Journal.entries(sim.events):
		for field: String in row.keys():
			assert_false(field.contains("standing") or field.contains("reputation"),
				"the journal row carries '%s' — it explains, it does not score you" % field)


func test_a_fact_with_one_source_is_shown_as_a_fact_with_one_source() -> void:
	# Invariant 6 made the player's problem as well as the designer's: the journal
	# tells you which of the things you know would die with the person who said it.
	var sim: Sim = _run()
	var cast := sim.store(&"cast") as Cast
	var alone: Array[Dictionary] = Journal.knowledge(sim.facts, cast)
	assert_eq(alone.size(), 1, "one thing known, from Ossa alone")
	assert_false(bool(alone[0]["safe"]), "and nobody else has told you it")

	sim.facts.add_source(ArmyRules.FACT_PAY_FRAUD, &"garrick")
	assert_true(bool(Journal.knowledge(sim.facts, cast)[0]["safe"]),
		"now two people have, and it survives either of them")


func test_spending_the_telling_is_written_down() -> void:
	# Found in play: warn Harrowgate, walk to the camp, and the option to expose
	# the fraud is simply gone with nothing said anywhere. That is the intended
	# cost — it can be told once — but an absent prompt is indistinguishable from
	# a bug, and the journal is the only screen allowed to explain.
	var sim: Sim = _run()
	var world := sim.store(&"world") as WorldState
	world.player_pos = in_town(&"harrowgate")
	sim.submit(&"tell_town")
	sim.advance(3)

	var told: Dictionary = {}
	for row: Dictionary in Journal.entries(sim.events):
		if row["kind"] == Journal.DEED and row["deed"] == DeedRules.DEED_WARNING:
			told = row
	assert_false(told.is_empty(), "the warning is in the journal")
	assert_true(bool(told["spends_the_telling"]), "and so is what it cost")


func test_the_camp_stops_advertising_what_you_can_no_longer_do() -> void:
	# The ambient half of the same fix. The atmosphere line is authored in the
	# window, so what is checked here is the state it reads: three cases, not two.
	var sim: Sim = _run()
	var world := sim.store(&"world") as WorldState
	assert_eq(world.fraud_told_to, &"", "nothing told yet — the pay tent has a queue")

	world.player_pos = in_town(&"harrowgate")
	sim.submit(&"tell_town")
	sim.advance(3)
	assert_eq(world.fraud_told_to, &"harrowgate", "told, and not at the camp")
	assert_false(world.pay_fraud_exposed,
		"so the camp is neither untouched nor exposed, and needs its own line")


func test_bookkeeping_is_not_knowledge() -> void:
	# The fact base holds "met:maddox" and similar. Those are not things the player
	# learned and they must never appear on the screen that shows what they know.
	var sim: Sim = _run()
	sim.facts.add_source(&"met:maddox", &"witnessed")
	for row: Dictionary in Journal.knowledge(sim.facts, sim.store(&"cast") as Cast):
		assert_false(String(row["fact"]).begins_with("met:"),
			"'%s' is bookkeeping, not knowledge" % row["fact"])


# ---------------------------------- what they think of you, and why (J6) ---

## The player's own store and its writer, added for the standings page. The lean
## world above raises the events; without these two nothing holds the number.
func _run_with_a_player() -> Sim:
	var sim: Sim = _run()
	sim.add_store(&"player", PlayerState.new())
	sim.add_system(PlayerSystem.new())
	return sim


func _row_for(rows: Array[Dictionary], town: StringName) -> Dictionary:
	for row: Dictionary in rows:
		if row["town"] == town:
			return row
	fail("no row for %s" % town)
	return {}


func test_the_number_and_its_cause_are_on_the_same_row() -> void:
	# J6's whole reason: **a town that hates you and will not say why is a bug.** The
	# standing is in the store, the deed that moved it is in the log, and this is the
	# reading that puts them together.
	var sim: Sim = _run_with_a_player()
	_steal_and_wait(sim, 0.0)
	var rows: Array[Dictionary] = Journal.standings(
		sim.store(&"player") as PlayerState, sim.events)
	var here: Dictionary = _row_for(rows, &"harrowgate")
	assert_eq(here["word"], &"wary", "Harrowgate has heard something")
	assert_eq(float(here["amount"]), PlayerRules.A_THEFT, "and it is worth ten of them")
	var moves: Array[Dictionary] = here["moves"] as Array[Dictionary]
	assert_eq(moves.size(), 1, "one act moved it")
	assert_eq(moves[0]["deed"], DeedRules.DEED_THEFT, "and the row says which")
	assert_eq(float(moves[0]["by"]), PlayerRules.A_THEFT, "and what it cost")


func test_a_killing_reads_as_a_killing_and_not_as_a_number() -> void:
	var sim: Sim = _run_with_a_player()
	var world := sim.store(&"world") as WorldState
	world.player_pos = in_town(&"harrowgate")
	Deeds.perform(sim, PlayerRules.DEED_KILLED_INNOCENT, &"harrowgate", world.player_pos)
	sim.advance(3)
	var here: Dictionary = _row_for(Journal.standings(
		sim.store(&"player") as PlayerState, sim.events), &"harrowgate")
	assert_eq(here["word"], &"hated", "one afternoon and the town is done with you")
	var moves: Array[Dictionary] = here["moves"] as Array[Dictionary]
	assert_eq(moves.size(), 1, "and there is one line under it")
	assert_eq(moves[0]["deed"], PlayerRules.DEED_KILLED_INNOCENT, "saying what you did")
	assert_eq(float(moves[0]["by"]), PlayerRules.A_MURDER, "and what it cost")


func test_every_town_is_on_the_page_including_the_ones_that_never_heard() -> void:
	# §4's half that is easy to leave out: the towns never visited are part of the
	# reading, at neutral, and a page that hid them would hide why the court's number
	# is what it is.
	var sim: Sim = _run_with_a_player()
	_steal_and_wait(sim, 0.0)
	var rows: Array[Dictionary] = Journal.standings(
		sim.store(&"player") as PlayerState, sim.events)
	assert_eq(rows.size(), 5, "five towns, whether or not they have heard of you")
	var quiet: Dictionary = _row_for(rows, &"muster")
	assert_eq(quiet["word"], &"unknown", "the camp has heard nothing")
	assert_eq((quiet["moves"] as Array[Dictionary]).size(), 0, "and has nothing to say")


func test_a_page_read_before_anything_happened_says_so_rather_than_nothing() -> void:
	var rows: Array[Dictionary] = Journal.standings(
		_run_with_a_player().store(&"player") as PlayerState, null)
	assert_eq(rows.size(), 5, "the towns are there from the first minute")
	for row: Dictionary in rows:
		assert_eq(row["word"], &"unknown", "%s has never heard of you" % row["town"])
