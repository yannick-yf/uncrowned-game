extends Node2D

## The first screen: **his world at dusk, gliding behind the menu** (D19, the audit's 20).
##
## It was a night sky and a treeline of the 2D pack's trees — the one pack the art rule says
## never appears — and nothing of the world the game is played in. Now it is Brindle at dusk,
## photographed from his world by `tools/capture_title.gd` (`view3d/title/brindle_dusk.jpg`),
## drifting slowly as a camera would over it, graded toward evening, with ash rising over
## it; the game's name drawn over a fallen crown; and the menu in the panel every other
## screen uses. Without the picture (a clone that has not captured it) the night stays.
##
## It is drawn rather than laid out, for the same reason the world is — one `_draw`
## with the numbers visible beats a scene tree of anchored `Control`s whose positions
## live in a file nobody reads.

signal chose(what: StringName, carrying: Variant)

## Sky, top to bottom. Night rather than black: a black screen with words on it is a
## crash report.
const SKY_TOP: Color = Color(0.055, 0.075, 0.125)
const SKY_LOW: Color = Color(0.025, 0.045, 0.050)

const PICTURE: String = "res://view3d/title/brindle_dusk.jpg"
## How large the picture is drawn: a 2560-pixel picture over 960 of the 640 units, so a
## third of it is off the screen to glide into.
const PICTURE_SCALE: float = 0.375
## One slow loop of the glide, in seconds, and how far of the room it uses.
const GLIDE_SECONDS: float = 96.0
const GLIDE_REACH: Vector2 = Vector2(0.42, 0.36)
## Evening on his daylight: shadows toward blue, lights toward ember, a little dimmer.
const GRADE_SHADER: String = """
shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 cool = vec3(0.74, 0.80, 1.0);
	vec3 warm = vec3(1.10, 0.93, 0.78);
	c.rgb *= mix(cool, warm, smoothstep(0.12, 0.50, lum)) * 0.88;
	COLOR = vec4(c.rgb, 1.0);
}
"""
const ASH_FLAKES: int = 34

const MENU_TOP: float = 230.0
## The menu's panel: as wide as its widest row and the caret, centred.
const MENU_PAD: Vector2 = Vector2(22.0, 10.0)
const LOGO_Y: float = 96.0
const LOGO_SIZE: int = 48
const BOLD_FONT: String = "res://view/fonts/pixel_operator/PixelOperator-Bold.ttf"

var _backdrop: Sprite2D = null
var _bold: Font = null
var _menu: Menu = Menu.new()
## The menu asking whether a run in progress may be thrown away, or null when it is
## not being asked. A second menu rather than a mode flag on the first: the question
## has its own rows and its own cursor, and conflating them is how a screen ends up
## quitting the game because the cursor was on row 4 of the wrong list.
var _asking: Menu = null
var _elapsed: float = 0.0


func _ready() -> void:
	_build_backdrop()
	_build()
	Sound.play_music_now(Sound.MUSIC_TITLE)
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
		{"id": &"sound", "key": &"title.sound", "args": [Text.of(_sound_word())]},
		{"id": &"quit", "key": &"title.quit"},
	])
	if not _menu.point_at(was) and has_save:
		_menu.point_at(&"continue")


func _process(delta: float) -> void:
	_elapsed += delta
	_glide()
	_read_input()
	queue_redraw()


## The picture of his world, under everything this node draws.
func _build_backdrop() -> void:
	if ResourceLoader.exists(BOLD_FONT):
		_bold = load(BOLD_FONT) as Font
	if not ResourceLoader.exists(PICTURE):
		return
	_backdrop = Sprite2D.new()
	_backdrop.name = "Backdrop"
	_backdrop.texture = load(PICTURE) as Texture2D
	_backdrop.centered = false
	_backdrop.region_enabled = true
	_backdrop.scale = Vector2(PICTURE_SCALE, PICTURE_SCALE)
	_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_backdrop.z_index = -1
	var shader := Shader.new()
	shader.code = GRADE_SHADER
	var grade := ShaderMaterial.new()
	grade.shader = shader
	_backdrop.material = grade
	add_child(_backdrop)
	_glide()


## A slow loop over the picture, as a camera gliding over Brindle would draw it.
func _glide() -> void:
	if _backdrop == null or _backdrop.texture == null:
		return
	var screen: Vector2 = get_viewport_rect().size if is_inside_tree() else Vector2(640.0, 360.0)
	var shown: Vector2 = screen / PICTURE_SCALE
	var room: Vector2 = (_backdrop.texture.get_size() - shown).max(Vector2.ZERO)
	var turn: float = TAU * _elapsed / GLIDE_SECONDS
	var at: Vector2 = room * 0.5 + room * 0.5 * Vector2(cos(turn) * GLIDE_REACH.x * 2.0, sin(turn * 2.0) * GLIDE_REACH.y)
	_backdrop.region_rect = Rect2(at.clamp(Vector2.ZERO, room), shown)


## Whether his world stands behind the menu, for the suite.
func shows_his_world() -> bool:
	return _backdrop != null and _backdrop.texture != null


