extends TestCase

## The house style, enforced.
##
## Measured on 2026-09-12, after twenty-four characters had been written: **53% of
## all replies ended with the speaker turning back on themselves** in a wry,
## self-aware coda. A scavenger, a foreman, a banker, an archivist, a deserter and
## a king all landed the same closing beat. That is not "AI writing" exactly, it is
## one writer's tic applied twenty-four times, which is the same thing.
##
## **These rules are also the generation constraints.** A model asked to write for
## this game will imitate what is already in it, tics included, so the corpus has to
## be clean before it is ever used as an example, and this file becomes the reject
## filter on anything generated. Every rule here is machine-checkable on purpose.

const LANGUAGES: Array[String] = ["en", "fr"]

## The dialogue box is 608 x 52 at font size 10: about four lines of 120 characters.
## A reply that does not fit is a reply the player reads half of.
const BOX_CHARS: int = 420
## Nobody should need this many words to answer a question in a game about people
## who are busy.
const MAX_REPLY_WORDS: int = 40
## And no character should average near it.
const MAX_AVERAGE_WORDS: int = 32
## How many replies may end by turning back on the speaker. It is a good device and
## it is the *only* device this cast had.
const CODA_SHARE: float = 0.25


func _replies(language: String) -> Array[Dictionary]:
	var cast: Cast = Cast.load_from(Cast.path_for(language))
	var out: Array[Dictionary] = []
	# One voice per *kind*, not per placement. Six watchmen share one line set, and
	# counting each of them separately made two lines look like twelve and put the
	# measurement out by twenty points.
	var counted: Dictionary = {}
	for id: StringName in cast.npcs.keys():
		var npc: Npc = cast.get_npc(id)
		var voice: StringName = npc.kind if npc.generic else npc.id
		if counted.has(voice):
			continue
		counted[voice] = true
		out.append({"who": id, "what": "greeting", "text": npc.greeting})
		for alt: Dictionary in npc.alt_greetings:
			out.append({"who": id, "what": "alt", "text": String(alt["text"])})
		for option: DialogueOption in npc.options:
			out.append({"who": id, "what": "option", "text": option.text})
			out.append({"who": id, "what": "reply", "text": option.reply})
	return out


func test_no_line_uses_an_em_dash() -> void:
	# The most recognisable tell in the language, and one a model reaches for
	# constantly. French typography uses it differently again.
	for language: String in LANGUAGES:
		for row: Dictionary in _replies(language):
			assert_false(String(row["text"]).contains("—"),
				"%s/%s (%s) uses an em dash" % [language, row["who"], row["what"]])


func test_every_line_fits_on_the_screen() -> void:
	# Found by measuring rather than by playing: Arthur's argument was 987
	# characters, twice what the box holds, so half of the most important speech in
	# the game was never displayed.
	for language: String in LANGUAGES:
		for row: Dictionary in _replies(language):
			assert_true(String(row["text"]).length() <= BOX_CHARS,
				"%s/%s (%s) is %d characters and the box holds %d" % [
					language, row["who"], row["what"], String(row["text"]).length(), BOX_CHARS])


func test_nobody_makes_a_speech() -> void:
	for language: String in LANGUAGES:
		for row: Dictionary in _replies(language):
			if row["what"] != "reply":
				continue
			var words: int = String(row["text"]).split(" ", false).size()
			assert_true(words <= MAX_REPLY_WORDS,
				"%s/%s answers in %d words" % [language, row["who"], words])


func test_no_voice_runs_long_on_average() -> void:
	for language: String in LANGUAGES:
		var totals: Dictionary = {}
		var counts: Dictionary = {}
		for row: Dictionary in _replies(language):
			if row["what"] != "reply":
				continue
			var who: StringName = row["who"] as StringName
			totals[who] = int(totals.get(who, 0)) + String(row["text"]).split(" ", false).size()
			counts[who] = int(counts.get(who, 0)) + 1
		for who: StringName in totals.keys():
			var average: float = float(totals[who]) / float(counts[who])
			assert_true(average <= float(MAX_AVERAGE_WORDS),
				"%s/%s averages %.0f words a reply" % [language, who, average])


func test_not_everybody_ends_on_themselves() -> void:
	# The measurement that started this. It is a fine device for two or three
	# people whose business is self-examination, and it was doing the work of
	# characterisation for all twenty-four.
	for language: String in LANGUAGES:
		var codas: int = 0
		var replies: int = 0
		var guilty := PackedStringArray()
		for row: Dictionary in _replies(language):
			if row["what"] != "reply":
				continue
			replies += 1
			if _turns_back_on_the_speaker(String(row["text"]), language):
				codas += 1
				guilty.append(String(row["who"]))
		var share: float = float(codas) / float(maxi(replies, 1))
		assert_true(share <= CODA_SHARE,
			"%s: %d of %d replies (%.0f%%) end on the speaker, cap is %.0f%% — %s" % [
				language, codas, replies, share * 100.0, CODA_SHARE * 100.0, guilty])


## The last sentence, short, with the speaker in it.
##
## Whole words only. An earlier version matched substrings, so it counted "i " and
## missed nothing, but it also called this rule satisfied while a third of the cast
## was still doing it. A check that cannot fail is not a check.
func _turns_back_on_the_speaker(text: String, language: String) -> bool:
	var sentences: PackedStringArray = text.replace("!", ".").replace("?", ".").split(".", false)
	if sentences.is_empty():
		return false
	var last: String = sentences[sentences.size() - 1].strip_edges().to_lower()
	var words: PackedStringArray = last.split(" ", false)
	if words.size() > 22:
		return false
	# Written out rather than as a ternary: GDScript cannot infer Array[String] from
	# one, and the version that tried errored inside the check. A check that throws
	# is a check that passes, which is the failure this project has a rule about.
	var me: Array[String] = []
	if language == "en":
		me.assign(["i", "me", "my", "myself", "i'll", "i'd", "i've", "i'm"])
	else:
		me.assign(["je", "j'ai", "moi", "mon", "ma", "mes", "j'y", "j'en"])
	for word: String in words:
		var bare: String = word.lstrip("(\"'").rstrip(",;:)\"'")
		if me.has(bare):
			return true
	return false
