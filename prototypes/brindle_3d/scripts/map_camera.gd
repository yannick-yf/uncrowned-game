extends Camera3D
## Map inspection camera only; no player or NPC behaviour is introduced.

const MIN_ZOOM: float = 12.0
var tilt_degrees: float = 55.0
var azimuth_degrees: float = 0.0
var _overview: bool = true
var _bridge_index: int = -1

var focus: Vector3 = Vector3.ZERO
var _maximum_zoom: float = 420.0
@onready var _ground: Node3D = get_node("../Terrain")
@onready var _dimensions: Label = get_node("../MapInfo/Dimensions")


func _ready() -> void:
	_ground.connect(&"rebuilt", _on_ground_rebuilt)
	get_viewport().size_changed.connect(_update_limits)
	_on_ground_rebuilt()


func _on_ground_rebuilt() -> void:
	_dimensions.text = "UNCROWNED  /  ATELIER DE CARTE\n%.0f × %.0f m  ·  Brindle, aciérie, scierie et cité royale" % [
		float(_ground.get("width_m")), float(_ground.get("depth_m"))]
	frame_all()


func _update_limits() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var aspect: float = viewport_size.x / maxf(1.0, viewport_size.y)
	var extent_x: float = float(_ground.get("width_m"))
	var extent_z: float = float(_ground.get("depth_m"))
	var yaw: float = deg_to_rad(azimuth_degrees)
	var span_x: float = absf(cos(yaw)) * extent_x + absf(sin(yaw)) * extent_z
	var span_z: float = absf(cos(yaw)) * extent_z + absf(sin(yaw)) * extent_x
	var required_height: float = maxf(span_z * sin(deg_to_rad(tilt_degrees)) + 235.0 * float(_ground.get("elevation_scale")) * cos(deg_to_rad(tilt_degrees)), span_x / aspect)
	_maximum_zoom = maxf(48.0, required_height * 1.65)
	size = clampf(size, MIN_ZOOM, _maximum_zoom)
	_update_transform()


func frame_all() -> void:
	_overview = true
	tilt_degrees = 55.0
	azimuth_degrees = 0.0
	_update_limits()
	focus = Vector3(0, 65.0 * float(_ground.get("elevation_scale")), 0)
	size = _maximum_zoom / 1.65 * 1.20
	_update_transform()


func close_view() -> void:
	var scale_x: float = float(_ground.get("width_m")) / 768.0
	var scale_z: float = float(_ground.get("depth_m")) / 768.0
	set_view(Vector2(120 * scale_x, -140 * scale_z), 150.0 * maxf(scale_x, scale_z), 45.0, -12.0)


func set_view(at: Vector2, zoom: float, tilt: float = 45.0, azimuth: float = 0.0) -> void:
	_overview = false
	focus = Vector3(at.x, 0, at.y)
	size = zoom
	tilt_degrees = tilt
	azimuth_degrees = azimuth
	_update_transform()


func _process(delta: float) -> void:
	var movement := Vector2.ZERO
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movement.x += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_LEFT):
		movement.x -= 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_UP):
		movement.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movement.y += 1.0
	var speed: float = maxf(10.0, size * 0.55)
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= 2.0
	if not movement.is_zero_approx():
		_overview = false
		movement = movement.normalized() * speed * delta
		focus += Basis(Vector3.UP, deg_to_rad(azimuth_degrees)) * Vector3(movement.x, 0.0, movement.y)
		_update_transform()


func _update_transform() -> void:
	focus.x = clampf(focus.x, -float(_ground.get("width_m")) * 0.5, float(_ground.get("width_m")) * 0.5)
	focus.z = clampf(focus.z, -float(_ground.get("depth_m")) * 0.5, float(_ground.get("depth_m")) * 0.5)
	if not _overview:
		focus.y = maxf(float(_ground.call("height_at_world", focus.x, focus.z)), float(_ground.call("water_at_world", focus.x, focus.z))) + 7.0
	rotation_degrees = Vector3(-tilt_degrees, azimuth_degrees, 0.0)
	# Bring close inspections near their subject; a fixed 100 m retreat can place
	# unrelated upstream terrain and water between the camera and a small workshop.
	position = focus + basis.z * maxf(30.0, size * 1.65)
	far = maxf(1200.0, size * 4.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			frame_all()
		elif event.keycode == KEY_F:
			close_view()
		elif event.keycode == KEY_G:
			_ground.call("toggle_guides")
		elif event.keycode == KEY_B:
			set_view(Vector2(175,255),90,49,-12)
		elif event.keycode == KEY_L:
			set_view(Vector2(175,321),138,31,-10)
		elif event.keycode == KEY_M:
			set_view(Vector2(308,80),62,27,-70)
		elif event.keycode == KEY_I:
			set_view(Vector2(235,37),112,49,-25)
		elif event.keycode == KEY_C:
			set_view(Vector2(-177,-232),230,38,-18)
		elif event.keycode == KEY_T:
			set_view(Vector2(237,-159),98,48,24)
		elif event.keycode == KEY_V:
			var farm: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://planning/farming-town.json"))
			set_view(Vector2(farm.focus_xz[0],farm.focus_xz[1]),142,48,-22)
		elif event.keycode == KEY_P:
			var bridges: Node3D=get_node_or_null("../Decor/Franchissements/Ponts")
			if bridges!=null and bridges.get_child_count()>0:
				_bridge_index=wrapi(_bridge_index+1,0,bridges.get_child_count())
				var bridge: Node3D=bridges.get_child(_bridge_index)
				set_view(Vector2(bridge.position.x,bridge.position.z),maxf(42,float(bridge.get_meta("length_m",20))*2.8),38,rad_to_deg(bridge.rotation.y)+55)
	elif event is InputEventMouseButton and event.pressed:
		_overview = false
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			size = clampf(size * 0.85, MIN_ZOOM, _maximum_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			size = clampf(size / 0.85, MIN_ZOOM, _maximum_zoom)
		_update_transform()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		azimuth_degrees -= event.relative.x * 0.25
		tilt_degrees = clampf(tilt_degrees + event.relative.y * 0.2, 25.0, 80.0)
		_update_transform()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		_overview = false
		var metres_per_pixel: float = size / get_viewport().get_visible_rect().size.y
		var shift := Vector3(-event.relative.x * metres_per_pixel, 0, -event.relative.y * metres_per_pixel / sin(deg_to_rad(tilt_degrees)))
		focus += Basis(Vector3.UP, deg_to_rad(azimuth_degrees)) * shift
		_update_transform()
