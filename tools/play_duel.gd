extends SceneTree

## Plays the turn-based fight with a scripted player and prints what happened, turn by
## turn and step by step.
##
## **This exists because a green suite has been wrong about a fight in this project six
## times.** `docs/COMBAT.md` §5 and §10: two bugs the first design shipped and four
## numbers it got wrong were found by scripting a player and counting, and none by a
## test written from the design. The second design inherits the habit, not the code.
##
##     godot --headless --path . -s tools/play_duel.gd                  every hand
##     godot --headless --path . -s tools/play_duel.gd -- press 600     one, traced
##
## The hands are `DuelPlayer`'s — `press`, `hold`, `stand`, `leave`. With a hand and a
## step count the run prints every step that matters: a turn opening, a fighter
## walking, a blow winding up, a blow landing, somebody running, the beat. **That is
## also how the step numbers for `UNCROWNED_DUEL` are found**, which is the only way to
## photograph a particular moment of a fight rather than whatever the shutter caught.
##
## Without arguments it plays each hand once against Bram and prints the summary: turns
## taken, events written, blows by each side, and how it ended.

const OPPONENT: String = "bram"
const HANDS: Array[StringName] = [
	DuelPlayer.PRESS, DuelPlayer.HOLD, DuelPlayer.STAND, DuelPlayer.LEAVE,
]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() >= 1:
		_trace(StringName(args[0]), args[1].to_int() if args.size() > 1 else 2000)
	else:
		for hand: StringName in HANDS:
			_summary(hand)
	quit(0)


## On open ground, because a fight about position needs somewhere to stand. The player
## is put a stride from the man and the fight is begun from there, as the world will
## begin it once K6 wires this to a conversation.
##
## **`UNCROWNED_AT=x,y` stands them somewhere else**, and it is the same variable
## `tools/shot.sh` reads — so the trace and the photograph are of the same fight. Step
## numbers depend on the ground: two people three tiles apart spend a turn closing and
## two people beside each other do not, and a trace taken somewhere else would send
## the shutter to the wrong step.
func _square_up() -> Sim:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	var stand: String = OS.get_environment("UNCROWNED_AT")
	if stand.contains(","):
		var parts: PackedStringArray = stand.split(",")
		world.player_pos = Vector2(float(parts[0]) + 0.5, float(parts[1]) + 0.5)
	else:
		var him: Npc = cast.get_npc(StringName(OPPONENT))
		if him != null:
			world.player_pos = him.centre() + Vector2(3.0, 0.0)
	sim.submit(&"duel_began", {"opponent": OPPONENT, "by": "player"})
	sim.advance(1)
	return sim


func _summary(hand: StringName) -> void:
	var sim: Sim = _square_up()
	var duel := sim.store(&"duel") as Duel
	var world := sim.store(&"world") as WorldState
	var hands := DuelPlayer.new(hand)
	var turns: int = 0
	var rounds: int = 0
	var steps: int = 0
	var outcome: StringName = &""
	for _step: int in 12000:
		if not duel.on():
			break
		hands.play(sim, duel)
		sim.advance(1)
		steps += 1
		turns = duel.turns_taken
		rounds = duel.round_number
		outcome = duel.outcome
	var mine: int = 0
	var his: int = 0
	for event: SimEvent in sim.events.all():
		if event.type != &"blow_landed":
			continue
		if String(event.data.get("by", "")) == "player":
			mine += 1
		else:
			his += 1
	print("%-7s %-5s  %2d turns / %d rounds in %4d steps (%.1f s)   you landed %d, he landed %d   world hp %d/%d, deaths %d   log: %d turn rows" % [
		String(hand), String(outcome), turns, rounds, steps, float(steps) / 60.0,
		mine, his, world.player_hp, WorldState.MAX_HP, world.deaths,
		sim.events.of_type(&"duel_turn").size()])


func _trace(hand: StringName, steps: int) -> void:
	var sim: Sim = _square_up()
	var duel := sim.store(&"duel") as Duel
	var hands := DuelPlayer.new(hand)
	var seen: int = sim.events.size()
	var was: Dictionary = {}
	print("step  turn  phase      you            him           hp you/him  what")
	for i: int in steps:
		if not duel.on():
			print("%4d  fight over: %s" % [i, String(duel.outcome)])
			break
		hands.play(sim, duel)
		sim.advance(1)
		var note: Array[String] = []
		var now: Dictionary = {
			"phase": duel.phase, "turn": duel.turn, "n": duel.turns_taken,
			"settling": duel.settling > 0,
		}
		if int(now["n"]) != int(was.get("n", -1)):
			var who: DuelFighter = duel.acting_fighter()
			note.append("TURN %d: %s %s" % [int(now["n"]),
				String(who.who) if who != null else "?", String(duel.acting)])
		if now["phase"] != was.get("phase", &"") and now["phase"] == Duel.ACTING \
				and duel.acting == DuelRules.STRIKE:
			note.append("winds up")
		for k: int in range(seen, sim.events.size()):
			var event: SimEvent = sim.events.at(k)
			match event.type:
				&"blow_landed":
					note.append("%s LANDS for %d on %s" % [String(event.data.get("by", "")),
						int(event.data.get("damage", 0)), String(event.data.get("target", ""))])
				&"blow_missed":
					note.append("%s MISSES" % String(event.data.get("by", "")))
				&"duel_down":
					note.append("%s IS DOWN" % String(event.data.get("who", "")))
				&"duel_fled":
					note.append("%s HAS LEFT THE FIGHT" % String(event.data.get("who", "")))
				&"duel_decided", &"duel_ended":
					note.append("%s %s" % [String(event.type), String(event.data.get("how", ""))])
		seen = sim.events.size()
		if bool(now["settling"]) and not bool(was.get("settling", false)):
			note.append("the beat begins")
		if note.size() > 0 or i % 30 == 0:
			var mine: DuelFighter = duel.me()
			var him: DuelFighter = duel.foe()
			print("%4d  %4d  %-10s %-14s %-13s %3d/%-3d   %s" % [
				i, duel.turns_taken, String(duel.phase),
				_where(duel, mine), _where(duel, him),
				mine.hp if mine != null else 0, him.hp if him != null else 0,
				"  ".join(note)])
		was = now


func _where(duel: Duel, who: DuelFighter) -> String:
	if who == null:
		return "-"
	var at: Vector2 = duel.drawn_at(who)
	return "%.1f,%.1f%s" % [at.x, at.y, "!" if who.hurt_left > 0 else ""]
