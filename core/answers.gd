class_name Answers
extends RefCounted

## What an answer has to contain, as facts rather than as a sentence.
##
## The sibling of `Voices`: instructions for whoever writes a line, never shown to a
## player, so English only and not translated. A translated copy of a brief is two
## things to keep in step for no benefit, and the line itself is written in the
## player's language from these facts rather than translated into it.
##
## **Why this exists.** The packet used to end with `MUST SAY:` and the whole
## finished reply, which is a brief to *rephrase*. Rephrasing is safe and nearly
## worthless: if the sentence is already written, generating it again buys nothing.
## Facts are the brief that earns its keep, because one fact set covers every world
## the same question can be asked in, and the hand-written reply covers one.
##
## An option with no facts declared is **never generated** and its written reply
## stands. That is what makes this safe to turn on one line at a time rather than
## all at once.

const PATH: String = "res://content/answers.json"

var _facts: Dictionary = {}

static var _shared: Answers = null


static func shared() -> Answers:
	if _shared == null:
		_shared = load_from(PATH)
	return _shared


static func load_from(path: String) -> Answers:
	var answers := Answers.new()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return answers
	var section: Dictionary = (parsed as Dictionary).get("answers", {}) as Dictionary
	for key: String in section.keys():
		var facts := PackedStringArray()
		for fact: Variant in (section[key] as Array):
			facts.append(String(fact))
		answers._facts[StringName(key)] = facts
	return answers


static func key_for(who: StringName, intent: StringName) -> StringName:
	return StringName("%s.%s" % [who, intent])


func must_be_true(who: StringName, intent: StringName) -> PackedStringArray:
	return _facts.get(key_for(who, intent), PackedStringArray())


## Whether this answer may be written rather than looked up. The one gate: no facts,
## no generation, and the hand-written line is what the player hears.
func may_be_written(who: StringName, intent: StringName) -> bool:
	return not must_be_true(who, intent).is_empty()


func everything() -> Array[StringName]:
	var out: Array[StringName] = []
	for key: StringName in _facts.keys():
		out.append(key)
	out.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return out
