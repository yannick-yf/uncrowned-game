extends SceneTree

## Builds `view3d/fight/traveler_sheet.png`: his traveller fighting, in four facings.
##
## **This breaks the art rule, on Yannick's explicit call (2026-09-19, widened
## 2026-09-24).** `CLAUDE.md` says the figures are his brother's and that what he has not
## drawn should be *visibly missing*. He has drawn eight animations — idle and walk, four
## directions — and no attack, no guard and no flinch, so a fight showed three different
## actions as a person standing still. Yannick was told that a second hand on his
## brother's character would show, said to do it anyway, and this is it. It is written
## down in the art rule and in `docs/POUR_SLOSINIO.md` so his brother is not surprised.
##
## **Twelve frames since K5, and the reason is the grid.** The first pass drew left and
## right only, which was enough while a fight ran along one axis. `docs/COMBAT_V2.md`
## puts fights on the world grid, where two fighters stand north and south of each other
## constantly. Yannick was offered the free answer — a blow thrown north drawn side-on —
## and refused it twice, the second time raising the count himself: *"Ok pour huit
## images, et même plus si nécessaire. On veut un rendu assez propre pour la demo v1."*
## So the up and down facings get a wind-up, a blow and a flinch of their own.
##
## **The guard is not among them.** It was cut from the design on 2026-09-24; the two
## guard frames already drawn stay where they are and go unused, and the two axial
## facings have no guard cell of their own — his plain idle stands in those two squares,
## so anything that plays a guard that no longer exists shows a person standing rather
## than nothing at all.
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
##     godot --headless --path . -s tools/draw_fight_frames.gd -- --contact
##
## `--contact` also writes the contact sheets under `docs/frames/fight/`: the whole grid
## at playing size and the six new frames at twice it, both with his discard rule already
## applied, because the chequer is not what the game shows and a frame judged against the
## chequer is a frame judged wrong.
##
## **Not in `assets/`, and that is not a dodge.** `assets/` is the approved 2D pack’s
## family and `tools/asset_validator.gd` checks every PNG in it against that palette —
## correctly rejecting this one, which is made of his chequer and his browns. The 3D
## world’s art has never lived there: his own sheet is in `prototypes/`. Ours sits
## beside the 3D window instead.
##
## Re-runnable and deterministic: the same sheet in, the same frames out.

const HIS_SHEET: String = "prototypes/brindle_3d/prototype_3d/assets/traveler_walk_v2.png"
const OUT_PNG: String = "view3d/fight/traveler_sheet.png"
const CONTACT_DIR: String = "docs/frames/fight/"

## **One sheet, his on top and ours below it.** Not two files, and that is not tidiness:
## his material hands the *whole sheet* to his shader as a uniform and the frames index
## into it by UV (`traveler_sprite.gdshader`), so a second texture is simply not looked
## at — six frames in one of their own drew the entire sheet, shrunk, onto every fighter.
## Appending keeps every one of his pixel coordinates exactly where it was.
##
## One cell per frame, the poses across and the facings down. `view/world3d.gd` reads the
## same numbers, so they live in one place — here — and are printed at the end of a run.
const CELL: Vector2i = Vector2i(160, 200)
## **Four, since the second pass.** `ready` is the cocked arm, and it is the one that
## was missing: without it the twenty-eight frames of wind-up had no drawing at all and
## the fight's whole tell was a lean. Now the arm pulls back and snaps out.
const POSES: Array[StringName] = [&"ready", &"attack", &"guard", &"hurt"]
## **Four rows since K5, and this order is load-bearing.** `view/world3d.gd` finds our
## block by counting up from the bottom of the sheet — `height - CELL.y * OUR_WAYS.size()`
## — so right and left are deliberately the *last two rows*. A window that still knows
## only those two finds them exactly where it found them before up and down were added,
## and a window that knows all four finds all four. Do not reorder this.
const WAYS: Array[StringName] = [&"up", &"down", &"right", &"left"]

