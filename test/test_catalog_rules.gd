extends TestCase

## **His catalogue, read** (G1, 2026-09-21). Pure functions of a catalogue entry and a
## placement, so the bake's reading of `size_m`, `front: +Z`, `ground_pivot` and the
## collision shapes can be checked without a region or a file. The entries below are
## his own numbers, copied from `prototypes/brindle_3d/assets/ironworks/catalog.json`.

const CATALOG: Dictionary = {
	"units": "meters", "origin": "ground center", "front": "+Z",
	"assets": [
		{"id": "soubassement_2m", "size_m": [1.98, 0.68, 0.4], "ground_pivot": true,
		 "bounds_center_m": [0.0, 0.34, 0.0], "collision_shapes": 12,
		 "scene": "res://assets/ironworks/modules/soubassement_2m.tscn"},
		{"id": "portail_cour", "size_m": [3.26, 1.5, 1.37], "ground_pivot": true,
		 "bounds_center_m": [0.0, 0.75, 0.585], "collision_shapes": 6,
		 "scene": "res://assets/ironworks/modules/portail_cour.tscn"},
		{"id": "charrette_ore", "size_m": [2.0, 1.65, 4.03], "ground_pivot": true,
		 "bounds_center_m": [0.0, 0.817, 1.039], "collision_shapes": 2,
		 "scene": "res://assets/ironworks/stockage/charrette_ore.tscn"},
		{"id": "centred_thing", "size_m": [1.0, 2.0, 1.0], "ground_pivot": false,
		 "bounds_center_m": [0.0, 0.5, 0.0], "collision_shapes": 1, "scene": "res://x.tscn"},
	],
}

const ORIGIN: Vector2 = Vector2(-384.0, -384.0)
const TILE: float = 2.0


func test_an_entry_is_found_by_id_and_its_size_is_his() -> void:
	var wall: Dictionary = CatalogRules.entry(CATALOG, "soubassement_2m")
	assert_eq(String(wall["id"]), "soubassement_2m", "found")
	assert_eq(CatalogRules.size_m(wall), Vector3(1.98, 0.68, 0.4), "his size, in metres")
	assert_eq(CatalogRules.scene_of(wall), "res://assets/ironworks/modules/soubassement_2m.tscn", "his scene")
	assert_true(CatalogRules.entry(CATALOG, "fence_2m").is_empty(), "a piece he has not made is nothing")


func test_a_yaw_turns_x_along_a_run_and_z_to_its_front() -> void:
	# Godot's basis: at 0° +X is east and +Z south; at 90° +X is north and +Z east.
	assert_eq(CatalogRules.yaw_along(Vector2.RIGHT), 0.0, "a run east is laid at 0°")
	assert_eq(CatalogRules.yaw_along(Vector2.UP), 90.0, "a run north is laid at 90°")
	assert_eq(CatalogRules.yaw_along(Vector2.DOWN), -90.0, "a run south at −90°")
	var east: Vector2 = CatalogRules.to_world(Vector2(1.0, 0.0), Vector2.ZERO, 0.0)
	assert_true(east.distance_to(Vector2.RIGHT) < 0.001, "local +X at 0° is east: %s" % east)
	var front: Vector2 = CatalogRules.to_world(Vector2(0.0, 1.0), Vector2.ZERO, 90.0)
	assert_true(front.distance_to(Vector2.RIGHT) < 0.001, "the front of a piece turned 90° faces east: %s" % front)
	var along: Vector2 = CatalogRules.to_world(Vector2(1.0, 0.0), Vector2.ZERO, 90.0)
	assert_true(along.distance_to(Vector2.UP) < 0.001, "and its length runs north: %s" % along)


func test_a_footprint_is_the_turned_size_in_tiles() -> void:
	var gate: Dictionary = CatalogRules.entry(CATALOG, "portail_cour")
	assert_eq(CatalogRules.footprint_tiles(gate, 0.0, TILE), Vector2i(2, 1), "3.26 × 1.37 m lying east–west")
	assert_eq(CatalogRules.footprint_tiles(gate, 90.0, TILE), Vector2i(1, 2), "and north–south when turned")
	var cart: Dictionary = CatalogRules.entry(CATALOG, "charrette_ore")
	assert_eq(CatalogRules.footprint_tiles(cart, 0.0, TILE), Vector2i(1, 3), "a 4 m cart is three tiles long")
	var wall: Dictionary = CatalogRules.entry(CATALOG, "soubassement_2m")
	assert_eq(CatalogRules.footprint_tiles(wall, 0.0, TILE), Vector2i(1, 1), "a 2 m module is one tile")
	assert_eq(CatalogRules.footprint_tiles(wall, 45.0, TILE), Vector2i(1, 1),
		"turned 45° it reaches 1.68 m across, still one tile")


