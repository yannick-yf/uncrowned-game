class_name TalkBox
extends Control

## **The dialogue box, sized to its words** (D16, the audit's 13). It was a dark rectangle
## over the bottom half of the screen whatever it held — two lines and two choices in a box
## for eight — with no face and not the frame of the other panels. Now it is as tall as what
## it says, in the panel the inventory and the pause are drawn in (`Ui.panel`), and on its
## left the speaker's face: **cut from his own frame** in the world, his look's sheet read by
## the rule his shader uses for what is background, so the face is the figure you walked up
## to. The fairy is her figure (D17) in her light.
##
## `main` hands it the words each frame; it only decides how they look.

const WIDTH: float = 560.0
const BOTTOM: float = 352.0
const PAD: float = 10.0
const PORTRAIT: float = 64.0
const LINE: float = 17.0
## Between the line and the choices.
const GAP: float = 7.0
## The part of a frame a face is cut from, as fractions of it: the head and the shoulders.
const FACE: Rect2 = Rect2(0.08, 0.04, 0.84, 0.62)
## A darker well for the face, as the inventory's for the figure.
const WELL: Color = Color(0.10, 0.10, 0.11, 0.92)
const FAIRY_LIGHT: Color = Color(0.80, 0.96, 0.82)
## The look that stands for her: drawn whole from her own sheet, not cut from his frames.
const FAIRY: StringName = &"fairy"

## His rule for what is background, in linear light as the world reads it — so a face is
## cut where the figure is cut, and an old man's grey hair is not taken for the sheet.
const FACE_SHADER: String = """
shader_type canvas_item;
void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	vec3 lin = mix(ink.rgb / 12.92, pow((ink.rgb + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), ink.rgb));
	float high = max(lin.r, max(lin.g, lin.b));
	float low = min(lin.r, min(lin.g, lin.b));
	if (ink.a < 0.5 || (high > 0.35 && (high - low) / max(high, 0.001) < 0.22)) { discard; }
	COLOR = vec4(ink.rgb, 1.0);
}
"""

var _speaker: String = ""
var _line: String = ""
var _rows: PackedStringArray = PackedStringArray()
var _look: StringName = &""
var _glow: bool = false
var _clock: float = 0.0
var _face: Sprite2D = null
var _frames: SpriteFrames = null


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face = Sprite2D.new()
	_face.centered = true
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var shader := Shader.new()
	shader.code = FACE_SHADER
	var paint := ShaderMaterial.new()
	paint.shader = shader
	_face.material = paint
	_face.visible = false
	add_child(_face)


## What is said, by whom, and the face: `look` is the speaker's look in `content/looks.json`,
## `FAIRY` for her, `&""` for nobody drawn; `glow` draws the fairy's light in the well.
func present(speaker: String, line: String, rows: Array[String], look: StringName, glow: bool, now: float) -> void:
	_speaker = speaker
	_line = line
	_rows = PackedStringArray(rows)
	_glow = glow
	_clock = now
	if look != _look:
		_look = look
		_dress_face()
	_place_face()
	queue_redraw()


## The well the face stands in, at the box's left.
func _well() -> Rect2:
	return Rect2(box().position + Vector2(PAD, PAD), Vector2(PORTRAIT, PORTRAIT))


func _place_face() -> void:
	_face.visible = _face.texture != null and (_speaker != "" or _line != "")
	if not _face.visible:
		return
	var cut: Vector2 = _face.texture.get_size()
	var fit: float = minf((PORTRAIT - 4.0) / cut.x, (PORTRAIT - 4.0) / cut.y)
	_face.scale = Vector2(fit, fit)
	_face.position = _well().get_center() + Vector2(0.0, 1.0)


## Where the box stands this frame, for the suite and for the face.
func box() -> Rect2:
	var height: float = PAD + LINE + 2.0 + float(_line_rows().size()) * LINE + GAP \
		+ float(_choice_rows().size()) * LINE + PAD - 4.0
	height = maxf(height, PORTRAIT + PAD * 2.0)
	var screen: Vector2 = size if size.x > 0.0 else Vector2(640.0, 360.0)
	return Rect2(Vector2(floorf((screen.x - WIDTH) * 0.5), screen.y - (360.0 - BOTTOM) - height), Vector2(WIDTH, height))


## The width the words wrap at: the box less the face and the air round it.
func text_width() -> float:
	return WIDTH - PORTRAIT - PAD * 3.0


func speaker() -> String:
	return _speaker


func line() -> String:
	return _line


func rows() -> PackedStringArray:
	return _rows


## Whether a face is shown, for the suite.
func shows_a_face() -> bool:
	return _face.visible and _face.texture != null


func _line_rows() -> PackedStringArray:
	return Ui.wrapped(_line, Ui.BODY, text_width())


func _choice_rows() -> PackedStringArray:
	var out := PackedStringArray()
	for row: String in _rows:
		out.append_array(Ui.wrapped(row, Ui.ROW, text_width()))
	return out


## The speaker's frame facing you, idle, on his look's sheet — the frame the world draws.
func _dress_face() -> void:
	_face.texture = null
	if _look == FAIRY:
		if ResourceLoader.exists(World3d.FAIRY_SHEET):
			var her := AtlasTexture.new()
			her.atlas = load(World3d.FAIRY_SHEET) as Texture2D
			her.region = Rect2(8.0, 4.0, World3d.FAIRY_CELL - 16.0, World3d.FAIRY_CELL - 16.0)
			_face.texture = her
		return
	if _look == &"" or not ResourceLoader.exists(World3d.HIS_FRAMES):
		return
	var path: String = CastLooks.sheet_path(_look)
	if not ResourceLoader.exists(path):
		return
	if _frames == null:
		_frames = load(World3d.HIS_FRAMES) as SpriteFrames
	if _frames == null:
		return
	var dressed: SpriteFrames = CastLooks.frames_for(_frames, load(path) as Texture2D)
	var frame := dressed.get_frame_texture(&"idle_down", 0) as AtlasTexture
	if frame == null:
		return
	var cut := AtlasTexture.new()
	cut.atlas = frame.atlas
	var whole: Rect2 = frame.region
	cut.region = Rect2(whole.position + whole.size * FACE.position, whole.size * FACE.size).abs()
	_face.texture = cut


func _draw() -> void:
	if _speaker == "" and _line == "":
		return
	var at: Rect2 = box()
	Ui.panel(self, at)
	var well: Rect2 = _well()
	Ui.panel(self, well, WELL)
	if _glow:
		_draw_light(well.get_center())
	var x: float = well.end.x + PAD
	var y: float = at.position.y + PAD + 12.0
	Ui.write(self, Vector2(x, y), _speaker, Ui.BODY, Ui.GOLD)
	y += LINE + 2.0
	for row: String in _line_rows():
		Ui.write(self, Vector2(x, y), row, Ui.BODY, Ui.INK)
		y += LINE
	y += GAP
	for row: String in _choice_rows():
		Ui.write(self, Vector2(x, y), row, Ui.ROW, Ui.SAGE)
		y += LINE


## The fairy in the well: her light, breathing as it does in the world.
func _draw_light(centre: Vector2) -> void:
	var breath: float = 0.5 + 0.5 * sin(_clock * 2.4)
	# Many faint discs, each a pixel smaller: a soft light, not a target.
	for ring: int in 26:
		var light: Color = FAIRY_LIGHT
		light.a = 0.028 + 0.012 * breath
		draw_circle(centre, 27.0 - float(ring), light)
	var core: Color = Color(0.96, 1.0, 0.94, 0.85)
	draw_circle(centre, 2.0 + breath, core)
