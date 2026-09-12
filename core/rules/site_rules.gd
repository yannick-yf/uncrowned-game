class_name SiteRules
extends RefCounted

## What can be done to a place, and where.
##
## §3 lists how each of the king's six power bases can be weakened, and none of it
## was built: every one of those levers is an **act at a landmark**, not a
## conversation. This is the table that says which landmark offers which act, and it
## is the reason the ten inert quantities finally have inputs that are not somebody
## else's dialogue.
##
## Not built here, and why: **Greyhold has no location** — §3 names it a power base
## and §4's eight zones do not include it (§19). Anything needing a **kill** waits
## for Phase 4's combat screen, and anything needing **money** waits for §12's
## economy, which is still a bare TBD.

## Landmark kind -> the deed done to it.
static func deed_at(kind: StringName) -> StringName:
	match kind:
		&"kiln":
			return DeedRules.DEED_SABOTAGE
		&"granary":
			return DeedRules.DEED_BURN_STORES
		&"counting_house":
			return DeedRules.DEED_ROB_BANK
		&"muster_rolls":
			return DeedRules.DEED_WRECK_ROLLS
	return &""


static func is_site(kind: StringName) -> bool:
	return deed_at(kind) != &""


## Which line the prompt should use. A verb and a thing, never a consequence: the
## world shows, the journal explains (§8), and the HUD never says what an act will
## cost (§15). The words themselves belong to the window.
static func label_key(kind: StringName) -> StringName:
	match kind:
		&"kiln":
			return &"act.kiln"
		&"granary":
			return &"act.granary"
		&"counting_house":
			return &"act.counting_house"
		&"muster_rolls":
			return &"act.muster_rolls"
	return &""


## How close you must be, measured to the building's footprint rather than to its
## corner — the same lesson the market stalls taught (§20, 2026-09-11).
const REACH: float = 2.4
