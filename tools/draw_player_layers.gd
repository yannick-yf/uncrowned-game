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
	for part: StringName in all_parts():
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
	var items: Dictionary = _items(img, way, null)
	var fig := Looks.Fig.new(img, way)
	Looks._measure(fig, null)
	var parts: Dictionary = _split(fig)
	parts.merge(items)
	return parts


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
		var items: Dictionary = _items(idle_img, way, null)
		var parts: Dictionary = _split(idle)
		parts.merge(items)
		for part: StringName in parts.keys():
			parts[part] = Looks._flinch(parts[part] as Image, at, base.size, way)
		return parts
	var img: Image = Looks._crop(sheet, rect, Rect2i(Vector2i.ZERO, rect.size))
	var cell_items: Dictionary = _items(img, way, idle)
	var fig := Looks.Fig.new(img, way)
	Looks._measure(fig, idle)
	var whole: Dictionary = _split(fig)
	whole.merge(cell_items)
	return whole


## Every sheet this tool writes: his parts, the painted styles, and the items' layers and
## masks (E4).
static func all_parts() -> Array[StringName]:
	var out: Array[StringName] = PaperDoll.HIS_PARTS + PaperDoll.STYLE_PARTS
	out.append(PaperDoll.BARE_SKIN)
	var items: Dictionary = item_layers()
	for layer: StringName in items.keys():
		out.append(layer)
		if bool((items[layer] as Dictionary)["mask"]):
			out.append(StringName(String(layer) + "_mask"))
	return out


## **The items' layers** (E4): each layer an item of `content/items.json` is drawn with,
## and the pieces of `draw_cast_looks.gd` that draw it — the cap a works' guard wears, the
## king's guard's helm and plate, a sword at the belt or in the hand, a bow.
static func item_layers() -> Dictionary:
	var out: Dictionary = {}
	for item: StringName in ItemRules.items():
		var row: Dictionary = ItemRules.row(item)
		var draw: Dictionary = row.get("draw", {}) as Dictionary
		for layer: String in draw.keys():
			out[StringName(layer)] = {"pieces": draw[layer], "recolour": row.get("draw_recolour", {}),
				"mask": bool(row.get("hides_hair", false))}
	return out


## His figure dressed in each item, against his figure undressed: **what changed is the
## item's layer, and what the piece took away from his head is its mask** — a helm's hiding
## of his hair, his ears and their outline, a cap's of his crown.
static func _items(img: Image, way: StringName, from: Looks.Fig) -> Dictionary:
	var out: Dictionary = {}
	var items: Dictionary = item_layers()
	for layer: StringName in items.keys():
		var spec: Dictionary = items[layer] as Dictionary
		var dressed: Image = img.duplicate() as Image
		var fig := Looks.Fig.new(dressed, way)
		Looks._measure(fig, from)
		Looks._wear(fig, {"recolour": spec["recolour"], "pieces": spec["pieces"]})
		var drawn: Image = Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
		drawn.fill(CLEAR)
		var mask: Image = Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
		mask.fill(CLEAR)
		for y: int in img.get_height():
			for x: int in img.get_width():
				var was: Color = img.get_pixel(x, y)
				var now: Color = dressed.get_pixel(x, y)
				if now.a > 0.0 and (was.a == 0.0 or not now.is_equal_approx(was)):
					drawn.set_pixel(x, y, now)
				elif was.a > 0.0 and now.a == 0.0 and y < fig.neck + 8:
					mask.set_pixel(x, y, Color.WHITE)
		out[layer] = drawn
		if bool(spec["mask"]):
			out[StringName(String(layer) + "_mask")] = mask
	return out


