class_name BeastRules
extends RefCounted

## What lives in the wild, how fast it is, and what it costs you.
##
## Pure. SPECS §4: everything off the road "is slower, holds wild animals and
## monsters, and is unwatched". Stage 3 is the second clause.

const KINDS: Array[StringName] = [&"bear", &"spider", &"bat"]

## Beasts are all slower than the player's 6 tiles/sec. A predator you cannot
## outrun is not a risk, it is a tax — the wild has to be survivable by running.
const SPEEDS: Dictionary = {&"bear": 4.2, &"spider": 5.2, &"bat": 5.6}
const DAMAGE: Dictionary = {&"bear": 2, &"spider": 1, &"bat": 1}
const SIGHT: Dictionary = {&"bear": 11.0, &"spider": 13.0, &"bat": 14.0}

const CONTACT_RADIUS: float = 0.9
## How often a wandering beast picks a new direction, in seconds.
const DRIFT_SECONDS: float = 2.0

const MAX_NEARBY: int = 4
const SPAWN_MIN_TILES: float = 18.0
const SPAWN_MAX_TILES: float = 26.0
const DESPAWN_TILES: float = 34.0
## One spawn attempt every half second; the cap does the rest of the limiting.
const SPAWN_EVERY_STEPS: int = 45
## Half-angle of the arc ahead of the walker that a beast may appear in.
const SPAWN_ARC: float = 1.2
## How far a beast will wander from where it lives before turning back.
const HOME_RANGE: float = 9.0

const FACT_WILD_IS_DANGEROUS: StringName = &"the_wild_bites"


static func speed_for(kind: StringName) -> float:
	return float(SPEEDS.get(kind, 4.0))


static func damage_for(kind: StringName) -> int:
	return int(DAMAGE.get(kind, 1))


static func sight_for(kind: StringName) -> float:
	return float(SIGHT.get(kind, 10.0))


## Where a beast may stand — and therefore where it may walk.
##
## Not the road, and not a settlement. §4 calls the King's Road patrolled, and
## that is what patrolled means: the animals keep off it. It is also what makes
## the road *safe* rather than merely long, which is the whole of the choice now
## that the ground no longer slows anyone down.
static func is_wild_ground(terrain: Region.Terrain) -> bool:
	match terrain:
		Region.Terrain.WILD, Region.Terrain.FOREST, Region.Terrain.MARSH:
			return true
	return false


## Thicker cover, more of them: the Thornwood is where the danger lives.
static func kind_for(terrain: Region.Terrain, roll: int) -> StringName:
	if terrain == Region.Terrain.FOREST:
		return KINDS[roll % KINDS.size()]
	return KINDS[1 + roll % 2]
