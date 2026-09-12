extends TestCase

## The house style, enforced.
##
## **The register, settled 2026-09-12:** plain words, short sentences, no metaphor,
## and every line understandable on its own. A 10 year old should be able to read
## any line in the game, in either language.
##
## That is not a simplification of the writing, it *is* the writing. These are busy
## people saying what happened. The line that settled it was *"chaque peine de plus
## de 4 mois porte ma main au bas"*, which is not French at all: it existed because
## it had been written in English and translated, and a 25 word sentence gave the
## image somewhere to live. French is written first now, and neither language is a
## translation of the other.
##
## Two earlier rules were **deleted** rather than relaxed, because both were built
## for a register that is gone:
##
## - *at most a quarter of replies may end on the speaker* — a proxy for the wry,
##   self-aware coda, which the plain register removes by construction. In plain
##   speech people say "I" constantly and "give me a week" is not a literary flourish.
## - *the cast must span a wide range of sentence lengths* — this one actively caused
##   the damage. It pushed characters into 27 word built sentences, and a built
##   sentence is exactly where a metaphor hides. A rule that fights the register is a
##   bad rule however well it measures.
##
## **These rules are the generation constraints.** A model asked to write for this
## game will imitate what is already in it, so the corpus has to be clean before it
## is ever used as an example, and this file is the reject filter on anything
## generated. Every rule here is checkable without a human reading the line.

const LANGUAGES: Array[String] = ["en", "fr"]

## The dialogue box is 608 x 52 at font size 10: about four lines of 120 characters.
## A reply that does not fit is a reply the player reads half of.
const BOX_CHARS: int = 420
## Nobody makes a speech.
const MAX_REPLY_WORDS: int = 48
const MAX_AVERAGE_WORDS: int = 44
## A short sentence can be wrong. It cannot be ornate, and it survives being written
## in one language and checked in the other.
const MAX_SENTENCE_WORDS: int = 24
## Long words are where the literary register creeps back, and they are the first
## thing a model reaches for when it is asked to sound serious. Measured after the
## plain rewrite: 3.9 letters a word in English, 4.2 in French.
const MAX_LETTERS_PER_WORD: float = 4.6


func _replies(language: String) -> Array[Dictionary]:
	var cast: Cast = Cast.load_from(Cast.path_for(language))
	var out: Array[Dictionary] = []
	# One voice per *kind*, not per placement. Six watchmen share one line set, and
	# counting each of them separately made two lines look like twelve.
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


func test_no_sentence_is_long_enough_to_hide_a_metaphor_in() -> void:
	# The rule that replaced the two deleted ones. Short sentences cannot be ornate.
	for language: String in LANGUAGES:
		for row: Dictionary in _replies(language):
			for sentence: String in String(row["text"]).replace("!", ".").replace(
					"?", ".").split(".", false):
				var words: int = sentence.split(" ", false).size()
				assert_true(words <= MAX_SENTENCE_WORDS,
					"%s/%s has a %d word sentence: %s" % [
						language, row["who"], words, sentence.strip_edges()])


func test_the_words_are_short_ones() -> void:
	for language: String in LANGUAGES:
		var letters: int = 0
		var words: int = 0
		for row: Dictionary in _replies(language):
			for word: String in String(row["text"]).split(" ", false):
				var bare: String = word.lstrip("(\"'").rstrip(".,!?;:)\"'")
				if bare.length() == 0:
					continue
				letters += bare.length()
				words += 1
		var average: float = float(letters) / float(maxi(words, 1))
		assert_true(average <= MAX_LETTERS_PER_WORD,
			"%s averages %.2f letters a word, which is not plain speech" % [language, average])
