extends TestCase

## Phase 3, stage 4: the acts that raise a town.
##
## §8, answering Q38. Reputation was one-way — every act subtracted, the `welcome`
## band was unreachable, and a system where subtraction is free and addition is
## gated teaches the player to stand still. The answer is giving away what you
## know: warn a town of what is coming, and, smaller, put back what you took.
##
## Both are the mirror of theft rather than a balancing mechanic wearing its coat:
## a deed, the people near enough to witness it, a story that may travel, and
## standing that moves as it arrives.



func _deed_sim(cast: Cast = Cast.shared()) -> Sim:
	var sim := Sim.new()
	sim.add_store(&"world", Game.build_world())
	sim.add_store(&"cast", cast)
	sim.add_store(&"worldtick", WorldTick.new())
	sim.add_store(&"standing", Standing.new())
	sim.add_store(&"rumours", Rumours.new())
	sim.add_system(ArmySystem.new())
	sim.add_system(WorldTickSystem.new())
	sim.add_system(GrainSystem.new())
	sim.add_system(DialogueSystem.new())
	sim.add_system(TellingSystem.new())
	sim.add_system(TheftSystem.new())
	sim.add_system(RumourSystem.new())
	# What the player would have learned from Odile. Every test here starts from
	# the moment after the fact was found, because finding it is Phase 1's proof.
	sim.facts.add_source(ArmyRules.FACT_PAY_FRAUD, &"odile")
	return sim


func _act(sim: Sim, where: Vector2, event: StringName) -> void:
	var world := sim.store(&"world") as WorldState
	world.player_pos = where
	sim.submit(event)
	sim.advance(2)


func _days(sim: Sim, count: float) -> void:
	sim.advance_world_ticks(int(float(Game.TICKS_PER_IN_GAME_DAY) * count))


# ------------------------------------------------------------- the hard rule ---

func test_every_deed_names_who_is_offended_and_who_is_impressed() -> void:
	# §8's counterpart rule, as a test rather than a habit. A deed with no
	# counterpart is not finished, and the only way that stays true as verbs are
	# added is if adding one to the table fails this.
	for deed: StringName in DeedRules.all_deeds():
		var factions: Dictionary = DeedRules.faction_effects(deed)
		assert_true(absf(DeedRules.town_effect(deed)) > 0.0,
			"%s does nothing to the town that sees it" % deed)
		var up: int = 0
		var down: int = 0
		for faction: StringName in factions.keys():
			if float(factions[faction]) > 0.0:
				up += 1
			elif float(factions[faction]) < 0.0:
				down += 1
		assert_true(up > 0, "%s impresses nobody — every door that shuts opens another" % deed)
		assert_true(down > 0, "%s offends nobody, which makes it free" % deed)


func test_the_positive_act_is_not_smaller_than_the_negative_one() -> void:
	# Deliberate, and the whole reason Q38 was a defect rather than a gap. If
	# addition is both gated *and* smaller, standing still is the optimal play.
	assert_true(DeedRules.town_effect(DeedRules.DEED_WARNING)
			> absf(DeedRules.town_effect(DeedRules.DEED_THEFT)),
		"warning a town is worth more than stealing from it costs")


# --------------------------------------------------------------- the warning ---

func test_you_cannot_tell_an_empty_street_anything() -> void:
	# The one way a warning is unlike a theft. You can rob a deserted market; you
	# cannot warn one, because the witnesses *are* the audience.
	var sim: Sim = _deed_sim()
	var world := sim.store(&"world") as WorldState
	var standing := sim.store(&"standing") as Standing
	var cast := sim.store(&"cast") as Cast
	assert_true(world.region().zone_at(Vector2i(empty_corner_of(&"harrowgate"))) == &"harrowgate",
		"the spot is inside the town, so only the audience rule can refuse it")
	assert_eq(CrimeRules.witnesses_to(
		cast, WorldState.OVERWORLD, empty_corner_of(&"harrowgate")).size(), 0,
		"and there is nobody standing in it")

	_act(sim, empty_corner_of(&"harrowgate"), &"tell_town")
	assert_eq(world.fraud_told_to, &"", "nothing was told, so nothing was spent")
	assert_eq(standing.in_town(&"harrowgate"), Standing.NEUTRAL, "and nobody's opinion moved")

	# The control: the same act, the same town, six tiles away where Maddox is.
	_act(sim, in_town(&"harrowgate"), &"tell_town")
	assert_eq(world.fraud_told_to, &"harrowgate", "with an audience, it lands")


