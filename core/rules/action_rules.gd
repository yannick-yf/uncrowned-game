class_name ActionRules
extends RefCounted

## **What the player can do on his turn, and to whom** (group N, 2026-10-03).
##
## Yannick, after Baldur's Gate 3: the actions gathered by category in a wheel rather than a
## key that changes the weapon, then a target chosen, its chance to hit and its damage shown
## before the blow. This is the one answer the wheel, the targeting and the fight read:
## `offered` says what is on the wheel and why an action is greyed, `targets` says, from the
## tile the player will stand on, whom an action reaches and with what chance and damage —
## the very numbers the blow then uses (`DuelRules`).
##
## Pure, and generic: an action is a row of `content/actions.json`. A new weapon, spell or
## item is a row there.

const FILE: String = "res://content/actions.json"
const STRIKE: StringName = &"strike"
const CAST: StringName = &"cast"
const WAIT: StringName = &"wait"
## What a row's `weapon` names: the sword in his hand or his fists, or the bow on his back.
const HELD: StringName = &"held"

static var _data: Dictionary = {}


static func _read() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		_data = parsed as Dictionary if parsed is Dictionary else {}
	return _data


## The wheel's categories, clockwise from the top.
static func categories() -> Array[StringName]:
	var out: Array[StringName] = []
	for row: Variant in _read().get("categories", []) as Array:
		out.append(StringName(String((row as Dictionary).get("id", ""))))
	return out


static func icon_of(category: StringName) -> StringName:
	for row: Variant in _read().get("categories", []) as Array:
		if StringName(String((row as Dictionary).get("id", ""))) == category:
			return StringName(String((row as Dictionary).get("icon", "")))
	return &""


static func rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row: Variant in _read().get("actions", []) as Array:
		out.append(row as Dictionary)
	return out


## **What is on the wheel now**: every action of the table, each with what it strikes with,
## whether it can be done this turn and, if not, why — a text key: no bow, no spell, the
## gift resting. In the table's order.
static func offered(inventory: Inventory, facts: FactBase, me: DuelFighter, round_now: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row: Dictionary in rows():
		var kind := StringName(String(row.get("kind", "wait")))
		var entry: Dictionary = {"id": StringName(String(row.get("id", ""))),
			"category": StringName(String(row.get("category", ""))), "kind": kind,
			"weapon": &"", "available": true, "why": &""}
		var weapon := StringName(String(row.get("weapon", "")))
		if weapon == HELD:
			entry["weapon"] = inventory.weapon_in_hand() if inventory != null else DuelRules.SWORD
		elif weapon != &"":
			entry["weapon"] = weapon
		var needs: String = String(row.get("needs", ""))
		if needs == "bow" and not (inventory != null and inventory.has_bow()):
			entry["available"] = false
			entry["why"] = &"action.why.no_bow"
		elif needs.begins_with("fact:") and (facts == null or not facts.has(StringName(needs.substr(5)))):
			entry["available"] = false
			entry["why"] = &"action.why.no_spell"
		elif kind == CAST and me != null and round_now < me.ready_round:
			entry["available"] = false
			entry["why"] = &"action.why.resting"
		out.append(entry)
	return out


## The first action of a category, or an empty one: what the wheel's segment does.
static func of_category(offered_now: Array[Dictionary], category: StringName) -> Dictionary:
	for entry: Dictionary in offered_now:
		if entry["category"] == category:
			return entry
	return {}


## **Whom an action reaches from `from`, and how**: every foe still up, each with whether it
## is in reach, the chance the blow lands and what it costs him — in reach first, then the
## nearest, then by name, so a target cycled to is always found in the same order.
static func targets(entry: Dictionary, from: Vector2i, foes: Array[DuelFighter], traits: Traits,
		drill: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var kind: StringName = entry.get("kind", WAIT) as StringName
	if kind == WAIT:
		return out
	var weapon: StringName = entry.get("weapon", DuelRules.SWORD) as StringName
	for foe: DuelFighter in foes:
		if not foe.alive():
			continue
		var row: Dictionary = {"who": foe.who, "at": foe.at, "apart": DuelRules.apart(from, foe.at)}
		if kind == CAST:
			row["in_reach"] = DuelRules.apart(from, foe.at) <= DuelRules.spell_reach_tiles()
			row["chance"] = 100
			row["damage"] = DuelRules.spell_damage()
		else:
			row["in_reach"] = DuelRules.reaches(weapon, from, foe.at)
			row["chance"] = DuelRules.hit_chance(DuelRules.PLAYER, foe.who, traits, drill)
			row["damage"] = DuelRules.damage_with(weapon)
		out.append(row)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a["in_reach"]) != bool(b["in_reach"]):
			return bool(a["in_reach"])
		if int(a["apart"]) != int(b["apart"]):
			return int(a["apart"]) < int(b["apart"])
		return String(a["who"]) < String(b["who"]))
	return out


## What a turn with this action asks of the fight: its `action` and `weapon`.
static func turn_of(entry: Dictionary) -> Dictionary:
	var kind: StringName = entry.get("kind", WAIT) as StringName
	if kind == CAST:
		return {"action": String(DuelRules.CAST), "weapon": ""}
	if kind == STRIKE:
		return {"action": String(DuelRules.STRIKE), "weapon": String(entry.get("weapon", ""))}
	return {"action": String(DuelRules.WAIT), "weapon": ""}
