class_name CatalogRules
extends RefCounted

## **His catalogue, read** (G1, 2026-09-21). `prototypes/brindle_3d/assets/*/catalog.json`
## is the brother's own description of every piece he has made: `size_m` in metres,
## `bounds_center_m`, `ground_pivot`, how many `collision_shapes` it carries, and a
## `placement` note in French saying how it is meant to be used. Its header fixes the
## contract — `units: meters`, `origin: ground center`, `front: +Z`.
##
## For a year the bake did not read it, and stood his 2 m fence modules as 1×1 tiles
## with no facing, so a run of them rendered as spaced posts. Everything here is a pure
## function of a catalogue entry and a placement — no file, no node, no region — so a
## test can ask it what a piece takes up before anything is baked.
##
## **The one convention.** Yaw is Godot's `Basis(Vector3.UP, angle)`: a local point
## `(x, z)` lands at `(x·cos θ + z·sin θ, −x·sin θ + z·cos θ)`. So at 0° a piece's `+X`
## runs east and its front `+Z` faces south; at 90° `+X` runs north and the front faces
## east. `tools/workshop_geometry.gd` transforms his collision shapes with the same
## basis, so what this decides and what the tool extracts never disagree.

## How near a tile's centre a collision shape has to come to stop a walker on that
## tile. His 2 m stone module is four blocks with two-centimetre joints and one of the
## joints falls exactly on the module's centre; a rule that only asked *is the tile's
## centre inside a shape* found the joint and let the wall be walked through. A
## quarter of a metre closes the joint and is still far short of the next tile.
const REACH_M: float = 0.25

## The pitch his modules tile at. `soubassement_2m` is 1.98 m with its connection
## markers at X = ±1 m ("dupliquer pour prolonger"), `cloture_2m` 2.13 m with the same
## markers: the markers, not the meshes, are the pitch.
const MODULE_PITCH_M: float = 2.0


## One entry of the catalogue, by id, or an empty dictionary.
static func entry(catalog: Dictionary, id: String) -> Dictionary:
	for row: Variant in (catalog.get("assets", []) as Array):
		var asset: Dictionary = row as Dictionary
		if String(asset.get("id", "")) == id:
			return asset
	return {}


static func size_m(asset: Dictionary) -> Vector3:
	var size: Array = asset.get("size_m", [1.0, 1.0, 1.0]) as Array
	if size.size() < 3:
		return Vector3.ONE
	return Vector3(float(size[0]), float(size[1]), float(size[2]))


static func scene_of(asset: Dictionary) -> String:
	return String(asset.get("scene", ""))


## Where a local point of the piece lands in his world, given the placement.
static func to_world(local: Vector2, xz: Vector2, yaw_deg: float) -> Vector2:
	var angle: float = deg_to_rad(yaw_deg)
	return xz + Vector2(
		local.x * cos(angle) + local.y * sin(angle),
		-local.x * sin(angle) + local.y * cos(angle))


## The yaw that lays a piece's `+X` along a direction — the way a run of modules is
## laid, end marker to end marker. East is 0°, north 90°, south −90°.
static func yaw_along(direction: Vector2) -> float:
	if direction == Vector2.ZERO:
		return 0.0
	return rad_to_deg(atan2(-direction.y, direction.x))


## The ground footprint of a piece in tiles once it is turned: the axis-aligned box
## round its rotated `size_m`, never smaller than one tile.
static func footprint_tiles(asset: Dictionary, yaw_deg: float, metres_per_tile: float) -> Vector2i:
	var size: Vector3 = size_m(asset)
	var half := Vector2(size.x, size.z) * 0.5
	var reach := Vector2.ZERO
	for corner: Vector2 in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
			Vector2(half.x, half.y), Vector2(-half.x, half.y)]:
		var turned: Vector2 = to_world(corner, Vector2.ZERO, yaw_deg)
		reach = reach.max(turned.abs())
	return Vector2i(
		maxi(ceili(reach.x * 2.0 / metres_per_tile - 0.001), 1),
		maxi(ceili(reach.y * 2.0 / metres_per_tile - 0.001), 1))


## How far above the ground a piece's origin sits. His pieces all carry
## `ground_pivot: true`, so the origin is on the ground and the answer is zero; a piece
## pivoted at its centre would need lifting by half its height, less the offset of its
## bounds — honoured here so a future piece of his cannot sink into his own terrain.
static func lift_m(asset: Dictionary) -> float:
	if bool(asset.get("ground_pivot", true)):
		return 0.0
	var centre: Array = asset.get("bounds_center_m", [0.0, 0.0, 0.0]) as Array
	var centre_y: float = float(centre[1]) if centre.size() > 1 else 0.0
	return size_m(asset).y * 0.5 - centre_y


