class_name ContactSystem
extends SimSystem

## The king, who does not move and does not need to.
##
## Phase 0 exception (CLAUDE.md): there is no combat screen, so the confrontation
## is contact damage in the overworld. Death respawns the player in Brindle with
## everything kept — no save system, no cost — and that respawn is a consequence of
## a tick, so replay reproduces it.

func on_step(sim: Sim, step: int) -> void:
	var world := sim.store(&"world") as WorldState
	if world == null or world.current_zone != WorldState.OVERWORLD:
		return
	if step < world.invulnerable_until:
		return
	if not ContactRules.touching(world.player_pos, world.king_pos):
		return

	world.player_hp = ContactRules.damage_after(world.player_hp)
	world.touches_taken += 1
	world.invulnerable_until = step + ContactRules.invulnerable_steps()
	sim.facts.add_source(&"the_king_is_lethal", &"witnessed")

	if ContactRules.is_dead(world.player_hp):
		world.deaths += 1
		world.player_hp = WorldState.MAX_HP
		world.player_pos = world.region().brindle_centre()
		world.player_dir = Vector2i.ZERO
		sim.facts.add_source(&"the_king_killed_me", &"witnessed")


func system_name() -> StringName:
	return &"contact"
