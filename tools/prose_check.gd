extends SceneTree

## Run the door over the hand-written corpus.
##
## The door (`ProseRules`) exists to judge lines a model produced, and the only
## calibration available is the corpus that was written by hand and accepted. A door
## that rejects Maddox is not strict, it is wrong, and a door that accepts everything
## is not a door.
##
##   godot --headless --path . -s tools/prose_check.gd -- fr

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	Text.set_locale(args[0] if args.size() > 0 else "fr")
	var sim: Sim = Game.build()
	Text.set_locale(args[0] if args.size() > 0 else "fr")
	var cast := sim.store(&"cast") as Cast
	var known: PackedStringArray = ProseRules.known_names(cast)
	var total: int = 0
	var refused: int = 0
	for npc: Npc in cast.named():
		var lines: Array[String] = [npc.greeting]
		for option: DialogueOption in npc.options:
			lines.append(option.reply)
		for line: String in lines:
			if line.strip_edges().is_empty():
				continue
			total += 1
			var faults: PackedStringArray = ProseRules.faults(line, known)
			if not faults.is_empty():
				refused += 1
				print("%s: %s" % [npc.id, ", ".join(faults)])
				print("    %s" % line)
	print("---")
	print("%d hand-written lines, %d refused by the door (%.0f%%)" % [
		total, refused, 100.0 * float(refused) / float(maxi(total, 1))])
	quit()
