class_name UnrestSystem
extends SimSystem

## How the world's mood follows its conditions.
##
## §8 says what each quantity drifts on and most of them drift on each other: bank
## confidence on the treasury, town sentiment on prices and patrols, patrol density
## on crime reports. None of that was built, which is why ten of the twelve sat at
## their baseline and the game had only one number that moved.
##
## **The handprint travels with the cause.** If the player emptied the treasury, the
## bank losing faith is their doing too — so a quantity dragged by another inherits
## its credit. Without that, coupling would launder the player's hand out of every
## consequence more than one step from the act, and §3's endings would stop firing
## for the very runs that deserved them most.

## How fast a coupled quantity follows the one that drives it.
const FOLLOWS_PER_DAY: float = 3.0
## What a crime the world hears about does to the men paid to prevent it.
const PATROL_PER_CRIME: float = 9.0
## What one deed the world hears about does to the watch where it happened. Tuned
## so three acts in a place close it and the fourth is refused: a rhythm of act,
## move on, come back, rather than a wall or a free pass.
const ALERT_PER_CRIME: float = 9.0
## And how fast that settles again once nothing is happening.
## And how fast it settles once nothing is happening. At 1.5 a shut power base
## stayed shut for forty real minutes, which is not a rhythm, it is a wait.
const CALM_PER_DAY: float = 6.0
## Bread this dear is what turns a town against whoever is supposed to prevent it.
const BREAD_BITES: float = 55.0


func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type != &"deed_witnessed":
		return
	var ticked := sim.store(&"worldtick") as WorldTick
	if ticked == null:
		return
	# §8's fourth and fifth quantities, as §8 states them: patrol density is pushed
	# by being seen committing violence, guard alertness by any witnessed crime.
	# §10's "violence is never mechanically punished" means no karma meter and no
	# progression gate — the world thickening its patrols *is* the social
	# punishment §10 describes, and it is visible, diegetic and escapable (§19 Q7).
	if DeedRules.town_effect(StringName(event.data.get("about", ""))) >= 0.0:
		return
	ticked.push(&"patrol_density", PATROL_PER_CRIME)
	ticked.rouse(StringName(event.data.get("town", "")), ALERT_PER_CRIME)


func on_tick(sim: Sim, _tick: int) -> void:
	var ticked := sim.store(&"worldtick") as WorldTick
	if ticked == null:
		return
	_follow(ticked, &"bank_confidence", &"crown_treasury")
	_sentiment(ticked)
	_calm(ticked, &"patrol_density")
	for town: StringName in Region.ZONE_ORDER:
		ticked.guard_alertness_by_town[town] = WorldRules.drift(
			ticked.alertness_in(town), WorldTick.NEUTRAL, CALM_PER_DAY)
	ticked.settle_alertness()

	# Quantity #11 is a readout, not a store. Rumour spread stopped being a scalar
	# the day rumours became objects that travel; this is what the number was
	# always reporting.
	var rumours := sim.store(&"rumours") as Rumours
	if rumours != null:
		ticked.rumour_spread = clampf(float(rumours.live.size()) * 20.0, 0.0, 100.0)


## One quantity eases toward another, carrying its credit with it.
func _follow(ticked: WorldTick, target: StringName, driver: StringName) -> void:
	var was: float = ticked.get_quantity(target)
	var now: float = WorldRules.drift(was, ticked.get_quantity(driver), FOLLOWS_PER_DAY)
	if is_equal_approx(now, was):
		return
	ticked.set_quantity(target, now)
	ticked.credit_from(target, driver, absf(now - was))


## Towns sour when bread does. §8's eighth quantity drifts on prices, and the price
## is already a consequence of something the player did or did not prevent.
func _sentiment(ticked: WorldTick) -> void:
	for town: StringName in Region.ZONE_ORDER:
		var dear: float = maxf(ticked.grain_in(town) - BREAD_BITES, 0.0)
		var was: float = ticked.sentiment_in(town)
		var now: float = WorldRules.drift(was, WorldTick.NEUTRAL - dear, FOLLOWS_PER_DAY)
		if is_equal_approx(now, was):
			continue
		ticked.town_sentiment[town] = now
		ticked.credit_from(&"town_sentiment", &"grain_price", absf(now - was))


func _calm(ticked: WorldTick, quantity: StringName) -> void:
	ticked.set_quantity(quantity, WorldRules.drift(
		ticked.get_quantity(quantity), WorldTick.NEUTRAL, CALM_PER_DAY))


func system_name() -> StringName:
	return &"unrest"