## **His hair takes the top three fifths of the frame**, so the only ground clear enough
## to draw an arm on is the chest and below. Two passes were spent learning that: a guard
## under the chin put a dark blob over his eye, and a fist cocked at shoulder height
## disappeared behind his own backpack. Every number below lives in that band.
const ARM_THICK: int = 11
## A little thicker for the axial facings, because their arms run on a slant across the
## pixel grid and a slanted band of the same count reads thinner than a level one.
const AXIAL_THICK: int = 13

## Where the fist ends for the two **axial** facings, as an offset from the shoulder —
## sideways first, then down the screen. Tuned by looking at what `--contact` writes.
##
## **Screen direction carries the blow, because nothing else can.** His figure fills the
## cell from top to bottom, so the body cannot lunge north or south by even three pixels
## without losing his hair or his boots. What is left is the arm, and the one thing an
## arm can say at this size is *which way it is going*: the blow thrown away from us
## rises up the frame and tucks behind his hair, the blow thrown at us falls down the
## frame past his knee. The facing itself is never in doubt — a back with no face on it
## reads instantly — so these frames have to say **struck**, not *struck northwards*.
const UP_READY: Vector2i = Vector2i(15, 36)
const UP_BLOW: Vector2i = Vector2i(24, -30)
const DOWN_READY: Vector2i = Vector2i(19, -22)
const DOWN_BLOW: Vector2i = Vector2i(21, 40)


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
	var contact: bool = OS.get_cmdline_user_args().has("--contact")
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
	var cells: Array[Image] = []
	for row: int in WAYS.size():
		var way: StringName = WAYS[row]
		var base: Rect2i = _region_of(frames, StringName("idle_" + String(way)))
		for col: int in POSES.size():
			var cell: Image = _pose(sheet, base, POSES[col], way)
			cells.append(cell)
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
			print("  %-7s %-6s  cell %s%s" % [POSES[col], WAYS[row],
				str(Rect2i(col * CELL.x, below + row * CELL.y, CELL.x, CELL.y)),
				"   (unused: the guard was cut 2026-09-24 — his idle stands here)"
					if _is_unused(POSES[col], WAYS[row]) else ""])
	if contact:
		_contact(cells)
	quit(0)


## The guard went out of the design on 2026-09-24. The two already drawn stay drawn; the
## two axial facings never get one.
func _is_unused(pose: StringName, way: StringName) -> bool:
	return pose == &"guard" and (way == &"up" or way == &"down")


func _region_of(frames: SpriteFrames, named: StringName) -> Rect2i:
	var texture: Texture2D = frames.get_frame_texture(named, 0)
	if texture is AtlasTexture:
		return Rect2i((texture as AtlasTexture).region)
	return Rect2i()


## One pose, built on top of one of his idle frames.
func _pose(sheet: Image, base: Rect2i, pose: StringName, way: StringName) -> Image:
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

	if way == &"right" or way == &"left":
		_side_on(cell, hand, tunic, ink, pose, at, base.size, 1 if way == &"right" else -1)
	else:
		_axial(cell, sheet, base, at, tunic, ink, pose, 1 if way == &"down" else -1)
	return cell


## The two facings he is seen from the side in, unchanged since the second pass.
##
## **All three arms live in one narrow band, across his chest.** His hair is enormous —
## it takes the top three fifths of the frame — so anything drawn at head height is lost
## behind it or smeared across his face. Two passes were spent finding that out: a guard
## under the chin put a dark blob over his eye, and a fist cocked at shoulder height
## disappeared behind his own backpack. The clear ground is the chest, so the three
## poses differ by how far the arm goes and which way, never by height.
func _side_on(cell: Image, hand: Rect2i, tunic: Rect2i, ink: Color, pose: StringName,
		at: Vector2i, size: Vector2i, forward: int) -> void:
	var punch_y: int = tunic.position.y + int(float(tunic.size.y) * 0.34)
	match pose:
		&"ready":
			# The arm drawn back, and the frame that was missing: without it the wind-up
			# had no drawing at all and the whole tell was a lean, which Yannick played
			# and called very slight.
			_reach(cell, hand, tunic, ink, forward, 22, punch_y + 3, -forward)
		&"attack":
			_reach(cell, hand, tunic, ink, forward, 30, punch_y)
		&"guard":
			# Short, forward, and a little above the punch line: an arm held up rather
			# than thrown out. A slanting two-pixel forearm was tried first and read as a
			# stick — at this size an arm has to be as thick as his own or it is a line.
			_reach(cell, hand, tunic, ink, forward, 15, punch_y - 9)
		&"hurt":
			_recoil(cell, at, size, forward)


