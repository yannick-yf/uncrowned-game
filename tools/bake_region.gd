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

const WORKSHOP: String = "res://prototypes/brindle_3d/"
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
]


func _initialize() -> void:
	var check: bool = OS.get_cmdline_user_args().has("--check")
	for file: String in INPUTS:
		if not FileAccess.file_exists(WORKSHOP + file):
			push_error("missing input: %s" % (WORKSHOP + file))
			quit(1)
			return
	var first: RegionBake = _bake()
	if first.region == null:
		for line: String in first.report:
			print(line)
		quit(1)
		return
	var second: RegionBake = _bake()
	var source: Dictionary = {}
	for file: String in INPUTS:
		source[file] = FileAccess.get_sha256(WORKSHOP + file)
	source["content/bake_brief.json"] = FileAccess.get_sha256(BRIEF)
	# Keys unsorted, so the places come out in the brief's order — which is the zone
	# order — and a reader finds the rows top to bottom as on the map.
	var text: String = JSON.stringify(first.to_dictionary(source), "  ", false) + "\n"
	var again: String = JSON.stringify(second.to_dictionary(source), "  ", false) + "\n"

	print("bake_region — %d x %d tiles at %.1f m, origin (%.0f, %.0f) m\n" % [
		first.width, first.height, first.metres_per_tile, first.origin_m.x, first.origin_m.y])
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


func _bake() -> RegionBake:
	return RegionBake.bake(
		_json(WORKSHOP + "assets/landscape/landscape.json") as Dictionary,
		_floats(WORKSHOP + "assets/landscape/height.f32"),
		_floats(WORKSHOP + "assets/landscape/water_level.f32"),
		_floats(WORKSHOP + "assets/landscape/terrain_paint.f32"),
		_json(WORKSHOP + "planning/geographie-v1.json") as Dictionary,
		_json(WORKSHOP + "planning/brindle-sectors-v1.json") as Dictionary,
		_json(WORKSHOP + "planning/forest-placements-v1.json") as Array,
		_json(BRIEF) as Dictionary,
	)


func _json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


## His arrays: little-endian float32, row-major z then x — exactly as his
## `flat_ground.gd` reads them.
func _floats(path: String) -> PackedFloat32Array:
	return FileAccess.get_file_as_bytes(path).to_float32_array()
