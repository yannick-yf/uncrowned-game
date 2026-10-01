class_name Wild
extends RefCounted

## **What lives on the roads the demo does not want you on** (W2).
##
## `docs/COMBAT_V2.md` §6: monsters live in the forest and never in the towns. This is
## the store that knows where they stand, and it is deliberately the smallest thing that
## can be true — **a pack is a place and a count**, and nothing else.
##
## **They wander a little, and they look** (R2, 2026-10-01 — until then they stood still
## and a fight began only when the player touched them). Each pack walks about its own
## ground — `DuelRules.roams_of` tiles round its anchor — stopping to look one way and
## another, and sees what is in the cone in front of it (`DuelRules.sight_of`). Yannick:
## *« les loups peuvent un peu bouger dans leurs territoires, cela rend la mécanique plus
## dynamique »*. Where a pack is and where it looks are this store's, moved by `WildSystem`
## on the simulation's own steps, so a replay walks them exactly again.
##
## **Where they stand is content** (`content/places.json`, the `wild` block), the same
## discipline the routines already follow — `CLAUDE.md`: anything positional is an
## anchor and never a tile constant in a `.gd`.
##
## A store like any other: rebuilt by replay, holding nothing the log did not put there.
## What a replay rebuilds is which packs are *gone*, and that is read from the duels the
## log already holds rather than kept in step by a flag of its own.

## Pack -> true, for the ones that have been killed. The key is the pack's index, which
## is its order in the content file: the same discipline the strangers use, where "the
## third watchman" is an identity because the list is ordered.
var cleared: Dictionary = {}

## Which pack the fight now running belongs to, or -1. Set when a fight begins and read
## when it ends, because `duel_ended` says who you fought and not which pack they were.
var fighting: int = -1
## Pack -> where its leader stands now, which way the pack looks, where it is walking to,
## and how many of `WildSystem.PACE` it rests before choosing again. Empty until a pack
## first moves: then its anchor and its content's facing.
var spot: Dictionary = {}
var facing: Dictionary = {}
var goal: Dictionary = {}
var rest: Dictionary = {}
## **Not state, a shortcut** (R2): the step before which no pack can see the player, because
## every one is further than it sees plus the ground he and it can cover meanwhile, and the
## tile he stood on when that was worked out. Rebuilt by any replay; not in the fingerprint.
var quiet_until: int = -1
var quiet_from: Vector2i = Vector2i(-99999, -99999)

static var _packs: Array[Dictionary] = []

## Where each pack stands in the world `_tiles_for`, for the content `_tiles_of` (see `at`).
var _tiles_for: Region = null
var _tiles_of: Array[Dictionary] = []
var _tiles: Array[Vector2i] = []


## The packs, from the content file, in order. Anchors rather than tiles, so a pack that
## names the road it watches survives the map moving under it.
static func packs() -> Array[Dictionary]:
	if not _packs.is_empty():
		return _packs
	for row: Dictionary in Places.shared().wild():
		_packs.append(row)
	return _packs


## Only used by tests that change the content under the store.
static func forget() -> void:
	_packs = []
	_kinds = []


## **Where a pack stands now**: where it has walked to, or its own ground.
func now_at(region: Region, which: int) -> Vector2i:
	if spot.has(which):
		return spot[which] as Vector2i
	return at(region, which)


## Which way a pack looks now: where it last turned, or its content's facing.
func looks(which: int) -> Vector2i:
	if facing.has(which):
		return facing[which] as Vector2i
	var all: Array[Dictionary] = packs()
	return all[which].get("faces", Vector2i(0, 1)) as Vector2i if which >= 0 and which < all.size() else Vector2i(0, 1)


## **Where each animal of a pack stands** — the leader where the pack is, the others on
## the free tiles round him in a fixed order — so the window draws them where a fight
## begins with them, and a blade can be brought to one of them (R3).
const AROUND: Array[Vector2i] = [Vector2i(0, 0), Vector2i(-1, 1), Vector2i(1, 1), Vector2i(0, 2),
	Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(2, 1), Vector2i(0, 1)]


func members(region: Region, which: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if region == null:
		return out
	var lead: Vector2i = now_at(region, which)
	var look: Vector2i = looks(which)
	for offset: Vector2i in AROUND:
		if out.size() >= count_of(which):
			break
		# The others stand behind him, the way he looks being his front.
		var tile: Vector2i = lead + _behind(offset, look)
		if offset == Vector2i.ZERO or region.is_passable(tile):
			out.append(tile)
	while out.size() < count_of(which):
		out.append(lead)
	return out


## An offset written for a pack looking north (-y), turned to the way it looks.
static func _behind(offset: Vector2i, look: Vector2i) -> Vector2i:
	if look == Vector2i.ZERO:
		return offset
	var angle: float = Vector2(look).angle() - Vector2(0, -1).angle()
	var turned: Vector2 = Vector2(offset).rotated(angle)
	return Vector2i(int(round(turned.x)), int(round(turned.y)))


## Where each pack's ground is, resolved against the world it is in: its anchor.
func at(region: Region, which: int) -> Vector2i:
	var all: Array[Dictionary] = packs()
	if which < 0 or which >= all.size() or region == null:
		return Vector2i(-1, -1)
	# **Resolved once per world, not once per step** (T4, 2026-09-29). `standing` is asked
	# every step, and resolving the anchors was the largest single cost of a simulated day.
	# Where a pack stands depends only on the world and the content, so the answer is kept
	# for as long as both are the same objects. Not state: nothing a replay rebuilds.
	if region != _tiles_for or not is_same(all, _tiles_of):
		_tiles_for = region
		_tiles_of = all
		_tiles = []
		for row: Dictionary in all:
			_tiles.append(region.resolve(row.get("anchor", {}) as Dictionary))
	return _tiles[which]


## How many of them, and of what. Two fields, which is the whole of a pack.
func count_of(which: int) -> int:
	var all: Array[Dictionary] = packs()
	return int(all[which].get("count", 1)) if which >= 0 and which < all.size() else 0


## Asked every step of every pack (R2), so the names are made once.
static var _kinds: Array[StringName] = []


func kind_of(which: int) -> StringName:
	var all: Array[Dictionary] = packs()
	if _kinds.size() != all.size():
		_kinds = []
		for row: Dictionary in all:
			_kinds.append(StringName(String(row.get("kind", "wolf"))))
	return _kinds[which] if which >= 0 and which < _kinds.size() else &"wolf"


## Everything still standing, as tile -> pack index, for the window to draw and for the
## simulation to bump into. A pack that has been killed is not hidden, it is **gone**.
func standing(region: Region) -> Dictionary:
	var out: Dictionary = {}
	# No packs before the world exists; a bare simulation has no roads to stand on.
	if region == null:
		return out
	for which: int in packs().size():
		if cleared.has(which):
			continue
		var tile: Vector2i = now_at(region, which)
		if tile.x >= 0:
			out[tile] = which
	return out


func fingerprint() -> String:
	var where := PackedStringArray()
	for which: Variant in spot.keys():
		where.append("%d@%s>%s" % [which, spot[which], facing.get(which, Vector2i.ZERO)])
	return "wild cleared=%d fighting=%d %s" % [cleared.size(), fighting, ",".join(where)]