## The two facings he is seen from the front and the back in — **K5, 2026-09-24**.
##
## `toward` is +1 when he faces us and -1 when he faces away. Three things carry a blow
## here, and none of them is the one the side views use:
##
## - **The arm's direction on the screen is the blow's direction in the world.** Away
##   from us the arm rises; at us it falls past his knee. That is the oldest convention
##   in top-down games and it is the only one that survives a figure with no face.
## - **Depth is occlusion, and occlusion is free.** The blow thrown away goes *behind*
##   his hair — his own pixels are stamped back over the arm afterwards — so the arm
##   leaves us. Nothing else on a flat sprite says that.
## - **The clear ground is beside him, not above him.** His hair reaches the top row of
##   the frame and his boots the bottom, so the arm works in the gap either side of the
##   torso, which is twenty pixels wide and the only room there is.
##
## He punches with the same hand in both: seen from behind it is on the screen's right,
## seen from the front it is on the screen's left.
func _axial(cell: Image, sheet: Image, base: Rect2i, at: Vector2i,
		tunic: Rect2i, ink: Color, pose: StringName, toward: int) -> void:
	var side: int = -toward
	var chest: int = tunic.position.y + int(float(tunic.size.y) * 0.34)
	# **The arm leaves from the edge of him, not from the middle of his back.** Six pixels
	# in is where the side views start, and it is right for them — edge-on, six pixels in
	# is the shoulder. Seen from behind, six pixels in is between his shoulder blades, and
	# the first pass drew what looked like a strap across his satchel.
	var shoulder: Vector2i = Vector2i(
		tunic.end.x - 3 if side > 0 else tunic.position.x + 3, chest)
	# **His own fist, and not eighteen pixels of whatever is beside it.** The side views
	# take a fixed rectangle from the first skin they meet below the hips, which is right
	# when he is seen edge-on. Seen from the back it swept up his own backpack and stamped
	# a brown satchel on the end of his arm. Here the skin is grouped and the blob on the
	# side he punches with is taken whole.
	var fist_of: Rect2i = _fist_in(sheet, base, side)
	fist_of.position += at
	var across: PackedColorArray = _cuff(cell, fist_of, tunic, ink)
	# **Cut the fist out before the arm is drawn, and take it away with it.** Two things
	# went wrong the first time round, and they are two halves of one mistake: the arm was
	# laid straight over the hand he is already drawn with, so the fist stamped at the far
	# end was a copy of the sleeve that had just covered it; and where the arm missed, his
	# old hand stayed behind and he had three. The hand has *moved*, so it leaves.
	var fist_art: Image = _cut_out(cell, fist_of)
	if pose == &"ready" or pose == &"attack":
		_take_the_hand(cell, fist_of)
	match pose:
		&"ready":
			var back: Vector2i = UP_READY if toward < 0 else DOWN_READY
			var held: Vector2i = shoulder + Vector2i(side * back.x, back.y)
			_limb(cell, across, shoulder, held, AXIAL_THICK)
			_stamp_image(cell, fist_art, held - fist_of.size / 2)
		&"attack":
			var blow: Vector2i = UP_BLOW if toward < 0 else DOWN_BLOW
			var fist: Vector2i = shoulder + Vector2i(side * blow.x, blow.y)
			_limb(cell, across, shoulder, fist, AXIAL_THICK)
			_stamp_image(cell, fist_art, fist - fist_of.size / 2)
			if toward < 0:
				# **The arm goes behind him**, which is the whole of what "away from us"
				# can mean on a flat sprite. His head and his hair are stamped back over
				# it from his own sheet, so the fist comes out from behind his hair
				# rather than in front of it.
				_stamp_region(cell, sheet,
					Rect2i(base.position, Vector2i(base.size.x, tunic.position.y - at.y)),
					at)
		&"hurt":
			_fold(cell, at, base.size, -side)
		&"guard":
			# Cut from the design on 2026-09-24. His idle stands here, untouched.
			pass


