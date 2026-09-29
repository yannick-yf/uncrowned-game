class_name DuelSystem
extends SimSystem

## The fight, resolved — second design (K1, K2; `docs/COMBAT_V2.md`).
##
## **The only fight there is, since K6** (2026-09-26). It was built beside the first
## design's real-time fight, the game was switched over to it, Yannick played it, and
## the first design was deleted.
##
## **Turn-based, on the world grid.** Everybody in the fight acts once per round in a
## fixed order, and **whoever started it acts first** — there is no initiative roll,
## because there are no dice anywhere in this design. On their turn a fighter **moves
## and acts**: up to `tiles_per_turn` tiles of the game's own 8-way movement, then one
## of two actions — **strike** or **wait**. There is no guard (Yannick, 2026-09-24):
## Baldur's Gate 3 has no block button and neither does this. Defence is position and
## initiative.
##
## **What the log holds: `duel_began`, one event per turn, `duel_ended`.** A fight of
## twenty turns is twenty events, which is fewer than the first design rather than
## more. The player's turn is the event they submitted; an opponent's turn is derived,
## as a record of what the world did — recomputed on replay from the same state, never
## re-injected, which is `Sim`'s rule and not a special case for fighting.
##
## **The world's clock is held for the duration** (`Sim.ticks_held`), and this system
## is its only writer: every step it sets it to whether a duel is on. Recomputed, never
## remembered — so a fight that ended cannot leave the world stopped.
##
## A turn takes real steps to play out — the walk, the wind-up, the blow, the recovery
## — because a turn nobody can see is not a turn. Every one of those counts is an
## integer in `content/duel.json`, so the same fight replays step for step.

## What a strike with a bow is called where it lands (T5).
const ARROW: StringName = &"arrow"


func on_event(sim: Sim, event: SimEvent) -> void:
	var duel := sim.store(&"duel") as Duel
	if duel == null:
		return
	match event.type:
		&"duel_began":
			_begin(sim, duel, event)
		&"duel_turn":
			# Our own record of an opponent's turn, replayed back at us. The turn was
			# resolved when it was decided; reading it again would take it twice.
			if event.derived:
				return
			_player_turn(sim, duel, event)
		&"duel_left":
			if duel.on():
				_decided(sim, duel, &"left")


func on_step(sim: Sim, _step: int) -> void:
	var duel := sim.store(&"duel") as Duel
	# The path where nobody is fighting is one store lookup, one write and a return,
	# which is what it costs every other simulation in the game. **The write is not
	# optional** (K6): this is the only thing that turns the hold off, and without it
	# the first fight of the game would stop the world's clock for good.
	if duel == null or not duel.on():
		sim.ticks_held = false
		return
	sim.ticks_held = true
	var world := sim.store(&"world") as WorldState
	if world == null:
		return

	for fighter: DuelFighter in duel.fighters:
		fighter.hurt_left = maxi(fighter.hurt_left - 1, 0)

	# **The beat** (kept from the first design, H5): decided, not over. Everybody stands
	# where the last blow left them, the clock is still held, and nothing anybody presses
	# does anything. Then the world comes back.
	if duel.settling > 0:
		duel.settling -= 1
		if duel.settling <= 0:
			_end(sim, duel, duel.outcome, world)
		else:
			_stand(duel, world)
		return

	match duel.phase:
		Duel.WAITING:
			pass
		Duel.MOVING:
			_walk_on(duel)
		Duel.ACTING:
			_act_on(sim, duel, world)
		Duel.PAUSING:
			duel.phase_left -= 1
			if duel.phase_left <= 0:
				_next_turn(sim, duel, world)
	_stand(duel, world)


## **Where the player stands while a fight is on.** `MovementSystem` stands down for a
## duel exactly as it does for the first design's fight and for a conversation, so there
## is still only one hand on the player's position at a time.
func _stand(duel: Duel, world: WorldState) -> void:
	var mine: DuelFighter = duel.me()
	if mine == null:
		return
	world.player_pos = duel.drawn_at(mine)
	world.player_facing = mine.facing


# ------------------------------------------------------------------- beginning ---

