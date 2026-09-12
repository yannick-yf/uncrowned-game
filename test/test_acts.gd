extends TestCase

## Phase 5, step 3: the ten inert quantities get inputs.
##
## Measured before this existed: two of the twelve tracked quantities were ever
## touched by a system, and dialogue was the only input to the only one that
## mattered. That is why the game had begun to feel like matching people to states —
## **there was no other way in.** §3 lists how each power base can be weakened and
## every one of those levers is an act at a landmark, not a conversation.


## Lean: wildlife and travellers cost steps and move none of the numbers an act
## touches. Through the full build these ran in seventeen seconds; through this, two.
func _world() -> Sim:
	var sim := Sim.new()
	sim.add_store(&"world", Game.build_world())
	sim.add_store(&"cast", Cast.shared())
	sim.add_store(&"worldtick", WorldTick.new())
	sim.add_store(&"standing", Standing.new())
	sim.add_store(&"rumours", Rumours.new())
	sim.add_system(WorldTickSystem.new())
	sim.add_system(GrainSystem.new())
	sim.add_system(UnrestSystem.new())
	sim.add_system(ActSystem.new())
	sim.add_system(TheftSystem.new())
	sim.add_system(RumourSystem.new())
	sim.add_system(EndingSystem.new())
	return sim


func _sites_of(sim: Sim, kind: StringName) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for prop: Dictionary in (sim.store(&"world") as WorldState).region().props:
		if (prop["kind"] as StringName) == kind:
			out.append(prop["at"] as Vector2i)
	return out


func _act_at(sim: Sim, at: Vector2i) -> void:
	(sim.store(&"world") as WorldState).player_pos = Vector2(at) + Vector2(1.5, 2.0)
	sim.submit(&"act")
	sim.advance(3)


func _days(sim: Sim, count: float) -> void:
	sim.advance_world_ticks(int(float(Game.TICKS_PER_IN_GAME_DAY) * count))


# ------------------------------------------------------------- the levers ---

func test_every_power_base_that_has_a_place_has_a_lever() -> void:
	# Five of §3's six. Greyhold is not on the map at all — §4's eight zones do not
	# include it — which is recorded rather than quietly skipped (§19).
	var sim: Sim = _world()
	for kind: StringName in [&"kiln", &"granary", &"counting_house", &"muster_rolls"]:
		assert_true(_sites_of(sim, kind).size() > 0, "nowhere to do anything to a %s" % kind)
		assert_true(SiteRules.deed_at(kind) != &"", "%s offers no act" % kind)
		assert_true(Text.has(SiteRules.label_key(kind)),
			"%s has nothing the prompt can say in the player's language" % kind)


func test_an_act_moves_the_world_and_records_whose_doing_it_was() -> void:
	var sim: Sim = _world()
	var ticked := sim.store(&"worldtick") as WorldTick
	assert_eq(ticked.steel_output, WorldTick.BASELINE, "the furnaces are lit")

	_act_at(sim, _sites_of(sim, &"kiln")[0])
	assert_true(ticked.steel_output < WorldTick.BASELINE, "and now one of them is not")
	assert_true(ticked.handprint_on(&"steel_output") > 0.0,
		"with the player's hand on it, or no ending will ever count it")


func test_a_wrecked_site_stays_wrecked() -> void:
	# Not a cooldown. A cold furnace is cold, and the count of them is what caps
	# how far steel output can be driven by hand.
	var sim: Sim = _world()
	var ticked := sim.store(&"worldtick") as WorldTick
	var kiln: Vector2i = _sites_of(sim, &"kiln")[0]
	_act_at(sim, kiln)
	var after_one: float = ticked.steel_output
	_act_at(sim, kiln)
	_act_at(sim, kiln)
	assert_eq(ticked.steel_output, after_one, "you cannot put the same furnace out three times")


