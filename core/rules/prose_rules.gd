class_name ProseRules
extends RefCounted

## The house style, as a function.
##
## §9's register, settled 2026-09-12: plain words, short sentences, no metaphor, and
## every line understandable on its own. These rules were written as a test first and
## live here so there is **one definition** used by two callers: `test_prose.gd`
## checks the hand-written corpus, and the phrasing pipeline checks every line a
## model ever produces. Two copies would drift, and the copy that drifted would be
## the one guarding the generated text.
##
## Everything here is checkable without a human reading the line. That is the whole
## point: a reject filter that needs judgement is not a filter.

## The dialogue box holds about four lines of 120 characters.
const MAX_CHARS: int = 420
const MAX_WORDS: int = 48
## A short sentence can be wrong. It cannot be ornate, and it survives being written
## in one language and checked in the other.
const MAX_SENTENCE_WORDS: int = 24
## Long words are where the literary register creeps back, and the first thing a
## model reaches for when asked to sound serious.
##
## **Per language, because one number cannot serve both.** Measured over the 95
## hand-written replies: English averages 3.85 letters a word and its longest line
## reaches 5.00; French averages 4.28 and reaches 5.46. French words are longer than
## English words for reasons that have nothing to do with register, and a single
## threshold at 5.4 refused two perfectly plain French lines while leaving English
## with 0.4 of slack it never used. Each is the measured maximum plus roughly 0.4.
const MAX_LETTERS_PER_WORD: Dictionary = {"en": 5.4, "fr": 5.9}
const MAX_LETTERS_FALLBACK: float = 5.9


## The ceiling for the language the player is reading, which is the language the line
## was written in: nothing here is translated.
static func max_letters_per_word() -> float:
	return float(MAX_LETTERS_PER_WORD.get(Text.locale(), MAX_LETTERS_FALLBACK))


## Everything wrong with this line, or an empty list. A list rather than a bool so a
## generator can be told what to fix.
static func faults(line: String, known_names: PackedStringArray,
		must_be_true: PackedStringArray = PackedStringArray()) -> PackedStringArray:
	var out := PackedStringArray()
	var trimmed: String = line.strip_edges()
	if trimmed.is_empty():
		out.append("empty")
		return out
	if trimmed.contains("—"):
		out.append("uses an em dash")
	# Somebody said this out loud. It cannot be formatted, and it cannot contain a
	# stage direction. A model reaches for both the moment it is asked to write
	# dialogue — *se retourne vers la mer*, **381 en onze ans** — and both would be
	# printed literally into the box.
	for mark: String in ["*", "_", "#", "`", "\n", "\r", "[", "]"]:
		if trimmed.contains(mark):
			out.append("is formatted or carries a stage direction")
			break
	if trimmed.length() > MAX_CHARS:
		out.append("is %d characters, over %d" % [trimmed.length(), MAX_CHARS])
	var words: PackedStringArray = trimmed.split(" ", false)
	if words.size() > MAX_WORDS:
		out.append("is %d words, over %d" % [words.size(), MAX_WORDS])

	for sentence: String in sentences_of(trimmed):
		var count: int = sentence.split(" ", false).size()
		if count > MAX_SENTENCE_WORDS:
			out.append("has a %d word sentence, over %d" % [count, MAX_SENTENCE_WORDS])
			break

	var letters: int = 0
	var counted: int = 0
	for word: String in words:
		var bare: String = bare_word(word)
		if bare.is_empty():
			continue
		letters += bare.length()
		counted += 1
	if counted > 0 and float(letters) / float(counted) > max_letters_per_word():
		out.append("averages %.1f letters a word, over %.1f, which is not plain speech"
			% [float(letters) / float(counted), max_letters_per_word()])

	var invented: PackedStringArray = names_not_in(trimmed, known_names)
	for name: String in invented:
		out.append("names '%s', who or which does not exist" % name)
	out.append_array(number_faults(trimmed, must_be_true))
	return out


static func accepts(line: String, known_names: PackedStringArray,
		must_be_true: PackedStringArray = PackedStringArray()) -> bool:
	return faults(line, known_names, must_be_true).is_empty()


