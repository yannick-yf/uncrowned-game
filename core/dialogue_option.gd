class_name DialogueOption
extends RefCounted

## One thing the player may say, and the one thing it means.
##
## SPECS §9: the player never types. Every utterance maps to a known intent, so
## nothing can be talked into existence that the systems did not already permit.
## The text is hand-written and looked up — never generated — and `tag` is the
## visibly trait-gated marker Fallout uses. Traits do not exist yet, so `tag` is
## display-only: it labels the option, it does not gate it.

var intent: StringName = &""
var text: String = ""
var reply: String = ""
var tag: StringName = &""
var teaches: StringName = &""
var requires: StringName = &""
var hides_after: StringName = &""


func label() -> String:
	return "[%s] %s" % [String(tag), text] if tag != &"" else text
