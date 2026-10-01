extends TestCase

## The screens in front of the world: the title, the character, and the pause.
##
## These are `view/` files, which the suite normally leaves alone — but three of the
## things that can go wrong here are invisible until someone looks at the running
## game, and two of them are silent forever:
##
## - a menu row whose text key was never written, which draws as `title.quti`;
## - a line using a character the pack's font has no glyph for, which draws in
##   whatever typeface the operating system supplies;
## - a character creation screen that can hand the simulation an illegal set of
##   traits, which `CreationSystem` refuses — leaving a player who pressed Begin
##   in a world where nothing happened.
##
## Every screen is instantiated for real and its own table read, rather than a copy of
## the table being kept here. A list in a test is a list that goes stale.


func _screen(path: String) -> Node:
	return (load(path) as GDScript).new() as Node


## Every row of every menu in the game, gathered by building the menus.
func _all_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []

	var title: Node = _screen("res://view/title.gd")
	title.call(&"_build")
	rows.append_array((title.get(&"_menu") as Menu).rows)
	title.call(&"_ask")
	rows.append_array((title.get(&"_asking") as Menu).rows)
	title.free()

	var creation: Node = _screen("res://view/creation.gd")
	creation.call(&"_build")
	rows.append_array((creation.get(&"_look_menu") as Menu).rows)
	rows.append_array((creation.get(&"_talent_menu") as Menu).rows)
	creation.free()

	var play: Node = _screen("res://view/main.gd")
	play.call(&"_pause_menu")
	rows.append_array((play.get(&"_paused") as Menu).rows)
	play.free()

	return rows


func test_every_menu_row_has_a_line_in_both_languages() -> void:
	var rows: Array[Dictionary] = _all_rows()
	assert_true(rows.size() >= 15, "%d menu rows found across the screens" % rows.size())
	for language: String in ["en", "fr"]:
		var known: Array[String] = Text.keys_for(language)
		for row: Dictionary in rows:
			var key: String = String(row.get("key", &""))
			assert_true(known.has(key), "%s has no line for '%s'" % [language, key])


func test_no_row_is_missing_its_id() -> void:
	# A row without an id is a row the screen will silently do nothing about.
	for row: Dictionary in _all_rows():
		assert_ne(String(row.get("id", &"")), "", "a row has no id: %s" % row)


# -------------------------------------------------------------------- menu ---

func test_the_cursor_skips_rows_it_cannot_sit_on() -> void:
	# Continue before there is a save: on screen, so the player learns the game has
	# one, and never under the cursor.
	var menu := Menu.new([
		{"id": &"continue", "key": &"title.continue", "enabled": false},
		{"id": &"new", "key": &"title.new"},
		{"id": &"quit", "key": &"title.quit"},
	])
	assert_eq(String(menu.chosen()), "new", "it opens on the first row it can use")
	menu.move(-1)
	assert_eq(String(menu.chosen()), "quit", "up from the top wraps past the disabled one")
	menu.move(1)
	assert_eq(String(menu.chosen()), "new", "and down again comes back")


func test_a_menu_with_nothing_to_pick_picks_nothing() -> void:
	var menu := Menu.new([{"id": &"continue", "key": &"title.continue", "enabled": false}])
	assert_eq(String(menu.chosen()), "", "no row, no choice")
	assert_false(menu.move(1), "and nowhere to move to")


func test_the_cursor_can_be_put_on_a_row_by_name() -> void:
	var menu := Menu.new([
		{"id": &"continue", "key": &"title.continue"},
		{"id": &"new", "key": &"title.new"},
	])
	assert_true(menu.point_at(&"new"), "asked for a row that is there")
	assert_eq(String(menu.chosen()), "new")
	assert_false(menu.point_at(&"nothing"), "and one that is not")
	assert_eq(String(menu.chosen()), "new", "which leaves the cursor alone")


func test_a_single_row_does_not_pretend_to_move() -> void:
	# What the sound cue hangs on: a menu that clicks when nothing moved is worse
	# than one that is silent.
	var menu := Menu.new([{"id": &"resume", "key": &"pause.resume"}])
	assert_false(menu.move(1), "one row, nowhere to go")


# ---------------------------------------------------------------- the font ---

