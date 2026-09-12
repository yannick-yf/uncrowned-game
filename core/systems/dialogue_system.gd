class_name DialogueSystem
extends SimSystem

## Runs conversations. Applies the rules layer's verdict and looks up the line.
##
## Nothing here generates text. The reply is authored in content/cast.json and
## fetched; the fact learned is decided by DialogueRules. When a model is attached
## later it replaces the *lookup*, not the verdict.

func on_event(sim: Sim, event: SimEvent) -> void:
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	var ticked := sim.store(&"worldtick") as WorldTick
	if world == null or cast == null:
		return
	var standing := sim.store(&"standing") as Standing
	var conditions: Dictionary = DialogueRules.conditions(world, ticked, standing)
	# Whose opinion is being asked is a property of the conversation, not of the
	# world, so it is added per conversation rather than computed in the rules
	# layer — which has no way of knowing who you walked up to.
	var who: StringName = StringName(event.data.get("npc", String(world.talking_to)))
	var regard: float = standing.with_person(who) if standing != null else 0.0
	conditions[&"they_think_ill_of_me"] = StandingRules.is_unwelcome(regard)
	conditions[&"they_think_well_of_me"] = StandingRules.is_welcome(regard)

	match event.type:
		&"talk":
			_open(world, cast, sim, StringName(event.data.get("npc", "")), conditions, regard)
		&"choose_intent":
			_choose(world, cast, sim, StringName(event.data.get("intent", "")), conditions, regard)
		&"end_talk":
			_close(world)


func _open(
	world: WorldState,
	cast: Cast,
	sim: Sim,
	id: StringName,
	conditions: Dictionary,
	regard: float,
) -> void:
	var npc: Npc = cast.get_npc(id)
	if npc == null or npc.zone != world.current_zone:
		return
	world.talking_to = npc.id
	world.speaker_name = npc.display_name
	world.last_intent = &""
	world.current_line = _opening(cast, npc, conditions, regard)
	world.options = DialogueRules.available(npc, sim.facts, conditions, regard)
	world.player_dir = Vector2i.ZERO
	sim.facts.add_source(StringName("met:%s" % npc.id), &"witnessed")


## How the conversation opens, and the whole of why a town that has turned on you
## no longer chats.
##
## Three tiers, most specific first. A line **written for this person in these
## circumstances** always wins — that is where the good writing goes. Failing that,
## the shared line for how they *regard* you: narration rather than speech, so one
## sentence works in everybody's mouth. Only somebody with no opinion of you at all
## gets their everyday greeting.
##
## The order is the point. Reaction used to be something each line opted into, so
## silence was the default and four of the five named cast greeted a player the
## whole town had turned on exactly as they greeted a stranger.
func _opening(cast: Cast, npc: Npc, conditions: Dictionary, regard: float) -> String:
	var authored: String = npc.alt_greeting_for(conditions)
	if authored != "":
		return authored
	var shared: String = cast.disposition_line(
		StandingRules.word_for(regard), npc.display_name)
	return shared if shared != "" else npc.greeting


func _choose(
	world: WorldState,
	cast: Cast,
	sim: Sim,
	intent: StringName,
	conditions: Dictionary,
	regard: float,
) -> void:
	if not world.in_dialogue():
		return
	var npc: Npc = cast.get_npc(world.talking_to)
	var option: DialogueOption = DialogueRules.find(npc, intent)
	if option == null:
		return
	# And it has to be a line he is actually offering. The verdict already refused
	# to teach anything for an intent that was not on the list, but the reply was
	# spoken regardless — so an unoffered line was read aloud and taught nothing,
	# which looks exactly like a fact that failed to register. The keyboard cannot
	# reach one; a tool or a test can, and did.
	if not DialogueRules.available(npc, sim.facts, conditions, regard).has(option):
		return
	# The verdict is the rules layer's, and it is issued before the line is read.
	var learned: StringName = DialogueRules.verdict(npc, intent, sim.facts, conditions, regard)
	if learned != &"":
		sim.facts.add_source(learned, npc.id)
	# And he has now answered it. Recorded as a fact like everything else, so it
	# replays, and so the journal could one day show what you have already asked.
	if not option.repeatable:
		sim.facts.add_source(option.spent_by(npc.id), &"witnessed")
	# And what saying it does, if it does anything. Raised rather than applied here:
	# the dialogue system runs conversations and has no business knowing what a
	# furnace is.
	if option.causes != &"":
		Deeds.perform(sim, option.causes, world.region().zone_at(world.player_tile()),
			world.player_pos)
	# The reaction goes in front of the answer, **once**, on the first thing they tell
	# you in this conversation. Not on every answer: a man who says "you pay first"
	# four times in one exchange is a machine with a stuck key, and the relationship
	# only needs acknowledging once. The greeting is not the place for it either —
	# that already has a narrated disposition line, and this one is spoken.
	var spoken: String = option.reply
	if world.said_before.is_empty():
		spoken = ProseRules.joined(
			cast.reaction_for(npc, StandingRules.word_for(regard)), option.reply)
	world.said_before.append("%s -> %s" % [option.text, spoken])
	world.current_line = spoken
	world.last_intent = intent
	world.options = DialogueRules.available(npc, sim.facts, conditions, regard)


func _close(world: WorldState) -> void:
	world.talking_to = &""
	world.last_intent = &""
	world.speaker_name = ""
	world.current_line = ""
	world.said_before = []
	world.options = []


func system_name() -> StringName:
	return &"dialogue"
