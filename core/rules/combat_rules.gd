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
## His second option (F5), and the reason distance is a decision rather than a number.
const JAB: StringName = &"jab"
## The player's third thing to do, beside hitting and holding (F5).
const BACKSTEP: StringName = &"backstep"

static var _moves: Dictionary = {}
static var _fighters: Dictionary = {}
static var _opponents: Dictionary = {}


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
	_opponents = root.get("opponents", {}) as Dictionary


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


## **Does this move hurt anybody?** The backstep is a move like the others — it runs
## its frames, it cannot be interrupted, and you cannot act during it — but it has no
## blow in it. Without this, its ten travelling frames would read as ten active frames
## of a hitbox that does nothing, and the log would fill with blows that cost zero.
static func is_attack(move: StringName) -> bool:
	return of(move, "damage") > 0


## How far a move carries the fighter, per frame of its active window. Only the
## backstep has one; everything else is zero and moves nobody.
static func travel_mm(move: StringName) -> int:
	return of(move, "travel_mm")


## **Which blow he throws, and it is not a coin** (F5). The distance decides it, so it
## is a thing the player can learn and then use: stand at the edge of his reach and he
## must wind up the slow one, step inside it and he answers with the short one.
##
## Pure, and here rather than in the system, because "what he does" is the half of the
## fight a player is actually reading.
static func chooses(apart_mm: int) -> StringName:
	if apart_mm <= of(JAB, "reach_mm") + slack_mm():
		return JAB
	return SWING


## Whether the blow is out on this frame of the move. Before that the fighter is
## winding up and can be hit; after it, they are recovering and can be punished.
static func is_active(move: StringName, frame: int) -> bool:
	var startup: int = of(move, "startup")
	return frame >= startup and frame < startup + of(move, "active")


## **Frames a move cannot be hit during.** Only the backstep has any, and they are
## exactly its travel. It is what makes it a dodge rather than a slow walk backwards:
## measured without them, reacting to the heavy blow at a human’s sixteen frames left
## the player 360 mm further away when it landed, which is nowhere near out of a blow
## that reaches two metres. The played fight said so while every number looked right.
static func is_invulnerable(move: StringName, frame: int) -> bool:
	var to: int = of(move, "invulnerable_to")
	return to > 0 and frame >= of(move, "invulnerable_from") and frame < to


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


## **The shape of a blow, for whoever is drawing it.** −1 is fully drawn back, +1 is
## fully thrust forward, 0 is standing. Returned as a fraction so the window decides how
## many centimetres that is worth and the rule decides *when*.
##
## **This exists because his brother has not drawn a blow.** `traveler_walk_frames.tres`
## holds eight animations — idle and walk, four directions — and no attack, no guard and
## no flinch. Without something, a strike, a guard and a backstep all look like a person
## standing still, and the twenty-four frames of wind-up the whole fight is built to be
## read are invisible. Moving the sprite he already made is not drawing over him: it is a
## placeholder that is visibly a placeholder, which is this project's rule for anything
## his library does not have yet.
##
## Pure and here rather than in the window because *when* a blow reads as coming is the
## fight's business, and because it can then be tested without drawing anything.
static func lunge_at(move: StringName, frame: int) -> float:
	if move == &"" or not is_attack(move):
		return 0.0
	var startup: int = of(move, "startup")
	if frame < startup:
		# Drawn back, further the closer it is to landing. The tell.
		return -float(frame + 1) / float(maxi(startup, 1))
	if is_active(move, frame):
		return 1.0
	var since: int = frame - startup - of(move, "active") + 1
	var recovery: int = maxi(of(move, "recovery"), 1)
	return maxf(1.0 - float(since) / float(recovery), 0.0)


## **How low a fighter is carried, as the same fraction.** Positive is a crouch and
## negative is a rise. A blow is a gather and a release: he sinks through the wind-up and
## comes up as it goes out, which is the part of a punch a person actually reads. Purely
## up and down, so his pixels are never stretched — a pixel figure squashed to sell a
## movement stops being pixel art.
static func dip_at(move: StringName, frame: int) -> float:
	if move == &"" or not is_attack(move):
		return 0.0
	var startup: int = of(move, "startup")
	if frame < startup:
		return float(frame + 1) / float(maxi(startup, 1))
	if is_active(move, frame):
		return -0.4
	return 0.0


