extends SceneTree

## The bake: the 3D workshop's data in, `content/region.json` out (MIGRATION_3D §6.2).
##
##   godot --headless --path . -s tools/bake_region.gd            bake and write
##   godot --headless --path . -s tools/bake_region.gd -- --check bake and compare with
##                                                                  the checked-in file;
##                                                                  exit 1 if it differs
##
## Run it whenever his data or the brief changes, and check the output in, so a clone
## plays without his tools. It bakes twice and refuses to write if the two differ:
## a bake that is not deterministic would make a save that does not replay.
## `--check` is for CI: a merged map change that nobody re-baked is a red build,
## not a surprise in play.

const Geometry: GDScript = preload("res://tools/workshop_geometry.gd")

const WORKSHOP: String = RegionBake.WORKSHOP
const BRIEF: String = "res://content/bake_brief.json"
const OUT: String = "res://content/region.json"

const INPUTS: Array[String] = [
	"assets/landscape/landscape.json",
	"assets/landscape/height.f32",
	"assets/landscape/water_level.f32",
	"assets/landscape/terrain_paint.f32",
	"planning/geographie-v1.json",
	"planning/brindle-sectors-v1.json",
	"planning/forest-placements-v1.json",
	"planning/ironworks-town.json",
	"planning/river-layout-v2.json",
	"planning/river-routes-v2.json",
	# His final ground round Brindle (O11): the coast and the scripts that make it.
	"planning/coastline.json",
	"assets/coastline/terrain_edits.f32",
	"assets/landscape/water_flow.f32",
	"scripts/flat_ground.gd",
	"scripts/terrain_stamp.gd",
	"scenes/relief_godot.tscn",
	"scripts/coastal_terrain.gd",
	"scripts/royal_ascent.gd",
	"scripts/farming_terrain.gd",
	"planning/royal-city.json",
	"planning/farming-town.json",
]

## The files his runtime reads from the copy in `view3d/workshop/`, which must be the
## same bytes as his in `prototypes/` or the final ground is somebody else's.
const RUNTIME_READS: Array[String] = [
	"assets/landscape/landscape.json",
	"assets/landscape/height.f32",
	"assets/landscape/water_level.f32",
	"assets/landscape/terrain_paint.f32",
	"assets/landscape/water_flow.f32",
	"assets/coastline/terrain_edits.f32",
	"planning/coastline.json",
	"planning/royal-city.json",
	"planning/farming-town.json",
]
const VENDORED: String = "res://view3d/workshop/"

## His final ground inside the brief's box, once made: {"heights", "paint"} as his
## runtime leaves them, or empty.
var _final: Dictionary = {}


func _initialize() -> void:
	# **His final ground needs his runtime, and his runtime needs a frame** (O11): the
	# relief stamps are placed by their transforms, which only exist inside the tree. So
	# the plate is stood up now and the bake runs on the first frame.
	var brief: Dictionary = _json(BRIEF) as Dictionary
	if brief.has("his_final_ground"):
		for file: String in RUNTIME_READS:
			if not _same_as_his(file):
				push_error("the copy of his workshop is stale (%s); run tools/vendor_workshop.sh" % file)
				quit(1)
				return
		var plate := Node3D.new()
		plate.name = "Plate"
		root.add_child(plate)
		var ground := Node3D.new()
		ground.set_script(load(VENDORED + "scripts/flat_ground.gd"))
		ground.name = "Terrain"
		plate.add_child(ground)
		var relief: Node = (load(VENDORED + "scenes/relief_godot.tscn") as PackedScene).instantiate()
		relief.name = "ReliefGodot"
		plate.add_child(relief)
		process_frame.connect(_with_his_ground.bind(ground), CONNECT_ONE_SHOT)
		return
	_run()


## Whether the copy his runtime reads is his file. Byte for byte for his data; for a
## JSON file once the paths the copy repoints are put back, since repointing them is
## what the copy is for.
func _same_as_his(file: String) -> bool:
	if not file.ends_with(".json"):
		return FileAccess.get_sha256(WORKSHOP + file) == FileAccess.get_sha256(VENDORED + file)
	var copied: String = FileAccess.get_file_as_string(VENDORED + file).replace(VENDORED, "res://")
	return copied == FileAccess.get_file_as_string(WORKSHOP + file)


