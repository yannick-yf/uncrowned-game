extends TestCase

## **The start zone** (group Z, 2026-10-08). Yannick: the castle and the other villages
## are still being drawn, so the demo's player stays in a closed zone — the cemetery,
## Brindle, the tutorial, the wolves and the Forges — as Breath of the Wild's Great
## Plateau. His river, the sea and his mountains close most of it; the brief closes the
## rest (his bridge north of Brindle, a wood round the Forges, a wood west of Brindle).
##
## These walk the world the way a player does — Navigation's step, no corner cutting —
## from where a run begins. A leak anywhere in the edge is a zone of seventy thousand
## tiles, so the zone's size is a check of its own.

const SLOW: bool = false

## About 10,000 tiles when it was planned (4 ha). The bounds are wide on purpose: the
## edges wander, and what this guards against is a leak, which is seven times as large.
const ZONE_AT_MOST: int = 14000
const ZONE_AT_LEAST: int = 7000


func _zone(region: Region) -> Dictionary:
	return Navigation.reachable(region, Places.shared().point(&"cemetery"))


func test_the_zone_holds_what_the_demo_needs() -> void:
	if not Places.baked():
		off("the start zone is the baked world's (group Z)")
		return
	var region: Region = Region.build_overworld()
	var zone: Dictionary = _zone(region)
	var places: Places = Places.shared()
	assert_true(zone.has(places.centre(&"brindle")), "Brindle")
	for point: StringName in [&"cemetery", &"bram_post", &"brindle_hail", &"kell_fire",
			&"PasserelleLisiere", &"PontMine", &"cinderworks_gate"]:
		assert_true(zone.has(places.point(point)), "%s is in the zone" % point)
	assert_true(zone.has(Wild.new().at(region, 0)), "the wolves before the Forges' bridge")
	var yard: Dictionary = region.yards[0] as Dictionary
	assert_true(zone.has(yard["inside"] as Vector2i), "the furnaces' yard, past its gate")


func test_nothing_beyond_the_zone_can_be_walked_to() -> void:
	if not Places.baked():
		off("the start zone is the baked world's (group Z)")
		return
	var zone: Dictionary = _zone(Region.build_overworld())
	var places: Places = Places.shared()
	for place: StringName in [&"harrowgate", &"cairnwell", &"blackcairn", &"wide_acres", &"muster",
			&"saltmarch"]:
		assert_false(zone.has(places.centre(place)), "%s is out of reach" % place)
	# The Scierie has no place of ours: his bridge into it stands for it.
	for point: StringName in [&"PontVillageScierie", &"PontScierie", &"PontRouteRoyale", &"PontBrindle",
			&"ford", &"ferry", &"road_long_stretch"]:
		assert_false(zone.has(places.point(point)), "%s is out of reach" % point)
	assert_true(zone.size() <= ZONE_AT_MOST and zone.size() >= ZONE_AT_LEAST,
		"the zone is about 10,000 tiles: %d" % zone.size())


## **Nobody stands in a closure** (Z3): not a person, a fire, a stall, a paper, a find, a
## pack. A man in a wood would be a conversation that cannot be had.
func test_nobody_stands_where_the_zone_is_closed() -> void:
	if not Places.baked():
		off("the start zone is the baked world's (group Z)")
		return
	var region: Region = Region.build_overworld()
	var checked: int = 0
	for npc: Npc in Cast.shared().named():
		if npc.zone != WorldState.OVERWORLD:
			continue
		assert_eq(region.closure_at(npc.tile), &"", "%s does not stand in %s" % [npc.id, region.closure_at(npc.tile)])
		checked += 1
	for prop: Dictionary in region.props:
		var kind: StringName = prop["kind"] as StringName
		if kind in [&"campfire", &"stall"] or prop.has("fact"):
			assert_eq(region.closure_at(prop["at"] as Vector2i), &"", "the %s at %s is not in a closure" % [kind, prop["at"]])
			checked += 1
	for find: Dictionary in Places.shared().finds():
		var at: Vector2i = region.resolve(find["anchor"] as Dictionary)
		assert_eq(region.closure_at(at), &"", "the find %s is not in a closure" % find["id"])
	var wild := Wild.new()
	for which: int in Wild.packs().size():
		assert_eq(region.closure_at(wild.at(region, which)), &"", "pack %d does not stand in a closure" % which)
	assert_true(checked > 20, "%d people and things checked" % checked)


## The closures are a layer over the world, not a rewrite of it: the same file without
## them is the open world, so opening the zone one day is taking an entry out.
func test_the_closures_are_a_layer_over_an_open_world() -> void:
	if not Places.baked():
		off("the start zone is the baked world's (group Z)")
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(Places.BAKED_PATH))
	assert_true(data is Dictionary, "the baked world reads")
	var closed: Dictionary = (data as Dictionary).duplicate()
	assert_eq(((closed.get("closures", []) as Array)).size(), 3, "the bridge and the two woods")
	var open: Dictionary = (data as Dictionary).duplicate()
	open.erase("closures")
	var places: Places = Places.shared()
	var everywhere: Dictionary = _zone(RegionBake.read(open))
	for place: StringName in [&"harrowgate", &"cairnwell", &"blackcairn"]:
		assert_true(everywhere.has(places.centre(place)), "without its closures, %s is a walk away" % place)
	assert_false(_zone(RegionBake.read(closed)).has(places.centre(&"harrowgate")), "and with them it is not")
