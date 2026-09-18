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

## Once an in-game hour rather than once a minute. How many people go to work changes
## at most once a day — the kingdom feeds on a daily clock and the player acts rarely —
## and asking sixty times an hour cost the fast suite two seconds for nothing.
const ASKED_EVERY: int = 60


## **The player's act shows at once.** The hourly clock below is for the weather — the
## slow drift of a place's fortunes — and it would have meant a works stopping and
## everybody carrying on up the road for the rest of the hour. A test said so.
func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type != &"town_moved" and event.type != &"town_fed":
		return
	var world := sim.store(&"world") as WorldState
	var towns := sim.store(&"towns") as TownState
	var folk := sim.store(&"folk") as Folk
	if world == null or towns == null or folk == null:
		return
	var place: StringName = StringName(String(event.data.get("place", "")))
	if Folk.count_in(place) > 0:
		_match_population(world, towns, folk, place)


func on_tick(sim: Sim, tick: int) -> void:
	# The first tick puts everybody out; after that, once an hour. Asking only on the
	# hour looked tidier and meant a run of four minutes had nobody on the road at all —
	# five tests said so before anybody looked at a screen.
	if tick > 1 and tick % ASKED_EVERY != 0:
		return
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
	if world == null or folk == null or folk.walkers.is_empty():
		return
	var seconds: float = Game.seconds_per_step()
	# The route is looked up once a place rather than once a walker: this runs sixty
	# times a second and the lookup was the whole of its cost.
	for place: StringName in Folk.places():
		var route: Array[Vector2] = folk.route_in(world.region(), place)
		if route.size() < 2:
			continue
		for walker: Dictionary in folk.walkers:
			if (walker["place"] as StringName) == place:
				_walk(route, walker, seconds)


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
func _walk(route: Array[Vector2], walker: Dictionary, seconds: float) -> void:
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
