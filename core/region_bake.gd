class_name RegionBake
extends RefCounted

## A `Region` built from the 3D workshop's data and our brief (MIGRATION_3D §6, M1b–c).
##
## The bake is a build step with one input and one output (§6.2): the brother's files
## in `prototypes/brindle_3d/` plus `content/bake_brief.json` in, `content/region.json`
## out. It is deterministic — same data, same grid — which is what keeps a save
## replaying. `tools/bake_region.gd` runs it; `Region.load_baked()` reads the result
## through `read()` and never touches his files.
##
## Order, and why. Ground first from his samples. Then the brief's woods and grounds,
## over open ground only and never inside a place — his map has the works on grass,
## and §4 needs it in a wound in a wood. His trees close their tiles. The kit's wound
## and clearing. His bridge decks open their crossings, then roads meet their
## landings without opening extra water beside them. The ford is a band on the river.
## His buildings stand as walls under a prop; the ironworks uses collision polygons
## extracted by the build tool, so open halls are not closed by their roof bounds. Then **the kit**: every place marked scaffold gets its ground,
## streets, landmarks and scenery from `Region.scaffold_place`; a place of his gets the
## same only if his data stands no building in it. Then the brief's yards, composed
## from his own catalogue (`compose_yards`, G1–G4, 2026-09-21). Last, the border is closed.
##
## Uses only the public face of `Region` — `set_terrain`, `terrain_at`, `is_passable`,
## `in_bounds`, `zone_at`, `props`, `sites`, `footprints`, `bake_zones` and the
## `scaffold_*` kit — so the two classes stay separable.

## Where his data lives, and its four landscape files. One place for the path, because
## the bake and the 3D window read the same files and must never disagree about them.
const WORKSHOP: String = "res://prototypes/brindle_3d/"
const LANDSCAPE: String = WORKSHOP + "assets/landscape/"

## How far a scaffold site may be nudged onto dry ground before the bake gives up.
const NUDGE_RADIUS: int = 12
## The ford band, in tiles either side of the point; a river here is 6–9 tiles wide.
const FORD_HALF: int = 5
## The road's half width in tiles: three tiles, as the procedural map's.
const ROAD_HALF: int = 1
## A village path narrower than this many metres is one tile wide.
const PATH_WIDE_FROM_M: float = 2.0
## A tree closes its own tile and the ring around it: a mature fir's crown is five
## metres across, and a wood of single tiles is a lawn with dots on it.
const CANOPY: int = 1
## The brief's woods stop this many tiles short of a place's built ground.
const WOOD_KEEPS_OFF: int = 2

var width: int = 0
var height: int = 0
var origin_m: Vector2 = Vector2.ZERO
var metres_per_tile: float = BakeRules.METRES_PER_TILE
var region: Region = null
## Place id -> {"centre", "size" (the zone), "kit" (the built ground), "scaffold", "from"}
var places: Dictionary = {}
var place_order: Array[StringName] = []
## Point id -> {"at": Vector2i, "scaffold": bool}
var points: Dictionary = {}
var trunk: Array[StringName] = []
var spurs: Dictionary = {}
## How fast a walker crosses this world, in tiles a second: his metres a second over
## the metres a tile (decision 1). The 2D map keeps `MovementRules.TILES_PER_SECOND`.
var tiles_per_second: float = 0.0
## Where a road was laid over water: {"road": String, "at": Vector2i, "metres": Vector2}
var crossings: Array[Dictionary] = []
var report: Array[String] = []
var _built_crossings: bool = false
## Every tile one of his delivered bridges laid down, so a road meeting water beside
## one is his deck's own raster and a road meeting water anywhere else is a gap.
var _bridge_tiles: Dictionary = {}


# ----------------------------------------------------------------- his files ---

## His landscape as the bake and the 3D window read it: the descriptor, and three
## arrays of little-endian float32, row-major z then x, paint interleaved in three
## channels — exactly as his `flat_ground.gd` reads them. Empty when the workshop is
## not there, so a clone without it fails a step rather than a frame.
static func read_landscape() -> Dictionary:
	if not FileAccess.file_exists(LANDSCAPE + "landscape.json"):
		return {}
	var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(LANDSCAPE + "landscape.json"))
	return {
		"meta": meta if meta is Dictionary else {},
		"heights": FileAccess.get_file_as_bytes(LANDSCAPE + "height.f32").to_float32_array(),
		"waters": FileAccess.get_file_as_bytes(LANDSCAPE + "water_level.f32").to_float32_array(),
		"paint": FileAccess.get_file_as_bytes(LANDSCAPE + "terrain_paint.f32").to_float32_array(),
	}


# ------------------------------------------------------------------- baking ---

static func bake(
	landscape: Dictionary,
	heights: PackedFloat32Array,
	waters: PackedFloat32Array,
	paint: PackedFloat32Array,
	geography: Dictionary,
	sectors: Dictionary,
	trees: Array,
	brief: Dictionary,
	town: Dictionary = {},
	routes: Dictionary = {},
	yard_pieces: Array = [],
) -> RegionBake:
	var out := RegionBake.new()
	var samples: int = int(landscape.get("grid_size", 0))
	var extent: float = float(landscape.get("extent_m", 0.0))
	if samples < 2 or extent <= 0.0 or heights.size() != samples * samples \
			or waters.size() != heights.size() or paint.size() != heights.size() * 3:
		out.report.append("REFUSED: landscape data incomplete (grid %d, %d heights, %d waters, %d paint)"
			% [samples, heights.size(), waters.size(), paint.size()])
		return out
	out.width = samples - 1
	out.height = samples - 1
	out.metres_per_tile = extent / float(samples - 1)
	out.origin_m = Vector2(-extent * 0.5, -extent * 0.5)
	out.region = Region.new(out.width, out.height)
	var walking: float = float(brief.get("walking_m_per_s", 0.0))
	out.tiles_per_second = walking / out.metres_per_tile if walking > 0.0 else MovementRules.TILES_PER_SECOND
	out.report.append("walking: %.1f m/s, %.2f tiles a second on this world" % [
		walking if walking > 0.0 else out.tiles_per_second * out.metres_per_tile, out.tiles_per_second])

	out._ground(samples, heights, waters, paint)
	out._places(geography, brief, town)
	out._points(sectors, brief)
	out._woods(brief)
	out._grounds(brief)
	out._trees(trees)
	out._wound_and_clearing()
	out._bridges(landscape, brief)
	out._roads(geography, sectors, brief, routes, town)
	out._ford()
	out._buildings(sectors, brief)
	out._ironworks(town)
	out._kit(brief)
	out._thin_footprints(brief)
	# After the thinning, never before it: the thinning exists to open the outer ring of
	# a kit footprint, and a wall of his modules opened by a rule meant for cottages would
	# be a hole nobody could see and nobody would look for. After the roads too, because a
	# piece may stand along a road and never across one.
	out._yards(brief, yard_pieces)
	out._border()
	out._summarise()
	return out