func test_the_game_draws_in_the_packs_own_typeface() -> void:
	assert_true(FileAccess.file_exists(Ui.SOURCE_FONT), "the pack's face is where Ui says")
	var font: FontVariation = Ui.font() as FontVariation
	assert_not_null(font, "and the widened version of it loads")
	assert_eq(font.base_font.resource_path, Ui.SOURCE_FONT,
		"what the game draws with is that face and not another one")
	# Two ways to reach it — Labels take it from the project, everything drawn by hand
	# takes it from Ui — so they have to name one file.
	assert_eq(String(ProjectSettings.get_setting("gui/theme/custom_font", "")), Ui.FONT,
		"the project's default font is the one Ui hands out")


func test_a_space_is_wide_enough_to_be_a_space() -> void:
	# The bug this was written for: the pack's own space is a tenth of an em, so
	# "Nouvelle partie" drew as "Nouvellepartie" and nothing failed.
	for size: int in [Ui.NOTE, Ui.BODY, Ui.ROW, Ui.LARGE]:
		var gap: float = Ui.width_of("n n", size) - Ui.width_of("nn", size)
		assert_true(gap >= float(size) * 0.2,
			"at %d a space is %d wide, which is not a gap" % [size, gap])


func test_nothing_the_player_reads_needs_a_glyph_the_font_lacks() -> void:
	# Godot silently substitutes a system font for a missing glyph, so one bullet in
	# the wrong typeface is the only symptom, and nobody notices it in a screenshot.
	for language: String in ["en", "fr"]:
		var table: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string(Text.PATH % language)) as Dictionary
		for key: String in table.keys():
			assert_eq(Ui.missing_glyph(String(table[key])), "",
				"%s '%s' uses a character the pack's font has no glyph for" % [language, key])
		var cast: Cast = Cast.load_from(Cast.path_for(language))
		for npc: Npc in cast.named():
			var lines: PackedStringArray = PackedStringArray([npc.display_name, npc.role])
			for option: DialogueOption in npc.options:
				lines.append(option.text)
				lines.append(option.reply)
			for band: StringName in npc.reactions.keys():
				lines.append(String(npc.reactions[band]))
			for line: String in lines:
				assert_eq(Ui.missing_glyph(line), "",
					"%s %s: a line uses a character the font has no glyph for"
						% [language, npc.id])


# ------------------------------------------------------------ making a man ---

func test_creation_cannot_spend_a_point_it_does_not_have() -> void:
	var creation: Node = _screen("res://view/creation.gd")
	creation.call(&"_build")
	# Pour the whole pool into the first trait the cursor can reach, then keep
	# pressing. §11's cap stops it at 5 and the pool stops the rest.
	for _press: int in 40:
		creation.call(&"_spend", 1)
		(creation.get(&"_talent_menu") as Menu).move(1)
	var levels: Dictionary = creation.get(&"_levels") as Dictionary
	assert_true(TraitRules.is_legal(levels),
		"no sequence of presses builds an illegal character: %s" % levels)
	assert_eq(TraitRules.spent(levels), TraitRules.POOL, "and the pool is what is spent")
	creation.free()


func test_begin_is_closed_until_the_last_point_is_placed() -> void:
	var creation: Node = _screen("res://view/creation.gd")
	creation.call(&"_build")
	var menu: Menu = creation.get(&"_talent_menu") as Menu
	assert_false(menu.point_at(&"begin"),
		"with ten points unspent the cursor cannot even reach Begin")
	for _press: int in TraitRules.POOL:
		creation.call(&"_spend", 1)
		if TraitRules.spent(creation.get(&"_levels") as Dictionary) % 4 == 0:
			menu.move(1)
	menu = creation.get(&"_talent_menu") as Menu
	assert_eq(TraitRules.spent(creation.get(&"_levels") as Dictionary), TraitRules.POOL,
		"ten presses, ten points")
	assert_true(menu.point_at(&"begin"), "and now Begin is a row you can sit on")
	creation.free()


