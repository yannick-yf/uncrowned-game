extends SceneTree

## Bring the Brindle 3D workshop's scenes into this project (MIGRATION_3D §6, M2b).
##
##   godot --headless --path . -s tools/vendor_workshop.gd
##   tools/vendor_workshop.sh          the same, then the import the new files need
##
## His project lives in `prototypes/brindle_3d/` with its own `res://` root, hidden from
## our importer by `prototypes/.gdignore`, and nothing of his moves (Yannick,
## 2026-09-13, decision 6). This copies the folders his scenes need into
## `view3d/workshop/` and rewrites every `res://<folder>/` in his text files to point
## there, so `res://view3d/workshop/scenes/map_plate.tscn` loads in our project with his
## materials, shaders, meshes and masks. Binary resources are copied as they are — his
## 86 `.res` meshes carry no paths, which was checked before this was written.
##
## Generated, never committed (`.gitignore`): run it after cloning and after each
## delivery of his, as CI does before the suite. The copy is a pure function of his
## tree, so two runs agree, and the day the two projects become one this is the
## layout a `git mv` would produce.

const SOURCE: String = "res://prototypes/brindle_3d/"
const TARGET: String = "res://view3d/workshop/"
## His top-level folders that his scenes reach into. `tools/`, `planning/`'s cousins
## `apercus/` and `reference/`, and his `project.godot` stay his.
const FOLDERS: Array[String] = [
	"assets", "materials", "planning", "prototype_3d", "scenes", "scripts", "shaders",
]
const SKIP_DIRS: Array[String] = [".godot", "__pycache__", "verification-output"]
const TEXT_EXTENSIONS: Array[String] = ["tscn", "tres", "gd", "gdshader", "import", "json", "txt", "cfg"]

var _copied: int = 0
var _rewritten: int = 0
var _bytes: int = 0


func _initialize() -> void:
	if not DirAccess.dir_exists_absolute(SOURCE):
		push_error("no workshop at %s" % SOURCE)
		quit(1)
		return
	_remove_tree(TARGET)
	DirAccess.make_dir_recursive_absolute(TARGET)
	for folder: String in FOLDERS:
		if DirAccess.dir_exists_absolute(SOURCE + folder):
			_copy_tree(SOURCE + folder, TARGET + folder)
	_write_note()
	print("vendor_workshop — %d files (%.1f MB) into %s, %d rewritten to point there" % [
		_copied, float(_bytes) / 1048576.0, TARGET, _rewritten])
	print("now: godot --headless --path . --import   (the copied textures and scenes need importing)")
	quit(0)


func _copy_tree(from: String, to: String) -> void:
	DirAccess.make_dir_recursive_absolute(to)
	var listing: DirAccess = DirAccess.open(from)
	if listing == null:
		push_error("cannot read %s" % from)
		return
	listing.list_dir_begin()
	var name: String = listing.get_next()
	while name != "":
		if listing.current_is_dir():
			if not SKIP_DIRS.has(name):
				_copy_tree(from.path_join(name), to.path_join(name))
		elif not name.ends_with(".log"):
			_copy_file(from.path_join(name), to.path_join(name))
		name = listing.get_next()
	listing.list_dir_end()


func _copy_file(from: String, to: String) -> void:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(from)
	if TEXT_EXTENSIONS.has(from.get_extension()):
		var text: String = bytes.get_string_from_utf8()
		var rewritten: String = _repoint(text)
		if rewritten != text:
			_rewritten += 1
		bytes = rewritten.to_utf8_buffer()
	var out: FileAccess = FileAccess.open(to, FileAccess.WRITE)
	if out == null:
		push_error("cannot write %s" % to)
		return
	out.store_buffer(bytes)
	out.close()
	_copied += 1
	_bytes += bytes.size()


## `res://assets/...` → `res://view3d/workshop/assets/...`, for his folders only. His
## `.import` files also name `res://.godot/imported/...`, which is our importer's
## business and is left alone.
func _repoint(text: String) -> String:
	var out: String = text
	for folder: String in FOLDERS:
		out = out.replace("res://%s/" % folder, "%s%s/" % [TARGET, folder])
	return out


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var listing: DirAccess = DirAccess.open(path)
	if listing == null:
		return
	listing.list_dir_begin()
	var name: String = listing.get_next()
	while name != "":
		var child: String = path.path_join(name)
		if listing.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		name = listing.get_next()
	listing.list_dir_end()
	DirAccess.remove_absolute(path)


## A note beside the copy, so anyone who opens the folder knows not to edit it.
func _write_note() -> void:
	var note: FileAccess = FileAccess.open(TARGET + "GENERATED.md", FileAccess.WRITE)
	if note == null:
		return
	note.store_string("# Generated — do not edit\n\nA copy of `prototypes/brindle_3d/` with its `res://` paths repointed here, made by\n`tools/vendor_workshop.gd`. Edit his project, then run the tool again. Not committed.\n")
	note.close()