static func _split(fig: Looks.Fig) -> Dictionary:
	var parts: Dictionary = {}
	for part: StringName in PaperDoll.HIS_PARTS + PaperDoll.STYLE_PARTS:
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
	# **Bare skin, for every cut but his** (the review of group E): his face is shaded
	# darker where his fringe falls on it, and its warm rim runs along the fringe's edge.
	# Under his own hair that is the shadow of his hair; under a shorter cut it read as an
	# orange line across the forehead and down the cheeks. A second skin, worn with every
	# other style, gives what lies within two pixels of his hair to the head painted under
	# it — and his own skin, worn with his own hair, stays his, pixel for pixel.
	var bare: Image = (parts[&"skin"] as Image).duplicate() as Image
	var shaded := hair.duplicate()
	for y: int in fig.neck:
		for x: int in fig.w:
			var i: int = y * fig.w + x
			if hair[i] == 0 and bare.get_pixel(x, y).a > 0.0 and _near(fig, x, y, Looks.K.HAIR, 2):
				shaded[i] = 1
	_skull(fig, hair, parts[&"skin"] as Image)
	_skull(fig, shaded, bare)
	parts[PaperDoll.BARE_SKIN] = bare
	_styles(fig, parts)
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
## **Where his head is under his hair**, in this frame: its centre and half-width, the top
## of the skull, where its dome meets its sides, how far down its sides go, and the tone of
## his skin. Seen from the front it rises from the face; from the side it reaches back
## behind the face; from behind it fills the back of the head down to the neck. The hair
## styles and the beards (A4) are placed on it.
static func skull_of(fig: Looks.Fig) -> Dictionary:
	var tones: Array[Color] = []
	for y: int in fig.h:
		for x: int in fig.w:
			if fig.at(x, y) == Looks.K.SKIN and y < fig.neck:
				tones.append(fig.colour(x, y))
	if tones.is_empty():
		return {}
	tones.sort_custom(func(a: Color, b: Color) -> bool: return a.v < b.v)
	var hw: float = fig.head.z - fig.head.x
	var hh: float = fig.neck - fig.head.y
	var back: float = {&"left": 1.0, &"right": -1.0}.get(fig.way, 0.0)
	var cx: float
	var rx: float
	var top: float
	var waist: float
	var bottom: float
	if fig.has_face:
		var fw: float = fig.face.z - fig.face.x
		var fh: float = fig.face.w - fig.face.y
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
	return {"cx": cx, "rx": rx, "top": top, "waist": waist, "bottom": bottom, "back": back,
		"tone": tones[tones.size() * 3 / 5]}


static func _skull(fig: Looks.Fig, hair: PackedByteArray, skin: Image) -> void:
	var geo: Dictionary = skull_of(fig)
	if geo.is_empty():
		return
	var tone: Color = geo["tone"] as Color
	var cx: float = geo["cx"]
	var rx: float = geo["rx"]
	var top: float = geo["top"]
	var waist: float = geo["waist"]
	var bottom: float = geo["bottom"]
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


# ------------------------------------------------------------------- the styles ---

