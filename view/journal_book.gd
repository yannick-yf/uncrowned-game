class_name JournalBook
extends Control

## **The journal, laid out as a notebook** (D20, the audit's 21). It was a dark sheet over the
## whole screen with one crowded header — the name, the clock, the page's name, its number
## and the keys in one line — and the page's lines under it, so an empty page was one line on
## a black screen. Now: a tab for each page down the left, the page open beside them with its
## title and a rule under it, the keys at its foot as caps, and an empty page that says so in
## the middle of the page rather than in its corner.
##
## `main` keeps building the pages — what they say and how much of each fits — and hands
## them over; this decides only how they look. The lines are cut to `BODY` by `main`.

## The notebook, the tabs' column, and the page's body, in the HUD's 640 × 360.
const BOOK: Rect2 = Rect2(16.0, 12.0, 608.0, 336.0)
const TABS_WIDTH: float = 158.0
const BODY: Rect2 = Rect2(190.0, 62.0, 418.0, 262.0)
const TAB_TOP: float = 74.0
const TAB_STEP: float = 24.0
const LINE: float = 17.0
## Where a row's figures end, from the body's left: the name's column is this wide.
const FIGURES: float = 300.0
const PAGE_FILL: Color = Color(0.105, 0.098, 0.112, 0.97)
const SPINE: Color = Color(0.050, 0.046, 0.058, 0.97)

var _tabs: PackedStringArray = PackedStringArray()
var _at: int = 0
var _title: String = ""
var _lines: PackedStringArray = PackedStringArray()
var _header: String = ""
var _welcome: String = ""
var _empty: String = ""
var _keys: Array[Array] = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## A page to show. `tabs` names every page, `at` is the one open; `empty` is the page's
## line when it has nothing to say, drawn in the middle with `welcome` above it, if any;
## `keys` are pairs of a key and what it does, for the foot of the page.
func present(tabs: PackedStringArray, at: int, title: String, lines: PackedStringArray, header: String,
		empty: String, welcome: String, keys: Array[Array]) -> void:
	_tabs = tabs
	_at = at
	_title = title
	_lines = lines
	_header = header
	_empty = empty
	_welcome = welcome
	_keys = keys
	queue_redraw()


## A page's name as a heading: its capitals in sentence case — « CE QUI LE TIENT DEBOUT »
## is « Ce qui le tient debout » — and the debug mark kept as it is.
static func heading(name: String) -> String:
	var plain: String = name.strip_edges()
	if plain.is_empty():
		return plain
	var lower: String = plain.to_lower()
	return lower.left(1).to_upper() + lower.substr(1)


## Whether a line heads a section of its page: not a row of a list, and ending on a colon
## or written in capitals.
static func is_section(line: String) -> bool:
	var plain: String = line.strip_edges()
	if plain.is_empty() or plain.begins_with("-") or plain.begins_with("("):
		return false
	return plain.ends_with(":") or (plain == plain.to_upper() and plain != plain.to_lower())


## The tab a page sits under, for the suite: its rectangle in the tabs' column.
static func tab_rect(index: int) -> Rect2:
	return Rect2(Vector2(BOOK.position.x + 6.0, TAB_TOP + float(index) * TAB_STEP - 15.0),
		Vector2(TABS_WIDTH - 6.0, TAB_STEP - 4.0))


## How many lines the body holds, for `main` and the suite.
static func lines_held() -> int:
	return floori(BODY.size.y / LINE)


func _draw() -> void:
	if _tabs.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.55), true)
	# The cover and the spine: the tabs sit on the darker part, the page is the lighter.
	Ui.panel(self, BOOK, SPINE)
	var page := Rect2(Vector2(BOOK.position.x + TABS_WIDTH, BOOK.position.y), Vector2(BOOK.size.x - TABS_WIDTH, BOOK.size.y))
	draw_rect(page.grow(-1.0), PAGE_FILL, true)
	draw_line(Vector2(page.position.x, page.position.y + 1.0), Vector2(page.position.x, page.end.y - 1.0), Ui.EDGE, 1.0)
	_draw_tabs(page)
	_draw_page(page)


func _draw_tabs(page: Rect2) -> void:
	Ui.write(self, Vector2(BOOK.position.x + 12.0, BOOK.position.y + 24.0), Text.of(&"journal.book"), Ui.ROW, Ui.INK)
	Ui.write(self, Vector2(BOOK.position.x + 12.0, BOOK.position.y + 40.0), _header, Ui.NOTE, Ui.FAINT)
	draw_line(Vector2(BOOK.position.x + 12.0, BOOK.position.y + 48.0), Vector2(page.position.x - 12.0, BOOK.position.y + 48.0),
		Color(Ui.GOLD, 0.25), 1.0)
	for index: int in _tabs.size():
		var tab: Rect2 = tab_rect(index)
		var open: bool = index == _at
		if open:
			# The open tab is cut from the page: the page's colour, joined to it.
			draw_rect(Rect2(tab.position, Vector2(page.position.x - tab.position.x + 1.0, tab.size.y)), PAGE_FILL, true)
			draw_rect(Rect2(tab.position, Vector2(2.0, tab.size.y)), Ui.GOLD, true)
		Ui.write(self, Vector2(tab.position.x + 10.0, tab.position.y + 15.0), _tabs[index], Ui.ROW,
			Ui.GOLD if open else Ui.DIM)


