extends Node2D

## The first screen: a night, a treeline, and four things you can do.
##
## It is drawn rather than laid out, for the same reason the world is — one `_draw`
## with the numbers visible beats a scene tree of anchored `Control`s whose positions
## live in a file nobody reads. Everything on it comes out of the approved pack: the
## trees are the Thornwood's own sprite in silhouette, and the lights above them are
## the fairies, drawn exactly as the opening draws them.
##
## The picture is the game's argument in one frame: the wood, at night, still there.

signal chose(what: StringName, carrying: Variant)

## Sky, top to bottom. Night rather than black: a black screen with words on it is a
## crash report.
const SKY_TOP: Color = Color(0.055, 0.075, 0.125)
const SKY_LOW: Color = Color(0.025, 0.045, 0.050)

const TREE: Rect2i = Rect2i(32, 0, 32, 32)
const SCRUB: Rect2i = Rect2i(0, 0, 32, 32)
## Two ranks of trees. The far one is smaller, higher and lighter; the near one runs
## off the bottom of the screen. Two is enough for depth and cheap enough to redraw
## every frame.
const FAR: Color = Color(0.062, 0.086, 0.076)
const NEAR: Color = Color(0.016, 0.032, 0.026)

const MENU_LEFT: float = 262.0
const MENU_TOP: float = 214.0

var _art: Art = null
var _menu: Menu = Menu.new()
## The menu asking whether a run in progress may be thrown away, or null when it is
## not being asked. A second menu rather than a mode flag on the first: the question
## has its own rows and its own cursor, and conflating them is how a screen ends up
## quitting the game because the cursor was on row 4 of the wrong list.
var _asking: Menu = null
var _elapsed: float = 0.0


func _ready() -> void:
	_art = Art.new()
	_build()
	set_process(true)


## The rows, rebuilt whenever what they say changes — which is when the language
## changes, and when a save appears or stops being readable.
func _build() -> void:
	var was: StringName = _menu.chosen()
	var has_save: bool = SaveFile.exists()
	_menu.set_rows([
		{"id": &"continue", "key": &"title.continue", "enabled": has_save},
		{"id": &"new", "key": &"title.new"},
		{"id": &"language", "key": &"title.language", "args": [Text.locale().to_upper()]},
		{"id": &"quit", "key": &"title.quit"},
	])
	if not _menu.point_at(was) and has_save:
		_menu.point_at(&"continue")


func _process(delta: float) -> void:
	_elapsed += delta
	_read_input()
	queue_redraw()


func _read_input() -> void:
	var menu: Menu = _asking if _asking != null else _menu
	if Input.is_action_just_pressed(&"move_down"):
		menu.move(1)
	if Input.is_action_just_pressed(&"move_up"):
		menu.move(-1)
	if Input.is_action_just_pressed(&"back") and _asking != null:
		_asking = null
		return
	if Input.is_action_just_pressed(&"interact"):
		_take(menu.chosen())


func _take(id: StringName) -> void:
	match id:
		&"continue":
			var loaded: Sim = SaveFile.read()
			# A file that will not parse is not a run. Say so by taking the row away
			# rather than by dropping the player into a world built from nothing.
			if loaded == null:
				_build()
				return
			chose.emit(&"play", loaded)
		&"new":
			# One save slot, so a new run overwrites the old one. That is a thing to
			# be asked about, not a thing to discover afterwards.
			if SaveFile.exists():
				_ask()
			else:
				chose.emit(&"creation", null)
		&"language":
			Text.cycle()
			_build()
		&"quit":
			chose.emit(&"quit", null)
		&"replace":
			chose.emit(&"creation", null)
		&"keep":
			_asking = null


func _ask() -> void:
	_asking = Menu.new([
		{"id": &"keep", "key": &"title.keep"},
		{"id": &"replace", "key": &"title.replace"},
	])


# ----------------------------------------------------------------- drawing ---

func _draw() -> void:
	var screen: Vector2 = get_viewport_rect().size
	Ui.sky(self, Rect2(Vector2.ZERO, screen), SKY_TOP, SKY_LOW)
	_draw_stars(screen)
	_draw_treeline(screen)
	_draw_fairies(screen)
	_draw_name(screen)

	_menu.draw_on(self, MENU_LEFT, MENU_TOP)
	Ui.write_over(self, Vector2(0.0, screen.y - 12.0), Text.of(&"title.hint"), Ui.NOTE,
		Ui.FAINT, HORIZONTAL_ALIGNMENT_CENTER, screen.x)

	if _asking != null:
		_draw_question(screen)


