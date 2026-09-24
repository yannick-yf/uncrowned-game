extends TestCase

## The fight, second design — turn-based, on the world grid (K1, K2; `docs/COMBAT_V2.md`).
##
## Everything here runs headless: nobody draws anything, and a fight is a handful of
## integers and a fixed order. **Nothing in it is random** — not a seeded roll, not a
## coin — so two runs of the same fight are the same fight, which several of these
## tests check rather than assume.
##
## **In the fast suite on purpose**, for the reason `test_combat.gd` gives: the fight
## is the thing that will be retuned most often in this project, and a balance change
## you have to remember to check is a balance change nobody checks.
const SLOW: bool = false


func after_each() -> void:
	# The balance table is static and one of these tests edits it. A leaked override
	# would quietly rebalance every fight that ran after it, in this suite and the next.
	DuelRules.forget()


func _duel(sim: Sim) -> Duel:
	return sim.store(&"duel") as Duel


## A fight against somebody, started by whoever `by` names. The player keeps the ground
## they are standing on; the opponent is set down a stride away on the side they are on.
func _start(against: String = "bram", by: String = "player") -> Sim:
	var sim: Sim = Game.build()
	sim.submit(&"duel_began", {"opponent": against, "by": by})
	sim.advance(1)
	return sim


## The same, on open ground. A fight about *walking away* needs somewhere to walk to,
## and where the player wakes is a clearing in a wood on one map and a hollow on the
## other. Said in the world's own terms — `alone_on_the_road` — rather than as a tile,
## so it holds on both. The position is written straight into the store and is
## therefore not in the log; nothing below it replays.
func _start_in_the_open(against: String = "bram", by: String = "player") -> Sim:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	world.player_pos = alone_on_the_road()
	sim.submit(&"duel_began", {"opponent": against, "by": by})
	sim.advance(1)
	return sim


## Plays a fight with one of `DuelPlayer`'s hands on the keys, up to `steps` steps or
## until it is over. Returns how many steps it actually took.
func _play(sim: Sim, policy: StringName, steps: int) -> int:
	var hands := DuelPlayer.new(policy)
	var duel: Duel = _duel(sim)
	for step: int in steps:
		if not duel.on():
			return step
		hands.play(sim, duel)
		sim.advance(1)
	return steps


## The blows one side landed. `by` is `"player"` or a cast id, which is the word the
## window's blows already speak.
func _blows_by(sim: Sim, by: String) -> int:
	var count: int = 0
	for event: SimEvent in sim.events.of_type(&"blow_landed"):
		if String(event.data.get("by", "")) == by:
			count += 1
	return count


## Runs the fight until the player has taken `turns` turns, or the fight ends.
func _play_turns(sim: Sim, policy: StringName, turns: int, cap: int = 4000) -> void:
	var hands := DuelPlayer.new(policy)
	var duel: Duel = _duel(sim)
	var taken: int = 0
	for _step: int in cap:
		if not duel.on() or taken >= turns:
			return
		if hands.play(sim, duel):
			taken += 1
		sim.advance(1)


# ------------------------------------------------------------------- the table ---
#
# K2's hard requirement, and the one rule worth keeping from the first design: **all of
# balance stays one small table**. Two tests hold it, because it can be broken in two
# ways — a number written into the machinery, and a fallback in the rules that quietly
# says something other than the file.

## Every integer and float written in the fight's machinery, with the line it is on.
## Comments and strings are taken out first, and a digit inside a name — `Vector2i`,
## `maxi` — is not a number.
func _numbers_in(path: String) -> Array:
	var out: Array = []
	var strings := RegEx.create_from_string("&?\"[^\"]*\"")
	var numbers := RegEx.create_from_string("(?<![A-Za-z0-9_.])[0-9]+(\\.[0-9]+)?")
	var line_at: int = 0
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		line_at += 1
		var hash_at: int = line.find("#")
		var code: String = line.substr(0, hash_at) if hash_at >= 0 else line
		code = strings.sub(code, "", true)
		for found: RegExMatch in numbers.search_all(code):
			out.append([line_at, found.get_string(), line.strip_edges()])
	return out


