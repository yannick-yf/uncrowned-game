extends TestCase

## The road carries news; the Thornwood does not.
##
## The slow half of it: each of these runs the whole region for four in-game days
## with six people walking the King's Road, which is the only way to watch a story
## get somewhere on somebody's feet. The invariants that keep travellers from
## becoming people live in test_rumour.gd and run every time.

const SLOW: bool = true

const TRADER: StringName = &"trader@1"


func _road_sim() -> Sim:
	var sim := Sim.new()
	sim.add_store(&"world", Game.build_world())
	sim.add_store(&"cast", Cast.shared())
	sim.add_store(&"worldtick", WorldTick.new())
	sim.add_store(&"standing", Standing.new())
	sim.add_store(&"rumours", Rumours.new())
	sim.add_store(&"travellers", Travellers.new())
	sim.add_store(&"player", PlayerState.new())
	sim.add_system(PlayerSystem.new())
	sim.add_system(DialogueSystem.new())
	sim.add_system(WorldTickSystem.new())
	sim.add_system(TheftSystem.new())
	sim.add_system(RumourSystem.new())
	sim.add_system(TravellerSystem.new())
	return sim


func _steal_at(sim: Sim, where: Vector2) -> void:
	(sim.store(&"world") as WorldState).player_pos = where
	sim.submit(&"steal")
	sim.advance(2)


func _days(sim: Sim, count: float) -> void:
	sim.advance_world_ticks(int(float(Game.TICKS_PER_IN_GAME_DAY) * count))


func _talk_to_trader(sim: Sim) -> WorldState:
	var world := sim.store(&"world") as WorldState
	world.player_pos = beside_npc(TRADER)
	sim.submit(&"talk", {"npc": String(TRADER)})
	sim.advance(2)
	return world


func _offered(world: WorldState) -> Array[String]:
	var out: Array[String] = []
	for option: DialogueOption in world.options:
		out.append(String(option.intent))
	return out


func test_anything_further_has_to_be_carried() -> void:
	# The road's whole cost. Stand where you can be seen after doing something, and
	# somebody walking to Cairnwell takes the story with them.
	var sim: Sim = _road_sim()
	var standing := sim.store(&"standing") as Standing
	var road := sim.store(&"travellers") as Travellers
	_steal_at(sim, at_a_stall())
	_days(sim, 1.5)

	assert_true(road.deliveries > 0, "somebody walked it somewhere")
	assert_true(StandingRules.is_unwelcome(standing.in_town(&"cairnwell")),
		"and Cairnwell heard: %.1f" % standing.in_town(&"cairnwell"))


func test_the_thornwood_is_the_one_nobody_can_report_you_on() -> void:
	# §18's proof for this phase, which was false until travellers existed: a
	# rumour spread as a circle of fixed radius and reached Cairnwell whichever way
	# you walked. The same theft, the same day and a half, and the only difference is
	# whether the player stood where anybody could see them.
	var seen: Sim = _road_sim()
	_steal_at(seen, at_a_stall())
	_days(seen, 1.5)

	var unseen: Sim = _road_sim()
	_steal_at(unseen, at_a_stall())
	# Off into the trees, well clear of the road, and wait the same day and a half.
	(unseen.store(&"world") as WorldState).player_pos = in_the_wood()
	_days(unseen, 1.5)

	var watched: float = (seen.store(&"standing") as Standing).in_town(&"cairnwell")
	var hidden: float = (unseen.store(&"standing") as Standing).in_town(&"cairnwell")
	assert_true(StandingRules.is_unwelcome(watched), "seen on the road: Cairnwell knows")
	assert_eq(hidden, Standing.NEUTRAL, "gone into the Thornwood: Cairnwell never hears")


func test_the_trader_reads_your_name_in_the_kingdom_and_not_the_story() -> void:
	# **Rewritten with J5** (`docs/PLAYER_MODEL.md` §4), and the change is deliberate.
	#
	# It used to say that a theft in Harrowgate closed a shop in Cairnwell once
	# somebody had walked the story there. Word still walks — the two tests above
	# prove it on the old store, and the road still costs what it cost — but the
	# **player's standing does not walk with it**: a town's opinion is made of deeds
	# done in it, and Cairnwell is not a town at all, it is half the kingdom. So the
	# trader reads the mean of every town, and one theft in Harrowgate is −2 of it.
	var sim: Sim = _road_sim()
	var road := sim.store(&"travellers") as Travellers
	_steal_at(sim, at_a_stall())
	_days(sim, 1.5)
	assert_true(road.deliveries > 0, "somebody walked the story to the capital")
	var world: WorldState = _talk_to_trader(sim)
	assert_true(_offered(world).has("ask_trade"),
		"and one theft three days' walk away does not close a shop in it")

	# What does: a name that is bad everywhere. Five towns at −30 is a mean of −30,
	# past `StandingRules.UNWELCOME`, and consistency is what the court and the
	# capital read (§4).
	var player := sim.store(&"player") as PlayerState
	for town: StringName in player.towns():
		player.standing[town] = -30.0
	sim.submit(&"end_talk")
	sim.advance(2)
	world = _talk_to_trader(sim)
	assert_false(_offered(world).has("ask_trade"),
		"the door that shut: he is no longer offering to sell")
	assert_true(_offered(world).has("ask_refusal"),
		"and the door that opened: you may ask him why")
	assert_ne(world.current_line, "",
		"he greets you differently from how he greeted a stranger")