## **The other hair styles and the beards** (A4), painted on the head `skull_of` finds and
## filled from his own hair's pixels in the same frame, mapped across the new shape — so a
## short cut or a braid carries his strands, his highlights and his outline.
static func _styles(fig: Looks.Fig, parts: Dictionary) -> void:
	var geo: Dictionary = skull_of(fig)
	var his: Image = parts[&"hair_spiky"] as Image
	var source: Rect2i = his.get_used_rect()
	if geo.is_empty() or source.size.x < 8:
		return
	var cx: float = geo["cx"]
	var rx: float = geo["rx"]
	var top: float = geo["top"]
	var waist: float = geo["waist"]
	var bottom: float = geo["bottom"]
	var back: float = geo["back"]
	var neck: float = fig.neck
	var face: bool = fig.has_face
	var fx0: float = fig.face.x
	var fx1: float = fig.face.z
	var fy0: float = fig.face.y
	var fh: float = fig.face.w - fig.face.y
	var fw: float = fx1 - fx0
	# Seen from behind, a cut covers the head down to the nape; from the front it stops
	# above the ears.
	var ear_line: float = fy0 + fh * 0.30 if face else bottom - 3.0
	# **Tufts, not a bowl** (the first board): the outer edge rises and falls in uneven
	# locks, as his own hair's does, rather than following the skull's smooth dome.
	var tuft := func(x: int, y: int) -> float:
		var angle: float = atan2(waist - y, (x - cx) * 0.8)
		var lock: int = int(floor(angle * 7.0 + 20.0))
		return 3.0 * Looks.noise(lock, 3, 101) + 2.0 * Looks.noise(lock, 5, 103)
	var dome := func(x: int, y: int, grow: float) -> bool:
		var g: float = grow + (tuft.call(x, y) if grow > 0.0 else 0.0)
		return y <= waist and pow((x - cx) / (rx + g), 2) + pow((waist - y) / (waist - top + g), 2) <= 1.0
	var sides := func(x: int, y: int, grow: float, low: float) -> bool:
		return y > waist and y <= low and absf(x - cx) <= rx + grow
	# The face stays clear below a fringe of uneven strands, each a few pixels wide and
	# pointed, as his own fringe falls.
	var in_face := func(x: int, y: int) -> bool:
		if not face or x < fx0 - 1 or x > fx1 + 1:
			return false
		var strand: int = int(floor((x - fx0 + 3.0) / 10.0))
		var within: float = fposmod(x - fx0 + 3.0, 10.0) / 10.0
		var depth: float = fh * (0.10 + 0.26 * Looks.noise(strand, 7, 107))
		var point: float = depth * (1.0 - pow(absf(within - 0.5) * 2.0, 1.5) * 0.85)
		return y > fy0 + maxf(point, fh * 0.04)
	# Seen from the side, the back of the head is hair down to the nape, behind the ear.
	var behind_face: float = (fx1 + 3.0) if back > 0.0 else (fx0 - 3.0)
	var nape := func(x: int, y: int) -> bool:
		return back != 0.0 and (x - behind_face) * back > 0.0 and sides.call(x, y, 5.0, bottom - 3.0)
	var short := func(x: int, y: int) -> bool:
		return (dome.call(x, y, 5.0) or sides.call(x, y, 5.0, ear_line) or nape.call(x, y)) and not in_face.call(x, y)
	var hair_against := func(_x: int, _y: int) -> bool: return true
	# Short: close to the skull, the ears showing.
	_paint(fig, parts[&"hair_short"] as Image, short, his, source, 3, hair_against)
	# Long: the short cut, and hair falling past the jaw to the shoulders — **in disorder**
	# (Yannick, on the first board): locks of uneven length, an edge that comes and goes.
	var long_hair := func(x: int, y: int) -> bool:
		if short.call(x, y):
			return true
		if y <= waist or in_face.call(x, y):
			return false
		var lock: int = int(floor((x - cx) / 5.0)) + 40
		var low: float = neck + 14.0 + 14.0 * Looks.noise(lock, 11, 109)
		if y > low:
			return false
		var d: float = absf(x - cx)
		var t: float = (y - waist) / (neck + 20.0 - waist)
		var band: int = int(floor((y - waist) / 6.0))
		var reach: float = (rx + 6.0) * (1.0 - 0.10 * t * t) + 5.0 * Looks.noise(band, 13 + int(signf(x - cx)), 111) - 1.0
		if back == 0.0 and face:
			return d >= fw * 0.42 and d <= reach
		if back != 0.0:
			return (x - cx) * back >= -rx * 0.15 and d <= reach
		return d <= reach
	_paint(fig, parts[&"hair_long"] as Image, long_hair, his, source, 3, hair_against)
	# **Tied: every hair pulled back** (Yannick, on the first board): close to the skull, the
	# forehead bare under a clean hairline, combed back, and the tail behind.
	var hairline := func(x: int, y: int) -> bool:
		if not face or x < fx0 - 1 or x > fx1 + 1:
			return false
		var u: float = (x - (fx0 + fx1) / 2.0) / maxf(fw / 2.0, 1.0)
		return y > fy0 - fh * 0.06 + fh * 0.10 * u * u
	var slick := func(x: int, y: int) -> bool:
		var close: bool = dome.call(x, y, -1.0) or sides.call(x, y, 1.0, ear_line) \
			or (back != 0.0 and (x - behind_face) * back > 0.0 and sides.call(x, y, 1.0, bottom - 3.0))
		return close and not hairline.call(x, y)
	var tail_from := Vector2(cx + back * (rx + 1.0), waist - 4.0) if back != 0.0 else Vector2(cx, waist - 2.0)
	var tail_to := Vector2(cx + back * (rx + 8.0), neck + 24.0) if back != 0.0 else Vector2(cx, neck + 30.0)
	var tail := func(x: int, y: int) -> bool:
		if face and back == 0.0:
			return false
		var t: float = clampf((Vector2(x, y) - tail_from).dot(tail_to - tail_from) / (tail_to - tail_from).length_squared(), 0.0, 1.0)
		var on: Vector2 = tail_from.lerp(tail_to, t)
		return Vector2(x, y).distance_to(on) <= 8.0 - 3.0 * t
	var tied := func(x: int, y: int) -> bool:
		return slick.call(x, y) or (tail.call(x, y) and not hairline.call(x, y))
	_paint(fig, parts[&"hair_tied"] as Image, tied, his, source, 3, hair_against)
	_combed(parts[&"hair_tied"] as Image, slick, fig, cx, top, back)
	_band(parts[&"hair_tied"] as Image, tail_from.lerp(tail_to, 0.10), tail_to - tail_from, 7.0)
	# **Braided: cornrows** (Yannick, on the first board: *« comme Allen Iverson »*) — rows
	# plaited flat to the skull from the hairline to the nape, the scalp showing between
	# them — and the braids that hang from them.
	var row_of := func(x: int, y: int) -> float:
		# From the front or behind the rows run up and over; from the side, front to back.
		return float(x) - cx if back == 0.0 else float(y) - top
	var cornrow := func(x: int, y: int) -> bool:
		var close: bool = dome.call(x, y, 0.0) or sides.call(x, y, 0.0, ear_line) \
			or (back != 0.0 and (x - behind_face) * back > 0.0 and sides.call(x, y, 0.0, bottom - 3.0))
		return close and not hairline.call(x, y) and fposmod(row_of.call(x, y) + 3.0, 9.0) < 6.0
	var braids: Array[Array] = []
	if face and back == 0.0:
		braids = [[Vector2(cx - fw * 0.52, fy0 + fh * 0.45), Vector2(cx - fw * 0.55, neck + 24.0)],
			[Vector2(cx + fw * 0.52, fy0 + fh * 0.45), Vector2(cx + fw * 0.55, neck + 24.0)]]
	elif back != 0.0:
		braids = [[Vector2(cx + back * rx * 0.75, waist), Vector2(cx + back * (rx * 0.75 + 6.0), neck + 22.0)]]
	else:
		braids = [[Vector2(cx - 9.0, waist), Vector2(cx - 10.0, neck + 26.0)],
			[Vector2(cx + 9.0, waist), Vector2(cx + 10.0, neck + 26.0)]]
	var on_braid := func(x: int, y: int) -> bool:
		for b: Array in braids:
			var a: Vector2 = b[0]
			var z: Vector2 = b[1]
			var t: float = clampf((Vector2(x, y) - a).dot(z - a) / (z - a).length_squared(), 0.0, 1.0)
			if Vector2(x, y).distance_to(a.lerp(z, t)) <= 7.0 - 2.0 * t:
				return true
		return false
	var braided := func(x: int, y: int) -> bool:
		return cornrow.call(x, y) or (on_braid.call(x, y) and not (in_face.call(x, y) and y < fy0 + fh * 0.9))
	_paint(fig, parts[&"hair_braided"] as Image, braided, his, source, 2, hair_against)
	_plait(parts[&"hair_braided"] as Image, braids)
	_cornrow_plaits(parts[&"hair_braided"] as Image, cornrow, row_of, fig, back)
	# Shaved: an even stubble on the skull — every other pixel, so at the game's size it
	# reads as a shadow of hair rather than as specks — his outline left as the skull's.
	var shaved := func(x: int, y: int) -> bool:
		return (dome.call(x, y, -2.0) or sides.call(x, y, -2.0, ear_line)) and not (face and x >= fx0 - 1 and x <= fx1 + 1 and y > fy0 + 2.0) \
			and (x + y) % 2 == 0 and (x + 2 * y) % 5 != 0
	_paint(fig, parts[&"hair_shaved"] as Image, shaved, his, source, 0, hair_against, 0.68)
	if not face:
		return
	_beards(fig, parts, his, source)


