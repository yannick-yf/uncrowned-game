extends TestCase

## **A yard composed from his pieces** (G2, 2026-09-21): runs of modules laid end
## marker to end marker, stopping at his water and stepping aside for his own walls,
## one gate whose origin is its passage, single pieces. Checked here on a made-up brief
## against his real numbers, without a region.

const CATALOG: Dictionary = {
	"assets": [
		{"id": "soubassement_2m", "size_m": [1.98, 0.68, 0.4], "ground_pivot": true,
		 "scene": "res://assets/ironworks/modules/soubassement_2m.tscn"},
		{"id": "portail_cour", "size_m": [3.26, 1.5, 1.37], "ground_pivot": true,
		 "scene": "res://assets/ironworks/modules/portail_cour.tscn"},
		{"id": "enseigne_forge", "size_m": [1.57, 2.45, 0.17], "ground_pivot": true,
		 "scene": "res://assets/ironworks/modules/enseigne_forge.tscn"},
	],
}

## Water from x = 20 m eastward, wherever it is asked.
static func _river_east_of_20(point: Vector2) -> bool:
	return point.x >= 20.0


static func _dry(_point: Vector2) -> bool:
	return false


func test_a_run_is_whole_modules_laid_along_its_direction() -> void:
	var run: Dictionary = {"id": "north", "piece": "soubassement_2m", "from_xz": [0.2, 0.0], "to_xz": [8.2, 0.0]}
	var laid: Array[Dictionary] = YardRules.lay_run(run, CatalogRules.entry(CATALOG, "soubassement_2m"), _dry, [])
	assert_eq(laid.size(), 4, "eight metres are four modules")
	assert_eq(laid[0]["xz"], Vector2(1.2, 0.0), "the first is centred a metre in from the start")
	assert_eq(float(laid[0]["yaw"]), 0.0, "laid east, so his +X runs east")
	assert_eq(String(laid[0]["role"]), "run", "and it is a run's module")
	var south: Dictionary = {"id": "west", "piece": "soubassement_2m", "from_xz": [0.0, 0.0], "to_xz": [0.0, 6.0]}
	var down: Array[Dictionary] = YardRules.lay_run(south, CatalogRules.entry(CATALOG, "soubassement_2m"), _dry, [])
	assert_eq(down.size(), 3, "six metres south are three")
	assert_eq(float(down[0]["yaw"]), -90.0, "turned so his +X runs south")


func test_a_run_toward_the_water_stops_on_the_bank() -> void:
	# **Yannick saw a palisade in the river** (Q1). The run is asked to reach x = 40 and
	# the water begins at 20: it lays what fits on dry ground and says where it stopped.
	var run: Dictionary = {"id": "north", "piece": "soubassement_2m", "from_xz": [0.0, 0.0], "to_xz": [40.0, 0.0],
		"until": "water"}
	var laid: Array[Dictionary] = YardRules.lay_run(run, CatalogRules.entry(CATALOG, "soubassement_2m"),
		_river_east_of_20, [])
	assert_eq(laid.size(), 9, "nine modules end at 18 m; the tenth would reach the water")
	assert_true(laid[laid.size() - 1].has("stopped_at_water"), "and the last says why the run ended")
	for module: Dictionary in laid:
		assert_true((module["xz"] as Vector2).x + 1.0 <= 20.0, "%s is on dry ground" % str(module["xz"]))


func test_a_module_over_one_of_his_walls_is_dropped_and_his_stands() -> void:
	var his: Array = [[[4.8, -0.5], [5.2, -0.5], [5.2, 0.5], [4.8, 0.5]]]
	var run: Dictionary = {"id": "south", "piece": "soubassement_2m", "from_xz": [0.0, 0.0], "to_xz": [10.0, 0.0]}
	var laid: Array[Dictionary] = YardRules.lay_run(run, CatalogRules.entry(CATALOG, "soubassement_2m"), _dry, his)
	assert_eq(laid.size(), 5, "five laid")
	var dropped: int = 0
	for module: Dictionary in laid:
		if module.has("dropped"):
			dropped += 1
			assert_eq(module["xz"], Vector2(5.0, 0.0), "the one across his wall")
	assert_eq(dropped, 1, "exactly one steps aside")


