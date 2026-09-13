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
	rows.append_array((creation.get(&"_menu") as Menu).rows)
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
		(creation.get(&"_menu") as Menu).move(1)
	var levels: Dictionary = creation.get(&"_levels") as Dictionary
	assert_true(TraitRules.is_legal(levels),
		"no sequence of presses builds an illegal character: %s" % levels)
	assert_eq(TraitRules.spent(levels), TraitRules.POOL, "and the pool is what is spent")
	creation.free()


func test_begin_is_closed_until_the_last_point_is_placed() -> void:
	var creation: Node = _screen("res://view/creation.gd")
	creation.call(&"_build")
	var menu: Menu = creation.get(&"_menu") as Menu
	assert_false(menu.point_at(&"begin"),
		"with ten points unspent the cursor cannot even reach Begin")
	for _press: int in TraitRules.POOL:
		creation.call(&"_spend", 1)
		if TraitRules.spent(creation.get(&"_levels") as Dictionary) % 4 == 0:
			menu.move(1)
	menu = creation.get(&"_menu") as Menu
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
	levels[TraitRules.WITS] = 5
	levels[TraitRules.PRESENCE] = 4
	var sim: Sim = Game.build()
	var data: Dictionary = {}
	for what: StringName in TraitRules.ALL:
		data[String(what)] = int(levels[what])
	sim.submit(&"create_character", data)
	sim.advance(1)
	var traits := sim.store(&"traits") as Traits
	assert_true(traits.chosen, "the run has a person in it")
	assert_eq(traits.level_of(TraitRules.WITS), 5, "who is the one that was chosen")
	assert_true(traits.speaks_with(TraitRules.PRESENCE), "and speaks with what they took")
	creation.free()


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
func _play_screen() -> Node:
	var play: Node = (load("res://view/main.tscn") as PackedScene).instantiate()
	play.call(&"begin", Game.build())
	play.call(&"_ready")
	return play


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