func test_the_fights_machinery_holds_no_number_of_its_own() -> void:
	# A balance number written in a system is a balance number nobody finds again. The
	# only figures allowed here are structural — an index, a counter, a nothing.
	var looked: int = 0
	for path: String in ["res://core/systems/duel_system.gd", "res://core/duel.gd",
			"res://core/duel_fighter.gd"]:
		for row: Array in _numbers_in(path):
			looked += 1
			assert_true(float(row[1]) <= 1.0,
				"%s:%d writes %s — every number the fight uses belongs in content/duel.json: %s"
					% [path.get_file(), int(row[0]), String(row[1]), String(row[2])])
	assert_true(looked > 0, "the scan found something to look at")


func test_the_rules_never_quietly_disagree_with_the_file() -> void:
	# Each accessor carries a fallback so a missing row cannot crash a fight. A fallback
	# that drifts from the file is a second balance table nobody is reading.
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DuelRules.PATH))
	var table: Dictionary = (parsed as Dictionary)["table"] as Dictionary
	assert_eq(DuelRules.tiles_per_turn(), int(table["tiles_per_turn"]))
	assert_eq(DuelRules.reach_tiles(), int(table["reach_tiles"]))
	assert_eq(DuelRules.strike_damage(), int(table["strike_damage"]))
	assert_eq(DuelRules.player_hp(), int(table["player_hp"]))
	assert_eq(DuelRules.stand_off_tiles(), int(table["stand_off_tiles"]))
	assert_eq(DuelRules.leaves_at_tiles(), int(table["leaves_at_tiles"]))
	assert_eq(DuelRules.leaves_after_rounds(), int(table["leaves_after_rounds"]))
	assert_eq(DuelRules.follows_tiles(), int(table["follows_tiles"]))
	assert_eq(DuelRules.flees_at_hp(), int(table["flees_at_hp"]))
	assert_eq(DuelRules.steps_per_tile(), int(table["steps_per_tile"]))
	assert_eq(DuelRules.act_steps(), int(table["act_steps"]))
	assert_eq(DuelRules.strike_at_step(), int(table["strike_at_step"]))
	assert_eq(DuelRules.hurt_steps(), int(table["hurt_steps"]))
	assert_eq(DuelRules.pause_steps(), int(table["pause_steps"]))
	assert_eq(DuelRules.beat_steps(), int(table["beat_steps"]))


func test_all_of_the_balance_is_one_small_table() -> void:
	# The one rule worth keeping from the first design. Every number that decides how a
	# fight goes is in content/duel.json and in no other file.
	var table: Dictionary = DuelRules.table()
	for key: String in ["tiles_per_turn", "reach_tiles", "strike_damage", "player_hp",
			"stand_off_tiles", "leaves_at_tiles", "leaves_after_rounds", "follows_tiles",
			"flees_at_hp", "steps_per_tile",
			"act_steps", "strike_at_step", "hurt_steps", "pause_steps", "beat_steps"]:
		assert_true(table.has(key), "the table says what '%s' is" % key)
	assert_eq(DuelRules.tiles_per_turn(), 4, "four tiles a turn — eight metres")
	assert_eq(DuelRules.reach_tiles(), 1, "reach is one tile")
	assert_eq(DuelRules.strike_damage(), 5, "a strike takes five")
	assert_eq(DuelRules.player_hp(), 100, "the player's hundred, a development value")
	assert_eq(DuelRules.hp_of(&"bram"), 10, "and everything else has ten")
	assert_eq(DuelRules.hp_of(&"nobody_in_particular"), 10, "including anybody not listed")


func test_there_are_two_actions_and_no_guard() -> void:
	# Yannick, 2026-09-24: Baldur's Gate 3 has no block button and neither does this.
	# Defence is position and initiative.
	assert_eq(DuelRules.STRIKE, &"strike")
	assert_eq(DuelRules.WAIT, &"wait")
	assert_false(DuelRules.table().has("guard"), "there is no guard in the table")
	var sim: Sim = _start()
	var duel: Duel = _duel(sim)
	var mine: DuelFighter = duel.me()
	sim.submit(&"duel_turn", {"who": "player", "to_x": mine.at.x, "to_y": mine.at.y,
		"action": "guard", "target": "bram"})
	sim.advance(2)
	assert_eq(duel.acting, DuelRules.WAIT, "anything that is not a strike is a wait")


