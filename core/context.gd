class_name Context
extends RefCounted

## Everything one person knows about you and about the day they are having.
##
## §9's context assembler, as a **pure function over fixed, ordered sources**. Given
## an NPC and the world, it renders a packet: the same state always renders the same
## string, so the packet can be hashed and the hash used as a dialogue cache key.
##
## There is no model here and there does not need to be one. The packet is worth
## building on its own — it is what a hand-written line is choosing between, it is
## what the dialogue cache would be keyed on, and it is the thing to *read* before
## deciding whether a model should ever see it. A rich packet means generation would
## be good; a thin one means no model on earth would save it.
##
## **Why not retrieval** (§9, and §21's cut): the packet is hashed. Vector recall
## drifts between runs, hardware and index builds, and a drifting packet is a
## drifting hash, a cache miss and a broken determinism guarantee at exactly the
## layer that needs it most. With this cast the whole world fits in a context window
## many times over, and what §9 wanted — family, employers, debts, rivalries — is a
## graph traversal, which a query answers exactly and an embedding answers
## approximately.

## Each source gets a fixed slice and a stable sort, so identical state renders an
## identical packet. §9's six, in §9's order.
const MAX_EDGES: int = 10
const MAX_FACTS: int = 12
const MAX_HISTORY: int = 8
## What the player knows, clipped. Everything they have learned is in the fact base
## and most of it has nothing to do with the person in front of them; an unbounded
## list would also be the largest thing in the packet, competing with the task.
const MAX_KNOWN: int = 6
## The last exchanges of the current conversation, in full.
const MAX_THREAD: int = 2


