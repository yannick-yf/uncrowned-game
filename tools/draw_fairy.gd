extends SceneTree

## Builds `view3d/fairy/fairy_sheet.png`: **the fairy, a light with a shape** (D17, the
## audit's 18). She was a pale green blur — the first person of the game, and no shape at
## all. Now she is a small figure in his manner: a pale head under long hair, a dress that
## thins to a wisp where legs would be, and two pairs of wings, in four frames of one beat.
## The window keeps her light and her glow round her, and a few motes that twinkle.
##
## **How it stays his** (`CLAUDE.md`, *Art rule*): his dark outline (`INK`, three pixels, as
## `tools/draw_cast_looks.gd` draws it), his light from the top left, a painted grain that is
## a hash of the pixel's place, alpha all or nothing, and every colour one his shader keeps
## (`safe`: a bright colour carries some saturation). Drawn at the density of his figures
## (`World3d.HIS_FIGURE_PIXEL_SIZE`), so she is a third of a man's height and as fine.
## A grown woman's proportions, not a child's: the head a fifth of her, the body slender
## (invariant 10).
##
##     godot --headless --path . -s tools/draw_fairy.gd
##
## Re-runnable and deterministic: nothing random.

const OUT: String = "res://view3d/fairy/fairy_sheet.png"
const CELL: int = 128
const FRAMES: int = 4
const INK: Color = Color8(22, 14, 14)
const OUTLINE: int = 3
## The wings' lift and their foreshortening through one beat: up, level, down, level.
const LIFT: Array[float] = [34.0, 14.0, -6.0, 14.0]
const SPAN: Array[float] = [1.0, 0.86, 0.72, 0.86]

## Hue, saturation, value of each part.
const WING: Vector3 = Vector3(168.0, 0.30, 0.94)
const VEIN: Vector3 = Vector3(172.0, 0.42, 0.72)
const DRESS: Vector3 = Vector3(128.0, 0.34, 0.90)
const SKIN: Vector3 = Vector3(40.0, 0.24, 0.98)
const HAIR: Vector3 = Vector3(48.0, 0.46, 0.96)

const CENTRE_X: float = 64.0
const HEAD: Vector2 = Vector2(64.0, 34.0)
const HEAD_R: float = 12.5


