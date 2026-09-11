class_name WorldState
extends RefCounted

## Everything mutable about the world.
##
## Registered on the Sim as a store rather than held on a node, so that replaying
## the log into a fresh WorldState has to reproduce it exactly. Nothing here is
## written by view/; nothing here is written outside Sim.advance().

const MAX_HP: int = 10
const OVERWORLD: StringName = &"overworld"

var zones: Dictionary = {}
var current_zone: StringName = OVERWORLD

var player_pos: Vector2 = Vector2.ZERO
var player_dir: Vector2i = Vector2i.ZERO
## Last direction actually faced, so a standing figure still looks somewhere.
var player_facing: Vector2i = Vector2i(0, 1)
var player_tile_last: Vector2i = Vector2i(-1, -1)
var player_hp: int = MAX_HP
var invulnerable_until: int = 0
var king_pos: Vector2 = Vector2.ZERO
var deaths: int = 0
var touches_taken: int = 0
var reached_blackcairn: bool = false

## Conversation. Derived from events and the cast, never authored here.
var talking_to: StringName = &""
var speaker_name: String = ""
var current_line: String = ""
var options: Array[DialogueOption] = []

## The Muster, and what it holds up.
var pay_fraud_exposed: bool = false
var army_strength: int = ArmyRules.ARMY_AT_FULL_STRENGTH
var king_escort: int = ArmyRules.ESCORT_AT_FULL_STRENGTH


func region() -> Region:
	return zones.get(current_zone, null) as Region


func player_tile() -> Vector2i:
	return Vector2i(floori(player_pos.x), floori(player_pos.y))


func in_dialogue() -> bool:
	return talking_to != &""


func tiles_to_blackcairn() -> float:
	if current_zone != OVERWORLD:
		return -1.0
	return player_pos.distance_to(king_pos)


func fingerprint() -> String:
	return "zone=%s pos=%.4f,%.4f dir=%d,%d hp=%d deaths=%d touches=%d reached=%s talk=%s fraud=%s escort=%d army=%d" % [
		String(current_zone), player_pos.x, player_pos.y, player_dir.x, player_dir.y,
		player_hp, deaths, touches_taken, reached_blackcairn,
		String(talking_to), pay_fraud_exposed, king_escort, army_strength,
	]
