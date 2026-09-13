extends TestCase

## Phase 3, stage 3: witnesses, rumour, and reputation that has an address.
##
## §8's first consequence: take something from a stall in Harrowgate while Maddox
## is looking, walk to Cairnwell, and a trader who has never met you will not sell
## to you. Everything here is that sentence, taken apart.
##
## The three registers (§8) are all present and each is tested separately. The
## window phrases the first two, so what is tested here is the state it phrases
## them from: IMMEDIATE — the theft records how many people looked up, and when;
## AMBIENT — the town's opinion moves with nobody saying a word to you; NARRATED
## — the trader says word came up the road, and never says it was you.


## Standing at the counter of the first stall in the Harrowgate market.
const AT_A_STALL: Vector2 = Vector2(146.5, 172.0)
## Beside the Cairnwell trader, a hundred and twenty-six tiles away.
const AT_THE_TRADER: Vector2 = Vector2(93.5, 60.0)

const TRADER: StringName = &"trader@1"


## Lean on purpose: travellers and movement cost steps and prove nothing here.
func _crime_sim(cast: Cast = Cast.shared()) -> Sim:
	var sim := Sim.new()
	sim.add_store(&"world", Game.build_world())
	sim.add_store(&"cast", cast)
	sim.add_store(&"worldtick", WorldTick.new())
	sim.add_store(&"standing", Standing.new())
	sim.add_store(&"rumours", Rumours.new())
	sim.add_system(DialogueSystem.new())
	sim.add_system(WorldTickSystem.new())
	sim.add_system(TheftSystem.new())
	sim.add_system(RumourSystem.new())
	return sim


## The same world with the King's Road in use. Distance past a neighbouring town is
## covered by people now, so anything about somewhere far away needs carriers.
func _road_sim() -> Sim:
	var sim: Sim = _crime_sim()
	sim.add_store(&"travellers", Travellers.new())
	sim.add_system(TravellerSystem.new())
	return sim


func _steal_at(sim: Sim, where: Vector2) -> void:
	var world := sim.store(&"world") as WorldState
	world.player_pos = where
	sim.submit(&"steal")
	# Two steps, not one. The theft is answered by a derived event, and a derived
	# event is handled on the step after the one that raised it — one sixtieth of
	# a second of latency, and the reason a system can answer a system at all.
	sim.advance(2)


func _days(sim: Sim, count: float) -> void:
	sim.advance_world_ticks(int(float(Game.TICKS_PER_IN_GAME_DAY) * count))


# ---------------------------------------------------------------- the crime ---

func test_there_is_something_to_steal_from() -> void:
	var region: Region = Region.build_overworld()
	assert_ne(region.nearest_stall(Vector2i(AT_A_STALL), CrimeRules.STALL_REACH), Region.NOWHERE,
		"a stall is within reach of the market")
	assert_eq(region.nearest_stall(Region.BRINDLE, CrimeRules.STALL_REACH), Region.NOWHERE,
		"and Brindle, being a ruin, has no market at all")


func test_a_theft_nobody_sees_did_not_happen() -> void:
	# §8, and the reason witnesses are recorded per event rather than assumed. The
	# empty cast is the honest way to test it: every stall on the shipped map is
	# overlooked by somebody, which is what a market is.
	var sim: Sim = _crime_sim(Cast.new())
	var world := sim.store(&"world") as WorldState
	var standing := sim.store(&"standing") as Standing
	var rumours := sim.store(&"rumours") as Rumours

	_steal_at(sim, AT_A_STALL)
	assert_eq(world.thefts, 1, "the theft happened — the fact is yours either way")
	assert_eq(rumours.told, 0, "but there is no story, because there is nobody to tell it")
	assert_eq(standing.in_town(&"harrowgate"), Standing.NEUTRAL,
		"and the town's opinion of you has not moved")


func test_maddox_sees_it_and_harrowgate_turns() -> void:
	var sim: Sim = _crime_sim()
	var cast := sim.store(&"cast") as Cast
	var standing := sim.store(&"standing") as Standing
	var rumours := sim.store(&"rumours") as Rumours

	var seen: PackedStringArray = CrimeRules.witnesses_to(cast, WorldState.OVERWORLD, AT_A_STALL)
	assert_true(seen.has("maddox"), "Maddox is standing two tiles away, %s" % str(seen))

	_steal_at(sim, AT_A_STALL)
	assert_eq(rumours.told, 1, "one theft, one story")
	assert_true(StandingRules.is_unwelcome(standing.in_town(&"harrowgate")),
		"Harrowgate knows already: %.1f" % standing.in_town(&"harrowgate"))