## A handful of stars, placed by the same hash the world scatters trees with, so they
## are in the same place every time the game opens and nobody has to store them.
func _draw_stars(screen: Vector2) -> void:
	for i: int in 70:
		var roll: int = Art.scatter_hash(i * 7, i * 13)
		var at := Vector2(
			float(Art.scatter_hash(i, i * 3)) / 999.0 * screen.x,
			float(roll) / 999.0 * (screen.y * 0.55))
		var twinkle: float = 0.25 + 0.20 * sin(_elapsed * 0.7 + float(i))
		draw_circle(at.round(), 1.0, Color(0.86, 0.92, 1.0, twinkle))


func _draw_treeline(screen: Vector2) -> void:
	var nature: Texture2D = _art.atlas(&"nature")
	if nature == null:
		return
	# Far rank, then near, so the near one overlaps.
	for rank: int in 2:
		var far: bool = rank == 0
		var step: float = 17.0 if far else 24.0
		# The near rank runs off the bottom of the screen rather than standing on it,
		# and its tops reach above the far rank's feet. The first version left a strip
		# of sky between the two, which read as a stripe rather than as distance.
		var base: float = screen.y - (32.0 if far else -10.0)
		var tint: Color = FAR if far else NEAR
		var column: int = 0
		var x: float = -step
		while x < screen.x + step:
			var roll: int = Art.scatter_hash(column * 5 + rank * 97, rank * 31)
			# Height varies more than position does. Trees at one height read as a
			# hedge; trees at one x-spacing do not read as anything at all.
			var size: float = (22.0 if far else 40.0) + float(roll % 7) * (2.0 if far else 3.0)
			var lift: float = float(roll % 13) - 6.0 if far else float(roll % 9) - 4.0
			var source: Rect2i = SCRUB if roll % 11 == 0 else TREE
			draw_texture_rect_region(nature,
				Rect2(Vector2(x, base - size + lift).round(), Vector2(size, size)),
				Rect2(source), tint)
			x += step
			column += 1


## Three of them, over the wood, on their own clocks — the same light the opening
## puts in the clearing. They are the only thing on the screen that moves.
func _draw_fairies(screen: Vector2) -> void:
	var homes: Array[Vector2] = [
		Vector2(screen.x * 0.16, screen.y - 96.0),
		Vector2(screen.x * 0.78, screen.y - 118.0),
		Vector2(screen.x * 0.53, screen.y - 78.0),
	]
	for index: int in homes.size():
		var phase: float = _elapsed * (0.21 + float(index) * 0.05) + float(index) * 2.3
		var centre: Vector2 = homes[index] + Vector2(
			cos(phase) * 26.0, sin(phase * 0.8) * 11.0)
		var breath: float = 0.82 + 0.18 * sin(_elapsed * 1.1 + float(index))
		for ring: int in 3:
			draw_circle(centre, (11.0 - float(ring) * 3.2) * breath,
				Color(0.78, 0.94, 0.80, 0.05 + float(ring) * 0.06))
		draw_circle(centre, 1.4, Color(0.90, 1.0, 0.88, 0.55))


func _draw_name(screen: Vector2) -> void:
	var middle: float = screen.x * 0.5
	Ui.write_over(self, Vector2(0.0, 118.0), Text.of(&"title.name"), Ui.HUGE, Ui.INK,
		HORIZONTAL_ALIGNMENT_CENTER, screen.x)
	var rule: float = Ui.width_of(Text.of(&"title.name"), Ui.HUGE) * 0.5 + 10.0
	draw_line(Vector2(middle - rule, 128.0), Vector2(middle + rule, 128.0),
		Color(0.75, 0.70, 0.55, 0.35), 1.0)
	Ui.write_over(self, Vector2(0.0, 150.0), Text.of(&"title.subtitle"), Ui.NOTE,
		Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, screen.x)


func _draw_question(screen: Vector2) -> void:
	var box := Rect2(screen.x * 0.5 - 170.0, 128.0, 340.0, 96.0)
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0.0, 0.0, 0.0, 0.55), true)
	Ui.panel(self, box)
	Ui.write(self, box.position + Vector2(0.0, 26.0), Text.of(&"title.replace.ask"),
		Ui.BODY, Ui.INK, HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	Ui.write(self, box.position + Vector2(0.0, 42.0), Text.of(&"title.replace.note"),
		Ui.NOTE, Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	_asking.draw_on(self, box.position.x + 40.0, box.position.y + 64.0)
