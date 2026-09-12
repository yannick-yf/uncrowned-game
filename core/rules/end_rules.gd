class_name EndRules
extends RefCounted

## When a reign is over.
##
## §3: the goal is not to kill the king, it is that he stops being king. The ending
## is a **predicate over the tracked quantities**, never a completed route — nothing
## is scripted, nothing has required steps, and any combination of acts that reaches
## one of these states finishes the game. An earlier §3 wrote Force, Access and
## Exposure as recipes with required steps, which is exactly the "quest that can only
## start one way" invariant 5 calls a bug.
##
## **Two hard rules, and both are structural here rather than remembered.**
##
## *The handprint.* Every reading an ending uses must carry the player's hand as
## well as crossing its line, so a reign can never fall out of ambient motion. Drift
## may move the world; only the player may end it.
##
## *Legibility.* The endings and the journal's second page read **the same table**.
## A predicate over numbers the player cannot see is not a goal, it is a trapdoor —
## so an ending whose readings are not on the page is not expressible.

const NONE: StringName = &""
const DEAD: StringName = &"dead"
const RUINED: StringName = &"ruined"
const DEPOSED: StringName = &"deposed"
const DISCREDITED: StringName = &"discredited"
const ABANDONED: StringName = &"abandoned"

## How much of a reading has to be the player's doing before it can help end a
## reign. Well below the thresholds themselves: the player must have had a real hand
## in it, not have done the whole thing unaided — the world helping is the entire
## point of having a simulation.
const HANDPRINT_NEEDED: float = 25.0

const DOWN: int = -1
const UP: int = 1


## Every way a reign ends, as the readings it needs. Ordered as the world would
## resolve them.
##
## `dead` is here and is unreachable until Phase 4 builds the combat screen — which
## is what makes deferring combat cost one ending rather than the climax.
static func endings() -> Array[Dictionary]:
	return [
		{"id": DEAD, "needs": [_at(&"king_health", DOWN, 0.0)]},
		{"id": RUINED, "needs": [
			_at(&"crown_treasury", DOWN, 20.0), _at(&"bank_confidence", DOWN, 25.0)]},
		{"id": DEPOSED, "needs": [
			_at(&"army_strength", DOWN, 30.0), _at(&"faction_tension", UP, 75.0)]},
		{"id": DISCREDITED, "needs": [
			_at(&"facts_public", UP, 3.0), _at(&"towns_turned", UP, 4.0)]},
		{"id": ABANDONED, "needs": [
			_at(&"kings_escort", DOWN, 2.0), _at(&"town_sentiment_at_blackcairn", DOWN, 35.0)]},
	]


static func _at(reading: StringName, direction: int, line: float) -> Dictionary:
	return {"reading": reading, "direction": direction, "line": line}


## The one place a reading is taken, used by the predicates and by the page. A
## reading is either a tracked quantity or something derived from several.
static func value_of(reading: StringName, ticked: WorldTick, world: WorldState, facts: FactBase) -> float:
	match reading:
		&"king_health":
			return float(world.king_hp) if world != null else 0.0
		&"facts_public":
			return float(public_facts(facts))
		&"towns_turned":
			return float(ticked.towns_below(SENTIMENT_SOUR))
		&"kings_escort":
			return float(ticked.kings_escort())
		&"town_sentiment_at_blackcairn":
			return ticked.sentiment_in(&"blackcairn")
	return ticked.get_quantity(reading)


## Whose doing it is. Derived readings answer with the handprint of whatever moves
## them, because that is the number the player actually pushed.
static func handprint_of(reading: StringName, ticked: WorldTick) -> float:
	match reading:
		&"king_health":
			return 0.0
		&"facts_public":
			return ticked.handprint_on(&"facts_public")
		&"towns_turned", &"town_sentiment_at_blackcairn":
			return ticked.handprint_on(&"town_sentiment")
		&"kings_escort":
			return ticked.handprint_on(&"army_strength")
	return ticked.handprint_on(reading)


const SENTIMENT_SOUR: float = 35.0


## Which line names a reading on the page. The word belongs to the window; this
## says only which reading it is.
static func label_key(reading: StringName) -> StringName:
	return StringName("holds.%s" % reading)


## The ending the world has reached, or NONE.
static func ending_for(ticked: WorldTick, world: WorldState, facts: FactBase) -> StringName:
	if ticked == null:
		return NONE
	for ending: Dictionary in endings():
		var met: bool = true
		for need: Dictionary in (ending["needs"] as Array):
			if not _satisfied(need, ticked, world, facts):
				met = false
				break
		if met:
			return ending["id"] as StringName
	return NONE


static func _satisfied(need: Dictionary, ticked: WorldTick, world: WorldState, facts: FactBase) -> bool:
	var reading: StringName = need["reading"] as StringName
	var value: float = value_of(reading, ticked, world, facts)
	var line: float = float(need["line"])
	var crossed: bool = value <= line if int(need["direction"]) == DOWN else value >= line
	# The guardrail. Crossing a line is not enough — somebody has to have pushed it.
	return crossed and handprint_of(reading, ticked) >= HANDPRINT_NEEDED


## Facts the player made public. Knowing a thing privately has never embarrassed
## anybody, so only what was said aloud counts.
static func public_facts(facts: FactBase) -> int:
	if facts == null:
		return 0
	var count: int = 0
	for fact: StringName in facts.facts():
		if String(fact).begins_with("public:"):
			count += 1
	return count


## §15's second page: every reading any ending uses, once, in the order they are
## first needed. Walks the same table the predicates do, so a number that decides
## the game cannot fail to be on it.
static func what_holds_him_up(ticked: WorldTick, world: WorldState, facts: FactBase) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if ticked == null:
		return rows
	var seen: Dictionary = {}
	for ending: Dictionary in endings():
		for need: Dictionary in (ending["needs"] as Array):
			var reading: StringName = need["reading"] as StringName
			if seen.has(reading):
				continue
			seen[reading] = true
			rows.append({
				"reading": String(reading),
				"name_key": label_key(reading),
				"value": value_of(reading, ticked, world, facts),
				"yours": handprint_of(reading, ticked),
				"line": float(need["line"]),
			})
	return rows
