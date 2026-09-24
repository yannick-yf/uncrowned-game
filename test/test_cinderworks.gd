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


func test_the_furnaces_offer_nothing_to_somebody_with_no_side() -> void:
	var sim: Sim = _world()
	assert_eq(SiteRules.quest_deed_at(&"kiln", sim.facts), &"",
		"a stranger at a furnace is offered none of it")
	sim.facts.add_source(VOUCHED, &"sena")
	assert_eq(SiteRules.quest_deed_at(&"kiln", sim.facts), RELIGHT,
		"and somebody she answered for is offered it the moment they are inside")


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

	# This run still hands itself `cinderworks:faced_them`, so it cannot be replayed: a
	# fact set by hand is not in the log. **That debt is paid elsewhere** —
	# `test_the_whole_quest_replays_from_its_log` walks the thing from where the game
	# begins, with no hand on anything, and rebuilds the same works from the log alone.
	# Kept apart because this one is about *once*, and that one is about *again*.


# ------------------------------------------ the fight belongs to the quest (F6) ---
#
# The middle of §4's spine. Until this, the fight and the quest did not know each other:
# you could fight Bram because he offered it, and in the quest nobody fought you at all.

const FACED: StringName = &"cinderworks:faced_them"


## Play a fight out with a competent player and hand back the outcome.
## Walk the player to a tile the way a player does: held directions, through the
## simulation, so every step of it is in the log.
##
## It follows `Navigation.path` rather than steering by eye — a town is full of his
## buildings and naive "go west, then north" gets wedged in the first doorway, which is
## what the first draft of this did.
func _walk_to(sim: Sim, target: Vector2i, budget: int) -> bool:
	var world := sim.store(&"world") as WorldState
	var route: Array[Vector2i] = Navigation.path(
		world.region(), world.player_tile(), target, true)
	if route.is_empty():
		return false
	var held := Vector2i.ZERO
	var next: int = 0
	for _step: int in budget:
		while next < route.size() \
				and world.player_pos.distance_to(Vector2(route[next]) + Vector2(0.5, 0.5)) < 0.9:
			next += 1
		if next >= route.size():
			sim.submit(&"move_intent", {"x": 0, "y": 0})
			sim.advance(2)
			return true
		var gap: Vector2 = Vector2(route[next]) + Vector2(0.5, 0.5) - world.player_pos
		var wanted := Vector2i(
			signi(int(round(gap.x))) if absf(gap.x) > 0.4 else 0,
			signi(int(round(gap.y))) if absf(gap.y) > 0.4 else 0)
		if wanted != held:
			held = wanted
			sim.submit(&"move_intent", {"x": held.x, "y": held.y})
		sim.advance(1)
	return false


## **The quest's fight is the turn-based one, since K6** (2026-09-24). The claims here
## have not changed — beating him is what lets the act through, losing opens nothing —
## only the engine underneath them. `DuelPlayer.PRESS` is the hand that closes and
## strikes, which is what "a competent player" meant when this drove the first design.
func _fight_it_out(sim: Sim) -> StringName:
	var duel := sim.store(&"duel") as Duel
	var hands := DuelPlayer.new(DuelPlayer.PRESS)
	for _step: int in 8000:
		if not duel.on():
			break
		hands.play(sim, duel)
		sim.advance(1)
	return duel.outcome


## The first design's, kept until the first design is deleted (K6's other half).
func _fight_it_out_the_old_way(sim: Sim) -> StringName:
	var fight := sim.store(&"fight") as Fight
	var held: Dictionary = {}
	for _step: int in 6000:
		if not fight.on():
			break
		var want: Dictionary = {"walk": 0, "attack": false, "guard": true, "evade": false}
		if not CombatRules.reaches(fight.player_at_mm, fight.opponent_at_mm, CombatRules.STRIKE):
			want = {"walk": 1, "attack": false, "guard": false, "evade": false}
		elif fight.player_free() and (fight.opponent_stun > 0 or fight.opponent_move == &""):
			want = {"walk": 0, "attack": true, "guard": false, "evade": false}
		if want != held:
			sim.submit(&"fight_input", want)
			held = want
		sim.advance(1)
	return fight.outcome


func test_whose_side_you_took_decides_who_stands_in_the_way() -> void:
	var his: Sim = _world()
	his.facts.add_source(BROUGHT, &"tom")
	assert_true(SiteRules.stands_in_the_way(&"harry", his.facts), "Tom's man is stopped by the foreman")
	assert_false(SiteRules.stands_in_the_way(&"tom", his.facts), "not by Tom, who sent him")

	var hers: Sim = _world()
	hers.facts.add_source(VOUCHED, &"sena")
	assert_true(SiteRules.stands_in_the_way(&"tom", hers.facts), "Sena's is stopped by Tom")
	assert_false(SiteRules.stands_in_the_way(&"harry", hers.facts), "not by the foreman")

	assert_false(SiteRules.stands_in_the_way(&"harry", _world().facts),
		"and nobody stands in the way of somebody who has taken no side")


