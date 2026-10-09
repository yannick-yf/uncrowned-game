class_name ExploreHud
extends Control

## **What the player sees while he walks** (D2, 2026-10-09). The audit found the HUD a
## column of six lines of plain text — the place, his health, his deaths, the king's
## escort, the clock, two keys, and a debug key in English — which read as a debug
## overlay. Now only what he needs: his health as a framed bar, where he is and how that
## place regards him (§8's ambient register, shown from the first minute), and the
## place's name as a title that rises when he enters it and fades. The escort is the
## journal's, the keys the pause menu's, the clock is gone (it read midnight in full
## sun). Debug lines stay behind the debug gate, top right, small.
##
## Drawn here, from a reading `main` hands it each frame; it holds only what the eye
## needs between frames — which title is showing and since when.

## How long a place's title shows: rising, holding, fading, in seconds.
const TITLE_IN: float = 0.5
const TITLE_HOLD: float = 2.4
const TITLE_OUT: float = 1.0
const BAR: Rect2 = Rect2(8.0, 8.0, 120.0, 8.0)

var _reading: Dictionary = {}
var _title: String = ""
var _title_since: float = -100.0
var _clock: float = 0.0
var _last_place: String = ""


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## `{hp, max_hp, place, regard, debug: Array[String]}`. A new place's name starts its
## title; the same name again does not.
func present(reading: Dictionary, now: float) -> void:
	_reading = reading
	_clock = now
	var place: String = capitalised(String(reading.get("place", "")))
	if place != "" and place != _last_place:
		_last_place = place
		_title = place
		_title_since = _clock
	queue_redraw()


## How much of the title shows now, 0 to 1: what a test and a photograph ask.
func title_alpha() -> float:
	var t: float = _clock - _title_since
	if t < 0.0 or t > TITLE_IN + TITLE_HOLD + TITLE_OUT:
		return 0.0
	if t < TITLE_IN:
		return t / TITLE_IN
	if t < TITLE_IN + TITLE_HOLD:
		return 1.0
	return 1.0 - (t - TITLE_IN - TITLE_HOLD) / TITLE_OUT


## A place's name standing alone takes a capital: *les Forges* mid-sentence, *Les
## Forges* as a title.
static func capitalised(name: String) -> String:
	return name.left(1).to_upper() + name.substr(1)


## The title showing now — rising, held or fading — or empty.
func title() -> String:
	var t: float = _clock - _title_since
	return _title if t >= 0.0 and t <= TITLE_IN + TITLE_HOLD + TITLE_OUT else ""


func _draw() -> void:
	if _reading.is_empty():
		return
	var hp: int = int(_reading.get("hp", 0))
	var most: int = maxi(int(_reading.get("max_hp", 1)), 1)
	Ui.bar(self, BAR, float(hp) / float(most))
	Ui.write_over(self, Vector2(BAR.end.x + 6.0, BAR.position.y + 8.0), Text.of(&"hud.health", [hp, most]),
		Ui.NOTE, Ui.DIM)
	var place: String = capitalised(String(_reading.get("place", "")))
	var regard: String = String(_reading.get("regard", ""))
	Ui.write_over(self, Vector2(BAR.position.x, BAR.end.y + 16.0), place, Ui.ROW, Ui.INK)
	# How the place regards him, on a line of its own: *le cimetière inconnu* beside the
	# name read as though the place were the unknown thing.
	if regard != "":
		Ui.write_over(self, Vector2(BAR.position.x, BAR.end.y + 31.0), Text.of(&"hud.regard", [regard]),
			Ui.NOTE, Ui.DIM)
	var alpha: float = title_alpha()
	if alpha > 0.0:
		var width: float = size.x
		var rise: float = (1.0 - minf(alpha, 1.0)) * 6.0
		var y: float = 64.0 + rise
		# A soft dark band behind it, so gold reads over sunlit grass as over a roof.
		var core: float = Ui.width_of(_title, Ui.HEADING) * 0.5 + 24.0
		var fade: float = 80.0
		var dark := Color(0.0, 0.0, 0.0, 0.38 * alpha)
		var clear := Color(0.0, 0.0, 0.0, 0.0)
		var top: float = y - 24.0
		var bottom: float = y + 12.0
		var mid: float = width * 0.5
		for side: float in [-1.0, 1.0]:
			var inner_x: float = mid + side * core
			var outer_x: float = mid + side * (core + fade)
			draw_polygon(PackedVector2Array([Vector2(inner_x, top), Vector2(outer_x, top),
				Vector2(outer_x, bottom), Vector2(inner_x, bottom)]),
				PackedColorArray([dark, clear, clear, dark]))
		draw_rect(Rect2(mid - core, top, core * 2.0, bottom - top), dark, true)
		Ui.write(self, Vector2(1.0, y + 1.0), _title, Ui.HEADING, Color(Ui.SHADOW, Ui.SHADOW.a * alpha),
			HORIZONTAL_ALIGNMENT_CENTER, width)
		Ui.write(self, Vector2(0.0, y), _title, Ui.HEADING, Color(Ui.GOLD, alpha), HORIZONTAL_ALIGNMENT_CENTER, width)
		var half: float = Ui.width_of(_title, Ui.HEADING) * 0.5 + 18.0
		draw_line(Vector2(width * 0.5 - half, y + 8.0), Vector2(width * 0.5 + half, y + 8.0), Color(Ui.EDGE, Ui.EDGE.a * alpha), 1.0)
	# The key over what E would use (D6): a small dark cap with a gold edge, bobbing a pixel.
	var key_at: Vector2 = _reading.get("key_at", Vector2(-1.0, -1.0)) as Vector2
	if key_at.x >= 0.0:
		var bob: float = roundf(sin(_clock * 4.0))
		var cap := Rect2(key_at + Vector2(-7.0, -14.0 + bob), Vector2(14.0, 14.0))
		draw_rect(cap, Color(0.05, 0.05, 0.06, 0.88), true)
		draw_rect(cap, Ui.GOLD, false, 1.0)
		Ui.write(self, Vector2(cap.position.x, cap.end.y - 3.0), "E", Ui.ROW, Ui.GOLD, HORIZONTAL_ALIGNMENT_CENTER, cap.size.x)
	var debug: Array = _reading.get("debug", []) as Array
	for i: int in debug.size():
		var line: String = String(debug[i])
		var ink: Color = Ui.EMBER if line.begins_with("[G]") else Ui.FAINT
		Ui.write_over(self, Vector2(0.0, 14.0 + float(i) * 14.0), line, Ui.NOTE, ink, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 8.0)
