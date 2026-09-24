class_name TestCase
extends RefCounted

## Base class for every file in test/.
##
## One instance per test method: the runner constructs a fresh case, calls
## before_each(), the test_* method, then after_each(). Assertions record failures
## rather than halting, so one broken expectation does not hide the next.

var _failures: PackedStringArray = PackedStringArray()
var _assertions: int = 0
var _debts: PackedStringArray = PackedStringArray()
var _offs: PackedStringArray = PackedStringArray()


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func failures() -> PackedStringArray:
	return _failures


func failure_count() -> int:
	return _failures.size()


func assertion_count() -> int:
	return _assertions


func fail(message: String) -> void:
	_failures.append(message)


## Something the **map** owes, not something the code got wrong (MIGRATION_3D §5).
## On the world baked from the 3D workshop a few of the spec's claims are false until
## the brother moves a place or plants a wood — the works in Brindle's first frame,
## for one — and a test that encodes such a claim records a debt rather than a
## failure. The runner prints debts with the run and counts them apart, so the suite
## stays green while the brief is open and nobody learns to stop reading red.
func debt(message: String) -> void:
	_debts.append(message)


func debts() -> PackedStringArray:
	return _debts


## Something a **testing switch** has turned off, not something the code got wrong
## (CLAUDE.md, *Testing switches*). While the 3D world is tested the 2D game's layers
## come off one by one — the wild's price in time, the music — each behind one word,
## and a test that claims what a switch turns off records this rather than failing or
## quietly passing. The runner prints it as `OFF` and counts it apart, so the switch is
## not forgotten and the claim is not lost.
func off(message: String) -> void:
	_offs.append(message)


func offs() -> PackedStringArray:
	return _offs


func assert_true(condition: bool, message: String = "") -> void:
	_assertions += 1
	if not condition:
		fail("expected true%s" % _suffix(message))


func assert_false(condition: bool, message: String = "") -> void:
	_assertions += 1
	if condition:
		fail("expected false%s" % _suffix(message))


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	_assertions += 1
	if actual != expected:
		fail("expected %s, got %s%s" % [_show(expected), _show(actual), _suffix(message)])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	_assertions += 1
	if actual == unexpected:
		fail("expected anything but %s%s" % [_show(unexpected), _suffix(message)])


func assert_null(value: Variant, message: String = "") -> void:
	_assertions += 1
	if value != null:
		fail("expected null, got %s%s" % [_show(value), _suffix(message)])


func assert_not_null(value: Variant, message: String = "") -> void:
	_assertions += 1
	if value == null:
		fail("expected non-null%s" % _suffix(message))


# -------------------------------------------------------- where a test stands ---
#
# A test says *where* it stands in the world's own terms — beside a stall in
# Harrowgate, on the open road, deep in the wood — and never as a tile (MIGRATION_3D
# §6.2, M1c). The same test then holds on the 2D map and on the world baked from the
# 3D workshop, and a tile constant in a test is the same debt as one in a `.gd`.
# Every spot is deterministic: same world, same tile.

## Standing on the first stall in a place, where `nearest_stall` finds it in reach.
func at_a_stall(zone: StringName = &"harrowgate") -> Vector2:
	var region: Region = Region.build_overworld()
	for prop: Dictionary in region.props:
		if (prop["kind"] as StringName) == &"stall" and region.zone_at(prop["at"] as Vector2i) == zone:
			return Vector2(prop["at"] as Vector2i) + Vector2(0.5, 1.0)
	fail("no stall stands in %s" % zone)
	return Vector2.ZERO


## Every counter in a place, in the region's own order. Two thefts in one town need
## two of them: a robbed stall stays bare for a quarter of an in-game day.
func stalls_in(zone: StringName) -> Array[Vector2]:
	var region: Region = Region.build_overworld()
	var out: Array[Vector2] = []
	for prop: Dictionary in region.props:
		if (prop["kind"] as StringName) == &"stall" and region.zone_at(prop["at"] as Vector2i) == zone:
			out.append(Vector2(prop["at"] as Vector2i) + Vector2(0.5, 1.0))
	return out


## In the middle of a place, on its street.
func in_town(zone: StringName) -> Vector2:
	var region: Region = Region.build_overworld()
	var site: Vector2i = Region.zone_sites()[zone] as Vector2i
	return Vector2(_open_near(region, site + Vector2i(-1, -1))) + Vector2(0.5, 0.0)


