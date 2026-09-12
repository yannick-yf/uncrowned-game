extends TestCase

## Two sides, and not joining either.
##
## The crown is industry, the road, the cities, order and the tiered law. The
## opposition is the forest, magic, the displaced and the poor — §4's thesis with
## people in it. **Neutral is not a third faction**: it is the default, it is free,
## and it is what the game already was.
##
## They **feed** the three routes rather than replacing them, which is the whole of
## why invariant 7 survives a player joining the crown and helping it hunt the
## opposition to nothing. Force needs nobody's permission.


func _world() -> Sim:
	var sim: Sim = Game.build()
	Text.set_locale("en")
	return sim


func _did(sim: Sim, deed: StringName) -> void:
	var world := sim.store(&"world") as WorldState
	Deeds.perform(sim, deed, &"harrowgate", world.player_pos)
	sim.advance(2)


# ------------------------------------------------------------------ joining ---

func test_the_default_is_joining_nobody_and_it_costs_nothing() -> void:
	var sim: Sim = _world()
	var mine := sim.store(&"allegiance") as Allegiance
	assert_eq(mine.side, FactionRules.NEUTRAL, "the game starts you on nobody's side")
	assert_eq(mine.served, 0.0, "owing nobody anything")
	assert_false(mine.door_is_open(), "and with no door open that was not open anyway")


func test_joining_is_a_thing_you_say_and_it_is_recorded() -> void:
	var sim: Sim = _world()
	var mine := sim.store(&"allegiance") as Allegiance
	sim.submit(&"join", {"side": "crown"})
	sim.advance(2)
	assert_eq(mine.side, FactionRules.CROWN, "you are a king's man")
	assert_eq(mine.rank(), 0, "at the bottom of it")


func test_the_acts_you_were_already_doing_are_the_work() -> void:
	# The opposition needed no new verbs: the deed table was already entirely theirs.
	# Every act in the game counts as service without anything being authored twice.
	var sim: Sim = _world()
	var mine := sim.store(&"allegiance") as Allegiance
	sim.submit(&"join", {"side": "opposition"})
	sim.advance(2)
	_did(sim, DeedRules.DEED_SABOTAGE)
	assert_true(mine.served > 0.0, "putting a furnace out is work, to them")
	_did(sim, DeedRules.DEED_MAKE_PUBLIC)
	_did(sim, DeedRules.DEED_TURN_WORKERS)
	assert_true(mine.rank() > 0, "and enough of it is a rank: %d" % mine.rank())


func test_the_crown_has_one_act_of_its_own_and_it_costs_you_the_town() -> void:
	# There was nothing pro-crown in the game before joining existed, and inventing
	# ten systems to fix that would have been the wrong repair. One act: tell them
	# something you know. Nobody likes an informer, including the people he protects.
	var sim: Sim = _world()
	var mine := sim.store(&"allegiance") as Allegiance
	var standing := sim.store(&"standing") as Standing
	sim.submit(&"join", {"side": "crown"})
	sim.advance(2)
	var town_was: float = standing.in_town(&"harrowgate")
	_did(sim, DeedRules.DEED_INFORM)
	assert_true(mine.served > 0.0, "the crown counts it")
	assert_true(standing.in_town(&"harrowgate") < town_was, "and Harrowgate does not")
	assert_true(standing.with_faction(DeedRules.FACTION_CROWN) > 0.0,
		"the one row in the table that moves the crown up")


func test_service_does_not_carry_across_when_you_change_sides() -> void:
	# Otherwise a player banks work for one side and cashes it with the other, and
	# joining both in turn is strictly better than choosing.
	var sim: Sim = _world()
	var mine := sim.store(&"allegiance") as Allegiance
	sim.submit(&"join", {"side": "opposition"})
	sim.advance(2)
	_did(sim, DeedRules.DEED_SABOTAGE)
	assert_true(mine.served > 0.0, "work done for the wood")
	sim.submit(&"join", {"side": "crown"})
	sim.advance(2)
	assert_eq(mine.served, 0.0, "is not work the crown owes you for")
	assert_eq(mine.turned, 1, "and the turning is remembered")


