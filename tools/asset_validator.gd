class_name AssetValidator
extends RefCounted

## Rejects art that does not belong to the approved pack.
##
## SPECS §13 makes this a hard rule: assets come from one approved pack, and
## anything off-palette or off-grid fails a validator rather than reaching the
## screen. Mixing packs is the clearest mark of an amateur game, and it is very
## easy to do by accident — one borrowed sprite at a time.
##
## The approved pack is the palette source, so it passes by construction. The point
## of this validator is everything added *after* it.

const PALETTE_PATH: String = "res://content/palette.txt"
const ASSETS_ROOT: String = "res://assets"

## Per-machine, outside the repo: a cache is an optimisation, not a fact about the
## project, and a stale one committed by accident would be worse than none.
const CACHE_PATH: String = "user://asset_validator_cache.json"

## The 16 px grid is checked only for declared tile sources. Free-standing sprites
## are not laid on the grid and the approved pack does not pretend otherwise: 812
## of its 1899 art files are not multiples of 16, because a 38x38 portrait or a
## 13x13 UI arrow has no reason to be. Widening this to every image would reject
## the approved pack itself.
const TILE_SOURCE_MARKERS: Array[String] = ["/Tilesets/"]

## Sprite folders that must never exist in assets/ and must never be named in
## code. CLAUDE.md invariant 10: "There are no children in this game. No child
## characters, in any role, ever."
##
## Enforced by the machine rather than remembered, because remembering is exactly
## what fails. The pack shipped all four; they are deleted, and this stops them
## coming back with the next pack update or the next borrowed sprite.
##
## Matched as path segments — "Character/Child", not "Child" — so that get_child()
## and add_child() do not trip it. A denylist that cries wolf gets switched off.
const FORBIDDEN_SPRITES: Array[String] = ["Child", "EggBoy", "EggGirl", "LionBoy"]
const SOURCE_ROOTS: Array[String] = ["res://core", "res://view", "res://tools",
	"res://test", "res://content"]
const DENYLIST_FILE: String = "res://tools/asset_validator.gd"


## Denylisted sprite folders still sitting in assets/.
static func forbidden_assets() -> PackedStringArray:
	var found := PackedStringArray()
	for name: String in FORBIDDEN_SPRITES:
		for root: String in ["res://assets"]:
			_find_dirs_named(root, name, found)
	return found


static func _find_dirs_named(dir: String, name: String, out: PackedStringArray) -> void:
	for sub: String in DirAccess.get_directories_at(dir):
		var path: String = "%s/%s" % [dir, sub]
		if sub == name:
			out.append(path)
		_find_dirs_named(path, name, out)


## Denylisted sprite folders named anywhere in the source.
static func forbidden_references() -> PackedStringArray:
	var found := PackedStringArray()
	for root: String in SOURCE_ROOTS:
		_scan_source(root, found)
	return found


static func _scan_source(dir: String, out: PackedStringArray) -> void:
	for sub: String in DirAccess.get_directories_at(dir):
		_scan_source("%s/%s" % [dir, sub], out)
	for name: String in DirAccess.get_files_at(dir):
		if not (name.ends_with(".gd") or name.ends_with(".tscn") or name.ends_with(".json")):
			continue
		var path: String = "%s/%s" % [dir, name]
		# The file that declares the list necessarily names everything on it.
		if path == DENYLIST_FILE:
			continue
		var text: String = FileAccess.get_file_as_string(path)
		for forbidden: String in FORBIDDEN_SPRITES:
			if text.contains("Character/%s" % forbidden) or text.contains("\"%s\"" % forbidden):
				out.append("%s names %s" % [path, forbidden])


## Contact sheets, not assets: scaled marketing composites whose resampling invents
## 193 blended colours found in no art file. Excluded from the palette, so also
## excluded from the check against it.
const PREVIEW_MARKER: String = "preview"

## Off-grid tile sources that predate the rule, each with a reason. Reported on
## every run so they cannot quietly become normal. Do not add to this without a
## reason you would defend out loud.
const KNOWN_EXCEPTIONS: Dictionary = {
	"res://assets/NinjaAdventure/Ninja Adventure - Asset Pack/Backgrounds/Tilesets/TilesetFloor.png":
		"352x417 — one pixel taller than 26 tiles. A flaw in the approved pack, not ours.",
}


