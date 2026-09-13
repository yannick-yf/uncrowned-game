extends Node
## Cycle piloté par la distance réellement parcourue, après move_and_slide().
## Une phase commune aux quatre directions évite de recommencer le pas en tournant.
@export_range(0.5, 6.0, 0.05) var cycle_distance := 3.0
@export_range(0.01, 0.5, 0.01) var movement_threshold := 0.08
@export_range(0.0, 0.1, 0.005) var stop_delay := 0.04
@export_range(1.0, 2.0, 0.05) var direction_hysteresis := 1.25
@export var sprite_path: NodePath = ^"../AnimatedSprite3D"

var facing: StringName = &"down"
var cycle_phase := 0.0
var distance_travelled := 0.0
var still_time := 0.0
var is_walking := false
@onready var sprite: AnimatedSprite3D = get_node(sprite_path)


func _ready() -> void:
	reset_pose()


func update_motion(displacement: Vector3, delta: float, input: Vector2, camera: Camera3D) -> void:
	var planar := Vector3(displacement.x, 0.0, displacement.z)
	var distance := planar.length()
	var moving := distance > movement_threshold * delta
	var screen_motion := input
	if moving:
		var right := Vector3.RIGHT
		var back := Vector3.BACK
		if is_instance_valid(camera):
			right = camera.global_basis.x
			back = camera.global_basis.z
			right.y = 0.0
			back.y = 0.0
			screen_motion = Vector2(planar.dot(right.normalized()), planar.dot(back.normalized()))
		else:
			screen_motion = Vector2(planar.x, planar.z)
	if screen_motion.length_squared() > 0.000001:
		_update_facing(screen_motion)
	if moving:
		still_time = 0.0
		is_walking = true
		distance_travelled += distance
		cycle_phase = fposmod(cycle_phase + distance / cycle_distance, 1.0)
		_show_walk()
	else:
		still_time += delta
		if still_time >= stop_delay or not is_walking:
			is_walking = false
			_show_idle()
		else:
			# Pas de progression artificielle pendant l'arrêt ou contre un mur.
			_show_walk()


func _update_facing(direction: Vector2) -> void:
	var horizontal := facing == &"left" or facing == &"right"
	var ax := absf(direction.x)
	var ay := absf(direction.y)
	if ax > ay * direction_hysteresis:
		horizontal = true
	elif ay > ax * direction_hysteresis:
		horizontal = false
	if horizontal and ax > 0.0001:
		facing = &"right" if direction.x > 0.0 else &"left"
	elif ay > 0.0001:
		facing = &"down" if direction.y > 0.0 else &"up"


func _show_walk() -> void:
	var name := StringName("walk_" + String(facing))
	if sprite.animation != name:
		sprite.animation = name
	sprite.pause()
	var position := cycle_phase * sprite.sprite_frames.get_frame_count(name)
	sprite.set_frame_and_progress(floori(position), fposmod(position, 1.0))


func _show_idle() -> void:
	sprite.animation = StringName("idle_" + String(facing))
	sprite.pause()
	sprite.set_frame_and_progress(0, 0.0)


func reset_pose() -> void:
	cycle_phase = 0.0
	distance_travelled = 0.0
	still_time = 0.0
	is_walking = false
	facing = &"down"
	_show_idle()