## Somewhere inside a place where nobody is within earshot: no person nearer than
## the witness rule looks, no stall to be accused of.
func empty_corner_of(zone: StringName) -> Vector2:
	var region: Region = Region.build_overworld()
	var cast: Cast = Cast.shared()
	var site: Vector2i = Region.zone_sites()[zone] as Vector2i
	var half: Vector2i = (Region.zone_footprints()[zone] as Vector2i) / 2 + Vector2i(Region.ZONE_MARGIN, Region.ZONE_MARGIN)
	# From the far corner inward, so the spot is the emptiest the place has.
	for ring: int in range(0, maxi(half.x, half.y)):
		for dx: int in [half.x - ring, -(half.x - ring)]:
			for dy: int in range(-half.y, half.y + 1):
				var tile: Vector2i = site + Vector2i(dx, dy)
				if _is_empty_spot(region, cast, tile, zone):
					return Vector2(tile) + Vector2(0.5, 0.5)
	fail("no empty corner in %s" % zone)
	return Vector2(site) + Vector2(0.5, 0.5)


func _is_empty_spot(region: Region, cast: Cast, tile: Vector2i, zone: StringName) -> bool:
	if not region.is_passable(tile) or region.zone_at(tile) != zone:
		return false
	for npc: Npc in cast.in_zone(WorldState.OVERWORLD):
		if Vector2(npc.tile).distance_to(Vector2(tile)) < 10.0:
			return false
	for prop: Dictionary in region.props:
		if (prop["kind"] as StringName) == &"stall" \
				and Vector2(prop["at"] as Vector2i).distance_to(Vector2(tile)) < 8.0:
			return false
	return true


## On the King's Road, in open country, with nobody near.
##
## **The waypoints first, then the road itself** (2026-09-16). This walked only
## `road_waypoints()` — 34 thinned steering targets — and the day his royal city
## arrived, 23 of the 34 stood inside a zone (its own is 100 × 90) and somebody was
## within 14 tiles of all eleven that were left, so four suites failed saying the
## road had no empty stretch. It had 1941 of them: the sample was too coarse, not
## the world too crowded. The waypoints are still tried first, because they are
## cheap and they keep the spot these tests have always used wherever it still
## holds; the road is scanned only when none of them answers.
func alone_on_the_road() -> Vector2:
	var region: Region = Region.build_overworld()
	var cast: Cast = Cast.shared()
	for point: Vector2i in Region.road_waypoints():
		if _is_lonely_road(region, cast, point):
			return Vector2(point) + Vector2(0.5, 0.5)
	for y: int in region.height:
		for x: int in region.width:
			var tile := Vector2i(x, y)
			if region.terrain_at(tile) != Region.Terrain.ROAD:
				continue
			if _is_lonely_road(region, cast, tile):
				return Vector2(tile) + Vector2(0.5, 0.5)
	fail("the road has no empty stretch")
	return Vector2.ZERO


## Open road, outside every settlement, with no one of the cast within 14 tiles.
func _is_lonely_road(region: Region, cast: Cast, tile: Vector2i) -> bool:
	if region.zone_at(tile) != &"" or not region.is_passable(tile):
		return false
	for npc: Npc in cast.in_zone(WorldState.OVERWORLD):
		if Vector2(npc.tile).distance_to(Vector2(tile)) < 14.0:
			return false
	return true


## Next to a person, close enough to talk.
func beside_npc(id: StringName) -> Vector2:
	var region: Region = Region.build_overworld()
	var npc: Npc = Cast.shared().get_npc(id)
	if npc == null:
		fail("no such person: %s" % id)
		return Vector2.ZERO
	return Vector2(_open_near(region, npc.tile + Vector2i(0, 1))) + Vector2(0.5, 0.0)


## Deep in the wood: by Kell's fire, which is the one landmark out there.
func in_the_wood() -> Vector2:
	var region: Region = Region.build_overworld()
	var kell: Npc = Cast.shared().get_npc(&"kell")
	var at: Vector2i = _open_near(region, kell.tile + Vector2i(2, 2)) if kell != null else Vector2i.ZERO
	return Vector2(at) + Vector2(0.5, 0.5)


## The tile itself if it can be stood on, else the nearest that can.
func _open_near(region: Region, from: Vector2i) -> Vector2i:
	if region.is_passable(from):
		return from
	for radius: int in range(1, 12):
		for dx: int in range(-radius, radius + 1):
			for dy: int in range(-radius, radius + 1):
				var at: Vector2i = from + Vector2i(dx, dy)
				if region.is_passable(at):
					return at
	return from


func _show(value: Variant) -> String:
	if value is String or value is StringName:
		return "\"%s\"" % String(value)
	return str(value)


func _suffix(message: String) -> String:
	return "" if message.is_empty() else " — %s" % message


## Every built crossing and the ford. The brother's five bridges replace the old
## assumption that damming two points closes the river (2026-09-15).
func river_crossings() -> Array[Vector2i]:
	if not Places.baked():
		return [Region.BRIDGE, Region.FORD]
	var out: Array[Vector2i] = [Region.FORD]
	for bridge: Dictionary in (RegionBake.read_landscape()["meta"] as Dictionary)["crossings"]:
		out.append(Places.shared().point(StringName(bridge["id"])))
	return out