func test_the_countryside_is_not_a_town() -> void:
	var sim: Sim = _deed_sim()
	var world := sim.store(&"world") as WorldState
	_act(sim, alone_on_the_road(), &"tell_town")
	assert_eq(world.fraud_told_to, &"", "there is nobody on the King's Road to tell")


func test_warning_harrowgate_makes_you_welcome_there() -> void:
	var sim: Sim = _deed_sim()
	var standing := sim.store(&"standing") as Standing
	_act(sim, in_town(&"harrowgate"), &"tell_town")
	assert_eq(StandingRules.word_for(standing.in_town(&"harrowgate")), &"welcome",
		"the band Q38 said was unreachable: %.1f" % standing.in_town(&"harrowgate"))


func test_warning_a_town_is_sedition_somewhere_else() -> void:
	var sim: Sim = _deed_sim()
	var standing := sim.store(&"standing") as Standing
	_act(sim, in_town(&"harrowgate"), &"tell_town")
	assert_true(standing.with_faction(DeedRules.FACTION_TOWNS) > 0.0,
		"the towns are glad to have been told")
	assert_true(standing.with_faction(DeedRules.FACTION_CROWN) < 0.0,
		"and the crown is not — telling a town the army is rotting is sedition")


func test_the_army_keeps_its_men() -> void:
	var sim: Sim = _deed_sim()
	var ticked := sim.store(&"worldtick") as WorldTick
	_act(sim, in_town(&"harrowgate"), &"tell_town")
	_days(sim, 5.0)
	assert_eq(ticked.army_strength, 100.0,
		"you spent the fraud on the town, so the Muster never heard it")


func test_word_of_the_warning_travels_like_any_other_story() -> void:
	var sim: Sim = _deed_sim()
	var standing := sim.store(&"standing") as Standing
	_act(sim, in_town(&"harrowgate"), &"tell_town")
	assert_eq(standing.in_town(&"muster"), Standing.NEUTRAL, "the camp has not heard yet")
	_days(sim, 3.0)
	assert_true(standing.in_town(&"muster") > 0.0,
		"and three days later it has: %.1f" % standing.in_town(&"muster"))


# ---------------------------------------------------------- the one telling ---

func test_the_fraud_can_be_told_once() -> void:
	var sim: Sim = _deed_sim()
	var world := sim.store(&"world") as WorldState
	var ticked := sim.store(&"worldtick") as WorldTick
	_act(sim, in_town(&"harrowgate"), &"tell_town")
	assert_eq(world.fraud_told_to, &"harrowgate", "spent, and on the town")

	# Walk to the camp and try to spend it again.
	_act(sim, Vector2(Region.MUSTER) + Vector2(0.5, 0.5), &"expose_fraud")
	assert_false(world.pay_fraud_exposed, "there is nothing left to expose")
	assert_eq(ticked.army_strength, 100.0, "and the army is untouched")


func test_exposing_at_the_muster_spends_it_too() -> void:
	var sim: Sim = _deed_sim()
	var world := sim.store(&"world") as WorldState
	var standing := sim.store(&"standing") as Standing
	_act(sim, Vector2(Region.MUSTER) + Vector2(0.5, 0.5), &"expose_fraud")
	assert_true(world.pay_fraud_exposed, "the men heard it")

	_act(sim, in_town(&"harrowgate"), &"tell_town")
	assert_eq(world.fraud_told_to, &"muster", "and there is no town left to warn")
	assert_eq(standing.in_town(&"harrowgate"), Standing.NEUTRAL, "so Harrowgate owes you nothing")


func test_the_knowing_is_never_spent_only_the_telling() -> void:
	# Route C needs the player to *know* this and put it in front of the king.
	# Invariants 6 and 7 are claims about reaching a fact, so nothing here may
	# remove one.
	var sim: Sim = _deed_sim()
	_act(sim, in_town(&"harrowgate"), &"tell_town")
	assert_true(sim.facts.has(ArmyRules.FACT_PAY_FRAUD),
		"the fact stays in the fact base forever")


