class_name Cast
extends RefCounted

## Everyone with a sheet, loaded from content/cast.json.
##
## Immutable content shared by the window and the tests, so a test can never pass
## against dialogue the player will not see.

const CAST_PATH: String = "res://content/cast.json"

var npcs: Dictionary = {}
var fact_descriptions: Dictionary = {}

static var _shared: Cast = null


static func shared() -> Cast:
	if _shared == null:
		_shared = load_from(CAST_PATH)
	return _shared


static func load_from(path: String) -> Cast:
	var cast := Cast.new()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return cast
	var root: Dictionary = parsed as Dictionary

	for fact: String in (root.get("facts", {}) as Dictionary).keys():
		cast.fact_descriptions[StringName(fact)] = String((root["facts"] as Dictionary)[fact])

	for key: String in (root.get("npcs", {}) as Dictionary).keys():
		var row: Dictionary = (root["npcs"] as Dictionary)[key] as Dictionary
		var npc := Npc.new()
		npc.id = StringName(key)
		npc.display_name = String(row.get("name", key))
		npc.role = String(row.get("role", ""))
		npc.zone = StringName(row.get("zone", ""))
		var at: Array = row.get("tile", [0, 0]) as Array
		npc.tile = Vector2i(int(at[0]), int(at[1]))
		npc.sprite = String(row.get("sprite", ""))
		npc.greeting = String(row.get("greeting", ""))
		for entry: Variant in (row.get("options", []) as Array):
			var data: Dictionary = entry as Dictionary
			var option := DialogueOption.new()
			option.intent = StringName(data.get("intent", ""))
			option.text = String(data.get("text", ""))
			option.reply = String(data.get("reply", ""))
			option.tag = StringName(data.get("tag", ""))
			option.teaches = StringName(data.get("teaches", ""))
			option.requires = StringName(data.get("requires", ""))
			option.hides_after = StringName(data.get("hides_after", ""))
			npc.options.append(option)
		cast.npcs[npc.id] = npc
	return cast


func get_npc(id: StringName) -> Npc:
	return npcs.get(id, null) as Npc


func in_zone(zone: StringName) -> Array[Npc]:
	var out: Array[Npc] = []
	for id: StringName in npcs.keys():
		var npc: Npc = npcs[id] as Npc
		if npc.zone == zone:
			out.append(npc)
	out.sort_custom(func(a: Npc, b: Npc) -> bool: return String(a.id) < String(b.id))
	return out


## Nearest NPC within reach in the current zone, or null. Used to decide who the
## interact key is aimed at.
func nearest_to(zone: StringName, pos: Vector2, reach: float) -> Npc:
	var best: Npc = null
	var best_distance: float = reach
	for npc: Npc in in_zone(zone):
		var distance: float = pos.distance_to(npc.centre())
		if distance <= best_distance:
			best = npc
			best_distance = distance
	return best
