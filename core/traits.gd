class_name Traits
extends RefCounted

## Who the player chose to be.
##
## A store like any other, rebuilt by replay: the levels arrive as one external event
## at creation and nothing changes them afterwards (§19 Q23 — traits do not rise). So
## this holds no history and needs none.

var levels: Dictionary = TraitRules.at_the_floor()
## Whether the player has actually been through creation, as opposed to being at the
## floor because nobody asked them. The title screen needs to know; the simulation
## does not care, and treats an unmade character as a legal one.
var chosen: bool = false


func level_of(what: StringName) -> int:
	return int(levels.get(what, TraitRules.FLOOR))


## Whether a line that leans on a trait is one this character can say.
func speaks_with(what: StringName) -> bool:
	return level_of(what) >= TraitRules.SPEAKS_AT


func choose(wanted: Dictionary) -> bool:
	if not TraitRules.is_legal(wanted):
		return false
	levels = TraitRules.at_the_floor()
	for what: StringName in TraitRules.ALL:
		if wanted.has(what):
			levels[what] = int(wanted[what])
	chosen = true
	return true


func fingerprint() -> String:
	var parts := PackedStringArray()
	for what: StringName in TraitRules.ALL:
		parts.append("%s=%d" % [what, level_of(what)])
	return "%s chosen=%s" % [";".join(parts), chosen]
