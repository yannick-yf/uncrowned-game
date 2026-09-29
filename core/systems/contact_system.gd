class_name ContactSystem
extends SimSystem

## The king, who does not move and does not need to.
##
## Phase 0 exception (CLAUDE.md, *Standing exceptions*): the king fights nobody, so the
## confrontation is contact damage in the overworld. Dying to it is dying like anything
## else — back at the last fire you rested at (`WorldState`, `RestSystem`) — and it is a
## consequence of a tick, so replay reproduces it.

func on_step(sim: Sim, step: int) -> void:
	var world := sim.store(&"world") as WorldState
	if world == null or world.current_zone != WorldState.OVERWORLD:
		return
	# Nobody is stabbed mid-sentence. Arthur is a person you can walk up to and
	# speak with — he is not afraid of you — and he becomes lethal again the moment
	# the conversation ends. It also stops a wolf interrupting Ossa.
	if world.in_dialogue():
		return
	if step < world.invulnerable_until:
		return
	if not ContactRules.touching(world.player_pos, world.king_pos):
		return

	sim.facts.add_source(&"the_king_is_lethal", &"witnessed")
	if world.hurt(ContactRules.KING_DAMAGE, step):
		sim.facts.add_source(&"the_king_killed_me", &"witnessed")


## Nothing to do on the world's clock.
func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"contact"
