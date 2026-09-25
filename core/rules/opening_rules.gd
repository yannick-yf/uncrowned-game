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
##
## **Two people can leave it, for opposite reasons** (Q6, 2026-09-19). The fairy goes
## because she is finished with you. **Tom goes because the works went back to work** —
## `docs/QUEST_CINDERWORKS.md` §5, Sena's outcome: *Tom and his people are not there any
## more, and those who remain know it*. Whether he was stopped or killed, the quest does
## not say and neither does this.
##
## It is read from a fact and nothing is kept in step: no removal event, no flag, nothing
## that can disagree with the world. And his people go with him without being modelled one
## by one, because richesse decides how many walk to work and putting the fires back on
## does not bring back the men who wanted them out.
##
## This lives beside the fairy rather than in a quest file because there is one question
## here — *should the world still draw this person* — and one place worth asking it.
const TOM: StringName = &"tom"
const WORKS_RELIT: StringName = &"i_lit_them_again"


## **And a third reason, which is the bluntest** (K3, 2026-09-25): they were killed.
## `FellingSystem` writes `killed:<who>` when a duel puts somebody down, and this reads
## it — a fact, like the other two, so a replay rebuilds it and nothing is kept in step.
## It is checked first because it outranks the others: a dead man is not merely finished
## with you.
const KILLED: String = "killed:%s"


static func is_gone(who: StringName, facts: FactBase) -> bool:
	if facts != null and facts.has(StringName(KILLED % who)):
		return true
	if who == FAIRY:
		return not fairy_is_here(facts)
	if who == TOM:
		return facts != null and facts.has(WORKS_RELIT)
	return false


# ------------------------------------------------------- what became of it ---

## The wood's state, for the journal.
##
## **Why this is on the page at all.** The fairy's last word is *if you can, save
## us*, and until now that was a request the player could satisfy and never find out
## about: the wood stops shrinking when the furnaces stop, and nothing said so. §8's
## rule is that a change the player cannot perceive is identical to no change, so
## either this is shown or the asking was empty.
##
## State and attribution, never advice. It says how much ground is left and whether
## anything is still taking it. It never says to go and put the furnaces out.
static func wood_row(ticked: WorldTick) -> Dictionary:
	if ticked == null:
		return {}
	var held: float = ticked.held_ground
	return {
		"held": held,
		"paces": int(round(held)),
		"gone": held <= 0.0,
		# Running furnaces are what takes it, so "is anything still taking it" is a
		# question about the works rather than about the wood.
		"falling": held > 0.0 and ticked.steel_output > 0.0,
	}


## Whether the player has any business being shown the wood at all.
##
## Only once she has told them it is happening. A journal that explains a thing the
## player has never heard of is the game telling them their own story.
static func knows_about_the_wood(facts: FactBase) -> bool:
	return facts != null and facts.has(&"thornwood:axes")