## His runtime makes his ground; the bake takes the heights and the rock inside the box.
func _with_his_ground(ground: Node3D) -> void:
	ground.call("rebuild_ground")
	_final = {
		"heights": ground.get("_height") as PackedFloat32Array,
		"paint": ground.get("_paint") as PackedFloat32Array,
	}
	ground.get_parent().queue_free()
	_run()


## The landscape the bake reads: his raw files, with his final ground inside the box.
func _landscape() -> Dictionary:
	var landscape: Dictionary = RegionBake.read_landscape()
	if _final.is_empty():
		return landscape
	var box: Array = ((_json(BRIEF) as Dictionary).get("his_final_ground", {}) as Dictionary).get("box_tiles", []) as Array
	if box.size() != 4:
		return landscape
	var samples: int = int((landscape["meta"] as Dictionary).get("grid_size", 0))
	var heights: PackedFloat32Array = (landscape["heights"] as PackedFloat32Array).duplicate()
	var paint: PackedFloat32Array = (landscape["paint"] as PackedFloat32Array).duplicate()
	var final_h: PackedFloat32Array = _final["heights"] as PackedFloat32Array
	var final_p: PackedFloat32Array = _final["paint"] as PackedFloat32Array
	for z: int in range(maxi(int(box[1]), 0), mini(int(box[3]) + 1, samples)):
		for x: int in range(maxi(int(box[0]), 0), mini(int(box[2]) + 1, samples)):
			var i: int = z * samples + x
			heights[i] = final_h[i]
			for channel: int in 3:
				paint[i * 3 + channel] = final_p[i * 3 + channel]
	landscape["heights"] = heights
	landscape["paint"] = paint
	return landscape


## His coast's paths, as the bake lays them: `{id, points_xz, width_m}`.
func _his_paths() -> Array:
	var coast: Dictionary = _json(WORKSHOP + "planning/coastline.json") as Dictionary
	var out: Array = []
	for entry: Variant in (coast.get("trails", []) as Array) + (coast.get("approach_grading", []) as Array):
		var trail: Dictionary = entry as Dictionary
		var points: Array = []
		for p: Variant in trail.get("profile_xzy", []) as Array:
			points.append([(p as Array)[0], (p as Array)[1]])
		out.append({"id": String(trail.get("id", "his path")), "points_xz": points,
			"width_m": float(trail.get("width_m", 0.0))})
	return out


