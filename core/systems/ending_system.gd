class_name EndingSystem
extends SimSystem

## Watches for a reign being over.
##
## It decides nothing. EndRules holds the predicates and this asks them once a tick,
## which is the §9 shape applied to the ending itself: the rules layer issues the
## verdict and everything else only notices.
##
## It fires once. A reign ends the way a person dies — not repeatedly, and not
## un-endingly if a number wanders back over a line afterwards.

func on_tick(sim: Sim, _tick: int) -> void:
	var world := sim.store(&"world") as WorldState
	var ticked := sim.store(&"worldtick") as WorldTick
	if world == null or ticked == null or world.reign_ended != &"":
		return
	var ending: StringName = EndRules.ending_for(ticked, world, sim.facts)
	if ending == &"":
		return
	world.reign_ended = ending
	world.reign_ended_tick = sim.tick
	sim.derive(&"reign_ended", {"how": String(ending)})


func system_name() -> StringName:
	return &"ending"
