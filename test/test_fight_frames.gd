extends TestCase

## The twelve frames of the fight, and the three promises they were made under.
##
## `tools/draw_fight_frames.gd` draws on his brother's character, which `CLAUDE.md`'s art
## rule forbade until 2026-09-30 and which Yannick allowed anyway, twice: eight frames on
## 2026-09-19 and six more on 2026-09-24, when the fight moved onto the world grid. Since
## 2026-09-30 the rule is coherence with his hand, and these three promises are how the
## frames keep it; two of them can be checked by a machine rather than remembered:
##
## - **No colour is invented.** Every pixel of ours occurs in the very frame of his it was
##   built from. `test_no_colour_of_ours_is_absent_from_his_own_frame` walks all sixteen
##   cells and says so pixel by pixel.
## - **His files are never touched, and ours is not in `assets/`.**
##   `test_the_tool_reads_his_folder_and_writes_ours`.
## - **His, the day he draws his own — or ours, by choice.** `test_his_brother_has_not_drawn_a_blow`,
##   below, fails on a ninth animation of his. It lived in `test_combat.gd` until that
##   file went with the first design (K6, 2026-09-26).
##
## Nothing here draws: it reads the sheet the tool wrote and the numbers `view/world3d.gd`
## reads it with. `--headless` never calls `_draw()`, so whether the frames are any *good*
## is a question for `docs/frames/fight/k5_twelve_frames.png` and a pair of eyes.

const SLOW: bool = false

const TOOL: String = "res://tools/draw_fight_frames.gd"


func _tool() -> Dictionary:
	var script: GDScript = load(TOOL) as GDScript
	if script == null:
		return {}
	return script.get_script_constant_map()


func _sheet() -> Image:
	var texture: Texture2D = load(World3d.OUR_FIGHT_FRAMES) as Texture2D
	return texture.get_image() if texture != null else null


func _his() -> Image:
	return Image.load_from_file(
		"prototypes/brindle_3d/prototype_3d/assets/traveler_walk_v2.png")


func test_the_sheet_is_his_with_four_rows_of_ours_under_it() -> void:
	var made: Dictionary = _tool()
	assert_false(made.is_empty(), "the tool loads and says what it drew")
	var ways: Array = made.get("WAYS", [])
	var poses: Array = made.get("POSES", [])
	assert_eq(ways.size(), 4, "four facings: %s" % str(ways))
	assert_eq(poses.size(), 4, "four columns: %s" % str(poses))
	if not ResourceLoader.exists(World3d.OUR_FIGHT_FRAMES):
		debt("view3d/fight/traveler_sheet.png is missing — run tools/draw_fight_frames.gd")
		return
	var sheet: Image = _sheet()
	var his: Image = _his()
	if his == null:
		debt("his workshop is not copied in; run tools/vendor_workshop.sh")
		return
	assert_eq(sheet.get_width(), his.get_width(), "ours is his sheet, the same width")
	assert_eq(sheet.get_height(), his.get_height() + World3d.OUR_CELL.y * ways.size(),
		"with our four rows below it")


func test_his_own_pixels_are_where_he_left_them() -> void:
	# His material hands the **whole sheet** to his shader and his frames index into it by
	# UV, so re-pointing his atlases at ours is only safe while every one of his pixels is
	# still at his own coordinate and every one of his regions still fits inside.
	var sheet: Image = _sheet()
	var his: Image = _his()
	if sheet == null or his == null:
		debt("his workshop is not copied in; run tools/vendor_workshop.sh")
		return
	var moved: int = 0
	for y: int in range(0, his.get_height(), 3):
		for x: int in range(0, his.get_width(), 3):
			if sheet.get_pixel(x, y) != his.get_pixel(x, y):
				moved += 1
	assert_eq(moved, 0, "not one of his pixels has moved")
	var frames: SpriteFrames = load(World3d.HIS_FRAMES) as SpriteFrames
	if frames == null:
		debt("his SpriteFrames is not there; run tools/vendor_workshop.sh")
		return
	var whole: Rect2i = Rect2i(Vector2i.ZERO, sheet.get_size())
	var outside: PackedStringArray = PackedStringArray()
	for named: String in frames.get_animation_names():
		for i: int in frames.get_frame_count(StringName(named)):
			var slice := frames.get_frame_texture(StringName(named), i) as AtlasTexture
			if slice != null and not whole.encloses(Rect2i(slice.region)):
				outside.append(named)
	assert_eq(outside.size(), 0,
		"every one of his frames still lands inside the combined sheet: %s" % str(outside))


