class_name DuelPlayer
extends RefCounted

## A hand on the keys, for a turn-based fight that is being **played** headless — by
## `tools/play_duel.gd`, by the suite, and by `UNCROWNED_DUEL`.
##
## It submits what a keyboard would: **one `duel_turn` per turn**, and only when the
## fight is actually waiting on the player. That is the whole contract — a fight of
## twenty turns is twenty events whether a person or this played it.
##
## Four hands, and none of them is clever. They exist so that a picture can be taken of
## a particular thing happening — a blow, a retreat, the end — rather than of whatever
## a random press produced.
##
## Lives in `tools/` and not in `core/` on purpose: it decides nothing about the rules,
## it only presses. Nothing in the game loads it.

## Closes and strikes, by the same rule an opponent uses. The fight fights itself.
const PRESS: StringName = &"press"
## Strikes whatever is already in reach and otherwise stands still.
const HOLD: StringName = &"hold"
## Does nothing at all, ever. For watching an opponent work.
const STAND: StringName = &"stand"
## **Walks out of the fight.** As far from the nearest enemy as a turn buys, every
## turn, and never a blow — which is the thing nothing in this design prevents.
const LEAVE: StringName = &"leave"

var policy: StringName = PRESS


func _init(p_policy: StringName = PRESS) -> void:
	policy = p_policy if p_policy != &"" else PRESS


## One look at the fight. Submits a turn if it is the player's and the fight is waiting
## on them, and does nothing otherwise — so it can be called every step without
## flooding the log.
func play(sim: Sim, duel: Duel) -> bool:
	if duel == null or not duel.waiting_on_player():
		return false
	var world := sim.store(&"world") as WorldState
	if world == null:
		return false
	var mine: DuelFighter = duel.acting_fighter()
	var foes: Array[DuelFighter] = duel.foes_of(mine.who)
	sim.submit(&"duel_turn", _turn(mine, foes, world.region(), duel))
	return true


func _turn(mine: DuelFighter, foes: Array[DuelFighter], region: Region, duel: Duel) -> Dictionary:
	var standing: Dictionary = {
		"who": String(mine.who), "to_x": mine.at.x, "to_y": mine.at.y,
		"action": String(DuelRules.WAIT), "target": "",
	}
	if foes.is_empty():
		return standing
	match policy:
		STAND:
			return standing
		HOLD:
			for foe: DuelFighter in foes:
				if DuelRules.in_reach(mine.at, foe.at):
					standing["action"] = String(DuelRules.STRIKE)
					standing["target"] = String(foe.who)
					break
			return standing
		LEAVE:
			var away: Vector2i = _furthest(mine, foes, region, duel)
			standing["to_x"] = away.x
			standing["to_y"] = away.y
			return standing
	var chosen: Dictionary = DuelRules.decide(mine, foes, region, duel.began_at, _taken(duel, mine))
	var to: Vector2i = chosen["to"] as Vector2i
	return {
		"who": String(mine.who), "to_x": to.x, "to_y": to.y,
		"action": String(chosen["action"] as StringName),
		"target": String(chosen["target"] as StringName),
	}


func _furthest(mine: DuelFighter, foes: Array[DuelFighter], region: Region, duel: Duel) -> Vector2i:
	var cost: Dictionary = DuelRules.reachable(
		mine.at, region, DuelRules.tiles_per_turn(), _taken(duel, mine))
	var best: Vector2i = mine.at
	var gap: int = _nearest(mine.at, foes)
	for key: Variant in cost.keys():
		var tile: Vector2i = key as Vector2i
		var here: int = _nearest(tile, foes)
		# Ties broken north to south and west to east, as everything in the rules is,
		# so the same retreat is walked twice.
		if here > gap or (here == gap and _before(tile, best)):
			gap = here
			best = tile
	return best


static func _before(a: Vector2i, b: Vector2i) -> bool:
	if a.y != b.y:
		return a.y < b.y
	return a.x < b.x


static func _nearest(tile: Vector2i, foes: Array[DuelFighter]) -> int:
	var best: int = 1 << 20
	for foe: DuelFighter in foes:
		best = mini(best, DuelRules.apart(tile, foe.at))
	return best


static func _taken(duel: Duel, but: DuelFighter) -> Dictionary:
	var out: Dictionary = {}
	for fighter: DuelFighter in duel.fighters:
		if fighter == but or not fighter.alive():
			continue
		out[fighter.at] = true
	return out
