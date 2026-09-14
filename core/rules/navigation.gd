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


## What a step onto the king's ground costs against a step on ground nobody watches,
## when a walk is asked to keep off the road. Ten: crossing a three-wide road where
## you must is thirty, running a hundred tiles along it is a thousand, and a detour
## of any plausible length beats the second and never the first.
const WATCHED_COST: int = 10


## Tiles from `from` to `to` inclusive, or empty if there is no way through.
##
## `off_road` is the wild line as §4 means it: the walk that spends the least time on
## ground the crown watches (Region.is_watched). It cannot be "never" — the King's
## Road runs from the south-east coast to the castle against the mountains and seals
## the east, so every way to Blackcairn crosses it at least once — so watched tiles
## are *dear* rather than forbidden, and the line crosses where it must and never runs
## along. That is also what sends it over the ford: the bridge is the road's.
static func path(region: Region, from: Vector2i, to: Vector2i, off_road: bool = false) -> Array[Vector2i]:
	if region == null or not region.is_passable(to):
		return []
	if from == to:
		return [from]
	return _dearest_path(region, from, to) if off_road else _shortest_path(region, from, to)


## Breadth-first: every step costs one.
static func _shortest_path(region: Region, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
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
			if came_from.has(next) or not _can_step(region, tile, step):
				continue
			came_from[next] = tile
			queue.append(next)
	return []


## Cheapest-first, with two prices: one for ground nobody watches, WATCHED_COST for
## the king's. Integer costs, so the frontier is a row of buckets rather than a heap —
## bucket c is finished before anything in c + 1 is looked at, and a tile pushed into
## a later bucket at a higher price is skipped when its turn comes.
static func _dearest_path(region: Region, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var best: Dictionary = {from: 0}
	var came_from: Dictionary = {from: from}
	var buckets: Array[Array] = [[from]]
	var cost: int = 0
	while cost < buckets.size():
		for tile: Vector2i in buckets[cost]:
			if int(best[tile]) != cost:
				continue
			if tile == to:
				return _unwind(came_from, from, to)
			for step: Vector2i in DIRECTIONS:
				var next: Vector2i = tile + step
				if not _can_step(region, tile, step):
					continue
				var price: int = cost + (WATCHED_COST if region.is_watched(next) else 1)
				if best.has(next) and int(best[next]) <= price:
					continue
				best[next] = price
				came_from[next] = tile
				while buckets.size() <= price:
					buckets.append([])
				buckets[price].append(next)
		cost += 1
	return []


## Whether a walker can take this step: the tile is passable, and a diagonal does not
## cut a corner.
##
## **No cutting corners.** A diagonal step between two blocked tiles is a move a
## walker cannot make: movement slides each axis separately, so it tries x, fails,
## tries y, fails, and stands there. Breadth-first search was happy to squeeze
## through and every journey test failed the day the wood closed, with a path that
## existed and could not be walked.
static func _can_step(region: Region, tile: Vector2i, step: Vector2i) -> bool:
	if not region.is_passable(tile + step):
		return false
	if step.x != 0 and step.y != 0:
		if not region.is_passable(Vector2i(tile.x + step.x, tile.y)) \
				or not region.is_passable(Vector2i(tile.x, tile.y + step.y)):
			return false
	return true



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
static func waypoints(
	region: Region, from: Vector2i, to: Vector2i, spacing: int = 4, off_road: bool = false,
) -> Array[Vector2]:
	var tiles: Array[Vector2i] = path(region, from, to, off_road)
	if tiles.is_empty():
		return []
	var out: Array[Vector2] = []
	for tile: Vector2i in thin(region, tiles, spacing):
		out.append(Vector2(tile) + Vector2(0.5, 0.5))
	return out


## A path thinned to steering targets, **kept only while the straight line to them
## stays walkable.**
##
## This used to take every fourth tile, which is fine in a field and wrong in a
## wood: a walker steers straight at the next waypoint, and four tiles of straight
## line across a bend in a three-tile corridor goes through the trees. Every
## journey test failed the day the Thornwood closed, and the paths were all fine —
## it was the shortcuts between the samples that were not.
##
## `spacing` is a *maximum* rather than a stride, so the list stays short in the open
## and gets as dense as it needs to be in the tight parts. Public and on tiles, so the
## King's Road's line on a baked world — which bends, where the 2D map's legs did not —
## is thinned by the same rule (`Region._road_line`).
static func thin(region: Region, tiles: Array[Vector2i], spacing: int) -> Array[Vector2i]:
	if tiles.is_empty():
		return []
	var out: Array[Vector2i] = [tiles[0]]
	var anchor: int = 0
	for i: int in range(1, tiles.size()):
		if i - anchor < spacing and _walkable_from_around(region, tiles[anchor], tiles[i]):
			continue
		anchor = i - 1 if i - 1 > anchor else i
		out.append(tiles[anchor])
	out.append(tiles[tiles.size() - 1])
	return out


## Whether the straight line to `to` stays on ground from `anchor` **and from every
## tile round it** (M1c). A walker counts as arrived within a tile of a waypoint and
## steers on from wherever that left them, so the line that has to be clear is not
## the one from the anchor's centre but the one from any tile they may be standing
## on. On the 2D map's open ground the two rarely differed; on the baked world a
## river two tiles off the line had walkers pressing into it for ever.
static func _walkable_from_around(region: Region, anchor: Vector2i, to: Vector2i) -> bool:
	for dx: int in [-1, 0, 1]:
		for dy: int in [-1, 0, 1]:
			var from: Vector2i = anchor + Vector2i(dx, dy)
			if region.is_passable(from) and not _walkable_line(region, from, to):
				return false
	return true


## Whether a walker steering straight from one tile to another stays on ground.
static func _walkable_line(region: Region, from: Vector2i, to: Vector2i) -> bool:
	var steps: int = maxi(absi(to.x - from.x), absi(to.y - from.y))
	var previous: Vector2i = from
	for step: int in steps + 1:
		var at: Vector2 = Vector2(from).lerp(Vector2(to), float(step) / float(maxi(steps, 1)))
		# Floored, not rounded: this has to ask about the same tile the walker will
		# actually occupy, and `MovementRules.tile_of` floors.
		var tile := Vector2i(floori(at.x), floori(at.y))
		if not region.is_passable(tile):
			return false
		# **And no squeezing between two corners** (M1c). The mover slides one axis at a
		# time, so a diagonal between two blocked tiles is a step it cannot make — the
		# rule the search already keeps (`_can_step`) and this check did not, which on
		# the baked world's noisier ground left walkers pressing into a corner for ever.
		var delta: Vector2i = tile - previous
		if delta.x != 0 and delta.y != 0 and not _can_step(region, previous, delta):
			return false
		previous = tile
	return true
