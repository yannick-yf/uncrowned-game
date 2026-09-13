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
const QUESTS: Array[Dictionary] = [
	# --- who you are -------------------------------------------------------
	{
		"id": &"who_you_were",
		"needs": [&"you:raised"],
		"done": [&"brindle:the_ground", &"acres:razed_villages", &"brindle:that_night"],
	},
	# --- what the king's project costs -------------------------------------
	{
		"id": &"the_true_count",
		"needs": [&"you:owed"],
		"done": [&"cinderworks:death_toll"],
	},
	{
		"id": &"why_they_run",
		"needs": [&"thornwood:kell"],
		"done": [&"muster:pay_fraud"],
	},
	{
		"id": &"what_leaves",
		"needs": [&"muster:pay_fraud"],
		"done": [&"saltmarch:what_leaves"],
	},
	{
		"id": &"the_kings_purse",
		"needs": [&"law:the_effects"],
		"done": [&"bank:leveraged"],
	},
	# --- the people --------------------------------------------------------
	{
		"id": &"the_man_in_the_wood",
		"needs": [&"thornwood:kell"],
		"done": [&"met:kell"],
	},
	{
		"id": &"another_way_across",
		"needs": [&"met:garrick"],
		"done": [&"kettle:ford"],
	},
	# --- and the thing you were raised for ---------------------------------
	{
		"id": &"the_wood_is_going",
		"needs": [&"thornwood:save_us"],
		# Either lever stops the furnaces, and stopping the furnaces is what stops
		# the clearing (§8). Two ways, because there are two.
		"done_any": [&"i_turned_the_workers", &"i_wrecked_a_furnace"],
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
