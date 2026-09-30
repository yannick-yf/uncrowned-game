extends TestCase

## **Attack the gatekeeper, and the king's guards answer** (T9, revised in V1, 2026-09-30).
##
## Yannick's answer to QUEST_CINDERWORKS §9's third question, revised the day after T9
## built it as an endless flow: three guards of the castle city come, **very strong**, too
## strong for the player at the start of the game. If by a miracle he kills the four, the
## gate is his (V2) and so are the furnaces (V3, V4).

func after_each() -> void:
	DuelRules.forget()


func _duel(sim: Sim) -> Duel:
	return sim.store(&"duel") as Duel


func _gatekeeper(sim: Sim) -> Npc:
	for npc: Npc in (sim.store(&"cast") as Cast).npcs.values():
		if npc.kind == &"gatekeeper":
			return npc
	return null


## Standing in front of him and saying the line, as the game does.
func _attack(sim: Sim) -> void:
	var world := sim.store(&"world") as WorldState
	past_the_hail(sim)
	var him: Npc = _gatekeeper(sim)
	# From the street in front of the gate — the tile beside him outside the yard — and
	# not from inside its wall, which is where the first draft of this suite stood (T10's
	# review).
	var outside: Vector2i = world.region().open_near(him.tile + Vector2i(-1, 0))
	assert_true(world.region().is_passable(outside), "the player stands on open ground: %s" % outside)
	world.player_pos = Vector2(outside) + Vector2(0.5, 0.5)
	sim.submit(&"talk", {"npc": String(him.id)})
	sim.advance(2)
	sim.submit(&"choose_intent", {"intent": "attack_gatekeeper"})
	sim.advance(3)


func _play(sim: Sim, policy: StringName, steps: int) -> void:
	var hands := DuelPlayer.new(policy)
	var duel: Duel = _duel(sim)
	for _step: int in steps:
		if not duel.on():
			return
		hands.play(sim, duel)
		sim.advance(1)


func test_the_gatekeeper_can_be_attacked() -> void:
	var sim: Sim = Game.build()
	_attack(sim)
	var duel: Duel = _duel(sim)
	assert_true(duel.on(), "saying it is a fight")
	assert_not_null(duel.get_fighter(_gatekeeper(sim).id), "against him")
	assert_false(duel.spar, "and a real one")
	assert_eq(duel.reinforced_by, &"kings_guard", "which the king's guards answer")


func test_three_kings_guards_come_together_and_no_more() -> void:
	var sim: Sim = Game.build()
	(sim.store(&"world") as WorldState).unkillable = true
	_attack(sim)
	var duel: Duel = _duel(sim)
	var hands := DuelPlayer.new(DuelPlayer.STAND)
	var round_two_began: int = -1
	for _step: int in 8000:
		if not duel.on():
			break
		hands.play(sim, duel)
		sim.advance(1)
		if round_two_began < 0 and duel.round_number >= 2:
			round_two_began = sim.step
	var joined: Array[SimEvent] = sim.events.of_type(&"duel_joined")
	assert_eq(joined.size(), 3, "three came, and no more")
	for row: SimEvent in joined:
		assert_true(String(row.data.get("who", "")).begins_with("kings_guard"), "a king's guard: %s" % row.data)
		assert_true(round_two_began < 0 or row.step < round_two_began, "all at the end of the first round")


func test_a_kings_guard_is_far_stronger_than_a_man() -> void:
	assert_true(DuelRules.hp_of(&"kings_guard") >= 2 * DuelRules.hp_of(&"_default"),
		"he takes %d where a man takes %d" % [DuelRules.hp_of(&"kings_guard"), DuelRules.hp_of(&"_default")])
	assert_true(DuelRules.damage_of(&"kings_guard", DuelRules.SWORD) >= 2 * DuelRules.strike_damage(),
		"and strikes for %d" % DuelRules.damage_of(&"kings_guard", DuelRules.SWORD))
	var sim: Sim = Game.build()
	_attack(sim)
	_play(sim, DuelPlayer.STAND, 8000)
	var theirs: int = 0
	for row: SimEvent in sim.events.of_type(&"blow_landed"):
		if String(row.data.get("by", "")).begins_with("kings_guard"):
			theirs += 1
			assert_eq(int(row.data.get("damage", 0)), DuelRules.damage_of(&"kings_guard", DuelRules.SWORD),
				"a king's guard's blow")
	assert_true(theirs > 0, "they struck")


