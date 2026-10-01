class_name Appearance
extends RefCounted

## What the player chose to look like (group A): five choices, made once at creation by
## the same event that sets the traits, and never changed after (Yannick, 2026-10-01). A
## store like `Traits`, rebuilt by replay; a run that never chose is his brother's traveller.

var _choices: Dictionary = AppearanceRules.default_appearance()


## Every choice, his traveller's where none was made.
func chosen() -> Dictionary:
	return _choices.duplicate()


func of(choice: StringName) -> StringName:
	return _choices.get(choice, &"") as StringName


func choose(wanted: Dictionary) -> bool:
	if not AppearanceRules.is_legal(wanted):
		return false
	_choices = AppearanceRules.completed(wanted)
	return true


func fingerprint() -> String:
	var parts := PackedStringArray()
	for choice: StringName in AppearanceRules.ALL:
		parts.append("%s=%s" % [choice, of(choice)])
	return ";".join(parts)
