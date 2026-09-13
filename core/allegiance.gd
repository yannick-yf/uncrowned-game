class_name Allegiance
extends RefCounted

## What the player is, and who holds what.
##
## A store like any other, rebuilt by replay. It holds nothing the log does not.
##
## Joining is deliberately **not** standing. Standing is what a place thinks of you
## and it moves on its own; this is a thing you chose, it changes only when you say
## so, and everyone can see it (§8's appearance register). A crown officer can be
## despised in Harrowgate and still get through the gate at Blackcairn.

var side: StringName = FactionRules.NEUTRAL
## What the court last called you. Rank is *derived* — read off your side's standing
## by FactionRules.rank_from, never stored — and this remembers only the last reading
## so a change can be announced. Rebuilt by replay like everything else.
var last_rank: int = 0
## How many times the player has changed their mind. Not a cost yet; it is here
## because a game that lets you switch sides silently is one where the choice is free.
var turned: int = 0
var owner_of: Dictionary = {}
## **The freeze** (§8, 2026-09-13): zone -> the tick a player's decision holds until.
## While it holds, the band cannot move the place and the opposite decisive act is
## refused. A tick stamp, so a replay lands on the same tick in the same state.
var held_until: Dictionary = {}
## Zone -> the tick of the player's last decisive act there. The stamp *is* the
## handprint: a drift flip writes none, so a place with an entry here is a place the
## player decided, whichever way it now lies — which is what the entrance sign reads.
var decided_at: Dictionary = {}
## Every change of hands, by either path, oldest first: zone, to, tick, by_player.
## Blackcairn's instability reads how many and how recently (§4), and a flip is a flip
## to the men on the wall whoever caused it.
var flips: Array[Dictionary] = []


func _init() -> void:
	owner_of = FactionRules.holds_at_start()


## Take a side. Returns whether anything changed, so the caller knows whether to
## announce it. **One implementation**, called both by the event and by a line of
## dialogue, because two would drift and the one that drifted would be the one
## nobody tested.
func join(side: StringName) -> bool:
	if not FactionRules.SIDES.has(side) or side == self.side:
		return false
	if self.side != FactionRules.NEUTRAL:
		turned += 1
	self.side = side
	return true


func rank_with(standing: Standing) -> int:
	return FactionRules.rank_from(side, standing)


func rank_key_with(standing: Standing) -> StringName:
	return FactionRules.rank_key(side, rank_with(standing))


## Whether the player stands high enough for their side's last door to open. One of
## the ways in, never the only one (invariant 4): at high standing the gate opens
## because the guard knows your face; at low standing you climb the wall.
func door_is_open(standing: Standing) -> bool:
	return side != FactionRules.NEUTRAL and rank_with(standing) >= FactionRules.RANK_OPENS_THE_DOOR



## Whether a player's decision still holds here.
func is_frozen(zone: StringName, tick: int) -> bool:
	return tick < int(held_until.get(zone, 0))


func was_decided(zone: StringName) -> bool:
	return decided_at.has(zone)


## The player path (§8): a decisive act sets the state, stamps the tick and holds for
## the freeze window. Stamped even when the state does not change — enforcing the
## grants on a Wide Acres the crown already held is still the player deciding it stays
## so, and the sign says as much. Returns whether the state changed.
func decide(zone: StringName, to: StringName, tick: int) -> bool:
	var changed: bool = holder(zone) != to
	owner_of[zone] = to
	held_until[zone] = tick + PlaceRules.freeze_ticks()
	decided_at[zone] = tick
	if changed:
		flips.append({"zone": zone, "to": to, "tick": tick, "by_player": true})
	return changed


## The drift path: the band moved it, and no handprint is written.
func drift_to(zone: StringName, to: StringName, tick: int) -> void:
	owner_of[zone] = to
	flips.append({"zone": zone, "to": to, "tick": tick, "by_player": false})



func holder(zone: StringName) -> StringName:
	return owner_of.get(zone, FactionRules.NEUTRAL) as StringName


func zones_held_by(who: StringName) -> int:
	var count: int = 0
	for zone: StringName in owner_of.keys():
		if owner_of[zone] == who:
			count += 1
	return count


func fingerprint() -> String:
	var zones: Array = owner_of.keys()
	zones.sort()
	var held := PackedStringArray()
	for zone: StringName in zones:
		held.append("%s:%s" % [zone, owner_of[zone]])
	var stamps := PackedStringArray()
	for zone: StringName in zones:
		if decided_at.has(zone) or held_until.has(zone):
			stamps.append("%s@%d<%d" % [zone, int(decided_at.get(zone, -1)), int(held_until.get(zone, 0))])
	return "side=%s rank=%d turned=%d flips=%d | %s | %s" % [
		side, last_rank, turned, flips.size(), ";".join(held), ";".join(stamps)]
