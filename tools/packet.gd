extends SceneTree

## Print one NPC's context packet, which is the thing to read before deciding
## whether a model should ever see it.
##
##   godot --headless --path . -s tools/packet.gd -- maddox

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var who: StringName = StringName(args[0]) if args.size() > 0 else &"maddox"
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	if cast.get_npc(who) == null:
		print("no such person: %s" % who)
		print("try: %s" % ", ".join(PackedStringArray(cast.named().map(
			func(n: Npc) -> String: return String(n.id)))))
		quit()
		return
	var packet: String = Context.build(who, world, cast,
		sim.store(&"standing") as Standing, sim.store(&"worldtick") as WorldTick,
		sim.facts, Relations.shared())
	print(packet)
	print("---")
	print("%d lines, %d characters, key %s" % [
		packet.split("\n").size(), packet.length(), Context.fingerprint(packet)])
	quit()