func test_the_line_that_squares_you_up_appears_only_to_the_other_side() -> void:
	var sim: Sim = _world()
	assert_false(_talk(sim, &"harry").has("face_harry"), "the foreman has no quarrel with a stranger")
	sim.submit(&"end_talk")
	sim.advance(2)
	sim.facts.add_source(BROUGHT, &"tom")
	assert_true(_talk(sim, &"harry").has("face_harry"), "and every quarrel with Tom's man")


func test_reaching_for_a_furnace_brings_somebody_out() -> void:
	# **Yannick, 2026-09-19, and it is what the quest document always said**: *Tom, come
	# to stop the shift*. He arrives. Sending the player off to find him and pick a fight
	# was the weaker half of F6, and reaching for the furnace is the better moment — the
	# prompt says what you are reaching for, never what it will cost you.
	if not Places.baked():
		debt("the furnaces stand where his ironworks delivery puts them")
		return
	var sim: Sim = _world()
	sim.facts.add_source(VOUCHED, &"sena")
	_at_a_furnace(sim)
	_act(sim)

	var duel := sim.store(&"duel") as Duel
	assert_true(duel.on(), "somebody came out")
	assert_eq((duel.foe()).who, &"tom", "and on her side it is Tom")
	assert_false(sim.facts.has(RELIGHT), "the furnaces are untouched while he is standing there")


func test_beating_him_is_what_lets_the_act_through() -> void:
	if not Places.baked():
		debt("the furnaces stand where his ironworks delivery puts them")
		return
	var sim: Sim = _world()
	sim.facts.add_source(VOUCHED, &"sena")
	_at_a_furnace(sim)
	_act(sim)
	assert_eq(_fight_it_out(sim), &"won", "he goes down")
	sim.advance(4)
	assert_true(sim.facts.has(FACED), "which is what having faced somebody means")

	_at_a_furnace(sim)
	_act(sim)
	assert_true(sim.facts.has(RELIGHT), "and now the act goes through")
	# The act raises an event, the outcome answers it, and the town system answers that.
	# Three steps of the world talking to itself before the two numbers have moved.
	sim.advance(4)
	assert_eq(_values(sim), [9, 7], "and the works runs")


func test_he_does_not_come_out_twice() -> void:
	if not Places.baked():
		debt("the furnaces stand where his ironworks delivery puts them")
		return
	var sim: Sim = _world()
	sim.facts.add_source(VOUCHED, &"sena")
	sim.facts.add_source(FACED, &"tom")
	_at_a_furnace(sim)
	_act(sim)
	assert_false((sim.store(&"duel") as Duel).on(),
		"somebody already stopped you once, and lost")
	assert_true(sim.facts.has(RELIGHT), "so the furnace answers instead")


func test_losing_opens_nothing() -> void:
	# Only a win counts, which is what makes the fight the price of the act rather than
	# a scene in front of it.
	var sim: Sim = _world()
	sim.facts.add_source(BROUGHT, &"tom")
	_talk(sim, &"harry")
	_say(sim, &"face_harry")
	# **A small bar, on purpose.** The shipped one is a hundred, which Yannick set as a
	# development value so that nothing in the demo can threaten him — at five damage a
	# blow that is twenty turns of standing still. This test is about the *rule* that
	# only a win opens the furnaces, not about the balance, so it gives the player a bar
	# a loss can actually empty and leaves the hundred to the player.
	var world := sim.store(&"world") as WorldState
	world.player_hp = 10
	var duel := sim.store(&"duel") as Duel
	if duel.on():
		(duel.me()).hp = world.player_hp
	var hands := DuelPlayer.new(DuelPlayer.STAND)
	for _step: int in 8000:
		if not duel.on():
			break
		hands.play(sim, duel)
		sim.advance(1)
	assert_eq(duel.outcome, &"lost", "stand there and he fells you")
	sim.advance(4)
	assert_false(sim.facts.has(FACED), "and the furnaces are still shut to you")


