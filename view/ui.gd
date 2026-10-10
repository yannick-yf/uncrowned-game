class_name Ui
extends RefCounted

## What every screen in the game is made of: one font, one palette, one panel.
##
## The reason this is a file rather than a habit: before it, the dialogue box was a
## charcoal `ColorRect` in `main.tscn`, the journal was a slightly different charcoal
## in the same file, and the map screen invented a third in code. Three places to
## change and no way to tell they were meant to match. A new screen now starts by
## reading this and matches the rest of the game for free.
##
## **The font is Pixel Operator** (Jayvee Enaguas, CC0 — `view/fonts/pixel_operator/`,
## its licence beside it), chosen in D1 (2026-10-09). The 2D pack's own face read its
## lowercase *i* as a dot — *ce qui v.t dans le bo.s* — and Yannick asked for a font
## that looks clean and finished, free-licensed or made. Pixelify Sans was tried first
## and refused, its *B* reading as *G* and its *5* as *S*; Pixel Operator's 8-pixel cut
## was refused next, its accented capitals squeezed to the height of an *E*, so *Écouter*
## read *écouter*. This, the 16-pixel cut, sets every glyph on a grid of sixteen to the
## em: drawn sharp at every size that is a multiple of eight (the window doubles the
## 640×360 canvas, so eight is one pixel of the font to one of the screen), and it
## carries every character the French text uses but one, listed below.
const FONT: String = "res://view/font.tres"
## The face itself, and the licence that travels with it (CC0).
const SOURCE_FONT: String = "res://view/fonts/pixel_operator/PixelOperator.ttf"
const FONT_LICENCE: String = "res://view/fonts/pixel_operator/LICENSE.txt"
## The font's grid: a size is sharp when it is a multiple of this.
const FONT_GRID: int = 8

## The characters the font has no glyph for. Godot falls back to a system font for
## these, which renders them in the wrong typeface — visible immediately as one grey
## character in a line of cream ones. A test walks the shipped text and fails on any.
const NOT_IN_THE_FONT: String = "§"

## Sizes, all multiples of eight so every one is sharp (D1). Pixel fonts want few sizes:
## the three smallest are one size now, and the hierarchy between them is the palette's
## — gold, ink, dim — rather than a pixel of height the font cannot draw cleanly.
const HUGE: int = 40
const LARGE: int = 24
const HEADING: int = 24
const ROW: int = 16
const BODY: int = 16
const NOTE: int = 16

## The palette, lifted from the boxes that were already on screen so nothing shifts.
const INK: Color = Color(0.94, 0.93, 0.88)
const DIM: Color = Color(0.62, 0.61, 0.57)
const FAINT: Color = Color(0.45, 0.44, 0.41)
const GOLD: Color = Color(1.0, 0.847, 0.443)
const SAGE: Color = Color(0.694, 0.851, 0.804)
const EMBER: Color = Color(1.0, 0.42, 0.28)
const NIGHT: Color = Color(0.055, 0.052, 0.070)
const PANEL: Color = Color(0.078, 0.071, 0.086, 0.92)
const EDGE: Color = Color(0.75, 0.70, 0.55, 0.55)
const SHADOW: Color = Color(0.0, 0.0, 0.0, 0.65)

static var _font: Font = null


## Loaded once and kept. Godot's resource cache would hand back the same object
## anyway; the point of the accessor is that there is one name for the question.
static func font() -> Font:
	if _font == null:
		_font = load(FONT) as Font
	return _font


## The first character in a line the font cannot draw, or "". A line rather than a
## character at a time, because the caller always wants to name the offender.
static func missing_glyph(line: String) -> String:
	for glyph: String in NOT_IN_THE_FONT:
		if line.contains(glyph):
			return glyph
	return ""


static func width_of(line: String, size: int) -> float:
	return font().get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x


## Text at a baseline. Every screen draws through here so a change of font or of
## default colour is one edit.
## **A line broken into rows no wider than `width`**, at the spaces (T8): the lesson's card
## carried a sentence of Bram's that ran off the right of the screen. A word longer than
## the width keeps its own row rather than being cut.
static func wrapped(line: String, size: int, width: float) -> PackedStringArray:
	# A line that fits is kept as it was written, its spaces and all (D20: the journal's
	# columns were padded with spaces, and rejoining the words took them away).
	if line != "" and width_of(line, size) <= width:
		return PackedStringArray([line])
	var rows := PackedStringArray()
	var row: String = ""
	for word: String in line.split(" ", false):
		var longer: String = word if row == "" else row + " " + word
		if row != "" and width_of(longer, size) > width:
			rows.append(row)
			row = word
		else:
			row = longer
	if row != "":
		rows.append(row)
	return rows


static func write(canvas: CanvasItem, at: Vector2, line: String, size: int,
		colour: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		width: float = -1.0) -> void:
	canvas.draw_string(font(), at, line, align, width, size, colour)