## The centres of whole modules laid end to end from `from` toward `to`, at `pitch`.
## Only modules that fit within the segment are laid; a leftover shorter than a module
## stays at the `to` end, which is where the caller wanted the run to stop anyway.
static func modules_along(from_m: Vector2, to_m: Vector2, pitch_m: float = MODULE_PITCH_M) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var length: float = from_m.distance_to(to_m)
	if length <= 0.0 or pitch_m <= 0.0:
		return out
	var direction: Vector2 = (to_m - from_m) / length
	var count: int = floori((length + 0.01) / pitch_m)
	for i: int in count:
		out.append(from_m + direction * (pitch_m * 0.5 + pitch_m * float(i)))
	return out


## Whether the segment `a`–`b` runs through any of these polygons. A module of ours
## laid where a wall of his already stands is dropped, and his wall is the wall.
static func segment_crosses(a: Vector2, b: Vector2, polygons: Array) -> bool:
	for raw: Variant in polygons:
		var polygon: PackedVector2Array = _polygon(raw)
		if polygon.size() < 3:
			continue
		if Geometry2D.is_point_in_polygon(a, polygon) or Geometry2D.is_point_in_polygon(b, polygon):
			return true
		for i: int in polygon.size():
			var c: Vector2 = polygon[i]
			var d: Vector2 = polygon[(i + 1) % polygon.size()]
			if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
				return true
	return false


## **What a placed piece stops** (G1's last clause): the tiles whose centre a collision
## shape of his covers or comes within `reach_m` of — never its bounding box, so an open
## hall stays walkable under its roof — plus the tile the piece itself stands on, so a
## thin wall laid along a tile's edge still closes exactly one row of tiles. `origin`
## is that tile, or `Region.NOWHERE` for a piece that stands over open ground on
## purpose: his gate's origin is the middle of its passage, and the passage is the point.
static func blocked_tiles(polygons: Array, origin: Vector2i, origin_m: Vector2,
		metres_per_tile: float, reach_m: float = REACH_M) -> Array[Vector2i]:
	var found: Dictionary = {}
	if origin != Region.NOWHERE:
		found[origin] = true
	for raw: Variant in polygons:
		var polygon: PackedVector2Array = _polygon(raw)
		if polygon.size() < 3:
			continue
		var low := Vector2(INF, INF)
		var high := Vector2(-INF, -INF)
		for point: Vector2 in polygon:
			low = low.min(point)
			high = high.max(point)
		var first: Vector2i = BakeRules.tile_for(low.x - reach_m, low.y - reach_m, origin_m, metres_per_tile)
		var last: Vector2i = BakeRules.tile_for(high.x + reach_m, high.y + reach_m, origin_m, metres_per_tile)
		for x: int in range(first.x, last.x + 1):
			for y: int in range(first.y, last.y + 1):
				var tile := Vector2i(x, y)
				if found.has(tile):
					continue
				var centre: Vector2 = BakeRules.metres_for(tile, origin_m, metres_per_tile)
				if Geometry2D.is_point_in_polygon(centre, polygon) or _distance_to(centre, polygon) <= reach_m:
					found[tile] = true
	var out: Array[Vector2i] = []
	for tile: Vector2i in found.keys():
		out.append(tile)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	return out


static func _distance_to(point: Vector2, polygon: PackedVector2Array) -> float:
	var nearest: float = INF
	for i: int in polygon.size():
		var a: Vector2 = polygon[i]
		var b: Vector2 = polygon[(i + 1) % polygon.size()]
		nearest = minf(nearest, point.distance_to(Geometry2D.get_closest_point_to_segment(point, a, b)))
	return nearest


## A polygon as the build tool hands it over — an array of `[x, z]` pairs — or as a
## test writes it, already packed.
static func _polygon(raw: Variant) -> PackedVector2Array:
	if raw is PackedVector2Array:
		return raw as PackedVector2Array
	var out := PackedVector2Array()
	for pair: Variant in (raw as Array):
		if pair is Vector2:
			out.append(pair as Vector2)
		else:
			var xy: Array = pair as Array
			out.append(Vector2(float(xy[0]), float(xy[1])))
	return out
