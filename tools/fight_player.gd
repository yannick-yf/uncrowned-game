class_name FightPlayer
extends RefCounted

## A scripted pair of hands on the player's side of a fight, so the fight can be
## *played* headless — by `tools/play_fight.gd`, by the suite, and by `UNCROWNED_FIGHT`
## when a frame of it is photographed.
##
## It is here and not in `core/` because it is not a rule of the fight: it is a stand-in
## for a person, and the simulation must never know one is there. It submits exactly
## what a keyboard would — one `fight_input` per **change** of what is held — so a fight
## it plays replays from its log like any other.
##
## The policies are the players `docs/COMBAT.md` was tuned against:
##   `stand`      does nothing. The shortest way to lose.
##   `guard`      holds the guard and never swings.
##   `competent`  closes, hits him while he is open, guards the rest of the time —
##                the loop `test_combat.gd` plays, and the one that found F1's two bugs.
##   `dodger`     the competent player who backsteps on seeing the heavy blow, at a
##                human's sixteen frames of reaction (§2), and guards the short one.

const POLICIES: Array[StringName] = [&"stand", &"guard", &"competent", &"dodger"]
## Measured human reaction, in frames — `docs/COMBAT.md` §2.
const REACTION: int = 16

var policy: StringName = &"competent"
var _held: Dictionary = {}
## The step the dodger first saw his heavy blow start, so the backstep goes in
## `REACTION` frames later and not on the frame the sprite moved.
var _saw_swing_at: int = -1
var _dodged_this_swing: bool = false


func _init(which: StringName = &"competent") -> void:
	policy = which


## One frame of decisions, submitted only when they change.
func play(sim: Sim, fight: Fight) -> void:
	if not fight.on():
		return
	var want: Dictionary = wants(fight, sim.step)
	if want != _held or bool(want.get("evade", false)):
		sim.submit(&"fight_input", want)
		_held = want


func wants(fight: Fight, step: int) -> Dictionary:
	match policy:
		&"stand":
			return {"walk": 0, "attack": false, "guard": false, "evade": false}
		&"guard":
			return {"walk": 0, "attack": false, "guard": true, "evade": false}
		&"dodger":
			return _dodger(fight, step)
	return _competent(fight)


func _competent(fight: Fight) -> Dictionary:
	if not CombatRules.reaches(fight.player_at_mm, fight.opponent_at_mm, CombatRules.STRIKE):
		return {"walk": 1, "attack": false, "guard": false, "evade": false}
	var open: bool = fight.opponent_stun > 0 or fight.opponent_move == &""
	if fight.player_free() and open:
		return {"walk": 0, "attack": true, "guard": false, "evade": false}
	return {"walk": 0, "attack": false, "guard": true, "evade": false}


## Until the heavy blow has been *perceived* — `REACTION` frames after it started — the
## dodger goes on doing whatever they were doing, as a person does; then one backstep,
## and back to closing and punishing. A first draft stood still through the reaction
## window and never landed a blow in a hundred seconds: he swings the moment you reach
## the edge of his range, you step out, walk back, and he swings again.
func _dodger(fight: Fight, step: int) -> Dictionary:
	if fight.opponent_move == CombatRules.SWING:
		if _saw_swing_at < 0:
			_saw_swing_at = step
			_dodged_this_swing = false
		if not _dodged_this_swing and step - _saw_swing_at >= REACTION and fight.player_free():
			_dodged_this_swing = true
			return {"walk": 0, "attack": false, "guard": false, "evade": true}
	else:
		_saw_swing_at = -1
	return _competent(fight)
