class_name DialogueRules
extends RefCounted

## The rules layer for conversation. Pure, and the only thing allowed to decide
## what the player may say.
##
## SPECS §9 and CLAUDE.md invariant 8: when a model is eventually attached, it
## phrases lines and nothing else. The set of legal intents is computed here, from
## facts, and the model never gets to add to it. Phase 1 has no model at all — the
## line is looked up — but the seam is in the right place already.

## Three or four, per §9. The fourth slot is always the way out.
const MAX_OPTIONS: int = 4


## The named world conditions content may gate a line on.
##
## Content names a condition; this decides what it means. A line that read the
## world directly would put game logic in content/, where it cannot be reasoned
## about or tested — and §9's whole point is that the rules layer issues the
## verdict and the words only phrase it.
const GRAIN_IS_DEAR: float = 60.0

## Where a town stops being willing is decided by StandingRules, not here, because
## the HUD reads its word off the same number. One witnessed theft costs more than
## that threshold on arrival, deliberately: the first consequence has to be legible
## the first time, not on the third repetition.


static func conditions(
	world: WorldState,
	ticked: WorldTick,
	standing: Standing = null,
) -> Dictionary:
	if world == null or ticked == null:
		return {}
	var here: StringName = world.region().zone_at(world.player_tile())
	return {
		&"grain_is_dear_here": here != &"" and ticked.grain_in(here) >= GRAIN_IS_DEAR,
		&"the_army_is_shrinking": ticked.army_strength < 90.0,
		# Asked of the town you are standing in, never of a global number. Word
		# reaching Cairnwell shuts a door there and nowhere else.
		#
		# Dialogue no longer uses this: a conversation reads what the person in
		# front of you thinks, which already carries their town's opinion through
		# hearsay. It stays for content that is about a *place* rather than a
		# person — whether a market will price-gouge you, whether a gate is
		# watched — which is the only kind of thing it was ever right for.
		&"i_am_unwelcome_here": (standing != null and here != &""
			and StandingRules.is_unwelcome(standing.in_town(here))),
	}


## Which of an NPC's authored options are legal right now.
static func available(
	npc: Npc,
	facts: FactBase,
	world_conditions: Dictionary = {},
	regard: float = 0.0,
) -> Array[DialogueOption]:
	var out: Array[DialogueOption] = []
	if npc == null:
		return out
	# Past a point there is no conversation to have. Not a line withheld — the
	# whole exchange, refused.
	if StandingRules.refuses_to_talk(regard):
		return out
	# Two passes, and the order is the point. A line that exists *only because the
	# world changed* outranks one that is always there — otherwise the three-slot
	# cap fills with standing filler and the reactive line, authored last, is never
	# seen. Reactivity nobody can reach is reactivity nobody has.
	var reactive: Array[DialogueOption] = []
	var standing: Array[DialogueOption] = []
	for option: DialogueOption in npc.options:
		if option.requires != &"" and not facts.has(option.requires):
			continue
		# Already answered. A person is a finite resource in a game about
		# information, and a conversation should get shorter every time you have it
		# until there is nothing left but the way out.
		if not option.repeatable and facts.has(option.spent_by(npc.id)):
			continue
		if option.hides_after != &"" and facts.has(option.hides_after):
			continue
		if option.forbids_condition != &"":
			if bool(world_conditions.get(option.forbids_condition, false)):
				continue
		# The rule that applies to the whole cast rather than line by line: nobody
		# confides in, or does favours for, someone they think ill of. Content
		# marks the exceptions; it no longer has to remember the rule.
		if option.asks_for_goodwill() and StandingRules.is_unwelcome(regard):
			continue
		if option.requires_condition != &"":
			if not bool(world_conditions.get(option.requires_condition, false)):
				continue
			reactive.append(option)
		else:
			standing.append(option)

	for option: DialogueOption in reactive:
		out.append(option)
	for option: DialogueOption in standing:
		if out.size() >= MAX_OPTIONS - 1:
			break
		out.append(option)
	return out


static func find(npc: Npc, intent: StringName) -> DialogueOption:
	if npc == null:
		return null
	for option: DialogueOption in npc.options:
		if option.intent == intent:
			return option
	return null


## The verdict: what actually happens when this intent is spoken. Returns the fact
## learned, or an empty name for "nothing mechanical, just words". An intent the
## rules layer does not recognise does nothing at all — which is the whole point
## of intents being a closed set.
static func verdict(
	npc: Npc,
	intent: StringName,
	facts: FactBase,
	world_conditions: Dictionary = {},
	regard: float = 0.0,
) -> StringName:
	var option: DialogueOption = find(npc, intent)
	if option == null:
		return &""
	if not available(npc, facts, world_conditions, regard).has(option):
		return &""
	return option.teaches
