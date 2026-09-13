extends CharacterBody3D
## Déplacement sur X/Z relatif à la caméra. La gravité conserve le contact au sol.

@export_range(0.5, 15.0, 0.1) var move_speed: float = 5.0
@export_range(1.0, 100.0, 0.5) var acceleration: float = 28.0
@export_range(1.0, 100.0, 0.5) var deceleration: float = 36.0
@export_range(1.0, 60.0, 0.5) var gravity: float = 24.0
@export var camera_path: NodePath = ^"../../Camera3D"

var facing: StringName = &"down"
var spawn_position: Vector3
@onready var camera: Camera3D = get_node_or_null(camera_path) as Camera3D
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var walk_animation: Node = get_node_or_null(^"WalkAnimation")


func _ready() -> void:
	spawn_position = global_position


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed(&"reset_player") or global_position.y < -8.0:
		reset_to_spawn()
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var right := Vector3.RIGHT
	var back := Vector3.BACK
	if is_instance_valid(camera):
		right = camera.global_basis.x
		back = camera.global_basis.z
		right.y = 0.0
		back.y = 0.0
	var direction := right.normalized() * input.x + back.normalized() * input.y
	var rate := acceleration if input.length_squared() > 0.0 else deceleration
	velocity.x = move_toward(velocity.x, direction.x * move_speed, rate * delta)
	velocity.z = move_toward(velocity.z, direction.z * move_speed, rate * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	var before_move := global_position
	move_and_slide()
	if is_instance_valid(walk_animation):
		walk_animation.update_motion(global_position - before_move, delta, input, camera)
		facing = walk_animation.facing
	else:
		_update_animation(input)


func _update_animation(input: Vector2) -> void:
	if input.length_squared() > 0.01:
		if absf(input.x) > absf(input.y):
			facing = &"right" if input.x > 0.0 else &"left"
		else:
			facing = &"down" if input.y > 0.0 else &"up"
	var moving := Vector2(velocity.x, velocity.z).length() > 0.15
	var prefix := "walk_" if moving and input.length_squared() > 0.01 else "idle_"
	sprite.play(StringName(prefix + String(facing)))


func reset_to_spawn() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	if is_instance_valid(walk_animation):
		walk_animation.reset_pose()
