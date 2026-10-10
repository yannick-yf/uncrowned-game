extends SceneTree

## Builds `view3d/title/brindle_dusk.jpg`: **his world at dusk, for the title** (D19, the
## audit's 20). The title was a night sky and a treeline of the 2D pack's trees — the one
## pack the art rule says never appears — and nothing of his world. Now the menu stands over
## Brindle at dusk, the picture gliding slowly behind it.
##
## **A picture, not a world.** Building his world behind the menu costs two and a half
## seconds before the title can show, and a second world when the game begins. His camera is
## orthographic, so gliding over a picture of it is exactly what a gliding camera would show;
## what a picture loses is the smoke's drift, and the title draws ash over it instead.
##
## It builds the window as the game does, with the game's cast in it, at dusk
## (`World3d.dusk()`), frames Brindle wider than play does and photographs it into a
## viewport twice the screen. Run with a display, not headless — a headless run draws
## nothing:
##
##     godot --path . -s tools/capture_title.gd
##
## Re-runnable: the same world, the same seed, the same picture, but for the fires' flicker.

const OUT: String = "res://view3d/title/brindle_dusk.jpg"
const SIZE: Vector2i = Vector2i(2560, 1440)
## Metres the picture spans top to bottom: wider than play's 24, so it can glide.
const SPAN_M: float = 42.0
## Where the camera looks, from Brindle's centre, in tiles: a little north, so the ruins,
## the well and the roads out of the village are in it and the graves' mist is not.
const LOOK_FROM_CENTRE: Vector2 = Vector2(2.0, -4.0)
## Where the player stands while the picture is taken: far off, out of it.
const AWAY: Vector2 = Vector2(40.5, 40.5)
const SETTLE_FRAMES: int = 150

var _view: SubViewport = null
var _window: World3d = null
var _frames: int = 0
var _at: Vector2 = Vector2.ZERO


func _initialize() -> void:
	var landscape: Dictionary = RegionBake.read_landscape()
	var region: Region = Region.load_baked()
	var sim: Sim = Game.build()
	_view = SubViewport.new()
	_view.size = SIZE
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_view.msaa_3d = Viewport.MSAA_4X
	root.add_child(_view)
	_window = World3d.new()
	_view.add_child(_window)
	_window.build(region, landscape, Art.new(), sim)
	_window.dusk()
	_at = Vector2(Places.shared().centre(&"brindle")) + Vector2(0.5, 0.5) + LOOK_FROM_CENTRE
	var lens := _window.get_node_or_null(^"Lens") as Camera3D
	if lens != null:
		lens.size = SPAN_M
		_window.set(&"_zoom", SPAN_M)


func _process(_delta: float) -> bool:
	_frames += 1
	# The player stands far off, out of the picture: this is Brindle, not him.
	_window.sync({
		"player": AWAY, "facing": Vector2i(0, 1), "camera": _at,
		"tents": 6, "crowd": 4, "free": {}, "shuttered": false, "escort": 10,
		"towns": {}, "extra_guards": 0, "witnesses": [], "now": float(_frames) / 60.0,
	}, 1.0 / 60.0)
	if _frames < SETTLE_FRAMES:
		return false
	var picture: Image = _view.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://view3d/title/"))
	var error: Error = picture.save_jpg(ProjectSettings.globalize_path(OUT), 0.9)
	print("title: %dx%d of Brindle at dusk -> %s (%s)" % [picture.get_width(), picture.get_height(), OUT,
		error_string(error)])
	quit(0 if error == OK else 1)
	return true