func _ground(samples: int, heights: PackedFloat32Array, waters: PackedFloat32Array,
		paint: PackedFloat32Array) -> void:
	for y: int in height:
		for x: int in width:
			var i: int = y * samples + x
			region.set_terrain(Vector2i(x, y), BakeRules.terrain_for(
				heights[i], waters[i], paint[i * 3], paint[i * 3 + 1]))


## The eight places: his where he has them, the brief's where he does not. The zone
## is his envelope; the kit's ground is `kit_footprint_xz` when the brief gives one.
func _places(geography: Dictionary, brief: Dictionary, town: Dictionary = {}) -> void:
	var his: Dictionary = {}
	for entry: Variant in (geography.get("sites", []) as Array):
		var site: Dictionary = entry as Dictionary
		his[String(site.get("id", ""))] = site
	var wanted: Dictionary = brief.get("places", {}) as Dictionary
	for id: String in wanted.keys():
		var row: Dictionary = wanted[id] as Dictionary
		var centre: Vector2i
		var size: Vector2i
		var scaffold: bool = bool(row.get("scaffold", false))
		var from: String = String(row.get("from", ""))
		if from != "" and his.has(from):
			var site: Dictionary = his[from] as Dictionary
			centre = _tile(site.get("center_xz", [0, 0]))
			size = _tiles(site.get("footprint_xz", [40, 40]))
		elif row.has("centre_xz"):
			centre = _tile(row["centre_xz"])
			size = _tiles(row.get("footprint_xz", [40, 28]))
			scaffold = true
		else:
			report.append("PLACE %s: neither his site '%s' nor a proposal — skipped" % [id, from])
			continue
		if bool(row.get("use_town_bounds", false)) and town.has("bounds_xz"):
			var bounds: Array = town["bounds_xz"]
			centre = _tile([float(bounds[0]) + float(bounds[2]) * 0.5,
				float(bounds[1]) + float(bounds[3]) * 0.5])
			size = _tiles([bounds[2], bounds[3]])
		var kit: Vector2i = _tiles(row["kit_footprint_xz"]) if row.has("kit_footprint_xz") else size
		var landed: Vector2i = _dry(centre)
		if landed != centre:
			report.append("PLACE %s: centre %s is not dry ground, nudged to %s" % [id, centre, landed])
		places[StringName(id)] = {"centre": landed, "size": size, "kit": kit, "scaffold": scaffold,
			"from": from if from != "" else "brief"}
		place_order.append(StringName(id))
		region.sites[StringName(id)] = landed
		region.footprints[StringName(id)] = size
	region.bake_zones()
	for id: String in (brief.get("ignored_sites", []) as Array):
		report.append("his site '%s' ignored, as the brief says" % id)
	for id: StringName in (brief.get("trunk", []) as Array):
		trunk.append(StringName(id))
	for id: String in (brief.get("spurs", {}) as Dictionary).keys():
		var legs: Array[StringName] = []
		for leg: Variant in ((brief["spurs"] as Dictionary)[id] as Array):
			legs.append(StringName(String(leg)))
		spurs[StringName(id)] = legs


func _points(sectors: Dictionary, brief: Dictionary) -> void:
	for id: String in (brief.get("points", {}) as Dictionary).keys():
		var row: Dictionary = (brief["points"] as Dictionary)[id] as Dictionary
		if not row.has("xz"):
			continue
		var at: Vector2i = _tile(row["xz"])
		# A proposal lands on ground somebody can stand on, and the report says when it
		# had to move. The crossings belong in the water — the road is laid over them
		# later — and the working face is a direction, not a place to stand.
		var landed: Vector2i = at if id in ["ford", "bridge", "working_face"] else _dry(at)
		if landed != at:
			report.append("POINT %s: %s is not dry ground, nudged to %s" % [id, at, landed])
		points[StringName(id)] = {"at": landed, "scaffold": bool(row.get("scaffold", true))}
	# His bridge is data he owns: recorded as a point of its own so the report and
	# the map can name it, whatever the brief calls the King's Road's crossing.
	var ends: Array = sectors.get("bridge_endpoints_xzy", []) as Array
	if ends.size() == 2:
		var a: Array = ends[0] as Array
		var b: Array = ends[1] as Array
		var mid: Vector2 = (Vector2(float(a[0]), float(a[1])) + Vector2(float(b[0]), float(b[1]))) * 0.5
		points[&"his_bridge"] = {"at": BakeRules.tile_for(mid.x, mid.y, origin_m, metres_per_tile),
			"scaffold": false}


## The brief's woods: an ellipse, or a belt between two points. Open ground only, and
## never on a place's built ground.
func _woods(brief: Dictionary) -> void:
	for entry: Variant in (brief.get("woods", []) as Array):
		var wood: Dictionary = entry as Dictionary
		var planted: int = 0
		if wood.has("ellipse_xz"):
			var centre: Vector2i = _tile(wood["ellipse_xz"])
			var radii: Vector2i = _tiles(wood.get("radii_xz", [20, 20]))
			for x: int in range(centre.x - radii.x, centre.x + radii.x + 1):
				for y: int in range(centre.y - radii.y, centre.y + radii.y + 1):
					var dx: float = float(x - centre.x) / float(maxi(radii.x, 1))
					var dy: float = float(y - centre.y) / float(maxi(radii.y, 1))
					if dx * dx + dy * dy <= 1.0 and _plant(Vector2i(x, y)):
						planted += 1
		elif wood.has("belt_xz"):
			var ends: Array = wood["belt_xz"] as Array
			var from: Vector2i = _tile(ends[0])
			var to: Vector2i = _tile(ends[1])
			var half: int = int(round(float(wood.get("half_m", 40.0)) / metres_per_tile))
			var steps: int = maxi(absi(to.x - from.x), absi(to.y - from.y))
			for step: int in steps + 1:
				var point := Vector2i(Vector2(from).lerp(Vector2(to), float(step) / float(maxi(steps, 1))).round())
				for dx: int in range(-half, half + 1):
					for dy: int in range(-half, half + 1):
						if _plant(point + Vector2i(dx, dy)):
							planted += 1
		report.append("wood %-16s %d tiles planted%s" % [String(wood.get("id", "?")), planted,
			" (scaffold)" if bool(wood.get("scaffold", true)) else ""])


