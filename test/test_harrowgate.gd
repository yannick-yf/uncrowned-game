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


## Walk to a tile by an actual path, not by pressing into whatever is in the way.
func _walk_to(target: Vector2i, max_seconds: float) -> bool:
	var deadline: int = _sim.step + int(max_seconds * float(Sim.STEPS_PER_REAL_SECOND))
	var zone: StringName = _world.current_zone
	var route: Array[Vector2] = Navigation.waypoints(_world.region(), _world.player_tile(), target)
	if route.is_empty():
		return false
	for point: Vector2 in route:
		while _sim.step < deadline:
			if _world.current_zone != zone:
				return true
			var delta: Vector2 = point - _world.player_pos
			if delta.length() <= 1.0:
				break
			var dir := Vector2i.ZERO
			if absf(delta.x) >= 0.5:
				dir.x = 1 if delta.x > 0.0 else -1
			if absf(delta.y) >= 0.5:
				dir.y = 1 if delta.y > 0.0 else -1
			_sim.submit(&"move_intent", {"x": dir.x, "y": dir.y})
			_sim.advance(Sim.STEPS_PER_REAL_SECOND / 10)
		if _sim.step >= deadline:
			return false
	_sim.submit(&"move_intent", {"x": 0, "y": 0})
	_sim.advance(1)
	return true


func _at(tile: Vector2i) -> Vector2:
	return Vector2(tile) + Vector2(0.5, 0.5)


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
	var here: Array[Npc] = _cast.in_zone(WorldState.OVERWORLD)
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

	# Brindle to Harrowgate, on foot, along the King's Road and over the bridge.
	assert_true(_walk_to(Region.HARROWGATE, 180.0), "walked the road to Harrowgate")
	assert_eq(_world.region().zone_at(_world.player_tile()), &"harrowgate", "and into the town")

	# Across the town to the herbalist, who treats the men who ran.
	var ossa: Npc = _cast.get_npc(&"ossa")
	assert_true(_walk_to(ossa.tile, 60.0), "crossed the town to Ossa")
	assert_true(_world.player_pos.distance_to(ossa.centre()) <= Game.TALK_REACH,
		"standing close enough to speak")

	_say(&"talk", {"npc": "ossa"})
	_say(&"choose_intent", {"intent": "ask_why"})
	assert_true(_sim.facts.has(ArmyRules.FACT_PAY_FRAUD), "learned why they are deserting")
	_say(&"end_talk")

	# On up the road to the Muster, without a loading screen in between.
	assert_true(_walk_to(Region.MUSTER, 300.0), "followed the road to the camp")
	assert_true(_world.region().is_in_muster(_world.player_tile()),
		"standing in the camp at %s" % _world.player_tile())

	_say(&"expose_fraud")

	assert_true(_world.pay_fraud_exposed, "the camp knows")
	assert_eq(_world.army_strength, 55, "men leave")
	assert_eq(_world.king_escort, 5, "after: five, and the king is that much more reachable")
	assert_true(_sim.facts.has(ArmyRules.FACT_FRAUD_EXPOSED))


func test_the_whole_chain_replays_identically_from_its_log() -> void:
	assert_true(_walk_to(Region.HARROWGATE, 180.0))
	var ossa: Npc = _cast.get_npc(&"ossa")
	assert_true(_walk_to(ossa.tile, 60.0))
	_say(&"talk", {"npc": "ossa"})
	_say(&"choose_intent", {"intent": "ask_why"})
	_say(&"end_talk")
	assert_true(_walk_to(Region.MUSTER, 300.0))
	_say(&"expose_fraud")
	assert_eq(_world.king_escort, 5, "the run did what it was supposed to")

	var replayed: Sim = Game.replay(_sim)
	var replayed_world := replayed.store(&"world") as WorldState
	assert_eq(replayed_world.fingerprint(), _world.fingerprint(),
		"a conversation and its consequence rebuild from the log like anything else")
	assert_eq(replayed.facts.fingerprint(), _sim.facts.fingerprint(), "same facts, same sources")
