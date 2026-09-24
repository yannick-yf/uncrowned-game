class_name PlayerRules
extends RefCounted

## What a deed costs the player, in the town it happened in.
##
## `docs/PLAYER_MODEL.md` §1: **the town is the unit of account.** A deed moves the
## standing of the *place* it happened in. It does not move the opinion of the person
## it happened to — a per-person ledger is a second economy to balance and the player
## cannot see it, where they can see a town turn cold.
##
## This is a new table beside `DeedRules`' four, not a rewrite of them. `DeedRules`
## carries the old model's arithmetic — a faction's regard, a witness's own opinion, a
## town's opinion as a story arrives — and all of it goes with **C3**. Until then the
## two run side by side, which is `DEMO_TASKS.md`'s rule 4: build beside, delete
## nothing.

## **The two ends of the scale, and Yannick set them both** (§3, 2026-09-23). The scale
## itself is the existing one, −100 to +100.
##
## The gap is the design: **ten thefts and you are hated in one town; one murder and
## you are nearly there in a single afternoon.** It also says something true about the
## game — the player who takes things is a nuisance, and the player who kills is
## something else.
const A_THEFT: float = -10.0
const A_MURDER: float = -80.0

## Putting it back. Less than the theft cost, so restitution is repair and not a reset:
## the same proportion of the theft it undoes that the old table held, 14 against 22.
const A_RESTITUTION: float = 6.0

## **Killing somebody who drew on you first is a different deed** (§3, and the whole of
## J3). Not free — there is still a body in the street and the town has to live with a
## man who leaves them — but a quarter of the murder, because everyone standing there
## saw who reached for a blade first.
##
## Yannick set the two ends and not this one; it is the first number in the model that
## is ours, and it is the obvious one for him to move.
const A_KILLING_IN_SELF_DEFENCE: float = -20.0

## **What *innocent* means, as two ids rather than as a judgement made at the moment of
## the blow.** The distinction has to be in the deed, because the town's opinion is the
## only place it can show, and a single `i_killed_somebody` would have to guess.
##
## They live here rather than in `DeedRules` on purpose: that file's docstring promises
## every deed's effects are written in one place, and these have no faction row, no
## witness row and no hardship row — the old model's three columns, all of which go
## with C3. They are the new model's deeds and this is the new model's table.
const DEED_KILLED_INNOCENT: StringName = &"i_killed_somebody_innocent"
const DEED_KILLED_ATTACKER: StringName = &"i_killed_a_man_who_drew_first"


## What a witnessed deed does to the town it was done in.
##
## Anything this table does not name keeps the old model's number until **C3** takes
## the old model out. That is deliberate rather than lazy: the twenty-four acts against
## the six power bases are on their way out, re-pricing them on the new scale would be
## work thrown away, and dropping them to zero would quietly remove every way a town's
## opinion of you can go **up** — which is the exact defect §8's Q38 was raised about.
static func standing_effect(deed: StringName) -> float:
	if deed == DeedRules.DEED_THEFT:
		return A_THEFT
	if deed == DeedRules.DEED_RESTITUTION:
		return A_RESTITUTION
	if deed == DEED_KILLED_INNOCENT:
		return A_MURDER
	if deed == DEED_KILLED_ATTACKER:
		return A_KILLING_IN_SELF_DEFENCE
	return DeedRules.town_effect(deed)


## The deeds the new model prices itself, walked by a test so that one added without a
## number fails rather than quietly falling through to the old table.
static func priced_deeds() -> Array[StringName]:
	return [
		DeedRules.DEED_THEFT, DeedRules.DEED_RESTITUTION,
		DEED_KILLED_INNOCENT, DEED_KILLED_ATTACKER,
	]


## The two killings, so nothing has to spell the ids out to tell them apart.
static func is_a_killing(deed: StringName) -> bool:
	return deed == DEED_KILLED_INNOCENT or deed == DEED_KILLED_ATTACKER
