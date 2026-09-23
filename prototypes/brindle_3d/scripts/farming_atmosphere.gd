extends Node3D
## Local art direction. The authored map environment is restored outside the farm.
## Keep this node outside the generated village so offline rebuilds stay neutral.
@export var enabled: bool = true
var blend_weight: float = 0.0
var initialized: bool = false
var fog_volumes: Array[FogVolume] = []
var foliage_stats: Dictionary = {}
var _settings: Dictionary
var _plan: Dictionary
var _region: Rect2
var _world: Node3D
var _ground: Node3D
var _environment_node: WorldEnvironment
var _original_environment: Environment
var _environment: Environment
var _sun: DirectionalLight3D
var _base_sun: Dictionary = {}
var _fog_material: ShaderMaterial
var _quality_active: bool = false
var _particles: Node3D
var _active_camera: Camera3D
var _camera_far: float = 1200.0
var _last_camera_far: float = 1200.0
var _water: MeshInstance3D
var _original_water_override: Material
var _water_material: ShaderMaterial

func _ready() -> void:
	process_priority = 10
	call_deferred("_setup")

func _setup() -> void:
	_world = get_parent() as Node3D
	_ground = _world.get_node_or_null("Terrain")
	_environment_node = _world.get_node_or_null("WorldEnvironment")
	_sun = _world.get_node_or_null("Sun")
	var village: Node3D = _world.get_node_or_null("Decor/VillageFermier")
	if _ground == null or _sun == null or _environment_node == null or village == null:
		set_process(false)
		return
	_settings = JSON.parse_string(FileAccess.get_file_as_string("res://planning/farming-lighting.json"))
	_plan = JSON.parse_string(FileAccess.get_file_as_string("res://planning/farming-town.json"))
	var b: Array = _plan.bounds_xz
	_region = Rect2(b[0], b[1], b[2], b[3])
	_water = _ground.get_node_or_null("Landscape/LakeRiversAndSea")
	if _water != null:
		_original_water_override = _water.material_override
		var source: ShaderMaterial = _water.get_active_material(0) as ShaderMaterial
		if source != null:
			_water_material = source.duplicate() as ShaderMaterial
			_water_material.set_shader_parameter("farming_light_bounds", Vector4(_region.position.x, _region.position.y, _region.end.x, _region.end.y))
	_original_environment = _environment_node.environment
	_environment = _original_environment.duplicate() as Environment
	for property: String in ["rotation_degrees", "light_color", "light_energy", "light_angular_distance", "light_volumetric_fog_energy", "directional_shadow_max_distance", "directional_shadow_mode", "directional_shadow_blend_splits", "shadow_normal_bias", "shadow_bias"]:
		_base_sun[property] = _sun.get(property)
	_environment.volumetric_fog_density = 0.0
	_environment.volumetric_fog_anisotropy = _settings.fog_anisotropy
	_environment.volumetric_fog_ambient_inject = 0.22
	_environment.volumetric_fog_gi_inject = 0.0
	_environment.volumetric_fog_sky_affect = 0.0
	_environment.volumetric_fog_temporal_reprojection_enabled = true
	_environment.volumetric_fog_temporal_reprojection_amount = 0.86
	_environment.ssao_detail = 0.65
	_environment.ssao_light_affect = 0.08
	_environment.glow_hdr_threshold = 1.6
	_environment.glow_intensity = 0.17
	_environment.glow_bloom = 0.0
	_environment.ssil_enabled = false
	_fog_material = ShaderMaterial.new()
	_fog_material.shader = load("res://shaders/farming_orchard_mist.gdshader")
	_fog_material.set_shader_parameter("density", _settings.fog_density)
	_build_mist()
	if FileAccess.file_exists("res://scripts/farming_foliage_light.gd"):
		var helper: RefCounted = load("res://scripts/farming_foliage_light.gd").new()
		var stats: Variant = helper.call("apply", village)
		if stats is Dictionary:foliage_stats = stats
	if FileAccess.file_exists("res://scripts/farming_orchard_particles.gd"):
		_particles = Node3D.new()
		_particles.name = "FeuillesEtPoussieres"
		_particles.set_script(load("res://scripts/farming_orchard_particles.gd"))
		add_child(_particles)
		_particles.call("configure", _plan.orchards, _ground)
	initialized = true
	refresh(true)

