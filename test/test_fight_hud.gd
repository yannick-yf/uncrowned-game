extends TestCase

## The fight's flat layer (H1, H5), fed a reading and asked what it made of it.
##
## `--headless` never calls `_draw`, so nothing here sees a pip. What it sees is the
## node's state from the reading: up or not, whose name, how many pips each side, what
## the banner says — the things `tools/shot.sh` then confirms are on the screen.

const SLOW: bool = false


func _reading(lens: float, my_hp: int, his_hp: int, outcome: String = "", blows: Array = []) -> Dictionary:
	return {
		"lens": lens, "on": true, "who": "bram", "his_name": "Bram",
		"my_hp": my_hp, "my_max": 10, "his_hp": his_hp, "his_max": 10,
		"felled": false, "his_down": his_hp <= 0, "settling": 100 if outcome != "" else 0,
		"outcome": outcome, "blows": blows,
	}


func test_it_comes_up_with_the_fight_and_names_him() -> void:
	var hud := FightHud.new()
	hud.present({"lens": 0.0, "on": false}, 1.0 / 60.0)
	assert_false(hud.is_up(), "nothing to show when nobody is fighting")
	hud.present(_reading(1.0, 10, 10), 1.0 / 60.0)
	assert_true(hud.is_up(), "up when the fight is")
	assert_eq(hud.opponent_named(), "Bram", "and the man in front of you is named")
	assert_eq(hud.pips_shown(&"mine"), 10, "ten of yours")
	assert_eq(hud.pips_shown(&"his"), 10, "ten of his")
	hud.free()


func test_the_pips_follow_the_blows_and_a_number_is_hung_on_them() -> void:
	var hud := FightHud.new()
	hud.present(_reading(1.0, 10, 10), 1.0 / 60.0)
	var blow: Dictionary = {"type": "blow_landed", "by": "player", "move": "strike", "damage": 2,
		"guarded": false, "at": Vector2(400.0, 120.0)}
	hud.present(_reading(1.0, 10, 8, "", [blow]), 1.0 / 60.0)
	assert_eq(hud.pips_shown(&"his"), 8, "two of his went")
	assert_eq(hud.floats_shown(), 1, "and the number it cost hangs over him")
	var guarded: Dictionary = {"type": "blow_landed", "by": "bram", "move": "jab", "damage": 1,
		"guarded": true, "at": Vector2(-1.0, -1.0)}
	hud.present(_reading(1.0, 9, 8, "", [guarded]), 1.0 / 60.0)
	assert_eq(hud.pips_shown(&"mine"), 9, "one of yours, through the guard")
	assert_eq(hud.floats_shown(), 2, "with a word for the guard, placed by the bar when the window gave no point")
	var missed: Dictionary = {"type": "blow_missed", "by": "player", "move": "strike", "at": Vector2(300.0, 100.0)}
	hud.present(_reading(1.0, 9, 8, "", [missed]), 1.0 / 60.0)
	assert_eq(hud.floats_shown(), 3, "and a miss says so too")
	# They fade.
	for _i: int in 90:
		hud.present(_reading(1.0, 9, 8), 1.0 / 60.0)
	assert_eq(hud.floats_shown(), 0, "a second and a half later the words are gone")
	hud.free()


func test_the_banner_is_read_off_the_outcome_and_goes_with_the_fight() -> void:
	var hud := FightHud.new()
	hud.present(_reading(1.0, 7, 0, "won"), 1.0 / 60.0)
	assert_true(hud.banner().contains("Bram"), "he is named as the one down: '%s'" % hud.banner())
	assert_eq(hud.pips_shown(&"his"), 0, "with nothing left in his bar")
	# A frame the fight is off and the lens has come back up: everything is cleared,
	# so the next fight does not open on the last one's banner.
	hud.present({"lens": 0.0, "on": false}, 1.0 / 60.0)
	assert_false(hud.is_up(), "gone with the fight")
	assert_eq(hud.banner(), "", "and the banner with it")
	hud.present(_reading(1.0, 2, 4, "lost"), 1.0 / 60.0)
	assert_true(hud.banner() != "" and not hud.banner().contains("Bram"),
		"losing names you, not him: '%s'" % hud.banner())
	hud.free()


func test_a_felled_player_is_shown_at_nothing() -> void:
	# The felling blow is paid at the end of the beat, so the store still says one or
	# two while you are on the ground. The picture says nothing left, because that is
	# what happened.
	var hud := FightHud.new()
	var reading: Dictionary = _reading(1.0, 2, 4, "lost")
	reading["felled"] = true
	hud.present(reading, 1.0 / 60.0)
	assert_eq(hud.pips_shown(&"mine"), 0, "down is drawn as nothing left")
	hud.free()


func test_the_fights_words_exist_in_both_languages() -> void:
	for key: StringName in [&"fight.you", &"fight.keys", &"fight.blocked", &"fight.miss", &"fight.down", &"fight.you_down"]:
		assert_true(Text.has(key), "%s is written" % key)
		assert_eq(Ui.missing_glyph(Text.of(key, ["Bram"])), "",
			"and the font can draw it: %s" % Text.of(key, ["Bram"]))
