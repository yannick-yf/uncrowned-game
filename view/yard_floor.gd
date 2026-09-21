class_name YardFloor
extends RefCounted

## **The threshold, on the ground** (G4, 2026-09-21). A yard the bake composed from his
## catalogue records its floor — every tile a walker inside can reach, a tile off his
## water — and this lays his packed earth over it, so the ground changes exactly where
## the wall does and a player walking up knows they have arrived somewhere else before
## anybody says so.
##
## Our geometry, his material: `ironworks_path.tres`, the ground his own paths at the
## works are drawn with, a few centimetres above his terrain with every corner sampled on
## his relief. His shader fades a path's edge with the vertex alpha and grains it with
## his ground noise, and that is the whole trick here, three times over:
##
## - **The plate is not opaque.** At `FLOOR_ALPHA` his noise breaks it into trampled
##   earth with his own soil showing through in patches, where a full plate was a slab —
##   the one thing in the first frame that read as a second hand.
## - **It dies toward his water.** A vertex's alpha falls off with its distance to the
##   nearest water tile, from `FADE_FROM_M` to nothing, so the plate's tile boundary
##   against his jagged bank is a gradient his noise dissolves and not a staircase of
##   squares — which is what the second frame showed.
## - **It stops crisply at the wall.** A skirt `SKIRT_M` wide runs out from every exposed
##   side to nothing, which puts the fade under the wall itself, because the wall stands
##   0.2–0.6 m outside the last inside tile's edge. Under his buildings the skirt is
##   hidden by their foundations.
##
## `view/` only. It reads `Region.yards`, a height function and a water test, and writes
## nothing.

const LIFT_M: float = 0.08
const SKIRT_M: float = 0.7
const UV_PER_M: float = 0.3
const FLOOR_ALPHA: float = 0.62
## Each quad is cut this many times a side and every vertex sampled on his relief. A flat
## 2 m quad pinned at its corners diverges from his mesh between them wherever the ground
## curves — on the riverbank his grass came up through the middle of every tile and left
## a lattice of squares. His own `ground_path.gd` samples every 0.45 m for the same reason.
const CUTS: int = 4
## Nothing of the plate is left this near a water tile's centre; it is whole this far.
const FADE_FROM_M: float = 1.5
const FADE_TO_M: float = 7.5
## How far round the floor to look for water, in tiles.
const WATER_REACH: int = 5

const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]


## One plate per yard, parented to `under`. `ground(x_m, z_m) -> float` is his terrain's
## height at a point; `water(tile) -> bool` whether a tile of the region is his water;
## `origin_m` and `metres_per_tile` are BakeRules' contract.
static func build(yards: Array[Dictionary], material: Material, ground: Callable, water: Callable,
		origin_m: Vector2, metres_per_tile: float, under: Node3D) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for yard: Dictionary in yards:
		var tiles: Dictionary = {}
		for tile: Vector2i in (yard["floor"] as Array):
			tiles[tile] = true
		if tiles.is_empty():
			continue
		var shore: Array[Vector2] = _water_near(tiles, water, origin_m, metres_per_tile)
		var fade: Callable = func(at: Vector2) -> float:
			var nearest: float = INF
			for wet: Vector2 in shore:
				nearest = minf(nearest, at.distance_to(wet))
			return FLOOR_ALPHA * smoothstep(FADE_FROM_M, FADE_TO_M, nearest)
		var plate := SurfaceTool.new()
		plate.begin(Mesh.PRIMITIVE_TRIANGLES)
		for tile: Vector2i in tiles.keys():
			var corner: Vector2 = origin_m + Vector2(tile) * metres_per_tile
			_quad(plate, ground, fade,
				corner, corner + Vector2(metres_per_tile, 0.0),
				corner + Vector2(metres_per_tile, metres_per_tile), corner + Vector2(0.0, metres_per_tile),
				[1.0, 1.0, 1.0, 1.0])
			for i: int in SIDES.size():
				var side: Vector2i = SIDES[i]
				if tiles.has(tile + side):
					continue
				_skirt(plate, ground, fade, corner, metres_per_tile, side)
				# A convex corner — the next side round is exposed too — gets a patch so
				# the two skirts do not leave a bare square at the tile's corner.
				var next: Vector2i = SIDES[(i + 1) % SIDES.size()]
				if not tiles.has(tile + next):
					_corner(plate, ground, fade, corner, metres_per_tile, side, next)
		plate.generate_normals()
		var floor := MeshInstance3D.new()
		floor.name = "Floor_%s" % String(yard["place"])
		floor.mesh = plate.commit()
		floor.material_override = material
		floor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		under.add_child(floor)
		out.append(floor)
	return out


