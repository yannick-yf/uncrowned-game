class_name Sim
extends RefCounted

## The simulation.
##
## The only thing in the project that mutates world state, and it only does so
## inside advance(). There is no _process() anywhere in core/ and there never will
## be: a run is a seed, a list of events, and a number of ticks, which is why it can
## be replayed exactly.
##
## Ordering, which is the whole contract:
##   submit()  stamps an event with the current step, appends it to the log, and
##             queues it. Systems do NOT see it during the call that submitted it.
##   advance() per step: dispatch everything queued, increment the step, run
##             on_step for every system in registration order, and every 15th step
##             increment the world tick and run on_tick.
##
## Events submitted while a step is being processed land in the next step. That is
## what stops a system cascade from looping forever inside one advance(), and it
## means view/ can submit input at any moment without racing the sim.
##
## Two kinds of event, and the difference is the whole of replay:
##   submit() is **external** — a key press, a tool, a test. It is what happened
##            *to* the world, it goes in the log, and replay re-injects it.
##   derive() is **derived** — what a system said back. It goes in the log too, so
##            that a journal can explain why something happened, but replay does
##            NOT re-inject it: it is recomputed from the same ticks and the same
##            external events. Replaying both would produce it twice.

const DEFAULT_SEED: int = 0x556E6372

## Two clocks, one entry point.
##
## A *step* is the simulation's own heartbeat, 60 a second. A *world tick* is one
## in-game minute, 4 a second, and fires every 15th step — which is exactly SPECS
## §8's "4 ticks per real second", preserved to the letter.
##
## The reason for two: §8's coarse clock is right for grain prices drifting and
## wrong for a walking man. At 4 Hz a key press waited up to 250 ms to be seen,
## and the player felt it as lag on every direction change. Movement, collision
## and input now resolve at 60 Hz; the world still drifts at 4.
const STEPS_PER_REAL_SECOND: int = 60
const STEPS_PER_WORLD_TICK: int = 15

var step: int = 0
var tick: int = 0
var rng_seed: int = DEFAULT_SEED
var rng: RandomNumberGenerator = null
var events: EventLog = null
var facts: FactBase = null

var _systems: Array[SimSystem] = []
var _inbox: Array[SimEvent] = []
var _stores: Dictionary = {}
var _steps_into_tick: int = 0
var _derived_this_step: int = 0
## A backstop, not a design. Systems reacting to systems is the point of derive();
## a system reacting to its own output is a bug, and this is how it announces
## itself rather than hanging the game.
const MAX_DERIVED_PER_STEP: int = 256
var derived_overflows: int = 0


func _init(p_seed: int = DEFAULT_SEED) -> void:
	rng_seed = p_seed
	rng = RandomNumberGenerator.new()
	rng.seed = p_seed
	events = EventLog.new()
	facts = FactBase.new()


func add_system(system: SimSystem) -> void:
	_systems.append(system)


func system_count() -> int:
	return _systems.size()


## Mutable world state lives in stores, not on systems and not on nodes. Sim does
## not know or care what a store contains — that is what keeps core/ generic and
## what lets replay rebuild the world into fresh, empty ones.
func add_store(id: StringName, store: RefCounted) -> void:
	_stores[id] = store


func store(id: StringName) -> RefCounted:
	return _stores.get(id, null) as RefCounted


func has_store(id: StringName) -> bool:
	return _stores.has(id)


## Record that something happened. Returns the logged event.
func submit(type: StringName, data: Dictionary = {}) -> SimEvent:
	var event := SimEvent.new(step, type, data)
	events.append(event)
	_inbox.append(event)
	return event


## Raise a consequence. For systems only, inside advance().
##
## The world talking to itself: a killing seen, a rumour arriving, a price moving
## because an army shrank. Logged for the record, recomputed on replay.
func derive(type: StringName, data: Dictionary = {}) -> SimEvent:
	if _derived_this_step >= MAX_DERIVED_PER_STEP:
		derived_overflows += 1
		push_error("derived event budget exhausted at step %d: '%s'" % [step, type])
		return null
	_derived_this_step += 1
	var event := SimEvent.new(step, type, data, true)
	events.append(event)
	_inbox.append(event)
	return event


func pending_count() -> int:
	return _inbox.size()


## The only entry point that mutates state, measured in steps. advance(n) is
## exactly n single steps, so how a caller chunks its calls can never change the
## outcome — which is what lets replay rebuild a run from the log alone.
func advance(steps: int = 1) -> void:
	for _i: int in maxi(steps, 0):
		var batch: Array[SimEvent] = _inbox
		_inbox = []
		for event: SimEvent in batch:
			for system: SimSystem in _systems:
				system.on_event(self, event)

		step += 1
		_derived_this_step = 0
		for system: SimSystem in _systems:
			system.on_step(self, step)

		_steps_into_tick += 1
		if _steps_into_tick >= STEPS_PER_WORLD_TICK:
			_steps_into_tick = 0
			tick += 1
			for system: SimSystem in _systems:
				system.on_tick(self, tick)


## Convenience for callers that think in world ticks, like the headless runner.
func advance_world_ticks(ticks: int) -> void:
	advance(maxi(ticks, 0) * STEPS_PER_WORLD_TICK)


## Rebuild a run from its log. `systems` must be fresh, stateless instances.
##
## This is the proof of the architecture rather than a convenience: if replaying a
## log does not reproduce the fact base byte for byte, then something important is
## being stored outside the log, and the save format is a lie.
static func replay(
	rows: Array,
	p_seed: int,
	systems: Array[SimSystem],
	final_step: int,
	stores: Dictionary = {},
) -> Sim:
	var sim := Sim.new(p_seed)
	for id: StringName in stores.keys():
		sim.add_store(id, stores[id] as RefCounted)
	for system: SimSystem in systems:
		sim.add_system(system)
	for row: Variant in rows:
		var event := SimEvent.from_dict(row as Dictionary)
		# Belt and braces: replay is given external rows, and refuses derived ones
		# even if handed them, because injecting one doubles it.
		if event.derived:
			continue
		if event.step > sim.step:
			sim.advance(event.step - sim.step)
		sim._inject(event)
	if final_step > sim.step:
		sim.advance(final_step - sim.step)
	return sim


## Re-queue an already-stamped event during replay, keeping its original step.
func _inject(event: SimEvent) -> void:
	events.append(event)
	_inbox.append(event)