## An arm put out: his sleeve lengthened by repeating one of its own columns, his hand
## on the end, his outline above and below. `along` is how far, `down` where on the
## torso it leaves from as a fraction of its height.
func _reach(cell: Image, hand: Rect2i, tunic: Rect2i, ink: Color, facing: int,
		along: int, y: int, arm: int = 0) -> void:
	var forward: int = arm if arm != 0 else facing
	var thick: int = ARM_THICK
	# The shoulder is on the side he faces whichever way the arm goes: a cocked arm
	# comes off the same shoulder as the punch, or the two frames do not belong to one
	# movement.
	var shoulder: int = tunic.end.x - 6 if facing > 0 else tunic.position.x + 6
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


## The same arm, but along any line rather than along the horizon — which the axial
## facings need, because theirs go up and down the screen. `across` is a cross-section of
## his sleeve, from `_cuff`; it is stretched to the width the slant asks for and laid
## down slice by slice along the longer axis, so the band never breaks and its two dark
## edges travel with it.
func _limb(cell: Image, across: PackedColorArray, from: Vector2i, to: Vector2i,
		thick: int) -> void:
	var span: Vector2i = to - from
	var steps: int = maxi(absi(span.x), absi(span.y))
	if steps <= 0 or across.size() < 3:
		return
	var flat: bool = absi(span.x) >= absi(span.y)
	# **A slanting arm is laid down in upright slices, so it has to be a taller slice or
	# it comes out thinner than the arm beside it.** The first pass drew a forty-five
	# degree arm eleven pixels tall, which is seven and a half pixels wide across the
	# limb, and it read as a stick — the same mistake the guard made, in another axis.
	var square: float = sqrt(float(span.x * span.x + span.y * span.y))
	var wide: int = maxi(int(round(float(thick) * square / float(steps))), 3)
	var slice: Image = Image.create(2 if flat else wide, wide if flat else 2, false,
		cell.get_format())
	for i: int in wide:
		var c: Color = across[mini(i * across.size() / wide, across.size() - 1)]
		for k: int in 2:
			slice.set_pixel(k if flat else i, i if flat else k, c)
	for i: int in steps + 1:
		var along: float = float(i) / float(steps)
		var p: Vector2i = from + Vector2i(
			int(round(float(span.x) * along)), int(round(float(span.y) * along)))
		_blit_inside(cell, slice,
			p - (Vector2i(0, wide / 2) if flat else Vector2i(wide / 2, 0)))


## **A cross-section of the sleeve he actually drew**, cut straight across his hanging
## arm a few pixels above the cuff: his dark line, his shadowed blue, his lit blue, his
## dark line again. Laid down an arm it gives the arm his shading and his edges, and
## every pixel of it is his.
##
## Two passes were spent not doing this. A two-pixel column of the tunic, which is what
## the side views repeat, is fine at eleven pixels tall and comes out mostly *background*
## at sixteen — the torso is not sixteen pixels of unbroken blue anywhere — so the
## slanting arm rendered as a three-pixel scratch with a dark edge and nothing inside it.
func _cuff(cell: Image, fist: Rect2i, tunic: Rect2i, ink: Color) -> PackedColorArray:
	var middle: int = fist.position.x + fist.size.x / 2
	for up: int in range(4, 18):
		var y: int = fist.position.y - up
		if y <= tunic.position.y:
			break
		var at: int = -1
		for dx: int in range(-4, 5):
			if is_tunic(cell.get_pixel(clampi(middle + dx, 0, cell.get_width() - 1), y)):
				at = middle + dx
				break
		if at < 0:
			continue
		var lo: int = at
		var hi: int = at
		while lo > 0 and is_tunic(cell.get_pixel(lo - 1, y)):
			lo -= 1
		while hi < cell.get_width() - 2 and is_tunic(cell.get_pixel(hi + 1, y)):
			hi += 1
		if hi - lo < 5:
			continue
		var across: PackedColorArray = PackedColorArray()
		across.append(ink)
		for x: int in range(lo, hi + 1):
			across.append(cell.get_pixel(x, y))
		across.append(ink)
		return across
	# Nothing found: the column the side views use, which is thin but is still his.
	var fallback: PackedColorArray = PackedColorArray()
	var cut: Rect2i = _bluest_column(cell, tunic,
		tunic.position.y + int(float(tunic.size.y) * 0.34), ARM_THICK)
	fallback.append(ink)
	for i: int in ARM_THICK:
		fallback.append(cell.get_pixel(cut.position.x, cut.position.y + i))
	fallback.append(ink)
	return fallback


