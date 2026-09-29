extends TestCase

## **Where a named person actually stands** (O7, 2026-09-29).
##
## Until the opening's redo nobody named ever moved: a person was content, resolved once
## from `content/places.json` and drawn there. A spar moves Bram — he closes, he steps
## off — and the drills and the hail will move him on purpose. So a person the world has
## displaced is held by one store, `Walkers`, and everything that asks where somebody is
## asks it; `Npc` and the shared `Cast` are never written.

const SLOW: bool = false


func _walkers(sim: Sim) -> Walkers:
	return sim.store(&"walkers") as Walkers


## A spar against Bram started a few tiles from him, so he has to walk to fight.
func _spar_from_afar(sim: Sim) -> Duel:
	var world := sim.store(&"world") as WorldState
	var bram: Npc = (sim.store(&"cast") as Cast).get_npc(&"bram")
	world.player_pos = bram.centre() + Vector2(3.0, 0.0)
	sim.submit(&"duel_began", {"opponent": "bram", "by": "player", "spar": true})
	sim.advance(1)
	var duel := sim.store(&"duel") as Duel
	var hands := DuelPlayer.new(DuelPlayer.STAND)
	for _step: int in 4000:
		if not duel.on():
			break
		hands.play(sim, duel)
		sim.advance(1)
	return duel


## Where Bram stood when the fight ended, read off the log.
func _where_it_ended(sim: Sim, bram: Npc) -> Vector2i:
	var last: Vector2i = bram.tile
	for row: Variant in sim.events.of_type(&"duel_turn"):
		var turn: SimEvent = row as SimEvent
		if String(turn.data.get("who", "")) == "bram":
			last = Vector2i(int(turn.data["to_x"]), int(turn.data["to_y"]))
	return last


func test_after_a_fight_he_stands_where_it_ended() -> void:
	var sim: Sim = Game.build()
	var bram: Npc = (sim.store(&"cast") as Cast).get_npc(&"bram")
	_spar_from_afar(sim)
	var ended: Vector2i = _where_it_ended(sim, bram)
	assert_ne(ended, bram.tile, "the fight moved him off his post")
	assert_eq(_walkers(sim).where(bram), ended, "and he is where it left him, not back at his post")
	assert_eq(bram.tile, (Cast.shared().get_npc(&"bram")).tile, "and nobody wrote on the shared cast")


func test_the_interact_key_finds_him_where_he_stands() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	var bram: Npc = cast.get_npc(&"bram")
	_spar_from_afar(sim)
	var here: Vector2 = Vector2(_walkers(sim).where(bram)) + Vector2(0.5, 0.5)
	var found: Npc = cast.nearest_to(world.current_zone, here, 0.4, _walkers(sim))
	assert_not_null(found, "somebody is standing there")
	assert_eq(found.id, &"bram", "and it is him")


func test_a_witness_sees_from_where_he_stands() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	var bram: Npc = cast.get_npc(&"bram")
	_spar_from_afar(sim)
	var here: Vector2 = Vector2(_walkers(sim).where(bram)) + Vector2(0.5, 0.5)
	assert_true(CrimeRules.witnesses_to(cast, world.current_zone, here, WorldTick.NEUTRAL, _walkers(sim)).has("bram"),
		"a theft beside him is seen by him")


func test_he_walks_home_and_the_store_lets_him_go() -> void:
	var sim: Sim = Game.build()
	var bram: Npc = (sim.store(&"cast") as Cast).get_npc(&"bram")
	_spar_from_afar(sim)
	var walkers: Walkers = _walkers(sim)
	assert_true(walkers.is_displaced(&"bram"), "he is away from his post")
	sim.advance(Sim.STEPS_PER_REAL_SECOND * 30)
	assert_false(walkers.is_displaced(&"bram"), "and after a while he has walked back")
	assert_eq(walkers.where(bram), bram.tile, "to his post")


func test_the_walk_home_is_drawn_between_tiles() -> void:
	var sim: Sim = Game.build()
	var bram: Npc = (sim.store(&"cast") as Cast).get_npc(&"bram")
	_spar_from_afar(sim)
	sim.advance(WalkerRules.linger_steps() + 5)
	var walkers: Walkers = _walkers(sim)
	assert_true(walkers.is_displaced(&"bram"), "he is on his way")
	var drawn: Vector2 = walkers.drawn_at(bram)
	assert_true(drawn.distance_to(Vector2(walkers.where(bram)) + Vector2(0.5, 0.5)) < 1.01,
		"he is drawn on his way, never more than a tile from where he stands")


func test_the_walk_home_replays_from_the_log() -> void:
	# A fight squared up from where the game starts, so nothing about it is set outside
	# the log: he is stood off beside the player, far from his post, and walks back.
	var sim: Sim = Game.build()
	sim.submit(&"duel_began", {"opponent": "bram", "by": "player", "spar": true})
	sim.advance(1)
	var duel := sim.store(&"duel") as Duel
	var hands := DuelPlayer.new(DuelPlayer.STAND)
	for _step: int in 4000:
		if not duel.on():
			break
		hands.play(sim, duel)
		sim.advance(1)
	sim.advance(WalkerRules.linger_steps() + 200)
	assert_true(_walkers(sim).is_displaced(&"bram"), "he is walking home from far off")
	var replayed: Sim = Game.replay(sim)
	assert_eq(_walkers(replayed).fingerprint(), _walkers(sim).fingerprint(),
		"and a replay puts him on the same tile, the same step into it")


func test_how_the_steps_are_chunked_changes_nothing() -> void:
	var one: Sim = Game.build()
	var other: Sim = Game.build()
	_spar_from_afar(one)
	_spar_from_afar(other)
	assert_eq(_walkers(one).fingerprint(), _walkers(other).fingerprint(), "two identical runs agree")
	var steps: int = WalkerRules.linger_steps() + WalkerRules.steps_per_tile() / 2
	one.advance(steps)
	for _i: int in steps:
		other.advance(1)
	assert_true(_walkers(one).is_displaced(&"bram"), "compared mid-walk, where it could differ")
	assert_eq(_walkers(one).fingerprint(), _walkers(other).fingerprint(),
		"advance(%d) is %d advance(1)" % [steps, steps])
