extends AnimatedSprite3D
## Le bas du sprite reste ancré aux pieds, même quand la caméra change d'inclinaison.

@export_range(1, 128, 1) var frame_height_pixels: int = 24
@export_range(0.0, 0.5, 0.01) var foot_clearance: float = 0.04
@export var use_texture_height: bool = true


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var height_pixels := float(frame_height_pixels)
	if use_texture_height and sprite_frames != null:
		var texture := sprite_frames.get_frame_texture(animation, frame)
		if texture != null:
			height_pixels = float(texture.get_height())
	var half_height := height_pixels * pixel_size * 0.5
	global_position = get_parent().global_position + Vector3.UP * foot_clearance + camera.global_basis.y * half_height
