extends TestCase

## Phase B — the second axis (§8, 2026-09-13).
##
## v1 could break the kingdom nine ways and build it none, and every deed's effect
## was negative. That is a missing *sign*, not a missing feature: the store was
## already signed. What the second direction needed before it needed acts was a
## reason neither end is correct — **hardship**, what an act costs the people who
## live somewhere, held per town beside the twelve — and a rule that every act that
## moves the kingdom names who it costs, with a face who can say so.
##
## These hold the rule, the number, and the proof §18 gives the phase: burn the
## stores and feed the works the forest in one run, and two towns are worse off in
## two different ways, and a named person in each says so without naming you.

const CROSSES_THE_LINE: String = "one act should carry a place from the ordinary 50 past the line"


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


## Spend every standing question this person has except the one wanted, so the cap
## of three cannot hide it. A player does the same by asking them.
func _exhaust_but(sim: Sim, who: StringName, keep: StringName) -> void:
	var npc: Npc = (sim.store(&"cast") as Cast).get_npc(who)
	for option: DialogueOption in npc.options:
		if option.intent != keep and option.requires_condition == &"":
			sim.facts.add_source(option.spent_by(npc.id), &"test")


func _say(sim: Sim, who: StringName, intent: StringName) -> void:
	var world := sim.store(&"world") as WorldState
	var npc: Npc = (sim.store(&"cast") as Cast).get_npc(who)
	world.player_pos = Vector2(npc.tile) + Vector2(0.5, 0.5)
	sim.submit(&"talk", {"npc": String(who)})
	sim.advance(2)
	sim.submit(&"choose_intent", {"intent": String(intent)})
	sim.advance(2)
	sim.submit(&"end_talk")
	sim.advance(1)


func _offered(sim: Sim, who: StringName) -> Array[String]:
	var world := sim.store(&"world") as WorldState
	var npc: Npc = (sim.store(&"cast") as Cast).get_npc(who)
	world.player_pos = Vector2(npc.tile) + Vector2(0.5, 0.5)
	sim.submit(&"talk", {"npc": String(who)})
	sim.advance(2)
	var out: Array[String] = []
	for option: DialogueOption in world.options:
		out.append(String(option.intent))
	sim.submit(&"end_talk")
	sim.advance(1)
	return out


func _town_of(npc: Npc, region: Region) -> StringName:
	return region.zone_at(npc.tile)


# ---------------------------------------------------------------- the rule ---

func test_every_act_that_moves_the_kingdom_names_who_it_costs() -> void:
	# §8's hard rule, as a test rather than a habit. A deed with world effects and no
	# hardship anywhere is a scoreboard row, and it is not finished.
	var moving: int = 0
	for deed: StringName in DeedRules.all_deeds():
		if not DeedRules.moves_the_kingdom(deed):
			continue
		moving += 1
		var costs: Dictionary = DeedRules.hardship_effects(deed)
		assert_false(costs.is_empty(), "%s moves the kingdom and costs nobody" % deed)
		var somebody_worse_off: bool = false
		for town: StringName in costs.keys():
			assert_true(town == DeedRules.HERE or Region.is_place(town),
				"%s lands a cost in '%s', which is not a place" % [deed, town])
			if float(costs[town]) > 0.0:
				somebody_worse_off = true
		assert_true(somebody_worse_off, "%s makes everybody better off, which is free" % deed)
	assert_true(moving >= 20, "%d deeds move the kingdom — ten each way" % moving)


func test_every_place_a_cost_can_land_in_has_a_face_in_both_languages() -> void:
	# The other half of the rule: *who there can say it*. A cost lands as hardship in
	# a town, and somebody with a name standing in that town has to be able to say so —
	# in a greeting, so that it is the world speaking, and without naming the player,
	# so that the attribution stays in the journal (§8: push the ambient, pull the
	# attribution). Every place, because `HERE` can be any of them.
	var region: Region = Region.build_overworld()
	for language: String in ["en", "fr"]:
		var cast: Cast = Cast.load_from(Cast.path_for(language))
		for zone: StringName in Region.ZONE_ORDER:
			var faces: int = 0
			for npc: Npc in cast.named():
				if _town_of(npc, region) != zone:
					continue
				for alt: Dictionary in npc.alt_greetings:
					if alt.get("when", &"") != &"hardship_is_high_here":
						continue
					faces += 1
					var line: String = String(alt.get("text", "")).to_lower()
					var names_you: bool = (" you" in line) if language == "en" else ("vous" in line)
					assert_false(names_you, "%s's %s hardship line names the player: %s" % [npc.id, language, line])
			assert_true(faces > 0, "%s: nobody in %s can say the place is worse off" % [language, zone])


