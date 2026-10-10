extends TestCase

## **The fairy, a light with a shape** (D17, the audit's 18): her figure, drawn by
## `tools/draw_fairy.gd` in his manner. What a machine can say about it is said here: four
## frames of one beat, his dark outline round her, his all-or-nothing alpha, and not a pixel
## his shader's rule for what is background would throw away. Whether she is any good is a
## question for the frames of the wake.

const SLOW: bool = false


func _sheet() -> Image:
	if not ResourceLoader.exists(World3d.FAIRY_SHEET):
		return null
	var texture: Texture2D = load(World3d.FAIRY_SHEET) as Texture2D
	return texture.get_image() if texture != null else null


func test_her_sheet_is_four_frames_of_one_beat() -> void:
	var sheet: Image = _sheet()
	assert_true(sheet != null, "her sheet is drawn: tools/draw_fairy.gd")
	if sheet == null:
		return
	if sheet.is_compressed():
		sheet.decompress()
	assert_eq(sheet.get_size(), Vector2i(World3d.FAIRY_CELL * World3d.FAIRY_FRAMES, World3d.FAIRY_CELL),
		"four cells side by side")
	var shapes: Array[int] = []
	for frame: int in World3d.FAIRY_FRAMES:
		var drawn: int = 0
		for y: int in World3d.FAIRY_CELL:
			for x: int in World3d.FAIRY_CELL:
				if sheet.get_pixel(frame * World3d.FAIRY_CELL + x, y).a > 0.5:
					drawn += 1
		shapes.append(drawn)
		assert_true(drawn > 1500, "frame %d has a figure in it: %d pixels" % [frame, drawn])
	assert_true(shapes[0] != shapes[2], "and her wings move: %s" % str(shapes))


func test_she_is_drawn_in_his_manner() -> void:
	var sheet: Image = _sheet()
	if sheet == null:
		assert_true(false, "her sheet is drawn")
		return
	if sheet.is_compressed():
		sheet.decompress()
	# The sheet's mip levels blend her edge; the drawing itself is the top level.
	var flat: Image = sheet.duplicate() as Image
	flat.clear_mipmaps()
	var ink: int = 0
	var halfway: int = 0
	var thrown: int = 0
	for y: int in flat.get_height():
		for x: int in flat.get_width():
			var c: Color = flat.get_pixel(x, y)
			if c.a > 0.0 and c.a < 1.0:
				halfway += 1
			if c.a < 0.5:
				continue
			if c.r8 == 22 and c.g8 == 14 and c.b8 == 14:
				ink += 1
			var lin: Color = c.srgb_to_linear()
			var high: float = maxf(lin.r, maxf(lin.g, lin.b))
			var low: float = minf(lin.r, minf(lin.g, lin.b))
			if high > 0.35 and (high - low) / maxf(high, 0.001) < 0.22:
				thrown += 1
	assert_true(ink > 1000, "his dark outline round her: %d pixels of his ink" % ink)
	assert_eq(halfway, 0, "his alpha, all or nothing")
	assert_eq(thrown, 0, "and not a pixel his shader would take for the background")
