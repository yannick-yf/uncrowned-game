extends TestCase

## Phase E — Blackcairn reads the kingdom (§4, §9, §15, 2026-09-13).
##
## The castle cannot be taken and has one state. What it carries is two derived
## readings, legible from anywhere: wealth, from the treasury, the works and the
## bread; and instability, from how many places have changed hands inside one freeze
## window — whoever moved them. Recency is what makes the second political rather
## than statistical: four places in a week is a crisis, the same four over a season is
## policy. Each reading has a second channel, what people in the towns say, and the
## journal's kingdom page reads all of it out in words.


func _sim() -> Sim:
	return Game.build()


# ----------------------------------------------------------------- wealth ---

func test_the_castle_starts_building_and_a_ruin_shutters_it() -> void:
	var ticked := WorldTick.new()
	assert_eq(CastleRules.wealth(ticked), CastleRules.BUILDING, "the king's programme, at the start")
	ticked.push(&"crown_treasury", -60.0)
	ticked.push(&"steel_output", -40.0)
	assert_eq(CastleRules.wealth(ticked), CastleRules.HOLDING, "one bad season: %.0f" % CastleRules.wealth_score(ticked))
	ticked.push(&"crown_treasury", -40.0)
	ticked.push(&"steel_output", -40.0)
	assert_eq(CastleRules.wealth(ticked), CastleRules.SHUTTERED, "and a ruin: %.0f" % CastleRules.wealth_score(ticked))


func test_dear_bread_everywhere_counts_against_the_castle() -> void:
	var ticked := WorldTick.new()
	for town: StringName in Region.ZONE_ORDER:
		ticked.grain_price[town] = 100.0
	assert_true(CastleRules.supply_score(ticked) < 60.0, "the capital eats what the towns cannot afford")
	assert_true(CastleRules.wealth_score(ticked) < 100.0)


# ------------------------------------------------------------ instability ---

func test_a_flip_is_a_flip_to_the_men_on_the_wall_whoever_caused_it() -> void:
	var mine := Allegiance.new()
	assert_eq(CastleRules.instability(mine, 0), CastleRules.CALM, "nothing has moved")
	mine.decide(&"wide_acres", FactionRules.OPPOSITION, 10)
	assert_eq(CastleRules.instability(mine, 20), CastleRules.UNEASY, "one place, by your hand")
	mine.drift_to(&"saltmarch", FactionRules.OPPOSITION, 30)
	assert_eq(CastleRules.instability(mine, 40), CastleRules.CRISIS, "two in a week, one of them the weather's")
	assert_eq(CastleRules.extra_guards(CastleRules.CRISIS), 4, "and the wall fills")


func test_the_same_flips_over_a_season_are_policy() -> void:
	var mine := Allegiance.new()
	mine.decide(&"wide_acres", FactionRules.OPPOSITION, 10)
	mine.drift_to(&"saltmarch", FactionRules.OPPOSITION, 30)
	var later: int = 30 + PlaceRules.freeze_ticks() + 1
	assert_eq(CastleRules.instability(mine, later), CastleRules.CALM,
		"the window is §8's freeze window and no other, and both flips are outside it")
	assert_eq(CastleRules.extra_guards(CastleRules.CALM), 0)


func test_a_stamp_that_moved_nothing_is_not_a_flip() -> void:
	var mine := Allegiance.new()
	mine.decide(&"wide_acres", FactionRules.CROWN, 10)
	assert_eq(CastleRules.instability(mine, 20), CastleRules.CALM, "nothing changed hands, so nothing to count")


# ------------------------------------------------------ the second channel ---