func test_the_window_reads_the_tools_last_rows_in_the_tools_order() -> void:
	# **The row order is load-bearing.** `view/world3d.gd` counts our block up from the
	# bottom of the sheet, so right and left have to stay the last two rows: a window that
	# knows only those two finds them unmoved, and a window taught the other two finds all
	# four. Reorder `WAYS` and every fighter draws somebody else's arm.
	var made: Dictionary = _tool()
	var ways: Array = made.get("WAYS", [])
	assert_eq(ways.size(), 4, "four facings")
	if ways.size() != 4:
		return
	assert_eq(String(ways[2]), "right", "right is the second row from the bottom")
	assert_eq(String(ways[3]), "left", "left is the last")
	assert_eq(Vector2i(made.get("CELL", Vector2i.ZERO)), World3d.OUR_CELL,
		"the tool and the window agree on the size of a cell")
	var sheet: Image = _sheet()
	var his: Image = _his()
	if sheet == null or his == null:
		debt("his workshop is not copied in; run tools/vendor_workshop.sh")
		return
	# **The invariant, rather than a snapshot of it.** Whatever the window reads, it must
	# read the tool's *last* rows in the tool's order — that is what makes the block
	# findable by counting up from the bottom, and it holds whether the window knows two
	# facings or four. It was two until 2026-09-24, when the grid fight could aim north
	# and south and `OUR_WAYS` was extended; the assertion below is the same claim
	# written so that it survived the change instead of failing it.
	var window_looks: int = sheet.get_height() - World3d.OUR_CELL.y * World3d.OUR_WAYS.size()
	var tool_put_them: int = his.get_height() \
		+ World3d.OUR_CELL.y * (ways.size() - World3d.OUR_WAYS.size())
	assert_eq(window_looks, tool_put_them,
		"the window's first row is the tool's %dth" % (ways.size() - World3d.OUR_WAYS.size()))
	for at: int in World3d.OUR_WAYS.size():
		assert_eq(String(World3d.OUR_WAYS[at]),
			String(ways[ways.size() - World3d.OUR_WAYS.size() + at]),
			"the window's facings are the tool's last ones, in the tool's order")


func test_each_of_the_new_facings_actually_drew_something() -> void:
	# The guard was cut on 2026-09-24 and its two axial cells are his plain idle, which
	# makes them the control: a wind-up, a blow or a flinch that drew nothing would be
	# identical to one, and that is the failure this catches.
	var made: Dictionary = _tool()
	var poses: Array = made.get("POSES", [])
	var ways: Array = made.get("WAYS", [])
	var sheet: Image = _sheet()
	var his: Image = _his()
	if sheet == null or his == null or poses.size() != 4 or ways.size() != 4:
		debt("his workshop is not copied in; run tools/vendor_workshop.sh")
		return
	var below: int = his.get_height()
	for row: int in 2:
		var still: int = poses.find(&"guard")
		for col: int in poses.size():
			if col == still:
				continue
			var drawn: int = _differing(sheet,
				Vector2i(col * World3d.OUR_CELL.x, below + row * World3d.OUR_CELL.y),
				Vector2i(still * World3d.OUR_CELL.x, below + row * World3d.OUR_CELL.y))
			assert_true(drawn > 150, "%s %s moved %d pixels off his idle"
				% [String(poses[col]), String(ways[row]), drawn])


func test_no_colour_of_ours_is_absent_from_his_own_frame() -> void:
	# **The art rule's first condition, checked rather than promised.** Every pixel in
	# every cell of ours must be a colour he already painted in the very frame that cell
	# was built from — his hand moved, his sleeve repeated, his line sampled. One pixel of
	# a blue we chose and this fails.
	var made: Dictionary = _tool()
	var ways: Array = made.get("WAYS", [])
	var sheet: Image = _sheet()
	var his: Image = _his()
	var frames: SpriteFrames = load(World3d.HIS_FRAMES) as SpriteFrames
	if sheet == null or his == null or frames == null or ways.size() != 4:
		debt("his workshop is not copied in; run tools/vendor_workshop.sh")
		return
	var below: int = his.get_height()
	var invented: PackedStringArray = PackedStringArray()
	for row: int in ways.size():
		var slice := frames.get_frame_texture(
			StringName("idle_" + String(ways[row])), 0) as AtlasTexture
		if slice == null:
			continue
		var region: Rect2i = Rect2i(slice.region)
		var his_own: Dictionary = {}
		for y: int in region.size.y:
			for x: int in region.size.x:
				his_own[his.get_pixelv(region.position + Vector2i(x, y)).to_rgba32()] = true
		for col: int in 4:
			var at: Vector2i = Vector2i(
				col * World3d.OUR_CELL.x, below + row * World3d.OUR_CELL.y)
			for y: int in World3d.OUR_CELL.y:
				for x: int in World3d.OUR_CELL.x:
					if his_own.has(sheet.get_pixelv(at + Vector2i(x, y)).to_rgba32()):
						continue
					invented.append("%s at %d,%d" % [String(ways[row]), x, y])
					break
				if invented.size() > 0:
					break
			if invented.size() > 0:
				break
		if invented.size() > 0:
			break
	assert_eq(invented.size(), 0, "no colour of ours: %s" % str(invented))


