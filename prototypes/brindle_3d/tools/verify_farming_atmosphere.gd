extends SceneTree
## Exercise local lighting through the real workshop cameras and scene lifecycle.
## Headless checks validate state and coverage; visual rays and GPU cost need rendering.
const SUN_PROPERTIES: Array[String] = ["rotation_degrees", "light_color", "light_energy", "light_angular_distance", "light_volumetric_fog_energy", "shadow_enabled", "directional_shadow_max_distance", "directional_shadow_mode", "directional_shadow_blend_splits", "shadow_normal_bias", "shadow_bias"]
var checks: int = 0
var failures: int = 0
var started_ms: int = 0
var world: Node3D
var ground: Node3D
var atmosphere: Node3D
var environment_node: WorldEnvironment
var original_environment: Environment
var original_environment_values: Dictionary = {}
var sun: DirectionalLight3D
var original_sun: Dictionary = {}
var water: MeshInstance3D
var original_water_override: Material
var original_water_source: ShaderMaterial
var original_water_values: Dictionary = {}
var original_water_balance: Variant
var original_water_shader_code: String = ""

func _initialize() -> void:
	started_ms = Time.get_ticks_msec()
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", label)

func run() -> void:
	var packed: PackedScene = load("res://scenes/test_brindle.tscn")
	check(packed != null, "Real workshop scene loads")
	if packed == null:
		_finish(); return
	var session: Node3D = packed.instantiate()
	world = session.get_node("World")
	ground = world.get_node("Terrain")
	environment_node = world.get_node("WorldEnvironment")
	original_environment = environment_node.environment
	for property: Dictionary in original_environment.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_STORAGE:
			original_environment_values[property.name] = original_environment.get(property.name)
	sun = world.get_node("Sun")
	for property: String in SUN_PROPERTIES: original_sun[property] = sun.get(property)
	# Observe the generated water before the atmosphere's deferred setup can touch it.
	ground.connect("rebuilt", _capture_water_source)
	root.add_child(session)
	for i: int in 45: await process_frame
	atmosphere = world.get_node_or_null("FarmingAtmosphere")
	check(atmosphere != null, "Local atmosphere controller is integrated")
	if atmosphere == null:
		session.queue_free(); await process_frame; _finish(); return
	check(bool(atmosphere.get("initialized")), "Controller initializes on the real terrain")
	if not bool(atmosphere.get("initialized")):
		session.queue_free(); await process_frame; _finish(); return
	check(water != null and original_water_source != null, "Original active water material captured when terrain is built")
	if water == null or original_water_source == null:
		session.queue_free(); await process_frame; _finish(); return
	check(original_water_balance == null or is_zero_approx(float(original_water_balance)), "Authored water has no farm light balance")
	# Explicit refreshes make transitions reproducible, without depending on FPS.
	atmosphere.set_process(false)
	var player: CharacterBody3D = world.get_node("Characters/Player")
	player.set_physics_process(false)
	var player_camera: Camera3D = world.get_node("PlayerCamera")
	var map_camera: Camera3D = world.get_node("MapCamera")
	var player_far: float = player_camera.far
	atmosphere.call("refresh", true)
	_check_neutral("Initial Brindle", player_camera, player_far)
	session.call("set_playing", false)
	map_camera.set_process(false)
	map_camera.call("set_view", Vector2(175, 255), 48.0, 48.0, -22.0)
	var map_far: float = map_camera.far
	atmosphere.call("refresh", true)
	_check_neutral("Map at Brindle", map_camera, map_far)
	map_camera.call("set_view", Vector2(-174, 34), 48.0, 48.0, -22.0)
	atmosphere.call("refresh", false, 0.25)
	check(float(atmosphere.get("blend_weight")) > 0.0 and float(atmosphere.get("blend_weight")) < 1.0, "Farm entry blends over time")
	_check_water_active("Partial farm entry", float(atmosphere.get("blend_weight")))
	atmosphere.call("refresh", true)
	_check_active("Farm map close-up", map_camera, map_far, Vector2(-174, 34))
	_check_orchard_volumes()
	map_camera.call("set_view", Vector2(175, 255), 48.0, 48.0, -22.0)
	atmosphere.call("refresh", true)
	_check_neutral("Return to Brindle", map_camera, map_far)
	map_camera.call("set_view", Vector2(-174, 34), 48.0, 48.0, -22.0)
	atmosphere.call("refresh", true)
	map_camera.call("set_view", Vector2(-174, 34), 500.0, 55.0, 0.0)
	var overview_far: float = map_camera.far
	atmosphere.call("refresh", true)
	_check_neutral("Wide overview stays neutral", map_camera, overview_far)
	# Switch while active: the abandoned camera must regain its own far plane.
	map_camera.call("set_view", Vector2(-174, 34), 48.0, 48.0, -22.0)
	map_far = map_camera.far
	atmosphere.call("refresh", true)
	player.global_position = Vector3(-174, ground.call("surface_height_at_world", -174, 34), 34)
	player.velocity = Vector3.ZERO
	session.call("set_playing", true)
	player_camera.set_process(false)
	atmosphere.call("refresh", true)
	check(is_equal_approx(map_camera.far, map_far), "Camera switch restores inactive map far plane")
	_check_active("Player visiting farm", player_camera, player_far, Vector2(-174, 34))
	player.global_position = Vector3(175, ground.call("surface_height_at_world", 175, 255), 255)
	player_camera.call("snap_to_target")
	atmosphere.call("refresh", true)
	_check_neutral("Player returns to Brindle", player_camera, player_far)
	player.global_position = Vector3(-174, ground.call("surface_height_at_world", -174, 34), 34)
	player_camera.call("snap_to_target")
	atmosphere.call("refresh", true)
	atmosphere.set("enabled", false)
	atmosphere.call("refresh", true)
	_check_neutral("Disabled controller", player_camera, player_far)
	atmosphere.set("enabled", true)
	atmosphere.call("refresh", true)
	_check_active("Re-enabled controller", player_camera, player_far, Vector2(-174, 34))
	world.remove_child(atmosphere)
	check(environment_node.environment == original_environment, "Removing active controller restores original Environment resource")
	check(is_equal_approx(player_camera.far, player_far), "Removing active controller restores camera far plane")
	_check_sun_restored("Controller removal")
	_check_water_restored("Controller removal")
	atmosphere.free()
	var original_unchanged: bool = true
	for property: String in original_environment_values:
		original_unchanged = original_unchanged and original_environment.get(property) == original_environment_values[property]
	check(original_unchanged, "Original Environment resource remains entirely unchanged")
	session.queue_free()
	await process_frame
	_finish()

