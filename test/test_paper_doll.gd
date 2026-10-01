extends TestCase

## The player in layers (group A): his brother's traveller split into the parts a person
## is dressed in, by `tools/draw_player_layers.gd`, and stacked again by a shader.
##
## The one claim that makes the layers trustworthy is checked here: **stacked in
## `PaperDoll.ORDER`, his parts give his traveller back, pixel for pixel** — so a player who
## changes nothing on the creation screen is the character his brother drew, and anything
## else is a change somebody chose.

const SLOW: bool = false


func _base() -> Image:
	var texture: Texture2D = load(World3d.OUR_FIGHT_FRAMES) as Texture2D
	if texture == null:
		return null
	var img: Image = texture.get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _part(part: StringName) -> Image:
	var path: String = PaperDoll.sheet_path(part)
	if not ResourceLoader.exists(path):
		return null
	var img: Image = (load(path) as Texture2D).get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _his_frames() -> SpriteFrames:
	return load(World3d.HIS_FRAMES) as SpriteFrames if ResourceLoader.exists(World3d.HIS_FRAMES) else null


## His parts, in the order the shader stacks them.
func _stacked_order() -> Array[StringName]:
	var out: Array[StringName] = []
	for layer: StringName in PaperDoll.ORDER:
		for part: StringName in PaperDoll.HIS_PARTS:
			if part == layer or (layer == &"hair" and part == &"hair_spiky"):
				out.append(part)
	return out


func test_every_part_is_a_sheet_his_size() -> void:
	var base: Image = _base()
	assert_not_null(base, "his sheet with our fight cells")
	for part: StringName in PaperDoll.HIS_PARTS:
		var img: Image = _part(part)
		assert_not_null(img, "%s is there — run tools/draw_player_layers.gd" % part)
		if img != null and base != null:
			assert_eq(img.get_size(), base.get_size(), "%s has his sheet's size" % part)
	assert_eq(_stacked_order().size(), PaperDoll.HIS_PARTS.size(), "every part of him has its place in the order")


func test_his_parts_stacked_are_his_traveller() -> void:
	var frames: SpriteFrames = _his_frames()
	var base: Image = _base()
	if frames == null or base == null:
		debt("his workshop is not copied in; run tools/vendor_workshop.sh")
		return
	var parts: Array[Image] = []
	for part: StringName in _stacked_order():
		parts.append(_part(part))
	if parts.has(null):
		assert_true(false, "a part is missing — run tools/draw_player_layers.gd")
		return
	# His four idle frames, and three of our cells — a blow, a wind-up and a flinch.
	var rects: Array[Rect2i] = []
	for way: String in ["down", "left", "right", "up"]:
		rects.append(Rect2i((frames.get_frame_texture(StringName("idle_" + way), 0) as AtlasTexture).region))
	var below: int = base.get_height() - World3d.OUR_CELL.y * World3d.OUR_WAYS.size()
	for cell: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(3, 2)]:
		rects.append(Rect2i(cell.x * World3d.OUR_CELL.x, below + cell.y * World3d.OUR_CELL.y, World3d.OUR_CELL.x, World3d.OUR_CELL.y))
	var made: GDScript = load("res://tools/draw_cast_looks.gd") as GDScript
	for rect: Rect2i in rects:
		var differ: int = 0
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				var top := Color(0, 0, 0, 0)
				for img: Image in parts:
					var c: Color = img.get_pixel(x, y)
					if c.a > 0.0:
						top = c
				var his: Color = base.get_pixel(x, y)
				if made.visible(his):
					if not top.is_equal_approx(his):
						differ += 1
				elif top.a > 0.0:
					differ += 1
		assert_eq(differ, 0, "%s: his parts stacked are his traveller, pixel for pixel" % rect)


func test_his_hair_is_its_own_layer_and_a_head_is_under_it() -> void:
	# Take his hair away, and there is a head: the skull painted under it, only where his
	# hair was, in his skin's colour, with his dark outline.
	var frames: SpriteFrames = _his_frames()
	var hair: Image = _part(&"hair_spiky")
	var skin: Image = _part(&"skin")
	if frames == null or hair == null or skin == null:
		debt("his workshop or the layers are missing")
		return
	var region := Rect2i((frames.get_frame_texture(&"idle_down", 0) as AtlasTexture).region)
	var hair_px: int = 0
	var under: int = 0
	for y: int in range(region.position.y, region.end.y):
		for x: int in range(region.position.x, region.end.x):
			if hair.get_pixel(x, y).a > 0.0:
				hair_px += 1
				if skin.get_pixel(x, y).a > 0.0:
					under += 1
	assert_true(hair_px > 3000, "his hair is a layer of its own: %d pixels" % hair_px)
	assert_true(under > hair_px / 4, "and a head stands under it: %d of its pixels" % under)
