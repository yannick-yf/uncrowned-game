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


static func build(
	who: StringName,
	world: WorldState,
	cast: Cast,
	standing: Standing,
	ticked: WorldTick,
	facts: FactBase,
	relations: Relations = null,
) -> String:
	var npc: Npc = cast.get_npc(who) if cast != null else null
	if npc == null:
		return ""
	if relations == null:
		relations = Relations.shared()
	var town: StringName = world.region().zone_at(npc.tile) if world != null else &""
	var lines := PackedStringArray()

	# 1. The sheet: who they are.
	lines.append("WHO: %s, %s, in %s" % [npc.display_name, npc.role, town])

	# 2. Their social edges, one and two hops.
	var edges: Array = relations.near(who, 2)
	for i: int in mini(edges.size(), MAX_EDGES):
		var edge: Dictionary = edges[i]
		lines.append("KNOWS: %s %s %s" % [edge["from"], edge["kind"], edge["to"]])

	# 3. What they know — the facts they are able to tell somebody.
	var theirs := PackedStringArray()
	for option: DialogueOption in npc.options:
		if option.teaches != &"":
			theirs.append(String(option.teaches))
	theirs.sort()
	for i: int in mini(theirs.size(), MAX_FACTS):
		lines.append("HOLDS: %s" % theirs[i])

	# 4. What they know about *you*, which is the half that changes.
	var regard: float = standing.with_person(who) if standing != null else 0.0
	lines.append("REGARDS YOU: %s (%d)" % [StandingRules.word_for(regard), int(round(regard))])
	lines.append("HAS MET YOU: %s" % (facts != null and facts.has(StringName("met:%s" % who))))
	if facts != null and facts.has(DeedRules.DEED_THEFT):
		lines.append("HAS HEARD: you have taken something in front of people")
	if facts != null and facts.has(ArmyRules.FACT_FRAUD_EXPOSED):
		lines.append("HAS HEARD: the pay fraud was said aloud at the camp")

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
			said.append(String(option.intent))
	said.sort()
	for i: int in mini(said.size(), MAX_HISTORY):
		lines.append("ALREADY ASKED: %s" % said[i])

	return "\n".join(lines)


## The cache key. Same situation, same words — and the reason retrieval is out.
static func fingerprint(packet: String) -> String:
	return packet.sha256_text().substr(0, 16)
