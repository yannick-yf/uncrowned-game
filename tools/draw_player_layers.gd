extends SceneTree

## Builds `view3d/layers/<part>.png`: his brother's traveller split into the layers the
## player is drawn in (group A, `docs/CREATION_AND_GEAR.md` §3; `PaperDoll`).
##
## **Split, not repainted.** Every visible pixel of his — his walk frames and our fight
## cells, from `view3d/fight/traveler_sheet.png` — goes to exactly one layer: his outline
## and eyes to `body`, his skin to `skin`, his shirt to `tunic`, his trousers and boots,
## his pack with its straps and belt, his hair to `hair_spiky`. So the layers stacked in
## `PaperDoll.ORDER` give his traveller back **pixel for pixel**, and `test_paper_doll`
## holds that.
##
## **One thing is added, and only where it cannot show.** His hair is drawn over nothing:
## take it off and there is no head under it. So a head is painted into `skin` — a skull,
## in his skin's own colour, shaded from the top left, with his dark outline — **only on
## pixels his hair covers**, so his traveller is unchanged and a shaved head, or a short
## cut, has a head to stand on.
##
## It measures each frame with `tools/draw_cast_looks.gd`'s own functions, so a part is
## found exactly where group L's looks found it, and it keeps the same room round his
## frames, so the window reads these sheets with the frames it already has.
##
##     godot --headless --path . -s tools/draw_player_layers.gd
##     godot --headless --path . -s tools/draw_player_layers.gd -- --board
##
## `--board` writes `docs/frames/creation/layers.png`: his traveller restacked, then
## without his hair, in three facings, close up and at the game's size.

const Looks := preload("res://tools/draw_cast_looks.gd")
const BOARD_PNG: String = "docs/frames/creation/layers.png"
const CLEAR: Color = Color(0, 0, 0, 0)
const INK: Color = Color8(22, 14, 14)

var _room: int = 8


func _initialize() -> void:
	var sheet: Image = Image.load_from_file(Looks.BASE_SHEET)
	var frames: SpriteFrames = load(World3d.HIS_FRAMES) as SpriteFrames
	if sheet == null or frames == null:
		push_error("his sheet or his frames are missing — run tools/draw_fight_frames.gd and tools/vendor_workshop.sh")
		quit(1)
		return
	sheet.convert(Image.FORMAT_RGBA8)
	_room = CastLooks.room_px()
	var outs: Dictionary = {}
	for part: StringName in PaperDoll.HIS_PARTS:
		var out: Image = Image.create(sheet.get_width(), sheet.get_height(), false, Image.FORMAT_RGBA8)
		out.fill(CLEAR)
		outs[part] = out
	for frame: Dictionary in _his_frames(frames):
		var region: Rect2i = frame["region"] as Rect2i
		var parts: Dictionary = split_region(sheet, region, frame["way"] as StringName, _room)
		_stamp_all(outs, parts, CastLooks.with_room(region, _room).position)
	for cell: Dictionary in _our_cells(sheet, frames):
		_stamp_all(outs, split_cell(sheet, cell), (cell["rect"] as Rect2i).position)
	DirAccess.make_dir_recursive_absolute(PaperDoll.DIR)
	for part: StringName in outs.keys():
		var path: String = PaperDoll.sheet_path(part)
		if (outs[part] as Image).save_png(path) != OK:
			push_error("could not write %s" % path)
			quit(1)
			return
		print("wrote %s" % path)
	if OS.get_cmdline_user_args().has("--board"):
		_board(outs, frames)
	quit(0)


func _his_frames(frames: SpriteFrames) -> Array[Dictionary]:
	var seen: Dictionary = {}
	var out: Array[Dictionary] = []
	for named: StringName in frames.get_animation_names():
		for i: int in frames.get_frame_count(named):
			var slice := frames.get_frame_texture(named, i) as AtlasTexture
			if slice == null or seen.has(Rect2i(slice.region)):
				continue
			seen[Rect2i(slice.region)] = true
			out.append({"region": Rect2i(slice.region), "way": StringName(String(named).get_slice("_", 1))})
	return out


