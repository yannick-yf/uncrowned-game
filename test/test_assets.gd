extends TestCase

## Slow by nature: it reads 1,867 files off disk.
const SLOW: bool = true

## SPECS §13's asset rule, as a test.
##
## The approved pack is where the palette came from, so these pass by construction
## today. They exist for the sprite someone borrows from another artist in six
## months, which is exactly when nobody is looking.

var _report: AssetValidator.Report = null


func before_each() -> void:
	_report = AssetValidator.cached_report()


func test_the_palette_is_loaded_and_locked() -> void:
	assert_eq(_report.palette_size, 340,
		"the approved pack authored 340 colours; a change here means the pack changed")


func test_every_image_uses_only_palette_colours() -> void:
	assert_true(_report.scanned > 1800, "found %d images to check" % _report.scanned)
	assert_eq(_report.off_palette.size(), 0,
		"off-palette: %s" % ", ".join(_report.off_palette))


func test_tile_sources_are_on_the_sixteen_pixel_grid() -> void:
	assert_true(_report.tile_sources > 0, "found tile sources to check")
	assert_eq(_report.off_grid.size(), 0, "off-grid: %s" % ", ".join(_report.off_grid))


func test_every_image_could_be_read() -> void:
	assert_eq(_report.unreadable.size(), 0, "unreadable: %s" % ", ".join(_report.unreadable))


## A validator that has never rejected anything is not known to work. These four
## feed it art it must refuse, without touching assets/.

func _painted(width: int, height: int, colour: Color) -> Image:
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(colour)
	return image


func test_it_accepts_a_colour_that_is_in_the_palette() -> void:
	var palette: Dictionary = AssetValidator.load_palette()
	var clean: Image = _painted(4, 4, Color8(255, 255, 255))
	assert_eq(AssetValidator.first_stray_colour(clean, palette), -1, "#ffffff is pack white")


func test_it_rejects_a_colour_outside_the_palette() -> void:
	var palette: Dictionary = AssetValidator.load_palette()
	var poison: Image = _painted(4, 4, Color8(255, 0, 255))
	assert_eq(AssetValidator.first_stray_colour(poison, palette), 0xff00ff,
		"magenta is in no pixel of the approved pack and must be caught")


func test_it_ignores_fully_transparent_pixels() -> void:
	var palette: Dictionary = AssetValidator.load_palette()
	var empty: Image = _painted(4, 4, Color(1.0, 0.0, 1.0, 0.0))
	assert_eq(AssetValidator.first_stray_colour(empty, palette), -1,
		"what you cannot see has no colour")


func test_it_rejects_a_tile_source_off_the_sixteen_pixel_grid() -> void:
	assert_true(AssetValidator.is_on_grid(_painted(32, 48, Color.WHITE)), "32x48 is on the grid")
	assert_false(AssetValidator.is_on_grid(_painted(33, 48, Color.WHITE)), "33 is not")
	assert_false(AssetValidator.is_on_grid(_painted(32, 47, Color.WHITE)), "nor is 47")
	assert_true(AssetValidator.is_tile_source("res://assets/Pack/Backgrounds/Tilesets/A.png"))
	assert_false(AssetValidator.is_tile_source("res://assets/Pack/Ui/Arrow.png"),
		"a 13x13 UI arrow is not laid on the tile grid and is not asked to be")
	assert_true(AssetValidator.is_preview("res://assets/Pack/Items/AllPreview.png"))


# ------------------------------------------------- invariant 10, by machine ---

func test_no_child_sprite_survives_in_the_pack() -> void:
	# CLAUDE.md invariant 10 is absolute and permanent, so it is checked rather
	# than remembered. The pack shipped four; they are gone, and this is what
	# stops them returning with the next pack update.
	var found: PackedStringArray = AssetValidator.forbidden_assets()
	assert_eq(found.size(), 0, "child sprite folders present: %s" % ", ".join(found))


