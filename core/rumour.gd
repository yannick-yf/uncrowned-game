class_name Rumour
extends RefCounted

## One story, travelling.
##
## Not a number. §8's eleventh quantity is a single "rumour spread" scalar, and a
## scalar cannot arrive in Cairnwell three days after a theft in Harrowgate — it
## has no *what*, no *where*, and no *how far it has got*. A rumour carries all
## three, and reaches towns one at a time as it spreads.

var id: int = 0
## What happened, as a fact id: theft, violence, whatever later joins them.
var about: StringName = &""
## Where it happened, and who told the story first.
var origin: StringName = &""
var witnesses: PackedStringArray = PackedStringArray()
## How far from the origin the story has got, in tiles.
var reach: float = 0.0
var started_step: int = 0
## Towns it has already reached, so it moves a reputation once and not every tick.
var arrived: Dictionary = {}


func has_reached(town: StringName) -> bool:
	return bool(arrived.get(town, false))


func describe() -> String:
	return "%s from %s, %d witness(es), %.0f tiles out" % [
		String(about), String(origin), witnesses.size(), reach,
	]
