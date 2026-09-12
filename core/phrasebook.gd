class_name Phrasebook
extends RefCounted

## Words somebody has already been given for a situation.
##
## Keyed by the **packet fingerprint plus the intent**, so the same person in the
## same world answering the same question always gets the same words. That is the
## whole reason §9 refused retrieval: the packet is hashed, and a drifting packet is
## a drifting key, a cache miss and a broken determinism guarantee.
##
## A store like any other, rebuilt by replay. It holds nothing the log does not.

var lines: Dictionary = {}
var asked: int = 0
var served: int = 0


static func key_for(packet: String, intent: StringName) -> String:
	return "%s:%s" % [Context.fingerprint(packet), intent]


func remembers(key: String) -> bool:
	return lines.has(key)


func recall(key: String) -> String:
	return String(lines.get(key, ""))


func remember(key: String, line: String) -> void:
	lines[key] = line


## How often the book had an answer, which is the number that decides whether a
## model ever needs to run while somebody is playing.
func hit_rate() -> float:
	return float(served) / float(maxi(asked, 1))


func fingerprint() -> String:
	var keys: Array = lines.keys()
	keys.sort()
	var parts := PackedStringArray()
	for key: String in keys:
		parts.append("%s=%d" % [key, String(lines[key]).length()])
	return "n=%d asked=%d served=%d %s" % [lines.size(), asked, served, ";".join(parts)]
