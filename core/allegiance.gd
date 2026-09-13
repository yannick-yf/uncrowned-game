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
## Work done for whoever you joined. Rank is read off it rather than stored, so
## there is one number to replay and no way for the two to disagree.
var served: float = 0.0
## How many times the player has changed their mind. Not a cost yet; it is here
## because a game that lets you switch sides silently is one where the choice is free.
var turned: int = 0
var owner_of: Dictionary = {}


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
	# Service does not carry across. What you did for the other side is not work they
	# owe you for, and a player who could bank it would join both in turn.
	served = 0.0
	return true


func rank() -> int:
	return FactionRules.rank_for(side, served)


func rank_key() -> StringName:
	return FactionRules.rank_key(side, rank())


## Whether the player has risen far enough for their side's last door to open.
func door_is_open() -> bool:
	return side != FactionRules.NEUTRAL and rank() >= FactionRules.RANK_OPENS_THE_DOOR


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
	return "side=%s served=%.2f rank=%d turned=%d | %s" % [
		side, served, rank(), turned, ";".join(held)]
