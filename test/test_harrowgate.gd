extends TestCase

## Phase 1: Harrowgate alive, and one consequence that reaches the king.

var _sim: Sim = null
var _world: WorldState = null
var _cast: Cast = null
var _ticked: WorldTick = null


func before_each() -> void:
	_sim = Game.build()
	_world = _sim.store(&"world") as WorldState
	_cast = _sim.store(&"cast") as Cast
	_ticked = _sim.store(&"worldtick") as WorldTick


## Quarter-seconds, converted to steps: the routes below were measured in the old
## world tick and the two-clock change moved none of their geometry.
func _walk(dir: Vector2i, quarter_seconds: int) -> void:
	_sim.submit(&"move_intent", {"x": dir.x, "y": dir.y})
	_sim.advance(quarter_seconds * Sim.STEPS_PER_WORLD_TICK)


func _say(type: StringName, data: Dictionary = {}) -> void:
	_sim.submit(type, data)
	_sim.advance(1)


# ---------------------------------------------------------------- the town ---

func test_harrowgate_is_part_of_the_map_not_a_room_you_enter() -> void:
	# Towns are laid out on the overworld at their real size. A transition now
	# means a change of scale or of rules — an interior — never a change of place.
	var region: Region = _world.region()
	assert_eq(_world.current_zone, WorldState.OVERWORLD)
	assert_eq(_world.zones.size(), 1, "one region, and the towns are in it")
	assert_true(region.portals.is_empty(), "no doorway stands between the road and the town")
	assert_eq(region.zone_at(Region.HARROWGATE), &"harrowgate", "and it still knows where it is")

	var walkable: int = 0
	var half: Vector2i = Region.HARROWGATE_SIZE / 2
	for x: int in range(Region.HARROWGATE.x - half.x, Region.HARROWGATE.x + half.x + 1):
		for y: int in range(Region.HARROWGATE.y - half.y, Region.HARROWGATE.y + half.y + 1):
			if region.is_passable(Vector2i(x, y)):
				walkable += 1
	assert_true(walkable > 600, "the town has streets to walk, not just roofs: %d tiles" % walkable)


func test_the_road_runs_through_the_town() -> void:
	# §4's King's Road goes "through Harrowgate", and now it literally does —
	# which is only safe because there is no portal left for it to run through.
	var region: Region = _world.region()
	var road: int = 0
	for x: int in range(Region.HARROWGATE.x - 18, Region.HARROWGATE.x + 19):
		if region.terrain_at(Vector2i(x, Region.HARROWGATE.y)) == Region.Terrain.ROAD:
			road += 1
	assert_true(road > 25, "the road crosses the town, %d tiles of it" % road)


func test_exactly_the_five_npcs_spec_6_names_live_here() -> void:
	# Harrowgate's five, not the whole roster — §6 names twenty-five across the
	# region and they arrive a town at a time. Filtered by where they stand rather
	# than by a list, so adding somebody elsewhere never touches this.
	var region: Region = _world.region()
	var here: Array[Npc] = []
	for npc: Npc in _cast.named():
		if region.zone_at(npc.tile) == &"harrowgate":
			here.append(npc)
	var ids: Array[String] = []
	for npc: Npc in here:
		ids.append(String(npc.id))
	ids.sort()
	assert_eq(ids, ["bell", "garrick", "maddox", "ossa", "tovin"],
		"§6's Harrowgate roster, and nobody invented")
	for npc: Npc in here:
		assert_true(npc.greeting.length() > 0, "%s has a written greeting" % npc.id)
		# Authored count may exceed what is shown: lines gated on a world condition
		# are written alongside the standing ones and displace them when they apply.
		# What §9 constrains is what the player is *offered*.
		var offered: int = DialogueRules.available(npc, _sim.facts).size() + 1
		assert_true(offered >= 3 and offered <= 4,
			"%s offers %d slots including the exit; §9 says three or four" % [npc.id, offered])
		for option: DialogueOption in npc.options:
			assert_true(option.intent != &"", "every option maps to a named intent")
			assert_true(option.reply.length() > 0, "and every intent has a written reply")