func test_a_ground_pivot_is_not_lifted_and_a_centre_pivot_is() -> void:
	assert_eq(CatalogRules.lift_m(CatalogRules.entry(CATALOG, "soubassement_2m")), 0.0,
		"his pieces stand on their origin")
	assert_eq(CatalogRules.lift_m(CatalogRules.entry(CATALOG, "centred_thing")), 0.5,
		"a piece pivoted at its middle is lifted by half its height less its bounds' offset")


func test_modules_are_laid_at_his_pitch_from_the_start_and_whole() -> void:
	var centres: Array[Vector2] = CatalogRules.modules_along(Vector2(0.0, 0.0), Vector2(7.0, 0.0))
	assert_eq(centres.size(), 3, "seven metres take three whole 2 m modules, not three and a half")
	assert_eq(centres[0], Vector2(1.0, 0.0), "the first starts exactly at the run's start")
	assert_eq(centres[2], Vector2(5.0, 0.0), "and the leftover is at the far end")
	assert_eq(CatalogRules.modules_along(Vector2.ZERO, Vector2(0.0, 6.0)).size(), 3, "a run south lays the same")
	assert_eq(CatalogRules.modules_along(Vector2.ZERO, Vector2.ZERO).size(), 0, "a run of no length lays nothing")


func test_a_run_through_one_of_his_walls_is_noticed() -> void:
	var his: Array = [[[276.8, 46.0], [277.2, 46.0], [277.2, 48.0], [276.8, 48.0]]]
	assert_true(CatalogRules.segment_crosses(Vector2(275.0, 47.0), Vector2(279.0, 47.0), his),
		"a module laid across his wall crosses it")
	assert_false(CatalogRules.segment_crosses(Vector2(275.0, 48.8), Vector2(279.0, 48.8), his),
		"one laid past its end does not")


func test_what_a_piece_blocks_is_its_shapes_not_its_box() -> void:
	# A 2 m module centred on tile (320, 201)'s row, standing at x 255.2–257.2 and
	# z 19.37–19.77 like the yard's north wall: four blocks with two-centimetre joints,
	# one joint exactly at the module's centre.
	var blocks: Array = []
	for x: float in [255.45, 255.95, 256.45, 256.95]:
		blocks.append([[x - 0.24, 19.37], [x + 0.24, 19.37], [x + 0.24, 19.77], [x - 0.24, 19.77]])
	var origin: Vector2i = BakeRules.tile_for(256.2, 19.57, ORIGIN, TILE)
	assert_eq(origin, Vector2i(320, 201), "the module's own tile")
	var blocked: Array[Vector2i] = CatalogRules.blocked_tiles(blocks, origin, ORIGIN, TILE)
	assert_eq(blocked, [Vector2i(320, 201)] as Array[Vector2i],
		"one tile: its own, and the joint at its centre does not open it: %s" % str(blocked))
	# The same module with no origin given — a gate, whose origin is its passage — blocks
	# only what its shapes reach, which for a thin wall between tile centres is nothing.
	var loose: Array[Vector2i] = CatalogRules.blocked_tiles(blocks, Region.NOWHERE, ORIGIN, TILE)
	assert_eq(loose.size(), 0, "a passage stops nobody: %s" % str(loose))
	# A big roof box would have blocked a 2×2; two piers standing on two tile centres
	# block those two tiles and the hall between them stays open.
	var piers: Array = [
		[[264.9, 44.8], [265.3, 44.8], [265.3, 45.2], [264.9, 45.2]],
		[[269.0, 44.8], [269.4, 44.8], [269.4, 45.2], [269.0, 45.2]]]
	var under: Array[Vector2i] = CatalogRules.blocked_tiles(piers, Region.NOWHERE, ORIGIN, TILE)
	assert_eq(under, [Vector2i(324, 214), Vector2i(326, 214)] as Array[Vector2i],
		"an open hall on piers is walkable under its roof: %s" % str(under))
	# And a pier well off a tile's centre — 0.4 m, more than `REACH_M` — leaves the tile
	# open, as his own buildings have always done: a 2 m tile is not closed by a post.
	var aside: Array = [[[264.9, 44.4], [265.3, 44.4], [265.3, 44.6], [264.9, 44.6]]]
	assert_eq(CatalogRules.blocked_tiles(aside, Region.NOWHERE, ORIGIN, TILE).size(), 0,
		"a post 0.4 m from a tile's centre does not close the tile")
