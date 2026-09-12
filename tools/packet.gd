extends SceneTree

## Print one NPC's context packet, which is the thing to read before deciding
## whether a model should ever see it.
##
##   godot --headless --path . -s tools/packet.gd -- maddox
##   godot --headless --path . -s tools/packet.gd -- maddox played
##
## `played` walks the player through a short session first — meet him, ask him
## things, take something off a stall while he watches. A packet from a fresh world
## shows the half that never changes; the half worth reading only exists after
## somebody has done something.

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var who: StringName = StringName(args[0]) if args.size() > 0 else &"maddox"
	var sim: Sim = Game.build()
	if args.size() > 1 and args[1] == "played":
		_play(sim, who)
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	if cast.get_npc(who) == null:
		print("no such person: %s" % who)
		print("try: %s" % ", ".join(PackedStringArray(cast.named().map(
			func(n: Npc) -> String: return String(n.id)))))
		quit()
		return
	var npc: Npc = cast.get_npc(who)
	var asking: DialogueOption = npc.options[0] if not npc.options.is_empty() else null
	var packet: String = Context.build(who, world, cast,
		sim.store(&"standing") as Standing, sim.store(&"worldtick") as WorldTick,
		sim.facts, Relations.shared(), asking)
	print(packet)
	print("---")
	print("%d lines, %d characters, key %s" % [
		packet.split("\n").size(), packet.length(), Context.fingerprint(packet)])
	quit()


func _play(sim: Sim, who: StringName) -> void:
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	world.player_pos = cast.get_npc(who).centre()
	sim.submit(&"talk", {"npc": String(who)})
	sim.advance(2)
	for _round: int in 3:
		if world.options.is_empty():
			break
		sim.submit(&"choose_intent", {"intent": String(world.options[0].intent)})
		sim.advance(2)
	sim.submit(&"steal")
	sim.advance(4)
