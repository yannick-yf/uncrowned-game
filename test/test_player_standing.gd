extends TestCase

## What a town thinks of the player — `docs/PLAYER_MODEL.md` §§1–3, task J2.
##
## **The town is the unit of account.** A deed moves the standing of the place it
## happened in, and of no other place, and it moves nothing at all if nobody saw it.
##
## The old model is still running beside this one and is meant to be: `Standing`'s
## factions, its per-person ledger and its town opinion carried by rumour all go with
## **C3**, not with this task. So these tests read `PlayerState` and never `Standing`,
## and the ones that hold the old model true are still in `test_deeds`, `test_rumour`
## and `test_factions`, still green.


func _at(sim: Sim, where: Vector2) -> void:
	(sim.store(&"world") as WorldState).player_pos = where


## Somebody's own tile, so there is certainly a pair of eyes on it.
func _beside(sim: Sim, who: StringName) -> Vector2:
	var npc: Npc = (sim.store(&"cast") as Cast).get_npc(who)
	if npc == null:
		fail("nobody called %s stands in the world" % who)
		return Vector2.ZERO
	return Vector2(npc.centre())


func _steal_in(sim: Sim, town: StringName, at: Vector2) -> void:
	_at(sim, at)
	Deeds.perform(sim, DeedRules.DEED_THEFT, town, at, &"theft_unseen")
	sim.advance(2)


func _days(sim: Sim, count: float) -> void:
	sim.advance_world_ticks(int(float(Game.TICKS_PER_IN_GAME_DAY) * count))


# ------------------------------------------------- the town, and no other town ---

func test_a_theft_in_the_cinderworks_moves_the_cinderworks_and_no_other_town() -> void:
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	_steal_in(sim, &"cinderworks", _beside(sim, &"ivo"))
	assert_true(player.standing_in(&"cinderworks") < PlayerState.NEUTRAL,
		"the works saw it: %.1f" % player.standing_in(&"cinderworks"))
	for town: StringName in player.towns():
		if town == &"cinderworks":
			continue
		assert_eq(player.standing_in(town), PlayerState.NEUTRAL,
			"%s was not there and has no opinion of you" % town)

	# And three days later, with the story arrived everywhere it travels, still none.
	# The player's standing does not propagate place to place (§4): the kingdom's star
	# is the only route, and a town's own opinion is made of deeds done in it.
	_days(sim, 3.0)
	for town: StringName in player.towns():
		if town == &"cinderworks":
			continue
		assert_eq(player.standing_in(town), PlayerState.NEUTRAL,
			"%s heard the story and still has no opinion of you" % town)


func test_a_theft_nobody_saw_moves_nothing() -> void:
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	var cast := sim.store(&"cast") as Cast
	var corner: Vector2 = empty_corner_of(&"cinderworks")
	assert_eq(CrimeRules.witnesses_to(cast, WorldState.OVERWORLD, corner).size(), 0,
		"nobody is standing in that corner of the works")
	_steal_in(sim, &"cinderworks", corner)
	for town: StringName in player.towns():
		assert_eq(player.standing_in(town), PlayerState.NEUTRAL,
			"%s: a deed nobody saw did not happen" % town)


func test_the_deed_the_player_actually_commits_moves_the_town_it_was_done_in() -> void:
	# The one above performs the deed through the shared pipe directly, because no
	# stall stands in the Cinderworks. This is the whole path — a key press, a stall,
	# the witnesses, the standing — in the town that has stalls.
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	_at(sim, at_a_stall(&"harrowgate"))
	sim.submit(&"steal")
	sim.advance(2)
	assert_true(player.standing_in(&"harrowgate") < PlayerState.NEUTRAL,
		"Harrowgate saw you take it: %.1f" % player.standing_in(&"harrowgate"))
	assert_eq(player.standing_in(&"muster"), PlayerState.NEUTRAL, "the camp was not there")


func test_putting_it_back_repairs_the_place_and_no_other() -> void:
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	_at(sim, at_a_stall(&"harrowgate"))
	sim.submit(&"steal")
	sim.advance(2)
	var after_the_theft: float = player.standing_in(&"harrowgate")
	sim.submit(&"give_back")
	sim.advance(2)
	assert_true(player.standing_in(&"harrowgate") > after_the_theft,
		"they watched you put it back")
	assert_true(player.standing_in(&"harrowgate") < PlayerState.NEUTRAL,
		"but the town remembers: %.1f" % player.standing_in(&"harrowgate"))


# --------------------------------------------------- what a place is, and is not ---

