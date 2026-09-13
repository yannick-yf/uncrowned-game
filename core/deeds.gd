class_name Deeds
extends RefCounted

## Doing a thing in front of people, whatever the thing is.
##
## One pipe for every deed in the game — taking from a stall, putting it back,
## warning a town, wrecking a kiln, emptying a vault. They differ only in what
## DeedRules says they do; the shape is always the same: who saw it, what it does to
## how you are regarded, what it does to the world, and a story if there is anybody
## to tell one.
##
## Extracted when the third system needed it. Three copies of "apply the counterpart,
## then raise the event" is how the counterpart rule quietly stops being true for one
## of them.

## Returns the witnesses, so a caller can say whether it was seen.
static func perform(
	sim: Sim,
	deed: StringName,
	where: StringName,
	at: Vector2,
	unseen: StringName = &"deed_unseen",
) -> PackedStringArray:
	var cast := sim.store(&"cast") as Cast
	var world := sim.store(&"world") as WorldState
	var standing := sim.store(&"standing") as Standing
	var ticked := sim.store(&"worldtick") as WorldTick
	var witnesses: PackedStringArray = CrimeRules.witnesses_to(
		cast, world.current_zone, at,
		ticked.alertness_in(where) if ticked != null else WorldTick.NEUTRAL
	) if cast != null and world != null else PackedStringArray()

	# What it does to the world, and whose doing that is. Through push(), because a
	# quantity that moves by assignment leaves no fingerprints and §3's endings will
	# not count it (the handprint rule).
	if ticked != null:
		var effects: Dictionary = DeedRules.world_effects(deed)
		for quantity: StringName in effects.keys():
			var amount: float = float(effects[quantity])
			# Town sentiment is held per settlement, so it is pushed where the deed
			# happened rather than globally — §8's eighth quantity is about a place.
			if quantity == &"town_sentiment":
				ticked.push_sentiment(where, amount)
			else:
				ticked.push(quantity, amount)
		# A quantity that eases toward a target is undone by its own drift unless
		# the target moves with it. Destroying the muster rolls took eighteen men
		# off the strength and then the world quietly recruited them back, which
		# made the act theatre. Only army strength has a target.
		if effects.has(&"army_strength"):
			ticked.army_target = clampf(
				ticked.army_target + float(effects[&"army_strength"]), 0.0, WorldTick.BASELINE)

		# And who it costs. §8's hard rule: every act that moves the kingdom names the
		# people it lands on, as hardship in their town — and the journal is what joins
		# the two, so each push is announced as a derived event it can read.
		var costs: Dictionary = DeedRules.hardship_effects(deed)
		for town_key: StringName in costs.keys():
			var town: StringName = where if town_key == DeedRules.HERE else town_key
			if town == &"":
				continue
			var cost: float = float(costs[town_key])
			ticked.push_hardship(town, cost)
			sim.derive(&"hardship_moved", {
				"town": String(town), "about": String(deed), "amount": cost,
				"to": ticked.hardship_in(town),
			})

	if standing != null:
		standing.shift_factions(DeedRules.faction_effects(deed))
		for who: String in witnesses:
			standing.shift_person(StringName(who), DeedRules.witness_effect(deed))

	sim.facts.add_source(deed, &"witnessed")

	# A deed nobody saw did not happen (§8) — as a *story*. It still changed the
	# world, and the world does not need a witness to have been broken.
	if not CrimeRules.is_worth_repeating(witnesses):
		sim.derive(unseen, {"town": String(where), "about": String(deed)})
		return witnesses
	sim.derive(&"deed_witnessed", {
		"about": String(deed),
		"town": String(where),
		"witnesses": witnesses,
	})
	return witnesses
