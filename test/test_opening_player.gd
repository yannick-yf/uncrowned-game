extends TestCase

## **A scripted walker gets through what the world puts in its way** (O15, 2026-09-29).
## From the tutorial on, the world talks first: Bram calls out and walks over, a pack
## squares up. A walker that only presses a direction stalls at the first of them and
## the suite says *walk failed*, which names nothing. `OpeningPlayer` walks a path, plays
## any fight, leaves any conversation it did not open — or, told to, stops and says
## exactly where it stood and who was talking.


func _sim() -> Sim:
	return Game.build()


func _near(world: WorldState, tile: Vector2i) -> bool:
	return world.player_pos.distance_to(Vector2(tile) + Vector2(0.5, 0.5)) < 1.5


func test_a_walker_facing_a_conversation_it_did_not_open_says_so_by_name() -> void:
	var sim: Sim = _sim()
	var world := sim.store(&"world") as WorldState
	sim.submit(&"talk", {"npc": String(OpeningRules.FAIRY)})
	sim.advance(1)
	assert_true(world.in_dialogue(), "she has started talking")
	var walker := OpeningPlayer.new(OpeningPlayer.STOP)
	assert_false(walker.walk_to(sim, Region.BRINDLE, 600), "a walker that will not answer does not arrive")
	assert_true(walker.report.contains(String(OpeningRules.FAIRY)), "and names who is talking: %s" % walker.report)
	assert_true(walker.report.contains("%s" % world.player_tile()), "and where it stood: %s" % walker.report)
	assert_true(walker.report.contains("talk"), "and what happened last: %s" % walker.report)


func test_a_walker_leaves_a_conversation_it_did_not_open_and_goes_on() -> void:
	var sim: Sim = _sim()
	var world := sim.store(&"world") as WorldState
	sim.submit(&"talk", {"npc": String(OpeningRules.FAIRY)})
	sim.advance(1)
	var walker := OpeningPlayer.new()
	var goal: Vector2i = world.player_tile() + Vector2i(-4, 0)
	assert_true(walker.walk_to(sim, goal, 1200), "it walks away from her and on: %s" % walker.report)
	assert_true(_near(world, goal), "to where it was going")
	assert_eq(walker.left, [OpeningRules.FAIRY] as Array[StringName], "and remembers whom it walked away from")
	assert_false(world.in_dialogue(), "the conversation is closed")


func test_a_walk_with_no_way_says_where_it_stood() -> void:
	var sim: Sim = _sim()
	var world := sim.store(&"world") as WorldState
	var walker := OpeningPlayer.new()
	var sea := Vector2i(0, 0)
	assert_false(world.region().is_passable(sea), "the corner of the map is not ground")
	assert_false(walker.walk_to(sim, sea, 100), "there is no way there")
	assert_true(walker.report.contains("no way"), "and it says so: %s" % walker.report)
	assert_true(walker.report.contains(String(world.region().zone_at(world.player_tile())))
		or walker.report.contains("the wild"), "naming the place it stood in: %s" % walker.report)


func test_a_walker_follows_a_line_of_points_through_the_same_things() -> void:
	var sim: Sim = _sim()
	var world := sim.store(&"world") as WorldState
	sim.submit(&"talk", {"npc": String(OpeningRules.FAIRY)})
	sim.advance(1)
	var here: Vector2i = world.player_tile()
	var walker := OpeningPlayer.new()
	var points: Array[Vector2i] = [here + Vector2i(-2, 0), here + Vector2i(-4, 0)]
	assert_true(walker.follow(sim, points, 1200), "it steers through the points: %s" % walker.report)
	assert_true(_near(world, points[1]), "and ends on the last")


func test_past_the_hail_is_the_fact_the_hail_writes() -> void:
	var sim: Sim = _sim()
	var hails: Array[Dictionary] = [HailRules.row(&"bram", &"brindle_hail")]
	assert_true(HailRules.calls_out(&"bram", sim.facts), "before, he would call")
	past_the_hail(sim, hails)
	assert_false(HailRules.calls_out(&"bram", sim.facts), "after, he has")


func test_the_lonely_road_is_never_where_somebody_calls_from() -> void:
	var at := Vector2i(alone_on_the_road())
	for hail: Dictionary in Places.shared().hails():
		assert_false(HailRules.in_sight(hail, at), "the empty road is out of %s's sight" % hail["who"])
	assert_false(HailRules.in_sight(HailRules.row(&"bram", &"brindle_hail"), at),
		"and out of the ground Bram will watch")
