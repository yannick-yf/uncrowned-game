class_name RecoverySystem
extends SimSystem

## Mends the player, slowly, when nothing is biting them.

func on_step(sim: Sim, step: int) -> void:
	var world := sim.store(&"world") as WorldState
	if world == null or world.player_hp >= WorldState.MAX_HP:
		return
	if not RecoveryRules.is_calm(step, world.last_hurt_step):
		world.mending_steps = 0
		return

	var in_town: bool = world.region().zone_at(world.player_tile()) != &""
	world.mending_steps += 1
	if world.mending_steps < RecoveryRules.steps_per_point(in_town):
		return
	world.mending_steps = 0
	world.player_hp = mini(world.player_hp + 1, WorldState.MAX_HP)


## Nothing to do on the world's clock.
func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"recovery"