func _sound_word() -> StringName:
	return &"sound.off" if Sound.muted() else &"sound.on"


func _read_input() -> void:
	var menu: Menu = _asking if _asking != null else _menu
	if Input.is_action_just_pressed(&"move_down") and menu.move(1):
		Sound.cue(&"move")
	if Input.is_action_just_pressed(&"move_up") and menu.move(-1):
		Sound.cue(&"move")
	if Input.is_action_just_pressed(&"back") and _asking != null:
		Sound.cue(&"cancel")
		_asking = null
		return
	if Input.is_action_just_pressed(&"interact"):
		Sound.cue(&"accept")
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
		&"sound":
			Sound.set_muted(not Sound.muted())
			_build()
		&"quit":
			chose.emit(&"quit", null)
		&"replace":
			chose.emit(&"creation", null)
		&"keep":
			Sound.cue(&"cancel")
			_asking = null


func _ask() -> void:
	_asking = Menu.new([
		{"id": &"keep", "key": &"title.keep"},
		{"id": &"replace", "key": &"title.replace"},
	])


# ----------------------------------------------------------------- drawing ---

func _draw() -> void:
	var screen: Vector2 = get_viewport_rect().size
	if not shows_his_world():
		Ui.sky(self, Rect2(Vector2.ZERO, screen), SKY_TOP, SKY_LOW)
		_draw_stars(screen)
	_draw_veil(screen)
	_draw_ash(screen)
	_draw_name(screen)
	_draw_menu(screen)
	Ui.write_over(self, Vector2(0.0, screen.y - 10.0), Text.of(&"title.hint"), Ui.NOTE,
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


## Dark at the top for the name, dark at the bottom for the hint, and the edges closed in,
## so the words stand on the picture without a box round each.
func _draw_veil(screen: Vector2) -> void:
	var dark := Color(0.02, 0.025, 0.04, 0.78)
	var clear := Color(0.02, 0.025, 0.04, 0.0)
	draw_polygon(PackedVector2Array([Vector2(0.0, 0.0), Vector2(screen.x, 0.0),
		Vector2(screen.x, 170.0), Vector2(0.0, 170.0)]), PackedColorArray([dark, dark, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0.0, screen.y - 60.0), Vector2(screen.x, screen.y - 60.0),
		Vector2(screen.x, screen.y), Vector2(0.0, screen.y)]), PackedColorArray([clear, clear, dark, dark]))
	var side := Color(0.02, 0.025, 0.04, 0.55)
	for left: bool in [true, false]:
		var edge: float = 0.0 if left else screen.x
		var inner: float = 90.0 if left else screen.x - 90.0
		draw_polygon(PackedVector2Array([Vector2(edge, 0.0), Vector2(inner, 0.0), Vector2(inner, screen.y),
			Vector2(edge, screen.y)]), PackedColorArray([side, clear, clear, side]))


## Ash rising over the ruins and an ember or two, each on its own clock, so the picture
## breathes: the one thing a photograph of smoke cannot do.
func _draw_ash(screen: Vector2) -> void:
	for i: int in ASH_FLAKES:
		var speed: float = 6.0 + float(Art.scatter_hash(i, 17) % 9)
		var rise: float = fposmod(_elapsed * speed + float(Art.scatter_hash(i * 3, 5)), screen.y + 40.0)
		var x: float = float(Art.scatter_hash(i * 11, 23)) / 999.0 * screen.x + sin(_elapsed * 0.4 + float(i)) * 14.0
		var at := Vector2(x, screen.y + 20.0 - rise)
		var ember: bool = i % 9 == 0
		var fade: float = clampf(rise / 80.0, 0.0, 1.0) * clampf((screen.y + 40.0 - rise) / 120.0, 0.0, 1.0)
		var colour: Color = Color(1.0, 0.55, 0.25, 0.75 * fade) if ember else Color(0.86, 0.84, 0.80, 0.30 * fade)
		draw_rect(Rect2(at.round(), Vector2(1.0, 1.0)), colour, true)


## **The name, drawn** (D19): his game's name in the bold cut, inked as his figures are
## outlined, over a crown that has fallen on its side — the argument of the game in one mark.
func _draw_name(screen: Vector2) -> void:
	# The name stands a little left of the middle, so the name and the crown after it are
	# centred together.
	var middle: float = screen.x * 0.5 - 24.0
	var name: String = Text.of(&"title.name")
	var font: Font = _bold if _bold != null else Ui.font()
	var width: float = font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, LOGO_SIZE).x
	var left: float = roundf(middle - width * 0.5)
	font.draw_string_outline(get_canvas_item(), Vector2(left, LOGO_Y + 2.0), name, HORIZONTAL_ALIGNMENT_LEFT,
		-1, LOGO_SIZE, 6, Color(0.0, 0.0, 0.0, 0.55))
	font.draw_string_outline(get_canvas_item(), Vector2(left, LOGO_Y), name, HORIZONTAL_ALIGNMENT_LEFT,
		-1, LOGO_SIZE, 4, CROWN_INK)
	font.draw_string(get_canvas_item(), Vector2(left, LOGO_Y), name, HORIZONTAL_ALIGNMENT_LEFT, -1, LOGO_SIZE,
		Color(0.96, 0.92, 0.80))
	# The rule runs on under the crown, which lies tipped over on it past the name's end, one
	# corner of its band on the line and its broken point beside it.
	var rule: float = width * 0.5 + 72.0
	draw_line(Vector2(middle + 24.0 - rule, LOGO_Y + 12.0), Vector2(middle + 24.0 + rule, LOGO_Y + 12.0),
		Color(Ui.GOLD, 0.55), 1.0)
	_draw_fallen_crown(Vector2(roundf(middle + width * 0.5 + 32.0), LOGO_Y + 12.0 - CROWN_FOOT))
	Ui.write_over(self, Vector2(0.0, LOGO_Y + 32.0), Text.of(&"title.subtitle"), Ui.NOTE,
		Ui.INK, HORIZONTAL_ALIGNMENT_CENTER, screen.x)


