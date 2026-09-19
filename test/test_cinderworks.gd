extends TestCase

## Phase 6a — the Cinderworks gets its three people.
##
## The first town where the cast carries something mechanical rather than flavour,
## and the first place §5's argument is spoken by somebody who believes it.
##
## §5: *"Route C only works if his argument is real. Exposing a pantomime villain is
## not a climax."* Harry is that argument at human scale — he gives you the
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
	for who: StringName in [&"harry", &"sena", &"ivo"]:
		var npc: Npc = cast.get_npc(who)
		assert_not_null(npc, "%s exists" % who)
		assert_eq(region.zone_at(npc.tile), &"cinderworks", "%s stands in the works" % who)
		assert_true(region.is_passable(npc.tile), "%s is not inside a furnace" % who)


func test_the_toll_has_three_sources_and_one_of_them_tells_anybody() -> void:
	# Invariant 6, and characterisation doing the same job. Sena and Marsh both
	# hold it back from somebody they mistrust; Harry does not, because he does
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
	assert_eq(ungated, ["harry"], "and the foreman is the one who says it to anybody")


func test_harry_gives_you_the_number_that_damns_the_king() -> void:
	var sim: Sim = _world()
	assert_true(_talk(sim, &"harry").has("ask_cost"), "he is asked what it cost")
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
	_talk(sim, &"harry")
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
	_talk(sim, &"harry")
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
	for who: StringName in [&"harry", &"sena", &"ivo"]:
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


# --------------------------------------------- choosing a side gets you in (Q3) ---
#
# **Choosing is what opens the gate.** The yard's way in is a man (Q1, `WardRules`), and
# what gets you past him is a fact somebody gave you: Tom brings you through a way he
# knows, Sena answers for you at the gate. Two keys, so a death does not close the works.
#
# The *words* of these two lines are Yannick's (P2). What is tested here is their shape.

const BROUGHT: StringName = &"cinderworks:brought_through"
const VOUCHED: StringName = &"cinderworks:vouched_for"


func _a_furnace_tile() -> Vector2i:
	var region: Region = Region.build_overworld()
	for prop: Dictionary in region.props:
		if String(prop["kind"]) == "kiln":
			return prop["at"] as Vector2i
	return Vector2i(-1, -1)


func test_you_cannot_take_a_side_before_you_know_what_it_is() -> void:
	# A player who has said nothing to him cannot offer to help him do a thing he has
	# not said he wants. It is also what frees the slot: the box holds three lines, and
	# the one that taught you is spent by the time this one appears.
	var sim: Sim = _world()
	assert_false(_talk(sim, &"tom").has("side_with_tom"), "nothing to take sides about yet")
	_say(sim, &"ask_tom_pay")
	assert_true(sim.facts.has(TOM_DOWN), "now he has said what he wants")
	assert_true(_talk(sim, &"tom").has("side_with_tom"), "and now you can offer")


func test_taking_one_side_closes_the_other() -> void:
	var sim: Sim = _world()
	_talk(sim, &"tom")
	_say(sim, &"ask_tom_pay")
	_say(sim, &"side_with_tom")
	assert_true(sim.facts.has(BROUGHT), "Tom brings you through")

	sim.submit(&"end_talk")
	sim.advance(2)
	_talk(sim, &"sena")
	_say(sim, &"ask_hand")
	assert_false(_talk(sim, &"sena").has("side_with_sena"),
		"and she is not going to vouch for Tom's man")


func test_either_side_is_a_key_to_the_yard() -> void:
	if not Places.baked():
		debt("the yard is the baked world's")
		return
	for taking: StringName in [BROUGHT, VOUCHED]:
		var sim: Sim = _world()
		var region: Region = (sim.store(&"world") as WorldState).region()
		var gate: Vector2i = region.wards.keys()[0] as Vector2i
		assert_false(WardRules.opens(region.wards[gate] as StringName, sim.facts),
			"shut to a stranger")
		sim.facts.add_source(taking, &"witnessed")
		assert_true(WardRules.opens(region.wards[gate] as StringName, sim.facts),
			"and %s opens it" % taking)


func test_neither_side_refuses_you_for_being_disliked() -> void:
	# **Invariant 6.** Both of them want something from the player: Tom needs somebody to
	# help him, Sena needs a number. Neither is doing a favour, and if both were behind a
	# goodwill gate a rude player could never enter the works at all.
	var cast := Cast.shared()
	for pair: Array in [[&"tom", &"side_with_tom"], [&"sena", &"side_with_sena"]]:
		var option: DialogueOption = DialogueRules.find(
			cast.get_npc(pair[0] as StringName), pair[1] as StringName)
		assert_not_null(option, "%s can be taken up on it" % pair[0])
		assert_false(option.asks_for_goodwill(),
			"%s takes your help whatever they think of you" % pair[0])


