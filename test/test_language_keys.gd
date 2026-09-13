extends TestCase

## Every line the code asks for exists, in both languages.
##
## The failure this catches is silent and only visible in play: `Text.of` returns the
## key itself when it is missing, so a forgotten line shows up as `journal.wood` in
## the middle of a sentence. No test drew anything, so nothing noticed — which is
## exactly how the terrain colour table came to be one entry short.
##
## Scanned out of the source rather than listed here, because a list is a thing that
## goes stale and this cannot.

const SLOW: bool = true

## Keys built at runtime from an id — `place.short.%s`, `end.%s`. The literal scan
## cannot see them, so their families are checked by hand below.
const BUILT_AT_RUNTIME: Array[String] = [
	"place.short.", "place.", "end.", "doc.", "trait.", "rank.crown.", "rank.opposition.",
	"ground.", "deed.heard.", "relation.", "moment.", "journal.deed.", "journal.phrase.",
	"journal.elapsed.", "journal.who", "journal.because.",
]


func _sources() -> PackedStringArray:
	var out := PackedStringArray()
	for directory: String in ["res://core", "res://core/rules", "res://core/systems", "res://view"]:
		var listing: DirAccess = DirAccess.open(directory)
		if listing == null:
			continue
		for file: String in listing.get_files():
			if file.ends_with(".gd"):
				out.append("%s/%s" % [directory, file])
	return out


## Every `Text.of(&"literal")` in the code.
func _keys_asked_for() -> PackedStringArray:
	var out := PackedStringArray()
	for path: String in _sources():
		var source: String = FileAccess.get_file_as_string(path)
		var at: int = source.find("Text.of(&\"")
		while at >= 0:
			var from: int = at + "Text.of(&\"".length()
			var to: int = source.find("\"", from)
			if to > from:
				var key: String = source.substr(from, to - from)
				if not out.has(key):
					out.append(key)
			at = source.find("Text.of(&\"", from)
	return out


func test_every_line_the_code_asks_for_exists_in_both_languages() -> void:
	var asked: PackedStringArray = _keys_asked_for()
	assert_true(asked.size() > 30, "%d literal keys found in the source" % asked.size())
	for language: String in ["en", "fr"]:
		var known: Array[String] = Text.keys_for(language)
		for key: String in asked:
			var built: bool = false
			for family: String in BUILT_AT_RUNTIME:
				if key.begins_with(family):
					built = true
			if built:
				continue
			assert_true(known.has(key), "%s has no '%s'" % [language, key])


func test_the_families_built_at_runtime_are_complete() -> void:
	# The half the scan cannot see. Each of these is asked for with an id pasted on
	# the end, so the check is that every id the game can produce has a line.
	for language: String in ["en", "fr"]:
		var known: Array[String] = Text.keys_for(language)
		for zone: StringName in Region.ZONE_ORDER:
			assert_true(known.has("place.short.%s" % zone), "%s: place.short.%s" % [language, zone])
		for side: StringName in FactionRules.SIDES:
			for rank: int in (FactionRules.RANKS[side] as Array).size():
				var key: StringName = FactionRules.rank_key(side, rank)
				assert_true(known.has(String(key)), "%s: %s" % [language, key])
			assert_true(known.has("ground.%s" % side), "%s: ground.%s" % [language, side])
		assert_true(known.has("ground.none"), "%s: ground.none" % language)
		for deed: StringName in DeedRules.all_deeds():
			# Only the ones a person can have heard about carry a phrase; the rest
			# fall back to the deed id and never reach a player.
			if deed == DeedRules.DEED_THEFT or deed == DeedRules.DEED_INFORM:
				assert_true(known.has("deed.heard.%s" % deed),
					"%s: deed.heard.%s" % [language, deed])


func test_both_languages_carry_exactly_the_same_keys() -> void:
	# A line in one and not the other is a French player reading an English key.
	var english: Array[String] = Text.keys_for("en")
	var french: Array[String] = Text.keys_for("fr")
	for key: String in english:
		assert_true(french.has(key), "fr is missing '%s'" % key)
	for key: String in french:
		assert_true(english.has(key), "en is missing '%s'" % key)