func test_the_tool_reads_his_folder_and_writes_ours() -> void:
	# The second condition. `prototypes/` is his and the tool only reads it; `assets/` is
	# the approved 2D pack's family and `tools/asset_validator.gd` would rightly refuse a
	# sheet made of his palette. Ours sits beside the 3D window.
	var made: Dictionary = _tool()
	var reads: String = String(made.get("HIS_SHEET", ""))
	var writes: String = String(made.get("OUT_PNG", ""))
	assert_true(reads.begins_with("prototypes/"), "it reads his own folder: %s" % reads)
	assert_true(writes.begins_with("view3d/"), "and writes beside the window: %s" % writes)
	assert_false(writes.begins_with("assets/"), "never into the 2D pack's family")
	assert_false(writes.begins_with("prototypes/"), "and never into his")


## How many pixels of one cell differ from another's, sampled every other row and column —
## enough to tell a drawn pose from an undrawn one and cheap enough for the fast suite.
func _differing(sheet: Image, one: Vector2i, other: Vector2i) -> int:
	var count: int = 0
	for y: int in range(0, World3d.OUR_CELL.y, 2):
		for x: int in range(0, World3d.OUR_CELL.x, 2):
			if sheet.get_pixelv(one + Vector2i(x, y)) \
					!= sheet.get_pixelv(other + Vector2i(x, y)):
				count += 1
	return count


# ------------------------------- moved from test_combat.gd when it went (K6) ---

func test_his_brother_has_not_drawn_a_blow() -> void:
	# Written down as a test rather than as a note, so the day the sheet gains an
	# `attack_left` this fails and somebody chooses between his and ours. **A watch and not
	# a debt since 2026-09-30**, when Yannick widened the art rule: we may draw what the
	# game needs, coherent with his hand, so our frames owe nobody anything.
	var frames: SpriteFrames = load(World3d.HIS_FRAMES) as SpriteFrames
	if frames == null:
		debt("his workshop is not copied in; run tools/vendor_workshop.sh")
		return
	var names: PackedStringArray = PackedStringArray()
	for name: StringName in frames.get_animation_names():
		names.append(String(name))
	assert_eq(names.size(), 8, "eight animations: %s" % str(names))
	for way: String in ["up", "down", "left", "right"]:
		assert_true(names.has("idle_" + way), "idle_%s" % way)
		assert_true(names.has("walk_" + way), "walk_%s" % way)


func test_the_frames_we_drew_are_there() -> void:
	# Yannick's exception to the art rule, 2026-09-19, kept as a check so that a build
	# which quietly lost the sheet falls back to his eight animations and says so rather
	# than drawing a fist that is not there.
	#
	# **The row count is the tool's, not this window's, since K5 (2026-09-24).** The sheet
	# grew a row for north and a row for south, and the window has not been taught them
	# yet; right and left are deliberately the *last* two rows, so what the window counts
	# up from the bottom still lands where it always did. `test_fight_frames.gd` holds the
	# rest of the frames' checks.
	if not ResourceLoader.exists(World3d.OUR_FIGHT_FRAMES):
		debt("view3d/fight/traveler_sheet.png is missing — run tools/draw_fight_frames.gd")
		return
	var sheet: Texture2D = load(World3d.OUR_FIGHT_FRAMES) as Texture2D
	assert_not_null(sheet, "our sheet loads")
	var his: Texture2D = null
	var frames: SpriteFrames = load(World3d.HIS_FRAMES) as SpriteFrames
	if frames != null:
		var slice := frames.get_frame_texture(&"idle_right", 0) as AtlasTexture
		his = slice.atlas if slice != null else null
	var drawn: GDScript = load("res://tools/draw_fight_frames.gd") as GDScript
	var rows: int = (drawn.get_script_constant_map().get("WAYS", []) as Array).size()
	assert_eq(rows, 4, "four facings drawn")
	if his != null:
		assert_eq(int(sheet.get_width()), int(his.get_width()),
			"ours is his sheet, the same width")
		assert_eq(int(sheet.get_height()),
			int(his.get_height()) + World3d.OUR_CELL.y * rows,
			"with our rows below it — his pixels stay at his coordinates")