## **Which of the drawn poses a fighter is in**, or `&""` for none of them —
## standing or walking, as the rest of the game draws people.
##
## **The wind-up announces itself on the frame it starts** (H3, 2026-09-21). The second
## pass held the cocked arm back until the second half of the wind-up, on the argument
## that a fist that cocks instantly reads as a twitch. Played, that argument lost: §2
## gives the player 28 frames to read the heavy blow and a human needs 16 of them, and
## a tell that only began on frame 14 left two frames to act on. The arm comes back on
## frame 0 now, and the telegraph beside it (`telegraph_at`) fills from the same frame.
static func pose_of(move: StringName, frame: int, stunned: int, guarding: bool) -> StringName:
	if stunned > 0:
		return &"hurt"
	if is_attack(move):
		if frame >= of(move, "startup"):
			return &"attack"
		return &"ready"
	if guarding and move == &"":
		return &"guard"
	return &""


## **How far through its wind-up a blow is**, 0.0 on the frame it starts and 1.0 on the
## frame before it is out — or **−1.0 when nothing is winding up**, so the window can
## tell "no telegraph" from "a telegraph just begun" without a second question.
##
## This is the telegraph's clock, and it is a rule and not a picture because the whole
## of `docs/COMBAT.md` §2 is a promise about *when* a blow can be read: 28 frames for
## the heavy one, 18 for the short one, and the player needs 16. Whatever the window
## draws to say "a blow is coming" — a ring filling, a figure drawn back — it draws it
## against this number, so the moment a tell begins is the fight's to decide and can be
## tested with nothing on screen.
static func telegraph_at(move: StringName, frame: int) -> float:
	if move == &"" or not is_attack(move) or not is_winding_up(move, frame):
		return -1.0
	var startup: int = maxi(of(move, "startup"), 1)
	return float(frame) / float(maxi(startup - 1, 1))


## How far a fighter leans away while holding a guard. Small: it is a stance, not a move.
static func guard_lean() -> float:
	return -0.35


## And how low. Behind a guard you are braced, not standing.
static func guard_dip() -> float:
	return 0.5


## Does this blow reach? One subtraction and one comparison, on integers.
##
## The slack is the pushbox by another name: two fighters cannot stand in the same
## millimetre, and a blow that only just reaches should land rather than be lost to an
## off-by-one nobody can see.
static func reaches(attacker_mm: int, defender_mm: int, move: StringName) -> bool:
	return absi(defender_mm - attacker_mm) <= of(move, "reach_mm") + slack_mm()


static func slack_mm() -> int:
	return int(fighters().get("reach_slack_mm", 0))


## **How close two fighters may stand**, centre to centre. Its own number since H4:
## it was twice the slack, 500 mm, and his traveller is drawn 1.1 m wide at the head —
## so two of them at 500 mm were one figure with two pairs of feet, which is what
## "the collisions are not right" looked like. A file without the row keeps the old
## relation, so nothing of the fight's history reads differently.
static func pushbox_mm() -> int:
	return int(fighters().get("pushbox_mm", slack_mm() * 2))


## **The beat** (H5): frames between the blow that decides a fight and the world
## coming back. Zero means what it did before — over on the frame it is decided.
static func settle_steps() -> int:
	return int(fighters().get("settle_steps", 0))


static func walk_mm_per_step() -> int:
	return int(fighters().get("walk_mm_per_step", 0))


## **How long he stands free before he commits.** Deliberately not the move’s own
## startup, which is what it was: he then waited as long as the blow took to wind up
## and wound up for that long again, and the player crossed a whole distance band in
## the gap. Separating the two is what let the heavy blow exist at all.
static func decides_after_steps() -> int:
	return int(fighters().get("decides_after_steps", 0))


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


# -------------------------------------------------------------- who he is (F4) ---

static func opponents() -> Dictionary:
	if _opponents.is_empty():
		_read()
	return _opponents


static func _about(who: StringName) -> Dictionary:
	var all: Dictionary = opponents()
	if all.has(who):
		return all[who] as Dictionary
	return all.get("_default", {}) as Dictionary


static func hp_of(who: StringName) -> int:
	return int(_about(who).get("hp", WorldState.MAX_HP))


## **Whether he stops when you go down.** A sparring partner does, and Bram says so in
## his own line — *« je m'arrête quand tu tombes »* — so the code had better agree with
## the content. Anybody not listed does not: the demo's fights are not all friendly, and
## the king least of all.
##
## It is per opponent and lives in `content/moves.json` rather than in a branch here,
## because "who spares you" is a fact about a person and the whole of this fight's
## tuning is one file.
static func spares(who: StringName) -> bool:
	return bool(_about(who).get("spares", false))


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
