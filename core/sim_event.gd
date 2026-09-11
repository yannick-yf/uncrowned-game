class_name SimEvent
extends RefCounted

## One thing that happened.
##
## Events are the only record of anything. They are stamped with the simulation
## step on which they were submitted, appended to the log, and never modified
## afterwards — replaying the log has to reproduce the run exactly, and it cannot
## do that if the record can be edited after the fact.
##
## The stamp is the *step*, not the world tick: two key presses inside the same
## in-game minute are two different events and must replay in the right order.

var step: int = 0
var type: StringName = &""
var data: Dictionary = {}


func _init(p_step: int = 0, p_type: StringName = &"", p_data: Dictionary = {}) -> void:
	step = p_step
	type = p_type
	data = p_data.duplicate(true)


func to_dict() -> Dictionary:
	return {"step": step, "type": String(type), "data": data.duplicate(true)}


static func from_dict(row: Dictionary) -> SimEvent:
	var raw_data: Dictionary = row.get("data", {}) as Dictionary
	return SimEvent.new(int(row.get("step", 0)), StringName(row.get("type", "")), raw_data)


func _to_string() -> String:
	return "[s%d] %s %s" % [step, String(type), data]
