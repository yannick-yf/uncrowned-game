extends TestCase

## **Where Bram calls from, as pure rules** (O14, 2026-09-29). The hail is the
## tutorial's way in (Yannick's « dresseur Pokémon »): walk into the ground around the
## ruined village and the man who teaches the sword sees you, calls out, and comes over.
## These are its rules without a world — who can see you, who still calls, and the way
## he walks — so the system that runs it (O16) only has to ask.

const ROW: Dictionary = {"who": &"bram", "at": Vector2i(10, 10), "radius": 4.0}


func _open_region(size: int) -> Region:
	var region := Region.new(size, size)
	for x: int in size:
		for y: int in size:
			region.set_terrain(Vector2i(x, y), Region.Terrain.WILD)
	return region


func test_the_table_is_read() -> void:
	assert_true(HailRules.radius_tiles() > 0.0, "a zone has a size")
	assert_true(HailRules.spotted_steps() > 0, "he sees you before he moves")
	assert_true(HailRules.budget_steps() > HailRules.spotted_steps(), "and has time to reach you")


func test_he_sees_you_inside_his_ground_and_not_outside_it() -> void:
	assert_true(HailRules.in_sight(ROW, Vector2i(10, 10)), "on the point itself")
	assert_true(HailRules.in_sight(ROW, Vector2i(13, 10)), "three tiles off")
	assert_true(HailRules.in_sight(ROW, Vector2i(14, 10)), "four, the edge")
	assert_false(HailRules.in_sight(ROW, Vector2i(13, 13)), "four and a quarter on the diagonal is out")
	assert_false(HailRules.in_sight({"who": &"bram", "at": Region.NOWHERE, "radius": 4.0}, Vector2i(-1, -1)),
		"a zone that resolves nowhere sees nobody")


func test_a_row_without_a_radius_takes_the_tables() -> void:
	assert_eq(HailRules.radius_of({"who": &"bram", "at": Vector2i.ZERO}), HailRules.radius_tiles(),
		"the table's radius")
	assert_eq(HailRules.radius_of(ROW), 4.0, "unless the row says otherwise")


func test_he_calls_out_once_and_never_to_somebody_he_knows() -> void:
	var facts := FactBase.new()
	assert_true(HailRules.calls_out(&"bram", facts), "a stranger walks in: he calls")
	facts.add_source(&"hailed:bram", &"witnessed")
	assert_false(HailRules.calls_out(&"bram", facts), "once")
	var met := FactBase.new()
	met.add_source(&"met:bram", &"witnessed")
	assert_false(HailRules.calls_out(&"bram", met), "a man you have already spoken to has no reason to shout")
	var dead := FactBase.new()
	dead.add_source(&"killed:bram", &"witnessed")
	assert_false(HailRules.calls_out(&"bram", dead), "and a dead one cannot")
	assert_false(HailRules.calls_out(&"bram", null), "nor a man with no world")


func test_he_walks_to_you_and_stops_a_tile_short() -> void:
	var region: Region = _open_region(20)
	var from := Vector2i(2, 2)
	var to := Vector2i(10, 6)
	var walk: Array[Vector2i] = HailRules.approach(region, from, to)
	assert_false(walk.is_empty(), "there is a way")
	assert_eq(walk[0], from, "from where he stands")
	var last: Vector2i = walk[walk.size() - 1]
	assert_eq(maxi(absi(last.x - to.x), absi(last.y - to.y)), 1, "to beside you, not onto you")
	for i: int in range(1, walk.size()):
		var step: Vector2i = walk[i] - walk[i - 1]
		assert_true(maxi(absi(step.x), absi(step.y)) == 1, "one tile a step")
	assert_eq(walk, HailRules.approach(region, from, to), "and the same walk every time")


func test_already_beside_you_he_does_not_move() -> void:
	var region: Region = _open_region(8)
	assert_eq(HailRules.approach(region, Vector2i(3, 3), Vector2i(4, 4)), [Vector2i(3, 3)] as Array[Vector2i],
		"a man beside you stays where he is")


func test_he_goes_round_what_is_in_the_way() -> void:
	var region: Region = _open_region(12)
	for y: int in range(0, 10):
		region.set_terrain(Vector2i(5, y), Region.Terrain.WALL)
	var walk: Array[Vector2i] = HailRules.approach(region, Vector2i(2, 2), Vector2i(8, 2))
	assert_false(walk.is_empty(), "the wall has an end")
	for tile: Vector2i in walk:
		assert_true(region.is_passable(tile), "and he walks round it: %s" % tile)
	assert_true(HailRules.approach(_walled_off(), Vector2i(1, 1), Vector2i(8, 8)).is_empty(),
		"and a man who cannot reach you does not try")


func _walled_off() -> Region:
	var region: Region = _open_region(10)
	for i: int in 10:
		region.set_terrain(Vector2i(5, i), Region.Terrain.WALL)
	return region
