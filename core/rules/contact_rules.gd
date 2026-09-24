class_name ContactRules
extends RefCounted

## Pure. Is the king touching the player, and what does that cost?
##
## The three-touch death is CLAUDE.md's Phase 0 brief against §3's 10 HP player:
## 4 damage is the only integer that kills on the third touch and not the second.
## 10 → 6 → 2 → 0.

const CONTACT_RADIUS: float = 1.25
## Scaled with `WorldState.MAX_HP` when it went from ten to a hundred (2026-09-24).
## **`TOUCHES_TO_KILL` below is the claim** — three touches and you are dead — so this
## is a third of the bar rounded up, and changing the bar without changing this is how
## the king quietly stops being lethal.
const KING_DAMAGE: int = 34
const TOUCHES_TO_KILL: int = 3

## Half a second of grace, so standing in the king does not drain ten hit points
## in three frames. Three touches take about a second and a half.
const INVULNERABLE_SECONDS: float = 0.5


static func invulnerable_steps() -> int:
	return int(round(INVULNERABLE_SECONDS * float(Sim.STEPS_PER_REAL_SECOND)))


static func touching(a: Vector2, b: Vector2, radius: float = CONTACT_RADIUS) -> bool:
	return a.distance_to(b) <= radius


static func damage_after(hp: int, damage: int = KING_DAMAGE) -> int:
	return maxi(hp - damage, 0)


static func is_dead(hp: int) -> bool:
	return hp <= 0