func _initialize() -> void:
	var sheet := Image.create(CELL * FRAMES, CELL, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for frame: int in FRAMES:
		var cell := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
		cell.fill(Color(0, 0, 0, 0))
		_paint(cell, frame)
		sheet.blit_rect(cell, Rect2i(0, 0, CELL, CELL), Vector2i(frame * CELL, 0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://view3d/fairy/"))
	var error: Error = sheet.save_png(ProjectSettings.globalize_path(OUT))
	print("fairy: %d frames of %d px -> %s (%s)" % [FRAMES, CELL, OUT, error_string(error)])
	quit(0 if error == OK else 1)


## One frame, back to front: the far wings, the near wings, the dress, the head, the hair.
## Each part outlined against whatever is not itself, as his parts are.
func _paint(cell: Image, frame: int) -> void:
	var lift: float = LIFT[frame]
	var span: float = SPAN[frame]
	for side: float in [-1.0, 1.0]:
		var lower: Callable = _wing(Vector2(CENTRE_X + side * 15.0, 66.0), Vector2(15.0 * span, 7.5),
			side * (-22.0 + lift * 0.4))
		_layer(cell, lower, _wing_colour(Vector2(CENTRE_X, 60.0), 21))
	for side: float in [-1.0, 1.0]:
		var upper: Callable = _wing(Vector2(CENTRE_X + side * 25.0 * span, 44.0 - lift * 0.18), Vector2(25.0 * span, 12.5),
			side * (28.0 + lift))
		_layer(cell, upper, _wing_colour(Vector2(CENTRE_X, 50.0), 22))
	_layer(cell, _dress, _shade(DRESS, Rect2(48.0, 44.0, 32.0, 68.0), 31, 0.30))
	_layer(cell, _head, _shade(SKIN, Rect2(HEAD - Vector2(HEAD_R, HEAD_R), Vector2(HEAD_R, HEAD_R) * 2.0), 41, 0.16))
	_eyes(cell)
	_layer(cell, _hair, _shade(HAIR, Rect2(50.0, 20.0, 34.0, 50.0), 51, 0.32))


## A wing: an ellipse turned about its root, with a vein down its length.
func _wing(centre: Vector2, radii: Vector2, degrees: float) -> Callable:
	var turn: float = deg_to_rad(degrees)
	return func(x: int, y: int) -> bool:
		var d: Vector2 = (Vector2(x, y) - centre).rotated(-turn)
		return (d.x * d.x) / (radii.x * radii.x) + (d.y * d.y) / (radii.y * radii.y) <= 1.0


## Paler toward the tip, a darker vein from the root; the light still from the top left.
func _wing_colour(root: Vector2, seed: int) -> Callable:
	return func(x: int, y: int) -> Color:
		var away: float = clampf(Vector2(x, y).distance_to(root) / 34.0, 0.0, 1.0)
		var light: float = 1.0 - 0.35 * (x / float(CELL)) - 0.35 * (y / float(CELL))
		var grain: float = (_noise(x / 2, y / 2, seed) - 0.5) * 0.05
		# A vein every few pixels round the root: rings of the wing's own darker hue.
		var ring: float = fposmod(Vector2(x, y).distance_to(root), 9.0)
		if ring < 1.0 and away > 0.25:
			return _safe(VEIN.x, VEIN.y, VEIN.z + grain)
		return _safe(WING.x, WING.y - 0.08 * away, WING.z - 0.10 + 0.10 * away + 0.12 * (light - 0.5) + grain)


## The dress: narrow at the shoulders, a waist, a skirt that widens and then thins to a wisp
## that drifts to one side, where a body would have legs.
func _dress(x: int, y: int) -> bool:
	var fy: float = float(y)
	if fy < 44.0 or fy > 112.0:
		return false
	var half: float
	var sway: float = 0.0
	if fy < 52.0:
		half = lerpf(5.0, 9.0, (fy - 44.0) / 8.0)
	elif fy < 60.0:
		half = lerpf(9.0, 6.5, (fy - 52.0) / 8.0)
	elif fy < 84.0:
		half = lerpf(6.5, 12.0, (fy - 60.0) / 24.0)
	else:
		var t: float = (fy - 84.0) / 28.0
		half = lerpf(12.0, 0.5, pow(t, 0.8))
		sway = -7.0 * sin(t * PI * 0.5)
	return absf(float(x) - (CENTRE_X + sway)) <= half


func _head(x: int, y: int) -> bool:
	return Vector2(x, y).distance_to(HEAD) <= HEAD_R


## Long hair: a fringe over the brow, a curtain each side of the face to the shoulders, and
## a lock that falls behind the right shoulder to the waist.
func _hair(x: int, y: int) -> bool:
	var p := Vector2(x, y)
	var fx: float = float(x) - HEAD.x
	var fy: float = float(y)
	var round_head: bool = p.distance_to(HEAD + Vector2(0.0, -1.0)) <= HEAD_R + 2.5
	var fringe: bool = round_head and fy <= HEAD.y - 3.0 + 1.5 * absf(sin(float(x) * 0.45))
	var curtain: bool = absf(fx) >= HEAD_R - 6.0 and absf(fx) <= HEAD_R + 3.0 and fy >= HEAD.y - 8.0 \
		and fy <= HEAD.y + 14.0 - 4.0 * signf(-fx) and (round_head or fy > HEAD.y)
	var lock: bool = false
	if fy > HEAD.y + 4.0 and fy < 70.0:
		var t: float = (fy - (HEAD.y + 4.0)) / (70.0 - (HEAD.y + 4.0))
		var cx: float = HEAD.x + HEAD_R + 1.0 + 4.0 * sin(t * PI * 0.9)
		lock = absf(float(x) - cx) <= lerpf(3.5, 1.0, t)
	return fringe or curtain or lock


## His eyes: two dark upright marks.
func _eyes(cell: Image) -> void:
	for eye: float in [-5.0, 3.0]:
		for dy: int in 4:
			for dx: int in 2:
				cell.set_pixel(int(HEAD.x + eye) + dx, int(HEAD.y + 1.0) + dy, INK)


## A part painted with his outline round it: a pixel of the part within `OUTLINE` of any
## pixel that is not the part is ink.
func _layer(cell: Image, inside: Callable, colour_at: Callable) -> void:
	var ring: Array[Vector2i] = []
	for dy: int in range(-OUTLINE, OUTLINE + 1):
		for dx: int in range(-OUTLINE, OUTLINE + 1):
			if (dx != 0 or dy != 0) and dx * dx + dy * dy <= OUTLINE * OUTLINE:
				ring.append(Vector2i(dx, dy))
	for y: int in CELL:
		for x: int in CELL:
			if not inside.call(x, y):
				continue
			var edge: bool = false
			for d: Vector2i in ring:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x < 0 or q.y < 0 or q.x >= CELL or q.y >= CELL or not inside.call(q.x, q.y):
					edge = true
					break
			cell.set_pixel(x, y, INK if edge else colour_at.call(x, y) as Color)


## His light: from the top left, soft, with a painted grain.
func _shade(c: Vector3, box: Rect2, seed: int, spread: float) -> Callable:
	return func(x: int, y: int) -> Color:
		var u: float = (x - box.position.x) / maxf(box.size.x, 1.0)
		var w: float = (y - box.position.y) / maxf(box.size.y, 1.0)
		var light: float = 1.0 - 0.55 * u - 0.45 * w
		var grain: float = (_noise(x / 2, y / 2, seed) - 0.5) * 0.05
		return _safe(c.x, c.y, c.z + spread * (light - 0.5) + grain)


## A colour his shader keeps: a bright one must carry some saturation.
static func _safe(h: float, s: float, v: float) -> Color:
	if v > 0.35 and s < 0.24:
		s = 0.24
	return Color.from_hsv(fposmod(h, 360.0) / 360.0, clampf(s, 0.0, 1.0), clampf(v, 0.0, 1.0))


static func _noise(x: int, y: int, seed: int) -> float:
	var n: int = (x * 73856093) ^ (y * 19349663) ^ (seed * 83492791)
	return float((n >> 3) % 1000) / 1000.0
