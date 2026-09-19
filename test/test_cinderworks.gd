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


# ------------------------------------------------- the quest's two sides (Q2) ---
#
# **Two people, and either one starts it.** `docs/QUEST_CINDERWORKS.md`: each tells the
# player about the other, so no single death makes the quest unreachable — invariant 6
# for a route that is a conversation rather than a paper.
#
# **Tom is the only person Q2 adds.** The worker the quest wanted is Sena, who already
# stands at the works, and her sheet makes the part better than the draft did: a woman
# who left her hand in furnace four and still says the fires must not go out is a
# stronger argument for the works than somebody merely glad of the money.

const TOM_DOWN: StringName = &"cinderworks:tom_wants_it_down"
const SENA_KEEP: StringName = &"cinderworks:sena_wants_it_kept"


func test_both_sides_of_the_works_are_people_you_can_find() -> void:
	var sim: Sim = _world()
	var cast := sim.store(&"cast") as Cast
	var region: Region = (sim.store(&"world") as WorldState).region()
	for who: StringName in [&"tom", &"sena"]:
		var npc: Npc = cast.get_npc(who)
		assert_not_null(npc, "%s stands somewhere" % who)
		var at: Vector2i = Vector2i(npc.centre())
		assert_true(region.is_passable(at), "%s can be walked up to: %s" % [who, str(at)])
		if Places.baked():
			assert_false(region.wards.has(at),
				"%s is not standing in the gateway" % who)

	# Not in the same breath: finding one has to be a different walk from finding the
	# other, or "two people" is one conversation with two names on it.
	var apart: float = cast.get_npc(&"tom").centre().distance_to(cast.get_npc(&"sena").centre())
	assert_true(apart > 6.0, "and they are not side by side: %.0f tiles apart" % apart)


func test_neither_of_them_is_the_only_way_in() -> void:
	# The check that matters: kill either and the other still names them. A quest whose
	# two halves are each reachable only through themselves has one half.
	var sim: Sim = _world()
	var from_tom: Array[String] = _talk(sim, &"tom")
	assert_true(from_tom.has("ask_tom_other"), "Tom will talk about her: %s" % str(from_tom))
	_say(sim, &"ask_tom_other")
	assert_true(sim.facts.has(SENA_KEEP), "and saying it is how you learn she exists")

	# **She names him in a line she already had**, and that is not a shortcut. The
	# dialogue box holds three lines; Sena had three, and every one she gains pushes one
	# out — the first attempt pushed `ask_organise`, which a route needs, out of reach
	# entirely and two old tests said so at once. Her hand is her position, so Tom
	# belongs in the same breath.
	var other: Sim = _world()
	var from_sena: Array[String] = _talk(other, &"sena")
	assert_true(from_sena.has("ask_hand"), "she will talk about her hand: %s" % str(from_sena))
	var line: DialogueOption = DialogueRules.find(
		(other.store(&"cast") as Cast).get_npc(&"sena"), &"ask_hand")
	assert_true(line.reply.contains("Tom"), "and Tom is in the answer: %s" % line.reply)
	_say(other, &"ask_hand")
	assert_true(other.facts.has(SENA_KEEP), "which is also where she says where she stands")


func test_what_each_of_them_wants_is_learnable_from_them() -> void:
	var sim: Sim = _world()
	_talk(sim, &"tom")
	_say(sim, &"ask_tom_pay")
	assert_true(sim.facts.has(TOM_DOWN), "Tom says what he wants")

	var other: Sim = _world()
	_talk(other, &"sena")
	_say(other, &"ask_hand")
	assert_true(other.facts.has(SENA_KEEP), "and she says what she wants")


func test_the_line_that_names_the_other_is_never_refused() -> void:
	# **Marked `costs: free`, and that is invariant 6 again.** Everything that teaches a
	# fact asks for goodwill by default, and a player the works already dislikes would
	# otherwise be unable to learn that the other side exists — which would close the
	# quest by being rude rather than by anything a player could see.
	var cast := Cast.shared()
	for pair: Array in [[&"tom", &"ask_tom_other"], [&"sena", &"ask_hand"]]:
		var option: DialogueOption = DialogueRules.find(
			cast.get_npc(pair[0] as StringName), pair[1] as StringName)
		assert_not_null(option, "%s has the line" % pair[0])
		assert_false(option.asks_for_goodwill(),
			"%s names the other whatever they think of you" % pair[0])
