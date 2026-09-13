class_name Region
extends RefCounted

## The world as terrain, and nothing else. Immutable once built.
##
## Two regions exist: the overworld, and Harrowgate on its own grid. Zones are the
## loadable unit (SPECS §19 Q28) — a town is its own Region and the overworld holds
## portal tiles into it.
##
## **Where things stand is data, not code** (MIGRATION_3D §6.2, M1a, 2026-09-13). The
## eight sites, their footprints, the clearing, the crossings, every fire, stall and
## paper, and every person are read from `content/places.json` as *anchors* — a place
## or point plus an offset — and resolved by `resolve()`. Nothing that a person stands
## next to is a literal in this file any more. What *is* still here are the offsets
## inside `_stamp_landmarks` and its neighbours: **the shape of a settlement**, kilns
## round a works and tents in rows — the kit the bake (M1c) will use to scaffold any
## place the 3D map has not built yet. The map is about to move; content that names
## what it stands next to survives the move.

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
	WATER,
	FORD,
	FOREST,
	MARSH,
	FARMLAND,
	SAND,
	## The fairies' clearing, where the player wakes. Open ground inside the wood.
	CLEARING,
	## Ground the works has already taken: stumps, bare earth, a working face.
	##
	## **The map's thesis, on the ground** (§4). The road is the king's world and the
	## forest is what he is destroying, and the edge between them has to be legible
	## at a glance or the argument is a caption. The Cinderworks is a wound with a
	## radius, not a building standing on grass.
	CLEARED,
	## A built wall: a castle's rampart, a town's curtain. Impassable, and drawn as a
	## wall rather than as the packed earth `WALL` is — `WALL` is a building's
	## *footprint*, hidden under the sprite standing on it, and using it for a curtain
	## wall gave Blackcairn an invisible perimeter around a white rectangle.
	RAMPART,
	## Wood too dense to walk into. **Geography, not a gate** — the map already
	## closes itself with sea and mountain, and Pillar 1 is about progression checks
	## rather than walls. The rule that keeps it honest: thicket may never be the
	## only thing between the player and anything. It shapes the first minute and
	## bounds nothing else.
	THICKET,
}

const WIDTH: int = 280
const HEIGHT: int = 200

## The sea lies south and west, the mountains north and east (SPECS §4), so the
## playable area is everything inside these.
const SEA_WEST: int = 9
const SEA_SOUTH: int = 190
const MOUNTAIN_NORTH: int = 9
const MOUNTAIN_EAST: int = 271

## The eight zones of §4, placed to make the King's Road a genuine dog-leg rather
## than a ruled line: it runs west along the south to Harrowgate, out to the farms,
## then back north-east to the Muster before turning north-west for the capital.
## That bow is what makes the road about a third longer than a direct wild crossing
## — without it the wild costs time and blood and saves no distance, which would
## make it strictly worse forever, witnesses or not.
##
## `static var`, not `const`, **read from `content/places.json`**: a const cannot be
## initialised from data, and the value has to be the file's so the bake can move a
## place without anyone editing this class. Every caller still reads `Region.BRINDLE`.
static var BRINDLE: Vector2i = Places.shared().centre(&"brindle")
static var CINDERWORKS: Vector2i = Places.shared().centre(&"cinderworks")
static var HARROWGATE: Vector2i = Places.shared().centre(&"harrowgate")
static var WIDE_ACRES: Vector2i = Places.shared().centre(&"wide_acres")
static var SALTMARCH: Vector2i = Places.shared().centre(&"saltmarch")
static var MUSTER: Vector2i = Places.shared().centre(&"muster")
static var CAIRNWELL: Vector2i = Places.shared().centre(&"cairnwell")
static var BLACKCAIRN: Vector2i = Places.shared().centre(&"blackcairn")

## Towns are laid out on the overworld at the size they actually are, rather than
## marked by a rectangle you walk into. A transition now means a change of *scale
## or rules* — an interior, a dungeon — never a change of place. See §20.
##
## Harrowgate and Cairnwell are the two you spend time in (§6), so they are a
## screenful and a bit across; the rest are smaller because they are smaller.
static var HARROWGATE_SIZE: Vector2i = Places.shared().size(&"harrowgate")
static var CAIRNWELL_SIZE: Vector2i = Places.shared().size(&"cairnwell")
static var CINDERWORKS_SIZE: Vector2i = Places.shared().size(&"cinderworks")
static var SALTMARCH_SIZE: Vector2i = Places.shared().size(&"saltmarch")
static var WIDE_ACRES_SIZE: Vector2i = Places.shared().size(&"wide_acres")
static var BRINDLE_SIZE: Vector2i = Places.shared().size(&"brindle")
static var MUSTER_SIZE: Vector2i = Places.shared().size(&"muster")
static var BLACKCAIRN_SIZE: Vector2i = Places.shared().size(&"blackcairn")

const ROAD_HALF_WIDTH: int = 1

## No tile. Returned by lookups that found nothing, so that callers do not have to
## agree on a sentinel of their own.
const NOWHERE: Vector2i = Vector2i(-1, -1)

## The Kettle runs from the northern mountains to the southern sea, dividing the
## eastern strip — Brindle, the Cinderworks, the Thornwood — from everything else.
const KETTLE: Array[Vector2i] = [
	Vector2i(196, 8), Vector2i(208, 70), Vector2i(220, 138), Vector2i(236, 191),
]
const KETTLE_HALF_WIDTH: int = 2

## The road's one guarded crossing, and the ford downstream of it. Both are bands
## rather than tiles: a walker covers 6 tiles a second and can step clean over a
## one-tile trigger (§19 Q28b).
## **The fairies' clearing** (§4's opening, §5). The player wakes here, and one
## corridor leads south out of it to Brindle — no maze, no choice, nothing gated.
##
## Placed inside the Thornwood 30 tiles north of Brindle, which is about five
## seconds of walking: long enough to be a walk out of the trees, short enough that
## §4's rule against empty walking still holds. East of the Kettle, so it sits on
## Brindle's own side of the river.
static var CLEARING: Vector2i = Places.shared().point(&"clearing")
const CLEARING_RADIUS: int = 7
## How deep the thicket ring is. Five, because 8-way movement will find a diagonal
## seam in anything thinner.
const THICKET_DEPTH: int = 5
const PATH_HALF_WIDTH: int = 1
## Where the corridor's walls stop. Below this the ruins and the furnaces are
## already in frame, and a destination you can see guides better than a wall does.
const PATH_WALLED_TO: int = 168

static var BRIDGE: Vector2i = Places.shared().point(&"bridge")
static var FORD: Vector2i = Places.shared().point(&"ford")
const CROSSING_HALF_WIDTH: int = 2

var width: int = 0
var height: int = 0
var portals: Dictionary = {}
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
	match terrain_at(tile):
		Terrain.SEA, Terrain.MOUNTAIN, Terrain.WALL, Terrain.WATER, Terrain.THICKET, \
		Terrain.RAMPART:
			return false
	return true



## The king's ground: the road, town streets, the camp. Everything done on it is
## seen (§4), so "the wild" means the walk that touches it as little as it can — it
## cannot be never, because the road seals the east (Navigation). The instrument and
## the route tests ask this so that a measured "wild" line is actually wild: the
## shortest walkable path from Brindle to the castle was 42% road before it did.
func is_watched(tile: Vector2i) -> bool:
	match terrain_at(tile):
		Terrain.ROAD, Terrain.TOWN, Terrain.CAMP:
			return true
	return false


