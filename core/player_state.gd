class_name PlayerState
extends RefCounted

## The player's own numbers — `docs/PLAYER_MODEL.md`, the J group.
##
## **The player is shaped like a town** (§2), which is the whole idea of the model:
## something you decide, and something that moves with what happens. `TownState` holds
## two numbers for each place; this holds the player's, and it is a store like any
## other — rebuilt from nothing on replay, holding only what the log put there, and
## written by `PlayerSystem` and by nothing else.
##
## Two of the model's three dimensions live here. The third, **allégeance**, is the
## side the player *chose* and has lived in `Allegiance.side` since September — a thing
## you decide rather than a thing that moves, which is why it is not in this file.

## §6: *"A purse — one integer on the player, moved only through the event log like
## everything else."* The floor, and the whole of what a purse may not do.
const EMPTY: int = 0

## **Richesse: the gold the player has** (§2). One integer, and `SPECS` §12's currency
## and nothing more — no prices, no market, no items. It exists because the fight needs
## somewhere for a dead man's gold to go, not because v1 spends it.
##
## A new player starts with nothing. Waking in the fairies' clearing with a purse is a
## fact about the character nobody has written, and zero is the one reading that claims
## nothing.
var gold: int = EMPTY

## The scale, −100 to +100, which is the one standing has always been on (§3). The
## constants are repeated here rather than read off `Standing` on purpose: that file's
## factions and per-person ledger go with **C3**, and nothing in the new model should
## have to be untangled from it on the day it does.
const NEUTRAL: float = 0.0
const WORST: float = -100.0
const BEST: float = 100.0

## **Standing, per town** (§2): what each place thinks of the player, moved by deeds
## done there and by nothing else. A town not in here is a place outside the system —
## Brindle, a ruin with nobody in it to have an opinion, and the road — exactly as
## `TownState` holds no numbers for one.
##
## **It does not decay** (§3). There is no tick on `PlayerSystem` and no timer here: a
## town remembers, because a number that drains is a number the player cannot reason
## about.
var standing: Dictionary = {}


func _init() -> void:
	# The same five places `TownState` carries, from the same file, so the player's
	# standing and the places' two numbers can never come to disagree about which
	# places exist. They start at neutral: a town the player has never been to has
	# heard nothing (§4).
	for id: StringName in TownState.starts().keys():
		standing[id] = NEUTRAL


func has_standing(town: StringName) -> bool:
	return standing.has(town)


func standing_in(town: StringName) -> float:
	return float(standing.get(town, NEUTRAL))


## Move a town's opinion, clamped, and answer with what actually moved — nothing, for a
## place outside the system. Called by `PlayerSystem` and by nothing else.
func shift_standing(town: StringName, amount: float) -> float:
	if not has_standing(town) or amount == 0.0:
		return 0.0
	var was: float = standing_in(town)
	standing[town] = clampf(was + amount, WORST, BEST)
	return standing_in(town) - was


## Every town the player has a standing with, in a stable order, so a reading of the
## whole kingdom does not depend on dictionary order.
func towns() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in standing.keys():
		out.append(id)
	out.sort()
	return out


## Move the purse, and answer with what actually moved.
##
## **A purse cannot go below zero** (J1's check). Taking more than is there takes what
## is there — it does not refuse, because refusing is a price check and there are no
## prices in v1 (§5). The caller is told the real amount so the log records what
## happened rather than what was asked for.
func move_gold(amount: int) -> int:
	var was: int = gold
	gold = maxi(gold + amount, EMPTY)
	return gold - was


func fingerprint() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for id: StringName in towns():
		parts.append("%s:%.2f" % [id, standing_in(id)])
	return "gold=%d towns[%s]" % [gold, ";".join(parts)]
