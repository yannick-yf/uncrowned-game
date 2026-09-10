class_name SimSystem
extends RefCounted

## Systems react. They read events and ticks, and they write facts.
##
## A system holds no state of its own: everything it learns goes into the fact base,
## because replay constructs fresh systems and must arrive at the same world. If you
## find yourself wanting a member variable here, it belongs in the fact base.
##
## Systems never touch the event log directly and never know that view/ exists.

func on_event(_sim: Sim, _event: SimEvent) -> void:
	pass


func on_tick(_sim: Sim, _tick: int) -> void:
	pass


func system_name() -> StringName:
	return &"system"
