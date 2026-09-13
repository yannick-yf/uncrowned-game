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
		&"document_read":
			# Read aloud in the place it is about, and the place goes free (§3).
			var read_in: StringName = StringName(event.data.get("town", ""))
			if PlaceRules.frees(read_in, StringName(event.data.get("fact", ""))):
				_decide(sim, mine, read_in, FactionRules.OPPOSITION)
		&"fraud_exposed":
			# The Muster's thing is the fraud in its rolls; exposed at the camp, the camp
			# empties, and the place is free.
			_decide(sim, mine, &"muster", FactionRules.OPPOSITION)
		_:
			# Any event that names a deed, rather than the two event *types* a deed
			# usually raises: `Deeds.perform` takes the unseen event's name as a
			# parameter, so theft and the rest raise their own. Matching on the
			# payload catches every act instead of the two spelled here.
			if event.data.has("about"):
				var about: StringName = StringName(event.data.get("about", ""))
				_serve(sim, mine, about)
				# The same thing spent the crown's way, in the place, holds it.
				var holds: StringName = PlaceRules.held_by(about)
				if holds != &"" and StringName(event.data.get("town", "")) == holds:
					_decide(sim, mine, holds, FactionRules.CROWN)


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


## The player path of §8's two: a decisive act sets a place's state directly, stamps
## the tick, and holds it for the freeze window. The acts that reach here are refused
## upstream while a place is held — the option is not offered, the document is not
## tellable, the fraud cannot be exposed — so a frozen place arriving here is the case
## that should not happen, and it is recorded rather than hidden.
func _decide(sim: Sim, mine: Allegiance, zone: StringName, to: StringName) -> void:
	if not PlaceRules.has_state(zone):
		return
	if mine.is_frozen(zone, sim.tick):
		sim.derive(&"place_held", {"zone": String(zone), "wanted": String(to)})
		return
	var changed: bool = mine.decide(zone, to, sim.tick)
	sim.derive(&"place_decided", {
		"zone": String(zone), "to": String(to), "changed": changed, "tick": sim.tick,
	})


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


## The ground changing hands, once per world tick, by drift.
##
## Only the two borders move this way. The other places with a state — the works, the
## camp, the bank — move only by the player's hand (PlaceRules): a Cinderworks that
## went free on a bad week of bread would be a power base falling to weather. You do
## not take Blackcairn by being disliked there, and the forest's ground was never his.
func on_tick(sim: Sim, tick: int) -> void:
	var mine := sim.store(&"allegiance") as Allegiance
	var ticked := sim.store(&"worldtick") as WorldTick
	if mine == null or ticked == null:
		return
	for zone: StringName in FactionRules.CONTESTED:
		# The drift path (§8). During a player's hold the band cannot move it back;
		# after, both paths apply again and a freed Wide Acres whose town swings above
		# the line goes back to the crown, exactly as v1 would have moved it.
		if mine.is_frozen(zone, tick):
			continue
		var was: StringName = mine.holder(zone)
		var now: StringName = FactionRules.holder_after(zone, was, ticked.sentiment_in(zone))
		if now != was:
			mine.drift_to(zone, now, tick)
			sim.derive(&"ground_changed_hands", {"zone": String(zone), "to": String(now)})


## Nothing to do between ticks.
func steps() -> bool:
	return false


func system_name() -> StringName:
	return &"allegiance"
