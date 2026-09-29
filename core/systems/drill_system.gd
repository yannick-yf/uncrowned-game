class_name DrillSystem
extends SimSystem

## **What a drill leaves behind** (O8, 2026-09-29): the fact that you passed it, a mended
## player, and the master speaking to you again — which is the way on to the next lesson.
##
## Passed or failed, the master mends you: a drill is practice, and nobody should walk
## from the tutorial to the bridge wolves on what it cost. `drilled:<id>` is read by the
## master's own next line and by nothing else (test_tutorial pins it): a lesson, not a
## gate.

const DRILLED: String = "drilled:%s"


func steps() -> bool:
	return false


func ticks() -> bool:
	return false


func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type != &"duel_ended":
		return
	var drill := StringName(String(event.data.get("drill", "")))
	if drill == &"":
		return
	if bool(event.data.get("passed", false)):
		sim.facts.add_source(StringName(DRILLED % drill), &"witnessed")
	var world := sim.store(&"world") as WorldState
	if world != null and world.player_hp > 0:
		world.player_hp = WorldState.MAX_HP
	var master: StringName = DuelRules.drill_master(drill)
	if master != &"" and not OpeningRules.is_gone(master, sim.facts):
		sim.derive(&"drill_over", {"drill": String(drill), "passed": bool(event.data.get("passed", false))})
		sim.derive(&"talk", {"npc": String(master)})
