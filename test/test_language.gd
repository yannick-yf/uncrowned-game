extends TestCase

## The game in more than one language.
##
## Done at 150 strings rather than after Phase 6, when it would have been 25 NPCs
## and tens of thousands of generated lines. The same job, about a day now and about
## a month later.
##
## What these guard is the failure nobody notices: a language that falls behind. A
## missing line does not crash — it shows a key, or an English sentence in a French
## game, and it does so on one screen that nobody opened during testing. So the
## languages are compared to each other, every run.

const LANGUAGES: Array[String] = ["en", "fr"]


func test_every_language_has_every_line() -> void:
	var english: Array[String] = Text.keys_for("en")
	assert_true(english.size() > 50, "there is a table to compare against")
	for other: String in LANGUAGES:
		var keys: Array[String] = Text.keys_for(other)
		assert_eq(keys, english,
			"content/text.%s.json has drifted from the English — a missing line shows "
				% other + "a key on a screen nobody opened during testing")


func test_no_language_has_an_empty_line() -> void:
	for language: String in LANGUAGES:
		Text.set_locale(language)
		for key: String in Text.keys_for(language):
			assert_true(Text.of(StringName(key)).length() > 0,
				"%s is empty in %s" % [key, language])
	Text.set_locale("en")


func test_a_suite_reads_english_whatever_the_player_last_chose() -> void:
	# The runner forces it, and this is what says why. Content tests assert on the
	# words — that Maddox blames the soldiers — so without this a suite passes or
	# fails depending on which language somebody last pressed L in. It did.
	assert_eq(Text.locale(), "en", "the suite runs in English regardless of settings")
	assert_eq(Cast.path_for(Text.locale()), "res://content/cast.en.json",
		"and reads the English sheets with it")


func test_every_cast_sheet_exists_in_every_language() -> void:
	# Ids and structure must match exactly: same people, same options, same intents.
	# Only the words differ. A French cast missing an option would silently remove a
	# fact from the world for French players and nothing else would notice.
	var english: Cast = Cast.load_from(Cast.path_for("en"))
	for language: String in LANGUAGES:
		var other: Cast = Cast.load_from(Cast.path_for(language))
		assert_eq(_shape_of(other), _shape_of(english),
			"content/cast.%s.json does not match the English sheet for sheet" % language)


func test_the_words_actually_differ() -> void:
	# The cheapest way for a translation to be "complete" is to copy the English in.
	var english: Cast = Cast.load_from(Cast.path_for("en"))
	var french: Cast = Cast.load_from(Cast.path_for("fr"))
	var same: int = 0
	var counted: int = 0
	for id: StringName in english.npcs.keys():
		counted += 1
		if french.get_npc(id).greeting == english.get_npc(id).greeting:
			same += 1
	assert_true(counted > 0, "there are people to check")
	assert_eq(same, 0, "%d of %d French greetings are still the English" % [same, counted])


func test_a_missing_line_shows_its_key_rather_than_nothing() -> void:
	# A screen reading `journal.holds` is a bug you fix in a minute. A screen that
	# has quietly gone blank is one you ship.
	assert_eq(Text.of(&"no.such.key.exists"), "no.such.key.exists",
		"an unknown key names itself")


## Everybody, every option, every intent — ids only, never words.
func _shape_of(cast: Cast) -> PackedStringArray:
	var out := PackedStringArray()
	var ids: Array = cast.npcs.keys()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	for id: StringName in ids:
		var npc: Npc = cast.get_npc(id)
		var intents := PackedStringArray()
		for option: DialogueOption in npc.options:
			intents.append("%s:%s:%s" % [option.intent, option.teaches, option.costs])
		out.append("%s|%s|alts=%d|%s" % [
			id, npc.generic, npc.alt_greetings.size(), ",".join(intents)])
	return out
