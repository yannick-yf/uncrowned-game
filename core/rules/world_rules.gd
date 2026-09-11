class_name WorldRules
extends RefCounted

## How the world's quantities move. Pure.

## The escort, from army strength. Ten men at full strength, two when there is
## nothing left — §3's "bare handful" — and five at the strength a camp is left
## with once the pay fraud is public, which is the figure Phase 1 settled.
const ESCORT_AT_FULL: int = 10
const ESCORT_FLOOR: int = 2


static func escort_for(army_strength: float) -> int:
	var scaled: float = clampf(army_strength, 0.0, 100.0) * 0.08
	return clampi(ESCORT_FLOOR + roundi(scaled), ESCORT_FLOOR, ESCORT_AT_FULL)


## What the army settles at once the fraud is public and men have stopped arriving.
const ARMY_AFTER_FRAUD: float = 40.0
## The men already on the edge, who leave the night it becomes public. The rest
## drift away over the following days — that easing is consequence 5.
const ARMY_IMMEDIATE_LOSS: float = 25.0
## How fast the rest go, per in-game day.
const ARMY_DRIFT_PER_DAY: float = 12.0


static func army_target_for(fraud_exposed: bool) -> float:
	return ARMY_AFTER_FRAUD if fraud_exposed else 100.0


## How far any drifting quantity moves in one world tick — one in-game minute.
static func per_tick(per_day: float) -> float:
	return per_day / float(Game.TICKS_PER_IN_GAME_DAY)


## Ease `value` toward `target`, never overshooting it.
static func drift(value: float, target: float, per_day: float) -> float:
	var step: float = per_tick(per_day)
	if absf(target - value) <= step:
		return target
	return value + (step if target > value else -step)


# ------------------------------------------------------------------- grain ---

## How far from the Muster a deserter will carry his appetite.
const GRAIN_REACH_TILES: float = 90.0
## How much a town's grain can be pushed up by the army emptying out entirely.
const GRAIN_PRESSURE: float = 55.0
## And how fast it gets there — deliberately slower than the desertions causing it.
## At 5 a day the price finished climbing on day three, which tracks the army
## almost exactly and reads as the same event rather than its consequence. At 2.5
## it is still moving most of a week later, which is what §8's second consequence
## describes and what makes it feel like something the world worked out for itself.
const GRAIN_DRIFT_PER_DAY: float = 2.5
## How much of the pressure a town that was warned in time can absorb. It laid in
## stores before the deserters arrived, so the price still rises and rises less.
## Not 1.0: a warning is preparation, not a harvest, and a town that could be made
## immune would turn §8's second consequence off with one conversation.
const GRAIN_PREPARED_RELIEF: float = 0.45


## Share of the pressure a town takes, by how near the camp it is. Deserters walk
## to the nearest places that sell bread.
static func grain_share(town: StringName) -> float:
	var site: Vector2i = Region.zone_sites().get(town, Region.MUSTER) as Vector2i
	var distance: float = Vector2(site).distance_to(Vector2(Region.MUSTER))
	if distance >= GRAIN_REACH_TILES:
		return 0.0
	# Squared, so the falloff is gentle near the camp and sharp at the edge of it.
	# A straight line gave Harrowgate — seventy tiles out, and one of the two towns
	# the player actually lives in — a fifth of the pressure, which was not enough
	# to be noticed by anybody.
	var reach: float = distance / GRAIN_REACH_TILES
	return 1.0 - reach * reach


## Where a town's grain settles given how much of the army has gone.
##
## §8's first quantity now drifts on "mouths to feed" as well as season and supply:
## men who were issued food are buying it. This coupling is not a detail — it is
## the whole mechanism of consequence 2, the one where the world reacts to what the
## player broke without ever mentioning them.
static func grain_target_for(
	town: StringName,
	army_strength: float,
	prepared: bool = false,
) -> float:
	var gone: float = clampf((100.0 - army_strength) / 100.0, 0.0, 1.0)
	var relief: float = 1.0 - GRAIN_PREPARED_RELIEF if prepared else 1.0
	return 50.0 + GRAIN_PRESSURE * gone * grain_share(town) * relief