func _blit_inside(cell: Image, slice: Image, to: Vector2i) -> void:
	for dy: int in slice.get_height():
		for dx: int in slice.get_width():
			var onto: Vector2i = to + Vector2i(dx, dy)
			if onto.x < 0 or onto.y < 0 \
					or onto.x >= cell.get_width() or onto.y >= cell.get_height():
				continue
			cell.set_pixelv(onto, slice.get_pixel(dx, dy))


## Hit: **the whole of him knocked back, and his head further than his feet.** The first
## pass moved only the head three pixels and was invisible at playing size. He goes back
## six and down two, and the head another five on top of that, which is a body folding
## round a blow rather than a man with a crooked neck.
func _recoil(cell: Image, at: Vector2i, size: Vector2i, forward: int) -> void:
	var whole: Image = Image.create(size.x, size.y, false, cell.get_format())
	whole.blit_rect(cell, Rect2i(at, size), Vector2i.ZERO)
	var chequer: Color = cell.get_pixelv(at + Vector2i(1, 1))
	for y: int in size.y:
		for x: int in size.x:
			cell.set_pixelv(at + Vector2i(x, y), chequer)
	var waist: int = int(float(size.y) * 0.62)
	# The legs, back six and down two.
	cell.blit_rect(whole, Rect2i(0, waist, size.x, size.y - waist),
		at + Vector2i(-6 * forward, waist + 2))
	# The head and shoulders, back eleven and down one.
	cell.blit_rect(whole, Rect2i(0, 0, size.x, waist), at + Vector2i(-11 * forward, 1))


## Hit, facing us or facing away — **a buckle rather than a knock-back**, and that is a
## constraint rather than a choice. His figure fills the cell top to bottom, so there is
## no room to shove him up or down the screen the way the side views shove him left and
## right: eleven pixels of travel would cost eleven pixels of his hair or his boots.
## What is left is the shape of a man taking one: his legs slip one way, his shoulders go
## the other, and his head drops into them. He gets shorter, which is what a blow does.
func _fold(cell: Image, at: Vector2i, size: Vector2i, aside: int) -> void:
	var whole: Image = Image.create(size.x, size.y, false, cell.get_format())
	whole.blit_rect(cell, Rect2i(at, size), Vector2i.ZERO)
	var chequer: Color = cell.get_pixelv(at + Vector2i(1, 1))
	for y: int in size.y:
		for x: int in size.x:
			cell.set_pixelv(at + Vector2i(x, y), chequer)
	var waist: int = int(float(size.y) * 0.62)
	# The legs, slipping out from under him.
	cell.blit_rect(whole, Rect2i(0, waist, size.x, size.y - waist),
		at + Vector2i(4 * aside, waist + 1))
	# The head and shoulders the other way, and eight pixels down into them. Eleven
	# sideways is what the side views use and what a blow looks like; less than that and
	# the frame reads as a man crouching, which was the first pass.
	cell.blit_rect(whole, Rect2i(0, 0, size.x, waist), at + Vector2i(-11 * aside, 8))


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


## A rectangle of the cell lifted out whole, before anything is drawn over it.
func _cut_out(cell: Image, from: Rect2i) -> Image:
	var out: Image = Image.create(from.size.x, from.size.y, false, cell.get_format())
	out.blit_rect(cell, from, Vector2i.ZERO)
	return out


## The same masked copy as `_stamp_hand`, from a rectangle already lifted out.
func _stamp_image(cell: Image, art: Image, to: Vector2i) -> void:
	for dy: int in art.get_height():
		for dx: int in art.get_width():
			var c: Color = art.get_pixel(dx, dy)
			if not is_his_ink(c):
				continue
			var onto: Vector2i = to + Vector2i(dx, dy)
			if onto.x < 0 or onto.y < 0 \
					or onto.x >= cell.get_width() or onto.y >= cell.get_height():
				continue
			cell.set_pixelv(onto, c)


