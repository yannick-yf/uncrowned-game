class_name ActSystem
extends SimSystem

## Doing something to a place.
##
## §3 lists how each power base can be weakened and every one of those levers is an
## act at a landmark. This is all of them: one event, one table (SiteRules), and the
## shared deed pipe. Adding a lever is a row, not a system.
##
## **A wrecked site stays wrecked.** Not a cooldown — a cold furnace is cold, and
## the six of them are why steel output can be driven to nothing by hand and no
## further. It is also legible: you can see which ones you have already done.

func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type != &"act":
		return
	var world := sim.store(&"world") as WorldState
	if world == null:
		return

	# Papers first: they lie on the ground and a landmark may be standing over them.
	if _take_papers(sim, world):
		return

	var site: Dictionary = world.region().nearest_site(world.player_tile(), SiteRules.REACH)
	if site.is_empty():
		return
	var at: Vector2i = site["at"] as Vector2i
	if world.spent_sites.has(at):
		return
	var deed: StringName = SiteRules.deed_at(site["kind"] as StringName)
	if deed == &"":
		return
	# A roused watch stands over what it guards. Not a failure and not a refusal to
	# be argued with — you simply cannot work at a post somebody is watching, and
	# the way past it is to let things go quiet.
	var ticked := sim.store(&"worldtick") as WorldTick
	var cast := sim.store(&"cast") as Cast
	var here_now: StringName = world.region().zone_at(world.player_tile())
	# A freed place has no watch: the crown's men left with the crown (§4's free
	# variant — the granary door open, no watchman).
	var mine := sim.store(&"allegiance") as Allegiance
	var unwatched: bool = mine != null and PlaceRules.is_free(mine.holder(here_now))
	if not unwatched and ticked != null and WatchRules.guarded_by(
			cast, world.current_zone, world.player_pos, ticked.alertness_in(here_now)) != &"":
		sim.derive(&"act_prevented", {"town": String(here_now)})
		return

	world.spent_sites[at] = true
	world.last_act_step = sim.step
	world.last_act = deed
	var where: StringName = world.region().zone_at(world.player_tile())
	world.last_act_seen = Deeds.perform(sim, deed, where, world.player_pos, &"act_unseen").size()


## Picking a document up. Reading it and holding it happen in the same movement —
## §7's Q24 says it is both, and there is no sense in which you could carry one
## without having looked at it.
##
## Nobody minds. It is not a theft: these are papers in a room, and the people who
## would care are not in the room. That may change when there are people in it.
func _take_papers(sim: Sim, world: WorldState) -> bool:
	var papers: Dictionary = world.region().nearest_document(
		world.player_tile(), DocumentRules.REACH)
	if papers.is_empty():
		return false
	var fact: StringName = papers["fact"] as StringName
	if world.holds(fact):
		return false
	world.documents.append(String(fact))
	world.last_taken = fact
	world.last_taken_step = sim.step
	sim.facts.add_source(fact, &"read")
	sim.derive(&"document_taken", {"fact": String(fact)})
	return true


## Nothing to do between ticks.
func steps() -> bool:
	return false


## Nothing to do on the world's clock.
func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"act"
