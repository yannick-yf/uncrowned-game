class_name SimEvent
extends RefCounted

## One thing that happened.
##
## Events are the only record of anything. They are stamped with the tick on which
## they were submitted, appended to the log, and never modified afterwards —
## replaying the log has to reproduce the run exactly, and it cannot do that if the
## record can be edited after the fact.

var tick: int = 0
var type: StringName = &""
var data: Dictionary = {}


func _init(p_tick: int = 0, p_type: StringName = &"", p_data: Dictionary = {}) -> void:
	tick = p_tick
	type = p_type
	data = p_data.duplicate(true)


func to_dict() -> Dictionary:
	return {"tick": tick, "type": String(type), "data": data.duplicate(true)}


static func from_dict(row: Dictionary) -> SimEvent:
	var raw_data: Dictionary = row.get("data", {}) as Dictionary
	return SimEvent.new(int(row.get("tick", 0)), StringName(row.get("type", "")), raw_data)


func _to_string() -> String:
	return "[t%d] %s %s" % [tick, String(type), data]
