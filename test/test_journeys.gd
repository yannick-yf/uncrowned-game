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
var _wild: Wildlife = null
var _ticked: WorldTick = null


func before_each() -> void:
	_sim = Game.build()
	_world = _sim.store(&"world") as WorldState
	_cast = _sim.store(&"cast") as Cast
	_wild = _sim.store(&"wildlife") as Wildlife
	_ticked = _sim.store(&"worldtick") as WorldTick


# ------------------------------------------------------------------ walking ---

func _walk(dir: Vector2i, quarter_seconds: int) -> void:
	_sim.submit(&"move_intent", {"x": dir.x, "y": dir.y})
	_sim.advance(quarter_seconds * Sim.STEPS_PER_WORLD_TICK)


func _say(type: StringName, data: Dictionary = {}) -> void:
	_sim.submit(type, data)
	_sim.advance(1)


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
	var dammed := Region.build_overworld(true)
	for x: int in range(Region.BRIDGE.x - 12, Region.BRIDGE.x + 12):
		for y: int in range(Region.BRIDGE.y - 4, Region.FORD.y + 6):
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
	assert_true(_follow(route, 200.0), "walked the King's Road to the capital")
	assert_eq(_blood_price(hp, deaths), 0, "the long way round is the safe way round")


func test_cutting_through_the_thornwood_draws_blood() -> void:
	var hp: int = _world.player_hp
	var deaths: int = _world.deaths
	assert_true(_walk_to(Vector2i(150, 90), 180.0), "crossed the wild")
	var price: int = _blood_price(hp, deaths)
	assert_true(price > 0, "the wild took nothing, so it is not a choice")
	assert_true(price <= 24, "the wild took %d health, which is a wall rather than a risk" % price)
	assert_true(_sim.facts.has(BeastRules.FACT_WILD_IS_DANGEROUS),
		"and you now know it, which is a fact like any other")


func test_beasts_never_stand_on_the_road_however_long_you_wait() -> void:
	var region: Region = _world.region()
	_world.player_pos = Vector2(200.5, 140.5)
	_world.player_tile_last = _world.player_tile()
	_sim.advance(Sim.STEPS_PER_REAL_SECOND * 40)
	assert_true(_wild.count() > 0, "the wood is inhabited")
	for beast: Beast in _wild.beasts:
		assert_true(BeastRules.is_wild_ground(region.terrain_at(beast.tile())),
			"a %s is standing on terrain %d" % [beast.kind, region.terrain_at(beast.tile())])
		assert_eq(region.zone_at(beast.tile()), &"", "and not inside a settlement")


func test_a_mauling_replays_from_the_log() -> void:
	assert_true(_walk_to(Vector2i(180, 120), 120.0), "walked into the wood")
	assert_true(_wild.count() > 0)
	var replayed: Sim = Game.replay(_sim)
	assert_eq((replayed.store(&"world") as WorldState).fingerprint(), _world.fingerprint(),
		"the same walk rebuilds the same wounds")
	assert_eq((replayed.store(&"wildlife") as Wildlife).fingerprint(), _wild.fingerprint(),
		"and the same animals, in the same places, hunting or not")


# ------------------------------------------------------------ end to end ---

func test_a_whole_phase_0_run_replays_identically_from_its_log() -> void:
	for node: Vector2i in Region.road_route():
		assert_true(_walk_to(node, 120.0), "walked the road to %s" % node)
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
	assert_true(_walk_to(Vector2i(146, 172), 200.0), "walked to the Harrowgate market")
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

	assert_true(_walk_to(Region.HARROWGATE, 180.0), "walked the road to Harrowgate")
	assert_eq(_world.region().zone_at(_world.player_tile()), &"harrowgate", "and into the town")

	var ossa: Npc = _cast.get_npc(&"ossa")
	assert_true(_walk_to(ossa.tile, 60.0), "crossed the town to Ossa")
	_say(&"talk", {"npc": "ossa"})
	_say(&"choose_intent", {"intent": "ask_why"})
	assert_true(_sim.facts.has(ArmyRules.FACT_PAY_FRAUD), "learned why they are deserting")
	_say(&"end_talk")

	assert_true(_walk_to(Region.MUSTER, 300.0), "followed the road to the camp")
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
	assert_true(_walk_to(Region.HARROWGATE, 180.0))
	var ossa: Npc = _cast.get_npc(&"ossa")
	assert_true(_walk_to(ossa.tile, 60.0))
	_say(&"talk", {"npc": "ossa"})
	_say(&"choose_intent", {"intent": "ask_why"})
	_say(&"end_talk")
	assert_true(_walk_to(Region.MUSTER, 300.0))
	_say(&"expose_fraud")
	assert_true(_ticked.kings_escort() < 10, "the run did what it was supposed to")

	var replayed: Sim = Game.replay(_sim)
	assert_eq((replayed.store(&"world") as WorldState).fingerprint(), _world.fingerprint(),
		"a conversation and its consequence rebuild from the log like anything else")
	assert_eq((replayed.store(&"worldtick") as WorldTick).fingerprint(), _ticked.fingerprint(),
		"and so does the world they moved")
	assert_eq(replayed.facts.fingerprint(), _sim.facts.fingerprint(), "same facts, same sources")
