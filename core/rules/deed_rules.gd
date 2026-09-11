class_name DeedRules
extends RefCounted

## What a witnessed deed does to how people regard you.
##
## One table, because §8's counterpart rule is only checkable if every deed's
## effects are written in the same place: a change with no counterpart is not
## finished, and that is far easier to miss when each system carries its own
## arithmetic. Adding a row here is what adding a verb costs.
##
## Two sides to a deed and they resolve at different moments. **Factions move once,
## at the act** — a faction is not a place and cannot hear the same story eight
## times. **Towns move as the story arrives**, which is the delay §8's first
## consequence is made of.

const DEED_THEFT: StringName = &"i_stole_in_public"
const DEED_RESTITUTION: StringName = &"i_gave_it_back"
const DEED_WARNING: StringName = &"i_warned_the_town"

const FACTION_TOWNS: StringName = &"towns"
const FACTION_UNDERWORLD: StringName = &"the unlawful"
const FACTION_CROWN: StringName = &"the crown"


## What the town where the story lands thinks, once it lands.
##
## Theft costs more than a warning gains is *not* the shape here — the warning is
## worth more, and deliberately. Subtraction is free and available; if addition were
## also smaller, the arithmetic would teach the same lesson the gating did.
static func town_effect(deed: StringName) -> float:
	if deed == DEED_THEFT:
		return -22.0
	if deed == DEED_RESTITUTION:
		return 14.0
	if deed == DEED_WARNING:
		return 30.0
	return 0.0


## Who is offended and who is impressed — §8's hard rule, as data. Every deed names
## both, and a deed that names only one has not been finished.
static func faction_effects(deed: StringName) -> Dictionary:
	if deed == DEED_THEFT:
		return {FACTION_TOWNS: -11.0, FACTION_UNDERWORLD: 14.0}
	if deed == DEED_RESTITUTION:
		# More than the theft gained. A thief who gives things back is no use to
		# anybody, and the door that opened shuts harder than it opened.
		return {FACTION_TOWNS: 7.0, FACTION_UNDERWORLD: -18.0}
	if deed == DEED_WARNING:
		# Telling a town the king's army is rotting is sedition, whoever it helps.
		return {FACTION_TOWNS: 15.0, FACTION_CROWN: -25.0}
	return {}


## What somebody who *watched you do it* thinks, personally.
##
## Worse than what their town thinks, and better when it is good: seeing a thing
## is not hearing about it. Everyone else in the town moves with the town, because
## a town's opinion is the aggregate of the people in it — so the two track each
## other until somebody is standing there, and from then on that one person's
## opinion is their own.
static func witness_effect(deed: StringName) -> float:
	if deed == DEED_THEFT:
		return -30.0
	if deed == DEED_RESTITUTION:
		return 20.0
	if deed == DEED_WARNING:
		return 35.0
	return 0.0


## Whether the story goes anywhere, which is not the same as whether it mattered.
##
## A theft is worth repeating three days' walk away. So is a man standing in the
## square telling a town the king's army is rotting. Somebody quietly putting
## something back on a stall is not — it is news to the people who saw it and to
## nobody else, which is exactly why restitution repairs the place and not the past.
static func travels(deed: StringName) -> bool:
	return deed != DEED_RESTITUTION


## Deeds nobody performed do nothing, and a deed with no counterpart is a bug. Used
## by the test that walks every deed in the table.
static func all_deeds() -> Array[StringName]:
	return [DEED_THEFT, DEED_RESTITUTION, DEED_WARNING]
