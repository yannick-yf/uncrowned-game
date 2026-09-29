extends TestCase

## The contract between the content and the map (MIGRATION_3D §6.2, M1a).
##
## A position is an anchor — a place or a point plus an offset, or a feature standing
## in a place — and every anchor the content references resolves. The map is about to
## move under the content, and this is the test that says *which name* stopped meaning
## anywhere, before anyone plays: `cast:maddox harrowgate.inn+(0,1)` is a sentence,
## and a person standing at (0, 0) in the sea is a mystery.


func test_every_anchor_resolves_by_name() -> void:
	var region: Region = Region.build_overworld()
	var missing: Array[String] = []
	var owed: Array[String] = []
	for name: String in region.unresolved_anchors():
		# The first pack is anchored where his map has a bridge, which on the 2D map is off
		# its edge: the 2D map's own debt, and said so, as the ground check below says it.
		if not Places.baked() and name.begins_with("wild:"):
			owed.append(name)
		else:
			missing.append(name)
	assert_eq(missing.size(), 0, "anchors that resolve nowhere: %s" % ", ".join(missing))
	if not owed.is_empty():
		debt("the packs are anchored to his map; the 2D one stands nothing there: %s" % ", ".join(owed))


func test_an_anchor_nobody_placed_is_named_not_guessed() -> void:
	var region: Region = Region.build_overworld()
	assert_eq(region.resolve({"place": &"atlantis", "offset": Vector2i.ZERO}), Region.NOWHERE,
		"an unknown place is nowhere, not the first place in the list")
	assert_eq(region.resolve({"point": &"the_far_side", "offset": Vector2i.ZERO}), Region.NOWHERE,
		"an unknown point is nowhere")
	assert_eq(region.resolve({}), Region.NOWHERE, "no anchor at all is nowhere")
	assert_eq(Places.describe({"place": &"harrowgate", "feature": &"inn", "offset": Vector2i(2, -3)}),
		"harrowgate.inn+(2,-3)", "and the message reads the way the file is written")
	assert_eq(Places.NOWHERE, Region.NOWHERE, "one sentinel, spelled twice on purpose")


func test_a_feature_anchor_finds_the_thing_standing_in_the_place() -> void:
	var region: Region = Region.build_overworld()
	var inn: Vector2i = region.resolve({"place": &"harrowgate", "feature": &"inn",
		"offset": Vector2i.ZERO})
	assert_ne(inn, Region.NOWHERE, "Harrowgate has an inn")
	assert_eq(region.zone_at(inn), &"harrowgate", "and it stands in Harrowgate")
	var beside: Vector2i = region.resolve({"place": &"harrowgate", "feature": &"inn",
		"offset": Vector2i(0, 4)})
	assert_eq(beside, inn + Vector2i(0, 4), "an offset is from the feature, not the place")
	assert_eq(region.resolve({"place": &"harrowgate", "feature": &"keep", "offset": Vector2i.ZERO}),
		Region.NOWHERE, "Harrowgate has no keep, and the anchor says so rather than borrowing Blackcairn's")


func test_the_sheets_carry_no_coordinates() -> void:
	# A position is not language content, and it was written twice — once per sheet.
	for language: String in ["fr", "en"]:
		var root: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string(Cast.CAST_PATH % language)) as Dictionary
		var npcs: Dictionary = root.get("npcs", {}) as Dictionary
		assert_true(npcs.size() >= 25, "%s: the cast is there" % language)
		for id: String in npcs.keys():
			assert_false((npcs[id] as Dictionary).has("tile"),
				"%s carries a tile in the %s sheet; positions live in content/places.json" % [id, language])
		assert_false((root.get("strangers", {}) as Dictionary).has("placements"),
			"strangers are placed in content/places.json, not in the %s sheet" % language)


func test_everybody_named_is_placed_and_nobody_placed_is_unnamed() -> void:
	var places: Places = Places.shared()
	var cast: Cast = Cast.shared()
	for npc: Npc in cast.named():
		assert_false(places.cast_anchor(npc.id).is_empty(), "%s has no anchor" % npc.id)
		assert_ne(npc.tile, Region.NOWHERE, "%s stands somewhere" % npc.id)
	for id: StringName in places.cast_ids():
		assert_not_null(cast.get_npc(id), "places.json places %s, who is not in the cast" % id)
	assert_eq(cast.npcs.size() - cast.named().size(), places.strangers().size(),
		"every placement in the file became a stranger, and no stranger came from anywhere else")


func test_the_sites_are_the_files() -> void:
	var places: Places = Places.shared()
	assert_eq(places.ids(), Region.ZONE_ORDER, "the eight places, in zone order")
	for id: StringName in Region.ZONE_ORDER:
		assert_eq(Region.zone_sites()[id], places.centre(id), "%s's centre is the file's" % id)
		assert_eq(Region.zone_footprints()[id], places.size(id), "%s's footprint is the file's" % id)
	assert_eq(Region.CLEARING, places.point(&"clearing"), "the clearing is the file's")
	# O3: the start is its own name, and every new run is put on it.
	assert_ne(Region.START, Region.NOWHERE, "the start resolves")
	assert_eq(where_the_game_starts(), Region.START, "and the tests mean the same point")
	var sim: Sim = Game.build()
	assert_eq((sim.store(&"world") as WorldState).player_pos,
		(sim.store(&"world") as WorldState).region().start_centre(), "a new run wakes on it")
	assert_eq(Region.BRIDGE, places.point(&"bridge"), "and the bridge")
	assert_eq(Region.FORD, places.point(&"ford"), "and the ford")


## **An anchor stands on ground before anything moves it** (O14, 2026-09-29). Offsets
## are shared between the two worlds, and Brindle is 35×30 on his map but 15×11 on the
## 2D one, so an offset that is a verge on one is a wall or the river on the other.
## `Region.open_near` then moves the fire, the paper or the man somewhere near, quietly —
## eight of them were standing somewhere nobody chose. This names them instead.
##
## One is the 2D map's own debt and says so: the first wolf pack is anchored where his
## map has a bridge, and on the 2D map that is the mountain.
func test_every_anchor_stands_on_open_ground_before_it_is_nudged() -> void:
	var region: Region = Region.build_overworld()
	var off: Array[String] = region.anchors_off_ground()
	var owed: Array[String] = []
	var wrong: Array[String] = []
	for name: String in off:
		if not Places.baked() and name.begins_with("wild:"):
			owed.append(name)
		else:
			wrong.append(name)
	assert_eq(wrong.size(), 0, "anchors on ground nobody can stand on: %s" % ", ".join(wrong))
	if not owed.is_empty():
		debt("the packs are anchored to his map; the 2D one stands nothing there: %s" % ", ".join(owed))


func test_bram_calls_from_named_ground_on_both_worlds() -> void:
	# O14: his post and the zone he calls from are points of their own on each world,
	# never Brindle plus an offset.
	var places: Places = Places.shared()
	for id: StringName in [&"bram_post", &"brindle_hail", &"brindle_hail_east"]:
		assert_true(places.has_point(id), "%s is a named point on this world" % id)
		var region: Region = Region.build_overworld()
		var at: Vector2i = places.point(id)
		assert_true(region.is_passable(at), "%s stands on open ground: %s" % [id, at])
		assert_eq(region.zone_at(at), &"brindle", "and in the ruined village")
	assert_eq(places.cast_anchor(&"bram").get("point", &""), &"bram_post", "Bram stands at his post")
