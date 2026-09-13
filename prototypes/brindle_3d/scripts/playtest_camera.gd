extends "res://prototype_3d/scripts/follow_camera.gd"

func snap_to_target() -> void:
	if is_instance_valid(target):
		focus = target.global_position + focus_offset
	_update_transform()

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		azimuth_degrees -= event.relative.x * 0.25
		tilt_degrees = clampf(tilt_degrees + event.relative.y * 0.2, 30.0, 65.0)