func _check_neutral(label: String, camera: Camera3D, expected_far: float) -> void:
	check(is_zero_approx(float(atmosphere.get("blend_weight"))), label + ": zero farm blend")
	check(environment_node.environment == original_environment, label + ": exact original Environment resource")
	check(is_equal_approx(camera.far, expected_far), label + ": original camera far plane (expected " + str(expected_far) + ", got " + str(camera.far) + ")")
	_check_sun_restored(label)
	var invisible: bool = true
	for volume: FogVolume in atmosphere.get("fog_volumes"): invisible = invisible and not volume.visible
	check(invisible, label + ": local fog volumes hidden")
	_check_water_restored(label)

func _check_sun_restored(label: String) -> void:
	for property: String in SUN_PROPERTIES:
		# Node3D stores a basis; assigning its Euler angles entails a float round-trip.
		var same: bool = (sun.rotation_degrees as Vector3).is_equal_approx(original_sun[property]) if property == "rotation_degrees" else sun.get(property) == original_sun[property]
		check(same, label + ": original sun " + property)

func _check_active(label: String, camera: Camera3D, previous_far: float, focus: Vector2) -> void:
	check(is_equal_approx(float(atmosphere.get("blend_weight")), 1.0), label + ": full local blend")
	check(environment_node.environment != original_environment, label + ": separate Environment resource")
	check(environment_node.environment.volumetric_fog_enabled, label + ": true volumetric fog enabled")
	check(is_zero_approx(environment_node.environment.volumetric_fog_density), label + ": no global fog blanket")
	check(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, label + ": orthographic framing preserved")
	check(camera.far < previous_far and camera.far > camera.near, label + ": tighter valid shadow frustum")
	var visible_ground: bool = true
	for dx: float in [-camera.size * 0.45, 0.0, camera.size * 0.45]:
		for dz: float in [-camera.size * 0.45, 0.0, camera.size * 0.45]:
			var point: Vector3 = Vector3(focus.x + dx, ground.call("surface_height_at_world", focus.x + dx, focus.y + dz), focus.y + dz)
			var depth: float = -camera.to_local(point).z
			visible_ground = visible_ground and depth > camera.near and depth < camera.far - 0.5
	check(visible_ground, label + ": reduced far plane still covers surrounding ground")
	check(sun.light_color != original_sun.light_color or not is_equal_approx(sun.light_energy, original_sun.light_energy), label + ": local sun treatment applied")
	_check_water_active(label, 1.0)

