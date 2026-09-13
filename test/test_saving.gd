extends TestCase

## §19 Q5, settled 2026-09-12: you save at a campfire and dying puts you back at
## the last one, as you were.
##
## The save is the event log and nothing else, which is what the whole architecture
## was for: everything in the world is derived from the events, so loading is
## replaying and there is no snapshot that can drift out of step with it. Loading a
## save is not a feature with its own bugs — it is the thing every replay test has
## been exercising since Phase 0.



func before_each() -> void:
	SaveFile.discard()


func after_each() -> void:
	SaveFile.discard()


func _rest_at_the_nearest_fire(sim: Sim) -> bool:
	var world := sim.store(&"world") as WorldState
	for prop: Dictionary in world.region().props:
		if (prop["kind"] as StringName) != &"campfire":
			continue
		world.player_pos = Vector2(prop["at"] as Vector2i) + Vector2(0.5, 1.5)
		sim.submit(&"rest")
		sim.advance(2)
		return world.rested_tick >= 0
	return false


func test_there_is_somewhere_to_rest_in_every_place_worth_being() -> void:
	# They have to be common enough that reaching one is a plan rather than a
	# pilgrimage. Rare campfires would make death a punishment, not a cost.
	var region: Region = Region.build_overworld()
	var fires: Array[Vector2i] = []
	for prop: Dictionary in region.props:
		if (prop["kind"] as StringName) == &"campfire":
			fires.append(prop["at"] as Vector2i)
			assert_true(region.is_passable(prop["at"] as Vector2i),
				"a fire at %s is inside a wall" % prop["at"])
	assert_true(fires.size() >= Region.ZONE_ORDER.size(),
		"only %d fires for %d places" % [fires.size(), Region.ZONE_ORDER.size()])

	for zone: StringName in Region.ZONE_ORDER:
		var nearest: float = 1000.0
		for at: Vector2i in fires:
			nearest = minf(nearest, Vector2(at).distance_to(Vector2(Region.zone_sites()[zone])))
		assert_true(nearest < 20.0, "%s has no fire within reach: %.0f tiles" % [zone, nearest])


func test_resting_puts_you_back_together_and_moves_the_world_on() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	world.player_hp = 3
	assert_true(_rest_at_the_nearest_fire(sim), "there was a fire to sit at")
	assert_eq(world.player_hp, WorldState.MAX_HP, "you wake whole")
	assert_true(world.rested_at != Vector2i(-1, -1), "and the fire is remembered")


func test_a_run_is_saved_and_comes_back_the_same() -> void:
	# Walked, not teleported. A save is the list of things the player *did*, so a
	# position set directly is not in it and replay puts you back where you really
	# were — which is correct, and which caught this test rather than the code.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	_walk_to_a_fire(sim)
	sim.submit(&"rest")
	sim.advance(3)
	assert_true(world.rested_tick >= 0, "sat down at a fire we walked to")
	assert_true(SaveFile.write(sim), "and wrote it down")

	var loaded: Sim = SaveFile.read()
	assert_not_null(loaded, "there is a run on disk")
	assert_eq(loaded.step, sim.step, "same clock")
	assert_eq((loaded.store(&"world") as WorldState).fingerprint(), world.fingerprint(),
		"the same run, rebuilt from the things you did")
	assert_eq((loaded.store(&"standing") as Standing).fingerprint(),
		(sim.store(&"standing") as Standing).fingerprint(),
		"and six towns remember you exactly as they did")


## Walk to the nearest fire, using the same event the keyboard sends. Everything a
## save can reproduce goes through here — a position set directly is not an event,
## so it is not in the log, and replay would put the player where they really were.
## Since the opening, the nearest fire is the fairies' own, a few tiles away.
func _walk_to_a_fire(sim: Sim) -> void:
	var world := sim.store(&"world") as WorldState
	var fire: Vector2i = Region.NOWHERE
	var best: float = 1000.0
	for prop: Dictionary in world.region().props:
		if (prop["kind"] as StringName) != &"campfire":
			continue
		var distance: float = world.player_pos.distance_to(Vector2(prop["at"] as Vector2i))
		if distance < best:
			best = distance
			fire = prop["at"] as Vector2i
	var target := Vector2(fire) + Vector2(0.5, 1.5)
	for _i: int in 400:
		if world.player_pos.distance_to(target) <= 1.0:
			break
		var delta: Vector2 = target - world.player_pos
		sim.submit(&"move_intent", {
			"x": signi(int(round(delta.x))), "y": signi(int(round(delta.y)))})
		sim.advance(6)
	sim.submit(&"move_intent", {"x": 0, "y": 0})
	sim.advance(1)


func test_nothing_is_saved_that_the_world_cannot_recompute() -> void:
	# Only external events go to disk. A system's answers are recomputed on load,
	# and storing them would replay each one twice.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	world.player_pos = at_a_stall()
	sim.submit(&"steal")
	sim.advance(3)
	assert_true(sim.events.size() > sim.events.external_rows().size(),
		"the run raised derived events")
	for row: Variant in sim.events.external_rows():
		assert_false(bool((row as Dictionary).get("derived", false)),
			"a derived event reached the save file and would happen twice")


func test_dying_puts_you_back_at_the_fire() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	assert_true(_rest_at_the_nearest_fire(sim), "sat down somewhere")
	var fire: Vector2i = world.rested_at

	world.player_pos = alone_on_the_road()
	world.hurt(WorldState.MAX_HP, sim.step)
	assert_eq(world.deaths, 1, "you died")
	assert_eq(world.player_tile(), fire + Vector2i(0, 1),
		"and woke at the fire, not in Brindle")


func test_a_first_death_before_any_rest_is_not_a_dead_end() -> void:
	# All that survives of Phase 0's "respawn in Brindle keeping everything": a
	# player who dies before ever sitting down has to wake up somewhere. Since the
	# opening that somewhere is the fairies' clearing — where they woke the first
	# time, and the only ground left that could hold them.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	world.player_pos = alone_on_the_road()
	world.hurt(WorldState.MAX_HP, sim.step)
	assert_eq(world.player_tile(), Region.CLEARING, "you wake where you first woke")
