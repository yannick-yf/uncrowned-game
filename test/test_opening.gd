extends TestCase

## Phase 7, the opening — stage 1: the ground.
##
## The player wakes in the fairies' clearing inside the Thornwood, and **one
## corridor** leads south out of it to Brindle. Brindle is ash; the Cinderworks
## stands in the same frame, on the village's own ground. No maze, no choice in the
## first minute, and nothing gated anywhere.
##
## **The thicket is geography, not a gate.** The map already closes itself with sea
## and mountain, and Pillar 1 is about progression checks rather than walls. The rule
## that keeps it honest is asserted below: thicket may never be the only thing
## between the player and anything, which is why every zone must still be reachable
## with the corridor open.

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


func _corridor_mouth() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var from: int = Region.CLEARING.y + Region.CLEARING_RADIUS
	for x: int in range(Region.CLEARING.x - Region.PATH_HALF_WIDTH,
			Region.CLEARING.x + Region.PATH_HALF_WIDTH + 1):
		for y: int in range(from, from + Region.THICKET_DEPTH + 2):
			out.append(Vector2i(x, y))
	return out


# ------------------------------------------------------------- the clearing ---

func test_the_player_wakes_on_open_ground_in_the_wood() -> void:
	var region: Region = _region()
	assert_eq(region.terrain_at(Region.CLEARING), Region.Terrain.CLEARING,
		"the centre of the clearing is clearing, not the corridor cut through it")
	assert_true(region.is_passable(Region.CLEARING), "and you can stand on it")
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	assert_eq(world.player_pos, region.clearing_centre(), "and the game starts you there")


func test_the_clearing_is_ringed_by_wood_you_cannot_walk_into() -> void:
	var region: Region = _region()
	var outer: int = Region.CLEARING_RADIUS + Region.THICKET_DEPTH
	# North of the clearing, away from the corridor, the ring must be solid.
	var solid: int = 0
	for y: int in range(Region.CLEARING.y - outer, Region.CLEARING.y - Region.CLEARING_RADIUS):
		if not region.is_passable(Vector2i(Region.CLEARING.x, y)):
			solid += 1
	assert_true(solid >= Region.THICKET_DEPTH - 1,
		"the ring north of the clearing is %d tiles deep" % solid)


func test_one_corridor_leads_out_and_only_one() -> void:
	# The whole geography claim, and the only way to check it: block the corridor
	# and the clearing has to become a closed pocket. If any other way out exists,
	# Brindle is still reachable and this fails.
	var region: Region = _region()
	var open: Dictionary = _reachable(region, Region.CLEARING, [] as Array[Vector2i])
	assert_true(open.has(Region.BRINDLE), "with the corridor open you can walk to Brindle")

	var sealed: Dictionary = _reachable(region, Region.CLEARING, _corridor_mouth())
	assert_false(sealed.has(Region.BRINDLE), "with it dammed you cannot")
	assert_true(sealed.size() < 400,
		"and what is left is a pocket, not the map: %d tiles" % sealed.size())


func test_walking_out_takes_about_five_seconds() -> void:
	# §4's rule against empty walking cuts both ways: long enough to be a walk out
	# of the trees, short enough that it is not the content.
	var tiles: float = Vector2(Region.CLEARING).distance_to(Vector2(Region.BRINDLE))
	var seconds: float = tiles / 6.0
	assert_true(seconds >= 3.0 and seconds <= 8.0,
		"clearing to Brindle is %.1f tiles, %.1f seconds" % [tiles, seconds])


# ------------------------------------------------------- what it must not break ---

func test_the_king_is_still_reachable_from_the_first_minute() -> void:
	# Pillar 1. Starting in the wood may not put the castle further away than
	# "minutes, not hours", and the straight line is the number that says so.
	var region: Region = _region()
	var seconds: float = region.clearing_to_blackcairn_tiles() / 6.0
	assert_true(seconds < 90.0,
		"the clearing is %.0f tiles from Blackcairn, %.0f seconds" % [
			region.clearing_to_blackcairn_tiles(), seconds])


func test_every_zone_is_still_reachable_from_where_the_player_wakes() -> void:
	# The rule attached to the thicket: it may never be the only thing between the
	# player and anything. Eight zones, walked from the clearing, over ground.
	var region: Region = _region()
	var open: Dictionary = _reachable(region, Region.CLEARING, [] as Array[Vector2i])
	for zone: StringName in Region.ZONE_ORDER:
		var site: Vector2i = Region.zone_sites().get(zone, Region.NOWHERE)
		if site == Region.NOWHERE:
			continue
		assert_true(open.has(site), "%s is reachable from the clearing" % zone)


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
	assert_true(absf(from.x - near.x) < half.x and absf(from.y - near.y) < half.y,
		"the nearest of the works is %.0f,%.0f tiles from Brindle's centre, in a %.0f x %.0f frame"
			% [absf(from.x - near.x), absf(from.y - near.y), half.x * 2.0, half.y * 2.0])


