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


func test_a_won_spar_says_he_yields_not_that_he_is_down() -> void:
	# O1: nobody dies in a spar, so the banner does not say he is down.
	var hud := FightHud.new()
	var reading: Dictionary = _reading(1.0, 7, 0, "won")
	reading["spar"] = true
	hud.present(reading, 1.0 / 60.0)
	assert_eq(hud.banner(), Text.of(&"fight.yielded", ["Bram"]), "he yields: '%s'" % hud.banner())
	hud.free()


func test_walking_out_of_a_fight_does_not_say_you_are_down() -> void:
	# Found by O1's review: leaving is the ordinary way out of a spar, and every outcome
	# but a win used to read "you are down" — at full health.
	var hud := FightHud.new()
	hud.present(_reading(1.0, 10, 10, "left"), 1.0 / 60.0)
	assert_eq(hud.banner(), Text.of(&"fight.you_left"), "you walked away: '%s'" % hud.banner())
	hud.free()


func test_the_fallen_lose_their_bars_until_the_beat() -> void:
	# T9: at the works' gate a man joins every round, and every fallen one kept his bar.
	var hud := FightHud.new()
	var reading: Dictionary = _reading(1.0, 60, 15)
	var rows: Array = [{"who": "gatekeeper@1", "name": "Gatekeeper", "his_hp": 0, "his_max": 15, "his_down": true}]
	for seat: int in 6:
		rows.append({"who": "kings_guard#%d" % (seat + 1), "name": "King's guard", "his_hp": 15, "his_max": 15,
			"his_down": seat < 2})
	reading["fighters"] = rows
	hud.present(reading, 1.0 / 60.0)
	assert_eq(hud.bars_shown(), 1 + 4, "yours and the four still standing")
	reading["settling"] = 100
	hud.present(reading, 1.0 / 60.0)
	assert_eq(hud.bars_shown(), 1 + 7, "and every one through the beat that ends it")
	hud.free()


func test_a_man_named_with_his_trade_takes_his_turn_in_good_french() -> void:
	# The review of T9: « À Le portier des Forges », « À Garde de l'usine ». A man the
	# cast names by his trade has his turn said the way a beast's is, from his noun.
	var hud := FightHud.new()
	var reading: Dictionary = _reading(1.0, 100, 15)
	reading["my_turn"] = false
	reading["acting_name"] = "Le portier des Forges"
	reading["acting_noun"] = Text.of(&"fighter.gatekeeper.of")
	hud.present(reading, 1.0 / 60.0)
	assert_eq(hud.whose_turn(), Text.of(&"duel.beast_turn", [Text.of(&"fighter.gatekeeper.of")]),
		"from his noun: '%s'" % hud.whose_turn())
	reading.erase("acting_noun")
	reading["acting_name"] = "Bram"
	hud.present(reading, 1.0 / 60.0)
	assert_eq(hud.whose_turn(), Text.of(&"duel.his_turn", ["Bram"]), "and a man by his name")
	hud.free()


func test_the_french_turn_lines_elide_before_a_vowel() -> void:
	# V6's frame: « Au tour du archer de l'usine ». The article and its elision are in the
	# words themselves, one per kind, checked here in the French file.
	var fr: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/text.fr.json")) as Dictionary
	for key: String in fr.keys():
		if not key.ends_with(".of"):
			continue
		var words: String = String(fr[key])
		var noun: String = words.trim_prefix("du ").trim_prefix("de l'").trim_prefix("de la ").trim_prefix("des ")
		var vowel: bool = "aeiouhéèàâ".contains(noun.substr(0, 1).to_lower())
		assert_true(not (vowel and words.begins_with("du ")), "%s: « %s » elides before a vowel" % [key, words])
		assert_true(words.begins_with("du ") or words.begins_with("de l'") or words.begins_with("de la ") or words.begins_with("des "),
			"%s: « %s » carries its article" % [key, words])
	assert_eq(String(fr.get("fighter.works_archer.of", "")), "de l'archer de l'usine", "the archer's")


