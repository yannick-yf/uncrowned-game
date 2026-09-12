class_name Voices
extends RefCounted

## How each person talks.
##
## Instructions for whoever writes a line, and never shown to a player, so unlike
## every other content file this one is English only and is not translated. That is
## also why it is kept out of `cast.*.json`: a translated copy of a writing note
## would be two things to keep in step for no benefit.
##
## The notes are deliberately plain. "Answers with figures" is something a person
## and a model can both follow. "Wry and world-weary" is not, and asking for it is
## how twenty-four characters end up sounding like one.

const PATH: String = "res://content/voices.json"

var _notes: Dictionary = {}

static var _shared: Voices = null


static func shared() -> Voices:
	if _shared == null:
		_shared = load_from(PATH)
	return _shared


static func load_from(path: String) -> Voices:
	var voices := Voices.new()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		for who: String in ((parsed as Dictionary).get("voices", {}) as Dictionary).keys():
			voices._notes[StringName(who)] = String(
				((parsed as Dictionary)["voices"] as Dictionary)[who])
	return voices


## A generic's note belongs to their trade, not to the placement: every watchman
## talks the same way because there is one watchman written.
func of(npc: Npc) -> String:
	if npc == null:
		return ""
	var key: StringName = npc.kind if npc.generic else npc.id
	return String(_notes.get(key, ""))


func everybody() -> Array[StringName]:
	var out: Array[StringName] = []
	for who: StringName in _notes.keys():
		out.append(who)
	out.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return out
