class_name CombatRules
extends RefCounted

## The rules of a fight. Pure, and integers all the way down.
##
## **One sim step is one frame.** `Sim` has run at 60 steps a second since Phase 0 for
## its own reasons, and that happens to be exactly a fighting game's clock — so the
## frame data in `content/moves.json` is written in steps and thirty years of published
## numbers can be read into it without conversion.
##
## **No Godot physics, ever.** Snopek, who wrote rollback for Godot, replaced the engine's
## physics rather than fix it: *the built-in physics engine in Godot is NOT
## deterministic*. A save here **is** the event log, so a fight that asked an `Area3D`
## whether a blow landed would break every save in the game and break them silently. A
## hit is an interval overlap between two integers, computed here, by a function that
## could not call into Godot if it wanted to.
##
## **Millimetres on a line.** A fight locks its two fighters to one axis, so a position
## is one integer and a reach is another. Nothing rounds, nothing drifts, and a replay
## lands on the same millimetre a week later.

const PATH: String = "res://content/moves.json"

const STRIKE: StringName = &"strike"
const SWING: StringName = &"swing"

static var _moves: Dictionary = {}
static var _fighters: Dictionary = {}


## The frame data, read once. Everything a fight can be balanced with is in that file
## and in no other: the whole of tuning is editing one row.
static func moves() -> Dictionary:
	if _moves.is_empty():
		_read()
	return _moves


static func fighters() -> Dictionary:
	if _fighters.is_empty():
		_read()
	return _fighters


static func _read() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not (parsed is Dictionary):
		return
	var root: Dictionary = parsed as Dictionary
	for id: String in (root.get("moves", {}) as Dictionary).keys():
		_moves[StringName(id)] = (root["moves"] as Dictionary)[id]
	_fighters = root.get("fighters", {}) as Dictionary


static func has_move(move: StringName) -> bool:
	return moves().has(move)


static func of(move: StringName, field: String, fallback: int = 0) -> int:
	if not has_move(move):
		return fallback
	return int((moves()[move] as Dictionary).get(field, fallback))


## How long the whole move takes, from the frame it is pressed to the frame the fighter
## can act again.
static func length(move: StringName) -> int:
	return of(move, "startup") + of(move, "active") + of(move, "recovery")


## Whether the blow is out on this frame of the move. Before that the fighter is
## winding up and can be hit; after it, they are recovering and can be punished.
static func is_active(move: StringName, frame: int) -> bool:
	var startup: int = of(move, "startup")
	return frame >= startup and frame < startup + of(move, "active")


## Whether the fighter can still be hit *before* their own blow is out. The whole of
## why a slow move is a risk.
static func is_winding_up(move: StringName, frame: int) -> bool:
	return frame < of(move, "startup")


## What the fighter is owed after the blow: positive means their turn, negative means
## the other's. Reported rather than used, because it is how a move is judged.
static func advantage_on_hit(move: StringName) -> int:
	return of(move, "hitstun") - (of(move, "active") - 1 + of(move, "recovery"))


static func advantage_on_block(move: StringName) -> int:
	return of(move, "blockstun") - (of(move, "active") - 1 + of(move, "recovery"))


## Does this blow reach? One subtraction and one comparison, on integers.
##
## The slack is the pushbox by another name: two fighters cannot stand in the same
## millimetre, and a blow that only just reaches should land rather than be lost to an
## off-by-one nobody can see.
static func reaches(attacker_mm: int, defender_mm: int, move: StringName) -> bool:
	return absi(defender_mm - attacker_mm) <= of(move, "reach_mm") + slack_mm()


static func slack_mm() -> int:
	return int(fighters().get("reach_slack_mm", 0))


static func walk_mm_per_step() -> int:
	return int(fighters().get("walk_mm_per_step", 0))


static func start_apart_mm() -> int:
	return int(fighters().get("start_apart_mm", 0))


## What a blow costs the fighter who took it, guarding or not.
##
## A guard does not make anybody invulnerable. It makes the exchange survivable: a
## quarter of the damage, and blockstun instead of hitstun. Holding it is not a
## strategy, because every blocked blow still costs and no blow of yours can come out
## while it is up.
static func damage_through(move: StringName, guarding: bool) -> int:
	var damage: int = of(move, "damage")
	if not guarding:
		return damage
	var percent: int = int((fighters().get("guard", {}) as Dictionary).get("damage_taken_percent", 0))
	# Rounded up, so a guard never makes a blow free.
	return (damage * percent + 99) / 100


static func stun_from(move: StringName, guarding: bool) -> int:
	return of(move, "blockstun") if guarding else of(move, "hitstun")


static func knockback_from(move: StringName, guarding: bool) -> int:
	var back: int = of(move, "knockback_mm")
	return back if not guarding else back / 2


## Both fighters stop dead for a moment when a blow lands — the oldest trick in the
## genre and the reason a hit feels like a hit. It belongs **here** and not in the
## window: done in the view, the simulation would keep running behind a frozen picture
## and the next input would land on the wrong frame.
static func hitstop(move: StringName) -> int:
	return of(move, "hitstop")


## How much health an opponent brings to a fight. The player brings `WorldState`'s,
## because a fight has to be able to kill you down the same path everything else does.
static func opponent_hp() -> int:
	return WorldState.MAX_HP


static func is_down(hp: int) -> bool:
	return hp <= 0


# ----------------------------------------------------------------- the ground ---
#
# F3, 2026-09-19. The fight stops being an invisible line and becomes two people
# standing somewhere. Everything below converts between the two, and nothing else
# in the project is allowed to know the conversion.

## A tile is two metres (`BakeRules.METRES_PER_TILE`), which makes it two thousand
## millimetres. Read from there rather than written here, because a fight that
## disagreed with the map about how big a tile is would be wrong in a way no test of
## the fight alone could see.
static func mm_per_tile() -> float:
	return BakeRules.METRES_PER_TILE * 1000.0


static func tiles_of(mm: int) -> float:
	return float(mm) / mm_per_tile()


## How far from the middle of the fight either fighter may go.
##
## **A wall, not a warning** (Yannick, 2026-09-19: no fleeing in the demo). The fight
## is bounded so that it has a shape the camera can frame and the screen's darkened
## edge can mean something — and so that walking away is not a way out of a fight the
## player started by saying so.
static func arena_radius_mm() -> int:
	return int(fighters().get("arena_radius_mm", 0))


## The middle of the fight, on the fight's own line. The player starts at 0 and the
## opponent at `start_apart_mm`, so the middle is halfway between them and **not** the
## player's feet — an arena centred on the player would give him twice the room.
static func arena_centre_mm() -> int:
	return start_apart_mm() / 2


## Wherever a fighter was trying to get to, this is where they end up.
static func inside_arena(at_mm: int) -> int:
	var centre: int = arena_centre_mm()
	var radius: int = arena_radius_mm()
	return clampi(at_mm, centre - radius, centre + radius)