func _draw_page(page: Rect2) -> void:
	var left: float = BODY.position.x
	Ui.write(self, Vector2(left, page.position.y + 32.0), _title, Ui.HEADING, Ui.GOLD)
	draw_line(Vector2(left, page.position.y + 41.0), Vector2(BODY.end.x, page.position.y + 41.0), Color(Ui.GOLD, 0.35), 1.0)
	Ui.write(self, Vector2(left, page.position.y + 32.0), "%d / %d" % [_at + 1, _tabs.size()], Ui.NOTE, Ui.FAINT,
		HORIZONTAL_ALIGNMENT_RIGHT, BODY.size.x)
	if _empty != "":
		_draw_empty()
	else:
		var y: float = BODY.position.y + 12.0
		for line: String in _lines:
			if line.strip_edges().is_empty():
				y += LINE
				continue
			# A section's own heading — "Blackcairn :", "QUI TIENT QUOI" — in the page's
			# second colour, so a page reads as its parts.
			var colour: Color = Ui.SAGE if is_section(line) else Ui.INK
			if line.contains("\t"):
				_draw_cells(line.split("\t"), y)
				y += LINE
				continue
			for row: String in Ui.wrapped(line, Ui.BODY, BODY.size.x):
				Ui.write(self, Vector2(left, y), row, Ui.BODY, colour)
				y += LINE
	_draw_keys(page)


## A row of columns: the name, its figure ending at `FIGURES`, and a note after it in gold.
func _draw_cells(cells: PackedStringArray, y: float) -> void:
	var left: float = BODY.position.x
	Ui.write(self, Vector2(left, y), cells[0], Ui.BODY, Ui.INK)
	if cells.size() > 1:
		Ui.write(self, Vector2(left, y), cells[1], Ui.BODY, Ui.INK, HORIZONTAL_ALIGNMENT_RIGHT, FIGURES)
	if cells.size() > 2 and cells[2] != "":
		Ui.write(self, Vector2(left + FIGURES + 12.0, y), cells[2], Ui.BODY, Ui.GOLD)


## An empty page: its welcome, a mark, and what it has not got yet, in the middle of it.
func _draw_empty() -> void:
	var middle: float = BODY.get_center().y - 20.0
	var y: float = middle
	if _welcome != "":
		for row: String in Ui.wrapped(_welcome, Ui.BODY, BODY.size.x * 0.68):
			Ui.write(self, Vector2(BODY.position.x, y), row, Ui.BODY, Ui.SAGE, HORIZONTAL_ALIGNMENT_CENTER, BODY.size.x)
			y += LINE
		y += 6.0
	var mark: Vector2 = Vector2(BODY.get_center().x, y - 5.0)
	draw_line(mark - Vector2(30.0, 0.0), mark - Vector2(6.0, 0.0), Color(Ui.GOLD, 0.45), 1.0)
	draw_line(mark + Vector2(6.0, 0.0), mark + Vector2(30.0, 0.0), Color(Ui.GOLD, 0.45), 1.0)
	draw_colored_polygon(PackedVector2Array([mark + Vector2(0, -3), mark + Vector2(3, 0), mark + Vector2(0, 3),
		mark + Vector2(-3, 0)]), Color(Ui.GOLD, 0.7))
	y += 14.0
	for row: String in Ui.wrapped(_empty, Ui.BODY, BODY.size.x - 40.0):
		Ui.write(self, Vector2(BODY.position.x, y), row, Ui.BODY, Ui.DIM, HORIZONTAL_ALIGNMENT_CENTER, BODY.size.x)
		y += LINE


## The keys at the foot of the page, each a cap and what it does.
func _draw_keys(page: Rect2) -> void:
	var y: float = page.end.y - 10.0
	var x: float = BODY.position.x
	for pair: Array in _keys:
		for key: String in (pair[0] as String).split(" ", false):
			var cap := Rect2(Vector2(x, y - 11.0), Vector2(maxf(14.0, Ui.width_of(key, Ui.NOTE) + 6.0), 14.0))
			draw_rect(cap, Color(0.05, 0.05, 0.06, 0.9), true)
			draw_rect(cap, Color(Ui.GOLD, 0.8), false, 1.0)
			Ui.write(self, Vector2(cap.position.x, y), key, Ui.NOTE, Ui.GOLD, HORIZONTAL_ALIGNMENT_CENTER, cap.size.x)
			x = cap.end.x + 3.0
		x += 3.0
		Ui.write(self, Vector2(x, y), pair[1] as String, Ui.NOTE, Ui.DIM)
		x += Ui.width_of(pair[1] as String, Ui.NOTE) + 16.0