## The centres, in metres, of every water tile within reach of the floor.
static func _water_near(tiles: Dictionary, water: Callable, origin_m: Vector2, metres_per_tile: float) -> Array[Vector2]:
	var low := Vector2i(1 << 30, 1 << 30)
	var high := Vector2i(-(1 << 30), -(1 << 30))
	for tile: Vector2i in tiles.keys():
		low = low.min(tile)
		high = high.max(tile)
	var out: Array[Vector2] = []
	for x: int in range(low.x - WATER_REACH, high.x + WATER_REACH + 1):
		for y: int in range(low.y - WATER_REACH, high.y + WATER_REACH + 1):
			var tile := Vector2i(x, y)
			if bool(water.call(tile)):
				out.append(origin_m + (Vector2(tile) + Vector2(0.5, 0.5)) * metres_per_tile)
	return out


## The strip outside one side of a tile, the plate's alpha at the tile's edge, gone at `SKIRT_M`.
static func _skirt(plate: SurfaceTool, ground: Callable, fade: Callable, corner: Vector2, size: float,
		side: Vector2i) -> void:
	var a: Vector2
	var b: Vector2
	match side:
		Vector2i.UP:
			a = corner
			b = corner + Vector2(size, 0.0)
		Vector2i.RIGHT:
			a = corner + Vector2(size, 0.0)
			b = corner + Vector2(size, size)
		Vector2i.DOWN:
			a = corner + Vector2(size, size)
			b = corner + Vector2(0.0, size)
		_:
			a = corner + Vector2(0.0, size)
			b = corner
	var out: Vector2 = Vector2(side) * SKIRT_M
	_quad(plate, ground, fade, a, b, b + out, a + out, [1.0, 1.0, 0.0, 0.0])


## The square outside a convex corner, the plate's alpha at the corner point only.
static func _corner(plate: SurfaceTool, ground: Callable, fade: Callable, corner: Vector2, size: float,
		side: Vector2i, next: Vector2i) -> void:
	var point: Vector2 = corner + Vector2(
		size if (side.x > 0 or next.x > 0) else 0.0,
		size if (side.y > 0 or next.y > 0) else 0.0)
	var along: Vector2 = Vector2(side) * SKIRT_M
	var across: Vector2 = Vector2(next) * SKIRT_M
	_quad(plate, ground, fade, point, point + along, point + along + across, point + across, [1.0, 0.0, 0.0, 0.0])


## `weight` is each corner's share of the plate's alpha, 1 on the plate and 0 where a
## skirt dies; the alpha itself is the fade at each vertex. The quad a–b–c–d is cut into
## `CUTS` × `CUTS` cells, bilinearly, and every vertex stands on his ground.
static func _quad(plate: SurfaceTool, ground: Callable, fade: Callable, a: Vector2, b: Vector2, c: Vector2,
		d: Vector2, weight: Array) -> void:
	for i: int in CUTS:
		for j: int in CUTS:
			var u0: float = float(i) / float(CUTS)
			var u1: float = float(i + 1) / float(CUTS)
			var v0: float = float(j) / float(CUTS)
			var v1: float = float(j + 1) / float(CUTS)
			var cell: Array[Vector2] = [
				_lerp_quad(a, b, c, d, u0, v0), _lerp_quad(a, b, c, d, u1, v0),
				_lerp_quad(a, b, c, d, u1, v1), _lerp_quad(a, b, c, d, u0, v1)]
			var weights: Array[float] = [
				_lerp_weight(weight, u0, v0), _lerp_weight(weight, u1, v0),
				_lerp_weight(weight, u1, v1), _lerp_weight(weight, u0, v1)]
			for order: Array in [[0, 1, 2], [0, 2, 3]]:
				for index: int in order:
					var at: Vector2 = cell[index]
					plate.set_color(Color(1.0, 1.0, 1.0, weights[index] * float(fade.call(at))))
					plate.set_uv(at * UV_PER_M)
					plate.add_vertex(Vector3(at.x, float(ground.call(at.x, at.y)) + LIFT_M, at.y))


## A point of the quad a–b–c–d: `u` runs a→b (and d→c), `v` runs a→d (and b→c).
static func _lerp_quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, u: float, v: float) -> Vector2:
	return a.lerp(b, u).lerp(d.lerp(c, u), v)


static func _lerp_weight(weight: Array, u: float, v: float) -> float:
	var top: float = lerpf(float(weight[0]), float(weight[1]), u)
	var bottom: float = lerpf(float(weight[3]), float(weight[2]), u)
	return lerpf(top, bottom, v)