## Whether the ground slows you at all.
##
## **On again (2026-09-13, §4).** It was switched off on 2026-09-11 because "a forest
## should be dangerous, not tiring" — and then the beasts went, so "dangerous" has no
## first half left and tiring is the price the table below was reasoned for. The wild
## is *slow and unwatched*, the road *fast and watched*, and the choice is what §4
## said first: speed against witnesses. Time is the only price of the wild now, which
## is why MAP_SPEC's road ratio matters more rather than less, and why
## `tools/measure_routes.gd` has to be run after touching the map or this table.
##
## One exception, by trait: an attuned walker is not slowed by the wood as much
## (MovementRules.ATTUNED_WOOD_MULTIPLIER, §11).
const TERRAIN_SLOWS_YOU: bool = true


static func speed_multiplier(terrain: Terrain) -> float:
	return speed_table(terrain) if TERRAIN_SLOWS_YOU else 1.0


## The tuned figures, as settled in §4. Consulted only when TERRAIN_SLOWS_YOU.
##
## **Open country is 0.65, not the 0.80 it was tuned to** (Yannick, 2026-09-13,
## measured). The table was reasoned about while speeds were off and never measured
## against the claim it exists for. Measured, the least-watched line from Brindle to
## the castle is 208 tiles of open ground and 29 of wood, and at 0.80 the road beat a
## plain walker by 2.4 s and lost to an attuned one. At 0.65 the road wins by 12 s and
## 9 s — a fifth of the walk, noticeable, not a slog. Worked fields keep 0.80: they
## have paths, and the Wide Acres is a place you walk around in. Cleared ground and the
## clearing are not in the table and walk at 1.00 — bare earth — until it matters.
static func speed_table(terrain: Terrain) -> float:
	match terrain:
		Terrain.ROAD, Terrain.TOWN, Terrain.CAMP, Terrain.CASTLE:
			return 1.00
		Terrain.RUINS:
			return 0.90
		Terrain.FARMLAND:
			return 0.80
		Terrain.WILD:
			return 0.65
		Terrain.SAND:
			return 0.75
		Terrain.FOREST:
			return 0.55
		Terrain.FORD:
			return 0.50
		Terrain.MARSH:
			return 0.45
	return 1.00


func portal_at(tile: Vector2i) -> Dictionary:
	return portals.get(tile, {}) as Dictionary


## Asking the ground what place you are in stopped working the moment towns were
## laid out for real: the King's Road runs through them, so a town's own centre
## tile is street. Proximity to the site is the question, and zone_at answers it.
func is_in_muster(tile: Vector2i) -> bool:
	return zone_at(tile) == &"muster"


## Which zone a tile belongs to, or an empty name out in the country.
##
## Terrain cannot answer this — every settlement stands on TOWN, so asking the
## ground which town you are in gets you the first one in the list — and neither
## can a fixed radius, now that Harrowgate is forty tiles across and Brindle is
## fifteen. It is baked from each zone's own footprint when the region is built:
## correct for towns of different sizes, and a byte lookup rather than eight
## square roots, which matters because it is asked every step.
const ZONE_ORDER: Array[StringName] = [
	&"brindle", &"cinderworks", &"harrowgate", &"wide_acres",
	&"muster", &"saltmarch", &"cairnwell", &"blackcairn",
]
## How far past its buildings a place still counts as itself.
const ZONE_MARGIN: int = 3


## Places are identified, never named. The word belongs to the window, which knows
## what language the player reads; core knows only which place it is.
static func is_place(zone: StringName) -> bool:
	return ZONE_ORDER.has(zone)

var _zone_map: PackedByteArray = PackedByteArray()


func zone_at(tile: Vector2i) -> StringName:
	if not in_bounds(tile) or _zone_map.is_empty():
		return &""
	var index: int = _zone_map[tile.y * width + tile.x]
	return ZONE_ORDER[index - 1] if index > 0 else &""


func _bake_zones() -> void:
	_zone_map.resize(width * height)
	_zone_map.fill(0)
	var sizes: Dictionary = zone_footprints()
	for i: int in ZONE_ORDER.size():
		var id: StringName = ZONE_ORDER[i]
		var site: Vector2i = zone_sites()[id] as Vector2i
		var half: Vector2i = (sizes[id] as Vector2i) / 2 + Vector2i(ZONE_MARGIN, ZONE_MARGIN)
		for x: int in range(site.x - half.x, site.x + half.x + 1):
			for y: int in range(site.y - half.y, site.y + half.y + 1):
				if in_bounds(Vector2i(x, y)):
					_zone_map[y * width + x] = i + 1


static func zone_footprints() -> Dictionary:
	return {
		&"brindle": BRINDLE_SIZE,
		&"cinderworks": CINDERWORKS_SIZE,
		&"harrowgate": HARROWGATE_SIZE,
		&"wide_acres": WIDE_ACRES_SIZE,
		&"muster": MUSTER_SIZE,
		&"saltmarch": SALTMARCH_SIZE,
		&"cairnwell": CAIRNWELL_SIZE,
		&"blackcairn": BLACKCAIRN_SIZE,
	}


## Where the player wakes, which is no longer Brindle (§4's opening, 2026-09-12).
func clearing_centre() -> Vector2:
	return Vector2(CLEARING) + Vector2(0.5, 0.5)


## The figure §4's "reachable from minute one" is really about, now that the game
## does not start in Brindle.
func clearing_to_blackcairn_tiles() -> float:
	return clearing_centre().distance_to(blackcairn_centre())


func brindle_centre() -> Vector2:
	return Vector2(BRINDLE) + Vector2(0.5, 0.5)


func blackcairn_centre() -> Vector2:
	return Vector2(BLACKCAIRN) + Vector2(0.5, 0.5)


## The eight zones of §4, by name, for anything that needs to visit all of them.
static func zone_sites() -> Dictionary:
	return {
		&"brindle": BRINDLE,
		&"cinderworks": CINDERWORKS,
		&"harrowgate": HARROWGATE,
		&"wide_acres": WIDE_ACRES,
		&"muster": MUSTER,
		&"saltmarch": SALTMARCH,
		&"cairnwell": CAIRNWELL,
		&"blackcairn": BLACKCAIRN,
	}


## The King's Road, in order. §4's prose wins over its sketch: the trunk runs
## through the Muster, and Saltmarch hangs off that junction on a spur. The prose
## is the only place the route is stated in words, the sketch disclaims itself as
## topology, and §4's own roster calls the Muster "on the crossroads" — which a
## dead-end spur is not.
static func road_route() -> Array[Vector2i]:
	return [CINDERWORKS, BRIDGE, HARROWGATE, WIDE_ACRES, MUSTER, CAIRNWELL, BLACKCAIRN]


## Points along the King's Road itself, every few tiles.
##
## Distinct from road_route(), which is only the corners: anything that should
## travel *on* the road rather than merely between its ends needs the line, not
## the nodes. A shortest path between two corners cuts the bend, which puts you on
## the verge — and the verge is where the animals are.
## Cached: the road is a constant of the class, and the traveller system asks for
## the line once per walker per step. Rebuilding it there cost more than everything
## else in the simulation put together.
static var _waypoint_cache: Dictionary = {}


static func road_waypoints(spacing: int = 5) -> Array[Vector2i]:
	if _waypoint_cache.has(spacing):
		return _waypoint_cache[spacing] as Array[Vector2i]
	var built: Array[Vector2i] = _build_waypoints(spacing)
	_waypoint_cache[spacing] = built
	return built


