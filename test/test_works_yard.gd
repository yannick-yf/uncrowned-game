extends TestCase

## The Cinderworks' production yard: his stone modules in a closed line, his gate in it,
## and a man in the gate's passage.
##
## **Rebuilt from his catalogue on 2026-09-21 (G1–G4).** The first yard (Q1) was a
## one-tile rectangle of generic fence stamped on two computed corners — no facing, no
## metre dimensions, no gate, and ten of its pieces planted in the river. It is now
## composed in `content/bake_brief.json` from the pieces his own catalogue documents
## for the job: `soubassement_2m` (*module de séparation de cour*), `portail_cour`
## (*passage central de 2,6 m*), `enseigne_forge`. What each piece stops is what its own
## collision shapes cover, and the bake refuses a yard that does not close.
##
## **Why a man and not a lock.** The gate's passage is open ground, warded: somebody
## stands in it, and getting past him is a **fact** rather than a flag — invariant 4
## working rather than being bent.
##
## **Baked world only.** The yard is composed in his metres against his buildings and
## his river, and the procedural map has neither. The baked world is the game (M4
## cut-over); the procedural one is kept for its tests and its history.

const SLOW: bool = true

const VOUCHED: StringName = &"cinderworks:vouched_for"
const WALL_PIECE: String = "soubassement_2m"
const GATE_PIECE: String = "portail_cour"
const SIGN_PIECE: String = "enseigne_forge"


func _works_centre() -> Vector2i:
	return Places.shared().centre(&"cinderworks")


