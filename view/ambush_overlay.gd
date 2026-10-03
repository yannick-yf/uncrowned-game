class_name AmbushOverlay
extends Node2D

## **Choosing whom to surprise** (N4, 2026-10-03), outside a fight: K, from where no pack
## sees the player, stops the world and marks every animal his blade or his bow could reach
## — a ring at its feet, the one chosen ringed twice in gold with its name and what the blow
## would cost it — and the keys along the bottom. The world's window fills `rows` every
## frame with where each one is on the screen; this only draws. In the HUD's gold, ink and
## panel, drawn here: nothing downloaded.

## `{feet, head, name, damage, weapon}` a candidate, in the order the arrows go through them.
var rows: Array = []
var chosen: int = 0


func show_rows(p_rows: Array, p_chosen: int) -> void:
	rows = p_rows
	chosen = p_chosen
	queue_redraw()


func _draw() -> void:
	var screen: Vector2 = get_viewport_rect().size
	for index: int in rows.size():
		var row: Dictionary = rows[index] as Dictionary
		var feet: Vector2 = row.get("feet", Vector2(-1.0, -1.0)) as Vector2
		if feet.x < 0.0:
			continue
		var lit: bool = index == chosen
		_ellipse(feet, 15.0 if lit else 12.0, Color(Ui.GOLD, 0.95 if lit else 0.5), 2.0 if lit else 1.0)
		if lit:
			_ellipse(feet, 10.0, Color(Ui.GOLD, 0.8), 1.0)
	if rows.is_empty():
		return
	var row: Dictionary = rows[clampi(chosen, 0, rows.size() - 1)] as Dictionary
	var head: Vector2 = row.get("head", Vector2(-1.0, -1.0)) as Vector2
	if head.x >= 0.0:
		var name: String = String(row.get("name", ""))
		var cost: String = Text.of(StringName("ambush.damage.%s" % String(row.get("weapon", "sword"))), [int(row.get("damage", 0))])
		var width: float = maxf(Ui.width_of(name, Ui.ROW), Ui.width_of(cost, Ui.NOTE)) + 16.0
		var box := Rect2(Vector2(head.x - width * 0.5, head.y - 40.0), Vector2(width, 32.0))
		Ui.panel(self, box)
		Ui.write_over(self, Vector2(box.position.x, box.position.y + 13.0), name, Ui.ROW, Ui.INK,
			HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
		Ui.write_over(self, Vector2(box.position.x, box.position.y + 26.0), cost, Ui.NOTE, Ui.GOLD,
			HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	var title: String = Text.of(&"ambush.title")
	Ui.write_over(self, Vector2(0.0, screen.y - 30.0), title, Ui.ROW, Ui.GOLD, HORIZONTAL_ALIGNMENT_CENTER, screen.x)
	Ui.write_over(self, Vector2(0.0, screen.y - 12.0), Text.of(&"ambush.keys"), Ui.NOTE, Ui.DIM,
		HORIZONTAL_ALIGNMENT_CENTER, screen.x)


## A ring laid on the ground, as the eye sees it from the camera: wider than it is tall.
func _ellipse(at: Vector2, radius: float, ink: Color, width: float) -> void:
	var points := PackedVector2Array()
	for i: int in 33:
		var a: float = TAU * float(i) / 32.0
		points.append(at + Vector2(cos(a) * radius, sin(a) * radius * 0.45))
	draw_polyline(points, ink, width)