const CROWN_INK: Color = Color(0.086, 0.055, 0.055)
## How far below its centre the tipped crown's lowest corner falls, so it can rest on a line.
const CROWN_FOOT: float = 21.0
const CROWN_GOLD: Color = Color(0.93, 0.74, 0.30)
const CROWN_LIGHT: Color = Color(1.0, 0.88, 0.52)


## A crown tipped over, a point of it broken off and lying beside it: polygons in his ink
## and a gold lit from the top left.
func _draw_fallen_crown(at: Vector2) -> void:
	var turn: float = deg_to_rad(34.0)
	var shape := PackedVector2Array([Vector2(-18, 8), Vector2(-18, -4), Vector2(-12, 2), Vector2(-6, -10),
		Vector2(0, 0), Vector2(5, -7), Vector2(9, 1), Vector2(18, -4), Vector2(18, 8)])
	var placed := PackedVector2Array()
	for point: Vector2 in shape:
		placed.append(at + (point * 1.25).rotated(turn))
	var outline := PackedVector2Array(placed)
	outline.append(placed[0])
	var lit := PackedColorArray()
	for point: Vector2 in placed:
		lit.append(CROWN_LIGHT.lerp(CROWN_GOLD, clampf((point.x - at.x + 18.0) / 36.0 + (point.y - at.y + 10.0) / 40.0, 0.0, 1.0)))
	draw_polygon(placed, lit)
	draw_polyline(outline, CROWN_INK, 2.0)
	# Its band, and the point that broke off, lying at its foot.
	draw_line(at + (Vector2(-18, 4) * 1.25).rotated(turn), at + (Vector2(18, 4) * 1.25).rotated(turn), CROWN_INK, 2.0)
	var shard := PackedVector2Array([at + Vector2(24, CROWN_FOOT), at + Vector2(29, CROWN_FOOT - 6.0),
		at + Vector2(33, CROWN_FOOT)])
	draw_polygon(shard, PackedColorArray([CROWN_LIGHT, CROWN_GOLD, CROWN_GOLD]))
	var shard_edge := PackedVector2Array(shard)
	shard_edge.append(shard[0])
	draw_polyline(shard_edge, CROWN_INK, 2.0)


## The menu in the panel every screen uses, centred under the name.
func _draw_menu(screen: Vector2) -> void:
	var widest: float = 0.0
	for index: int in _menu.rows.size():
		widest = maxf(widest, Ui.width_of(_menu.label(index), Ui.ROW))
	var box := Rect2(Vector2(roundf(screen.x * 0.5 - widest * 0.5) - MENU_PAD.x, MENU_TOP - 14.0 - MENU_PAD.y),
		Vector2(widest + MENU_PAD.x * 2.0, float(_menu.rows.size()) * Menu.SPACING + MENU_PAD.y * 2.0 - 2.0))
	Ui.panel(self, box)
	_menu.draw_on(self, box.position.x + MENU_PAD.x, MENU_TOP)


## Where the menu's panel stands, for the suite.
func menu_box() -> Rect2:
	var widest: float = 0.0
	for index: int in _menu.rows.size():
		widest = maxf(widest, Ui.width_of(_menu.label(index), Ui.ROW))
	return Rect2(Vector2(320.0 - widest * 0.5 - MENU_PAD.x, MENU_TOP - 14.0 - MENU_PAD.y),
		Vector2(widest + MENU_PAD.x * 2.0, float(_menu.rows.size()) * Menu.SPACING + MENU_PAD.y * 2.0 - 2.0))


func _draw_question(screen: Vector2) -> void:
	var box := Rect2(screen.x * 0.5 - 170.0, 128.0, 340.0, 96.0)
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0.0, 0.0, 0.0, 0.55), true)
	Ui.panel(self, box)
	Ui.write(self, box.position + Vector2(0.0, 26.0), Text.of(&"title.replace.ask"),
		Ui.BODY, Ui.INK, HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	Ui.write(self, box.position + Vector2(0.0, 42.0), Text.of(&"title.replace.note"),
		Ui.NOTE, Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	_asking.draw_on(self, box.position.x + 40.0, box.position.y + 64.0)
