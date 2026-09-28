class_name QuestRules
extends RefCounted

## What the player is trying to find out, as predicates over the fact base.
##
## **Invariant 5, structurally rather than hopefully.** *"Quests are reactions to fact
## patterns, not scripts. A quest that can only start one way is a bug."* So a quest
## here is not a thing anybody gives you, not a sequence of steps, and not a flag. It
## is two patterns:
##
## - **`needs`** — what you have to know before it is a question you could be asking.
## - **`done` / `done_any`** — what makes it answered.
##
## Nothing opens a quest but learning something, and because §7 requires every fact
## to have more than one source, **every quest has more than one way in for free**.
## Kill the person who would have told you and a different one still can. No test has
## to police that; it falls out of keying on facts instead of on people.
##
## **There is no quest store and no quest system.** The state is the fact base, so
## there is nothing to keep in step, nothing to migrate, and nothing to replay: a
## reloaded save has exactly the quests its facts imply. Adding one is a row.

## `id` is the text key's suffix, so a quest needs no name field: `quest.<id>` and
## `quest.<id>.note` are looked up, and a test asserts both exist in both languages.
## **One quest, since C3** (2026-09-28). The old game had eight — who you were, what
## the works cost, why the soldiers run and five more — and they went with it: the new
## model is one quest per place and the demo has one place in play. The mechanism is
## what `SIMULATION_KEEP_OR_DROP.md` kept, and adding the next place's quest is a row.
const QUESTS: Array[Dictionary] = [
	{
		"id": &"the_wood_is_going",
		# The fairy's last word, given in the first minute by somebody who cannot be
		# killed and does not leave until she has said it.
		"needs": [OpeningRules.FACT_LAST_WORD],
		# **Either act at the works settles it** — put the fires out with Tom, or light
		# them again with Sena (`docs/QUEST_CINDERWORKS.md` §4). Relighting answers her
		# the way she did not want, and it is still an answer.
		"done_any": [DeedRules.DEED_DOUSE, DeedRules.DEED_RELIGHT],
	},
]


static func all() -> Array[Dictionary]:
	return QUESTS


static func find(id: StringName) -> Dictionary:
	for quest: Dictionary in QUESTS:
		if quest["id"] == id:
			return quest
	return {}


## Whether every fact in a list is known. An empty list is vacuously true, which is
## what makes `done_any` able to stand alone.
static func _all_known(facts: FactBase, of: Array) -> bool:
	if facts == null:
		return false
	for fact: Variant in of:
		if not facts.has(fact as StringName):
			return false
	return true


static func _any_known(facts: FactBase, of: Array) -> bool:
	if facts == null or of.is_empty():
		return false
	for fact: Variant in of:
		if facts.has(fact as StringName):
			return true
	return false


## Answered.
static func is_done(quest: Dictionary, facts: FactBase) -> bool:
	var any: Array = quest.get("done_any", []) as Array
	if not any.is_empty():
		return _any_known(facts, any)
	var all_of: Array = quest.get("done", []) as Array
	return not all_of.is_empty() and _all_known(facts, all_of)


## A question the player could be asking, and has not answered yet.
static func is_open(quest: Dictionary, facts: FactBase) -> bool:
	return _all_known(facts, quest.get("needs", []) as Array) and not is_done(quest, facts)


static func open_ones(facts: FactBase) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for quest: Dictionary in QUESTS:
		if is_open(quest, facts):
			out.append(quest)
	return out


static func done_ones(facts: FactBase) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for quest: Dictionary in QUESTS:
		if is_done(quest, facts):
			out.append(quest)
	return out


## How far through a quest's answer the player is, as *known* of *needed*.
##
## For the journal: "two of the three people who remember your village". Reported
## rather than advised — it says where you are, never where to go (§8).
static func progress(quest: Dictionary, facts: FactBase) -> Array:
	var any: Array = quest.get("done_any", []) as Array
	if not any.is_empty():
		return [1 if _any_known(facts, any) else 0, 1]
	var wanted: Array = quest.get("done", []) as Array
	var known: int = 0
	for fact: Variant in wanted:
		if facts != null and facts.has(fact as StringName):
			known += 1
	return [known, wanted.size()]


static func name_key(quest: Dictionary) -> StringName:
	return StringName("quest.%s" % quest["id"])


static func note_key(quest: Dictionary) -> StringName:
	return StringName("quest.%s.note" % quest["id"])
