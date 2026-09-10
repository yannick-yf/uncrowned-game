extends TestCase

## The skeleton's contracts. Nothing here knows anything about the game — these are
## the guarantees every later system depends on.


## The shape a real system takes: read events, write facts, keep no state.
## Draws from sim.rng rather than global randf(), which is what makes the replay
## test below meaningful rather than decorative.
class FoldingSystem extends SimSystem:
	func on_event(sim: Sim, event: SimEvent) -> void:
		if event.type != &"fact_learned":
			return
		var fact := StringName(event.data.get("fact", ""))
		var source := StringName(event.data.get("source", ""))
		if fact == &"" or source == &"":
			return
		var roll: int = sim.rng.randi_range(0, 999)
		sim.facts.add_source(fact, StringName("%s#%03d" % [String(source), roll]))

	func system_name() -> StringName:
		return &"folding"


## Instrumentation only — a real system would not carry counters.
class CountingSystem extends SimSystem:
	var events_seen: int = 0
	var ticks_seen: int = 0

	func on_event(_sim: Sim, _event: SimEvent) -> void:
		events_seen += 1

	func on_tick(_sim: Sim, _tick: int) -> void:
		ticks_seen += 1


func test_a_new_sim_is_at_tick_zero_and_empty() -> void:
	var sim := Sim.new()
	assert_eq(sim.tick, 0, "clock starts at zero")
	assert_eq(sim.events.size(), 0, "no events yet")
	assert_eq(sim.facts.size(), 0, "no facts yet")
	assert_eq(sim.system_count(), 0, "no systems yet")


func test_advance_is_the_only_thing_that_moves_the_clock() -> void:
	var sim := Sim.new()
	sim.advance()
	assert_eq(sim.tick, 1, "one tick by default")
	sim.advance(9)
	assert_eq(sim.tick, 10, "advance(n) moves n ticks")
	sim.advance(0)
	assert_eq(sim.tick, 10, "advance(0) is a no-op")
	sim.advance(-5)
	assert_eq(sim.tick, 10, "negative advance is a no-op, not a rewind")


func test_submit_logs_immediately_and_stamps_the_current_tick() -> void:
	var sim := Sim.new()
	sim.advance(7)
	var event := sim.submit(&"thing_happened", {"detail": 1})
	assert_eq(sim.events.size(), 1, "the log grows on submit, not on advance")
	assert_eq(event.tick, 7, "stamped with the tick it happened on")
	assert_eq(sim.events.at(0).type, &"thing_happened")


func test_systems_see_events_on_the_next_advance_not_before() -> void:
	var sim := Sim.new()
	var counter := CountingSystem.new()
	sim.add_system(counter)

	sim.submit(&"a")
	sim.submit(&"b")
	assert_eq(counter.events_seen, 0, "submitting does not dispatch")
	assert_eq(sim.pending_count(), 2, "both are queued")

	sim.advance()
	assert_eq(counter.events_seen, 2, "both dispatched on the next advance")
	assert_eq(counter.ticks_seen, 1, "and the tick ran once")
	assert_eq(sim.pending_count(), 0, "queue drained")


func test_the_fact_base_counts_independent_sources() -> void:
	var facts := FactBase.new()
	assert_false(facts.has(&"the_ledger"), "unknown until sourced")

	facts.add_source(&"the_ledger", &"halgrave")
	assert_true(facts.has(&"the_ledger"))
	assert_eq(facts.source_count(&"the_ledger"), 1)
	assert_false(facts.is_redundant(&"the_ledger"), "one source is not redundant")

	facts.add_source(&"the_ledger", &"halgrave")
	assert_eq(facts.source_count(&"the_ledger"), 1, "the same source twice is still one")

	facts.add_source(&"the_ledger", &"sena")
	assert_true(facts.is_redundant(&"the_ledger"), "two independent sources")
	assert_eq(facts.sources_of(&"the_ledger"), [&"halgrave", &"sena"] as Array[StringName],
		"sorted, so anything hashing this is stable")

	facts.remove_source(&"the_ledger", &"sena")
	assert_eq(facts.single_source_facts(), [&"the_ledger"] as Array[StringName],
		"a death can leave a fact one source from gone")


func test_the_same_seed_gives_the_same_rolls() -> void:
	var a := Sim.new(1234)
	var b := Sim.new(1234)
	var c := Sim.new(4321)
	assert_eq(a.rng.randi_range(0, 1_000_000), b.rng.randi_range(0, 1_000_000),
		"same seed, same sequence")
	assert_ne(a.rng.randi_range(0, 1_000_000), c.rng.randi_range(0, 1_000_000),
		"different seed, different sequence")


func test_replaying_the_log_rebuilds_the_world_exactly() -> void:
	var sim := Sim.new(99)
	sim.add_system(FoldingSystem.new())
	sim.advance(3)
	sim.submit(&"fact_learned", {"fact": "the_ledger", "source": "halgrave"})
	sim.advance(2)
	sim.submit(&"fact_learned", {"fact": "the_ledger", "source": "sena"})
	sim.submit(&"fact_learned", {"fact": "the_grants", "source": "nessa"})
	sim.submit(&"ignored_by_every_system", {"noise": true})
	sim.advance(10)

	assert_eq(sim.facts.size(), 2, "two facts learned")
	assert_true(sim.facts.is_redundant(&"the_ledger"), "from two sources")

	var systems: Array[SimSystem] = [FoldingSystem.new()]
	var replayed := Sim.replay(sim.events.to_array(), sim.rng_seed, systems, sim.tick)

	assert_eq(replayed.tick, sim.tick, "same clock")
	assert_eq(replayed.events.size(), sim.events.size(), "same log")
	assert_eq(replayed.facts.fingerprint(), sim.facts.fingerprint(),
		"same facts, same sources — nothing important lives outside the log")
	assert_eq(replayed.rng.state, sim.rng.state,
		"the rng was consumed identically, so the run is reproducible")


func test_the_log_round_trips_through_its_serialisable_form() -> void:
	var sim := Sim.new()
	sim.submit(&"one", {"n": 1})
	sim.advance()
	sim.submit(&"two", {"nested": {"deep": [1, 2, 3]}})

	var restored := EventLog.from_array(sim.events.to_array())
	assert_eq(restored.size(), 2)
	assert_eq(restored.at(0).type, &"one")
	assert_eq(restored.at(1).tick, 1, "ticks survive")
	assert_eq(restored.at(1).data, sim.events.at(1).data, "so does nested data")
	assert_eq(restored.of_type(&"two").size(), 1)