func test_an_act_nobody_sees_still_breaks_the_thing() -> void:
	# The asymmetry that matters: a deed needs a witness to become a *story*, and
	# needs nobody at all to have happened. The world does not require an audience
	# to have been broken.
	#
	# Every power base is watched now, so the empty cast is the honest way to test
	# it — the same shape as the unwitnessed theft.
	var sim: Sim = _world()
	sim.add_store(&"cast", Cast.new())
	var ticked := sim.store(&"worldtick") as WorldTick
	var rumours := sim.store(&"rumours") as Rumours
	_act_at(sim, _sites_of(sim, &"granary")[0])
	assert_true(ticked.crown_treasury < WorldTick.BASELINE, "the stores burned")
	assert_eq(rumours.told, 0, "and nobody was there to say so")


func test_every_power_base_is_watched() -> void:
	# The defect this pass exists to fix. Eight of the ten levers stood in places
	# with no cast at all, so wrecking a furnace or burning a winter's stores cost
	# precisely nothing: no witness, no story, no standing, no watch woken.
	var sim: Sim = _world()
	var cast := sim.store(&"cast") as Cast
	for prop: Dictionary in (sim.store(&"world") as WorldState).region().props:
		if not SiteRules.is_site(prop["kind"] as StringName):
			continue
		var at: Vector2 = Vector2(prop["at"] as Vector2i) + Vector2(1.5, 2.0)
		assert_true(CrimeRules.witnesses_to(cast, WorldState.OVERWORLD, at).size() > 0,
			"%s at %s can be done for free" % [prop["kind"], prop["at"]])


func test_a_roused_watch_stands_over_what_it_guards() -> void:
	# §8's fifth quantity was an input with no output. This is what reads it: the
	# more the watch has heard about lately, the less you can work, and the way
	# past it is to let things go quiet rather than to fight anybody.
	var sim: Sim = _world()
	var ticked := sim.store(&"worldtick") as WorldTick
	var cast := sim.store(&"cast") as Cast
	var kiln: Vector2 = Vector2(_sites_of(sim, &"kiln")[0]) + Vector2(1.5, 2.0)

	assert_eq(WatchRules.guarded_by(cast, WorldState.OVERWORLD, kiln, WorldTick.NEUTRAL), &"",
		"on a quiet day they are there and not looking hard")
	assert_ne(WatchRules.guarded_by(cast, WorldState.OVERWORLD, kiln, 100.0), &"",
		"and once roused they are standing over it")
	assert_eq(ticked.alertness_in(&"cinderworks"), WorldTick.NEUTRAL,
		"and the watch is held per town — the Wide Acres has never heard of the works")


func test_you_cannot_work_at_a_post_somebody_is_watching() -> void:
	var sim: Sim = _world()
	var ticked := sim.store(&"worldtick") as WorldTick
	ticked.guard_alertness_by_town[&"cinderworks"] = 100.0
	var before: float = ticked.steel_output
	_act_at(sim, _sites_of(sim, &"kiln")[0])
	assert_eq(ticked.steel_output, before, "the furnace is still lit")
	assert_eq((sim.store(&"world") as WorldState).spent_sites.size(), 0,
		"and nothing was spent trying")


func test_an_act_is_not_undone_by_the_worlds_own_drift() -> void:
	# Found in play: the muster rolls came off the army strength and the world
	# quietly recruited the men back over the following week, which made the act
	# theatre. A quantity that eases toward a target needs the target moved too.
	var sim: Sim = _world()
	var ticked := sim.store(&"worldtick") as WorldTick
	_act_at(sim, _sites_of(sim, &"muster_rolls")[0])
	var straight_after: float = ticked.army_strength
	assert_true(straight_after < WorldTick.BASELINE, "the rolls are gone")
	_days(sim, 20.0)
	assert_true(ticked.army_strength <= straight_after + 0.01,
		"and three weeks later they are still gone: %.0f" % ticked.army_strength)


