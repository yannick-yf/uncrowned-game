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
## **How near the master must be to speak** (the review of O8), in tiles. Beside you he
## turns and speaks — a talk opened from sixteen tiles away was a voice from nowhere.
## **Further off, he comes over** (the review of O21): a lesson that ended with the two
## of you at its opposite edges ended in silence, and the last one sent nobody on to the
## works; now he walks to you, as he did at the hail, and speaks when he is beside you.
const SPEAKS_WITHIN: float = 4.0


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
	sim.derive(&"drill_over", {"drill": String(drill), "passed": bool(event.data.get("passed", false))})
	var cast := sim.store(&"cast") as Cast
	var him: Npc = cast.get_npc(master) if cast != null else null
	if him == null or world == null or OpeningRules.is_gone(master, sim.facts):
		return
	var where: Vector2 = Walkers.centre_of(him, sim.store(&"walkers") as Walkers)
	var passed: bool = bool(event.data.get("passed", false))
	if world.player_pos.distance_to(where) <= SPEAKS_WITHIN:
		# He speaks to the lesson just done (the review of O21): the talk says which, and
		# how it went, and `DialogueSystem` turns that into his first words.
		sim.derive(&"talk", {"npc": String(master), "after": String(drill), "passed": passed})
	else:
		# Further than that he comes over first, as he came over at the hail — the
		# hail's own walk, without its shout — and speaks when he is beside you.
		sim.derive(&"summon", {"who": String(master), "after": String(drill), "passed": passed})