func test_the_crowns_acts_are_paid_for_by_the_people_his_project_ruined() -> void:
	# The second direction is not a mirror image that helps everyone. Each of the ten
	# moves the crown up, the dispossessed down, some quantity the crown's way — and
	# costs somebody, exactly as the breaking acts do.
	for deed: StringName in DeedRules.BUILDS:
		var factions: Dictionary = DeedRules.faction_effects(deed)
		assert_true(float(factions.get(DeedRules.FACTION_CROWN, 0.0)) > 0.0, "%s does not serve the crown" % deed)
		assert_true(float(factions.get(DeedRules.FACTION_DISPOSSESSED, 0.0)) < 0.0,
			"%s costs the dispossessed nothing, so it is free" % deed)
		assert_true(DeedRules.moves_the_kingdom(deed), "%s moves nothing" % deed)


func test_every_building_act_can_be_said_to_somebody() -> void:
	# Availability is the hard part of a positive act (§8): it has to be as available
	# as breaking something. Every one of the ten is a line in somebody's mouth.
	var cast: Cast = Cast.shared()
	for deed: StringName in DeedRules.BUILDS:
		var speakers: int = 0
		for npc: Npc in cast.named():
			for option: DialogueOption in npc.options:
				if option.causes == deed:
					speakers += 1
		assert_true(speakers > 0, "nobody in the cast can be asked to %s" % deed)


# -------------------------------------------------------------- the number ---

func test_hardship_never_drifts() -> void:
	# §8: it barely drifts and moves sharply when acted on, so it always reads as
	# caused. A quiet day and every town sits exactly where it started. One day rather
	# than three: there is no drift path to it at all, so a day proves what a week would,
	# and the fast suite has to stay the thing you run without thinking.
	var sim: Sim = Game.build()
	var ticked := sim.store(&"worldtick") as WorldTick
	sim.advance_world_ticks(Game.TICKS_PER_IN_GAME_DAY)
	for town: StringName in Region.ZONE_ORDER:
		assert_eq(ticked.hardship_in(town), WorldTick.NEUTRAL, "%s drifted" % town)
	assert_eq(ticked.handprint_on(&"hardship"), 0.0, "and none of it was anybody's doing")


func test_hardship_is_not_an_ending_input() -> void:
	# An ending reads it out, never in. A threshold would hand it a correct
	# direction, which is the one thing it exists not to have (§8).
	for ending: Dictionary in EndRules.endings():
		for need: Dictionary in (ending["needs"] as Array):
			assert_true(String(need["reading"]).find("hardship") < 0,
				"%s reads hardship as a predicate" % ending["id"])


func test_up_is_worse_and_it_carries_the_handprint() -> void:
	var ticked := WorldTick.new()
	ticked.push_hardship(&"wide_acres", 20.0)
	assert_eq(ticked.hardship_in(&"wide_acres"), WorldTick.NEUTRAL + 20.0, "worse off")
	assert_eq(ticked.handprint_on(&"hardship"), 20.0, "and the player's doing")
	ticked.push_hardship(&"wide_acres", -80.0)
	assert_eq(ticked.hardship_in(&"wide_acres"), 0.0, "clamped at the floor")


# --------------------------------------------------------------- the proof ---