func test_editing_the_table_alone_changes_the_outcome_of_a_scripted_fight() -> void:
	# K2's check, and the reason the table exists. Same fight, same hands, one number.
	var five: Sim = _start()
	_play(five, DuelPlayer.PRESS, 4000)
	assert_eq((_duel(five)).outcome, &"won", "ten health against five a blow")
	assert_eq(_blows_by(five, "player"), 2, "goes down in two")

	DuelRules.override({"strike_damage": 10})
	var ten: Sim = _start()
	_play(ten, DuelPlayer.PRESS, 4000)
	assert_eq((_duel(ten)).outcome, &"won", "and against ten a blow")
	assert_eq(_blows_by(ten, "player"), 1, "it goes down in one")


func test_the_movement_cap_is_the_tables_and_nothing_elses() -> void:
	var region: Region = Region.build_overworld()
	var from: Vector2i = Vector2i(alone_on_the_road())
	var four: Dictionary = DuelRules.reachable(from, region, DuelRules.tiles_per_turn())
	for key: Variant in four.keys():
		assert_true(DuelRules.apart(from, key as Vector2i) <= 4,
			"nothing further than four tiles is reachable in one turn")
	DuelRules.override({"tiles_per_turn": 2})
	var two: Dictionary = DuelRules.reachable(from, region, DuelRules.tiles_per_turn())
	assert_true(two.size() < four.size(), "and two tiles a turn reaches fewer of them")


# -------------------------------------------------------------------- the grid ---

func test_reach_is_one_tile_and_diagonals_count() -> void:
	# The game's movement is 8-way, so a diagonal is one step like any other.
	var here := Vector2i(10, 10)
	assert_true(DuelRules.in_reach(here, Vector2i(11, 10)), "east of you")
	assert_true(DuelRules.in_reach(here, Vector2i(11, 11)), "and diagonally too")
	assert_false(DuelRules.in_reach(here, Vector2i(12, 10)), "but not two away")
	assert_false(DuelRules.in_reach(here, here), "and not yourself")
	assert_eq(DuelRules.apart(here, Vector2i(14, 12)), 4, "8-way distance, not the crow's")


func test_a_tile_is_the_maps_own_tile() -> void:
	# A fight that disagreed with the map about how big a tile is would be wrong in a
	# way no test of the fight alone could see.
	assert_eq(DuelRules.metres_of(1), BakeRules.METRES_PER_TILE, "two metres, from the bake")
	assert_eq(DuelRules.metres_of(DuelRules.tiles_per_turn()), 8.0, "so a turn is eight")


# ------------------------------------------------------------------- the turn ---

func test_whoever_started_the_fight_acts_first() -> void:
	# There is no initiative roll, because there are no dice. Attacking from a
	# conversation is an advantage, and the price is paid in standing.
	var mine: Sim = _start("bram", "player")
	assert_true((_duel(mine)).waiting_on_player(), "you opened on him, so it is your turn")
	var his: Sim = _start("bram", "bram")
	var duel: Duel = _duel(his)
	assert_false(duel.waiting_on_player(), "he opened on you, so it is not")
	assert_eq((duel.acting_fighter()).who, &"bram", "he moves first")


func test_a_turn_is_move_and_act() -> void:
	# Yannick, 2026-09-24: both, not one or the other.
	var sim: Sim = _start()
	var duel: Duel = _duel(sim)
	var was: Vector2i = (duel.me()).at
	_play_turns(sim, DuelPlayer.PRESS, 1)
	sim.advance(DuelRules.tiles_per_turn() * DuelRules.steps_per_tile() + DuelRules.act_steps())
	assert_ne((duel.me()).at, was, "the player moved on their turn")
	assert_eq(_blows_by(sim, "player"), 1, "and struck on the same one")


func test_a_fighter_cannot_cross_the_grid_and_strike_in_the_same_turn() -> void:
	# The cap is not a comfort setting: without it, moving and acting in one turn makes
	# the grid meaningless. Standing six tiles off, a turn cannot both close and land.
	var sim: Sim = _start()
	var duel: Duel = _duel(sim)
	var mine: DuelFighter = duel.me()
	var him: DuelFighter = duel.foe()
	him.at = mine.at + Vector2i(6, 0)
	sim.submit(&"duel_turn", {"who": "player", "to_x": mine.at.x + 4, "to_y": mine.at.y,
		"action": "strike", "target": "bram"})
	sim.advance(2)
	assert_eq(duel.acting, DuelRules.WAIT, "a strike at nobody in reach becomes a wait")
	sim.advance(DuelRules.tiles_per_turn() * DuelRules.steps_per_tile() + DuelRules.act_steps())
	assert_eq(_blows_by(sim, "player"), 0, "and nothing of the player's was landed")


