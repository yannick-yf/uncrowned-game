class_name CastleRules
extends RefCounted

## Blackcairn reads the kingdom (§4, 2026-09-13).
##
## The castle cannot be taken and has one state. What it carries instead is two
## **derived** readings, both legible from anywhere in the region: nothing here is
## stored, and nothing about an ending consults either. §8's rule applies — a change
## the player cannot perceive is identical to no change — so each reading has two
## channels: the castle's face for a player standing at it (§13), and what people in
## the towns say about it for a player who is not (§9).

# ----------------------------------------------------------------- wealth ---

## Scaffolding and new stone, or shuttered works and an unfinished wall.
const BUILDING: StringName = &"building"
const HOLDING: StringName = &"holding"
const SHUTTERED: StringName = &"shuttered"

## The kingdom starts at 100 on everything the castle is built from, so the castle
## starts building — that is the king's programme, and it is true. One large act
## against the treasury or the works takes it to holding; a ruin takes it to shuttered.
const RICH_FROM: float = 85.0
const POOR_BELOW: float = 45.0


## Grain supply as a score: 100 at the ordinary price, falling as bread gets dear.
static func supply_score(ticked: WorldTick) -> float:
	var total: float = 0.0
	for town: StringName in Region.ZONE_ORDER:
		total += ticked.grain_in(town)
	var average: float = total / float(maxi(Region.ZONE_ORDER.size(), 1))
	return clampf(150.0 - average, 0.0, 100.0)


## Crown treasury, steel output, grain supply — the three things a castle is built
## and fed from — read as one figure.
static func wealth_score(ticked: WorldTick) -> float:
	if ticked == null:
		return 0.0
	return (ticked.crown_treasury + ticked.steel_output + supply_score(ticked)) / 3.0


static func wealth(ticked: WorldTick) -> StringName:
	var score: float = wealth_score(ticked)
	if score >= RICH_FROM:
		return BUILDING
	if score < POOR_BELOW:
		return SHUTTERED
	return HOLDING


# ------------------------------------------------------------ instability ---

## Banners up and the gate open; more guards on the wall; banners down and the gate
## shut in daylight.
const CALM: StringName = &"calm"
const UNEASY: StringName = &"uneasy"
const CRISIS: StringName = &"crisis"

## How many places changing hands inside one freeze window is a crisis. Two: four
## towns flipping in a week is a crisis and the same four over a season is policy, and
## the window is the one §8 defined, not a second one.
const CRISIS_FROM: int = 2


## Flips inside the last window, by either path. To the men on the wall a flip is a
## flip, whoever caused it — recency is what makes this political rather than
## statistical, and it is the same window that holds a player's decision.
static func recent_flips(mine: Allegiance, tick: int) -> int:
	if mine == null:
		return 0
	var since: int = tick - PlaceRules.freeze_ticks()
	var count: int = 0
	for flip: Dictionary in mine.flips:
		if int(flip.get("tick", -1)) >= since:
			count += 1
	return count


static func instability(mine: Allegiance, tick: int) -> StringName:
	var recent: int = recent_flips(mine, tick)
	if recent >= CRISIS_FROM:
		return CRISIS
	if recent > 0:
		return UNEASY
	return CALM


## How many more men stand on the wall than the escort accounts for. Drawn, never
## fought: the escort is the number the endings read, and this is what the wall looks
## like from the road.
static func extra_guards(unrest: StringName) -> int:
	match unrest:
		CRISIS:
			return 4
		UNEASY:
			return 2
	return 0
