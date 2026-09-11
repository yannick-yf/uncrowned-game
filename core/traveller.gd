class_name Traveller
extends RefCounted

## Somebody walking the King's Road, who is nobody.
##
## Deliberately not a person: no name, no home town, no schedule, and no opinion of
## the player — §21's cut on NPC routines stands, and this is furniture that moves.
## A traveller can never *be* a source. Every story has a named witness behind it
## and a traveller only ever carries one that already exists, which is what keeps
## the rumour system from acquiring anonymous sources it cannot attribute.

var id: int = 0
var pos: Vector2 = Vector2.ZERO
## Where along Region.road_waypoints() they are, and which way they are walking.
var leg: int = 0
var heading: int = 1
## Rumour ids picked up by recognising the player on the road.
var carrying: PackedInt32Array = PackedInt32Array()
## The last town walked into, so arriving is an event and standing still is not.
var last_town: StringName = &""


func tile() -> Vector2i:
	return Vector2i(floori(pos.x), floori(pos.y))


func is_carrying(rumour_id: int) -> bool:
	return carrying.has(rumour_id)
