class_name WalkerSystem
extends SimSystem

## **Somebody the world displaced walks back to their post** (O7, 2026-09-29), at the
## world's walking pace, along a path worked out once and kept in the store so a replay
## walks the same tiles. Nobody walks while they are in the fight or in a conversation:
## the lingering starts again whenever the player is talking to them.


func steps() -> bool:
	return true


func ticks() -> bool:
	return false


func on_step(sim: Sim, _step: int) -> void:
	var walkers := sim.store(&"walkers") as Walkers
	if walkers == null or walkers.at.is_empty():
		return
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	var duel := sim.store(&"duel") as Duel
	var hail := sim.store(&"hail") as Hail
	if world == null or cast == null:
		return
	var ids: Array = walkers.at.keys()
	ids.sort()
	for id: Variant in ids:
		var who := StringName(String(id))
		var npc: Npc = cast.get_npc(who)
		if npc == null or OpeningRules.is_gone(who, sim.facts):
			walkers.release(who)
			continue
		if duel != null and duel.on() and duel.get_fighter(who) != null:
			continue
		# Nor a drill's master watching his lesson from the side (the review of O21).
		if duel != null and duel.on() and duel.drill != Duel.NOBODY and DuelRules.drill_master(duel.drill) == who:
			walkers.linger[who] = WalkerRules.linger_steps()
			continue
		# The hail walks a man calling you over; nobody walks him home at the same time.
		if hail != null and hail.walks(who):
			continue
		if world.talking_to == who:
			walkers.linger[who] = WalkerRules.linger_steps()
			continue
		var left: int = int(walkers.linger.get(who, 0))
		if left > 0:
			walkers.linger[who] = left - 1
			continue
		_walk_home(walkers, world.region(), npc)


func _walk_home(walkers: Walkers, region: Region, npc: Npc) -> void:
	var who: StringName = npc.id
	if not walkers.path.has(who):
		var route: Array[Vector2i] = Navigation.path(region, walkers.where(npc), npc.tile)
		# The first tile is where he stands; a path of one, or none, means there is no way
		# home he can walk, and he is simply back.
		if route.size() <= 1:
			walkers.release(who)
			return
		route.remove_at(0)
		walkers.path[who] = route
		walkers.walked[who] = 0
	var walked: int = int(walkers.walked.get(who, 0)) + 1
	if walked < WalkerRules.steps_per_tile():
		walkers.walked[who] = walked
		return
	var ahead: Array = walkers.path[who] as Array
	walkers.at[who] = ahead[0] as Vector2i
	ahead.remove_at(0)
	walkers.walked[who] = 0
	if ahead.is_empty() or walkers.at[who] == npc.tile:
		walkers.release(who)
