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
## The last step on which anything hurt the player, and how far through mending
## the next point of health is. Both are what RecoverySystem reads.
var last_hurt_step: int = 0
var mending_steps: int = 0
var king_pos: Vector2 = Vector2.ZERO
## §10 gives him a thousand and the means to lose it. Declared here so §3's "dead"
## ending is written with the other four rather than bolted on later; it cannot be
## reached until Phase 4 builds the combat screen, which is the point of deferring
## combat costing one ending rather than the climax.
var king_hp: int = 1000
## How the reign ended, or nothing. Set once — a reign ends the way a person dies.
var reign_ended: StringName = &""
var reign_ended_tick: int = -1
## Landmarks already acted on. A cold furnace is cold; there is no undoing and no
## refilling, which is what caps how far each quantity can be pushed by hand.
var spent_sites: Dictionary = {}
var last_act_step: int = -1
var last_act: StringName = &""
var last_act_seen: int = 0
var deaths: int = 0
var touches_taken: int = 0
var reached_blackcairn: bool = false

## Conversation. Derived from events and the cast, never authored here.
var talking_to: StringName = &""
var speaker_name: String = ""
var current_line: String = ""
var options: Array[DialogueOption] = []

## The Muster. Army strength and the escort live on the WorldTick store now —
## they are the world's vital signs, not the player's state, and they keep moving
## when nobody is looking at them.
var pay_fraud_exposed: bool = false
var thefts: int = 0
## Stall tile -> the tick it was last emptied. A stall you have just robbed has
## nothing left on it, which is what stops one keypress held down from starting
## fifty rumours and flooring every reputation in the region inside a second.
var robbed: Dictionary = {}
## What the last theft was, so the view can say so at the moment it happens and
## then stop saying it. The system records the facts; the window finds the words.
var last_theft_step: int = -1
var last_theft_seen: int = 0
## What you are carrying that is not yours, and where it came from. Put back on the
## stall you took it from, which is both the natural reading and what stops "give
## it back" and "take something" fighting over the same key at the same stall.
var carrying_stolen: int = 0
var stolen_from: Vector2i = Vector2i(-1, -1)
var stolen_town: StringName = &""
## Who you told about the pay fraud, or nothing. It can be told once, to one
## audience: the Muster, or a town. Spending it is §8's opportunity cost, and what
## is spent is the telling — the fact itself never leaves the fact base.
var fraud_told_to: StringName = &""


## You put it back on the stall you took it from. That is the natural reading, and
## it is also what keeps "give it back" and "take something" from fighting over one
## key — the robbed stall offers the first, every other stall still offers the
## second.
func can_give_back(stall_in_reach: Vector2i) -> bool:
	return carrying_stolen > 0 and stall_in_reach != Region.NOWHERE \
		and stall_in_reach == stolen_from


func stall_is_bare(at: Vector2i, tick: int) -> bool:
	if not robbed.has(at):
		return false
	return tick - int(robbed[at]) < CrimeRules.STALL_RESTOCK_TICKS


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


## Take a hit. Returns true if it killed. Called only by systems, inside
## Sim.advance() — it is a state transition, not a rule, and the verdict about
## *whether* you were hit belongs to the caller.
##
## One path for the king and the beasts both, so that death, the respawn and the
## grace window cannot drift apart between them.
func hurt(amount: int, step: int) -> bool:
	if step < invulnerable_until:
		return false
	player_hp = ContactRules.damage_after(player_hp, amount)
	touches_taken += 1
	last_hurt_step = step
	mending_steps = 0
	invulnerable_until = step + ContactRules.invulnerable_steps()
	if not ContactRules.is_dead(player_hp):
		return false
	deaths += 1
	player_hp = MAX_HP
	mending_steps = 0
	player_pos = region().brindle_centre()
	player_dir = Vector2i.ZERO
	player_tile_last = player_tile()
	return true


func fingerprint() -> String:
	return "zone=%s pos=%.4f,%.4f dir=%d,%d hp=%d deaths=%d touches=%d reached=%s talk=%s fraud=%s thefts=%d end=%s" % [
		String(current_zone), player_pos.x, player_pos.y, player_dir.x, player_dir.y,
		player_hp, deaths, touches_taken, reached_blackcairn,
		String(talking_to), pay_fraud_exposed, thefts, String(reign_ended),
	]
