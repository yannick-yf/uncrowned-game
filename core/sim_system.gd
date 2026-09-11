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
## They never *submit* events — submit() is for things that happen to the world
## from outside it — but they may **derive** one with sim.derive(). A derived
## event is what the world says back: a killing seen, a rumour arriving, a price
## moving because an army shrank. It is logged so that a journal can explain why
## something happened, and it is recomputed rather than replayed, so the same run
## rebuilds without doubling it.
##
## This is what lets systems react to systems, which is the whole of SPECS §8's
## second consequence — the world reacting to what you broke rather than to you.

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