func test_a_character_made_on_the_screen_is_one_the_simulation_accepts() -> void:
	# The whole screen, end to end, without a window: the event it submits is the
	# event the system checks, and the traits that come out are the ones chosen.
	var creation: Node = _screen("res://view/creation.gd")
	creation.call(&"_build")
	var levels: Dictionary = creation.get(&"_levels") as Dictionary
	levels[TraitRules.INTELLIGENCE] = 5
	levels[TraitRules.PRESENCE] = 4
	var sim: Sim = Game.build()
	var data: Dictionary = {}
	for what: StringName in TraitRules.ALL:
		data[String(what)] = int(levels[what])
	sim.submit(&"create_character", data)
	sim.advance(1)
	var traits := sim.store(&"traits") as Traits
	assert_true(traits.chosen, "the run has a person in it")
	assert_eq(traits.level_of(TraitRules.INTELLIGENCE), 5, "who is the one that was chosen")
	assert_true(traits.speaks_with(TraitRules.PRESENCE), "and speaks with what they took")
	creation.free()


# ------------------------------------------------- where the game opens (S2) ---

func _opens(debug: bool, screen: String = "", shot: String = "", quick: String = "") -> StringName:
	var screens: GDScript = load("res://view/screens.gd") as GDScript
	return screens.call(&"first_screen", debug, screen, shot, quick) as StringName


func test_the_public_build_opens_on_the_title() -> void:
	# **S2, 2026-09-28.** The demo opens on creation, so the public build passes through
	# the title and never drops a stranger into the world at the floor of every trait.
	assert_eq(_opens(false), &"title", "a release build opens on the title")
	assert_eq(_opens(false, "play", "/tmp/x.png", "1"), &"title",
		"and nothing a player can set in their environment changes that")


func test_the_quick_launch_is_a_development_path_only() -> void:
	assert_eq(_opens(true), &"title", "a debug build opens on the title too, unless asked")
	assert_eq(_opens(true, "", "", "1"), &"play", "UNCROWNED_QUICK=1 skips to the world")
	assert_eq(_opens(true, "creation"), &"creation", "and the harness still names its screen")
	assert_eq(_opens(true, "", "/tmp/x.png"), &"play", "a bare shot is still of the world")


func test_a_fresh_run_reaches_the_fairy_through_creation() -> void:
	# The check S2 names: start fresh, allocate, meet the fairy; save; Continue. Without
	# a window: the run the creation screen begins, the save it writes, and the run the
	# title's Continue reads back.
	var levels: Dictionary = TraitRules.at_the_floor()
	levels[TraitRules.STRENGTH] = 5
	levels[TraitRules.AGILITY] = 5
	var run: Sim = Game.begin_run(levels)
	var world := run.store(&"world") as WorldState
	var fairy: Npc = (run.store(&"cast") as Cast).get_npc(OpeningRules.FAIRY)
	assert_true((run.store(&"traits") as Traits).chosen, "the run has the person who was made")
	assert_true(fairy.centre().distance_to(world.player_pos) <= Game.TALK_REACH,
		"and wakes within reach of her")
	run.submit(&"talk", {"npc": "fairy"})
	run.advance(2)
	assert_true(world.in_dialogue(), "who speaks first")
	var continued: Sim = Game.replay(run)
	assert_eq((continued.store(&"traits") as Traits).fingerprint(),
		(run.store(&"traits") as Traits).fingerprint(), "and Continue rebuilds the same person")
	assert_eq((continued.store(&"world") as WorldState).fingerprint(), world.fingerprint(),
		"in the same place")


# ----------------------------------------------------------------- journal ---

## The whole play screen, wired up, so the journal's pages can be measured against the
## box they are drawn into. Freed by the caller.
##
## The scene rather than the script, because the journal is a Label inside it. And
## `_ready` by hand rather than by adding it to the tree: a `-s` tool script runs
## before the SceneTree has finished starting, so a node added to the root never
## enters it and never becomes ready. Calling it directly is exact — GDScript puts the
## `@onready` assignments inside `_ready` — and a Label resolves `$HUD/...` out of the
## tree just as well as in it.
## The play screen without his 3D window, which none of these tests look at and which
## costs a second each to build (T4). `test_world3d` builds the window.
func _flat_play() -> Node:
	var play: Node = (load("res://view/main.tscn") as PackedScene).instantiate()
	play.set(&"draws_the_world", false)
	return play


