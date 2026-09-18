extends TestCase

## Where every place stands, in two numbers (`docs/SIMULATION_MODEL.md`, M1).
##
## The model this replaces had twelve quantities for the whole kingdom and no player
## could go and look at one. These are two per place, and the tests below are about
## the only three things that can go wrong with them: that a place has the numbers the
## designer wrote, that a number cannot leave 0–10, and that a change is in the log
## rather than in memory.


func test_the_cinderworks_starts_loyal_and_going_badly() -> void:
	# The one starting pair that is settled rather than proposed: the dispute is
	# visible before anybody speaks (docs/QUEST_CINDERWORKS.md §1).
	var towns := Game.build().store(&"towns") as TownState
	assert_eq(towns.allegiance_of(&"cinderworks"), 6, "still the king's works")
	assert_eq(towns.richesse_of(&"cinderworks"), 4, "and going badly")
	assert_true(TownRules.is_high(towns.allegiance_of(&"cinderworks")), "loyal reads high")
	assert_false(TownRules.is_high(towns.richesse_of(&"cinderworks")), "poor reads low")
	assert_eq(towns.look_of(&"cinderworks"), &"loyal_poor",
		"which is the one appearance that says there is an argument here")


func test_five_places_carry_the_two_numbers_and_three_do_not() -> void:
	var towns := Game.build().store(&"towns") as TownState
	for id: StringName in [&"cinderworks", &"wide_acres", &"harrowgate", &"muster", &"saltmarch"]:
		assert_true(towns.has_state(id), "%s carries the two numbers" % id)
	# Brindle is outside the system: a ruined village has no standing to report, and
	# that is not the same as having a low one (Yannick, 2026-09-18).
	assert_false(towns.has_state(&"brindle"), "a ruin is outside the system")
	assert_eq(towns.allegiance_of(&"brindle"), -1, "and says so rather than reading zero")
	# Cairnwell and Blackcairn together are the kingdom, which carries its own two.
	assert_false(towns.has_state(&"cairnwell"), "the capital is the kingdom's half")
	assert_false(towns.has_state(&"blackcairn"), "and so is the castle")


func test_a_number_never_leaves_the_floor_or_the_ceiling() -> void:
	# Guardrail 2 of the model. Without it a bad turn becomes a spiral nobody can stop.
	assert_eq(TownRules.clamped(14), TownRules.CEILING)
	assert_eq(TownRules.clamped(-3), TownRules.FLOOR)
	var towns := Game.build().store(&"towns") as TownState
	for _i: int in 6:
		towns.move(&"saltmarch", TownRules.RICHESSE, -1)
	assert_eq(towns.richesse_of(&"saltmarch"), TownRules.FLOOR, "poor, and no poorer")
	for _i: int in 6:
		towns.move(&"saltmarch", TownRules.RICHESSE, 1)
	assert_eq(towns.richesse_of(&"saltmarch"), TownRules.CEILING, "rich, and no richer")


func test_one_act_crosses_the_threshold_whichever_way_it_goes() -> void:
	# Three is chosen so that an outcome is *seen*, not for balance: from 6 and 4, both
	# of the Cinderworks quest's endings turn both appearances.
	assert_eq(TownRules.moved(6, -1), 3, "6 - 3")
	assert_eq(TownRules.moved(4, -1), 1, "4 - 3")
	assert_eq(TownRules.moved(6, 1), 9, "6 + 3")
	assert_eq(TownRules.moved(4, 1), 7, "4 + 3")
	assert_eq(TownRules.look_of(3, 1), &"hostile_poor", "backing the workers reads dead")
	assert_eq(TownRules.look_of(9, 7), &"loyal_rich", "backing the management reads restored")
	assert_ne(TownRules.look_of(3, 1), TownRules.look_of(6, 4),
		"and neither ending leaves the place looking as it did")


func test_a_direction_of_zero_moves_nothing() -> void:
	# A caller that means "no change" says so. A zero that reads like an arithmetic
	# accident is how a number moves for a reason nobody wrote down.
	assert_eq(TownRules.moved(6, 0), 6)
	var towns := Game.build().store(&"towns") as TownState
	assert_false(towns.move(&"cinderworks", TownRules.ALLEGIANCE, 0), "nothing moved")
	assert_eq(towns.allegiance_of(&"cinderworks"), 6)


func test_nothing_writes_a_number_except_an_event_in_the_log() -> void:
	var sim: Sim = Game.build()
	var towns := sim.store(&"towns") as TownState
	sim.submit(&"move_town_value",
		{"place": "cinderworks", "value": "allegiance", "direction": -1})
	sim.submit(&"move_town_value",
		{"place": "cinderworks", "value": "richesse", "direction": -1})
	sim.advance(2)
	assert_eq(towns.allegiance_of(&"cinderworks"), 3, "the works turned against him")
	assert_eq(towns.richesse_of(&"cinderworks"), 1, "and stopped paying")
	assert_eq(towns.look_of(&"cinderworks"), &"hostile_poor")

	var replayed: Sim = Game.replay(sim)
	assert_eq((replayed.store(&"towns") as TownState).fingerprint(), towns.fingerprint(),
		"the same kingdom, rebuilt from the log alone")


func test_a_move_that_changes_nothing_is_still_visible_in_the_log() -> void:
	# A place outside the system, or a number already at its ceiling. Neither is an
	# error; both are things somebody will one day need to see in a journal.
	var sim: Sim = Game.build()
	sim.submit(&"move_town_value",
		{"place": "brindle", "value": "richesse", "direction": 1})
	sim.advance(2)
	var kinds: Array[StringName] = []
	for event: SimEvent in sim.events.all():
		kinds.append(event.type)
	assert_true(kinds.has(&"town_unmoved"), "the world said nothing happened")
	assert_false(kinds.has(&"town_moved"), "and did not pretend otherwise")