func test_no_code_names_a_child_sprite() -> void:
	var found: PackedStringArray = AssetValidator.forbidden_references()
	assert_eq(found.size(), 0, "code references a forbidden sprite: %s" % ", ".join(found))


func test_the_casting_table_uses_nothing_forbidden() -> void:
	# The text scan catches paths; this catches the one place that turns a name
	# into a path at runtime, where a typo would slip past a grep.
	var art := Art.new()
	for role: StringName in Art.CASTING.keys():
		assert_false(AssetValidator.FORBIDDEN_SPRITES.has(String(Art.CASTING[role])),
			"%s is cast as a forbidden sprite" % role)
	assert_true(art.sheet_for(&"player") != null, "and the casting still resolves")


# -------------------------------------------------------------- the casting ---

## One face each.
##
## Twenty-nine roles shared eighteen sheets, so Bell, Sena and Mira were the same
## woman standing in three towns and the bank and the estate were run by the same man
## in a hat. Nothing failed: a sheet that is drawn twice is drawn correctly twice.
## This is the check that was missing, and the spare faces are the margin — when it
## fails, somebody has joined the cast and the pack has run out of people.

func _sheet_path(folder: String) -> String:
	return "%s/Actor/Character/%s/SpriteSheet.png" % [Art.PACK, folder]


func test_every_role_is_cast_as_somebody_the_pack_actually_ships() -> void:
	assert_true(Art.CASTING.size() >= 25, "%d roles cast" % Art.CASTING.size())
	for role: StringName in Art.CASTING.keys():
		assert_true(FileAccess.file_exists(_sheet_path(String(Art.CASTING[role]))),
			"%s is cast as %s, which is not in the pack" % [role, Art.CASTING[role]])


func test_nobody_in_the_cast_shares_a_face() -> void:
	var taken: Dictionary = {}
	for role: StringName in Art.CASTING.keys():
		var folder: String = String(Art.CASTING[role])
		assert_false(taken.has(folder),
			"%s and %s are both drawn as %s" % [role, taken.get(folder, ""), folder])
		taken[folder] = String(role)


func test_everybody_with_a_name_has_a_face() -> void:
	# The fairy is light rather than a body (§4's opening) and is drawn by hand.
	Cast.forget()
	var cast: Cast = Cast.shared()
	for npc: Npc in cast.named():
		if npc.id == OpeningRules.FAIRY:
			continue
		assert_true(Art.CASTING.has(npc.id), "%s has no face" % npc.id)
	Cast.forget()


func test_the_crowd_is_drawn_from_faces_that_exist() -> void:
	assert_true(Art.TOWNSFOLK.size() >= 8, "%d faces in the crowd" % Art.TOWNSFOLK.size())
	for folder: String in Art.TOWNSFOLK:
		assert_true(FileAccess.file_exists(_sheet_path(folder)),
			"the crowd draws on %s, which is not in the pack" % folder)


func test_every_building_the_map_puts_up_has_a_sprite() -> void:
	# `Art.props` is the other half of the identity table: `core/` says a workshop
	# stands at a tile and this is what says what a workshop looks like. A kind with
	# no entry draws nothing at all, silently.
	var art := Art.new()
	for zone: StringName in Region.BUILDINGS_AT.keys():
		for kind: Variant in Region.BUILDINGS_AT[zone] as Array:
			assert_true(art.props.has(kind as StringName),
				"%s puts up a %s and nothing knows how to draw one" % [zone, kind])
	for zone: StringName in Region.SCENERY_AT.keys():
		for kind: Variant in Region.SCENERY_AT[zone] as Array:
			assert_true(art.props.has(kind as StringName),
				"%s keeps a %s in the street and nothing knows how to draw one" % [zone, kind])


func test_no_two_places_are_built_out_of_the_same_kit() -> void:
	# What "each town has its own identity" means when it is a test rather than a
	# wish: no two settlements may put up the same set of buildings.
	var seen: Dictionary = {}
	for zone: StringName in Region.BUILDINGS_AT.keys():
		var kit: Array = (Region.BUILDINGS_AT[zone] as Array).duplicate()
		kit.sort()
		var key: String = ",".join(PackedStringArray(kit.map(func(k: Variant) -> String:
			return String(k))))
		assert_false(seen.has(key), "%s is built exactly like %s" % [zone, seen.get(key, "")])
		seen[key] = String(zone)