func test_breaking_and_building_both_cost_somebody_and_the_journal_says_who() -> void:
	# §18's proof for the phase. Burn the stores at the Wide Acres and feed the works
	# the forest, in one run: two towns worse off, two different causes, a named person
	# in each who says so without naming you — and the journal, pulled, joins the two.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var ticked := sim.store(&"worldtick") as WorldTick
	var cast := sim.store(&"cast") as Cast

	# Breaking it.
	_act_at(sim, _sites_of(sim, &"granary")[0])
	assert_true(ticked.crown_treasury < WorldTick.BASELINE, "the stores burned")
	assert_true(ticked.hardship_in(&"wide_acres") >= DialogueRules.HARDSHIP_BITES, CROSSES_THE_LINE)

	# Building it.
	var steel: float = ticked.steel_output
	var wood: float = ticked.held_ground
	_exhaust_but(sim, &"harry", &"feed_forest")
	assert_true(_offered(sim, &"harry").has("feed_forest"), "Harry can be asked")
	_say(sim, &"harry", &"feed_forest")
	# Steel was already at 100 and the twelve are clamped at BASELINE, so the second
	# direction *restores* rather than raising a full quantity fuller. The push is the
	# player's all the same, and the belt moves whatever the furnaces read.
	assert_true(ticked.steel_output >= steel, "the furnaces did not cool")
	assert_true(ticked.handprint_on(&"steel_output") > 0.0, "and the push was the player's")
	assert_true(ticked.held_ground < wood, "and the belt widened toward the clearing")
	assert_true(ticked.hardship_in(&"brindle") >= DialogueRules.HARDSHIP_BITES, CROSSES_THE_LINE)
	assert_true(ticked.handprint_on(&"hardship") > 0.0, "all of it the player's doing")

	# The faces. Standing in each place, the greeting has changed and does not say why.
	world.player_pos = Vector2(cast.get_npc(&"pell").tile) + Vector2(0.5, 0.5)
	var at_the_acres: Dictionary = DialogueRules.conditions(world, ticked)
	assert_true(bool(at_the_acres[&"hardship_is_high_here"]), "the Wide Acres are worse off")
	var pell: Npc = cast.get_npc(&"pell")
	assert_true(pell.greeting_for(at_the_acres) != pell.greeting, "Pell says so")
	assert_false(" you" in pell.greeting_for(at_the_acres).to_lower(), "and does not say who")

	world.player_pos = Vector2(cast.get_npc(&"wren").tile) + Vector2(0.5, 0.5)
	var at_brindle: Dictionary = DialogueRules.conditions(world, ticked)
	assert_true(bool(at_brindle[&"hardship_is_high_here"]), "Brindle is worse off")
	var wren: Npc = cast.get_npc(&"wren")
	assert_true(wren.greeting_for(at_brindle) != wren.greeting, "Wren says so")

	# The journal: two towns, two different causes, once each.
	var towns: Dictionary = {}
	for row: Dictionary in Journal.entries(sim.events):
		if row["kind"] == Journal.HARDSHIP:
			towns[row["town"]] = row["deed"]
	assert_true(towns.has(&"wide_acres") and towns.has(&"brindle"), "both towns are in the journal: %s" % towns)
	assert_true(towns[&"wide_acres"] != towns[&"brindle"], "for two different reasons")
	assert_eq(towns[&"wide_acres"], DeedRules.DEED_BURN_STORES)
	assert_eq(towns[&"brindle"], DeedRules.DEED_FEED_FOREST)


func test_a_spoken_building_act_is_said_once() -> void:
	# A question answered is a question spent, and an act is a question.
	var sim: Sim = Game.build()
	_exhaust_but(sim, &"harry", &"feed_forest")
	_say(sim, &"harry", &"feed_forest")
	assert_false(_offered(sim, &"harry").has("feed_forest"), "you cannot feed it the forest twice")


func test_the_same_acts_leave_the_same_hardship_twice_over() -> void:
	# Determinism at the level of the store: two worlds given the same acts agree to
	# the digit, and hardship is part of what they agree on. The log-replay guarantee
	# itself is held by the journeys and saving suites, over events rather than pokes.
	var fingerprints: Array[String] = []
	for _run: int in 2:
		var sim: Sim = Game.build()
		_act_at(sim, _sites_of(sim, &"granary")[0])
		_exhaust_but(sim, &"harry", &"deliver_labour")
		_say(sim, &"harry", &"deliver_labour")
		fingerprints.append((sim.store(&"worldtick") as WorldTick).fingerprint())
	assert_eq(fingerprints[0], fingerprints[1], "same acts, same world")
	assert_true(fingerprints[0].find("wide_acres:50.00/50.00/70.00") >= 0,
		"and hardship is in the fingerprint, where a replay would have to match it: %s" % fingerprints[0])