func test_the_five_places_that_carry_numbers_are_the_five_that_have_an_opinion() -> void:
	# The same five `TownState` carries, read from the same file, so the player's
	# standing and the places' two values can never disagree about which places exist.
	var player := Game.build().store(&"player") as PlayerState
	for id: StringName in [&"cinderworks", &"wide_acres", &"harrowgate", &"muster", &"saltmarch"]:
		assert_true(player.has_standing(id), "%s has an opinion of you" % id)
	assert_false(player.has_standing(&"brindle"),
		"a ruin has nobody in it to have one")
	assert_eq(player.towns().size(), 5, "and there are five of them")


func test_a_town_never_visited_sits_at_neutral() -> void:
	var player := Game.build().store(&"player") as PlayerState
	for town: StringName in player.towns():
		assert_eq(player.standing_in(town), PlayerState.NEUTRAL,
			"%s has heard nothing about you" % town)


func test_standing_does_not_decay() -> void:
	# Yannick, 2026-09-23: a town remembers. No timer quietly forgives, because a
	# number that drains is a number the player cannot reason about.
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	_steal_in(sim, &"cinderworks", _beside(sim, &"ivo"))
	var straight_after: float = player.standing_in(&"cinderworks")
	_days(sim, 5.0)
	assert_eq(player.standing_in(&"cinderworks"), straight_after,
		"five days later, to the decimal")


func test_a_deed_on_the_road_moves_nothing_and_says_so() -> void:
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	Deeds.perform(sim, DeedRules.DEED_THEFT, &"brindle", _beside(sim, &"ivo"))
	sim.advance(2)
	for town: StringName in player.towns():
		assert_eq(player.standing_in(town), PlayerState.NEUTRAL,
			"%s: a ruin is outside the system" % town)
	var kinds: Array[StringName] = []
	for event: SimEvent in sim.events.all():
		kinds.append(event.type)
	assert_true(kinds.has(&"standing_unmoved"), "and the log says nothing happened")


# ------------------------------------------------------------ the scale's ends ---

func test_a_theft_costs_ten_and_a_murder_costs_eighty() -> void:
	# Yannick's two worked examples, end to end (§3, 2026-09-23), written out because
	# the gap between them *is* the design: ten thefts and you are hated in one town;
	# one murder and you are nearly there in a single afternoon.
	assert_eq(PlayerRules.standing_effect(DeedRules.DEED_THEFT), -10.0, "a theft")
	assert_eq(PlayerRules.standing_effect(PlayerRules.DEED_KILLED_INNOCENT), -80.0,
		"killing somebody innocent")
	assert_eq(StandingRules.word_for(10.0 * PlayerRules.A_THEFT), &"hated",
		"ten thefts and one town is done with you")
	assert_eq(StandingRules.word_for(PlayerRules.A_MURDER), &"hated",
		"and one murder gets there in an afternoon")


func test_killing_a_man_who_drew_first_is_not_the_same_deed_as_killing_a_bystander() -> void:
	# The substance of J3. Two ids rather than one judgement made at the moment of the
	# blow, because the town's opinion is the only place the distinction can show.
	var murder: float = PlayerRules.standing_effect(PlayerRules.DEED_KILLED_INNOCENT)
	var self_defence: float = PlayerRules.standing_effect(PlayerRules.DEED_KILLED_ATTACKER)
	assert_true(self_defence > murder,
		"a man who drew on you first costs less: %.1f against %.1f" % [self_defence, murder])
	assert_true(self_defence < PlayerState.NEUTRAL,
		"but it is not free — there is still a body in the street: %.1f" % self_defence)
	assert_true(absf(self_defence) < absf(PlayerRules.A_THEFT) * 3.0,
		"and it is nearer a theft than a murder")


func test_the_two_killings_move_the_town_they_happened_in() -> void:
	# Not the table this time: the whole pipe, both deeds, in the same town, so that
	# the distinction cannot quietly disappear into a rules file nothing calls.
	var murdered: Sim = Game.build()
	_at(murdered, _beside(murdered, &"ivo"))
	Deeds.perform(murdered, PlayerRules.DEED_KILLED_INNOCENT, &"cinderworks",
		_beside(murdered, &"ivo"))
	murdered.advance(2)

	var defended: Sim = Game.build()
	_at(defended, _beside(defended, &"ivo"))
	Deeds.perform(defended, PlayerRules.DEED_KILLED_ATTACKER, &"cinderworks",
		_beside(defended, &"ivo"))
	defended.advance(2)

	var after_murder: float = (murdered.store(&"player") as PlayerState).standing_in(&"cinderworks")
	var after_defence: float = (defended.store(&"player") as PlayerState).standing_in(&"cinderworks")
	assert_eq(after_murder, PlayerRules.A_MURDER, "the works watched you kill a bystander")
	assert_eq(after_defence, PlayerRules.A_KILLING_IN_SELF_DEFENCE,
		"and watched somebody draw on you first")
	assert_eq(StandingRules.word_for(after_murder), &"hated", "one is the end of that town")
	assert_ne(StandingRules.word_for(after_defence), &"hated", "and one is not")


