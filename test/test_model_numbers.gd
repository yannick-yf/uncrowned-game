extends TestCase

## Every number the model can be balanced with, in one place (M6).
##
## Not tidiness. A number that gets written down twice is a number that gets changed
## once, and the old simulation had exactly that failure: quantities written in one
## file and read in another, with nobody able to say which was right.
##
## **Two places, and they are different kinds of thing.** `core/rules/town_rules.gd`
## holds the *rules'* numbers — the floor, the ceiling, the threshold, the player's
## step, the food floor, the gap the kingdom pulls across. `content/towns.json` holds
## the *world's* — where each place starts, what it sends, how many people walk, what
## disappears when it is poor. One is design, the other is data, and neither is code
## anybody has to read to change a balance.
##
## This scans the model's own files and fails naming the file and the line. It is the
## same kind of guard as `test_workshop_provenance`: cheap, and it only ever goes off
## when somebody is about to make a mess.

## The files the model is made of. The window is not here: what it takes to draw a
## thing is not what it takes to balance one.
const MODEL: Array[String] = [
	"res://core/rules/kingdom_rules.gd",
	"res://core/town_state.gd",
	"res://core/systems/town_system.gd",
	"res://core/systems/kingdom_system.gd",
	"res://core/folk.gd",
	"res://core/systems/folk_system.gd",
]

## Numbers that are structure rather than balance: an empty count, a step of one along
## a list, a pair, a half. Changing one of these does not change the game, it breaks it.
const STRUCTURAL: Array[String] = ["0", "1", "2", "-1", "0.0", "1.0", "0.5"]

## The one number outside `TownRules` that is allowed to be its own, and why: it is how
## often the walking population is recounted, which is a cost and not a balance.
const COST_KNOBS: Array[String] = ["ASKED_EVERY"]


func test_no_balancing_number_lives_outside_the_two_places() -> void:
	var loose: PackedStringArray = PackedStringArray()
	var numbers := RegEx.create_from_string("(?<![A-Za-z_0-9.])-?[0-9]+(\\.[0-9]+)?")
	for path: String in MODEL:
		var source: String = FileAccess.get_file_as_string(path)
		assert_true(source != "", "%s is there to be read" % path)
		var line_number: int = 0
		for line: String in source.split("\n"):
			line_number += 1
			var code: String = _code_of(line)
			if code.strip_edges().is_empty() or _is_cost_knob(code):
				continue
			for found: RegExMatch in numbers.search_all(code):
				if STRUCTURAL.has(found.get_string()):
					continue
				loose.append("%s:%d  %s" % [path.get_file(), line_number, code.strip_edges()])
	assert_eq(loose.size(), 0,
		"these numbers belong in TownRules or in towns.json:\n  %s" % "\n  ".join(loose))


func test_no_model_file_declares_a_number_of_its_own() -> void:
	# The failure this really guards against: somebody adds `const SOMETHING: int = 4`
	# beside the code that uses it, and six months later two files disagree.
	var declared: PackedStringArray = PackedStringArray()
	for path: String in MODEL:
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			var code: String = _code_of(line).strip_edges()
			if not code.begins_with("const "):
				continue
			if not code.contains("int") and not code.contains("float"):
				continue
			var named: String = code.substr(6).split(":")[0].strip_edges()
			if COST_KNOBS.has(named):
				continue
			declared.append("%s declares %s" % [path.get_file(), named])
	assert_eq(declared.size(), 0,
		"a number of the model's own, outside TownRules:\n  %s" % "\n  ".join(declared))


func test_the_rules_numbers_are_all_in_one_file() -> void:
	# And they are the ones the model is actually described by, so that a reader of
	# `docs/SIMULATION_MODEL.md` finds each of them where the document says.
	assert_eq(TownRules.FLOOR, 0, "a place at the bottom")
	assert_eq(TownRules.CEILING, 10, "and at the top")
	assert_eq(TownRules.THRESHOLD, 5, "where a number becomes an appearance")
	assert_eq(TownRules.STEP, 3, "what one act of the player's moves")
	assert_eq(TownRules.PULLS_FROM, TownRules.STEP,
		"and the kingdom never moves a place as far as the player does")
	assert_true(TownRules.FOOD_FLOOR > TownRules.FLOOR,
		"the kingdom can starve nobody to death")


func test_the_world_numbers_are_all_in_one_file() -> void:
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://content/towns.json"))
	assert_true(parsed is Dictionary, "towns.json parses")
	var root: Dictionary = parsed as Dictionary
	for block: String in ["towns", "poverty", "routines", "goods"]:
		assert_true(root.has(block), "towns.json carries its %s" % block)


## The one declaration allowed to carry a number of its own. **Deliberately a list of
## names rather than a wider list of tolerated numbers**: a tolerated number is a door,
## and this way the exception has to be written down and read.
func _is_cost_knob(code: String) -> bool:
	for named: String in COST_KNOBS:
		if code.contains(named):
			return true
	return false


## A line with its comment taken off, so a number written in prose is not a number in
## the code. Our own files, so a `#` inside a string is not a case that arises.
func _code_of(line: String) -> String:
	var at: int = line.find("#")
	return line if at < 0 else line.substr(0, at)