func _run() -> void:
	var check: bool = OS.get_cmdline_user_args().has("--check")
	for file: String in INPUTS:
		if not FileAccess.file_exists(WORKSHOP + file):
			push_error("missing input: %s" % (WORKSHOP + file))
			quit(1)
			return
	# The landscape carries resolved bridge endpoints. Refuse stale derived metadata
	# instead of blessing changed river input with a fresh source hash.
	var layout: Dictionary = _json(WORKSHOP + "planning/river-layout-v2.json") as Dictionary
	var meta: Dictionary = _json(WORKSHOP + "assets/landscape/landscape.json") as Dictionary
	var resolved: Dictionary = {}
	for bridge: Dictionary in meta.get("crossings", []):
		resolved[bridge["id"]] = bridge
	for bridge: Dictionary in layout.get("crossings", []):
		for key: String in bridge:
			if not resolved.has(bridge["id"]) or resolved[bridge["id"]].get(key) != bridge[key]:
				push_error("workshop landscape has stale crossing metadata for %s" % bridge["id"])
				quit(1)
				return
	if resolved.size() != (layout.get("crossings", []) as Array).size():
		push_error("workshop landscape and river layout name different crossings")
		quit(1)
		return
	var town: Dictionary = _json(WORKSHOP + "planning/ironworks-town.json") as Dictionary
	var geometry: Dictionary = Geometry.town_with_collisions(town)
	if geometry.is_empty():
		push_error("missing workshop scenes; run tools/vendor_workshop.sh")
		quit(1)
		return
	# **His catalogue, then the yards composed from it** (G1–G2, 2026-09-21). The brief
	# names which of his catalogues the bake reads; every piece the yards place is one of
	# their entries, stood at a place and a yaw in his metres, and the geometry tool
	# extracts what his scene blocks at exactly that placement.
	var brief: Dictionary = _json(BRIEF) as Dictionary
	var catalog: Dictionary = {"assets": []}
	var catalog_files: Array = brief.get("catalogs", []) as Array
	for file: Variant in catalog_files:
		if not FileAccess.file_exists(WORKSHOP + String(file)):
			push_error("missing catalogue of his: %s" % (WORKSHOP + String(file)))
			quit(1)
			return
		var one: Dictionary = _json(WORKSHOP + String(file)) as Dictionary
		(catalog["assets"] as Array).append_array(one.get("assets", []) as Array)
	var landscape: Dictionary = _landscape()
	var composed: Dictionary = RegionBake.compose_yards(landscape.get("meta", {}) as Dictionary,
		landscape.get("heights", PackedFloat32Array()) as PackedFloat32Array,
		landscape.get("waters", PackedFloat32Array()) as PackedFloat32Array, brief, catalog, geometry)
	var pieces: Array = Geometry.pieces_with_collisions(composed["pieces"] as Array)
	if pieces.size() != (composed["pieces"] as Array).size():
		push_error("a piece of his catalogue could not be read; run tools/vendor_workshop.sh")
		quit(1)
		return
	var first: RegionBake = _bake(geometry, pieces)
	if first.region == null:
		for line: String in first.report:
			print(line)
		quit(1)
		return
	var second: RegionBake = _bake(geometry, pieces)
	var source: Dictionary = {}
	for file: String in INPUTS:
		source[file] = FileAccess.get_sha256(WORKSHOP + file)
	for file: Variant in catalog_files:
		source[String(file)] = FileAccess.get_sha256(WORKSHOP + String(file))
	for item: Dictionary in (town["buildings"] as Array) + (town["props"] as Array) + pieces:
		var relative: String = String(item["scene"]).trim_prefix("res://")
		source[relative] = FileAccess.get_sha256(WORKSHOP + relative)
	source["content/bake_brief.json"] = FileAccess.get_sha256(BRIEF)
	# Keys unsorted, so the places come out in the brief's order — which is the zone
	# order — and a reader finds the rows top to bottom as on the map.
	var text: String = JSON.stringify(first.to_dictionary(source), "  ", false) + "\n"
	var again: String = JSON.stringify(second.to_dictionary(source), "  ", false) + "\n"

	print("bake_region — %d x %d tiles at %.1f m, origin (%.0f, %.0f) m\n" % [
		first.width, first.height, first.metres_per_tile, first.origin_m.x, first.origin_m.y])
	for line: String in (composed["report"] as Array):
		print("  " + String(line))
	for line: String in first.report:
		print("  " + line)
	print()
	if text != again:
		print("REFUSED: two bakes of the same data differ. Nothing written.")
		quit(1)
		return
	print("deterministic: two bakes agree, %d bytes" % text.length())

	if check:
		var current: String = FileAccess.get_file_as_string(OUT) if FileAccess.file_exists(OUT) else ""
		if current == text:
			print("check: content/region.json is up to date with his data and the brief")
			quit(0)
		else:
			print("check: content/region.json is STALE — run the bake and commit the result")
			quit(1)
		return

	var out: FileAccess = FileAccess.open(OUT, FileAccess.WRITE)
	if out == null:
		push_error("cannot write %s" % OUT)
		quit(1)
		return
	out.store_string(text)
	out.close()
	print("wrote %s" % OUT)
	quit(0)


func _bake(town: Dictionary, pieces: Array) -> RegionBake:
	var landscape: Dictionary = _landscape()
	return RegionBake.bake(
		landscape.get("meta", {}) as Dictionary,
		landscape.get("heights", PackedFloat32Array()) as PackedFloat32Array,
		landscape.get("waters", PackedFloat32Array()) as PackedFloat32Array,
		landscape.get("paint", PackedFloat32Array()) as PackedFloat32Array,
		_json(WORKSHOP + "planning/geographie-v1.json") as Dictionary,
		_json(WORKSHOP + "planning/brindle-sectors-v1.json") as Dictionary,
		_json(WORKSHOP + "planning/forest-placements-v1.json") as Array,
		_json(BRIEF) as Dictionary,
		town,
		_json(WORKSHOP + "planning/river-routes-v2.json") as Dictionary,
		pieces,
		_his_paths(),
	)


func _json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))
