class_name TravellerSystem
extends SimSystem

## The road carries news; the Thornwood does not.
##
## A rumour used to spread as a circle of fixed radius, which meant it reached every
## town whichever way the player walked — so the road cost nothing and §18's proof
## was false. Now a story spreads on its own about as far as the next town, and any
## further than that it has to be **carried by somebody who walked there**.
##
## The player is roughly thirty-five times faster than gossip, and that stays true:
## you can always outrun word. What you cannot do is take the road and not be seen.

func on_step(sim: Sim, step: int) -> void:
	var world := sim.store(&"world") as WorldState
	var road := sim.store(&"travellers") as Travellers
	if world == null or road == null:
		return
	if road.walkers.is_empty():
		_set_out(world, road)

	# Walking is per step, because it is drawn. Everything else — recognising the
	# player, walking into a town — is per tick, because a story does not need
	# deciding sixty times a second and doing it there cost more than the rest of
	# the simulation put together.
	var seconds: float = Game.seconds_per_step()
	for walker: Traveller in road.walkers:
		_walk(world, walker, seconds)


func on_tick(sim: Sim, _tick: int) -> void:
	var world := sim.store(&"world") as WorldState
	var road := sim.store(&"travellers") as Travellers
	if world == null or road == null:
		return
	for walker: Traveller in road.walkers:
		_recognise(sim, world, walker)
		_arrive(sim, world, road, walker)


## Spread along the road at the start, half going each way. Fixed positions rather
## than random ones: the population is deterministic without touching the rng, and
## a save rebuilt from its log puts everybody back where they were.
func _set_out(world: WorldState, road: Travellers) -> void:
	var line: Array[Vector2i] = world.region().road_waypoints()
	if line.is_empty():
		return
	for i: int in TravelRules.ON_THE_ROAD:
		var leg: int = (line.size() * i) / TravelRules.ON_THE_ROAD
		road.add(Vector2(line[leg]) + Vector2(0.5, 0.5), leg, 1 if i % 2 == 0 else -1)


func _walk(world: WorldState, walker: Traveller, seconds: float) -> void:
	var line: Array[Vector2i] = world.region().road_waypoints()
	if line.is_empty():
		return
	var target: int = clampi(walker.leg + walker.heading, 0, line.size() - 1)
	# The ends of the road are the ends of the world. Turn round and walk back.
	if target == walker.leg:
		walker.heading = -walker.heading
		target = clampi(walker.leg + walker.heading, 0, line.size() - 1)
	var to: Vector2 = Vector2(line[target]) + Vector2(0.5, 0.5)
	var step: float = TravelRules.WALK_SPEED * seconds
	if walker.pos.distance_to(to) <= step:
		walker.pos = to
		walker.leg = target
		return
	walker.pos += (to - walker.pos).normalized() * step


## "That's the one they were talking about in the last town."
##
## The only way a traveller picks anything up. They never witness a deed and never
## become a source: the story already exists, with a named person behind it, and
## seeing the player is what attaches the two.
func _recognise(sim: Sim, world: WorldState, walker: Traveller) -> void:
	var rumours := sim.store(&"rumours") as Rumours
	if rumours == null:
		return
	if walker.pos.distance_to(world.player_pos) > TravelRules.RECOGNISE_RANGE:
		return
	for rumour: Rumour in rumours.live:
		if not walker.is_carrying(rumour.id):
			walker.carrying.append(rumour.id)


## Walking into a town is what delivers. Standing in one is not.
func _arrive(sim: Sim, world: WorldState, road: Travellers, walker: Traveller) -> void:
	var here: StringName = world.region().zone_at(walker.tile())
	if here == walker.last_town:
		return
	walker.last_town = here
	if here == &"" or walker.carrying.is_empty():
		return
	var rumours := sim.store(&"rumours") as Rumours
	var standing := sim.store(&"standing") as Standing
	if rumours == null or standing == null:
		return
	for rumour: Rumour in rumours.live:
		if not walker.is_carrying(rumour.id) or rumour.has_reached(here):
			continue
		road.deliveries += 1
		RumourSystem.deliver(sim, rumour, here, true)


func system_name() -> StringName:
	return &"travellers"
