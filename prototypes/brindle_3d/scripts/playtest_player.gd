extends "res://prototype_3d/scripts/player_controller.gd"
## Brindle's existing movement and animation, seated on the workshop terrain.
@export var spawn_xz := Vector2(181, 252)
var controls_enabled := true
var terrain_ready := false
@onready var terrain: Node3D = get_node("../../Terrain")

func _ready() -> void:
	super._ready()
	terrain.connect("rebuilt", _ground_rebuilt)
	if int(terrain.get("chunk_count")) > 0:
		_ground_rebuilt()

func _ground_rebuilt() -> void:
	spawn_position = Vector3(spawn_xz.x, terrain.call("height_at_world", spawn_xz.x, spawn_xz.y) + 0.12, spawn_xz.y)
	terrain_ready = true
	reset_to_spawn()

func _physics_process(delta: float) -> void:
	if not terrain_ready:
		return
	if not controls_enabled:
		velocity = Vector3.ZERO
		walk_animation.update_motion(Vector3.ZERO, delta, Vector2.ZERO, camera)
		return
	super._physics_process(delta)

func reset_to_spawn() -> void:
	super.reset_to_spawn()
	if is_instance_valid(camera) and camera.has_method("snap_to_target"):
		camera.call("snap_to_target")
