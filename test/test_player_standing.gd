extends TestCase

## What a town thinks of the player — `docs/PLAYER_MODEL.md` §§1–3, task J2.
##
## **The town is the unit of account.** A deed moves the standing of the place it
## happened in, and of no other place, and it moves nothing at all if nobody saw it.
##
## The old model is still running beside this one and is meant to be: `Standing`'s
## factions, its per-person ledger and its town opinion carried by rumour all go with
## **C3**, not with this task. So these tests read `PlayerState` and never `Standing`,
## and the ones that hold the old model true are still in `test_deeds`, `test_rumour`
## and `test_factions`, still green.


func _at(sim: Sim, where: Vector2) -> void:
	(sim.store(&"world") as WorldState).player_pos = where


## Somebody's own tile, so there is certainly a pair of eyes on it.
func _beside(sim: Sim, who: StringName) -> Vector2:
	var npc: Npc = (sim.store(&"cast") as Cast).get_npc(who)
	if npc == null:
		fail("nobody called %s stands in the world" % who)
		return Vector2.ZERO
	return Vector2(npc.centre())


func _steal_in(sim: Sim, town: StringName, at: Vector2) -> void:
	_at(sim, at)
	Deeds.perform(sim, DeedRules.DEED_THEFT, town, at, &"theft_unseen")
	sim.advance(2)


func _days(sim: Sim, count: float) -> void:
	sim.advance_world_ticks(int(float(Game.TICKS_PER_IN_GAME_DAY) * count))


# ------------------------------------------------- the town, and no other town ---

func test_a_theft_in_the_cinderworks_moves_the_cinderworks_and_no_other_town() -> void:
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	_steal_in(sim, &"cinderworks", _beside(sim, &"ivo"))
	assert_true(player.standing_in(&"cinderworks") < PlayerState.NEUTRAL,
		"the works saw it: %.1f" % player.standing_in(&"cinderworks"))
	for town: StringName in player.towns():
		if town == &"cinderworks":
			continue
		assert_eq(player.standing_in(town), PlayerState.NEUTRAL,
			"%s was not there and has no opinion of you" % town)

	# And three days later, with the story arrived everywhere it travels, still none.
	# The player's standing does not propagate place to place (§4): the kingdom's star
	# is the only route, and a town's own opinion is made of deeds done in it.
	_days(sim, 3.0)
	for town: StringName in player.towns():
		if town == &"cinderworks":
			continue
		assert_eq(player.standing_in(town), PlayerState.NEUTRAL,
			"%s heard the story and still has no opinion of you" % town)


func test_a_theft_nobody_saw_moves_nothing() -> void:
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	var cast := sim.store(&"cast") as Cast
	var corner: Vector2 = empty_corner_of(&"cinderworks")
	assert_eq(CrimeRules.witnesses_to(cast, WorldState.OVERWORLD, corner).size(), 0,
		"nobody is standing in that corner of the works")
	_steal_in(sim, &"cinderworks", corner)
	for town: StringName in player.towns():
		assert_eq(player.standing_in(town), PlayerState.NEUTRAL,
			"%s: a deed nobody saw did not happen" % town)


func test_the_deed_the_player_actually_commits_moves_the_town_it_was_done_in() -> void:
	# The one above performs the deed through the shared pipe directly, because no
	# stall stands in the Cinderworks. This is the whole path — a key press, a stall,
	# the witnesses, the standing — in the town that has stalls.
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	_at(sim, at_a_stall(&"harrowgate"))
	sim.submit(&"steal")
	sim.advance(2)
	assert_true(player.standing_in(&"harrowgate") < PlayerState.NEUTRAL,
		"Harrowgate saw you take it: %.1f" % player.standing_in(&"harrowgate"))
	assert_eq(player.standing_in(&"muster"), PlayerState.NEUTRAL, "the camp was not there")


func test_putting_it_back_repairs_the_place_and_no_other() -> void:
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	_at(sim, at_a_stall(&"harrowgate"))
	sim.submit(&"steal")
	sim.advance(2)
	var after_the_theft: float = player.standing_in(&"harrowgate")
	sim.submit(&"give_back")
	sim.advance(2)
	assert_true(player.standing_in(&"harrowgate") > after_the_theft,
		"they watched you put it back")
	assert_true(player.standing_in(&"harrowgate") < PlayerState.NEUTRAL,
		"but the town remembers: %.1f" % player.standing_in(&"harrowgate"))


# --------------------------------------------------- what a place is, and is not ---

func test_the_five_places_that_carry_numbers_are_the_five_that_have_an_opinion() -> void:
	# The same five `TownState` carries, read from the same file, so the player's
	# standing and the places' two values can never disagree about which places exist.
	var player := Game.build().store(&"player") as PlayerState
	for id: StringName in [&"cinderworks", &"wide_acres", &"harrowgate", &"muster", &"saltmarch"]:
		assert_true(player.has_standing(id), "%s has an opinion of you" % id)
	assert_false(player.has_standing(&"brindle"),
		"a ruin has nobody in it to have one")
	assert_eq(player.towns().size(), 5, "and there are five of them")


func test_a_town_never_visited_sits_at_neutral() -> void:
	var player := Game.build().store(&"player") as PlayerState
	for town: StringName in player.towns():
		assert_eq(player.standing_in(town), PlayerState.NEUTRAL,
			"%s has heard nothing about you" % town)


func test_standing_does_not_decay() -> void:
	# Yannick, 2026-09-23: a town remembers. No timer quietly forgives, because a
	# number that drains is a number the player cannot reason about.
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	_steal_in(sim, &"cinderworks", _beside(sim, &"ivo"))
	var straight_after: float = player.standing_in(&"cinderworks")
	_days(sim, 5.0)
	assert_eq(player.standing_in(&"cinderworks"), straight_after,
		"five days later, to the decimal")


func test_a_deed_on_the_road_moves_nothing_and_says_so() -> void:
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	Deeds.perform(sim, DeedRules.DEED_THEFT, &"brindle", _beside(sim, &"ivo"))
	sim.advance(2)
	for town: StringName in player.towns():
		assert_eq(player.standing_in(town), PlayerState.NEUTRAL,
			"%s: a ruin is outside the system" % town)
	var kinds: Array[StringName] = []
	for event: SimEvent in sim.events.all():
		kinds.append(event.type)
	assert_true(kinds.has(&"standing_unmoved"), "and the log says nothing happened")


# ------------------------------------------------------------------- the log ---

func test_nothing_writes_a_standing_except_a_deed_in_the_log() -> void:
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	_at(sim, at_a_stall(&"harrowgate"))
	sim.submit(&"steal")
	sim.advance(2)
	var moved: Dictionary = {}
	for event: SimEvent in sim.events.all():
		if event.type == &"standing_moved":
			moved = event.data
	assert_false(moved.is_empty(), "the world said what it did")
	assert_eq(String(moved.get("town", "")), "harrowgate", "and where")
	assert_eq(String(moved.get("about", "")), String(DeedRules.DEED_THEFT), "and why")
	assert_eq(float(moved.get("to", 0.0)), player.standing_in(&"harrowgate"),
		"and the event carries the number the store now holds")
	# That a run rebuilds the same standing from its log alone is proved in
	# `test_journeys`, where the walk to the stall is in the log too. A test that
	# puts the player somewhere by writing `player_pos` has already stepped outside
	# the log and cannot prove anything about replay.
