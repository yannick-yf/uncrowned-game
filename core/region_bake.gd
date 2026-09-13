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
## and clearing. Roads — his, then ours — over everything walkable and *over water
## where his roads cross it*, because a road drawn through a river is a crossing
## whether or not a bridge was modelled, and the report names every one so the brief
## can ask for the bridge. The ford is a band on the river. His buildings stand as
## walls under a prop. Then **the kit**: every place marked scaffold gets its ground,
## streets, landmarks and scenery from `Region.scaffold_place`; a place of his gets the
## same only if his data stands no building in it. Last, the border is closed.
##
## Uses only the public face of `Region` — `set_terrain`, `terrain_at`, `is_passable`,
## `in_bounds`, `zone_at`, `props`, `sites`, `footprints`, `bake_zones` and the
## `scaffold_*` kit — so the two classes stay separable.

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
## Where a road was laid over water: {"road": String, "at": Vector2i, "metres": Vector2}
var crossings: Array[Dictionary] = []
var report: Array[String] = []


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

	out._ground(samples, heights, waters, paint)
	out._places(geography, brief)
	out._points(sectors, brief)
	out._woods(brief)
	out._grounds(brief)
	out._trees(trees)
	out._wound_and_clearing()
	out._roads(geography, sectors, brief)
	out._ford()
	out._buildings(sectors, brief)
	out._kit(brief)
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
func _places(geography: Dictionary, brief: Dictionary) -> void:
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
		region.scaffold_clearing((points[&"clearing"] as Dictionary)["at"] as Vector2i, walled_to)


## His roads, his village paths, his bridge, then the brief's roads.
func _roads(geography: Dictionary, sectors: Dictionary, brief: Dictionary) -> void:
	for entry: Variant in (geography.get("roads", []) as Array):
		var road: Dictionary = entry as Dictionary
		_polyline(String(road.get("id", "road")), road.get("points_xz", []) as Array, ROAD_HALF,
			Region.Terrain.ROAD)
	for entry: Variant in (sectors.get("routes", []) as Array):
		var route: Dictionary = entry as Dictionary
		var half: int = ROAD_HALF if float(route.get("width", 0.0)) >= PATH_WIDE_FROM_M else 0
		_polyline(String(route.get("id", "path")), route.get("points", []) as Array, half,
			Region.Terrain.ROAD)
	var ends: Array = sectors.get("bridge_endpoints_xzy", []) as Array
	if ends.size() == 2:
		var a: Array = ends[0] as Array
		var b: Array = ends[1] as Array
		_polyline("his_bridge", [[a[0], a[1]], [b[0], b[1]]], ROAD_HALF, Region.Terrain.ROAD)
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
						wet += 1
						if first_wet == Region.NOWHERE:
							first_wet = tile
					region.set_terrain(tile, terrain)
	if wet > 0:
		crossings.append({"road": id, "at": first_wet,
			"metres": BakeRules.metres_for(first_wet, origin_m, metres_per_tile), "tiles": wet})
	if cut > 0:
		report.append("cutting %-28s %d tiles of rock under the road" % [id, cut])


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
		place(StringName(kind), centre - size / 2, size)
	report.append("buildings: %d of his stand as props" % (sectors.get("buildings", []) as Array).size())


## A prop with a solid footprint, as `Region._place` does for the procedural map.
## The road is never closed by it.
func place(kind: StringName, at: Vector2i, size: Vector2i) -> void:
	region.props.append({"kind": kind, "at": at, "size": size})
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
			report.append("kit   %-12s his: %d of his buildings stand in it, nothing of ours" % [id, _his_props_in(id)])


func _his_props_in(zone: StringName) -> int:
	var count: int = 0
	for prop: Dictionary in region.props:
		if region.zone_at(prop["at"] as Vector2i) == zone:
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
	var props_out: Array = []
	for prop: Dictionary in region.props:
		var out: Dictionary = {"kind": String(prop["kind"]),
			"at": [(prop["at"] as Vector2i).x, (prop["at"] as Vector2i).y],
			"size": [(prop["size"] as Vector2i).x, (prop["size"] as Vector2i).y]}
		if prop.has("solid"):
			out["solid"] = bool(prop["solid"])
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
		"origin_m": [origin_m.x, origin_m.y],
		"places": places_out,
		"points": points_out,
		"trunk": trunk_out,
		"spurs": spurs_out,
		"crossings": crossings_out,
		"props": props_out,
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
	for entry: Variant in (data.get("props", []) as Array):
		var prop: Dictionary = entry as Dictionary
		var out: Dictionary = {"kind": StringName(String(prop.get("kind", ""))),
			"at": _pair(prop.get("at", [0, 0])), "size": _pair(prop.get("size", [1, 1]))}
		if prop.has("solid"):
			out["solid"] = bool(prop["solid"])
		region.props.append(out)
	return region
