extends SceneTree

## Run written lines through the door, with the brief they were written from.
##
## The experiment behind step 4 of the dialogue plan. The door was built to judge
## lines nobody had written yet, and until something is actually put through it the
## only evidence it works is the handful of bad lines its own test feeds it. Those
## were written to fail. These were written to pass.
##
##   godot --headless --path . -s tools/try_lines.gd -- fr lines.json

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var locale: String = args[0] if args.size() > 0 else "fr"
	var path: String = args[1] if args.size() > 1 else ""
	Text.set_locale(locale)
	var sim: Sim = Game.build()
	Text.set_locale(locale)
	var cast := sim.store(&"cast") as Cast
	var known: PackedStringArray = ProseRules.known_names(cast)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Array):
		print("no lines at %s" % path)
		quit()
		return

	var passed: int = 0
	var total: int = 0
	for row: Variant in (parsed as Array):
		var entry: Dictionary = row as Dictionary
		var who: StringName = StringName(entry.get("npc", ""))
		var intent: StringName = StringName(entry.get("intent", ""))
		var line: String = String(entry.get("line", ""))
		var faults: PackedStringArray
		if bool(entry.get("opener", false)):
			faults = ProseRules.opener_faults(line, known)
		else:
			faults = ProseRules.faults(line, known,
				Answers.shared().must_be_true(who, intent))
		total += 1
		if faults.is_empty():
			passed += 1
			var shown: String = ProseRules.joined(line, String(entry.get("wrote", ""))) \
				if bool(entry.get("opener", false)) else line
			print("PASS %s %s/%s/%s" % [entry.get("id", "?"), who, intent, entry.get("sit", "")])
			print("     %s" % shown)
		else:
			print("FAIL %s %s/%s/%s — %s" % [entry.get("id", "?"), who, intent,
				entry.get("sit", ""), ", ".join(faults)])
			print("     %s" % line)
	print("---")
	print("%d lines, %d through the door (%.0f%%)" % [
		total, passed, 100.0 * float(passed) / float(maxi(total, 1))])
	quit()
