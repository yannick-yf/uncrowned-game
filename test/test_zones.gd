extends TestCase

## The transition mechanism, kept alive for interiors.
##
## No town uses it any more — towns are laid out on the overworld at their real
## size. It stays because a transition is still the right answer for a change of
## *scale or rules*: a building you go inside, a dungeon, the castle's keep. §4's
## three ways into Blackcairn are three entrances to one interior, which is exactly
## what this is for.
##
## Untested unused code is code that has quietly stopped working by the time you
## want it. These build two rooms and walk between them.

var _sim: Sim = null
var _world: WorldState = null

const OUTSIDE: StringName = &"outside"
const INSIDE: StringName = &"inside"


func before_each() -> void:
	# Two small open rooms. The doorway is a band two tiles deep, per §19 Q28b.
	var outside := Region.new(20, 20)
	var inside := Region.new(12, 12)
	for x: int in range(8, 12):
		for y: int in range(14, 16):
			outside.portals[Vector2i(x, y)] = {"zone": INSIDE, "at": Vector2i(6, 8)}
	inside.portals[Vector2i(6, 10)] = {"zone": OUTSIDE, "at": Vector2i(10, 10)}

	_world = WorldState.new()
	_world.zones[OUTSIDE] = outside
	_world.zones[INSIDE] = inside
	_world.current_zone = OUTSIDE
	_world.player_pos = Vector2(10.5, 10.5)
	_world.player_tile_last = _world.player_tile()

	_sim = Sim.new()
	_sim.add_store(&"world", _world)
	_sim.add_store(&"cast", Cast.shared())
	_sim.add_system(MovementSystem.new())
	_sim.add_system(ZoneSystem.new())


func _walk(dir: Vector2i, seconds: float) -> void:
	_sim.submit(&"move_intent", {"x": dir.x, "y": dir.y})
	_sim.advance(int(seconds * float(Sim.STEPS_PER_REAL_SECOND)))


func test_stepping_on_a_portal_moves_you_to_the_other_zone() -> void:
	assert_eq(_world.current_zone, OUTSIDE)
	_walk(Vector2i(0, 1), 1.2)
	assert_eq(_world.current_zone, INSIDE, "walked through the doorway")
	assert_eq(_world.player_tile(), Vector2i(6, 8), "and arrived where it leads")
	assert_eq(_world.player_dir, Vector2i.ZERO, "standing still on arrival")


func test_arriving_does_not_bounce_you_straight_back() -> void:
	_walk(Vector2i(0, 1), 1.2)
	assert_eq(_world.current_zone, INSIDE)
	_sim.advance(Sim.STEPS_PER_REAL_SECOND)
	assert_eq(_world.current_zone, INSIDE, "standing on the arrival tile is not a transition")


func test_the_transition_is_recorded_as_a_fact() -> void:
	_walk(Vector2i(0, 1), 1.2)
	assert_true(_sim.facts.has(StringName("zone:%s:entered" % INSIDE)),
		"going somewhere is knowledge like anything else")


func test_a_portal_to_a_zone_that_does_not_exist_does_nothing() -> void:
	var outside: Region = _world.zones[OUTSIDE] as Region
	outside.portals[Vector2i(10, 12)] = {"zone": &"nowhere", "at": Vector2i(1, 1)}
	_world.player_pos = Vector2(10.5, 11.5)
	_world.player_tile_last = _world.player_tile()
	_walk(Vector2i(0, 1), 0.2)
	assert_eq(_world.current_zone, OUTSIDE, "a door to nothing is a wall")
