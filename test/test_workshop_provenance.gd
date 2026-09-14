extends TestCase

## The asset rule, for the 3D world (MIGRATION_3D §8; CLAUDE.md's art rule as amended):
## one asset family, with a provenance-and-licence manifest the game refuses to ship
## without. His library lives in `prototype_3d/assets/library/` and his manifest is
## `planning/assets-brindle-utilises.json`; every file of the library has to be in it,
## by name, or this says which is not. His own work — the ruins he built, the masks he
## painted, the traveller he drew — is his provenance and is counted, not judged.

const WORKSHOP: String = RegionBake.WORKSHOP
const LIBRARY: String = WORKSHOP + "prototype_3d/assets/library/"
const MANIFEST: String = WORKSHOP + "planning/assets-brindle-utilises.json"
const NOT_ASSETS: Array[String] = ["import", "uid"]


func _files_under(path: String, out: Array[String]) -> void:
	var listing: DirAccess = DirAccess.open(path)
	if listing == null:
		return
	listing.list_dir_begin()
	var name: String = listing.get_next()
	while name != "":
		var child: String = path.path_join(name)
		if listing.current_is_dir():
			_files_under(child, out)
		elif not NOT_ASSETS.has(name.get_extension()):
			out.append(child)
		name = listing.get_next()
	listing.list_dir_end()


func test_every_file_of_his_library_is_in_his_manifest() -> void:
	assert_true(FileAccess.file_exists(MANIFEST), "his manifest is at %s" % MANIFEST)
	if not FileAccess.file_exists(MANIFEST):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	assert_true(parsed is Dictionary, "and it parses")
	if not (parsed is Dictionary):
		return
	var manifest: Dictionary = parsed as Dictionary
	assert_true(String(manifest.get("source", "")).length() > 10,
		"it names where the library came from: '%s'" % String(manifest.get("source", "")))
	var listed: Dictionary = {}
	for entry: Variant in (manifest.get("files", []) as Array):
		# His manifest speaks in his project's `res://`; the file lives under ours.
		listed[String(entry).replace("res://", WORKSHOP)] = true
	var files: Array[String] = []
	_files_under(LIBRARY, files)
	assert_true(files.size() > 50, "his library has %d files" % files.size())
	var orphans: Array[String] = []
	for file: String in files:
		if not listed.has(file):
			orphans.append(file.replace(WORKSHOP, ""))
	assert_eq(orphans.size(), 0, "library files with no provenance: %s" % ", ".join(orphans))