func test_a_blow_for_nothing_says_it_landed() -> void:
	# The review of T9: a lesson's partner stops at one point, so the arrow after it did
	# nothing and the HUD floated « -0 ». It landed; that is what counts in the lesson.
	var hud := FightHud.new()
	var reading: Dictionary = _reading(1.0, 100, 1)
	reading["blows"] = [{"type": "blow_landed", "by": "player", "damage": 0, "at": Vector2(100, 100)}]
	hud.present(reading, 1.0 / 60.0)
	assert_true(hud.float_words().has(Text.of(&"fight.touched")), "it says it landed")
	assert_false(hud.float_words().has("-0"), "and never « -0 »")
	hud.free()


func test_three_guards_down_are_said_as_three() -> void:
	# The review of group V: « Garde du roi est à terre » for all three.
	var hud := FightHud.new()
	var reading: Dictionary = _reading(1.0, 60, 0, "won")
	reading["his_name"] = "Garde du roi"
	reading["foes"] = 3
	reading["foes_many"] = "gardes du roi"
	hud.present(reading, 1.0 / 60.0)
	assert_eq(hud.banner(), Text.of(&"fight.pack_down", ["gardes du roi"]), "as a band: '%s'" % hud.banner())
	hud.free()


func test_every_foe_has_a_bar() -> void:
	# O6: two wolves, two bars under the one that names the fight.
	var hud := FightHud.new()
	var reading: Dictionary = _reading(1.0, 10, 10)
	reading["fighters"] = [
		{"who": "wolf", "name": "Wolf", "his_hp": 10, "his_max": 10},
		{"who": "wolf#2", "name": "Wolf", "his_hp": 4, "his_max": 10},
	]
	hud.present(reading, 1.0 / 60.0)
	assert_eq(hud.bars_shown(), 3, "yours and one each")
	assert_eq(hud.pips_shown(&"wolf#2"), 4, "and each shows its own health")
	hud.free()


func test_a_drill_shows_its_lesson_and_how_far_you_are() -> void:
	# O8: an instruction, an objective with its count, and a way to tell it is done.
	var hud := FightHud.new()
	var reading: Dictionary = _reading(1.0, 100, 15)
	reading["drill"] = "sword"
	reading["goal_done"] = 2
	reading["goal_of"] = 3
	hud.present(reading, 1.0 / 60.0)
	var card: PackedStringArray = hud.drill_card()
	assert_eq(card[0], Text.of(&"drill.sword.title"), "named for its weapon")
	assert_true(card[1].contains("2 / 3"), "the objective counts: '%s'" % card[1])
	assert_true(card[card.size() - 1] == Text.of(&"drill.sword.instruction"), "and, off your turn, what to do")
	hud.free()


## A drill's reading on the player's own turn, standing `apart` tiles from the nearest foe.
func _drill_turn(drill: String, apart: int, weapon: String = "sword") -> Dictionary:
	var reading: Dictionary = _reading(1.0, 100, 15)
	reading["drill"] = drill
	reading["goal_done"] = 0
	reading["goal_of"] = 3
	reading["my_turn"] = true
	reading["choosing"] = true
	reading["nearest_apart"] = apart
	reading["my_weapon"] = weapon
	reading["has_bow"] = drill == "bow"
	reading["spell_ready"] = true
	reading["spell_reach"] = DuelRules.spell_reach_tiles()
	return reading


