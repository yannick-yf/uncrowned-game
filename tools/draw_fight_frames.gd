extends SceneTree

## Builds `assets/fight/traveler_fight.png`: six frames of his traveller fighting.
##
## **This breaks the art rule, on Yannick's explicit call (2026-09-19).** `CLAUDE.md`
## says the figures are his brother's and that what he has not drawn should be *visibly
## missing*. He has drawn eight animations — idle and walk, four directions — and no
## attack, no guard and no flinch, so a fight showed three different actions as a person
## standing still. Yannick was told that a second hand on his brother's character would
## show, said to do it anyway, and this is it. It is written down in the art rule and in
## `docs/POUR_SLOSINIO.md` so his brother is not surprised to find it.
##
## **Nothing here invents a colour.** Every pixel comes out of his own sheet: his hand is
## copied to a new place, his sleeve is lengthened by repeating one of its own columns,
## his outline black is sampled from his own outline. That is deliberate — his figure is
## not flat pixel art but *painted*, with the brown of the hair varying pixel by pixel
## across ten thousand shades, and a flat rectangle of colour beside it would read as a
## different hand at fifty paces.
##
## **His background rule is his too.** The source sheet carries an opaque grey chequer
## where the transparency should be, and his shader discards any pixel that is bright and
## desaturated (`traveler_sprite.gdshader`: *"Le fond neutre de la planche source est
## découpé au rendu"*). So the chequer that comes along with a copied region costs
## nothing — it is discarded at render exactly as his own is.
##
##     godot --headless --path . -s tools/draw_fight_frames.gd
##
## **Not in `assets/`, and that is not a dodge.** `assets/` is the approved 2D pack’s
## family and `tools/asset_validator.gd` checks every PNG in it against that palette —
## correctly rejecting this one, which is made of his chequer and his browns. The 3D
## world’s art has never lived there: his own sheet is in `prototypes/`. Ours sits
## beside the 3D window instead.
##
## Re-runnable and deterministic: the same sheet in, the same six frames out.

const HIS_SHEET: String = "prototypes/brindle_3d/prototype_3d/assets/traveler_walk_v2.png"
const OUT_PNG: String = "view3d/fight/traveler_sheet.png"

## **One sheet, his on top and ours below it.** Not two files, and that is not tidiness:
## his material hands the *whole sheet* to his shader as a uniform and the frames index
## into it by UV (`traveler_sprite.gdshader`), so a second texture is simply not looked
## at — six frames in one of their own drew the entire sheet, shrunk, onto every fighter.
## Appending keeps every one of his pixel coordinates exactly where it was.
##
## One cell per frame, three across and two down: attack, guard, hurt, for the
## right-facing row and then the left-facing one. `view/world3d.gd` reads the same
## numbers, so they live in one place — here — and are printed at the end of a run.
const CELL: Vector2i = Vector2i(160, 200)
const POSES: Array[StringName] = [&"attack", &"guard", &"hurt"]
const WAYS: Array[StringName] = [&"right", &"left"]


static func is_skin(c: Color) -> bool:
	if c.a < 0.5:
		return false
	return c.r > 0.80 and c.g > 0.55 and c.g < 0.88 and c.b > 0.40 and c.b < 0.78 \
		and (c.r - c.b) > 0.15


static func is_tunic(c: Color) -> bool:
	return c.a > 0.5 and c.b > 0.35 and c.b - c.r > 0.12 and c.b - c.g > 0.05


## His own rule for what is background, copied from his shader so the two agree.
static func is_his_ink(c: Color) -> bool:
	if c.a < 0.5:
		return false
	var high: float = maxf(c.r, maxf(c.g, c.b))
	var low: float = minf(c.r, minf(c.g, c.b))
	return not (high > 0.35 and (high - low) / maxf(high, 0.001) < 0.22)


