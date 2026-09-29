class_name Walkers
extends RefCounted

## **Where a named person actually stands, when it is not where content put them** (O7,
## 2026-09-29).
##
## A person is content — resolved once from `content/places.json` onto `Npc.tile`, and
## the shared `Cast` is never written. Until the opening's redo nobody named ever moved.
## Now a fight moves them and the tutorial will move them on purpose, so the world keeps
## the displaced here, rebuilt by replay like any other store, and everything that asks
## where somebody is — the interact key, a witness, the fight, both windows, the
## journal — asks `where()`. Somebody not in it stands on their anchor, as always.

## id -> the tile they stand on.
var at: Dictionary = {}
## id -> steps left before they start back to their post.
var linger: Dictionary = {}
## id -> the tiles still to walk home, first one next.
var path: Dictionary = {}
## id -> steps into the tile they are walking to.
var walked: Dictionary = {}


## Left standing somewhere else than their post, as a fight or a walk leaves them.
func place(id: StringName, tile: Vector2i, post: Vector2i) -> void:
	if tile == post:
		release(id)
		return
	at[id] = tile
	linger[id] = WalkerRules.linger_steps()
	path.erase(id)
	walked.erase(id)


func release(id: StringName) -> void:
	at.erase(id)
	linger.erase(id)
	path.erase(id)
	walked.erase(id)


func is_displaced(id: StringName) -> bool:
	return at.has(id)


## The tile somebody stands on: where the world left them, or their post.
func where(npc: Npc) -> Vector2i:
	return at.get(npc.id, npc.tile) as Vector2i


## Where to draw them, between the tile they stand on and the next one on their way.
func drawn_at(npc: Npc) -> Vector2:
	var here: Vector2 = Vector2(where(npc)) + Vector2(0.5, 0.5)
	var ahead: Array = path.get(npc.id, []) as Array
	if ahead.is_empty():
		return here
	var through: float = float(int(walked.get(npc.id, 0))) / float(maxi(WalkerRules.steps_per_tile(), 1))
	return here.lerp(Vector2(ahead[0] as Vector2i) + Vector2(0.5, 0.5), clampf(through, 0.0, 1.0))


## The centre of the tile somebody stands on, for a rule that measures distance to them.
## Static, so a rule handed no store reads the anchor exactly as it always did.
static func centre_of(npc: Npc, walkers: Walkers) -> Vector2:
	if walkers == null:
		return npc.centre()
	return Vector2(walkers.where(npc)) + Vector2(0.5, 0.5)


func fingerprint() -> String:
	var ids: Array = at.keys()
	ids.sort()
	var parts := PackedStringArray()
	for id: Variant in ids:
		parts.append("%s@%s l%d w%d p%d" % [id, at[id], int(linger.get(id, 0)),
			int(walked.get(id, 0)), (path.get(id, []) as Array).size()])
	return ";".join(parts)