static func build(
	who: StringName,
	world: WorldState,
	cast: Cast,
	standing: Standing,
	ticked: WorldTick,
	facts: FactBase,
	relations: Relations = null,
	asking: DialogueOption = null,
	allegiance: Allegiance = null,
) -> String:
	var npc: Npc = cast.get_npc(who) if cast != null else null
	if npc == null:
		return ""
	if relations == null:
		relations = Relations.shared()
	var town: StringName = world.region().zone_at(npc.tile) if world != null else &""
	var lines := PackedStringArray()

	# 1. The sheet: who they are, and how they talk.
	#
	# The voice note is the difference between a packet somebody could write from
	# and a packet that only says a name. Without it the answer to "who is this"
	# is "a foreman", which is not enough to put words in his mouth.
	lines.append("WHO: %s, %s, in %s" % [npc.display_name, npc.role, _place(town)])
	var voice: String = Voices.shared().of(npc)
	if voice != "":
		lines.append("VOICE: %s" % voice)

	# 2. Their social edges, one and two hops.
	var edges: Array = relations.near(who, 2)
	for i: int in mini(edges.size(), MAX_EDGES):
		var edge: Dictionary = edges[i]
		lines.append("KNOWS: %s %s %s" % [
			_person(cast, edge["from"]),
			Text.of(StringName("relation.%s" % edge["kind"])),
			_person(cast, edge["to"])])

	# 3. What they know — the facts they are able to tell somebody.
	var theirs := PackedStringArray()
	for option: DialogueOption in npc.options:
		if option.teaches != &"":
			theirs.append(_fact(cast, option.teaches))
	theirs.sort()
	for i: int in mini(theirs.size(), MAX_FACTS):
		lines.append("HOLDS: %s" % theirs[i])

	# 4. What they know about *you*, which is the half that changes.
	var regard: float = standing.with_person(who) if standing != null else 0.0
	lines.append("REGARDS YOU: %s (%d)" % [StandingRules.word_for(regard), int(round(regard))])
	lines.append("HAS MET YOU: %s" % (facts != null and facts.has(StringName("met:%s" % who))))
	# Every deed, not the two that happened to be written down first. A hand-kept
	# list of "which acts are worth mentioning" goes stale the moment the deed table
	# gains a row, and it had already gone stale by eleven of them.
	if facts != null:
		for deed: StringName in DeedRules.all_deeds():
			if facts.has(deed):
				var heard: String = Text.of(StringName("deed.heard.%s" % deed))
				if heard != String(deed):
					lines.append("HAS HEARD: %s" % heard)
		if facts.has(ArmyRules.FACT_FRAUD_EXPOSED):
			lines.append("HAS HEARD: the pay fraud was said aloud at the camp")

	# 4b. And what you have declared yourself to be, which everybody can see.
	#
	# §8's appearance register: joining is worn. A place does not have to be told
	# what you are, the way it has to be told what you did — so this is in the packet
	# beside what they think of you rather than among the facts they may not know.
	if allegiance != null and allegiance.side != FactionRules.NEUTRAL:
		lines.append("SEES YOU AS: %s" % Text.of(allegiance.rank_key()))

	# 5. And what *you* know, which nothing here has ever said.
	#
	# The packet described the person and the world and never the player, so every
	# answer was written for somebody who had just walked in off the road. Whether
	# you have read the ledger is the difference between being told the number and
	# being asked what you intend to do with it — and when the player's own options
	# are generated, this is the source they are generated from.
	if facts != null and cast != null:
		var known := PackedStringArray()
		for fact: StringName in facts.facts():
			var described: String = String(cast.fact_descriptions.get(fact, ""))
			if described != "":
				known.append(described)
		known.sort()
		for i: int in mini(known.size(), MAX_KNOWN):
			lines.append("YOU KNOW: %s" % known[i])

	# 5. The world-tick values that touch them, and nothing that does not.
	if ticked != null and town != &"":
		lines.append("HIS TOWN: bread %d, regard for the crown %d, watch %d" % [
			int(round(ticked.grain_in(town))), int(round(ticked.sentiment_in(town))),
			int(round(ticked.alertness_in(town)))])
		lines.append("THE KINGDOM: army %d, treasury %d, steel %d" % [
			int(round(ticked.army_strength)), int(round(ticked.crown_treasury)),
			int(round(ticked.steel_output))])

	# 6. What the two of you have already said. Kept last and clipped, because it is
	# the part that grows without bound.
	var said := PackedStringArray()
	for option: DialogueOption in npc.options:
		if facts != null and facts.has(option.spent_by(who)):
			said.append(option.text)
	said.sort()
	for i: int in mini(said.size(), MAX_HISTORY):
		lines.append("ALREADY ASKED: %s" % said[i])
	# And the thread of *this* conversation, which the set of asked questions cannot
	# carry: it has no order and holds no answers. Clipped from the end, because the
	# line before last is what a reply has to sound like it follows.
	if world != null:
		var thread: Array[String] = world.said_before
		for i: int in range(maxi(0, thread.size() - MAX_THREAD), thread.size()):
			lines.append("SO FAR IN THIS TALK: %s" % thread[i])

	# 7. And what is actually being asked, if anything. A packet without this says
	# who somebody is and never says what they are answering, which is most of a
	# brief and none of a question.
	#
	# **Facts, not the finished sentence.** This line used to be `MUST SAY:` followed
	# by the whole written reply, which is a brief to rephrase — safe, and worth
	# almost nothing, because a sentence that is already written does not need
	# writing again. `MUST BE TRUE:` is the brief that pays for itself: the same facts
	# serve every world the question can be asked in, and there are four of those per
	# question before anything interesting has happened.
	#
	# Where no facts are declared the written reply is shown instead and the answer is
	# not generatable at all (`Answers.may_be_written`). So this turns on one line at
	# a time, and everything it is not turned on for is unchanged.
	if asking != null:
		lines.append("ASKED: %s" % asking.text)
		var must: PackedStringArray = Answers.shared().must_be_true(who, asking.intent)
		if must.is_empty():
			lines.append("MUST SAY: %s" % asking.reply)
		else:
			for fact: String in must:
				lines.append("MUST BE TRUE: %s" % fact)
		if asking.teaches != &"":
			lines.append("TEACHES: %s" % _fact(cast, asking.teaches))

	return "\n".join(lines)


## Anything that names a thing in the world, in the player's language.
##
## **The rule the first real generation run taught us** (2026-09-12). The packet was
## written to be read by a person and handed the model raw internal ids —
## `maddox knows_of kell`, `HOLDS: thornwood:kell`, `in cinderworks`. The model
## echoed them: it wrote *"il est dans Thornwood"* into a French line, in a game
## where that wood is called la Ronceraie and Thornwood is a name no player has ever
## seen. It was blamed on the model for about ten minutes. It was ours.
##
## So: **anything in the packet that names a thing may be repeated, therefore
## everything that names a thing must be sayable.** English survives in the packet
## only where it is an instruction and never a name — the section labels, the voice
## note, and the facts under MUST BE TRUE, which exist to be rendered rather than
## copied. That last one is the whole bet, and it is what the experiment measures.
static func _person(cast: Cast, who: Variant) -> String:
	var npc: Npc = cast.get_npc(StringName(who)) if cast != null else null
	return npc.display_name if npc != null else String(who)


static func _place(zone: StringName) -> String:
	return Text.of(StringName("place.short.%s" % zone)) if zone != &"" else "nowhere"


static func _fact(cast: Cast, fact: StringName) -> String:
	if cast == null:
		return String(fact)
	var described: String = String(cast.fact_descriptions.get(fact, ""))
	return described if described != "" else String(fact)


## The cache key. Same situation, same words — and the reason retrieval is out.
static func fingerprint(packet: String) -> String:
	return packet.sha256_text().substr(0, 16)