func test_every_deed_still_names_who_is_offended_and_who_is_impressed() -> void:
	# §8's counterpart rule, now over eight deeds rather than three. The table grew
	# by acts against power bases and the rule has to grow with it.
	for deed: StringName in DeedRules.all_deeds():
		var factions: Dictionary = DeedRules.faction_effects(deed)
		var up: int = 0
		var down: int = 0
		for faction: StringName in factions.keys():
			if float(factions[faction]) > 0.0:
				up += 1
			elif float(factions[faction]) < 0.0:
				down += 1
		assert_true(up > 0, "%s impresses nobody" % deed)
		assert_true(down > 0, "%s offends nobody, which makes it free" % deed)


func test_the_deed_carries_the_fall_and_the_drift_only_garnishes_it() -> void:
	# §8: ambient drift stays slow and small; player-caused change is large, fast
	# and local. Measured and found backwards — robbing the bank took 34 points off
	# confidence and the coupling carried the other 41, so most of a reign's fall
	# was the world doing it rather than the player.
	var sim: Sim = _world()
	var ticked := sim.store(&"worldtick") as WorldTick
	_act_at(sim, _sites_of(sim, &"counting_house")[0])
	var from_the_act: float = WorldTick.BASELINE - ticked.bank_confidence
	_days(sim, 14.0)
	var from_the_drift: float = WorldTick.BASELINE - from_the_act - ticked.bank_confidence
	assert_true(from_the_act > from_the_drift,
		"the robbery moved %.0f and the world moved %.0f — the act has to be the bigger half"
			% [from_the_act, from_the_drift])


# ----------------------------------------------------------- the couplings ---

func test_the_bank_loses_faith_in_a_sovereign_who_cannot_pay() -> void:
	# §8 says bank confidence drifts on the treasury and it never did. This is that
	# coupling, and the reason `ruined` is reachable by acts rather than by wishing.
	var sim: Sim = _world()
	var ticked := sim.store(&"worldtick") as WorldTick
	for at: Vector2i in _sites_of(sim, &"granary"):
		_act_at(sim, at)
	var before: float = ticked.bank_confidence
	_days(sim, 12.0)
	assert_true(ticked.bank_confidence < before,
		"confidence followed the treasury down: %.0f" % ticked.bank_confidence)
	assert_true(ticked.handprint_on(&"bank_confidence") > 0.0,
		"and the credit travelled with the cause — otherwise coupling launders the "
			+ "player's hand out of everything more than one step from the act")


func test_the_watch_thickens_after_a_crime_it_heard_about() -> void:
	# §19 Q7 settled: §10's "violence is never mechanically punished" means no karma
	# meter and no progression gate. Patrols thickening is the social punishment
	# §10 describes, and it is visible, diegetic and escapable.
	var sim: Sim = _world()
	var ticked := sim.store(&"worldtick") as WorldTick
	var world := sim.store(&"world") as WorldState
	var quiet: float = ticked.patrol_density
	world.player_pos = Vector2(147.5, 173.0)
	sim.submit(&"steal")
	sim.advance(4)
	assert_true(ticked.patrol_density > quiet, "somebody reported it")
	assert_true(ticked.alertness_in(&"harrowgate") > WorldTick.NEUTRAL,
		"and the watch is awake in Harrowgate")
	assert_eq(ticked.alertness_in(&"cairnwell"), WorldTick.NEUTRAL,
		"and nowhere else — the watch is a place's, not the kingdom's")


func test_the_watch_settles_again_when_nothing_happens() -> void:
	var sim: Sim = _world()
	var ticked := sim.store(&"worldtick") as WorldTick
	var world := sim.store(&"world") as WorldState
	world.player_pos = Vector2(147.5, 173.0)
	sim.submit(&"steal")
	sim.advance(4)
	var roused: float = ticked.alertness_in(&"harrowgate")
	assert_true(roused > WorldTick.NEUTRAL, "the watch woke where it happened")
	_days(sim, 4.0)
	assert_true(ticked.alertness_in(&"harrowgate") < roused, "and a quiet week settles them")
