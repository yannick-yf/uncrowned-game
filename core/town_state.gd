class_name TownState
extends RefCounted

## Where every place stands, in its two numbers.
##
## A store like any other: rebuilt from nothing on replay, holding only what the log
## put there. Its starting values come from `content/towns.json` — data, so the one
## thing a designer changes is a file — and everything after that arrives as an event
## through `Sim`. Nothing outside `TownSystem` writes to it.
##
## **Five places carry values**: the Cinderworks, the Wide Acres, Harrowgate, the
## Muster and Saltmarch. **Brindle does not** — a ruined village is outside the system
## (Yannick, 2026-09-18), which closes the door on ever showing it rebuilt, knowingly.
## **Cairnwell and Blackcairn do not either**: together they are the kingdom, and the
## kingdom carries its own two numbers, which are not these.

const PATH: String = "res://content/towns.json"

## Parsed once. The file is read on the first `TownState` built in a process and
## copied after that: a test suite builds hundreds of simulations and none of them
## should touch the disk to learn the same five rows.
static var _starts: Dictionary = {}

## Place id -> {allegiance: int, richesse: int}. A place absent from this is a place
## outside the system, and asking about one is not an error — it has no standing to
## report, which is different from having a low one.
var towns: Dictionary = {}


func _init() -> void:
	for id: StringName in starts().keys():
		towns[id] = (starts()[id] as Dictionary).duplicate()


## The starting rows, read from the file the first time and shared after.
static func starts() -> Dictionary:
	if not _starts.is_empty():
		return _starts
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not (parsed is Dictionary):
		return _starts
	for id: String in ((parsed as Dictionary).get("towns", {}) as Dictionary).keys():
		var row: Dictionary = ((parsed as Dictionary)["towns"] as Dictionary)[id] as Dictionary
		_starts[StringName(id)] = {
			TownRules.ALLEGIANCE: TownRules.clamped(int(row.get("allegiance", 0))),
			TownRules.RICHESSE: TownRules.clamped(int(row.get("richesse", 0))),
		}
	return _starts


func has_state(place: StringName) -> bool:
	return towns.has(place)


func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in towns.keys():
		out.append(id)
	return out


## A place's number, or -1 where the place is outside the system. **Not 0**: zero is a
## real reading — a works that has died — and a caller that cannot tell the two apart
## would report Brindle as the poorest place in the kingdom.
func value_of(place: StringName, which: StringName) -> int:
	if not has_state(place) or not TownRules.is_value(which):
		return -1
	return int((towns[place] as Dictionary).get(which, 0))


func allegiance_of(place: StringName) -> int:
	return value_of(place, TownRules.ALLEGIANCE)


func richesse_of(place: StringName) -> int:
	return value_of(place, TownRules.RICHESSE)


## How this place reads, or "" where it is outside the system.
func look_of(place: StringName) -> StringName:
	if not has_state(place):
		return &""
	return TownRules.look_of(allegiance_of(place), richesse_of(place))


## Write a number, clamped. Returns whether anything moved, so a system knows whether
## there is anything to announce. Called by `TownSystem` and by nothing else.
func set_value(place: StringName, which: StringName, value: int) -> bool:
	if not has_state(place) or not TownRules.is_value(which):
		return false
	var row: Dictionary = towns[place] as Dictionary
	var wanted: int = TownRules.clamped(value)
	if int(row.get(which, 0)) == wanted:
		return false
	row[which] = wanted
	return true


## Move a number by one act of the player's, in the direction given (+1 or -1).
func move(place: StringName, which: StringName, direction: int) -> bool:
	if not has_state(place) or not TownRules.is_value(which):
		return false
	return set_value(place, which, TownRules.moved(value_of(place, which), direction))


## Every number, in one string, for a replay test to compare two runs without naming
## each place — the same trick `Traits.fingerprint` uses, and for the same reason.
func fingerprint() -> String:
	var ids: Array[StringName] = ids()
	ids.sort()
	var parts: PackedStringArray = PackedStringArray()
	for id: StringName in ids:
		parts.append("%s=%d/%d" % [String(id), allegiance_of(id), richesse_of(id)])
	return ",".join(parts)
