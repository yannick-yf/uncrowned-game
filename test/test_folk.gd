extends TestCase

## Who walks to work (P1).
##
## The point of them is one sentence: **a town that has stopped is a town where nobody
## walks to the mine any more.** Everything below is about that being true, being
## visible in numbers a test can read, and surviving a replay.

const SLOW: bool = true


func test_the_works_sends_people_to_the_mine() -> void:
	var sim: Sim = Game.build()
	sim.advance(Sim.STEPS_PER_REAL_SECOND)
	var folk := sim.store(&"folk") as Folk
	assert_true(folk.in_place(&"cinderworks") > 0,
		"the works at 4 of 10 still sends somebody: %d" % folk.in_place(&"cinderworks"))
	assert_true(folk.in_place(&"cinderworks") < Folk.count_in(&"cinderworks"),
		"but not everybody, because it is going badly")


func test_a_works_that_has_stopped_sends_nobody() -> void:
	var sim: Sim = Game.build()
	var towns := sim.store(&"towns") as TownState
	var folk := sim.store(&"folk") as Folk
	sim.advance(Sim.STEPS_PER_REAL_SECOND)
	var working: int = folk.in_place(&"cinderworks")

	# The workers' outcome: richesse 4 down to 1.
	sim.submit(&"move_town_value", {"place": "cinderworks", "value": "richesse", "direction": -1})
	sim.advance(Sim.STEPS_PER_REAL_SECOND)
	assert_eq(towns.richesse_of(&"cinderworks"), 1)
	assert_true(folk.in_place(&"cinderworks") < working,
		"fewer walk to the mine: %d, was %d" % [folk.in_place(&"cinderworks"), working])

	# And at the floor, the road is empty.
	towns.set_value(&"cinderworks", TownRules.RICHESSE, TownRules.FLOOR)
	sim.advance(Sim.STEPS_PER_REAL_SECOND)
	assert_eq(folk.in_place(&"cinderworks"), 0, "a dead works sends nobody")


func test_a_works_that_is_working_sends_everybody() -> void:
	var sim: Sim = Game.build()
	var towns := sim.store(&"towns") as TownState
	var folk := sim.store(&"folk") as Folk
	towns.set_value(&"cinderworks", TownRules.RICHESSE, TownRules.CEILING)
	sim.advance(Sim.STEPS_PER_REAL_SECOND)
	assert_eq(folk.in_place(&"cinderworks"), Folk.count_in(&"cinderworks"),
		"a works at its ceiling puts everybody on the road")


func test_they_move() -> void:
	# A count is not a walk. This is the half a screenshot cannot show.
	var sim: Sim = Game.build()
	var folk := sim.store(&"folk") as Folk
	sim.advance(Sim.STEPS_PER_REAL_SECOND)
	assert_true(folk.walkers.size() > 0, "somebody is out")
	var before: Vector2 = folk.walkers[0]["pos"] as Vector2
	sim.advance(Sim.STEPS_PER_REAL_SECOND * 2)
	var after: Vector2 = folk.walkers[0]["pos"] as Vector2
	assert_true(before.distance_to(after) > 1.0,
		"and they are further along the road than they were: %.1f tiles" % before.distance_to(after))


func test_nobody_walks_where_no_routine_says_to() -> void:
	# Only the Cinderworks has a routine today. A place without one has no walkers at
	# all — not a default population, and not a crash.
	var sim: Sim = Game.build()
	sim.advance(Sim.STEPS_PER_REAL_SECOND)
	var folk := sim.store(&"folk") as Folk
	for place: StringName in [&"saltmarch", &"muster", &"brindle", &"cairnwell"]:
		assert_eq(folk.in_place(place), 0, "%s has no routine, so nobody walks it" % place)


func test_the_walk_replays() -> void:
	# They are furniture, but furniture that moves has to land on the same tile twice
	# or a save stops being a save.
	var sim: Sim = Game.build()
	sim.submit(&"move_town_value", {"place": "cinderworks", "value": "richesse", "direction": 1})
	sim.advance(Sim.STEPS_PER_REAL_SECOND * 3)
	var folk := sim.store(&"folk") as Folk
	assert_true(folk.walkers.size() > 0, "somebody is out")

	var replayed: Sim = Game.replay(sim)
	assert_eq((replayed.store(&"folk") as Folk).fingerprint(), folk.fingerprint(),
		"the same people on the same stones, rebuilt from the log")
