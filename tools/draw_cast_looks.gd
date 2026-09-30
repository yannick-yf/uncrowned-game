extends SceneTree

## Builds `view3d/cast/<look>.png`: his traveller, dressed as each kind of person the demo
## shows — the king's guards, the watch, the works' guards and archers, the ironworks'
## workers, the villagers, Bram and Wren.
##
## **Why** (Yannick, 2026-09-30): *« Pour l'instant tous les personnages se ressemblent. Il
## faut que chaque type de personnage se reconnaisse du premier coup d'œil. »* His brother
## has drawn one person, and until he draws the cast every man in the game is that man —
## six of him in one fight. He chose every look below from a board (`docs/frames/cast/`),
## and on the same day widened the art rule: we may draw what the game needs, in 2D and in
## 3D, **as long as it is coherent with his hand** (`CLAUDE.md`, *Art rule*).
##
## **How it stays coherent.** A look is his figure first and ours second:
##
## - **Recoloured, not repainted.** Each region of his figure — hair, shirt, trousers,
##   leather, skin — is moved to another hue with the values of his brush scaled rather
##   than replaced, so the shape of his shading, his outline and his grain stay his.
## - **Pieces drawn in his manner.** What he never drew — a helm, a cap, a hood, a hat,
##   an apron, a beard, a sword, a bow — is painted over him with his dark outline, his
##   light from the top left and a painted grain, never a flat fill.
## - **Measured on each frame.** Every piece is placed from what the frame itself shows —
##   where the neck is, how wide the hair, where the face and the hands are — so the same
##   recipe follows his walk cycle and our fight frames without a table of positions.
##   Our sixteen fight cells are his idle frames with an arm moved, so they are measured
##   on that idle frame and only their hands are looked for again.
## - **Kept by his shader.** His `traveler_sprite.gdshader` throws away any pixel that is
##   bright and grey (that is how his chequered background disappears). Every colour here
##   is checked against the same rule (`safe`), so no piece of steel or linen vanishes.
##
## **What it reads and writes.** It reads `view3d/fight/traveler_sheet.png` — his sheet
## with our fight frames below it — his `SpriteFrames` for where each of his frames is, and
## the recipes in `content/looks.json`. It writes one sheet per look, the same size and the
## same layout as that one, so the window can hand a look's sheet to his shader and every
## frame still lands where it did. Around each of his frames it keeps `room_px` of room on
## top and at the sides for what stands out of a man's outline — a plume, a bow — and the
## window widens those frames by the same amount (`CastLooks.frames_for`).
## Everything outside a frame is transparent.
##
##     godot --headless --path . -s tools/draw_cast_looks.gd
##     godot --headless --path . -s tools/draw_cast_looks.gd -- --board
##     godot --headless --path . -s tools/draw_cast_looks.gd -- --only bram
##
## A full run also writes `view3d/cast/recipes_drawn.json`, the recipes the sheets were
## drawn from; `test_cast_looks` fails when `content/looks.json` has moved on without them.
##
## `--board` also writes `docs/frames/cast/looks.png`: every look standing in three
## facings, close up and at the size the game shows it, with his shader's discard applied.
##
## Re-runnable and deterministic: the same sheet and the same recipes in, the same looks
## out. Nothing random — the painted grain is a hash of the pixel's place.

const BASE_SHEET: String = "view3d/fight/traveler_sheet.png"
const BOARD_PNG: String = "docs/frames/cast/looks.png"

enum K { NONE, INK, SHIRT, SKIN, HAIR, TROUSERS, LEATHER, OTHER, PIECE }
const REGIONS: Dictionary = {
	"shirt": K.SHIRT, "skin": K.SKIN, "hair": K.HAIR, "trousers": K.TROUSERS, "leather": K.LEATHER,
}

## His outline black, as dark as his own line is.
const INK: Color = Color8(22, 14, 14)
const CLEAR: Color = Color(0, 0, 0, 0)

## The colours the pieces are made of. Hue in degrees, saturation, value.
const STEEL: Vector3 = Vector3(212, 0.26, 0.62)
## Blackened steel: dark enough that his shader keeps it grey.
const IRON: Vector3 = Vector3(218, 0.14, 0.34)
const KING_RED: Vector3 = Vector3(356, 0.78, 0.52)
const GOLD: Vector3 = Vector3(44, 0.80, 0.86)


