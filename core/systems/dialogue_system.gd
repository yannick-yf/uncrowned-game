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
	if world == null or cast == null:
		return

	match event.type:
		&"talk":
			_open(world, cast, sim, StringName(event.data.get("npc", "")))
		&"choose_intent":
			_choose(world, cast, sim, StringName(event.data.get("intent", "")))
		&"end_talk":
			_close(world)


func _open(world: WorldState, cast: Cast, sim: Sim, id: StringName) -> void:
	var npc: Npc = cast.get_npc(id)
	if npc == null or npc.zone != world.current_zone:
		return
	world.talking_to = npc.id
	world.speaker_name = npc.display_name
	world.current_line = npc.greeting
	world.options = DialogueRules.available(npc, sim.facts)
	world.player_dir = Vector2i.ZERO
	sim.facts.add_source(StringName("met:%s" % npc.id), &"witnessed")


func _choose(world: WorldState, cast: Cast, sim: Sim, intent: StringName) -> void:
	if not world.in_dialogue():
		return
	var npc: Npc = cast.get_npc(world.talking_to)
	var option: DialogueOption = DialogueRules.find(npc, intent)
	if option == null:
		return
	# The verdict is the rules layer's, and it is issued before the line is read.
	var learned: StringName = DialogueRules.verdict(npc, intent, sim.facts)
	if learned != &"":
		sim.facts.add_source(learned, npc.id)
	world.current_line = option.reply
	world.options = DialogueRules.available(npc, sim.facts)


func _close(world: WorldState) -> void:
	world.talking_to = &""
	world.speaker_name = ""
	world.current_line = ""
	world.options = []


func system_name() -> StringName:
	return &"dialogue"
