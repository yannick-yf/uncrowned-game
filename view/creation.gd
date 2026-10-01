extends Node2D

## Who you are, before you wake up among the graves.
##
## **Two pages since group A (2026-10-01).** First what you look like — the five choices of
## `docs/CREATION_AND_GEAR.md`, with you on the left, turning and walking, drawn by the
## game's own layers (`PaperDoll`, the canvas shader) so what you see here is what walks in
## the world. Then §11's pool, as before: four traits at the floor, eight points to place,
## nothing above five (S1). The same figure stays on the left while you place them.
##
## The screen only ever moves choices about — the decision is one `create_character` event
## submitted to a fresh run, carrying the look beside the traits, and `CreationSystem`
## refuses it if either does not hold. That refusal is what makes the save honest, because
## a run is its event log and this is the first row. **What you look like is chosen once
## and never changed after** (Yannick, 2026-10-01).
##
## Begin is closed until the last point is spent: a player who leaves points on the table
## has almost always misread the screen rather than decided something.

signal chose(what: StringName, carrying: Variant)

const LOOK: StringName = &"look"
const TALENTS: StringName = &"talents"

## The figure on the left, and the choices or the traits on the right.
const PREVIEW: Rect2 = Rect2(36.0, 86.0, 220.0, 214.0)
const SIDE: Rect2 = Rect2(268.0, 86.0, 336.0, 214.0)
const ROWS_TOP: float = 114.0
const ROW_STEP: float = 21.0
const LABEL_X: float = 300.0
const VALUE_X: float = 452.0
const PIPS_X: float = 452.0
const PIP_STEP: float = 13.0
const PIP: float = 8.0
const NOTE_LEFT: float = 284.0
const NOTE_WIDTH: float = 304.0
## His figure at two screen pixels to one of his: the largest that fits the panel, and an
## exact multiple, so his pixels stay square.
const FIGURE_SCALE: float = 1.0
## And as the game shows him — about seventy pixels tall on the window.
const GAME_SCALE: float = 70.0 / 197.0 / 2.0
## How long he faces each way before turning.
const TURN_SECONDS: float = 1.6
const WAYS: Array[StringName] = [&"down", &"left", &"up", &"right"]

var _page: StringName = LOOK
var _look_menu: Menu = Menu.new()
var _talent_menu: Menu = Menu.new()
var _levels: Dictionary = TraitRules.at_the_floor()
var _looks: Dictionary = AppearanceRules.default_appearance()
var _doll: AnimatedSprite2D = null
var _small: AnimatedSprite2D = null
var _turned: float = 0.0
var _way: int = 0


func _ready() -> void:
	_looks = AppearanceRules.completed(look_asked())
	_build()
	_build_doll()
	Sound.play_music_now(Sound.MUSIC_CREATION)
	# A debug photograph may ask for the second page (`UNCROWNED_SCREEN=creation:talents`).
	if OS.has_feature("debug") and OS.get_environment("UNCROWNED_SCREEN") == "creation:talents":
		_page = TALENTS
	set_process(true)


func _build() -> void:
	var was: StringName = _look_menu.chosen()
	var rows: Array[Dictionary] = []
	for choice: StringName in AppearanceRules.ALL:
		rows.append({"id": choice, "key": StringName("look.%s" % choice)})
	rows.append({"id": &"random", "key": &"creation.random"})
	rows.append({"id": &"next", "key": &"creation.next"})
	_look_menu.set_rows(rows)
	_look_menu.point_at(was)
	var at: StringName = _talent_menu.chosen()
	var talents: Array[Dictionary] = []
	for what: StringName in TraitRules.ALL:
		talents.append({"id": what, "key": TraitRules.name_key(what)})
	talents.append({"id": &"begin", "key": &"creation.begin", "enabled": _left() == 0})
	_talent_menu.set_rows(talents)
	_talent_menu.point_at(at)


