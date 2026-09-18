class_name TownSystem
extends SimSystem

## The only thing that writes a place's two numbers.
##
## One event, one move. A quest's outcome submits `move_town_value` and the number
## changes by `TownRules.STEP` in the direction given; nothing else in the codebase is
## allowed to reach into `TownState` and set anything, which is what keeps a save
## honest — the log holds every change, so a replay arrives at the same kingdom.
##
## It answers with `town_moved`, carrying what the place now reads as, because the
## journal has to be able to say *why* the works went cold and the window has to be
## told something changed without watching a number.

func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type == &"settle_town":
		_settle(sim, event)
		return
	if event.type != &"move_town_value":
		return
	var towns := sim.store(&"towns") as TownState
	if towns == null:
		return
	var place: StringName = StringName(String(event.data.get("place", "")))
	var which: StringName = StringName(String(event.data.get("value", "")))
	var direction: int = int(event.data.get("direction", 0))
	var before: int = towns.value_of(place, which)
	if not towns.move(place, which, direction):
		# A place outside the system, a value that is not one of the two, a direction
		# of zero, or a number already at its floor or ceiling. None of those is an
		# error worth stopping for; all of them are worth being able to see in a log.
		sim.derive(&"town_unmoved", {"place": String(place), "value": String(which)})
		return
	sim.derive(&"town_moved", {
		"place": String(place),
		"value": String(which),
		"from": before,
		"to": towns.value_of(place, which),
		"look": String(towns.look_of(place)),
	})


## **Rule 6's freeze.** A place whose quest the player has resolved stops drifting: its
## story is told, nobody starves in it, and the weather cannot undo what was chosen.
func _settle(sim: Sim, event: SimEvent) -> void:
	var towns := sim.store(&"towns") as TownState
	if towns == null:
		return
	var place: StringName = StringName(String(event.data.get("place", "")))
	if towns.settle(place):
		sim.derive(&"town_settled", {"place": String(place),
			"look": String(towns.look_of(place))})


## Nothing sixty times a second.
func steps() -> bool:
	return false


## Nothing on the world's clock: the slow drift is `KingdomSystem`'s, because it is the
## kingdom redistributing rather than a place changing its own mind.
func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"towns"