## Did the line say the figures it was given, and only those?
##
## The one part of "it must state the facts" that is checkable without a human, and
## it is checkable **because the numbers are written as digits**. That decision was
## taken for the player — 381 reads faster than three hundred and eighty-one — and it
## turns out to be the only thing here that survives being written in one language
## and checked in another. 381 is 381 in French.
##
## Both directions matter. A missing figure is an answer that dodged the question; an
## invented one is worse, because a figure is why anybody believes the rest of the
## line. Facts that spell a number out ("two winters") are checked by neither, which
## is correct: content spells a number out exactly where the number is not the point.
static func number_faults(line: String, must_be_true: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	if must_be_true.is_empty():
		return out
	var wanted: PackedStringArray = numbers_in(" ".join(must_be_true))
	var said: PackedStringArray = numbers_in(line)
	for number: String in wanted:
		if not said.has(number):
			out.append("never says %s, which it was told to" % number)
	for number: String in said:
		if not wanted.has(number):
			out.append("says %s, which is a figure nobody gave it" % number)
	return out


static func numbers_in(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	var digits: String = ""
	for i: int in text.length() + 1:
		var character: String = text[i] if i < text.length() else " "
		if character >= "0" and character <= "9":
			digits += character
			continue
		if digits != "" and not out.has(digits):
			out.append(digits)
		digits = ""
	return out


## Capitalised words that are not a known person, place or the first word of a
## sentence.
##
## This is the rule the whole design rests on. Facts in this game are mechanical: a
## line that mentions a person who does not exist sends the player somewhere to find
## nothing, and after that they stop trusting anything anybody tells them, which ends
## a game about trusting what people tell you. A heuristic is not proof, which is why
## the real answer at generation time is a grammar that cannot emit an unknown name.
## This catches what gets past it.
static func names_not_in(line: String, known_names: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for sentence: String in sentences_of(line):
		var words: PackedStringArray = sentence.split(" ", false)
		for i: int in words.size():
			# The first word of a sentence is capitalised for grammar, not identity.
			if i == 0:
				continue
			var bare: String = bare_word(words[i])
			if bare.length() < 2 or bare[0] != bare[0].to_upper() or bare[0] == bare[0].to_lower():
				continue
			if known_names.has(bare) or out.has(bare):
				continue
			out.append(bare)
	return out


## Everybody and everywhere a line is allowed to mention, in the player's language.
##
## **Calibrated against the hand-written corpus** (`tools/prose_check.gd`), which is
## the only calibration available: a door that refuses Maddox is not strict, it is
## wrong. The first version refused 8 of 95 written lines, and every refusal was the
## list being short rather than the line being bad — a role that is capitalised in
## French (*le Prevot*), a wood that has a name but is not a town (*la Ronceraie*),
## and four burned villages that exist only inside the sentences that name them.
##
## So four sources, and content declares the fourth. A name the world contains but
## nothing declares cannot be told apart from a name a model invented, and inventing
## people is the one thing this rule exists to stop.
static func known_names(cast: Cast) -> PackedStringArray:
	var out := PackedStringArray()
	if cast != null:
		for id: StringName in cast.npcs.keys():
			var npc: Npc = cast.get_npc(id)
			_add_words(out, npc.display_name)
			# Roles as well as names. French capitalises a title mid-sentence and
			# "le Prevot" is not a person this line made up, it is Tovin's job.
			_add_words(out, npc.role)
		for name: String in cast.names:
			_add_words(out, name)
	# Every place, not only the eight towns: the wood, the ford, the road and the
	# marshes are named in dialogue and are as real as Harrowgate.
	for key: String in Text.keys_for(Text.locale()):
		if key.begins_with("place."):
			_add_words(out, Text.of(StringName(key)))
	return out


static func _add_words(out: PackedStringArray, phrase: String) -> void:
	for part: String in phrase.split(" ", false):
		var bare: String = bare_word(part)
		if bare.length() >= 2 and not out.has(bare):
			out.append(bare)


# ------------------------------------------------------------- the opener ---

## The one sentence a character puts in front of a written answer because of where
## the player stands.
const OPENER_WORDS: int = 14
## What a character says when nothing has changed and there is nothing to react to.
const NO_OPENER: String = "RIEN"


## Everything wrong with an opening reaction.
##
## **Why this is a different job from writing the whole line.** A model asked for a
## whole answer has to carry the facts, and carrying facts is where it fails in the
## way nothing can catch: *"Je ne défends pas ceux qui n'ont pas d'argent"* is the
## exact inverse of Mira's brief, contains no figure, names nobody, and is clean on
## every rule the door has. Meaning is not checkable here and probably not anywhere
## cheap.
##
## An opener states no facts at all. It says what the speaker will or will not give,
## the written line says what is true, and the two are joined. So the whole class of
## failure that cannot be checked is removed by construction rather than detected —
## and what is left is checkable to the last rule: no figures, no names the world
## does not have, one short sentence.
static func opener_faults(line: String, known_names: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	var trimmed: String = line.strip_edges()
	if trimmed == NO_OPENER:
		return out
	if trimmed.is_empty():
		out.append("empty")
		return out
	out.append_array(faults(trimmed, known_names))
	var words: int = trimmed.split(" ", false).size()
	if words > OPENER_WORDS:
		out.append("is %d words, over %d for an opener" % [words, OPENER_WORDS])
	if sentences_of(trimmed).size() > 1:
		out.append("is more than one sentence")
	# The hard one, and the reason this is safe: an opener that states a figure is
	# stating a fact, and stating facts is the job it exists to not have.
	if not numbers_in(trimmed).is_empty():
		out.append("gives a figure, which is the written line's job")
	return out


static func opener_accepted(line: String, known_names: PackedStringArray) -> bool:
	return opener_faults(line, known_names).is_empty()


## The opener and the written answer, as one thing somebody says.
static func joined(opener: String, written: String) -> String:
	var trimmed: String = opener.strip_edges()
	if trimmed.is_empty() or trimmed == NO_OPENER:
		return written
	return "%s %s" % [trimmed, written]


static func sentences_of(line: String) -> PackedStringArray:
	return line.replace("!", ".").replace("?", ".").split(".", false)


## A word with its punctuation off, and cut at an apostrophe. Without the cut,
## "Hesper's" is a different person from Hesper and "I'd" is a stranger entirely.
static func bare_word(word: String) -> String:
	var bare: String = word.lstrip("(\"'\u2018\u201c«»").rstrip(".,!?;:)\"'\u2019\u201d«»")
	for mark: String in ["'", "\u2019"]:
		var at: int = bare.find(mark)
		if at >= 0:
			bare = bare.substr(0, at)
	return bare
