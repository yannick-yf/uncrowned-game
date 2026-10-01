class_name ItemRules
extends RefCounted

## **What can be carried and worn** (group E, `docs/CREATION_AND_GEAR.md` §4).
##
## Six slots — head, torso, legs, feet, the weapon in the hand and the bow on the back —
## and two numbers on armour: **protection**, taken off every blow received and never
## below one, and **heavy**, of which two pieces or more cost a tile of movement a turn.
## Weapons keep the fight's own numbers (`content/duel.json`). The table is
## `content/items.json`; how each item looks is the window's (`PaperDoll`).

const FILE: String = "res://content/items.json"
const HEAD: StringName = &"head"
const TORSO: StringName = &"torso"
const LEGS: StringName = &"legs"
const FEET: StringName = &"feet"
const WEAPON: StringName = &"weapon"
const BOW: StringName = &"bow"
const SLOTS: Array[StringName] = [HEAD, TORSO, LEGS, FEET, WEAPON, BOW]
## Two heavy pieces or more, and a fight's move is a tile shorter.
const HEAVY_FROM: int = 2

static var _table: Dictionary = {}


static func _read() -> Dictionary:
	if _table.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		_table = parsed as Dictionary if parsed is Dictionary else {}
	return _table


static func items() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: String in (_read().get("items", {}) as Dictionary).keys():
		out.append(StringName(id))
	return out


static func row(item: StringName) -> Dictionary:
	return (_read().get("items", {}) as Dictionary).get(String(item), {}) as Dictionary


static func exists(item: StringName) -> bool:
	return not row(item).is_empty()


static func slot_of(item: StringName) -> StringName:
	return StringName(String(row(item).get("slot", "")))


static func protection_of(item: StringName) -> int:
	return int(row(item).get("protection", 0))


static func is_heavy(item: StringName) -> bool:
	return bool(row(item).get("heavy", false))


## `DuelRules.SWORD` or `DuelRules.BOW` for a weapon, `&""` for anything else.
static func weapon_of(item: StringName) -> StringName:
	return StringName(String(row(item).get("weapon", "")))


## The fact that, written, means the player has this — Wren's bow since T5.
static func fact_of(item: StringName) -> StringName:
	return StringName(String(row(item).get("from_fact", "")))


static func start_kit() -> Array[StringName]:
	var out: Array[StringName] = []
	for item: Variant in _read().get("start", []) as Array:
		out.append(StringName(String(item)))
	return out


## What a beaten fighter of this kind leaves. A king's guard leaves one piece, by his
## seat — the first the helm, the second the breastplate — so three of them leave the set.
static func loot_of(kind: StringName, seat: int = 1) -> Array[StringName]:
	var out: Array[StringName] = []
	var listed: Array = (_read().get("loot", {}) as Dictionary).get(String(kind), []) as Array
	if listed.is_empty():
		return out
	if kind == &"kings_guard":
		out.append(StringName(String(listed[clampi(seat - 1, 0, listed.size() - 1)])))
		return out
	for item: Variant in listed:
		out.append(StringName(String(item)))
	return out


## **What a set of equipped items adds up to.** Protection: the sum. Heavy: how many.
static func protection(equipped: Dictionary) -> int:
	var total: int = 0
	for slot: StringName in SLOTS:
		total += protection_of(equipped.get(slot, &"") as StringName)
	return total


static func heavy_pieces(equipped: Dictionary) -> int:
	var count: int = 0
	for slot: StringName in SLOTS:
		if is_heavy(equipped.get(slot, &"") as StringName):
			count += 1
	return count


## A blow received, after the armour: never below one.
static func after_armour(amount: int, armour: int) -> int:
	return maxi(amount - armour, 1) if amount > 0 else 0


## The tiles a fight's turn buys, after the weight.
static func tiles_with(equipped: Dictionary, tiles: int) -> int:
	return tiles - (1 if heavy_pieces(equipped) >= HEAVY_FROM else 0)
