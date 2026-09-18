extends TestCase

## The kingdom handing the food back out (M5, rule 6), and rule 2 with it.
##
## The arrow that was missing: until this existed the world only ran one way, so
## stopping a works cost the farms nothing and helping the farms did nothing for the
## works. These are the tests that the return leg exists, that it is slow, and that it
## cannot undo what the player chose.

const SLOW: bool = true

const A_DAY: int = Game.TICKS_PER_IN_GAME_DAY * Sim.STEPS_PER_REAL_SECOND \
	/ Game.TICKS_PER_REAL_SECOND


func test_a_place_that_has_turned_sends_the_king_nothing() -> void:
	# Rule 2, and it is what lets allégeance weaken the king at all now that his force
	# is only his treasury.
	var towns := Game.build().store(&"towns") as TownState
	var before: float = KingdomRules.tresor(towns)
	assert_eq(KingdomRules.sent_by(towns, &"cinderworks"), 4, "a loyal works ships its steel")
	towns.set_value(&"cinderworks", TownRules.ALLEGIANCE, TownRules.FLOOR)
	assert_eq(KingdomRules.sent_by(towns, &"cinderworks"), 0,
		"a works that has turned keeps what it makes")
	assert_true(KingdomRules.tresor(towns) < before, "and the crown is poorer for it")
	assert_eq(KingdomRules.force(towns), KingdomRules.tresor(towns),
		"the king's force is his treasury and cannot be anything else")


func test_the_king_can_be_brought_down_without_burning_anything() -> void:
	var towns := Game.build().store(&"towns") as TownState
	var before: float = KingdomRules.force(towns)
	var richesse: Dictionary = {}
	for place: StringName in towns.ids():
		richesse[place] = towns.richesse_of(place)
		towns.set_value(place, TownRules.ALLEGIANCE, TownRules.FLOOR)
	for place: StringName in towns.ids():
		assert_eq(towns.richesse_of(place), int(richesse[place]),
			"not a furnace has gone out in %s" % place)
	assert_true(KingdomRules.force(towns) < before,
		"and the king is weaker anyway: %.1f, was %.1f" % [KingdomRules.force(towns), before])


func test_a_kingdom_at_rest_moves_nothing() -> void:
	# **The property the first build did not have, and the whole reason it was wrong.**
	# Everything drifted toward the food level, so two days later every place that does
	# not grow food sat on the same number and the kingdom stopped having places in it.
	# The kingdom now pulls only across a real gap, so at rest a town keeps what it is.
	var sim: Sim = Game.build()
	var towns := sim.store(&"towns") as TownState
	var before: Dictionary = {}
	for place: StringName in towns.ids():
		before[place] = towns.richesse_of(place)
	sim.advance(A_DAY * 5)
	for place: StringName in towns.ids():
		assert_eq(towns.richesse_of(place), int(before[place]),
			"%s is where it was five days ago, because nothing happened" % place)


func test_famine_reaches_a_town_a_point_a_day() -> void:
	var sim: Sim = Game.build()
	var towns := sim.store(&"towns") as TownState
	# The harvest fails. Harrowgate grows nothing and lives on what the crown hands out.
	towns.set_value(&"wide_acres", TownRules.RICHESSE, TownRules.FLOOR)
	var start: int = towns.richesse_of(&"harrowgate")
	sim.advance(A_DAY)
	assert_eq(towns.richesse_of(&"harrowgate"), start - 1, "one point on the first day")
	sim.advance(A_DAY * 3)
	assert_true(towns.richesse_of(&"harrowgate") < start,
		"and the town is poorer than it was, without being emptied")