## Text with a hard shadow under it, for anything drawn over the world rather than
## over a panel — a cream word on a pale sky is unreadable without one.
static func write_over(canvas: CanvasItem, at: Vector2, line: String, size: int,
		colour: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
		width: float = -1.0) -> void:
	canvas.draw_string(font(), at + Vector2(1.0, 1.0), line, align, width, size, SHADOW)
	canvas.draw_string(font(), at, line, align, width, size, colour)


## **A health bar, the one style in the game** (D2, D5): a dark frame, a dark well, the
## fill coloured from green through gold to ember as it empties, a lighter top row of
## pixels for a bevel, and — when `ghost` is above `fraction` — the part a blow has just
## taken, pale, draining. The HUD and every bar of a fight draw through here.
const BAR_FULL: Color = Color(0.47, 0.74, 0.36)
const BAR_HALF: Color = Color(0.93, 0.74, 0.30)
const BAR_LOW: Color = Color(0.86, 0.30, 0.24)


static func bar_colour(fraction: float) -> Color:
	if fraction >= 0.5:
		return BAR_HALF.lerp(BAR_FULL, (fraction - 0.5) * 2.0)
	return BAR_LOW.lerp(BAR_HALF, maxf(fraction, 0.0) * 2.0)


## `segments` above zero cuts the well into that many notches, so a small health can still be
## counted (a wolf's ten); `mirrored` anchors what is left at the right end, so a foe's bar on
## the right of the screen drains toward the middle as the player's does; `alpha` fades the
## whole of it with the fight's HUD.
static func bar(canvas: CanvasItem, rect: Rect2, fraction: float, ghost: float = -1.0,
		segments: int = 0, mirrored: bool = false, alpha: float = 1.0) -> void:
	var inner := rect.grow(-1.0)
	canvas.draw_rect(rect, Color(0.02, 0.02, 0.03, 0.95 * alpha), true)
	canvas.draw_rect(inner, Color(0.16, 0.15, 0.17, 0.95 * alpha), true)
	var full: float = clampf(fraction, 0.0, 1.0)
	var span: Callable = func(from: float, to: float) -> Rect2:
		var a: float = (1.0 - to) if mirrored else from
		return Rect2(inner.position + Vector2(inner.size.x * a, 0.0), Vector2(inner.size.x * (to - from), inner.size.y))
	if ghost > full:
		canvas.draw_rect(span.call(full, clampf(ghost, 0.0, 1.0)), Color(0.96, 0.92, 0.80, 0.75 * alpha), true)
	if full > 0.0:
		var fill: Color = bar_colour(full)
		fill.a = alpha
		var lit: Rect2 = span.call(0.0, full)
		canvas.draw_rect(lit, fill, true)
		var top_row: Color = fill.lightened(0.35)
		top_row.a = alpha
		canvas.draw_rect(Rect2(lit.position, Vector2(lit.size.x, 1.0)), top_row, true)
	for notch: int in range(1, segments):
		var x: float = inner.position.x + inner.size.x * float(notch) / float(segments)
		canvas.draw_rect(Rect2(Vector2(floorf(x), inner.position.y), Vector2(1.0, inner.size.y)),
			Color(0.02, 0.02, 0.03, 0.85 * alpha), true)
	var edge: Color = EDGE
	edge.a *= alpha
	canvas.draw_rect(rect, edge, false, 1.0)


## A box to put words in: filled, with a hairline edge.
static func panel(canvas: CanvasItem, rect: Rect2, fill: Color = PANEL) -> void:
	canvas.draw_rect(rect, fill, true)
	canvas.draw_rect(rect, EDGE, false, 1.0)


## The night behind a menu, as horizontal bands rather than a flat fill.
##
## A gradient is the cheapest thing that stops a screen looking like a debug overlay,
## and bands are the cheapest gradient: no shader, no texture, no import step.
static func sky(canvas: CanvasItem, rect: Rect2, top: Color, bottom: Color,
		bands: int = 36) -> void:
	var height: float = rect.size.y / float(bands)
	for band: int in bands:
		var through: float = float(band) / float(maxi(bands - 1, 1))
		canvas.draw_rect(Rect2(rect.position + Vector2(0.0, float(band) * height),
			Vector2(rect.size.x, ceilf(height))), top.lerp(bottom, through), true)


## The cursor beside the row a menu is sitting on. A triangle rather than the pack's
## arrow sprite, because it has to point at text drawn at six different sizes and a
## 13-pixel bitmap only looks right at one of them.
static func caret(canvas: CanvasItem, at: Vector2, size: float,
		colour: Color = GOLD) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([
		at + Vector2(0.0, -size * 0.5),
		at + Vector2(size * 0.8, 0.0),
		at + Vector2(0.0, size * 0.5),
	]), colour)
