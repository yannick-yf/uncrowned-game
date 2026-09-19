class_name OutcomeSystem
extends SimSystem

## **What the act at the furnaces does to the place** (Q5).
##
## One act, two numbers and a freeze. `docs/QUEST_CINDERWORKS.md` §5: putting the fires
## out takes the Cinderworks from 6 and 4 to 3 and 1; lighting them again takes it to 9
## and 7. Both are one `TownRules.STEP` on each value, which is not a coincidence — the
## step is what one act of the player's is worth, and this is one act of the player's.
##
## **It writes nothing itself.** `TownSystem` is the only thing allowed to touch
## `TownState`, and it is reached the way everything reaches it: by an event. That is
## what keeps a save honest, because the log then holds every change and a replay
## arrives at the same kingdom.
##
## **And it fires once**, because `works_act` is derived once — `ActSystem` remembers the
## act as a fact rather than as a tile, so the second furnace raises nothing.

const DOWN: int = -1
const UP: int = 1


func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type != &"works_act":
		return
	var deed := StringName(String(event.data.get("deed", "")))
	var direction: int = _direction_of(deed)
	if direction == 0:
		return
	var place := StringName(String(event.data.get("town", "")))
	if place == &"":
		return
	for value: StringName in TownRules.BOTH:
		sim.derive(&"move_town_value", {
			"place": String(place), "value": String(value), "direction": direction,
		})
	# **Rule 6's freeze.** The place's story is told: the crown stops redistributing into
	# it, nobody starves in it, and the weather cannot undo what the player chose.
	sim.derive(&"settle_town", {"place": String(place)})


## Which way the two numbers go. Out of the deed rather than out of whose side the
## player took, because the act is the thing that happened and a side is only how they
## came to do it.
func _direction_of(deed: StringName) -> int:
	match deed:
		DeedRules.DEED_DOUSE:
			return DOWN
		DeedRules.DEED_RELIGHT:
			return UP
	return 0


## Nothing sixty times a second, and nothing on the world's clock: this answers an act.
func steps() -> bool:
	return false


func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"outcome"
