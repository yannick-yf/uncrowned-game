extends TestCase

## Phase 6b and 6c — the Wide Acres and the Muster, and the two people who can tell
## the player who they were.
##
## §5: *"recovering memory and acquiring world knowledge are the same system. A
## recovered memory is a fact in the fact base like any other."* §6 names the two
## sources of the player's past — **Old Pell**, who worked the soil and knew the
## family and does not recognise the face, and **Kell**, who was there that night on
## the wrong side. Both are reachable and neither is told to the player as a
## revelation: they are facts, learned from people, like the price of bread.


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
	sim.submit(&"end_talk")
	sim.advance(2)


func test_everybody_stands_somewhere_you_can_reach() -> void:
	var sim: Sim = _world()
	var region: Region = (sim.store(&"world") as WorldState).region()
	var cast := sim.store(&"cast") as Cast
	var where: Dictionary = {
		&"cadan": &"wide_acres", &"nessa": &"wide_acres", &"pell": &"wide_acres",
		&"ryse": &"muster", &"odile": &"muster",
	}
	for who: StringName in where.keys():
		var npc: Npc = cast.get_npc(who)
		assert_not_null(npc, "%s exists" % who)
		assert_eq(region.zone_at(npc.tile), where[who], "%s is where §6 puts them" % who)
		assert_true(region.is_passable(npc.tile), "%s is not inside a wall" % who)

	var kell: Npc = cast.get_npc(&"kell")
	assert_eq(region.terrain_at(kell.tile), Region.Terrain.FOREST, "Kell is in the Thornwood")
	assert_eq(region.zone_at(kell.tile), &"", "and not in any town, which is the point of him")


func test_a_man_in_a_wood_has_a_fire_you_can_see() -> void:
	# Otherwise "he is out in the Thornwood" is an instruction to search a forest.
	var region: Region = Region.build_overworld()
	var kell: Vector2i = Cast.shared().get_npc(&"kell").tile
	var nearest: float = 1000.0
	for prop: Dictionary in region.props:
		if (prop["kind"] as StringName) == &"campfire":
			nearest = minf(nearest, Vector2(kell).distance_to(Vector2(prop["at"] as Vector2i)))
	assert_true(nearest < 4.0, "the nearest fire to Kell is %.0f tiles away" % nearest)


func test_you_are_told_where_kell_is_before_you_can_find_him() -> void:
	var sim: Sim = _world()
	assert_false(sim.facts.has(&"thornwood:kell"), "you do not start knowing")
	_say(sim, &"ask_deserter") if _talk(sim, &"maddox").has("ask_deserter") else _hunt(sim)
	assert_true(sim.facts.has(&"thornwood:kell"), "and somebody tells you")


## Maddox knows more than three things and §9 shows three, so the line may be behind
## another. Ask past it — which is the spent-question rule doing its job.
func _hunt(sim: Sim) -> void:
	for _round: int in 5:
		var offered: Array[String] = _talk(sim, &"maddox")
		if offered.has("ask_deserter"):
			_say(sim, &"ask_deserter")
			return
		if offered.is_empty():
			return
		_say(sim, StringName(offered[0]))


func test_old_pell_tells_you_what_the_ground_was_without_knowing_who_he_is_telling() -> void:
	var sim: Sim = _world()
	assert_true(_talk(sim, &"pell").has("ask_soil"), "he will talk about the soil to anybody")
	_say(sim, &"ask_soil")
	assert_true(sim.facts.has(&"brindle:the_ground"), "and it is a fact like any other")

	# The line about the family is there and teaches nothing. It is not a mechanism;
	# it is the scene, and he does not recognise the face he is describing it to.
	var cast := sim.store(&"cast") as Cast
	for option: DialogueOption in cast.get_npc(&"pell").options:
		if option.intent == &"ask_family":
			assert_eq(option.teaches, &"", "the family is not a key, it is a person")


func test_kell_was_there_and_ryse_ordered_it() -> void:
	# Invariant 6 on the most important fact in the player's own story: the witness
	# and the man who sent him both hold it, and Ryse's is the one nothing can gate
	# shut — he sleeps fine and does not think it needs hiding.
	var cast := Cast.shared()
	var sources: Array[String] = []
	var ungated: Array[String] = []
	for id: StringName in cast.npcs.keys():
		for option: DialogueOption in cast.get_npc(id).options:
			if option.teaches != &"brindle:that_night":
				continue
			sources.append(String(id))
			if not option.asks_for_goodwill():
				ungated.append(String(id))
	sources.sort()
	assert_eq(sources, ["kell", "ryse"], "the witness and the commander")
	assert_eq(ungated, ["ryse"], "and the commander is the one who says it to anybody")


func test_how_arthur_fights_is_sold_cheaply_by_the_woman_running_a_fraud() -> void:
	# §20 made Ryse primary and Odile second. She gives it away because it costs her
	# nothing, which is exactly why the route through her stays open when he closes.
	var sim: Sim = _world()
	assert_true(_talk(sim, &"odile").has("ask_king"), "she will discuss it")
	_say(sim, &"ask_king")
	assert_true(sim.facts.has(&"muster:how_the_king_fights"),
		"Route A's one knowledge requirement, from the cheapest source in the camp")


func test_two_more_levers_that_are_things_you_say() -> void:
	var sim: Sim = _world()
	var ticked := sim.store(&"worldtick") as WorldTick

	# The Wide Acres: a withholding needs a reason a farmer can say out loud.
	assert_false(_talk(sim, &"pell").has("ask_withhold"), "no reason yet")
	sim.submit(&"end_talk")
	sim.advance(2)
	_talk(sim, &"nessa")
	_say(sim, &"ask_names")
	assert_true(_talk(sim, &"pell").has("ask_withhold"), "and now there is one")
	_say(sim, &"ask_withhold")
	assert_true(ticked.crown_treasury < WorldTick.BASELINE, "the harvest stays in the barn")

	# The Muster: deserters come in for somebody who already knows what they did.
	_talk(sim, &"kell")
	_say(sim, &"ask_that_night")
	var army: float = ticked.army_strength
	_talk(sim, &"kell")
	_say(sim, &"ask_recruit")
	assert_true(ticked.army_strength < army, "and eleven men he knows by name walk")
	assert_true(ticked.handprint_on(&"army_strength") > 0.0, "with your hand on it")
