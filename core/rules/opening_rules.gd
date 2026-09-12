class_name OpeningRules
extends RefCounted

## The opening, as rules rather than as a script.
##
## §4's opening: the player wakes in the fairies' clearing, one of them tells them
## what only she can tell them, and then she is gone. There is no cutscene and no
## flag — she is an ordinary NPC whose seven lines are chained on facts, so the
## whole scene is in the event log and replays like a keypress.
##
## **What she must never say**: the king, by name or title, and nothing of industry,
## steel, land or law. A fairy in a wood does not have the political map; she knows
## men came with axes. The player already remembers it was the king's men (§5), so
## the motive is complete without her explaining his politics — and if she pre-judges
## him in minute one, Route C stops working, because §5 holds that his argument has
## to be real and found. A test asserts the silence rather than trusting it.

const FAIRY: StringName = &"fairy"

## The last thing she says. Knowing it is what means she has finished, so nothing
## needs a "she is gone" flag: the facts the player holds *are* the state.
const FACT_LAST_WORD: StringName = &"thornwood:save_us"

## Everything she tells the player, in order.
const WHAT_SHE_TELLS_YOU: Array[StringName] = [
	&"you:died", &"you:raised", &"thornwood:axes", &"thornwood:dying",
	&"you:remembered", &"you:owed", &"thornwood:save_us",
]

## Words that would make her a briefing rather than a fairy.
const SHE_MAY_NEVER_SAY: Array[String] = [
	"roi", "king", "arthur", "couronne", "crown", "loi", "law", "acier", "steel",
	"forge", "works", "usine", "industry", "terre", "land", "impôt", "tax",
]


## Whether she is still in the clearing.
##
## She leaves when she has finished, and finishing is knowing her last word. No flag,
## no removal event, nothing to keep in step — a player who has been told everything
## is a player she is done with.
static func fairy_is_here(facts: FactBase) -> bool:
	return facts != null and not facts.has(FACT_LAST_WORD)


## Whether this is somebody the world should stop drawing and stop offering.
static func is_gone(who: StringName, facts: FactBase) -> bool:
	return who == FAIRY and not fairy_is_here(facts)
