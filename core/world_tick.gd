class_name WorldTick
extends RefCounted

## §8's twelve tracked quantities — the world's vital signs.
##
## A store, rebuilt by replay like any other. Global unless §8 says per town: grain
## price and town sentiment are held once per settlement, army strength is not,
## because there is one army.
##
## Everything is 0–100 with 100 as "as good as it gets for whoever owns it", except
## the escort, which is a count of men. Stage 1 of Phase 3 gives only **army
## strength** a drift rule; the rest are declared, addressable and at their
## baseline, and each gets its rule when the consequence that needs it is built.
## Twelve invented drift rates would be twelve numbers nobody had reasoned about.

const BASELINE: float = 100.0
const NEUTRAL: float = 50.0

# -- global ---------------------------------------------------------------
var steel_output: float = BASELINE
var worker_morale: float = NEUTRAL
var patrol_density: float = NEUTRAL
var guard_alertness: float = NEUTRAL
var crown_treasury: float = BASELINE
var bank_confidence: float = BASELINE
var army_strength: float = BASELINE
var faction_tension: float = NEUTRAL
var rumour_spread: float = 0.0
## How many tiles around the fairies' clearing are still theirs.
##
## **Not a thirteenth tracked quantity** — §19 Q11 refused one of those and the
## refusal still holds. This is the same kind of thing as `grain_price` and
## `town_sentiment`: a reading about a *place*, kept here because here is where
## readings live. Nothing about an ending consults it.
var held_ground: float = WorldRules.HELD_AT_START

# -- per town (§8) --------------------------------------------------------
var grain_price: Dictionary = {}
var town_sentiment: Dictionary = {}
## Guard alertness, §8's fifth quantity, **per town** (2026-09-11). It was global
## and a granary burned in the Wide Acres closed the bank a hundred and twenty tiles
## away, which nobody could read as anything but a bug. Same change grain price and
## town sentiment already took, for the same reason: this one is about a place.
var guard_alertness_by_town: Dictionary = {}
## **Hardship**, per town (2026-09-13, §8). What an act costs the people who live in a
## place, held apart from what it costs the crown. Not a thirteenth quantity: the
## twelve are untouched and this stands beside them the way `held_ground` does, a
## reading about a *place*.
##
## **Up is worse.** Like grain price, and unlike the eight global figures where 100 is
## as good as it gets: 50 is the ordinary lot of a place under this crown, and it rises
## when the people there are worse off. It barely drifts and moves sharply when acted
## on — every deed that moves the kingdom pushes it somewhere, in either direction
## (DeedRules.hardship_effects) — so it always reads as caused. Nothing about an ending
## reads it as a threshold; the journal reads it out.
var hardship: Dictionary = {}

## What army strength is easing toward. Set by events; reached over in-game days.
var army_target: float = BASELINE
## And what each town's grain is easing toward. Bread does not double overnight;
## the delay is what makes a price rise read as a consequence rather than a switch.
var grain_target: Dictionary = {}
## Towns that were warned in time and laid in stores. Worth nothing on the day and
## a great deal on the day the camp empties — §8's warning, cashed later.
var prepared: Dictionary = {}

## **The handprint.** Quantity name -> how much of where that number stands the
## player put there.
##
## §3's hard rule: drift may move the world, only the player may end it. A deed
## writes the quantity *and* this; a drift writes only the quantity. Without it a
## reign could fall out of ambient motion and the player would be a spectator at
## their own story.
##
## It is also the only place the game knows what it caused. §8 forbids the *world*
## from ever telling the player — but the journal reads this, and so do the end
## conditions, which is the difference between a king brought down and one who fell
## over on his own.
var handprint: Dictionary = {}


## The one way a quantity moves by the player's hand.
##
## Everything that is a consequence of an act goes through here; everything that is
## weather goes straight to the field. Making them different calls is what keeps the
## distinction from being a comment somebody forgets.
func push(quantity: StringName, amount: float) -> void:
	set_quantity(quantity, get_quantity(quantity) + amount)
	handprint[quantity] = float(handprint.get(quantity, 0.0)) + absf(amount)


## A change the player set in motion that has not arrived yet.
##
## Exposing the fraud drops the army twenty-five points tonight and forty more over
## the following week. All of it is the player's doing, but only the first part
## happens on the day — so the handprint is credited at the act for the whole of
## what was set going, and the drift that delivers it stays weather in the code.
func credit(quantity: StringName, amount: float) -> void:
	handprint[quantity] = handprint_on(quantity) + absf(amount)