func test_the_theft_moves_only_the_town_that_saw_it() -> void:
	# Reputation with an address. A global number would have turned the whole map
	# against you the instant Maddox looked up, and nothing about that is legible.
	var sim: Sim = _crime_sim()
	var standing := sim.store(&"standing") as Standing
	_steal_at(sim, AT_A_STALL)
	assert_eq(standing.in_town(&"cairnwell"), Standing.NEUTRAL,
		"Cairnwell is a hundred and twenty-six tiles away and has heard nothing")
	assert_eq(standing.in_town(&"saltmarch"), Standing.NEUTRAL, "nor has Saltmarch")


func test_every_door_that_shuts_opens_another() -> void:
	# §8's hard rule. A change with no counterpart is a morality meter.
	var sim: Sim = _crime_sim()
	var standing := sim.store(&"standing") as Standing
	_steal_at(sim, AT_A_STALL)
	assert_true(standing.with_faction(DeedRules.FACTION_TOWNS) < 0.0,
		"the towns think less of you")
	assert_true(standing.with_faction(DeedRules.FACTION_UNDERWORLD) > 0.0,
		"and somebody who profits from a busy watch thinks more")


func test_the_act_is_reported_at_the_moment_it_happens() -> void:
	# §8's IMMEDIATE register. What the window draws from: how many looked up, and
	# the step it happened on, so the line can be said once and then stop.
	var sim: Sim = _crime_sim()
	var world := sim.store(&"world") as WorldState
	assert_eq(world.last_theft_step, -1, "nothing has happened yet")
	_steal_at(sim, AT_A_STALL)
	assert_true(world.last_theft_step >= 0, "and now something has")
	assert_true(world.last_theft_seen > 0, "with somebody watching: %d" % world.last_theft_seen)


func test_a_stall_you_just_robbed_has_nothing_left_on_it() -> void:
	# Without this, holding E down starts fifty stories in a second and floors
	# every reputation in the region — a consequence you can spam is not one.
	var sim: Sim = _crime_sim()
	var world := sim.store(&"world") as WorldState
	var rumours := sim.store(&"rumours") as Rumours
	_steal_at(sim, AT_A_STALL)
	_steal_at(sim, AT_A_STALL)
	_steal_at(sim, AT_A_STALL)
	assert_eq(world.thefts, 1, "one theft, however many times you pressed it")
	assert_eq(rumours.told, 1, "and one story")


func test_the_stall_is_restocked_eventually() -> void:
	var sim: Sim = _crime_sim()
	var world := sim.store(&"world") as WorldState
	_steal_at(sim, AT_A_STALL)
	sim.advance_world_ticks(CrimeRules.STALL_RESTOCK_TICKS + 1)
	_steal_at(sim, AT_A_STALL)
	assert_eq(world.thefts, 2, "come back later and there is something on it again")


# --------------------------------------------------------------- the travel ---

func test_a_story_spreads_as_far_as_the_next_town_and_stops() -> void:
	# On its own a story carries about as far as a neighbour. It used to carry 220
	# tiles, which is the whole map — so it reached everywhere whichever way the
	# player walked, and the road cost nothing.
	var sim: Sim = _crime_sim()
	var standing := sim.store(&"standing") as Standing
	_steal_at(sim, AT_A_STALL)

	var arrived_on: int = 0
	for day: int in range(1, 6):
		_days(sim, 1.0)
		if arrived_on == 0 and standing.in_town(&"muster") < Standing.NEUTRAL:
			arrived_on = day
	assert_true(arrived_on >= 1 and arrived_on <= 3,
		"the camp is seventy tiles off and took %d day(s)" % arrived_on)
	assert_eq(standing.in_town(&"cairnwell"), Standing.NEUTRAL,
		"and Cairnwell, at a hundred and twenty-seven, hears nothing at all on its own")






func test_a_story_moves_a_town_once_and_not_every_tick() -> void:
	var sim: Sim = _crime_sim()
	var standing := sim.store(&"standing") as Standing
	_steal_at(sim, AT_A_STALL)
	var after_the_crime: float = standing.in_town(&"harrowgate")
	_days(sim, 4.0)
	assert_eq(standing.in_town(&"harrowgate"), after_the_crime,
		"Harrowgate heard it once, on the day, and has not re-heard it since")


func test_a_story_stops_being_worth_repeating() -> void:
	var sim: Sim = _crime_sim()
	var rumours := sim.store(&"rumours") as Rumours
	_steal_at(sim, AT_A_STALL)
	assert_eq(rumours.live.size(), 1, "one story in the air")
	_days(sim, CrimeRules.RUMOUR_RANGE / CrimeRules.RUMOUR_TILES_PER_DAY + 1.0)
	assert_eq(rumours.live.size(), 0, "and eventually it is old news")


# ------------------------------------------------------------- the refusal ---