func test_the_whole_quest_replays_from_its_log() -> void:
	# **The quest, played the way it is meant to go, and then rebuilt from the log.**
	# Everything here is an event: the steps taken, the side chosen in conversation, the
	# man who comes out when the player reaches for a furnace, every blow, and the act.
	# Nothing is put anywhere by hand.
	#
	# That last part is the whole difficulty. `_talk` teleports, because forty other tests
	# only care what somebody says — and a position written into the store is not in the
	# log, so a replay of a run that teleported starts its walk from the wrong field and
	# never arrives. This one walks from where the game begins.
	if not Places.baked():
		debt("the furnaces stand where his ironworks delivery puts them")
		return
	var sim: Sim = _world()
	var cast := sim.store(&"cast") as Cast

	assert_true(_walk_to(sim, Vector2i(cast.get_npc(&"sena").centre()), 6000), "walked to Sena")
	sim.submit(&"talk", {"npc": "sena"})
	sim.advance(2)
	_say(sim, &"ask_hand")
	_say(sim, &"side_with_sena")
	sim.submit(&"end_talk")
	sim.advance(2)

	# She answers for him at the gate, so the yard lets him in: Q1 and Q3, played.
	assert_true(_walk_to(sim, _a_furnace_tile(), 6000), "and into the yard")
	_act(sim)
	var duel := sim.store(&"duel") as Duel
	assert_true(duel.on(), "and Tom comes out to stop the shift")
	assert_eq((duel.foe()).who, &"tom", "it is him and not somebody else")
	assert_eq(_fight_it_out(sim), &"won", "Tom is stopped")
	sim.advance(4)

	_act(sim)
	sim.advance(4)
	assert_eq(_values(sim), [9, 7], "and the works runs")

	var replayed: Sim = Game.replay(sim)
	var theirs := replayed.store(&"towns") as TownState
	assert_eq(theirs.value_of(&"cinderworks", &"allegiance"), 9, "the log rebuilds it")
	assert_eq(theirs.value_of(&"cinderworks", &"richesse"), 7, "both of it")
	assert_true(replayed.facts.has(FACED), "including the fight in the middle")


# ------------------------------------------- what the works becomes after (Q6) ---
#
# **Most of this was already built and had never been checked together.** M2 lights the
# furnaces off richesse, P1 walks people to work off the same number, and Q5 moves it.
# Q6's job was to find out what that actually amounts to, and to add the one thing
# missing: on Sena's path, Tom is not there any more.

func _settle_the_works(side: StringName) -> Sim:
	var sim: Sim = _world()
	var world := sim.store(&"world") as WorldState
	sim.advance(Sim.STEPS_PER_WORLD_TICK * 90)
	sim.facts.add_source(side, &"witnessed")
	sim.facts.add_source(FACED, &"witnessed")
	_at_a_furnace(sim)
	_act(sim)
	sim.advance(Sim.STEPS_PER_WORLD_TICK * 90)
	return sim


func _furnaces_alight(sim: Sim) -> int:
	var towns := sim.store(&"towns") as TownState
	var kilns: int = 0
	for prop: Dictionary in (sim.store(&"world") as WorldState).region().props:
		if String(prop["kind"]) == "kiln":
			kilns += 1
	return TownRules.lit_of(kilns, towns.value_of(&"cinderworks", &"richesse"))


func test_putting_them_out_empties_the_road_and_the_furnaces() -> void:
	if not Places.baked():
		debt("the furnaces stand where his ironworks delivery puts them")
		return
	var sim: Sim = _settle_the_works(BROUGHT)
	var folk := sim.store(&"folk") as Folk
	assert_eq(_furnaces_alight(sim), 0, "not one furnace still burning")
	assert_true(folk.in_place(&"cinderworks") <= 1,
		"and all but the last man off the road: %d" % folk.in_place(&"cinderworks"))


func test_lighting_them_again_fills_both() -> void:
	if not Places.baked():
		debt("the furnaces stand where his ironworks delivery puts them")
		return
	var sim: Sim = _settle_the_works(VOUCHED)
	var folk := sim.store(&"folk") as Folk
	assert_true(_furnaces_alight(sim) >= 4, "the fires are up: %d" % _furnaces_alight(sim))
	assert_true(folk.in_place(&"cinderworks") >= 6,
		"and the road is fuller than it was: %d" % folk.in_place(&"cinderworks"))


func test_tom_is_not_there_any_more_once_the_works_runs() -> void:
	# §5, Sena's outcome: *Tom and his people are not there any more, and those who
	# remain know it.* Whether he was stopped or killed the quest does not say, and
	# neither does this.
	var before: Sim = _world()
	assert_false(OpeningRules.is_gone(&"tom", before.facts), "he is here to begin with")

	var after: Sim = _settle_the_works(VOUCHED)
	assert_true(OpeningRules.is_gone(&"tom", after.facts), "and gone once the fires are back")
	assert_false(OpeningRules.is_gone(&"sena", after.facts), "she is not")


func test_he_is_still_there_if_you_took_his_side() -> void:
	var sim: Sim = _settle_the_works(BROUGHT)
	assert_false(OpeningRules.is_gone(&"tom", sim.facts),
		"putting the fires out is what he wanted; he has no reason to go")


func test_somebody_who_is_gone_cannot_be_talked_to() -> void:
	# The fairy's rule, and now his: one question — *should the world still draw this
	# person* — asked in one place, so the window and the conversation cannot disagree.
	var sim: Sim = _settle_the_works(VOUCHED)
	var world := sim.store(&"world") as WorldState
	world.player_pos = (sim.store(&"cast") as Cast).get_npc(&"tom").centre()
	sim.submit(&"talk", {"npc": "tom"})
	sim.advance(2)
	assert_false(world.in_dialogue(), "there is nobody there to answer")