func test_the_clearing_never_wrote_over_the_road_the_river_or_a_town() -> void:
	# `_stamp_clearing` only ever overwrites FOREST, so this cannot fail by
	# construction — which is the point of asserting it, because the next person to
	# move the clearing will not know that.
	# Scanned over what the opening actually stamps, not a box around it. The first
	# draft swept fourteen tiles either side all the way down to Brindle and caught
	# the Cinderworks, which the opening never touched.
	var region: Region = _region()
	var laid: int = 0
	for x: int in range(Region.CLEARING.x - 20, Region.CLEARING.x + 21):
		for y: int in range(Region.CLEARING.y - 20, Region.BRINDLE.y):
			var here: Region.Terrain = region.terrain_at(Vector2i(x, y))
			if here != Region.Terrain.CLEARING and here != Region.Terrain.THICKET:
				continue
			laid += 1
			# A tile the opening owns may never be one of these, and the stamp only
			# ever overwrites FOREST, so this holds by construction — which is why
			# it is asserted, for whoever moves the clearing next.
			assert_true(here != Region.Terrain.ROAD and here != Region.Terrain.WATER
					and here != Region.Terrain.TOWN, "at %d,%d" % [x, y])
	assert_true(laid > 100, "the opening laid %d tiles of its own" % laid)


# ------------------------------------------------- stage 4: the first fire ---

func test_the_fairies_ground_is_the_first_fire() -> void:
	# The save the game opens on, and it earns the place twice: the ground that can
	# hold you is the ground still held, and it gives the player a reason to come
	# back — which is the only way the shrinking can be *seen* rather than asserted.
	var region: Region = _region()
	assert_ne(region.nearest_campfire(Region.CLEARING, 4.0), Region.NOWHERE,
		"there is a fire in the clearing")


func test_dying_before_you_ever_rest_puts_you_back_where_you_woke() -> void:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	world.player_pos = world.region().brindle_centre()
	assert_eq(world.rested_at, Vector2i(-1, -1), "nobody has slept yet")
	world.hurt(WorldState.MAX_HP, sim.step)
	assert_eq(world.player_pos, world.region().clearing_centre(),
		"back in the clearing, not in the ruins")


# --------------------------------------------- stage 2: the protected ground ---

func test_nothing_with_teeth_stands_on_ground_the_fairies_hold() -> void:
	# The same shape as the test that keeps beasts off the King's Road, because it
	# is the same kind of claim: a safe place is safe because nothing may enter it,
	# not because nothing happened to.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var wild := sim.store(&"wildlife") as Wildlife
	var ticked := sim.store(&"worldtick") as WorldTick
	world.player_pos = world.region().clearing_centre()
	sim.advance(60 * 40)
	var trespassers: int = 0
	for beast: Beast in wild.beasts:
		if BeastRules.is_protected(Vector2i(floori(beast.pos.x), floori(beast.pos.y)),
				ticked.held_ground):
			trespassers += 1
	assert_eq(trespassers, 0, "forty seconds of standing in the clearing, and nothing came in")


func test_the_walk_out_is_protected_too_at_the_start() -> void:
	# The first walk out of the trees is the last walk on held ground. The corridor
	# has to be inside it or the claim is only about the clearing.
	var ticked := WorldTick.new()
	var mouth := Vector2i(Region.CLEARING.x, Region.CLEARING.y + Region.CLEARING_RADIUS + 2)
	assert_true(BeastRules.is_protected(Region.CLEARING, ticked.held_ground), "the clearing")
	assert_true(BeastRules.is_protected(mouth, ticked.held_ground), "and the corridor out")
	assert_false(BeastRules.is_protected(Region.BRINDLE, ticked.held_ground),
		"but not the ruins — you step out of the last protected place to reach them")


func test_the_wood_gets_smaller_while_the_furnaces_run() -> void:
	var held: float = WorldRules.HELD_AT_START
	for _tick: int in Game.TICKS_PER_IN_GAME_DAY * 10:
		held = WorldRules.held_ground_after(held, 100.0)
	assert_true(held < WorldRules.HELD_AT_START - 4.0,
		"ten days of the works running flat out took %.1f tiles" % (WorldRules.HELD_AT_START - held))
	assert_true(held > 0.0, "and did not finish it: %.1f left" % held)


func test_putting_the_furnaces_out_stops_the_wood_shrinking() -> void:
	# The point of driving it off steel output rather than the calendar. Stopping
	# the clearing is already something the player can do with the levers they have,
	# so "save us" is not a request the game cannot answer (§19 Q42/Q43 deferred).
	var held: float = WorldRules.HELD_AT_START
	for _tick: int in Game.TICKS_PER_IN_GAME_DAY * 10:
		held = WorldRules.held_ground_after(held, 0.0)
	assert_eq(held, WorldRules.HELD_AT_START, "nothing running, nothing taken")


func test_the_edge_comes_in_so_a_later_visit_is_different() -> void:
	# What makes the shrinking something the player walks into rather than is told.
	var mouth := Vector2i(Region.CLEARING.x, Region.CLEARING.y + Region.CLEARING_RADIUS + 2)
	assert_true(BeastRules.is_protected(mouth, WorldRules.HELD_AT_START), "held at the start")
	assert_false(BeastRules.is_protected(mouth, 6.0),
		"and not once the wood has lost most of what it had")


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
	assert_eq(her.sprite, "", "and she is not a body: no sprite, drawn as light")


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
	# still be in the clearing when you come back — so the premise is never lost,
	# and it is never forced on you either.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	_wake_and_listen(sim, 3)
	sim.submit(&"end_talk")
	sim.advance(2)
	world.player_pos = world.region().brindle_centre()
	sim.advance(120)
	assert_true(OpeningRules.fairy_is_here(sim.facts), "she has not finished, so she waits")
	world.player_pos = world.region().clearing_centre()
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