func _talk_to_trader(sim: Sim) -> WorldState:
	var world := sim.store(&"world") as WorldState
	world.player_pos = AT_THE_TRADER
	sim.submit(&"talk", {"npc": String(TRADER)})
	sim.advance(2)
	return world


func _offered(world: WorldState) -> Array[String]:
	var out: Array[String] = []
	for option: DialogueOption in world.options:
		out.append(String(option.intent))
	return out


func test_the_trader_sells_to_a_stranger_who_has_done_nothing() -> void:
	# The control. Without it the refusal test proves only that the trader is rude.
	var sim: Sim = _crime_sim()
	var world: WorldState = _talk_to_trader(sim)
	assert_eq(world.talking_to, TRADER, "the trader is standing where the spec put him")
	assert_true(_offered(world).has("ask_trade"), "and will sell you something")
	assert_false(_offered(world).has("ask_refusal"), "with nothing to refuse you for")




func test_the_refusal_is_local_to_where_word_has_got() -> void:
	# The same trade, the same man, in a place that has not heard. There is no
	# second trader yet, so this asks the rules layer the question directly.
	#
	# No carriers in this sim, so the story reaches a neighbour and stops, which is
	# the sharpest version of "reputation has an address".
	var sim: Sim = _crime_sim()
	_steal_at(sim, AT_A_STALL)
	_days(sim, 3.0)
	var world := sim.store(&"world") as WorldState
	var ticked := sim.store(&"worldtick") as WorldTick
	var standing := sim.store(&"standing") as Standing

	world.player_pos = Vector2(Region.MUSTER) + Vector2(0.5, 0.5)
	assert_true(bool(DialogueRules.conditions(world, ticked, standing)[&"i_am_unwelcome_here"]),
		"unwelcome at the camp, seventy tiles off")
	world.player_pos = AT_THE_TRADER
	assert_false(bool(DialogueRules.conditions(world, ticked, standing)[&"i_am_unwelcome_here"]),
		"but not in Cairnwell, which nobody has walked to with it")


# ------------------------------------------------------------ the carriers ---
#
# Travellers are furniture that moves. These are the rules that keep them from
# quietly becoming people — cheap, and run on every change. The end-to-end proofs
# they serve are in test_travellers.gd, which is slow.

func test_a_traveller_can_never_be_a_source() -> void:
	# The whole of the attribution guarantee. A story needs somebody who can be
	# named and asked; a traveller has no name and no home and you will never meet
	# the same one twice. So a deed nobody named saw stays a deed nobody saw, even
	# with six people walking past.
	var sim: Sim = _road_sim()
	var world := sim.store(&"world") as WorldState
	var rumours := sim.store(&"rumours") as Rumours
	var road := sim.store(&"travellers") as Travellers
	sim.advance(2)
	assert_eq(road.walkers.size(), TravelRules.ON_THE_ROAD, "the road is in use")

	# The Saltmarch stall, which no member of the cast stands near.
	_steal_at(sim, Vector2(34.5, 149.0))
	assert_eq(world.thefts, 1, "the theft happened")
	assert_eq(rumours.told, 0, "and started nothing, however many people were on the road")


func test_a_traveller_never_acquires_an_opinion() -> void:
	# They carry stories; they do not hold them against you. An opinion you can
	# never encounter again is not an opinion, and putting one in the standing
	# table is how a system acquires rows nobody can account for.
	var sim: Sim = _road_sim()
	var standing := sim.store(&"standing") as Standing
	_steal_at(sim, AT_A_STALL)
	_days(sim, 1.0)
	for who: StringName in standing.by_person.keys():
		assert_false(String(who).begins_with("traveller"),
			"'%s' has an opinion of the player and cannot be found to ask" % who)
		assert_true(Cast.shared().get_npc(who) != null,
			"'%s' holds standing but is nobody in the cast" % who)


func test_the_road_is_walked_the_same_way_every_time() -> void:
	# Seeded from the road itself rather than from the rng, so a run rebuilt from
	# its log puts everybody back where they were without spending randomness.
	var first: Sim = _road_sim()
	var second: Sim = _road_sim()
	first.advance(Sim.STEPS_PER_REAL_SECOND * 20)
	second.advance(Sim.STEPS_PER_REAL_SECOND * 20)
	assert_eq((second.store(&"travellers") as Travellers).fingerprint(),
		(first.store(&"travellers") as Travellers).fingerprint(),
		"the same road, walked identically")


