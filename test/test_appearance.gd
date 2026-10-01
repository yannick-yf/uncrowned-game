extends TestCase

## What the player chose to look like (group A): five choices on the creation event, kept
## by a store a replay rebuilds, and never read by anything that decides.

const SLOW: bool = false


func _blond() -> Dictionary:
	return {&"hair_style": &"long", &"hair_colour": &"blond", &"skin": &"olive", &"beard": &"short", &"clothes": &"moss"}


func test_the_options_are_the_table_s_and_the_default_is_his_traveller() -> void:
	for choice: StringName in AppearanceRules.ALL:
		assert_true(AppearanceRules.options(choice).size() >= 4, "%s has its options" % choice)
	var his: Dictionary = AppearanceRules.default_appearance()
	assert_eq(his[&"hair_style"], &"spiky", "his own hair")
	assert_eq(his[&"hair_colour"], &"red", "red")
	assert_eq(his[&"beard"], &"none", "no beard")
	assert_eq(AppearanceRules.options(&"hair_style").size(), 6, "six styles, as Yannick settled")
	assert_eq(AppearanceRules.options(&"hair_colour").size(), 8, "eight colours")
	assert_eq(AppearanceRules.options(&"skin").size(), 5, "five skins")
	assert_eq(AppearanceRules.options(&"beard").size(), 4, "four beards")
	assert_eq(AppearanceRules.options(&"clothes").size(), 6, "six colours of clothes")


func test_the_appearance_rides_the_creation_event_and_replays() -> void:
	var sim: Sim = Game.begin_run(TraitRules.at_the_floor(), Sim.DEFAULT_SEED, _blond())
	var looks := sim.store(&"appearance") as Appearance
	assert_eq(looks.of(&"hair_colour"), &"blond", "chosen at creation")
	assert_eq(looks.of(&"beard"), &"short", "the beard too")
	var again: Sim = Game.replay(sim)
	assert_eq((again.store(&"appearance") as Appearance).fingerprint(), looks.fingerprint(),
		"a replay rebuilds the same person")


func test_a_run_from_before_the_appearance_is_his_traveller() -> void:
	# A save written before group A carries traits and nothing else on its creation event.
	var sim: Sim = Game.build()
	var data: Dictionary = {}
	for what: StringName in TraitRules.ALL:
		data[String(what)] = TraitRules.FLOOR
	sim.submit(&"create_character", data)
	sim.advance(1)
	assert_true((sim.store(&"traits") as Traits).chosen, "the character is made")
	assert_eq((sim.store(&"appearance") as Appearance).chosen(), AppearanceRules.default_appearance(),
		"and looks like his brother's traveller")


func test_a_look_that_does_not_exist_is_refused_and_nothing_is_made() -> void:
	var sim: Sim = Game.build()
	var data: Dictionary = {"strength": 3, "intelligence": 3, "agility": 2, "presence": 2,
		"hair_style": "mohawk"}
	sim.submit(&"create_character", data)
	sim.advance(1)
	assert_false((sim.store(&"traits") as Traits).chosen, "no character made")
	assert_eq((sim.store(&"traits") as Traits).level_of(&"strength"), TraitRules.FLOOR, "the traits untouched")
	assert_eq((sim.store(&"appearance") as Appearance).chosen(), AppearanceRules.default_appearance(), "nor the look")
	var refused: bool = false
	for event: SimEvent in sim.events.all():
		if event.type == &"creation_refused" and String(event.data.get("why", "")) == "creation.no_such_look":
			refused = true
	assert_true(refused, "and the refusal says why")
	assert_true(Text.of(&"creation.no_such_look") != "creation.no_such_look", "in words")


func test_the_window_draws_what_was_chosen() -> void:
	var slots: Dictionary = PaperDoll.slots_for(_blond())
	assert_eq(slots[&"hair"]["part"], &"hair_long", "the long hair")
	assert_eq(slots[&"beard"]["part"], &"beard_short", "the short beard")
	assert_eq(slots[&"beard"]["recolour"], slots[&"hair"]["recolour"], "in the hair's colour")

