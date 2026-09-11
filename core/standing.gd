class_name Standing
extends RefCounted

## What the world thinks of the player, indexed rather than global.
##
## §8's opening line: "Reputation, per town and per faction (not one global
## number)." This is that structure — deliberately *beside* the twelve tracked
## quantities rather than among them, because the twelve describe how the world is
## doing and this describes where the player stands in it. They are different kinds
## of thing and adding a thirteenth quantity would have been the wrong repair.

const NEUTRAL: float = 0.0
const WORST: float = -100.0
const BEST: float = 100.0

var by_town: Dictionary = {}
var by_faction: Dictionary = {}
## And per person. A town's opinion is the aggregate of the people in it, so these
## track each other — until somebody *watches* you do something, and then theirs
## diverges from their neighbours' and stays diverged.
var by_person: Dictionary = {}


func _init() -> void:
	for town: StringName in Region.ZONE_ORDER:
		by_town[town] = NEUTRAL


func in_town(town: StringName) -> float:
	return float(by_town.get(town, NEUTRAL))


func with_faction(faction: StringName) -> float:
	return float(by_faction.get(faction, NEUTRAL))


func with_person(who: StringName) -> float:
	return float(by_person.get(who, NEUTRAL))


## Every door that shuts opens another (§8). A change is never only a loss: it
## names who is offended *and* who is impressed, and refusing to move one without
## the other is what keeps this from becoming a morality meter.
func shift_town(town: StringName, amount: float) -> void:
	by_town[town] = clampf(in_town(town) + amount, WORST, BEST)


func shift_faction(faction: StringName, amount: float) -> void:
	by_faction[faction] = clampf(with_faction(faction) + amount, WORST, BEST)


func shift_person(who: StringName, amount: float) -> void:
	by_person[who] = clampf(with_person(who) + amount, WORST, BEST)


## A whole deed's worth at once, from DeedRules' table. Applied at the act and
## never on arrival: a faction is not a place and cannot hear the same story once
## per town.
func shift_factions(effects: Dictionary) -> void:
	for faction: StringName in effects.keys():
		shift_faction(faction, float(effects[faction]))


func fingerprint() -> String:
	var towns := PackedStringArray()
	for town: StringName in Region.ZONE_ORDER:
		towns.append("%s:%.2f" % [town, in_town(town)])
	var factions: Array = by_faction.keys()
	factions.sort()
	var sides := PackedStringArray()
	for faction: StringName in factions:
		sides.append("%s:%.2f" % [faction, with_faction(faction)])
	var people: Array = by_person.keys()
	people.sort()
	var faces := PackedStringArray()
	for who: StringName in people:
		faces.append("%s:%.2f" % [who, with_person(who)])
	return "towns[%s] factions[%s] people[%s]" % [
		";".join(towns), ";".join(sides), ";".join(faces)]