func _play_screen() -> Node:
	var play: Node = _flat_play()
	play.call(&"begin", Game.build())
	play.call(&"_ready")
	return play


func test_the_first_prompt_says_what_e_does() -> void:
	# **O2, a defect in the first frame.** The fire is in reach of where you wake and so
	# is the fairy; E talks to her, and the prompt used to offer the fire. Both now read
	# one answer to "what does E do here", so they cannot disagree again.
	var play: Node = _flat_play()
	play.call(&"begin", Game.begin_run(TraitRules.at_the_floor()))
	play.call(&"_ready")
	assert_eq(play.call(&"_what_e_does") as StringName, &"talk", "E talks to the fairy")
	play.call(&"_draw_hud")
	var prompt: String = (play.get(&"_prompt") as Label).text
	var fairy: Npc = Cast.shared().get_npc(OpeningRules.FAIRY)
	assert_true(prompt.contains(fairy.prompt_name), "and the prompt names her, mid-sentence: '%s'" % prompt)
	assert_false(prompt.contains(fairy.display_name), "not with the capital her name takes alone (the review of O21)")
	assert_false(prompt.contains(Text.of(&"prompt.rest")), "not the fire")
	play.free()


func test_the_fight_reading_carries_every_fighter() -> void:
	# **O6.** The reading named one foe, so a second wolf was never drawn where it
	# fought. Every opponent is in it now, each at the tile the duel draws it on.
	var sim: Sim = Game.build()
	sim.submit(&"duel_began", {"opponents": ["wolf", "wolf"], "by": "wolf", "asked_by": "the_wood"})
	sim.advance(1)
	var duel := sim.store(&"duel") as Duel
	assert_true(duel.on(), "two wolves are on you")
	var play: Node = _flat_play()
	play.call(&"begin", sim)
	play.call(&"_ready")
	var reading: Dictionary = play.call(&"_fight_frame") as Dictionary
	var fighters: Array = reading.get("fighters", []) as Array
	assert_eq(fighters.size(), 2, "both of them are in the reading")
	for row: Variant in fighters:
		var entry: Dictionary = row as Dictionary
		var him: DuelFighter = duel.get_fighter(StringName(String(entry["who"])))
		assert_not_null(him, "%s is a fighter" % entry["who"])
		assert_eq(entry["at"] as Vector2, duel.drawn_at(him), "%s is drawn where he stands" % entry["who"])
		assert_eq(String(entry["kind"]), "wolf", "and is a wolf")
		assert_eq(String(entry["name"]), Text.of(&"beast.wolf"), "named in the player's language")
	assert_eq(String(reading["his_name"]), Text.of(&"beast.wolf"), "the fight too, not 'Wolf#2'")
	play.free()


func test_the_reach_ring_speaks_for_whoever_is_acting() -> void:
	# Found by O6's review: the ring moved to the acting wolf, but whether it was full
	# was still measured from the first wolf.
	var sim: Sim = Game.build()
	sim.submit(&"duel_began", {"opponents": ["wolf", "wolf"], "by": "wolf", "asked_by": "the_wood"})
	sim.advance(1)
	var duel := sim.store(&"duel") as Duel
	var mine: DuelFighter = duel.me()
	var near: DuelFighter = duel.get_fighter(&"wolf")
	var far: DuelFighter = duel.get_fighter(&"wolf#2")
	near.at = mine.at + Vector2i(1, 0)
	far.at = mine.at + Vector2i(4, 0)
	var play: Node = _flat_play()
	play.call(&"begin", sim)
	play.call(&"_ready")
	duel.turn = duel.fighters.find(far)
	assert_false(bool((play.call(&"_fight_frame") as Dictionary)["in_reach"]),
		"the far wolf's ring is faint: nobody is in its reach")
	duel.turn = duel.fighters.find(near)
	assert_true(bool((play.call(&"_fight_frame") as Dictionary)["in_reach"]),
		"the near wolf's ring is full")
	near.at = mine.at + Vector2i(-4, 0)
	far.at = mine.at + Vector2i(0, 1)
	duel.turn = duel.fighters.find(mine)
	assert_true(bool((play.call(&"_fight_frame") as Dictionary)["in_reach"]),
		"and yours is full when any of them is beside you, not only the first")
	play.free()