func test_nobody_greets_a_thief_the_way_they_greet_a_stranger() -> void:
	# The coverage rule, and the reason it is a test rather than a habit.
	#
	# Found in play: steal in front of Maddox, Bell and Tovin, walk up to any of
	# them, and all three opened exactly as they had the first time. The machinery
	# was right — Maddox was at -30 and the whole town at -22 — but reaction was
	# something each *line* opted into, so silence was the default and four of the
	# five named cast had never opted in. Writing more lines would not have fixed
	# that; it would have postponed it until the next NPC.
	#
	# (Those two numbers are the old model's, and the bug they describe is the reason
	# this test exists. What the band is read off changed in J5; the rule did not.)
	# **Read off the town since J5** (`docs/PLAYER_MODEL.md` §5): the band comes from
	# what the place both of you are standing in thinks of you, not from a ledger kept
	# per face. So the player stands in Harrowgate and Harrowgate's opinion is what
	# moves — the claim is unchanged, and it is still every named person in the game.
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	world.player_pos = in_town(&"harrowgate")
	assert_true(player.has_standing(world.region().zone_at(world.player_tile())),
		"the player is standing in a town that has an opinion")

	for id: StringName in cast.npcs.keys():
		var npc: Npc = cast.get_npc(id)
		player.standing[&"harrowgate"] = PlayerState.NEUTRAL
		var plain: Array = _conversation(sim, world, id)

		player.standing[&"harrowgate"] = StandingRules.UNWELCOME - 1.0
		assert_ne(_conversation(sim, world, id), plain,
			"%s opens the same way for somebody the town thinks ill of" % npc.display_name)

		player.standing[&"harrowgate"] = StandingRules.HATED - 1.0
		var done: Array = _conversation(sim, world, id)
		assert_eq((done[1] as Array).size(), 0,
			"%s will still hold a conversation with somebody the town hates" % npc.display_name)

		player.standing[&"harrowgate"] = StandingRules.WELCOME + 1.0
		assert_ne(_conversation(sim, world, id), plain,
			"%s opens the same way for somebody the town is glad to see" % npc.display_name)
		player.standing[&"harrowgate"] = PlayerState.NEUTRAL


## The line and the options, as the player would get them.
func _conversation(sim: Sim, world: WorldState, id: StringName) -> Array:
	sim.submit(&"talk", {"npc": String(id)})
	sim.advance(2)
	var intents: Array[String] = []
	for option: DialogueOption in world.options:
		intents.append(String(option.intent))
	var line: String = world.current_line
	sim.submit(&"end_talk")
	sim.advance(2)
	return [line, intents]


func test_a_question_answered_is_a_question_spent() -> void:
	# Found in play: you could ask Maddox the same thing forty times and he would
	# answer identically every time, which is what talking to a machine feels like.
	# A person is a finite resource in a game about information — you should leave a
	# conversation having used somebody up.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState

	sim.submit(&"talk", {"npc": "maddox"})
	sim.advance(2)
	assert_true(world.options.size() >= 2, "he starts with things to say")

	sim.submit(&"choose_intent", {"intent": "ask_town"})
	sim.advance(2)
	# The *intent* is gone, which is the rule. The count need not drop: §9 shows
	# three at a time and a man with six things to say simply moves the next one up
	# — a conversation that refills until it is genuinely exhausted is right, and
	# asserting the count was asserting how much Maddox happened to know that week.
	for option: DialogueOption in world.options:
		assert_ne(String(option.intent), "ask_town", "he has answered that one")

	sim.submit(&"end_talk")
	sim.advance(2)
	sim.submit(&"talk", {"npc": "maddox"})
	sim.advance(2)
	for option: DialogueOption in world.options:
		assert_ne(String(option.intent), "ask_town",
			"and it is still answered when you come back tomorrow")


func test_some_things_bear_asking_twice() -> void:
	# Not everything is spent. A trader's stock and a guard's "anything moving on
	# the road" are questions with a different answer each time you ask.
	var cast := Cast.shared()
	var repeatable: int = 0
	for id: StringName in cast.npcs.keys():
		for option: DialogueOption in cast.get_npc(id).options:
			if option.repeatable:
				repeatable += 1
	assert_true(repeatable > 0, "somebody in the world can be asked the same thing twice")


func test_a_line_he_is_not_offering_is_not_spoken() -> void:
	# Found with a tool rather than a keyboard: choosing an intent outside the three
	# offered slots read the reply aloud and taught nothing, because the verdict
	# refused it and the line was printed anyway. It looks precisely like a fact
	# that failed to register, and §9's whole point is that intents are a closed set.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	sim.submit(&"talk", {"npc": "maddox"})
	sim.advance(2)

	var offered: Array[String] = []
	for option: DialogueOption in world.options:
		offered.append(String(option.intent))
	var hidden: StringName = &""
	for option: DialogueOption in _cast.get_npc(&"maddox").options:
		if not offered.has(String(option.intent)):
			hidden = option.intent
			break
	assert_ne(hidden, &"", "he knows more than three things, so something is off the list")

	var before: String = world.current_line
	sim.submit(&"choose_intent", {"intent": String(hidden)})
	sim.advance(2)
	assert_eq(world.current_line, before, "he did not answer a question you could not ask")


