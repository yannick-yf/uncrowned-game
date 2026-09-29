extends TestCase

## Phase 7, the opening — stage 1: the ground.
##
## The player wakes among the graves at Brindle's southern edge (O12), beside the
## fairy, and walks north into the ruins. No maze, no choice in the first minute, and
## nothing gated anywhere. **The fairies' clearing** — a pocket in the Thornwood, ringed
## by thicket, with one corridor south — was where the game began until O12 and was
## deleted in T2 (Yannick, 2026-09-29), with the tests that described it.
##
## **The thicket is geography, not a gate.** The rule that keeps it honest is asserted
## below: it may never be the only thing between the player and anything, which is why
## every zone must be reachable from where the player wakes.

const SLOW: bool = true


func _region() -> Region:
	return Region.build_overworld()


## Everywhere you can walk from here, optionally with some tiles dammed.
##
## The damming is the shape MAP_SPEC uses for the river — *"damming both crossings
## makes Blackcairn unreachable"* — because a barrier you can only assert is a
## barrier nobody has checked. One corridor is true when blocking the corridor
## closes the pocket, and not before.
func _reachable(region: Region, from: Vector2i, dammed: Array[Vector2i]) -> Dictionary:
	var blocked: Dictionary = {}
	for tile: Vector2i in dammed:
		blocked[tile] = true
	var seen: Dictionary = {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_back()
		for dx: int in [-1, 0, 1]:
			for dy: int in [-1, 0, 1]:
				var next := Vector2i(at.x + dx, at.y + dy)
				if seen.has(next) or blocked.has(next):
					continue
				if not region.in_bounds(next) or not region.is_passable(next):
					continue
				seen[next] = true
				queue.append(next)
	return seen


# ------------------------------------------------------- the cemetery (O12) ---
#
# Yannick, 2026-09-29: the game starts south of the ruined village, in a cemetery, so
# the player walks through Brindle and meets the tutorial — "not on a beach". His
# promontory is an island of cliffs, so it is the village's own graveyard, on the
# meadow at Brindle's southern edge.

func test_the_game_starts_in_a_cemetery_on_open_ground() -> void:
	var region: Region = _region()
	var start: Vector2i = where_the_game_starts()
	assert_eq(start, Places.shared().point(&"cemetery"), "the start is the cemetery")
	assert_true(region.is_passable(start), "on ground you can stand on")
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			var here: Region.Terrain = region.terrain_at(start + Vector2i(dx, dy))
			assert_true(here != Region.Terrain.SAND and here != Region.Terrain.SEA,
				"not on a beach (Yannick): %s" % Region.Terrain.keys()[here])


func test_the_cemetery_is_at_brindles_southern_edge_and_joined_to_it() -> void:
	if not Places.baked():
		off("the 2D map's shore is three rows of sand; its cemetery is a point west of Brindle")
		return
	var region: Region = _region()
	var start: Vector2i = where_the_game_starts()
	var brindle: Vector2i = Region.zone_sites()[&"brindle"] as Vector2i
	assert_true(start.y >= brindle.y + 10, "at the southern edge of the ruined village: %s" % start)
	assert_false(Navigation.path(region, start, brindle).is_empty(), "and you can walk into it")


func test_a_road_joins_the_cemetery_to_brindle_on_the_2d_map() -> void:
	if Places.baked():
		off("on his map the way into Brindle is his own path, drawn and walked")
		return
	var region: Region = _region()
	var route: Array[Vector2i] = Navigation.path(region, where_the_game_starts(), Region.BRINDLE)
	assert_false(route.is_empty(), "the cemetery reaches Brindle")
	var roads: int = 0
	for tile: Vector2i in route:
		if region.terrain_at(tile) == Region.Terrain.ROAD:
			roads += 1
	assert_true(roads * 2 >= route.size(), "along a road: %d of %d tiles" % [roads, route.size()])


func test_she_waits_among_the_graves_and_so_does_her_fire() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var fairy: Npc = (sim.store(&"cast") as Cast).get_npc(OpeningRules.FAIRY)
	assert_true(fairy.centre().distance_to(world.player_pos) <= Game.TALK_REACH, "she is beside you when you wake")
	var fire: Vector2i = world.region().nearest_campfire(where_the_game_starts(), 4.0)
	assert_ne(fire, Region.NOWHERE, "her fire is among the graves")
	assert_true(Vector2(fire).distance_to(Vector2(where_the_game_starts())) > 2.2,
		"and not so close that the first key rests you instead of hearing her")


# --------------------------------------------------- where Bram calls from (O14) ---
#
# The ground the hail fires in, on each world: the rows `hails` in places.json holds —
# two discs side by side since the review, across the village's south edge, which every shortest way north crosses.
#
# **Not a wall round the start.** The plan asked that the start could not reach
# Brindle or the bridge with the zone dammed. That held for the cove it was written
# for; O12 put the graves on open meadow instead, and his wood is walkable all round,
# so no disc could be passed only through. What matters is that the way a person walks
# out of the graves — the way the walkers and the tests walk it — goes through it.

func _the_hail() -> Array[Dictionary]:
	return Places.shared().hails()


func test_the_hail_is_not_where_you_wake() -> void:
	var hail: Array[Dictionary] = _the_hail()
	assert_eq(hail.size(), 2, "his ground is two discs")
	var region: Region = _region()
	for row: Dictionary in hail:
		assert_ne(row["at"], Region.NOWHERE, "%s resolves" % row["point"])
		# He walks down from his post to meet you, and has the table's time to do it.
		var walk: Array[Vector2i] = HailRules.approach(region, Places.shared().point(&"bram_post"), row["at"] as Vector2i)
		assert_false(walk.is_empty(), "he can walk from his post to %s" % row["point"])
		assert_true(walk.size() * WalkerRules.steps_per_tile() + HailRules.spotted_steps() <= HailRules.budget_steps(),
			"within the time he has: %d tiles" % walk.size())
	assert_false(HailRules.in_sight_of_any(hail, where_the_game_starts()), "you wake outside it")
	assert_false(HailRules.in_sight_of_any(hail, Region.BRINDLE), "and so is the village's heart, where tests and frames stand")
	assert_false(HailRules.in_sight_of_any(hail, Vector2i(in_town(&"brindle"))), "and where a test stands in the village")


func test_no_pack_stands_in_the_hail() -> void:
	# A pack would set upon somebody the hail is holding still. A fire may stand in it:
	# to wake at one you must have rested there, and to rest there you walked in and
	# were called (content/hail.json).
	var region: Region = _region()
	var hail: Array[Dictionary] = _the_hail()
	for tile: Vector2i in Wild.new().standing(region).keys():
		assert_false(HailRules.in_sight_of_any(hail, tile), "a pack at %s is out of it" % tile)


## Moves from one tile to another by the navigation's own step rule, keeping out of the
## tiles `dammed` says, or -1 when there is no way.
func _moves(region: Region, from: Vector2i, to: Vector2i, dammed: Callable) -> int:
	var seen: Dictionary = {from: 0}
	var queue: Array[Vector2i] = [from]
	var head: int = 0
	while head < queue.size():
		var tile: Vector2i = queue[head]
		head += 1
		if tile == to:
			return int(seen[tile])
		for step: Vector2i in Navigation.DIRECTIONS:
			var next: Vector2i = tile + step
			if seen.has(next) or bool(dammed.call(next)) or not Navigation._can_step(region, tile, step):
				continue
			seen[next] = int(seen[tile]) + 1
			queue.append(next)
	return -1


func test_every_shortest_way_out_of_the_graves_walks_into_the_hail() -> void:
	# **Every one, not the one Navigation happens to pick** (the review of O13–O16): a
	# 3.5 disc grazed the tested walk while an equally short one passed it by. So the
	# ground is dammed and the walk must come out longer, or not at all.
	var region: Region = _region()
	var hail: Array[Dictionary] = _the_hail()
	var goals: Array[Vector2i] = [Region.BRINDLE, Region.BRIDGE]
	if not Places.baked():
		# On his map the works lie north through the village; on the 2D map the graves
		# are west of Brindle, on the way to the bridge, and the walk there never enters it.
		off("on the 2D map the graves lie between Brindle and the bridge")
		goals = [Region.BRINDLE]
	var open: Callable = func(_tile: Vector2i) -> bool: return false
	var watched: Callable = func(tile: Vector2i) -> bool: return HailRules.in_sight_of_any(hail, tile)
	for goal: Vector2i in goals:
		var shortest: int = _moves(region, where_the_game_starts(), goal, open)
		assert_true(shortest > 0, "the graves reach %s" % goal)
		var round: int = _moves(region, where_the_game_starts(), goal, watched)
		assert_true(round == -1 or round > shortest,
			"no walk to %s as short as %d moves keeps out of his sight: %d" % [goal, shortest, round])


func test_his_trail_into_the_village_runs_through_the_hail() -> void:
	# A player on the road his brother drew — up from the coast past the graves into the
	# village — walks into it too.
	if not Places.baked():
		off("the 2D map's road into Brindle is ours, and is the shortest walk already")
		return
	var region: Region = _region()
	var hail: Array[Dictionary] = _the_hail()
	# His trail on the start's own row, west of the graves, where it comes up from the coast.
	var south: Vector2i = where_the_game_starts()
	while south.x > 0 and region.terrain_at(south) != Region.Terrain.ROAD:
		south.x -= 1
	var post: Vector2i = Places.shared().point(&"bram_post")
	assert_eq(region.terrain_at(south), Region.Terrain.ROAD, "his trail passes beside the graves")
	assert_eq(region.terrain_at(post), Region.Terrain.ROAD, "and through Bram's post")
	var off_trail_or_watched: Callable = func(tile: Vector2i) -> bool:
		return region.terrain_at(tile) != Region.Terrain.ROAD or HailRules.in_sight_of_any(hail, tile)
	assert_true(_moves(region, south, post, func(t: Vector2i) -> bool: return region.terrain_at(t) != Region.Terrain.ROAD) > 0,
		"the trail runs from beside the graves to his post")
	assert_eq(_moves(region, south, post, off_trail_or_watched), -1,
		"and cannot be walked along out of his sight")


# ------------------------------------------------------------ the walk in ---

func test_the_walk_from_the_graves_into_the_ruins_is_short() -> void:
	# §4's rule against empty walking. Since O12 the graves are the village's own, at
	# its edge, so the walk into the ruins is a few seconds at the world's own pace and
	# never the content.
	var tiles: float = Vector2(where_the_game_starts()).distance_to(Vector2(Region.BRINDLE))
	var seconds: float = tiles / MovementRules.tiles_per_second()
	assert_true(seconds <= 15.0,
		"the graves to Brindle's heart is %.1f tiles, %.1f seconds" % [tiles, seconds])


# ------------------------------------------------------- what it must not break ---

func test_the_king_is_still_reachable_from_the_first_minute() -> void:
	# Pillar 1. Starting in the wood may not put the castle further away than
	# "minutes, not hours", and the straight line is the number that says so.
	var region: Region = _region()
	var seconds: float = region.start_to_blackcairn_tiles() / 6.0
	assert_true(seconds < 90.0,
		"the start is %.0f tiles from Blackcairn, %.0f seconds" % [
			region.start_to_blackcairn_tiles(), seconds])


func test_every_zone_is_still_reachable_from_where_the_player_wakes() -> void:
	# The rule attached to the thicket: it may never be the only thing between the
	# player and anything. Eight zones, walked from where you wake, over ground.
	var region: Region = _region()
	var open: Dictionary = _reachable(region, where_the_game_starts(), [] as Array[Vector2i])
	for zone: StringName in Region.ZONE_ORDER:
		var site: Vector2i = Region.zone_sites().get(zone, Region.NOWHERE)
		if site == Region.NOWHERE:
			continue
		assert_true(open.has(site), "%s is reachable from where the player wakes" % zone)


func test_the_furnaces_are_in_frame_when_you_reach_the_ruins() -> void:
	# The image the opening rests on, and the reason no exposition is needed: the
	# crime and the industry it served in one frame. Checked against the viewport,
	# 640x360 at 16px a tile, so 40 x 22.5 tiles and half of that either side.
	# The *nearest* part of the works, not its far corner: what has to be in shot is
	# some of the thing, not all of it. The first draft measured the northern edge,
	# 16 tiles up, and failed on a frame that plainly contains the furnaces.
	var half := Vector2(20.0, 11.25)
	var from: Vector2 = Vector2(Region.BRINDLE)
	var near := Vector2(
		clampf(from.x, float(Region.CINDERWORKS.x - Region.CINDERWORKS_SIZE.x / 2),
			float(Region.CINDERWORKS.x + Region.CINDERWORKS_SIZE.x / 2)),
		clampf(from.y, float(Region.CINDERWORKS.y - Region.CINDERWORKS_SIZE.y / 2),
			float(Region.CINDERWORKS.y + Region.CINDERWORKS_SIZE.y / 2)))
	var in_frame: bool = absf(from.x - near.x) < half.x and absf(from.y - near.y) < half.y
	if not in_frame and Places.baked():
		# On the 3D map the works stand a hundred tiles from Brindle. That is the brief's
		# first line (MIGRATION_3D §5) and the map's to settle, not this suite's to fail on.
		debt("the nearest of the works is %.0f,%.0f tiles from Brindle's centre; §4 wants the furnaces in the first frame (%.0f x %.0f)"
			% [absf(from.x - near.x), absf(from.y - near.y), half.x * 2.0, half.y * 2.0])
		return
	assert_true(in_frame,
		"the nearest of the works is %.0f,%.0f tiles from Brindle's centre, in a %.0f x %.0f frame"
			% [absf(from.x - near.x), absf(from.y - near.y), half.x * 2.0, half.y * 2.0])


# ------------------------------------------------- stage 4: the first fire ---

func test_the_fairies_ground_is_the_first_fire() -> void:
	# The save the game opens on, and it earns the place twice: the ground that can
	# hold you is the ground still held, and it gives the player a reason to come
	# back — which is the only way the shrinking can be *seen* rather than asserted.
	var region: Region = _region()
	assert_ne(region.nearest_campfire(where_the_game_starts(), 4.0), Region.NOWHERE,
		"there is a fire where you wake")


func test_dying_before_you_ever_rest_puts_you_back_where_you_woke() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	world.player_pos = world.region().brindle_centre()
	assert_eq(world.rested_at, Vector2i(-1, -1), "nobody has slept yet")
	world.hurt(WorldState.MAX_HP, sim.step)
	assert_eq(world.player_pos, world.region().start_centre(),
		"back where you woke, not in the ruins")


# ------------------------------------------ stage 2: the wood they still hold ---

func test_the_wood_gets_smaller_while_the_furnaces_run() -> void:
	var held: float = WorldRules.HELD_AT_START
	for _tick: int in Game.TICKS_PER_IN_GAME_DAY * 10:
		held = WorldRules.held_ground_after(held, 100.0)
	assert_true(held < WorldRules.HELD_AT_START - 4.0,
		"ten days of the works running flat out took %.1f tiles" % (WorldRules.HELD_AT_START - held))
	assert_true(held > 0.0, "and did not finish it: %.1f left" % held)


func test_putting_the_furnaces_out_stops_the_wood_shrinking() -> void:
	# The point of driving it off steel output rather than the calendar. Stopping
	# the felling is already something the player can do with the levers they have,
	# so "save us" is not a request the game cannot answer (§19 Q42/Q43 deferred).
	var held: float = WorldRules.HELD_AT_START
	for _tick: int in Game.TICKS_PER_IN_GAME_DAY * 10:
		held = WorldRules.held_ground_after(held, 0.0)
	assert_eq(held, WorldRules.HELD_AT_START, "nothing running, nothing taken")


func test_the_wood_shrinking_can_never_end_a_reign() -> void:
	# §8's hard rule. Drift may move the world; only the player may end it. This is
	# drift, so it writes no handprint and no ending can read it.
	var sim: Sim = Game.build()
	var ticked := sim.store(&"worldtick") as WorldTick
	sim.advance(60 * 30)
	assert_true(ticked.held_ground < WorldRules.HELD_AT_START, "the wood did shrink")
	assert_eq(ticked.handprint_on(&"held_ground"), 0.0, "and none of it was the player's doing")


# ------------------------------------------------- stage 3: she speaks ---

func _wake_and_listen(sim: Sim, times: int) -> Array[String]:
	var world := sim.store(&"world") as WorldState
	sim.submit(&"talk", {"npc": "fairy"})
	sim.advance(2)
	var heard: Array[String] = []
	for _round: int in times:
		if world.options.is_empty():
			break
		assert_eq(world.options.size(), 1,
			"she offers exactly one thing to do, which is listen")
		sim.submit(&"choose_intent", {"intent": String(world.options[0].intent)})
		sim.advance(2)
		heard.append(world.current_line)
	return heard


func test_she_is_standing_there_when_you_wake() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	var her: Npc = cast.get_npc(&"fairy")
	assert_not_null(her, "there is a fairy")
	assert_true(her.centre().distance_to(world.player_pos) <= Game.TALK_REACH,
		"within reach of where the player wakes, without walking anywhere")
	# She is light and movement, never a body (§4). The way that is enforced is that
	# nothing casts her: `Art` draws whoever is in `CASTING` from a character sheet,
	# and a fairy with a face would be a twinkling humanoid, which is the one thing
	# the opening must not be.
	assert_false(Art.CASTING.has(&"fairy"), "and nobody has given her a face")


func test_she_says_seven_things_one_at_a_time_and_in_order() -> void:
	var sim: Sim = Game.build()
	Text.set_locale("en")
	var heard: Array[String] = _wake_and_listen(sim, 9)
	assert_eq(heard.size(), OpeningRules.WHAT_SHE_TELLS_YOU.size(),
		"seven lines, and then nothing more to say")
	assert_true(heard[0].contains("died"), "she opens with the thing only she can tell you")
	assert_true(heard[heard.size() - 1].contains("save us"), "and closes by asking")


func test_everything_she_tells_you_is_in_the_fact_base() -> void:
	var sim: Sim = Game.build()
	_wake_and_listen(sim, 9)
	for fact: StringName in OpeningRules.WHAT_SHE_TELLS_YOU:
		assert_true(sim.facts.has(fact), "the player knows '%s'" % fact)


func test_she_never_has_the_political_map() -> void:
	# The restriction the whole opening rests on. A fairy in a wood knows men came
	# with axes; she does not know whose men. If she pre-judges him in minute one,
	# Route C stops working, because §5 holds that his argument has to be real and
	# found. Asserted rather than trusted, in both languages.
	for language: String in ["en", "fr"]:
		var cast: Cast = Cast.load_from(Cast.path_for(language))
		var her: Npc = cast.get_npc(&"fairy")
		var lines: Array[String] = [her.greeting]
		for option: DialogueOption in her.options:
			lines.append(option.reply)
		for line: String in lines:
			for word: String in line.to_lower().replace(".", " ").replace(",", " ").split(" ", false):
				var bare: String = ProseRules.bare_word(word)
				assert_false(OpeningRules.SHE_MAY_NEVER_SAY.has(bare),
					"%s: she says '%s' in \"%s\"" % [language, bare, line])


func test_she_is_gone_once_she_has_finished_and_stays_gone() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	assert_true(OpeningRules.fairy_is_here(sim.facts), "she is here to begin with")
	_wake_and_listen(sim, 9)
	sim.submit(&"end_talk")
	sim.advance(2)
	assert_false(OpeningRules.fairy_is_here(sim.facts), "and gone when she has finished")

	sim.submit(&"talk", {"npc": "fairy"})
	sim.advance(2)
	assert_false(world.in_dialogue(), "walking back does not find her again")


func test_walking_away_leaves_her_there_because_nothing_is_gated() -> void:
	# Pillar 1. You may ignore her entirely and walk to Blackcairn, and she will
	# still be where you woke when you come back — so the premise is never lost,
	# and it is never forced on you either.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	_wake_and_listen(sim, 3)
	sim.submit(&"end_talk")
	sim.advance(2)
	world.player_pos = world.region().brindle_centre()
	sim.advance(120)
	assert_true(OpeningRules.fairy_is_here(sim.facts), "she has not finished, so she waits")
	# Back to her, wherever she stands.
	world.player_pos = (sim.store(&"cast") as Cast).get_npc(OpeningRules.FAIRY).centre()
	var rest: Array[String] = _wake_and_listen(sim, 9)
	assert_eq(rest.size(), OpeningRules.WHAT_SHE_TELLS_YOU.size() - 3,
		"and picks up where she left off")


func test_the_whole_opening_replays_from_the_log() -> void:
	# It is a conversation, not a cutscene: every line is an ordinary event, so the
	# scene is in the save and a reload says the same words in the same order.
	var sim: Sim = Game.build()
	_wake_and_listen(sim, 9)
	var replayed: Sim = Game.replay(sim)
	assert_eq(replayed.facts.fingerprint(), sim.facts.fingerprint(),
		"rebuilt from the log, down to what she told you")
	assert_false(OpeningRules.fairy_is_here(replayed.facts), "and she is gone there too")


# -------------------------------- stage 5: what you did to the wood ---

func test_the_journal_says_nothing_about_a_wood_you_have_not_heard_of() -> void:
	# A journal that explains a thing the player has never been told is the game
	# telling them their own story. She has to say it first.
	var sim: Sim = Game.build()
	assert_false(OpeningRules.knows_about_the_wood(sim.facts), "nothing yet")
	_wake_and_listen(sim, 9)
	assert_true(OpeningRules.knows_about_the_wood(sim.facts), "and now she has said it")


func test_the_page_says_how_much_is_left_and_whether_it_is_still_going() -> void:
	var sim: Sim = Game.build()
	var ticked := sim.store(&"worldtick") as WorldTick
	var running: Dictionary = OpeningRules.wood_row(ticked)
	assert_eq(int(running["paces"]), int(round(WorldRules.HELD_AT_START)), "all of it, at the start")
	assert_true(bool(running["falling"]), "and the furnaces are running")

	ticked.steel_output = 0.0
	assert_false(bool(OpeningRules.wood_row(ticked)["falling"]),
		"put them out and nothing is taking it")

	ticked.held_ground = 0.0
	assert_true(bool(OpeningRules.wood_row(ticked)["gone"]), "and it can run out")


func test_an_ending_reads_differently_depending_on_what_became_of_the_wood() -> void:
	# The proof for this stage, and the reason her last line is not empty. "If you
	# can, save us" is answerable with the levers the player already has, and this
	# is where they find out whether they did it.
	Text.set_locale("en")
	var saved: String = Text.of(&"journal.wood.saved")
	var lost: String = Text.of(&"journal.wood.lost")
	assert_ne(saved, lost, "the two endings do not read the same")
	assert_true(saved.contains("you did"), "one says you did it")
	assert_true(lost.contains("nobody did"), "the other says nobody did")


func test_the_wood_page_never_gives_advice() -> void:
	# Same rule as §15's second page: state and attribution only. It may say the
	# furnaces are running and that the wood is going; it may never say to go and
	# put them out.
	var forbidden: Array[String] = ["should", "try ", "next", "you must", "in order to", "tip"]
	for language: String in ["en", "fr"]:
		Text.set_locale(language)
		for key: StringName in [&"journal.wood", &"journal.wood.falling",
				&"journal.wood.holding", &"journal.wood.gone",
				&"journal.wood.saved", &"journal.wood.lost"]:
			for phrase: String in forbidden:
				assert_false(Text.of(key).to_lower().contains(phrase),
					"%s: '%s' says \"%s\"" % [language, key, Text.of(key)])
	Text.set_locale("en")
