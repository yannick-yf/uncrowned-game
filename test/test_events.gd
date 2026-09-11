extends TestCase

## The external-versus-derived event split.
##
## This is the debt Phase 3 could not be built on top of. Systems need to react to
## systems — SPECS §8's second consequence is exactly that, grain prices moving
## because an army shrank — but every logged event used to be re-injected on
## replay, so a system that raised one would produce it twice: once from the log,
## once from itself.
##
## The fix is to say which kind an event is. External events happened *to* the
## world and are replayed. Derived events are what the world said *back*, and are
## recomputed.


## Turns one kind of event into another, the way a real consequence does.
class EchoSystem extends SimSystem:
	var heard: int = 0
	var echoed: int = 0

	func on_event(sim: Sim, event: SimEvent) -> void:
		if event.type != &"shout":
			return
		heard += 1
		echoed += 1
		sim.derive(&"echo", {"of": String(event.type)})


## Listens for the echo, proving one system can hear another's consequence.
class ListenerSystem extends SimSystem:
	var echoes: int = 0

	func on_event(_sim: Sim, event: SimEvent) -> void:
		if event.type == &"echo":
			echoes += 1


## A system that answers its own output, to prove the backstop works.
class BabblerSystem extends SimSystem:
	func on_event(sim: Sim, event: SimEvent) -> void:
		if event.type == &"babble":
			sim.derive(&"babble", {})


func _sim_with(systems: Array[SimSystem]) -> Sim:
	var sim := Sim.new()
	for system: SimSystem in systems:
		sim.add_system(system)
	return sim


func test_a_system_can_answer_and_another_system_hears_it() -> void:
	var echo := EchoSystem.new()
	var listener := ListenerSystem.new()
	var sim: Sim = _sim_with([echo, listener])

	sim.submit(&"shout")
	sim.advance()
	assert_eq(echo.heard, 1, "the shout was heard")
	assert_eq(listener.echoes, 0, "but the answer lands on the next step, not this one")

	sim.advance()
	assert_eq(listener.echoes, 1, "and then it is heard in turn")


func test_both_kinds_are_logged_and_told_apart() -> void:
	var sim: Sim = _sim_with([EchoSystem.new()])
	sim.submit(&"shout")
	sim.advance(2)

	assert_eq(sim.events.size(), 2, "the shout and the echo are both on the record")
	assert_false(sim.events.at(0).derived, "the shout came from outside")
	assert_true(sim.events.at(1).derived, "the echo came from within")
	assert_eq(sim.events.external().size(), 1, "only one of them happened *to* the world")
	assert_eq(sim.events.external_rows().size(), 1, "and only one needs saving")


func test_replay_recomputes_the_answer_rather_than_repeating_it() -> void:
	var sim: Sim = _sim_with([EchoSystem.new()])
	sim.submit(&"shout")
	sim.submit(&"shout")
	sim.advance(4)
	assert_eq(sim.events.size(), 4, "two shouts, two echoes")

	var systems: Array[SimSystem] = [EchoSystem.new()]
	var replayed := Sim.replay(sim.events.external_rows(), sim.rng_seed, systems, sim.step)

	assert_eq(replayed.events.size(), sim.events.size(),
		"the same four events — not six, which is what re-injecting them would give")
	assert_eq(replayed.events.external().size(), 2, "the same two came from outside")
	assert_eq((systems[0] as EchoSystem).echoed, 2, "and the system answered twice, not four times")


func test_handing_replay_a_derived_event_still_does_not_double_it() -> void:
	# external_rows() already filters, so this is the belt to that braces: a caller
	# who passes the whole log by mistake gets the same world, not a doubled one.
	var sim: Sim = _sim_with([EchoSystem.new()])
	sim.submit(&"shout")
	sim.advance(3)

	var careless: Array[SimSystem] = [EchoSystem.new()]
	var replayed := Sim.replay(sim.events.to_array(), sim.rng_seed, careless, sim.step)
	assert_eq(replayed.events.size(), sim.events.size(), "same log, not a longer one")
	assert_eq((careless[0] as EchoSystem).echoed, 1, "answered once")


func test_a_system_answering_itself_is_caught_rather_than_hanging() -> void:
	var sim: Sim = _sim_with([BabblerSystem.new()])
	sim.submit(&"babble")
	sim.advance(4)
	assert_true(sim.events.size() > 1, "it did keep talking")
	assert_eq(sim.derived_overflows, 0,
		"but one answer per step is not a runaway — deferral bounds each step")
	assert_true(sim.pending_count() <= 2, "and the queue is not growing without limit")


func test_the_budget_stops_a_real_runaway() -> void:
	var sim := Sim.new()
	sim.submit(&"start")
	sim.advance()
	for _i: int in Sim.MAX_DERIVED_PER_STEP + 10:
		sim.derive(&"noise")
	assert_true(sim.derived_overflows > 0, "the backstop reported rather than silently dropped")