func test_every_line_that_causes_something_names_a_real_deed() -> void:
	# Found the hard way: Sena's line said `causes: "turn_the_workers"` and the deed
	# is `i_turned_the_workers`, so choosing it ran a deed nobody had written — no
	# error, no effect, the furnaces merrily alight. An id typed in content and
	# never compared against anything is a lever that silently does nothing.
	var known: Array[StringName] = DeedRules.all_deeds()
	var causing: int = 0
	for id: StringName in _cast.npcs.keys():
		for option: DialogueOption in _cast.get_npc(id).options:
			if option.causes == &"":
				continue
			causing += 1
			assert_true(known.has(option.causes),
				"%s's '%s' causes '%s', which is not a deed" % [id, option.intent, option.causes])
	assert_true(causing > 0, "somebody in the world can do something by saying it")


func test_every_fact_keeps_one_source_nothing_can_gate_shut() -> void:
	# Invariants 6 and 7, checked against the content rather than hoped for.
	#
	# Ossa stops telling you why men run once she thinks ill of you, which is the
	# door shutting — and it is only legal because Garrick teaches the same fact
	# and nothing gates him. The moment somebody gates the last open source, a
	# required fact leaves the world and no test elsewhere would notice.
	# **Refined 2026-09-12.** `requires` used to count as a gate on its own, which
	# cannot tell a *gate* from a *sequence*. The fairy tells the player seven things
	# in order, each line needing the one before it — but the first needs nothing, she
	# never leaves until she has finished, and no condition or standing is consulted
	# anywhere in the chain. Nothing can shut that door; you simply have to listen in
	# order. A prerequisite taught by the same person through an otherwise ungated
	# option is a sequence, so the fixpoint below walks each speaker's own chain and
	# only counts a real gate as a gate.
	var open_sources: Dictionary = {}
	for id: StringName in _cast.npcs.keys():
		var npc: Npc = _cast.get_npc(id)
		var reachable_from_them: Dictionary = {}
		var moved: bool = true
		while moved:
			moved = false
			for option: DialogueOption in npc.options:
				if option.teaches == &"" or reachable_from_them.has(option.teaches):
					continue
				if option.forbids_condition != &"" or option.requires_condition != &"" \
						or option.asks_for_goodwill():
					continue
				# A trait gate is a gate. A character created at the floor of every
				# trait has to be able to finish the game (invariant 7), so no fact
				# may sit behind one — the line can *lean* on Wits, but somebody
				# somewhere has to be able to say it without.
				if option.needs_trait() != &"":
					continue
				if option.requires != &"" and not reachable_from_them.has(option.requires):
					continue
				reachable_from_them[option.teaches] = true
				moved = true
		for option: DialogueOption in npc.options:
			if option.teaches == &"":
				continue
			if not open_sources.has(option.teaches):
				open_sources[option.teaches] = 0
			if reachable_from_them.has(option.teaches):
				open_sources[option.teaches] += 1

	assert_true(open_sources.size() > 0, "somebody teaches something")
	for fact: StringName in open_sources.keys():
		assert_true(int(open_sources[fact]) >= 1,
			"every route to '%s' can be gated shut — invariant 6" % fact)


func test_every_dialogue_slot_has_a_key_bound_to_it() -> void:
	# The bug this pins down: the dialogue box printed "4. (say nothing and go)"
	# while only 1-3 were bound, so the option it offered did nothing and the
	# player was stuck in the conversation.
	for npc: Npc in _cast.in_zone(WorldState.OVERWORLD):
		var slots: int = DialogueRules.available(npc, _sim.facts).size() + 1
		assert_true(slots <= DialogueRules.MAX_OPTIONS,
			"%s offers %d slots, more than §9's three-or-four" % [npc.id, slots])
		for slot: int in range(1, slots + 1):
			assert_true(InputMap.has_action(StringName("option_%d" % slot)),
				"slot %d is offered to the player but option_%d is not bound" % [slot, slot])


func test_the_player_can_stand_where_every_npc_stands() -> void:
	var town: Region = _world.region()
	for npc: Npc in _cast.in_zone(WorldState.OVERWORLD):
		assert_true(town.is_passable(npc.tile), "%s is not inside a wall" % npc.id)


# ------------------------------------------------------------- the talking ---

func _stand_by(id: StringName) -> Npc:
	var npc: Npc = _cast.get_npc(id)
	_world.current_zone = npc.zone
	_world.player_pos = npc.centre() + Vector2(1.0, 0.0)
	_world.player_tile_last = _world.player_tile()
	return npc


