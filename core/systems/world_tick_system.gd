class_name WorldTickSystem
extends SimSystem

## The world running without anybody. §8's coarse clock, once per in-game minute.
##
## Nothing here reads the player. That is the point of consequence 5: the
## desertions you started keep going while you are somewhere else, and the world
## you come back to is not the one you left.

func on_tick(sim: Sim, _tick: int) -> void:
	var world := sim.store(&"world") as WorldState
	var ticked := sim.store(&"worldtick") as WorldTick
	if world == null or ticked == null:
		return

	var before: int = ticked.kings_escort()
	var was: float = ticked.army_strength
	ticked.army_strength = WorldRules.drift(
		ticked.army_strength, ticked.army_target, WorldRules.ARMY_DRIFT_PER_DAY)

	# Announce the change rather than leaving it to be noticed. A derived event is
	# how the rest of the world — and later the journal — finds out.
	var after: int = ticked.kings_escort()
	if after != before:
		sim.derive(&"escort_changed", {"from": before, "to": after})

	# Announced on whole points, so the rest of the world can react to the army
	# shrinking without the log carrying an event every in-game minute.
	if floori(ticked.army_strength) != floori(was):
		sim.derive(&"army_fell", {"to": ticked.army_strength})

	# The wood gets smaller, at the rate the furnaces are running. Drift, not a
	# deed: it moves the world and writes no handprint, so it can never end
	# anything (§8's hard rule). Put the furnaces out and it stops.
	var held_was: float = ticked.held_ground
	ticked.held_ground = WorldRules.held_ground_after(ticked.held_ground, ticked.steel_output)
	if floori(ticked.held_ground) != floori(held_was):
		sim.derive(&"wood_lost", {"to": ticked.held_ground})


## Nothing to do between ticks.
func steps() -> bool:
	return false


func system_name() -> StringName:
	return &"worldtick"
