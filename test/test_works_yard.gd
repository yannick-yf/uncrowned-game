extends TestCase

## The Cinderworks' production yard (Q1): a fence in a ring, and a man in the gap.
##
## **Why a man and not a lock.** His street runs north-south straight through where the
## west wall wants to be, and this map's oldest map-rule is that a wall never closes a
## road — it has already caught a curtain wall sealing the only way into Blackcairn. So
## the road keeps its gap, somebody stands in it, and getting past him is a **fact**
## rather than a flag, which is invariant 4 working rather than being bent.
##
## **Baked world only.** The yard's corners are tile offsets tuned to *his* buildings —
## his homes at x −23..0, his kilns at +8..+16 — and the procedural map's kit stands
## nothing in those places. The baked world is the game (M4 cut-over); the procedural one
## is kept for its tests and its history, and this is a claim about a place that only
## exists on one of them.

const SLOW: bool = true

const VOUCHED: StringName = &"cinderworks:vouched_for"


func _works_centre() -> Vector2i:
	return Places.shared().centre(&"cinderworks")


## Everywhere a walker can get to from the quarter, honouring the fence *and* the watch.
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


func test_the_furnaces_are_behind_something() -> void:
	if not Places.baked():
		debt("the yard is the baked world's: its corners are his buildings' offsets")
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
	# there can be two ways in — Tom's and Drissa's — and why killing one of them does
	# not close the works for ever (invariant 6).
	if not Places.baked():
		debt("the yard is the baked world's")
		return
	var sim: Sim = Game.build()
	var furnace: Vector2i = _a_furnace()
	assert_false(_reachable_from_the_quarter(sim).has(furnace), "shut to begin with")

	sim.facts.add_source(VOUCHED, &"drissa")
	assert_true(_reachable_from_the_quarter(sim).has(furnace),
		"and open to somebody the works vouched for")


func test_the_gate_has_more_than_one_key() -> void:
	# A gate one death closes for ever is the thing invariant 6 exists to prevent.
	assert_true(WardRules.is_warded(&"cinderworks_gate"), "the gateway is watched")
	assert_true((WardRules.KEYS[&"cinderworks_gate"] as Array).size() >= 2,
		"and more than one thing opens it")
	assert_true(WardRules.opens(&"nowhere_in_particular", null),
		"anywhere nobody watches is simply open")


func test_the_wall_is_drawn_and_the_gap_is_not() -> void:
	# **What stops you must be seen**, and its other half, which cost a pass to learn:
	# what does *not* stop you must not be drawn as though it does. A fence standing
	# across his street that the player walks through is worse than an invisible wall —
	# one is a thing that fails, the other is a thing that is not there.
	if not Places.baked():
		debt("the yard is the baked world's")
		return
	var region: Region = Region.build_overworld()
	var fences: Dictionary = {}
	for prop: Dictionary in region.props:
		if String(prop["kind"]) == "yard_fence":
			fences[prop["at"] as Vector2i] = true
	assert_true(fences.size() > 30, "the yard is fenced: %d pieces" % fences.size())
	for at: Vector2i in fences.keys():
		assert_false(region.is_passable(at),
			"every piece of it stops you: %s does not" % str(at))
	for at: Vector2i in region.wards.keys():
		assert_false(fences.has(at), "and nothing is drawn across the way in: %s" % str(at))
		assert_true(region.is_passable(at),
			"which is open ground with a man on it, not a wall: %s" % str(at))


func test_somebody_is_standing_in_it() -> void:
	if not Places.baked():
		debt("the yard is the baked world's")
		return
	var region: Region = Region.build_overworld()
	var cast := Cast.shared()
	var nearest: float = 9999.0
	for npc: Npc in cast.npcs.values():
		if not String(npc.id).begins_with("guard"):
			continue
		for at: Vector2i in region.wards.keys():
			nearest = minf(nearest, npc.centre().distance_to(Vector2(at)))
	assert_true(nearest < 8.0,
		"a guard stands in the gateway, not across the works: %.1f tiles away" % nearest)


# ------------------------------------------- what playing it found (2026-09-19) ---

func test_no_fence_stands_where_it_closes_nothing() -> void:
	# **Yannick played it and saw a palisade in the river.** The yard's east side runs
	# along his water, and ten pieces were planted in it: closing nothing, in front of a
	# bank that already stopped you. It read as *the fences do not work* and as invisible
	# walls at once, because what was stopping the player there was the water.
	#
	# The same rule already kept them off his street. It now covers both: a fence goes
	# where it closes something, or it does not go.
	if not Places.baked():
		debt("the yard is the baked world's")
		return
	var region: Region = Region.build_overworld()
	var loose: PackedStringArray = PackedStringArray()
	for prop: Dictionary in region.props:
		if String(prop["kind"]) != "yard_fence":
			continue
		var at: Vector2i = prop["at"] as Vector2i
		if region.terrain_at(at) == Region.Terrain.WATER:
			loose.append("%s stands in the river" % str(at))
		if region.terrain_at(at) == Region.Terrain.ROAD:
			loose.append("%s stands across his street" % str(at))
	assert_eq(loose.size(), 0, "fences that close nothing:\n  %s" % "\n  ".join(loose))


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
