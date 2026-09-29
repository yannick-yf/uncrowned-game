class_name HailSystem
extends SimSystem

## **Bram calls you over** (O16, 2026-09-29). The one writer of the `Hail` store.
##
## On the step the player stands in the ground somebody watches, and that somebody still
## calls (`HailRules.calls_out`), the hail is spent — `hailed:<who>` — and raised, and
## the player is held: the '!' beat, then he walks over through `Walkers` at the world's
## pace, and beside the player a `talk` is derived, as though the player had pressed
## the key. When that conversation closes the player is free and he is handed back to
## the world, which walks him home.
##
## Three things it never does. It never calls during a fight or a conversation: the
## world waits until it is the player's own again. It never holds the clock — a hail is
## people walking, not a pause; `Sim.ticks_held` keeps its one writer. And it never
## takes him home itself while something the talk began is still happening: a drill or
## a spar chosen in the talk is raised as the talk closes and reaches the fight a step
## later, so the hail waits for the world to be quiet for `QUIET_STEPS` before it lets go.

const HAILED: StringName = &"hailed"
## Steps of nothing — no fight, no settling, no conversation — before a hail is over.
const QUIET_STEPS: int = 2


func steps() -> bool:
	return true


func ticks() -> bool:
	return false


func on_step(sim: Sim, _step: int) -> void:
	var hail := sim.store(&"hail") as Hail
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	var walkers := sim.store(&"walkers") as Walkers
	var duel := sim.store(&"duel") as Duel
	if hail == null or world == null or cast == null or walkers == null:
		return
	var busy: bool = world.in_dialogue() or (duel != null and (duel.on() or duel.settling > 0))
	match hail.phase:
		Hail.IDLE:
			if not busy:
				_look(sim, hail, world, cast, walkers)
		Hail.SPOTTED:
			hail.spent += 1
			hail.beat -= 1
			if hail.beat <= 0:
				_set_off(hail, world, cast.get_npc(hail.who), walkers)
		Hail.COMING:
			hail.spent += 1
			var him: Npc = cast.get_npc(hail.who)
			if hail.spent > HailRules.budget_steps() or him == null or OpeningRules.is_gone(him.id, sim.facts):
				_let_go(hail, walkers, him)
				return
			_stride(hail, walkers, him, world)
		Hail.ARRIVED:
			hail.phase = Hail.TALKING
			# He stays put for the step the talk takes to open: without it the walkers saw a
			# man nobody was walking, talking to nobody, and set him off home (the review).
			if walkers.is_displaced(hail.who):
				walkers.linger[hail.who] = WalkerRules.linger_steps()
			# Derived, as the fight a line begins is: the player's event was the step
			# into his ground, and the conversation is the world's answer to it.
			sim.derive(&"talk", {"npc": String(hail.who)})
		Hail.TALKING:
			if world.talking_to != hail.who:
				hail.phase = Hail.RETURNING
				hail.quiet = 0
				# He stays where the talk left him a moment, as anybody does, so a drill
				# chosen in it finds him standing there when it begins a step later.
				if walkers.is_displaced(hail.who):
					walkers.linger[hail.who] = WalkerRules.linger_steps()
		Hail.RETURNING:
			hail.quiet = 0 if busy else hail.quiet + 1
			if hail.quiet >= QUIET_STEPS:
				_let_go(hail, walkers, cast.get_npc(hail.who))


## Whether anybody sees the player where they stand. The first row that does calls.
func _look(sim: Sim, hail: Hail, world: WorldState, cast: Cast, walkers: Walkers) -> void:
	var here: Vector2i = world.player_tile()
	for row: Dictionary in hail.rows:
		var id: StringName = row.get("who", &"") as StringName
		if not HailRules.in_sight(row, here) or not HailRules.calls_out(id, sim.facts):
			continue
		var him: Npc = cast.get_npc(id)
		if him == null or OpeningRules.is_gone(id, sim.facts):
			continue
		sim.facts.add_source(StringName(HailRules.HAILED % id), &"witnessed")
		hail.who = id
		hail.phase = Hail.SPOTTED
		hail.beat = HailRules.spotted_steps()
		hail.spent = 0
		hail.facing = _toward(walkers.where(him), here)
		sim.derive(HAILED, {"who": String(id)})
		return


## The '!' has stood long enough: work out his walk, once, into `Walkers`, so a replay
## walks the same tiles and both windows draw him walking.
func _set_off(hail: Hail, world: WorldState, him: Npc, walkers: Walkers) -> void:
	if him == null:
		hail.phase = Hail.RETURNING
		return
	var from: Vector2i = walkers.where(him)
	var walk: Array[Vector2i] = HailRules.approach(world.region(), from, world.player_tile())
	if walk.size() <= 1:
		# Already beside you, or no way to you: either way he speaks from where he is.
		hail.phase = Hail.ARRIVED if not walk.is_empty() else Hail.RETURNING
		hail.facing = _toward(from, world.player_tile())
		return
	walk.remove_at(0)
	walkers.at[him.id] = from
	walkers.linger[him.id] = 0
	walkers.path[him.id] = walk
	walkers.walked[him.id] = 0
	hail.facing = _toward(from, walk[0])
	hail.phase = Hail.COMING


## One step of his walk, at the world's walking pace, as `WalkerSystem` walks a man home.
func _stride(hail: Hail, walkers: Walkers, him: Npc, world: WorldState) -> void:
	var walked: int = int(walkers.walked.get(him.id, 0)) + 1
	if walked < WalkerRules.steps_per_tile():
		walkers.walked[him.id] = walked
		return
	var ahead: Array = walkers.path.get(him.id, []) as Array
	if ahead.is_empty():
		hail.phase = Hail.ARRIVED
		return
	walkers.at[him.id] = ahead[0] as Vector2i
	ahead.remove_at(0)
	walkers.walked[him.id] = 0
	if ahead.is_empty():
		walkers.path.erase(him.id)
		hail.facing = _toward(walkers.where(him), world.player_tile())
		hail.phase = Hail.ARRIVED
	else:
		hail.facing = _toward(walkers.where(him), ahead[0] as Vector2i)


## The hail is over: he is the world's again — left where he stands, lingering, and
## then walked home by `WalkerSystem` like anybody a fight displaced.
func _let_go(hail: Hail, walkers: Walkers, him: Npc) -> void:
	if him != null and walkers.is_displaced(him.id):
		walkers.path.erase(him.id)
		walkers.walked.erase(him.id)
		walkers.linger[him.id] = WalkerRules.linger_steps()
	hail.phase = Hail.IDLE
	hail.who = &""
	hail.quiet = 0
	hail.beat = 0


static func _toward(from: Vector2i, to: Vector2i) -> Vector2i:
	var d: Vector2i = (to - from).sign()
	return d if d != Vector2i.ZERO else Vector2i(0, 1)


func system_name() -> StringName:
	return &"hail"
