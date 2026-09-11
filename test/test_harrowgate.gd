extends TestCase

## Phase 1: Harrowgate alive, and one consequence that reaches the king.

var _sim: Sim = null
var _world: WorldState = null
var _cast: Cast = null


func before_each() -> void:
	_sim = Game.build()
	_world = _sim.store(&"world") as WorldState
	_cast = _sim.store(&"cast") as Cast


## Quarter-seconds, converted to steps: the routes below were measured in the old
## world tick and the two-clock change moved none of their geometry.
func _walk(dir: Vector2i, quarter_seconds: int) -> void:
	_sim.submit(&"move_intent", {"x": dir.x, "y": dir.y})
	_sim.advance(quarter_seconds * Sim.STEPS_PER_WORLD_TICK)


func _say(type: StringName, data: Dictionary = {}) -> void:
	_sim.submit(type, data)
	_sim.advance(1)


# ---------------------------------------------------------------- the town ---

func test_harrowgate_is_a_walled_zone_with_a_way_in_and_out() -> void:
	var town: Region = _world.zones[&"harrowgate"] as Region
	assert_not_null(town, "the zone exists")
	assert_false(town.is_passable(Vector2i(0, 0)), "walled")
	assert_false(town.is_passable(Vector2i(20, 0)), "walled to the north too")
	assert_true(town.is_passable(Region.HARROWGATE_ARRIVAL), "you can stand where you arrive")
	assert_false(town.portal_at(Region.HARROWGATE_ARRIVAL).has("zone"),
		"and arriving does not immediately send you back")
	assert_true(town.portal_at(Vector2i(20, 24)).has("zone"), "the gate leads out")


func test_the_gate_is_wide_enough_that_a_step_cannot_miss_it() -> void:
	# One step is 1.5 tiles, so a one-tile doorway is a doorway you walk through.
	var overworld: Region = _world.zones[WorldState.OVERWORLD] as Region
	var band: int = 0
	for dx: int in range(-3, 4):
		if overworld.portal_at(Region.HARROWGATE_GATE + Vector2i(dx, 0)).has("zone"):
			band += 1
	assert_true(band >= 3, "town doorway is %d tiles wide, needs 2+" % band)


func test_walking_into_the_town_footprint_enters_harrowgate() -> void:
	_world.player_pos = Vector2(Region.HARROWGATE_GATE) + Vector2(6.5, 0.5)
	_world.player_tile_last = _world.player_tile()
	_walk(Vector2i(-1, 0), 4)
	assert_eq(_world.current_zone, &"harrowgate", "entered by walking")
	assert_eq(_world.player_tile(), Region.HARROWGATE_ARRIVAL)
	assert_true(_sim.facts.has(&"zone:harrowgate:entered"), "and the world noticed")


# ---------------------------------------------------------------- the cast ---

func test_exactly_the_five_npcs_spec_6_names_live_here() -> void:
	var here: Array[Npc] = _cast.in_zone(&"harrowgate")
	var ids: Array[String] = []
	for npc: Npc in here:
		ids.append(String(npc.id))
	ids.sort()
	assert_eq(ids, ["bell", "garrick", "maddox", "ossa", "tovin"],
		"§6's Harrowgate roster, and nobody invented")
	for npc: Npc in here:
		assert_true(npc.greeting.length() > 0, "%s has a written greeting" % npc.id)
		assert_true(npc.options.size() >= 2 and npc.options.size() <= 3,
			"%s offers %d intents; with the exit that is 3-4 (§9)" % [npc.id, npc.options.size()])
		for option: DialogueOption in npc.options:
			assert_true(option.intent != &"", "every option maps to a named intent")
			assert_true(option.reply.length() > 0, "and every intent has a written reply")


func test_every_dialogue_slot_has_a_key_bound_to_it() -> void:
	# The bug this pins down: the dialogue box printed "4. (say nothing and go)"
	# while only 1-3 were bound, so the option it offered did nothing and the
	# player was stuck in the conversation.
	for npc: Npc in _cast.in_zone(&"harrowgate"):
		var slots: int = DialogueRules.available(npc, _sim.facts).size() + 1
		assert_true(slots <= DialogueRules.MAX_OPTIONS,
			"%s offers %d slots, more than §9's three-or-four" % [npc.id, slots])
		for slot: int in range(1, slots + 1):
			assert_true(InputMap.has_action(StringName("option_%d" % slot)),
				"slot %d is offered to the player but option_%d is not bound" % [slot, slot])


