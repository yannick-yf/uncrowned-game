class_name EventLog
extends RefCounted

## Append-only. The single authoritative record of a run.
##
## Everything else in core/ is derived state that can be thrown away and rebuilt by
## replaying this. That is what makes a save file a log rather than a snapshot of
## every node in the scene tree.

var _events: Array[SimEvent] = []


func append(event: SimEvent) -> void:
	_events.append(event)


func size() -> int:
	return _events.size()


func at(index: int) -> SimEvent:
	return _events[index]


func all() -> Array[SimEvent]:
	return _events.duplicate()


func of_type(type: StringName) -> Array[SimEvent]:
	var out: Array[SimEvent] = []
	for event: SimEvent in _events:
		if event.type == type:
			out.append(event)
	return out


## Serialisable form. Round-trips through to_array/from_array without loss.
func to_array() -> Array:
	var out: Array = []
	for event: SimEvent in _events:
		out.append(event.to_dict())
	return out


static func from_array(rows: Array) -> EventLog:
	var restored := EventLog.new()
	for row: Variant in rows:
		restored.append(SimEvent.from_dict(row as Dictionary))
	return restored
