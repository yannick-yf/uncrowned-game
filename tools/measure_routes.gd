extends SceneTree

## Walks both ways across the region and reports what each one costs.
##
##   godot --headless --path . -s tools/measure_routes.gd
##
## This is the instrument Phase 2 was built to be read by: the road against the
## wild. Since 2026-09-13 the wild has no teeth and the ground slows you again, so
## the price of the wild is **time**, and the third row is the one trait that does
## not pay all of it (§11, Attunement). Run it after touching the map or the speed
## table, and check the rows still say different things: the road faster, the wild
## unseen, the attuned wild somewhere between.

func _initialize() -> void:
	_report("the King's Road", Region.road_waypoints(), false)
	_report("the wild", _wild_line(), false)
	_report("the wild, attuned", _wild_line(), true)
	quit(0)


## The shortest walkable way from Brindle to the castle — which is what a player
## cuts when they leave the road, and which finds its own way over the river
## rather than pressing into it. A ruled line is not a route: the Kettle is in it.
func _wild_line() -> Array[Vector2i]:
	var region: Region = Region.build_overworld()
	var out: Array[Vector2i] = []
	for point: Vector2 in Navigation.waypoints(region, Region.BRINDLE, Region.BLACKCAIRN, 5, true):
		out.append(Vector2i(point.floor()))
	return out


func _report(label: String, route: Array[Vector2i], attuned: bool) -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	if attuned:
		var wanted: Dictionary = TraitRules.at_the_floor()
		wanted[TraitRules.ATTUNEMENT] = TraitRules.SPEAKS_AT
		(sim.store(&"traits") as Traits).choose(wanted)
	# Both routes are Brindle to the castle by definition. The game starts the player
	# in the fairies' clearing now, and since the deep wood closed, walking straight
	# out of it is not a thing anybody can do — which is the point of the wood, and
	# not something this instrument should be measuring.
	world.player_pos = world.region().brindle_centre()
	var start_hp: int = world.player_hp
	var travelled: float = 0.0
	var last: Vector2 = world.player_pos
	var deadline: int = int(400.0 * float(Sim.STEPS_PER_REAL_SECOND))

	for point: Vector2i in route:
		# The king stands at the end of both routes and is not what is being
		# measured here.
		if Vector2(point).distance_to(Vector2(Region.BLACKCAIRN)) <= 14.0:
			break
		if world.deaths > 0:
			break
		var target: Vector2 = Vector2(point) + Vector2(0.5, 0.5)
		while sim.step < deadline and world.deaths == 0:
			var delta: Vector2 = target - world.player_pos
			if delta.length() <= 1.0:
				break
			var dir := Vector2i.ZERO
			if absf(delta.x) >= 0.5:
				dir.x = 1 if delta.x > 0.0 else -1
			if absf(delta.y) >= 0.5:
				dir.y = 1 if delta.y > 0.0 else -1
			sim.submit(&"move_intent", {"x": dir.x, "y": dir.y})
			sim.advance(Sim.STEPS_PER_REAL_SECOND / 10)
			travelled += last.distance_to(world.player_pos)
			last = world.player_pos

	var seconds: float = float(sim.step) / float(Sim.STEPS_PER_REAL_SECOND)
	var blood: int = start_hp - world.player_hp + world.deaths * WorldState.MAX_HP
	var reached: String = "arrived" if world.deaths == 0 else "died on the way"
	print("%-18s %6.1f tiles   %5.1f s   %2d health   %s" % [
		label, travelled, seconds, blood, reached,
	])