func test_a_warned_town_takes_less_of_the_price() -> void:
	# Worth nothing on the day and a great deal on the day the camp empties, by
	# whatever hand. Phase 3 has only one lever and warning spends it, so this is
	# checked at the rules layer, where the relief is decided.
	var unwarned: float = WorldRules.grain_target_for(
		&"harrowgate", WorldRules.ARMY_AFTER_FRAUD, false)
	var warned: float = WorldRules.grain_target_for(
		&"harrowgate", WorldRules.ARMY_AFTER_FRAUD, true)
	assert_true(warned < unwarned, "stores laid in: %.1f against %.1f" % [warned, unwarned])
	assert_true(warned > WorldTick.NEUTRAL,
		"but the price still rises — a warning is preparation, not a harvest")


# -------------------------------------------------------- what people think ---

func _talk_to(sim: Sim, who: StringName) -> Array[String]:
	var world := sim.store(&"world") as WorldState
	world.player_pos = Vector2((sim.store(&"cast") as Cast).get_npc(who).centre())
	sim.submit(&"talk", {"npc": String(who)})
	sim.advance(2)
	var out: Array[String] = []
	for option: DialogueOption in world.options:
		out.append(String(option.intent))
	return out


func test_a_witness_thinks_worse_of_you_than_the_neighbours_who_heard() -> void:
	# Maddox is two tiles from the stall and watched it. Ossa is ten tiles away
	# and gets it the way everyone else does — as the story, once it is a story.
	var sim: Sim = _deed_sim()
	var cast := sim.store(&"cast") as Cast
	var standing := sim.store(&"standing") as Standing
	assert_true(CrimeRules.witnesses_to(cast, WorldState.OVERWORLD, at_a_stall()).has("maddox"),
		"Maddox saw it")
	assert_false(CrimeRules.witnesses_to(cast, WorldState.OVERWORLD, at_a_stall()).has("ossa"),
		"and Ossa, ten tiles off, did not")

	_act(sim, at_a_stall(), &"steal")
	assert_true(standing.with_person(&"maddox") < standing.with_person(&"ossa"),
		"seeing it is worse than hearing it: maddox %.1f, ossa %.1f"
			% [standing.with_person(&"maddox"), standing.with_person(&"ossa")])
	assert_true(standing.with_person(&"ossa") < 0.0,
		"but the whole town heard, so she thinks less of you too")


func test_nobody_is_counted_against_you_twice_for_one_deed() -> void:
	# Maddox is both a witness and a resident. He must not take the witness hit
	# and the town's hit for the same theft.
	var sim: Sim = _deed_sim()
	var standing := sim.store(&"standing") as Standing
	_act(sim, at_a_stall(), &"steal")
	assert_eq(standing.with_person(&"maddox"), DeedRules.witness_effect(DeedRules.DEED_THEFT),
		"exactly what one pair of eyes is worth, and not that plus the hearsay")


func test_ossa_stops_telling_you_things() -> void:
	# The door that shuts, at the level of one person. She still treats whoever
	# bleeds — that is who she is — but you get nothing else from her.
	var sim: Sim = _deed_sim()
	var before: Array[String] = _talk_to(sim, &"ossa")
	assert_true(before.has("ask_why"), "she will tell a stranger why the men run")
	assert_true(before.has("ask_kell"), "and hint at the one she remembers")

	_act(sim, at_a_stall(), &"steal")
	var after: Array[String] = _talk_to(sim, &"ossa")
	assert_false(after.has("ask_why"), "not any more")
	assert_false(after.has("ask_kell"), "nor that")
	assert_true(after.has("ask_deserters"), "but she is still standing there talking to you")


func test_what_ossa_knows_is_still_reachable() -> void:
	# Invariant 7, at the level of a conversation rather than a death. Closing a
	# source is the design working; closing the last one is a bug.
	var sim: Sim = _deed_sim()
	_act(sim, at_a_stall(), &"steal")
	var garrick: Array[String] = _talk_to(sim, &"garrick")
	assert_true(garrick.has("ask_muster"),
		"Garrick teaches the same fact and nothing gates him")


