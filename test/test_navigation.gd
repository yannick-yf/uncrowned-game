extends TestCase

## **The searches, held to the plain one** (T4, 2026-09-29).
##
## `Navigation` searches on flat arrays since T4, because one walk across the baked world
## cost a second over Dictionaries. It must find **the very same path** the plain search
## finds — the walkers, the hail and every journey test walk what it returns, and a
## changed tie would move them. This suite keeps a plain copy of the search, the one it
## replaced, and compares the two on short trips round the start: 320 long ones on both
## worlds agreed when the change was made, and these are what keep it so.

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]


## Short trips from the start and from Brindle's heart, each end set on the open ground
## nearest it — the 2D map's Brindle is small and the sea is close, and a trip into the
## water compares nothing.
func _trips(region: Region) -> Array[Array]:
	var start: Vector2i = where_the_game_starts()
	var brindle: Vector2i = Region.BRINDLE
	var out: Array[Array] = []
	for offset: Vector2i in [Vector2i(9, -14), Vector2i(-11, -6), Vector2i(4, 12), Vector2i(-13, 13)]:
		out.append([start, region.open_near(start + offset)])
		out.append([brindle, region.open_near(brindle + offset)])
	out.append([start, brindle])
	return out


func test_the_shortest_path_is_the_plain_one() -> void:
	var region: Region = Region.build_overworld()
	var checked: int = 0
	for trip: Array in _trips(region):
		var from: Vector2i = trip[0]
		var to: Vector2i = trip[1]
		var plain: Array[Vector2i] = _plain(region, from, to, false)
		assert_eq(Navigation.path(region, from, to), plain, "%s to %s" % [from, to])
		checked += 1 if not plain.is_empty() else 0
	assert_true(checked >= 7, "and most of the trips have a way through: %d of 9" % checked)


func test_the_walk_off_the_road_is_the_plain_one() -> void:
	var region: Region = Region.build_overworld()
	for trip: Array in _trips(region):
		var from: Vector2i = trip[0]
		var to: Vector2i = trip[1]
		assert_eq(Navigation.path(region, from, to, true), _plain(region, from, to, true),
			"%s to %s, off the road" % [from, to])


func test_nowhere_to_go_is_still_nowhere() -> void:
	var region: Region = Region.build_overworld()
	var shut := Vector2i(-5, -5)
	assert_eq(Navigation.path(region, where_the_game_starts(), shut), [] as Array[Vector2i],
		"off the map is no way")
	assert_eq(Navigation.path(region, where_the_game_starts(), where_the_game_starts()),
		[where_the_game_starts()] as Array[Vector2i], "and standing still is one tile")


# ------------------------------------------------- the plain search, kept as it was ---

func _plain(region: Region, from: Vector2i, to: Vector2i, off_road: bool) -> Array[Vector2i]:
	if region == null or not region.is_passable(to):
		return []
	if from == to:
		return [from]
	return _plain_dearest(region, from, to) if off_road else _plain_shortest(region, from, to)


func _plain_shortest(region: Region, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
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


func _plain_dearest(region: Region, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
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
				var price: int = cost + (Navigation.WATCHED_COST if region.is_watched(next) else 1)
				if best.has(next) and int(best[next]) <= price:
					continue
				best[next] = price
				came_from[next] = tile
				while buckets.size() <= price:
					buckets.append([])
				buckets[price].append(next)
		cost += 1
	return []


func _can_step(region: Region, tile: Vector2i, step: Vector2i) -> bool:
	if not region.is_passable(tile + step):
		return false
	if step.x != 0 and step.y != 0:
		if not region.is_passable(Vector2i(tile.x + step.x, tile.y)) \
				or not region.is_passable(Vector2i(tile.x, tile.y + step.y)):
			return false
	return true


func _unwind(came_from: Dictionary, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = [to]
	var tile: Vector2i = to
	while tile != from:
		tile = came_from[tile] as Vector2i
		out.append(tile)
	out.reverse()
	return out
