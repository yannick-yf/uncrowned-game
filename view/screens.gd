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

## **Quick start, for testing** (Yannick, 2026-09-14). The title menu and the character
## creation are skipped: the game opens straight into a fresh run with every trait at
## the floor, as if Begin had been pressed with nothing chosen — and the fresh run is
## saved, as Begin saves it, so dying still puts you back at a fire. Both screens still
## exist, still route, and are still tested; set this to false to get them back. Not a
## debug tool in CLAUDE.md's sense: it is on in every build until Yannick says otherwise.
## The screenshot harness is unaffected — it names the screen it wants.
const QUICK_START: bool = true

var _current: Node = null
var _shot_frames: int = 0


func _ready() -> void:
	# Before the first screen, so the title has music the moment it appears. This node
	# is the one thing in the game that is never replaced, which is what makes it the
	# right place to hang something that must outlive every screen.
	Sound.install(self)
	var first: StringName = _first_screen()
	var carrying: Variant = null
	if first == &"play" and QUICK_START and OS.get_environment("UNCROWNED_SHOT").is_empty():
		var run: Sim = Game.begin_run(TraitRules.at_the_floor())
		SaveFile.write(run)
		carrying = run
	_go(first, carrying)


## Where the game opens. The title, unless a debug build is being driven by the
## screenshot harness — which wants a picture of a screen, not of a menu in front of
## one. `UNCROWNED_SCREEN` names the screen; with only `UNCROWNED_SHOT` set it means
## the world, which is what every existing invocation of the harness expects. And,
## while `QUICK_START` is on, the world straight away.
func _first_screen() -> StringName:
	if not OS.has_feature("debug"):
		return &"play" if QUICK_START else &"title"
	match OS.get_environment("UNCROWNED_SCREEN"):
		"title":
			return &"title"
		"creation":
			return &"creation"
		# "pause", "journal" and "map" are the world with one of its overlays already
		# open; the play screen reads the same variable and opens it. One knob naming
		# every screen, because a variable per overlay is one more thing to forget.
		"play", "pause", "journal", "map":
			return &"play"
	if not OS.get_environment("UNCROWNED_SHOT").is_empty():
		return &"play"
	if QUICK_START:
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
