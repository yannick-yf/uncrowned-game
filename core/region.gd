class_name Region
extends RefCounted

## The overworld as terrain, and nothing else. Immutable once built.
##
## Phase 0's geometry is placeholder: Brindle in the south-east, Blackcairn in the
## north-west, one road between them, sea to the south and west and mountains to
## the north and east (SPECS §4). The road's real shape is an open question —
## SPECS §19 Q26, where the prose and the sketch disagree — so nothing about the
## line drawn here should be read as settled topology.

enum Terrain {
	WILD,
	ROAD,
	RUINS,
	CASTLE,
	SEA,
	MOUNTAIN,
	TOWN,
	WALL,
	CAMP,
}

const WIDTH: int = 280
const HEIGHT: int = 200
const BORDER: int = 3

## Brindle sits in the south-east. Blackcairn is *centre*-north-west (SPECS §4),
## pulled in off the corner: at 28% across and 12% down it reads as north-west
## against the mountains without being the literal map corner.
const BRINDLE: Vector2i = Vector2i(271, 191)
const BLACKCAIRN: Vector2i = Vector2i(78, 24)
const BRINDLE_SIZE: Vector2i = Vector2i(13, 9)
const BLACKCAIRN_SIZE: Vector2i = Vector2i(15, 11)
const ROAD_HALF_WIDTH: int = 1

## Harrowgate sits south-centre on the King's Road (SPECS §4). The Muster sits at
## the road's bend, which is the nearest thing to the "crossroads" §4 names — the
## road's true shape is still open (§19 Q26), so neither is load-bearing yet.
const HARROWGATE_GATE: Vector2i = Vector2i(210, 155)
const MUSTER: Vector2i = Vector2i(150, 120)
const MUSTER_SIZE: Vector2i = Vector2i(13, 9)

const HARROWGATE_SIZE: Vector2i = Vector2i(40, 28)
const HARROWGATE_BORDER: int = 3
const HARROWGATE_ARRIVAL: Vector2i = Vector2i(20, 22)
## Where you come out, set clear of the town footprint so leaving does not put
## you straight back inside it.
const HARROWGATE_RETURN: Vector2i = Vector2i(210, 160)

## Gates are bands, not tiles. At 1.5 tiles per tick a walker covers a tile and a
## half in one step, so a one-tile doorway can be stepped clean over — the player
## walks through the wall of a town and nothing happens. Every gate here is wide
## enough that no single step can miss it.
const TOWN_FOOTPRINT: Vector2i = Vector2i(5, 5)

var width: int = 0
var height: int = 0
## Tile -> {"zone": StringName, "at": Vector2i}. Stepping onto one moves you.
var portals: Dictionary = {}
## Placed scenery: {"kind": StringName, "at": Vector2i}. Their footprint is
## already WALL in the grid — this says what to draw on top of it, and the view
## decides what each kind looks like.
var props: Array[Dictionary] = []
var _tiles: PackedByteArray = PackedByteArray()


func _init(p_width: int = WIDTH, p_height: int = HEIGHT) -> void:
	width = p_width
	height = p_height
	_tiles.resize(width * height)
	_tiles.fill(Terrain.WILD)


func in_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < width and tile.y < height


func terrain_at(tile: Vector2i) -> Terrain:
	if not in_bounds(tile):
		return Terrain.MOUNTAIN
	return _tiles[tile.y * width + tile.x] as Terrain


func set_terrain(tile: Vector2i, terrain: Terrain) -> void:
	if in_bounds(tile):
		_tiles[tile.y * width + tile.x] = terrain


func is_passable(tile: Vector2i) -> bool:
	var terrain: Terrain = terrain_at(tile)
	return terrain != Terrain.SEA and terrain != Terrain.MOUNTAIN and terrain != Terrain.WALL


func portal_at(tile: Vector2i) -> Dictionary:
	return portals.get(tile, {}) as Dictionary


func is_in_muster(tile: Vector2i) -> bool:
	return terrain_at(tile) == Terrain.CAMP


## SPECS §4 says the road is fast and the wild slower, but states one speed —
## 4 tiles/sec — and no multiplier. Phase 0 therefore walks everything at that one
## speed: the mechanism is here so the number stays a decision rather than
## something invented in code.
static func speed_multiplier(_terrain: Terrain) -> float:
	return 1.0


func brindle_centre() -> Vector2:
	return Vector2(BRINDLE) + Vector2(0.5, 0.5)


func blackcairn_centre() -> Vector2:
	return Vector2(BLACKCAIRN) + Vector2(0.5, 0.5)


## Tiles of travel from Brindle to Blackcairn on a straight 8-way line. §4's 343 is
## the true map diagonal, (0,0) to (279,199); the settlements sit inside the border.
func brindle_to_blackcairn_tiles() -> float:
	return brindle_centre().distance_to(blackcairn_centre())


## A region is content: stamped once, then read. Shared rather than rebuilt because
## stamping 56,000 tiles thirteen times over is most of a test run, and nothing
## mutates terrain after build. Pass fresh = true if you intend to.
static var _phase_0: Region = null


