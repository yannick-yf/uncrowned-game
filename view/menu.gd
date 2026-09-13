class_name Menu
extends RefCounted

## A list of rows with a cursor on one of them, which is every menu this game has.
##
## The title screen, the confirmation before a run is thrown away, character creation
## and the pause screen are all this object with a different table in it. Adding a row
## is a row; adding a screen is a table and a `_draw`.
##
## It knows nothing about what a row *does*. A row carries an `id`, the caller
## switches on it, and nothing here has to change when the meaning does.
##
##   `id`      what the screen gets back when this row is chosen
##   `key`     the text key for the label — never the words themselves, or the menu
##             would be English
##   `args`    optional, substituted into the line, for "Language: FR"
##   `enabled` optional, default true. A disabled row is drawn greyed and skipped by
##             the cursor, which is how Continue behaves before there is a save:
##             visible, so the player learns the game has one, and unreachable.

const SPACING: float = 17.0

var rows: Array[Dictionary] = []
var at: int = 0


func _init(with_rows: Array[Dictionary] = []) -> void:
	set_rows(with_rows)


## Replace the table. The cursor lands on the first row it is allowed to sit on —
## or stays put if the caller has already said where it wants it via `point_at`.
func set_rows(new_rows: Array[Dictionary]) -> void:
	rows = new_rows
	at = 0
	if not can_pick(at):
		move(1)


## Put the cursor on a row by id, if that row can be sat on. Used to open the title
## screen on Continue when there is something to continue.
func point_at(id: StringName) -> bool:
	for index: int in rows.size():
		if rows[index].get("id", &"") == id and can_pick(index):
			at = index
			return true
	return false


func can_pick(index: int) -> bool:
	return index >= 0 and index < rows.size() and bool(rows[index].get("enabled", true))


## Move the cursor by `by` rows, skipping what cannot be picked and wrapping at both
## ends. Returns whether anything actually moved, so a screen can play a sound only
## when it did — a menu that clicks when the cursor has not moved is worse than one
## that is silent.
func move(by: int) -> bool:
	if rows.is_empty() or by == 0:
		return false
	for step: int in rows.size():
		var index: int = posmod(at + by * (step + 1), rows.size())
		if can_pick(index):
			if index == at:
				return false
			at = index
			return true
	return false


func current() -> Dictionary:
	return rows[at] if can_pick(at) else {}


## The id under the cursor, or nothing if every row is disabled.
func chosen() -> StringName:
	return current().get("id", &"") as StringName


func label(index: int) -> String:
	if index < 0 or index >= rows.size():
		return ""
	return Text.of(rows[index].get("key", &"") as StringName,
		rows[index].get("args", []) as Array)


## Where row `index` sits when the first is at `top`.
func y_of(index: int, top: float, spacing: float = SPACING) -> float:
	return top + float(index) * spacing


## Draw the rows, left-aligned at `left`, first baseline at `top`.
##
## Only the label and the cursor. Anything a particular screen wants beside a row —
## creation draws five pips and a number — it draws itself, using `y_of` so the two
## cannot drift apart.
func draw_on(canvas: CanvasItem, left: float, top: float, size: int = Ui.ROW,
		spacing: float = SPACING) -> void:
	for index: int in rows.size():
		var y: float = y_of(index, top, spacing)
		var colour: Color = Ui.INK
		if not can_pick(index):
			colour = Ui.FAINT
		elif index == at:
			colour = Ui.GOLD
			Ui.caret(canvas, Vector2(left - 9.0, y - float(size) * 0.32), 6.0)
		Ui.write_over(canvas, Vector2(left, y), label(index), size, colour)
