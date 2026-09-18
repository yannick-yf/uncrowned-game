class_name CombatSystem
extends SimSystem

## The fight, resolved. **The first system in this codebase that runs on the step
## rather than the tick**, because it is the first thing the player's hands can feel
## sixty times a second.
##
## Everything here is integers and order: no physics, no randomness, no clock of its
## own. A fight is advanced only by `Sim.advance()`, so the same inputs replay to the
## same millimetre on the same frame, which is what a save in this game is made of.
##
## **The world's clock stops while it runs** (`SPECS.md` §8: *combat runs beside the sim,
## and the world clock stops during a fight*). Without that, thirty seconds of fighting
## is 1,800 steps and **two in-game hours** of grain drifting, rumours travelling and
## armies moving — a fight would cost a morning.
##
## What the log holds: `fight_began`, one event per **change** of what the player is
## holding, and `fight_left`. Positions, health, who swung and what landed are all
## recomputed — `MovementSystem`'s rule, at four times the rate.

func on_event(sim: Sim, event: SimEvent) -> void:
	var fight := sim.store(&"fight") as Fight
	if fight == null:
		return
	match event.type:
		&"fight_began":
			_begin(sim, fight, event)
		&"fight_input":
			_input(fight, event)
		&"fight_left":
			if fight.on():
				_end(sim, fight, &"left")


func on_step(sim: Sim, _step: int) -> void:
	# **This runs sixty times a second for every simulation in the game, fighting or
	# not**, so the path where nobody is fighting is one store lookup and a return. It
	# is written that way on principle and not on evidence: the suite was measured with
	# this system registered and with it taken out, and the difference was inside the
	# noise — 42.8 s against 42.2 s. Kept because it is also the clearer shape.
	var fight := sim.store(&"fight") as Fight
	if fight == null or not fight.on():
		# The world's clock is held for exactly as long as somebody is fighting, and it
		# is recomputed every step rather than remembered, so a fight that ended cannot
		# leave it on. **This is its only writer.**
		sim.ticks_held = false
		return
	sim.ticks_held = true
	var world := sim.store(&"world") as WorldState
	if world == null:
		return

	# The freeze both fighters share when a blow lands, before anything else moves.
	if fight.freeze > 0:
		fight.freeze -= 1
		return

	_advance_move(fight, true)
	_advance_move(fight, false)
	_count_down(fight)
	_walk(fight)
	_decide(fight)
	_resolve(sim, fight, world)
	_finish(sim, fight, world)


# ------------------------------------------------------------------ the fight ---

func _begin(sim: Sim, fight: Fight, event: SimEvent) -> void:
	if fight.on():
		return
	var who: StringName = StringName(String(event.data.get("opponent", "")))
	if who == Fight.NOBODY:
		return
	var apart: int = CombatRules.start_apart_mm()
	fight.opponent = who
	fight.player_side = -1
	fight.player_at_mm = 0
	fight.opponent_at_mm = apart
	fight.opponent_hp = CombatRules.opponent_hp()
	fight.player_move = &""
	fight.opponent_move = &""
	fight.player_frame = 0
	fight.opponent_frame = 0
	fight.player_stun = 0
	fight.opponent_stun = 0
	fight.freeze = 0
	fight.pressing_attack = false
	fight.pressing_guard = false
	fight.walking = 0
	fight.player_connected = false
	fight.opponent_connected = false
	fight.opponent_waited = 0
	fight.outcome = &""
	sim.derive(&"fight_ready", {"opponent": String(who), "apart_mm": apart})


## One event per change of what the player holds, never one a frame.
func _input(fight: Fight, event: SimEvent) -> void:
	if not fight.on():
		return
	if event.data.has("attack"):
		fight.pressing_attack = bool(event.data["attack"])
	if event.data.has("guard"):
		fight.pressing_guard = bool(event.data["guard"])
	if event.data.has("walk"):
		fight.walking = signi(int(event.data["walk"]))


## A move runs its frames whatever else happens; nothing interrupts it but a blow.
func _advance_move(fight: Fight, is_player: bool) -> void:
	var move: StringName = fight.player_move if is_player else fight.opponent_move
	if move == &"":
		return
	var frame: int = (fight.player_frame if is_player else fight.opponent_frame) + 1
	if frame >= CombatRules.length(move):
		if is_player:
			fight.player_move = &""
			fight.player_frame = 0
			fight.player_connected = false
		else:
			fight.opponent_move = &""
			fight.opponent_frame = 0
			fight.opponent_connected = false
		return
	if is_player:
		fight.player_frame = frame
	else:
		fight.opponent_frame = frame


func _count_down(fight: Fight) -> void:
	fight.player_stun = maxi(fight.player_stun - 1, 0)
	fight.opponent_stun = maxi(fight.opponent_stun - 1, 0)


## Walking, and the pushbox: two fighters cannot stand in the same millimetre.
func _walk(fight: Fight) -> void:
	if not fight.player_free() or fight.walking == 0 or fight.pressing_guard:
		return
	var step: int = CombatRules.walk_mm_per_step() * signi(fight.walking)
	var wanted: int = fight.player_at_mm + step
	# Never past him, and never further than the line allows.
	var closest: int = fight.opponent_at_mm - CombatRules.slack_mm() * 2
	fight.player_at_mm = mini(wanted, closest) if step > 0 else maxi(wanted, -CombatRules.start_apart_mm())


