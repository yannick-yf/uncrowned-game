extends TestCase

## The slow suite: everything that walks the map, searches it, or runs the whole
## game for in-game days.
##
## `const SLOW` keeps these out of `run_tests.sh` by default. They are not less
## important — the end-to-end chain is the most important test in the project —
## they are just too expensive to sit between a change and knowing it compiled.
## Run the whole thing before committing.

const SLOW: bool = true

var _sim: Sim = null
var _world: WorldState = null
var _cast: Cast = null
var _ticked: WorldTick = null


func before_each() -> void:
	_sim = Game.build()
	_world = _sim.store(&"world") as WorldState
	_cast = _sim.store(&"cast") as Cast
	_ticked = _sim.store(&"worldtick") as WorldTick


# ------------------------------------------------------------------ walking ---

func _walk(dir: Vector2i, quarter_seconds: int) -> void:
	_sim.submit(&"move_intent", {"x": dir.x, "y": dir.y})
	_sim.advance(quarter_seconds * Sim.STEPS_PER_WORLD_TICK)


func _say(type: StringName, data: Dictionary = {}) -> void:
	_sim.submit(type, data)
	_sim.advance(1)


## A time budget written for the 2D map's six tiles a second, at this world's pace:
## the same walk on the baked world takes 2.4 times as long, and the budget says so
## rather than failing on the pace Yannick chose (decision 1).
func _at_pace(seconds_at_six: float) -> float:
	return seconds_at_six * MovementRules.TILES_PER_SECOND / MovementRules.tiles_per_second()


## Walk to a tile by an actual path, not by pressing into whatever is in the way.
func _walk_to(target: Vector2i, max_seconds: float) -> bool:
	var deadline: int = _sim.step + int(max_seconds * float(Sim.STEPS_PER_REAL_SECOND))
	var route: Array[Vector2] = Navigation.waypoints(_world.region(), _world.player_tile(), target)
	if route.is_empty():
		return false
	for point: Vector2 in route:
		while _sim.step < deadline:
			var delta: Vector2 = point - _world.player_pos
			if delta.length() <= 1.0:
				break
			_sim.submit(&"move_intent", _aim(delta))
			_sim.advance(Sim.STEPS_PER_REAL_SECOND / 10)
		if _sim.step >= deadline:
			return false
	_sim.submit(&"move_intent", {"x": 0, "y": 0})
	_sim.advance(1)
	return true


## Steer straight through a list of points, without pathfinding. Used for the road,
## because a shortest path between two corners cuts the bend onto the verge.
func _follow(points: Array[Vector2i], max_seconds: float) -> bool:
	var deadline: int = _sim.step + int(max_seconds * float(Sim.STEPS_PER_REAL_SECOND))
	for point: Vector2i in points:
		var target: Vector2 = Vector2(point) + Vector2(0.5, 0.5)
		while _sim.step < deadline:
			var delta: Vector2 = target - _world.player_pos
			if delta.length() <= 1.0:
				break
			_sim.submit(&"move_intent", _aim(delta))
			_sim.advance(Sim.STEPS_PER_REAL_SECOND / 10)
		if _sim.step >= deadline:
			return false
	return true


## Push into a target rather than arriving politely beside it, and stop on dying —
## a player respawned in Brindle would otherwise set off for the castle again.
func _walk_into(target: Vector2, seconds: float) -> void:
	var deadline: int = _sim.step + int(seconds * float(Sim.STEPS_PER_REAL_SECOND))
	var deaths: int = _world.deaths
	while _sim.step < deadline:
		if _world.deaths > deaths:
			_sim.submit(&"move_intent", {"x": 0, "y": 0})
			_sim.advance(1)
			return
		_sim.submit(&"move_intent", _aim(target - _world.player_pos, 0.2))
		_sim.advance(Sim.STEPS_PER_REAL_SECOND / 10)


func _aim(delta: Vector2, deadzone: float = 0.5) -> Dictionary:
	var dir := Vector2i.ZERO
	if absf(delta.x) >= deadzone:
		dir.x = 1 if delta.x > 0.0 else -1
	if absf(delta.y) >= deadzone:
		dir.y = 1 if delta.y > 0.0 else -1
	return {"x": dir.x, "y": dir.y}


func _blood_price(before_hp: int, before_deaths: int) -> int:
	return before_hp - _world.player_hp + (_world.deaths - before_deaths) * WorldState.MAX_HP


