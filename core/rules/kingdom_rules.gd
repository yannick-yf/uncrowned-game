class_name KingdomRules
extends RefCounted

## The kingdom's two numbers (`docs/SIMULATION_MODEL.md` §2).
##
## **There is one kingdom and it is the castle plus the capital.** Yannick's correction
## of 2026-09-18 gave it **the same shape as a place**: two numbers, **allégeance** and
## **trésor**, and those two decide how it looks. One rule learnt once and used twice,
## which is the whole design principle of this model.
##
## Its **force** is a *reading* of the two, not a third number. If force can be worked
## out from allégeance and trésor it carries no information of its own, and the count
## stays at twelve numbers in the whole game rather than thirteen. It is what the
## confrontation will read: how hard the king is to put down.
##
## This is what turns *the ironworks has stopped* into *the crown is short of steel* —
## the hop that makes the star do any work at all.
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


## **The kingdom's allégeance**: the average of what its places send it of theirs.
##
## Yannick, 2026-09-18: *toutes les villes envoient une valeur d'allégeance*. A place
## that has turned sends a low one, and the crown is that much less the crown.
static func allegiance(towns: TownState) -> float:
	var total: int = 0
	var places: int = 0
	for place: StringName in towns.ids():
		places += 1
		total += towns.allegiance_of(place)
	return 0.0 if places == 0 else float(total) / float(places)


## **Force**, the reading: what the kingdom holds and who is with it, together.
##
## An army needs weapons **and** men. A kingdom whose places have turned is weaker
## without a furnace having gone out — which is the argument the whole game is about,
## and the reason the player can beat a king without burning anything.
static func force(towns: TownState) -> float:
	return clampf((tresor(towns) + allegiance(towns)) * 0.5,
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


## How the capital looks: the same four appearances as any place, off the same two
## thresholds. A capital reads loyal or hostile, rich or poor, and a player who has
## learnt to read one town has learnt to read the kingdom.
static func look(towns: TownState) -> StringName:
	return TownRules.look_of(roundi(allegiance(towns)), roundi(tresor(towns)))


## Everything about the kingdom at once, for a journal or a window.
static func reading(towns: TownState) -> Dictionary:
	return {"allegiance": allegiance(towns), "tresor": tresor(towns),
		"force": force(towns), "look": String(look(towns))}
