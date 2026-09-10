extends SceneTree

## Headless world-advance, for watching drift without a window.
##
##   godot --headless --path . -s tools/sim_runner.gd -- --ticks 5000 --seed 7
##
## One tick is one in-game minute and the overworld runs 4 ticks per real second
## (SPECS §8), so 5000 ticks is 3.5 in-game days — about 21 real minutes of play.

const TICKS_PER_IN_GAME_DAY: int = 1440
const TICKS_PER_REAL_SECOND: int = 4


func _initialize() -> void:
	var ticks: int = _int_arg("--ticks", 1000)
	var run_seed: int = _int_arg("--seed", Sim.DEFAULT_SEED)

	var sim := Sim.new(run_seed)
	# No systems yet: core/systems/ is empty until there is a world to react to.
	var started_usec: int = Time.get_ticks_usec()
	sim.advance(ticks)
	var elapsed_ms: float = float(Time.get_ticks_usec() - started_usec) / 1000.0

	print("seed        %d" % sim.rng_seed)
	print("ticks       %d  (%.1f in-game days, %.1f real minutes of play)" % [
		sim.tick,
		float(sim.tick) / float(TICKS_PER_IN_GAME_DAY),
		float(sim.tick) / float(TICKS_PER_REAL_SECOND) / 60.0,
	])
	print("systems     %d" % sim.system_count())
	print("events      %d" % sim.events.size())
	print("facts       %d" % sim.facts.size())
	print("simulated   %.1f ms" % elapsed_ms)
	quit(0)


func _int_arg(flag: String, fallback: int) -> int:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i: int in args.size():
		if args[i] == flag and i + 1 < args.size():
			return int(args[i + 1])
	return fallback
