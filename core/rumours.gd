class_name Rumours
extends RefCounted

## Every story currently in the air.
##
## A store like any other, rebuilt by replay. Rumours are dropped once they have
## reached everywhere they are going — the world does not keep a permanent record
## of gossip, only of what the gossip did to people's opinion of you.

var live: Array[Rumour] = []
var next_id: int = 1
var told: int = 0


func start(about: StringName, origin: StringName, witnesses: PackedStringArray, step: int) -> Rumour:
	var rumour := Rumour.new()
	rumour.id = next_id
	next_id += 1
	rumour.about = about
	rumour.origin = origin
	rumour.witnesses = witnesses
	rumour.started_step = step
	live.append(rumour)
	told += 1
	return rumour


func fingerprint() -> String:
	var parts := PackedStringArray()
	for rumour: Rumour in live:
		parts.append("%d:%s:%s:%.1f:%d" % [
			rumour.id, String(rumour.about), String(rumour.origin),
			rumour.reach, rumour.arrived.size(),
		])
	return "n=%d told=%d %s" % [next_id, told, ";".join(parts)]