func test_each_step_names_its_key_and_is_ticked_when_done() -> void:
	# T8: Yannick could not shoot and nothing told him why. The bow's lesson is three
	# steps, each with its key, and the ones done are ticked.
	var hud := FightHud.new()
	hud.present(_drill_turn("bow", 1, "sword"), 1.0 / 60.0)
	var steps: Array[Dictionary] = hud.lesson_steps()
	assert_eq(steps.size(), 3, "take the bow, keep your distance, shoot")
	assert_true(String(steps[0]["text"]).begins_with("U"), "the first names U: '%s'" % steps[0]["text"])
	assert_false(bool(steps[0]["done"]), "and it is not done while you hold the sword")
	assert_true(bool(steps[0]["current"]), "so it is the step you are on")
	hud.present(_drill_turn("bow", 3, "bow"), 1.0 / 60.0)
	steps = hud.lesson_steps()
	assert_true(bool(steps[0]["done"]) and bool(steps[1]["done"]), "the bow in hand, three tiles off: two done")
	assert_true(bool(steps[2]["current"]), "and K is next")
	assert_true(hud.drill_card()[2].begins_with("[x]"), "a done step is ticked: '%s'" % hud.drill_card()[2])
	hud.free()


func test_the_hint_answers_where_you_stand() -> void:
	var hud := FightHud.new()
	var cases: Array[Array] = [
		["bow", 3, "sword", &"drill.hint.take_bow"],
		["bow", 1, "bow", &"drill.hint.bow_too_close"],
		["bow", 9, "bow", &"drill.hint.too_far"],
		["bow", 4, "bow", &"drill.hint.shoot_now"],
		["sword", 4, "sword", &"drill.hint.sword_too_far"],
		["sword", 1, "sword", &"drill.hint.strike_now"],
		["magic", 6, "sword", &"drill.hint.gift_too_far"],
		["magic", 2, "sword", &"drill.hint.cast_now"],
	]
	for row: Array in cases:
		hud.present(_drill_turn(String(row[0]), int(row[1]), String(row[2])), 1.0 / 60.0)
		assert_eq(hud.hint_key(), row[3] as StringName, "%s, %d tiles, %s in hand" % [row[0], row[1], row[2]])
	var resting: Dictionary = _drill_turn("magic", 2)
	resting["spell_ready"] = false
	hud.present(resting, 1.0 / 60.0)
	assert_eq(hud.hint_key(), &"drill.hint.gift_resting", "the gift resting")
	var theirs: Dictionary = _drill_turn("bow", 1, "bow")
	theirs["choosing"] = false
	hud.present(theirs, 1.0 / 60.0)
	assert_eq(hud.hint_key(), &"", "and nothing is advised while it is not your turn")
	hud.free()


func test_a_long_row_is_broken_and_nothing_is_lost() -> void:
	var line: String = "Wren, your spare bow. Here, it's yours now. I'll come at you: land three arrows before I close, and don't let me stand next to you."
	var rows: PackedStringArray = Ui.wrapped(line, Ui.NOTE, 300.0)
	assert_true(rows.size() > 1, "broken into %d rows" % rows.size())
	for row: String in rows:
		assert_true(Ui.width_of(row, Ui.NOTE) <= 300.0, "each within the width: '%s'" % row)
	assert_eq(" ".join(rows), line, "and every word is kept, in order")


func test_what_was_said_does_not_take_the_card_off_the_screen() -> void:
	# Found by T8: the card had three colours for four lines, so the first round of every
	# lesson begun by its line — every lesson in play — stopped drawing the HUD at the
	# fourth, before the whose-turn line and the keys. Every row now carries its own.
	var hud := FightHud.new()
	var reading: Dictionary = _drill_turn("sword", 4)
	reading["said"] = "I'll step back. Come and get me."
	reading["said_by"] = "Bram"
	hud.present(reading, 1.0 / 60.0)
	var rows: Array[Dictionary] = hud.card_rows()
	assert_true(rows.size() >= 5, "title, count, steps, hint and what he said: %d rows" % rows.size())
	for row: Dictionary in rows:
		assert_true(row.has("tone") and row.has("size"), "every row says how it is drawn: '%s'" % row.get("text", ""))
	hud.free()