## A quantity dragged by another inherits its credit.
##
## The bank losing faith because the player emptied the treasury is the player's
## doing, one step removed. Without this, coupling would launder the hand out of
## every consequence further than one step from the act — and §3's endings would
## stop firing for exactly the runs that earned them.
func credit_from(target: StringName, driver: StringName, amount: float) -> void:
	if handprint_on(driver) <= 0.0:
		return
	credit(target, amount)


func handprint_on(quantity: StringName) -> float:
	return float(handprint.get(quantity, 0.0))


## Addressable by name, because the end conditions and the journal both walk the
## list rather than naming ten fields each.
const TRACKED: Array[StringName] = [
	&"steel_output", &"worker_morale", &"patrol_density", &"guard_alertness",
	&"crown_treasury", &"bank_confidence", &"army_strength", &"faction_tension",
]


func get_quantity(quantity: StringName) -> float:
	return float(get(String(quantity)))


func set_quantity(quantity: StringName, value: float) -> void:
	set(String(quantity), clampf(value, 0.0, BASELINE))


func _init() -> void:
	for town: StringName in Region.ZONE_ORDER:
		grain_price[town] = NEUTRAL
		grain_target[town] = NEUTRAL
		town_sentiment[town] = NEUTRAL
		guard_alertness_by_town[town] = NEUTRAL
		hardship[town] = NEUTRAL


func grain_in(town: StringName) -> float:
	return float(grain_price.get(town, NEUTRAL))


func sentiment_in(town: StringName) -> float:
	return float(town_sentiment.get(town, NEUTRAL))


## How the region as a whole regards the crown. The end conditions ask about towns
## in the plural — one sour town is a bad week, five is a country turning.
func towns_below(sentiment: float) -> int:
	var count: int = 0
	for town: StringName in Region.ZONE_ORDER:
		if sentiment_in(town) < sentiment:
			count += 1
	return count


func alertness_in(town: StringName) -> float:
	return float(guard_alertness_by_town.get(town, NEUTRAL))


func rouse(town: StringName, amount: float) -> void:
	guard_alertness_by_town[town] = clampf(alertness_in(town) + amount, 0.0, BASELINE)
	handprint[&"guard_alertness"] = handprint_on(&"guard_alertness") + absf(amount)


## §8 declares one figure and the watch is now per town, so the regional one is the
## worst-watched place in the kingdom. Recomputed rather than accumulated: a
## high-water mark that only ever rises is not a reading of anything.
func settle_alertness() -> void:
	var worst: float = 0.0
	for town: StringName in Region.ZONE_ORDER:
		worst = maxf(worst, alertness_in(town))
	guard_alertness = worst


func push_sentiment(town: StringName, amount: float) -> void:
	town_sentiment[town] = clampf(sentiment_in(town) + amount, 0.0, BASELINE)
	handprint[&"town_sentiment"] = handprint_on(&"town_sentiment") + absf(amount)


func hardship_in(town: StringName) -> float:
	return float(hardship.get(town, NEUTRAL))


## The one way hardship moves. A deed's doing, so it carries the handprint like every
## other push; there is no drift path to it at all.
func push_hardship(town: StringName, amount: float) -> void:
	hardship[town] = clampf(hardship_in(town) + amount, 0.0, BASELINE)
	handprint[&"hardship"] = handprint_on(&"hardship") + absf(amount)


## The king's escort, quantity #12 — a count of men, derived rather than stored.
##
## §3's "roughly one and a half fewer per power base damaged" never worked: six
## power bases at 1.5 leaves one guard rather than "a bare handful", and 1.5 is not
## a person. Reading it off army strength makes it continuous, integral, and a
## consequence of the world rather than a tally of the player's achievements.
func kings_escort() -> int:
	return WorldRules.escort_for(army_strength)


func fingerprint() -> String:
	var towns := PackedStringArray()
	for town: StringName in Region.ZONE_ORDER:
		towns.append("%s:%.2f/%.2f/%.2f" % [town, grain_in(town), sentiment_in(town), hardship_in(town)])
	return "army=%.3f->%.1f escort=%d steel=%.1f morale=%.1f patrol=%.1f alert=%.1f treasury=%.1f bank=%.1f tension=%.1f rumour=%.1f held=%.3f | %s" % [
		army_strength, army_target, kings_escort(), steel_output, worker_morale,
		patrol_density, guard_alertness, crown_treasury, bank_confidence,
		faction_tension, rumour_spread, held_ground, ";".join(towns),
	]
