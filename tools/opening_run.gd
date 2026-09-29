class_name OpeningRun
extends RefCounted

## **The demo's opening, played headless** (O20, 2026-09-29) — as Yannick tells it: made
## at creation, woken among the graves, the fairy, a rest at her fire, the path up into
## the village, Bram calling you over, the sword, the bow and the magic, out of his sight
## and back again, the wolves before the bridge, the works' gate. Played through the
## simulation by hands on the keys, stage by stage, each with a budget at the world's
## pace and a watchdog that names the stage it died in.
##
##   godot --headless --path . -s tools/play_opening.gd
##
## Played fast: the hands never hesitate and never read. So each stage is counted three
## ways — walking, fighting, and the lines a person would read, at `READING_S_PER_LINE`
## each — and the damage taken is set against the player's hundred and against the thirty
## `S4` will probably settle on. At the end the run must replay and load from its save
## into the same world. Lives in `tools/`: it decides nothing, it only presses.

## Seconds a person takes over one line of dialogue, read and answered.
const READING_S_PER_LINE: float = 4.0
## The hit points S4 is likely to settle on, against which the damage is also read.
const LIKELY_HP: int = 30
## Walks get this many times the time their path takes at the world's pace, and this
## much more, before the watchdog calls them stuck.
const WALK_SLACK: float = 3.0
const WALK_SLACK_S: float = 30.0
const FIGHT_STEPS: int = 40000
const SAVE_UNDER_TEST: String = "user://save_under_test_opening.json"

var sim: Sim = null
## One row per stage reached: {name, from, to, fighting, lines, damage}.
var stages: Array[Dictionary] = []
## What stopped the run — the stage and why — or empty when it reached the works' gate.
var stopped: String = ""
## Stages this world cannot play, and why (the 2D map has no wolves before a bridge).
var owed: Array[String] = []
## Where damage first reached `LIKELY_HP` since the last mend, or empty.
var would_have_died: String = ""

var _stage: Dictionary = {}
var _lines: int = 0
var _since_mend: int = 0
var _seen_events: int = 0


func play(levels: Dictionary = {}) -> bool:
	sim = Game.begin_run(levels)
	var steps: Array[Array] = [
		["creation", _create], ["the fairy", _hear_the_fairy], ["a rest at her fire", _rest],
		["the path and the hail", _answer_the_hail], ["the sword", _drill.bind("drill_sword", DuelPlayer.PRESS)],
		["the bow", _drill.bind("drill_bow", DuelPlayer.DODGE)],
		["the magic", _drill.bind("drill_magic", DuelPlayer.CAST)],
		["out of his sight and back", _leave_and_return], ["the wolves before the bridge", _the_wolves],
		["the works' gate", _to_the_works], ["replay and save", _round_trip],
	]
	for row: Array in steps:
		_begin(String(row[0]))
		var ok: bool = bool((row[1] as Callable).call())
		_close()
		if not ok:
			if stopped == "":
				stopped = "%s: stopped" % row[0]
			return false
	return true


func _world() -> WorldState:
	return sim.store(&"world") as WorldState


func _begin(name: String) -> void:
	_stage = {"name": name, "from": sim.step, "lines": 0, "slept": 0}
	_lines = 0


func _close() -> void:
	_stage["to"] = sim.step
	_stage["lines"] = _lines
	var fighting: int = 0
	var damage: int = 0
	var opened: int = -1
	for i: int in range(_seen_events, sim.events.size()):
		var event: SimEvent = sim.events.at(i)
		match event.type:
			&"duel_began":
				if opened < 0:
					opened = event.step
			&"duel_ended":
				if opened >= 0:
					fighting += event.step - opened
					opened = -1
			&"blow_landed":
				if String(event.data.get("target", "")) == String(DuelRules.PLAYER):
					var hurt: int = int(event.data.get("damage", 0))
					damage += hurt
					_since_mend += hurt
					if _since_mend >= LIKELY_HP and would_have_died == "":
						would_have_died = "%s (%d taken since the last mend)" % [_stage["name"], _since_mend]
			&"drill_over", &"rest":
				_since_mend = 0
	if opened >= 0:
		fighting += sim.step - opened
	_seen_events = sim.events.size()
	_stage["fighting"] = fighting
	_stage["damage"] = damage
	stages.append(_stage)


func _stop(why: String) -> bool:
	stopped = "%s: %s" % [_stage.get("name", "?"), why]
	return false