func _begin(sim: Sim, duel: Duel, event: SimEvent) -> void:
	if duel.on():
		return
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	if world == null:
		return
	var against: Array[StringName] = _named(event, cast)
	if against.is_empty():
		return

	var mine := DuelFighter.new()
	mine.who = DuelRules.PLAYER
	# **The world's bar, not one of the fight's own** (Yannick, 2026-09-24). A fight
	# does not hand the player a fresh hundred; it spends what he walked in with.
	mine.hp = world.player_hp
	mine.max_hp = WorldState.MAX_HP
	mine.at = world.player_tile()
	mine.facing = world.player_facing
	duel.fighters = [mine]
	duel.began_at = mine.at

	var region: Region = world.region()
	var taken: Dictionary = {mine.at: true}
	var seats: Dictionary = {}
	for who: StringName in against:
		var him := DuelFighter.new()
		# **A seat, when the kind repeats.** Three wolves are three fighters; without
		# this they are one fighter found three times, and a blow aimed at the second
		# lands on the first — which is dead by then.
		seats[who] = int(seats.get(who, 0)) + 1
		him.who = who if seats[who] == 1 else StringName("%s#%d" % [who, seats[who]])
		him.hp = DuelRules.hp_of(who)
		him.max_hp = him.hp
		him.weapon = DuelRules.weapon_of(who)
		var npc: Npc = cast.get_npc(who) if cast != null else null
		# Where he actually stands, which is not always his post (O7).
		var walkers := sim.store(&"walkers") as Walkers
		var stands: Vector2i = mine.at + Vector2i(1, 0)
		if npc != null:
			stands = walkers.where(npc) if walkers != null else npc.tile
		# **Squared up.** Somebody already beside you keeps the ground they are standing
		# on; somebody who is not is set down a stride away on the side they are already
		# on, so nobody is spun round and nobody teleports far. A fight begins because
		# there is a person in front of you — a debug photograph taken in a town where
		# the man is three hundred tiles away would otherwise be a picture of nothing.
		if npc == null or DuelRules.apart(stands, mine.at) > DuelRules.tiles_per_turn():
			stands = DuelRules.stand_off(mine.at, stands, region, DuelRules.stand_off_tiles())
		while taken.has(stands):
			stands += Vector2i(0, 1)
		taken[stands] = true
		him.at = stands
		him.facing = DuelRules.facing_from(him.at, mine.at)
		duel.fighters.append(him)

	mine.facing = DuelRules.facing_from(mine.at, duel.fighters[1].at)
	duel.asked_by = StringName(String(event.data.get("asked_by", "")))
	duel.started_by = StringName(String(event.data.get("by", String(DuelRules.PLAYER))))
	duel.round_number = 0
	duel.turns_taken = 0
	duel.outcome = Duel.NOBODY
	duel.settling = 0
	duel.owed_damage = 0
	duel.player_felled = false
	duel.felled_by = Duel.NOBODY
	duel.spar = bool(event.data.get("spar", false))
	duel.drill = StringName(String(event.data.get("drill", "")))
	duel.tally = 0
	# **Who answers the attack** (T9): the yard, for a gatekeeper — read from the trade of
	# the one this fight is against.
	duel.reinforced_by = Duel.NOBODY
	var answer: Dictionary = DuelRules.reinforcement(DuelRules.trade_of(against[0]))
	if not answer.is_empty():
		duel.reinforced_by = StringName(String(answer.get("kind", "")))
		duel.reinforce_from = region.resolve({"point": StringName(String(answer.get("from_point", "")))})
		if duel.reinforce_from == Region.NOWHERE:
			duel.reinforce_from = duel.fighters[1].at
		duel.reinforce_every = maxi(int(answer.get("every_rounds", 1)), 1)
		duel.reinforce_most = maxi(int(answer.get("most_at_once", 1)), 1)
	duel.said = String(event.data.get("said", ""))
	duel.said_by = StringName(String(event.data.get("said_by", "")))
	duel.master_at = Duel.NOWHERE
	if duel.drill != Duel.NOBODY:
		var master: StringName = DuelRules.drill_master(duel.drill)
		if duel.get_fighter(master) == null and cast != null and cast.get_npc(master) != null:
			var walkers := sim.store(&"walkers") as Walkers
			duel.master_at = walkers.where(cast.get_npc(master)) if walkers != null \
				else cast.get_npc(master).tile
	# **Whoever started the fight acts first.** A player who opens on somebody gets the
	# first blow, which is the right incentive: attacking from a conversation should be
	# an advantage, and the price should be paid in standing rather than in mechanics.
	duel.turn = 0
	for index: int in duel.fighters.size():
		if duel.fighters[index].who == duel.started_by:
			duel.turn = index
			break
	sim.derive(&"duel_ready", {
		"opponent": String(duel.fighters[1].who),
		"first": String(duel.fighters[duel.turn].who),
	})
	_open_turn(sim, duel, world)


