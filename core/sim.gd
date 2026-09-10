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
##   submit()  stamps an event with the current tick, appends it to the log, and
##             queues it. Systems do NOT see it during the call that submitted it.
##   advance() per tick: dispatch everything queued, then increment the clock, then
##             run on_tick for every system in registration order.
##
## Events submitted while a tick is being processed land in the next tick. That is
## what stops a system cascade from looping forever inside one advance(), and it
## means view/ can submit input at any moment without racing the sim.
##
## One tick is one in-game minute (SPECS §8).

const DEFAULT_SEED: int = 0x556E6372

var tick: int = 0
var rng_seed: int = DEFAULT_SEED
var rng: RandomNumberGenerator = null
var events: EventLog = null
var facts: FactBase = null

var _systems: Array[SimSystem] = []
var _inbox: Array[SimEvent] = []


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


## Record that something happened. Returns the logged event.
func submit(type: StringName, data: Dictionary = {}) -> SimEvent:
	var event := SimEvent.new(tick, type, data)
	events.append(event)
	_inbox.append(event)
	return event


func pending_count() -> int:
	return _inbox.size()


## The only entry point that mutates state. advance(n) is exactly n single steps,
## so how a caller chunks its calls can never change the outcome.
func advance(ticks: int = 1) -> void:
	for _step: int in max(ticks, 0):
		var batch: Array[SimEvent] = _inbox
		_inbox = []
		for event: SimEvent in batch:
			for system: SimSystem in _systems:
				system.on_event(self, event)
		tick += 1
		for system: SimSystem in _systems:
			system.on_tick(self, tick)


## Rebuild a run from its log. `systems` must be fresh, stateless instances.
##
## This is the proof of the architecture rather than a convenience: if replaying a
## log does not reproduce the fact base byte for byte, then something important is
## being stored outside the log, and the save format is a lie.
static func replay(rows: Array, p_seed: int, systems: Array[SimSystem], final_tick: int) -> Sim:
	var sim := Sim.new(p_seed)
	for system: SimSystem in systems:
		sim.add_system(system)
	for row: Variant in rows:
		var event := SimEvent.from_dict(row as Dictionary)
		if event.tick > sim.tick:
			sim.advance(event.tick - sim.tick)
		sim._inject(event)
	if final_tick > sim.tick:
		sim.advance(final_tick - sim.tick)
	return sim


## Re-queue an already-stamped event during replay, keeping its original tick.
func _inject(event: SimEvent) -> void:
	events.append(event)
	_inbox.append(event)