func test_a_blow_does_not_move_you() -> void:
	# No knockback, no pushbox, no shove (Yannick, 2026-09-24). A hit that moved you
	# would make position depend on the enemy's dice, and there are no dice.
	var sim: Sim = _start()
	var duel: Duel = _duel(sim)
	var him: DuelFighter = duel.foe()
	_play_turns(sim, DuelPlayer.PRESS, 1)
	# Walked, and about to swing: the tile he is standing on now is the one the blow
	# must leave him on. Anything after his own turn would be him moving, not the blow.
	for _step: int in 400:
		if duel.phase == Duel.ACTING:
			break
		sim.advance(1)
	var stood: Vector2i = him.at
	var health: int = him.hp
	for _step: int in 400:
		if duel.struck:
			break
		sim.advance(1)
	sim.advance(1)
	assert_true(him.hp < health, "he took it")
	assert_eq(him.at, stood, "and he is standing exactly where he was")
	assert_true(him.hurt_left > 0, "flinching, which is the whole of what a blow does to him")


func test_the_world_clock_is_held_for_the_length_of_it() -> void:
	var sim: Sim = _start()
	var tick: int = sim.tick
	sim.advance(200)
	assert_true(sim.ticks_held, "the world's clock is held")
	assert_eq(sim.tick, tick, "so a fight is not an hour of the day")


# ------------------------------------------------------------------- the log ---

func test_a_fight_of_twenty_turns_is_twenty_events() -> void:
	# K1's check, and the whole of what makes a fight replayable: the log holds that a
	# fight began, one event per turn, and that it ended. Nothing else.
	DuelRules.override({"player_hp": 400, "strike_damage": 1, "flees_at_hp": 0})
	var sim: Sim = _start("harry", "player")
	var duel: Duel = _duel(sim)
	# Enough health on both sides that twenty turns pass before anybody falls: the
	# count of events is what is being tested here, not the balance.
	(duel.foe()).hp = 400
	(duel.foe()).max_hp = 400
	for _step: int in 6000:
		if duel.turns_taken >= 20 or not duel.on():
			break
		DuelPlayer.new(DuelPlayer.PRESS).play(sim, duel)
		sim.advance(1)
	assert_eq(duel.turns_taken, 20, "twenty turns were taken")
	assert_eq(sim.events.of_type(&"duel_turn").size(), 20, "and the log holds twenty rows")


func test_the_players_own_turn_is_not_written_down_twice() -> void:
	# The event the player submitted IS the record. Deriving a second one would make a
	# fight of twenty turns twenty-five events, and replay would take each turn twice.
	var sim: Sim = _start()
	_play_turns(sim, DuelPlayer.PRESS, 1)
	var rows: Array[SimEvent] = sim.events.of_type(&"duel_turn")
	assert_eq(rows.size(), 1, "one turn, one row")
	assert_false(rows[0].derived, "and it is the player's own, not a copy of it")


func test_the_same_log_replays_to_the_same_tiles() -> void:
	# The reason a fight lives in the simulation at all. A save here IS the event log.
	var sim: Sim = _start()
	_play(sim, DuelPlayer.PRESS, 600)
	var duel: Duel = _duel(sim)
	var world := sim.store(&"world") as WorldState
	var replayed: Sim = Game.replay(sim)
	assert_eq((replayed.store(&"duel") as Duel).fingerprint(), duel.fingerprint(),
		"the same fight, rebuilt from the log alone")
	assert_eq((replayed.store(&"world") as WorldState).player_pos, world.player_pos,
		"standing on the same tile")
	assert_eq(replayed.events.of_type(&"blow_landed").size(),
		sim.events.of_type(&"blow_landed").size(), "with the same blows in it")