func test_giving_it_back_in_front_of_them_is_forgiven() -> void:
	var sim: Sim = _deed_sim()
	var standing := sim.store(&"standing") as Standing
	_act(sim, at_a_stall(), &"steal")
	var after_the_theft: float = standing.with_person(&"maddox")
	_act(sim, at_a_stall(), &"give_back")
	assert_true(standing.with_person(&"maddox") > after_the_theft,
		"Maddox watched you put it back")
	assert_false(StandingRules.is_unwelcome(standing.with_person(&"maddox")),
		"and having watched both, he is done with it: %.1f" % standing.with_person(&"maddox"))


# ----------------------------------------------------------- giving it back ---

func test_you_can_only_put_it_back_where_you_took_it() -> void:
	var sim: Sim = _deed_sim()
	var world := sim.store(&"world") as WorldState
	assert_false(world.can_give_back(Vector2i(at_a_stall())), "you are carrying nothing")
	_act(sim, at_a_stall(), &"steal")
	assert_eq(world.carrying_stolen, 1, "and now you are carrying something")
	assert_true(world.can_give_back(world.stolen_from), "the stall you took it from")
	assert_false(world.can_give_back(Region.HARROWGATE + Vector2i(4, -3)),
		"and not the one along the row")


func test_giving_it_back_repairs_the_place() -> void:
	var sim: Sim = _deed_sim()
	var world := sim.store(&"world") as WorldState
	var standing := sim.store(&"standing") as Standing
	_act(sim, at_a_stall(), &"steal")
	var after_the_theft: float = standing.in_town(&"harrowgate")
	_act(sim, at_a_stall(), &"give_back")

	assert_eq(world.carrying_stolen, 0, "your hands are empty")
	assert_true(standing.in_town(&"harrowgate") > after_the_theft,
		"Harrowgate thinks better of you than it did")
	assert_true(standing.in_town(&"harrowgate") < Standing.NEUTRAL,
		"but not as well as before you took it — the town remembers")


func test_giving_it_back_costs_more_than_taking_it_gained() -> void:
	var sim: Sim = _deed_sim()
	var standing := sim.store(&"standing") as Standing
	_act(sim, at_a_stall(), &"steal")
	_act(sim, at_a_stall(), &"give_back")
	assert_true(standing.with_faction(DeedRules.FACTION_UNDERWORLD) < 0.0,
		"a thief who gives things back is no use to anybody: %.1f"
			% standing.with_faction(DeedRules.FACTION_UNDERWORLD))


func test_giving_it_back_cannot_catch_the_story() -> void:
	# The lesson the act exists to teach. You can repair the place; the story
	# already walking toward the next town keeps walking.
	var sim: Sim = _deed_sim()
	var standing := sim.store(&"standing") as Standing
	_act(sim, at_a_stall(), &"steal")
	_act(sim, at_a_stall(), &"give_back")
	_days(sim, 3.0)
	# The next town is the nearest other one on the map — the Wide Acres on the 2D map,
	# the camp on the baked world — because a story walks to whoever is closest.
	var next_town: StringName = &""
	var nearest: float = 1.0e9
	for zone: StringName in Region.ZONE_ORDER:
		if zone == &"harrowgate" or zone == &"brindle":
			continue
		var away: float = Vector2(Region.zone_sites()[zone] as Vector2i).distance_to(Vector2(Region.HARROWGATE))
		if away < nearest:
			nearest = away
			next_town = zone
	assert_true(StandingRules.is_unwelcome(standing.in_town(next_town)),
		"the next town, %s, heard that you stole and will never hear that you gave it back" % next_town)


func test_the_stall_has_something_on_it_again() -> void:
	var sim: Sim = _deed_sim()
	var world := sim.store(&"world") as WorldState
	_act(sim, at_a_stall(), &"steal")
	var stall: Vector2i = world.stolen_from
	assert_true(world.stall_is_bare(stall, sim.tick), "you took what was on it")
	_act(sim, at_a_stall(), &"give_back")
	assert_false(world.stall_is_bare(stall, sim.tick), "and put it back on the counter")
