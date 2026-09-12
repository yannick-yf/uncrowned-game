class_name Cast
extends RefCounted

## Everyone with a sheet, loaded from content/cast.json.
##
## Immutable content shared by the window and the tests, so a test can never pass
## against dialogue the player will not see.

## Sheets are content and content is written in the player's language, so there is
## one file per language with identical ids and structure. A test asserts they match
## exactly — a line missing from a translation is a build failure, not a surprise
## somebody finds in play.
const CAST_PATH: String = "res://content/cast.%s.json"


static func path_for(locale: String) -> String:
	var path: String = CAST_PATH % locale
	return path if FileAccess.file_exists(path) else CAST_PATH % Text.FALLBACK

var npcs: Dictionary = {}
var fact_descriptions: Dictionary = {}
## Band -> the narrated line anybody opens with at that standing, when nobody has
## written them one of their own.
var dispositions: Dictionary = {}

static var _shared: Cast = null


static func shared() -> Cast:
	if _shared == null:
		_shared = load_from(path_for(Text.locale()))
	return _shared


## Thrown away when the language changes, because every line in it is in the old one.
static func forget() -> void:
	_shared = null


static func load_from(path: String) -> Cast:
	var cast := Cast.new()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return cast
	var root: Dictionary = parsed as Dictionary

	for band: String in (root.get("dispositions", {}) as Dictionary).keys():
		cast.dispositions[StringName(band)] = String(
			(root["dispositions"] as Dictionary)[band])

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
		for entry: Variant in (row.get("alt_greetings", []) as Array):
			var alt: Dictionary = entry as Dictionary
			npc.alt_greetings.append({
				"when": StringName(alt.get("when", "")),
				"text": String(alt.get("text", "")),
			})
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
			option.requires_condition = StringName(data.get("requires_condition", ""))
			option.forbids_condition = StringName(data.get("forbids_condition", ""))
			option.costs = StringName(data.get("costs", ""))
			option.repeatable = bool(data.get("repeatable", false))
			option.causes = StringName(data.get("causes", ""))
			npc.options.append(option)
		cast.npcs[npc.id] = npc

	cast._load_strangers(root.get("strangers", {}) as Dictionary)
	return cast


## Generic types, placed. Everyone of a trade shares one line set, so a second
## trader anywhere costs a placement and not a sheet — which is what keeps §6's
## twenty-five from quietly becoming thirty.
func _load_strangers(section: Dictionary) -> void:
	var types: Dictionary = section.get("types", {}) as Dictionary
	var placed: Dictionary = {}
	for entry: Variant in (section.get("placements", []) as Array):
		var spot: Dictionary = entry as Dictionary
		var kind: StringName = StringName(spot.get("kind", ""))
		if not types.has(String(kind)):
			continue
		var row: Dictionary = types[String(kind)] as Dictionary
		placed[kind] = int(placed.get(kind, 0)) + 1
		var npc := Npc.new()
		npc.id = StringName("%s@%d" % [kind, placed[kind]])
		npc.kind = kind
		npc.generic = true
		npc.display_name = String(row.get("name", "A stranger"))
		npc.role = String(row.get("role", ""))
		npc.zone = StringName(spot.get("zone", ""))
		var at: Array = spot.get("tile", [0, 0]) as Array
		npc.tile = Vector2i(int(at[0]), int(at[1]))
		npc.sprite = String(row.get("sprite", ""))
		npc.greeting = String(row.get("greeting", ""))
		for alt_entry: Variant in (row.get("alt_greetings", []) as Array):
			var alt: Dictionary = alt_entry as Dictionary
			npc.alt_greetings.append({
				"when": StringName(alt.get("when", "")),
				"text": String(alt.get("text", "")),
			})
		for option_entry: Variant in (row.get("options", []) as Array):
			var data: Dictionary = option_entry as Dictionary
			var option := DialogueOption.new()
			option.intent = StringName(data.get("intent", ""))
			option.text = String(data.get("text", ""))
			option.reply = String(data.get("reply", ""))
			option.tag = StringName(data.get("tag", ""))
			option.teaches = StringName(data.get("teaches", ""))
			option.requires = StringName(data.get("requires", ""))
			option.hides_after = StringName(data.get("hides_after", ""))
			option.requires_condition = StringName(data.get("requires_condition", ""))
			option.forbids_condition = StringName(data.get("forbids_condition", ""))
			option.costs = StringName(data.get("costs", ""))
			option.repeatable = bool(data.get("repeatable", false))
			option.causes = StringName(data.get("causes", ""))
			npc.options.append(option)
		npcs[npc.id] = npc


## The twenty-five. Strangers are scenery with lines, and §6's budget does not
## count them.
func named() -> Array[Npc]:
	var out: Array[Npc] = []
	for id: StringName in npcs.keys():
		var npc: Npc = npcs[id] as Npc
		if not npc.generic:
			out.append(npc)
	return out


## How somebody at this standing opens, or "" if that band has no shared line.
func disposition_line(band: StringName, speaker: String) -> String:
	var pattern: String = String(dispositions.get(band, ""))
	return pattern % speaker if pattern != "" else ""


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
