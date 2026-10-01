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
	# **And what you look like** (group A), on the same event: a save from before it names
	# none, and is his brother's traveller. Both are checked before either is written, so a
	# refusal leaves nothing half-made.
	var looks: Dictionary = {}
	for choice: StringName in AppearanceRules.ALL:
		if event.data.has(String(choice)):
			looks[choice] = StringName(String(event.data[String(choice)]))
	var appearance := sim.store(&"appearance") as Appearance
	var why: StringName = TraitRules.why_not(wanted)
	if why == &"" and appearance != null:
		why = AppearanceRules.why_not(looks)
	if why == &"" and traits.choose(wanted):
		if appearance != null:
			appearance.choose(looks)
		sim.derive(&"character_made", {"spent": TraitRules.spent(wanted)})
	else:
		sim.derive(&"creation_refused", {"why": String(why)})


## Nothing to do between ticks.
func steps() -> bool:
	return false


## Nothing to do on the world's clock.
func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"creation"
