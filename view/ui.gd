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
## **The font is the pack's own** (`Ui/Font/NormalFont.ttf`), not Godot's fallback
## sans. §13's rule is one pack and never a mix, and the pack that drew the tiles also
## drew a typeface for them — using anything else is exactly the mismatch the rule
## exists to prevent. It carries the accented Latin the French text needs; what it
## lacks is listed below and a test refuses to let a line use one.

const PACK: String = Art.PACK
## The face itself, straight out of the pack and never edited — CC0 allows editing it
## and the pack stays pristine anyway, so a reader can diff it against the download.
const SOURCE_FONT: String = "%s/Ui/Font/NormalFont.ttf" % PACK
## What the game actually draws with: the same face with its word space widened.
##
## The pack's space is one pixel at nine and four at forty, roughly a tenth of an em
## where a quarter is normal, so words ran together — "Nouvellepartie", "Langue:FR".
## Godot's `spacing_space` is in whole pixels and does not scale with the size, which
## sounds like it would need one resource per size and does not: the only text in the
## game above twenty pixels is the word UNCROWNED, and it has no space in it.
const FONT: String = "res://view/font.tres"

## The characters the pack's font has no glyph for. Godot falls back to a system font
## for these, which renders them in the wrong typeface at the wrong weight — visible
## immediately as one grey character in a line of cream ones. Kept here because a
## test walks the shipped text and fails on any of them, which is the only way this
## stays true as lines are written.
const NOT_IN_THE_FONT: String = "ÎŒœ«»…—·•"

## Sizes. Pixel fonts want whole numbers and few of them; six sizes across the whole
## game is a constraint worth keeping, because the seventh is always someone nudging
## one screen and leaving the rest behind.
const HUGE: int = 40
const LARGE: int = 20
const HEADING: int = 13
const ROW: int = 11
const BODY: int = 10
const NOTE: int = 9

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
