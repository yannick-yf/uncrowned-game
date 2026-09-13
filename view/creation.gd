extends Node2D

## Who you are, before you wake up in the clearing.
##
## §11's pool, on screen: six traits at the floor, ten points to place, nothing above
## five. The screen only ever moves numbers about — the decision is one
## `create_character` event submitted to a fresh run, and `CreationSystem` refuses it
## if the numbers do not add up. That refusal is not defensive clutter: it is what
## makes the save honest, because a run is its event log and this is the first row.
##
## Begin is closed until the last point is spent. Nothing here forbids underspending —
## `TraitRules` allows it, and a replayed save from a version that did would still
## load — but a player who leaves points on the table has almost always misread the
## screen rather than decided something.

signal chose(what: StringName, carrying: Variant)

## One framed block holding the six traits, the seventh row that starts the game, and
## what the trait under the cursor means. Framed because the alternative — six rows
## floating on a dark field — left a third of the screen empty and read as unfinished.
const FRAME: Rect2 = Rect2(96.0, 86.0, 448.0, 212.0)
const ROWS_TOP: float = 112.0
const ROW_STEP: float = 21.0
const LABEL_X: float = 150.0
const PIPS_X: float = 320.0
const PIP_STEP: float = 13.0
const PIP: float = 8.0
const NOTE_LEFT: float = 112.0
const NOTE_WIDTH: float = 416.0

var _menu: Menu = Menu.new()
var _levels: Dictionary = TraitRules.at_the_floor()


func _ready() -> void:
	_build()
	Sound.play_music_now(Sound.MUSIC_CREATION)
	set_process(true)


func _build() -> void:
	var was: StringName = _menu.chosen()
	var rows: Array[Dictionary] = []
	for what: StringName in TraitRules.ALL:
		rows.append({"id": what, "key": TraitRules.name_key(what)})
	rows.append({"id": &"begin", "key": &"creation.begin", "enabled": _left() == 0})
	_menu.set_rows(rows)
	_menu.point_at(was)


func _left() -> int:
	return TraitRules.POOL - TraitRules.spent(_levels)


func _process(_delta: float) -> void:
	_read_input()
	queue_redraw()


func _read_input() -> void:
	if Input.is_action_just_pressed(&"move_down") and _menu.move(1):
		Sound.cue(&"move")
	if Input.is_action_just_pressed(&"move_up") and _menu.move(-1):
		Sound.cue(&"move")
	if Input.is_action_just_pressed(&"move_right"):
		_spend(1)
	if Input.is_action_just_pressed(&"move_left"):
		_spend(-1)
	if Input.is_action_just_pressed(&"back"):
		Sound.cue(&"cancel")
		chose.emit(&"title", null)
		return
	if Input.is_action_just_pressed(&"interact") and _menu.chosen() == &"begin":
		Sound.cue(&"accept")
		_begin()


## Move one point into or out of the trait under the cursor. Refused rather than
## clamped when there is nothing left to spend, so the pool is visibly the thing
## stopping you.
func _spend(by: int) -> void:
	var what: StringName = _menu.chosen()
	if not TraitRules.ALL.has(what):
		return
	var wanted: int = int(_levels[what]) + by
	if wanted < TraitRules.FLOOR or wanted > TraitRules.CAP:
		Sound.cue(&"refused")
		return
	if by > 0 and _left() <= 0:
		Sound.cue(&"refused")
		return
	_levels[what] = wanted
	Sound.cue(&"move")
	_build()


## The only thing this screen decides, and it decides it by submitting an event.
##
## The run is written to disk here rather than at the first campfire. One save slot
## means the file still holds the *previous* run until something replaces it, and
## dying before the first rest would reload that one — a player would start a new
## game, walk into the wood, die, and find themselves in somebody else's afternoon.
func _begin() -> void:
	var sim: Sim = Game.build()
	var data: Dictionary = {}
	for what: StringName in TraitRules.ALL:
		data[String(what)] = int(_levels[what])
	sim.submit(&"create_character", data)
	sim.advance(1)
	SaveFile.write(sim)
	chose.emit(&"play", sim)


# ----------------------------------------------------------------- drawing ---

func _draw() -> void:
	var screen: Vector2 = get_viewport_rect().size
	Ui.sky(self, Rect2(Vector2.ZERO, screen), Color(0.055, 0.060, 0.085),
		Color(0.025, 0.028, 0.038))
	Ui.write_over(self, Vector2(0.0, 46.0), Text.of(&"creation.title"), Ui.LARGE,
		Ui.INK, HORIZONTAL_ALIGNMENT_CENTER, screen.x)
	Ui.write_over(self, Vector2(0.0, 68.0), Text.of(&"creation.pool", [_left()]),
		Ui.BODY, Ui.GOLD if _left() > 0 else Ui.SAGE, HORIZONTAL_ALIGNMENT_CENTER,
		screen.x)

	Ui.panel(self, FRAME)
	_menu.draw_on(self, LABEL_X, ROWS_TOP, Ui.ROW, ROW_STEP)
	for index: int in TraitRules.ALL.size():
		_draw_pips(TraitRules.ALL[index], _menu.y_of(index, ROWS_TOP, ROW_STEP),
			index == _menu.at)

	var rule: float = _menu.y_of(TraitRules.ALL.size(), ROWS_TOP, ROW_STEP) + 12.0
	draw_line(Vector2(NOTE_LEFT, rule), Vector2(NOTE_LEFT + NOTE_WIDTH, rule),
		Color(0.75, 0.70, 0.55, 0.28), 1.0)
	_draw_note(rule + 18.0)

	Ui.write_over(self, Vector2(0.0, 330.0), Text.of(&"creation.help"),
		Ui.NOTE, Ui.FAINT, HORIZONTAL_ALIGNMENT_CENTER, screen.x)


## Five boxes, filled to the level. A bar would read as progress towards something;
## these are five places a point can be, which is what they are.
func _draw_pips(what: StringName, y: float, lit: bool) -> void:
	var level: int = int(_levels[what])
	for pip: int in TraitRules.CAP:
		var box := Rect2(Vector2(PIPS_X + float(pip) * PIP_STEP, y - PIP), Vector2(PIP, PIP))
		if pip < level:
			draw_rect(box, Ui.GOLD if lit else Ui.INK, true)
		else:
			draw_rect(box, Ui.FAINT, false, 1.0)
	Ui.write_over(self, Vector2(PIPS_X + float(TraitRules.CAP) * PIP_STEP + 8.0, y),
		str(level), Ui.ROW, Ui.GOLD if lit else Ui.DIM)


## What the trait under the cursor means, in the words the game uses everywhere else.
## On Begin there is no trait, so it says what the six of them add up to instead.
func _draw_note(top: float) -> void:
	var what: StringName = _menu.chosen()
	var line: String = Text.of(&"creation.ready") if what == &"begin" \
		else Text.of(TraitRules.note_key(what))
	draw_multiline_string(Ui.font(), Vector2(NOTE_LEFT, top), line,
		HORIZONTAL_ALIGNMENT_CENTER, NOTE_WIDTH, Ui.NOTE, 3, Ui.DIM)
