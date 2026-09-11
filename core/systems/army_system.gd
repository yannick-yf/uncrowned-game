class_name ArmySystem
extends SimSystem

## The one consequence Phase 1 carries end to end.
##
## Expose the pay fraud at the Muster and soldiers leave, because they were not
## being paid and now everyone knows it. Army strength falls, and the king's
## escort falls with it — the same lever §3 describes, arriving from the fact the
## player had to go and find.

func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type != &"expose_fraud":
		return
	var world := sim.store(&"world") as WorldState
	if world == null:
		return
	var in_muster: bool = world.current_zone == WorldState.OVERWORLD \
		and world.region().is_in_muster(world.player_tile())
	if not ArmyRules.can_expose(in_muster, world.pay_fraud_exposed, sim.facts):
		return

	world.pay_fraud_exposed = true
	world.army_strength = ArmyRules.army_strength_for(true)
	world.king_escort = ArmyRules.escort_for(true)
	sim.facts.add_source(ArmyRules.FACT_FRAUD_EXPOSED, &"witnessed")


func system_name() -> StringName:
	return &"army"
