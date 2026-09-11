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
var greeting: String = ""
var options: Array[DialogueOption] = []


func centre() -> Vector2:
	return Vector2(tile) + Vector2(0.5, 0.5)
