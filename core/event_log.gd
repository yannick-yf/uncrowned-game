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


func external() -> Array[SimEvent]:
	var out: Array[SimEvent] = []
	for event: SimEvent in _events:
		if not event.derived:
			out.append(event)
	return out


## Everything, for reading: a journal, an audit, a question about why something
## happened. Use external_rows() to rebuild a run.
func to_array() -> Array:
	var out: Array = []
	for event: SimEvent in _events:
		out.append(event.to_dict())
	return out


## What a save file needs, and what replay re-injects: the events that came from
## outside. Everything the world said back is recomputed rather than restored.
func external_rows() -> Array:
	var out: Array = []
	for event: SimEvent in _events:
		if not event.derived:
			out.append(event.to_dict())
	return out


static func from_array(rows: Array) -> EventLog:
	var restored := EventLog.new()
	for row: Variant in rows:
		restored.append(SimEvent.from_dict(row as Dictionary))
	return restored