func test_the_same_five_turns_twice_over_get_the_same_result_to_the_tile() -> void:
	# K2's check. Two runs, two different seeds, and nothing to tell them apart —
	# because nothing in this design is random, not even seeded.
	var one: Sim = Game.build(1)
	one.submit(&"duel_began", {"opponent": "harry"})
	one.advance(1)
	_play_turns(one, DuelPlayer.PRESS, 5)
	var two: Sim = Game.build(999)
	two.submit(&"duel_began", {"opponent": "harry"})
	two.advance(1)
	_play_turns(two, DuelPlayer.PRESS, 5)
	assert_eq((one.store(&"duel") as Duel).fingerprint(),
		(two.store(&"duel") as Duel).fingerprint(), "the same five turns to the tile")
	assert_eq((one.store(&"world") as WorldState).player_pos,
		(two.store(&"world") as WorldState).player_pos, "standing in the same place")


func test_how_the_caller_chunks_its_steps_changes_nothing() -> void:
	var one: Sim = _start("harry")
	var many: Sim = _start("harry")
	one.advance(300)
	for _i: int in 300:
		many.advance(1)
	assert_eq((one.store(&"duel") as Duel).fingerprint(),
		(many.store(&"duel") as Duel).fingerprint(), "300 at once is 300 one at a time")


# ------------------------------------------------- ending, fleeing, and leaving ---

func test_a_fight_ends_when_somebody_reaches_nothing() -> void:
	var sim: Sim = _start()
	var duel: Duel = _duel(sim)
	_play(sim, DuelPlayer.PRESS, 4000)
	assert_false(duel.on(), "it is over")
	assert_eq(duel.outcome, &"won")
	assert_eq(sim.events.of_type(&"duel_ended").size(), 1, "and said so once")
	sim.advance(2)
	assert_false(sim.ticks_held, "the world is allowed to run again")


func test_the_end_is_held_for_a_beat_before_the_world_comes_back() -> void:
	var sim: Sim = _start()
	var duel: Duel = _duel(sim)
	for _step: int in 4000:
		if duel.outcome != &"" :
			break
		DuelPlayer.new(DuelPlayer.PRESS).play(sim, duel)
		sim.advance(1)
	assert_eq(duel.outcome, &"won", "decided")
	assert_true(duel.settled(), "and not over: somebody is down and the world is still held")
	assert_eq(sim.events.of_type(&"duel_ended").size(), 0, "nothing has been handed back yet")
	sim.advance(DuelRules.beat_steps() + 2)
	assert_false(duel.on(), "then the beat runs out")
	assert_eq(sim.events.of_type(&"duel_ended").size(), 1, "and the one result is handed over")


func test_a_wounded_opponent_runs_rather_than_striking() -> void:
	# docs/COMBAT_V2.md §5: attack the works' people and they run and hide somewhere.
	var sim: Sim = _start()
	var duel: Duel = _duel(sim)
	var him: DuelFighter = duel.foe()
	var mine: DuelFighter = duel.me()
	_play_turns(sim, DuelPlayer.PRESS, 1)
	_play(sim, DuelPlayer.STAND, 40)
	assert_true(him.hp <= DuelRules.flees_at_hp(), "one blow of five leaves him at it")
	var was: int = DuelRules.apart(mine.at, him.at)
	_play(sim, DuelPlayer.STAND, 400)
	assert_true(DuelRules.apart(mine.at, him.at) > was,
		"and he spends his turn getting away rather than swinging")
	assert_eq(_blows_by(sim, "bram"), 0, "he threw nothing back")


func test_nothing_stops_the_player_walking_out_of_a_fight() -> void:
	# K4's rule from the simulation's side: the ring is not a boundary, and leaving is
	# the same for the player as for anybody. It takes more than one turn, because a
	# chaser closes what a retreat opens — which is why it is settled once a round.
	var sim: Sim = _start_in_the_open()
	var duel: Duel = _duel(sim)
	_play(sim, DuelPlayer.LEAVE, 4000)
	assert_false(duel.on(), "the fight is over without a blow being landed")
	assert_eq(duel.outcome, &"left", "and it ended because the player walked out of it")
	assert_eq(sim.events.of_type(&"blow_landed").size(), 0, "nobody hit anybody")
	assert_eq(sim.events.of_type(&"duel_fled").size(), 1, "one of them left")


func test_leaving_takes_more_than_one_turn() -> void:
	# Four tiles out is not out: the man in front of you has his own turn to close it.
	var sim: Sim = _start_in_the_open()
	var duel: Duel = _duel(sim)
	_play_turns(sim, DuelPlayer.LEAVE, 1)
	_play(sim, DuelPlayer.LEAVE, 20)
	assert_true(duel.on(), "one turn of walking away is not leaving")


