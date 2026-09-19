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


## **The quest's act at the furnaces, and what it takes to be offered** (Q4).
##
## Two gates, and they are different in kind. **Whose side you took** decides which
## direction the act goes — Tom's people put the fires out, Sena's relight them. **Having
## faced somebody** decides whether it is offered at all: §4's spine is *get in, face
## whoever stands in the way, act*, and the fight is not an addition to that, it is the
## middle of it. Walking through the gate straight to a furnace would leave a hole where
## the quest should be (Yannick, 2026-09-19).
##
## `&""` for anything else, and the site keeps whatever `deed_at` gives it.
##
## **The facing fact is written by F6**, which wires the fight into this. Until it does,
## the act is reachable in a test and not in play, which is the honest state to be in:
## the gate is built and the thing that opens it is not.
const FACED: StringName = &"cinderworks:faced_them"
const BROUGHT_THROUGH: StringName = &"cinderworks:brought_through"
const VOUCHED_FOR: StringName = &"cinderworks:vouched_for"


static func quest_deed_at(kind: StringName, facts: FactBase) -> StringName:
	if kind != &"kiln" or facts == null or not facts.has(FACED):
		return &""
	if facts.has(BROUGHT_THROUGH):
		return DeedRules.DEED_DOUSE
	if facts.has(VOUCHED_FOR):
		return DeedRules.DEED_RELIGHT
	return &""


## And its prompt. A verb and a thing, like every other one: the window never says what
## an act will cost.
static func quest_label_key(deed: StringName) -> StringName:
	match deed:
		DeedRules.DEED_DOUSE:
			return &"act.kiln.douse"
		DeedRules.DEED_RELIGHT:
			return &"act.kiln.relight"
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