func test_by_a_miracle_the_four_can_be_beaten() -> void:
	# Unkillable (G), pressing: each can be killed, and once all four are down it is won.
	var sim: Sim = Game.build()
	(sim.store(&"world") as WorldState).unkillable = true
	_attack(sim)
	_play(sim, DuelPlayer.PRESS, 60000)
	var downs: int = 0
	for row: SimEvent in sim.events.of_type(&"duel_down"):
		if String(row.data.get("who", "")) != "player":
			downs += 1
	assert_eq(downs, 4, "the gatekeeper and the three")
	var won: bool = false
	for row: SimEvent in sim.events.of_type(&"duel_decided"):
		won = won or String(row.data.get("how", "")) == "won"
	assert_true(won, "and the fight is won")


func test_winning_forces_the_gate() -> void:
	# V2: if by a miracle the four fall, the gate is the player's — open, and nobody in it.
	var sim: Sim = Game.build()
	(sim.store(&"world") as WorldState).unkillable = true
	_attack(sim)
	var him: Npc = _gatekeeper(sim)
	assert_false(sim.facts.has(SiteRules.FORCED), "not before")
	_play(sim, DuelPlayer.PRESS, 60000)
	# The ending is said as the fight closes, and heard on the next step.
	sim.advance(2)
	assert_true(sim.facts.has(SiteRules.FORCED), "won, the gate is forced")
	assert_eq(sim.events.of_type(&"gate_forced").size(), 1, "and it is said once")
	assert_true(WardRules.opens(&"cinderworks_gate", sim.facts), "it opens")
	assert_true(OpeningRules.is_gone(him.id, sim.facts), "and nobody stands in it now")


func test_leaving_forces_nothing() -> void:
	var sim: Sim = Game.build()
	_attack(sim)
	_play(sim, DuelPlayer.LEAVE, 40000)
	sim.advance(2)
	assert_false(sim.facts.has(SiteRules.FORCED), "walking away takes no gate")
	assert_false(WardRules.opens(&"cinderworks_gate", sim.facts), "it stays shut")