func test_being_asked_to_leave_ends_it_too() -> void:
	var sim: Sim = _start()
	var duel: Duel = _duel(sim)
	sim.submit(&"duel_left", {})
	sim.advance(DuelRules.beat_steps() + 4)
	assert_false(duel.on())
	assert_eq(duel.outcome, &"left")


func test_losing_is_paid_down_the_one_path_everything_that_hurts_you_takes() -> void:
	# The death, the count, the respawn at the last fire — one path, as everything that
	# can hurt the player goes through `WorldState.hurt`.
	DuelRules.override({"player_hp": 5})
	var sim: Sim = _start("harry", "harry")
	var duel: Duel = _duel(sim)
	var world := sim.store(&"world") as WorldState
	_play(sim, DuelPlayer.STAND, 4000)
	assert_eq(duel.outcome, &"lost", "one blow of five against five and the player is down")
	assert_eq(world.deaths, 1, "and it was paid as a death")


func test_a_sparring_partner_stops_when_you_go_down() -> void:
	# Bram says so in his own line, so the code had better agree with the content.
	DuelRules.override({"player_hp": 5})
	var sim: Sim = _start("bram", "bram")
	var world := sim.store(&"world") as WorldState
	_play(sim, DuelPlayer.STAND, 4000)
	assert_eq((_duel(sim)).outcome, &"lost", "you lost")
	assert_eq(world.deaths, 0, "and he left you standing")
	assert_eq(world.player_hp, 1, "with one point of it")


func test_nothing_can_take_a_point_off_you_while_the_development_switch_is_on() -> void:
	# `G`, and it is read here as well as in `WorldState.hurt`: a fight that drained a
	# bar nothing was allowed to empty would be a fight the HUD lied about.
	DuelRules.override({"player_hp": 5})
	var sim: Sim = Game.build()
	sim.submit(&"unkillable", {"on": true})
	sim.submit(&"duel_began", {"opponent": "harry", "by": "harry"})
	sim.advance(1)
	var duel: Duel = _duel(sim)
	_play(sim, DuelPlayer.STAND, 1200)
	assert_true(duel.on() or duel.settled(), "the fight is still going after a blow")
	assert_eq((duel.me()).hp, 1, "and the player is left standing on one")


# -------------------------------------------------- what the window is handed ---

func test_the_shape_of_a_blow_is_the_fights_business_and_not_the_windows() -> void:
	# Pure, so it can be tested with nothing on screen, and the same in both windows.
	assert_eq(DuelRules.pose_of(0, DuelRules.WAIT, 0), &"", "waiting is standing")
	assert_eq(DuelRules.pose_of(0, DuelRules.STRIKE, 0), &"ready", "the wind-up is drawn back")
	assert_eq(DuelRules.pose_of(0, DuelRules.STRIKE, DuelRules.strike_at_step()), &"attack",
		"and the blow is out on the step it lands")
	assert_eq(DuelRules.pose_of(3, DuelRules.STRIKE, 0), &"hurt",
		"a fighter struck mid-blow is shown taking it")
	assert_eq(DuelRules.telegraph_at(DuelRules.WAIT, 0), -1.0, "nothing is winding up")
	assert_eq(DuelRules.telegraph_at(DuelRules.STRIKE, 0), 0.0, "and a tell begins at nothing")
	assert_true(DuelRules.lunge_at(DuelRules.STRIKE, 0) < 0.0, "drawn back before it goes out")
	assert_eq(DuelRules.lunge_at(DuelRules.STRIKE, DuelRules.strike_at_step()), 1.0,
		"and fully out on the step it lands")


func test_the_walk_is_drawn_between_two_tiles() -> void:
	var sim: Sim = _start()
	var duel: Duel = _duel(sim)
	_play_turns(sim, DuelPlayer.PRESS, 1)
	sim.advance(DuelRules.steps_per_tile() / 2)
	var mine: DuelFighter = duel.me()
	if duel.phase != Duel.MOVING:
		assert_true(true, "the first turn had nowhere to walk")
		return
	assert_ne(duel.drawn_at(mine), mine.centre(),
		"a fighter half way across a tile is drawn half way across it")
