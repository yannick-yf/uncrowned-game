extends TestCase

## Who the player chose to be.
##
## **Four traits, a pool of 8, a floor of 1 and a cap of 5** (S1, 2026-09-28; the
## simulation model's own list). At 4 points to take a trait from 1 to 5, eight buys
## exactly two specialisms and nothing else — or one at 5 and two at 3, or a flat
## spread. The six traits and the pool of 10 went with it.


func test_there_are_four_traits() -> void:
	assert_eq(TraitRules.ALL, [TraitRules.STRENGTH, TraitRules.INTELLIGENCE,
		TraitRules.AGILITY, TraitRules.PRESENCE] as Array[StringName],
		"Force, Intelligence, Agilité, Prestance, in that order")
	assert_eq(TraitRules.POOL, 8)
	assert_eq(TraitRules.FLOOR, 1)
	assert_eq(TraitRules.CAP, 5)


func test_the_pool_buys_two_specialisms_and_nothing_else() -> void:
	var two_maxed: Dictionary = TraitRules.at_the_floor()
	two_maxed[TraitRules.INTELLIGENCE] = 5
	two_maxed[TraitRules.PRESENCE] = 5
	assert_eq(TraitRules.spent(two_maxed), 8, "two specialisms cost all 8")
	assert_true(TraitRules.is_legal(two_maxed), "and are legal")

	var one_more: Dictionary = two_maxed.duplicate()
	one_more[TraitRules.STRENGTH] = 2
	assert_eq(TraitRules.spent(one_more), 9, "a ninth point")
	assert_eq(TraitRules.why_not(one_more), &"creation.overspent", "is refused, with the reason")


func test_nothing_can_be_created_outside_the_floor_and_the_cap() -> void:
	var over: Dictionary = TraitRules.at_the_floor()
	over[TraitRules.STRENGTH] = 6
	assert_eq(TraitRules.why_not(over), &"creation.out_of_range")
	var under: Dictionary = TraitRules.at_the_floor()
	under[TraitRules.STRENGTH] = 0
	assert_eq(TraitRules.why_not(under), &"creation.out_of_range")


func test_a_trait_the_game_no_longer_has_is_ignored() -> void:
	# A save from before S1 carries `wits` and `attunement`. The character is still
	# made — at the floor for whatever it did not name — rather than the save refused.
	var traits := Traits.new()
	assert_true(traits.choose({"wits": 5, "attunement": 5}), "an old character still loads")
	for what: StringName in TraitRules.ALL:
		assert_eq(traits.level_of(what), TraitRules.FLOOR, "%s at the floor" % what)


func test_a_character_is_made_by_one_event_and_replays() -> void:
	# Creation is an ordinary external event, so it is in the save and a reload
	# rebuilds the same person. There is nothing else to persist.
	var sim: Sim = Game.build()
	var traits := sim.store(&"traits") as Traits
	assert_false(traits.chosen, "nobody has been asked yet")
	sim.submit(&"create_character", {"intelligence": 4, "agility": 3})
	sim.advance(2)
	assert_true(traits.chosen, "and now they have")
	assert_eq(traits.level_of(TraitRules.INTELLIGENCE), 4)
	assert_eq(traits.level_of(TraitRules.STRENGTH), TraitRules.FLOOR, "the rest sit at the floor")

	var replayed: Sim = Game.replay(sim)
	assert_eq((replayed.store(&"traits") as Traits).fingerprint(), traits.fingerprint(),
		"the same person, rebuilt from the log")


func test_an_illegal_character_is_refused_and_nothing_changes() -> void:
	var sim: Sim = Game.build()
	var traits := sim.store(&"traits") as Traits
	sim.submit(&"create_character", {"intelligence": 5, "presence": 5, "strength": 2})
	sim.advance(2)
	assert_false(traits.chosen, "nine points, so nobody was made")
	assert_eq(traits.level_of(TraitRules.INTELLIGENCE), TraitRules.FLOOR, "and nothing was written")


# --------------------------------------------------------- what they do ---

func test_a_line_that_leans_on_a_trait_needs_the_trait() -> void:
	# §11 always meant `tag` to be the Fallout marker; it was display-only because
	# traits did not exist. Ossa's "why do they run" leans on Intelligence.
	var cast: Cast = Cast.shared()
	var ossa: Npc = cast.get_npc(&"ossa")
	var option: DialogueOption = DialogueRules.find(ossa, &"ask_why")
	assert_eq(option.needs_trait(), TraitRules.INTELLIGENCE, "the tag names the trait")

	var facts := FactBase.new()
	var dull := Traits.new()
	var sharp := Traits.new()
	sharp.choose({TraitRules.INTELLIGENCE: TraitRules.SPEAKS_AT})
	assert_false(DialogueRules.available(ossa, facts, {}, 0.0, dull).has(option),
		"somebody who does not notice things is not offered it")
	assert_true(DialogueRules.available(ossa, facts, {}, 0.0, sharp).has(option),
		"and somebody who does is")


func test_no_fact_can_be_reached_only_by_a_trait() -> void:
	# Invariant 7, applied to the newest kind of gate. A character created at the
	# floor of all four has to be able to finish the game, so every fact needs a
	# teacher whose line leans on nothing.
	var cast: Cast = Cast.shared()
	var plainly_taught: Dictionary = {}
	var taught_at_all: Dictionary = {}
	for id: StringName in cast.npcs.keys():
		for option: DialogueOption in cast.get_npc(id).options:
			if option.teaches == &"":
				continue
			taught_at_all[option.teaches] = true
			if option.needs_trait() == &"":
				plainly_taught[option.teaches] = true
	for fact: StringName in taught_at_all.keys():
		assert_true(plainly_taught.has(fact),
			"'%s' can only be learned by somebody with the right trait" % fact)


func test_every_trait_has_a_name_and_a_note_in_both_languages() -> void:
	for language: String in ["en", "fr"]:
		var known: Array[String] = Text.keys_for(language)
		for what: StringName in TraitRules.ALL:
			assert_true(known.has(String(TraitRules.name_key(what))),
				"%s: %s" % [language, TraitRules.name_key(what)])
			assert_true(known.has(String(TraitRules.note_key(what))),
				"%s: %s" % [language, TraitRules.note_key(what)])