func _budget(to: Vector2i) -> int:
	var walk: Array[Vector2i] = Navigation.path(_world().region(), _world().player_tile(), to)
	var seconds: float = float(walk.size()) / MovementRules.tiles_per_second() * WALK_SLACK + WALK_SLACK_S
	return int(seconds * float(Sim.STEPS_PER_REAL_SECOND))


func _create() -> bool:
	if not _world().player_tile() == Region.START:
		return _stop("the run does not wake at the cemetery: %s" % _world().player_tile())
	return true


## Every one of her lines, first option each time, until she has finished and given.
func _hear_the_fairy() -> bool:
	sim.submit(&"talk", {"npc": String(OpeningRules.FAIRY)})
	sim.advance(2)
	var world: WorldState = _world()
	for _line: int in 12:
		if not world.in_dialogue() or world.options.is_empty():
			break
		_lines += 1
		sim.submit(&"choose_intent", {"intent": String(world.options[0].intent)})
		sim.advance(2)
	_leave()
	if not sim.facts.has(OpeningRules.GIFT):
		return _stop("she gave no gift")
	return true


## To her fire, and sit: the first save of the game.
func _rest() -> bool:
	var region: Region = _world().region()
	var fire: Vector2i = region.nearest_campfire(_world().player_tile(), 6.0)
	if fire == Region.NOWHERE:
		return _stop("no fire among the graves")
	var walker := OpeningPlayer.new()
	if not walker.walk_to(sim, fire, _budget(fire)):
		return _stop(walker.report)
	if region.nearest_campfire(_world().player_tile(), RecoveryRules.FIRE_REACH) == Region.NOWHERE:
		return _stop("at the fire and not in reach of it")
	sim.submit(&"rest")
	# The eight hours pass in one frame for the person at the keys, as the window does
	# it (`_rest`), so they are not counted as time anybody spent.
	var night: int = Sim.STEPS_PER_WORLD_TICK * RecoveryRules.REST_TICKS
	sim.advance(night)
	_stage["slept"] = night
	return true


## Up toward the village until somebody opens a conversation: that is the hail.
func _answer_the_hail() -> bool:
	var walker := OpeningPlayer.new(OpeningPlayer.STOP)
	if walker.walk_to(sim, Region.BRINDLE, _budget(Region.BRINDLE)):
		return _stop("walked into Brindle and nobody called")
	if _world().talking_to != &"bram":
		return _stop("stopped, but not by Bram: %s" % walker.report)
	if not sim.facts.has(&"hailed:bram"):
		return _stop("Bram is talking, but he did not call")
	_lines += 1
	return true


## One lesson: the line, the fight played by a hand, and the master speaking again.
func _drill(intent: String, hand: StringName) -> bool:
	var world: WorldState = _world()
	if world.talking_to != &"bram":
		sim.submit(&"talk", {"npc": "bram"})
		sim.advance(2)
	var offered: bool = false
	for option: DialogueOption in world.options:
		offered = offered or String(option.intent) == intent
	if not offered:
		return _stop("Bram does not offer %s" % intent)
	_lines += 1
	sim.submit(&"choose_intent", {"intent": intent})
	sim.advance(3)
	var duel := sim.store(&"duel") as Duel
	var hands := DuelPlayer.new(hand)
	for _step: int in FIGHT_STEPS:
		if not duel.on():
			break
		hands.play(sim, duel)
		sim.advance(1)
	if duel.on():
		return _stop("the drill never ended")
	# He speaks after every lesson — at once when beside you, after walking over when not
	# (the review of O21) — so wait for him, as a person at the keys would.
	for _step: int in HailRules.budget_steps() + DuelRules.beat_steps():
		if world.talking_to == &"bram":
			break
		sim.advance(1)
	if world.talking_to != &"bram":
		return _stop("he did not speak after the lesson")
	_lines += 1
	var id: String = intent.trim_prefix("drill_")
	if not sim.facts.has(StringName("drilled:%s" % id)):
		return _stop("not passed with the %s hand" % hand)
	return true


func _leave() -> void:
	if _world().in_dialogue():
		sim.submit(&"end_talk")
		sim.advance(2)


## Down to the graves and back up: he called once, and does not call again.
func _leave_and_return() -> bool:
	_leave()
	var hailed: int = sim.events.of_type(&"hailed").size()
	var walker := OpeningPlayer.new(OpeningPlayer.STOP)
	if not walker.walk_to(sim, Region.START, _budget(Region.START)):
		return _stop("back to the graves: %s" % walker.report)
	if not walker.walk_to(sim, Region.BRINDLE, _budget(Region.BRINDLE)):
		return _stop("up again: %s" % walker.report)
	if sim.events.of_type(&"hailed").size() != hailed:
		return _stop("he called a second time")
	return true