func _build_mist() -> void:
	for orchard: Dictionary in _plan.orchards:
		var bounds: Rect2
		var first: bool = true
		var ground_min: float = INF
		var ground_max: float = -INF
		for tree: Dictionary in orchard.trees:
			var xz: Vector2 = Vector2(tree.xz[0], tree.xz[1])
			if first:
				bounds = Rect2(xz, Vector2.ZERO)
				first = false
			else:bounds = bounds.expand(xz)
			var y: float = _ground.call("surface_height_at_world", xz.x, xz.y)
			ground_min = minf(ground_min, y)
			ground_max = maxf(ground_max, y)
		if first:continue
		bounds = bounds.grow(float(_settings.fog_padding_m))
		var height: float = float(_settings.fog_height_m) + ground_max - ground_min
		var volume: FogVolume = FogVolume.new()
		volume.name = "Brume_" + str(orchard.id)
		volume.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
		volume.size = Vector3(bounds.size.x, height, bounds.size.y)
		volume.position = Vector3(bounds.get_center().x, ground_min + height * 0.5 - 0.25, bounds.get_center().y)
		volume.material = _fog_material
		add_child(volume)
		fog_volumes.append(volume)

func _process(delta: float) -> void:
	if initialized:refresh(false, delta)

func camera_subject(camera: Camera3D) -> Vector3:
	if camera == _world.get_node_or_null("MapCamera"):
		return camera.get("focus")
	var player: Node3D = _world.get_node_or_null("Characters/Player")
	if player != null and camera == _world.get_node_or_null("PlayerCamera"):
		return player.global_position
	var direction: Vector3 = -camera.global_basis.z
	var plane_height: float = _ground.call("surface_height_at_world", _region.get_center().x, _region.get_center().y)
	var t: float = maxf(0.0, (plane_height - camera.global_position.y) / minf(direction.y, -0.01))
	return camera.global_position + direction * t

