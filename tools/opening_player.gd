class_name OpeningPlayer
extends RefCounted

## **A scripted walker that gets through what the world puts in its way** (O15,
## 2026-09-29). From the tutorial on, the world talks first — Bram calls out and walks
## over, a pack squares up with whoever passes — and a walker that only holds a
## direction stalls at the first of them, and the suite says *walk failed*, which names
## nothing.
##
## This walks the way a player does, through the simulation, so every step of it is in
## the log: it follows `Navigation.path` (a town is full of his buildings, and steering
## by eye wedges in the first doorway), plays any fight with a `DuelPlayer` hand, and
## **leaves any conversation it did not open** — the player's Esc, `end_talk`. Told to
## `STOP` instead, it stands still and says why. Either way, a walk that does not arrive
## leaves a `report` naming the tile, the place, who was talking, the fight's phase and
## the last things that happened.
##
## Lives in `tools/` with the other hands on the keys: it decides nothing about the
## rules, it only presses. Nothing in the game loads it.

## Walk away from a conversation somebody else opened.
const LEAVE: StringName = &"leave"
## Stop at one, and report it.
const STOP: StringName = &"stop"
## How many of the last events a report names.
const LAST_EVENTS: int = 6
## The most steps of fighting one walk will play before it calls the fight stuck.
const FIGHT_CAP: int = 20000
## What `_through` dealt with.
const NOTHING: int = 0
const FOUGHT: int = 1
const LEFT: int = 2
const STOPPED: int = -1

var talks: StringName = LEAVE
var hands: DuelPlayer = DuelPlayer.new(DuelPlayer.PRESS)
## Why the last walk stopped short. Empty after one that arrived.
var report: String = ""
## Everyone it walked away from, in order.
var left: Array[StringName] = []


func _init(p_talks: StringName = LEAVE) -> void:
	talks = p_talks


## Walk to a tile by a path, within `budget` steps of walking, fighting and leaving as
## it goes. The path is `Navigation.waypoints` — thinned to straight lines that stay on
## open ground, which is how a person crosses a field — and `off_road` asks it to keep
## off the king's ground where it can. **A fight's steps are not the walk's**: the
## world's clock is held while one lasts, so a walk that meets a pack still has the
## time it was given; `FIGHT_CAP` stops one that never ends.
func walk_to(sim: Sim, target: Vector2i, budget: int, off_road: bool = false) -> bool:
	report = ""
	var world := sim.store(&"world") as WorldState
	var route: Array[Vector2] = Navigation.waypoints(world.region(), world.player_tile(), target, 4, off_road)
	if route.is_empty():
		report = _stalled(sim, target, "no way from here")
		return false
	var next: int = 0
	var held := Vector2i.ZERO
	var spent: int = 0
	var fought: int = 0
	var replan: bool = false
	while spent < budget:
		var interrupted: int = _through(sim)
		if interrupted == STOPPED:
			report = _stalled(sim, target, "a conversation it did not open")
			return false
		if interrupted != NOTHING:
			held = Vector2i.ZERO
			replan = true
			if interrupted == FOUGHT:
				fought += 1
				if fought > FIGHT_CAP:
					report = _stalled(sim, target, "a fight that would not end")
					return false
			else:
				spent += 1
			continue
		if replan:
			# **The route was worked out before the fight and the fight moved us.** Walking
			# the old one from a new tile wanders; look again from where you are — once,
			# when it is over, and not on every step of it (the review).
			replan = false
			route = Navigation.waypoints(world.region(), world.player_tile(), target, 4, off_road)
			next = 0
			if route.is_empty():
				report = _stalled(sim, target, "no way from where it was left")
				return false
		while next < route.size() and world.player_pos.distance_to(route[next]) <= 1.0:
			next += 1
		if next >= route.size():
			sim.submit(&"move_intent", {"x": 0, "y": 0})
			sim.advance(2)
			return true
		held = _hold(sim, world, route[next], held)
		sim.advance(1)
		spent += 1
	report = _stalled(sim, target, "out of time")
	return false


## Steer straight through a line of points — a road's bends, where a shortest path
## between two corners would cut onto the verge — fighting and leaving the same way.
func follow(sim: Sim, points: Array[Vector2i], budget: int) -> bool:
	report = ""
	var world := sim.store(&"world") as WorldState
	var held := Vector2i.ZERO
	var next: int = 0
	var spent: int = 0
	var fought: int = 0
	while spent < budget:
		var interrupted: int = _through(sim)
		if interrupted == STOPPED:
			report = _stalled(sim, points[next], "a conversation it did not open")
			return false
		if interrupted != NOTHING:
			held = Vector2i.ZERO
			if interrupted == FOUGHT:
				fought += 1
				if fought > FIGHT_CAP:
					report = _stalled(sim, points[next], "a fight that would not end")
					return false
			else:
				spent += 1
			continue
		var target: Vector2 = Vector2(points[next]) + Vector2(0.5, 0.5)
		if world.player_pos.distance_to(target) <= 1.0:
			next += 1
			if next >= points.size():
				sim.submit(&"move_intent", {"x": 0, "y": 0})
				sim.advance(2)
				return true
			continue
		held = _hold(sim, world, target, held)
		sim.advance(1)
		spent += 1
	report = _stalled(sim, points[mini(next, points.size() - 1)], "out of time")
	return false


## One step of whatever is not walking: a fight's turn, or leaving a conversation, or
## `STOPPED` when a conversation is open and this walker was told to stop at one.
func _through(sim: Sim) -> int:
	var duel := sim.store(&"duel") as Duel
	if duel != null and duel.on():
		hands.play(sim, duel)
		sim.advance(1)
		return FOUGHT
	var world := sim.store(&"world") as WorldState
	if world.in_dialogue():
		if talks == STOP:
			return STOPPED
		left.append(world.talking_to)
		sim.submit(&"end_talk")
		sim.advance(1)
		return LEFT
	return NOTHING


## Hold the direction toward a point, submitting only when it changes, as a keyboard does.
static func _hold(sim: Sim, world: WorldState, target: Vector2, held: Vector2i) -> Vector2i:
	var gap: Vector2 = target - world.player_pos
	var wanted := Vector2i(
		signi(int(round(gap.x))) if absf(gap.x) > 0.4 else 0,
		signi(int(round(gap.y))) if absf(gap.y) > 0.4 else 0)
	if wanted != held:
		sim.submit(&"move_intent", {"x": wanted.x, "y": wanted.y})
	return wanted


## Where the walker stood and what was going on, in one line an assertion can print.
func _stalled(sim: Sim, target: Vector2i, why: String) -> String:
	var world := sim.store(&"world") as WorldState
	var tile: Vector2i = world.player_tile()
	var zone: StringName = world.region().zone_at(tile)
	var duel := sim.store(&"duel") as Duel
	var last := PackedStringArray()
	var count: int = sim.events.size()
	for i: int in range(maxi(count - LAST_EVENTS, 0), count):
		last.append(String(sim.events.at(i).type))
	return "walk to %s stopped at %s in %s, step %d: %s; talking to %s; fight %s; last: %s" % [
		target, tile, zone if zone != &"" else &"the wild", sim.step, why,
		world.talking_to if world.talking_to != &"" else &"nobody",
		duel.phase if duel != null and duel.on() else &"none", ", ".join(last)]
