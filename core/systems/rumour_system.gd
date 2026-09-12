class_name RumourSystem
extends SimSystem

## How word gets about.
##
## A rumour starts where the deed was, spreads outward at a walking pace, and
## moves the player's standing in each town as it *arrives* — not when it started.
## That delay is §8's first consequence: the story reaches Cairnwell before you do.
##
## Nothing here tells the player anything. The world changes its mind quietly and
## the journal explains it later if asked — push the ambient, pull the attribution.

func on_event(sim: Sim, event: SimEvent) -> void:
	# One pipe for every witnessed deed, whatever its sign. Theft, restitution and
	# a warning all travel the same way and differ only in what DeedRules says they
	# do on arrival — which is what makes "the exact mirror of theft" true in the
	# code and not only in the design note.
	if event.type != &"deed_witnessed":
		return
	var rumours := sim.store(&"rumours") as Rumours
	if rumours == null:
		return
	var witnesses := PackedStringArray()
	for name: Variant in (event.data.get("witnesses", []) as Array):
		witnesses.append(String(name))
	var about: StringName = StringName(event.data.get("about", ""))
	var where: StringName = StringName(event.data.get("town", ""))
	var rumour: Rumour = rumours.start(about, where, witnesses, sim.step)
	# It is already known where it happened: the witnesses are standing there.
	_arrive(sim, rumour, where)
	# Some deeds are news and some are only true. One that nobody will repeat has
	# already done everything it is going to do, here, and never leaves.
	if not DeedRules.travels(about):
		rumours.live.erase(rumour)


func on_tick(sim: Sim, _tick: int) -> void:
	var world := sim.store(&"world") as WorldState
	var rumours := sim.store(&"rumours") as Rumours
	if world == null or rumours == null or rumours.live.is_empty():
		return

	var still_going: Array[Rumour] = []
	for rumour: Rumour in rumours.live:
		rumour.reach += CrimeRules.rumour_reach_per_tick()
		var from: Vector2i = Region.zone_sites().get(rumour.origin, Region.HARROWGATE) as Vector2i
		for town: StringName in Region.ZONE_ORDER:
			if rumour.has_reached(town):
				continue
			var to: Vector2i = Region.zone_sites()[town] as Vector2i
			if Vector2(from).distance_to(Vector2(to)) <= rumour.reach:
				_arrive(sim, rumour, town)
		if rumour.reach < CrimeRules.RUMOUR_RANGE:
			still_going.append(rumour)
	rumours.live = still_going


## The story gets somewhere, and somebody's opinion changes.
func _arrive(sim: Sim, rumour: Rumour, town: StringName) -> void:
	deliver(sim, rumour, town, false)


## Shared with the traveller system, which is the other way a story gets somewhere.
## `carried` only changes what the journal says: a story that walked up the road
## with somebody is attributed to the road, and one that simply spread is not.
static func deliver(sim: Sim, rumour: Rumour, town: StringName, carried: bool) -> void:
	if rumour.has_reached(town):
		return
	rumour.arrived[town] = true
	var standing := sim.store(&"standing") as Standing
	if standing == null:
		return

	# Only the town, and the people in it. The factions moved once, where the deed
	# happened — they are not places and cannot hear the same story eight times.
	var effect: float = DeedRules.town_effect(rumour.about)
	standing.shift_town(town, effect)
	_town_hears(sim, rumour, town, effect)
	# And what it does to how they regard *him*, which is a different number from
	# how they regard you and the one §3's `discredited` ending counts.
	var about_the_crown: float = DeedRules.sentiment_on_arrival(rumour.about)
	if about_the_crown != 0.0:
		var ticked := sim.store(&"worldtick") as WorldTick
		if ticked != null:
			ticked.push_sentiment(town, about_the_crown)
	sim.derive(&"rumour_arrived", {
		"town": String(town),
		"about": String(rumour.about),
		"carried": carried,
		"days": float(sim.step - rumour.started_step)
			/ float(Sim.STEPS_PER_WORLD_TICK * Game.TICKS_PER_IN_GAME_DAY),
	})


## The people who live there, who heard it rather than saw it.
##
## A town's opinion is the aggregate of the people in it, so residents move with
## their town by default. Anyone who actually watched the deed is skipped — theirs
## already moved, further, at the moment it happened, and adding this on top would
## count the same event against them twice.
static func _town_hears(sim: Sim, rumour: Rumour, town: StringName, effect: float) -> void:
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	var standing := sim.store(&"standing") as Standing
	if world == null or cast == null or standing == null:
		return
	var region: Region = world.region()
	for npc: Npc in cast.in_zone(WorldState.OVERWORLD):
		if region.zone_at(npc.tile) != town:
			continue
		if rumour.witnesses.has(String(npc.id)):
			continue
		standing.shift_person(npc.id, effect)


func system_name() -> StringName:
	return &"rumour"
