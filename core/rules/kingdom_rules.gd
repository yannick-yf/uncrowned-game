class_name KingdomRules
extends RefCounted

## The kingdom's two numbers (`docs/SIMULATION_MODEL.md` §2).
##
## **There is one kingdom and it is the castle plus the capital.** Yannick's correction
## of 2026-09-18 gave it **the same shape as a place**: two numbers, **allégeance** and
## **trésor**, and those two decide how it looks. One rule learnt once and used twice,
## which is the whole design principle of this model.
##
## **The king's force is his trésor** (rule 4). The same number, named for what it is
## used for: troops are fed and armed out of one store. `force()` returns `tresor()`
## literally, and a test holds them equal, because one number with two names is how two
## numbers are born.
##
## **And a place that has turned sends nothing** (rule 2). That is what keeps the
## allégeance of the places able to weaken the king at all, now that force is only the
## trésor: a works that has thrown out the crown's men does not ship its steel to the
## capital. Allégeance weakens him by what it cuts off rather than by being a term in a
## formula.
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
## What a good is for. Adding one is a line in `content/towns.json`, never a rule.
const VIVRES: StringName = &"vivres"
const MATERIEL: StringName = &"materiel"

static var _produces: Dictionary = {}
static var _goods: Dictionary = {}


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


## Good -> what it is for: vivres or matériel. From the file, so a new good is a line.
static func categories() -> Dictionary:
	if not _goods.is_empty():
		return _goods
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary:
		for good: String in ((parsed as Dictionary).get("goods", {}) as Dictionary).keys():
			_goods[StringName(good)] = StringName(String(((parsed as Dictionary)["goods"] as Dictionary)[good]))
	return _goods


static func category_of(good: StringName) -> StringName:
	return categories().get(good, &"") as StringName


## Whether a place is still shipping to the crown. **Rule 2**: only while it is with
## him. A place that has turned keeps what it makes, and that is the whole of how
## allégeance reaches the king's strength.
static func still_sending(towns: TownState, place: StringName) -> bool:
	return towns.has_state(place) and TownRules.is_high(towns.allegiance_of(place))


## What a place actually sends this year: its richesse. A place doing well sends more,
## and one that has stopped sends nothing — which is the whole of *stop the ironworks
## and the crown feels it*, in one line.
static func sent_by(towns: TownState, place: StringName) -> int:
	if not towns.has_state(place) or sends(place) == &"":
		return 0
	return towns.richesse_of(place) if still_sending(towns, place) else 0


## The average of what the places producing `good` send, 0–10. A place that has turned
## counts as the nothing it sends, rather than being left out of the average — otherwise
## losing a place would not cost the crown anything.
static func supply_of(towns: TownState, good: StringName) -> float:
	var total: int = 0
	var places: int = 0
	for place: StringName in towns.ids():
		if sends(place) != good:
			continue
		places += 1
		total += sent_by(towns, place)
	return 0.0 if places == 0 else float(total) / float(places)


## Everything of one kind that reached the crown: the vivres it can hand back out, or
## the matériel it keeps.
static func kind_supply(towns: TownState, kind: StringName) -> float:
	var total: int = 0
	var places: int = 0
	for place: StringName in towns.ids():
		if category_of(sends(place)) != kind:
			continue
		places += 1
		total += sent_by(towns, place)
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


## **The king's force is his trésor** — rule 4, and this is it literally, so the two can
## never drift apart. Troops are fed and armed out of one store.
##
## A kingdom whose places have turned is still weaker without a furnace having gone out,
## because a place that has turned stops shipping (rule 2). That is the reason the
## player can bring a king down without burning anything.
static func force(towns: TownState) -> float:
	return tresor(towns)


## **Trésor**: everything that actually reached the crown, on the same scale as the rest.
##
## The sum, normalised — which for goods that all run 0–10 is their average. It is
## written as an average rather than a sum divided by a constant so that adding a sixth
## place does not silently make the kingdom poorer. A place that has turned is counted
## at the nothing it sends.
static func tresor(towns: TownState) -> float:
	var total: int = 0
	var senders: int = 0
	for place: StringName in towns.ids():
		if sends(place) == &"":
			continue
		senders += 1
		total += sent_by(towns, place)
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
		"force": force(towns), "look": String(look(towns)),
		"vivres": kind_supply(towns, VIVRES), "materiel": kind_supply(towns, MATERIEL)}
