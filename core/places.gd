class_name Places
extends RefCounted

## Where things stand, as data. Loaded once from content/places.json.
##
## **A position is an anchor, never a coordinate** (MIGRATION_3D §6.2). Content says
## what it stands next to — Pell at the Wide Acres, Kell at his fire, a stall on the
## north edge of Saltmarch — and this file turns that into a tile. When the map moves
## under the content, the content moves with it, because it never knew where it was.
##
## Three forms, each a Dictionary:
##   {"place": "harrowgate", "offset": [dx, dy]}          a place's centre, plus an offset
##   {"point": "clearing", "offset": [dx, dy]}            a named point, plus an offset
##   {"place": "harrowgate", "feature": "inn", "offset": [dx, dy]}
##                                                        a prop of that kind standing in the
##                                                        place — which only a built Region can
##                                                        answer, so `Region.resolve` handles it
##
## This class knows places and points. It knows nothing about terrain, props or zones,
## which is what lets `Region` read its sites from here without a cycle.

const PATH: String = "res://content/places.json"

## The same sentinel as `Region.NOWHERE`, spelled here on purpose: `Region` initialises
## its sites from this class while it is loading, and this class must not reach back
## into `Region` while that happens. A test asserts the two are equal.
const NOWHERE: Vector2i = Vector2i(-1, -1)

## Place id -> {"centre": Vector2i, "size": Vector2i}, in the file's order.
var _places: Dictionary = {}
var _order: Array[StringName] = []
var _points: Dictionary = {}
var _cast: Dictionary = {}
var _strangers: Array[Dictionary] = []
var _campfires: Array[Dictionary] = []
var _stalls: Array[Dictionary] = []
var _documents: Dictionary = {}

static var _shared: Places = null


static func shared() -> Places:
	if _shared == null:
		_shared = load_from(PATH)
	return _shared


static func load_from(path: String) -> Places:
	var places := Places.new()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return places
	var root: Dictionary = parsed as Dictionary

	for id: String in (root.get("places", {}) as Dictionary).keys():
		var row: Dictionary = (root["places"] as Dictionary)[id] as Dictionary
		places._places[StringName(id)] = {
			"centre": _pair(row.get("centre", [0, 0])),
			"size": _pair(row.get("size", [1, 1])),
		}
		places._order.append(StringName(id))

	for id: String in (root.get("points", {}) as Dictionary).keys():
		places._points[StringName(id)] = _pair((root["points"] as Dictionary)[id])

	for id: String in (root.get("cast", {}) as Dictionary).keys():
		places._cast[StringName(id)] = _anchor((root["cast"] as Dictionary)[id])

	for entry: Variant in (root.get("strangers", []) as Array):
		places._strangers.append(_anchor(entry))
	for entry: Variant in (root.get("campfires", []) as Array):
		places._campfires.append(_anchor(entry))
	for entry: Variant in (root.get("stalls", []) as Array):
		places._stalls.append(_anchor(entry))

	for fact: String in (root.get("documents", {}) as Dictionary).keys():
		places._documents[StringName(fact)] = _anchor((root["documents"] as Dictionary)[fact])
	return places


static func _pair(value: Variant) -> Vector2i:
	var pair: Array = value as Array
	if pair == null or pair.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(pair[0]), int(pair[1]))


## An anchor as read from the file, with typed names and a typed offset, and nothing
## else copied in — the `_why` a content file may carry is for the reader of the file.
static func _anchor(value: Variant) -> Dictionary:
	var row: Dictionary = value as Dictionary
	if row == null:
		return {}
	var out: Dictionary = {"offset": _pair(row.get("offset", [0, 0]))}
	if row.has("place"):
		out["place"] = StringName(String(row["place"]))
	if row.has("point"):
		out["point"] = StringName(String(row["point"]))
	if row.has("feature"):
		out["feature"] = StringName(String(row["feature"]))
	if row.has("kind"):
		out["kind"] = StringName(String(row["kind"]))
	if row.has("zone"):
		out["zone"] = StringName(String(row["zone"]))
	return out


# ----------------------------------------------------------------- places ---

## The places, in the order the file lists them — which is the zone order.
func ids() -> Array[StringName]:
	return _order.duplicate()


func has_place(id: StringName) -> bool:
	return _places.has(id)


func centre(id: StringName) -> Vector2i:
	if not _places.has(id):
		return NOWHERE
	return (_places[id] as Dictionary)["centre"] as Vector2i


func size(id: StringName) -> Vector2i:
	if not _places.has(id):
		return Vector2i.ONE
	return (_places[id] as Dictionary)["size"] as Vector2i


func has_point(id: StringName) -> bool:
	return _points.has(id)


func point(id: StringName) -> Vector2i:
	return _points.get(id, NOWHERE) as Vector2i


# ---------------------------------------------------------------- content ---

func cast_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in _cast.keys():
		out.append(id)
	return out


## Where a named person stands, or an empty dictionary for somebody the file does
## not place.
func cast_anchor(id: StringName) -> Dictionary:
	return _cast.get(id, {}) as Dictionary


## The strangers' placements, in order. The order is the id: the third watchman in
## the file is `watchman@3`.
func strangers() -> Array[Dictionary]:
	return _strangers.duplicate()


func campfires() -> Array[Dictionary]:
	return _campfires.duplicate()


func stalls() -> Array[Dictionary]:
	return _stalls.duplicate()


func document(fact: StringName) -> Dictionary:
	return _documents.get(fact, {}) as Dictionary


# ------------------------------------------------------------- resolution ---

## A place or point anchor as a tile, or NOWHERE. Feature anchors need a built
## region and come back NOWHERE from here; ask `Region.resolve` for those.
func locate(anchor: Dictionary) -> Vector2i:
	if anchor.is_empty() or anchor.has("feature"):
		return NOWHERE
	var offset: Vector2i = anchor.get("offset", Vector2i.ZERO) as Vector2i
	if anchor.has("place"):
		var id: StringName = anchor["place"] as StringName
		return centre(id) + offset if has_place(id) else NOWHERE
	if anchor.has("point"):
		var id: StringName = anchor["point"] as StringName
		return point(id) + offset if has_point(id) else NOWHERE
	return NOWHERE


## An anchor as a reader would write it: `harrowgate.inn+(2,-3)`, `clearing+(0,-1)`.
## For the message that names what did not resolve.
static func describe(anchor: Dictionary) -> String:
	if anchor.is_empty():
		return "(no anchor)"
	var name: String = String(anchor.get("place", anchor.get("point", &"?")))
	if anchor.has("feature"):
		name += ".%s" % String(anchor["feature"])
	var offset: Vector2i = anchor.get("offset", Vector2i.ZERO) as Vector2i
	return "%s+(%d,%d)" % [name, offset.x, offset.y]