func _passable_neighbours(region: Region, tile: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx: int in [-1, 0, 1]:
		for dy: int in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			if region.is_passable(tile + Vector2i(dx, dy)):
				out.append(tile + Vector2i(dx, dy))
	return out


func _reachable_from(region: Region, start: Vector2i) -> Dictionary:
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		for next: Vector2i in _passable_neighbours(region, queue.pop_back()):
			if not seen.has(next):
				seen[next] = true
				queue.append(next)
	return seen


# ------------------------------------------------------- the map holds together ---

func test_every_zone_is_reachable_on_foot_from_brindle() -> void:
	var seen: Dictionary = _reachable_from(_world.region(), Region.BRINDLE)
	for id: StringName in Region.zone_sites().keys():
		assert_true(seen.has(Region.zone_sites()[id]), "%s is reachable from Brindle" % id)


func test_landmarks_never_close_the_road() -> void:
	assert_true(_reachable_from(_world.region(), Region.BRINDLE).has(Region.BLACKCAIRN),
		"a building was put through the King's Road")


func test_the_kettle_actually_divides_the_map() -> void:
	# If the river is not a barrier then the bridge and the ford are decoration.
	# Fill both crossings in and the castle must become unreachable.
	# A square round each crossing rather than one rectangle spanning both: the 2D
	# map's ford lies just downstream of its bridge, the baked world's does not.
	var dammed := Region.build_overworld(true)
	for crossing: Vector2i in [Region.BRIDGE, Region.FORD]:
		for x: int in range(crossing.x - 12, crossing.x + 13):
			for y: int in range(crossing.y - 12, crossing.y + 13):
				var here: Region.Terrain = dammed.terrain_at(Vector2i(x, y))
				if here == Region.Terrain.ROAD or here == Region.Terrain.FORD:
					dammed.set_terrain(Vector2i(x, y), Region.Terrain.WATER)
	assert_false(_reachable_from(dammed, Region.BRINDLE).has(Region.BLACKCAIRN),
		"with both crossings dammed, the east bank is cut off — so the river is real")


# --------------------------------------------------------- the two routes ---

func test_walking_the_kings_road_costs_nothing() -> void:
	# Start on the road rather than wherever the game happens to begin. This used to
	# lean on the player starting in Brindle; the opening now starts them in the
	# wood, and a test about whether *the road* is safe should not also be a test
	# about walking to it.
	_world.player_pos = _world.region().brindle_centre()
	var hp: int = _world.player_hp
	var deaths: int = _world.deaths
	# Stopping short of the castle gate: the road is safe, but the man standing at
	# the end of it is not, and that is a different test.
	var route: Array[Vector2i] = []
	for point: Vector2i in Region.road_waypoints():
		if Vector2(point).distance_to(Vector2(Region.BLACKCAIRN)) > 14.0:
			route.append(point)
	# Brindle is not on the King's Road; it is reached by its own track. Find the road
	# first — on the 2D map that is the track to the works, on the baked world his
	# road north to Harrowgate — and then keep to it.
	assert_true(_walk_to(route[0], _at_pace(90.0)), "found the road from Brindle")
	assert_true(_follow(route, _at_pace(200.0)), "walked the King's Road to the capital")
	assert_eq(_blood_price(hp, deaths), 0, "the long way round is the safe way round")


## **The wild costs time, not blood** (2026-09-13). The beasts are gone and the ground
## slows you again, so the claim under test is the one §4 makes now: the road is the
## *fast* way and the wild the *slow* one, and neither draws blood. If the road ever
## stops being faster, the wild is faster *and* unwatched — strictly better — and the
## map has stopped making its argument. Measured, not assumed: the same walk both
## ways, in seconds. `tools/measure_routes.gd` prints the same figures.
func test_the_wild_costs_time_and_the_road_costs_none_of_it() -> void:
	var road_seconds: float = _seconds_to_cross(Region.road_waypoints())
	var road_blood: int = _blood_price(WorldState.MAX_HP, 0)

	_sim = Game.build()
	_world = _sim.store(&"world") as WorldState
	var wild_seconds: float = _seconds_to_cross(_wild_line())
	var wild_blood: int = _blood_price(WorldState.MAX_HP, 0)

	assert_eq(road_blood, 0, "the road drew blood")
	assert_eq(wild_blood, 0, "the wild drew blood, and nothing lives in it now")
	assert_true(road_seconds < wild_seconds,
		"road %.0f s, wild %.0f s: the wild is faster and unwatched, so the road has no case"
			% [road_seconds, wild_seconds])
	assert_true(wild_seconds - road_seconds >= 5.0,
		"and the difference is worth noticing: %.0f s" % (wild_seconds - road_seconds))


## §11's second half of Attunement, on the ground. Faster through the wood than
## anybody else, and still slower than the road — or the forest build gets the wild
## for free and the choice stops being a choice for exactly the player it is about.
func test_an_attuned_walker_crosses_the_wood_faster_but_not_as_fast_as_the_road() -> void:
	var road_seconds: float = _seconds_to_cross(Region.road_waypoints())

	_sim = Game.build()
	_world = _sim.store(&"world") as WorldState
	var plain: float = _seconds_to_cross(_wild_line())

	_sim = Game.build()
	_world = _sim.store(&"world") as WorldState
	var wanted: Dictionary = TraitRules.at_the_floor()
	wanted[TraitRules.ATTUNEMENT] = TraitRules.SPEAKS_AT
	assert_true((_sim.store(&"traits") as Traits).choose(wanted), "a forest build")
	var attuned: float = _seconds_to_cross(_wild_line())

	assert_true(attuned < plain,
		"attuned %.0f s against %.0f s: the wood should slow them less" % [attuned, plain])
	assert_true(road_seconds < attuned,
		"road %.0f s, attuned wild %.0f s: the road must stay the fast way for everyone"
			% [road_seconds, attuned])


func test_a_walk_through_the_wood_replays_from_the_log() -> void:
	assert_true(_walk_to(Vector2i(in_the_wood()), 200.0), "walked into the wood")
	var replayed: Sim = Game.replay(_sim)
	assert_eq((replayed.store(&"world") as WorldState).fingerprint(), _world.fingerprint(),
		"the same walk rebuilds the same position, to the step")


## Brindle to the castle along a line, in real seconds, stopping short of the man at
## the end of it. What `tools/measure_routes.gd` prints, as an assertion.
func _seconds_to_cross(line: Array[Vector2i]) -> float:
	_world.player_pos = _world.region().brindle_centre()
	_world.player_tile_last = _world.player_tile()
	var route: Array[Vector2i] = []
	for point: Vector2i in line:
		if Vector2(point).distance_to(Vector2(Region.BLACKCAIRN)) <= 14.0:
			break
		route.append(point)
	var started: int = _sim.step
	# From Brindle to the line's first point on foot, and that walk is part of the
	# measurement: both ways start in Brindle, and the road's first point is wherever
	# the road is.
	if not route.is_empty():
		assert_true(_walk_to(route[0], _at_pace(90.0)), "reached the start of the line")
	assert_true(_follow(route, _at_pace(400.0)), "crossed within the budget")
	return float(_sim.step - started) / float(Sim.STEPS_PER_REAL_SECOND)


## The shortest walkable way, which finds its own crossing of the Kettle. A ruled
## line is not a route: the river is in it.
func _wild_line() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for point: Vector2 in Navigation.waypoints(_world.region(), Region.BRINDLE, Region.BLACKCAIRN, 5, true):
		out.append(Vector2i(point.floor()))
	return out



# ------------------------------------------------------------ end to end ---

func test_a_whole_phase_0_run_replays_identically_from_its_log() -> void:
	for node: Vector2i in Region.road_route():
		assert_true(_walk_to(node, _at_pace(120.0)), "walked the road to %s" % node)
	assert_eq(_world.deaths, 0, "and arrived alive, because the road is safe")
	_walk_into(_world.king_pos, 4.0)

	assert_true(_world.reached_blackcairn, "the player got there")
	assert_eq(_world.deaths, 1, "and lost, once")
	assert_eq(_world.player_tile(), Region.CLEARING, "and woke up in the clearing again")

	var replayed: Sim = Game.replay(_sim)
	assert_eq(replayed.step, _sim.step, "same clock")
	assert_eq(replayed.events.size(), _sim.events.size(), "same log")
	assert_eq(replayed.facts.fingerprint(), _sim.facts.fingerprint(), "same facts")
	assert_eq((replayed.store(&"world") as WorldState).fingerprint(), _world.fingerprint(),
		"same world, down to the position — nothing important lives outside the log")


func test_a_theft_and_the_story_it_starts_replay_from_the_log() -> void:
	# The architectural proof for stage 3. Reputation and rumour are stores like
	# any other: nothing about them is remembered outside the log, so the same
	# walk and the same keypress rebuild the same opinion of you in every town.
	assert_true(_walk_to(Vector2i(at_a_stall()), 200.0), "walked to the Harrowgate market")
	_sim.submit(&"steal")
	_sim.advance(2)

	var standing := _sim.store(&"standing") as Standing
	var rumours := _sim.store(&"rumours") as Rumours
	assert_true(standing.in_town(&"harrowgate") < 0.0,
		"somebody in the market saw it: %.1f" % standing.in_town(&"harrowgate"))
	_sim.advance_world_ticks(Game.TICKS_PER_IN_GAME_DAY * 2)
	assert_true(standing.in_town(&"muster") < 0.0, "and two days later the camp has heard")

	var replayed: Sim = Game.replay(_sim)
	assert_eq((replayed.store(&"standing") as Standing).fingerprint(), standing.fingerprint(),
		"every town's opinion of you rebuilds from the log alone")
	assert_eq((replayed.store(&"rumours") as Rumours).fingerprint(), rumours.fingerprint(),
		"and every story still in the air, at the same distance out")

	# And the journal with them. If it could only be built from live state, the log
	# would not be the authoritative record of a run — and a save file that is a log
	# rather than a snapshot is the whole design.
	var told := PackedStringArray()
	for row: Dictionary in Journal.entries(_sim.events):
		told.append(str(row))
	var retold := PackedStringArray()
	for row: Dictionary in Journal.entries(replayed.events):
		retold.append(str(row))
	assert_true(told.size() > 1, "there is a story to tell: %d entries" % told.size())
	assert_eq(retold, told, "and the same log tells it again, rebuilt from nothing")


func test_the_whole_chain_walk_learn_expose_and_the_escort_drops() -> void:
	# Somebody who notices things, because the chain goes through Ossa's Wits line.
	_say(&"create_character", {"wits": 4})
	assert_eq(_ticked.kings_escort(), 10, "before: ten guards stand between me and the king")

	assert_true(_walk_to(Region.HARROWGATE, _at_pace(180.0)), "walked the road to Harrowgate")
	assert_eq(_world.region().zone_at(_world.player_tile()), &"harrowgate", "and into the town")

	var ossa: Npc = _cast.get_npc(&"ossa")
	assert_true(_walk_to(ossa.tile, _at_pace(60.0)), "crossed the town to Ossa")
	_say(&"talk", {"npc": "ossa"})
	_say(&"choose_intent", {"intent": "ask_why"})
	assert_true(_sim.facts.has(ArmyRules.FACT_PAY_FRAUD), "learned why they are deserting")
	_say(&"end_talk")

	assert_true(_walk_to(Region.MUSTER, _at_pace(300.0)), "followed the road to the camp")
	assert_true(_world.region().is_in_muster(_world.player_tile()), "standing in the camp")
	_say(&"expose_fraud")

	assert_true(_world.pay_fraud_exposed, "the camp knows")
	assert_true(_ticked.kings_escort() < 10, "some of them left tonight")
	assert_eq(_ticked.army_target, WorldRules.ARMY_AFTER_FRAUD, "and the rest are going")

	_sim.advance_world_ticks(Game.TICKS_PER_IN_GAME_DAY * 7)
	assert_eq(_ticked.kings_escort(), 5, "after a week: five, and the king is that much nearer")


func test_the_world_moves_while_the_player_does_nothing() -> void:
	# §8's fifth consequence end to end, through the real game.
	_sim.facts.add_source(ArmyRules.FACT_PAY_FRAUD, &"ossa")
	_world.player_pos = Vector2(Region.MUSTER) + Vector2(0.5, 0.5)
	_world.player_tile_last = _world.player_tile()
	_say(&"expose_fraud")

	var escort_then: int = _ticked.kings_escort()
	assert_true(escort_then < 10, "some of them left tonight")
	_world.player_pos = _world.region().brindle_centre()
	_world.player_tile_last = _world.player_tile()
	_sim.advance_world_ticks(Game.TICKS_PER_IN_GAME_DAY * 7)

	assert_true(_ticked.kings_escort() < escort_then, "the desertions kept going without me")
	assert_eq(_ticked.kings_escort(), 5, "and settled at five")


func test_the_whole_chain_replays_identically_from_its_log() -> void:
	# Through Ossa's Wits line again, so this needs the same person the chain test
	# makes. Creation is an ordinary event, so it replays with everything else —
	# which is half of what this test is checking.
	_say(&"create_character", {"wits": 4})
	assert_true(_walk_to(Region.HARROWGATE, _at_pace(180.0)))
	var ossa: Npc = _cast.get_npc(&"ossa")
	assert_true(_walk_to(ossa.tile, _at_pace(60.0)))
	_say(&"talk", {"npc": "ossa"})
	_say(&"choose_intent", {"intent": "ask_why"})
	_say(&"end_talk")
	assert_true(_walk_to(Region.MUSTER, _at_pace(300.0)))
	_say(&"expose_fraud")
	assert_true(_ticked.kings_escort() < 10, "the run did what it was supposed to")

	var replayed: Sim = Game.replay(_sim)
	assert_eq((replayed.store(&"world") as WorldState).fingerprint(), _world.fingerprint(),
		"a conversation and its consequence rebuild from the log like anything else")
	assert_eq((replayed.store(&"worldtick") as WorldTick).fingerprint(), _ticked.fingerprint(),
		"and so does the world they moved")
	assert_eq(replayed.facts.fingerprint(), _sim.facts.fingerprint(), "same facts, same sources")