func _our_cells(sheet: Image, frames: SpriteFrames) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var cell: Vector2i = World3d.OUR_CELL
	var below: int = sheet.get_height() - cell.y * World3d.OUR_WAYS.size()
	for row: int in World3d.OUR_WAYS.size():
		var way: StringName = World3d.OUR_WAYS[row]
		var base := Rect2i((frames.get_frame_texture(StringName("idle_" + String(way)), 0) as AtlasTexture).region)
		for col: int in World3d.OUR_POSES.size():
			out.append({"rect": Rect2i(col * cell.x, below + row * cell.y, cell.x, cell.y), "way": way,
				"pose": World3d.OUR_POSES[col], "base": base, "at": (cell - base.size) / 2})
	return out


static func _stamp_all(outs: Dictionary, parts: Dictionary, at: Vector2i) -> void:
	for part: StringName in parts.keys():
		var img: Image = parts[part] as Image
		var out: Image = outs[part] as Image
		for y: int in img.get_height():
			for x: int in img.get_width():
				var c: Color = img.get_pixel(x, y)
				if c.a > 0.0:
					out.set_pixel(at.x + x, at.y + y, c)


# ------------------------------------------------------------------- splitting ---

## One of his frames split into his parts, with `room` kept round it: exactly what each
## layer's sheet holds at `CastLooks.with_room(region, room)`.
static func split_region(sheet: Image, region: Rect2i, way: StringName, room: int) -> Dictionary:
	var rect: Rect2i = CastLooks.with_room(region, room)
	var img: Image = Looks._crop(sheet, rect, Rect2i(region.position - rect.position, region.size))
	var fig := Looks.Fig.new(img, way)
	Looks._measure(fig, null)
	return _split(fig)


## One of our fight cells: measured on the idle frame it was built from, as the looks are;
## a flinch is the idle frame split, then cut and moved as `draw_fight_frames.gd` cuts it.
static func split_cell(sheet: Image, cell: Dictionary) -> Dictionary:
	var rect: Rect2i = cell["rect"] as Rect2i
	var way: StringName = cell["way"] as StringName
	var base: Rect2i = cell["base"] as Rect2i
	var at: Vector2i = cell["at"] as Vector2i
	var idle_img: Image = Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	idle_img.fill(CLEAR)
	idle_img.blit_rect(Looks._crop(sheet, base, Rect2i(Vector2i.ZERO, base.size)), Rect2i(Vector2i.ZERO, base.size), at)
	var idle := Looks.Fig.new(idle_img, way)
	Looks._measure(idle, null)
	if cell["pose"] == &"hurt":
		var parts: Dictionary = _split(idle)
		for part: StringName in parts.keys():
			parts[part] = Looks._flinch(parts[part] as Image, at, base.size, way)
		return parts
	var img: Image = Looks._crop(sheet, rect, Rect2i(Vector2i.ZERO, rect.size))
	var fig := Looks.Fig.new(img, way)
	Looks._measure(fig, idle)
	return _split(fig)


static func _split(fig: Looks.Fig) -> Dictionary:
	var parts: Dictionary = {}
	for part: StringName in PaperDoll.HIS_PARTS:
		var img: Image = Image.create(fig.w, fig.h, false, Image.FORMAT_RGBA8)
		img.fill(CLEAR)
		parts[part] = img
	# Where his boots begin: the first leather below his torso.
	var boots_top: int = fig.h
	for y: int in range(fig.shirt.w + 4, fig.h):
		for x: int in fig.w:
			if fig.at(x, y) == Looks.K.LEATHER:
				boots_top = mini(boots_top, y)
	var hair := PackedByteArray()
	hair.resize(fig.w * fig.h)
	for y: int in fig.h:
		for x: int in fig.w:
			if fig.at(x, y) == 0:
				continue
			var part: StringName = _part_of(fig, x, y, boots_top)
			(parts[part] as Image).set_pixel(x, y, fig.colour(x, y))
			if part == &"hair_spiky":
				hair[y * fig.w + x] = 1
	_skull(fig, hair, parts[&"skin"] as Image)
	return parts


