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
## hail's ground, a pack — each checked where its anchor puts it, **before anything nudges
## it** (the review of Z): the cast, the fires and the papers are moved off ground nobody can
## stand on when the world is built, so asking where they ended up would always pass.
## `test_anchors` refuses any anchor off open ground; this names the closure it is in.
func test_nobody_stands_where_the_zone_is_closed() -> void:
	if not Places.baked():
		off("the start zone is the baked world's (group Z)")
		return
	var region: Region = Region.build_overworld()
	var places: Places = Places.shared()
	var anchors: Array = []
	for id: StringName in places.cast_ids():
		anchors.append(["cast:%s" % id, places.cast_anchor(id)])
	for anchor: Dictionary in places.strangers():
		anchors.append(["a stranger", anchor])
	for anchor: Dictionary in places.campfires():
		anchors.append(["a fire", anchor])
	for anchor: Dictionary in places.stalls():
		anchors.append(["a stall", anchor])
	for fact: StringName in DocumentRules.facts():
		anchors.append(["the papers %s" % fact, places.document(fact)])
	for anchor: Dictionary in places.hail_anchors():
		anchors.append(["a hail", anchor])
	for pack: Dictionary in places.wild():
		anchors.append(["a pack", pack["anchor"]])
	for find: Dictionary in places.finds():
		anchors.append(["the find %s" % find["id"], find["anchor"]])
	for row: Array in anchors:
		var at: Vector2i = region.resolve(row[1] as Dictionary)
		assert_eq(region.closure_at(at), &"", "%s at %s is not in a closure" % [row[0], at])
	assert_true(anchors.size() > 40, "%d anchors checked" % anchors.size())


## **What the demo needs is a walk away** (the review of Z): everything the content stands
## in Brindle and the Forges — people, fires, stalls, papers, the find on a grave, the
## hail's ground — can be walked to from the cemetery. The claims about the whole map moved
## to the open world; these are the ones about the zone.
func test_the_demo_is_whole_inside_the_zone() -> void:
	if not Places.baked():
		off("the start zone is the baked world's (group Z)")
		return
	var region: Region = Region.build_overworld()
	var zone: Dictionary = _zone(region)
	var places: Places = Places.shared()
	var anchors: Array = []
	for id: StringName in places.cast_ids():
		anchors.append(["cast:%s" % id, places.cast_anchor(id)])
	for anchor: Dictionary in places.strangers() + places.campfires() + places.stalls() + places.hail_anchors():
		anchors.append(["%s" % Places.describe(anchor), anchor])
	for fact: StringName in DocumentRules.facts():
		anchors.append(["the papers %s" % fact, places.document(fact)])
	for find: Dictionary in places.finds():
		anchors.append(["the find %s" % find["id"], find["anchor"]])
	var checked: int = 0
	for row: Array in anchors:
		var at: Vector2i = region.resolve(row[1] as Dictionary)
		if not (region.zone_at(at) in [&"brindle", &"cinderworks"]):
			continue
		checked += 1
		assert_true(_beside(zone, at), "%s at %s can be walked to from the cemetery" % [row[0], at])
	assert_true(checked >= 15, "%d of the demo's people and things checked" % checked)


## **A fire you can rest at puts you back inside** (the review of Z): you rest at the first
## fire within `RecoveryRules.FIRE_REACH` of where you stand, and dying puts you a tile
## south of it. So every fire within reach of the zone must give back a tile of the zone —
## a fire across the river within reach of its bank would be a door out.
func test_a_fire_you_can_rest_at_puts_you_back_inside() -> void:
	if not Places.baked():
		off("the start zone is the baked world's (group Z)")
		return
	var region: Region = Region.build_overworld()
	var zone: Dictionary = _zone(region)
	var usable: Dictionary = {}
	for prop: Dictionary in region.props:
		if (prop["kind"] as StringName) != &"campfire":
			continue
		var at: Vector2i = prop["at"] as Vector2i
		for dy: int in range(-4, 5):
			for dx: int in range(-4, 5):
				var tile: Vector2i = at + Vector2i(dx, dy)
				if zone.has(tile):
					var fire: Vector2i = region.nearest_campfire(tile, RecoveryRules.FIRE_REACH)
					if fire != Region.NOWHERE:
						usable[fire] = true
	for fire: Variant in usable.keys():
		var back: Vector2i = (fire as Vector2i) + Vector2i(0, 1)
		assert_true(zone.has(back), "resting at the fire at %s puts you back at %s, inside" % [fire, back])
	assert_true(usable.size() >= 3, "the zone has its fires: %d" % usable.size())


func _beside(zone: Dictionary, at: Vector2i) -> bool:
	for dy: int in range(-3, 4):
		for dx: int in range(-3, 4):
			if zone.has(at + Vector2i(dx, dy)):
				return true
	return false


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