## Wood grows on open ground, and not where a place has built.
func _plant(tile: Vector2i) -> bool:
	if not region.in_bounds(tile) or region.terrain_at(tile) != Region.Terrain.WILD:
		return false
	for id: StringName in place_order:
		var row: Dictionary = places[id] as Dictionary
		var half: Vector2i = (row["kit"] as Vector2i) / 2 + Vector2i(WOOD_KEEPS_OFF, WOOD_KEEPS_OFF)
		var centre: Vector2i = row["centre"] as Vector2i
		if absi(tile.x - centre.x) <= half.x and absi(tile.y - centre.y) <= half.y:
			return false
	region.set_terrain(tile, Region.Terrain.FOREST)
	return true


## The brief's grounds: farmland round the farms, marsh round the port — an ellipse
## of one terrain over open ground, as the 2D map lays them.
func _grounds(brief: Dictionary) -> void:
	for entry: Variant in (brief.get("grounds", []) as Array):
		var ground: Dictionary = entry as Dictionary
		var place: StringName = StringName(String(ground.get("place", "")))
		if not places.has(place):
			report.append("GROUND for '%s': no such place" % place)
			continue
		var terrain: Region.Terrain = _terrain_named(String(ground.get("terrain", "wild")))
		var centre: Vector2i = (places[place] as Dictionary)["centre"] as Vector2i
		var radii: Vector2i = _tiles(ground.get("radii_xz", [40, 30]))
		var laid: int = 0
		for x: int in range(centre.x - radii.x, centre.x + radii.x + 1):
			for y: int in range(centre.y - radii.y, centre.y + radii.y + 1):
				var tile := Vector2i(x, y)
				var dx: float = float(x - centre.x) / float(maxi(radii.x, 1))
				var dy: float = float(y - centre.y) / float(maxi(radii.y, 1))
				if dx * dx + dy * dy > 1.0 or not region.in_bounds(tile):
					continue
				if region.terrain_at(tile) == Region.Terrain.WILD:
					region.set_terrain(tile, terrain)
					laid += 1
		report.append("ground %-9s round %-11s %d tiles" % [String(ground.get("terrain", "?")), place, laid])


static func _terrain_named(name: String) -> Region.Terrain:
	var index: int = Region.Terrain.keys().find(name.to_upper())
	return (index if index >= 0 else Region.Terrain.WILD) as Region.Terrain


## Every tree closes its tile and its canopy. Open ground only: a tree drawn on sand
## or in a river is his to move, not ours to rewrite.
func _trees(trees: Array) -> void:
	var planted: int = 0
	for entry: Variant in trees:
		var row: Dictionary = entry as Dictionary
		if row == null or not row.has("xz"):
			continue
		var at: Vector2i = _tile(row["xz"])
		for dx: int in range(-CANOPY, CANOPY + 1):
			for dy: int in range(-CANOPY, CANOPY + 1):
				var tile: Vector2i = at + Vector2i(dx, dy)
				if region.in_bounds(tile) and region.terrain_at(tile) == Region.Terrain.WILD:
					region.set_terrain(tile, Region.Terrain.FOREST)
					planted += 1
	report.append("trees: %d placed, %d tiles of wood under their crowns" % [trees.size(), planted])


## The kit's two pieces of terrain thesis: the works' wound and the fairies' clearing.
func _wound_and_clearing() -> void:
	if places.has(&"cinderworks") and points.has(&"clearing") and points.has(&"working_face"):
		region.scaffold_wound((places[&"cinderworks"] as Dictionary)["centre"] as Vector2i,
			(points[&"clearing"] as Dictionary)["at"] as Vector2i,
			(points[&"working_face"] as Dictionary)["at"] as Vector2i)
	if points.has(&"clearing") and places.has(&"brindle"):
		var brindle: Dictionary = places[&"brindle"] as Dictionary
		var walled_to: int = (brindle["centre"] as Vector2i).y - (brindle["size"] as Vector2i).y / 2 \
			- Region.CORRIDOR_STOPS_SHORT
		var clearing: Vector2i = (points[&"clearing"] as Dictionary)["at"] as Vector2i
		region.scaffold_clearing(clearing, walled_to)
		# The ring of thicket the kit closes the clearing with cannot be seen on his map —
		# nothing of ours is drawn there — and a wall nobody sees is a wall in the face
		# (Yannick, 2026-09-14). It stands as open wood until he plants the ring himself;
		# the corridor's tests say so as a debt.
		var reach: int = Region.CLEARING_RADIUS + Region.THICKET_DEPTH + 2
		var opened: int = 0
		for x: int in range(clearing.x - reach, clearing.x + reach + 1):
			for y: int in range(clearing.y - reach, walled_to + 2):
				var tile := Vector2i(x, y)
				if region.in_bounds(tile) and region.terrain_at(tile) == Region.Terrain.THICKET:
					region.set_terrain(tile, Region.Terrain.FOREST)
					opened += 1
		report.append("clearing: %d tiles of thicket left as open wood, nothing standing there to be seen" % opened)


## His roads, his village paths, his bridge, then the brief's roads.
func _roads(geography: Dictionary, sectors: Dictionary, brief: Dictionary,
		routes: Dictionary = {}, town: Dictionary = {}) -> void:
	var regional: Array = routes.get("routes", geography.get("roads", [])) as Array
	for entry: Variant in regional:
		var road: Dictionary = entry as Dictionary
		_polyline(String(road.get("id", "road")), road.get("points_xz", []) as Array, ROAD_HALF,
			Region.Terrain.ROAD)
	for entry: Variant in (sectors.get("routes", []) as Array):
		var route: Dictionary = entry as Dictionary
		var half: int = ROAD_HALF if float(route.get("width", 0.0)) >= PATH_WIDE_FROM_M else 0
		_polyline(String(route.get("id", "path")), route.get("points", []) as Array, half,
			Region.Terrain.ROAD)
	var ends: Array = sectors.get("bridge_endpoints_xzy", []) as Array
	if ends.size() == 2 and routes.is_empty():
		var a: Array = ends[0] as Array
		var b: Array = ends[1] as Array
		_polyline("his_bridge", [[a[0], a[1]], [b[0], b[1]]], ROAD_HALF, Region.Terrain.ROAD)
	for path: Dictionary in town.get("paths", []):
		_polyline(String(path["id"]), path["points_xz"] as Array, 0, Region.Terrain.ROAD)
	for entry: Variant in (brief.get("roads", []) as Array):
		var road: Dictionary = entry as Dictionary
		_polyline(String(road.get("id", "road")) + " (brief)", road.get("points_xz", []) as Array,
			ROAD_HALF, Region.Terrain.ROAD)