## The player swings when they press it; the opponent swings when he has waited long
## enough and the player is within his reach. **Nothing here is a coin.** He is a
## pattern to be learnt, which is what a twenty-four frame wind-up is for.
func _decide(fight: Fight) -> void:
	if fight.player_free() and fight.pressing_attack and not fight.pressing_guard:
		fight.player_move = CombatRules.STRIKE
		fight.player_frame = 0
		fight.player_connected = false

	# **Being hit does not make him forget he was waiting.** The first build reset this
	# whenever he was stunned, and the player's blow leaves +2 — so a player who simply
	# kept hitting never gave him the twenty-four free frames his swing needs, and he
	# died without ever raising his arm. That is the genre's oldest bug, an infinite, and
	# it was found by playing the fight rather than by a test.
	if not fight.opponent_free():
		return
	fight.opponent_waited += 1
	# **He closes.** Without this the fight deadlocks the first time he is knocked back:
	# one blow puts him past both reaches and he stands there for ever, which is exactly
	# what the first run of it did. An opponent who does not walk is a target.
	var in_reach: bool = CombatRules.reaches(fight.opponent_at_mm, fight.player_at_mm, CombatRules.SWING)
	if not in_reach:
		var toward: int = -1 if fight.opponent_at_mm > fight.player_at_mm else 1
		var closest: int = fight.player_at_mm - toward * CombatRules.slack_mm() * 2
		var wanted: int = fight.opponent_at_mm + CombatRules.walk_mm_per_step() * toward
		fight.opponent_at_mm = maxi(wanted, closest) if toward < 0 else mini(wanted, closest)
		return
	if fight.opponent_waited >= CombatRules.of(CombatRules.SWING, "startup"):
		fight.opponent_move = CombatRules.SWING
		fight.opponent_frame = 0
		fight.opponent_connected = false
		fight.opponent_waited = 0


## Whose blow is out this frame, and does it reach. Two integers and a subtraction.
func _resolve(sim: Sim, fight: Fight, world: WorldState) -> void:
	_try(sim, fight, world, true)
	_try(sim, fight, world, false)


func _try(sim: Sim, fight: Fight, world: WorldState, by_player: bool) -> void:
	var move: StringName = fight.player_move if by_player else fight.opponent_move
	var frame: int = fight.player_frame if by_player else fight.opponent_frame
	var already: bool = fight.player_connected if by_player else fight.opponent_connected
	if move == &"" or already or not CombatRules.is_active(move, frame):
		return
	var from_mm: int = fight.player_at_mm if by_player else fight.opponent_at_mm
	var to_mm: int = fight.opponent_at_mm if by_player else fight.player_at_mm
	if not CombatRules.reaches(from_mm, to_mm, move):
		return

	# A guard is only a guard while nothing of yours is out.
	var guarding: bool = (not by_player) and fight.pressing_guard and fight.player_move == &""
	var damage: int = CombatRules.damage_through(move, guarding)
	var stun: int = CombatRules.stun_from(move, guarding)
	var back: int = CombatRules.knockback_from(move, guarding)

	if by_player:
		fight.player_connected = true
		fight.opponent_hp = maxi(fight.opponent_hp - damage, 0)
		fight.opponent_stun = stun
		fight.opponent_at_mm += back
	else:
		fight.opponent_connected = true
		fight.player_stun = stun
		fight.player_at_mm -= back
		# One path for everything that can hurt you: the same one the king's touch
		# uses, so death, the grace window and the respawn cannot drift apart.
		world.hurt(damage, sim.step)
	fight.freeze = CombatRules.hitstop(move)
	sim.derive(&"blow_landed", {
		"by": "player" if by_player else String(fight.opponent),
		"move": String(move), "damage": damage, "guarded": guarding,
		"opponent_hp": fight.opponent_hp, "player_hp": world.player_hp,
	})


func _finish(sim: Sim, fight: Fight, world: WorldState) -> void:
	if CombatRules.is_down(fight.opponent_hp):
		_end(sim, fight, &"won")
	elif world.player_hp >= WorldState.MAX_HP and world.deaths > 0 and fight.player_stun > 0:
		# `hurt()` already respawned them somewhere else. The fight cannot follow.
		_end(sim, fight, &"lost")


func _end(sim: Sim, fight: Fight, how: StringName) -> void:
	var who: StringName = fight.opponent
	fight.outcome = how
	fight.opponent = Fight.NOBODY
	fight.player_move = &""
	fight.opponent_move = &""
	fight.pressing_attack = false
	fight.pressing_guard = false
	fight.walking = 0
	# **The hold is not released here**, though it is tempting. `on_step` sets it from
	# the store at the top of every step and the tick is checked at the bottom of the
	# same one, so clearing it in the middle lets the world tick on the frame the last
	# blow lands — which a test caught on frame 262 of a fight that was still running.
	# One writer, once a step. The next step turns it off on its own.
	sim.derive(&"fight_ended", {"opponent": String(who), "how": String(how)})


## Sixty times a second, which is the point of it.
func steps() -> bool:
	return true


## And never on the world's clock, which it holds still anyway.
func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"combat"