## Who the fight is against: one name, or a list of them. There is no party — the
## player fights alone — but *you can kill everyone* means drawing on three people in a
## yard, so the fight itself is written for a list.
## **A person appears once; a species appears as often as it is named** (W1,
## 2026-09-25). This used to refuse every repeat, which is right for Harry — a man
## cannot be in a fight twice — and wrong for a wolf, where the danger is *three of
## them*. So the guard now asks the cast: somebody it knows is a person and is taken
## once, and anything it does not know is a kind and may repeat.
func _named(event: SimEvent, cast: Cast) -> Array[StringName]:
	var out: Array[StringName] = []
	var one: String = String(event.data.get("opponent", ""))
	if one != "":
		out.append(StringName(one))
	for row: Variant in event.data.get("opponents", []) as Array:
		var who := StringName(String(row))
		if who == Duel.NOBODY:
			continue
		var a_person: bool = cast != null and cast.get_npc(who) != null
		if a_person and out.has(who):
			continue
		out.append(who)
	return out


# ----------------------------------------------------------------------- a turn ---

## The turn of whoever `duel.turn` points at. The player's is waited for; anybody
## else's is decided here and now, by the one rule in `DuelRules.decide`.
func _open_turn(sim: Sim, duel: Duel, world: WorldState) -> void:
	var who: DuelFighter = duel.acting_fighter()
	if who == null:
		return
	duel.walk = []
	duel.walked = 0
	duel.struck = false
	if who.is_player():
		duel.phase = Duel.WAITING
		duel.phase_left = 0
		return
	_choose(sim, duel, world, who)


## What somebody who is not the player does with their turn.
func _choose(sim: Sim, duel: Duel, world: WorldState, who: DuelFighter) -> void:
	if who == null or not who.alive():
		_next_turn(sim, duel, world)
		return
	# **A drill's opening** (O8): the master's first act is to walk off, further than one
	# turn can close and strike, so the first thing the lesson teaches is to move. Walked,
	# not set down — the player sees him step back and why.
	if duel.drill != Duel.NOBODY and duel.turns_taken == 0 \
			and DuelRules.kind_of(who.who) == DuelRules.drill_first(duel.drill):
		var mine: DuelFighter = duel.me()
		var apart: int = DuelRules.drill_stand_off(duel.drill)
		var to: Vector2i = DuelRules.step_back(who.at, mine.at, world.region(), apart, _taken(duel, who))
		_take(sim, duel, world, who, to, DuelRules.WAIT, Duel.NOBODY, true,
			DuelRules.walk_back_budget(apart))
		return
	var chosen: Dictionary = DuelRules.decide(
		who, duel.foes_of(who.who), world.region(), duel.began_at, _taken(duel, who))
	_take(sim, duel, world, who,
		chosen["to"] as Vector2i,
		chosen["action"] as StringName,
		chosen["target"] as StringName,
		true)