static func _build_waypoints(spacing: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var route: Array[Vector2i] = road_route()
	for i: int in route.size() - 1:
		var from := Vector2(route[i])
		var to := Vector2(route[i + 1])
		var steps: int = maxi(int(from.distance_to(to)) / maxi(spacing, 1), 1)
		for step: int in steps:
			out.append(Vector2i(from.lerp(to, float(step) / float(steps)).round()))
	out.append(route[route.size() - 1])
	return out


static func saltmarch_spur() -> Array[Vector2i]:
	return [MUSTER, SALTMARCH]


func path_length(points: Array[Vector2i]) -> float:
	var total: float = 0.0
	for i: int in points.size() - 1:
		total += Vector2(points[i]).distance_to(Vector2(points[i + 1]))
	return total


func brindle_to_blackcairn_tiles() -> float:
	return brindle_centre().distance_to(blackcairn_centre())


## Road distance from Brindle to the castle, the figure §4's 45–90 second target
## is about.
func road_distance() -> float:
	var route: Array[Vector2i] = [BRINDLE]
	route.append_array(road_route())
	return path_length(route)


# ------------------------------------------------------------- construction ---

static var _overworld: Region = null


static func build_overworld(fresh: bool = false) -> Region:
	if not fresh and _overworld != null:
		return _overworld
	var region: Region = _build_overworld()
	if not fresh:
		_overworld = region
	return region


static func _build_overworld() -> Region:
	var region := Region.new()
	# Zones first: they depend on nothing but the sites, and a feature anchor asked
	# for while the world is still being laid out has to know which place a prop
	# stands in.
	region._bake_zones()
	region._stamp_bounds()
	region._stamp_thornwood()
	# The bite the works has taken out of the wood, before the clearing, so that the
	# fairies' ground wins where the two nearly meet — which is the point: the wound
	# stops just short of them, and the gap is what is left to lose.
	region._stamp_wound()
	# Before the road, the river and the settlements, so that if any of this
	# geometry is ever wrong they overwrite it rather than the other way round.
	region._stamp_clearing()
	# And last of the wood: close it up, leaving the ways through.
	region._stamp_deep_wood()
	region._stamp_ellipse(WIDE_ACRES, Vector2i(34, 24), Terrain.FARMLAND)
	region._stamp_ellipse(SALTMARCH, Vector2i(32, 22), Terrain.MARSH)
	region._stamp_kettle()
	region._stamp_road()
	region._stamp_crossings()
	region._stamp_settlements()
	region._stamp_landmarks()
	region._stamp_crowd()
	region._stamp_stalls()
	return region


func _stamp_bounds() -> void:
	for x: int in width:
		for y: int in height:
			var tile := Vector2i(x, y)
			if y < MOUNTAIN_NORTH or x > MOUNTAIN_EAST:
				set_terrain(tile, Terrain.MOUNTAIN)
			elif x < SEA_WEST or y > SEA_SOUTH:
				set_terrain(tile, Terrain.SEA)
			elif x < SEA_WEST + 3 or y > SEA_SOUTH - 3:
				set_terrain(tile, Terrain.SAND)


## The Thornwood: everything east of the river that is not a settlement, plus a
## tongue reaching north-west toward the Redcut. Unwatched, slow, and where the
## animals live.
func _stamp_thornwood() -> void:
	for x: int in range(198, MOUNTAIN_EAST + 1):
		for y: int in range(MOUNTAIN_NORTH, 176):
			if is_passable(Vector2i(x, y)) and terrain_at(Vector2i(x, y)) == Terrain.WILD:
				set_terrain(Vector2i(x, y), Terrain.FOREST)
	# And a belt of it running north-west across the middle, lying squarely on the
	# line a player cuts when they leave the road. Wood behind the start line is
	# scenery; wood on the shortcut is a decision. The road bows south and west
	# around most of it.
	_stamp_line(Vector2i(220, 165), Vector2i(145, 85), 24, Terrain.FOREST, false)


## How far the works has eaten into the Thornwood.
##
## 26 tiles of wood gone around the furnaces. The works is a wound with a radius,
## not a building standing on grass.
const WOUND_RADIUS: int = 26
## And the face they are working now: a strip pushing north-west into the wood, so
## the clearing reads as a thing happening rather than a thing that happened. Aimed
## away from the fairies, because the point below is that they have not reached them.
const WORKING_FACE: Vector2i = Vector2i(238, 138)
const WORKING_FACE_WIDTH: int = 7

## How much untouched wood is left between the wound and the fairies' ring.
##
## **The most important number on the map and the smallest.** The works has eaten
## everything it can reach and stopped four tiles short of the last of them, so the
## two are in the same thought and the gap is the thing the player is being asked to
## save. Without it the wound simply swallows the clearing and there is nothing left
## to lose — which is also what happened the first time this was stamped, and the
## corridor test caught it.
const WOUND_KEEPS_CLEAR: int = 4


func _stamp_wound() -> void:
	var spare: float = float(CLEARING_RADIUS + THICKET_DEPTH + WOUND_KEEPS_CLEAR)
	for x: int in range(CINDERWORKS.x - WOUND_RADIUS, CINDERWORKS.x + WOUND_RADIUS + 1):
		for y: int in range(CINDERWORKS.y - WOUND_RADIUS, CINDERWORKS.y + WOUND_RADIUS + 1):
			var tile := Vector2i(x, y)
			if terrain_at(tile) != Terrain.FOREST:
				continue
			if Vector2(tile).distance_to(Vector2(CLEARING)) <= spare:
				continue
			if Vector2(tile).distance_to(Vector2(CINDERWORKS)) <= float(WOUND_RADIUS):
				set_terrain(tile, Terrain.CLEARED)
	# Its own loop rather than `_stamp_line`, which would happily lay stumps over the
	# works, the road and the town — it only refuses sea, mountain and water. Like
	# `_stamp_wound` above, this touches nothing but standing wood.
	var face_from := Vector2(CINDERWORKS)
	var face_to := Vector2(WORKING_FACE)
	var steps: int = int(face_from.distance_to(face_to))
	for step: int in steps + 1:
		var point: Vector2 = face_from.lerp(face_to, float(step) / float(maxi(steps, 1)))
		for dx: int in range(-WORKING_FACE_WIDTH, WORKING_FACE_WIDTH + 1):
			for dy: int in range(-WORKING_FACE_WIDTH, WORKING_FACE_WIDTH + 1):
				var tile := Vector2i(int(point.x) + dx, int(point.y) + dy)
				if terrain_at(tile) == Terrain.FOREST:
					set_terrain(tile, Terrain.CLEARED)


## The clearing, the thicket that closes it, and the one corridor south.
##
## Only ever writes over `FOREST`, so the river, the road and every settlement are
## safe from it by construction rather than by getting the arithmetic right.
func _stamp_clearing() -> void:
	var outer: int = CLEARING_RADIUS + THICKET_DEPTH
	for x: int in range(CLEARING.x - outer, CLEARING.x + outer + 1):
		for y: int in range(CLEARING.y - outer, CLEARING.y + outer + 1):
			var tile := Vector2i(x, y)
			if terrain_at(tile) != Terrain.FOREST:
				continue
			var away: float = Vector2(tile).distance_to(Vector2(CLEARING))
			if away <= float(CLEARING_RADIUS):
				set_terrain(tile, Terrain.CLEARING)
			elif away <= float(outer):
				set_terrain(tile, Terrain.THICKET)

	# The corridor, cut back through the ring the loop above just laid down, and
	# walled on both sides until Brindle comes into frame.
	for y: int in range(CLEARING.y, PATH_WALLED_TO + 1):
		for x: int in range(CLEARING.x - PATH_HALF_WIDTH - THICKET_DEPTH,
				CLEARING.x + PATH_HALF_WIDTH + THICKET_DEPTH + 1):
			var tile := Vector2i(x, y)
			var here: Terrain = terrain_at(tile)
			if here != Terrain.FOREST and here != Terrain.THICKET and here != Terrain.CLEARING:
				continue
			# Inside the clearing nothing is cut: the corridor begins at its edge,
			# or the open ground the player wakes on has a path stamped through it.
			if Vector2(tile).distance_to(Vector2(CLEARING)) <= float(CLEARING_RADIUS):
				continue
			if absi(x - CLEARING.x) <= PATH_HALF_WIDTH:
				set_terrain(tile, Terrain.FOREST)
			else:
				set_terrain(tile, Terrain.THICKET)


## The ways through the deep wood.
##
## Each leg is walked and cleared, so the wood is **carved rather than blocked** —
## connectivity holds by construction instead of by hoping a noise function left a
## gap. The legs are the routes a person would actually want: out of Brindle, north
## along the mountains, west toward the camp, and the spur to the deserter's fire.
const WOOD_WAYS: Array[Vector2i] = [
	Vector2i(266, 172), Vector2i(258, 160), Vector2i(252, 143), Vector2i(244, 124),
	Vector2i(232, 104), Vector2i(216, 86), Vector2i(204, 66), Vector2i(206, 40),
]
const WOOD_SPUR_WEST: Array[Vector2i] = [
	Vector2i(232, 104), Vector2i(214, 108), Vector2i(200, 112),
]
const WOOD_SPUR_KELL: Array[Vector2i] = [
	Vector2i(216, 86), Vector2i(200, 100), Vector2i(186, 116), Vector2i(176, 128),
]
## How wide a way through is. Three tiles: wide enough to walk and fight in, narrow
## enough that you are following it rather than wandering near it.
const WOOD_WAY_HALF_WIDTH: int = 1
## And how far the wood stays open around a way, so a path is a path and not a slot.
const WOOD_VERGE: int = 1


## Close the Thornwood up, leaving the ways.
##
## **What this changes about the game.** The wood was a lawn with trees drawn on it:
## you crossed it in a straight line and the only cost was teeth. Now it is wood —
## you find a way through, and the way is longer than the line. That is the road
## against the wild finally being about *ground* rather than only about witnesses.
##
## Only the deep wood east of the river is closed. The belt running north-west across
## the middle is the shortcut the road bows around (§4), and turning that into a maze
## would take away the choice it exists to offer; it gets thickets to weave past
## instead.
func _stamp_deep_wood() -> void:
	var keep_clear: float = float(CLEARING_RADIUS + THICKET_DEPTH + 2)
	for x: int in range(198, MOUNTAIN_EAST + 1):
		for y: int in range(MOUNTAIN_NORTH, 176):
			var tile := Vector2i(x, y)
			if terrain_at(tile) != Terrain.FOREST:
				continue
			if Vector2(tile).distance_to(Vector2(CLEARING)) <= keep_clear:
				continue
			# The corridor out of the clearing is a way through like any other.
			if absi(x - CLEARING.x) <= WOOD_WAY_HALF_WIDTH + WOOD_VERGE \
					and y >= CLEARING.y and y <= BRINDLE.y:
				continue
			set_terrain(tile, Terrain.THICKET)

	for route: Array in [WOOD_WAYS, WOOD_SPUR_WEST, WOOD_SPUR_KELL]:
		_carve_way(route as Array[Vector2i])

	# The belt across the middle keeps its choice: thickets to weave past, not a maze.
	for x: int in range(120, 232):
		for y: int in range(70, 176):
			var tile := Vector2i(x, y)
			if terrain_at(tile) != Terrain.FOREST:
				continue
			if _clump_hash(x, y) < 210:
				set_terrain(tile, Terrain.THICKET)


## Clumps rather than speckle: thicket one tile at a time is noise you walk through
## without noticing, and thicket in patches is something you go round.
func _clump_hash(x: int, y: int) -> int:
	var cx: int = x / 3
	var cy: int = y / 3
	var h: int = (cx * 73856093) ^ (cy * 19349663)
	return absi(h) % 1000


func _carve_way(route: Array[Vector2i]) -> void:
	# The fairies' ring is not a wall the wood may open. A way passing near the
	# clearing cut straight through it, and the corridor test caught it: the pocket
	# stopped being a pocket and the whole map was reachable with the corridor dammed.
	var ring: float = float(CLEARING_RADIUS + THICKET_DEPTH + 1)
	for leg: int in route.size() - 1:
		var from := Vector2(route[leg])
		var to := Vector2(route[leg + 1])
		var steps: int = int(from.distance_to(to)) * 2
		for step: int in steps + 1:
			var at: Vector2 = from.lerp(to, float(step) / float(maxi(steps, 1)))
			# A wander off the straight line, so a way bends the way a path bends.
			var wander: float = sin(float(step) * 0.19 + float(leg) * 2.2) * 2.4
			var across: Vector2 = (to - from).orthogonal().normalized() * wander
			var centre := Vector2i((at + across).round())
			for dx: int in range(-WOOD_WAY_HALF_WIDTH - WOOD_VERGE,
					WOOD_WAY_HALF_WIDTH + WOOD_VERGE + 1):
				for dy: int in range(-WOOD_WAY_HALF_WIDTH - WOOD_VERGE,
						WOOD_WAY_HALF_WIDTH + WOOD_VERGE + 1):
					var tile: Vector2i = centre + Vector2i(dx, dy)
					if Vector2(tile).distance_to(Vector2(CLEARING)) <= ring:
						continue
					if terrain_at(tile) == Terrain.THICKET:
						set_terrain(tile, Terrain.FOREST)


func _stamp_kettle() -> void:
	for i: int in KETTLE.size() - 1:
		_stamp_line(KETTLE[i], KETTLE[i + 1], KETTLE_HALF_WIDTH, Terrain.WATER, true)


func _stamp_road() -> void:
	var route: Array[Vector2i] = road_route()
	for i: int in route.size() - 1:
		_stamp_line(route[i], route[i + 1], ROAD_HALF_WIDTH, Terrain.ROAD, false)
	var spur: Array[Vector2i] = saltmarch_spur()
	for i: int in spur.size() - 1:
		_stamp_line(spur[i], spur[i + 1], ROAD_HALF_WIDTH, Terrain.ROAD, false)
	# Brindle's own track out to the works, so the player starts connected.
	_stamp_line(BRINDLE, CINDERWORKS, ROAD_HALF_WIDTH, Terrain.ROAD, false)


## The bridge carries the road over the Kettle; the ford is a wade downstream of
## it. Both are stamped after the river so they cut through it, and both are wide
## enough that no single 6-tiles-per-second step can miss them.
func _stamp_crossings() -> void:
	# Wide enough to span the river *and* its slant. The Kettle runs at an angle,
	# so at any given row it covers more columns than its width suggests — a
	# crossing sized to the width alone leaves water on the far side and the road
	# simply stops in the river.
	_stamp_rect(BRIDGE, Vector2i(19, 5), Terrain.ROAD)
	_stamp_rect(FORD, Vector2i(15, 5), Terrain.FORD)


## Scenery, placed in core because *where* a furnace stands is world layout and a
## test should be able to assert every zone has a landmark. What each kind looks
## like is view/'s business and core never learns it.
##
## Landmark footprints are impassable: §4's towns get "walkable exteriors" — you
## walk the streets between buildings, and the buildings are solid. Scattered trees
## and rocks are not, and are not props at all; the view draws those from the tile
## itself so that a wood can be dense without becoming a maze.
func _place(kind: StringName, at: Vector2i, size: Vector2i) -> void:
	props.append({"kind": kind, "at": at, "size": size})
	for dx: int in size.x:
		for dy: int in size.y:
			var tile: Vector2i = at + Vector2i(dx, dy)
			if in_bounds(tile) and is_passable(tile) and not _is_protected(tile):
				set_terrain(tile, Terrain.WALL)


## Two things a building may never close: the road, and the ground a zone is
## reached by. The first version stamped walls straight across the King's Road and
## cut the map in half — every route test failed at once, which is the cheap way
## to find out.
func _is_protected(tile: Vector2i) -> bool:
	var here: Terrain = terrain_at(tile)
	if here == Terrain.ROAD or here == Terrain.FORD:
		return true
	for site: Vector2i in zone_sites().values():
		if Vector2(tile).distance_to(Vector2(site)) <= 2.5:
			return true
	return false


## The ground a settlement stands on, as a **ragged ellipse rather than a rectangle**.
##
## Every town used to be a rectangle of one surface, which is what a town looks like
## when somebody lays it out with a ruler and nobody has ever walked on it. The edge
## now falls off over the outer third, clumped in threes by `_clump_hash` so it reads
## as a boundary worn into the grass rather than as noise.
##
## Only the surface. Water, mountain and the King's Road are never paved over — the
## road because a town that eats its own road is a town the map cannot reach.
func _lay_ground(site: Vector2i, size: Vector2i, ground: Terrain) -> void:
	var half := Vector2(maxf(float(size.x) * 0.5, 1.0), maxf(float(size.y) * 0.5, 1.0))
	for x: int in range(site.x - size.x / 2, site.x + size.x / 2 + 1):
		for y: int in range(site.y - size.y / 2, site.y + size.y / 2 + 1):
			var tile := Vector2i(x, y)
			if not in_bounds(tile):
				continue
			var here: Terrain = terrain_at(tile)
			match here:
				Terrain.SEA, Terrain.MOUNTAIN, Terrain.WATER, Terrain.ROAD, Terrain.FORD:
					continue
			# **The fray may only eat ground a town could sit beside.** Skipping
			# whatever it landed on left a corner of the Thornwood's thicket standing
			# inside the Muster — impassable, with a watchman posted in it. Anything a
			# settlement has to clear is cleared whatever the hash says.
			if _is_natural(here):
				var out: float = (Vector2(tile - site) / half).length()
				if out > 1.0:
					continue
				# The outer third frays. At the very edge nine tiles in ten are left
				# as they were, which is what stops the boundary being a line.
				if out > 0.66 and float(_clump_hash(x, y)) < (out - 0.66) * 2600.0:
					continue
			set_terrain(tile, ground)


## Ground a settlement may leave alone: what was growing there before it arrived.
## Everything else inside the footprint — thicket, another town's paving — is
## something the settlement has cleared, and is cleared.
func _is_natural(terrain: Terrain) -> bool:
	return terrain == Terrain.WILD or terrain == Terrain.FOREST \
		or terrain == Terrain.FARMLAND or terrain == Terrain.CLEARED \
		or terrain == Terrain.MARSH or terrain == Terrain.SAND


## A main street each way, and a back lane either side of it.
func _lay_streets(site: Vector2i, size: Vector2i) -> void:
	var half: Vector2i = size / 2
	var lane_x: int = maxi(half.x / 2, 4)
	var lane_y: int = maxi(half.y / 2, 3)
	for x: int in range(site.x - half.x, site.x + half.x + 1):
		for dy: int in [-1, 0, 1]:
			_street(Vector2i(x, site.y + dy))
		_street(Vector2i(x, site.y - lane_y))
		_street(Vector2i(x, site.y + lane_y))
	for y: int in range(site.y - half.y, site.y + half.y + 1):
		for dx: int in [-1, 0, 1]:
			_street(Vector2i(site.x + dx, y))
		_street(Vector2i(site.x - lane_x, y))
		_street(Vector2i(site.x + lane_x, y))


func _street(tile: Vector2i) -> void:
	var here: Terrain = terrain_at(tile)
	if here == Terrain.SEA or here == Terrain.MOUNTAIN or here == Terrain.WATER:
		return
	set_terrain(tile, Terrain.ROAD)


## Buildings in blocks either side of a street, skipping anything that would close
## the road or the ground a zone is reached by.
## `kinds` is a plain Array rather than `Array[StringName]`: it comes out of
## `BUILDINGS_AT`, and a Dictionary literal's values are untyped however the constant
## is annotated.
func _stamp_blocks(site: Vector2i, corners: Array[Vector2i], kinds: Array) -> void:
	for i: int in corners.size():
		var at: Vector2i = site + corners[i]
		# A nudge from the tile's own coordinates. Buildings on an exact grid read
		# as generated, and no town was ever surveyed that carefully.
		var jitter := Vector2i(
			(absi((at.x * 73856093) ^ (at.y * 19349663)) % 3) - 1,
			(absi((at.x * 19349663) ^ (at.y * 83492791)) % 3) - 1,
		)
		# Cycled rather than hashed off the position. The hash version looked cleverer
		# and was degenerate: with two kinds on a grid whose x-parity never changed,
		# every farm in the Wide Acres came out a house and the four barns that are
		# §3's second power base were never placed at all.
		_place(kinds[i % kinds.size()] as StringName, at + jitter, Vector2i(4, 3))


## Scenery that does not block the way: people, mostly. Recorded in core because
## *where* a crowd stands is world layout, and a test should be able to count them.
func _place_scenery(kind: StringName, at: Vector2i, size: Vector2i = Vector2i.ONE) -> void:
	props.append({"kind": kind, "at": at, "size": size, "solid": false})


## Standing room in Harrowgate for the men who left the Muster.
##
## Deserters have to go somewhere, and §8's ambient register works better with
## bodies than with numbers: the extra mouths explain the bread price by being
## there. How many are drawn is the view's business — it reads army strength, the
## same way the tents do. These are the places they stand.
##
## Scenery, not cast. No names, no sheets, no dialogue, outside the 25 (§6).
## Market stalls are anchors in `content/places.json` (see `_stamp_stalls`).
const CROWD_SPOTS: Array[Vector2i] = [
	Vector2i(-8, -6), Vector2i(-3, -9), Vector2i(4, -7), Vector2i(9, -4),
	Vector2i(-11, -2), Vector2i(-6, 3), Vector2i(2, 5), Vector2i(7, 2),
	Vector2i(-9, 8), Vector2i(-2, 10), Vector2i(6, 9), Vector2i(11, 6),
]


func _stamp_stalls() -> void:
	# Every stall is an anchor in `content/places.json`: three on Harrowgate's square,
	# one in Cairnwell beside the trader, and **one in Saltmarch, which has no cast,
	# no power base and no watch.**
	#
	# §8 says a crime nobody saw did not happen, and that rule had no reachable
	# case: every stall on the map stood inside somebody's nine tiles, so theft was
	# a flat tax rather than a decision. A stall nobody watches makes it a decision
	# about *where* — the same shape as road against wild, made on the map. It
	# started in the Wide Acres and moved here when the granaries got a watch:
	# Saltmarch is off the trunk road, so no traveller carries word out of it
	# either. Which is why Wren sells the location — she picks over ruins, so she
	# knows where nobody is looking. Moved twice, each time because the town it
	# stood in acquired people, and verified against a *roused* watch, so it stays
	# unwatched at the worst moment rather than the calmest. Moving it a third time
	# is now an edit to the file, and the same test still guards it.
	for anchor: Dictionary in Places.shared().stalls():
		_stall_at(resolve(anchor))
	_place_documents()
	_place_campfires()


## The evidence, on the ground where it lies. Placed as props so a document is a
## thing in a place — which is what stops violence ever closing Route C (§7).
func _place_documents() -> void:
	for row: Dictionary in DocumentRules.all():
		var fact: StringName = row["fact"] as StringName
		var at: Vector2i = resolve(Places.shared().document(fact))
		if at == NOWHERE:
			# Named by `unresolved_anchors()` and failed by test_anchors; a paper that
			# is nowhere would otherwise close Route C silently.
			continue
		if not is_passable(at):
			at = _nearest_open(at)
		props.append({"kind": &"papers", "at": at, "size": Vector2i(1, 1),
			"fact": row["fact"], "solid": false})


## Papers must never be unreachable, so a spot inside a wall walks outward until it
## is not. Spiral rather than a fixed nudge: the towns are laid out by hand and a
## fixed offset would find a different wall.
##
## **The tile itself first** (M1a, 2026-09-13). The spiral used to start at radius 1
## and never look at `from`, so anything open that was asked for at a tile landed one
## tile up and left of it — every campfire on the map sat at its constant minus (1, 1)
## for as long as the constants existed. Found by dumping the old and the new worlds
## tile for tile when the positions moved to data; fixed rather than reproduced.
func _nearest_open(from: Vector2i) -> Vector2i:
	if is_passable(from):
		return from
	for radius: int in range(1, 12):
		for dx: int in range(-radius, radius + 1):
			for dy: int in range(-radius, radius + 1):
				var at: Vector2i = from + Vector2i(dx, dy)
				if is_passable(at):
					return at
	return from


## Somewhere to rest, in every place worth being and a few places between them.
##
## §19 Q5: you save at a campfire and dying puts you back at the last one. They have
## to be common enough that reaching one is a plan rather than a pilgrimage — if
## they are rare, death stops being a cost and becomes a punishment.
## **Every fire is somewhere somebody would light one** (2026-09-13).
##
## They used to be scattered: one per zone at a fixed offset from its centre, which
## dropped them in the middle of streets and against house walls, plus five on the
## road. Fourteen fires in arbitrary places reads as *randomly placed*, which is what
## it was — the offset was chosen once and applied eight times.
##
## Now each one is a reason, and each reason is written beside its anchor in
## `content/places.json` (`_why`): one within reach of every settlement, at the yard
## or quay or verge that settlement would have one; **the fairies' fire** in the
## clearing — the first save in the game, on the last protected ground, and the reason
## to come back and *see* that ground shrink (§8: a change the player cannot perceive
## is identical to no change); the road's, a day's walk apart where a carter would
## stop; Kell's, the only landmark in the deep wood; the ferryman's. The file's order
## is the search order, a place's own fire first.
func _place_campfires() -> void:
	for anchor: Dictionary in Places.shared().campfires():
		var at: Vector2i = resolve(anchor)
		if at == NOWHERE:
			continue
		props.append({"kind": &"campfire", "at": _nearest_open(at),
			"size": Vector2i(2, 2), "solid": false})


## The fire you could sit down at, or NOWHERE.
func nearest_campfire(tile: Vector2i, reach: float) -> Vector2i:
	for prop: Dictionary in props:
		if (prop["kind"] as StringName) != &"campfire":
			continue
		if _distance_to_block(tile, prop["at"] as Vector2i, prop["size"] as Vector2i) <= reach:
			return prop["at"] as Vector2i
	return NOWHERE


## The document lying within reach, or an empty dictionary.
func nearest_document(tile: Vector2i, reach: float) -> Dictionary:
	for prop: Dictionary in props:
		if (prop["kind"] as StringName) != &"papers":
			continue
		if Vector2(tile).distance_to(Vector2(prop["at"] as Vector2i)) <= reach:
			return prop
	return {}


func _stall_at(at: Vector2i) -> void:
	if is_passable(at):
		props.append({"kind": &"stall", "at": at, "size": Vector2i(4, 5), "solid": false})


## The landmark you are standing next to that something can be done to, or an empty
## dictionary. Returns the whole prop, because the caller needs its position to know
## which one was used and its kind to know what the act is.
func nearest_site(tile: Vector2i, reach: float) -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = reach
	for prop: Dictionary in props:
		if not SiteRules.is_site(prop["kind"] as StringName):
			continue
		var distance: float = _distance_to_block(
			tile, prop["at"] as Vector2i, prop.get("size", Vector2i(1, 1)) as Vector2i)
		if distance <= best_distance:
			best = prop
			best_distance = distance
	return best


## The stall you are standing next to, or NOWHERE.
##
## Measured to the stall's *footprint*, not to its anchor. The anchor is the
## top-left corner of a four-by-five block and the sprite is drawn footed and
## centred on it, so measuring to the point put the only usable spot at the back
## corner of something five tiles tall — stand where the stall plainly is and you
## were five tiles from being able to touch it. Found in play: the whole Harrowgate
## market was unreachable except for one corner that happened to sit beside Bell,
## which read as "you can only steal from Bell".
func nearest_stall(tile: Vector2i, reach: float) -> Vector2i:
	var best: Vector2i = NOWHERE
	var best_distance: float = reach
	for prop: Dictionary in props:
		if (prop["kind"] as StringName) != &"stall":
			continue
		var at: Vector2i = prop["at"] as Vector2i
		var size: Vector2i = prop.get("size", Vector2i(1, 1)) as Vector2i
		var distance: float = _distance_to_block(tile, at, size)
		if distance <= best_distance:
			best = at
			best_distance = distance
	return best


## How far a tile is from the nearest tile of a block. Zero when standing on it.
static func _distance_to_block(tile: Vector2i, at: Vector2i, size: Vector2i) -> float:
	var nearest := Vector2(
		clampf(float(tile.x), float(at.x), float(at.x + size.x - 1)),
		clampf(float(tile.y), float(at.y), float(at.y + size.y - 1)),
	)
	return Vector2(tile).distance_to(nearest)


# ---------------------------------------------------------------- anchors ---

## An anchor as a tile, or NOWHERE (see `Places` for the three forms).
##
## A *feature* anchor names a prop by kind standing in a place — `harrowgate.inn` —
## and is answered here because only a built region knows where its props are. The
## first prop of that kind inside the place wins, in placement order, which is the
## order `_stamp_landmarks` lays them down. Anything else is `Places.locate`.
func resolve(anchor: Dictionary) -> Vector2i:
	if anchor.is_empty():
		return NOWHERE
	if not anchor.has("feature"):
		return Places.shared().locate(anchor)
	var place: StringName = anchor.get("place", &"") as StringName
	var kind: StringName = anchor["feature"] as StringName
	var offset: Vector2i = anchor.get("offset", Vector2i.ZERO) as Vector2i
	for prop: Dictionary in props:
		if (prop["kind"] as StringName) != kind:
			continue
		if zone_at(prop["at"] as Vector2i) == place:
			return (prop["at"] as Vector2i) + offset
	return NOWHERE


## Every anchor the content references that resolves nowhere, **by name**. Empty is
## the contract holding. This is what turns a map change that broke the game into a
## sentence — `cast:maddox harrowgate.inn+(0,1)` — before anyone plays it.
func unresolved_anchors() -> Array[String]:
	var out: Array[String] = []
	var places: Places = Places.shared()
	for id: StringName in places.cast_ids():
		_note_unresolved(out, "cast:%s" % id, places.cast_anchor(id))
	var strangers: Array[Dictionary] = places.strangers()
	for i: int in strangers.size():
		_note_unresolved(out, "stranger:%s#%d" % [String(strangers[i].get("kind", &"?")), i + 1],
			strangers[i])
	var fires: Array[Dictionary] = places.campfires()
	for i: int in fires.size():
		_note_unresolved(out, "campfire:%d" % (i + 1), fires[i])
	var stalls: Array[Dictionary] = places.stalls()
	for i: int in stalls.size():
		_note_unresolved(out, "stall:%d" % (i + 1), stalls[i])
	for fact: StringName in DocumentRules.facts():
		_note_unresolved(out, "document:%s" % fact, places.document(fact))
	return out


func _note_unresolved(out: Array[String], name: String, anchor: Dictionary) -> void:
	var at: Vector2i = resolve(anchor)
	if at == NOWHERE or not in_bounds(at):
		out.append("%s %s" % [name, Places.describe(anchor)])


func _stamp_crowd() -> void:
	for offset: Vector2i in CROWD_SPOTS:
		var at: Vector2i = HARROWGATE + offset
		if is_passable(at):
			_place_scenery(&"townsfolk", at)


## Every power base visible as a landmark, and nothing more — scenery, not systems
## (Phase 2 scope). The Muster keeps the interaction it already had.
## What each settlement is made of.
##
## **This is where a place stops being "a town" and becomes Harrowgate.** Every one of
## them used the same four house kinds on the same street grid, so the capital and the
## market town were the same picture with a different name over it — which is what
## Yannick meant by "each town and village needs its own identity".
##
## A place is now three things: the kinds of building it puts up, what it leaves lying
## about in the street, and the ground underfoot (the last of those lives in `Art`,
## because it is a texture rather than a fact). None of it is drawn here — `core/`
## records that a workshop stands at a tile and never learns what a workshop looks
## like.
const BUILDINGS_AT: Dictionary = {
	# A market town on the King's Road: shops with signs, a workshop with its front
	# open, and an inn. Nowhere else has all three.
	&"harrowgate": [&"house_0", &"shop", &"house_2", &"workshop", &"house_0", &"shop"],
	# The capital is stone and money. No workshops: the work is done elsewhere and the
	# profit arrives here.
	&"cairnwell": [&"stone_house", &"house_1", &"shop", &"stone_house", &"house_1"],
	# The works is sheds round the furnaces.
	&"cinderworks": [&"workshop", &"house_2"],
	# Farms: a house and a barn, over and over, because that is what a farm is.
	&"wide_acres": [&"house_1", &"granary"],
	# A port builds in stone and keeps its goods dry.
	&"saltmarch": [&"stone_house", &"house_1"],
}

## What lies about in the street. Scenery, so none of it blocks anything — a barrel
## you cannot walk past is a barrel that will eventually trap somebody.
const SCENERY_AT: Dictionary = {
	&"harrowgate": [&"well", &"produce", &"barrels"],
	&"cairnwell": [&"well", &"crates"],
	&"cinderworks": [&"logs", &"barrels", &"oven"],
	&"wide_acres": [&"fence", &"crates"],
	&"saltmarch": [&"crates", &"barrels"],
	&"blackcairn": [&"crates", &"barrels", &"well"],
}


## Where a settlement's scenery stands, **as a share of the place's own size** rather
## than in tiles. A camp is twenty tiles across and a capital forty, so fixed offsets
## put half of Blackcairn's barrels outside its own wall. These are read as fractions
## of the half-width, so the sixth of them lands in the same relative corner of every
## settlement however big it is.
const SCENERY_SPOTS: Array[Vector2] = [
	Vector2(-0.55, 0.55), Vector2(0.45, -0.6), Vector2(-0.78, -0.15),
	Vector2(0.78, 0.4), Vector2(0.15, 0.78), Vector2(-0.2, -0.82),
]


func _scatter_scenery(zone: StringName, site: Vector2i, size: Vector2i) -> void:
	var kinds: Array = SCENERY_AT.get(zone, []) as Array
	if kinds.is_empty():
		return
	var half := Vector2(size) * 0.5
	for i: int in SCENERY_SPOTS.size():
		var at: Vector2i = site + Vector2i((half * SCENERY_SPOTS[i]).round())
		# Placed after the buildings are up, so a barrel can never end up inside a
		# wall — and never on the road, where it would look dropped rather than kept.
		if not in_bounds(at) or not is_passable(at) or _is_protected(at):
			continue
		_place_scenery(kinds[i % kinds.size()] as StringName, at, Vector2i(2, 2))


func _stamp_landmarks() -> void:
	# Brindle: what is left of it, and what has grown back through it.
	_place(&"ruin_house", BRINDLE + Vector2i(-6, -4), Vector2i(4, 5))
	_place(&"ruin_house", BRINDLE + Vector2i(1, -1), Vector2i(4, 5))
	_place(&"overgrowth", BRINDLE + Vector2i(-5, 2), Vector2i(4, 3))

	# The Cinderworks: the furnaces the village was cleared for, on the river, and the
	# wood they are burning stacked beside them.
	for i: int in 3:
		_place(&"kiln", CINDERWORKS + Vector2i(-9 + i * 5, -6), Vector2i(3, 4))
	_place(&"kiln", CINDERWORKS + Vector2i(-9, 2), Vector2i(3, 4))
	_stamp_blocks(CINDERWORKS, [
		Vector2i(-4, 3), Vector2i(2, 3), Vector2i(2, -7),
	], BUILDINGS_AT[&"cinderworks"] as Array)

	# **Harrowgate is a town.** Twenty-eight buildings around a crossroads, a market
	# square with an inn on it, and two gatehouses where the King's Road comes in —
	# which is the thing a traveller sees first and the reason the place has a name
	# that ends in "gate".
	_stamp_blocks(HARROWGATE, [
		Vector2i(-17, -11), Vector2i(-11, -11), Vector2i(-5, -11),
		Vector2i(3, -11), Vector2i(9, -11), Vector2i(15, -11),
		Vector2i(-17, -6), Vector2i(-11, -6), Vector2i(9, -6), Vector2i(15, -6),
		Vector2i(-17, 4), Vector2i(-11, 4), Vector2i(-5, 4),
		Vector2i(3, 4), Vector2i(9, 4), Vector2i(15, 4),
		Vector2i(-17, 9), Vector2i(-11, 9), Vector2i(9, 9), Vector2i(15, 9),
		Vector2i(-5, -16), Vector2i(3, -16), Vector2i(-11, -16), Vector2i(9, -16),
		Vector2i(-5, 13), Vector2i(3, 13),
	], BUILDINGS_AT[&"harrowgate"] as Array)
	_place(&"inn", HARROWGATE + Vector2i(-9, -4), Vector2i(4, 3))
	_place(&"gatehouse", HARROWGATE + Vector2i(-20, -4), Vector2i(3, 3))
	_place(&"gatehouse", HARROWGATE + Vector2i(17, -4), Vector2i(3, 3))

	# The Wide Acres: a farmhouse and a barn, four times over, in a sea of crops. The
	# barns are the power base rather than the houses — §3's second pillar is what
	# feeds the capital and the standing army.
	_stamp_blocks(WIDE_ACRES, [
		Vector2i(-9, -6), Vector2i(4, -6), Vector2i(-9, 3), Vector2i(4, 3),
		Vector2i(-13, -1), Vector2i(-6, -1), Vector2i(1, -1), Vector2i(8, -1),
	], BUILDINGS_AT[&"wide_acres"] as Array)

	# The Muster: tents, in rows, because that is what a standing army looks like.
	for row: int in 2:
		for col: int in 3:
			var kind: StringName = &"tent" if (row + col) % 2 == 0 else &"tent_b"
			_place(kind, MUSTER + Vector2i(-9 + col * 6, -6 + row * 9), Vector2i(3, 3))

	# Saltmarch: boats, which is the whole point of a port, and stone behind them.
	_place(&"boat", SALTMARCH + Vector2i(-12, -7), Vector2i(5, 2))
	_place(&"boat", SALTMARCH + Vector2i(-12, 5), Vector2i(5, 2))
	_stamp_blocks(SALTMARCH, [
		Vector2i(3, -7), Vector2i(3, 4), Vector2i(-4, 5), Vector2i(-4, -6),
		Vector2i(9, -1),
	], BUILDINGS_AT[&"saltmarch"] as Array)

	# Cairnwell: the capital, and the bank is the tallest thing in it — which is the
	# point of §3's sixth power base and worth seeing from the road.
	_place(&"counting_house", CAIRNWELL + Vector2i(3, -11), Vector2i(4, 5))
	_stamp_blocks(CAIRNWELL, [
		Vector2i(-17, -11), Vector2i(-11, -11), Vector2i(-5, -11), Vector2i(11, -11),
		Vector2i(-17, -6), Vector2i(-11, -6), Vector2i(9, -6), Vector2i(15, -6),
		Vector2i(-17, 4), Vector2i(-11, 4), Vector2i(-5, 4),
		Vector2i(3, 4), Vector2i(9, 4), Vector2i(15, 4),
		Vector2i(-17, 9), Vector2i(-11, 9), Vector2i(3, 9), Vector2i(9, 9),
	], BUILDINGS_AT[&"cairnwell"] as Array)

	# Blackcairn. The keep stands against the north wall with a tower hard against
	# each side of it, so what a player sees on walking through the gate is one mass
	# at the far end rather than four outbuildings around an empty yard. The other two
	# towers hold the south corners, where the gate is.
	_place(&"keep", BLACKCAIRN + Vector2i(-2, -8), Vector2i(4, 5))
	_place(&"tower", BLACKCAIRN + Vector2i(-7, -7), Vector2i(3, 3))
	_place(&"tower", BLACKCAIRN + Vector2i(4, -7), Vector2i(3, 3))
	_place(&"tower", BLACKCAIRN + Vector2i(-10, 3), Vector2i(3, 3))
	_place(&"tower", BLACKCAIRN + Vector2i(7, 3), Vector2i(3, 3))

	for zone: StringName in SCENERY_AT.keys():
		_scatter_scenery(zone, zone_sites()[zone] as Vector2i,
			zone_footprints()[zone] as Vector2i)


## **Ground and streets are two decisions, not one flag.**
##
## They used to be a `streets: bool`, and that branch returned early — so a town with
## streets never laid its ground, and `Art`'s per-place floors (planks over the marsh
## at Saltmarch, paving at Cairnwell, ash at the works) were dead code that had never
## drawn a tile. Four towns shared the road's dirt because of a `return`.
##
## Written as two verbs, each settlement now says what it is made of. The Wide Acres
## take streets and no ground on purpose: it is a farm, and the fields are the point.
func _stamp_settlements() -> void:
	_lay_ground(BRINDLE, BRINDLE_SIZE, Terrain.RUINS)

	_lay_ground(CINDERWORKS, CINDERWORKS_SIZE, Terrain.TOWN)
	_lay_streets(CINDERWORKS, CINDERWORKS_SIZE)

	_lay_ground(HARROWGATE, HARROWGATE_SIZE, Terrain.TOWN)
	_lay_streets(HARROWGATE, HARROWGATE_SIZE)

	_lay_streets(WIDE_ACRES, WIDE_ACRES_SIZE)

	_lay_ground(MUSTER, MUSTER_SIZE, Terrain.CAMP)
	_place(&"muster_rolls", MUSTER + Vector2i(6, -2), Vector2i(3, 3))

	_lay_ground(SALTMARCH, SALTMARCH_SIZE, Terrain.TOWN)
	_lay_streets(SALTMARCH, SALTMARCH_SIZE)

	_lay_ground(CAIRNWELL, CAIRNWELL_SIZE, Terrain.TOWN)
	_lay_streets(CAIRNWELL, CAIRNWELL_SIZE)

	_stamp_castle()


## Blackcairn: a courtyard inside a wall, with one way in.
##
## It used to be `_stamp_town(..., Terrain.CASTLE)` — a pale rectangle with four
## houses standing in it and nothing to say it was a castle at all. A castle is a
## **wall with a gate**, and the gate is the whole reason Route B exists: Hesper's
## papers get you through a door, and a door you can walk round is not a door.
##
## The gate faces south, because that is where the King's Road arrives. The wall is
## `RAMPART` and so is impassable, which means **the gate is now the only way in on
## foot** — and that is exactly the shape §4 wanted when it said Blackcairn has three
## ways in: the gate with papers, the culvert, and the cliff path. Those two are not
## built yet, and until they are the gate stands open, because a castle nobody can
## enter would close every route at once.
const CASTLE_GATE_WIDTH: int = 5


func _stamp_castle() -> void:
	var half: Vector2i = BLACKCAIRN_SIZE / 2
	# The courtyard, but the road keeps running through it to the keep door. A castle
	# the road stops outside is a castle the road does not reach, and the phase 0 test
	# that has asked "does the road get to the castle" since the first week said so.
	for x: int in range(BLACKCAIRN.x - half.x, BLACKCAIRN.x + half.x + 1):
		for y: int in range(BLACKCAIRN.y - half.y, BLACKCAIRN.y + half.y + 1):
			var tile := Vector2i(x, y)
			var here: Terrain = terrain_at(tile)
			if here == Terrain.SEA or here == Terrain.MOUNTAIN or here == Terrain.ROAD:
				continue
			set_terrain(tile, Terrain.CASTLE)
	for x: int in range(BLACKCAIRN.x - half.x, BLACKCAIRN.x + half.x + 1):
		for y: int in range(BLACKCAIRN.y - half.y, BLACKCAIRN.y + half.y + 1):
			var on_edge: bool = x == BLACKCAIRN.x - half.x or x == BLACKCAIRN.x + half.x \
				or y == BLACKCAIRN.y - half.y or y == BLACKCAIRN.y + half.y
			if not on_edge:
				continue
			# The gate: a gap in the south wall, wide enough to be a gate rather
			# than a crack, standing where the road comes up to it.
			if y == BLACKCAIRN.y + half.y and absi(x - BLACKCAIRN.x) <= CASTLE_GATE_WIDTH / 2:
				continue
			# **A wall never closes the road.** The gate is wherever the King's Road
			# actually arrives, rather than where I guessed it would — the first
			# version put the gap on the south wall by arithmetic and walled the road
			# off, which the road test caught immediately. Letting the road cut its
			# own gate is self-correcting: move the road and the gate moves with it.
			if terrain_at(Vector2i(x, y)) == Terrain.ROAD:
				continue
			set_terrain(Vector2i(x, y), Terrain.RAMPART)

	# The gatehouse either side of the way in. The keep is placed with the rest of the
	# castle's buildings in `_stamp_landmarks`, where everything else that stands in a
	# settlement is placed.
	_place(&"gatehouse", BLACKCAIRN + Vector2i(-half.x + 1, half.y - 4), Vector2i(3, 4))
	_place(&"gatehouse", BLACKCAIRN + Vector2i(half.x - 3, half.y - 4), Vector2i(3, 4))


# ------------------------------------------------------------------ helpers ---

func _stamp_rect(centre: Vector2i, size: Vector2i, terrain: Terrain) -> void:
	var half: Vector2i = size / 2
	for x: int in range(centre.x - half.x, centre.x + half.x + 1):
		for y: int in range(centre.y - half.y, centre.y + half.y + 1):
			var tile := Vector2i(x, y)
			if terrain_at(tile) != Terrain.SEA and terrain_at(tile) != Terrain.MOUNTAIN:
				set_terrain(tile, terrain)


func _stamp_ellipse(centre: Vector2i, radii: Vector2i, terrain: Terrain) -> void:
	for x: int in range(centre.x - radii.x, centre.x + radii.x + 1):
		for y: int in range(centre.y - radii.y, centre.y + radii.y + 1):
			var tile := Vector2i(x, y)
			var dx: float = float(x - centre.x) / float(maxi(radii.x, 1))
			var dy: float = float(y - centre.y) / float(maxi(radii.y, 1))
			if dx * dx + dy * dy > 1.0:
				continue
			if terrain_at(tile) == Terrain.WILD:
				set_terrain(tile, terrain)


func _stamp_line(
	from: Vector2i,
	to: Vector2i,
	half_width: int,
	terrain: Terrain,
	over_water: bool,
) -> void:
	var steps: int = maxi(absi(to.x - from.x), absi(to.y - from.y))
	if steps == 0:
		return
	for step: int in steps + 1:
		var t: float = float(step) / float(steps)
		var point := Vector2i(Vector2(from).lerp(Vector2(to), t).round())
		for dx: int in range(-half_width, half_width + 1):
			for dy: int in range(-half_width, half_width + 1):
				var tile: Vector2i = point + Vector2i(dx, dy)
				if not in_bounds(tile):
					continue
				var here: Terrain = terrain_at(tile)
				if here == Terrain.SEA or here == Terrain.MOUNTAIN:
					continue
				if here == Terrain.WATER and not over_water:
					continue
				set_terrain(tile, terrain)
