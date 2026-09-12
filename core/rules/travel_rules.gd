class_name TravelRules
extends RefCounted

## Who is on the road, and what seeing you is worth.
##
## §18's proof for Phase 3 says the wild becomes a real choice "because the slow
## dangerous track through the trees is now the one nobody can report you on". That
## was not true: a rumour spread as a uniform circle at a fixed speed, so it reached
## every town on the map whichever way the player walked, and the road cost nothing.
##
## Travellers are the road's postal service. They are furniture, not people — no
## name, no home, no routine, no opinion of anybody. What they do is recognise the
## person a story is about and carry that story to the next town they walk into.

## How many walk the King's Road at once. Small on purpose: they are simulated for
## the whole map all the time rather than spawned around the player, because a
## carrier who vanishes when you look away cannot deliver anything.
const ON_THE_ROAD: int = 6
## Tiles per second, against the player's six. Visibly slower — you overtake them,
## which is the point: you can outrun word, and you cannot stop it being carried.
const WALK_SPEED: float = 2.4
## How close you have to pass for somebody to put your face to the story they heard
## in the last town, on a quiet road.
const RECOGNISE_RANGE: float = 7.0
## And on a road the crown has been moving men about on. §8's fourth quantity,
## patrol density, rises with crime reports and until now nothing read it — the same
## defect its neighbour had. This is what reads it: **the more the crown has heard
## about, the harder it is to pass along the King's Road unremarked.**
##
## Deliberately the same shape as WatchRules.sight_for. Two quantities, two dials on
## how hard it is to go unnoticed — one for the places you act in, one for the road
## between them — and both push the player the same way, toward the trees.
const RECOGNISE_RANGE_PATROLLED: float = 14.0


static func recognise_range_for(patrol_density: float) -> float:
	var busy: float = clampf(patrol_density, 0.0, 100.0) / 100.0
	return RECOGNISE_RANGE + (RECOGNISE_RANGE_PATROLLED - RECOGNISE_RANGE) * busy
