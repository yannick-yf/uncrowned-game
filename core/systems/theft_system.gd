class_name TheftSystem
extends SimSystem

## Taking something in front of somebody, and putting it back.

##
## §8's first consequence needs a witnessed crime, and theft is the verb the
## finished game needs anyway — building it now is building the game rather than
## scaffolding, and killing arrives in Phase 4 through exactly these pipes.
##
## Restitution lives here rather than in a system of its own because it is the same
## subject seen from the other side: the same stall, the same witnesses, the same
## story travelling, one sign flipped. Splitting them would have let the two drift
## apart, and "the exact mirror of theft" is a claim the code should keep true.
##
## Neither branch decides whether anyone *cares*. They record what happened and who
## saw it, and raise a derived event. What the world does about it is the rumour
## system's business, which is how the world ends up telling itself.

func on_event(sim: Sim, event: SimEvent) -> void:
	match event.type:
		&"steal":
			_steal(sim)
		&"give_back":
			_give_back(sim)


func _steal(sim: Sim) -> void:
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	if world == null or cast == null:
		return

	var stall: Vector2i = world.region().nearest_stall(world.player_tile(), CrimeRules.STALL_REACH)
	if stall == Region.NOWHERE:
		return
	# Nothing left on it. Not a refusal and not a failure — there is simply no
	# theft to commit, so no fact, no witnesses and no story.
	if world.stall_is_bare(stall, sim.tick):
		return

	var here: StringName = world.region().zone_at(world.player_tile())
	var witnesses: PackedStringArray = CrimeRules.witnesses_to(cast, world.current_zone, world.player_pos)
	world.thefts += 1
	world.robbed[stall] = sim.tick
	world.carrying_stolen += 1
	world.stolen_from = stall
	world.stolen_town = here
	world.last_theft_step = sim.step
	world.last_theft_seen = witnesses.size()
	sim.facts.add_source(DeedRules.DEED_THEFT, &"witnessed")
	_witnessed(sim, DeedRules.DEED_THEFT, here, witnesses, &"theft_unseen")


## Putting it back where it came from, in front of whoever is standing there.
##
## It repairs the place, not the past: the town thinks better of you, and the story
## already walking toward Cairnwell keeps walking. There is no branch here that
## catches a rumour, deliberately.
func _give_back(sim: Sim) -> void:
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	if world == null or cast == null:
		return
	if not world.can_give_back(world.region().nearest_stall(
			world.player_tile(), CrimeRules.STALL_REACH)):
		return

	var stall: Vector2i = world.stolen_from
	var here: StringName = world.stolen_town
	var witnesses: PackedStringArray = CrimeRules.witnesses_to(cast, world.current_zone, world.player_pos)
	world.carrying_stolen -= 1
	# Back on the counter, so the stall has something on it again.
	world.robbed.erase(stall)
	if world.carrying_stolen <= 0:
		world.stolen_from = Vector2i(-1, -1)
		world.stolen_town = &""
	world.last_theft_step = -1
	sim.facts.add_source(DeedRules.DEED_RESTITUTION, &"witnessed")
	_witnessed(sim, DeedRules.DEED_RESTITUTION, here, witnesses, &"restitution_unseen")


## The half both branches share: who is impressed or offended settles now, and the
## story starts only if there was somebody to start it.
func _witnessed(
	sim: Sim,
	deed: StringName,
	where: StringName,
	witnesses: PackedStringArray,
	unseen: StringName,
) -> void:
	var standing := sim.store(&"standing") as Standing
	if standing != null:
		standing.shift_factions(DeedRules.faction_effects(deed))
		# The people who watched it. Theirs is personal and immediate, and from
		# here it is their own opinion rather than their town's.
		for who: String in witnesses:
			standing.shift_person(StringName(who), DeedRules.witness_effect(deed))
	# A deed nobody saw did not happen (§8). It still occurred — the fact is yours
	# either way — but there is no story to travel and no town to hear it.
	if not CrimeRules.is_worth_repeating(witnesses):
		sim.derive(unseen, {"town": String(where)})
		return
	sim.derive(&"deed_witnessed", {
		"about": String(deed),
		"town": String(where),
		"witnesses": witnesses,
	})


func system_name() -> StringName:
	return &"theft"
