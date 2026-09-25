class_name DuelSystem
extends SimSystem

## The fight, resolved — second design (K1, K2; `docs/COMBAT_V2.md`).
##
## **Built beside `CombatSystem`, which still exists and still runs.** Nothing here
## replaces it and nothing here is wired to the player's keys by default: this fight is
## reached through its own tests and through `UNCROWNED_DUEL`, and the cut-over that
## takes the first design out is K6. Two fights on disk at once is the point — rule 4
## of `docs/DEMO_TASKS.md`, *build beside, delete nothing until the demo runs on the new
## one*.
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
## **The world's clock is held for the duration** (`Sim.ticks_held`), as it already was.
## `CombatSystem` is the other writer and recomputes it to `false` every step when
## nobody is fighting its fight; this system is registered after it and sets it back to
## `true` when a duel is on, so the two cannot leave it on between them.
##
## A turn takes real steps to play out — the walk, the wind-up, the blow, the recovery
## — because a turn nobody can see is not a turn. Every one of those counts is an
## integer in `content/duel.json`, so the same fight replays step for step.

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
	# The path where nobody is fighting is one store lookup and a return, which is what
	# it costs every other simulation in the game. **`ticks_held` is deliberately not
	# written here**: `CombatSystem` recomputes it every step and this system runs after
	# it, so a duel turns it back on and nothing turns it on when no fight is running.
	if duel == null or not duel.on():
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
	for who: StringName in against:
		var him := DuelFighter.new()
		him.who = who
		him.hp = DuelRules.hp_of(who)
		him.max_hp = him.hp
		var npc: Npc = cast.get_npc(who) if cast != null else null
		var stands: Vector2i = npc.tile if npc != null else mine.at + Vector2i(1, 0)
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
	# **Two actions, and there is no guard** (Yannick, 2026-09-24). Anything that is not
	# a strike is a wait: a window asking for a third one is a window out of date with
	# the design, and the fight answers it with the one action that always exists rather
	# than by dropping the turn.
	var action: StringName = DuelRules.STRIKE \
		if String(event.data.get("action", "")) == String(DuelRules.STRIKE) else DuelRules.WAIT
	var at := StringName(String(event.data.get("target", "")))
	if action == DuelRules.STRIKE:
		var victim: DuelFighter = duel.get_fighter(at)
		if victim == null or not victim.alive() or not DuelRules.in_reach(wanted, victim.at):
			at = Duel.NOBODY
			for foe: DuelFighter in duel.foes_of(mine.who):
				if DuelRules.in_reach(wanted, foe.at):
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
) -> void:
	var cost: Dictionary = DuelRules.reachable(
		who.at, world.region(), DuelRules.tiles_per_turn(), _taken(duel, who))
	duel.walk = DuelRules.path_to(who.at, to, cost)
	duel.walked = 0
	duel.acting = action
	duel.target = at
	duel.struck = false
	duel.turns_taken += 1
	if record:
		sim.derive(&"duel_turn", {
			"who": String(who.who), "to_x": to.x, "to_y": to.y,
			"action": String(action), "target": String(at),
		})
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
	duel.phase_left -= 1
	if duel.phase_left <= 0:
		_end_turn(sim, duel, world)


## **A blow lands for a fixed number and does not move anybody** (Yannick, 2026-09-24).
## The one who takes it plays the flinch and stays on their tile: no knockback, no
## pushbox, no shove. A hit that moved you would make position depend on the enemy's
## dice, and there are no dice.
func _strike(sim: Sim, duel: Duel, world: WorldState, who: DuelFighter) -> void:
	duel.struck = true
	var victim: DuelFighter = duel.get_fighter(duel.target)
	if victim == null or not victim.alive() or not DuelRules.in_reach(who.at, victim.at):
		sim.derive(&"blow_missed", {"by": _named_as(who), "move": String(DuelRules.STRIKE)})
		return
	var damage: int = DuelRules.strike_damage()
	# **`G` still means what it says.** The one development tool that makes the player
	# unkillable is read here as well as in `WorldState.hurt`, because a fight that
	# drained a bar nothing was allowed to empty would be a fight the HUD lied about.
	if victim.is_player() and world != null and world.unkillable:
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
		"move": String(DuelRules.STRIKE), "damage": damage, "guarded": false,
		"opponent_hp": foe.hp if foe != null else 0,
		"player_hp": mine.hp if mine != null else 0,
		"apart_mm": DuelRules.millimetres_of(DuelRules.apart(who.at, victim.at)),
		"felled": DuelRules.is_down(victim.hp),
	})


## `"player"` or a cast id, which is the word the window's blows already speak.
func _named_as(who: DuelFighter) -> String:
	return "player" if who.is_player() else String(who.who)


# ------------------------------------------------------- the end of a turn, and of it ---

func _end_turn(sim: Sim, duel: Duel, world: WorldState) -> void:
	duel.walk = []
	duel.walked = 0
	for fighter: DuelFighter in duel.fighters:
		if fighter.alive() and DuelRules.is_down(fighter.hp):
			fighter.out = true
			fighter.how_out = &"down"
			sim.derive(&"duel_down", {"who": String(fighter.who)})
	if _over(sim, duel):
		return
	duel.phase = Duel.PAUSING
	duel.phase_left = DuelRules.pause_steps()
	if duel.phase_left <= 0:
		_next_turn(sim, duel, world)


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
				if _over(sim, duel):
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
		_decided(sim, duel, &"won")
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
	})
	if duel.settling <= 0:
		_end(sim, duel, how, sim.store(&"world") as WorldState)


func _end(sim: Sim, duel: Duel, how: StringName, world: WorldState) -> void:
	var foe: DuelFighter = duel.foe()
	var who: String = String(foe.who) if foe != null else ""
	var asked_by: StringName = duel.asked_by
	var turns: int = duel.turns_taken
	var felled: bool = duel.player_felled
	var by: StringName = duel.felled_by
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
		if DuelRules.spares(by):
			owed = maxi(world.player_hp - 1, 0)
		world.hurt(owed, sim.step, false)
	duel.owed_damage = 0
	duel.player_felled = false
	duel.felled_by = Duel.NOBODY
	# The hold is not released here, for the reason the first design records: `on_step`
	# sets it from the store at the top of every step and the tick is checked at the
	# bottom of the same one, so clearing it in the middle lets the world tick on the
	# step the last blow lands. The next step turns it off on its own.
	sim.derive(&"duel_ended", {
		"opponent": who, "how": String(how), "asked_by": String(asked_by), "turns": turns,
	})


## Every tile somebody is standing on but this one, so nobody walks through anybody.
func _taken(duel: Duel, but: DuelFighter) -> Dictionary:
	var out: Dictionary = {}
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