static func build_phase_0(fresh: bool = false) -> Region:
	if not fresh and _phase_0 != null:
		return _phase_0
	var region: Region = _build_phase_0()
	if not fresh:
		_phase_0 = region
	return region


static func _build_phase_0() -> Region:
	var region := Region.new()
	region._stamp_bounds()
	# One road, Brindle to Blackcairn, with a single bend so it is visibly a road
	# and not a ruled line. Placeholder: see §19 Q26.
	region._stamp_line(BRINDLE, Vector2i(150, 120), ROAD_HALF_WIDTH, Terrain.ROAD)
	region._stamp_line(Vector2i(150, 120), BLACKCAIRN, ROAD_HALF_WIDTH, Terrain.ROAD)
	region._stamp_rect(BRINDLE, BRINDLE_SIZE, Terrain.RUINS)
	region._stamp_rect(BLACKCAIRN, BLACKCAIRN_SIZE, Terrain.CASTLE)
	region._stamp_rect(MUSTER, MUSTER_SIZE, Terrain.CAMP)
	region._stamp_rect(HARROWGATE_GATE, TOWN_FOOTPRINT, Terrain.TOWN)
	# The whole town footprint is the doorway, for the reason above.
	for dx: int in range(-(TOWN_FOOTPRINT.x / 2), TOWN_FOOTPRINT.x / 2 + 1):
		for dy: int in range(-(TOWN_FOOTPRINT.y / 2), TOWN_FOOTPRINT.y / 2 + 1):
			region.portals[HARROWGATE_GATE + Vector2i(dx, dy)] = {
				"zone": &"harrowgate", "at": HARROWGATE_ARRIVAL,
			}
	return region


## Harrowgate: a walled town on its own grid, entered from the King's Road.
##
## Zones are the loadable unit — CLAUDE.md invariant 3 says "zones unload, and
## their nodes with them", and SPECS §19 Q28 leaves zone-versus-screen open, so
## this is a decision rather than a reading. A town is its own Region, and the
## overworld holds a portal tile into it.
static var _harrowgate: Region = null


static func build_harrowgate(fresh: bool = false) -> Region:
	if not fresh and _harrowgate != null:
		return _harrowgate
	var region := Region.new(HARROWGATE_SIZE.x, HARROWGATE_SIZE.y)
	region._tiles.fill(Terrain.TOWN)

	for x: int in region.width:
		for y: int in region.height:
			var b: int = HARROWGATE_BORDER
			if x < b or y < b or x >= region.width - b or y >= region.height - b:
				region.set_terrain(Vector2i(x, y), Terrain.WALL)

	# Two streets, crossing. Everything else is packed earth between houses.
	for x: int in range(6, 35):
		for dy: int in range(-1, 2):
			region.set_terrain(Vector2i(x, 16 + dy), Terrain.ROAD)
	for y: int in range(6, 25):
		for dx: int in range(-1, 2):
			region.set_terrain(Vector2i(20 + dx, y), Terrain.ROAD)

	var houses: Array[Vector2i] = [
		Vector2i(8, 8), Vector2i(14, 8), Vector2i(24, 8), Vector2i(30, 8),
		Vector2i(8, 19), Vector2i(24, 21), Vector2i(30, 18),
	]
	for index: int in houses.size():
		var corner: Vector2i = houses[index]
		for dx: int in 4:
			for dy: int in 3:
				region.set_terrain(corner + Vector2i(dx, dy), Terrain.WALL)
		region.props.append({
			"kind": StringName("house_%d" % (index % 3)),
			"at": corner,
		})

	for x: int in range(19, 22):
		for y: int in range(23, 25):
			region.set_terrain(Vector2i(x, y), Terrain.ROAD)
			region.portals[Vector2i(x, y)] = {
				"zone": &"overworld", "at": HARROWGATE_RETURN,
			}
	if not fresh:
		_harrowgate = region
	return region


func _stamp_bounds() -> void:
	for x: int in width:
		for y: int in height:
			var tile := Vector2i(x, y)
			if y < BORDER or x >= width - BORDER:
				set_terrain(tile, Terrain.MOUNTAIN)
			elif x < BORDER or y >= height - BORDER:
				set_terrain(tile, Terrain.SEA)


func _stamp_rect(centre: Vector2i, size: Vector2i, terrain: Terrain) -> void:
	var half: Vector2i = size / 2
	for x: int in range(centre.x - half.x, centre.x + half.x + 1):
		for y: int in range(centre.y - half.y, centre.y + half.y + 1):
			var tile := Vector2i(x, y)
			if is_passable(tile):
				set_terrain(tile, terrain)


func _stamp_line(from: Vector2i, to: Vector2i, half_width: int, terrain: Terrain) -> void:
	var steps: int = maxi(absi(to.x - from.x), absi(to.y - from.y))
	if steps == 0:
		return
	for step: int in steps + 1:
		var t: float = float(step) / float(steps)
		var point := Vector2i(Vector2(from).lerp(Vector2(to), t).round())
		for dx: int in range(-half_width, half_width + 1):
			for dy: int in range(-half_width, half_width + 1):
				var tile: Vector2i = point + Vector2i(dx, dy)
				if is_passable(tile):
					set_terrain(tile, terrain)