## Lay one terrain along a polyline in metres. Never over the sea; over rock yes — his
## rock paint is steepness, and a road drawn up a steep bank is a cutting, which is
## what roads do to banks — and over a river yes, and every such tile is a crossing
## the report names. Found the hard way: his farms road met seven tiles of rock at the
## river's bank, and everything west of the junction was unreachable by road.
func _polyline(id: String, points_xz: Array, half: int, terrain: Region.Terrain) -> void:
	var wet: int = 0
	var cut: int = 0
	var first_wet: Vector2i = Region.NOWHERE
	for i: int in points_xz.size() - 1:
		var from: Vector2 = _metres(points_xz[i])
		var to: Vector2 = _metres(points_xz[i + 1])
		var steps: int = maxi(int(from.distance_to(to) / (metres_per_tile * 0.5)), 1)
		for step: int in steps + 1:
			var at: Vector2 = from.lerp(to, float(step) / float(steps))
			var centre: Vector2i = BakeRules.tile_for(at.x, at.y, origin_m, metres_per_tile)
			for dx: int in range(-half, half + 1):
				for dy: int in range(-half, half + 1):
					var tile: Vector2i = centre + Vector2i(dx, dy)
					if not region.in_bounds(tile):
						continue
					var here: Region.Terrain = region.terrain_at(tile)
					if here == Region.Terrain.SEA:
						continue
					if here == Region.Terrain.MOUNTAIN:
						cut += 1
					if here == Region.Terrain.WATER:
						if _built_crossings and _beside_his_bridge(tile):
							continue
						wet += 1
						if first_wet == Region.NOWHERE:
							first_wet = tile
					region.set_terrain(tile, terrain)
	if wet > 0:
		crossings.append({"road": id, "at": first_wet,
			"metres": BakeRules.metres_for(first_wet, origin_m, metres_per_tile), "tiles": wet})
	if cut > 0:
		report.append("cutting %-28s %d tiles of rock under the road" % [id, cut])


## A water tile his own bridge already rastered, or one touching it.
##
## **Why this is not simply "he has delivered crossings, so every wet road tile is
## his"** (2026-09-16). That is what it used to be, and it held only while his bridges
## covered every place a road met water. His royal city arrived with a moat and a
## feeder channel, and the King's Road crosses that channel twenty-five tiles from
## his nearest bridge: the bake laid no road over the three wet tiles, said nothing,
## and the road to the capital was cut — `along_road` found no way through, the King's
## Road's waypoints jumped 112 tiles in one leg, and two journeys failed with a
## walker trudging into a river. His bridges run before the roads and set their own
## tiles to ROAD, so a tile still wet under a road is one no bridge of his covers;
## next to one it is his deck's raster, and widening it into the river is ours to
## refuse.
func _beside_his_bridge(tile: Vector2i) -> bool:
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			if _bridge_tiles.has(tile + Vector2i(dx, dy)):
				return true
	return false


## The ford: a band of wadeable river around the brief's point. Only water turns to
## ford; the banks stay what they are.
func _ford() -> void:
	if not points.has(&"ford"):
		return
	var at: Vector2i = (points[&"ford"] as Dictionary)["at"] as Vector2i
	var turned: int = 0
	for dx: int in range(-FORD_HALF, FORD_HALF + 1):
		for dy: int in range(-FORD_HALF, FORD_HALF + 1):
			var tile: Vector2i = at + Vector2i(dx, dy)
			if region.in_bounds(tile) and region.terrain_at(tile) == Region.Terrain.WATER:
				region.set_terrain(tile, Region.Terrain.FORD)
				turned += 1
	if turned == 0:
		report.append("FORD at %s touches no river: the point is on dry land" % at)
	else:
		report.append("ford: %d tiles of river made wadeable at %s" % [turned, at])


## His buildings: a footprint of wall under a prop the view can draw.
func _buildings(sectors: Dictionary, brief: Dictionary) -> void:
	var rules: Dictionary = brief.get("buildings", {}) as Dictionary
	var size: Vector2i = _pair(rules.get("footprint_tiles", [2, 2]))
	var kinds: Dictionary = rules.get("kind_for_asset", {}) as Dictionary
	for entry: Variant in (sectors.get("buildings", []) as Array):
		var building: Dictionary = entry as Dictionary
		var kind: String = String(kinds.get(String(building.get("asset", "")), "ruin_house"))
		var centre: Vector2i = _tile(building.get("center_xz", [0, 0]))
		place(StringName(kind), centre - size / 2, size, true)
	report.append("buildings: %d of his stand as props" % (sectors.get("buildings", []) as Array).size())


## A prop with a solid footprint, as `Region._place` does for the procedural map.
## The road is never closed by it. `his` marks a building his data stands, so a
## window showing his scenes draws his mesh and not our sprite for it.
func place(kind: StringName, at: Vector2i, size: Vector2i, his: bool = false) -> void:
	var prop: Dictionary = {"kind": kind, "at": at, "size": size}
	if his:
		prop["his"] = true
	region.props.append(prop)
	for dx: int in size.x:
		for dy: int in size.y:
			var tile: Vector2i = at + Vector2i(dx, dy)
			if not region.in_bounds(tile) or not region.is_passable(tile):
				continue
			if region.terrain_at(tile) == Region.Terrain.ROAD:
				continue
			region.set_terrain(tile, Region.Terrain.WALL)


## The kit, per place (§6.2, point 3). A scaffold gets everything; a place of his gets
## the same only if his data stands nothing in it, so the day he draws the works the
## kilns of ours disappear on the next bake.
func _kit(_brief: Dictionary) -> void:
	for id: StringName in place_order:
		var row: Dictionary = places[id] as Dictionary
		var centre: Vector2i = row["centre"] as Vector2i
		var kit: Vector2i = row["kit"] as Vector2i
		if bool(row["scaffold"]):
			region.scaffold_place(id, centre, kit)
			report.append("kit   %-12s scaffold: ground, streets, landmarks, scenery at %s" % [id, kit])
		elif _his_props_in(id) == 0:
			region.scaffold_place(id, centre, kit)
			row["kit_on_his"] = true
			report.append("kit   %-12s his site, nothing built in it yet: our kit at %s" % [id, kit])
		else:
			report.append("kit   %-12s his: %d of his items stand in it, no settlement kit" % [id, _his_props_in(id)])