## The player said what they do. Read once, validated, and taken.
##
## **A turn is never dropped.** A destination the player cannot reach becomes standing
## still, and a strike at nobody in reach becomes a wait — deterministic either way,
## and the window only ever offers what the rules allow. An event that arrives when it
## is not the player's turn is ignored, which is the same answer on a replay.
func _player_turn(sim: Sim, duel: Duel, event: SimEvent) -> void:
	if not duel.waiting_on_player():
		return
	var world := sim.store(&"world") as WorldState
	if world == null:
		return
	var mine: DuelFighter = duel.acting_fighter()
	var wanted := Vector2i(int(event.data.get("to_x", mine.at.x)), int(event.data.get("to_y", mine.at.y)))
	var cost: Dictionary = DuelRules.reachable(
		mine.at, world.region(), DuelRules.tiles_per_turn(), _taken(duel, mine))
	if not cost.has(wanted):
		wanted = mine.at
	# **What he strikes with is his turn's to say** (T5), and a bow only if he has one of
	# his own: asked for without it, it is the sword in his hand.
	mine.weapon = DuelRules.SWORD
	if String(event.data.get("weapon", "")) == String(DuelRules.BOW) and sim.facts.has(DuelRules.THE_BOW):
		mine.weapon = DuelRules.BOW
	# **Two actions, and there is no guard** (Yannick, 2026-09-24). Anything that is not
	# a strike is a wait: a window asking for a third one is a window out of date with
	# the design, and the fight answers it with the one action that always exists rather
	# than by dropping the turn.
	var asked: String = String(event.data.get("action", ""))
	var action: StringName = DuelRules.WAIT
	if asked == String(DuelRules.STRIKE):
		action = DuelRules.STRIKE
	elif asked == String(DuelRules.CAST):
		action = DuelRules.CAST
	var at := StringName(String(event.data.get("target", "")))
	# **The gift, cast** (O10): only by somebody she gave it to, when it is ready, at
	# somebody within its reach of where the move ends — anything else is a wait.
	if action == DuelRules.CAST:
		var aimed: DuelFighter = duel.get_fighter(at)
		if not sim.facts.has(OpeningRules.GIFT):
			action = DuelRules.WAIT
		else:
			if aimed == null or not aimed.alive() \
					or not DuelRules.can_cast(mine, duel.round_number, wanted, aimed.at):
				aimed = null
				for foe: DuelFighter in duel.foes_of(mine.who):
					if DuelRules.can_cast(mine, duel.round_number, wanted, foe.at):
						aimed = foe
						break
			if aimed == null:
				action = DuelRules.WAIT
				at = Duel.NOBODY
			else:
				at = aimed.who
	if action == DuelRules.STRIKE:
		var victim: DuelFighter = duel.get_fighter(at)
		if victim == null or not victim.alive() or not DuelRules.reaches(mine.weapon, wanted, victim.at):
			at = Duel.NOBODY
			for foe: DuelFighter in duel.foes_of(mine.who):
				if DuelRules.reaches(mine.weapon, wanted, foe.at):
					at = foe.who
					break
		if at == Duel.NOBODY:
			action = DuelRules.WAIT
	_take(sim, duel, world, mine, wanted, action, at, false)


## One turn, taken: the way there, and what happens at the end of it.
##
## `record` says whether this turn needs writing down. The player's does not — the
## event they submitted is already the record, and deriving a second one would make a
## fight of twenty turns twenty-five events.
func _take(
	sim: Sim,
	duel: Duel,
	world: WorldState,
	who: DuelFighter,
	to: Vector2i,
	action: StringName,
	at: StringName,
	record: bool,
	budget: int = -1,
) -> void:
	# `budget` is a turn's tiles, except for a drill's opening walk (O8).
	var tiles: int = DuelRules.tiles_per_turn() if budget < 0 else budget
	var cost: Dictionary = DuelRules.reachable(who.at, world.region(), tiles, _taken(duel, who))
	duel.walk = DuelRules.path_to(who.at, to, cost)
	duel.walked = 0
	duel.acting = action
	duel.target = at
	duel.struck = false
	duel.turns_taken += 1
	if record:
		var turn: Dictionary = {
			"who": String(who.who), "to_x": to.x, "to_y": to.y,
			"action": String(action), "target": String(at),
		}
		sim.derive(&"duel_turn", turn)
	if duel.walk.is_empty():
		_start_acting(duel, who)
	else:
		duel.phase = Duel.MOVING
		duel.phase_left = 0


func _start_acting(duel: Duel, who: DuelFighter) -> void:
	duel.phase = Duel.ACTING
	duel.phase_left = DuelRules.act_steps()
	var victim: DuelFighter = duel.get_fighter(duel.target)
	if victim != null:
		who.facing = DuelRules.facing_from(who.at, victim.at)


## Walking, one tile at a time, at the pace the player walks everywhere else.
func _walk_on(duel: Duel) -> void:
	var who: DuelFighter = duel.acting_fighter()
	if who == null or duel.walk.is_empty():
		_start_acting(duel, who)
		return
	who.facing = DuelRules.facing_from(who.at, duel.walk[0])
	duel.walked += 1
	if duel.walked < DuelRules.steps_per_tile():
		return
	who.at = duel.walk.pop_front() as Vector2i
	duel.walked = 0
	if duel.walk.is_empty():
		_start_acting(duel, who)