func _initialize() -> void:
	var sheet: Image = Image.load_from_file(HIS_SHEET)
	if sheet == null:
		push_error("his sheet is not there: %s — run tools/vendor_workshop.sh?" % HIS_SHEET)
		quit(1)
		return
	var frames: SpriteFrames = load(World3d.HIS_FRAMES) as SpriteFrames
	if frames == null:
		push_error("his SpriteFrames is not there: %s" % World3d.HIS_FRAMES)
		quit(1)
		return

	var ours: Vector2i = Vector2i(CELL.x * POSES.size(), CELL.y * WAYS.size())
	var out: Image = Image.create(maxi(sheet.get_width(), ours.x),
		sheet.get_height() + ours.y, false, sheet.get_format())
	out.fill(sheet.get_pixel(0, 0))
	out.blit_rect(sheet, Rect2i(Vector2i.ZERO, sheet.get_size()), Vector2i.ZERO)
	var below: int = sheet.get_height()
	for row: int in WAYS.size():
		var way: StringName = WAYS[row]
		var base: Rect2i = _region_of(frames, StringName("idle_" + String(way)))
		var forward: int = 1 if way == &"right" else -1
		for col: int in POSES.size():
			var cell: Image = _pose(sheet, base, POSES[col], forward)
			out.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()),
				Vector2i(col * CELL.x, below + row * CELL.y))

	DirAccess.make_dir_recursive_absolute(OUT_PNG.get_base_dir())
	var wrote: Error = out.save_png(OUT_PNG)
	if wrote != OK:
		push_error("could not write %s" % OUT_PNG)
		quit(1)
		return
	print("wrote %s, %dx%d — his %dx%d with ours below it" % [
		OUT_PNG, out.get_width(), out.get_height(), sheet.get_width(), sheet.get_height()])
	for row: int in WAYS.size():
		for col: int in POSES.size():
			print("  %-7s %-6s  cell %s" % [POSES[col], WAYS[row],
				str(Rect2i(col * CELL.x, below + row * CELL.y, CELL.x, CELL.y))])
	quit(0)


func _region_of(frames: SpriteFrames, named: StringName) -> Rect2i:
	var texture: Texture2D = frames.get_frame_texture(named, 0)
	if texture is AtlasTexture:
		return Rect2i((texture as AtlasTexture).region)
	return Rect2i()


## One pose, built on top of one of his idle frames.
func _pose(sheet: Image, base: Rect2i, pose: StringName, forward: int) -> Image:
	var cell: Image = Image.create(CELL.x, CELL.y, false, sheet.get_format())
	# The chequer is his background and his shader throws it away, so filling the pad
	# with it costs nothing and keeps the cell uniform.
	cell.fill(sheet.get_pixelv(base.position + Vector2i(1, 1)))
	var at: Vector2i = (CELL - base.size) / 2
	cell.blit_rect(sheet, base, at)

	var hand: Rect2i = _hand_in(sheet, base)
	var tunic: Rect2i = _tunic_in(sheet, base)
	var ink: Color = _outline_of(sheet, base)
	# Everything below is in cell coordinates.
	hand.position += at
	tunic.position += at

	match pose:
		&"attack":
			_reach(cell, hand, tunic, ink, forward, 30,
				tunic.position.y + int(float(tunic.size.y) * 0.34))
		&"guard":
			# **The same arm, higher and shorter.** A slanting two-pixel forearm was tried
			# first and read as a stick: at this size an arm has to be as thick as his own
			# or it is a line. So a guard is the punch's forearm, brought up under the chin
			# and stopped half way.
			_reach(cell, hand, tunic, ink, forward, 14,
				_face_in(sheet, base).end.y + at.y - 14)
		&"hurt":
			_recoil(cell, at, base.size, forward)
	return cell


## An arm put out: his sleeve lengthened by repeating one of its own columns, his hand
## on the end, his outline above and below. `along` is how far, `down` where on the
## torso it leaves from as a fraction of its height.
func _reach(cell: Image, hand: Rect2i, tunic: Rect2i, ink: Color, forward: int,
		along: int, y: int) -> void:
	var thick: int = 11
	var shoulder: int = tunic.end.x - 6 if forward > 0 else tunic.position.x + 6
	# **The sleeve is one of his own columns, repeated** — and it has to be a column that
	# is actually his blue. Taking the middle of the tunic's box landed on the strap and
	# came out black, which read as a stick rather than an arm, so the column is now
	# chosen by looking: the two-wide slice inside the tunic with the most blue in it.
	var slice: Rect2i = _bluest_column(cell, tunic, y, thick)
	for i: int in along:
		cell.blit_rect(cell, slice, Vector2i(shoulder + forward * i - (1 if forward > 0 else 0), y))
	# His outline, one pixel above and below, so the arm is bounded like the rest of him.
	var from_x: int = mini(shoulder, shoulder + forward * along)
	for x: int in range(from_x, from_x + along + 2):
		for edge: int in [y - 1, y + thick]:
			if x >= 0 and x < cell.get_width() and edge >= 0 and edge < cell.get_height():
				cell.set_pixel(x, edge, ink)
	# And his hand at the end of it — **only the hand**. Blitting the whole rectangle
	# brought the chequer around it along too, and painted it back over the sleeve, which
	# is why the first fist came out washed out.
	var fist_x: int = shoulder + forward * along - (0 if forward > 0 else hand.size.x)
	_stamp_hand(cell, hand, Vector2i(fist_x, y - 3))


