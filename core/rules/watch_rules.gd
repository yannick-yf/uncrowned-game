class_name WatchRules
extends RefCounted

## The men paid to stand there and notice things.
##
## Before this, eight of the ten levers on the map stood in places with no cast in
## them at all, so wrecking a furnace or burning a winter's stores cost the player
## precisely nothing: no witness, no story, no standing, and a watch that never
## woke. The endings were reachable by walking to ten places and touching each.
##
## **A roused watch looks harder.** §8's fifth quantity, guard alertness, was an
## input with no output — built and read by nothing, which is the same defect the
## twelve quantities had one level up. It is what this reads: the more the watch has
## heard about lately, the further a watchman can see, so the second furnace is
## harder to put out than the first and the tenth is very hard indeed.

## What a watchman sees on a quiet day, against a townsman's nine tiles. They are
## posted to look, so they start ahead.
const SIGHT_CALM: float = 11.0
## And at the top of the scale, having heard about everything you have done.
const SIGHT_ROUSED: float = 18.0


## How far this watchman can see, given how awake the watch is.
##
## Linear between the two, because the player has to be able to *feel* it tighten —
## a curve would make the change hard to read and the whole point is that it is
## something you notice pushing back.
static func sight_for(alertness: float) -> float:
	var awake: float = clampf(alertness, 0.0, 100.0) / 100.0
	return SIGHT_CALM + (SIGHT_ROUSED - SIGHT_CALM) * awake


## Above this the watch is not merely present but paying attention, and a post it
## can see is a post you cannot work at.
##
## This is the teeth. Widening a watchman's sight only changes what a deed *costs*
## once it is done, and measured on the shipped map it barely changed the witness
## count at all — the posts are close to what they guard. Refusing the act is what
## makes a roused watch something the player has to wait out, and it gives the phase
## its rhythm: act, lie low, act again. It needs no combat to hurt.
const WATCHING_FROM: float = 70.0


## Whether this watchman is standing over that spot, awake enough to stop you.
static func is_guarding(npc: Npc, at: Vector2, alertness: float) -> bool:
	if not is_watchman(npc) or alertness < WATCHING_FROM:
		return false
	return npc.centre().distance_to(at) <= sight_for(alertness)


## Anybody standing over this spot, or "" if the watch is elsewhere or half asleep.
## `alertness` is the figure for the town the act is in, not a regional one — the
## watch in the Wide Acres has never heard of the Cinderworks.
static func guarded_by(cast: Cast, zone: StringName, at: Vector2, alertness: float) -> StringName:
	if cast == null:
		return &""
	for npc: Npc in cast.in_zone(zone):
		if is_guarding(npc, at, alertness):
			return npc.id
	return &""


static func is_watchman(npc: Npc) -> bool:
	return npc != null and npc.kind == &"watchman"
