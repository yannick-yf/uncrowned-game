class_name WildlifeSystem
extends SimSystem

## The wild, made dangerous.
##
## Beasts exist only near the player: spawned from sim.rng on a ring just past
## what you can see, forgotten once you have left them behind. That keeps a map of
## 56,000 tiles populated for the cost of six animals, and it replays exactly,
## because the spawns follow from the seed and from where the player walked.
##
## They never step onto the road or into a settlement (BeastRules.is_wild_ground).
## That is what makes the long way round *safe* rather than merely long.

func on_step(sim: Sim, step: int) -> void:
	var world := sim.store(&"world") as WorldState
	var wild := sim.store(&"wildlife") as Wildlife
	if world == null or wild == null or world.current_zone != WorldState.OVERWORLD:
		return

	# Spawning and forgetting share a heartbeat: both rebuild or allocate, and
	# doing either sixty times a second costs more than the animals do.
	if step % BeastRules.SPAWN_EVERY_STEPS == 0:
		_forget_distant(world, wild)
		_try_spawn(sim, world, wild)
	_move(sim, world, wild, step)


func _forget_distant(world: WorldState, wild: Wildlife) -> void:
	var kept: Array[Beast] = []
	for beast: Beast in wild.beasts:
		if beast.pos.distance_to(world.player_pos) <= BeastRules.DESPAWN_TILES:
			kept.append(beast)
	wild.beasts = kept


func _try_spawn(sim: Sim, world: WorldState, wild: Wildlife) -> void:
	if wild.count() >= BeastRules.MAX_NEARBY:
		return
	var region: Region = world.region()
	# One attempt, not a search: a failed roll simply means nothing happened here,
	# which is why clearings and roadsides stay quiet.
	#
	# Biased toward where the walker is going. Every beast is slower than the
	# player, so anything spawned behind is scenery — it can never catch up, and a
	# wood that is only dangerous if you stop is not dangerous. The danger is in
	# front of you, which is also how it reads: you run into things.
	var heading: Vector2 = Vector2(world.player_dir)
	var angle: float = sim.rng.randf() * TAU
	if heading.length() > 0.01:
		angle = heading.angle() + sim.rng.randf_range(-BeastRules.SPAWN_ARC, BeastRules.SPAWN_ARC)
	var reach: float = sim.rng.randf_range(BeastRules.SPAWN_MIN_TILES, BeastRules.SPAWN_MAX_TILES)
	var at: Vector2 = world.player_pos + Vector2(cos(angle), sin(angle)) * reach
	var tile := Vector2i(floori(at.x), floori(at.y))
	if not region.is_beast_ground(tile):
		return
	var beast: Beast = wild.add(BeastRules.kind_for(region.terrain_at(tile), sim.rng.randi()), at)
	beast.turn_at_step = sim.step
	beast.heading = Vector2(cos(angle), sin(angle))
	beast.home = at


func _move(sim: Sim, world: WorldState, wild: Wildlife, step: int) -> void:
	var region: Region = world.region()
	var seconds: float = 1.0 / float(Sim.STEPS_PER_REAL_SECOND)
	for beast: Beast in wild.beasts:
		var to_player: Vector2 = world.player_pos - beast.pos
		beast.hunting = to_player.length() <= BeastRules.sight_for(beast.kind)

		if beast.hunting:
			beast.heading = to_player.normalized()
		elif step >= beast.turn_at_step:
			beast.turn_at_step = step + int(BeastRules.DRIFT_SECONDS * float(Sim.STEPS_PER_REAL_SECOND))
			var angle: float = sim.rng.randf() * TAU
			var wandered: Vector2 = beast.home - beast.pos
			# Turn for home once it has strayed. Without this a wood empties
			# itself while the player stands and watches, and waiting becomes a
			# way to make the dangerous route safe.
			if wandered.length() > BeastRules.HOME_RANGE:
				beast.heading = wandered.normalized()
			else:
				beast.heading = Vector2(cos(angle), sin(angle))

		var delta: Vector2 = beast.heading * BeastRules.speed_for(beast.kind) * seconds
		beast.pos = _slide(region, beast.pos, delta)
		if beast.heading.length() > 0.01:
			beast.facing = Vector2i(
				0 if absf(beast.heading.x) < 0.4 else signi(int(signf(beast.heading.x))),
				0 if absf(beast.heading.y) < 0.4 else signi(int(signf(beast.heading.y))))

		if to_player.length() > BeastRules.CONTACT_RADIUS:
			continue
		sim.facts.add_source(BeastRules.FACT_WILD_IS_DANGEROUS, &"witnessed")
		if step >= world.invulnerable_until:
			wild.bites_taken += 1
		world.hurt(BeastRules.damage_for(beast.kind), step)


## Per axis, and only onto ground a beast will set foot on.
static func _slide(region: Region, from: Vector2, delta: Vector2) -> Vector2:
	var to: Vector2 = from
	if _wild_at(region, Vector2(from.x + delta.x, from.y)):
		to.x = from.x + delta.x
	if _wild_at(region, Vector2(to.x, from.y + delta.y)):
		to.y = from.y + delta.y
	return to


static func _wild_at(region: Region, pos: Vector2) -> bool:
	return region.is_beast_ground(Vector2i(floori(pos.x), floori(pos.y)))


func system_name() -> StringName:
	return &"wildlife"