# ------------------------------------------------------------------- audio ---

## Every noise the game can make is a file that is actually in the pack.
##
## A missing sound is the quietest bug there is: `load()` returns null, the player
## plays nothing, and the game carries on. Nobody notices for a month, and then
## somebody notices that the Muster has always been silent.

func _sound_exists(path: String) -> bool:
	return ResourceLoader.exists("%s/%s" % [Sound.PACK, path])


func test_every_track_the_game_can_ask_for_is_in_the_pack() -> void:
	var tracks: Array[String] = [Sound.MUSIC_ROAD, Sound.MUSIC_TITLE, Sound.MUSIC_CREATION]
	for zone: StringName in Sound.MUSIC_AT.keys():
		tracks.append(String(Sound.MUSIC_AT[zone]))
	for terrain: Variant in Sound.MUSIC_ON.keys():
		tracks.append(String(Sound.MUSIC_ON[terrain]))
	assert_true(tracks.size() >= 12, "%d tracks named" % tracks.size())
	for track: String in tracks:
		assert_true(_sound_exists("Musics/%s" % track), "no track called %s" % track)


func test_every_place_on_the_map_has_something_to_sound_like() -> void:
	# The check that a new zone cannot arrive silently. Blackcairn and the Muster both
	# have to sound like themselves, and the road is what everywhere else falls to.
	for zone: StringName in Region.ZONE_ORDER:
		assert_true(Sound.MUSIC_AT.has(zone), "%s has no music" % zone)
	assert_eq(Sound.track_for(&"", Region.Terrain.WILD), Sound.MUSIC_ROAD,
		"open country falls back to the travelling track")
	assert_eq(Sound.track_for(&"", Region.Terrain.THICKET),
		String(Sound.MUSIC_ON[Region.Terrain.THICKET]), "and the wood does not")
	assert_eq(Sound.track_for(&"blackcairn", Region.Terrain.THICKET),
		String(Sound.MUSIC_AT[&"blackcairn"]), "a place beats the ground it stands on")


func test_every_ambience_and_every_cue_is_in_the_pack() -> void:
	for terrain: Variant in Sound.AMBIENT_ON.keys():
		assert_true(_sound_exists("Sounds/Ambient/%s" % Sound.AMBIENT_ON[terrain]),
			"no ambience called %s" % Sound.AMBIENT_ON[terrain])
	assert_true(Sound.CUES.size() >= 8, "%d cues" % Sound.CUES.size())
	for what: StringName in Sound.CUES.keys():
		assert_true(_sound_exists(String(Sound.CUES[what])),
			"the cue '%s' names %s, which is not in the pack" % [what, Sound.CUES[what]])


func test_nothing_asks_for_a_noise_the_table_does_not_name() -> void:
	# Cues are looked up by a name in the source, so a typo is silence. Scanned out of
	# view/ rather than listed, because a list goes stale and this cannot.
	var listing: DirAccess = DirAccess.open("res://view")
	assert_not_null(listing, "view/ is readable")
	var asked: int = 0
	for file: String in listing.get_files():
		if not file.ends_with(".gd") or file == "sound.gd":
			continue
		var source: String = FileAccess.get_file_as_string("res://view/%s" % file)
		var at: int = source.find("Sound.cue(&\"")
		while at >= 0:
			var from: int = at + "Sound.cue(&\"".length()
			var to: int = source.find("\"", from)
			var name: String = source.substr(from, to - from)
			assert_true(Sound.CUES.has(StringName(name)),
				"%s asks for the cue '%s', which is not in the table" % [file, name])
			asked += 1
			at = source.find("Sound.cue(&\"", from)
	assert_true(asked >= 8, "%d cues asked for across the screens" % asked)