func test_a_killing_nobody_saw_moves_nothing_either() -> void:
	# The rule holds for the worst deed in the game, which is the only place it
	# matters that it is a rule and not a special case for stealing.
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	Deeds.perform(sim, PlayerRules.DEED_KILLED_INNOCENT, &"cinderworks",
		empty_corner_of(&"cinderworks"))
	sim.advance(2)
	assert_eq(player.standing_in(&"cinderworks"), PlayerState.NEUTRAL,
		"a wood with nobody in it is where a murder costs nothing")


func test_no_deed_the_model_prices_costs_nothing() -> void:
	for deed: StringName in PlayerRules.priced_deeds():
		assert_ne(PlayerRules.standing_effect(deed), 0.0,
			"%s is in the model's table and has no number" % deed)


func test_the_old_acts_keep_their_numbers_until_c3_takes_them() -> void:
	# Dropping them to zero would quietly remove every way a town's opinion of you can
	# go up, which is the defect §8's Q38 was raised about. They fall through to the
	# old table and die with it.
	assert_eq(PlayerRules.standing_effect(DeedRules.DEED_WARNING),
		DeedRules.town_effect(DeedRules.DEED_WARNING),
		"warning a town is still worth what it was")
	assert_true(PlayerRules.standing_effect(DeedRules.DEED_WARNING) > 0.0,
		"and it is still the way up")


# ------------------------------------------------- what the court hears (J4) ---

## Written straight into the store rather than played to, because this is a reading
## and not a route: the arithmetic is what the two tests below are about.
func _standings(sim: Sim, by_town: Dictionary) -> PlayerState:
	var player := sim.store(&"player") as PlayerState
	for town: StringName in player.towns():
		player.standing[town] = float(by_town.get(town, PlayerState.NEUTRAL))
	return player


func test_hated_in_one_town_and_liked_in_four_arrives_at_court_well_regarded() -> void:
	# The numbers, written out. A murder in the works — the worst single deed in the
	# game — and four towns you have done right by.
	var player: PlayerState = _standings(Game.build(), {
		&"cinderworks": -80.0,
		&"harrowgate": 30.0, &"muster": 30.0, &"saltmarch": 30.0, &"wide_acres": 30.0,
	})
	assert_eq(PlayerRules.at_blackcairn(player), 8.0, "(-80 + 30 + 30 + 30 + 30) / 5")
	assert_true(PlayerRules.at_blackcairn(player) > PlayerState.NEUTRAL,
		"one terrible town is survivable")
	assert_eq(StandingRules.word_for(PlayerRules.at_blackcairn(player)), &"welcome",
		"the court is glad to see you")


func test_mildly_disliked_everywhere_arrives_worse_than_loathed_in_one_place() -> void:
	# The counter-intuitive one, and the reason J4's check asks for both written out.
	# One theft in each of the five towns — the smallest deed in the game, five times —
	# and the court thinks less of you than it does of a murderer with four friends.
	var mild: PlayerState = _standings(Game.build(), {
		&"cinderworks": -10.0, &"harrowgate": -10.0, &"muster": -10.0,
		&"saltmarch": -10.0, &"wide_acres": -10.0,
	})
	var loathed: PlayerState = _standings(Game.build(), {
		&"cinderworks": -80.0,
		&"harrowgate": 30.0, &"muster": 30.0, &"saltmarch": 30.0, &"wide_acres": 30.0,
	})
	assert_eq(PlayerRules.at_blackcairn(mild), -10.0, "(-10 x 5) / 5")
	assert_eq(PlayerRules.at_blackcairn(loathed), 8.0, "against +8 for the murderer")
	assert_true(PlayerRules.at_blackcairn(mild) < PlayerRules.at_blackcairn(loathed),
		"consistency matters more than any single act")
	assert_eq(StandingRules.word_for(PlayerRules.at_blackcairn(mild)), &"wary",
		"and the court has heard about you")