func test_a_drill_ends_passed_or_not_yet() -> void:
	var hud := FightHud.new()
	var passed: Dictionary = _reading(1.0, 100, 5, "won")
	passed["drill"] = "sword"
	hud.present(passed, 1.0 / 60.0)
	assert_eq(hud.banner(), Text.of(&"drill.passed"), "passed, not 'Bram is down'")
	hud.present({"lens": 0.0, "on": false}, 1.0 / 60.0)
	var failed: Dictionary = _reading(1.0, 100, 15, "failed")
	failed["drill"] = "sword"
	hud.present(failed, 1.0 / 60.0)
	assert_eq(hud.banner(), Text.of(&"drill.failed"), "and failing is 'not yet', not 'you are down'")
	hud.free()


func test_the_keys_offer_the_gift_only_to_who_has_it() -> void:
	var hud := FightHud.new()
	var reading: Dictionary = _reading(1.0, 100, 15)
	hud.present(reading, 1.0 / 60.0)
	assert_true(hud.keys_line().contains(Text.of(&"duel.part.strike")), "K strikes")
	assert_false(hud.keys_line().contains(Text.of(&"duel.part.spell")), "and no spell without the gift")
	reading["can_cast"] = true
	hud.present(reading, 1.0 / 60.0)
	assert_true(hud.keys_line().contains(Text.of(&"duel.part.spell")), "with it, I casts")
	hud.free()


func test_the_keys_name_the_weapon_in_your_hands() -> void:
	# T6: Yannick could not shoot and nothing told him why. The line says what K does with
	# what you hold, and what U would put in your hands instead.
	var hud := FightHud.new()
	var reading: Dictionary = _reading(1.0, 100, 15)
	hud.present(reading, 1.0 / 60.0)
	assert_false(hud.keys_line().contains(Text.of(&"duel.part.take_bow")), "no bow of your own, no U")
	reading["has_bow"] = true
	reading["my_weapon"] = "sword"
	hud.present(reading, 1.0 / 60.0)
	assert_true(hud.keys_line().contains(Text.of(&"duel.part.strike")), "the sword in hand: K strikes")
	assert_true(hud.keys_line().contains(Text.of(&"duel.part.take_bow")), "and U takes the bow")
	reading["my_weapon"] = "bow"
	hud.present(reading, 1.0 / 60.0)
	assert_true(hud.keys_line().contains(Text.of(&"duel.part.shoot")), "the bow in hand: K shoots")
	assert_true(hud.keys_line().contains(Text.of(&"duel.part.take_sword")), "and U takes the sword back")
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
	for key: StringName in [&"fight.you", &"fight.yielded", &"fight.you_left", &"drill.passed", &"drill.failed",
			&"drill.sword.title", &"drill.sword.instruction", &"drill.sword.goal",
			&"drill.sword.step.close", &"drill.sword.step.strike", &"drill.bow.step.take", &"drill.bow.step.range",
			&"drill.bow.step.shoot", &"drill.magic.step.close", &"drill.magic.step.cast",
			&"drill.hint.take_bow", &"drill.hint.bow_too_close", &"drill.hint.too_far", &"drill.hint.shoot_now",
			&"drill.hint.sword_too_far", &"drill.hint.strike_now", &"drill.hint.gift_too_far",
			&"drill.hint.gift_resting", &"drill.hint.cast_now", &"fight.touched",
			&"fighter.kings_guard", &"fighter.kings_guard.of", &"fighter.kings_guard.many",
			&"fighter.works_guard", &"fighter.works_guard.of", &"fighter.works_guard.many",
			&"fighter.works_archer", &"fighter.works_archer.of", &"fighter.works_archer.many", &"fighter.gatekeeper.of", &"beast.wolf.of",
			&"drill.bow.title", &"drill.bow.instruction", &"drill.bow.goal",
			&"duel.part.move", &"duel.part.strike", &"duel.part.shoot", &"duel.part.take_bow",
			&"duel.part.take_sword", &"duel.part.spell", &"duel.part.wait",
			&"drill.magic.title", &"drill.magic.instruction", &"drill.magic.goal", &"fight.blocked", &"fight.miss", &"fight.down", &"fight.you_down",
			&"duel.your_turn", &"duel.his_turn"]:
		assert_true(Text.has(key), "%s is written" % key)
		assert_eq(Ui.missing_glyph(Text.of(key, ["Bram"])), "",
			"and the font can draw it: %s" % Text.of(key, ["Bram"]))


