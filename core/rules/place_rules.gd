class_name PlaceRules
extends RefCounted

## The four places, their two states, and the one decisive change each (§3, §8).
##
## **Crown-held or free, and never a third.** All four start crown-held, because that
## is what a power base is, and a place is never pushed past its starting state: you
## liberate one or you restore it, and the Wide Acres never becomes better than it has
## ever been. The state itself lives in `Allegiance.owner_of`, where the borders' band
## already kept it; this is the pure half — what each place holds, what spends it, and
## how long a decision holds.
##
## **One thing, two ways to spend it.** Each place holds one thing — the grants, the
## ledger, the fraud in the rolls, the debts — and the decisive change is what the
## player does with it *at the landmark*. Read aloud to the people it is about, the
## place goes free; spent the crown's way, to the person whose business it is, the
## place is held. It is the shape §8 already has for a fact, told once to one audience,
## and the shape of making a thing public against informing on it. Nothing at the
## landmark is a menu: what decides the outcome is what the player brought.

## Ids rather than the other classes' constants, because a const built from another
## class's const cannot be resolved at parse time. A test holds them equal.
const PLACES: Array[StringName] = [&"wide_acres", &"cinderworks", &"muster", &"cairnwell"]

## What each place holds — the thing that frees it when made public *there*.
const THING: Dictionary = {
	&"wide_acres": &"acres:land_grants",
	&"cinderworks": &"cinderworks:ledger",
	&"muster": &"muster:pay_fraud",
	&"cairnwell": &"bank:debts",
}

## The act that holds a place for the crown, spending the same thing the other way.
const HOLDS: Dictionary = {
	&"i_enforced_the_grants": &"wide_acres",
	&"i_settled_the_wage": &"cinderworks",
	&"i_paid_the_muster": &"muster",
	&"i_brought_the_creditors": &"cairnwell",
}


static func has_state(zone: StringName) -> bool:
	return PLACES.has(zone)


static func thing_of(zone: StringName) -> StringName:
	return THING.get(zone, &"") as StringName


## Whether making this fact public, in this place, frees it.
static func frees(zone: StringName, fact: StringName) -> bool:
	return has_state(zone) and thing_of(zone) == fact


## The place a deed holds for the crown, or "" for a deed that decides nothing.
static func held_by(deed: StringName) -> StringName:
	return HOLDS.get(deed, &"") as StringName


static func is_free(state: StringName) -> bool:
	return state == FactionRules.OPPOSITION


## **The freeze window — one constant, defined here and nowhere else** (§8). Two
## in-game days: 2 × 1440 = 2880 world ticks, twelve real minutes. A state the player
## set holds for that long against everything — the band cannot move it back and the
## opposite decisive act is refused — as a tick stamp in the event log, so a replay
## lands on the same tick in the same state. It is also what "recently" means to
## Blackcairn's instability reading (§4).
static func freeze_ticks() -> int:
	return 2 * Game.TICKS_PER_IN_GAME_DAY


## The entrance sign, in the place's own words (§15). A key, not a sentence: the
## words are content, French first, and which one shows is this verdict — from the
## holder and whether the player ever decided the place, so this rule owes the store
## nothing. A place the
## player strengthened boasts differently from one that was always loyal, and a freed
## one says something careful.
static func sign_key_for(zone: StringName, holder: StringName, decided: bool) -> StringName:
	if zone == &"blackcairn":
		return &"sign.blackcairn.crown"
	if not has_state(zone):
		return &""
	if is_free(holder):
		return StringName("sign.%s.free" % zone)
	if decided:
		return StringName("sign.%s.restored" % zone)
	return StringName("sign.%s.crown" % zone)
