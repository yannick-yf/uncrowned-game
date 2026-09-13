extends Camera3D
## Caméra orthographique. Taille = hauteur visible en unités du monde.

@export var target_path: NodePath = ^"../Characters/Player"
@export_range(25.0, 75.0, 1.0) var tilt_degrees: float = 50.0
@export_range(-180.0, 180.0, 1.0) var azimuth_degrees: float = 0.0
@export_range(10.0, 70.0, 0.5) var zoom_size: float = 32.0
@export_range(5.0, 50.0, 0.5) var min_zoom: float = 14.0
@export_range(20.0, 90.0, 0.5) var max_zoom: float = 48.0
@export_range(0.5, 20.0, 0.5) var follow_speed: float = 6.0
@export_range(10.0, 100.0, 1.0) var distance: float = 45.0
@export var focus_offset: Vector3 = Vector3(0.0, 0.0, 1.0)

var focus: Vector3
@onready var target: Node3D = get_node_or_null(target_path) as Node3D


func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = zoom_size
	if is_instance_valid(target):
		focus = target.global_position + focus_offset
	_update_transform()


func _process(delta: float) -> void:
	if is_instance_valid(target):
		var desired := target.global_position + focus_offset
		focus = focus.lerp(desired, 1.0 - exp(-follow_speed * delta))
	zoom_size = clampf(zoom_size, min_zoom, max_zoom)
	size = lerpf(size, zoom_size, 1.0 - exp(-10.0 * delta))
	_update_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"zoom_in"):
		zoom_size = clampf(zoom_size - 2.0, min_zoom, max_zoom)
	elif event.is_action_pressed(&"zoom_out"):
		zoom_size = clampf(zoom_size + 2.0, min_zoom, max_zoom)


func _update_transform() -> void:
	var tilt := deg_to_rad(tilt_degrees)
	var azimuth := deg_to_rad(azimuth_degrees)
	var offset := Vector3(sin(azimuth) * cos(tilt), sin(tilt), cos(azimuth) * cos(tilt))
	global_position = focus + offset * distance
	look_at(focus, Vector3.UP)
