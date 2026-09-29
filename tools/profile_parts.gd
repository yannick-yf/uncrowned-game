extends SceneTree

## What the suite's common steps cost, measured one by one (T4, 2026-09-29).
##
##   godot --headless --path . -s tools/profile_parts.gd
##
## The fast suite spent 41 s on 601 tests, and most of the slow tests cost almost the
## same second each — the mark of one step paid again and again. This times each step a
## test commonly takes, so the next profile starts from numbers rather than guesses.


func _initialize() -> void:
	_time("Region.build_overworld(fresh)", func() -> void: Region.build_overworld(true))
	_time("Game.build()", func() -> void: Game.build())
	_time("Game.build() again", func() -> void: Game.build())
	var sim: Sim = Game.build()
	_time("advance one in-game hour", func() -> void:
		sim.advance(Sim.STEPS_PER_WORLD_TICK * 60))
	_time("advance one in-game day", func() -> void:
		sim.advance_world_ticks(Game.TICKS_PER_IN_GAME_DAY))
	_time("advance one in-game day, clock held off", func() -> void:
		sim.advance(Sim.STEPS_PER_WORLD_TICK * Game.TICKS_PER_IN_GAME_DAY))
	_time("the play screen, built and readied", func() -> void:
		var play: Node = (load("res://view/main.tscn") as PackedScene).instantiate()
		play.call(&"begin", Game.build())
		play.call(&"_ready")
		play.free())
	_by_system(Game.build(), Game.TICKS_PER_IN_GAME_DAY)
	quit(0)


## **One in-game day, system by system.** The same loop as `Sim.advance`, with a clock
## round each call, so the day's cost is split between the systems that pay it. Events
## are dispatched exactly as `advance` does, so the day is the same day.
func _by_system(sim: Sim, ticks: int) -> void:
	var spent: Dictionary = {}
	var calls: Dictionary = {}
	for _i: int in ticks * Sim.STEPS_PER_WORLD_TICK:
		var batch: Array[SimEvent] = sim._inbox
		sim._inbox = []
		for event: SimEvent in batch:
			for system: SimSystem in sim._systems:
				_charge(spent, calls, system, "event", func() -> void: system.on_event(sim, event))
		sim.step += 1
		sim._derived_this_step = 0
		for system: SimSystem in sim._steppers:
			_charge(spent, calls, system, "step", func() -> void: system.on_step(sim, sim.step))
		sim._steps_into_tick += 1
		if sim._steps_into_tick >= Sim.STEPS_PER_WORLD_TICK and not sim.ticks_held:
			sim._steps_into_tick = 0
			sim.tick += 1
			for system: SimSystem in sim._tickers:
				_charge(spent, calls, system, "tick", func() -> void: system.on_tick(sim, sim.tick))
	var rows: Array = []
	for key: String in spent.keys():
		rows.append([float(spent[key]) / 1000.0, key, int(calls[key])])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	print("one in-game day, by system (the clock round each call costs a little too):")
	for row: Array in rows:
		print("%9.1f ms  %7d calls  %s" % [float(row[0]), int(row[2]), String(row[1])])


func _charge(spent: Dictionary, calls: Dictionary, system: SimSystem, kind: String, call: Callable) -> void:
	var key: String = "%s.%s" % [(system.get_script() as Script).resource_path.get_file().get_basename(), kind]
	var began: int = Time.get_ticks_usec()
	call.call()
	spent[key] = int(spent.get(key, 0)) + Time.get_ticks_usec() - began
	calls[key] = int(calls.get(key, 0)) + 1


func _time(what: String, step: Callable) -> void:
	var began: int = Time.get_ticks_usec()
	step.call()
	print("%9.1f ms  %s" % [float(Time.get_ticks_usec() - began) / 1000.0, what])