## The beards, seen from the front and the side: stubble, a short beard along the jaw, a
## full one below the chin. In the hair's colour, since they share its recolouring.
static func _beards(fig: Looks.Fig, parts: Dictionary, his: Image, source: Rect2i) -> void:
	var fx0: float = fig.face.x
	var fx1: float = fig.face.z
	var fy0: float = fig.face.y
	var fy1: float = fig.face.w
	var fh: float = fy1 - fy0
	var mouth: float = fy0 + fh * 0.80
	var lo := PackedInt32Array()
	var hi := PackedInt32Array()
	lo.resize(fig.h)
	hi.resize(fig.h)
	lo.fill(fig.w)
	hi.fill(-1)
	for y: int in fig.neck:
		for x: int in range(maxi(int(fx0) - 4, 0), mini(int(fx1) + 5, fig.w)):
			if fig.at(x, y) == Looks.K.SKIN:
				lo[y] = mini(lo[y], x)
				hi[y] = maxi(hi[y], x)
	# His face only: his hands are skin too, and a beard on the knuckles is not a beard.
	var skin_at := func(x: int, y: int) -> bool:
		return y >= 0 and y < fig.neck and x >= fx0 - 4.0 and x <= fx1 + 4.0 and fig.at(x, y) == Looks.K.SKIN
	var not_skin := func(x: int, y: int) -> bool:
		var k: int = fig.at(x, y)
		return k != Looks.K.SKIN
	var cx: float = (fx0 + fx1) / 2.0 + {&"left": -(fx1 - fx0) * 0.18, &"right": (fx1 - fx0) * 0.18}.get(fig.way, 0.0)
	var stubble := func(x: int, y: int) -> bool:
		return skin_at.call(x, y) and y >= fy0 + fh * 0.64 and (x + y) % 2 == 0 and (x / 2 + y) % 3 != 0
	_paint(fig, parts[&"beard_stubble"] as Image, stubble, his, source, 0, not_skin, 0.70)
	var short := func(x: int, y: int) -> bool:
		if not skin_at.call(x, y) and not (skin_at.call(x, y - 3) and y <= fy1 + 4):
			return false
		if y >= mouth + 1.0:
			return true
		if y < fy0 + fh * 0.55 or hi[y] < 0:
			return false
		var jaw: float = 3.0 + (y - (fy0 + fh * 0.55)) / (fh * 0.25) * 4.0
		return (fig.way != &"left" and x - lo[y] < jaw) or (fig.way != &"right" and hi[y] - x < jaw)
	_paint(fig, parts[&"beard_short"] as Image, short, his, source, 2, not_skin, 0.95)
	_mouth(parts[&"beard_short"] as Image, cx, mouth, (fx1 - fx0))
	var full := func(x: int, y: int) -> bool:
		if y < fy0 + fh * 0.66 or y > fy1 + 10.0 or x < fx0 - 4.0 or x > fx1 + 4.0:
			return false
		if y <= fy1 and hi[y] >= 0:
			# Round the cheeks: the beard climbs the sides of the face, not its middle.
			var side: float = minf(x - lo[y], hi[y] - x)
			return x >= lo[y] and x <= hi[y] and (y >= mouth or side < 7.0)
		var t: float = (y - fy1) / 10.0
		if t > 1.0:
			return false
		var half: float = (fx1 - fx0) * 0.42 * (1.0 - t * t * 0.6)
		return absf(x - cx) <= half
	_paint(fig, parts[&"beard_full"] as Image, full, his, source, 2, not_skin, 0.95)
	_mouth(parts[&"beard_full"] as Image, cx, mouth, (fx1 - fx0))


