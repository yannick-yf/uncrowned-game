class_name MessageBand
extends Control

## **One band for what the world says at the bottom of the screen** (D7, the audit's 16):
## the place's sign, what E or K or F would do there, what was just gained, why the way is
## closed. They were plain lines of text stacked at the bottom left; now one soft dark band
## across the bottom, a line each, centred, fading in when there is something to say and out
## when there is not. A line that begins with its key — *E, ramasser une épée courte* — has
## the key drawn as a cap, in the gold of the cap over the thing itself (D6).
##
## It draws the very text `main` writes into its prompt label, which stays as the reading a
## test asks for; this only decides how it looks.

const FADE_IN: float = 0.18
const FADE_OUT: float = 0.30
const LINE: float = 17.0

var _rows: PackedStringArray = PackedStringArray()
var _shown: PackedStringArray = PackedStringArray()
var _alpha: float = 0.0
var _clock: float = 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func present(text: String, now: float) -> void:
	var delta: float = maxf(now - _clock, 0.0)
	_clock = now
	_rows = text.split("\n", false)
	if not _rows.is_empty():
		_shown = _rows
		_alpha = minf(_alpha + delta / FADE_IN, 1.0)
	else:
		_alpha = maxf(_alpha - delta / FADE_OUT, 0.0)
	queue_redraw()


func rows() -> PackedStringArray:
	return _rows


func _draw() -> void:
	if _alpha <= 0.0 or _shown.is_empty():
		return
	var screen: Vector2 = size
	var height: float = float(_shown.size()) * LINE + 14.0
	var top: float = screen.y - height
	var dark := Color(0.0, 0.0, 0.0, 0.55 * _alpha)
	var clear := Color(0.0, 0.0, 0.0, 0.0)
	# A band that fades up into the picture rather than a box with an edge.
	draw_polygon(PackedVector2Array([Vector2(0.0, top - 18.0), Vector2(screen.x, top - 18.0),
		Vector2(screen.x, top + 6.0), Vector2(0.0, top + 6.0)]), PackedColorArray([clear, clear, dark, dark]))
	draw_rect(Rect2(0.0, top + 6.0, screen.x, screen.y - top - 6.0), dark, true)
	for i: int in _shown.size():
		_draw_row(_shown[i], top + 14.0 + float(i) * LINE, screen.x)


## A row, centred; a leading key — one capital and a comma — drawn as a cap.
func _draw_row(row: String, baseline: float, width: float) -> void:
	var ink: Color = Ui.INK
	ink.a = _alpha
	var key: String = ""
	var rest: String = row
	if row.length() > 3 and row.substr(1, 2) == ", " and row[0] == row[0].to_upper() and row[0] != row[0].to_lower():
		key = row[0]
		rest = row.substr(3)
	var cap_w: float = 14.0 if key != "" else 0.0
	var gap: float = 6.0 if key != "" else 0.0
	var total: float = cap_w + gap + Ui.width_of(rest, Ui.ROW)
	var x: float = (width - total) * 0.5
	if key != "":
		var cap := Rect2(Vector2(x, baseline - 11.0), Vector2(14.0, 14.0))
		draw_rect(cap, Color(0.05, 0.05, 0.06, 0.9 * _alpha), true)
		var gold: Color = Ui.GOLD
		gold.a = _alpha
		draw_rect(cap, gold, false, 1.0)
		Ui.write(self, Vector2(cap.position.x, baseline), key, Ui.ROW, gold, HORIZONTAL_ALIGNMENT_CENTER, cap.size.x)
	Ui.write_over(self, Vector2(x + cap_w + gap, baseline), rest, Ui.ROW, ink)