func test_a_yard_composes_its_runs_its_gate_and_its_sign() -> void:
	var yard: Dictionary = {
		"place": "cinderworks",
		"runs": [
			{"id": "north", "piece": "soubassement_2m", "from_xz": [0.2, 0.0], "to_xz": [40.0, 0.0], "until": "water"},
			{"id": "west", "piece": "soubassement_2m", "from_xz": [0.0, -0.2], "to_xz": [0.0, 5.8]},
			{"id": "nothing", "piece": "fence_2m", "from_xz": [0.0, 0.0], "to_xz": [4.0, 0.0]},
		],
		"gate": {"piece": "portail_cour", "xz": [0.0, 7.5], "yaw": 90},
		"pieces": [{"id": "sign", "piece": "enseigne_forge", "xz": [-0.4, 5.0], "yaw": -90}],
	}
	var out: Dictionary = YardRules.compose(yard, CATALOG, _river_east_of_20, [])
	var pieces: Array = out["pieces"]
	var by_role: Dictionary = {}
	for piece: Dictionary in pieces:
		by_role[piece["role"]] = int(by_role.get(piece["role"], 0)) + 1
	assert_eq(int(by_role.get(&"run", 0)), 9 + 3, "the north run to the water and the west run")
	assert_eq(int(by_role.get(&"gate", 0)), 1, "one gate")
	assert_eq(int(by_role.get(&"piece", 0)), 1, "one sign")
	var said: String = "\n".join(out["report"] as Array)
	assert_true(said.contains("no piece 'fence_2m'"), "a piece he has not made is refused by name: %s" % said)
	assert_true(said.contains("stopped at his water"), "and the run that met the river says so")
	for piece: Dictionary in pieces:
		assert_true(String(piece["scene"]).begins_with("res://assets/ironworks/"), "every piece is his scene")
		assert_true(piece.has("size_m") and piece.has("lift"), "and carries his size and pivot")


## **A yard on a point, from his library** (O13, 2026-09-29). The cemetery is no place's
## yard and his library has no catalogue: a piece may name a library scene instead of a
## catalogue entry, stand at many points at once, be scaled — his `boulder_round`, small,
## is an uncut grave stone — and vary from stone to stone by a jitter seeded from the
## yard's own name, so a re-bake stands every stone exactly where it stood.
func test_a_library_piece_stands_at_each_of_its_points_scaled_and_jittered() -> void:
	var yard: Dictionary = {
		"point": "cemetery",
		"pieces": [{"id": "graves", "library": "rocks/boulder_round", "scale": 0.3,
			"jitter": {"yaw": 20, "scale": 0.1, "shift_m": 0.15},
			"at": [[0.0, 0.0], [2.0, 0.0], [4.0, 0.0]]}],
	}
	var out: Dictionary = YardRules.compose(yard, CATALOG, _dry, [])
	var pieces: Array = out["pieces"]
	assert_eq(pieces.size(), 3, "one stone at each of its three points")
	var again: Array = YardRules.compose(yard, CATALOG, _dry, [])["pieces"]
	var yaws: Dictionary = {}
	for i: int in pieces.size():
		var stone: Dictionary = pieces[i]
		assert_eq(String(stone["scene"]), "res://prototype_3d/assets/library/rocks/boulder_round.tscn",
			"his library's scene, by its path under the library")
		assert_eq(String(stone["piece"]), "boulder_round", "named as his scene is named")
		var scale: Vector3 = stone["scale"] as Vector3
		assert_true(scale.x >= 0.27 and scale.x <= 0.33 and is_equal_approx(scale.x, scale.z)
			and is_equal_approx(scale.x, scale.y), "scaled evenly, within its jitter: %s" % scale)
		assert_true(absf(float(stone["yaw"])) <= 20.0, "turned within its jitter")
		var home := Vector2(2.0 * i, 0.0)
		assert_true((stone["xz"] as Vector2).distance_to(home) <= 0.15 * sqrt(2.0) + 0.001,
			"shifted within its jitter of where the brief put it")
		assert_eq(stone, again[i], "and the same on every bake")
		yaws[float(stone["yaw"])] = true
	assert_true(yaws.size() > 1, "and the stones are not all turned alike")


func test_a_piece_scaled_unevenly_keeps_each_axis() -> void:
	var yard: Dictionary = {"point": "cemetery", "pieces": [
		{"id": "earth", "piece": "enseigne_forge", "scale": [0.3, 1.0, 0.85], "xz": [1.0, 2.0]}]}
	var stood: Dictionary = (YardRules.compose(yard, CATALOG, _dry, [])["pieces"] as Array)[0]
	assert_eq(stood["scale"], Vector3(0.3, 1.0, 0.85), "each axis as the brief wrote it")
	assert_eq(stood["xz"], Vector2(1.0, 2.0), "and no jitter unless asked for")


func test_a_piece_laid_on_the_ground_stops_nobody() -> void:
	# His turned earth is four centimetres of soil: a grave's mound, walked beside and
	# never refused. The role says so, and the bake blocks nothing for it — not even the
	# tile it stands on, which every other piece closes.
	var yard: Dictionary = {"point": "cemetery", "pieces": [
		{"id": "earth", "piece": "enseigne_forge", "ground": true, "xz": [1.0, 2.0]}]}
	var stood: Dictionary = (YardRules.compose(yard, CATALOG, _dry, [])["pieces"] as Array)[0]
	assert_eq(stood["role"], YardRules.ROLE_GROUND, "laid on the ground")


func test_a_run_of_his_modules_carries_no_scale() -> void:
	var run: Dictionary = {"id": "north", "piece": "soubassement_2m", "from_xz": [0.0, 0.0], "to_xz": [4.0, 0.0]}
	var laid: Array[Dictionary] = YardRules.lay_run(run, CatalogRules.entry(CATALOG, "soubassement_2m"), _dry, [])
	assert_eq(laid[0]["scale"], Vector3.ONE, "a module stands at his size")