func test_an_arrow_in_flight_is_in_the_reading_while_it_flies() -> void:
	# T5: an arrow is shot and lands on the archer's own act. The window is handed the
	# arrow while it is in the air, from her to whoever she shot, and nothing before.
	var sim: Sim = Game.build()
	sim.submit(&"duel_began", {"opponent": "wren", "by": "wren", "spar": true})
	sim.advance(1)
	var duel := sim.store(&"duel") as Duel
	var play: Node = _flat_play()
	play.call(&"begin", sim)
	play.call(&"_ready")
	var hands := DuelPlayer.new(DuelPlayer.STAND)
	var seen: int = 0
	for _step: int in 3000:
		hands.play(sim, duel)
		sim.advance(1)
		if not sim.events.of_type(&"blow_landed").is_empty():
			break
		var arrow: Dictionary = (play.call(&"_fight_frame") as Dictionary).get("arrow", {}) as Dictionary
		if arrow.is_empty():
			continue
		seen += 1
		assert_eq(arrow["to"] as Vector2, duel.drawn_at(duel.me()), "flying at you")
		assert_true(float(arrow["through"]) >= 0.0 and float(arrow["through"]) <= 1.0, "part way there")
	assert_true(seen > 0, "and it was seen in the air before it landed")
	assert_false((play.call(&"_fight_frame") as Dictionary).has("volleys"), "no tile is announced ahead")
	play.free()


func _squared_up_with_bram(has_bow: bool) -> Array:
	var sim: Sim = Game.build()
	if has_bow:
		sim.facts.add_source(DuelRules.THE_BOW, &"wren")
	sim.submit(&"duel_began", {"opponent": "bram", "by": "player", "spar": true})
	sim.advance(1)
	var play: Node = _flat_play()
	play.call(&"begin", sim)
	play.call(&"_ready")
	# The turn opens for the window as it does in play: the cursor and the weapon are set.
	play.call(&"_read_duel_input")
	return [sim, play]


func test_u_puts_the_bow_in_your_hands_and_the_reading_follows() -> void:
	# T6: the weapon is chosen on your turn, like where you stand, and the ring the window
	# draws is the reach of what you hold, round the tile you have chosen.
	var pair: Array = _squared_up_with_bram(true)
	var sim: Sim = pair[0]
	var play: Node = pair[1]
	var reading: Dictionary = play.call(&"_fight_frame") as Dictionary
	assert_eq(String(reading.get("my_weapon", "")), "sword", "the sword to begin with")
	assert_true(bool(reading.get("has_bow", false)), "and a bow of your own")
	play.call(&"_toggle_weapon")
	reading = play.call(&"_fight_frame") as Dictionary
	assert_eq(String(reading.get("my_weapon", "")), "bow", "U: the bow")
	assert_eq(int(reading.get("reach_tiles", 0)), DuelRules.bow_reach_tiles(), "its reach")
	assert_eq(int(reading.get("min_reach_tiles", 0)), DuelRules.bow_min_tiles(), "and its nearest")
	assert_true(bool(reading.get("in_reach", false)), "Bram, three tiles off, is in the band")
	play.call(&"_submit_duel_turn", &"strike")
	var turns: Array[SimEvent] = sim.events.of_type(&"duel_turn")
	var last: SimEvent = turns[turns.size() - 1]
	assert_eq(String(last.data.get("weapon", "")), "bow", "and K shoots with it")
	assert_eq(String(last.data.get("action", "")), "strike", "at him")
	play.free()


func test_without_a_bow_u_changes_nothing() -> void:
	var pair: Array = _squared_up_with_bram(false)
	var play: Node = pair[1]
	play.call(&"_toggle_weapon")
	var reading: Dictionary = play.call(&"_fight_frame") as Dictionary
	assert_eq(String(reading.get("my_weapon", "")), "sword", "still the sword")
	assert_false(bool(reading.get("has_bow", true)), "you have no bow")
	assert_false(bool(reading.get("in_reach", true)), "and he is out of its reach")
	play.free()


