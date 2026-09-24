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

## **Sectors of his world the copied map plate does not carry** (2026-09-24).
##
## Not art direction and not a judgement on his work: it is the only answer we have to a
## defect in *this* tool. His merged meshes are **compressed binary resources** (their
## header is `RSCC`), and inside them the dependencies are written as `res://assets/...`
## — his project's root. This tool repoints paths in text files and cannot reach inside a
## compressed binary, so those references stay pointing at a folder that does not exist
## here. The game then prints **four hundred and sixty errors** at launch and Godot's
## editor refuses to play it, while the meshes themselves sit copied and unreachable a
## few folders away.
##
## Everything listed here is a sector the demo never walks to, so dropping it costs the
## player nothing today. **It is a patch and not a repair**, and Yannick said so first:
## the same defect returns with his next delivery, and the real answers are written in
## `docs/MIGRATION_3D.md` — none of them is free and all of them are his to choose.
const SECTORS_WE_DO_NOT_VISIT: Array[String] = [
	"VillageFermier", "FarmingAtmosphere", "CoastlineDecor",
]
const MAP_PLATE: String = "scenes/map_plate.tscn"
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
		if from.ends_with(MAP_PLATE):
			rewritten = _drop_sectors(rewritten)
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


## Take the sectors above out of the plate, and then any `ext_resource` nothing else
## names. Line by line rather than by regular expression, because a `.tscn` is a flat
## list of blocks and a block runs until the next `[`.
func _drop_sectors(text: String) -> String:
	var lines: PackedStringArray = text.split("\n")
	var kept: PackedStringArray = PackedStringArray()
	var dropping: bool = false
	for line: String in lines:
		if line.begins_with("["):
			dropping = false
			if line.begins_with("[node name=\""):
				var name: String = line.get_slice("\"", 1)
				dropping = SECTORS_WE_DO_NOT_VISIT.has(name)
			elif line.begins_with("[editable path=\""):
				# A marker for a node that is no longer here; Godot complains about it.
				var at: String = line.get_slice("\"", 1)
				dropping = SECTORS_WE_DO_NOT_VISIT.has(at.get_slice("/", at.get_slice_count("/") - 1))
		if not dropping:
			kept.append(line)
	# An `ext_resource` whose id is now named nowhere is dead weight, and Godot warns
	# about it. Checked against the text as it stands *after* the nodes have gone.
	var body: String = "\n".join(kept)
	var out: PackedStringArray = PackedStringArray()
	for line: String in kept:
		if line.begins_with("[ext_resource "):
			var id: String = line.get_slice("id=\"", 1).get_slice("\"", 0)
			if id != "" and body.count("\"%s\"" % id) <= 1:
				continue
		out.append(line)
	return "\n".join(out)


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
