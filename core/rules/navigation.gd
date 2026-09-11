class_name Navigation
extends RefCounted

## Breadth-first path over passable ground. Pure, deterministic, no state.
##
## Exists because greedy steering cannot get round a building: point a walker at a
## target and they will press into the first wall between them and it. The tests
## walk the world the way a player does rather than by teleporting, so they need to
## be able to find their way; NPCs and the reachability walk will want the same.

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]


## Tiles from `from` to `to` inclusive, or empty if there is no way through.
static func path(region: Region, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if region == null or not region.is_passable(to):
		return []
	if from == to:
		return [from]

	var came_from: Dictionary = {from: from}
	var queue: Array[Vector2i] = [from]
	var head: int = 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		if tile == to:
			return _unwind(came_from, from, to)
		for step: Vector2i in DIRECTIONS:
			var next: Vector2i = tile + step
			if came_from.has(next) or not region.is_passable(next):
				continue
			came_from[next] = tile
			queue.append(next)
	return []


static func _unwind(came_from: Dictionary, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = [to]
	var tile: Vector2i = to
	while tile != from:
		tile = came_from[tile] as Vector2i
		out.append(tile)
	out.reverse()
	return out


## The same path thinned to steering targets: a walker re-aiming at every tile
## wastes events, and one every few tiles is what a hand on a keyboard does.
static func waypoints(region: Region, from: Vector2i, to: Vector2i, spacing: int = 4) -> Array[Vector2]:
	var tiles: Array[Vector2i] = path(region, from, to)
	var out: Array[Vector2] = []
	for i: int in tiles.size():
		if i % spacing == 0 or i == tiles.size() - 1:
			out.append(Vector2(tiles[i]) + Vector2(0.5, 0.5))
	return out
