class_name Travellers
extends RefCounted

## Everybody on the road. A store like any other, rebuilt by replay.

var walkers: Array[Traveller] = []
var next_id: int = 1
## How many stories have been handed to a town by somebody who walked there.
var deliveries: int = 0


func add(at: Vector2, leg: int, heading: int) -> Traveller:
	var walker := Traveller.new()
	walker.id = next_id
	next_id += 1
	walker.pos = at
	walker.leg = leg
	walker.heading = heading
	walkers.append(walker)
	return walker


func carrying_count() -> int:
	var total: int = 0
	for walker: Traveller in walkers:
		total += walker.carrying.size()
	return total


func fingerprint() -> String:
	var parts := PackedStringArray()
	for walker: Traveller in walkers:
		parts.append("%d:%.2f,%.2f:%d:%d:%d" % [
			walker.id, walker.pos.x, walker.pos.y, walker.leg,
			walker.heading, walker.carrying.size(),
		])
	return "n=%d delivered=%d %s" % [next_id, deliveries, ";".join(parts)]
