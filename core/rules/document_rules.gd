class_name DocumentRules
extends RefCounted

## The evidence, and where it lies.
##
## §7's Q24, settled 2026-09-12: a document is **both**. Reading it is knowledge and
## holding it is proof, and they are not the same thing — the distinction the game
## already had between *knowing* the pay fraud and being able to *say* it, one level
## up.
##
## **Documents live in places, not in people.** A paper does not die with whoever
## owned it. Kill Hesper and her letters are still in her house; you have lost the
## person who would have told you where to look, not the letters. That is the same
## guarantee the power bases gave us — *a place cannot be murdered* — and it means
## **violence can never close Route C**, only make it harder. Invariant 7 stops
## being something we hope holds.
##
## **And nothing takes one off you.** Once it is in your hands it cannot be stolen,
## burned or confiscated. Evidence that can be lost is a route that can be closed,
## and §7 does not allow that.

## Each answers exactly one place the king's argument breaks (§5, §3).
const LAND_GRANTS: StringName = &"acres:land_grants"
const TIERED_LAW: StringName = &"cairnwell:tiered_law"
const WORKS_LEDGER: StringName = &"cinderworks:ledger"
const DEBTS: StringName = &"bank:debts"
const SIGNED_ORDERS: StringName = &"muster:signed_orders"


## The fact a document carries, the break it answers, and the place it sits.
## *Where* in that place is an anchor in `content/places.json`, keyed by the fact;
## the region puts a prop on each (M1a). A rule knows which place holds the proof
## and never a tile.
static func all() -> Array[Dictionary]:
	return [
		{"fact": LAND_GRANTS, "breaks": &"the_aggregate", "zone": &"wide_acres"},
		{"fact": TIERED_LAW, "breaks": &"the_tiered_law", "zone": &"cairnwell"},
		{"fact": WORKS_LEDGER, "breaks": &"the_wealth_went_up", "zone": &"cinderworks"},
		{"fact": DEBTS, "breaks": &"it_was_borrowed", "zone": &"cairnwell"},
		{"fact": SIGNED_ORDERS, "breaks": &"your_village", "zone": &"muster"},
	]


static func facts() -> Array[StringName]:
	var out: Array[StringName] = []
	for row: Dictionary in all():
		out.append(row["fact"] as StringName)
	return out


static func is_document(fact: StringName) -> bool:
	return facts().has(fact)


## What the world knows once you have said it somewhere people heard you. §3's
## `discredited` ending counts these.
static func made_public(fact: StringName) -> StringName:
	return StringName("public:%s" % fact)


## How close you must be to pick one up. The same figure as a market stall: it is a
## thing on a table, not a building.
const REACH: float = 1.8