func test_a_patrolled_road_is_harder_to_pass_unremarked() -> void:
	# §8's fourth quantity finally reads by something. The crown moves men about
	# after crime reports, so the more it has heard the further along the King's
	# Road somebody will put your face to the story — which pushes the player the
	# same way the watch does, toward the trees.
	assert_true(
		TravelRules.recognise_range_for(100.0) > TravelRules.recognise_range_for(WorldTick.NEUTRAL),
		"a busy road notices you from further off")
	assert_eq(TravelRules.recognise_range_for(0.0), TravelRules.RECOGNISE_RANGE,
		"and an empty one is the quiet figure")


func test_travellers_keep_to_the_road() -> void:
	var sim: Sim = _road_sim()
	var region: Region = (sim.store(&"world") as WorldState).region()
	sim.advance(Sim.STEPS_PER_REAL_SECOND * 30)
	for walker: Traveller in (sim.store(&"travellers") as Travellers).walkers:
		assert_true(region.is_passable(walker.tile()),
			"a traveller is standing inside something at %s" % walker.tile())


# ------------------------------------------------------------- the readout ---

func test_a_place_that_has_never_heard_of_you_says_so() -> void:
	assert_eq(StandingRules.word_for(Standing.NEUTRAL), &"unknown",
		"the baseline is shown from the first minute, so a change has something to read against")


func test_the_scale_runs_worst_to_best_without_a_gap() -> void:
	var scale: Array[StringName] = StandingRules.scale()
	assert_eq(scale.size(), 5, "five words")
	assert_eq(StandingRules.word_for(Standing.WORST), scale[0], "the bottom of the range is the first word")
	assert_eq(StandingRules.word_for(Standing.BEST), scale[4], "and the top is the last")
	# Every value in range lands on one of the five, and the word only ever
	# improves as the number does — a scale with a hole in it is a bug you find
	# by standing in the wrong town.
	var last: int = 0
	for step: int in range(-100, 101):
		var word: StringName = StandingRules.word_for(float(step))
		var rank: int = scale.find(word)
		assert_true(rank >= 0, "%d is off the scale entirely" % step)
		assert_true(rank >= last, "%d reads as %s, worse than the value below it" % [step, word])
		last = rank


func test_the_word_and_the_refusal_can_never_disagree() -> void:
	# The lie this forbids: the HUD saying "wary" while a trader will not serve
	# you. Both readings come off one set of constants, and this is what holds
	# them there when somebody tunes one of them.
	for step: int in range(-100, 101):
		var amount: float = float(step)
		var shut: bool = StandingRules.is_unwelcome(amount)
		var word: StringName = StandingRules.word_for(amount)
		assert_eq(shut, word == &"unwelcome" or word == &"hated",
			"%.0f reads as %s but doors %s" % [amount, word, "shut" if shut else "stay open"])


func test_one_witnessed_theft_reads_as_unwelcome() -> void:
	var sim: Sim = _crime_sim()
	var standing := sim.store(&"standing") as Standing
	_steal_at(sim, AT_A_STALL)
	assert_eq(StandingRules.word_for(standing.in_town(&"harrowgate")), &"unwelcome",
		"the first theft is legible the first time")


func test_the_word_travels_with_the_story_and_not_with_you() -> void:
	# What the player sees walking west: Harrowgate turns the moment it happens,
	# Cairnwell knows nothing, and then three days later it does. The readout is
	# per place, which is how reputation having an address is taught without a
	# line of explanation.
	var sim: Sim = _crime_sim()
	var standing := sim.store(&"standing") as Standing
	_steal_at(sim, AT_A_STALL)
	assert_eq(StandingRules.word_for(standing.in_town(&"harrowgate")), &"unwelcome")
	assert_eq(StandingRules.word_for(standing.in_town(&"muster")), &"unknown",
		"walk into the camp today and nobody there has heard")
	_days(sim, 3.0)
	assert_eq(StandingRules.word_for(standing.in_town(&"muster")), &"unwelcome",
		"stand there three days and you watch it turn")


func test_nobody_ever_tells_you_it_was_your_fault() -> void:
	# "Push the ambient, pull the attribution" (§8). The world may change its mind
	# in front of you; it may never read you the causal chain. Maddox not knowing
	# it was you is the entire pleasure of it.
	var accusations: Array[String] = [
		"you stole", "your theft", "because you", "you caused", "your actions",
		"as a result of", "reputation:",
	]
	var cast := Cast.shared()
	for id: StringName in cast.npcs.keys():
		var npc: Npc = cast.get_npc(id)
		var lines: Array[String] = [npc.greeting]
		for alt: Dictionary in npc.alt_greetings:
			lines.append(String(alt["text"]))
		for option: DialogueOption in npc.options:
			lines.append(option.text)
			lines.append(option.reply)
		for line: String in lines:
			for phrase: String in accusations:
				assert_false(line.to_lower().contains(phrase),
					"%s says \"%s\" — the world never narrates the player" % [id, line])
