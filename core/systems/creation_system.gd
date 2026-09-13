class_name CreationSystem
extends SimSystem

## Becoming somebody, once, as an ordinary event.
##
## The whole of character creation in the simulation: one event carrying six numbers,
## checked against §11's pool and cap before anything is written. It goes through the
## log like a keypress, so a save contains who you chose to be and a replay rebuilds
## the same person.

func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type != &"create_character":
		return
	var traits := sim.store(&"traits") as Traits
	if traits == null:
		return
	var wanted: Dictionary = {}
	for what: StringName in TraitRules.ALL:
		wanted[what] = int(event.data.get(String(what), TraitRules.FLOOR))
	if traits.choose(wanted):
		sim.derive(&"character_made", {"spent": TraitRules.spent(wanted)})
	else:
		sim.derive(&"creation_refused", {"why": String(TraitRules.why_not(wanted))})


## Nothing to do between ticks.
func steps() -> bool:
	return false


## Nothing to do on the world's clock.
func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"creation"