func test_getting_in_is_not_getting_to_the_furnaces() -> void:
	# **Yannick, 2026-09-19.** The gate opening must not hand the player the act. The
	# quest's spine is *get in, face whoever stands in the way, act* — the fight is the
	# moment somebody puts themselves between the two. Walking straight from the gate to
	# a cold furnace with nothing in between is the thing this guards against.
	if not Places.baked():
		debt("the yard is the baked world's")
		return
	var sim: Sim = _world()
	sim.facts.add_source(VOUCHED, &"sena")
	assert_false(sim.facts.has(&"cinderworks:faced_them"),
		"being let in is not having faced anybody")
	assert_true(_a_furnace_tile().x > 0, "and there is a furnace waiting behind it")


# ---------------------------------------------------- the act at the furnaces (Q4) ---
#
# One act in two directions: Tom's people put the fires out, Sena's light them again.
# **Which one is offered is whose side you took; whether it is offered at all is whether
# you have faced anybody.** §4's spine is *get in, face whoever stands in the way, act*,
# and the fight is the middle of it rather than an addition to it.

const DOUSE: StringName = &"i_put_the_fires_out"
const RELIGHT: StringName = &"i_lit_them_again"


func _at_a_furnace(sim: Sim) -> Vector2i:
	var world := sim.store(&"world") as WorldState
	var at: Vector2i = _a_furnace_tile()
	world.player_pos = Vector2(at) + Vector2(0.5, 1.5)
	return at


func _act(sim: Sim) -> void:
	sim.submit(&"act")
	sim.advance(2)


func test_the_furnaces_offer_nothing_until_somebody_has_been_faced() -> void:
	var sim: Sim = _world()
	_at_a_furnace(sim)
	assert_eq(SiteRules.quest_deed_at(&"kiln", sim.facts), &"",
		"a stranger at a furnace is offered none of it")

	# A side on its own is not enough: being let in is not having faced anybody.
	sim.facts.add_source(VOUCHED, &"sena")
	assert_eq(SiteRules.quest_deed_at(&"kiln", sim.facts), &"",
		"and neither is being vouched for")

	sim.facts.add_source(SiteRules.FACED, &"witnessed")
	assert_eq(SiteRules.quest_deed_at(&"kiln", sim.facts), RELIGHT,
		"only both together")


func test_the_side_you_took_decides_which_way_the_act_goes() -> void:
	var his: Sim = _world()
	his.facts.add_source(SiteRules.FACED, &"witnessed")
	his.facts.add_source(BROUGHT, &"tom")
	assert_eq(SiteRules.quest_deed_at(&"kiln", his.facts), DOUSE, "Tom's people put them out")

	var hers: Sim = _world()
	hers.facts.add_source(SiteRules.FACED, &"witnessed")
	hers.facts.add_source(VOUCHED, &"sena")
	assert_eq(SiteRules.quest_deed_at(&"kiln", hers.facts), RELIGHT, "Sena's light them again")


func test_each_direction_performed_in_its_own_run() -> void:
	if not Places.baked():
		debt("the furnaces stand where his ironworks delivery puts them")
		return
	for pair: Array in [[BROUGHT, DOUSE], [VOUCHED, RELIGHT]]:
		var sim: Sim = _world()
		sim.facts.add_source(SiteRules.FACED, &"witnessed")
		sim.facts.add_source(pair[0] as StringName, &"witnessed")
		_at_a_furnace(sim)
		_act(sim)
		assert_true(sim.facts.has(pair[1] as StringName),
			"the act went through: %s" % pair[1])
		assert_eq((sim.store(&"world") as WorldState).last_act, pair[1] as StringName,
			"and it is the one the side asked for")


func test_doing_it_at_the_second_furnace_does_not_count_twice() -> void:
	# **`spent_sites` is per tile, and that is right for a lever against the crown** —
	# six furnaces are six things you can wreck. This is not that. Putting the fires out
	# is one decision about the works, so it is remembered as a fact and the second
	# furnace has nothing left to offer.
	if not Places.baked():
		debt("the furnaces stand where his ironworks delivery puts them")
		return
	var sim: Sim = _world()
	var world := sim.store(&"world") as WorldState
	sim.facts.add_source(SiteRules.FACED, &"witnessed")
	sim.facts.add_source(BROUGHT, &"tom")
	_at_a_furnace(sim)
	_act(sim)
	assert_true(sim.facts.has(DOUSE), "done once")

	var done: int = 0
	for event: SimEvent in sim.events.all():
		if event.type == &"works_act":
			done += 1
	# Every other furnace on the site, one after another.
	var region: Region = world.region()
	for prop: Dictionary in region.props:
		if String(prop["kind"]) != "kiln":
			continue
		world.player_pos = Vector2(prop["at"] as Vector2i) + Vector2(0.5, 1.5)
		_act(sim)
	var after: int = 0
	for event: SimEvent in sim.events.all():
		if event.type == &"works_act":
			after += 1
	assert_eq(after, done, "and once however many furnaces you walk to: %d" % after)


