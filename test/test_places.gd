extends TestCase

## Phase C — four places, two states (§3, §8, 2026-09-13).
##
## A place is crown-held or free and never a third thing. It changes hands two ways:
## the band, which moves the two borders on the sentiment of the town under them and
## writes no handprint; and one decisive act per place — the thing the place holds,
## spent one way or the other at the landmark — which writes the stamp and holds the
## place for two in-game days against everything. These hold the shape and §18's
## proof: free the Wide Acres, watch the band fail to take it back for two days, then
## restore it; and the sign says something different each time.

const A_DAY: int = Game.TICKS_PER_IN_GAME_DAY


func _sim() -> Sim:
	return Game.build()


func _take(sim: Sim, fact: StringName) -> void:
	var world := sim.store(&"world") as WorldState
	for prop: Dictionary in world.region().props:
		if (prop["kind"] as StringName) == &"papers" and (prop["fact"] as StringName) == fact:
			world.player_pos = Vector2(prop["at"] as Vector2i) + Vector2(0.5, 0.5)
			sim.submit(&"act")
			sim.advance(3)
			return
	fail("no papers carry %s" % fact)


func _stand_by(sim: Sim, who: StringName) -> void:
	var world := sim.store(&"world") as WorldState
	world.player_pos = Vector2((sim.store(&"cast") as Cast).get_npc(who).tile) + Vector2(0.5, 0.5)


func _exhaust_but(sim: Sim, who: StringName, keep: StringName) -> void:
	var npc: Npc = (sim.store(&"cast") as Cast).get_npc(who)
	for option: DialogueOption in npc.options:
		if option.intent != keep and option.requires_condition == &"":
			sim.facts.add_source(option.spent_by(npc.id), &"test")


func _offered(sim: Sim, who: StringName) -> Array[String]:
	var world := sim.store(&"world") as WorldState
	_stand_by(sim, who)
	sim.submit(&"talk", {"npc": String(who)})
	sim.advance(2)
	var out: Array[String] = []
	for option: DialogueOption in world.options:
		out.append(String(option.intent))
	sim.submit(&"end_talk")
	sim.advance(1)
	return out


func _say(sim: Sim, who: StringName, intent: StringName) -> void:
	_stand_by(sim, who)
	sim.submit(&"talk", {"npc": String(who)})
	sim.advance(2)
	sim.submit(&"choose_intent", {"intent": String(intent)})
	sim.advance(2)
	sim.submit(&"end_talk")
	sim.advance(1)


## The grants in hand, read to the tenants at the Wide Acres.
func _free_the_acres(sim: Sim) -> void:
	_take(sim, DocumentRules.LAND_GRANTS)
	_stand_by(sim, &"pell")
	sim.submit(&"tell_town")
	sim.advance(2)


func _sign(mine: Allegiance, zone: StringName) -> StringName:
	return PlaceRules.sign_key_for(zone, mine.holder(zone), mine.was_decided(zone))


func _sites_of(sim: Sim, kind: StringName) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for prop: Dictionary in (sim.store(&"world") as WorldState).region().props:
		if (prop["kind"] as StringName) == kind:
			out.append(prop["at"] as Vector2i)
	return out


# --------------------------------------------------------------- the shape ---

func test_four_places_carry_a_state_and_all_start_crown_held() -> void:
	var mine := Allegiance.new()
	assert_eq(PlaceRules.PLACES.size(), 4, "four places, deeply")
	for place: StringName in PlaceRules.PLACES:
		assert_eq(mine.holder(place), FactionRules.CROWN, "%s starts the king's" % place)
	assert_eq(mine.holder(&"saltmarch"), FactionRules.CROWN, "the other border too: two states, no neutral")
	assert_eq(mine.holder(&"brindle"), FactionRules.OPPOSITION, "and the ruins were never his")
	for zone: StringName in Region.ZONE_ORDER:
		assert_true(mine.holder(zone) != FactionRules.NEUTRAL, "%s has a third state" % zone)


func test_the_thing_each_place_holds_is_a_real_fact_and_the_holding_deed_is_real() -> void:
	# PlaceRules names ids rather than the other classes' constants, because a const
	# built from another class's const cannot be resolved at parse time. So this holds
	# them equal instead.
	assert_eq(PlaceRules.thing_of(&"wide_acres"), DocumentRules.LAND_GRANTS)
	assert_eq(PlaceRules.thing_of(&"cinderworks"), DocumentRules.WORKS_LEDGER)
	assert_eq(PlaceRules.thing_of(&"muster"), ArmyRules.FACT_PAY_FRAUD)
	assert_eq(PlaceRules.thing_of(&"cairnwell"), DocumentRules.DEBTS)
	for deed: StringName in PlaceRules.HOLDS.keys():
		assert_true(DeedRules.all_deeds().has(deed), "%s is not a deed" % deed)
		assert_true(PlaceRules.has_state(PlaceRules.held_by(deed)), "%s holds nowhere" % deed)
	assert_eq(PlaceRules.freeze_ticks(), 2 * A_DAY, "two in-game days, 2880 ticks, twelve real minutes")


