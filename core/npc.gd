class_name Npc
extends RefCounted

## A person with a sheet (SPECS §6). Content, not state: loaded once from
## content/cast.json and never mutated. What the *player* has learned from them
## lives in the fact base; where they are standing lives here because in Phase 1
## nobody moves.

var id: StringName = &""
var display_name: String = ""
var role: String = ""
var zone: StringName = &""
var tile: Vector2i = Vector2i.ZERO
var sprite: String = ""
## Strangers. A generic is one of a trade rather than one of the twenty-five: it
## shares its lines with everyone else of that trade and has no name (§6). Marked
## so nothing counts it against the roster, and so a test can tell them apart.
var generic: bool = false
var kind: StringName = &""
var greeting: String = ""
## Greetings that replace the default when a named condition holds, first match
## winning. This is how a town tells you it has changed before you ask it anything.
var alt_greetings: Array[Dictionary] = []
var options: Array[DialogueOption] = []


## A line written for this person for these circumstances, or "" if nobody wrote
## one. Kept separate from `greeting_for` so the caller can tell the difference
## between "authored for this situation" and "the everyday line" — which is what
## decides whether the shared disposition line gets a turn.
func alt_greeting_for(conditions: Dictionary) -> String:
	for alt: Dictionary in alt_greetings:
		if bool(conditions.get(alt["when"] as StringName, false)):
			return String(alt["text"])
	return ""


## What they say when you open the conversation, given how the world is.
func greeting_for(conditions: Dictionary) -> String:
	var authored: String = alt_greeting_for(conditions)
	return authored if authored != "" else greeting


func centre() -> Vector2:
	return Vector2(tile) + Vector2(0.5, 0.5)
