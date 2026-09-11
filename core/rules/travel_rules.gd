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
## How close you have to pass for somebody to put your face to the story they
## heard in the last town. Generous — the road is open ground.
const RECOGNISE_RANGE: float = 7.0
