class_name MovementSystem
extends SimSystem

## Turns a held direction into a position, once per tick.
##
## Intent arrives as an event and is remembered in the world store rather than
## re-sent every tick, so holding a key writes one event, not four a second.

func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type != &"move_intent":
		return
	var world := sim.store(&"world") as WorldState
	if world == null:
		return
	world.player_dir = Vector2i(
		signi(int(event.data.get("x", 0))),
		signi(int(event.data.get("y", 0))),
	)
	if world.player_dir != Vector2i.ZERO:
		world.player_facing = world.player_dir


func on_step(sim: Sim, _step: int) -> void:
	var world := sim.store(&"world") as WorldState
	if world == null or world.player_dir == Vector2i.ZERO:
		return
	# You cannot walk away mid-sentence. Closing the conversation is an event.
	if world.in_dialogue():
		return
	# And you cannot walk away mid-fight (F3). `CombatSystem` owns the player's position
	# while a fight is on and writes it from the fight's own line every step — two hands
	# on one position is the bug that `Sim.ticks_held` already taught us once.
	var fight := sim.store(&"fight") as Fight
	if fight != null and fight.on():
		return
	# And nor mid-duel (K1): the second design's fight owns the player's position while
	# it runs and writes it from the tile they are standing on, for the same reason.
	var duel := sim.store(&"duel") as Duel
	if duel != null and duel.on():
		return
	var traits := sim.store(&"traits") as Traits
	var attuned: bool = traits != null and traits.is_attuned()
	var wanted: Vector2 = MovementRules.step(
		world.player_pos, world.player_dir, world.region(), -1.0, attuned)
	world.player_pos = _past_the_watch(sim, world, wanted)


## **Somebody standing in the way** (Q1). A warded tile is walkable ground with a person
## on it, and whether you get by is `WardRules`' answer, read from the facts.
##
## Per axis, like the passability it sits beside: pressing diagonally at the edge of a
## gateway should slide you along the fence rather than stop you dead against it.
##
## It is here and not in `MovementRules` on purpose. That is a pure function of the
## ground, and a ward is not about the ground — it is one person's decision about you,
## and the facts it reads live where systems can see them.
func _past_the_watch(sim: Sim, world: WorldState, wanted: Vector2) -> Vector2:
	var region: Region = world.region()
	if region.wards.is_empty():
		return wanted
	var out: Vector2 = wanted
	if _shut(sim, region, MovementRules.tile_of(Vector2(wanted.x, world.player_pos.y))):
		out.x = world.player_pos.x
	if _shut(sim, region, MovementRules.tile_of(Vector2(out.x, wanted.y))):
		out.y = world.player_pos.y
	return out


func _shut(sim: Sim, region: Region, tile: Vector2i) -> bool:
	if not region.wards.has(tile):
		return false
	return not WardRules.opens(region.wards[tile] as StringName, sim.facts)


## Nothing to do on the world's clock.
func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"movement"
