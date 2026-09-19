class_name WardRules
extends RefCounted

## **A gate that is a man, not a lock** (Q1, 2026-09-19; Yannick's call).
##
## His street runs straight through where the works' yard wall wants to be, and this
## map has a rule that a wall never closes a road — it has already caught one bug where
## a curtain wall sealed the way in. So the opening stays open and somebody stands in
## it, which is the better fiction anyway: the Cinderworks is not locked, it is
## *watched*.
##
## **This is invariant 4 working rather than being bent.** Nothing here asks whether a
## quest is done. A ward asks for a **fact** — that somebody vouched for you — and a
## fact can be got more than one way, which is the whole difference between a door and
## a flag. `docs/QUEST_CINDERWORKS.md` has two: Tom brings you through a way he knows,
## Drissa vouches for you at the gate.
##
## A ward nobody has a fact for is simply shut, and that is Q1's state: the yard is
## closed to everyone until Q3 gives the facts out.

## Which fact opens which ward. Content names the ward; this names the key, so that a
## place cannot invent its own way of being entered.
const KEYS: Dictionary = {
	&"cinderworks_gate": [&"cinderworks:vouched_for", &"cinderworks:brought_through"],
}


static func is_warded(ward: StringName) -> bool:
	return KEYS.has(ward)


## Whether this ward lets the player through, given what they have.
##
## **Any one key is enough**, deliberately: invariant 6 wants a route to survive losing
## a person, and a gate with one key is a gate one death closes for ever.
static func opens(ward: StringName, facts: FactBase) -> bool:
	if not KEYS.has(ward):
		return true
	if facts == null:
		return false
	for key: Variant in (KEYS[ward] as Array):
		if facts.has(key as StringName):
			return true
	return false