func test_the_tiles_offered_are_the_tiles_the_rules_take() -> void:
	# The review of T9: in Wren's lesson Bram watches from beside you, the window offered
	# his tile, and the rules refused it — the turn stayed where it was and the spell became
	# a wait.
	var sim: Sim = Game.build()
	sim.facts.add_source(OpeningRules.GIFT, &"fairy")
	var world := sim.store(&"world") as WorldState
	var walkers := sim.store(&"walkers") as Walkers
	var bram: Npc = (sim.store(&"cast") as Cast).get_npc(&"bram")
	var his: Vector2i = walkers.where(bram)
	world.player_pos = Vector2(world.region().open_near(his + Vector2i(-1, 0))) + Vector2(0.5, 0.5)
	sim.submit(&"duel_began", {"opponent": "wren", "by": "wren", "spar": true, "drill": "magic"})
	sim.advance(1)
	var duel := sim.store(&"duel") as Duel
	for _step: int in 2000:
		if duel.waiting_on_player():
			break
		sim.advance(1)
	assert_eq(duel.master_at, his, "Bram watches from his post")
	var play: Node = _flat_play()
	play.call(&"begin", sim)
	play.call(&"_ready")
	var offered: Array = play.call(&"_duel_reach", duel.me()) as Array
	assert_true(offered.size() > 1, "tiles are offered")
	assert_false(offered.has(Vector2(his) + Vector2(0.5, 0.5)), "and his is not one of them")
	play.free()


func test_the_reading_says_whether_the_gift_can_be_cast() -> void:
	# O10: the keys line offers the spell only to somebody she gave it to, and the ring
	# of its reach is drawn only while it is ready.
	var sim: Sim = Game.build()
	sim.submit(&"duel_began", {"opponent": "bram", "by": "player", "spar": true})
	sim.advance(1)
	var play: Node = _flat_play()
	play.call(&"begin", sim)
	play.call(&"_ready")
	assert_false(bool((play.call(&"_fight_frame") as Dictionary).get("can_cast", true)), "no gift, no spell")
	sim.facts.add_source(OpeningRules.GIFT, &"fairy")
	var reading: Dictionary = play.call(&"_fight_frame") as Dictionary
	assert_true(bool(reading.get("can_cast", false)), "the gift is yours")
	assert_true(bool(reading.get("spell_ready", false)), "and ready at the start")
	assert_eq(int(reading.get("spell_reach", 0)), DuelRules.spell_reach_tiles(), "with its reach")
	play.free()


func test_an_archers_ring_is_a_bows() -> void:
	# Found by the review of O9: her ring was a sword's one tile. Whoever acts is drawn with
	# the reach of what they hold.
	var sim: Sim = Game.build()
	sim.submit(&"duel_began", {"opponent": "wren", "by": "wren", "spar": true})
	sim.advance(1)
	var duel := sim.store(&"duel") as Duel
	var play: Node = _flat_play()
	play.call(&"begin", sim)
	play.call(&"_ready")
	var hands := DuelPlayer.new(DuelPlayer.PRESS)
	var saw_her: bool = false
	for _step: int in 3000:
		hands.play(sim, duel)
		sim.advance(1)
		if not duel.on():
			break
		var acting: DuelFighter = duel.acting_fighter()
		if acting == null or acting.is_player() or duel.acting != DuelRules.STRIKE:
			continue
		saw_her = true
		var reading: Dictionary = play.call(&"_fight_frame") as Dictionary
		assert_eq(int(reading.get("reach_tiles", 0)), DuelRules.bow_reach_tiles(), "her ring is a bow's")
	assert_true(saw_her, "she was seen shooting")
	play.free()


func test_no_page_of_the_journal_runs_off_the_bottom_of_the_box() -> void:
	# The failure this exists for is completely silent: a Label given more lines than
	# it has room for draws the ones that fit and says nothing about the rest. The
	# journal had outgrown its box some time ago and nobody could have known.
	var play: Node = _play_screen()
	var body: Label = play.get_node("HUD/JournalBox/Body") as Label
	var size: int = body.get_theme_font_size(&"font_size")
	var fits: int = floori(body.size.y / Ui.font().get_height(size))
	assert_true(fits >= 15, "the box holds %d lines" % fits)
	for page: Dictionary in play.call(&"_journal_pages") as Array[Dictionary]:
		var rows: int = 0
		for line: String in page["lines"] as Array[String]:
			rows += maxi(1, ceili(Ui.width_of(line, size) / body.size.x))
		assert_true(rows <= fits,
			"'%s' is %d rows and %d fit" % [page["name"], rows, fits])
	play.free()


