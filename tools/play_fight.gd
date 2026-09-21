extends SceneTree

## Plays the fight with a scripted player and prints what happened, frame by frame.
##
## **This exists because a green suite has been wrong about this fight six times.**
## `docs/COMBAT.md` §5 and §10: two bugs F1 shipped and four numbers F5 got wrong were
## all found by scripting a competent player and counting, and none by a test written
## from the design. So every change to the fight is *played* here as well as tested.
##
##     godot --headless --path . -s tools/play_fight.gd                 all policies
##     godot --headless --path . -s tools/play_fight.gd -- guard 300    one, traced
##
## The policies are `FightPlayer`'s. With a policy and a step count the run prints a
## trace of every frame that matters — a wind-up starting, a blow out, a blow landing
## or missing, the beat — which is also how the step numbers for `UNCROWNED_FIGHT`
## are found. Without arguments it plays each policy once against Bram and prints the
## summary: blows landed, blocked and missed by each side, the distance every blow
## landed at, and how it ended.

const OPPONENT: String = "bram"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() >= 1:
		var steps: int = args[1].to_int() if args.size() > 1 else 3000
		_trace(StringName(args[0]), steps)
	else:
		for policy: StringName in FightPlayer.POLICIES:
			_summary(policy)
	quit(0)


func _square_up() -> Sim:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	world.player_pos = cast.get_npc(StringName(OPPONENT)).centre()
	sim.submit(&"talk", {"npc": OPPONENT})
	sim.advance(2)
	sim.submit(&"choose_intent", {"intent": "ask_%s_spar" % OPPONENT})
	sim.advance(4)
	return sim


func _summary(policy: StringName) -> void:
	var sim: Sim = _square_up()
	var fight := sim.store(&"fight") as Fight
	var world := sim.store(&"world") as WorldState
	var player := FightPlayer.new(policy)
	var frames: int = 0
	for _step: int in 6000:
		if not fight.on():
			break
		player.play(sim, fight)
		sim.advance(1)
		frames += 1
	var landed: Dictionary = {"player": [], OPPONENT: []}
	var blocked: Dictionary = {"player": 0, OPPONENT: 0}
	var missed: Dictionary = {"player": 0, OPPONENT: 0}
	var by_move: Dictionary = {}
	for event: SimEvent in sim.events.all():
		var by: String = String(event.data.get("by", ""))
		if event.type == &"blow_landed":
			if bool(event.data.get("guarded", false)):
				blocked[by] = int(blocked[by]) + 1
			else:
				(landed[by] as Array).append(int(event.data.get("apart_mm", -1)))
			var move: String = String(event.data.get("move", ""))
			if not by_move.has(move):
				by_move[move] = []
			(by_move[move] as Array).append(int(event.data.get("apart_mm", -1)))
		elif event.type == &"blow_missed":
			missed[by] = int(missed[by]) + 1
	print("%-10s %-4s in %4d frames (%.1f s)  you: hp %2d, landed %d, blocked-by-him %d, missed %d   him: hp %2d, landed %d, you-blocked %d, missed %d" % [
		String(policy), String(fight.outcome), frames, float(frames) / 60.0,
		world.player_hp, (landed["player"] as Array).size(), blocked[OPPONENT], missed["player"],
		fight.opponent_hp, (landed[OPPONENT] as Array).size(), blocked["player"], missed[OPPONENT]])
	for move: String in by_move.keys():
		print("           %-9s connected at mm: %s" % [move, str(by_move[move])])


func _trace(policy: StringName, steps: int) -> void:
	var sim: Sim = _square_up()
	var fight := sim.store(&"fight") as Fight
	var world := sim.store(&"world") as WorldState
	var player := FightPlayer.new(policy)
	var seen: int = sim.events.size()
	var was: Dictionary = {}
	print("step  apart  you                          him                      hp you/him")
	for i: int in steps:
		if not fight.on():
			print("%4d  fight over: %s" % [i, String(fight.outcome)])
			break
		player.play(sim, fight)
		sim.advance(1)
		var now: Dictionary = {
			"pm": fight.player_move, "pf": fight.player_frame, "om": fight.opponent_move,
			"of": fight.opponent_frame, "settling": fight.settling > 0,
		}
		var note: Array[String] = []
		if now["om"] != was.get("om", &"") and now["om"] != &"":
			note.append("HE WINDS UP %s" % String(now["om"]))
		if now["pm"] != was.get("pm", &"") and now["pm"] != &"":
			note.append("you %s" % String(now["pm"]))
		var his_out_now: bool = now["om"] != &"" and CombatRules.is_active(now["om"], int(now["of"]))
		var his_out_was: bool = was.get("om", &"") == now["om"] and CombatRules.is_active(now["om"], int(was.get("of", -1)))
		if his_out_now and not his_out_was:
			note.append("his blow is OUT")
		var mine_out_now: bool = now["pm"] != &"" and CombatRules.is_active(now["pm"], int(now["pf"]))
		var mine_out_was: bool = was.get("pm", &"") == now["pm"] and CombatRules.is_active(now["pm"], int(was.get("pf", -1)))
		if mine_out_now and not mine_out_was:
			note.append("your blow is out")
		for k: int in range(seen, sim.events.size()):
			var event: SimEvent = sim.events.at(k)
			if event.type == &"blow_landed":
				note.append("%s %s %s for %d at %d mm" % [String(event.data.get("by", "")),
					"BLOCKED" if bool(event.data.get("guarded", false)) else "LANDS",
					String(event.data.get("move", "")), int(event.data.get("damage", 0)),
					int(event.data.get("apart_mm", -1))])
			elif event.type == &"blow_missed":
				note.append("%s MISSES %s at %d mm" % [String(event.data.get("by", "")),
					String(event.data.get("move", "")), int(event.data.get("apart_mm", -1))])
			elif event.type == &"fight_decided" or event.type == &"fight_ended":
				note.append("%s %s" % [String(event.type), String(event.data.get("how", ""))])
		seen = sim.events.size()
		if bool(now["settling"]) and not bool(was.get("settling", false)):
			note.append("the beat begins")
		if note.size() > 0 or i % 30 == 0:
			print("%4d  %5d  %-28s %-24s %2d/%2d  %s" % [i, fight.apart_mm(),
				_state(fight.player_move, fight.player_frame, fight.player_stun, fight.pressing_guard),
				_state(fight.opponent_move, fight.opponent_frame, fight.opponent_stun, false),
				world.player_hp, fight.opponent_hp, "  ".join(note)])
		was = now


func _state(move: StringName, frame: int, stun: int, guarding: bool) -> String:
	if stun > 0:
		return "stunned %d" % stun
	if move != &"":
		var phase: String = "windup" if CombatRules.is_winding_up(move, frame) else ("ACTIVE" if CombatRules.is_active(move, frame) else "recover")
		return "%s %d %s" % [String(move), frame, phase]
	return "guard" if guarding else "free"
