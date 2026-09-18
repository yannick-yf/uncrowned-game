class_name TownRules
extends RefCounted

## What a place is worth, in two numbers (`docs/SIMULATION_MODEL.md`, 2026-09-18).
##
## **Allégeance** is how far a place is with the king. **Richesse** is how well it is
## doing. Both run 0 to 10, and that is every number a place has — the twelve
## quantities this replaces were abstractions nobody could go and look at, and these
## two belong to ground the player can stand on.
##
## **One value belongs to the player and the other to the world.** Allégeance moves
## only when the player acts: it is who a place is *with*, and a choice that drifts
## back on its own is not a choice. Richesse moves when the player acts *and* drifts
## with what the kingdom sends the place, which is what carries *destroy the farms and
## the ironworks feels it*.
##
## Pure, as every rule here is. The store holds the numbers; this says what may be
## done to them.

const ALLEGIANCE: StringName = &"allegiance"
const RICHESSE: StringName = &"richesse"
const BOTH: Array[StringName] = [ALLEGIANCE, RICHESSE]

const FLOOR: int = 0
const CEILING: int = 10

## Where a number becomes an appearance. At or above it a place reads as loyal or
## rich; below it, as hostile or poor. **Nothing lands on it by design** — the
## Cinderworks starts at 6 and 4 and its two outcomes are 3/1 and 9/7 — so the
## boundary case is a definition rather than a decision anybody plays against.
const THRESHOLD: int = 5

## **The guardrail** (Yannick, 2026-09-18): the food a place drifts toward never counts
## as less than this, so the kingdom can make a place suffer and cannot starve it to
## death. Only the player's own act takes a place to the bottom.
const FOOD_FLOOR: int = 3

## What one act of the player's moves a value.
##
## **Three, chosen so an outcome always crosses the threshold** from the starts in
## `content/towns.json`, not for balance. A choice the player cannot see is not a
## choice, and the threshold is what a choice has to cross to be seen.
const STEP: int = 3


static func is_value(which: StringName) -> bool:
	return BOTH.has(which)


## Inside the floor and the ceiling, always. Guardrail 2 of the model: without them a
## bad turn becomes a spiral nobody can stop, and the player watches a machine.
static func clamped(value: int) -> int:
	return clampi(value, FLOOR, CEILING)


## Whether this number reads as the good half of its axis — loyal, or rich.
static func is_high(value: int) -> bool:
	return value >= THRESHOLD


## The four appearances, as the pair of thresholds (§4 of the model): loyal or
## hostile, rich or poor. The words are the window's; this is the verdict.
static func look_of(allegiance: int, richesse: int) -> StringName:
	if is_high(allegiance):
		return &"loyal_rich" if is_high(richesse) else &"loyal_poor"
	return &"hostile_rich" if is_high(richesse) else &"hostile_poor"


## How many of a place's furnaces burn, given its richesse.
##
## **Proportional, so the works reads as three things rather than two.** All-or-nothing
## would give a working town and a dead one and nothing in between — and the Cinderworks
## spends the whole quest *in* between, which is how the player knows there is an
## argument before anybody speaks. Of six furnaces: none at 1, two at 4, four at 7, all
## six at 10.
static func lit_of(total: int, richesse: int) -> int:
	if total <= 0:
		return 0
	return clampi(total * clamped(richesse) / CEILING, 0, total)


## A value after an act moved it. `direction` is +1 or -1; anything else moves nothing,
## because a caller that means "no change" should say so rather than pass a zero that
## reads like an arithmetic accident.
static func moved(value: int, direction: int) -> int:
	if direction == 0:
		return clamped(value)
	return clamped(value + (STEP if direction > 0 else -STEP))
