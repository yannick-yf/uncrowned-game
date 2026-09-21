class_name BakeRules
extends RefCounted

## How the 3D workshop's ground becomes the simulation's terrain (MIGRATION_3D §4,
## §6 M1b). Pure functions: a height, a water level and his paint in, one of our
## terrain kinds out. Nothing here reads a file or knows a place.
##
## The coordinate contract, stated once: his world is metres with the origin at the
## centre and north at -Z; ours is tiles with the origin top-left and y down. Two
## metres to a tile, so his 385-sample grid over 768 m is our 384 × 384 region, and a
## tile's y grows southward exactly as his z does — no axis flips, one offset.

const METRES_PER_TILE: float = 2.0

## Water this far above the ground is water you cannot walk in.
const WATER_DEPTH: float = 0.05
## Water whose level sits within this of the sea's is the sea. His rivers carry their
## own level down to the coast, where it fades to zero — so the last metres of a
## river are already sea, which is what an estuary is.
const SEA_LEVEL_BAND: float = 0.5
## His rock paint is slope and altitude together; at this much of it nobody walks.
## **0.85, not 0.5** (2026-09-14): at a half his river banks and road cuttings were
## mountain, and Yannick walked into walls nobody could see on ground his own
## character climbs. Now only the steepest flanks and the high ranges stop a walker —
## the border the map closes itself with — and a bank is a bank.
const ROCK_IMPASSABLE: float = 0.85
## His sand paint: the beach and the seabed's edge.
const SAND_MIN: float = 0.5


## The kind of ground a sample of his terrain is, before anything is built on it.
static func terrain_for(height: float, water: float, rock: float, sand: float) -> Region.Terrain:
	if water > height + WATER_DEPTH:
		return Region.Terrain.SEA if water <= SEA_LEVEL_BAND else Region.Terrain.WATER
	if rock >= ROCK_IMPASSABLE:
		return Region.Terrain.MOUNTAIN
	if sand >= SAND_MIN:
		return Region.Terrain.SAND
	return Region.Terrain.WILD


## His metres to our tile. `origin_m` is the world position of tile (0, 0)'s corner.
static func tile_for(x_m: float, z_m: float, origin_m: Vector2,
		metres_per_tile: float = METRES_PER_TILE) -> Vector2i:
	return Vector2i(
		floori((x_m - origin_m.x) / metres_per_tile),
		floori((z_m - origin_m.y) / metres_per_tile))


## The centre of one of our tiles, in his metres.
static func metres_for(tile: Vector2i, origin_m: Vector2,
		metres_per_tile: float = METRES_PER_TILE) -> Vector2:
	return origin_m + (Vector2(tile) + Vector2(0.5, 0.5)) * metres_per_tile


## A row of terrain as runs — `5x12 0x300 4x72` — so the baked file diffs by row and
## a reader can see a coastline move.
static func encode_row(row: PackedByteArray) -> String:
	if row.is_empty():
		return ""
	var out := PackedStringArray()
	var current: int = row[0]
	var count: int = 0
	for value: int in row:
		if value == current:
			count += 1
		else:
			out.append("%dx%d" % [current, count])
			current = value
			count = 1
	out.append("%dx%d" % [current, count])
	return " ".join(out)


## The inverse. A row shorter than `width` is padded with mountain, never with
## walkable ground: a truncated file must close the world, not open it.
static func decode_row(text: String, width: int) -> PackedByteArray:
	var out := PackedByteArray()
	for run: String in text.split(" ", false):
		var parts: PackedStringArray = run.split("x")
		if parts.size() != 2:
			continue
		var value: int = int(parts[0])
		var count: int = int(parts[1])
		for _i: int in maxi(count, 0):
			out.append(value)
	while out.size() < width:
		out.append(Region.Terrain.MOUNTAIN)
	if out.size() > width:
		out.resize(width)
	return out


## Whether a point of his ground is under his water **as the simulation will see it**:
## the sample of the tile the point falls in, exactly as `terrain_for` reads it through
## `RegionBake._ground`. Not bilinear — a bilinear read pulled a wet corner sample into a
## tile the sim calls dry and refused to lay a wall there, so a run stopped a tile short
## of the bank and the yard stood open. A run of wall laid toward the river stops on the
## last tile the sim will let a walker stand on, which is the only bank there is.
##
## (`yard_of`, the two-corner rectangle the first yard was computed from, was retired on
## 2026-09-21: a yard is now composed from his catalogue — `YardRules`.)
static func wet_at(x_m: float, z_m: float, heights: PackedFloat32Array, waters: PackedFloat32Array,
		samples: int, origin_m: Vector2, metres_per_tile: float = METRES_PER_TILE) -> bool:
	if samples < 2 or heights.size() != samples * samples or waters.size() != heights.size():
		return false
	var tile: Vector2i = tile_for(x_m, z_m, origin_m, metres_per_tile)
	if tile.x < 0 or tile.y < 0 or tile.x >= samples - 1 or tile.y >= samples - 1:
		return false
	var i: int = tile.y * samples + tile.x
	return waters[i] > heights[i] + WATER_DEPTH