## Where his face starts, so a guard can be put in front of it rather than in front of
## his belt.
func _face_in(sheet: Image, base: Rect2i) -> Rect2i:
	var lo: Vector2i = Vector2i(9999, 9999)
	var hi: Vector2i = Vector2i(-1, -1)
	for y: int in int(float(base.size.y) * 0.66):
		for x: int in base.size.x:
			if is_skin(sheet.get_pixelv(base.position + Vector2i(x, y))):
				lo.x = mini(lo.x, x); lo.y = mini(lo.y, y)
				hi.x = maxi(hi.x, x); hi.y = maxi(hi.y, y)
	if hi.x < 0:
		return Rect2i(0, int(float(base.size.y) * 0.3), 10, 10)
	return Rect2i(lo, hi - lo)


## Hit: his head and shoulders shoved back, the rest of him staying put. A shear rather
## than a redraw, so every pixel is still his and in his order.
func _recoil(cell: Image, at: Vector2i, size: Vector2i, forward: int) -> void:
	var top: Image = Image.create(size.x, size.y, false, cell.get_format())
	top.blit_rect(cell, Rect2i(at, size), Vector2i.ZERO)
	var waist: int = int(float(size.y) * 0.62)
	# Blank the upper half and put it back three pixels behind him and one pixel up.
	var chequer: Color = cell.get_pixelv(at + Vector2i(1, 1))
	for y: int in waist:
		for x: int in size.x:
			cell.set_pixelv(at + Vector2i(x, y), chequer)
	cell.blit_rect(top, Rect2i(0, 0, size.x, waist), at + Vector2i(-3 * forward, -1))


## The two-pixel column inside his tunic with the most of his blue in it, at the height
## the arm leaves from. Looked for rather than assumed, because the tunic's bounding box
## also contains the strap, the belt and a good deal of background.
func _bluest_column(cell: Image, tunic: Rect2i, y: int, thick: int) -> Rect2i:
	var best: int = tunic.position.x + tunic.size.x / 2
	var most: int = -1
	for x: int in range(tunic.position.x, tunic.end.x - 2):
		var blue: int = 0
		for dy: int in thick:
			for dx: int in 2:
				if is_tunic(cell.get_pixel(x + dx, y + dy)):
					blue += 1
		if blue > most:
			most = blue
			best = x
	return Rect2i(best, y, 2, thick)


## His hand, copied pixel by pixel and skipping his background, so what lands is a fist
## and not a rectangle of chequer with a fist in it.
func _stamp_hand(cell: Image, hand: Rect2i, to: Vector2i) -> void:
	for dy: int in hand.size.y:
		for dx: int in hand.size.x:
			var from: Vector2i = hand.position + Vector2i(dx, dy)
			if from.x < 0 or from.y < 0 or from.x >= cell.get_width() or from.y >= cell.get_height():
				continue
			var c: Color = cell.get_pixelv(from)
			if not is_his_ink(c):
				continue
			var onto: Vector2i = to + Vector2i(dx, dy)
			if onto.x < 0 or onto.y < 0 or onto.x >= cell.get_width() or onto.y >= cell.get_height():
				continue
			cell.set_pixelv(onto, c)


func _hand_in(sheet: Image, base: Rect2i) -> Rect2i:
	var lo: Vector2i = Vector2i(9999, 9999)
	for y: int in range(int(float(base.size.y) * 0.68), base.size.y):
		for x: int in base.size.x:
			if is_skin(sheet.get_pixelv(base.position + Vector2i(x, y))):
				if y < lo.y or (y == lo.y and x < lo.x):
					lo = Vector2i(x, y)
	if lo.x > 9000:
		return Rect2i(0, 0, 18, 20)
	return Rect2i(maxi(lo.x - 2, 0), maxi(lo.y - 2, 0), 18, 20)


func _tunic_in(sheet: Image, base: Rect2i) -> Rect2i:
	var lo: Vector2i = Vector2i(9999, 9999)
	var hi: Vector2i = Vector2i(-1, -1)
	for y: int in base.size.y:
		for x: int in base.size.x:
			if is_tunic(sheet.get_pixelv(base.position + Vector2i(x, y))):
				lo.x = mini(lo.x, x); lo.y = mini(lo.y, y)
				hi.x = maxi(hi.x, x); hi.y = maxi(hi.y, y)
	if hi.x < 0:
		return Rect2i(0, 0, base.size.x, base.size.y)
	return Rect2i(lo, hi - lo)


## The darkest ink he actually used, so the arm's edge is his line and not a black we
## chose.
func _outline_of(sheet: Image, base: Rect2i) -> Color:
	var darkest: Color = Color(0, 0, 0, 1)
	var least: float = 9.0
	for y: int in base.size.y:
		for x: int in base.size.x:
			var c: Color = sheet.get_pixelv(base.position + Vector2i(x, y))
			if not is_his_ink(c):
				continue
			var sum: float = c.r + c.g + c.b
			if sum < least:
				least = sum
				darkest = c
	return darkest