func test_the_holding_act_spends_the_same_thing_the_freeing_act_does() -> void:
	# One thing, two ways to spend it. The line that holds a place for the crown needs
	# the place's thing in hand, exactly as reading it aloud does — so the decisive
	# change is one act with two outcomes, and never a menu at the landmark.
	var cast: Cast = Cast.shared()
	for deed: StringName in PlaceRules.HOLDS.keys():
		var place: StringName = PlaceRules.held_by(deed)
		var found: bool = false
		for npc: Npc in cast.named():
			for option: DialogueOption in npc.options:
				if option.causes != deed:
					continue
				found = true
				assert_eq(option.requires, PlaceRules.thing_of(place),
					"%s's %s should need %s in hand" % [npc.id, option.intent, PlaceRules.thing_of(place)])
				assert_eq(option.forbids_condition, &"this_place_is_frozen",
					"%s's %s must not be offered while the place is held" % [npc.id, option.intent])
		assert_true(found, "nobody offers %s" % deed)


# --------------------------------------------------------------- the proof ---

func test_reading_the_grants_to_the_tenants_frees_the_acres() -> void:
	var sim: Sim = _sim()
	var mine := sim.store(&"allegiance") as Allegiance
	_free_the_acres(sim)
	assert_eq(mine.holder(&"wide_acres"), FactionRules.OPPOSITION, "the land went back")
	assert_true(mine.was_decided(&"wide_acres"), "and the stamp says whose doing it was")
	assert_true(mine.is_frozen(&"wide_acres", sim.tick), "and it holds")
	assert_eq(mine.flips.size(), 1)
	assert_true(bool(mine.flips[0]["by_player"]), "a player flip, not the weather")


func test_the_band_cannot_take_it_back_for_two_days_and_then_can() -> void:
	# §18's proof, the middle of it. The town under the Acres swings hard for the
	# crown the moment they are freed; the band would flip it back on the next tick
	# and the player's largest act in a place would read as a switch.
	var sim: Sim = _sim()
	var mine := sim.store(&"allegiance") as Allegiance
	var ticked := sim.store(&"worldtick") as WorldTick
	_free_the_acres(sim)
	ticked.town_sentiment[&"wide_acres"] = FactionRules.TURNS_TO_CROWN + 20.0
	sim.advance_world_ticks(A_DAY)
	assert_eq(mine.holder(&"wide_acres"), FactionRules.OPPOSITION, "a day later: still free, whatever the town reads")
	sim.advance_world_ticks(A_DAY + 10)
	ticked.town_sentiment[&"wide_acres"] = FactionRules.TURNS_TO_CROWN + 20.0
	sim.advance_world_ticks(2)
	assert_eq(mine.holder(&"wide_acres"), FactionRules.CROWN, "the hold is over and the band moves it")
	assert_eq(mine.flips.size(), 2)
	assert_false(bool(mine.flips[1]["by_player"]), "by drift: no handprint")


func test_the_hold_binds_the_player_too_and_then_lets_go() -> void:
	# Yannick's ruling (2026-09-13): during the hold nothing moves the place, not the
	# band and not the player. The holding act is simply not offered — the roused-watch
	# shape, world state refusing an act with the door shown shut.
	var sim: Sim = _sim()
	var mine := sim.store(&"allegiance") as Allegiance
	_free_the_acres(sim)
	_exhaust_but(sim, &"nessa", &"enforce_grants")
	assert_false(_offered(sim, &"nessa").has("enforce_grants"), "Nessa will not enforce them while the place is held")
	sim.advance_world_ticks(2 * A_DAY + 1)
	assert_true(_offered(sim, &"nessa").has("enforce_grants"), "two days on, she will")
	_say(sim, &"nessa", &"enforce_grants")
	assert_eq(mine.holder(&"wide_acres"), FactionRules.CROWN, "restored, by the player")
	assert_eq(mine.flips.size(), 2, "one flip each way")
	assert_true(bool(mine.flips[1]["by_player"]))


func test_the_reverse_hold_the_camp_paid_cannot_be_exposed_for_two_days() -> void:
	var sim: Sim = _sim()
	var world := sim.store(&"world") as WorldState
	var mine := sim.store(&"allegiance") as Allegiance
	sim.facts.add_source(ArmyRules.FACT_PAY_FRAUD, &"odile")
	_exhaust_but(sim, &"odile", &"pay_muster")
	_say(sim, &"odile", &"pay_muster")
	assert_eq(mine.holder(&"muster"), FactionRules.CROWN, "the camp is the king's, and decided so")
	assert_true(mine.was_decided(&"muster"), "stamped")
	assert_true(mine.is_frozen(&"muster", sim.tick))

	world.player_pos = Vector2(Region.MUSTER) + Vector2(0.5, 0.5)
	sim.submit(&"expose_fraud")
	sim.advance(2)
	assert_false(world.pay_fraud_exposed, "the men will not hear it while the camp is held")

	sim.advance_world_ticks(2 * A_DAY + 1)
	sim.submit(&"expose_fraud")
	sim.advance(2)
	assert_true(world.pay_fraud_exposed, "and two days on, they will")
	assert_eq(mine.holder(&"muster"), FactionRules.OPPOSITION, "and the camp goes free")