func test_the_player_can_stand_where_every_npc_stands() -> void:
	var town: Region = _world.zones[&"harrowgate"] as Region
	for npc: Npc in _cast.in_zone(&"harrowgate"):
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
	assert_eq(_world.king_escort, 10, "SPECS §3: ten guards")
	assert_eq(_world.army_strength, 100)
	assert_false(_world.pay_fraud_exposed)


func test_exposing_the_fraud_requires_knowing_it() -> void:
	_stand_in_muster()
	_say(&"expose_fraud")
	assert_false(_world.pay_fraud_exposed, "standing there is not knowing")
	assert_eq(_world.king_escort, 10)


func test_knowing_the_fraud_is_not_enough_if_you_are_not_there() -> void:
	_sim.facts.add_source(ArmyRules.FACT_PAY_FRAUD, &"ossa")
	_say(&"expose_fraud")
	assert_false(_world.pay_fraud_exposed, "you have to take it to the camp")
	assert_eq(_world.king_escort, 10)


func test_exposing_it_twice_changes_nothing_the_second_time() -> void:
	_sim.facts.add_source(ArmyRules.FACT_PAY_FRAUD, &"ossa")
	_stand_in_muster()
	_say(&"expose_fraud")
	assert_eq(_world.king_escort, 5)
	_say(&"expose_fraud")
	assert_eq(_world.king_escort, 5, "the men only desert once")


# ------------------------------------------------------------- the whole chain ---

func test_the_whole_chain_walk_learn_expose_and_the_escort_drops() -> void:
	assert_eq(_world.king_escort, 10, "before: ten guards stand between the player and the king")

	# Brindle to Harrowgate, on foot, north-west then west into the town.
	_walk(Vector2i(-1, -1), 34)
	_walk(Vector2i(-1, 0), 16)
	assert_eq(_world.current_zone, &"harrowgate", "walked into Harrowgate")

	# Across the town to the herbalist, who treats the men who ran.
	_walk(Vector2i(-1, -1), 3)
	var ossa: Npc = _cast.get_npc(&"ossa")
	assert_true(_world.player_pos.distance_to(ossa.centre()) <= Game.TALK_REACH,
		"standing close enough to speak")

	_say(&"talk", {"npc": "ossa"})
	_say(&"choose_intent", {"intent": "ask_why"})
	assert_true(_sim.facts.has(ArmyRules.FACT_PAY_FRAUD), "learned why they are deserting")
	_say(&"end_talk")

	# Out of the gate and across the region to the Muster.
	_walk(Vector2i(1, 1), 4)
	assert_eq(_world.current_zone, WorldState.OVERWORLD, "back on the King's Road")
	_walk(Vector2i(-1, 0), 10)
	_walk(Vector2i(-1, -1), 38)
	assert_true(_world.region().is_in_muster(_world.player_tile()),
		"standing in the camp at %s" % _world.player_tile())

	_say(&"expose_fraud")

	assert_true(_world.pay_fraud_exposed, "the camp knows")
	assert_eq(_world.army_strength, 55, "men leave")
	assert_eq(_world.king_escort, 5, "after: five, and the king is that much more reachable")
	assert_true(_sim.facts.has(ArmyRules.FACT_FRAUD_EXPOSED))


func test_the_whole_chain_replays_identically_from_its_log() -> void:
	_walk(Vector2i(-1, -1), 34)
	_walk(Vector2i(-1, 0), 16)
	_walk(Vector2i(-1, -1), 3)
	_say(&"talk", {"npc": "ossa"})
	_say(&"choose_intent", {"intent": "ask_why"})
	_say(&"end_talk")
	_walk(Vector2i(1, 1), 4)
	_walk(Vector2i(-1, 0), 10)
	_walk(Vector2i(-1, -1), 38)
	_say(&"expose_fraud")
	assert_eq(_world.king_escort, 5, "the run did what it was supposed to")

	var replayed: Sim = Game.replay(_sim)
	var replayed_world := replayed.store(&"world") as WorldState
	assert_eq(replayed_world.fingerprint(), _world.fingerprint(),
		"a conversation and its consequence rebuild from the log like anything else")
	assert_eq(replayed.facts.fingerprint(), _sim.facts.fingerprint(), "same facts, same sources")
