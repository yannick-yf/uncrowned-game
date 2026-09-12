class_name AllegianceSystem
extends SimSystem

## Joining a side, rising in it, and the ground changing hands.
##
## Three jobs, and they are here together because they are one idea: what the player
## *is*, what they have done for it, and what the map looks like as a result.
##
## **Nothing here gates anything.** Rank opens doors that were already open by other
## means — invariant 4 — and the highest crown rank is a second way through a gate
## Hesper could also grant, while the highest opposition rank is a second way to get a
## room to read in. Neither is the only way, so joining neither still leaves Force,
## and joining the crown and hunting the opposition to nothing leaves Force too.

func on_event(sim: Sim, event: SimEvent) -> void:
	var mine := sim.store(&"allegiance") as Allegiance
	if mine == null:
		return
	match event.type:
		&"join":
			_join(sim, mine, StringName(event.data.get("side", "")))
		&"leave":
			_leave(sim, mine)
		_:
			# Any event that names a deed, rather than the two event *types* a deed
			# usually raises: `Deeds.perform` takes the unseen event's name as a
			# parameter, so theft and the rest raise their own. Matching on the
			# payload catches every act instead of the two spelled here.
			if event.data.has("about"):
				_serve(sim, mine, StringName(event.data.get("about", "")))


func _join(sim: Sim, mine: Allegiance, side: StringName) -> void:
	if mine.join(side):
		sim.derive(&"joined", {"side": String(side), "turned": mine.turned})


func _leave(sim: Sim, mine: Allegiance) -> void:
	if mine.side == FactionRules.NEUTRAL:
		return
	var was: StringName = mine.side
	mine.side = FactionRules.NEUTRAL
	mine.served = 0.0
	mine.turned += 1
	sim.derive(&"left", {"side": String(was)})


## What a deed was worth to whoever the player joined.
##
## Read from the deed rather than from a quest list, so **every act already in the
## game counts as service without anything being authored twice**. It is also why
## the opposition needed no new acts: the deed table was already entirely theirs.
func _serve(sim: Sim, mine: Allegiance, deed: StringName) -> void:
	if mine.side == FactionRules.NEUTRAL or deed == &"":
		return
	var worth: float = FactionRules.worth_to(mine.side, deed)
	if worth <= 0.0:
		return
	var was: int = mine.rank()
	mine.served += worth
	if mine.rank() != was:
		sim.derive(&"rose", {"side": String(mine.side), "rank": mine.rank()})


## The ground changing hands, once per world tick.
##
## Only the two contested places move. The crown's eight points and the line between
## them are not up for grabs — you do not take Blackcairn by being disliked there —
## and the forest's ground was never his to lose. A border is what can move.
func on_tick(sim: Sim, _tick: int) -> void:
	var mine := sim.store(&"allegiance") as Allegiance
	var ticked := sim.store(&"worldtick") as WorldTick
	if mine == null or ticked == null:
		return
	for zone: StringName in FactionRules.CONTESTED:
		var was: StringName = mine.holder(zone)
		var now: StringName = FactionRules.holder_after(zone, was, ticked.sentiment_in(zone))
		if now != was:
			mine.owner_of[zone] = now
			sim.derive(&"ground_changed_hands", {"zone": String(zone), "to": String(now)})


func system_name() -> StringName:
	return &"allegiance"
