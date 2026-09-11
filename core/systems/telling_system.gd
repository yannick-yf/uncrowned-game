class_name TellingSystem
extends SimSystem

## Giving away what you know.
##
## §8's answer to a system that could only ever subtract. The player holds the
## Muster's pay fraud; until now it had one use, which was to collapse the army.
## Telling a town instead — the deserters are coming, here is why bread is about to
## rise, lay in stores — raises that town's opinion, leaves the army standing, and
## leaves the town better able to absorb the price whenever the Muster does empty
## out, by whatever hand.
##
## It is the exact mirror of theft and runs the identical pipe: a deed, the people
## near enough to hear it, a story that travels, standing that moves as the story
## arrives. Theft takes and is witnessed; telling gives and is witnessed.
##
## What it spends is the *telling*, never the *knowing*. The fact stays in the fact
## base forever — Route C needs the player to know this and put it in front of the
## king, and nothing here touches that.

func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type != &"tell_town":
		return
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	var ticked := sim.store(&"worldtick") as WorldTick
	if world == null or cast == null or ticked == null:
		return

	var here: StringName = world.region().zone_at(world.player_tile())
	var witnesses: PackedStringArray = CrimeRules.witnesses_to(
		cast, world.current_zone, world.player_pos)
	if not TellingRules.can_warn(here, world.fraud_told_to, witnesses, sim.facts):
		return

	# Told. To this town, and to nobody else ever — speaking it aloud is what
	# reaches Odile, and a quartermaster who knows she has been named does not
	# leave the books where she left them.
	world.fraud_told_to = here
	# They lay in stores. It is worth nothing today and a great deal on the day
	# the camp finally empties, which is the shape a warning should have.
	ticked.prepared[here] = true

	var standing := sim.store(&"standing") as Standing
	if standing != null:
		standing.shift_factions(DeedRules.faction_effects(DeedRules.DEED_WARNING))
		# You told these people to their faces. They remember that you did.
		for who: String in witnesses:
			standing.shift_person(
				StringName(who), DeedRules.witness_effect(DeedRules.DEED_WARNING))
	sim.facts.add_source(DeedRules.DEED_WARNING, &"witnessed")
	sim.derive(&"deed_witnessed", {
		"about": String(DeedRules.DEED_WARNING),
		"town": String(here),
		"witnesses": witnesses,
	})


func system_name() -> StringName:
	return &"telling"
