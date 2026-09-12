extends TestCase

## Phase 6a — the Cinderworks gets its three people.
##
## The first town where the cast carries something mechanical rather than flavour,
## and the first place §5's argument is spoken by somebody who believes it.
##
## §5: *"Route C only works if his argument is real. Exposing a pantomime villain is
## not a climax."* Halgrave is that argument at human scale — he gives you the
## number that damns Arthur **freely, to anyone**, because he is not ashamed of it
## and thinks the record matters. That is not decoration; it is why his line is the
## one source of the fact that nothing can gate shut.

const TOLL: StringName = &"cinderworks:death_toll"


func _world() -> Sim:
	return Game.build()


func _talk(sim: Sim, who: StringName) -> Array[String]:
	var world := sim.store(&"world") as WorldState
	world.player_pos = (sim.store(&"cast") as Cast).get_npc(who).centre()
	sim.submit(&"talk", {"npc": String(who)})
	sim.advance(2)
	var out: Array[String] = []
	for option: DialogueOption in world.options:
		out.append(String(option.intent))
	return out


func _say(sim: Sim, intent: StringName) -> void:
	sim.submit(&"choose_intent", {"intent": String(intent)})
	sim.advance(4)


func test_three_people_stand_in_the_works() -> void:
	var sim: Sim = _world()
	var region: Region = (sim.store(&"world") as WorldState).region()
	var cast := sim.store(&"cast") as Cast
	for who: StringName in [&"halgrave", &"sena", &"ivo"]:
		var npc: Npc = cast.get_npc(who)
		assert_not_null(npc, "%s exists" % who)
		assert_eq(region.zone_at(npc.tile), &"cinderworks", "%s stands in the works" % who)
		assert_true(region.is_passable(npc.tile), "%s is not inside a furnace" % who)


func test_the_toll_has_three_sources_and_one_of_them_tells_anybody() -> void:
	# Invariant 6, and characterisation doing the same job. Sena and Marsh both
	# hold it back from somebody they mistrust; Halgrave does not, because he does
	# not think it is damning. That is what keeps the fact reachable however badly
	# the player has behaved.
	var cast := Cast.shared()
	var sources: Array[String] = []
	var ungated: Array[String] = []
	for id: StringName in cast.npcs.keys():
		for option: DialogueOption in cast.get_npc(id).options:
			if option.teaches != TOLL:
				continue
			sources.append(String(id))
			if not option.asks_for_goodwill():
				ungated.append(String(id))
	assert_eq(sources.size(), 3, "three people know what the works cost: %s" % str(sources))
	assert_eq(ungated, ["halgrave"], "and the foreman is the one who says it to anybody")


func test_halgrave_gives_you_the_number_that_damns_the_king() -> void:
	var sim: Sim = _world()
	assert_true(_talk(sim, &"halgrave").has("ask_cost"), "he is asked what it cost")
	_say(sim, &"ask_cost")
	assert_true(sim.facts.has(TOLL), "and he answers without being made to")
	assert_true(Cast.shared().fact_descriptions[TOLL].contains("Arthur"),
		"the count went to the king by name, every year")


func test_sena_needs_a_number_before_she_will_move() -> void:
	# "A man will not walk off a shift for a feeling." The line does not exist
	# until you have something to give her.
	var sim: Sim = _world()
	assert_false(_talk(sim, &"sena").has("ask_organise"), "nothing to organise around yet")

	sim.submit(&"end_talk")
	sim.advance(2)
	_talk(sim, &"halgrave")
	_say(sim, &"ask_cost")
	sim.submit(&"end_talk")
	sim.advance(2)
	assert_true(_talk(sim, &"sena").has("ask_organise"), "and now there is")


func test_turning_the_workers_is_a_thing_you_say() -> void:
	# §3 lists "turn the workers" as a lever against the Cinderworks and every
	# lever until now was a thing you break. This one is a conversation.
	var sim: Sim = _world()
	var ticked := sim.store(&"worldtick") as WorldTick
	var standing := sim.store(&"standing") as Standing
	_talk(sim, &"halgrave")
	_say(sim, &"ask_cost")
	sim.submit(&"end_talk")
	sim.advance(2)
	_talk(sim, &"sena")
	_say(sim, &"ask_organise")

	assert_true(ticked.worker_morale < WorldTick.NEUTRAL, "the works stops believing in itself")
	assert_true(ticked.steel_output < WorldTick.BASELINE, "and makes less")
	assert_true(ticked.handprint_on(&"worker_morale") > 0.0,
		"with the player's hand on it, or no ending will count it")
	assert_true(standing.with_faction(DeedRules.FACTION_CROWN) < 0.0, "the crown minds")
	assert_true(standing.with_faction(DeedRules.FACTION_DISPOSSESSED) > 0.0,
		"and the people it used up do not")


func test_nobody_at_the_works_hands_over_the_ledger() -> void:
	# §7's Q24: documents lie in places. Three people can tell you what the ledger
	# says and none of them can give it to you, so killing all three destroys no
	# evidence — only the easy way of finding out it exists.
	var cast := Cast.shared()
	for who: StringName in [&"halgrave", &"sena", &"ivo"]:
		for option: DialogueOption in cast.get_npc(who).options:
			assert_false(DocumentRules.is_document(option.teaches),
				"%s hands over a document, which a death could then destroy" % who)
