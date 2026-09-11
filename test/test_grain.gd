extends TestCase

## Phase 3, stage 2: systems answering systems.
##
## §8's second consequence, and the one the event split was paid for: the army
## empties out, the men who were issued food start buying it, and a week later
## bread costs more in the towns nearest the camp. **Nobody mentions the player.**


class TargetSystem extends SimSystem:
	func on_event(sim: Sim, event: SimEvent) -> void:
		if event.type != &"set_army_target":
			return
		var ticked := sim.store(&"worldtick") as WorldTick
		ticked.army_target = float(event.data.get("to", 100.0))
		ticked.army_strength = float(event.data.get("from", ticked.army_strength))


func _bare() -> Sim:
	var sim := Sim.new()
	sim.add_store(&"world", Game.build_world())
	sim.add_store(&"worldtick", WorldTick.new())
	sim.add_store(&"cast", Cast.shared())
	sim.add_system(TargetSystem.new())
	sim.add_system(WorldTickSystem.new())
	sim.add_system(GrainSystem.new())
	return sim


func _days(sim: Sim, count: float) -> void:
	sim.advance_world_ticks(int(float(Game.TICKS_PER_IN_GAME_DAY) * count))


# ----------------------------------------------------------------- the chain ---

func test_bread_does_not_move_on_its_own() -> void:
	var sim: Sim = _bare()
	var ticked := sim.store(&"worldtick") as WorldTick
	_days(sim, 10.0)
	assert_true(absf(ticked.grain_in(&"harrowgate") - WorldTick.NEUTRAL) < 0.01,
		"a world with a full army has no reason to be hungry")


func test_the_army_shrinking_raises_bread_in_the_towns_nearest_the_camp() -> void:
	var sim: Sim = _bare()
	var ticked := sim.store(&"worldtick") as WorldTick
	sim.submit(&"set_army_target", {"from": 75.0, "to": WorldRules.ARMY_AFTER_FRAUD})
	_days(sim, 14.0)

	assert_true(ticked.grain_in(&"harrowgate") > WorldTick.NEUTRAL,
		"bread in Harrowgate: %.1f" % ticked.grain_in(&"harrowgate"))
	assert_true(ticked.grain_in(&"brindle") <= WorldTick.NEUTRAL + 0.01,
		"but not in Brindle, which is a hundred and forty tiles away and a ruin")


func test_bread_arrives_later_than_the_desertions_that_caused_it() -> void:
	# The delay is what makes it read as a consequence rather than a switch.
	var sim: Sim = _bare()
	var ticked := sim.store(&"worldtick") as WorldTick
	sim.submit(&"set_army_target", {"from": 75.0, "to": WorldRules.ARMY_AFTER_FRAUD})
	sim.advance(4)
	assert_true(absf(ticked.grain_in(&"harrowgate") - WorldTick.NEUTRAL) < 0.01,
		"nothing on the night itself")

	_days(sim, 1.0)
	var after_a_day: float = ticked.grain_in(&"harrowgate")
	_days(sim, 6.0)
	assert_true(ticked.grain_in(&"harrowgate") > after_a_day, "it keeps climbing after")


func test_one_system_hears_another_rather_than_reading_it() -> void:
	# Grain listens for a derived event; it never reaches into army strength.
	var sim: Sim = _bare()
	sim.submit(&"set_army_target", {"from": 75.0, "to": WorldRules.ARMY_AFTER_FRAUD})
	_days(sim, 10.0)
	var fell: int = 0
	var moved: int = 0
	for event: SimEvent in sim.events.all():
		if event.type == &"army_fell":
			fell += 1
			assert_true(event.derived, "the world saying something back")
		elif event.type == &"grain_moved":
			moved += 1
	assert_true(fell > 5, "the army announced itself shrinking %d times" % fell)
	assert_true(moved > 5, "and the price answered %d times" % moved)


func test_the_whole_thing_replays_from_one_logged_event() -> void:
	var sim: Sim = _bare()
	sim.submit(&"set_army_target", {"from": 75.0, "to": WorldRules.ARMY_AFTER_FRAUD})
	_days(sim, 8.0)
	var ticked := sim.store(&"worldtick") as WorldTick

	var systems: Array[SimSystem] = [TargetSystem.new(), WorldTickSystem.new(), GrainSystem.new()]
	var replayed: Sim = Sim.replay(
		sim.events.external_rows(), sim.rng_seed, systems, sim.step,
		{&"world": Game.build_world(), &"worldtick": WorldTick.new(), &"cast": Cast.shared()})
	assert_eq((replayed.store(&"worldtick") as WorldTick).fingerprint(), ticked.fingerprint(),
		"a fortnight of one system answering another rebuilds from a single event")


# ------------------------------------------------------- and somebody notices ---

func test_maddox_says_nothing_about_bread_while_bread_is_normal() -> void:
	var sim: Sim = _bare()
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	world.player_pos = Vector2(Region.HARROWGATE) + Vector2(0.5, 0.5)
	world.player_tile_last = world.player_tile()

	var conditions: Dictionary = DialogueRules.conditions(world, sim.store(&"worldtick") as WorldTick)
	var maddox: Npc = cast.get_npc(&"maddox")
	assert_false(bool(conditions[&"grain_is_dear_here"]), "bread is normal")
	assert_eq(maddox.greeting_for(conditions), maddox.greeting, "so he greets you normally")
	for option: DialogueOption in DialogueRules.available(maddox, sim.facts, conditions):
		assert_ne(option.intent, &"ask_bread", "and there is nothing to ask about it")


func test_maddox_complains_about_bread_without_mentioning_me() -> void:
	var sim: Sim = _bare()
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	var ticked := sim.store(&"worldtick") as WorldTick
	world.player_pos = Vector2(Region.HARROWGATE) + Vector2(0.5, 0.5)
	world.player_tile_last = world.player_tile()

	sim.submit(&"set_army_target", {"from": 75.0, "to": WorldRules.ARMY_AFTER_FRAUD})
	_days(sim, 14.0)

	var conditions: Dictionary = DialogueRules.conditions(world, ticked)
	assert_true(bool(conditions[&"grain_is_dear_here"]),
		"bread is dear: %.1f" % ticked.grain_in(&"harrowgate"))

	var maddox: Npc = cast.get_npc(&"maddox")
	var greeting: String = maddox.greeting_for(conditions)
	assert_ne(greeting, maddox.greeting, "he opens with it before you ask")
	assert_true(greeting.to_lower().contains("bread"))

	var found: bool = false
	for option: DialogueOption in DialogueRules.available(maddox, sim.facts, conditions):
		if option.intent == &"ask_bread":
			found = true
			var reply: String = option.reply.to_lower()
			assert_true(reply.contains("soldiers") or reply.contains("muster"),
				"he blames the army, which is true")
			assert_false(reply.contains("you"), "and never the player, who gets no credit")
	assert_true(found, "and there is now something to ask")