## Under a piece of his library the walls are the piece's, not the footprint's. The
## kit's footprints are the 2D sprites' sizes — twice his cottages in metres — and the
## strip between his wall and ours was a wall nobody could see (Yannick, 2026-09-14).
## The outer ring of every such footprint is opened again; the centre stays solid,
## because a house is still a house. Which kinds have a piece is the brief's
## `kit_library`, the same table the window draws from.
func _thin_footprints(brief: Dictionary) -> void:
	var library: Dictionary = brief.get("kit_library", {}) as Dictionary
	var opened: int = 0
	for prop: Dictionary in region.props:
		if bool(prop.get("his", false)) or not library.has(String(prop["kind"])):
			continue
		var at: Vector2i = prop["at"] as Vector2i
		var size: Vector2i = prop.get("size", Vector2i(1, 1)) as Vector2i
		if size.x < 3 and size.y < 3:
			continue
		var ground: Region.Terrain = _ground_beside(at, size)
		for dx: int in size.x:
			for dy: int in size.y:
				var inner_x: bool = size.x < 3 or (dx >= 1 and dx < size.x - 1)
				var inner_y: bool = size.y < 3 or (dy >= 1 and dy < size.y - 1)
				if inner_x and inner_y:
					continue
				var tile: Vector2i = at + Vector2i(dx, dy)
				if region.in_bounds(tile) and region.terrain_at(tile) == Region.Terrain.WALL:
					region.set_terrain(tile, ground)
					opened += 1
	report.append("footprints: %d wall tiles opened around pieces of his library" % opened)


## How many tiles a yard may hold before the bake decides it is not a yard but a leak.
const YARD_FLOOR_CAP: int = 2000


## **The brief's yards as placements of his pieces, before anything is baked** (G1–G2,
## 2026-09-21). Static and file-free: the tool hands it his landscape (so a run can stop
## at his water), the brief, his catalogue and his town with its collision polygons (so
## a module is dropped where his own wall already stands), and gets back placements the
## geometry tool can extract shapes for. `{"pieces": [...], "report": [...]}`.
static func compose_yards(landscape: Dictionary, heights: PackedFloat32Array,
		waters: PackedFloat32Array, brief: Dictionary, catalog: Dictionary, town: Dictionary) -> Dictionary:
	var out: Dictionary = {"pieces": [] as Array[Dictionary], "report": [] as Array[String]}
	var samples: int = int(landscape.get("grid_size", 0))
	var extent: float = float(landscape.get("extent_m", 0.0))
	if samples < 2 or extent <= 0.0:
		return out
	var metres: float = extent / float(samples - 1)
	var origin := Vector2(-extent * 0.5, -extent * 0.5)
	var wet: Callable = func(point: Vector2) -> bool:
		return BakeRules.wet_at(point.x, point.y, heights, waters, samples, origin, metres)
	var his: Array = []
	for item: Dictionary in (town.get("buildings", []) as Array) + (town.get("props", []) as Array):
		for polygon: Variant in (item.get("obstacles", []) as Array):
			his.append(polygon)
	for raw: Variant in (brief.get("yards", []) as Array):
		var yard: Dictionary = raw as Dictionary
		var composed: Dictionary = YardRules.compose(yard, catalog, wet, his)
		for piece: Dictionary in (composed["pieces"] as Array):
			piece["yard"] = String(yard.get("place", ""))
			(out["pieces"] as Array).append(piece)
		(out["report"] as Array).append_array(composed["report"] as Array)
	return out


## **The yards: his pieces, standing where the brief composed them** (G2–G4, 2026-09-21).
##
## `pieces` are `compose_yards`' placements, each carrying the collision polygons the
## build tool extracted from his own scene at that placement. What a piece stops is
## `CatalogRules.blocked_tiles` — his shapes, never a box — and every tile it stops
## becomes WALL under a prop the window draws, so what stops the player is what they see.
##
## Three rules, each of which cost a session before it was a rule:
## - **Never in the river.** A piece whose shapes reach his water is refused, by name.
## - **Along a road, never across one.** A piece may take a road tile at the road's
##   edge — along some axis one neighbour is road and the other is not — so a wall can
##   run along his street's verge. A tile with road on both sides of it is a crossing,
##   and a crossing is the gate's job: the gate's origin is its passage, open ground,
##   warded, with a man standing on it.
## - **The yard closes, or the report says where it does not.** A walk from just inside
##   the passage may not reach just outside it except through it.
##
## The floor is every tile that walk reaches, and the ground changes under it (G4): open
## ground inside becomes TOWN — the 2D window already draws the works' TOWN as cinder —
## and the whole plate, walls and his buildings included, is recorded for the 3D window
## to lay his packed earth over.
func _yards(brief: Dictionary, pieces: Array) -> void:
	var by_yard: Dictionary = {}
	for raw: Variant in pieces:
		var piece: Dictionary = raw as Dictionary
		var key: String = String(piece.get("yard", ""))
		if not by_yard.has(key):
			by_yard[key] = []
		(by_yard[key] as Array).append(piece)
	for entry: Variant in (brief.get("yards", []) as Array):
		var row: Dictionary = entry as Dictionary
		var id := StringName(String(row.get("place", "")))
		if not places.has(id):
			report.append("yard  %-12s no such place, skipped" % id)
			continue
		var ward := StringName(String(row.get("ward", "%s_gate" % id)))
		var passage: Vector2i = Region.NOWHERE
		var inside_seed: Vector2i = Region.NOWHERE
		var outside_seed: Vector2i = Region.NOWHERE
		var stood: Dictionary = {}
		var refused: int = 0
		for raw: Variant in (by_yard.get(String(id), []) as Array):
			var piece: Dictionary = raw as Dictionary
			var xz: Vector2 = piece["xz"] as Vector2
			var yaw: float = float(piece["yaw"])
			var role := StringName(String(piece["role"]))
			var origin: Vector2i = BakeRules.tile_for(xz.x, xz.y, origin_m, metres_per_tile)
			var blocked: Array[Vector2i] = CatalogRules.blocked_tiles(piece.get("obstacles", []) as Array,
				Region.NOWHERE if role == YardRules.ROLE_GATE else origin, origin_m, metres_per_tile)
			var wet: Vector2i = Region.NOWHERE
			var crossing: Vector2i = Region.NOWHERE
			for tile: Vector2i in blocked:
				if not region.in_bounds(tile):
					continue
				var here: Region.Terrain = region.terrain_at(tile)
				if here == Region.Terrain.WATER or here == Region.Terrain.SEA:
					wet = tile
				elif here == Region.Terrain.ROAD and not _road_edge(tile):
					crossing = tile
			if wet != Region.NOWHERE:
				report.append("YARD %s: %s %s at (%.1f, %.1f) m REFUSED, it stands in his river at %s"
					% [id, piece["id"], piece["piece"], xz.x, xz.y, wet])
				refused += 1
				continue
			if crossing != Region.NOWHERE:
				report.append("YARD %s: %s %s at (%.1f, %.1f) m REFUSED, it would cross his road at %s"
					% [id, piece["id"], piece["piece"], xz.x, xz.y, crossing])
				refused += 1
				continue
			var first: Vector2i = origin
			var last: Vector2i = origin
			for tile: Vector2i in blocked:
				if not region.in_bounds(tile):
					continue
				first = first.min(tile)
				last = last.max(tile)
				if region.is_passable(tile):
					region.set_terrain(tile, Region.Terrain.WALL)
			var prop: Dictionary = {"kind": StringName(String(piece["piece"])), "at": first,
				"size": last - first + Vector2i.ONE, "xz": xz, "yaw": yaw, "scene": String(piece["scene"]),
				"piece": String(piece["piece"]), "role": String(role), "yard": String(id),
				"lift": float(piece.get("lift", 0.0))}
			region.props.append(prop)
			stood[String(piece["piece"])] = int(stood.get(String(piece["piece"]), 0)) + 1
			if role == YardRules.ROLE_GATE:
				passage = origin
				var front: Vector2 = CatalogRules.to_world(Vector2(0.0, 1.0), Vector2.ZERO, yaw)
				var step := Vector2i(roundi(front.x), roundi(front.y))
				inside_seed = origin + step
				outside_seed = origin - step
		var counts := PackedStringArray()
		for piece_id: String in stood.keys():
			counts.append("%d × %s" % [stood[piece_id], piece_id])
		report.append("yard  %-12s %s stand from his catalogue%s" % [id, ", ".join(counts),
			", %d REFUSED" % refused if refused > 0 else ""])
		if passage == Region.NOWHERE:
			report.append("YARD %s: no gate stood, so nothing is warded and the yard is not a yard" % id)
			continue
		if not region.is_passable(passage):
			report.append("YARD %s: the gate's passage %s is not open ground" % [id, passage])
		region.wards[passage] = ward
		points[ward] = {"at": passage, "scaffold": true}
		var walk: Dictionary = _enclosed(inside_seed, passage, outside_seed)
		# **The floor stops a tile short of his water.** The walk reaches every dry tile
		# of his jagged bank — a spit of it ran five tiles north past the wall's end — and
		# painting those drew a checkerboard of squares down the river. A tile is the
		# works' ground only if no water touches it, corners included; the bank stays his.
		var floor: Array[Vector2i] = []
		var laid: int = 0
		for tile: Vector2i in (walk["inside"] as Dictionary).keys():
			if _touches_water(tile):
				continue
			floor.append(tile)
			match region.terrain_at(tile):
				Region.Terrain.WILD, Region.Terrain.CLEARED, Region.Terrain.FOREST:
					region.set_terrain(tile, Region.Terrain.TOWN)
					laid += 1
		floor.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.y < b.y or (a.y == b.y and a.x < b.x))
		region.yards.append({"place": String(id), "ward": String(ward), "passage": passage,
			"inside": inside_seed, "floor": floor})
		if bool(walk["leaked"]):
			report.append("YARD %s: NOT CLOSED — a walk from inside the passage %s gets out without it (%d tiles reached)"
				% [id, passage, (walk["inside"] as Dictionary).size()])
		else:
			report.append("yard  %-12s closed: passage %s warded by %s, %d tiles of floor, %d of them turned to cinder"
				% [id, passage, ward, floor.size(), laid])


