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
	sim.add_store(&"worldtick", WorldTick.new())
	sim.add_store(&"standing", Standing.new())
	sim.add_store(&"rumours", Rumours.new())
	sim.add_store(&"travellers", Travellers.new())
	sim.add_store(&"phrasebook", Phrasebook.new())
	sim.add_store(&"allegiance", Allegiance.new())
	sim.add_store(&"traits", Traits.new())
	for system: SimSystem in build_systems():
		sim.add_system(system)
	return sim


## A fresh run with a character: the world built and `create_character` submitted with
## these trait levels, as the creation screen does when Begin is pressed. One place, so
## the quick start for testing and the real screen make the same first event.
static func begin_run(levels: Dictionary, p_seed: int = Sim.DEFAULT_SEED) -> Sim:
	var sim: Sim = build(p_seed)
	var data: Dictionary = {}
	for what: StringName in TraitRules.ALL:
		data[String(what)] = int(levels.get(what, TraitRules.FLOOR))
	sim.submit(&"create_character", data)
	sim.advance(1)
	return sim


static func build_world() -> WorldState:
	var overworld: Region = Region.build_overworld()
	var world := WorldState.new()
	world.zones[WorldState.OVERWORLD] = overworld
	world.current_zone = WorldState.OVERWORLD
	# The player wakes in the fairies' clearing, not in Brindle (§4's opening).
	# One corridor leads south out of it; walking out of the trees into the ruins,
	# with the furnaces in the same frame, is the opening and needs no exposition.
	world.player_pos = overworld.clearing_centre()
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
	systems.append(PhrasingSystem.new())
	systems.append(ArmySystem.new())
	systems.append(WorldTickSystem.new())
	systems.append(GrainSystem.new())
	systems.append(UnrestSystem.new())
	systems.append(TellingSystem.new())
	systems.append(TravellerSystem.new())
	systems.append(CreationSystem.new())
	systems.append(AllegianceSystem.new())
	systems.append(EndingSystem.new())
	systems.append(ActSystem.new())
	systems.append(TheftSystem.new())
	systems.append(RumourSystem.new())
	systems.append(RestSystem.new())
	systems.append(RecoverySystem.new())
	systems.append(ArrivalSystem.new())
	systems.append(ContactSystem.new())
	return systems


## Rebuild a run from rows on disk. The same path a replay test takes, which is why
## loading a save is not a feature with its own bugs — it is the thing every test
## has been exercising since Phase 0.
static func replay_rows(rows: Array, p_seed: int, final_step: int) -> Sim:
	return Sim.replay(rows, p_seed, build_systems(), final_step, fresh_stores())


static func fresh_stores() -> Dictionary:
	return {
		&"world": build_world(), &"cast": Cast.shared(),
		&"worldtick": WorldTick.new(),
		&"standing": Standing.new(), &"rumours": Rumours.new(),
		&"travellers": Travellers.new(), &"phrasebook": Phrasebook.new(),
		&"allegiance": Allegiance.new(), &"traits": Traits.new(),
	}


## Rebuild a run from its log alone, into a world that starts empty.
static func replay(sim: Sim) -> Sim:
	return replay_rows(sim.events.external_rows(), sim.rng_seed, sim.step)


static func in_game_days(tick: int) -> float:
	return float(tick) / float(TICKS_PER_IN_GAME_DAY)


## Day, hour, minute — numbers, not a sentence. The window puts the word "day" in
## front of it, because that word has a language and core does not have one.
static func in_game_clock_parts(tick: int) -> Array:
	var minutes: int = tick * IN_GAME_MINUTES_PER_TICK
	return [1 + minutes / 1440, "%02d" % ((minutes / 60) % 24), "%02d" % (minutes % 60)]
