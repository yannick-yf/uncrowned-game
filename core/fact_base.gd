class_name FactBase
extends RefCounted

## What the world knows, and who can tell you.
##
## Derived state: never authoritative, always rebuildable by replaying the event
## log. A fact is an id plus the set of sources that can supply it, and the sources
## are the point — the redundancy rule counts them, and the reachability check walks
## them. A fact with one source is a fact one death can remove.
##
## Nothing here knows what a fact means. Ids are opaque.

var _sources: Dictionary = {}


func add_source(fact: StringName, source: StringName) -> void:
	if not _sources.has(fact):
		_sources[fact] = {}
	var sources: Dictionary = _sources[fact] as Dictionary
	sources[source] = true


func remove_source(fact: StringName, source: StringName) -> void:
	if not _sources.has(fact):
		return
	var sources: Dictionary = _sources[fact] as Dictionary
	sources.erase(source)
	if sources.is_empty():
		_sources.erase(fact)


func has(fact: StringName) -> bool:
	return _sources.has(fact)


func source_count(fact: StringName) -> int:
	if not _sources.has(fact):
		return 0
	return (_sources[fact] as Dictionary).size()


## Sorted lexicographically, so that anything hashing this — a dialogue context
## packet, a test fingerprint — gets the same bytes for the same state.
func sources_of(fact: StringName) -> Array[StringName]:
	if not _sources.has(fact):
		return [] as Array[StringName]
	return _sorted_names((_sources[fact] as Dictionary).keys())


func facts() -> Array[StringName]:
	return _sorted_names(_sources.keys())


## Array[StringName].sort() orders by StringName's internal pointer, not by the
## text, so it is stable within one process and meaningless across two. Every
## ordering here goes through String to stay reproducible between runs.
static func _sorted_names(names: Array) -> Array[StringName]:
	var text := PackedStringArray()
	for name: Variant in names:
		text.append(String(name))
	text.sort()
	var out: Array[StringName] = []
	for entry: String in text:
		out.append(StringName(entry))
	return out


func size() -> int:
	return _sources.size()


## Invariant 6, at the level of a single fact: two independent sources.
func is_redundant(fact: StringName) -> bool:
	return source_count(fact) >= 2


func single_source_facts() -> Array[StringName]:
	var out: Array[StringName] = []
	for fact: StringName in facts():
		if source_count(fact) < 2:
			out.append(fact)
	return out


## Stable string for the whole store. Two runs that agree here agree everywhere
## that matters, which is what makes replay testable.
func fingerprint() -> String:
	var parts := PackedStringArray()
	for fact: StringName in facts():
		var sources := PackedStringArray()
		for source: StringName in sources_of(fact):
			sources.append(String(source))
		parts.append("%s=%s" % [String(fact), ",".join(sources)])
	return ";".join(parts)
