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
## Where a town's people are visibly worse off (§8's hardship, 2026-09-13). One act
## against a place carries it from the ordinary 50 past this, so the person standing
## there can say so the same day, without saying who did it.
const HARDSHIP_BITES: float = 62.0

## Where a town stops being willing is decided by StandingRules, not here, because
## the HUD reads its word off the same number. One witnessed theft costs more than
## that threshold on arrival, deliberately: the first consequence has to be legible
## the first time, not on the third repetition.


static func conditions(
	world: WorldState,
	ticked: WorldTick,
	standing: Standing = null,
	allegiance: Allegiance = null,
	tick: int = 0,
) -> Dictionary:
	if world == null or ticked == null:
		return {}
	var here: StringName = world.region().zone_at(world.player_tile())
	var out: Dictionary = {
		&"grain_is_dear_here": here != &"" and ticked.grain_in(here) >= GRAIN_IS_DEAR,
		&"the_army_is_shrinking": ticked.army_strength < 90.0,
		&"hardship_is_high_here": here != &"" and ticked.hardship_in(here) >= HARDSHIP_BITES,
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
		# The offer to take a side, which exists while you have not taken one and
		# stops being offered the moment you do.
		#
		# It has to be *reactive* rather than standing, and that is not decoration:
		# the three-slot cap fills with standing lines in the order they were
		# written, so an offer authored last is an offer nobody is ever shown. The
		# same reason the rest of this table exists.
		&"nobody_has_your_name": allegiance == null or allegiance.side == FactionRules.NEUTRAL,
		# The four places' state (§8, 2026-09-13): what the person in front of you can
		# see out of the window. `frozen` is the two-day hold after a decisive act, and
		# the acts that would reverse it forbid it — refused by not being offered.
		&"this_place_is_free": allegiance != null and PlaceRules.has_state(here)
			and PlaceRules.is_free(allegiance.holder(here)),
		&"this_place_is_crown_held": allegiance != null and PlaceRules.has_state(here)
			and allegiance.holder(here) == FactionRules.CROWN,
		&"this_place_is_frozen": allegiance != null and here != &"" and allegiance.is_frozen(here, tick),
	}
	# And each place from anywhere, so Maddox can mention that the Acres went to the
	# smallholders three days after they did.
	for place: StringName in PlaceRules.PLACES:
		out[StringName("%s_is_free" % place)] = allegiance != null \
			and PlaceRules.is_free(allegiance.holder(place))
	return out


## Which of an NPC's authored options are legal right now.
static func available(
	npc: Npc,
	facts: FactBase,
	world_conditions: Dictionary = {},
	regard: float = 0.0,
	traits: Traits = null,
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
		# A line that leans on a trait is a line this character may not have in them.
		# §11's `tag` finally means something: it is the Fallout marker, and it gates.
		#
		# **This is not the progression check invariant 4 forbids.** Traits are chosen
		# once and never rise (§19 Q23), so nothing here opens because you did the
		# previous thing — it is the same kind of gate as being unwelcome in a town.
		# What keeps it legal is invariant 6: redundancy counts a trait-gated option
		# as gated, so no fact can end up behind one.
		if traits != null and option.needs_trait() != &"" \
				and not traits.speaks_with(option.needs_trait()):
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
## What saying this teaches, given what was actually on offer.
##
## **Takes the offered list rather than recomputing it** (2026-09-13). It used to call
## `available()` again with its own arguments, which meant two answers to "is this
## line on offer" that could disagree — and the moment `available()` learned about
## traits and this call did not, they did. The line was read aloud and taught nothing,
## which looks exactly like a fact failing to register and took an hour to find.
##
## One list, computed once by the caller, passed in. A parameter that has to be
## remembered in two places is a bug waiting for the next parameter.
static func verdict(option: DialogueOption, offered: Array[DialogueOption]) -> StringName:
	if option == null or not offered.has(option):
		return &""
	return option.teaches
