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
	if ticked != null and WatchRules.guarded_by(
			cast, world.current_zone, world.player_pos, ticked.alertness_in(here_now)) != &"":
		sim.derive(&"act_prevented", {"town": String(here_now)})
		return

	world.spent_sites[at] = true
	world.last_act_step = sim.step
	world.last_act = deed
	var where: StringName = world.region().zone_at(world.player_tile())
	world.last_act_seen = Deeds.perform(sim, deed, where, world.player_pos, &"act_unseen").size()


func system_name() -> StringName:
	return &"act"
