class_name Game
extends RefCounted

## Wires the world. One place, so the window and the tests run the same
## simulation and a test can never pass against a world the player never sees.

## SPECS §8: one world tick is one in-game minute, and the overworld runs 4 of
## them per real second. The simulation itself steps at 60 Hz — see Sim — so the
## world clock is unchanged and the player's input is not waiting on it.
const TICKS_PER_REAL_SECOND: int = 4


## A function rather than a constant: a const initialised from another class's
## const cannot be resolved at parse time, and duplicating the 60 here would be
## one more number able to drift out of step with Sim.
static func seconds_per_step() -> float:
	return 1.0 / float(Sim.STEPS_PER_REAL_SECOND)
const IN_GAME_MINUTES_PER_TICK: int = 1
const TICKS_PER_IN_GAME_DAY: int = 1440

## How close you must stand to talk to someone.
const TALK_REACH: float = 1.8


static func build(p_seed: int = Sim.DEFAULT_SEED) -> Sim:
	var sim := Sim.new(p_seed)
	sim.add_store(&"world", build_world())
	sim.add_store(&"cast", Cast.shared())
	sim.add_store(&"wildlife", Wildlife.new())
	for system: SimSystem in build_systems():
		sim.add_system(system)
	return sim


static func build_world() -> WorldState:
	var overworld: Region = Region.build_overworld()
	var world := WorldState.new()
	world.zones[WorldState.OVERWORLD] = overworld
	world.current_zone = WorldState.OVERWORLD
	world.player_pos = overworld.brindle_centre()
	world.player_tile_last = world.player_tile()
	world.king_pos = overworld.blackcairn_centre()
	return world


## Fresh, stateless systems. Replay needs a new set every time.
##
## Order matters and is the reading order of a tick: move, then arrive somewhere,
## then find out whether where you arrived kills you.
static func build_systems() -> Array[SimSystem]:
	var systems: Array[SimSystem] = []
	systems.append(MovementSystem.new())
	systems.append(ZoneSystem.new())
	systems.append(DialogueSystem.new())
	systems.append(ArmySystem.new())
	systems.append(WildlifeSystem.new())
	systems.append(ArrivalSystem.new())
	systems.append(ContactSystem.new())
	return systems


## Rebuild a run from its log alone, into a world that starts empty.
static func replay(sim: Sim) -> Sim:
	return Sim.replay(
		sim.events.to_array(),
		sim.rng_seed,
		build_systems(),
		sim.step,
		{&"world": build_world(), &"cast": Cast.shared(), &"wildlife": Wildlife.new()},
	)


static func in_game_days(tick: int) -> float:
	return float(tick) / float(TICKS_PER_IN_GAME_DAY)


static func in_game_clock(tick: int) -> String:
	var minutes: int = tick * IN_GAME_MINUTES_PER_TICK
	return "day %d, %02d:%02d" % [1 + minutes / 1440, (minutes / 60) % 24, minutes % 60]