func test_falling_ends_it() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	_attack(sim)
	_play(sim, DuelPlayer.STAND, 40000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_false(_duel(sim).on(), "it ends")
	assert_eq(_duel(sim).outcome, &"lost", "with you down")
	assert_eq(world.deaths, 1, "for real")


func test_leaving_ends_it() -> void:
	var sim: Sim = Game.build()
	_attack(sim)
	_play(sim, DuelPlayer.LEAVE, 40000)
	sim.advance(DuelRules.beat_steps() + 5)
	assert_false(_duel(sim).on(), "it ends")
	assert_ne(_duel(sim).outcome, &"won", "and not won")


func test_a_lost_fight_leaves_the_gate_shut() -> void:
	var sim: Sim = Game.build()
	_attack(sim)
	_play(sim, DuelPlayer.STAND, 40000)
	assert_false(WardRules.opens(&"cinderworks_gate", sim.facts), "you fell, and the gate is shut")
	assert_false(sim.facts.has(SiteRules.FORCED), "not forced")


func test_the_fight_at_the_gate_replays_from_the_log() -> void:
	# From where the game starts: attacking him from beside him needs a walk, so the
	# fight is begun as his line begins it, from the log.
	var sim: Sim = Game.build()
	sim.submit(&"unkillable", {"on": true})
	sim.advance(1)
	var him: Npc = _gatekeeper(sim)
	sim.submit(&"duel_began", {"opponent": String(him.id), "asked_by": "attack_gatekeeper"})
	sim.advance(1)
	_play(sim, DuelPlayer.PRESS, 3000)
	assert_true(sim.events.of_type(&"duel_joined").size() > 0, "guards joined")
	var replayed: Sim = Game.replay(sim)
	assert_eq(_duel(replayed).fingerprint(), _duel(sim).fingerprint(), "the same fight, guard for guard")


# ------------------------------------------------------- the review of T9 (T10) ---

func test_whoever_falls_at_the_gate_another_man_stands_in_it() -> void:
	# The review of T9: killing the gatekeeper stopped the window drawing him, and the ward
	# went on refusing his tile — a wall nobody could see. The works keeps its post manned.
	var sim: Sim = Game.build()
	(sim.store(&"world") as WorldState).unkillable = true
	_attack(sim)
	var him: Npc = _gatekeeper(sim)
	var duel: Duel = _duel(sim)
	var hands := DuelPlayer.new(DuelPlayer.PRESS)
	for _step: int in 30000:
		if not duel.on() or sim.facts.has(StringName("killed:%s" % him.id)):
			break
		hands.play(sim, duel)
		sim.advance(1)
	assert_true(sim.facts.has(StringName("killed:%s" % him.id)), "the gatekeeper was killed")
	assert_false(OpeningRules.is_gone(him.id, sim.facts), "and another man stands at the gate")
	assert_false(WardRules.opens(&"cinderworks_gate", sim.facts), "which is still shut")


func test_a_fight_does_not_walk_you_through_a_shut_gate() -> void:
	# Latent, found by the review of T9: the fight's own moves ignored the ward, so a turn
	# could end in the gateway, and a fight left from there left you inside the yard.
	var region: Region = Region.build_overworld()
	if region.wards.is_empty():
		assert_false(Places.baked(), "only the 2D map has no yard, and so no gate to keep")
		return
	var gate: Vector2i = region.wards.keys()[0] as Vector2i
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	past_the_hail(sim)
	var beside: Vector2i = region.open_near(gate + Vector2i(-1, 0))
	world.player_pos = Vector2(beside) + Vector2(0.5, 0.5)
	sim.submit(&"duel_began", {"opponents": ["wolf"], "by": "player"})
	sim.advance(1)
	var duel: Duel = _duel(sim)
	# The wolf is set down beside you, which here is the gateway itself: stand it off to
	# the west, so the gate is free and only the ward can refuse it.
	duel.foe().at = region.open_near(beside + Vector2i(-3, 0))
	assert_ne(duel.foe().at, gate, "the gateway is free")
	assert_true(duel.waiting_on_player(), "your turn, beside the gate")
	assert_false(WardRules.shut_tiles(region, sim.facts).is_empty(), "the gate is shut to you")
	sim.submit(&"duel_turn", {"who": "player", "to_x": gate.x, "to_y": gate.y, "action": "wait", "target": ""})
	sim.advance(200)
	assert_ne(duel.me().at, gate, "and a turn aimed into it ends outside")


# ------------------------------------------ V3: at the furnaces, whatever you want ---

func _kilns(region: Region) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for prop: Dictionary in region.props:
		if (prop["kind"] as StringName) == &"kiln" and region.zone_at(prop["at"] as Vector2i) == &"cinderworks":
			out.append(prop)
	return out


func test_the_furnaces_are_counted_in_one_order() -> void:
	# The window lights the first N of a place's furnaces, N from richesse; the rules must
	# count them in the same order or a furnace drawn cold would offer to be put out.
	var region: Region = Region.build_overworld()
	var kilns: Array[Dictionary] = _kilns(region)
	assert_true(kilns.size() > 1, "the works has furnaces: %d" % kilns.size())
	assert_eq(region.kilns_in(&"cinderworks"), kilns.size(), "all of them counted")
	for i: int in kilns.size():
		assert_eq(region.kiln_index(kilns[i]["at"] as Vector2i), i, "in the order they stand")


func test_with_the_gate_forced_a_burning_furnace_can_be_put_out_and_a_cold_one_lit() -> void:
	var sim: Sim = Game.build()
	sim.facts.add_source(SiteRules.FORCED, &"witnessed")
	var region: Region = (sim.store(&"world") as WorldState).region()
	var towns := sim.store(&"towns") as TownState
	var burning: int = 0
	var cold: int = 0
	for kiln: Dictionary in _kilns(region):
		var lit: bool = SiteRules.burns(region, towns, kiln)
		var deed: StringName = SiteRules.quest_deed_at(kiln, sim.facts, lit)
		assert_eq(deed, DeedRules.DEED_DOUSE if lit else DeedRules.DEED_RELIGHT,
			"%s, %s" % [kiln.get("source_id", kiln["at"]), "burning" if lit else "cold"])
		burning += 1 if lit else 0
		cold += 0 if lit else 1
	assert_true(burning > 0 and cold > 0, "both kinds stand in the works when you arrive: %d burning, %d cold" % [burning, cold])


func test_a_side_taken_keeps_its_one_act() -> void:
	var sim: Sim = Game.build()
	sim.facts.add_source(SiteRules.FORCED, &"witnessed")
	sim.facts.add_source(SiteRules.BROUGHT_THROUGH, &"tom")
	var region: Region = (sim.store(&"world") as WorldState).region()
	for kiln: Dictionary in _kilns(region):
		assert_eq(SiteRules.quest_deed_at(kiln, sim.facts, false), DeedRules.DEED_DOUSE, "Tom's way puts them out")


func test_one_act_once_whichever_it_was() -> void:
	var sim: Sim = Game.build()
	sim.facts.add_source(SiteRules.FORCED, &"witnessed")
	sim.facts.add_source(DeedRules.DEED_DOUSE, &"witnessed")
	assert_true(SiteRules.works_story_told(sim.facts), "the works' story is told")

