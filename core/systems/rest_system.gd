class_name RestSystem
extends SimSystem

## Sitting down at a fire.
##
## §19 Q5, settled 2026-09-12: **you save at a campfire, and dying puts you back at
## the last one you used, as you were.** Phase 0's "respawn in Brindle keeping
## everything" is retired by it — death finally costs something, and the cost is
## measured in the thing this game is made of: time and position.
##
## The system only records that you sat down and puts you back together. Advancing
## the clock and writing the file are the window's, because both are about the run
## rather than the world — and a system that wrote a file could not be replayed.

func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type != &"rest":
		return
	var world := sim.store(&"world") as WorldState
	if world == null:
		return
	var fire: Vector2i = world.region().nearest_campfire(world.player_tile(), RecoveryRules.FIRE_REACH)
	if fire == Region.NOWHERE:
		return

	world.rested_at = fire
	world.rested_tick = sim.tick
	world.player_hp = WorldState.MAX_HP
	world.mending_steps = 0
	world.player_dir = Vector2i.ZERO
	sim.derive(&"rested", {"at": fire})


func system_name() -> StringName:
	return &"rest"
