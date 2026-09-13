class_name GrainSystem
extends SimSystem

## Bread, and who is buying it.
##
## The second consequence of §8, and the first place one system answers another:
## the army empties out, the men who were issued food start buying it, and a week
## later bread costs more in the towns nearest the camp. Nobody mentions the player.
## Nobody thanks them.
##
## It listens for a derived event rather than reading army strength directly. That
## is the point of the split — the world telling itself something happened — and it
## is what lets a journal later say *why* the price moved.

func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type != &"army_fell":
		return
	var ticked := sim.store(&"worldtick") as WorldTick
	if ticked == null:
		return
	for town: StringName in Region.ZONE_ORDER:
		ticked.grain_target[town] = WorldRules.grain_target_for(
			town, ticked.army_strength, bool(ticked.prepared.get(town, false)))


func on_tick(sim: Sim, _tick: int) -> void:
	var ticked := sim.store(&"worldtick") as WorldTick
	if ticked == null:
		return
	for town: StringName in Region.ZONE_ORDER:
		var was: float = ticked.grain_in(town)
		var now: float = WorldRules.drift(
			was, float(ticked.grain_target.get(town, WorldTick.NEUTRAL)),
			WorldRules.GRAIN_DRIFT_PER_DAY)
		ticked.grain_price[town] = now
		# Announced only when it crosses a whole point, or the log would carry one
		# event per town per in-game minute and say nothing.
		if floori(now) != floori(was):
			sim.derive(&"grain_moved", {"town": String(town), "to": now})


## Nothing to do between ticks.
func steps() -> bool:
	return false


func system_name() -> StringName:
	return &"grain"
