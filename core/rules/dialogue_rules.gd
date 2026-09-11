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


## Which of an NPC's authored options are legal right now.
static func available(npc: Npc, facts: FactBase) -> Array[DialogueOption]:
	var out: Array[DialogueOption] = []
	if npc == null:
		return out
	for option: DialogueOption in npc.options:
		if option.requires != &"" and not facts.has(option.requires):
			continue
		if option.hides_after != &"" and facts.has(option.hides_after):
			continue
		out.append(option)
		if out.size() >= MAX_OPTIONS - 1:
			break
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
static func verdict(npc: Npc, intent: StringName, facts: FactBase) -> StringName:
	var option: DialogueOption = find(npc, intent)
	if option == null:
		return &""
	if not available(npc, facts).has(option):
		return &""
	return option.teaches
