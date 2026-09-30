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
## **The gate taken by force** (V2, 2026-09-30): the gatekeeper and the three king's
## guards who answered him, all down. A third way in, beside being brought and vouched for.
const FORCED: StringName = &"cinderworks:forced"


## **Who puts themselves between the player and the furnaces** (F6). Whose side you
## took decides who that is: Tom's man is stopped by the foreman, Sena's by Tom himself,
## come to stop the shift.
##
## It is a fact about the quest rather than about a site, and it sits here because the
## quest's three facts already do. If a fourth arrives, they all move together.
static func stands_in_the_way(who: StringName, facts: FactBase) -> bool:
	if facts == null:
		return false
	if facts.has(BROUGHT_THROUGH):
		return who == &"harry"
	if facts.has(VOUCHED_FOR):
		return who == &"tom"
	# With the gate forced (V4), whoever comes for the act reached for: Tom for a furnace
	# lit, the quest's guards for one put out (V6).
	if facts.has(FORCED):
		return who == &"tom" or DuelRules.trade_of(who) == QUEST_GUARD
	return false


## The quest's guards, who come for a furnace put out once the gate is forced (V6): the
## swordsman leads, and two archers come with him.
const QUEST_GUARD: StringName = &"works_guard"
const QUEST_ARCHER: StringName = &"works_archer"


## **Who comes to stop this act** (F6, V4): the fighters a `duel_began` is sent against.
## Tom's side is stopped by the foreman, Sena's by Tom; with the gate forced, **putting a
## furnace out brings the quest's guards** — a sword and two bows, easy (V6) — and
## **lighting one brings Tom** (Yannick, 2026-09-30).
static func who_stops(deed: StringName, facts: FactBase) -> Array[StringName]:
	if facts == null:
		return []
	if facts.has(BROUGHT_THROUGH):
		return [&"harry"]
	if facts.has(VOUCHED_FOR):
		return [&"tom"]
	if facts.has(FORCED):
		if deed == DeedRules.DEED_RELIGHT:
			return [&"tom"]
		return [QUEST_GUARD, QUEST_ARCHER, QUEST_ARCHER]
	return []


## **Whether the one who came for this act has been beaten** (V4). On a side, having faced
## anybody is enough, as F6 built it. With the gate forced, `FACED` must name him among
## its sources: beating Tom for a cold furnace is not beating the guards for a burning one.
## Nobody left to send — Tom dead — is nobody to beat.
static func faced_for(deed: StringName, facts: FactBase, cast: Cast = null) -> bool:
	if facts == null:
		return false
	if not facts.has(FORCED) or facts.has(BROUGHT_THROUGH) or facts.has(VOUCHED_FOR):
		# On a side, having faced its man is enough — but the guards beaten at a furnace on
		# a forced run are nobody's side (the review of group V: beat them, take Sena's side,
		# and Tom never came).
		for source: StringName in facts.sources_of(FACED):
			if source != QUEST_GUARD:
				return true
		return false
	var first: StringName = who_stops(deed, facts)[0]
	if cast != null and cast.get_npc(first) != null and OpeningRules.is_gone(first, facts):
		return true
	return facts.sources_of(FACED).has(first)


## **What the furnaces offer, to somebody who got in.** Whose side you took decides the
## direction. Having faced anybody is **not** asked here — the prompt is there the moment
## you are inside, and reaching for it is what brings somebody out to stop you.
##
## That is Yannick's, 2026-09-19, and it is what the quest document always said: *Tom,
## **come** to stop the shift*. He arrives. Sending the player off to find him and pick a
## fight was the weaker half of F6 and it is gone.
##
## **And with the gate forced** (V3, Yannick 2026-09-30: *il peut faire ce qu'il veut avec
## les fours*): for somebody who took no side, a furnace that burns offers to be put out
## and a cold one to be lit. `site` is the site's row, or only its kind; `burning` is
## `burns`' answer for it.
static func quest_deed_at(site: Variant, facts: FactBase, burning: bool = true) -> StringName:
	var kind: StringName = (site as Dictionary).get("kind", &"") as StringName if site is Dictionary \
		else StringName(String(site))
	if kind != &"kiln" or facts == null:
		return &""
	if facts.has(BROUGHT_THROUGH):
		return DeedRules.DEED_DOUSE
	if facts.has(VOUCHED_FOR):
		return DeedRules.DEED_RELIGHT
	if facts.has(FORCED):
		return DeedRules.DEED_DOUSE if burning else DeedRules.DEED_RELIGHT
	return &""


## **One act, once, whichever it was** (Q4, V3): the works' story is told by the first.
static func works_story_told(facts: FactBase) -> bool:
	return facts != null and (facts.has(DeedRules.DEED_DOUSE) or facts.has(DeedRules.DEED_RELIGHT))


## **Whether a furnace burns**, as the window lights it (V3): the first of a place's
## furnaces, as many as its richesse pays for (`TownRules.lit_of`), counted in the order
## they stand (`Region.kiln_index`). Anything that is not a place's furnace burns.
static func burns(region: Region, towns: TownState, site: Dictionary) -> bool:
	if region == null or towns == null or (site.get("kind", &"") as StringName) != &"kiln":
		return true
	var at: Vector2i = site["at"] as Vector2i
	var place: StringName = region.zone_at(at)
	if not towns.has_state(place):
		return true
	return region.kiln_index(at) < TownRules.lit_of(region.kilns_in(place), towns.richesse_of(place))


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

## **And on its side of any wall** (the review of group V, 2026-09-30): the west furnaces
## are 2 tiles from the street through the yard's wall, and E put one out from outside —
## which undid the gate, force included. A site is within reach when a tile beside it can
## be walked to in `REACH_WALK` steps, which a wall between makes impossible.
const REACH_WALK: int = 3


static func within_reach(region: Region, tile: Vector2i, site: Dictionary) -> bool:
	if region == null or site.is_empty():
		return false
	var at: Vector2i = site["at"] as Vector2i
	var size: Vector2i = site.get("size", Vector2i(1, 1)) as Vector2i
	var walk: Dictionary = DuelRules.reachable(tile, region, REACH_WALK)
	for x: int in range(at.x - 1, at.x + size.x + 1):
		for y: int in range(at.y - 1, at.y + size.y + 1):
			if walk.has(Vector2i(x, y)):
				return true
	return false