func test_the_journal_turns_its_pages_and_comes_back_round() -> void:
	var play: Node = _play_screen()
	var pages: int = (play.call(&"_journal_pages") as Array).size()
	assert_true(pages >= 4, "%d pages" % pages)
	for _turn: int in pages:
		play.call(&"_turn_page", 1)
	assert_eq(posmod(play.get(&"_journal_page") as int, pages), 0,
		"a full turn of the pages ends where it started")
	play.free()


func test_the_dialogue_box_holds_every_row_it_can_be_given() -> void:
	# The review of O21: a talk offering three lines plus the way out drew its fourth row
	# below the box, half off the screen.
	var main: Node = _flat_play()
	var box: Control = main.get_node("HUD/DialogueBox") as Control
	var choices: Label = main.get_node("HUD/DialogueBox/Choices") as Label
	var font_size: int = choices.get_theme_font_size(&"font_size")
	var row: float = float(font_size) * 1.8
	assert_true(choices.offset_bottom - choices.offset_top >= row * DialogueRules.MAX_OPTIONS,
		"%d rows fit the choices: %.0f px for rows of %.0f" % [DialogueRules.MAX_OPTIONS,
			choices.offset_bottom - choices.offset_top, row])
	assert_true(choices.offset_bottom <= box.offset_bottom - box.offset_top, "and the choices fit inside the box")
	assert_true(box.offset_bottom <= 360.0, "and the box on the screen")
	main.free()


# ------------------------------------------------------------ what he looks like (A6) ---

func test_the_look_page_turns_every_choice_both_ways_and_round() -> void:
	var creation: Node = _screen("res://view/creation.gd")
	creation.call(&"_build")
	var menu: Menu = creation.get(&"_look_menu") as Menu
	for choice: StringName in AppearanceRules.ALL:
		assert_true(menu.point_at(choice), "%s is a row of the first page" % choice)
		var options: Array[StringName] = AppearanceRules.options(choice)
		var seen: Dictionary = {}
		for _press: int in options.size():
			seen[(creation.call(&"looks") as Dictionary)[choice]] = true
			creation.call(&"_change", 1)
		assert_eq(seen.size(), options.size(), "%s: every option reached going right" % choice)
		assert_eq((creation.call(&"looks") as Dictionary)[choice], options[0], "%s: and round to the first" % choice)
		creation.call(&"_change", -1)
		assert_eq((creation.call(&"looks") as Dictionary)[choice], options[options.size() - 1], "%s: left from the first is the last" % choice)
	creation.free()


func test_a_look_chosen_on_the_screen_is_the_run_s() -> void:
	var creation: Node = _screen("res://view/creation.gd")
	creation.call(&"_build")
	var menu: Menu = creation.get(&"_look_menu") as Menu
	menu.point_at(&"hair_colour")
	creation.call(&"_change", 1)
	menu.point_at(&"beard")
	creation.call(&"_change", -1)
	var looks: Dictionary = creation.call(&"looks") as Dictionary
	var sim: Sim = Game.begin_run(TraitRules.at_the_floor(), Sim.DEFAULT_SEED, looks)
	assert_eq((sim.store(&"appearance") as Appearance).chosen(), AppearanceRules.completed(looks),
		"the run is the person on the screen")
	assert_ne(looks[&"hair_colour"], AppearanceRules.default_appearance()[&"hair_colour"], "changed from his")
	creation.free()


func test_every_option_has_a_name_in_both_languages() -> void:
	for language: String in ["en", "fr"]:
		var known: Array[String] = Text.keys_for(language)
		for choice: StringName in AppearanceRules.ALL:
			assert_true(known.has("look.%s" % choice), "%s names the %s row" % [language, choice])
			for option: StringName in AppearanceRules.options(choice):
				assert_true(known.has("look.%s.%s" % [choice, option]), "%s names %s %s" % [language, choice, option])