## The blow: a wind-up, the step it lands, and the recovery after it.
func _act_on(sim: Sim, duel: Duel, world: WorldState) -> void:
	var who: DuelFighter = duel.acting_fighter()
	if who == null:
		_next_turn(sim, duel, world)
		return
	var into: int = duel.into_act()
	if duel.acting == DuelRules.STRIKE and not duel.struck and into >= DuelRules.strike_at_step():
		_strike(sim, duel, world, who)
	# The gift lands at range, through the same door (O10).
	if duel.acting == DuelRules.CAST and not duel.struck and into >= DuelRules.strike_at_step():
		_cast(sim, duel, world, who)
	duel.phase_left -= 1
	if duel.phase_left <= 0:
		_end_turn(sim, duel, world)


## **A blow lands for a fixed number and does not move anybody** (Yannick, 2026-09-24).
## The one who takes it plays the flinch and stays on their tile: no knockback, no
## pushbox, no shove. A hit that moved you would make position depend on the enemy's
## dice, and there are no dice.
##
## **An arrow is a strike with a bow** (T5): it lands on this act, like a blow, on whoever
## the archer shot — « je tire, ça tire » — and is named `arrow` where it lands.
func _strike(sim: Sim, duel: Duel, world: WorldState, who: DuelFighter) -> void:
	duel.struck = true
	var move: StringName = ARROW if who.weapon == DuelRules.BOW else DuelRules.STRIKE
	var victim: DuelFighter = duel.get_fighter(duel.target)
	if victim == null or not victim.alive() or not DuelRules.reaches(who.weapon, who.at, victim.at):
		sim.derive(&"blow_missed", {"by": _named_as(who), "move": String(move)})
		return
	# In a drill the master's blow costs the drill's figure, and yours what it always does.
	var amount: int = DuelRules.damage_with(who.weapon)
	if duel.drill != Duel.NOBODY and not who.is_player():
		amount = DuelRules.drill_damage(duel.drill)
	_land(sim, duel, world, who, victim, amount, move)


## **The one door every hit goes through** (O5, 2026-09-29): a blow, and in time an
## arrow and a spell. Whatever lands here keeps `G`, the world's bar, the flinch, the
## facing, the felling and the one `blow_landed` the window reads — so nothing that
## hurts in a fight can quietly skip a rule the sword obeys.
func _land(sim: Sim, duel: Duel, world: WorldState, who: DuelFighter,
		victim: DuelFighter, amount: int, move: StringName) -> void:
	var damage: int = amount
	# **`G` still means what it says.** The one development tool that makes the player
	# unkillable is read here as well as in `WorldState.hurt`, because a fight that
	# drained a bar nothing was allowed to empty would be a fight the HUD lied about.
	if victim.is_player() and world != null and world.unkillable:
		damage = mini(damage, maxi(victim.hp - 1, 0))
	# **Nobody falls in a drill** (the review of O21). A lesson ends on its goal or its
	# rounds, never on a partner going down: the sword's third blow took Bram's fifteen
	# to nothing, he yielded, and the lesson counted as having beaten him — so he offered
	# a fight to the death straight after it. The partner stops at one point.
	if duel.drill != Duel.NOBODY and not victim.is_player():
		damage = mini(damage, maxi(victim.hp - 1, 0))
	victim.hp = maxi(victim.hp - damage, 0)
	# **And the world is where a player's blow is actually paid** (2026-09-24), through
	# the one door everything that hurts him goes through, so `G`, the grace window and
	# the death count all keep working inside a fight. The felling blow is the one
	# exception and it is paid when the beat is over, a dozen lines below: paying it
	# here would wake him at the last fire in the middle of his own death scene.
	if victim.is_player() and world != null and not DuelRules.is_down(victim.hp):
		world.hurt(damage, sim.step, false)
		victim.hp = world.player_hp
	victim.hurt_left = DuelRules.hurt_steps()
	victim.facing = DuelRules.facing_from(victim.at, who.at)
	# A drill counts the blows you land, when landing blows is its goal (O8) — sword blows:
	# a spell from three tiles is not the sword lesson (the review of O21) — and the arrows,
	# when the lesson is the bow's (T5).
	if duel.drill != Duel.NOBODY and who.is_player():
		var goal: StringName = DuelRules.drill_goal(duel.drill)
		if (goal == &"blows" and move == DuelRules.STRIKE) or (goal == &"arrows" and move == ARROW):
			duel.tally += 1
	if victim.is_player() and DuelRules.is_down(victim.hp):
		# Down is down whether or not he finishes it: recorded on the step the blow
		# lands and **paid when the beat is over**, so the picture can show you down
		# where you fell rather than already awake at the last fire.
		duel.player_felled = true
		duel.felled_by = who.who
	var mine: DuelFighter = duel.me()
	var foe: DuelFighter = duel.foe()
	sim.derive(&"blow_landed", {
		"by": _named_as(who), "target": String(victim.who),
		"move": String(move), "damage": damage, "guarded": false,
		"at_x": victim.at.x, "at_y": victim.at.y,
		"opponent_hp": foe.hp if foe != null else 0,
		"player_hp": mine.hp if mine != null else 0,
		"apart_mm": DuelRules.millimetres_of(DuelRules.apart(who.at, victim.at)),
		"felled": DuelRules.is_down(victim.hp),
	})


