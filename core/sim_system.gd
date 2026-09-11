class_name SimSystem
extends RefCounted

## Systems react. They read events and ticks, and they write facts.
##
## A system holds no state of its own: everything it learns goes into the fact base,
## because replay constructs fresh systems and must arrive at the same world. If you
## find yourself wanting a member variable here, it belongs in the fact base.
##
## Systems never touch the event log directly and never know that view/ exists.
##
## They also never submit events. Events come from outside the sim — the view,
## tools, tests — because replay re-injects every logged event: a system that
## submitted one would log it live and submit it again on replay, doubling it. A
## system's consequences are derived state, and replay recomputes them from the
## same ticks and the same events. If a system ever genuinely needs to raise an
## event, the log has to distinguish external events from derived ones first.

func on_event(_sim: Sim, _event: SimEvent) -> void:
	pass


## Every simulation step — 60 a second. Anything the player feels belongs here:
## movement, collision, arriving somewhere. Input submitted this step is already
## dispatched by the time it runs.
func on_step(_sim: Sim, _step: int) -> void:
	pass


## Every world tick — one in-game minute, 4 a second (SPECS §8). The twelve
## drifting quantities belong here. Nothing the player's hands can feel does.
func on_tick(_sim: Sim, _tick: int) -> void:
	pass


func system_name() -> StringName:
	return &"system"