## **`UNCROWNED_LOOK`** (debug builds only, like every `UNCROWNED_` variable): a look for
## the photograph — `hair_style=long,hair_colour=blond` — on this screen, and on the run
## `UNCROWNED_QUICK=1` opens. Not a save-able state of its own: it is only what the
## creation event would have carried.
static func look_asked() -> Dictionary:
	var out: Dictionary = {}
	if not OS.has_feature("debug"):
		return out
	for pair: String in OS.get_environment("UNCROWNED_LOOK").split(",", false):
		var kv: PackedStringArray = pair.split("=")
		if kv.size() == 2:
			out[StringName(kv[0].strip_edges())] = StringName(kv[1].strip_edges())
	return out if AppearanceRules.is_legal(out) else {}


func _left() -> int:
	return TraitRules.POOL - TraitRules.spent(_levels)


# ------------------------------------------------------------------- the figure ---

## **You, drawn as the game draws you.** His frames re-pointed at the layers, and the canvas
## version of the shader that draws the player in the world. Without the layers (a clone
## that has not baked them) the left panel says nothing rather than something false.
func _build_doll() -> void:
	if not PaperDoll.ready() or not ResourceLoader.exists(World3d.HIS_FRAMES):
		return
	var his: SpriteFrames = load(World3d.HIS_FRAMES) as SpriteFrames
	if his == null:
		return
	var frames: SpriteFrames = CastLooks.frames_for(his, PaperDoll.sheet(&"body"))
	_doll = _sprite(frames, FIGURE_SCALE)
	_doll.position = Vector2(PREVIEW.get_center().x, PREVIEW.end.y - 10.0)
	_small = _sprite(frames, GAME_SCALE)
	_small.position = Vector2(PREVIEW.end.x - 26.0, PREVIEW.end.y - 16.0)
	_dress()
	_face(0)


func _sprite(frames: SpriteFrames, scale_by: float) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.centered = true
	sprite.offset = Vector2(0.0, -float(frames.get_frame_texture(&"idle_down", 0).get_height()) * 0.5)
	sprite.scale = Vector2(scale_by, scale_by)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if scale_by >= 1.0 else CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.material = PaperDoll.material(PaperDoll.CANVAS_SHADER, PaperDoll.slots_for(_looks, PaperDoll.start_kit_worn()))
	add_child(sprite)
	return sprite


## What the figure wears, from the choices as they stand — on the frame they change.
func _dress() -> void:
	for sprite: AnimatedSprite2D in [_doll, _small]:
		if sprite != null:
			PaperDoll.apply(sprite.material as ShaderMaterial, PaperDoll.slots_for(_looks, PaperDoll.start_kit_worn()))


func _face(way: int) -> void:
	_way = way
	for sprite: AnimatedSprite2D in [_doll, _small]:
		if sprite != null:
			sprite.play(StringName("walk_" + String(WAYS[way])))


# ------------------------------------------------------------------- input ---

func _process(delta: float) -> void:
	_turned += delta
	if _turned >= TURN_SECONDS and _doll != null:
		_turned = 0.0
		_face((_way + 1) % WAYS.size())
	_read_input()
	queue_redraw()


func _read_input() -> void:
	var menu: Menu = _menu()
	if Input.is_action_just_pressed(&"move_down") and menu.move(1):
		Sound.cue(&"move")
	if Input.is_action_just_pressed(&"move_up") and menu.move(-1):
		Sound.cue(&"move")
	if Input.is_action_just_pressed(&"move_right"):
		_change(1)
	if Input.is_action_just_pressed(&"move_left"):
		_change(-1)
	if Input.is_action_just_pressed(&"back"):
		Sound.cue(&"cancel")
		if _page == TALENTS:
			_page = LOOK
		else:
			chose.emit(&"title", null)
		return
	if Input.is_action_just_pressed(&"interact"):
		_confirm(menu.chosen())


func _menu() -> Menu:
	return _look_menu if _page == LOOK else _talent_menu


func _change(by: int) -> void:
	if _page == TALENTS:
		_spend(by)
		return
	var choice: StringName = _look_menu.chosen()
	if not AppearanceRules.ALL.has(choice):
		return
	var options: Array[StringName] = AppearanceRules.options(choice)
	var at: int = options.find(_looks[choice] as StringName)
	_looks[choice] = options[posmod(at + by, options.size())]
	Sound.cue(&"move")
	_dress()


