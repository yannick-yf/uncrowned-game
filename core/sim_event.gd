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
## Raised by a system rather than submitted from outside.
##
## The distinction is the whole of replay. External events — a key press, a tool,
## a test — are the record of what happened *to* the world and are re-injected
## when a run is rebuilt. Derived events are what the world said *back*, and they
## are recomputed from the same ticks and the same inputs. Replaying both would
## produce each derived event twice: once from the log, once from the system that
## raises it.
var derived: bool = false


func _init(
	p_step: int = 0,
	p_type: StringName = &"",
	p_data: Dictionary = {},
	p_derived: bool = false,
) -> void:
	step = p_step
	type = p_type
	data = p_data.duplicate(true)
	derived = p_derived


func to_dict() -> Dictionary:
	var row: Dictionary = {"step": step, "type": String(type), "data": data.duplicate(true)}
	if derived:
		row["derived"] = true
	return row


static func from_dict(row: Dictionary) -> SimEvent:
	var raw_data: Dictionary = row.get("data", {}) as Dictionary
	return SimEvent.new(
		int(row.get("step", 0)),
		StringName(row.get("type", "")),
		raw_data,
		bool(row.get("derived", false)),
	)


func _to_string() -> String:
	return "[s%d]%s %s %s" % [step, " ->" if derived else "", String(type), data]