## Which of his parts one of his pixels belongs to.
static func _part_of(fig: Looks.Fig, x: int, y: int, boots_top: int) -> StringName:
	var k: int = fig.at(x, y)
	if fig.in_pack(x, y):
		return &"pack"
	if y < fig.neck:
		match k:
			Looks.K.HAIR, Looks.K.TROUSERS:
				return &"hair_spiky"
			Looks.K.SKIN:
				# The lightest strands of his hair are as pale as skin: one with more hair
				# round it than skin is a strand.
				return &"hair_spiky" if _count(fig, x, y, Looks.K.HAIR, 2) > _count(fig, x, y, Looks.K.SKIN, 2) \
					else &"skin"
			Looks.K.SHIRT:
				return &"tunic"
			Looks.K.INK:
				# His eyes and the line of his face are the face's; every other dark line in
				# his head is the line round his hair, however far from a strand.
				if _in_the_face(fig, x, y) or _near(fig, x, y, Looks.K.SKIN, 2):
					return &"body"
				return &"hair_spiky"
			_:
				# The warm rim his face is painted with goes with the skin, so a darker
				# skin carries it rather than wearing a halo.
				return &"skin" if _near(fig, x, y, Looks.K.SKIN, 2) else &"hair_spiky"
	match k:
		Looks.K.SHIRT:
			return &"tunic"
		Looks.K.SKIN:
			return &"skin"
		Looks.K.TROUSERS:
			return &"boots" if y >= boots_top else &"trousers"
		Looks.K.LEATHER:
			return &"boots" if y >= boots_top else &"pack"
		Looks.K.OTHER:
			return &"boots" if y >= boots_top else &"body"
	return &"body"


static func _count(fig: Looks.Fig, x: int, y: int, kind: int, r: int) -> int:
	var n: int = 0
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			if fig.at(x + dx, y + dy) == kind:
				n += 1
	return n


static func _near(fig: Looks.Fig, x: int, y: int, kind: int, r: int) -> bool:
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			if fig.at(x + dx, y + dy) == kind:
				return true
	return false


## Skin on both sides of it, along its row: an eye, or the line of his cheek.
static func _in_the_face(fig: Looks.Fig, x: int, y: int) -> bool:
	if not fig.has_face:
		return false
	var left: bool = false
	var right: bool = false
	for d: int in range(1, 13):
		if fig.at(x - d, y) == Looks.K.SKIN:
			left = true
		if fig.at(x + d, y) == Looks.K.SKIN:
			right = true
	return left and right


## **A head under his hair**, painted into the skin layer only where his hair is: his
## traveller is unchanged, and a shorter cut has a skull to sit on. Seen from the front
## it rises from the face; from the side it reaches back behind the face; from behind it
## fills the back of the head down to the neck.
static func _skull(fig: Looks.Fig, hair: PackedByteArray, skin: Image) -> void:
	var tones: Array[Color] = []
	for y: int in fig.h:
		for x: int in fig.w:
			if fig.at(x, y) == Looks.K.SKIN and y < fig.neck:
				tones.append(fig.colour(x, y))
	if tones.is_empty():
		return
	tones.sort_custom(func(a: Color, b: Color) -> bool: return a.v < b.v)
	var tone: Color = tones[tones.size() * 3 / 5]
	var hw: float = fig.head.z - fig.head.x
	var hh: float = fig.neck - fig.head.y
	var cx: float
	var rx: float
	var top: float
	var waist: float
	var bottom: float
	if fig.has_face:
		var fw: float = fig.face.z - fig.face.x
		var fh: float = fig.face.w - fig.face.y
		var back: float = {&"left": 1.0, &"right": -1.0}.get(fig.way, 0.0)
		cx = (fig.face.x + fig.face.z) / 2.0 + back * fw * 0.30
		rx = fw * (0.58 if back == 0.0 else 0.80)
		top = fig.face.y - fh * 0.80
		waist = fig.face.y + fh * 0.15
		# Down the sides of his face to the jaw: his hair covered his cheeks.
		bottom = fig.face.w + 1.0
	else:
		cx = (fig.head.x + fig.head.z) / 2.0
		rx = hw * 0.31
		top = fig.head.y + hh * 0.30
		waist = fig.head.y + hh * 0.62
		bottom = fig.neck - 1.0
	top = maxf(top, fig.head.y + 2.0)
	# **Wide enough to carry his ears**: they stand where his hair was, and a skull that
	# stops short of them leaves them floating beside the head.
	var ear_reach: float = 0.0
	for y: int in range(int(top), fig.neck):
		for x: int in fig.w:
			if fig.at(x, y) != Looks.K.SKIN:
				continue
			var in_face: bool = fig.has_face and x >= fig.face.x - 2 and x <= fig.face.z + 2
			if not in_face and _count(fig, x, y, Looks.K.SKIN, 2) > _count(fig, x, y, Looks.K.HAIR, 2):
				ear_reach = maxf(ear_reach, absf(x - cx) - 4.0)
	rx = maxf(rx, minf(ear_reach, hw * 0.45))
	var inside := func(x: int, y: int) -> bool:
		if y < top or y > bottom:
			return false
		if y <= waist:
			return pow((x - cx) / rx, 2) + pow((waist - y) / (waist - top), 2) <= 1.0
		return absf(x - cx) <= rx * (1.0 - 0.22 * pow((y - waist) / maxf(bottom - waist, 1.0), 2))
	var shape := PackedByteArray()
	shape.resize(fig.w * fig.h)
	for y: int in fig.h:
		for x: int in fig.w:
			if inside.call(x, y):
				shape[y * fig.w + x] = 1
	for y: int in fig.h:
		for x: int in fig.w:
			var i: int = y * fig.w + x
			if shape[i] == 0 or hair[i] == 0:
				continue
			var edge: bool = false
			for d: Vector2i in [Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, -3), Vector2i(2, 2), Vector2i(-2, 2), Vector2i(2, -2), Vector2i(-2, -2)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x < 0 or q.y < 0 or q.x >= fig.w or q.y >= fig.h:
					edge = true
				elif shape[q.y * fig.w + q.x] == 0 and fig.at(q.x, q.y) != Looks.K.SKIN:
					edge = true
			if edge:
				skin.set_pixel(x, y, INK)
				continue
			var u: float = (x - (cx - rx)) / (2.0 * rx)
			var w: float = (y - top) / maxf(bottom - top, 1.0)
			var light: float = 1.0 - 0.5 * u - 0.35 * w
			var g: float = (Looks.noise(x / 2, y / 2, 91) - 0.5) * 0.04
			skin.set_pixel(x, y, Color.from_hsv(tone.h, tone.s * (1.05 - 0.15 * light), clampf(tone.v * (0.86 + 0.22 * light) + g, 0.0, 1.0)))


