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

## **The one flag** (MIGRATION_3D §6, M1b; flipped at M4, 2026-09-13). The world baked
## from the 3D workshop is the game: this class overlays the baked file's places and
## points on the content's anchors, and `Region.build_overworld()` loads the baked grid.
## `UNCROWNED_WORLD=procedural` in the environment plays the 2D map v1 and v2 were
## built on instead — kept for its tests and its history, never the default again.
## Read once, here, because `Region` initialises its sites from this class and the two
## must never disagree about which world they are in. A process is one world;
## switching means restarting.
const WORLD_ENV: String = "UNCROWNED_WORLD"
const BAKED: String = "baked"
const PROCEDURAL: String = "procedural"
const BAKED_PATH: String = "res://content/region.json"

## The same sentinel as `Region.NOWHERE`, spelled here on purpose: `Region` initialises
## its sites from this class while it is loading, and this class must not reach back
## into `Region` while that happens. A test asserts the two are equal.
const NOWHERE: Vector2i = Vector2i(-1, -1)

## Whether this process plays on the baked world — which it does unless asked for
## the procedural map by name.
static func baked() -> bool:
	return OS.get_environment(WORLD_ENV) != PROCEDURAL


## The world this process plays on, by name, for a save file to remember: a run's
## event log replayed on another world walks into walls.
static func world_id() -> String:
	return BAKED if baked() else PROCEDURAL

## Place id -> {"centre": Vector2i, "size": Vector2i}, in the file's order.
var _places: Dictionary = {}
var _order: Array[StringName] = []
var _points: Dictionary = {}
var _cast: Dictionary = {}
var _strangers: Array[Dictionary] = []
## The packs of the wood (W2): a kind, a count and an anchor, in the file's order.
var _wild: Array[Dictionary] = []
var _campfires: Array[Dictionary] = []
var _stalls: Array[Dictionary] = []
var _documents: Dictionary = {}
## Which places are placeholders the bake stamped because the map has not built them.
var _scaffold: Dictionary = {}
## The King's Road as a sequence of place and point ids, and the spurs off it —
## from the baked file; the procedural map keeps its own in `Region.road_route()`.
var _trunk: Array[StringName] = []
var _spurs: Dictionary = {}
## How fast a walker crosses this world, in tiles a second. The 2D map's figure until a
## baked world states its own (decision 1: walking follows the workshop).
var _tiles_per_second: float = MovementRules.TILES_PER_SECOND

static var _shared: Places = null


static func shared() -> Places:
	if _shared == null:
		_shared = load_from(PATH)
		if baked():
			_shared.overlay_world(BAKED_PATH)
	return _shared


## Take the places, points and road order from a baked world file, keeping every
## anchor the content wrote. A place the file lacks is dropped: the anchors that
## stand in it then resolve nowhere, and `test_anchors` names them.
func overlay_world(path: String) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return
	var world: Dictionary = parsed as Dictionary
	_places.clear()
	_order.clear()
	_scaffold.clear()
	for id: String in (world.get("places", {}) as Dictionary).keys():
		var row: Dictionary = (world["places"] as Dictionary)[id] as Dictionary
		_places[StringName(id)] = {
			"centre": _pair(row.get("centre", [0, 0])),
			"size": _pair(row.get("size", [1, 1])),
		}
		_order.append(StringName(id))
		if bool(row.get("scaffold", false)):
			_scaffold[StringName(id)] = true
	_points.clear()
	for id: String in (world.get("points", {}) as Dictionary).keys():
		var row: Variant = (world["points"] as Dictionary)[id]
		_points[StringName(id)] = _pair((row as Dictionary).get("at", [0, 0])) \
			if row is Dictionary else _pair(row)
	var pace: float = float(world.get("tiles_per_second", 0.0))
	if pace > 0.0:
		_tiles_per_second = pace
	_trunk.clear()
	for id: Variant in (world.get("trunk", []) as Array):
		_trunk.append(StringName(String(id)))
	_spurs.clear()
	for id: String in (world.get("spurs", {}) as Dictionary).keys():
		var legs: Array[StringName] = []
		for leg: Variant in ((world["spurs"] as Dictionary)[id] as Array):
			legs.append(StringName(String(leg)))
		_spurs[StringName(id)] = legs


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
	for entry: Variant in (root.get("wild", []) as Array):
		var row: Dictionary = entry as Dictionary
		places._wild.append({
			"kind": String(row.get("kind", "wolf")),
			"count": int(row.get("count", 1)),
			"anchor": _anchor(entry),
		})
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


## A placeholder the bake stamped, not a place the map has built.
func is_scaffold(id: StringName) -> bool:
	return _scaffold.has(id)


## The King's Road as ids, in order, when a baked world states it; empty otherwise.
func trunk() -> Array[StringName]:
	return _trunk.duplicate()


func spur(id: StringName) -> Array[StringName]:
	var legs: Array[StringName] = []
	for leg: StringName in (_spurs.get(id, []) as Array):
		legs.append(leg)
	return legs


## How fast a walker crosses this world, in tiles a second.
func tiles_per_second() -> float:
	return _tiles_per_second


## A place's centre or a point, by id — the two things a road runs between.
func node(id: StringName) -> Vector2i:
	if has_place(id):
		return centre(id)
	return point(id)


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
## Where the wood is dangerous, in the content file's order. The order is the pack's
## identity, the way the third watchman's is: a store that has killed pack 1 has killed
## the one this list puts second.
func wild() -> Array[Dictionary]:
	return _wild


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