func _confirm(row: StringName) -> void:
	match row:
		&"random":
			Sound.cue(&"accept")
			_at_random()
		&"next":
			Sound.cue(&"accept")
			_page = TALENTS
		&"begin":
			Sound.cue(&"accept")
			_begin()
		_:
			if _page == LOOK and AppearanceRules.ALL.has(row):
				# Enter on a choice moves on to the next one, so a player can walk down the
				# list with one key.
				_look_menu.move(1)
				Sound.cue(&"move")


## **Somebody else, at random** — a look to start from. Seeded from the clock, which is the
## window's to read: what reaches the simulation is the look chosen, not the dice.
func _at_random() -> void:
	var dice := RandomNumberGenerator.new()
	dice.seed = Time.get_ticks_usec()
	for choice: StringName in AppearanceRules.ALL:
		var options: Array[StringName] = AppearanceRules.options(choice)
		_looks[choice] = options[dice.randi_range(0, options.size() - 1)]
	_dress()


## Move one point into or out of the trait under the cursor. Refused rather than
## clamped when there is nothing left to spend, so the pool is visibly the thing
## stopping you.
func _spend(by: int) -> void:
	var what: StringName = _talent_menu.chosen()
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
	var sim: Sim = Game.begin_run(_levels, Sim.DEFAULT_SEED, _looks)
	SaveFile.write(sim)
	chose.emit(&"play", sim)


## The choices as they stand, for the suite.
func looks() -> Dictionary:
	return _looks.duplicate()


# ----------------------------------------------------------------- drawing ---

func _draw() -> void:
	var screen: Vector2 = get_viewport_rect().size
	Ui.sky(self, Rect2(Vector2.ZERO, screen), Color(0.055, 0.060, 0.085),
		Color(0.025, 0.028, 0.038))
	Ui.write_over(self, Vector2(0.0, 40.0), Text.of(&"creation.title"), Ui.LARGE,
		Ui.INK, HORIZONTAL_ALIGNMENT_CENTER, screen.x)
	var page_key: StringName = &"creation.page_look" if _page == LOOK else &"creation.page_talents"
	Ui.write_over(self, Vector2(0.0, 62.0), Text.of(page_key), Ui.BODY, Ui.SAGE,
		HORIZONTAL_ALIGNMENT_CENTER, screen.x)
	_draw_preview()
	Ui.panel(self, SIDE)
	if _page == LOOK:
		_draw_looks()
	else:
		_draw_talents()
	var help: StringName = &"creation.help_look" if _page == LOOK else &"creation.help_talents"
	Ui.write_over(self, Vector2(0.0, SIDE.end.y + 30.0), Text.of(help),
		Ui.NOTE, Ui.FAINT, HORIZONTAL_ALIGNMENT_CENTER, screen.x)


## The panel he stands in: a dusk behind him, a patch of ground under his feet, and the
## same figure small in the corner at the size the game will show him.
func _draw_preview() -> void:
	Ui.panel(self, PREVIEW, Color(0.10, 0.10, 0.11, 0.92))
	var ground := Rect2(PREVIEW.position + Vector2(1.0, PREVIEW.size.y * 0.62),
		Vector2(PREVIEW.size.x - 2.0, PREVIEW.size.y * 0.38 - 1.0))
	draw_rect(ground, Color(0.23, 0.21, 0.16, 0.55), true)
	var feet: Vector2 = Vector2(PREVIEW.get_center().x, PREVIEW.end.y - 10.0)
	_draw_shadow(feet, 34.0)
	var corner := Rect2(PREVIEW.end - Vector2(56.0, 48.0), Vector2(52.0, 44.0))
	draw_rect(corner, Color(0.0, 0.0, 0.0, 0.35), true)
	draw_rect(corner, Ui.EDGE, false, 1.0)
	_draw_shadow(Vector2(PREVIEW.end.x - 26.0, PREVIEW.end.y - 16.0), 8.0)
	Ui.write_over(self, Vector2(corner.position.x, corner.position.y - 4.0), Text.of(&"creation.in_game"),
		Ui.NOTE, Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, corner.size.x)