func test_talking_offers_options_and_the_rules_layer_picks_them() -> void:
	var ossa: Npc = _stand_by(&"ossa")
	_say(&"talk", {"npc": "ossa"})
	assert_true(_world.in_dialogue())
	assert_eq(_world.speaker_name, "Ossa")
	assert_eq(_world.current_line, ossa.greeting, "the line is looked up, not made up")
	assert_true(_world.options.size() >= 2 and _world.options.size() <= DialogueRules.MAX_OPTIONS)
	assert_true(_sim.facts.has(&"met:ossa"), "she remembers meeting you")


func test_the_player_cannot_walk_away_mid_sentence() -> void:
	_stand_by(&"maddox")
	_say(&"talk", {"npc": "maddox"})
	var held: Vector2 = _world.player_pos
	_walk(Vector2i(-1, -1), 5)
	assert_eq(_world.player_pos, held, "movement is refused while talking")
	_say(&"end_talk")
	_walk(Vector2i(-1, -1), 2)
	assert_ne(_world.player_pos, held, "and allowed again once it ends")


func test_an_intent_the_npc_does_not_have_does_nothing() -> void:
	_stand_by(&"maddox")
	_say(&"talk", {"npc": "maddox"})
	var line: String = _world.current_line
	_say(&"choose_intent", {"intent": "ask_why"})
	assert_eq(_world.current_line, line, "Maddox has no such intent, so nothing was said")
	assert_false(_sim.facts.has(ArmyRules.FACT_PAY_FRAUD), "and nothing was learned")


func test_ossa_teaches_the_pay_fraud_and_garrick_confirms_it() -> void:
	# Ossa's line leans on Wits, and §11's `tag` gates now that traits exist — so
	# this asks somebody who would notice. Garrick tells anybody, which is what keeps
	# the fact out from behind the gate (invariant 6).
	_say(&"create_character", {"wits": 4})
	_stand_by(&"ossa")
	_say(&"talk", {"npc": "ossa"})
	assert_false(_sim.facts.has(ArmyRules.FACT_PAY_FRAUD))
	_say(&"choose_intent", {"intent": "ask_why"})
	assert_true(_sim.facts.has(ArmyRules.FACT_PAY_FRAUD), "she says who and why")
	assert_eq(_sim.facts.sources_of(ArmyRules.FACT_PAY_FRAUD), [&"ossa"] as Array[StringName])
	_say(&"end_talk")

	_stand_by(&"garrick")
	_say(&"talk", {"npc": "garrick"})
	_say(&"choose_intent", {"intent": "ask_muster"})
	assert_eq(_sim.facts.sources_of(ArmyRules.FACT_PAY_FRAUD),
		[&"garrick", &"ossa"] as Array[StringName], "two independent sources, per §7")
	assert_true(_sim.facts.is_redundant(ArmyRules.FACT_PAY_FRAUD),
		"killing either one leaves the fact in the world")


# ------------------------------------------------------------ the consequence ---

func _stand_in_muster() -> void:
	_world.current_zone = WorldState.OVERWORLD
	_world.player_pos = Vector2(Region.MUSTER) + Vector2(0.5, 0.5)
	_world.player_tile_last = _world.player_tile()


func test_the_escort_is_ten_until_something_changes_it() -> void:
	assert_eq(_ticked.kings_escort(), 10, "SPECS §3: ten guards")
	assert_eq(_ticked.army_strength, 100.0)
	assert_false(_world.pay_fraud_exposed)


func test_exposing_the_fraud_requires_knowing_it() -> void:
	_stand_in_muster()
	_say(&"expose_fraud")
	assert_false(_world.pay_fraud_exposed, "standing there is not knowing")
	assert_eq(_ticked.kings_escort(), 10)


func test_knowing_the_fraud_is_not_enough_if_you_are_not_there() -> void:
	_sim.facts.add_source(ArmyRules.FACT_PAY_FRAUD, &"ossa")
	_say(&"expose_fraud")
	assert_false(_world.pay_fraud_exposed, "you have to take it to the camp")
	assert_eq(_ticked.kings_escort(), 10)


func test_exposing_it_twice_changes_nothing_the_second_time() -> void:
	_sim.facts.add_source(ArmyRules.FACT_PAY_FRAUD, &"ossa")
	_stand_in_muster()
	_say(&"expose_fraud")
	var after: float = _ticked.army_strength
	_say(&"expose_fraud")
	assert_eq(_ticked.army_strength, after, "the men only desert once")


# ------------------------------------------------------------- the whole chain ---