func refresh(immediate: bool = false, delta: float = 0.0) -> void:
	if not initialized:return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:return
	if camera != _active_camera:
		if is_instance_valid(_active_camera):_active_camera.far = _camera_far
		_active_camera = camera
		_camera_far = camera.far
	elif blend_weight == 0.0 or not is_equal_approx(camera.far, _last_camera_far):
		# set_view()/frame_all() may have just selected a new authored clipping range.
		_camera_far = camera.far
	var focus: Vector3 = camera_subject(camera)
	var point: Vector2 = Vector2(focus.x, focus.z)
	var closest: Vector2 = point.clamp(_region.position, _region.end)
	var target: float = 1.0 - smoothstep(0.0, float(_settings.region_blend_margin_m), point.distance_to(closest))
	if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		target *= 1.0 - smoothstep(float(_settings.overview_fade_begin_m), float(_settings.overview_fade_end_m), camera.size)
	if not enabled:target = 0.0
	var previous: float = blend_weight
	blend_weight = target if immediate else move_toward(blend_weight, target, delta * 0.8)
	if blend_weight <= 0.001:
		blend_weight = 0.0
		if previous > 0.0 or immediate:
			_environment_node.environment = _original_environment
			if is_instance_valid(_water):_water.material_override = _original_water_override
			for property: String in _base_sun:_sun.set(property, _base_sun[property])
			for volume: FogVolume in fog_volumes:volume.visible = false
			_set_quality(false)
		camera.far = _camera_far
		_last_camera_far = camera.far
		if _particles != null:_particles.visible = false
		return
	_environment_node.environment = _environment
	_set_quality(true)
	var w: float = blend_weight
	if is_instance_valid(_water) and _water_material != null:
		_water.material_override = _water_material
		_water_material.set_shader_parameter("farming_light_balance", w)
	_environment.background_color = _original_environment.background_color.lerp(Color(_settings.sky_color), w)
	_environment.ambient_light_color = _original_environment.ambient_light_color.lerp(Color(_settings.ambient_color), w)
	_environment.ambient_light_energy = lerpf(_original_environment.ambient_light_energy, _settings.ambient_energy, w)
	_environment.ssao_radius = lerpf(_original_environment.ssao_radius, _settings.ao_radius_m, w)
	_environment.ssao_intensity = lerpf(_original_environment.ssao_intensity, _settings.ao_intensity, w)
	_environment.glow_enabled = true
	_environment.glow_intensity = 0.17 * w
	_environment.volumetric_fog_enabled = true
	# Both review and play cameras are orthographic: include their retreat distance.
	var distance: float = camera.global_position.distance_to(focus)
	# Godot's orthographic directional shadows use the camera far plane, not
	# directional_shadow_max_distance. Concentrate texels around the visible farm.
	camera.far = lerpf(_camera_far, maxf(125.0, distance + camera.size * 1.4 + 35.0), w)
	_last_camera_far = camera.far
	_environment.volumetric_fog_length = clampf(distance + camera.size * 0.8 + 22.0, 92.0, 480.0)
	_environment.volumetric_fog_detail_spread = 1.0
	var sun_angles: Array = _settings.sun_rotation_degrees
	_sun.rotation_degrees = (_base_sun.rotation_degrees as Vector3).lerp(Vector3(sun_angles[0], sun_angles[1], sun_angles[2]), w)
	_sun.light_color = (_base_sun.light_color as Color).lerp(Color(_settings.sun_color), w)
	_sun.light_energy = lerpf(_base_sun.light_energy, _settings.sun_energy, w)
	_sun.light_angular_distance = lerpf(_base_sun.light_angular_distance, _settings.sun_angular_distance, w)
	_sun.light_volumetric_fog_energy = lerpf(_base_sun.light_volumetric_fog_energy, _settings.sun_fog_energy, w)
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	_sun.directional_shadow_blend_splits = true
	_sun.directional_shadow_max_distance = lerpf(_base_sun.directional_shadow_max_distance, maxf(100.0, distance + camera.size * 1.2 + 35.0), w)
	_sun.shadow_normal_bias = lerpf(_base_sun.shadow_normal_bias, 0.65, w)
	_sun.shadow_bias = lerpf(_base_sun.shadow_bias, 0.06, w)
	_fog_material.set_shader_parameter("amount", w)
	for volume: FogVolume in fog_volumes:volume.visible = true
	if _particles != null:_particles.visible = true

func _set_quality(active: bool) -> void:
	if active == _quality_active:return
	_quality_active = active
	if DisplayServer.get_name() == "headless":return
	# High precision is concentrated in this small region; no extra shadow lights.
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_ULTRA if active else ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality"))
	RenderingServer.sub_surface_scattering_set_quality(RenderingServer.SUB_SURFACE_SCATTERING_QUALITY_HIGH if active else ProjectSettings.get_setting("rendering/environment/subsurface_scattering/subsurface_scattering_quality"))
	RenderingServer.environment_set_volumetric_fog_volume_size(int(_settings.fog_volume_size) if active else int(ProjectSettings.get_setting("rendering/environment/volumetric_fog/volume_size")), int(_settings.fog_volume_depth) if active else int(ProjectSettings.get_setting("rendering/environment/volumetric_fog/volume_depth")))

func _exit_tree() -> void:
	if not initialized:return
	if is_instance_valid(_active_camera):_active_camera.far = _camera_far
	if is_instance_valid(_water):_water.material_override = _original_water_override
	if is_instance_valid(_environment_node):_environment_node.environment = _original_environment
	if is_instance_valid(_sun):
		for property: String in _base_sun:_sun.set(property, _base_sun[property])
	_set_quality(false)