## Whether any of a tile's eight neighbours is his water.
func _touches_water(tile: Vector2i) -> bool:
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			var next: Vector2i = tile + Vector2i(dx, dy)
			if not region.in_bounds(next):
				continue
			var here: Region.Terrain = region.terrain_at(next)
			if here == Region.Terrain.WATER or here == Region.Terrain.SEA or here == Region.Terrain.FORD:
				return true
	return false


## Whether a road tile is at the road's edge: along one axis or the other, exactly one
## of its two neighbours is road. A wall may stand on such a tile and the road stays a
## road, one tile narrower; a tile with road on both sides is the road itself.
func _road_edge(tile: Vector2i) -> bool:
	var road: Array[bool] = []
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var next: Vector2i = tile + step
		road.append(region.in_bounds(next) and region.terrain_at(next) == Region.Terrain.ROAD)
	return road[0] != road[1] or road[2] != road[3]


## The walk that decides whether a yard is closed: from just inside the passage, over
## open ground, never through the passage itself. `inside` is every tile reached and
## `leaked` whether the walk got out — to the tile just outside the passage, or past any
## size a yard could be.
func _enclosed(seed: Vector2i, passage: Vector2i, outside: Vector2i) -> Dictionary:
	var inside: Dictionary = {}
	var leaked: bool = false
	if not region.in_bounds(seed) or not region.is_passable(seed):
		return {"inside": inside, "leaked": true}
	inside[seed] = true
	var queue: Array[Vector2i] = [seed]
	while not queue.is_empty() and inside.size() < YARD_FLOOR_CAP:
		var at: Vector2i = queue.pop_back()
		for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = at + step
			if inside.has(next) or next == passage or not region.in_bounds(next):
				continue
			if next == outside:
				leaked = true
				continue
			if not region.is_passable(next):
				continue
			inside[next] = true
			queue.append(next)
	if inside.size() >= YARD_FLOOR_CAP:
		leaked = true
	return {"inside": inside, "leaked": leaked}


## What the ground is next to a footprint — the street it stands on, usually.
func _ground_beside(at: Vector2i, size: Vector2i) -> Region.Terrain:
	for tile: Vector2i in [at + Vector2i(-1, 0), at + Vector2i(size.x, 0), at + Vector2i(0, -1), at + Vector2i(0, size.y)]:
		if region.in_bounds(tile) and region.is_passable(tile):
			return region.terrain_at(tile)
	return Region.Terrain.TOWN


func _his_props_in(zone: StringName) -> int:
	var count: int = 0
	for prop: Dictionary in region.props:
		if bool(prop.get("his", false)) and (StringName(prop.get("place", &"")) == zone
			or region.zone_at(prop["at"] as Vector2i) == zone):
			count += 1
	return count


## Nothing walks off the edge: the outer ring is closed with what already bounds it.
func _border() -> void:
	for x: int in width:
		_close(Vector2i(x, 0))
		_close(Vector2i(x, height - 1))
	for y: int in height:
		_close(Vector2i(0, y))
		_close(Vector2i(width - 1, y))


func _close(tile: Vector2i) -> void:
	if region.is_passable(tile):
		region.set_terrain(tile, Region.Terrain.MOUNTAIN)