## Everywhere a walker can get to from the quarter, honouring the wall *and* the watch.
## `Region.is_passable` alone answers a different question: the ground is walkable under
## a guard, which is the whole point of him.
func _reachable_from_the_quarter(sim: Sim) -> Dictionary:
	var region: Region = (sim.store(&"world") as WorldState).region()
	var centre: Vector2i = _works_centre()
	var from: Vector2i = centre + Vector2i(-10, -6)
	var seen: Dictionary = {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_back()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = at + step
			if seen.has(next) or not region.in_bounds(next) or not region.is_passable(next):
				continue
			if region.wards.has(next) \
					and not WardRules.opens(region.wards[next] as StringName, sim.facts):
				continue
			if absi(next.x - centre.x) > 45 or absi(next.y - centre.y) > 45:
				continue
			seen[next] = true
			queue.append(next)
	return seen


func _a_furnace() -> Vector2i:
	var region: Region = Region.build_overworld()
	for prop: Dictionary in region.props:
		if String(prop["kind"]) == "kiln":
			return prop["at"] as Vector2i
	return Vector2i(-1, -1)


func _pieces(region: Region, piece: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for prop: Dictionary in region.props:
		if String(prop.get("piece", "")) == piece:
			out.append(prop)
	return out


func _the_yard(region: Region) -> Dictionary:
	for yard: Dictionary in region.yards:
		if String(yard["place"]) == "cinderworks":
			return yard
	return {}


func test_the_furnaces_are_behind_something() -> void:
	if not Places.baked():
		debt("the yard is composed against his buildings and his river, which the 2D map has not")
		return
	var sim: Sim = Game.build()
	var furnace: Vector2i = _a_furnace()
	assert_true(furnace.x > 0, "there is a furnace to be kept from")
	var reached: Dictionary = _reachable_from_the_quarter(sim)
	assert_false(reached.has(furnace),
		"a stranger walking from the quarter cannot get to it: %s" % str(furnace))
	assert_true(reached.size() > 2000,
		"and the rest of the world is still open to them: %d tiles" % reached.size())


func test_being_vouched_for_is_what_gets_you_in() -> void:
	# **A fact, not a flag.** Nothing here asks whether a quest is done, which is why
	# there can be two ways in — Tom's and Sena's — and why killing one of them does
	# not close the works for ever (invariant 6).
	if not Places.baked():
		debt("the yard is the baked world's")
		return
	var sim: Sim = Game.build()
	var furnace: Vector2i = _a_furnace()
	assert_false(_reachable_from_the_quarter(sim).has(furnace), "shut to begin with")

	sim.facts.add_source(VOUCHED, &"sena")
	assert_true(_reachable_from_the_quarter(sim).has(furnace),
		"and open to somebody the works vouched for")


func test_the_gate_has_more_than_one_key() -> void:
	# A gate one death closes for ever is the thing invariant 6 exists to prevent.
	assert_true(WardRules.is_warded(&"cinderworks_gate"), "the gateway is watched")
	assert_true((WardRules.KEYS[&"cinderworks_gate"] as Array).size() >= 2,
		"and more than one thing opens it")
	assert_true(WardRules.opens(&"nowhere_in_particular", null),
		"anywhere nobody watches is simply open")


# ------------------------------------------------- composed from his catalogue (G1–G2) ---

func test_the_wall_is_his_modules_laid_end_to_end() -> void:
	# **His note says how**: *extrémités à X = ±1 m ; dupliquer pour prolonger*. So the
	# modules stand at a 2 m pitch, each turned to lie along its run, and each stops a
	# walker on the tile it stands on — a line, not a row of posts.
	if not Places.baked():
		debt("the yard is the baked world's")
		return
	var region: Region = Region.build_overworld()
	var walls: Array[Dictionary] = _pieces(region, WALL_PIECE)
	assert_true(walls.size() >= 30, "the yard is walled with his stone: %d modules" % walls.size())
	var yaws: Dictionary = {}
	for wall: Dictionary in walls:
		var xz: Vector2 = wall["xz"] as Vector2
		var yaw: float = float(wall["yaw"])
		yaws[roundi(yaw)] = true
		assert_true(is_equal_approx(fmod(absf(yaw), 90.0), 0.0), "%s lies along an axis: %.1f°" % [str(xz), yaw])
		assert_false(region.is_passable(wall["at"] as Vector2i), "every module stops you: %s does not" % str(xz))
		var neighbours: int = 0
		for other: Dictionary in walls:
			var gap: float = (other["xz"] as Vector2).distance_to(xz)
			if gap > 0.01 and gap < 2.05:
				neighbours += 1
		assert_true(neighbours >= 1, "%s has a module 2 m from it, end marker to end marker" % str(xz))
	assert_true(yaws.size() >= 2, "and the runs turn corners: yaws %s" % str(yaws.keys()))
	# A wall is 0.4 m thick and a tile 2 m: what a module blocks is its own tile and
	# never a 2×2 box round it.
	for wall: Dictionary in walls:
		var size: Vector2i = wall["size"] as Vector2i
		assert_true(size.x * size.y <= 2, "%s blocks %s, not a box" % [str(wall["xz"]), str(size)])


func test_the_gate_is_his_and_its_passage_is_open_ground_with_a_ward_on_it() -> void:
	# `portail_cour`: *deux battants ouverts… passage central de 2,6 m*. Its origin is
	# the middle of that passage, and the passage stops nobody by itself.
	if not Places.baked():
		debt("the yard is the baked world's")
		return
	var region: Region = Region.build_overworld()
	var gates: Array[Dictionary] = _pieces(region, GATE_PIECE)
	assert_eq(gates.size(), 1, "one gate, and it is his")
	var yard: Dictionary = _the_yard(region)
	assert_false(yard.is_empty(), "the bake recorded the yard")
	var passage: Vector2i = yard["passage"] as Vector2i
	assert_true(region.is_passable(passage), "the passage is open ground: %s" % str(passage))
	assert_eq(region.wards.get(passage, &""), &"cinderworks_gate", "with the ward on it")
	assert_eq(region.wards.size(), 1, "and the passage is the only warded tile: %s" % str(region.wards.keys()))
	assert_eq(Places.shared().point(&"cinderworks_gate"), passage, "the gate is a point content can stand at")
	assert_eq(_pieces(region, SIGN_PIECE).size(), 1, "and his sign hangs at the entrance")


func test_the_yard_is_closed_by_things_you_can_see() -> void:
	# **What stops you must be seen**, and its other half: what does not stop you must
	# not be drawn as though it does. A walk from inside the passage may reach the
	# outside only through it; and on the way it meets his walls, his buildings and his
	# water, never a bare tile.
	if not Places.baked():
		debt("the yard is the baked world's")
		return
	var region: Region = Region.build_overworld()
	var yard: Dictionary = _the_yard(region)
	var passage: Vector2i = yard["passage"] as Vector2i
	var inside: Vector2i = yard["inside"] as Vector2i
	var covered: Dictionary = {}
	for prop: Dictionary in region.props:
		var at: Vector2i = prop["at"] as Vector2i
		var size: Vector2i = prop.get("size", Vector2i.ONE) as Vector2i
		for dx: int in size.x:
			for dy: int in size.y:
				covered[at + Vector2i(dx, dy)] = true
	var seen: Dictionary = {inside: true}
	var queue: Array[Vector2i] = [inside]
	var bare: Array[String] = []
	var water: int = 0
	while not queue.is_empty():
		var at: Vector2i = queue.pop_back()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = at + step
			if seen.has(next) or next == passage:
				continue
			if not region.is_passable(next):
				var here: Region.Terrain = region.terrain_at(next)
				if here == Region.Terrain.WATER:
					water += 1
				elif here == Region.Terrain.WALL and not covered.has(next):
					bare.append(str(next))
				continue
			seen[next] = true
			queue.append(next)
	assert_true(seen.size() < 600, "the walk stays in the yard: %d tiles" % seen.size())
	assert_true(seen.has(_a_furnace() + Vector2i(0, 1)) or seen.size() > 100,
		"and the furnaces are in it")
	assert_true(water > 10, "the river is the east edge, with nothing built along it: %d wet tiles met" % water)
	assert_eq(bare.size(), 0, "every wall met is under something drawn: %s" % ", ".join(bare))


func test_no_piece_stands_where_it_closes_nothing() -> void:
	# **Yannick played it and saw a palisade in the river.** The first yard's east side
	# ran along his water and ten pieces were planted in it — closing nothing, in front
	# of a bank that already stopped you. Now a run toward the water stops on the bank,
	# and a piece may stand along a road's edge but never across the road.
	if not Places.baked():
		debt("the yard is the baked world's")
		return
	var region: Region = Region.build_overworld()
	var loose: PackedStringArray = PackedStringArray()
	for prop: Dictionary in region.props:
		if not prop.has("piece"):
			continue
		var at: Vector2i = prop["at"] as Vector2i
		var size: Vector2i = prop["size"] as Vector2i
		for dx: int in size.x:
			for dy: int in size.y:
				var tile: Vector2i = at + Vector2i(dx, dy)
				if region.terrain_at(tile) == Region.Terrain.WATER:
					loose.append("%s stands in the river at %s" % [prop["piece"], str(tile)])
		if String(prop["role"]) == "gate":
			continue
		var road_both_sides: bool = false
		for axis: Array in [[Vector2i.UP, Vector2i.DOWN], [Vector2i.LEFT, Vector2i.RIGHT]]:
			var a: Vector2i = at + (axis[0] as Vector2i)
			var b: Vector2i = at + (axis[1] as Vector2i)
			if region.terrain_at(a) == Region.Terrain.ROAD and region.terrain_at(b) == Region.Terrain.ROAD:
				road_both_sides = true
		if road_both_sides and region.terrain_at(at) == Region.Terrain.WALL:
			loose.append("%s stands across a road at %s" % [prop["piece"], str(at)])
	assert_eq(loose.size(), 0, "pieces that close nothing:\n  %s" % "\n  ".join(loose))


func test_the_ground_changes_across_the_threshold() -> void:
	# **G4.** Inside the wall the ground is the works' cinder; outside it is the
	# quarter's. A player who has crossed the line can tell without a word.
	if not Places.baked():
		debt("the yard is the baked world's")
		return
	var region: Region = Region.build_overworld()
	var yard: Dictionary = _the_yard(region)
	var floor: Array = yard["floor"]
	assert_true(floor.size() > 100, "the yard has a floor: %d tiles" % floor.size())
	var cinder: int = 0
	for tile: Vector2i in floor:
		if region.terrain_at(tile) == Region.Terrain.TOWN:
			cinder += 1
	assert_true(cinder * 10 >= floor.size() * 8, "and most of it is the works' ground: %d of %d" % [cinder, floor.size()])
	var passage: Vector2i = yard["passage"] as Vector2i
	var inside: Vector2i = yard["inside"] as Vector2i
	var outside: Vector2i = passage - (inside - passage)
	var out_of_it: int = 0
	for step: int in range(2, 6):
		var tile: Vector2i = outside + (outside - passage) * step
		if region.terrain_at(tile) != Region.Terrain.TOWN:
			out_of_it += 1
	assert_true(out_of_it >= 3, "while the street outside keeps its own ground")


func test_somebody_is_standing_in_it() -> void:
	# **With lines of his own** (G3): the man in the passage is the works' gatekeeper,
	# not a bridge guard who wandered in.
	var region: Region = Region.build_overworld()
	var cast := Cast.shared()
	var keeper: Npc = null
	for npc: Npc in cast.npcs.values():
		if npc.kind == &"gatekeeper":
			keeper = npc
	assert_not_null(keeper, "there is a gatekeeper")
	if keeper == null:
		return
	assert_true(keeper.greeting.length() > 0, "and he has something to say")
	assert_false(keeper.display_name.to_lower().contains("pont") or keeper.display_name.to_lower().contains("bridge"),
		"and it is not the bridge guard's: %s" % keeper.display_name)
	if not Places.baked():
		debt("the yard is the baked world's")
		return
	var yard: Dictionary = _the_yard(region)
	assert_eq(Vector2i(keeper.centre()), yard["passage"] as Vector2i, "he stands in the gate's passage")
	var keys: Dictionary = {}
	for option: DialogueOption in keeper.options:
		if option.requires != &"":
			keys[option.requires] = true
	for key: Variant in (WardRules.KEYS[&"cinderworks_gate"] as Array):
		assert_true(keys.has(key), "he answers to the key %s" % key)


func test_the_people_the_demo_asks_you_to_find_can_be_seen() -> void:
	# **This has cost two sessions now.** Bram stood behind one of his brother's trees,
	# and Sena under his roofs — both reachable, both talked to by a test, and neither
	# visible to a person playing. A prompt that says *E, talk to Sena* over a rooftop
	# is worse than nobody being there.
	#
	# Scoped to the three the demo sends the player to look for. The older cast has
	# people who stand inside buildings on purpose, and this is not a rule about them.
	var cast := Cast.shared()
	var region: Region = Region.build_overworld()
	var covered: Dictionary = {}
	for prop: Dictionary in region.props:
		var at: Vector2i = prop["at"] as Vector2i
		var size: Vector2i = prop.get("size", Vector2i.ONE) as Vector2i
		for dx: int in maxi(size.x, 1):
			for dy: int in maxi(size.y, 1):
				covered[at + Vector2i(dx, dy)] = String(prop["kind"])
	for who: StringName in [&"bram", &"tom", &"sena"]:
		var npc: Npc = cast.get_npc(who)
		assert_not_null(npc, "%s exists" % who)
		var at: Vector2i = Vector2i(npc.centre())
		assert_false(covered.has(at),
			"%s stands under a %s" % [who, covered.get(at, "")])
		# And not shoulder to shoulder with one either: his roofs overhang their tile.
		var crowded: int = 0
		for dx: int in range(-1, 2):
			for dy: int in range(-1, 2):
				if covered.has(at + Vector2i(dx, dy)):
					crowded += 1
		assert_true(crowded == 0, "%s has %d things within a pace of them" % [who, crowded])
