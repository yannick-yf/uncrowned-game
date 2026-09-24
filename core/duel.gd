class_name Duel
extends RefCounted

## What is happening in a fight, this step — second design (K1, `docs/COMBAT_V2.md`).
##
## A store like any other: rebuilt by replay, holding nothing the log did not put
## there. The log holds that a fight began, **one event per turn**, and that it ended.
## A fight of twenty turns is twenty events, which is fewer than the first design
## rather than more — that one logged every change of what the player was holding down.
##
## **Built beside `Fight`, which still exists and still runs.** Nothing here replaces
## it; K6 is the change that takes the first design out, by hand, with it still on disk
## until then.

## Nobody is fighting.
const NOBODY: StringName = &""

## The phases a turn passes through. A turn is **move and act** — both, not one or the
## other — so it walks first and swings afterwards, and the pause is the gap that makes
## two turns read as two turns.
const WAITING: StringName = &"waiting"   ## the player's turn; the fight waits for them
const MOVING: StringName = &"moving"
const ACTING: StringName = &"acting"
const PAUSING: StringName = &"pausing"

var fighters: Array[DuelFighter] = []
## Which of them is acting, or −1 when nobody is.
var turn: int = -1
## Rounds completed. Everybody acts once a round, in a fixed order.
var round_number: int = 0
## How many turns have been taken, which is how many events the fight has written.
var turns_taken: int = 0

var phase: StringName = &""
## Steps left in the current phase.
var phase_left: int = 0

## The tiles still to be walked on this turn, the destination last. Recomputed on
## replay from the same event, never stored in the log.
var walk: Array[Vector2i] = []
## Steps into the tile currently being walked, so the figure can be drawn between two.
var walked: int = 0

## What this turn does when the walking is over, and to whom.
var acting: StringName = DuelRules.WAIT
var target: StringName = NOBODY
## Set once the blow has landed, so one blow cannot land twice over its act window.
var struck: bool = false

## Where the fight began, which is what an opponent will not chase you far from.
var began_at: Vector2i = Vector2i.ZERO
## **Whoever started the fight acts first** — there is no initiative roll, because
## there are no dice.
var started_by: StringName = NOBODY
## Who asked for this fight, so the answer can be handed back to them.
var asked_by: StringName = NOBODY

## Why it ended — `&"won"`, `&"lost"`, `&"left"` — or `&""` while it is still going.
## Set the step it is decided, which is `beat_steps` before it is over.
var outcome: StringName = NOBODY
## The beat: steps in which the fight is decided but not yet over.
var settling: int = 0
## What the felling blow is still owed, paid when the beat is over so the picture can
## show the player down where they fell rather than already awake at the last fire.
var owed_damage: int = 0
## Set the step a blow would have felled the player, whether or not it did — somebody
## who spares you stops the killing blow, and you still lost.
var player_felled: bool = false
## Who threw it, because whether they finish it is a fact about that person.
var felled_by: StringName = NOBODY


func on() -> bool:
	return not fighters.is_empty()


## Decided but not over: the beat between the last blow and the world returning.
func settled() -> bool:
	return on() and settling > 0


func me() -> DuelFighter:
	for fighter: DuelFighter in fighters:
		if fighter.is_player():
			return fighter
	return null


## The one in front of you, for a window that draws one fight at a time. The first
## living opponent in the fixed order, or the last one standing when all are out.
func foe() -> DuelFighter:
	var fallback: DuelFighter = null
	for fighter: DuelFighter in fighters:
		if fighter.is_player():
			continue
		fallback = fighter if fallback == null else fallback
		if fighter.alive():
			return fighter
	return fallback


func get_fighter(who: StringName) -> DuelFighter:
	for fighter: DuelFighter in fighters:
		if fighter.who == who:
			return fighter
	return null


func living(against: StringName = NOBODY) -> Array[DuelFighter]:
	var out: Array[DuelFighter] = []
	for fighter: DuelFighter in fighters:
		if not fighter.alive():
			continue
		if against != NOBODY and fighter.who == against:
			continue
		out.append(fighter)
	return out


## Everybody still in it who is not this one — the enemies, since there is no party.
func foes_of(who: StringName) -> Array[DuelFighter]:
	return living(who)


func acting_fighter() -> DuelFighter:
	if turn < 0 or turn >= fighters.size():
		return null
	return fighters[turn]


## Whether the fight is waiting on the player to say what they do.
func waiting_on_player() -> bool:
	if not on() or settling > 0 or phase != WAITING:
		return false
	var who: DuelFighter = acting_fighter()
	return who != null and who.is_player()


## **Where somebody is drawn**, which is between two tiles while they are walking and
## on their own tile the rest of the time. In tiles, like everything else.
func drawn_at(fighter: DuelFighter) -> Vector2:
	if fighter == null:
		return Vector2.ZERO
	if phase != MOVING or acting_fighter() != fighter or walk.is_empty():
		return fighter.centre()
	var to: Vector2 = Vector2(walk[0]) + Vector2(0.5, 0.5)
	var through: float = float(walked) / float(maxi(DuelRules.steps_per_tile(), 1))
	return fighter.centre().lerp(to, clampf(through, 0.0, 1.0))


## How far into the blow the acting fighter is: 0 on the first step of it, and the
## step it lands is `DuelRules.strike_at_step()`. The window reads it to draw the
## wind-up, which is the half of a blow a player reads.
func into_act() -> int:
	if phase != ACTING:
		return 0
	return maxi(DuelRules.act_steps() - phase_left, 0)


func fingerprint() -> String:
	if not on():
		return "none"
	var parts := PackedStringArray()
	for fighter: DuelFighter in fighters:
		parts.append(fighter.fingerprint())
	return "%s turn=%d/%s r=%d n=%d %s->%s %s beat=%d owed=%d fell=%s" % [
		" ".join(parts), turn, String(phase), round_number, turns_taken,
		String(acting), String(target), String(outcome), settling, owed_damage,
		player_felled,
	]