## His hand rubbed out of the place it hangs in, so that when the arm carries it somewhere
## else he is not left holding both. His skin goes, and his dark line with it where the
## two touch; his sleeve stays, because the arm grows out of it.
##
## **What goes in its place is the pixel above, not the background.** Rubbing the hand out
## to his background left a bite out of his hip — the hand hangs against him, so the hole
## it leaves is inside his outline, and the dark of the arena showed through it. Taking
## the colour from straight above closes the hole with his tunic where his tunic is,
## with his trousers where his trousers are, and with the background only where the hand
## was sticking out past him in the first place.
func _take_the_hand(cell: Image, fist: Rect2i) -> void:
	var gone: Dictionary = {}
	for dy: int in fist.size.y:
		for dx: int in fist.size.x:
			var p: Vector2i = fist.position + Vector2i(dx, dy)
			if p.x < 0 or p.y < 0 or p.x >= cell.get_width() or p.y >= cell.get_height():
				continue
			if not is_skin(cell.get_pixelv(p)):
				continue
			for ay: int in range(-3, 4):
				for ax: int in range(-3, 4):
					var q: Vector2i = p + Vector2i(ax, ay)
					if q.x < 0 or q.y < 0 \
							or q.x >= cell.get_width() or q.y >= cell.get_height():
						continue
					var c: Color = cell.get_pixelv(q)
					if is_skin(c) or not is_tunic(c):
						gone[q] = true
	var chequer: Color = cell.get_pixel(0, 0)
	var healed: Dictionary = {}
	for q: Vector2i in gone:
		healed[q] = _nearest_above_or_below(cell, gone, q, chequer)
	for q: Vector2i in healed:
		cell.set_pixelv(q, healed[q])


## What closes the hole: the nearer of the two pixels straight above and straight below
## it that the hand did not cover. Above alone streaked the tunic's dark hem down over
## his trousers and left a rectangle on his hip; taking whichever is nearer gives the hole
## his tunic at the top and his trousers at the bottom, which is what is behind a hand.
func _nearest_above_or_below(cell: Image, gone: Dictionary, q: Vector2i,
		chequer: Color) -> Color:
	for away: int in range(1, 12):
		for step: int in [-away, away]:
			var p: Vector2i = q + Vector2i(0, step)
			if p.y < 0 or p.y >= cell.get_height() or gone.has(p):
				continue
			return cell.get_pixelv(p)
	return chequer


## The same masked copy, but out of his sheet rather than out of the cell: what puts his
## hair back on top of an arm that has gone behind him.
func _stamp_region(cell: Image, sheet: Image, from: Rect2i, to: Vector2i) -> void:
	for dy: int in from.size.y:
		for dx: int in from.size.x:
			var c: Color = sheet.get_pixelv(from.position + Vector2i(dx, dy))
			if not is_his_ink(c):
				continue
			var onto: Vector2i = to + Vector2i(dx, dy)
			if onto.x < 0 or onto.y < 0 \
					or onto.x >= cell.get_width() or onto.y >= cell.get_height():
				continue
			cell.set_pixelv(onto, c)


