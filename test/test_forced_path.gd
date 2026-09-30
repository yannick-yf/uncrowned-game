extends TestCase

## **The works taken by force, the whole way, replayed** (V4, 2026-09-30).
##
## Yannick's third way into the Cinderworks: attack the gatekeeper, beat him and the three
## king's guards who answer, and the furnaces are yours — putting one out brings three more
## guards, lighting one brings Tom. This walks it from where the game begins, with nothing
## set outside the log but G, which is itself an event, and rebuilds the same works from the
## log alone.

const SLOW: bool = true


func _duel(sim: Sim) -> Duel:
	return sim.store(&"duel") as Duel


func _fight(sim: Sim) -> void:
	var hands := DuelPlayer.new(DuelPlayer.PRESS)
	var duel: Duel = _duel(sim)
	for _step: int in 80000:
		if not duel.on():
			break
		hands.play(sim, duel)
		sim.advance(1)
	sim.advance(3)


func test_the_gate_forced_and_a_furnace_put_out_replay_from_the_log() -> void:
	var sim: Sim = Game.build()
	sim.submit(&"unkillable", {"on": true})
	sim.advance(1)
	var keeper: Npc = null
	for npc: Npc in (sim.store(&"cast") as Cast).npcs.values():
		if npc.kind == &"gatekeeper":
			keeper = npc
	sim.submit(&"duel_began", {"opponent": String(keeper.id), "asked_by": "attack_gatekeeper"})
	sim.advance(1)
	_fight(sim)
	assert_true(sim.facts.has(SiteRules.FORCED), "the gate is forced")

	# To a furnace that burns, through the gate, walked the way a player walks.
	var world := sim.store(&"world") as WorldState
	var region: Region = world.region()
	var towns := sim.store(&"towns") as TownState
	var beside: Vector2i = Region.NOWHERE
	for prop: Dictionary in region.props:
		if (prop["kind"] as StringName) == &"kiln" and region.zone_at(prop["at"] as Vector2i) == &"cinderworks" \
				and SiteRules.burns(region, towns, prop):
			beside = region.open_near((prop["at"] as Vector2i) + Vector2i(0, 1))
			break
	assert_ne(beside, Region.NOWHERE, "a furnace burns")
	var walker := OpeningPlayer.new()
	var arrived: bool = walker.walk_to(sim, beside, 200000, true)
	assert_true(arrived, "walked to it: %s" % walker.report)
	if not arrived:
		return

	sim.submit(&"act")
	sim.advance(3)
	assert_true(_duel(sim).on(), "reaching for it brings the king's guards")
	_fight(sim)
	# The fight moves you; back to the furnace, as a player would walk back to it.
	assert_true(walker.walk_to(sim, beside, 200000, true), "back to it: %s" % walker.report)
	sim.submit(&"act")
	sim.advance(3)
	assert_true(sim.facts.has(DeedRules.DEED_DOUSE), "and, beaten, it is put out")

	var replayed: Sim = Game.replay(sim)
	assert_true(replayed.facts.has(SiteRules.FORCED), "a replay forces the gate")
	assert_true(replayed.facts.has(DeedRules.DEED_DOUSE), "and puts the furnace out")
	assert_eq((replayed.store(&"towns") as TownState).fingerprint(), towns.fingerprint(), "to the same works")
	assert_eq((replayed.store(&"world") as WorldState).fingerprint(), world.fingerprint(), "and the same world")