func test_nothing_starves_to_death() -> void:
	# The guardrail: however badly the kingdom is doing, it never drifts a place below
	# the food floor. Only the player's own act takes a place to the bottom.
	var sim: Sim = Game.build()
	var towns := sim.store(&"towns") as TownState
	for place: StringName in towns.ids():
		towns.set_value(place, TownRules.RICHESSE, TownRules.CEILING)
	towns.set_value(&"wide_acres", TownRules.RICHESSE, TownRules.FLOOR)
	towns.set_value(&"saltmarch", TownRules.RICHESSE, TownRules.FLOOR)
	sim.advance(A_DAY * 8)
	for place: StringName in towns.ids():
		# The floor protects the places the kingdom feeds. It does not rescue a farm
		# somebody burned: the source of the food is not fed by itself, and what the
		# player ruined stays ruined until the player sees to it.
		if KingdomRules.category_of(KingdomRules.sends(place)) == KingdomRules.VIVRES:
			continue
		assert_true(towns.richesse_of(place) >= TownRules.FOOD_FLOOR,
			"%s is hungry at %d and not dead" % [place, towns.richesse_of(place)])


func test_a_settled_place_is_frozen() -> void:
	# Rule 6. The player resolved its quest: its story is told, and the weather does not
	# get to undo what was chosen.
	var sim: Sim = Game.build()
	var towns := sim.store(&"towns") as TownState
	sim.submit(&"move_town_value", {"place": "cinderworks", "value": "richesse", "direction": -1})
	sim.submit(&"settle_town", {"place": "cinderworks"})
	sim.advance(2)
	assert_eq(towns.richesse_of(&"cinderworks"), 1)
	assert_true(towns.is_settled(&"cinderworks"))
	# Make the kingdom hungry, so everywhere unsettled is being pulled.
	towns.set_value(&"wide_acres", TownRules.RICHESSE, TownRules.FLOOR)
	sim.advance(A_DAY * 4)
	assert_eq(towns.richesse_of(&"cinderworks"), 1,
		"four days later the works is exactly where the player left it")
	assert_true(towns.richesse_of(&"harrowgate") < 6,
		"while everywhere unsettled has felt the famine")


func test_helping_one_place_reaches_another_through_the_crown() -> void:
	# The whole point of the star, in one test: the works is never touched, and it ends
	# up better off because the farms did.
	var poor: Sim = Game.build()
	var poor_towns := poor.store(&"towns") as TownState
	poor_towns.set_value(&"wide_acres", TownRules.RICHESSE, TownRules.FLOOR)
	poor.advance(A_DAY * 5)

	var rich: Sim = Game.build()
	var rich_towns := rich.store(&"towns") as TownState
	rich_towns.set_value(&"wide_acres", TownRules.RICHESSE, TownRules.CEILING)
	# Saltmarch starts below the threshold and so ships the crown nothing (rule 2).
	# Feeding the kingdom means winning it back as well as growing more.
	rich_towns.set_value(&"saltmarch", TownRules.ALLEGIANCE, TownRules.CEILING)
	rich_towns.set_value(&"saltmarch", TownRules.RICHESSE, TownRules.CEILING)
	rich.advance(A_DAY * 5)

	assert_true(rich_towns.richesse_of(&"cinderworks") > poor_towns.richesse_of(&"cinderworks"),
		"fed by rich farms the works is at %d; by poor ones, %d" % [
			rich_towns.richesse_of(&"cinderworks"), poor_towns.richesse_of(&"cinderworks")])


func test_the_kingdom_never_touches_who_a_place_is_with() -> void:
	var sim: Sim = Game.build()
	var towns := sim.store(&"towns") as TownState
	var before: Dictionary = {}
	for place: StringName in towns.ids():
		before[place] = towns.allegiance_of(place)
	sim.advance(A_DAY * 3)
	for place: StringName in towns.ids():
		assert_eq(towns.allegiance_of(place), int(before[place]),
			"%s is with whoever it was with: that is the player's business alone" % place)


func test_the_whole_thing_replays() -> void:
	var sim: Sim = Game.build()
	sim.submit(&"move_town_value", {"place": "cinderworks", "value": "richesse", "direction": -1})
	sim.submit(&"settle_town", {"place": "cinderworks"})
	sim.advance(A_DAY * 2)
	var towns := sim.store(&"towns") as TownState
	var replayed: Sim = Game.replay(sim)
	assert_eq((replayed.store(&"towns") as TownState).fingerprint(), towns.fingerprint(),
		"two days of weather, rebuilt from the log alone")