func test_a_decision_that_keeps_a_place_where_it_was_is_a_stamp_not_a_flip() -> void:
	var mine := Allegiance.new()
	assert_false(mine.decide(&"wide_acres", FactionRules.CROWN, 100), "no change of hands")
	assert_true(mine.was_decided(&"wide_acres"), "but the player decided it stays")
	assert_true(mine.is_frozen(&"wide_acres", 100 + PlaceRules.freeze_ticks() - 1))
	assert_false(mine.is_frozen(&"wide_acres", 100 + PlaceRules.freeze_ticks()))
	assert_eq(mine.flips.size(), 0, "and nothing for the instability reading to count")


func test_the_sign_says_something_different_each_time() -> void:
	var mine := Allegiance.new()
	var loyal: StringName = _sign(mine, &"wide_acres")
	mine.decide(&"wide_acres", FactionRules.OPPOSITION, 10)
	var freed: StringName = _sign(mine, &"wide_acres")
	mine.decide(&"wide_acres", FactionRules.CROWN, 10 + PlaceRules.freeze_ticks())
	var restored: StringName = _sign(mine, &"wide_acres")
	assert_true(loyal != freed and freed != restored and loyal != restored,
		"%s / %s / %s" % [loyal, freed, restored])
	assert_eq(_sign(mine, &"blackcairn"), &"sign.blackcairn.crown", "the castle has one state")
	assert_eq(_sign(mine, &"harrowgate"), &"", "and a deferred place has no sign yet")


func test_every_sign_exists_in_both_languages() -> void:
	for language: String in ["en", "fr"]:
		var known: Array[String] = Text.keys_for(language)
		for place: StringName in PlaceRules.PLACES:
			for state: String in ["crown", "restored", "free"]:
				assert_true(known.has("sign.%s.%s" % [place, state]), "%s: sign.%s.%s" % [language, place, state])
		assert_true(known.has("sign.blackcairn.crown"), "%s: the castle's" % language)


func test_a_freed_place_has_no_watch() -> void:
	# §4's free variant: the granary door open and no watchman. The crown's men left
	# with the crown, so a roused watch does not stand over a place it no longer holds.
	var sim: Sim = _sim()
	var world := sim.store(&"world") as WorldState
	var ticked := sim.store(&"worldtick") as WorldTick
	var mine := sim.store(&"allegiance") as Allegiance
	ticked.rouse(&"wide_acres", 100.0)
	var granary: Vector2i = _sites_of(sim, &"granary")[0]
	world.player_pos = Vector2(granary) + Vector2(1.5, 2.0)
	sim.submit(&"act")
	sim.advance(3)
	assert_eq(ticked.crown_treasury, WorldTick.BASELINE, "a roused watch refuses the act while the crown holds the place")

	mine.decide(&"wide_acres", FactionRules.OPPOSITION, sim.tick)
	sim.submit(&"act")
	sim.advance(3)
	assert_true(ticked.crown_treasury < WorldTick.BASELINE, "freed, and nobody is standing over the granary")


func test_the_journal_says_who_moved_it_and_when_it_was_nobody() -> void:
	var sim: Sim = _sim()
	var ticked := sim.store(&"worldtick") as WorldTick
	_free_the_acres(sim)
	ticked.town_sentiment[&"wide_acres"] = FactionRules.TURNS_TO_CROWN + 20.0
	sim.advance_world_ticks(2 * A_DAY + 5)
	var flips: Array[Dictionary] = []
	for row: Dictionary in Journal.entries(sim.events):
		if row["kind"] == Journal.FLIP:
			flips.append(row)
	assert_eq(flips.size(), 2, "one row each way")
	assert_true(bool(flips[0]["by_player"]), "the first was yours")
	assert_false(bool(flips[1]["by_player"]), "the second, the town's — and the row says nothing about you")


func test_the_same_acts_leave_the_same_places_twice_over() -> void:
	var prints: Array[String] = []
	for _run: int in 2:
		var sim: Sim = _sim()
		_free_the_acres(sim)
		sim.advance_world_ticks(A_DAY)
		prints.append((sim.store(&"allegiance") as Allegiance).fingerprint())
	assert_eq(prints[0], prints[1], "same acts, same ground, same stamps")
	assert_true(prints[0].find("wide_acres:opposition") >= 0, "and the state is in the fingerprint")
	assert_true(prints[0].find("wide_acres@") >= 0, "with its stamp")