func test_the_act_has_a_prompt_in_both_languages() -> void:
	# An act with no words is an act nobody is offered.
	for deed: StringName in [DOUSE, RELIGHT]:
		var key: StringName = SiteRules.quest_label_key(deed)
		assert_true(key != &"", "%s has a prompt key" % deed)
		for locale: String in ["fr", "en"]:
			var words: Dictionary = JSON.parse_string(
				FileAccess.get_file_as_string("res://content/text.%s.json" % locale)) as Dictionary
			assert_true(words.has(String(key)), "%s is written in %s" % [key, locale])


# ------------------------------------------- the outcome moves the two values (Q5) ---
#
# §5 of the quest: putting the fires out takes the works from 6 and 4 to 3 and 1;
# lighting them again takes it to 9 and 7. Both are one `TownRules.STEP` on each value,
# which is not a coincidence — the step is what one act of the player's is worth.

func _values(sim: Sim) -> Array[int]:
	var towns := sim.store(&"towns") as TownState
	return [towns.value_of(&"cinderworks", &"allegiance"),
		towns.value_of(&"cinderworks", &"richesse")]


func _act_on_the_works(side: StringName) -> Sim:
	var sim: Sim = _world()
	sim.facts.add_source(SiteRules.FACED, &"witnessed")
	sim.facts.add_source(side, &"witnessed")
	_at_a_furnace(sim)
	_act(sim)
	sim.advance(4)
	return sim


func test_the_works_starts_where_the_quest_says() -> void:
	assert_eq(_values(_world()), [6, 4], "six and four, as QUEST_CINDERWORKS §1 has it")


func test_putting_the_fires_out_takes_it_to_three_and_one() -> void:
	if not Places.baked():
		debt("the furnaces stand where his ironworks delivery puts them")
		return
	assert_eq(_values(_act_on_the_works(BROUGHT)), [3, 1], "Tom's outcome")


func test_lighting_them_again_takes_it_to_nine_and_seven() -> void:
	if not Places.baked():
		debt("the furnaces stand where his ironworks delivery puts them")
		return
	assert_eq(_values(_act_on_the_works(VOUCHED)), [9, 7], "Sena's outcome")


func test_the_place_settles_and_stops_drifting_afterwards() -> void:
	# **Rule 6's freeze.** The story is told: the crown stops redistributing into it, and
	# a week of weather cannot undo what the player chose.
	if not Places.baked():
		debt("the furnaces stand where his ironworks delivery puts them")
		return
	var sim: Sim = _act_on_the_works(VOUCHED)
	var towns := sim.store(&"towns") as TownState
	assert_true(towns.is_settled(&"cinderworks"), "settled the moment it is resolved")
	var after: Array[int] = _values(sim)
	sim.advance(Sim.STEPS_PER_WORLD_TICK * 60 * 24 * 3)
	assert_eq(_values(sim), after, "and three days of the kingdom change nothing")


func test_it_is_applied_once_and_the_log_replays_to_it() -> void:
	# The whole reason it goes through events: a save here is the log, so an outcome
	# applied by a system writing straight into the store would replay to a different
	# kingdom. And an outcome applied twice would move a place six instead of three.
	if not Places.baked():
		debt("the furnaces stand where his ironworks delivery puts them")
		return
	var sim: Sim = _act_on_the_works(BROUGHT)
	var world := sim.store(&"world") as WorldState
	for prop: Dictionary in world.region().props:
		if String(prop["kind"]) == "kiln":
			world.player_pos = Vector2(prop["at"] as Vector2i) + Vector2(0.5, 1.5)
			_act(sim)
	assert_eq(_values(sim), [3, 1], "every other furnace changes nothing")

	# **And the replay half cannot honestly be proven yet.** This test hands itself
	# `cinderworks:faced_them` directly, because nothing in the game writes it until F6
	# wires the fight in. A fact set by hand is not in the log, so a replay of this run
	# does not do the act at all — and an assertion that passed here would be measuring
	# the test rather than the game.
	#
	# What *is* already proven: the outcome goes through events, and `test_sim`'s replay
	# check covers every event the log holds. When F6 gives the facing an event of its
	# own, this becomes a real end-to-end replay and the debt goes.
	debt("Q5's replay waits on F6: nothing writes cinderworks:faced_them into the log yet")