## A shape filled from his hair: each pixel takes the strand at the same place in his hair's
## box, and the edge — where the shape meets what `against` says — takes his dark line.
## `darken` below one is for stubble, which is hair seen through skin.
static func _paint(fig: Looks.Fig, img: Image, inside: Callable, his: Image, source: Rect2i, outline: int,
		against: Callable, darken: float = 1.0) -> void:
	# Against his face the line is one pixel, as his own fringe's is; against the world it
	# is his full outline.
	var mask := PackedByteArray()
	mask.resize(fig.w * fig.h)
	var box := Rect2i()
	var first: bool = true
	for y: int in fig.h:
		for x: int in fig.w:
			if inside.call(x, y):
				mask[y * fig.w + x] = 1
				box = Rect2i(x, y, 1, 1) if first else box.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
				first = false
	if first:
		return
	for y: int in range(box.position.y, box.end.y):
		for x: int in range(box.position.x, box.end.x):
			if mask[y * fig.w + x] == 0:
				continue
			var edge: bool = false
			if outline > 0:
				for dy: int in range(-outline, outline + 1):
					for dx: int in range(-outline, outline + 1):
						if dx * dx + dy * dy > outline * outline:
							continue
						var qx: int = x + dx
						var qy: int = y + dy
						var outside: bool = qx < 0 or qy < 0 or qx >= fig.w or qy >= fig.h or mask[qy * fig.w + qx] == 0
						var on_face: bool = fig.at(qx, qy) == Looks.K.SKIN
						if outside and on_face and dx * dx + dy * dy > 1:
							continue
						if outside and against.call(qx, qy):
							edge = true
							break
					if edge:
						break
			if edge:
				img.set_pixel(x, y, INK)
				continue
			var u: float = float(x - box.position.x) / maxf(box.size.x - 1, 1.0)
			var v: float = float(y - box.position.y) / maxf(box.size.y - 1, 1.0)
			var c: Color = _strand(his, source, u, v)
			if darken < 1.0:
				c = Color.from_hsv(c.h, c.s, c.v * darken)
			img.set_pixel(x, y, c)