## One of his frames, cut into what it is made of.
class Fig:
	var img: Image
	var way: StringName
	var w: int
	var h: int
	var kind: PackedByteArray
	var top: int = 0
	var bottom: int = 0
	var neck: int = 0
	## Boxes are inclusive: x0, y0, x1, y1.
	var head: Vector4i
	var face: Vector4i
	var has_face: bool = false
	var shirt: Vector4i
	var legs: Vector4i
	var has_legs: bool = false
	var hands: Array[Vector2i] = []
	var hand: PackedByteArray
	## In one of our cells: what the cell has that its idle frame had not — the arm moved.
	var moved: PackedByteArray
	var pack: PackedByteArray
	var lo: PackedInt32Array
	var hi: PackedInt32Array

	func _init(image: Image, facing: StringName) -> void:
		img = image
		way = facing
		w = image.get_width()
		h = image.get_height()
		kind = PackedByteArray()
		kind.resize(w * h)
		pack = PackedByteArray()
		pack.resize(w * h)
		hand = PackedByteArray()
		hand.resize(w * h)
		moved = PackedByteArray()
		moved.resize(w * h)

	func at(x: int, y: int) -> int:
		if x < 0 or y < 0 or x >= w or y >= h:
			return 0
		return kind[y * w + x]

	func set_kind(x: int, y: int, k: int) -> void:
		if x >= 0 and y >= 0 and x < w and y < h:
			kind[y * w + x] = k

	func has(x: int, y: int) -> bool:
		return at(x, y) != 0

	func is_hand(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h and hand[y * w + x] == 1

	func colour(x: int, y: int) -> Color:
		return img.get_pixel(x, y)

	func put(x: int, y: int, c: Color) -> void:
		if x >= 0 and y >= 0 and x < w and y < h:
			img.set_pixel(x, y, c)

	func is_moved(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h and moved[y * w + x] == 1

	func in_pack(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h and pack[y * w + x] == 1

	## Inside his silhouette on this row, holes included.
	func row_has(x: int, y: int) -> bool:
		if y < 0 or y >= h:
			return false
		return lo[y] <= x and x <= hi[y]

	func rebuild_rows() -> void:
		lo = PackedInt32Array()
		hi = PackedInt32Array()
		lo.resize(h)
		hi.resize(h)
		for y: int in h:
			lo[y] = w
			hi[y] = -1
			for x: int in w:
				if kind[y * w + x] != 0:
					lo[y] = mini(lo[y], x)
					hi[y] = maxi(hi[y], x)


var _looks: Dictionary = {}
var _room: int = 8


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var board: bool = args.has("--board")
	var only: String = ""
	var at_only: int = args.find("--only")
	if at_only >= 0 and at_only + 1 < args.size():
		only = args[at_only + 1]
	var sheet: Image = Image.load_from_file(BASE_SHEET)
	if sheet == null:
		push_error("the sheet is not there: %s — run tools/draw_fight_frames.gd" % BASE_SHEET)
		quit(1)
		return
	sheet.convert(Image.FORMAT_RGBA8)
	var frames: SpriteFrames = load(World3d.HIS_FRAMES) as SpriteFrames
	if frames == null:
		push_error("his SpriteFrames is not there: %s — run tools/vendor_workshop.sh" % World3d.HIS_FRAMES)
		quit(1)
		return
	_looks = CastLooks.looks()
	_room = CastLooks.room_px()
	var his: Array[Dictionary] = _his_frames(frames)
	if not _rooms_apart(his):
		quit(1)
		return
	var ours: Array[Dictionary] = _our_cells(sheet, frames)
	DirAccess.make_dir_recursive_absolute(CastLooks.DIR)
	var dressed: Dictionary = {}
	for look: String in _looks.keys():
		if only != "" and look != only:
			continue
		var out: Image = Image.create(sheet.get_width(), sheet.get_height(), false, Image.FORMAT_RGBA8)
		out.fill(CLEAR)
		var recipe: Dictionary = _looks[look] as Dictionary
		for frame: Dictionary in his:
			_dress_his(sheet, out, frame, recipe)
		for cell: Dictionary in ours:
			_dress_ours(sheet, out, cell, recipe)
		var path: String = CastLooks.sheet_path(StringName(look))
		if out.save_png(path) != OK:
			push_error("could not write %s" % path)
			quit(1)
			return
		dressed[look] = out
		print("wrote %s" % path)
	if only == "":
		# **What the sheets were drawn from**, so the suite can tell a recipe edited in
		# `content/looks.json` from a sheet rebuilt after it (the review of group L).
		var made := FileAccess.open(CastLooks.RECIPES_DRAWN, FileAccess.WRITE)
		made.store_string(JSON.stringify({"room_px": _room, "looks": _looks}, "  ", true) + "\n")
		made.close()
		print("wrote %s" % CastLooks.RECIPES_DRAWN)
	if board:
		_board(dressed, frames)
	quit(0)


# ------------------------------------------------------------------- the frames ---

## His frames, once each, with the facing their animation names.
func _his_frames(frames: SpriteFrames) -> Array[Dictionary]:
	var seen: Dictionary = {}
	var out: Array[Dictionary] = []
	for named: StringName in frames.get_animation_names():
		var way: StringName = StringName(String(named).get_slice("_", 1))
		for i: int in frames.get_frame_count(named):
			var slice := frames.get_frame_texture(named, i) as AtlasTexture
			if slice == null:
				continue
			var region := Rect2i(slice.region)
			if seen.has(region):
				continue
			seen[region] = true
			out.append({"region": region, "way": way, "idle": String(named).begins_with("idle")})
	return out


## **Room is taken above and beside each of his frames**, never below — his feet stand on
## the frame's bottom edge — and no two rooms may overlap, or one frame's plume would be
## written over another's boots.
func _rooms_apart(his: Array[Dictionary]) -> bool:
	for i: int in his.size():
		var a: Rect2i = CastLooks.with_room(his[i]["region"] as Rect2i, _room)
		for j: int in range(i + 1, his.size()):
			var b: Rect2i = CastLooks.with_room(his[j]["region"] as Rect2i, _room)
			if a.intersects(b):
				push_error("room_px %d makes %s and %s overlap" % [_room, str(a), str(b)])
				return false
	return true


## Our sixteen fight cells, each with the idle frame of his it was built on, placed as
## `draw_fight_frames.gd` placed it.
func _our_cells(sheet: Image, frames: SpriteFrames) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var cell: Vector2i = World3d.OUR_CELL
	var below: int = sheet.get_height() - cell.y * World3d.OUR_WAYS.size()
	for row: int in World3d.OUR_WAYS.size():
		var way: StringName = World3d.OUR_WAYS[row]
		var idle := frames.get_frame_texture(StringName("idle_" + String(way)), 0) as AtlasTexture
		var base := Rect2i(idle.region)
		for col: int in World3d.OUR_POSES.size():
			out.append({
				"rect": Rect2i(col * cell.x, below + row * cell.y, cell.x, cell.y),
				"way": way, "pose": World3d.OUR_POSES[col], "base": base, "at": (cell - base.size) / 2,
			})
	return out


func _dress_his(sheet: Image, out: Image, frame: Dictionary, recipe: Dictionary) -> void:
	var region: Rect2i = frame["region"] as Rect2i
	_stamp(out, dress_region(sheet, region, frame["way"] as StringName, recipe, _room),
		CastLooks.with_room(region, _room).position)


## One of his frames dressed in a look, with `room` kept above and beside it: exactly the
## pixels a look's sheet holds at `CastLooks.with_room(region, room)`. Static, so the
## suite can dress a frame and hold it against the committed sheet.
static func dress_region(sheet: Image, region: Rect2i, way: StringName, recipe: Dictionary,
		room: int) -> Image:
	var rect: Rect2i = CastLooks.with_room(region, room)
	var img: Image = _crop(sheet, rect, Rect2i(region.position - rect.position, region.size))
	var fig := Fig.new(img, way)
	_measure(fig, null)
	_wear(fig, recipe)
	return img


func _dress_ours(sheet: Image, out: Image, cell: Dictionary, recipe: Dictionary) -> void:
	var rect: Rect2i = cell["rect"] as Rect2i
	var way: StringName = cell["way"] as StringName
	var base: Rect2i = cell["base"] as Rect2i
	var at: Vector2i = cell["at"] as Vector2i
	# The idle frame the cell was built on, where `draw_fight_frames.gd` put it.
	var idle_img: Image = Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	idle_img.fill(CLEAR)
	idle_img.blit_rect(_crop(sheet, base, Rect2i(Vector2i.ZERO, base.size)), Rect2i(Vector2i.ZERO, base.size), at)
	var idle := Fig.new(idle_img, way)
	_measure(idle, null)
	if cell["pose"] == &"hurt":
		# **The flinch is the idle frame cut at the waist and the halves moved**, so it is
		# dressed as the idle frame and then cut and moved the same way — the whole cell,
		# so that a bow or a plume standing out of his rectangle goes with the half it
		# belongs to (the review of group L).
		_wear(idle, recipe)
		_stamp(out, _flinch(idle_img, at, base.size, way), rect.position)
		return
	# **Measured on the idle frame it was built from**: the cell's own arm can be up by his
	# hair, and a head measured with a fist beside it is a head a fist wider.
	var img: Image = _crop(sheet, rect, Rect2i(Vector2i.ZERO, rect.size))
	var fig := Fig.new(img, way)
	_measure(fig, idle)
	_wear(fig, recipe)
	_stamp(out, img, rect.position)


## `draw_fight_frames.gd`'s `_recoil` and `_fold`, on a dressed frame: seen from the side
## the legs go back six and the shoulders eleven; from the front or behind, the legs slip
## four one way and the shoulders eleven the other and eight down.
static func _flinch(img: Image, at: Vector2i, size: Vector2i, way: StringName) -> Image:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var cell: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	cell.fill(CLEAR)
	var waist: int = at.y + int(float(size.y) * 0.62)
	var legs: Vector2i
	var upper: Vector2i
	if way == &"right" or way == &"left":
		var forward: int = 1 if way == &"right" else -1
		legs = Vector2i(-6 * forward, 2)
		upper = Vector2i(-11 * forward, 1)
	else:
		var aside: int = 1 if way == &"down" else -1
		legs = Vector2i(4 * aside, 1)
		upper = Vector2i(-11 * aside, 8)
	cell.blit_rect(img, Rect2i(0, waist, w, h - waist), Vector2i(0, waist) + legs)
	cell.blit_rect(img, Rect2i(0, 0, w, waist), upper)
	return cell


## A copy of `rect`, with only what his shader would keep inside `keep` (in the copy's
## coordinates) and nothing anywhere else.
static func _crop(sheet: Image, rect: Rect2i, keep: Rect2i) -> Image:
	var img: Image = Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	img.fill(CLEAR)
	for y: int in range(keep.position.y, keep.end.y):
		for x: int in range(keep.position.x, keep.end.x):
			var sx: int = rect.position.x + x
			var sy: int = rect.position.y + y
			if sx < 0 or sy < 0 or sx >= sheet.get_width() or sy >= sheet.get_height():
				continue
			var c: Color = sheet.get_pixel(sx, sy)
			if visible(c):
				img.set_pixel(x, y, c)
	return img


static func _stamp(out: Image, img: Image, at: Vector2i) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.0:
				out.set_pixel(at.x + x, at.y + y, c)


# ------------------------------------------------------------------- measuring ---

## His shader's rule for what is background, as `draw_fight_frames.gd` copies it.
static func visible(c: Color) -> bool:
	if c.a < 0.5:
		return false
	var high: float = maxf(c.r, maxf(c.g, c.b))
	var low: float = minf(c.r, minf(c.g, c.b))
	return not (high > 0.35 and (high - low) / maxf(high, 0.001) < 0.22)


static func classify(c: Color, rel: float) -> int:
	var hd: float = c.h * 360.0
	var s: float = c.s
	var v: float = c.v
	if v < 0.13:
		return K.INK
	if hd >= 190.0 and hd <= 250.0 and s > 0.25:
		return K.SHIRT
	if (hd < 45.0 or hd > 345.0) and s < 0.62 and v > 0.78:
		return K.SKIN
	if (hd < 40.0 or hd > 345.0) and s >= 0.35 and rel < 0.6:
		return K.HAIR
	if s < 0.3 and v <= 0.36:
		return K.TROUSERS
	if hd < 50.0 or hd > 340.0:
		return K.LEATHER
	return K.OTHER


## Where his neck, head, face, shirt, legs, hands and pack are in this frame. `from`, when
## given, is the idle frame the cell was built on: everything but the hands is taken from it.
static func _measure(fig: Fig, from: Fig) -> void:
	var top: int = fig.h
	var bottom: int = -1
	for y: int in fig.h:
		for x: int in fig.w:
			if fig.img.get_pixel(x, y).a > 0.0:
				top = mini(top, y)
				bottom = maxi(bottom, y)
	if from != null:
		top = from.top
		bottom = from.bottom
	fig.top = top
	fig.bottom = bottom
	for y: int in fig.h:
		var rel: float = float(y - top) / float(maxi(bottom - top, 1))
		for x: int in fig.w:
			var c: Color = fig.img.get_pixel(x, y)
			if c.a > 0.0:
				fig.kind[y * fig.w + x] = classify(c, rel)
	fig.rebuild_rows()
	if from != null:
		fig.neck = from.neck
		fig.head = from.head
		fig.face = from.face
		fig.has_face = from.has_face
		fig.shirt = from.shirt
		fig.legs = from.legs
		fig.has_legs = from.has_legs
		fig.pack = from.pack.duplicate()
		for i: int in fig.kind.size():
			if fig.kind[i] != 0 and fig.kind[i] != from.kind[i]:
				fig.moved[i] = 1
		_find_hands(fig, from)
		return
	# The neck is the first row with a band of shirt across it. (Our cells, whose arm can
	# be raised by his hair, are measured on their idle frame instead — above.)
	fig.neck = fig.h
	for y: int in fig.h:
		var n: int = 0
		for x: int in fig.w:
			if fig.at(x, y) == K.SHIRT:
				n += 1
		if n >= 8:
			fig.neck = y
			break
	var head := Vector4i(fig.w, fig.h, -1, -1)
	var shirt := Vector4i(fig.w, fig.h, -1, -1)
	var legs := Vector4i(fig.w, fig.h, -1, -1)
	var skin_x: PackedInt32Array = PackedInt32Array()
	var skin_y0: int = fig.h
	var skin_y1: int = -1
	for y: int in fig.h:
		for x: int in fig.w:
			var k: int = fig.at(x, y)
			if k == K.NONE:
				continue
			if y < fig.neck:
				head = _grow(head, x, y)
				if k == K.SKIN:
					skin_x.append(x)
					skin_y0 = mini(skin_y0, y)
					skin_y1 = maxi(skin_y1, y)
			if k == K.SHIRT:
				shirt = _grow(shirt, x, y)
			if k == K.TROUSERS and y > fig.neck:
				legs = _grow(legs, x, y)
	fig.head = head
	fig.shirt = shirt
	fig.legs = legs
	fig.has_legs = legs.z >= 0
	# The face is the big blob of skin in the head; ears are small and stand apart, so a
	# twentieth is trimmed off each side. Seen from behind there is no face at all.
	fig.has_face = skin_x.size() >= 200 and fig.way != &"up"
	if fig.has_face:
		skin_x.sort()
		var trim: int = skin_x.size() / 20
		fig.face = Vector4i(skin_x[trim], skin_y0, skin_x[skin_x.size() - trim - 1], skin_y1)
	_find_hands(fig, null)
	_find_pack(fig)


## His hands: skin well below the neck — his chin can hang a row or two under the first
## row of shirt, seen from the side. In one of our cells, also any skin his idle frame did
## not have there: the fist has moved, and may be up by his hair.
static func _find_hands(fig: Fig, from: Fig) -> void:
	fig.hands.clear()
	fig.hand.fill(0)
	for y: int in fig.h:
		for x: int in fig.w:
			if fig.at(x, y) != K.SKIN:
				continue
			var yes: bool = y >= fig.neck + 8
			if from != null and from.at(x, y) != K.SKIN:
				yes = true
			if yes:
				fig.hands.append(Vector2i(x, y))
				fig.hand[y * fig.w + x] = 1


## His traveller's backpack: leather standing behind the torso, or on his back.
static func _find_pack(fig: Fig) -> void:
	# Measured across his shoulders, where his arms are still at his sides: an arm swung
	# back in the walk would otherwise stand in for his back, and the pack behind it stay.
	var x0: int = fig.w
	var x1: int = -1
	for y: int in range(fig.neck, mini(fig.neck + 15, fig.h)):
		for x: int in fig.w:
			if fig.at(x, y) == K.SHIRT:
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
	if x1 < 0:
		x0 = fig.shirt.x
		x1 = fig.shirt.z
	var y1: int = fig.shirt.w
	for y: int in fig.h:
		if y < fig.neck - 4 or y > y1 + 6:
			continue
		for x: int in fig.w:
			var k: int = fig.at(x, y)
			if k == K.NONE:
				continue
			var near: bool = k == K.LEATHER or k == K.INK or k == K.OTHER or k == K.TROUSERS
			var clear: bool = near or k == K.SKIN or k == K.HAIR
			var yes: bool = false
			if fig.way == &"left":
				yes = (x > x1 - 6 and near) or (x > x1 + 2 and clear)
			elif fig.way == &"right":
				yes = (x < x0 + 6 and near) or (x < x0 - 2 and clear)
			elif fig.way == &"up":
				var cx: float = (x0 + x1) / 2.0
				yes = absf(x - cx) < (x1 - x0) * 0.32 and y >= fig.neck and y <= y1 - 4 \
					and (k == K.LEATHER or k == K.INK or k == K.SKIN or k == K.OTHER or k == K.TROUSERS)
			if yes:
				fig.pack[y * fig.w + x] = 1


static func _grow(box: Vector4i, x: int, y: int) -> Vector4i:
	return Vector4i(mini(box.x, x), mini(box.y, y), maxi(box.z, x), maxi(box.w, y))


# ------------------------------------------------------------------- colour ---

static func hsv(h: float, s: float, v: float) -> Color:
	return Color.from_hsv(fposmod(h, 360.0) / 360.0, clampf(s, 0.0, 1.0), clampf(v, 0.0, 1.0))


## A colour his shader keeps: a bright one must carry some saturation.
static func safe(h: float, s: float, v: float) -> Color:
	if v > 0.35 and s < 0.24:
		s = 0.24
	return hsv(h, s, v)


## The painted grain: a hash of the pixel's place, the same on every run.
static func noise(x: int, y: int, seed: int) -> float:
	var n: int = (x * 73856093) ^ (y * 19349663) ^ (seed * 83492791)
	return float((n >> 3) % 1000) / 1000.0


static func _recolour(fig: Fig, table: Dictionary) -> void:
	for region: String in table.keys():
		if not REGIONS.has(region):
			continue
		var want: int = REGIONS[region]
		var row: Array = table[region] as Array
		for y: int in fig.h:
			for x: int in fig.w:
				if fig.at(x, y) == want:
					fig.put(x, y, _moved(fig.colour(x, y), row))


## One of his pixels moved to another hue: his value kept, scaled.
static func _moved(c: Color, row: Array) -> Color:
	var s: float = minf(maxf(c.s * float(row[1]), float(row[2])), 1.0)
	return safe(float(row[0]), s, minf(c.v * float(row[3]), 1.0))


static func vec(value: Variant, fallback: Vector3) -> Vector3:
	if value is Array and (value as Array).size() == 3:
		var a: Array = value as Array
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return fallback


# ------------------------------------------------------------------- painting ---

## A shape given as a predicate, painted with his dark outline round it. `box` bounds
## the search; `against`, when given, says which neighbours an outline is drawn against.
static func _fill(fig: Fig, box: Rect2i, inside: Callable, colour_at: Callable, outline: int = 3,
		against: Callable = Callable()) -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(fig.w * fig.h)
	var area: Rect2i = box.intersection(Rect2i(0, 0, fig.w, fig.h))
	var points: Array[Vector2i] = []
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			if inside.call(x, y):
				mask[y * fig.w + x] = 1
				points.append(Vector2i(x, y))
	var ring: Array[Vector2i] = []
	for dy: int in range(-outline, outline + 1):
		for dx: int in range(-outline, outline + 1):
			if (dx != 0 or dy != 0) and dx * dx + dy * dy <= outline * outline:
				ring.append(Vector2i(dx, dy))
	for p: Vector2i in points:
		var edge: bool = false
		for d: Vector2i in ring:
			var q: Vector2i = p + d
			var in_mask: bool = q.x >= 0 and q.y >= 0 and q.x < fig.w and q.y < fig.h and mask[q.y * fig.w + q.x] == 1
			if not in_mask and (not against.is_valid() or against.call(q.x, q.y)):
				edge = true
				break
		fig.put(p.x, p.y, INK if edge else colour_at.call(p.x, p.y) as Color)
		fig.set_kind(p.x, p.y, K.PIECE)
	return mask


## His light: from the top left, soft, with a painted grain.
static func shade(c: Vector3, box: Rect2, seed: int, spread: float = 0.30, grain: float = 0.05) -> Callable:
	return func(x: int, y: int) -> Color:
		var u: float = (x - box.position.x) / maxf(box.size.x, 1.0)
		var w: float = (y - box.position.y) / maxf(box.size.y, 1.0)
		var light: float = 1.0 - 0.55 * u - 0.45 * w
		var g: float = (noise(x / 2, y / 2, seed) - 0.5) * grain
		return safe(c.x, c.y, c.z + spread * (light - 0.5) + g)


## A rounded metal surface: dark at the rim, a highlight high on the left.
static func metal(c: Vector3, box: Rect2, seed: int, hi: Vector2 = Vector2(0.28, 0.30)) -> Callable:
	var centre: Vector2 = box.get_center()
	var r: Vector2 = box.size / 2.0
	var spot: Vector2 = box.position + box.size * hi
	return func(x: int, y: int) -> Color:
		var rim: float = pow((x - centre.x) / r.x, 2) + pow((y - centre.y) / r.y, 2)
		var near: float = pow((x - spot.x) / (r.x * 0.55), 2) + pow((y - spot.y) / (r.y * 0.5), 2)
		var val: float = c.z * (1.05 - 0.45 * minf(rim, 1.2)) + 0.42 * pow(maxf(0.0, 1.0 - near), 2)
		val += (noise(x / 2, y / 2, seed) - 0.5) * 0.05
		return safe(c.x, c.y if val <= 0.35 else maxf(c.y, 0.24), val)


static func _erase_where(fig: Fig, keep: Callable) -> void:
	for y: int in fig.h:
		for x: int in fig.w:
			if fig.at(x, y) != K.NONE and not fig.is_moved(x, y) and not keep.call(x, y):
				fig.put(x, y, CLEAR)
				fig.set_kind(x, y, K.NONE)


static func _box(x0: float, y0: float, x1: float, y1: float) -> Rect2i:
	return Rect2i(floori(x0) - 1, floori(y0) - 1, ceili(x1 - x0) + 3, ceili(y1 - y0) + 3)


# ------------------------------------------------------------------- the recipes ---

static func _wear(fig: Fig, recipe: Dictionary) -> void:
	_recolour(fig, recipe.get("recolour", {}) as Dictionary)
	for step: Variant in recipe.get("pieces", []) as Array:
		var row: Array = step as Array
		var params: Dictionary = row[1] as Dictionary if row.size() > 1 else {}
		match String(row[0]):
			"apron":
				_piece_apron(fig, params)
			"bascinet":
				_piece_bascinet(fig, params)
			"beard":
				_piece_beard(fig, params)
			"bow_in_hand":
				_piece_bow_in_hand(fig, params)
			"cap":
				_piece_cap(fig, params)
			"gloves":
				_piece_gloves(fig, params)
			"headscarf":
				_piece_headscarf(fig, params)
			"hood":
				_piece_hood(fig, params)
			"iron_body":
				_piece_iron_body(fig, params)
			"pauldrons":
				_piece_pauldrons(fig, params)
			"quiver":
				_piece_quiver(fig, params)
			"remove_pack":
				_piece_remove_pack(fig, params)
			"scabbard":
				_piece_scabbard(fig, params)
			"shield_on_back":
				_piece_shield_on_back(fig, params)
			"straw_hat":
				_piece_straw_hat(fig, params)
			"surcoat":
				_piece_surcoat(fig, params)
			"sword_in_hand":
				_piece_sword_in_hand(fig, params)
			_:
				push_error("no piece called %s" % row[0])


## His backpack goes. From behind it sat on the shirt, so the shirt is carried on under
## it from the median of his own shirt; from the side it stood clear of the body and goes.
static func _piece_remove_pack(fig: Fig, _params: Dictionary) -> void:
	var any: bool = false
	for i: int in fig.pack.size():
		if fig.pack[i] == 1:
			any = true
			break
	if not any:
		return
	if fig.way != &"up":
		for y: int in fig.h:
			for x: int in fig.w:
				if fig.in_pack(x, y):
					fig.put(x, y, CLEAR)
					fig.set_kind(x, y, K.NONE)
		fig.pack.fill(0)
		return
	var hs: Array[float] = []
	var ss: Array[float] = []
	var vs: Array[float] = []
	for y: int in fig.h:
		for x: int in fig.w:
			if not fig.in_pack(x, y) and fig.at(x, y) == K.SHIRT:
				var c: Color = fig.colour(x, y)
				hs.append(c.h)
				ss.append(c.s)
				vs.append(c.v)
	if hs.is_empty():
		return
	hs.sort()
	ss.sort()
	vs.sort()
	var m: int = hs.size() / 2
	# **The whole of the pack's box, a pixel past it, repainted evenly** (the review of
	# group L): filling only the pack's own pixels left its notched outline on his back,
	# and the buckle, which is dark enough to read as trousers, stayed as a square.
	var box: Vector4i = _pack_box(fig)
	var cx: float = (box.x + box.z) / 2.0
	var half: float = maxf((box.z - box.x) / 2.0 + 1.0, 1.0)
	for y: int in range(box.y, box.w + 1):
		var t: float = float(y - box.y) / float(maxi(box.w - box.y, 1))
		for x: int in range(box.x - 1, box.z + 2):
			if not fig.has(x, y) or fig.at(x, y) == K.SKIN or fig.at(x, y) == K.PIECE:
				continue
			var rounded: float = 1.04 - 0.10 * absf(x - cx) / half
			var g: float = (noise(x / 2, y / 2, 81) - 0.5) * 0.03
			fig.put(x, y, safe(hs[m] * 360.0, ss[m], vs[m] * rounded * (1.05 - 0.22 * t) + g))
			fig.set_kind(x, y, K.SHIRT)
	fig.pack.fill(0)


static func _pack_box(fig: Fig) -> Vector4i:
	var box := Vector4i(fig.w, fig.h, -1, -1)
	for y: int in fig.h:
		for x: int in fig.w:
			if fig.in_pack(x, y):
				box = _grow(box, x, y)
	return box


## His shirt becomes a breastplate, his trousers greaves, his hands gauntlets.
static func _piece_iron_body(fig: Fig, _params: Dictionary) -> void:
	# His sleeve anywhere — an arm raised by his head included — but trousers and leather
	# only below the neck, because the darkest of his hair reads as either.
	for y: int in fig.h:
		for x: int in fig.w:
			var k: int = fig.at(x, y)
			if k == K.SHIRT or (y >= fig.neck - 2 and (k == K.TROUSERS or k == K.LEATHER)):
				var v2: float = minf(1.0, 0.10 + fig.colour(x, y).v * (0.75 if k == K.SHIRT else 0.55))
				fig.put(x, y, safe(IRON.x, IRON.y if v2 <= 0.35 else 0.24, v2))
	for q: Vector2i in fig.hands:
		var v3: float = fig.colour(q.x, q.y).v * 0.55
		fig.put(q.x, q.y, safe(IRON.x, IRON.y if v3 <= 0.35 else 0.24, v3))


## Leather or steel over his hands.
static func _piece_gloves(fig: Fig, params: Dictionary) -> void:
	var c: Vector3 = vec(params.get("colour"), STEEL)
	for q: Vector2i in fig.hands:
		var was: Color = fig.colour(q.x, q.y)
		if was.v >= 0.13:
			fig.put(q.x, q.y, safe(c.x, c.y, minf(was.v * c.z / 0.9, 1.0)))


## A tabard over the chest and down between the legs, with the king's crown on it.
static func _piece_surcoat(fig: Fig, params: Dictionary) -> void:
	var c: Vector3 = vec(params.get("colour"), KING_RED)
	var x0: int = fig.shirt.x
	var x1: int = fig.shirt.z
	var y1: int = fig.shirt.w
	var cx: float = (x0 + x1) / 2.0 + {&"left": -(x1 - x0) * 0.06, &"right": (x1 - x0) * 0.06}.get(fig.way, 0.0)
	var half: float = (x1 - x0) * (0.26 if fig.way == &"down" or fig.way == &"up" else 0.22)
	var top: float = fig.neck + 3
	var bottom: float = y1 + ((fig.legs.w - y1) * 0.45 if fig.has_legs else 10.0)
	var inside := func(x: int, y: int) -> bool:
		if y < top or y > bottom:
			return false
		var flare: float = (y - top) / maxf(bottom - top, 1.0) * 3.0
		return absf(x - cx) <= half + flare and fig.row_has(x, y)
	_fill(fig, _box(cx - half - 4, top, cx + half + 4, bottom), inside,
		shade(c, Rect2(cx - half, top, half * 2, bottom - top), 7, 0.25), 2)
	if params.get("emblem", true) and (fig.way == &"down" or fig.way == &"up"):
		_crown(fig, cx, int(top + (y1 - top) * 0.45), true)


static func _crown(fig: Fig, cx: float, ey: int, outlined: bool) -> void:
	for y: int in range(ey - 7, ey + 4):
		for x: int in range(int(cx) - 7, int(cx) + 8):
			var dx: float = x - cx
			var dy: float = y - ey
			var band: bool = dy >= -1 and dy <= 3 and absf(dx) <= 6
			var points: bool = false
			if dy < -1:
				for p: Vector2 in [Vector2(-5, -6), Vector2(0, -7), Vector2(5, -6)]:
					if absf(dx - p.x) <= 1.5 and dy >= p.y - 1:
						points = true
			if band or points:
				var rim: bool = outlined and (dy == 3 or absf(dx) >= 6.5)
				fig.put(x, y, INK if rim else safe(GOLD.x, GOLD.y, GOLD.z))


static func _piece_pauldrons(fig: Fig, _params: Dictionary) -> void:
	var x0: int = fig.shirt.x
	var x1: int = fig.shirt.z
	var top: int = fig.neck
	var centres: Array[Vector2] = []
	if fig.way == &"down" or fig.way == &"up":
		centres = [Vector2(x0 + 4, top + 9), Vector2(x1 - 4, top + 9)]
	elif fig.way == &"left":
		centres = [Vector2((x0 + x1) / 2.0 + 3, top + 9)]
	else:
		centres = [Vector2((x0 + x1) / 2.0 - 3, top + 9)]
	for c: Vector2 in centres:
		var inside := func(x: int, y: int) -> bool:
			return pow((x - c.x) / 16.0, 2) + pow((y - c.y) / 12.0, 2) <= 1.0 and y <= c.y + 8
		_fill(fig, _box(c.x - 16, c.y - 12, c.x + 16, c.y + 8), inside,
			metal(IRON, Rect2(c.x - 16, c.y - 12, 32, 20), 9), 2)
		for x: int in range(int(c.x) - 13, int(c.x) + 14):
			var y: int = int(c.y + 3)
			if inside.call(x, y) and fig.colour(x, y) != INK:
				fig.put(x, y, safe(IRON.x, 0.12, 0.14))


## The king's guard's helm: rounded, visor down. No face shows, no hair, no ears.
static func _piece_bascinet(fig: Fig, _params: Dictionary) -> void:
	var w: float = fig.head.z - fig.head.x
	var cx: float = (fig.head.x + fig.head.z) / 2.0 + {&"left": -w * 0.03, &"right": w * 0.03}.get(fig.way, 0.0)
	var top: float = fig.head.y + (fig.neck - fig.head.y) * 0.14
	var bottom: float = fig.neck + 3
	var half: float = w * 0.39
	var widest: float = top + (bottom - top) * 0.50
	var inside := func(x: int, y: int) -> bool:
		if y < top or y > bottom:
			return false
		if y <= widest:
			return pow((x - cx) / half, 2) + pow((widest - y) / (widest - top), 2.2) <= 1.0
		var t: float = (y - widest) / (bottom - widest)
		return absf(x - cx) <= half * (1.0 - 0.22 * t * t)
	_erase_where(fig, func(x: int, y: int) -> bool:
		return y >= bottom or inside.call(x, y) or fig.is_hand(x, y) \
			or (fig.at(x, y) == K.SHIRT and (x < fig.head.x + 8 or x > fig.head.z - 8)))
	_fill(fig, _box(cx - half, top, cx + half, bottom), inside,
		metal(IRON, Rect2(cx - half, top, half * 2, bottom - top), 3), 3)
	if fig.way != &"up" and fig.has_face:
		var eye_y: int = int(fig.face.y + (fig.face.w - fig.face.y) * 0.40)
		var vcx: float = cx + {&"left": -half * 0.35, &"right": half * 0.35}.get(fig.way, 0.0)
		var vhalf: float = half * (0.78 if fig.way == &"down" else 0.62)
		var visor := func(x: int, y: int) -> bool:
			if y < eye_y - 6 or y > bottom - 4:
				return false
			var t: float = (y - (eye_y - 6)) / (bottom - 4 - (eye_y - 6))
			return absf(x - vcx) <= vhalf * (1.0 - 0.35 * t) and inside.call(x, y)
		_fill(fig, _box(vcx - vhalf, eye_y - 6, vcx + vhalf, bottom), visor,
			metal(Vector3(IRON.x, IRON.y, IRON.z * 1.1), Rect2(vcx - vhalf, eye_y - 6, vhalf * 2, bottom - eye_y + 6),
				4, Vector2(0.30, 0.20)), 2)
		for y: int in range(eye_y - 3, eye_y + 2):
			for x: int in range(int(vcx - vhalf) + 4, int(vcx + vhalf) - 3):
				if visor.call(x, y) and absf(x - vcx) > (2.0 if fig.way == &"down" else -1.0):
					fig.put(x, y, INK)
		for y: int in range(eye_y + 3, int(bottom) - 5):
			for dx: int in [-1, 0]:
				if visor.call(int(vcx) + dx, y):
					fig.put(int(vcx) + dx, y, safe(IRON.x, 0.24, 0.62 if dx < 0 else 0.40))
		for j: int in 3:
			for i: int in range(-2, 3):
				var hx: int = int(vcx + i * 5 + (half * 0.22 if fig.way == &"down" else 0.0))
				var hy: int = eye_y + 12 + j * 5
				for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
					if visor.call(hx + d.x, hy + d.y) and absi(i) + j < 4:
						fig.put(hx + d.x, hy + d.y, INK)
	else:
		for y: int in range(int(top) + 5, int(bottom) - 4):
			if inside.call(int(cx), y):
				fig.put(int(cx), y, safe(IRON.x, 0.24, 0.55))
				fig.put(int(cx) + 1, y, safe(IRON.x, 0.12, 0.22))
	_plume(fig, cx, top, half)
	_bridge_arm(fig)


## **An arm raised beside the head keeps its whole length** (the review of group L). In
## our blow thrown away from us the arm rises behind his hair, which is stamped back over
## it; a helm or a hood narrower than his hair uncovers where the arm was hidden and
## leaves a fist floating. So the arm is laid again, in its own sleeve's colour, from the
## shoulder to the fist, behind whatever already stands there.
static func _bridge_arm(fig: Fig) -> void:
	var fist := Vector2.ZERO
	var n: int = 0
	for q: Vector2i in fig.hands:
		if q.y < fig.neck and fig.is_moved(q.x, q.y):
			fist += Vector2(q)
			n += 1
	if n < 10:
		return
	fist /= float(n)
	var sleeve: Array[Color] = []
	for y: int in fig.h:
		for x: int in fig.w:
			if fig.at(x, y) == K.SHIRT and (fig.is_moved(x, y) or sleeve.is_empty()):
				sleeve.append(fig.colour(x, y))
	if sleeve.is_empty():
		return
	sleeve.sort_custom(func(a: Color, b: Color) -> bool: return a.v < b.v)
	var tone: Color = sleeve[sleeve.size() / 2]
	var right: bool = fist.x > (fig.shirt.x + fig.shirt.z) / 2.0
	var shoulder := Vector2(fig.shirt.z - 3.0 if right else fig.shirt.x + 3.0,
		fig.shirt.y + (fig.shirt.w - fig.shirt.y) * 0.34)
	var dir: Vector2 = fist - shoulder
	var length: float = dir.length()
	if length < 4.0:
		return
	dir /= length
	var across := Vector2(-dir.y, dir.x)
	var arm := func(x: int, y: int) -> bool:
		var d: Vector2 = Vector2(x, y) - shoulder
		var t: float = d.dot(dir)
		return t >= 0.0 and t <= length - 3.0 and absf(d.dot(across)) <= 6.0 and not fig.has(x, y)
	var paint := func(x: int, y: int) -> Color:
		var u: float = (Vector2(x, y) - shoulder).dot(across) / 6.0
		return safe(tone.h * 360.0, tone.s, tone.v * (1.0 - 0.18 * u))
	_fill(fig, _box(minf(shoulder.x, fist.x) - 8, minf(shoulder.y, fist.y) - 8,
		maxf(shoulder.x, fist.x) + 8, maxf(shoulder.y, fist.y) + 8), arm, paint, 2)


## A tuft of the king's red, falling back — no higher than the frame has room for.
static func _plume(fig: Fig, cx: float, top: float, half: float) -> void:
	var back: int = {&"left": 1, &"right": -1}.get(fig.way, 0)
	var inside: Callable
	var box: Rect2
	if back == 0:
		var ry: float = minf(11.0, (top + 3.0) / 2.0)
		var cy: float = top + 3.0 - ry
		inside = func(x: int, y: int) -> bool:
			return pow((x - cx) / 13.0, 2) + pow((y - cy) / ry, 2) <= 1.0 and y <= top + 3
		box = Rect2(cx - 13, cy - ry, 26, ry * 2)
	else:
		var dome_h: float = half * 1.05
		var lift: float = minf(12.0, top - 1.0)
		var surface := func(x: int) -> float:
			var u: float = minf(absf(x - cx) / half, 1.0)
			return top + dome_h * (1.0 - pow(1.0 - u * u, 1.0 / 2.2))
		inside = func(x: int, y: int) -> bool:
			var u: float = (x - cx) * back
			if u < -8.0 or u > half * 0.85:
				return false
			var thick: float = lift * pow(1.0 - maxf(0.0, u) / (half * 0.85), 0.6) + 3.0
			var s: float = surface.call(x)
			return y >= s - thick and y <= s + 3
		box = Rect2(cx - half, top - lift - 3, half * 2, dome_h + lift + 3)
	var feather := func(x: int, y: int) -> Color:
		var streak: float = 0.10 if ((x * 3 + y) / 4) % 3 == 0 else 0.0
		var v: float = KING_RED.z * (1.15 - 0.5 * (y - box.position.y) / (box.size.y + 1.0)) + streak \
			+ (noise(x, y, 71) - 0.5) * 0.08
		return safe(KING_RED.x, KING_RED.y, v)
	_fill(fig, Rect2i(box.grow(2)), inside, feather, 2)


## Where his backpack was: a shield, carried — its face from behind, its edge from the side.
static func _piece_shield_on_back(fig: Fig, _params: Dictionary) -> void:
	var p: Vector4i = _pack_box(fig)
	if p.z < 0:
		return
	_piece_remove_pack(fig, {})
	if fig.way == &"up":
		var cx: float = (p.x + p.z) / 2.0
		var half: float = (p.z - p.x) / 2.0 + 6.0
		var top: float = p.y - 4
		var bottom: float = p.w + 14
		var inside := func(x: int, y: int) -> bool:
			if y < top or y > bottom:
				return false
			var t: float = (y - top) / (bottom - top)
			var hw: float = half if t < 0.5 else half * pow(cos((t - 0.5) / 0.5 * PI / 2.0), 0.8)
			return absf(x - cx) <= hw
		_fill(fig, _box(cx - half, top, cx + half, bottom), inside,
			shade(KING_RED, Rect2(cx - half, top, half * 2, bottom - top), 11), 3)
		for y: int in range(int(top) + 3, int(top) + 7):
			for x: int in range(int(cx - half) + 3, int(cx + half) - 2):
				if inside.call(x, y):
					fig.put(x, y, safe(STEEL.x, 0.26, 0.7))
		_crown(fig, cx, int(top + (bottom - top) * 0.45), false)
	elif fig.way == &"left" or fig.way == &"right":
		var back: int = 1 if fig.way == &"left" else -1
		var edge: float = p.z if back == 1 else p.x
		var inner: float = p.x if back == 1 else p.z
		var top2: float = p.y - 6
		var bottom2: float = p.w + 16
		var inside2 := func(x: int, y: int) -> bool:
			if y < top2 or y > bottom2:
				return false
			var t: float = (y - top2) / (bottom2 - top2)
			var bulge: float = 5.0 * sin(PI * t)
			var a: float = inner - back * 2
			var b: float = edge - back * 8 + back * bulge
			return x >= minf(a, b) and x <= maxf(a, b) and not fig.has(x, y)
		_fill(fig, _box(minf(inner, edge) - 6, top2, maxf(inner, edge) + 6, bottom2), inside2,
			shade(KING_RED, Rect2(minf(inner, edge) - 4, top2, absf(edge - inner) + 4, bottom2 - top2), 11), 3)


## A close cap, leather or iron: his hair shows under it.
static func _piece_cap(fig: Fig, params: Dictionary) -> void:
	var c: Vector3 = vec(params.get("colour"), Vector3(28, 0.55, 0.36))
	var w: float = fig.head.z - fig.head.x
	var hh: float = fig.neck - fig.head.y
	var cx: float = (fig.head.x + fig.head.z) / 2.0
	var brow: float = (fig.face.y + 4.0) if fig.has_face else fig.head.y + hh * 0.42
	var half: float = w * 0.42
	var top: float = fig.head.y + hh * 0.05
	var r: float = brow - top
	var inside := func(x: int, y: int) -> bool:
		return y <= brow and pow((x - cx) / half, 2) + pow((brow - y) / r, 2) <= 1.0
	_erase_where(fig, func(x: int, y: int) -> bool:
		var k: int = fig.at(x, y)
		return y >= brow - r * 0.35 or inside.call(x, y) or not (k == K.HAIR or k == K.INK or k == K.LEATHER \
			or k == K.TROUSERS or k == K.OTHER))
	_fill(fig, _box(cx - half, top, cx + half, brow), inside,
		shade(c, Rect2(cx - half, top, half * 2, brow - top), 13, 0.45), 3)
	var seam: int = int(cx + (0.0 if fig.way == &"down" or fig.way == &"up" else (-half * 0.3 if fig.way == &"left" else half * 0.3)))
	for y: int in range(int(top) + 5, int(brow) - 2):
		if inside.call(seam, y):
			fig.put(seam, y, safe(c.x, c.y, c.z * 0.55))
	for x: int in range(int(cx - half) + 3, int(cx + half) - 2):
		for y: int in [int(brow) - 3, int(brow) - 2]:
			if inside.call(x, y) and fig.colour(x, y) != INK:
				fig.put(x, y, safe(c.x, c.y, c.z * 0.6))


## A cloth tied over the hair, knotted at the back.
static func _piece_headscarf(fig: Fig, params: Dictionary) -> void:
	var c: Vector3 = vec(params.get("colour"), Vector3(215, 0.30, 0.30))
	var w: float = fig.head.z - fig.head.x
	var hh: float = fig.neck - fig.head.y
	var cx: float = (fig.head.x + fig.head.z) / 2.0
	var brow: float = (fig.face.y + 2.0) if fig.has_face else fig.head.y + hh * 0.45
	var half: float = w * 0.44
	var top: float = fig.head.y + hh * 0.08
	var r: float = brow - top
	var inside := func(x: int, y: int) -> bool:
		return y <= brow + 2 and pow((x - cx) / half, 2) + pow((brow - y) / r, 2) <= 1.0
	_erase_where(fig, func(x: int, y: int) -> bool:
		return y >= brow - r * 0.3 or fig.at(x, y) == K.SKIN or inside.call(x, y))
	_fill(fig, _box(cx - half, top, cx + half, brow + 2), inside,
		shade(c, Rect2(cx - half, top, half * 2, brow - top), 29, 0.5, 0.08), 3)
	var back: int = {&"left": 1, &"right": -1}.get(fig.way, 0)
	if back != 0:
		var kx: float = cx + back * half * 0.95
		var ky: float = brow - r * 0.35
		var knot := func(x: int, y: int) -> bool:
			var u: float = (x - kx) * back
			return pow((x - kx) / 8.0, 2) + pow((y - ky) / 6.0, 2) <= 1.0 \
				or (u >= 0.0 and u <= 14.0 and y >= ky and y <= ky + 14.0 - u * 0.5 and absf(u - (y - ky) * 0.8) < 5.0)
		_fill(fig, _box(kx - 16, ky - 8, kx + 16, ky + 16), knot,
			shade(c, Rect2(kx - 10, ky - 8, 26, 24), 31), 2)


## A wide straw hat, for the fields.
static func _piece_straw_hat(fig: Fig, params: Dictionary) -> void:
	var c: Vector3 = vec(params.get("colour"), Vector3(44, 0.55, 0.78))
	var w: float = fig.head.z - fig.head.x
	var hh: float = fig.neck - fig.head.y
	var cx: float = (fig.head.x + fig.head.z) / 2.0
	var brim_y: float = (fig.face.y + 2.0) if fig.has_face else fig.head.y + hh * 0.45
	var brim_half: float = w * 0.56
	var crown_half: float = w * 0.30
	var crown_top: float = maxf(brim_y - hh * 0.36, 1.0)
	var crown := func(x: int, y: int) -> bool:
		return y >= crown_top and y <= brim_y \
			and pow((x - cx) / crown_half, 2) + pow((brim_y - y) / (brim_y - crown_top), 4) <= 1.0
	var brim := func(x: int, y: int) -> bool:
		return pow((x - cx) / brim_half, 2) + pow((y - brim_y) / 7.0, 2) <= 1.0
	var inside := func(x: int, y: int) -> bool:
		return crown.call(x, y) or brim.call(x, y)
	_erase_where(fig, func(x: int, y: int) -> bool:
		return y >= brim_y - 4 or fig.at(x, y) == K.SKIN or inside.call(x, y))
	var straw := func(x: int, y: int) -> Color:
		var light: float = 1.0 - 0.5 * (x - cx + brim_half) / (2.0 * brim_half) \
			- 0.3 * (y - crown_top) / (brim_y + 7.0 - crown_top)
		var weave: float = 0.07 if ((x + 2 * y) / 3) % 2 == 1 else -0.04
		var v: float = c.z * (0.78 + 0.35 * light) + weave + (noise(x, y, 67) - 0.5) * 0.06
		if brim.call(x, y) and y > brim_y + 1:
			v *= 0.78
		return safe(c.x, c.y, v)
	_fill(fig, _box(cx - brim_half, crown_top, cx + brim_half, brim_y + 7), inside, straw, 3)
	for y: int in range(int(brim_y) - 7, int(brim_y) - 3):
		for x: int in range(int(cx - crown_half) + 3, int(cx + crown_half) - 2):
			if crown.call(x, y) and fig.colour(x, y) != INK:
				fig.put(x, y, safe(8, 0.55, 0.42))


## A cloth hood: the head's whole shape changes, and the face looks out of it.
static func _piece_hood(fig: Fig, params: Dictionary) -> void:
	var c: Vector3 = vec(params.get("colour"), Vector3(130, 0.50, 0.40))
	var w: float = fig.head.z - fig.head.x
	var cx: float = (fig.head.x + fig.head.z) / 2.0
	var half: float = w * 0.43
	var top: float = fig.head.y + (fig.neck - fig.head.y) * 0.04
	var bottom: float = fig.neck + 6
	var cy: float = top + (bottom - top) * 0.52
	var ry: float = (bottom - top) * 0.52
	var back: int = {&"left": 1, &"right": -1}.get(fig.way, 0)
	var body := func(x: int, y: int) -> bool:
		var dx: float = (x - cx) / half
		var dy: float = (y - cy) / ry
		var yes: bool = dx * dx + dy * dy <= 1.0 or (y > cy and absf(x - cx) <= half * (1.0 - (y - cy) / ry * 0.15))
		if back != 0:
			var tx: float = cx + back * half * 0.75
			var ty: float = top + 8
			yes = yes or (pow((x - tx) / 14.0, 2) + pow((y - ty) / 18.0, 2) <= 1.0 and (x - cx) * back > 0)
		else:
			yes = yes or (absf(x - cx) <= 7.0 - (top - y) * 0.6 and y >= top - 8 and y <= top + 4)
		return yes and y <= bottom
	# The opening is his face as he drew it — skin, eyes, and the fringe just above.
	var span_lo: PackedInt32Array = PackedInt32Array()
	var span_hi: PackedInt32Array = PackedInt32Array()
	span_lo.resize(fig.h)
	span_hi.resize(fig.h)
	span_lo.fill(fig.w)
	span_hi.fill(-1)
	if fig.has_face:
		var skin := PackedByteArray()
		skin.resize(fig.w * fig.h)
		for y: int in range(0, fig.neck):
			for x: int in range(maxi(fig.face.x - 2, 0), mini(fig.face.z + 3, fig.w)):
				if fig.at(x, y) == K.SKIN:
					skin[y * fig.w + x] = 1
		var face := PackedByteArray(skin)
		for y: int in range(0, fig.neck):
			for x: int in fig.w:
				if fig.at(x, y) != K.INK:
					continue
				var left: bool = false
				var right: bool = false
				for d: int in range(1, 13):
					if x - d >= 0 and skin[y * fig.w + x - d] == 1:
						left = true
					if x + d < fig.w and skin[y * fig.w + x + d] == 1:
						right = true
				if left and right:
					face[y * fig.w + x] = 1
		for x: int in fig.w:
			var first: int = -1
			for y: int in fig.neck:
				if face[y * fig.w + x] == 1:
					first = y
					break
			if first < 0:
				continue
			for y: int in range(maxi(first - 10, 0), first):
				var k: int = fig.at(x, y)
				if k == K.HAIR or k == K.INK:
					face[y * fig.w + x] = 1
		for y: int in fig.h:
			for x: int in fig.w:
				if face[y * fig.w + x] == 1:
					span_lo[y] = mini(span_lo[y], x)
					span_hi[y] = maxi(span_hi[y], x)
	var opening := func(x: int, y: int) -> bool:
		return y >= 0 and y < fig.h and x >= span_lo[y] + 1 and x <= span_hi[y] - 1
	var inside := func(x: int, y: int) -> bool:
		return body.call(x, y) and not opening.call(x, y)
	_erase_where(fig, func(x: int, y: int) -> bool:
		return y >= fig.neck or body.call(x, y) or fig.at(x, y) == K.SKIN)
	_fill(fig, _box(cx - half - 16, top - 10, cx + half + 16, bottom), inside,
		shade(c, Rect2(cx - half, top, half * 2, bottom - top), 17, 0.40, 0.10), 3,
		func(x: int, y: int) -> bool: return not opening.call(x, y))
	if fig.has_face:
		for y: int in range(fig.face.y - 13, fig.face.w + 3):
			for x: int in range(fig.face.x - 6, fig.face.z + 7):
				if not inside.call(x, y) or fig.colour(x, y) == INK:
					continue
				for d: Vector2i in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
					if opening.call(x + d.x, y + d.y):
						fig.put(x, y, safe(c.x, c.y, c.z * 0.55))
						break
	_bridge_arm(fig)


## A smith's leather apron, chest to knees, on a strap round the neck; from behind, its ties.
static func _piece_apron(fig: Fig, params: Dictionary) -> void:
	var c: Vector3 = vec(params.get("colour"), Vector3(24, 0.50, 0.40))
	var x0: int = fig.shirt.x
	var y0: int = fig.shirt.y
	var x1: int = fig.shirt.z
	var y1: int = fig.shirt.w
	if fig.way == &"up":
		var yb: int = int(y1 - (y1 - y0) * 0.25)
		for y: int in range(yb, yb + 3):
			for x: int in range(x0 + 4, x1 - 3):
				if fig.has(x, y):
					fig.put(x, y, safe(c.x, c.y, c.z * 0.8))
		return
	var cx: float = (x0 + x1) / 2.0 + {&"left": -(x1 - x0) * 0.20, &"right": (x1 - x0) * 0.20}.get(fig.way, 0.0)
	var half_top: float = (x1 - x0) * (0.22 if fig.way == &"down" else 0.14)
	var half_bot: float = (x1 - x0) * (0.36 if fig.way == &"down" else 0.22)
	var top: float = fig.neck + 6
	var bottom: float = (fig.legs.w - (fig.legs.w - fig.legs.y) * 0.30) if fig.has_legs else y1 + 20.0
	var waist: float = y0 + (y1 - y0) * 0.55
	var inside := func(x: int, y: int) -> bool:
		if y < top or y > bottom:
			return false
		var hw: float = half_top if y < waist else half_top + (half_bot - half_top) * minf(1.0, (y - waist) / 10.0)
		return absf(x - cx) <= hw
	_fill(fig, _box(cx - half_bot, top, cx + half_bot, bottom), inside,
		shade(c, Rect2(cx - half_bot, top, half_bot * 2, bottom - top), 19, 0.35, 0.10), 2)
	for i: int in 7:
		var sx: int = int(cx + (noise(i, 1, 23) - 0.5) * half_bot * 1.6)
		var sy: int = int(top + 10 + noise(i, 2, 23) * (bottom - top - 18))
		for dy: int in 2:
			for dx: int in 3:
				if inside.call(sx + dx, sy + dy) and fig.colour(sx + dx, sy + dy) != INK:
					fig.put(sx + dx, sy + dy, safe(c.x, c.y, c.z * 0.45))
	for y: int in range(fig.neck - 2, int(top) + 1):
		for x: int in [int(cx - half_top) + 2, int(cx + half_top) - 2]:
			for d: int in 2:
				if fig.has(x + d, y):
					fig.put(x + d, y, safe(c.x, c.y, c.z * 0.6))


## A short beard along the jaw, and a moustache.
static func _piece_beard(fig: Fig, params: Dictionary) -> void:
	if not fig.has_face:
		return
	var c: Vector3 = vec(params.get("colour"), Vector3(32, 0.24, 0.80))
	var fx0: int = fig.face.x
	var fy0: int = fig.face.y
	var fx1: int = fig.face.z
	var fy1: int = fig.face.w
	var h: float = fy1 - fy0
	var mouth_y: float = fy0 + h * 0.80
	var face := PackedByteArray()
	face.resize(fig.w * fig.h)
	var row_lo: PackedInt32Array = PackedInt32Array()
	var row_hi: PackedInt32Array = PackedInt32Array()
	row_lo.resize(fig.h)
	row_hi.resize(fig.h)
	row_lo.fill(fig.w)
	row_hi.fill(-1)
	for y: int in fig.neck:
		for x: int in fig.w:
			if fig.at(x, y) == K.SKIN:
				face[y * fig.w + x] = 1
				row_lo[y] = mini(row_lo[y], x)
				row_hi[y] = maxi(row_hi[y], x)
	var is_face := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < fig.w and y < fig.h and face[y * fig.w + x] == 1
	var inside := func(x: int, y: int) -> bool:
		if not is_face.call(x, y) and not (is_face.call(x, y - 3) and y <= fy1 + 4):
			return false
		if y >= mouth_y - 1:
			return true
		if y < fy0 + h * 0.45 or y >= fig.h or row_hi[y] < 0:
			return false
		var jaw: float = 5.0 + (y - (fy0 + h * 0.45)) / (h * 0.35) * 5.0
		var near_side: bool = fig.way != &"left" and x - row_lo[y] < jaw
		var far_side: bool = fig.way != &"right" and row_hi[y] - x < jaw
		return near_side or far_side
	var hairy := func(x: int, y: int) -> Color:
		return safe(c.x, c.y, c.z * (0.70 + 0.45 * noise(x, y / 2, 61)))
	_fill(fig, _box(fx0 - 4, fy0, fx1 + 4, fy1 + 8), inside, hairy, 2,
		func(x: int, y: int) -> bool:
			var k: int = fig.at(x, y)
			return k != K.SKIN and k != K.PIECE)
	var cx: float = (fx0 + fx1) / 2.0 + {&"left": -(fx1 - fx0) * 0.18, &"right": (fx1 - fx0) * 0.18}.get(fig.way, 0.0)
	var half: float = (fx1 - fx0) * (0.16 if fig.way == &"down" else 0.10)
	var my: int = int(mouth_y) - 3
	for y: int in range(my - 2, my + 2):
		for x: int in range(int(cx - half), int(cx + half) + 1):
			if is_face.call(x, y):
				fig.put(x, y, safe(c.x, c.y, c.z * (0.62 if y < my else 0.85)))
	for x: int in range(int(cx - half * 0.5), int(cx + half * 0.5) + 1):
		fig.put(x, my + 3, INK)


## **The weapon hand**: the one he strikes with in our fight frames — screen left seen
## from the front, screen right from behind, the hand ahead seen from the side — so a
## sword or a bow drawn in it goes out with the blow.
static func _weapon_hand(fig: Fig) -> Array[Vector2i]:
	if fig.hands.is_empty():
		return []
	if fig.way == &"left" or fig.way == &"right":
		# **Seen from the side, the hand in front** (the review of group L): both his arms
		# swing in the walk, so the hand furthest ahead changes every few frames and the
		# weapon jumped from one to the other. The hand in front is the whole one, drawn
		# over his body — the larger blob — and in one of our cells it is the one that moved.
		var best: Array[Vector2i] = []
		var best_moved: bool = false
		for blob: Array[Vector2i] in _blobs(fig, fig.hands):
			var moved: bool = false
			for q: Vector2i in blob:
				if fig.is_moved(q.x, q.y):
					moved = true
					break
			if (moved and not best_moved) or (moved == best_moved and blob.size() > best.size()):
				best = blob
				best_moved = moved
		return best
	var pick: Vector2i = fig.hands[0]
	for q: Vector2i in fig.hands:
		if fig.way == &"down" or fig.way == &"left":
			if q.x < pick.x:
				pick = q
		elif q.x > pick.x:
			pick = q
	var out: Array[Vector2i] = []
	for q: Vector2i in fig.hands:
		if absi(q.x - pick.x) < 12 and absi(q.y - pick.y) < 16:
			out.append(q)
	return out


## The pieces `points` falls into, touching by an edge or a corner.
static func _blobs(fig: Fig, points: Array[Vector2i]) -> Array:
	var left := PackedByteArray()
	left.resize(fig.w * fig.h)
	for q: Vector2i in points:
		left[q.y * fig.w + q.x] = 1
	var out: Array = []
	for start: Vector2i in points:
		if left[start.y * fig.w + start.x] == 0:
			continue
		left[start.y * fig.w + start.x] = 0
		var blob: Array[Vector2i] = [start]
		var todo: Array[Vector2i] = [start]
		while not todo.is_empty():
			var p: Vector2i = todo.pop_back()
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					var q := Vector2i(p.x + dx, p.y + dy)
					if q.x >= 0 and q.y >= 0 and q.x < fig.w and q.y < fig.h and left[q.y * fig.w + q.x] == 1:
						left[q.y * fig.w + q.x] = 0
						blob.append(q)
						todo.append(q)
		out.append(blob)
	return out


## Where an arm comes from, for the weapon to point along it; and whether the hand is
## at rest by his side, in which case the weapon hangs.
static func _shoulder(fig: Fig, fist: Vector2) -> Vector2:
	var side: float = fig.shirt.x + 4.0 if fist.x < (fig.shirt.x + fig.shirt.z) / 2.0 else fig.shirt.z - 4.0
	return Vector2(side, fig.neck + 12.0)


static func _at_rest(fig: Fig, fist: Vector2) -> bool:
	return fist.y > fig.shirt.y + (fig.shirt.w - fig.shirt.y) * 0.55 \
		and fist.x >= fig.shirt.x - 10 and fist.x <= fig.shirt.z + 10


## A sword held in the weapon hand: hanging point down at rest, along the arm in a blow.
static func _piece_sword_in_hand(fig: Fig, params: Dictionary) -> void:
	var hs: Array[Vector2i] = _weapon_hand(fig)
	if hs.is_empty():
		return
	var fist := Vector2.ZERO
	var low: int = 0
	for q: Vector2i in hs:
		fist += Vector2(q)
		low = maxi(low, q.y)
	fist /= float(hs.size())
	var length: float = float(params.get("length", 46))
	var out: float = -1.0 if fig.way == &"down" or fig.way == &"left" else 1.0
	var dir := Vector2(0.28 * out, 1.0).normalized()
	var start := Vector2(fist.x, low + 4)
	if not _at_rest(fig, fist):
		dir = (fist - _shoulder(fig, fist)).normalized()
		start = fist + dir * 6.0
	_blade(fig, start, dir, length, fig.way == &"up")


static func _blade(fig: Fig, start: Vector2, dir: Vector2, length: float, behind: bool) -> void:
	var across := Vector2(-dir.y, dir.x)
	var mask := PackedByteArray()
	mask.resize(fig.w * fig.h)
	var pts: Array[Vector2i] = []
	var box: Rect2i = _box(minf(start.x, start.x + dir.x * length) - 6, minf(start.y, start.y + dir.y * length) - 6,
		maxf(start.x, start.x + dir.x * length) + 6, maxf(start.y, start.y + dir.y * length) + 6)
	box = box.intersection(Rect2i(0, 0, fig.w, fig.h))
	for y: int in range(box.position.y, box.end.y):
		for x: int in range(box.position.x, box.end.x):
			var d: Vector2 = Vector2(x, y) - start
			var t: float = d.dot(dir)
			if t < 0.0 or t > length:
				continue
			var width: float = 3.0 if t < length - 6.0 else 3.0 * (length - t) / 6.0
			if absf(d.dot(across)) <= width and not (behind and fig.has(x, y)):
				mask[y * fig.w + x] = 1
				pts.append(Vector2i(x, y))
	for p: Vector2i in pts:
		var edge: bool = false
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = p + d
			if q.x < 0 or q.y < 0 or q.x >= fig.w or q.y >= fig.h or mask[q.y * fig.w + q.x] == 0:
				edge = true
		var side: float = (Vector2(p) - start).dot(across)
		fig.put(p.x, p.y, INK if edge else safe(212, 0.24, 0.80 if side < 0.0 else 0.55))
		fig.set_kind(p.x, p.y, K.PIECE)
	# The cross-guard, across the blade under the fist.
	var g: Vector2 = start - dir * 1.0
	for i: int in range(-8, 9):
		for j: int in range(-1, 3):
			var q := Vector2i((g + across * i + dir * j).round())
			if behind and fig.has(q.x, q.y):
				continue
			var rim: bool = j == -1 or j == 2 or absi(i) == 8
			fig.put(q.x, q.y, INK if rim else safe(40, 0.6, 0.62))


## A sword at the belt, in its scabbard: the hilt at the hip, the scabbard down the thigh.
static func _piece_scabbard(fig: Fig, params: Dictionary) -> void:
	var c: Vector3 = vec(params.get("colour"), Vector3(24, 0.55, 0.28))
	var x0: int = fig.shirt.x
	var x1: int = fig.shirt.z
	var y1: int = fig.shirt.w
	var sx: float
	var dirx: float
	match fig.way:
		&"up":
			sx = x0 + 10
			dirx = -0.22
		&"down":
			sx = x1 - 10
			dirx = 0.22
		&"left":
			sx = (x0 + x1) / 2.0 + 8
			dirx = 0.45
		_:
			sx = (x0 + x1) / 2.0 - 8
			dirx = -0.45
	var sy: float = y1 - 8
	var length: float = (fig.legs.w - y1) * 0.95 if fig.has_legs else 40.0
	var inside := func(x: int, y: int) -> bool:
		var t: float = y - sy
		return t >= 0.0 and t <= length and absf(x - (sx + dirx * t)) <= 3.0
	_fill(fig, _box(sx - 24, sy, sx + 24, sy + length), inside,
		shade(c, Rect2(sx - 20, sy, 40, length), 43), 1)
	# The chape at its end, and the hilt and guard at the hip, steel.
	for y: int in range(int(sy + length) - 4, int(sy + length) + 1):
		var x: int = int(sx + dirx * (y - sy))
		for dx: int in range(-2, 3):
			if inside.call(x + dx, y):
				fig.put(x + dx, y, safe(STEEL.x, 0.25, 0.7))
	var gx: float = sx - dirx * 2.0
	var gy: float = sy - 2.0
	for y: int in range(int(gy) - 10, int(gy) + 2):
		for x: int in range(int(gx) - 8, int(gx) + 9):
			var guard: bool = absf(y - gy) <= 1.0 and absf(x - gx) <= 7.0
			var grip: bool = absf(x - (gx - dirx * (y - gy))) <= 1.5 and y < gy
			var pommel: bool = pow(x - (gx + dirx * 10.0), 2) + pow(y - (gy - 11.0), 2) <= 5.0
			var rim: bool = absf(y - gy) <= 2.0 and absf(y - gy) > 1.0 and absf(x - gx) <= 8.0
			if guard or grip or pommel:
				fig.put(x, y, safe(STEEL.x, 0.25, 0.75 if guard or pommel else 0.35))
			elif rim:
				fig.put(x, y, INK)


## A longbow in the weapon hand, upright — at his side at rest, held out in a shot.
static func _piece_bow_in_hand(fig: Fig, params: Dictionary) -> void:
	var hs: Array[Vector2i] = _weapon_hand(fig)
	if hs.is_empty():
		return
	var c: Vector3 = vec(params.get("colour"), Vector3(28, 0.60, 0.45))
	var fist := Vector2.ZERO
	for q: Vector2i in hs:
		fist += Vector2(q)
	fist /= float(hs.size())
	var side_on: bool = fig.way == &"left" or fig.way == &"right"
	if side_on and _at_rest(fig, fist):
		# **Seen from the side and at rest, the bow is slung on the back** (the review of
		# group L): held in the hand it stood taller than his face, which sticks out
		# further than his fist, and its limb and string crossed his cheek.
		_bow_slung(fig, c)
		return
	var out: float = -1.0 if fig.way == &"down" or fig.way == &"left" else 1.0
	var up_len: float = minf(58.0, fist.y - 2.0)
	var down_len: float = minf(58.0, float(fig.h - 2) - fist.y)
	var bend: float = 12.0
	var arc_x := func(y: float) -> float:
		var t: float = (y - fist.y) / (up_len if y < fist.y else down_len)
		return fist.x + out * bend * (1.0 - t * t) - out * 2.0
	var limb := func(x: int, y: int) -> bool:
		var span: float = up_len if y < fist.y else down_len
		var t: float = (y - fist.y) / span
		if absf(t) > 1.0:
			return false
		return absf(x - arc_x.call(float(y))) <= 3.2 - absf(t) * 1.6
	var behind: bool = fig.way == &"up"
	var mask: PackedByteArray = _fill(fig, _box(fist.x - 22, fist.y - up_len, fist.x + 22, fist.y + down_len),
		func(x: int, y: int) -> bool: return limb.call(x, y) and not (behind and fig.has(x, y)),
		shade(c, Rect2(fist.x - 20, fist.y - up_len, 40, up_len + down_len), 47, 0.4), 1)
	var sx: int = int(fist.x - out * 2.0)
	for y: int in range(int(fist.y - up_len) + 2, int(fist.y + down_len) - 1):
		if y < 0 or y >= fig.h or sx < 0 or sx >= fig.w or mask[y * fig.w + sx] == 1:
			continue
		if behind and fig.has(sx, y):
			continue
		fig.put(sx, y, safe(40, 0.30, 0.78))


## A bow carried across the back, seen from the side: behind him from the shoulder to
## the back of the knee, bowed away from his back, only where he does not hide it.
static func _bow_slung(fig: Fig, c: Vector3) -> void:
	var back: float = 1.0 if fig.way == &"left" else -1.0
	var edge: float = -1.0
	for y: int in range(fig.neck, mini(fig.neck + 15, fig.h)):
		for x: int in fig.w:
			if fig.at(x, y) == K.SHIRT:
				edge = float(x) if edge < 0.0 else (maxf(edge, x) if back > 0.0 else minf(edge, x))
	if edge < 0.0:
		return
	var top := Vector2(edge + back * 2.0, fig.neck - 16.0)
	var bottom := Vector2(edge + back * 4.0, (fig.legs.w if fig.has_legs else fig.h - 4) - 16.0)
	var along := func(y: int) -> float:
		return clampf((y - top.y) / (bottom.y - top.y), 0.0, 1.0)
	var limb := func(x: int, y: int) -> bool:
		if y < top.y or y > bottom.y or fig.has(x, y):
			return false
		var t: float = along.call(y)
		var mid: float = lerpf(top.x, bottom.x, t) + back * 10.0 * sin(PI * t)
		return absf(x - mid) <= 2.6 - absf(t - 0.5) * 1.2
	var mask: PackedByteArray = _fill(fig, _box(minf(top.x, bottom.x) - 16, top.y, maxf(top.x, bottom.x) + 16, bottom.y),
		limb, shade(c, Rect2(top.x - 12, top.y, 24, bottom.y - top.y), 47, 0.4), 1)
	for y: int in range(int(top.y) + 2, int(bottom.y) - 1):
		var x: int = int(round(lerpf(top.x, bottom.x, along.call(y))))
		if x >= 0 and y >= 0 and x < fig.w and y < fig.h and mask[y * fig.w + x] == 0 and not fig.has(x, y):
			fig.put(x, y, safe(40, 0.30, 0.78))
			fig.set_kind(x, y, K.PIECE)


## Where his backpack was: a quiver, and the fletchings over its mouth.
static func _piece_quiver(fig: Fig, params: Dictionary) -> void:
	if fig.way == &"down":
		return
	var p: Vector4i = _pack_box(fig)
	if p.z < 0:
		return
	_piece_remove_pack(fig, {})
	var c: Vector3 = vec(params.get("colour"), Vector3(24, 0.55, 0.32))
	var cx: float = (p.x + p.z) / 2.0
	if fig.way == &"left":
		cx = p.x + 4
	elif fig.way == &"right":
		cx = p.z - 4
	var tilt: float = {&"left": 0.35, &"right": -0.35, &"up": 0.30}.get(fig.way, 0.0)
	var top: float = maxf(p.y - 4, 16.0)
	var bottom: float = p.w + 8
	var inside := func(x: int, y: int) -> bool:
		return y >= top and y <= bottom and absf(x - (cx + tilt * (bottom - y))) <= 6.0
	_fill(fig, _box(cx - 30, top, cx + 30, bottom), inside, shade(c, Rect2(cx - 8, top, 20, bottom - top), 53), 2)
	for i: int in 3:
		var off: float = [-4.0, 0.0, 4.0][i]
		var fx: float = cx + tilt * (bottom - top) + off
		for y: int in range(int(top) - 14, int(top) + 1):
			for x: int in range(int(fx) - 2, int(fx) + 3):
				var k: int = fig.at(x, y)
				if k == K.HAIR or k == K.SKIN:
					continue
				var rim: bool = absf(x - fx) >= 2.0 or y == int(top) - 14
				fig.put(x, y, INK if rim else safe(0, 0.30, 0.62 if i == 1 else 0.80))


# ------------------------------------------------------------------- the board ---

## Every look standing in three facings, close up and at the game's size, with his
## shader's discard already applied (the sheets carry none of his chequer anyway).
func _board(dressed: Dictionary, frames: SpriteFrames) -> void:
	var ways: Array[StringName] = [&"down", &"left", &"up"]
	var cell := Vector2i(200, 250)
	var names: Array = dressed.keys()
	var sheet_h: int = cell.y * ways.size() + 110
	var board: Image = Image.create(cell.x * names.size(), sheet_h, false, Image.FORMAT_RGBA8)
	board.fill(Color8(34, 31, 28))
	var ground: Color = Color8(118, 104, 78)
	for i: int in names.size():
		var look: StringName = StringName(String(names[i]))
		var img: Image = dressed[names[i]] as Image
		var scale: float = CastLooks.scale_of(look)
		board.fill_rect(Rect2i(i * cell.x + 3, 3, cell.x - 6, cell.y * ways.size() - 6), ground)
		board.fill_rect(Rect2i(i * cell.x + 3, cell.y * ways.size() + 6, cell.x - 6, 100), ground)
		for j: int in ways.size():
			var slice := frames.get_frame_texture(StringName("idle_" + String(ways[j])), 0) as AtlasTexture
			var r: Rect2i = CastLooks.with_room(Rect2i(slice.region), _room)
			var one: Image = img.get_region(r)
			if scale != 1.0:
				one.resize(int(one.get_width() * scale), int(one.get_height() * scale), Image.INTERPOLATE_NEAREST)
			var at := Vector2i(i * cell.x + (cell.x - one.get_width()) / 2, (j + 1) * cell.y - one.get_height() - 6)
			board.blend_rect(one, Rect2i(Vector2i.ZERO, one.get_size()), at)
			if j < 2:
				var small: Image = one.duplicate() as Image
				var k: float = 70.0 / 197.0
				small.resize(maxi(1, int(small.get_width() * k)), maxi(1, int(small.get_height() * k)), Image.INTERPOLATE_BILINEAR)
				var sat := Vector2i(i * cell.x + cell.x / 2 + (j * 2 - 1) * 34 - small.get_width() / 2,
					sheet_h - 10 - small.get_height())
				board.blend_rect(small, Rect2i(Vector2i.ZERO, small.get_size()), sat)
	DirAccess.make_dir_recursive_absolute(BOARD_PNG.get_base_dir())
	board.save_png(BOARD_PNG)
	print("wrote %s — looks in this order: %s" % [BOARD_PNG, ", ".join(PackedStringArray(names))])
