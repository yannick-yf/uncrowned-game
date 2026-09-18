extends TestCase

## The kingdom's two numbers (M4).
##
## They are what turn *the ironworks has stopped* into *the crown is short of steel*.
## They are also **derived and never stored**, so these tests are about the arithmetic
## being right and about nothing being able to write a number that the towns disagree
## with — there is no third place for the two to fall out of step.


func _towns() -> TownState:
	return Game.build().store(&"towns") as TownState


func test_stopping_the_works_costs_the_crown_its_force() -> void:
	var towns: TownState = _towns()
	var before: float = KingdomRules.force(towns)
	towns.set_value(&"cinderworks", TownRules.RICHESSE, TownRules.FLOOR)
	var after: float = KingdomRules.force(towns)
	assert_true(after < before,
		"a dead works weakens the crown: %.1f, was %.1f" % [after, before])


func test_a_kingdom_can_be_disarmed_by_talking() -> void:
	# **Rule 2 is what makes this true**, now that the king's force is only his treasury.
	# Nothing is destroyed — every place keeps exactly the richesse it had — and the king
	# is weaker anyway, because a place that has turned stops shipping to him.
	var towns: TownState = _towns()
	var before: float = KingdomRules.force(towns)
	var kept: Dictionary = {}
	for place: StringName in towns.ids():
		kept[place] = towns.richesse_of(place)
		towns.set_value(place, TownRules.ALLEGIANCE, TownRules.FLOOR)
	for place: StringName in towns.ids():
		assert_eq(towns.richesse_of(place), int(kept[place]),
			"%s makes exactly what it made: nothing was broken" % place)
	assert_eq(KingdomRules.tresor(towns), 0.0, "and none of it reaches the crown")
	assert_true(KingdomRules.force(towns) < before, "so the king is weaker")


func test_only_the_places_that_send_something_fill_the_treasury() -> void:
	var towns: TownState = _towns()
	# Harrowgate and the Muster consume and send nothing. Their richesse is real and it
	# is not the crown's.
	assert_eq(KingdomRules.sends(&"harrowgate"), &"")
	assert_eq(KingdomRules.sends(&"muster"), &"")
	assert_eq(KingdomRules.sent_by(towns, &"muster"), 0, "the camp sends nothing")
	var before: float = KingdomRules.tresor(towns)
	towns.set_value(&"muster", TownRules.RICHESSE, TownRules.CEILING)
	assert_eq(KingdomRules.tresor(towns), before, "a rich camp is not a rich crown")
	towns.set_value(&"wide_acres", TownRules.RICHESSE, TownRules.CEILING)
	assert_true(KingdomRules.tresor(towns) > before, "rich farms are")


func test_the_capital_is_read_like_any_other_place() -> void:
	# Yannick's correction of 2026-09-18: the kingdom has the same shape as a place.
	# Two numbers, four appearances, the same thresholds. Somebody who has learnt to
	# read a town has learnt to read the kingdom.
	var towns: TownState = _towns()
	for place: StringName in towns.ids():
		towns.set_value(place, TownRules.ALLEGIANCE, TownRules.CEILING)
		towns.set_value(place, TownRules.RICHESSE, TownRules.CEILING)
	assert_eq(KingdomRules.look(towns), &"loyal_rich")
	for place: StringName in towns.ids():
		towns.set_value(place, TownRules.ALLEGIANCE, TownRules.FLOOR)
	assert_eq(KingdomRules.look(towns), &"hostile_poor",
		"a crown nobody is with is a poor crown: rule 2 means nothing arrives any more")


func test_force_is_a_reading_and_not_a_number_of_its_own() -> void:
	# One number with two names is how two numbers are born. This holds them equal.
	var towns: TownState = _towns()
	towns.set_value(&"cinderworks", TownRules.RICHESSE, 9)
	assert_eq(KingdomRules.force(towns), KingdomRules.tresor(towns),
		"rule 4: the king's force is his treasury, the same number under another name")


func test_the_two_numbers_stay_on_the_same_scale_as_everything_else() -> void:
	var towns: TownState = _towns()
	for place: StringName in towns.ids():
		towns.set_value(place, TownRules.ALLEGIANCE, TownRules.CEILING)
		towns.set_value(place, TownRules.RICHESSE, TownRules.CEILING)
	assert_eq(KingdomRules.force(towns), float(TownRules.CEILING), "a kingdom at its best")
	assert_eq(KingdomRules.tresor(towns), float(TownRules.CEILING))
	for place: StringName in towns.ids():
		towns.set_value(place, TownRules.ALLEGIANCE, TownRules.FLOOR)
		towns.set_value(place, TownRules.RICHESSE, TownRules.FLOOR)
	assert_eq(KingdomRules.force(towns), float(TownRules.FLOOR), "and at its worst")
	assert_eq(KingdomRules.tresor(towns), float(TownRules.FLOOR))


func test_nothing_can_write_the_kingdom_a_number_of_its_own() -> void:
	# Derived, never stored: two runs whose towns agree have kingdoms that agree, and
	# there is no third place for them to fall out of step. This is the whole reason
	# there is no kingdom store and no kingdom event.
	var sim: Sim = Game.build()
	sim.submit(&"move_town_value", {"place": "cinderworks", "value": "richesse", "direction": -1})
	sim.advance(2)
	var towns := sim.store(&"towns") as TownState
	var replayed: Sim = Game.replay(sim)
	var rebuilt := replayed.store(&"towns") as TownState
	assert_eq(rebuilt.fingerprint(), towns.fingerprint(), "the same towns")
	assert_eq(KingdomRules.force(rebuilt), KingdomRules.force(towns), "so the same crown")
	assert_eq(KingdomRules.tresor(rebuilt), KingdomRules.tresor(towns))