## His hair at a place in its box, or the nearest strand of it that is not his outline.
static func _strand(his: Image, source: Rect2i, u: float, v: float) -> Color:
	var at := Vector2i(int(source.position.x + u * (source.size.x - 1)),
		int(source.position.y + (0.08 + v * 0.55) * (source.size.y - 1)))
	for r: int in range(0, 9):
		for dy: int in range(-r, r + 1):
			for dx: int in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var q: Vector2i = at + Vector2i(dx, dy)
				if q.x < 0 or q.y < 0 or q.x >= his.get_width() or q.y >= his.get_height():
					continue
				var c: Color = his.get_pixelv(q)
				if c.a > 0.5 and c.v >= 0.2 and c.s >= 0.35:
					return c
	return Color8(150, 60, 30)


## Combed back: a darker stroke every few pixels, running toward the crown seen from the
## front and behind, toward the back of the head seen from the side.
static func _combed(img: Image, inside: Callable, fig: Looks.Fig, cx: float, top: float, back: float) -> void:
	for y: int in fig.h:
		for x: int in fig.w:
			if not inside.call(x, y) or img.get_pixel(x, y).a < 0.5 or img.get_pixel(x, y) == INK:
				continue
			var stroke: bool
			if back == 0.0:
				var spread: float = (x - cx) / maxf((y - top) * 0.35 + 6.0, 1.0)
				stroke = fposmod(spread * 4.0, 2.0) < 0.35
			else:
				stroke = (y - int(top) + int(x * 0.25 * back)) % 5 == 0
			if stroke:
				var c: Color = img.get_pixel(x, y)
				img.set_pixel(x, y, Color.from_hsv(c.h, c.s, c.v * 0.62))


## The cornrows' plaits: a dark notch across each row every few pixels along it.
static func _cornrow_plaits(img: Image, inside: Callable, row_of: Callable, fig: Looks.Fig, back: float) -> void:
	for y: int in fig.h:
		for x: int in fig.w:
			if not inside.call(x, y) or img.get_pixel(x, y).a < 0.5:
				continue
			var across: float = fposmod(row_of.call(x, y) + 3.0, 9.0)
			var along: int = y if back == 0.0 else x
			if (along + int(absf(across - 3.0))) % 5 == 0:
				img.set_pixel(x, y, INK)


## The tie round a tail: two dark rows and leather between, across it.
static func _band(img: Image, at: Vector2, along: Vector2, half: float) -> void:
	var dir: Vector2 = along.normalized()
	var across := Vector2(-dir.y, dir.x)
	for t: int in range(-1, 3):
		for s: int in range(-int(half), int(half) + 1):
			var p := Vector2i((at + dir * t + across * s).round())
			if p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height() or img.get_pixelv(p).a < 0.5:
				continue
			img.set_pixelv(p, INK if t == -1 or t == 2 else Color8(92, 52, 30))


## A braid's crossings: a dark notch every few pixels down it.
static func _plait(img: Image, braids: Array[Array]) -> void:
	for b: Array in braids:
		var a: Vector2 = b[0]
		var z: Vector2 = b[1]
		var length: float = a.distance_to(z)
		var dir: Vector2 = (z - a) / maxf(length, 1.0)
		var across := Vector2(-dir.y, dir.x)
		var t: float = 6.0
		while t < length:
			for s: int in range(-3, 4):
				var p := Vector2i((a + dir * (t + absf(s) * 0.6) + across * s).round())
				if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height() and img.get_pixelv(p).a > 0.5:
					img.set_pixelv(p, INK)
			t += 6.0


static func _mouth(img: Image, cx: float, mouth: float, fw: float) -> void:
	var half: float = fw * 0.08
	for x: int in range(int(cx - half), int(cx + half) + 1):
		var y: int = int(mouth) - 1
		if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
			img.set_pixel(x, y, INK)
