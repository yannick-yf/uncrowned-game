class_name DuelFighter
extends RefCounted

## One person in a fight (K1 — `docs/COMBAT_V2.md`).
##
## **Everything is an integer.** A position is a tile of the world grid, health is a
## count, and the only thing on this object that is not an integer is who they are. A
## replay a week later stands them on the same tile.
##
## The player is a fighter like any other, under the id `DuelRules.PLAYER`. There is
## no party — the player fights alone — but the fight itself is written for a list,
## because *you can kill everyone* means drawing on three people in a yard, and a
## design with a hard-coded pair could not carry that.

var who: StringName = &""
var hp: int = 0
var max_hp: int = 0
var at: Vector2i = Vector2i.ZERO
var facing: Vector2i = Vector2i(0, 1)
## **Out of the fight.** Down, or walked out of it. Kept rather than removed from the
## list, so the turn order is stable and a replay walks the same indices.
var out: bool = false
## How they went: `&"down"` or `&"left"`, or `&""` while they are still in it.
var how_out: StringName = &""
## **Rounds ending with nobody in reach of them.** Out of reach is half of leaving and
## staying there is the other half, so this is what counts the staying. Reset the
## moment somebody is near again.
var away_rounds: int = 0
## Steps of flinch left. A blow does not move you (Yannick, 2026-09-24) — this is the
## whole of what being hit does to where you are, which is nothing.
var hurt_left: int = 0


func is_player() -> bool:
	return who == DuelRules.PLAYER


func alive() -> bool:
	return not out


func centre() -> Vector2:
	return Vector2(at) + Vector2(0.5, 0.5)


func fingerprint() -> String:
	return "%s@%d,%d/%d hp=%d away=%d%s" % [
		String(who), at.x, at.y, hurt_left, hp, away_rounds,
		"" if not out else "/" + String(how_out),
	]