func _draw_shadow(at: Vector2, width: float) -> void:
	var points := PackedVector2Array()
	for i: int in 24:
		var a: float = TAU * float(i) / 24.0
		points.append(at + Vector2(cos(a) * width, sin(a) * width * 0.28))
	draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.35))


func _draw_looks() -> void:
	_look_menu.draw_on(self, LABEL_X, ROWS_TOP, Ui.ROW, ROW_STEP)
	for index: int in AppearanceRules.ALL.size():
		var choice: StringName = AppearanceRules.ALL[index]
		var y: float = _look_menu.y_of(index, ROWS_TOP, ROW_STEP)
		var lit: bool = index == _look_menu.at
		var option: StringName = _looks[choice] as StringName
		var colour: Color = Ui.GOLD if lit else Ui.INK
		_arrow(Vector2(VALUE_X - 10.0, y - 4.0), -1.0, lit)
		Ui.write_over(self, Vector2(VALUE_X, y), Text.of(StringName("look.%s.%s" % [choice, option])), Ui.ROW, colour)
		var swatch: Color = PaperDoll.swatch(choice, option)
		var right: float = VALUE_X + 104.0
		_arrow(Vector2(right, y - 4.0), 1.0, lit)
		if swatch.a > 0.0:
			var box := Rect2(Vector2(right + 12.0, y - 9.0), Vector2(10.0, 10.0))
			draw_rect(box, swatch, true)
			draw_rect(box, Ui.EDGE, false, 1.0)
	var rule: float = _look_menu.y_of(_look_menu.rows.size(), ROWS_TOP, ROW_STEP) + 2.0
	draw_line(Vector2(NOTE_LEFT, rule), Vector2(NOTE_LEFT + NOTE_WIDTH, rule),
		Color(0.75, 0.70, 0.55, 0.28), 1.0)
	draw_multiline_string(Ui.font(), Vector2(NOTE_LEFT, rule + 16.0), Text.of(&"creation.look_note"),
		HORIZONTAL_ALIGNMENT_CENTER, NOTE_WIDTH, Ui.NOTE, 2, Ui.DIM)


## A small triangle either side of a value: left and right change it.
func _arrow(at: Vector2, pointing: float, lit: bool) -> void:
	var colour: Color = Ui.GOLD if lit else Ui.FAINT
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-2.5 * pointing, -3.5),
		at + Vector2(2.5 * pointing, 0.0),
		at + Vector2(-2.5 * pointing, 3.5),
	]), colour)


func _draw_talents() -> void:
	Ui.write_over(self, Vector2(SIDE.position.x, SIDE.position.y + 16.0), Text.of(&"creation.pool", [_left()]),
		Ui.BODY, Ui.GOLD if _left() > 0 else Ui.SAGE, HORIZONTAL_ALIGNMENT_CENTER, SIDE.size.x)
	var top: float = ROWS_TOP + 14.0
	_talent_menu.draw_on(self, LABEL_X, top, Ui.ROW, ROW_STEP)
	for index: int in TraitRules.ALL.size():
		_draw_pips(TraitRules.ALL[index], _talent_menu.y_of(index, top, ROW_STEP),
			index == _talent_menu.at)
	var rule: float = _talent_menu.y_of(TraitRules.ALL.size(), top, ROW_STEP) + 12.0
	draw_line(Vector2(NOTE_LEFT, rule), Vector2(NOTE_LEFT + NOTE_WIDTH, rule),
		Color(0.75, 0.70, 0.55, 0.28), 1.0)
	var what: StringName = _talent_menu.chosen()
	var line: String = Text.of(&"creation.ready") if what == &"begin" \
		else Text.of(TraitRules.note_key(what))
	draw_multiline_string(Ui.font(), Vector2(NOTE_LEFT, rule + 16.0), line,
		HORIZONTAL_ALIGNMENT_CENTER, NOTE_WIDTH, Ui.NOTE, 3, Ui.DIM)


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