# ------------------------------------------ the second design's fight (K4) ---

func _turn_reading(my_hp: int, his_hp: int, my_turn: bool, outcome: String = "") -> Dictionary:
	return {
		"lens": 1.0, "on": true, "turn_based": true, "my_turn": my_turn,
		"who": "bram", "his_name": "Bram",
		"my_hp": my_hp, "my_max": DuelRules.player_hp(), "his_hp": his_hp, "his_max": 10,
		"felled": false, "his_down": his_hp <= 0, "settling": 100 if outcome != "" else 0,
		"outcome": outcome, "blows": [],
	}


func test_a_hundred_points_is_a_bar_and_ten_is_still_pips() -> void:
	# The second design's table gives the player a hundred (a development value, and
	# content/duel.json says so). A hundred pips is 1,500 pixels on a 640-wide screen,
	# so the same widget draws a bar above twelve and pips at or below it — and it still
	# reports the health it was handed either way, because the number is what is true.
	var hud := FightHud.new()
	hud.present(_turn_reading(100, 10, true), 1.0 / 60.0)
	assert_true(FightHud.MAX_PIPS < DuelRules.player_hp(), "a hundred is past the pips")
	assert_eq(hud.pips_shown(&"mine"), 100, "and the bar still knows it is a hundred")
	assert_eq(hud.pips_shown(&"his"), 10, "while his ten are still ten pips")
	hud.present(_turn_reading(95, 5, false), 1.0 / 60.0)
	assert_eq(hud.pips_shown(&"mine"), 95, "a blow of five off a hundred")
	assert_eq(hud.pips_shown(&"his"), 5, "and of five off ten")
	hud.free()


func test_a_turn_based_fight_says_whose_turn_it_is() -> void:
	# A turn-based fight that does not say so is a fight the player stands in wondering
	# why nothing is happening. `--headless` never calls `_draw`, so what is checked
	# here is that the reading reaches the node; `docs/frames/duel/turn.png` is the
	# check that it is on the screen.
	var hud := FightHud.new()
	hud.present(_turn_reading(100, 10, true), 1.0 / 60.0)
	assert_true(hud.is_up(), "up with the fight")
	assert_eq(hud.opponent_named(), "Bram")
	assert_eq(hud.banner(), "", "and nothing is decided yet")
	hud.present(_turn_reading(100, 0, true, "won"), 1.0 / 60.0)
	assert_true(hud.banner().contains("Bram"), "then he is named as the one down")
	hud.free()


func test_a_beast_is_named_with_its_article_and_a_pack_as_a_pack() -> void:
	# The review of O21: "Loup est à terre", and after the two wolves at the bridge, one.
	var hud := FightHud.new()
	var one: Dictionary = _reading(1.0, 7, 0, "won")
	one.merge({"his_name": "Wolf", "his_kind": "wolf", "foes": 1}, true)
	hud.present(one, 1.0 / 60.0)
	assert_eq(hud.banner(), Text.of(&"fight.beast_down", [Text.of(&"beast.wolf.noun")]), "the wolf is down")
	hud.present({"lens": 0.0, "on": false}, 1.0 / 60.0)
	var pack: Dictionary = _reading(1.0, 7, 0, "won")
	pack.merge({"his_name": "Wolf", "his_kind": "wolf", "foes": 2}, true)
	hud.present(pack, 1.0 / 60.0)
	assert_eq(hud.banner(), Text.of(&"fight.pack_down", [Text.of(&"beast.wolf.many")]), "and two are the wolves")
	hud.free()
