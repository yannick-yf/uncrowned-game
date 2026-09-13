class_name ZoneSystem
extends SimSystem

## Moves the player between zones when they step on a portal.
##
## Fires on the tile *changing*, not on occupying it, so arriving next to the
## portal you just came through does not bounce you straight back.

func on_step(sim: Sim, _step: int) -> void:
	var world := sim.store(&"world") as WorldState
	if world == null or world.region() == null:
		return
	var tile: Vector2i = world.player_tile()
	if tile == world.player_tile_last:
		return
	world.player_tile_last = tile

	var portal: Dictionary = world.region().portal_at(tile)
	if portal.is_empty():
		return
	var zone: StringName = portal["zone"] as StringName
	if not world.zones.has(zone):
		return
	world.current_zone = zone
	world.player_pos = Vector2(portal["at"] as Vector2i) + Vector2(0.5, 0.5)
	world.player_tile_last = world.player_tile()
	world.player_dir = Vector2i.ZERO
	sim.facts.add_source(StringName("zone:%s:entered" % zone), &"witnessed")


## Nothing to do on the world's clock.
func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"zone"