func _capture_water_source() -> void:
	if original_water_source != null: return
	water = ground.get_node_or_null("Landscape/LakeRiversAndSea") as MeshInstance3D
	if water == null: return
	original_water_override = water.material_override
	original_water_source = water.get_active_material(0) as ShaderMaterial
	if original_water_source == null: return
	for property: Dictionary in original_water_source.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_STORAGE:
			original_water_values[property.name] = original_water_source.get(property.name)
	original_water_balance = original_water_source.get_shader_parameter("farming_light_balance")
	if original_water_source.shader != null:
		original_water_shader_code = original_water_source.shader.code

func _check_water_source_unchanged(label: String) -> void:
	var unchanged: bool = original_water_source.get_shader_parameter("farming_light_balance") == original_water_balance
	for property: String in original_water_values:
		unchanged = unchanged and original_water_source.get(property) == original_water_values[property]
	unchanged = unchanged and original_water_source.shader != null and original_water_source.shader.code == original_water_shader_code
	check(unchanged, label + ": source water material and shader remain untouched")

func _check_water_restored(label: String) -> void:
	check(water.material_override == original_water_override, label + ": exact original water override restored")
	check(water.get_active_material(0) == original_water_source, label + ": original active water material restored")
	_check_water_source_unchanged(label)

func _check_water_active(label: String, expected_balance: float) -> void:
	var runtime_material: ShaderMaterial = water.material_override as ShaderMaterial
	check(runtime_material != null and runtime_material != original_water_source, label + ": water uses a separate runtime material")
	if runtime_material != null:
		check(water.get_active_material(0) == runtime_material, label + ": runtime copy is the rendered water material")
		var balance: Variant = runtime_material.get_shader_parameter("farming_light_balance")
		check(balance != null and is_equal_approx(float(balance), expected_balance), label + ": farm balance belongs to runtime copy only")
	_check_water_source_unchanged(label)

func _check_orchard_volumes() -> void:
	var volumes: Array = atmosphere.get("fog_volumes")
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://planning/farming-town.json"))
	check(volumes.size() == 4 and volumes.size() == plan.orchards.size(), "Four local volumes cover the four authored orchards")
	for orchard: Dictionary in plan.orchards:
		var contained: bool = false
		for volume: FogVolume in volumes:
			var all_trees: bool = volume.visible and volume.material != null
			for tree: Dictionary in orchard.trees:
				var x: float = tree.xz[0]
				var z: float = tree.xz[1]
				var point: Vector3 = volume.to_local(Vector3(x, ground.call("surface_height_at_world", x, z) + 1.0, z))
				all_trees = all_trees and absf(point.x) < volume.size.x * 0.5 and absf(point.y) < volume.size.y * 0.5 and absf(point.z) < volume.size.z * 0.5
			contained = contained or all_trees
		check(contained, str(orchard.id) + ": mist is visible and anchored around actual tree positions")

func _finish() -> void:
	print("FARMING_ATMOSPHERE_CHECK ", "PASS" if failures == 0 else "FAIL", " checks=", checks, " failures=", failures, " elapsed_ms=", Time.get_ticks_msec() - started_ms)
	quit(0 if failures == 0 else 1)
