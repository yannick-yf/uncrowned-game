class_name CrimeRules
extends RefCounted

## Who saw it, and how far the story gets.


## How far a bystander can see something worth repeating.
const WITNESS_SIGHT: float = 9.0
## How close you must be to a stall to take from it.
const STALL_REACH: float = 1.8
## How long a robbed stall stays bare, in ticks — a quarter of an in-game day, or
## about ninety seconds of walking. Long enough that theft is a decision about
## where to be, short enough that it is not a punishment for having tried it.
const STALL_RESTOCK_TICKS: int = 360

## How fast a story travels, in tiles per in-game day. Harrowgate to Cairnwell is
## about 130 tiles, so word of a theft gets there in roughly three days — which is
## §8's first consequence, stated as a number.
const RUMOUR_TILES_PER_DAY: float = 45.0
## How far a story carries on its own — about as far as the next town, and no
## further. It used to be 220 tiles, which reached every town on the map unaided
## and left the road costing nothing: word arrived in Cairnwell whether the player
## took the King's Road or the Thornwood. Distance beyond a neighbour is covered by
## people now (TravelRules), which is what makes the two routes differ.
const RUMOUR_RANGE: float = 80.0

## What a deed does to whom now lives in DeedRules, with every other deed's, so
## that §8's counterpart rule can be checked in one place rather than inferred from
## five systems. This file keeps the geometry: who can see you, how far a story
## walks, how long a robbed stall stays bare.


## Everyone close enough to have seen it. Named cast only for now: the crowd has no
## sheets, and a witness has to be able to repeat the story to somebody.
static func witnesses_to(cast: Cast, zone: StringName, at: Vector2) -> PackedStringArray:
	var seen := PackedStringArray()
	if cast == null:
		return seen
	for npc: Npc in cast.in_zone(zone):
		if npc.centre().distance_to(at) <= WITNESS_SIGHT:
			seen.append(String(npc.id))
	return seen


## A crime nobody saw did not happen (§8). No witness, no rumour, no reputation.
static func is_worth_repeating(witnesses: PackedStringArray) -> bool:
	return witnesses.size() > 0


static func rumour_reach_per_tick() -> float:
	return RUMOUR_TILES_PER_DAY / float(Game.TICKS_PER_IN_GAME_DAY)
