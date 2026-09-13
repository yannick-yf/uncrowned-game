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
	world.player_pos = MovementRules.step(world.player_pos, world.player_dir, world.region())


## Nothing to do on the world's clock.
func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"movement"
