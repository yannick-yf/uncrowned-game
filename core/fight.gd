class_name Fight
extends RefCounted

## What is happening in a fight, this frame.
##
## A store like any other: rebuilt by replay, holding nothing the log did not put there.
## The log holds the fact that a fight began, and one event per **change** of what the
## player is holding down — not sixty events a second. Everything below is recomputed
## from those, which is `MovementSystem`'s rule applied to a faster clock.
##
## **Everything is an integer.** Positions are millimetres on the fight's one axis,
## timings are counts of sim steps. There is no float in a fight and no Godot type: a
## replay a week later lands on the same millimetre on the same frame.

## Nobody is fighting. A fight's opponent is a cast id, so this is the empty one.
const NOBODY: StringName = &""

var opponent: StringName = NOBODY
## Which way along the line the player stands: -1 left of the opponent, +1 right.
var player_side: int = -1

var player_at_mm: int = 0
var opponent_at_mm: int = 0
var opponent_hp: int = 0

## The move each is in and how many frames into it. `&""` is standing free.
var player_move: StringName = &""
var player_frame: int = 0
var opponent_move: StringName = &""
var opponent_frame: int = 0

## Frames each still owes before they can act: hitstun, blockstun, or the freeze both
## fighters share when a blow lands.
var player_stun: int = 0
var opponent_stun: int = 0
var freeze: int = 0

## What the player is holding down, remembered rather than re-sent every frame.
var pressing_attack: bool = false
var pressing_guard: bool = false
var walking: int = 0

## Set once a move has landed, so one blow cannot hit twice on its three active frames.
var player_connected: bool = false
var opponent_connected: bool = false

## How long the opponent has been standing free, so his next blow is his own decision
## and not a coin. Nothing in a fight is random.
var opponent_waited: int = 0

## Why it ended, for the journal and for whoever asked for the fight: `&"won"`,
## `&"lost"`, `&"left"`, or `&""` while it is still going.
var outcome: StringName = &""


func on() -> bool:
	return opponent != NOBODY


func apart_mm() -> int:
	return absi(opponent_at_mm - player_at_mm)


## Can this fighter start something this frame? Not while frozen, not while stunned,
## and not in the middle of a move.
func player_free() -> bool:
	return on() and freeze <= 0 and player_stun <= 0 and player_move == &""


func opponent_free() -> bool:
	return on() and freeze <= 0 and opponent_stun <= 0 and opponent_move == &""


func fingerprint() -> String:
	if not on():
		return "none"
	return "%s p=%d/%s@%d/s%d o=%d/%s@%d/s%d hp=%d f=%d %s" % [
		String(opponent), player_at_mm, String(player_move), player_frame, player_stun,
		opponent_at_mm, String(opponent_move), opponent_frame, opponent_stun,
		opponent_hp, freeze, String(outcome)]
