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
	return "gold=%d" % gold