func test_the_towns_talk_about_the_castle_in_both_languages() -> void:
	var sim: Sim = _sim()
	var world := sim.store(&"world") as WorldState
	var ticked := sim.store(&"worldtick") as WorldTick
	var standing := sim.store(&"standing") as Standing
	var mine := sim.store(&"allegiance") as Allegiance

	var calm: Dictionary = DialogueRules.conditions(world, ticked, standing, mine, sim.tick)
	assert_true(bool(calm[&"blackcairn_is_rich"]), "the castle is building, to begin with")
	assert_false(bool(calm[&"blackcairn_is_unstable"]))
	assert_false(bool(calm[&"blackcairn_is_poor"]))

	mine.decide(&"wide_acres", FactionRules.OPPOSITION, sim.tick)
	mine.drift_to(&"saltmarch", FactionRules.OPPOSITION, sim.tick)
	ticked.push(&"crown_treasury", -100.0)
	ticked.push(&"steel_output", -70.0)
	var crisis: Dictionary = DialogueRules.conditions(world, ticked, standing, mine, sim.tick)
	assert_true(bool(crisis[&"blackcairn_is_unstable"]))
	assert_true(bool(crisis[&"blackcairn_is_poor"]))
	assert_false(bool(crisis[&"blackcairn_is_rich"]))

	for language: String in ["en", "fr"]:
		var cast: Cast = Cast.load_from(Cast.path_for(language))
		var maddox: Npc = cast.get_npc(&"maddox")
		var peyre: Npc = cast.get_npc(&"peyre")
		var garrick: Npc = cast.get_npc(&"garrick")
		assert_true(maddox.greeting_for(crisis) != maddox.greeting, "%s: Maddox has heard about the gate" % language)
		assert_true(peyre.greeting_for(crisis) != peyre.greeting, "%s: Peyre has seen the wall stop" % language)
		# The rich reading is true from minute one, so it is a question Garrick answers
		# rather than a greeting that would never lift off his disposition band.
		var asked_calm: Array[String] = []
		for option: DialogueOption in DialogueRules.available(garrick, sim.facts, calm):
			asked_calm.append(String(option.intent))
		var asked_crisis: Array[String] = []
		for option: DialogueOption in DialogueRules.available(garrick, sim.facts, crisis):
			asked_crisis.append(String(option.intent))
		assert_true(asked_calm.has("ask_castle_stone"), "%s: Garrick can be asked what the castle buys" % language)
		assert_false(asked_crisis.has("ask_castle_stone"), "%s: and not once the buying stops" % language)


# --------------------------------------------------------------- the page ---

func test_the_kingdom_page_reads_places_people_and_castle_out() -> void:
	var sim: Sim = _sim()
	var ticked := sim.store(&"worldtick") as WorldTick
	var mine := sim.store(&"allegiance") as Allegiance
	var rows: Array[Dictionary] = Journal.kingdom(mine, ticked, sim.tick)
	var places: int = 0
	var castle: Dictionary = {}
	for row: Dictionary in rows:
		if row["kind"] == &"place":
			places += 1
			assert_false(bool(row["free"]), "%s starts the crown's" % row["town"])
			assert_eq(int(row["tick"]), -1, "and nobody has moved it")
		elif row["kind"] == &"castle":
			castle = row
	assert_eq(places, 4, "the four places")
	assert_eq(castle["wealth"], CastleRules.BUILDING)
	assert_eq(castle["unrest"], CastleRules.CALM)

	mine.decide(&"wide_acres", FactionRules.OPPOSITION, sim.tick)
	ticked.push_hardship(&"wide_acres", 20.0)
	ticked.push_hardship(&"muster", -10.0)
	var worse: int = 0
	var better: int = 0
	for row: Dictionary in Journal.kingdom(mine, ticked, sim.tick):
		if row["kind"] == &"hardship":
			if bool(row["worse"]):
				worse += 1
			else:
				better += 1
		elif row["kind"] == &"place" and row["town"] == &"wide_acres":
			assert_true(bool(row["free"]) and bool(row["decided"]) and bool(row["by_player"]), "freed, by your hand")
			assert_eq(int(row["tick"]), sim.tick, "and when")
	assert_eq(worse, 1, "one town worse off")
	assert_eq(better, 1, "one better")


func test_the_kingdom_page_never_scores() -> void:
	# The journal explains; it does not score. No field on this page is a standing or
	# a reputation, and none of its words is a number.
	var sim: Sim = _sim()
	for row: Dictionary in Journal.kingdom(sim.store(&"allegiance") as Allegiance,
			sim.store(&"worldtick") as WorldTick, sim.tick):
		for field: String in row.keys():
			assert_false(field.contains("standing") or field.contains("reputation") or field.contains("score"),
				"the kingdom page carries '%s'" % field)
	for language: String in ["en", "fr"]:
		Text.set_locale(language)
		for key: String in ["journal.kingdom.crown", "journal.kingdom.free", "journal.kingdom.same",
				"journal.kingdom.wealth.building", "journal.kingdom.wealth.holding",
				"journal.kingdom.wealth.shuttered", "journal.kingdom.unrest.calm",
				"journal.kingdom.unrest.uneasy", "journal.kingdom.unrest.crisis"]:
			var line: String = Text.of(StringName(key))
			assert_ne(line, key, "%s: %s has words" % [language, key])
			for digit: String in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]:
				assert_false(line.contains(digit), "%s: %s carries a number: %s" % [language, key, line])
	Text.set_locale("en")


func test_nothing_about_an_ending_reads_the_castle() -> void:
	# Both readings are read out, never in (§4): a predicate over them would make the
	# castle's face a goal with a correct direction.
	for ending: Dictionary in EndRules.endings():
		for need: Dictionary in (ending["needs"] as Array):
			var reading: String = String(need["reading"])
			assert_false(reading.contains("wealth") or reading.contains("instability") or reading.contains("unrest"),
				"%s reads the castle's face" % ending["id"])