## His road toward the works, into the pack that waits before the bridge, and through it.
func _the_wolves() -> bool:
	if not Places.baked():
		owed.append("the wolves before the bridge: the packs are anchored to his map")
		return true
	var wild := sim.store(&"wild") as Wild
	var pack := Vector2i(-1, -1)
	for tile: Vector2i in wild.standing(_world().region()).keys():
		if int(wild.standing(_world().region())[tile]) == 0:
			pack = tile
	if pack.x < 0:
		return _stop("the demo's pack is not standing")
	var began: int = sim.events.of_type(&"duel_began").size()
	var walker := OpeningPlayer.new()
	walker.walk_to(sim, pack, _budget(pack))
	if sim.events.of_type(&"duel_began").size() == began:
		return _stop("walked to the pack and it never set on you: %s" % walker.report)
	if wild.cleared.is_empty():
		return _stop("the pack was not beaten")
	return true


## On to the tile in front of the works' gate, fighting what is on the way.
func _to_the_works() -> bool:
	var region: Region = _world().region()
	var front: Vector2i = Region.NOWHERE
	for yard: Dictionary in region.yards:
		if String(yard["place"]) == "cinderworks":
			var passage: Vector2i = yard["passage"] as Vector2i
			front = passage - ((yard["inside"] as Vector2i) - passage) * 2
	if front == Region.NOWHERE:
		if not Places.baked():
			owed.append("the works' gate: the yard is composed against his buildings and his river")
			return true
		return _stop("the works have no yard")
	var walker := OpeningPlayer.new()
	if not walker.walk_to(sim, front, _budget(front)):
		return _stop(walker.report)
	_lines += walker.left.size()
	return true


## The whole run again from its log, and from its save: the same world.
func _round_trip() -> bool:
	var again: Sim = Game.replay(sim)
	for id: StringName in [&"world", &"hail", &"walkers", &"wild", &"duel"]:
		var a: String = String(sim.store(id).call("fingerprint"))
		var b: String = String(again.store(id).call("fingerprint"))
		if a != b:
			return _stop("the replay's %s differs: %s against %s" % [id, b, a])
	var was: String = SaveFile.path
	SaveFile.path = SAVE_UNDER_TEST
	var wrote: bool = SaveFile.write(sim)
	var loaded: Sim = SaveFile.read() if wrote else null
	SaveFile.discard()
	SaveFile.path = was
	if loaded == null:
		return _stop("the save did not load")
	if (loaded.store(&"world") as WorldState).fingerprint() != _world().fingerprint():
		return _stop("the save loads into a different world")
	return true


## The run in words: a table of the stages, then the totals and what it would cost at 30.
func summary() -> String:
	var rows := PackedStringArray()
	var per: float = float(Sim.STEPS_PER_REAL_SECOND)
	rows.append("  %-30s %8s %8s %8s %7s" % ["stage", "walking", "fighting", "reading", "damage"])
	var total_walk: float = 0.0
	var total_fight: float = 0.0
	var total_read: float = 0.0
	var total_damage: int = 0
	for stage: Dictionary in stages:
		var spent: float = float(int(stage["to"]) - int(stage["from"]) - int(stage["slept"])) / per
		var fight: float = float(int(stage["fighting"])) / per
		var read: float = float(int(stage["lines"])) * READING_S_PER_LINE
		total_walk += spent - fight
		total_fight += fight
		total_read += read
		total_damage += int(stage["damage"])
		rows.append("  %-30s %7.1fs %7.1fs %7.1fs %7d" % [stage["name"], spent - fight, fight, read, int(stage["damage"])])
	rows.append("  %-30s %7.1fs %7.1fs %7.1fs %7d" % ["total", total_walk, total_fight, total_read, total_damage])
	rows.append("  about %.1f minutes in all, played by hands that never hesitate" % [
		(total_walk + total_fight + total_read) / 60.0])
	rows.append("  health %d/%d at the end; at %d HP: %s" % [_world().player_hp, WorldState.MAX_HP, LIKELY_HP,
		("would have fallen in " + would_have_died) if would_have_died != "" else "survives"])
	for debt: String in owed:
		rows.append("  OWED: %s" % debt)
	if stopped != "":
		rows.append("  STOPPED at %s" % stopped)
	return "\n".join(rows)
