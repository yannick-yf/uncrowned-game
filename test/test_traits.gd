extends TestCase

## Who the player chose to be.
##
## §11's six traits, a pool of 10 and a cap of 5 — closing §19 Q6 and Q22. Q22's
## complaint was that no pool size forces a count, only a cap does: at 4 points to
## take a trait from 1 to 5, twelve buys *three* maxed traits and leaves three at the
## floor, which is a shopping list rather than a choice. Ten buys two at 5 with two
## spare, or one at 5 and two at 3, or a flat spread — three different people.


func test_the_pool_forces_a_choice_rather_than_a_shopping_list() -> void:
	var two_maxed: Dictionary = TraitRules.at_the_floor()
	two_maxed[TraitRules.WITS] = 5
	two_maxed[TraitRules.PRESENCE] = 5
	assert_eq(TraitRules.spent(two_maxed), 8, "two specialisms cost 8 of 10")
	assert_true(TraitRules.is_legal(two_maxed), "and are legal")

	var three_maxed: Dictionary = two_maxed.duplicate()
	three_maxed[TraitRules.HANDS] = 5
	assert_false(TraitRules.is_legal(three_maxed), "three are not")


func test_nothing_can_be_created_outside_the_floor_and_the_cap() -> void:
	var over: Dictionary = TraitRules.at_the_floor()
	over[TraitRules.BODY] = 6
	assert_eq(TraitRules.why_not(over), &"creation.out_of_range")
	var under: Dictionary = TraitRules.at_the_floor()
	under[TraitRules.BODY] = 0
	assert_eq(TraitRules.why_not(under), &"creation.out_of_range")


func test_a_character_is_made_by_one_event_and_replays() -> void:
	# Creation is an ordinary external event, so it is in the save and a reload
	# rebuilds the same person. There is nothing else to persist.
	var sim: Sim = Game.build()
	var traits := sim.store(&"traits") as Traits
	assert_false(traits.chosen, "nobody has been asked yet")
	sim.submit(&"create_character", {"wits": 4, "attunement": 3})
	sim.advance(2)
	assert_true(traits.chosen, "and now they have")
	assert_eq(traits.level_of(TraitRules.WITS), 4)
	assert_eq(traits.level_of(TraitRules.BODY), TraitRules.FLOOR, "the rest sit at the floor")

	var replayed: Sim = Game.replay(sim)
	assert_eq((replayed.store(&"traits") as Traits).fingerprint(), traits.fingerprint(),
		"the same person, rebuilt from the log")


func test_an_illegal_character_is_refused_and_nothing_changes() -> void:
	var sim: Sim = Game.build()
	var traits := sim.store(&"traits") as Traits
	sim.submit(&"create_character", {"wits": 5, "presence": 5, "hands": 5})
	sim.advance(2)
	assert_false(traits.chosen, "overspent, so nobody was made")
	assert_eq(traits.level_of(TraitRules.WITS), TraitRules.FLOOR, "and nothing was written")


# --------------------------------------------------------- what they do ---

func test_a_line_that_leans_on_a_trait_needs_the_trait() -> void:
	# §11 always meant `tag` to be the Fallout marker; it was display-only because
	# traits did not exist. Ossa's "why do they run" leans on Wits.
	var cast: Cast = Cast.shared()
	var ossa: Npc = cast.get_npc(&"ossa")
	var option: DialogueOption = DialogueRules.find(ossa, &"ask_why")
	assert_eq(option.needs_trait(), TraitRules.WITS, "the tag names the trait")

	var facts := FactBase.new()
	var dull := Traits.new()
	var sharp := Traits.new()
	sharp.choose({TraitRules.WITS: TraitRules.SPEAKS_AT})
	assert_false(DialogueRules.available(ossa, facts, {}, 0.0, dull).has(option),
		"somebody who does not notice things is not offered it")
	assert_true(DialogueRules.available(ossa, facts, {}, 0.0, sharp).has(option),
		"and somebody who does is")


func test_no_fact_can_be_reached_only_by_a_trait() -> void:
	# Invariant 7, applied to the newest kind of gate. A character created at the
	# floor of all six has to be able to finish the game, so every fact needs a
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


func test_the_wood_does_not_slow_an_attuned_walker_as_much() -> void:
	# §11's second half of Attunement (2026-09-13, Q50). At the tag threshold and not
	# below, because "you put points here" means one thing for all six.
	var forest_build: Dictionary = TraitRules.at_the_floor()
	forest_build[TraitRules.ATTUNEMENT] = TraitRules.SPEAKS_AT
	var traits := Traits.new()
	assert_true(traits.choose(forest_build))
	assert_true(traits.is_attuned(), "3 is attuned")
	forest_build[TraitRules.ATTUNEMENT] = TraitRules.SPEAKS_AT - 1
	assert_true(traits.choose(forest_build))
	assert_false(traits.is_attuned(), "2 is not")

	var plain: float = MovementRules.multiplier_for(Region.Terrain.FOREST, false)
	var attuned: float = MovementRules.multiplier_for(Region.Terrain.FOREST, true)
	assert_true(attuned > plain, "the wood costs them less: %.2f against %.2f" % [attuned, plain])
	assert_true(attuned < 1.0, "but it is still a wood, not a road")
	assert_true(absf(MovementRules.multiplier_for(Region.Terrain.MARSH, true)
		- MovementRules.multiplier_for(Region.Terrain.MARSH, false)) < 0.001,
		"a marsh is a marsh whoever you are")
