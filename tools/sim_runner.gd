extends SceneTree

## Headless world-advance, for watching drift without a window.
##
##   godot --headless --path . -s tools/sim_runner.gd -- --ticks 5000 --seed 7
##
## One tick is one in-game minute and the overworld runs 4 ticks per real second
## (SPECS §8), so 5000 ticks is 3.5 in-game days — about 21 real minutes of play.

func _initialize() -> void:
	var ticks: int = _int_arg("--ticks", 1000)
	var run_seed: int = _int_arg("--seed", Sim.DEFAULT_SEED)

	var sim: Sim = Game.build(run_seed)
	var world := sim.store(&"world") as WorldState
	var ticked := sim.store(&"worldtick") as WorldTick

	var started_usec: int = Time.get_ticks_usec()
	sim.advance_world_ticks(ticks)
	var elapsed_ms: float = float(Time.get_ticks_usec() - started_usec) / 1000.0

	print("seed        %d" % sim.rng_seed)
	print("ticks       %d  (%s, %.1f real minutes of play)" % [
		sim.tick, Game.in_game_clock(sim.tick),
		float(sim.tick) / float(Game.TICKS_PER_REAL_SECOND) / 60.0,
	])
	print("steps       %d  (%d per world tick, %d per real second)" % [
		sim.step, Sim.STEPS_PER_WORLD_TICK, Sim.STEPS_PER_REAL_SECOND,
	])
	print("systems     %d" % sim.system_count())
	print("events      %d" % sim.events.size())
	print("facts       %d" % sim.facts.size())
	print("player      %s  hp %d/%d  deaths %d" % [
		world.player_tile(), world.player_hp, WorldState.MAX_HP, world.deaths,
	])
	print("to castle   %d tiles" % int(round(world.tiles_to_blackcairn())))
	print("escort      %d guards   army %.1f   fraud exposed %s" % [
		ticked.kings_escort(), ticked.army_strength, world.pay_fraud_exposed,
	])
	print("simulated   %.1f ms" % elapsed_ms)
	quit(0)


func _int_arg(flag: String, fallback: int) -> int:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i: int in args.size():
		if args[i] == flag and i + 1 < args.size():
			return int(args[i + 1])
	return fallback
