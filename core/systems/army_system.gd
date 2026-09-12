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
	var ticked := sim.store(&"worldtick") as WorldTick
	if world == null or ticked == null:
		return
	var in_muster: bool = world.current_zone == WorldState.OVERWORLD \
		and world.region().is_in_muster(world.player_tile())
	if not ArmyRules.can_expose(in_muster, world.fraud_told_to, sim.facts):
		return

	world.pay_fraud_exposed = true
	# Told, and to the one audience that does this with it. §8's opportunity cost
	# runs both ways: having spent it here, there is no town left to warn.
	world.fraud_told_to = &"muster"
	# Two parts, and both matter. The men already on the edge leave tonight, so
	# the player sees something happen; the rest drift away over the following
	# days, which is what makes the camp you come back to a different camp.
	# Through push(), not by assignment: the handprint is what separates a reign the
	# player brought down from one that fell over, and a quantity that moves by
	# assignment leaves no fingerprints (§3).
	var falling_to: float = WorldRules.army_target_for(true)
	var tonight: float = minf(WorldRules.ARMY_IMMEDIATE_LOSS, ticked.army_strength - falling_to)
	ticked.push(&"army_strength", -maxf(tonight, 0.0))
	# And the rest of it, which arrives over the following week but was set going
	# here. The drift that delivers it is weather; the decision was not.
	ticked.credit(&"army_strength", maxf(ticked.army_strength - falling_to, 0.0))
	ticked.army_target = falling_to
	sim.facts.add_source(ArmyRules.FACT_FRAUD_EXPOSED, &"witnessed")
	sim.facts.add_source(ArmyRules.made_public(ArmyRules.FACT_PAY_FRAUD), &"witnessed")
	ticked.credit(&"facts_public", EndRules.HANDPRINT_NEEDED)
	sim.derive(&"fraud_exposed", {"army": ticked.army_strength})


## Nothing to do between ticks.
func steps() -> bool:
	return false


## Nothing to do on the world's clock.
func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"army"
