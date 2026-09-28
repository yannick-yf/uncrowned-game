extends Node

## The front of the game: which screen is up, and nothing else.
##
## Before this, `main.tscn` was the whole program. It booted straight into the world
## and silently loaded whatever save was on disk, so a player had no way to say *new*
## and no way to say *continue* — the save system existed and was unreachable.
##
## Screens do not know about each other. Each one emits `chose(what, carrying)` and
## this routes it, which is what keeps the flow readable in one place and lets any of
## them be opened on its own: `main.tscn` still runs by itself, because it falls back
## to reading the save when nobody hands it a run.
##
## Only `&"play"` carries anything, and what it carries is a `Sim`.

const TITLE: PackedScene = preload("res://view/title.tscn")
const CREATION: PackedScene = preload("res://view/creation.tscn")
const PLAY: PackedScene = preload("res://view/main.tscn")

## **The public build opens on the title** (S2, 2026-09-28). The quick start of
## 2026-09-14 skipped the title and the creation for testing, and Yannick ruled on
## 2026-09-18 that the switch goes and the screens stay: the demo opens on creation.
## The quick launch survives as a development path only — `UNCROWNED_QUICK=1` in a
## debug build, listed in CLAUDE.md with the other tools that must never ship.

var _current: Node = null
var _shot_frames: int = 0


func _ready() -> void:
	# Before the first screen, so the title has music the moment it appears. This node
	# is the one thing in the game that is never replaced, which is what makes it the
	# right place to hang something that must outlive every screen.
	Sound.install(self)
	var shot: String = OS.get_environment("UNCROWNED_SHOT")
	var quick: String = OS.get_environment("UNCROWNED_QUICK")
	var first: StringName = first_screen(OS.has_feature("debug"),
		OS.get_environment("UNCROWNED_SCREEN"), shot, quick)
	var carrying: Variant = null
	# The quick launch is a fresh run at the floor, saved as Begin saves it, so dying
	# still puts you back at a fire.
	if first == &"play" and quick == "1" and shot.is_empty():
		var run: Sim = Game.begin_run(TraitRules.at_the_floor())
		SaveFile.write(run)
		carrying = run
	_go(first, carrying)


## Where the game opens, as a pure function of the four things that decide it, so it
## can be tested without a window. **A release build always opens on the title**:
## nothing a player can put in their environment changes it. A debug build opens on
## the title too, unless the screenshot harness names a screen (`UNCROWNED_SCREEN`,
## or `UNCROWNED_SHOT` alone, which means the world) or `UNCROWNED_QUICK=1` asks to
## skip straight to it.
static func first_screen(debug: bool, screen: String, shot: String, quick: String) -> StringName:
	if not debug:
		return &"title"
	# Split, because `journal:standing` names a screen and a page of it.
	match screen.split(":")[0]:
		"title":
			return &"title"
		"creation":
			return &"creation"
		# "pause", "journal" and "map" are the world with one of its overlays already
		# open; the play screen reads the same variable and opens it. One knob naming
		# every screen, because a variable per overlay is one more thing to forget.
		"play", "pause", "journal", "map":
			return &"play"
	if not shot.is_empty():
		return &"play"
	if quick == "1":
		return &"play"
	return &"title"


func _go(what: StringName, carrying: Variant) -> void:
	match what:
		&"title":
			_show(TITLE, null)
		&"creation":
			_show(CREATION, null)
		&"play":
			_show(PLAY, carrying)
		&"quit":
			get_tree().quit()
		_:
			push_error("no screen called '%s'" % what)


func _show(scene: PackedScene, carrying: Variant) -> void:
	if _current != null:
		# Removed before it is freed, so the outgoing screen cannot read input or
		# draw a frame alongside the incoming one.
		remove_child(_current)
		_current.queue_free()
		_current = null
	var screen: Node = scene.instantiate()
	# Before `add_child`, so the screen has what it needs by the time `_ready` runs.
	# Which means `begin` may only touch plain members — never an `@onready` one.
	if screen.has_method(&"begin"):
		screen.call(&"begin", carrying)
	screen.connect(&"chose", _go)
	add_child(screen)
	_current = screen


func _process(_delta: float) -> void:
	_screenshot_if_asked()


## Render a frame to a file and quit, for looking at the game without playing it.
##
## **The tool the first night needed and did not have.** "Zero script errors over 300
## frames" says nothing about whether the sea is the right colour, and the ocean
## shipped covered in shoreline tiles because nobody looked. This makes looking cheap:
##
##   UNCROWNED_SHOT=/tmp/a.png UNCROWNED_AT=241,150 godot --path . --quit-after 40
##   UNCROWNED_SHOT=/tmp/t.png UNCROWNED_SCREEN=title godot --path . --quit-after 40
##
## It lives here rather than in the world screen so it can photograph any of them.
## Debug builds only, like the day-skip, and listed in CLAUDE.md for the same reason.
func _screenshot_if_asked() -> void:
	if not OS.has_feature("debug"):
		return
	var path: String = OS.get_environment("UNCROWNED_SHOT")
	if path.is_empty():
		return
	_shot_frames += 1
	# A few frames in, so the camera has settled and the first draw is behind us.
	if _shot_frames != 12:
		return
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(path)
	print("wrote %s" % path)
	get_tree().quit()