func test_the_towns_never_visited_pull_it_toward_zero() -> void:
	# The half of §4 that is easy to leave out. The four towns the player has never
	# been to sit at neutral and are counted, so one ruined reputation is diluted.
	var player: PlayerState = _standings(Game.build(), {&"cinderworks": -80.0})
	assert_eq(PlayerRules.at_blackcairn(player), -16.0, "-80 / 5, and not -80")
	assert_eq(StandingRules.word_for(PlayerRules.at_blackcairn(player)), &"wary",
		"hated in the works, merely talked about at court")


func test_a_player_nobody_has_heard_of_arrives_at_neutral() -> void:
	var player := Game.build().store(&"player") as PlayerState
	assert_eq(PlayerRules.at_blackcairn(player), PlayerState.NEUTRAL,
		"five towns at neutral average to neutral")


# ----------------------------------------- what standing does, and all it does ---

func _greeting(sim: Sim, who: StringName) -> String:
	var world := sim.store(&"world") as WorldState
	world.player_pos = _beside(sim, who)
	sim.submit(&"talk", {"npc": String(who)})
	sim.advance(2)
	var line: String = world.current_line
	sim.submit(&"end_talk")
	sim.advance(2)
	return line


func test_the_greeting_fires_on_the_town_and_not_on_the_person() -> void:
	# J5, and the whole of what standing does in v1 (§5): **it changes what people say
	# to you.** Both halves are asserted here, because only the pair of them says the
	# reading moved rather than merely still working.
	var town: Sim = Game.build()
	var plain: String = _greeting(town, &"maddox")
	(town.store(&"player") as PlayerState).standing[&"harrowgate"] = StandingRules.UNWELCOME - 1.0
	assert_ne(_greeting(town, &"maddox"), plain,
		"Harrowgate has turned on you and Maddox does not greet you as a stranger")

	var person: Sim = Game.build()
	assert_eq(_greeting(person, &"maddox"), plain, "the same world, the same hello")
	(person.store(&"standing") as Standing).shift_person(&"maddox", StandingRules.HATED - 1.0)
	assert_eq(_greeting(person, &"maddox"), plain,
		"and what one man privately thinks of you no longer changes a word of it")


func test_a_town_that_has_had_enough_of_you_still_holds_a_conversation() -> void:
	# §5's explicit *not* list: no hostile towns, no closed doors. A watch does not
	# attack on sight at any standing, and the worst a place can do is talk to you
	# coldly — which keeps the demo from punishing a player who experiments.
	var sim: Sim = Game.build()
	(sim.store(&"player") as PlayerState).standing[&"harrowgate"] = PlayerState.WORST
	var world := sim.store(&"world") as WorldState
	world.player_pos = _beside(sim, &"maddox")
	sim.submit(&"talk", {"npc": "maddox"})
	sim.advance(2)
	assert_true(world.in_dialogue(), "he is standing there talking to you")
	assert_ne(world.current_line, "", "and he said something")


func test_the_kingdoms_two_places_hear_the_mean() -> void:
	# Cairnwell and Blackcairn carry no standing of their own — together they are the
	# kingdom (M1) — so the reading a conversation takes there is J4's mean.
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	for town: StringName in player.towns():
		player.standing[town] = -30.0
	assert_eq(PlayerRules.regard_in(player, &"cairnwell"), -30.0, "the capital hears it")
	assert_eq(PlayerRules.regard_in(player, &"blackcairn"), -30.0, "and so does the castle")
	assert_eq(PlayerRules.regard_in(player, &"brindle"), PlayerState.NEUTRAL,
		"and a ruin with nobody in it has no opinion either way")


# ------------------------------------------------------------------- the log ---

func test_nothing_writes_a_standing_except_a_deed_in_the_log() -> void:
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	_at(sim, at_a_stall(&"harrowgate"))
	sim.submit(&"steal")
	sim.advance(2)
	var moved: Dictionary = {}
	for event: SimEvent in sim.events.all():
		if event.type == &"standing_moved":
			moved = event.data
	assert_false(moved.is_empty(), "the world said what it did")
	assert_eq(String(moved.get("town", "")), "harrowgate", "and where")
	assert_eq(String(moved.get("about", "")), String(DeedRules.DEED_THEFT), "and why")
	assert_eq(float(moved.get("to", 0.0)), player.standing_in(&"harrowgate"),
		"and the event carries the number the store now holds")
	# That a run rebuilds the same standing from its log alone is proved in
	# `test_journeys`, where the walk to the stall is in the log too. A test that
	# puts the player somewhere by writing `player_pos` has already stepped outside
	# the log and cannot prove anything about replay.
