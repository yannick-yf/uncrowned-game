class_name OutcomeSystem
extends SimSystem

## **What the quest's two hinges do to the world** (Q5, then F6).
##
## Two things happen in the Cinderworks quest that the rest of the game has to answer:
## somebody is faced, and the furnaces are touched. Both arrive here as events and leave
## as events, and this system is the only thing that knows they belong to each other.
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
	if event.type == &"fight_ended":
		_faced(sim, event)
		return
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


## **Beating whoever stood in the way** (F6), which is the middle of §4's spine and the
## thing the furnaces wait for.
##
## Only a win counts. Losing sends the player back to the last fire with the works still
## closed to them, and walking away counts for nothing at all — which is what makes the
## fight the price of the act rather than a scene in front of it.
##
## **Written as a fact, from an event**, so it is in the log and a replay arrives at the
## same works. Until this existed, nothing wrote it and Q5 could not prove its own replay.
func _faced(sim: Sim, event: SimEvent) -> void:
	if String(event.data.get("how", "")) != "won":
		return
	var who := StringName(String(event.data.get("opponent", "")))
	if not SiteRules.stands_in_the_way(who, sim.facts):
		return
	if sim.facts.has(SiteRules.FACED):
		return
	sim.facts.add_source(SiteRules.FACED, who)
	sim.derive(&"faced_them", {"opponent": String(who)})


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