## **The fairy's gift, landing** (O10): at range, for the spell's figure, and not again
## for `spell_every_rounds` rounds.
func _cast(sim: Sim, duel: Duel, world: WorldState, who: DuelFighter) -> void:
	duel.struck = true
	who.ready_round = duel.round_number + DuelRules.spell_every_rounds()
	var victim: DuelFighter = duel.get_fighter(duel.target)
	if victim == null or not victim.alive() \
			or DuelRules.apart(who.at, victim.at) > DuelRules.spell_reach_tiles():
		sim.derive(&"blow_missed", {"by": _named_as(who), "move": String(DuelRules.CAST)})
		return
	sim.derive(&"spell_cast", {"by": _named_as(who), "x": victim.at.x, "y": victim.at.y})
	if duel.drill != Duel.NOBODY and who.is_player() and DuelRules.drill_goal(duel.drill) == &"spells":
		duel.tally += 1
	_land(sim, duel, world, who, victim, DuelRules.spell_damage(), &"spell")


## `"player"` or a cast id, which is the word the window's blows already speak.
func _named_as(who: DuelFighter) -> String:
	return "player" if who.is_player() else String(who.who)


# ------------------------------------------------------- the end of a turn, and of it ---

func _end_turn(sim: Sim, duel: Duel, world: WorldState) -> void:
	duel.walk = []
	duel.walked = 0
	if _settle(sim, duel):
		return
	duel.phase = Duel.PAUSING
	duel.phase_left = DuelRules.pause_steps()
	if duel.phase_left <= 0:
		_next_turn(sim, duel, world)


## **What a blow leaves settled**, after the end of a turn and after an arrow lands (the
## review of O9 found the arrow did not): anybody at nothing goes out, a drill whose goal
## is reached is passed, and a fight with a side empty is decided. True when it is.
func _settle(sim: Sim, duel: Duel) -> bool:
	for fighter: DuelFighter in duel.fighters:
		if fighter.alive() and DuelRules.is_down(fighter.hp):
			fighter.out = true
			# **In a spar the partner yields** (O1, 2026-09-29): out of the fight, not out
			# of the world. `duel_down` is what `FellingSystem` answers with a killing, so
			# a yield must never raise it. The player still goes out *down* — the spar's
			# floor in `_end` is what keeps him standing — or `_over` would read a lost
			# spar as a fight he walked out of.
			if duel.spar and not fighter.is_player():
				fighter.how_out = &"yielded"
				sim.derive(&"duel_yielded", {"who": String(fighter.who)})
				continue
			fighter.how_out = &"down"
			sim.derive(&"duel_down", {"who": String(fighter.who)})
	# **A drill is passed the moment its goal is reached** (O8), whether or not anybody
	# is down.
	if duel.drill != Duel.NOBODY and duel.outcome == Duel.NOBODY \
			and duel.tally >= DuelRules.drill_count(duel.drill):
		_decided(sim, duel, &"won")
		return true
	return _over(sim, duel)


