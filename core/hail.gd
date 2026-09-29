class_name Hail
extends RefCounted

## **Somebody calling the player over** (O16, 2026-09-29) — Yannick's « dresseur
## Pokémon »: you walk into the ground at the village's edge, Bram sees you, a '!' over
## his head, you are held, he walks over and the conversation opens without your
## asking. Once.
##
## A store like any other, rebuilt by replay: `HailSystem` is its one writer. It holds
## who is calling and how far it has got; the man himself is walked through `Walkers`,
## so everything that asks where somebody stands — both windows, the talk key, the
## fight — sees him walking without knowing why.

const IDLE: StringName = &"idle"
## He has seen you: the '!' stands over him and nobody moves yet.
const SPOTTED: StringName = &"spotted"
## He is walking over.
const COMING: StringName = &"coming"
## Beside you; the conversation is asked for.
const ARRIVED: StringName = &"arrived"
## The conversation he opened is open.
const TALKING: StringName = &"talking"
## It has closed and he is handed back to the world: waiting for anything the talk
## began — a drill, a spar — to settle before the hail is over.
const RETURNING: StringName = &"returning"

## Who calls from where: `HailRules` rows, the world's own unless a test hands others.
var rows: Array[Dictionary] = []
var who: StringName = &""
var phase: StringName = IDLE
## Steps left in the '!' beat.
var beat: int = 0
## Steps since he saw you, against the table's budget.
var spent: int = 0
## Steps the world has been quiet since the talk closed.
var quiet: int = 0
## Which way he faces: toward you.
var facing: Vector2i = Vector2i(0, 1)


func _init(p_rows: Array[Dictionary] = Places.shared().hails()) -> void:
	rows = p_rows


## Whether the player is held still: from the moment he sees you until the talk he
## opened has closed. Read by the movement system — never a flag in a window.
func holds_player() -> bool:
	return phase == SPOTTED or phase == COMING or phase == ARRIVED or phase == TALKING


## Whether the hail is walking this person, so nothing else walks them at the same time.
func walks(id: StringName) -> bool:
	return id == who and (phase == SPOTTED or phase == COMING or phase == ARRIVED)


## Whether this person opened the conversation now open by calling out — what the
## greeting's `called_out` reads. The phase, not the fact: the fact is forever, and he
## would open every conversation after with the hail.
func called_out(id: StringName) -> bool:
	return id == who and (phase == ARRIVED or phase == TALKING)


func fingerprint() -> String:
	return "hail %s %s b%d s%d q%d f%s" % [who, phase, beat, spent, quiet, facing]
