extends TestCase

## §7's Q24, settled: a document is **both** — reading it is knowledge, holding it
## is proof, and they are not the same thing.
##
## The rule that matters most is where they live. **Documents lie in places, not in
## people.** A paper does not die with whoever owned it, so killing every named
## person in the kingdom cannot destroy evidence — it can only cost you the person
## who would have told you where to look. That is what makes invariant 7 structural
## rather than hopeful, and it is the same lesson the power bases taught: a place
## cannot be murdered.


func _world() -> Sim:
	var sim := Sim.new()
	sim.add_store(&"world", Game.build_world())
	sim.add_store(&"cast", Cast.shared())
	sim.add_store(&"worldtick", WorldTick.new())
	sim.add_store(&"standing", Standing.new())
	sim.add_store(&"rumours", Rumours.new())
	sim.add_system(WorldTickSystem.new())
	sim.add_system(ActSystem.new())
	sim.add_system(TellingSystem.new())
	sim.add_system(RumourSystem.new())
	sim.add_system(EndingSystem.new())
	return sim


func _take_all(sim: Sim) -> void:
	var world := sim.store(&"world") as WorldState
	for prop: Dictionary in world.region().props:
		if (prop["kind"] as StringName) != &"papers":
			continue
		world.player_pos = Vector2(prop["at"] as Vector2i) + Vector2(0.5, 0.5)
		sim.submit(&"act")
		sim.advance(3)


func test_every_break_in_his_argument_has_a_document() -> void:
	# §5 lists where the king's argument breaks and §3 says what proves each. Before
	# Q18 the debts rebutted nothing and the tiered law — the break §5 calls the one
	# that gives him away — had no document at all.
	var breaks: Array[String] = []
	for row: Dictionary in DocumentRules.all():
		var name: String = String(row["breaks"])
		assert_false(breaks.has(name), "two documents both answer '%s'" % name)
		breaks.append(name)
	assert_true(breaks.size() >= 5, "five breaks, five documents: %d" % breaks.size())


func test_a_document_is_knowledge_and_proof_at_once() -> void:
	var sim: Sim = _world()
	var world := sim.store(&"world") as WorldState
	assert_eq(world.documents.size(), 0, "you start with nothing")

	_take_all(sim)
	assert_eq(world.documents.size(), DocumentRules.all().size(), "all of it in your hands")
	for fact: StringName in DocumentRules.facts():
		assert_true(sim.facts.has(fact), "and you have read %s" % fact)
		assert_true(world.holds(fact), "and you are carrying it")


func test_they_lie_in_places_and_not_in_people() -> void:
	# The guarantee. Nobody in the cast holds one, so no death removes one.
	var sim: Sim = _world()
	var cast := sim.store(&"cast") as Cast
	var on_the_map: int = 0
	for prop: Dictionary in (sim.store(&"world") as WorldState).region().props:
		if (prop["kind"] as StringName) == &"papers":
			on_the_map += 1
	assert_eq(on_the_map, DocumentRules.all().size(), "every document is somewhere you can walk")

	for id: StringName in cast.npcs.keys():
		for option: DialogueOption in cast.get_npc(id).options:
			assert_false(DocumentRules.is_document(option.teaches),
				"%s hands over a document in conversation — killing them would destroy it" % id)


func test_nothing_takes_one_off_you() -> void:
	# Yannick's call, and §7's: evidence that can be lost is a route that can be
	# closed. Guarded at the source — no code anywhere removes from the list.
	var sim: Sim = _world()
	var world := sim.store(&"world") as WorldState
	_take_all(sim)
	var carried: int = world.documents.size()

	# Everything the world can do to you, done to you.
	world.player_pos = at_a_stall()
	sim.submit(&"steal"); sim.advance(3)
	sim.submit(&"act"); sim.advance(3)
	sim.advance_world_ticks(Game.TICKS_PER_IN_GAME_DAY * 5)
	assert_eq(world.documents.size(), carried, "you still have all of it")


func test_your_word_alone_is_not_evidence() -> void:
	# Knowing is not proving. Somebody who has heard about the ledger cannot make
	# the kingdom believe it; somebody holding the ledger can.
	var sim: Sim = _world()
	var world := sim.store(&"world") as WorldState
	sim.facts.add_source(DocumentRules.WORKS_LEDGER, &"hearsay")
	assert_eq(TellingRules.tellable_document(
		&"harrowgate", PackedStringArray(["maddox"]), world, sim.facts), &"",
		"you know it and you cannot prove it")

	_take_all(sim)
	assert_ne(TellingRules.tellable_document(
		&"harrowgate", PackedStringArray(["maddox"]), world, sim.facts), &"",
		"and now you are holding it")


func test_you_cannot_read_it_out_to_an_empty_room() -> void:
	var sim: Sim = _world()
	var world := sim.store(&"world") as WorldState
	_take_all(sim)
	assert_eq(TellingRules.tellable_document(
		&"harrowgate", PackedStringArray(), world, sim.facts), &"",
		"proof with nobody to show it to is not an act")


func test_a_document_is_read_out_once() -> void:
	var sim: Sim = _world()
	var world := sim.store(&"world") as WorldState
	_take_all(sim)
	for i: int in 3:
		world.player_pos = in_town(&"harrowgate")
		sim.submit(&"tell_town")
		sim.advance(3)
	assert_eq(EndRules.public_facts(sim.facts), 3,
		"three readings, three things the kingdom now knows — not one thing three times")
