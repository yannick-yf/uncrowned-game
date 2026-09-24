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


## What a witnessed deed does to the town it was done in.
##
## **The numbers are still the old table's** (J2). This task moved the *routing* — a
## deed moves the place it happened in, once, where it happened — and **J3** is where
## the scale itself is settled: a theft at about −10, killing somebody innocent at
## about −80, and the distinction between a bystander and a man who drew on you first.
## Delegating until then keeps one set of numbers in the game rather than two, and
## leaves J3 with exactly the work its entry describes.
static func standing_effect(deed: StringName) -> float:
	return DeedRules.town_effect(deed)