## His fist, found rather than measured out — what the axial facings use instead of
## `_hand_in`. Every patch of his skin below the belt is grown into a blob, and the blob
## furthest towards the side he punches with is taken whole, at whatever size it is.
##
## Written because the first pass stamped his **backpack** on the end of his arm: seen
## from behind, eighteen pixels to the right of his left hand is the satchel, and a fixed
## rectangle took it along. The side views keep the rectangle — it is right for them, and
## their eight frames are not to be disturbed for this.
func _fist_in(sheet: Image, base: Rect2i, side: int) -> Rect2i:
	var from_y: int = int(float(base.size.y) * 0.60)
	var seen: Dictionary = {}
	var best: Rect2i = Rect2i()
	var furthest: int = -9999
	for y: int in range(from_y, base.size.y):
		for x: int in base.size.x:
			var key: int = y * base.size.x + x
			if seen.has(key) or not is_skin(sheet.get_pixelv(base.position + Vector2i(x, y))):
				continue
			seen[key] = true
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			var lo: Vector2i = Vector2i(x, y)
			var hi: Vector2i = Vector2i(x, y)
			var size: int = 0
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				size += 1
				lo.x = mini(lo.x, p.x); lo.y = mini(lo.y, p.y)
				hi.x = maxi(hi.x, p.x); hi.y = maxi(hi.y, p.y)
				for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0),
						Vector2i(0, 1), Vector2i(0, -1)]:
					var q: Vector2i = p + step
					if q.x < 0 or q.y < from_y or q.x >= base.size.x or q.y >= base.size.y:
						continue
					var k: int = q.y * base.size.x + q.x
					if seen.has(k) or not is_skin(sheet.get_pixelv(base.position + q)):
						continue
					seen[k] = true
					stack.append(q)
			# A knuckle's worth, or it is a stray pixel of his outline catching the light.
			if size < 24:
				continue
			var reach: int = ((lo.x + hi.x) / 2) * side
			if reach > furthest:
				furthest = reach
				best = Rect2i(lo, hi - lo + Vector2i.ONE)
	if best.size.x <= 0:
		return _hand_in(sheet, base)
	# Two pixels of margin, which is where his own dark line round the hand lives.
	return best.grow(2)


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


# ------------------------------------------------------------- looking at it ---
#
# `--headless` never calls `_draw()`, so the suite cannot see a frame and a count of
# files proves nothing about a drawing. These two PNGs are the check: the whole grid at
# playing size, and the six new ones at twice it. Both have his discard rule applied
# already, because the chequer is not what the game shows.

const BACKDROP: Color = Color(0.11, 0.12, 0.14)
const RULE: Color = Color(0.26, 0.28, 0.32)


func _contact(cells: Array[Image]) -> void:
	DirAccess.make_dir_recursive_absolute(CONTACT_DIR)
	var grid: Image = _grid(cells, POSES.size(), WAYS.size(), 1)
	grid.save_png(CONTACT_DIR + "k5_twelve_frames.png")
	# The six new ones, twice the size: up then down, wind-up, blow, flinch.
	var new_ones: Array[Image] = []
	for row: int in WAYS.size():
		if WAYS[row] != &"up" and WAYS[row] != &"down":
			continue
		for col: int in POSES.size():
			if _is_unused(POSES[col], WAYS[row]):
				continue
			new_ones.append(cells[row * POSES.size() + col])
	var close: Image = _grid(new_ones, 3, 2, 2)
	close.save_png(CONTACT_DIR + "k5_north_south.png")
	print("contact sheets: %sk5_twelve_frames.png (%dx%d, rows %s, columns %s)"
		% [CONTACT_DIR, grid.get_width(), grid.get_height(), str(WAYS), str(POSES)])
	print("                %sk5_north_south.png (%dx%d, the six new ones at twice size)"
		% [CONTACT_DIR, close.get_width(), close.get_height()])


func _grid(cells: Array[Image], across: int, down: int, zoom: int) -> Image:
	var pad: int = 1
	var out: Image = Image.create(across * (CELL.x + pad) + pad,
		down * (CELL.y + pad) + pad, false, Image.FORMAT_RGBA8)
	out.fill(RULE)
	for i: int in cells.size():
		var shown: Image = _as_rendered(cells[i])
		out.blit_rect(shown, Rect2i(Vector2i.ZERO, CELL),
			Vector2i(pad + (i % across) * (CELL.x + pad),
				pad + (i / across) * (CELL.y + pad)))
	if zoom > 1:
		out.resize(out.get_width() * zoom, out.get_height() * zoom,
			Image.INTERPOLATE_NEAREST)
	return out


## His discard rule, run over a cell, so what is looked at is what the shader draws.
func _as_rendered(cell: Image) -> Image:
	var out: Image = Image.create(cell.get_width(), cell.get_height(), false,
		Image.FORMAT_RGBA8)
	for y: int in cell.get_height():
		for x: int in cell.get_width():
			var c: Color = cell.get_pixel(x, y)
			out.set_pixel(x, y, c if is_his_ink(c) else BACKDROP)
	return out