class Report extends RefCounted:
	var scanned: int = 0
	var previews_skipped: int = 0
	var tile_sources: int = 0
	var exceptions_used: PackedStringArray = PackedStringArray()
	var palette_size: int = 0
	var cache_hits: int = 0
	var tree_rewalked: bool = true
	var off_palette: PackedStringArray = PackedStringArray()
	var off_grid: PackedStringArray = PackedStringArray()
	var unreadable: PackedStringArray = PackedStringArray()

	func ok() -> bool:
		return off_palette.is_empty() and off_grid.is_empty() and unreadable.is_empty()

	func failure_count() -> int:
		return off_palette.size() + off_grid.size() + unreadable.size()


## Every colour the approved pack authored, as packed 0xRRGGBB keys.
static func load_palette() -> Dictionary:
	var palette: Dictionary = {}
	var file: FileAccess = FileAccess.open(PALETTE_PATH, FileAccess.READ)
	if file == null:
		return palette
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		palette[line.to_lower().hex_to_int()] = true
	return palette


static func png_paths(root: String = ASSETS_ROOT) -> Array[String]:
	var out: Array[String] = []
	_collect(root, out)
	out.sort()
	return out


static func _collect(dir: String, out: Array[String]) -> void:
	for sub: String in DirAccess.get_directories_at(dir):
		_collect("%s/%s" % [dir, sub], out)
	for name: String in DirAccess.get_files_at(dir):
		if name.to_lower().ends_with(".png"):
			out.append("%s/%s" % [dir, name])


static func is_preview(path: String) -> bool:
	return path.get_file().to_lower().contains(PREVIEW_MARKER)


static func is_on_grid(image: Image) -> bool:
	return image.get_width() % 16 == 0 and image.get_height() % 16 == 0


static func is_tile_source(path: String) -> bool:
	for marker: String in TILE_SOURCE_MARKERS:
		if path.contains(marker):
			return true
	return false


## One scan of 1899 images costs about a second, which is a second the feedback
## loop does not have to spend eight times. Cached for the life of the process;
## the standalone runner calls validate() directly and always scans fresh.
static var _cached_report: Report = null


static func cached_report() -> Report:
	if _cached_report == null:
		_cached_report = validate()
	return _cached_report


static func validate(max_reported: int = 40, use_cache: bool = true) -> Report:
	var report := Report.new()
	var palette: Dictionary = load_palette()
	report.palette_size = palette.size()
	if palette.is_empty():
		report.unreadable.append("%s is missing or empty — no palette to validate against" % PALETTE_PATH)
		return report

	var cache: Dictionary = _load_cache(palette) if use_cache else {}
	var tree: Dictionary = _tree(cache) if use_cache else {"paths": png_paths(), "dirs": {}, "rewalked": true}
	var known: Dictionary = cache.get("files", {}) as Dictionary
	report.tree_rewalked = bool(tree["rewalked"])
	var fresh: Dictionary = {}

	for path: String in (tree["paths"] as Array):
		if is_preview(path):
			report.previews_skipped += 1
			continue

		var stamp: String = _stamp_of(path)
		if stamp.is_empty():
			report.unreadable.append(path)
			continue

		# A file whose bytes have not moved cannot have changed colour. Decoding it
		# again to confirm that is the whole second the feedback loop was losing.
		var entry: Array = known.get(path, []) as Array
		if entry.size() != 4 or String(entry[0]) != stamp:
			var image: Image = _read_source_png(path)
			if image == null:
				report.unreadable.append(path)
				continue
			entry = [stamp, first_stray_colour(image, palette), image.get_width(), image.get_height()]
		else:
			report.cache_hits += 1

		fresh[path] = entry
		report.scanned += 1
		var stray: int = int(entry[1])
		var w: int = int(entry[2])
		var h: int = int(entry[3])

		if is_tile_source(path):
			report.tile_sources += 1
			if w % 16 != 0 or h % 16 != 0:
				if KNOWN_EXCEPTIONS.has(path):
					report.exceptions_used.append("%s — %s" % [path.get_file(), KNOWN_EXCEPTIONS[path]])
				elif report.off_grid.size() < max_reported:
					report.off_grid.append("%s is %dx%d, not a multiple of 16" % [path, w, h])

		if stray >= 0 and report.off_palette.size() < max_reported:
			report.off_palette.append("%s uses #%06x, which is not in the palette" % [path, stray])

	if use_cache:
		_save_cache(palette, fresh, tree["dirs"] as Dictionary, tree["paths"] as Array)
	return report