## The next living fighter in the fixed order. Wrapping past the end of the list is the
## end of a round, and the end of a round is when leaving is settled.
func _next_turn(sim: Sim, duel: Duel, world: WorldState) -> void:
	var count: int = duel.fighters.size()
	var wrapped: bool = false
	for offset: int in range(1, count + 1):
		var index: int = duel.turn + offset
		if index >= count:
			index -= count
			if not wrapped:
				wrapped = true
				duel.round_number += 1
				_settle_leaving(sim, duel)
				_reinforce(sim, duel, world)
				if _over(sim, duel):
					return
				# And failed when its rounds run out first (O8).
				if duel.drill != Duel.NOBODY and duel.round_number >= DuelRules.drill_rounds(duel.drill):
					_decided(sim, duel, &"failed")
					return
		if duel.fighters[index].alive():
			duel.turn = index
			_open_turn(sim, duel, world)
			return
	_over(sim, duel)


## **Out of reach and staying there is leaving**, for the player exactly as for anybody
## (`docs/COMBAT_V2.md` §7). Counted once a round rather than once a turn: stepping four
## tiles back is not leaving when the man in front of you has his own turn to close it,
## and one round of it is not *staying* — the round is counted first and the ending only
## comes when the count is up, or the fight would end for whoever happened to move last.
func _settle_leaving(sim: Sim, duel: Duel) -> void:
	# A drill's first round is its master's opening walk, which leaves everybody apart on
	# purpose; it is not a round anybody spent away (the review of O8).
	if duel.drill != Duel.NOBODY and duel.round_number <= 1:
		return
	for fighter: DuelFighter in duel.fighters:
		if not fighter.alive():
			continue
		var foes: Array[DuelFighter] = duel.foes_of(fighter.who)
		if not DuelRules.out_of_reach(fighter, foes):
			fighter.away_rounds = 0
			continue
		fighter.away_rounds += 1
		if not DuelRules.has_left(fighter, foes):
			continue
		fighter.out = true
		fighter.how_out = &"left"
		sim.derive(&"duel_fled", {"who": String(fighter.who)})


## **A fight ends when somebody reaches 0, or when one side has nobody left in it** —
## dead or gone, and fleeing counts as leaving. Symmetry is the whole reason it needs
## no extra rule for the player.
func _over(sim: Sim, duel: Duel) -> bool:
	if duel.settling > 0 or duel.outcome != Duel.NOBODY:
		return true
	var mine: DuelFighter = duel.me()
	if mine == null:
		return false
	if not mine.alive():
		_decided(sim, duel, &"lost" if mine.how_out == &"down" else &"left")
		return true
	if duel.foes_of(mine.who).is_empty():
		# **Not won while more are coming** (T9): the yard sends the next at the round's end.
		if duel.reinforced_by != Duel.NOBODY:
			return false
		# A drill won by beating the partner before the lesson is learnt is not passed
		# (O9): the goal is the lesson, not the yield.
		var missed: bool = duel.drill != Duel.NOBODY and duel.tally < DuelRules.drill_count(duel.drill)
		_decided(sim, duel, &"failed" if missed else &"won")
		return true
	return false


## Decided: the outcome is known on this step and said once, for whoever is drawing the
## fight. The fight itself stays on for the beat and hands its one result back at the
## end of it.
func _decided(sim: Sim, duel: Duel, how: StringName) -> void:
	duel.outcome = how
	duel.settling = DuelRules.beat_steps()
	duel.phase = &""
	var foe: DuelFighter = duel.foe()
	sim.derive(&"duel_decided", {
		"opponent": String(foe.who) if foe != null else "", "how": String(how),
		"spar": duel.spar,
	})
	if duel.settling <= 0:
		_end(sim, duel, how, sim.store(&"world") as WorldState)


