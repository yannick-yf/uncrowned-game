class_name MovementRules
extends RefCounted

## Pure. Where does a walker end up, given where they are, where they are pointed
## and what the ground is? No state, no side effects — the systems ask, this
## answers, and a test can check the answer without a Sim.

## 6 tiles a second, or 96 px/sec on a 16 px grid — a shade brisker than A Link to
## the Past's walk, which is the reference §13 names.
##
## Expressed per *second* rather than per step, so the simulation's step rate can
## change without the player's speed changing with it. That separation is the
## whole point of the two clocks.
const TILES_PER_SECOND: float = 6.0


static func tiles_per_step() -> float:
	return TILES_PER_SECOND / float(Sim.STEPS_PER_REAL_SECOND)


## 8-way. The direction is normalised, so walking diagonally is not a way to travel
## 41% faster — the diagonal covers 4 tiles/sec *along the diagonal*, which is the
## assumption §4's corner-to-corner arithmetic is built on.
static func direction_of(dir: Vector2i) -> Vector2:
	if dir == Vector2i.ZERO:
		return Vector2.ZERO
	return Vector2(dir).normalized()


static func tile_of(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x), floori(pos.y))


## Resolved per axis, so that walking into a wall at an angle slides along it
## rather than stopping dead. Without this, the coast and the mountains would feel
## like glue.
static func step(
	from: Vector2,
	dir: Vector2i,
	region: Region,
	distance: float = -1.0,
) -> Vector2:
	var tiles_per_tick: float = distance if distance >= 0.0 else tiles_per_step()
	var multiplier: float = Region.speed_multiplier(region.terrain_at(tile_of(from)))
	var delta: Vector2 = direction_of(dir) * tiles_per_tick * multiplier
	if delta == Vector2.ZERO:
		return from

	var to: Vector2 = from
	if region.is_passable(tile_of(Vector2(from.x + delta.x, from.y))):
		to.x = from.x + delta.x
	if region.is_passable(tile_of(Vector2(to.x, from.y + delta.y))):
		to.y = from.y + delta.y
	return to
