class_name KingdomRules
extends RefCounted

## The kingdom's two numbers (`docs/SIMULATION_MODEL.md` §2).
##
## **There is one kingdom and it is the castle plus the capital.** It carries a
## **force** and a **trésor**, both 0–10 like everything else, and it is what turns
## *the ironworks has stopped* into *the crown is short of steel* — the hop that makes
## the star do any work at all.
##
## **Derived, never stored.** Both are functions of where the places stand, recomputed
## whenever anybody asks. There is no kingdom store, no kingdom event and nothing to
## replay: a number that cannot be written cannot drift out of step with the towns that
## make it, and the old model's twelve quantities drifted exactly like that.
##
## Pure, like every rule here.

## What a place sends, read from `content/towns.json` — content, because which place
## grows food and which makes steel is design rather than arithmetic.
const PATH: String = "res://content/towns.json"
const STEEL: StringName = &"steel"
const FOOD: StringName = &"food"

static var _produces: Dictionary = {}


## Place -> the good it sends, for the places that send one. A place absent from this
## consumes and produces nothing, which is an answer rather than an omission.
static func produces() -> Dictionary:
	if not _produces.is_empty():
		return _produces
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not (parsed is Dictionary):
		return _produces
	for id: String in ((parsed as Dictionary).get("towns", {}) as Dictionary).keys():
		var row: Dictionary = ((parsed as Dictionary)["towns"] as Dictionary)[id] as Dictionary
		var good: String = String(row.get("produces", ""))
		if good != "":
			_produces[StringName(id)] = StringName(good)
	return _produces


static func sends(place: StringName) -> StringName:
	return produces().get(place, &"") as StringName


## What a place actually sends this year: its richesse. A place doing well sends more,
## and one that has stopped sends nothing — which is the whole of *stop the ironworks
## and the crown feels it*, in one line.
static func sent_by(towns: TownState, place: StringName) -> int:
	if not towns.has_state(place) or sends(place) == &"":
		return 0
	return towns.richesse_of(place)


## The average of what the places producing `good` send, 0–10.
static func supply_of(towns: TownState, good: StringName) -> float:
	var total: int = 0
	var places: int = 0
	for place: StringName in towns.ids():
		if sends(place) != good:
			continue
		places += 1
		total += towns.richesse_of(place)
	return 0.0 if places == 0 else float(total) / float(places)


## How far the kingdom's places are with the king, 0–10.
static func loyalty(towns: TownState) -> float:
	var total: int = 0
	var places: int = 0
	for place: StringName in towns.ids():
		places += 1
		total += towns.allegiance_of(place)
	return 0.0 if places == 0 else float(total) / float(places)


## **Force**: the average of the steel it receives and how far its places are with it.
##
## An army needs weapons **and** men. A place that has turned does not send its sons,
## so a kingdom can be disarmed by talking as surely as by putting out its furnaces —
## which is the argument the whole game is about, in one number.
static func force(towns: TownState) -> float:
	return clampf((supply_of(towns, STEEL) + loyalty(towns)) * 0.5,
		float(TownRules.FLOOR), float(TownRules.CEILING))


## **Trésor**: everything the places send, on the same scale as everything else.
##
## The sum, normalised — which for goods that all run 0–10 is their average. It is
## written as an average rather than a sum divided by a constant so that adding a
## sixth place does not silently make the kingdom poorer.
static func tresor(towns: TownState) -> float:
	var total: int = 0
	var senders: int = 0
	for place: StringName in towns.ids():
		if sends(place) == &"":
			continue
		senders += 1
		total += towns.richesse_of(place)
	if senders == 0:
		return 0.0
	return clampf(float(total) / float(senders),
		float(TownRules.FLOOR), float(TownRules.CEILING))


## The two numbers as a reading, for a journal or a window that wants both at once.
static func reading(towns: TownState) -> Dictionary:
	return {"force": force(towns), "tresor": tresor(towns)}