func _summarise() -> void:
	var counts: Dictionary = {}
	for y: int in height:
		for x: int in width:
			var kind: int = region.terrain_at(Vector2i(x, y))
			counts[kind] = int(counts.get(kind, 0)) + 1
	var parts := PackedStringArray()
	for kind: int in counts.keys():
		parts.append("%s %d" % [Region.Terrain.keys()[kind], counts[kind]])
	report.append("terrain: " + ", ".join(parts))
	report.append("props: %d" % region.props.size())
	for place: StringName in place_order:
		var row: Dictionary = places[place] as Dictionary
		report.append("place %-12s %s zone %s %s" % [place, row["centre"], row["size"],
			"SCAFFOLD" if bool(row["scaffold"]) else "his (%s)" % row["from"]])
	for id: StringName in points.keys():
		var row: Dictionary = points[id] as Dictionary
		var at: Vector2i = row["at"] as Vector2i
		report.append("point %-22s %s on %-8s %s" % [id, at, Region.Terrain.keys()[region.terrain_at(at)],
			"scaffold" if bool(row["scaffold"]) else "his"])
	for crossing: Dictionary in crossings:
		report.append("CROSSING %-28s over %2d tiles of river at %s (%.0f, %.0f m)" % [
			crossing["road"], crossing["tiles"], crossing["at"],
			(crossing["metres"] as Vector2).x, (crossing["metres"] as Vector2).y])


# ------------------------------------------------------------- conversions ---

func _metres(value: Variant) -> Vector2:
	var pair: Array = value as Array
	return Vector2(float(pair[0]), float(pair[1]))


func _tile(value: Variant) -> Vector2i:
	var at: Vector2 = _metres(value)
	return BakeRules.tile_for(at.x, at.y, origin_m, metres_per_tile)


## A size in metres to a size in tiles, never smaller than one.
func _tiles(value: Variant) -> Vector2i:
	var size: Vector2 = _metres(value) / metres_per_tile
	return Vector2i(maxi(int(round(size.x)), 1), maxi(int(round(size.y)), 1))


static func _pair(value: Variant) -> Vector2i:
	var pair: Array = value as Array
	if pair == null or pair.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(pair[0]), int(pair[1]))


## The nearest open tile to `from`, `from` itself first, or `from` if none is near.
func _dry(from: Vector2i) -> Vector2i:
	if region.in_bounds(from) and region.is_passable(from):
		return from
	for radius: int in range(1, NUDGE_RADIUS + 1):
		for dx: int in range(-radius, radius + 1):
			for dy: int in range(-radius, radius + 1):
				var at: Vector2i = from + Vector2i(dx, dy)
				if region.in_bounds(at) and region.is_passable(at):
					return at
	return from


# ----------------------------------------------------------------- the file ---

## Everything `Region.load_baked()` needs, and the provenance of what it was baked from.
func to_dictionary(source: Dictionary) -> Dictionary:
	var rows: Array[String] = []
	for y: int in height:
		var row := PackedByteArray()
		for x: int in width:
			row.append(region.terrain_at(Vector2i(x, y)))
		rows.append(BakeRules.encode_row(row))
	var places_out: Dictionary = {}
	for id: StringName in place_order:
		var row: Dictionary = places[id] as Dictionary
		places_out[String(id)] = {
			"centre": [(row["centre"] as Vector2i).x, (row["centre"] as Vector2i).y],
			"size": [(row["size"] as Vector2i).x, (row["size"] as Vector2i).y],
			"kit": [(row["kit"] as Vector2i).x, (row["kit"] as Vector2i).y],
			"scaffold": bool(row["scaffold"]), "kit_on_his": bool(row.get("kit_on_his", false)),
			"from": String(row["from"]),
		}
	var points_out: Dictionary = {}
	for id: StringName in points.keys():
		var row: Dictionary = points[id] as Dictionary
		points_out[String(id)] = {"at": [(row["at"] as Vector2i).x, (row["at"] as Vector2i).y],
			"scaffold": bool(row["scaffold"])}
	# The warded tiles, sorted so a re-bake of the same map is the same file.
	var wards_out: Array = []
	var warded: Array = region.wards.keys()
	warded.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	for tile: Vector2i in warded:
		wards_out.append({"at": [tile.x, tile.y], "ward": String(region.wards[tile])})
	var yards_out: Array = []
	for yard: Dictionary in region.yards:
		var floor_out: Array = []
		for tile: Vector2i in (yard["floor"] as Array):
			floor_out.append([tile.x, tile.y])
		yards_out.append({"place": String(yard["place"]), "ward": String(yard["ward"]),
			"passage": [(yard["passage"] as Vector2i).x, (yard["passage"] as Vector2i).y],
			"inside": [(yard["inside"] as Vector2i).x, (yard["inside"] as Vector2i).y],
			"floor": floor_out})
	var props_out: Array = []
	for prop: Dictionary in region.props:
		var out: Dictionary = {"kind": String(prop["kind"]),
			"at": [(prop["at"] as Vector2i).x, (prop["at"] as Vector2i).y],
			"size": [(prop["size"] as Vector2i).x, (prop["size"] as Vector2i).y]}
		if prop.has("solid"):
			out["solid"] = bool(prop["solid"])
		if bool(prop.get("his", false)):
			out["his"] = true
		for key: String in ["source_id", "scene", "place", "piece", "role", "yard"]:
			if prop.has(key):
				out[key] = prop[key]
		# A piece of his catalogue we placed (G1): where it stands in his metres, how it
		# is turned, and how far its origin sits above the ground.
		if prop.has("xz"):
			out["xz"] = [(prop["xz"] as Vector2).x, (prop["xz"] as Vector2).y]
			out["yaw"] = float(prop.get("yaw", 0.0))
			out["lift"] = float(prop.get("lift", 0.0))
		props_out.append(out)
	var trunk_out: Array = []
	for id: StringName in trunk:
		trunk_out.append(String(id))
	var spurs_out: Dictionary = {}
	for id: StringName in spurs.keys():
		var legs: Array = []
		for leg: StringName in (spurs[id] as Array):
			legs.append(String(leg))
		spurs_out[String(id)] = legs
	var crossings_out: Array = []
	for crossing: Dictionary in crossings:
		crossings_out.append({"road": crossing["road"],
			"at": [(crossing["at"] as Vector2i).x, (crossing["at"] as Vector2i).y],
			"tiles": crossing["tiles"]})
	return {
		"_note": "Baked by tools/bake_region.gd from the Brindle 3D workshop's data and content/bake_brief.json. Do not edit: re-run the bake. Rows are terrain runs, `kindxcount`, in Region.Terrain order.",
		"source": source,
		"width": width, "height": height,
		"metres_per_tile": metres_per_tile,
		"tiles_per_second": tiles_per_second,
		"origin_m": [origin_m.x, origin_m.y],
		"places": places_out,
		"points": points_out,
		"trunk": trunk_out,
		"spurs": spurs_out,
		"crossings": crossings_out,
		"props": props_out,
		"wards": wards_out,
		"yards": yards_out,
		"rows": rows,
	}


