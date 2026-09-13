class_name ArrivalSystem
extends SimSystem

## Notices where the player has been, and writes it down.
##
## Standing in Blackcairn is knowledge, so it goes in the fact base like any other
## fact rather than being a flag on a node. Nothing gates on it — it is a record.

func on_step(sim: Sim, _step: int) -> void:
	var world := sim.store(&"world") as WorldState
	if world == null or world.current_zone != WorldState.OVERWORLD:
		return
	if world.region().zone_at(world.player_tile()) != &"blackcairn":
		return
	world.reached_blackcairn = true
	sim.facts.add_source(&"blackcairn:reached", &"witnessed")


## Nothing to do on the world's clock.
func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"arrival"
