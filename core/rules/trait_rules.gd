class_name TraitRules
extends RefCounted

## The four traits, and what a character is made of.
##
## **Force, Intelligence, Agilité, Prestance — a pool of 8, a floor of 1, a cap of 5**
## (S1, 2026-09-28; `docs/SIMULATION_MODEL.md`'s list). At 4 points to take a trait
## from 1 to 5, eight buys exactly two specialisms and nothing else — or one at 5 and
## two at 3, or a flat spread — and each of those is a different person.
##
## It was six traits and a pool of 10 (2026-09-13). Two of the six were ever asked for
## by a line of dialogue: *Wits* became Intelligence and *Temper* — saying it to their
## face — became Force. The other four were never read, and Attunement's one use, the
## wood slowing somebody not raised in it, is a layer that is switched off (C4).
##
## **Traits are not progression.** They are chosen once and do not rise (§19 Q23), so
## gating a line of dialogue on one is not the progression check invariant 4 forbids:
## it is the same kind of thing as being unwelcome in a town. What invariant 4 forbids
## is a door that opens because you did the previous thing, and none of these do.

const STRENGTH: StringName = &"strength"
const INTELLIGENCE: StringName = &"intelligence"
const AGILITY: StringName = &"agility"
const PRESENCE: StringName = &"presence"

## Order is the order they are shown in, and nothing else depends on it.
const ALL: Array[StringName] = [STRENGTH, INTELLIGENCE, AGILITY, PRESENCE]

const FLOOR: int = 1
const CAP: int = 5
const POOL: int = 8

## What a trait has to reach before a line that leans on it is offered. One number
## for all four, because four numbers would be four things nobody had reasoned about —
## and 3 is "you put points here", which is exactly what the gate should mean.
const SPEAKS_AT: int = 3


static func name_key(what: StringName) -> StringName:
	return StringName("trait.%s" % what)


static func note_key(what: StringName) -> StringName:
	return StringName("trait.%s.note" % what)


## What raising a trait from the floor to `level` costs out of the pool.
static func cost_of(level: int) -> int:
	return maxi(level, FLOOR) - FLOOR


static func spent(levels: Dictionary) -> int:
	var total: int = 0
	for what: StringName in ALL:
		total += cost_of(int(levels.get(what, FLOOR)))
	return total


## Whether a set of levels is one a character could be created with.
##
## Returns the reason it is not, or an empty string. A reason rather than a bool
## because the creation screen has to say why the button is refusing.
static func why_not(levels: Dictionary) -> StringName:
	for what: StringName in ALL:
		var level: int = int(levels.get(what, FLOOR))
		if level < FLOOR or level > CAP:
			return &"creation.out_of_range"
	if spent(levels) > POOL:
		return &"creation.overspent"
	return &""


static func is_legal(levels: Dictionary) -> bool:
	return why_not(levels) == &""


## A character with nothing chosen yet: every trait at the floor, the whole pool
## unspent. Also what anybody gets who never saw the creation screen, so a save from
## before this existed, or a test that does not care, still has a legal character.
static func at_the_floor() -> Dictionary:
	var out: Dictionary = {}
	for what: StringName in ALL:
		out[what] = FLOOR
	return out
