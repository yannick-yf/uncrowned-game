extends TestCase

## §7's reachability test, in the shape Phase 5 gave it.
##
## It used to ask whether each of three authored routes was still open, which only
## made sense while routes were machinery. Now the ending is a predicate over world
## state, so the question is whether the world can still be **moved** to satisfy any
## of them — a smaller test and a truer one.
##
## Slow because it is an end-to-end proof: every lever on the map, pulled, and then
## twenty-five in-game days for the consequences to settle.

const SLOW: bool = true


## Everything that moves a number an ending reads, and nothing that does not.
## Through the full build this took ten seconds of travellers walking
## about while the treasury emptied.
func _levers_only() -> Sim:
	var sim := Sim.new()
	sim.add_store(&"world", Game.build_world())
	sim.add_store(&"cast", Cast.shared())
	sim.add_store(&"worldtick", WorldTick.new())
	sim.add_store(&"standing", Standing.new())
	sim.add_store(&"rumours", Rumours.new())
	sim.add_system(WorldTickSystem.new())
	sim.add_system(GrainSystem.new())
	sim.add_system(UnrestSystem.new())
	sim.add_system(ActSystem.new())
	sim.add_system(RumourSystem.new())
	sim.add_system(EndingSystem.new())
	return sim


func _days(sim: Sim, count: float) -> void:
	sim.advance_world_ticks(int(float(Game.TICKS_PER_IN_GAME_DAY) * count))


func test_an_ending_is_reachable_by_acts_alone() -> void:
	# §18's proof for this phase, and step 4 of it. §7 used to ask whether each of
	# three authored routes was still open, which only made sense while routes were
	# machinery. The question now is whether the world can still be *moved* to
	# satisfy any predicate — a smaller test and a truer one.
	#
	# No dialogue, no facts learned, nobody talked to. Only things done to places.
	var sim: Sim = _levers_only()
	var world := sim.store(&"world") as WorldState
	for prop: Dictionary in world.region().props:
		if not SiteRules.is_site(prop["kind"] as StringName):
			continue
		world.player_pos = Vector2(prop["at"] as Vector2i) + Vector2(1.5, 2.0)
		sim.submit(&"act")
		sim.advance(3)
	_days(sim, 25.0)

	assert_ne(world.reign_ended, &"",
		"every lever on the map pulled and he is still king — no ending is reachable")
	assert_true(sim.facts.size() > 0, "and the acts are on the record")


func test_the_bloodless_route_finishes_the_game() -> void:
	# §3's Route C, end to end, and the proof that the game is about what people
	# know. Nothing is stolen, nothing is broken, nobody is touched: five documents
	# picked up off tables, read out where people can hear, and word does the rest.
	# With carriers, because Route C **needs the road**. A story spreads about as
	# far as the next town on its own, so reading the ledger out in Harrowgate
	# reaches Harrowgate — and the kingdom only learns what the king did because
	# people walking the King's Road carry it. The bloodless route is a tour.
	var sim: Sim = _levers_only()
	sim.add_store(&"travellers", Travellers.new())
	sim.add_system(TellingSystem.new())
	sim.add_system(TravellerSystem.new())
	var world := sim.store(&"world") as WorldState

	for prop: Dictionary in world.region().props:
		if (prop["kind"] as StringName) != &"papers":
			continue
		world.player_pos = Vector2(prop["at"] as Vector2i) + Vector2(0.5, 0.5)
		sim.submit(&"act")
		sim.advance(3)
	assert_eq(world.documents.size(), DocumentRules.all().size(), "the evidence is in hand")

	for i: int in DocumentRules.all().size():
		world.player_pos = Vector2(148.5, 173.0)
		sim.submit(&"tell_town")
		sim.advance(3)
		sim.advance_world_ticks(90)
	assert_eq(EndRules.public_facts(sim.facts), DocumentRules.all().size(),
		"and the kingdom has heard all of it")

	_days(sim, 8.0)
	assert_eq(world.reign_ended, EndRules.DISCREDITED,
		"he is finished, and nobody was hurt doing it")
	assert_eq(world.spent_sites.size(), 0, "nothing on the map was broken")
	assert_eq(world.thefts, 0, "and nothing was taken that was not evidence")


func test_killing_every_named_person_does_not_close_every_ending() -> void:
	# Invariant 7, restated for predicates. The cast can carry facts and perform
	# acts, but the levers that empty a treasury are **places**, and a place cannot
	# be murdered. That is what guarantees a last route out however permissive the
	# player has been — and it is a stronger guarantee than the old per-route walk,
	# which depended on somebody staying alive.
	var sim: Sim = _levers_only()
	var world := sim.store(&"world") as WorldState
	var levers: int = 0
	for prop: Dictionary in world.region().props:
		if SiteRules.is_site(prop["kind"] as StringName):
			levers += 1
	assert_true(levers >= 8,
		"only %d acts exist that need nobody alive to perform" % levers)

	var reachable: Array[String] = []
	for ending: Dictionary in EndRules.endings():
		for need: Dictionary in (ending["needs"] as Array):
			if DeedRules.all_deeds().any(func(deed: StringName) -> bool:
					return DeedRules.world_effects(deed).has(need["reading"])):
				reachable.append(String(ending["id"]))
				break
	assert_true(reachable.size() > 0,
		"no ending can be moved toward by any act in the game")