## The region in a baked file: its grid, its places as sites and zones, its props.
## The content's anchors — stalls, papers, fires — are `Region.load_baked()`'s job,
## because they need `Places`.
static func read(data: Dictionary) -> Region:
	var w: int = int(data.get("width", 0))
	var h: int = int(data.get("height", 0))
	var region := Region.new(maxi(w, 1), maxi(h, 1))
	var rows: Array = data.get("rows", []) as Array
	for y: int in h:
		var row: PackedByteArray = BakeRules.decode_row(String(rows[y]) if y < rows.size() else "", w)
		for x: int in w:
			region.set_terrain(Vector2i(x, y), row[x] as Region.Terrain)
	for id: String in (data.get("places", {}) as Dictionary).keys():
		var row: Dictionary = (data["places"] as Dictionary)[id] as Dictionary
		region.sites[StringName(id)] = _pair(row.get("centre", [0, 0]))
		region.footprints[StringName(id)] = _pair(row.get("size", [1, 1]))
	region.bake_zones()
	for entry: Variant in (data.get("wards", []) as Array):
		var row: Dictionary = entry as Dictionary
		var at: Array = row.get("at", [0, 0]) as Array
		region.wards[Vector2i(int(at[0]), int(at[1]))] = StringName(String(row.get("ward", "")))
	for entry: Variant in (data.get("props", []) as Array):
		var prop: Dictionary = entry as Dictionary
		var out: Dictionary = {"kind": StringName(String(prop.get("kind", ""))),
			"at": _pair(prop.get("at", [0, 0])), "size": _pair(prop.get("size", [1, 1]))}
		if prop.has("solid"):
			out["solid"] = bool(prop["solid"])
		if bool(prop.get("his", false)):
			out["his"] = true
		for key: String in ["source_id", "scene", "place", "piece", "role", "yard"]:
			if prop.has(key):
				out[key] = prop[key]
		if prop.has("xz"):
			var xz: Array = prop["xz"] as Array
			out["xz"] = Vector2(float(xz[0]), float(xz[1]))
			out["yaw"] = float(prop.get("yaw", 0.0))
			out["lift"] = float(prop.get("lift", 0.0))
		region.props.append(out)
	for entry: Variant in (data.get("yards", []) as Array):
		var row: Dictionary = entry as Dictionary
		var floor: Array[Vector2i] = []
		for pair: Variant in (row.get("floor", []) as Array):
			floor.append(_pair(pair))
		region.yards.append({"place": String(row.get("place", "")), "ward": String(row.get("ward", "")),
			"passage": _pair(row.get("passage", [-1, -1])), "inside": _pair(row.get("inside", [-1, -1])),
			"floor": floor})
	return region


## Built crossings go down before roads, so the report only owes unbuilt crossings.
## Their end markers are delivered in landscape.json, not coordinates of ours.
func _bridges(landscape: Dictionary, brief: Dictionary) -> void:
	for bridge: Dictionary in landscape.get("crossings", []):
		var entry: Array = bridge["entry_xyz"]
		var exit: Array = bridge["exit_xyz"]
		var anchor: Array = bridge["anchor_xz"]
		var id: StringName = StringName(bridge["id"])
		points[id] = {"at": _tile(anchor), "scaffold": false}
		var from := Vector2(float(entry[0]), float(entry[2]))
		var to := Vector2(float(exit[0]), float(exit[2]))
		# The narrow footbridge still needs an axis-connected staircase on a 2 m
		# grid; half a tile diagonal is the minimum raster coverage (2026-09-15).
		var radius: float = maxf(float(bridge["clear_width_m"]) * 0.5, metres_per_tile / sqrt(2.0))
		var low: Vector2i = _tile(anchor) - Vector2i.ONE * (ceili(float(bridge["length_m"]) / metres_per_tile) + 1)
		var high: Vector2i = _tile(anchor) + Vector2i.ONE * (ceili(float(bridge["length_m"]) / metres_per_tile) + 1)
		for x: int in range(low.x, high.x + 1):
			for y: int in range(low.y, high.y + 1):
				var tile := Vector2i(x, y)
				var metres: Vector2 = BakeRules.metres_for(tile, origin_m, metres_per_tile)
				if region.in_bounds(tile) and metres.distance_to(Geometry2D.get_closest_point_to_segment(metres, from, to)) <= radius:
					region.set_terrain(tile, Region.Terrain.ROAD)
					_bridge_tiles[tile] = true
	for name: String in (brief.get("points", {}) as Dictionary):
		var alias: Dictionary = brief["points"][name] as Dictionary
		if alias.has("from_crossing"):
			var source_id: StringName = StringName(alias["from_crossing"])
			if points.has(source_id):
				points[StringName(name)] = points[source_id].duplicate()
			else:
				report.append("POINT %s: missing delivered crossing %s" % [name, source_id])
	# Those water tiles are backed by his bridge meshes, not missing crossings.
	crossings.clear()
	_built_crossings = not (landscape.get("crossings", []) as Array).is_empty()
	report.append("bridges: %d of his crossings connect their delivered end markers" %
		(landscape.get("crossings", []) as Array).size())


## His collision shapes, rather than roof-sized boxes, keep open halls walkable.
## Geometry is extracted outside core by the build tool (2026-09-15).
func _ironworks(town: Dictionary) -> void:
	var items: Array = (town.get("buildings", []) as Array) + (town.get("props", []) as Array)
	for item: Dictionary in items:
		var centre: Vector2i = _tile(item["xz"])
		var kind: StringName = &"kiln" if String(item["asset"]).begins_with("bas_fourneau") else StringName(item["asset"])
		var size_m: Array = item["size_m"]
		var reach: int = ceili(maxf(float(size_m[0]), float(size_m[2])) / metres_per_tile) + 2
		var low: Vector2i = centre - Vector2i(reach, reach)
		var high: Vector2i = centre + Vector2i(reach, reach)
		var blocked: Array[Vector2i] = []
		for raw: Array in item.get("obstacles", []):
			var polygon := PackedVector2Array()
			for pair: Array in raw:
				polygon.append(_metres(pair))
			for x: int in range(low.x, high.x + 1):
				for y: int in range(low.y, high.y + 1):
					var tile := Vector2i(x, y)
					var metres: Vector2 = BakeRules.metres_for(tile, origin_m, metres_per_tile)
					if region.in_bounds(tile) and Geometry2D.is_point_in_polygon(metres, polygon):
						if not blocked.has(tile):
							blocked.append(tile)
		var first: Vector2i = centre
		var last: Vector2i = centre
		for tile: Vector2i in blocked:
			first = first.min(tile)
			last = last.max(tile)
			region.set_terrain(tile, Region.Terrain.WALL)
		region.props.append({"kind": kind, "at": first, "size": last - first + Vector2i.ONE,
			"his": true, "source_id": item["id"], "scene": item["scene"], "place": "cinderworks"})
	report.append("ironworks: %d buildings and %d props, collision shapes retained" % [
		(town.get("buildings", []) as Array).size(), (town.get("props", []) as Array).size()])
