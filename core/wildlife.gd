class_name Wildlife
extends RefCounted

## Everything currently alive and near enough to matter.
##
## A store, like the world: rebuilt by replay rather than saved. The population is
## never larger than what fits around the player, which is why a map of 56,000
## tiles costs nothing to fill with animals.

var beasts: Array[Beast] = []
var next_id: int = 1
var bites_taken: int = 0


func count() -> int:
	return beasts.size()


func add(kind: StringName, at: Vector2) -> Beast:
	var beast := Beast.new()
	beast.id = next_id
	next_id += 1
	beast.kind = kind
	beast.pos = at
	beasts.append(beast)
	return beast


func fingerprint() -> String:
	var parts := PackedStringArray()
	for beast: Beast in beasts:
		parts.append("%d:%s:%.3f,%.3f:%s" % [
			beast.id, String(beast.kind), beast.pos.x, beast.pos.y, beast.hunting,
		])
	return "n=%d bites=%d %s" % [next_id, bites_taken, ";".join(parts)]