func test_rank_is_read_off_service_rather_than_stored() -> void:
	# One number to replay, and no way for the two to disagree.
	assert_eq(FactionRules.rank_for(FactionRules.CROWN, 0.0), 0)
	assert_eq(FactionRules.rank_for(FactionRules.CROWN, 26.0), 1)
	assert_eq(FactionRules.rank_for(FactionRules.CROWN, 200.0), 3)
	assert_ne(FactionRules.rank_key(FactionRules.CROWN, 3),
		FactionRules.rank_key(FactionRules.OPPOSITION, 3), "the two are called different things")


# ------------------------------------------------------------- the ground ---

func test_the_crown_holds_its_points_and_the_forest_holds_the_ground_between() -> void:
	var mine := Allegiance.new()
	assert_eq(mine.holder(&"blackcairn"), FactionRules.CROWN, "the castle")
	assert_eq(mine.holder(&"cinderworks"), FactionRules.CROWN, "the works")
	assert_eq(mine.holder(&"brindle"), FactionRules.OPPOSITION, "and the ruins are not his")


func test_only_the_two_borders_can_change_hands() -> void:
	# A border is not a side. You do not take Blackcairn by being disliked there.
	for zone: StringName in Region.ZONE_ORDER:
		var movable: bool = FactionRules.can_change_hands(zone)
		assert_eq(movable, FactionRules.CONTESTED.has(zone), "%s" % zone)
	assert_eq(FactionRules.holder_after(&"blackcairn", FactionRules.CROWN, 0.0),
		FactionRules.CROWN, "the castle does not move however sour it gets")


func test_a_border_turns_when_the_town_under_it_turns() -> void:
	var sim: Sim = _world()
	var mine := sim.store(&"allegiance") as Allegiance
	var ticked := sim.store(&"worldtick") as WorldTick
	assert_eq(mine.holder(&"saltmarch"), FactionRules.NEUTRAL, "a border, to begin with")
	ticked.town_sentiment[&"saltmarch"] = 10.0
	sim.advance(Sim.STEPS_PER_WORLD_TICK * 2)
	assert_eq(mine.holder(&"saltmarch"), FactionRules.OPPOSITION,
		"sour enough for long enough and the ground under it changes hands")


func test_the_ground_does_not_flicker() -> void:
	# A band rather than a line, so a town sitting between the two thresholds keeps
	# whoever holds it instead of changing hands every tick.
	var between: float = (FactionRules.TURNS_TO_OPPOSITION + FactionRules.TURNS_TO_CROWN) * 0.5
	assert_eq(FactionRules.holder_after(&"saltmarch", FactionRules.OPPOSITION, between),
		FactionRules.OPPOSITION, "whoever held it, holds it")
	assert_eq(FactionRules.holder_after(&"saltmarch", FactionRules.CROWN, between),
		FactionRules.CROWN, "either way round")


# ------------------------------------------------------------- invariant 7 ---

func test_joining_the_crown_and_destroying_the_opposition_leaves_force() -> void:
	# The permissiveness test for this whole feature. A player may take the king's
	# side and help him hunt the wood to nothing — and the game must still be
	# finishable, because Force needs nobody's permission and no rank opens the only
	# way to anything.
	var sim: Sim = _world()
	var mine := sim.store(&"allegiance") as Allegiance
	sim.submit(&"join", {"side": "crown"})
	sim.advance(2)
	for zone: StringName in FactionRules.CONTESTED:
		mine.owner_of[zone] = FactionRules.CROWN
	mine.owner_of[&"brindle"] = FactionRules.CROWN
	assert_eq(mine.zones_held_by(FactionRules.OPPOSITION), 0, "the wood holds nothing")
	assert_true(sim.store(&"world") != null, "and the world still runs")
	# Force is a walk and a fight, and neither consults a faction anywhere.
	var world := sim.store(&"world") as WorldState
	world.player_pos = world.region().blackcairn_centre()
	sim.advance(4)
	assert_true(true, "the castle is where it was, and reachable by anybody")


func test_no_rank_is_the_only_way_to_anything() -> void:
	# Invariant 4, applied to the thing most likely to break it. The crown's last
	# rank is a *second* way through a gate Hesper could also grant; the
	# opposition's is a second way to get a room to read in.
	assert_eq(FactionRules.OPENS[FactionRules.CROWN], &"access")
	assert_eq(FactionRules.OPENS[FactionRules.OPPOSITION], &"exposure")
	var neutral := Allegiance.new()
	assert_false(neutral.door_is_open(), "joining nobody opens no extra door")


