extends TestCase

## Phase 7, the opening — stage 1: the ground.
##
## The player wakes in the fairies' clearing inside the Thornwood, and **one
## corridor** leads south out of it to Brindle. Brindle is ash; the Cinderworks
## stands in the same frame, on the village's own ground. No maze, no choice in the
## first minute, and nothing gated anywhere.
##
## **The thicket is geography, not a gate.** The map already closes itself with sea
## and mountain, and Pillar 1 is about progression checks rather than walls. The rule
## that keeps it honest is asserted below: thicket may never be the only thing
## between the player and anything, which is why every zone must still be reachable
## with the corridor open.

const SLOW: bool = true


func _region() -> Region:
	return Region.build_overworld()


## Everywhere you can walk from here, optionally with some tiles dammed.
##
## The damming is the shape MAP_SPEC uses for the river — *"damming both crossings
## makes Blackcairn unreachable"* — because a barrier you can only assert is a
## barrier nobody has checked. One corridor is true when blocking the corridor
## closes the pocket, and not before.
func _reachable(region: Region, from: Vector2i, dammed: Array[Vector2i]) -> Dictionary:
	var blocked: Dictionary = {}
	for tile: Vector2i in dammed:
		blocked[tile] = true
	var seen: Dictionary = {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_back()
		for dx: int in [-1, 0, 1]:
			for dy: int in [-1, 0, 1]:
				var next := Vector2i(at.x + dx, at.y + dy)
				if seen.has(next) or blocked.has(next):
					continue
				if not region.in_bounds(next) or not region.is_passable(next):
					continue
				seen[next] = true
				queue.append(next)
	return seen


func _corridor_mouth() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var from: int = Region.CLEARING.y + Region.CLEARING_RADIUS
	for x: int in range(Region.CLEARING.x - Region.PATH_HALF_WIDTH,
			Region.CLEARING.x + Region.PATH_HALF_WIDTH + 1):
		for y: int in range(from, from + Region.THICKET_DEPTH + 2):
			out.append(Vector2i(x, y))
	return out


# ------------------------------------------------------------- the clearing ---

func test_the_player_wakes_on_open_ground_in_the_wood() -> void:
	var region: Region = _region()
	assert_eq(region.terrain_at(Region.CLEARING), Region.Terrain.CLEARING,
		"the centre of the clearing is clearing, not the corridor cut through it")
	assert_true(region.is_passable(Region.CLEARING), "and you can stand on it")
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	assert_eq(world.player_pos, region.clearing_centre(), "and the game starts you there")


func test_the_clearing_is_ringed_by_wood_you_cannot_walk_into() -> void:
	var region: Region = _region()
	var outer: int = Region.CLEARING_RADIUS + Region.THICKET_DEPTH
	# North of the clearing, away from the corridor, the ring must be solid.
	var solid: int = 0
	for y: int in range(Region.CLEARING.y - outer, Region.CLEARING.y - Region.CLEARING_RADIUS):
		if not region.is_passable(Vector2i(Region.CLEARING.x, y)):
			solid += 1
	assert_true(solid >= Region.THICKET_DEPTH - 1,
		"the ring north of the clearing is %d tiles deep" % solid)


func test_one_corridor_leads_out_and_only_one() -> void:
	# The whole geography claim, and the only way to check it: block the corridor
	# and the clearing has to become a closed pocket. If any other way out exists,
	# Brindle is still reachable and this fails.
	var region: Region = _region()
	var open: Dictionary = _reachable(region, Region.CLEARING, [] as Array[Vector2i])
	assert_true(open.has(Region.BRINDLE), "with the corridor open you can walk to Brindle")

	var sealed: Dictionary = _reachable(region, Region.CLEARING, _corridor_mouth())
	assert_false(sealed.has(Region.BRINDLE), "with it dammed you cannot")
	assert_true(sealed.size() < 400,
		"and what is left is a pocket, not the map: %d tiles" % sealed.size())


func test_walking_out_takes_about_five_seconds() -> void:
	# §4's rule against empty walking cuts both ways: long enough to be a walk out
	# of the trees, short enough that it is not the content.
	var tiles: float = Vector2(Region.CLEARING).distance_to(Vector2(Region.BRINDLE))
	var seconds: float = tiles / 6.0
	assert_true(seconds >= 3.0 and seconds <= 8.0,
		"clearing to Brindle is %.1f tiles, %.1f seconds" % [tiles, seconds])


# ------------------------------------------------------- what it must not break ---

func test_the_king_is_still_reachable_from_the_first_minute() -> void:
	# Pillar 1. Starting in the wood may not put the castle further away than
	# "minutes, not hours", and the straight line is the number that says so.
	var region: Region = _region()
	var seconds: float = region.clearing_to_blackcairn_tiles() / 6.0
	assert_true(seconds < 90.0,
		"the clearing is %.0f tiles from Blackcairn, %.0f seconds" % [
			region.clearing_to_blackcairn_tiles(), seconds])


func test_every_zone_is_still_reachable_from_where_the_player_wakes() -> void:
	# The rule attached to the thicket: it may never be the only thing between the
	# player and anything. Eight zones, walked from the clearing, over ground.
	var region: Region = _region()
	var open: Dictionary = _reachable(region, Region.CLEARING, [] as Array[Vector2i])
	for zone: StringName in Region.ZONE_ORDER:
		var site: Vector2i = Region.zone_sites().get(zone, Region.NOWHERE)
		if site == Region.NOWHERE:
			continue
		assert_true(open.has(site), "%s is reachable from the clearing" % zone)


func test_the_furnaces_are_in_frame_when_you_reach_the_ruins() -> void:
	# The image the opening rests on, and the reason no exposition is needed: the
	# crime and the industry it served in one frame. Checked against the viewport,
	# 640x360 at 16px a tile, so 40 x 22.5 tiles and half of that either side.
	# The *nearest* part of the works, not its far corner: what has to be in shot is
	# some of the thing, not all of it. The first draft measured the northern edge,
	# 16 tiles up, and failed on a frame that plainly contains the furnaces.
	var half := Vector2(20.0, 11.25)
	var from: Vector2 = Vector2(Region.BRINDLE)
	var near := Vector2(
		clampf(from.x, float(Region.CINDERWORKS.x - Region.CINDERWORKS_SIZE.x / 2),
			float(Region.CINDERWORKS.x + Region.CINDERWORKS_SIZE.x / 2)),
		clampf(from.y, float(Region.CINDERWORKS.y - Region.CINDERWORKS_SIZE.y / 2),
			float(Region.CINDERWORKS.y + Region.CINDERWORKS_SIZE.y / 2)))
	assert_true(absf(from.x - near.x) < half.x and absf(from.y - near.y) < half.y,
		"the nearest of the works is %.0f,%.0f tiles from Brindle's centre, in a %.0f x %.0f frame"
			% [absf(from.x - near.x), absf(from.y - near.y), half.x * 2.0, half.y * 2.0])


func test_the_clearing_never_wrote_over_the_road_the_river_or_a_town() -> void:
	# `_stamp_clearing` only ever overwrites FOREST, so this cannot fail by
	# construction — which is the point of asserting it, because the next person to
	# move the clearing will not know that.
	# Scanned over what the opening actually stamps, not a box around it. The first
	# draft swept fourteen tiles either side all the way down to Brindle and caught
	# the Cinderworks, which the opening never touched.
	var region: Region = _region()
	var laid: int = 0
	for x: int in range(Region.CLEARING.x - 20, Region.CLEARING.x + 21):
		for y: int in range(Region.CLEARING.y - 20, Region.BRINDLE.y):
			var here: Region.Terrain = region.terrain_at(Vector2i(x, y))
			if here != Region.Terrain.CLEARING and here != Region.Terrain.THICKET:
				continue
			laid += 1
			# A tile the opening owns may never be one of these, and the stamp only
			# ever overwrites FOREST, so this holds by construction — which is why
			# it is asserted, for whoever moves the clearing next.
			assert_true(here != Region.Terrain.ROAD and here != Region.Terrain.WATER
					and here != Region.Terrain.TOWN, "at %d,%d" % [x, y])
	assert_true(laid > 100, "the opening laid %d tiles of its own" % laid)


# ------------------------------------------------- stage 4: the first fire ---

func test_the_fairies_ground_is_the_first_fire() -> void:
	# The save the game opens on, and it earns the place twice: the ground that can
	# hold you is the ground still held, and it gives the player a reason to come
	# back — which is the only way the shrinking can be *seen* rather than asserted.
	var region: Region = _region()
	assert_ne(region.nearest_campfire(Region.CLEARING, 4.0), Region.NOWHERE,
		"there is a fire in the clearing")


func test_dying_before_you_ever_rest_puts_you_back_where_you_woke() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	world.player_pos = world.region().brindle_centre()
	assert_eq(world.rested_at, Vector2i(-1, -1), "nobody has slept yet")
	world.hurt(WorldState.MAX_HP, sim.step)
	assert_eq(world.player_pos, world.region().clearing_centre(),
		"back in the clearing, not in the ruins")
