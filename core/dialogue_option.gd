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
## A named world condition, evaluated by DialogueRules. Content names it; the
## rules layer decides what it means. Dialogue that reads the world directly would
## put game logic in content/, and content cannot be reasoned about.
var requires_condition: StringName = &""
## The same, inverted: a line that exists until the world turns against it. Needed
## because a door shutting is as much a consequence as one opening, and "you may no
## longer offer to buy anything" has to be expressible as content.
var forbids_condition: StringName = &""
## What saying this asks of the listener. `goodwill` means it costs them something
## to answer — a fact confided, a favour, a name given up — and people do not do
## that for somebody they think ill of. Anything that teaches a fact is goodwill by
## default; `costs: "free"` is how content marks the one source of a fact that must
## stay open however badly the conversation is going (invariant 6).
var costs: StringName = &""


func asks_for_goodwill() -> bool:
	if costs == &"free":
		return false
	return costs == &"goodwill" or teaches != &""


func label() -> String:
	return "[%s] %s" % [String(tag), text] if tag != &"" else text
