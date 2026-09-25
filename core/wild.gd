class_name Wild
extends RefCounted

## **What lives on the roads the demo does not want you on** (W2).
##
## `docs/COMBAT_V2.md` §6: monsters live in the forest and never in the towns. This is
## the store that knows where they stand, and it is deliberately the smallest thing that
## can be true — **a pack is a place and a count**, and nothing else.
##
## **They do not roam.** A pack stands on its stretch of road until somebody walks into
## it, and then it is a fight. Wandering animals are a second system with a second set
## of bugs, and the demo does not need one: what the wolves are for is to make one road
## plainly safer than the others, and a pack that stays put does that.
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

static var _packs: Array[Dictionary] = []


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


## Where each pack stands, resolved against the world it is in.
func at(region: Region, which: int) -> Vector2i:
	var all: Array[Dictionary] = packs()
	if which < 0 or which >= all.size() or region == null:
		return Vector2i(-1, -1)
	return region.resolve(all[which].get("anchor", {}) as Dictionary)


## How many of them, and of what. Two fields, which is the whole of a pack.
func count_of(which: int) -> int:
	var all: Array[Dictionary] = packs()
	return int(all[which].get("count", 1)) if which >= 0 and which < all.size() else 0


func kind_of(which: int) -> StringName:
	var all: Array[Dictionary] = packs()
	return StringName(String(all[which].get("kind", "wolf"))) \
		if which >= 0 and which < all.size() else &"wolf"


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
		var tile: Vector2i = at(region, which)
		if tile.x >= 0:
			out[tile] = which
	return out


func fingerprint() -> String:
	return "wild cleared=%d fighting=%d" % [cleared.size(), fighting]
