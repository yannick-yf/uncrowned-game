class_name Text
extends RefCounted

## Everything the player reads, in the player's language.
##
## Lives in `view/` because choosing words is presentation. `core/` used to build
## English sentences — the journal did it, the region named its own places — which
## put phrasing inside the simulation and made the game untranslatable. Core now
## returns ids and numbers, and this turns them into a sentence (2026-09-12).
##
## Hand-rolled rather than Godot's CSV translations, for the same reason everything
## else here is: it loads like any other content file, it needs no import step, and
## a test can read it. Godot's system would still be the right answer if this ever
## needed plurals, genders and right-to-left.

const PATH: String = "res://content/text.%s.json"
const FALLBACK: String = "en"
## What a player gets before they have chosen anything. French, because the game is
## written and played in French first — the machine's language is not consulted, on
## purpose: this one is authored in French and translated into English, not the
## other way round. One line to change the day that stops being true.
const DEFAULT: String = "fr"
## Every language the game ships in, in the order the switch walks them.
const SHIPPED: Array[String] = ["en", "fr"]
## Where the player's choice is kept. Not a debug tool — §16 will grow an options
## screen and this becomes a row in it — but a key and a file is the honest v1.
const SETTINGS: String = "user://settings.cfg"

static var _table: Dictionary = {}
static var _locale: String = ""


## The language the player reads: their choice if they have made one, otherwise the
## machine's, otherwise English.
static func locale() -> String:
	if _locale == "":
		set_locale(_remembered())
	return _locale


static func _remembered() -> String:
	var file := ConfigFile.new()
	if file.load(SETTINGS) == OK:
		return String(file.get_value("player", "language", DEFAULT))
	return DEFAULT


## The next language along, remembered for next time.
static func cycle() -> String:
	var at: int = SHIPPED.find(locale())
	set_locale(SHIPPED[(at + 1) % SHIPPED.size()])
	var file := ConfigFile.new()
	file.load(SETTINGS)
	file.set_value("player", "language", _locale)
	file.save(SETTINGS)
	return _locale


static func set_locale(want: String) -> void:
	var table: Dictionary = _load(want)
	if table.is_empty():
		want = FALLBACK
		table = _load(want)
	var changed: bool = _locale != want
	_locale = want
	_table = table
	# The cast is written in a language too. Dropping it means the next reader loads
	# the sheets that match the words on the HUD.
	if changed:
		Cast.forget()


static func _load(want: String) -> Dictionary:
	var path: String = PATH % want
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


## The line for this key, with {0}, {1}… filled in.
##
## A missing key returns the key itself rather than an empty string: a screen that
## reads `journal.holds` is a bug you fix in a minute, and a screen that has quietly
## gone blank is one you ship.
static func of(key: StringName, args: Array = []) -> String:
	if _table.is_empty():
		set_locale(_remembered())
	var line: String = String(_table.get(String(key), String(key)))
	for i: int in args.size():
		line = line.replace("{%d}" % i, str(args[i]))
	return line


static func has(key: StringName) -> bool:
	if _table.is_empty():
		set_locale(_remembered())
	return _table.has(String(key))


## Every key the game ships, in every language it ships. Used by the test that
## refuses to let a language fall behind.
static func keys_for(want: String) -> Array[String]:
	var out: Array[String] = []
	for key: String in _load(want).keys():
		out.append(key)
	out.sort()
	return out
