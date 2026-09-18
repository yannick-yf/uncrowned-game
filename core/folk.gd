class_name Folk
extends RefCounted

## The people of a place, walking to work.
##
## **Furniture that moves, like the road's travellers** — no names, no opinions, no
## schedule. What they are for is one thing: a town that has stopped is a town where
## nobody walks to the mine any more, and that is the strongest sentence the game can
## say without a word of text.
##
## How many of them go is richesse's answer, by the same rule that decides how many
## furnaces burn (`TownRules.lit_of`). Where they go is `content/towns.json`'s, so the
## count and the destination are content rather than code.
##
## A store like any other: rebuilt by replay, holding nothing the log did not put there.
## Their positions are derived from the route and the population, both deterministic,
## so a replay walks them back to the same tiles.

const PATH: String = "res://content/towns.json"

static var _routines: Dictionary = {}

## {id, place, pos, leg, heading}. A dictionary rather than a class of its own: they
## carry less than a traveller does, and a traveller carries almost nothing.
var walkers: Array[Dictionary] = []
var next_id: int = 1
## Place -> the waypoints of its walk, worked out once from the region.
var _routes: Dictionary = {}


## What each place puts on the road at its ceiling, and where it walks to.
static func routines() -> Dictionary:
	if not _routines.is_empty():
		return _routines
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not (parsed is Dictionary):
		return _routines
	for id: String in ((parsed as Dictionary).get("routines", {}) as Dictionary).keys():
		var row: Dictionary = ((parsed as Dictionary)["routines"] as Dictionary)[id] as Dictionary
		_routines[StringName(id)] = {
			"count": maxi(int(row.get("count", 0)), 0),
			"to_point": StringName(String(row.get("to_point", ""))),
		}
	return _routines


static func places() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in routines().keys():
		out.append(id)
	return out


static func count_in(place: StringName) -> int:
	return int((routines().get(place, {}) as Dictionary).get("count", 0))


## The walk of a place, from its centre to the point its routine names. Worked out
## once and kept: it comes from the region, which does not move under a run.
func route_in(region: Region, place: StringName) -> Array[Vector2]:
	if _routes.has(place):
		return _routes[place] as Array[Vector2]
	var out: Array[Vector2] = []
	var places: Places = Places.shared()
	var to_point: StringName = (routines().get(place, {}) as Dictionary).get("to_point", &"") as StringName
	if region != null and places.has_place(place) and places.has_point(to_point):
		out = Navigation.waypoints(region, places.centre(place), places.point(to_point))
	_routes[place] = out
	return out


func in_place(place: StringName) -> int:
	var total: int = 0
	for walker: Dictionary in walkers:
		if (walker["place"] as StringName) == place:
			total += 1
	return total


func fingerprint() -> String:
	var parts := PackedStringArray()
	for walker: Dictionary in walkers:
		parts.append("%d:%s:%.2f,%.2f:%d:%d" % [int(walker["id"]), String(walker["place"]),
			(walker["pos"] as Vector2).x, (walker["pos"] as Vector2).y,
			int(walker["leg"]), int(walker["heading"])])
	return "n=%d %s" % [next_id, ";".join(parts)]