func _end(sim: Sim, duel: Duel, how: StringName, world: WorldState) -> void:
	var foe: DuelFighter = duel.foe()
	var who: String = String(foe.who) if foe != null else ""
	var asked_by: StringName = duel.asked_by
	var turns: int = duel.turns_taken
	var drill: StringName = duel.drill
	var felled: bool = duel.player_felled
	var by: StringName = duel.felled_by
	# **A person stays where the fight left him** (O7), and walks home from there — he is
	# not drawn back to his post the instant it ends. Beasts belong to their pack, and
	# the dead to nobody.
	var walkers := sim.store(&"walkers") as Walkers
	var cast := sim.store(&"cast") as Cast
	if walkers != null and cast != null:
		for fighter: DuelFighter in duel.fighters:
			var npc: Npc = cast.get_npc(fighter.who) if not fighter.is_player() else null
			if npc != null and fighter.how_out != &"down":
				walkers.place(npc.id, fighter.at, npc.tile)
	duel.fighters = []
	duel.turn = -1
	duel.phase = &""
	duel.phase_left = 0
	duel.walk = []
	duel.settling = 0
	duel.outcome = how
	# **The felling blow, paid.** One point left standing if he spares you, or the whole
	# of it down the one path everything that hurts you takes: the death, the count, the
	# respawn at the last fire. Paid now and not when it landed, so the beat shows you
	# down where you fell and `_stand` has stopped writing your position first.
	if felled and world != null:
		var owed: int = world.player_hp
		# **The line decides, not the man** (O1's review): a spar leaves you on one point,
		# and a fight picked for real — "I will not stop" — does not, whoever throws it.
		if duel.spar:
			owed = maxi(world.player_hp - 1, 0)
		world.hurt(owed, sim.step, false)
	duel.spar = false
	duel.drill = Duel.NOBODY
	duel.reinforced_by = Duel.NOBODY
	duel.master_at = Duel.NOWHERE
	duel.said = ""
	duel.said_by = Duel.NOBODY
	duel.tally = 0
	duel.owed_damage = 0
	duel.player_felled = false
	duel.felled_by = Duel.NOBODY
	# The hold is not released here, for the reason the first design records: `on_step`
	# sets it from the store at the top of every step and the tick is checked at the
	# bottom of the same one, so clearing it in the middle lets the world tick on the
	# step the last blow lands. The next step turns it off on its own.
	sim.derive(&"duel_ended", {
		"opponent": who, "how": String(how), "asked_by": String(asked_by), "turns": turns,
		"drill": String(drill), "passed": drill != Duel.NOBODY and how == &"won",
	})


## **A guard joins from the yard** (T9) at the end of every `reinforce_every` rounds, on
## the free tile nearest where they come from, while fewer than `reinforce_most` stand.
## Last in the order of play, like anybody who arrives late; seated `works_guard#2`,
## `#3`… so each is a fighter of his own. Derived: a replay sends the same men.
func _reinforce(sim: Sim, duel: Duel, world: WorldState) -> void:
	if duel.reinforced_by == Duel.NOBODY or duel.outcome != Duel.NOBODY or world == null:
		return
	if duel.round_number % duel.reinforce_every != 0:
		return
	var standing: int = 0
	var seats: int = 0
	for fighter: DuelFighter in duel.fighters:
		if DuelRules.kind_of(fighter.who) != duel.reinforced_by:
			continue
		seats += 1
		if fighter.alive():
			standing += 1
	if standing >= duel.reinforce_most:
		return
	var him := DuelFighter.new()
	him.who = duel.reinforced_by if seats == 0 else StringName("%s#%d" % [duel.reinforced_by, seats + 1])
	him.hp = DuelRules.hp_of(duel.reinforced_by)
	him.max_hp = him.hp
	him.weapon = DuelRules.weapon_of(duel.reinforced_by)
	var taken: Dictionary = _taken(duel, null)
	him.at = DuelRules.free_near(world.region(), duel.reinforce_from, taken)
	var mine: DuelFighter = duel.me()
	him.facing = DuelRules.facing_from(him.at, mine.at if mine != null else him.at)
	duel.fighters.append(him)
	sim.derive(&"duel_joined", {"who": String(him.who), "x": him.at.x, "y": him.at.y})


## Every tile somebody is standing on but this one, so nobody walks through anybody.
func _taken(duel: Duel, but: DuelFighter) -> Dictionary:
	var out: Dictionary = {}
	if duel.master_at != Duel.NOWHERE:
		out[duel.master_at] = true
	for fighter: DuelFighter in duel.fighters:
		if fighter == but or not fighter.alive():
			continue
		out[fighter.at] = true
	return out


## On the step, because a turn plays out over steps and the world's clock is held.
func steps() -> bool:
	return true


func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"duel"
