class_name FolkSystem
extends SimSystem

## Who walks to work, and how many.
##
## **The visible half of richesse, and the strongest one.** Cooling a furnace changes a
## corner of the picture; emptying the road to the mine changes the town. A works at
## its ceiling sends everybody; one that has stopped sends nobody, and the last figure
## to go is the one that says it out loud.
##
## The population is matched on the world's clock, not sixty times a second — how many
## people go to work is not a thing that needs deciding every frame. The walking is per
## step, because it is drawn.
##
## Nothing here is random. Where a new walker starts is its index along the route, so a
## replay puts the same people on the same stones.

func on_tick(sim: Sim, _tick: int) -> void:
	var world := sim.store(&"world") as WorldState
	var towns := sim.store(&"towns") as TownState
	var folk := sim.store(&"folk") as Folk
	if world == null or towns == null or folk == null:
		return
	for place: StringName in Folk.places():
		_match_population(world, towns, folk, place)


func on_step(sim: Sim, _step: int) -> void:
	var world := sim.store(&"world") as WorldState
	var folk := sim.store(&"folk") as Folk
	if world == null or folk == null:
		return
	var seconds: float = Game.seconds_per_step()
	for walker: Dictionary in folk.walkers:
		_walk(world, folk, walker, seconds)


## As many as richesse pays for — the same rule that lights the furnaces, so the two
## halves of a place's fortunes never disagree about how well it is doing.
func _match_population(world: WorldState, towns: TownState, folk: Folk, place: StringName) -> void:
	var route: Array[Vector2] = folk.route_in(world.region(), place)
	if route.is_empty():
		return
	var ceiling: int = Folk.count_in(place)
	var wanted: int = TownRules.lit_of(ceiling, towns.richesse_of(place)) if towns.has_state(place) else ceiling
	var here: int = folk.in_place(place)
	while here > wanted:
		for i: int in range(folk.walkers.size() - 1, -1, -1):
			if (folk.walkers[i]["place"] as StringName) == place:
				folk.walkers.remove_at(i)
				break
		here -= 1
	while here < wanted:
		# Spread along the walk by index, half going each way: deterministic without
		# touching the rng, so a save rebuilt from its log puts everybody back.
		var leg: int = (route.size() * here) / maxi(ceiling, 1)
		folk.walkers.append({"id": folk.next_id, "place": place, "pos": route[leg],
			"leg": leg, "heading": 1 if here % 2 == 0 else -1})
		folk.next_id += 1
		here += 1


## One step along the walk, turning round at either end. The road's own rule, because
## somebody walking to the mine and somebody walking the King's Road are the same
## problem and should not be two pieces of code that drift apart.
func _walk(world: WorldState, folk: Folk, walker: Dictionary, seconds: float) -> void:
	var route: Array[Vector2] = folk.route_in(world.region(), walker["place"] as StringName)
	if route.size() < 2:
		return
	var leg: int = int(walker["leg"])
	var heading: int = int(walker["heading"])
	var target: int = clampi(leg + heading, 0, route.size() - 1)
	if target == leg:
		heading = -heading
		walker["heading"] = heading
		target = clampi(leg + heading, 0, route.size() - 1)
	var to: Vector2 = route[target]
	var pos: Vector2 = walker["pos"] as Vector2
	var step: float = TravelRules.WALK_SPEED * seconds
	if pos.distance_to(to) <= step:
		walker["pos"] = to
		walker["leg"] = target
		return
	walker["pos"] = pos + (to - pos).normalized() * step


func system_name() -> StringName:
	return &"folk"
