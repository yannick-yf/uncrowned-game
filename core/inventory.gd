class_name Inventory
extends RefCounted

## What the player carries and what he wears (group E). A store like any other, rebuilt by
## replay: what he owns, in the order he came by it, and what is in each of the six slots.
## Items are unique — a second of the same is nothing more.
##
## **`made` is false for a run that never went through creation** — the suite's bare runs,
## a photograph's — and such a player is as he was before group E: a sword in his hand and
## no armour. A real run is made by `character_made`, with the start kit and no sword.

var owned: Array[StringName] = []
var equipped: Dictionary = {}
var made: bool = false
## Taken in a fight and not yet put on: worn when it is over, where the slot is still free.
## A fight is turns, and a helmet that goes on mid-blow would make loot a move.
var waiting: Array[StringName] = []


func has(item: StringName) -> bool:
	return owned.has(item)


func in_slot(slot: StringName) -> StringName:
	return equipped.get(slot, &"") as StringName


## Taken into the bag; worn at once when its slot is free, unless `wear` says not yet.
## False when already owned.
func gain(item: StringName, wear: bool = true) -> bool:
	if not ItemRules.exists(item) or owned.has(item):
		return false
	owned.append(item)
	if not wear:
		waiting.append(item)
	elif in_slot(ItemRules.slot_of(item)) == &"":
		equipped[ItemRules.slot_of(item)] = item
	return true


## What waited for the fight to end goes on where its slot is free, in the order it came.
## The items put on.
func wear_what_waited() -> Array[StringName]:
	var worn: Array[StringName] = []
	for item: StringName in waiting:
		if in_slot(ItemRules.slot_of(item)) == &"":
			equipped[ItemRules.slot_of(item)] = item
			worn.append(item)
	waiting.clear()
	return worn


func equip(item: StringName) -> bool:
	if not owned.has(item):
		return false
	equipped[ItemRules.slot_of(item)] = item
	return true


func unequip(slot: StringName) -> bool:
	if in_slot(slot) == &"":
		return false
	equipped.erase(slot)
	return true


## What his blows are struck with: his sword, his fists — or, a run never made, the sword
## he always had.
func weapon_in_hand() -> StringName:
	if not made:
		return DuelRules.SWORD
	var held: StringName = ItemRules.weapon_of(in_slot(ItemRules.WEAPON))
	return held if held != &"" else DuelRules.FISTS


## Whether anything he owns goes in the weapon slot, worn or in the bag.
func owns_a_weapon() -> bool:
	for item: StringName in owned:
		if ItemRules.slot_of(item) == ItemRules.WEAPON:
			return true
	return false


func has_bow() -> bool:
	return ItemRules.weapon_of(in_slot(ItemRules.BOW)) == DuelRules.BOW


func protection() -> int:
	return ItemRules.protection(equipped)


func fingerprint() -> String:
	var worn := PackedStringArray()
	for slot: StringName in ItemRules.SLOTS:
		worn.append("%s=%s" % [slot, in_slot(slot)])
	return "%s|%s|%s|%s" % [",".join(PackedStringArray(owned)), ";".join(worn), made,
		",".join(PackedStringArray(waiting))]