## Enumerating the 442 directories under assets/ costs about 170 ms; stat-ing them
## costs 3. So the tree is cached too, and a directory's modification time is what
## reports a file being added or removed inside it. Content changes are caught
## separately, by each file's own stamp — the two checks cover different things and
## both are needed.
static func _tree(cache: Dictionary) -> Dictionary:
	var cached_dirs: Dictionary = cache.get("dirs", {}) as Dictionary
	if not cached_dirs.is_empty() and _dirs_unchanged(cached_dirs):
		var reused: Array[String] = []
		for entry: Variant in (cache.get("paths", []) as Array):
			reused.append(String(entry))
		if not reused.is_empty():
			return {"dirs": cached_dirs, "paths": reused, "rewalked": false}

	var dirs: Array[String] = []
	var files: Array[String] = []
	_walk(ASSETS_ROOT, dirs, files)
	files.sort()
	var stamps: Dictionary = {}
	for dir: String in dirs:
		stamps[dir] = FileAccess.get_modified_time(dir)
	return {"dirs": stamps, "paths": files, "rewalked": true}


## A deleted directory stats as 0 and so reads as changed, which is correct.
static func _dirs_unchanged(stamps: Dictionary) -> bool:
	for dir: String in stamps.keys():
		if FileAccess.get_modified_time(dir) != int(stamps[dir]):
			return false
	return true


static func _walk(dir: String, dirs: Array[String], files: Array[String]) -> void:
	dirs.append(dir)
	for sub: String in DirAccess.get_directories_at(dir):
		_walk("%s/%s" % [dir, sub], dirs, files)
	for name: String in DirAccess.get_files_at(dir):
		if name.to_lower().ends_with(".png"):
			files.append("%s/%s" % [dir, name])


## Identity of a file, cheaply: one stat, no open, no read. This is what keeps a
## warm run in the low hundreds of milliseconds instead of half a second, and a
## warm run is the only kind that happens after every change.
##
## Modification time alone, deliberately: adding the length costs a second syscall
## per file for a weak guarantee, since a recolour usually preserves the byte count
## anyway. The honest failure mode is an edit within the same clock second as the
## previous scan. Run with --no-cache when that matters, which CI always should.
static func _stamp_of(path: String) -> String:
	var modified: int = FileAccess.get_modified_time(path)
	if modified == 0:
		return ""
	return str(modified)


## The palette is part of the cache key: relock it and every cached verdict about
## whether a colour belongs is worthless.
static func _palette_key(palette: Dictionary) -> String:
	var keys: Array = palette.keys()
	keys.sort()
	return "%d:%d" % [keys.size(), hash(keys)]


static func _load_cache(palette: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(CACHE_PATH):
		return {}
	var text: String = FileAccess.get_file_as_string(CACHE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {}
	var root: Dictionary = parsed as Dictionary
	if String(root.get("palette", "")) != _palette_key(palette):
		return {}
	return root


static func _save_cache(palette: Dictionary, files: Dictionary, dirs: Dictionary, paths: Array) -> void:
	var file: FileAccess = FileAccess.open(CACHE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"palette": _palette_key(palette),
		"files": files,
		"dirs": dirs,
		"paths": paths,
	}))
	file.close()


## Reads the PNG off disk rather than through the resource system. The validator's
## subject is the *source* file: an imported texture has been through the importer,
## which is free to compress or resize it, and a palette check on a lossy copy of
## the art would be a palette check on nothing.
static func _read_source_png(path: String) -> Image:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		return null
	return image


## Returns the first off-palette colour as 0xRRGGBB, or -1 if the image is clean.
## Stops at the first one: a file that is off-palette is off-palette, and scanning
## the remaining nine million pixels to say so again is not worth the wall clock.
static func first_stray_colour(image: Image, palette: Dictionary) -> int:
	image.convert(Image.FORMAT_RGBA8)
	var data: PackedByteArray = image.get_data()
	var count: int = data.size() / 4
	for i: int in count:
		var offset: int = i * 4
		if data[offset + 3] == 0:
			continue
		var key: int = (data[offset] << 16) | (data[offset + 1] << 8) | data[offset + 2]
		if not palette.has(key):
			return key
	return -1