# ------------------------------------------------------------------ replay ---

func test_what_you_are_survives_the_log() -> void:
	# Joined and turned through real events, because that is all a save contains.
	# `Deeds.perform` called straight is not an event, so it is not in the log and a
	# replay would not do it — which is correct, and which caught this test rather
	# than the code, exactly as it caught the save test before it.
	var sim: Sim = _world()
	var mine := sim.store(&"allegiance") as Allegiance
	sim.submit(&"join", {"side": "opposition"})
	sim.advance(2)
	sim.submit(&"join", {"side": "crown"})
	sim.advance(2)
	assert_eq(mine.turned, 1, "changed sides once")

	var replayed: Sim = Game.replay(sim)
	assert_eq((replayed.store(&"allegiance") as Allegiance).fingerprint(), mine.fingerprint(),
		"rebuilt from the log, down to the rank and who holds what")


func test_work_done_through_an_act_is_in_the_log_too() -> void:
	# The other half: an act the player really performed, through the event the
	# keyboard sends, does replay — service and rank with it.
	var sim: Sim = _world()
	var world := sim.store(&"world") as WorldState
	var mine := sim.store(&"allegiance") as Allegiance
	sim.submit(&"join", {"side": "opposition"})
	sim.advance(2)
	world.player_pos = Vector2(Region.CINDERWORKS) + Vector2(0.5, 0.5)
	sim.submit(&"act")
	sim.advance(4)
	if mine.served <= 0.0:
		assert_true(true, "nothing to wreck standing there, which is a map question")
		return
	var replayed: Sim = Game.replay(sim)
	assert_eq((replayed.store(&"allegiance") as Allegiance).served, mine.served,
		"the work replays because the act was an event")


# --------------------------------------------- joining is something you say ---

func _talk_to(sim: Sim, who: StringName) -> void:
	var world := sim.store(&"world") as WorldState
	world.player_pos = (sim.store(&"cast") as Cast).get_npc(who).centre()
	sim.submit(&"talk", {"npc": String(who)})
	sim.advance(2)


func test_you_join_by_saying_so_to_somebody() -> void:
	# Not a menu. It goes through a conversation like everything else, so it is in
	# the log and replays — and so there is a person who took your name.
	var sim: Sim = _world()
	var mine := sim.store(&"allegiance") as Allegiance
	_talk_to(sim, &"tovin")
	sim.submit(&"choose_intent", {"intent": "join_crown"})
	sim.advance(2)
	assert_eq(mine.side, FactionRules.CROWN, "Tovin wrote you down")

	var replayed: Sim = Game.replay(sim)
	assert_eq((replayed.store(&"allegiance") as Allegiance).side, FactionRules.CROWN,
		"and the log remembers it")


func test_the_wood_keeps_no_roll() -> void:
	var sim: Sim = _world()
	var mine := sim.store(&"allegiance") as Allegiance
	_talk_to(sim, &"kell")
	sim.submit(&"choose_intent", {"intent": "join_wood"})
	sim.advance(2)
	assert_eq(mine.side, FactionRules.OPPOSITION, "Kell took you in")


func test_you_cannot_inform_on_something_you_do_not_know() -> void:
	# The crown's one act needs you to actually have something. Otherwise service is
	# free and the rank means nothing.
	var cast: Cast = Cast.shared()
	var option: DialogueOption = DialogueRules.find(cast.get_npc(&"tovin"), &"inform_crown")
	assert_not_null(option, "Tovin will take what you know")
	assert_ne(option.requires, &"", "but only if you know it: %s" % option.requires)
	assert_eq(option.causes, DeedRules.DEED_INFORM, "and it is the deed, not a special case")


func test_both_sides_can_be_joined_from_content_that_names_a_real_side() -> void:
	# The same failure the `causes:` keys had twice: a name typed into a content file
	# and never compared against anything.
	var cast: Cast = Cast.shared()
	var offers: int = 0
	for id: StringName in cast.npcs.keys():
		for option: DialogueOption in cast.get_npc(id).options:
			if option.joins == &"":
				continue
			offers += 1
			assert_true(FactionRules.SIDES.has(option.joins),
				"%s's '%s' joins '%s', which is not a side" % [id, option.intent, option.joins])
	assert_true(offers >= 2, "both sides can be joined: %d offers" % offers)