# ------------------------------------------------------------------- the board ---

func _board(outs: Dictionary, frames: SpriteFrames) -> void:
	var ways: Array[StringName] = [&"down", &"left", &"up"]
	var cell := Vector2i(190, 240)
	var board: Image = Image.create(cell.x * ways.size() * 2, cell.y + 90, false, Image.FORMAT_RGBA8)
	board.fill(Color8(34, 31, 28))
	var ground: Color = Color8(118, 104, 78)
	for variant: int in 2:
		for j: int in ways.size():
			var slice := frames.get_frame_texture(StringName("idle_" + String(ways[j])), 0) as AtlasTexture
			var r: Rect2i = CastLooks.with_room(Rect2i(slice.region), _room)
			var one: Image = Image.create(r.size.x, r.size.y, false, Image.FORMAT_RGBA8)
			one.fill(CLEAR)
			for part: StringName in PaperDoll.HIS_PARTS:
				if variant == 1 and part == &"hair_spiky":
					continue
				var layer: Image = (outs[part] as Image).get_region(r)
				one.blend_rect(layer, Rect2i(Vector2i.ZERO, r.size), Vector2i.ZERO)
			var x0: int = (variant * ways.size() + j) * cell.x
			board.fill_rect(Rect2i(x0 + 3, 3, cell.x - 6, cell.y - 6), ground)
			board.blend_rect(one, Rect2i(Vector2i.ZERO, one.get_size()), Vector2i(x0 + (cell.x - r.size.x) / 2, cell.y - r.size.y - 6))
			board.fill_rect(Rect2i(x0 + 3, cell.y + 3, cell.x - 6, 84), ground)
			var small: Image = one.duplicate() as Image
			small.resize(maxi(1, int(r.size.x * 70.0 / 197.0)), maxi(1, int(r.size.y * 70.0 / 197.0)), Image.INTERPOLATE_BILINEAR)
			board.blend_rect(small, Rect2i(Vector2i.ZERO, small.get_size()), Vector2i(x0 + (cell.x - small.get_width()) / 2, cell.y + 84 - small.get_height()))
	DirAccess.make_dir_recursive_absolute(BOARD_PNG.get_base_dir())
	board.save_png(BOARD_PNG)
	print("wrote %s — his traveller restacked, then the same without his hair" % BOARD_PNG)
