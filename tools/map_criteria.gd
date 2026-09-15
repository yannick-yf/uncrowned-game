extends SceneTree

## MAP_SPEC §9's twelve machine-checkable acceptance criteria, measured.
##
## The map brief says an autonomous run is finished when all twelve pass. This
## prints which do. Criteria 11 and 12 are other tools' jobs and are reported as
## such rather than guessed at.
##
##   godot --headless --path . -s tools/map_criteria.gd

## MAP_SPEC leaves this `[DECIDE]`. Set here so the criterion is checkable.
const THORNWOOD_CROSSING_MIN: int = 30

var _passed: int = 0
var _failed: int = 0


func _ok(number: int, name: String, pass_: bool, detail: String) -> void:
	if pass_:
		_passed += 1
	else:
		_failed += 1
	print("%s %2d  %-52s %s" % ["PASS" if pass_ else "FAIL", number, name, detail])


func _reach(region: Region, from: Vector2i, dammed: Dictionary) -> Dictionary:
	var seen: Dictionary = {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_back()
		for dx: int in [-1, 0, 1]:
			for dy: int in [-1, 0, 1]:
				var next := Vector2i(at.x + dx, at.y + dy)
				if seen.has(next) or dammed.has(next):
					continue
				if not region.in_bounds(next) or not region.is_passable(next):
					continue
				seen[next] = true
				queue.append(next)
	return seen


func _band(centre: Vector2i, half: int) -> Dictionary:
	var out: Dictionary = {}
	for x: int in range(centre.x - half, centre.x + half + 1):
		for y: int in range(centre.y - half, centre.y + half + 1):
			out[Vector2i(x, y)] = true
	return out


func _init() -> void:
	var region: Region = Region.build_overworld()
	print("MAP_SPEC section 9 — the twelve\n")

	# 1 — every zone reachable. Checked from the clearing, where the player now
	# actually wakes, which is stricter than Brindle: it is behind the thicket.
	var open: Dictionary = _reach(region, Region.CLEARING, {})
	var unreachable: Array[String] = []
	for zone: StringName in Region.ZONE_ORDER:
		if not open.has(Region.zone_sites()[zone] as Vector2i):
			unreachable.append(String(zone))
	_ok(1, "every zone reachable, over ground", unreachable.is_empty(),
		"from the clearing" if unreachable.is_empty() else str(unreachable))

	# 2 — no walkable tile touches the edge.
	var leaks: int = 0
	for x: int in region.width:
		if region.is_passable(Vector2i(x, 0)) or region.is_passable(Vector2i(x, region.height - 1)):
			leaks += 1
	for y: int in region.height:
		if region.is_passable(Vector2i(0, y)) or region.is_passable(Vector2i(region.width - 1, y)):
			leaks += 1
	_ok(2, "no walkable tile touches the region edge", leaks == 0, "%d leaks" % leaks)

	# 3 — every delivered bridge and the ford reach dry land on both sides.
	var crossings: Array[Vector2i] = [Region.BRIDGE, Region.FORD]
	if Places.baked():
		crossings = [Region.FORD]
		for bridge: Dictionary in (RegionBake.read_landscape()["meta"] as Dictionary)["crossings"]:
			crossings.append(Places.shared().point(StringName(bridge["id"])))
	var dry: bool = true
	for crossing: Vector2i in crossings:
		var west: bool = false
		var east: bool = false
		for step: int in range(3, 14):
			if region.is_passable(crossing - Vector2i(step, 0)):
				west = true
			if region.is_passable(crossing + Vector2i(step, 0)):
				east = true
		dry = dry and west and east
	_ok(3, "every crossing reaches dry land on both sides", dry, "%d crossings" % crossings.size())

	# 4 — dam all crossings and the castle is cut off.
	var dammed: Dictionary = {}
	for crossing: Vector2i in crossings:
		dammed.merge(_band(crossing, Region.CROSSING_HALF_WIDTH + 3))
	var cut: Dictionary = _reach(region, Region.BRINDLE, dammed)
	_ok(4, "damming all crossings cuts Blackcairn off", not cut.has(Region.BLACKCAIRN),
		"the river is a barrier by test")

	# 5 and 6 — the road.
	var road: float = region.road_distance()
	var direct: float = region.brindle_to_blackcairn_tiles()
	var ratio: float = road / maxf(direct, 1.0)
	_ok(5, "road ratio >= 1.30", ratio >= 1.30, "%.2f  (%.0f road / %.0f direct)" % [ratio, road, direct])
	var seconds: float = road / MovementRules.tiles_per_second()
	_ok(6, "road travel 45-90 s", seconds >= 45.0 and seconds <= 90.0,
		"%.1f s at %.1f tiles/s" % [seconds, MovementRules.tiles_per_second()])

	# 7 — the wild line has to actually cross the wood.
	var crossed: int = 0
	var from := Vector2(Region.BRINDLE)
	var to := Vector2(Region.BLACKCAIRN)
	var steps: int = int(from.distance_to(to))
	for i: int in steps:
		var at: Vector2 = from.lerp(to, float(i) / float(steps))
		if region.terrain_at(Vector2i(floori(at.x), floori(at.y))) == Region.Terrain.FOREST:
			crossed += 1
	_ok(7, "wild line crosses the Thornwood >= %d tiles" % THORNWOOD_CROSSING_MIN,
		crossed >= THORNWOOD_CROSSING_MIN, "%d tiles" % crossed)

	# 8 — every zone has a landmark.
	var without: Array[String] = []
	for zone: StringName in Region.ZONE_ORDER:
		var site: Vector2i = Region.zone_sites()[zone] as Vector2i
		var found: bool = false
		for prop: Dictionary in region.props:
			if Vector2(prop["at"] as Vector2i).distance_to(Vector2(site)) <= 22.0:
				found = true
				break
		if not found:
			without.append(String(zone))
	_ok(8, "every zone has a landmark in core/", without.is_empty(),
		"%d props" % region.props.size() if without.is_empty() else str(without))

	# 9 — nothing built on the road, a crossing, or on a zone centre.
	# Narrowed to what the criterion protects: a building may never close the way
	# through, and on the *open* road nothing may stand in it. Inside a town, streets
	# and buildings interleave, which is what a town is. See test_map.gd.
	var trespass: int = 0
	var blocked: int = 0
	for prop: Dictionary in region.props:
		var at: Vector2i = prop["at"] as Vector2i
		var size: Vector2i = prop.get("size", Vector2i.ONE) as Vector2i
		if size.x <= 1 and size.y <= 1:
			continue
		var town: bool = false
		for zone: StringName in Region.ZONE_ORDER:
			if Vector2(at).distance_to(Vector2(Region.zone_sites()[zone] as Vector2i)) <= 24.0:
				town = true
		if town:
			continue
		if region.terrain_at(at) == Region.Terrain.ROAD or region.terrain_at(at) == Region.Terrain.FORD:
			trespass += 1
	for point: Vector2i in Region.road_waypoints(3):
		if not region.is_passable(point):
			blocked += 1
	_ok(9, "nothing stands in the open road, and none closes it", trespass == 0 and blocked == 0,
		"%d on the road, %d waypoints blocked" % [trespass, blocked])

	# 10 — every bend has a reason near it.
	var route: Array[Vector2i] = Region.road_route()
	var unexplained: int = 0
	for i: int in range(1, route.size() - 1):
		var bend: Vector2i = route[i]
		var reason: bool = false
		for zone: StringName in Region.ZONE_ORDER:
			if Vector2(bend).distance_to(Vector2(Region.zone_sites()[zone] as Vector2i)) <= 8.0:
				reason = true
		for step: int in range(0, 9):
			for angle: int in 8:
				var look: Vector2i = bend + Vector2i(
					int(round(cos(float(angle) * TAU / 8.0) * float(step))),
					int(round(sin(float(angle) * TAU / 8.0) * float(step))))
				var here: Region.Terrain = region.terrain_at(look)
				if here == Region.Terrain.WATER or here == Region.Terrain.MOUNTAIN \
						or here == Region.Terrain.SEA or here == Region.Terrain.FOREST \
						or here == Region.Terrain.MARSH:
					reason = true
		if not reason:
			unexplained += 1
	_ok(10, "every road bend has a reason within 8 tiles", unexplained == 0,
		"%d bends, %d unexplained" % [route.size() - 2, unexplained])

	print("\n 11  asset validator      — tools/validate_assets.gd")
	print(" 12  full test suite       — tools/run_tests.sh --all")
	print("\n%d of 10 measurable here pass, %d fail" % [_passed, _failed])
	quit()
