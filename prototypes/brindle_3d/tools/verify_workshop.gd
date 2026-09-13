extends SceneTree
## Load the shipped workshop and exercise physical access with its actual character.
## This is independent of the production simulation's test runner.
var failures: int = 0
var player: CharacterBody3D
var camera: Camera3D
var ground: Node3D
var world: Node3D

func _initialize() -> void:
	# Runtime errors can abandon a GDScript function without quitting the process.
	create_timer(50.0).timeout.connect(_timed_out)
	call_deferred("run")

func _timed_out() -> void:
	push_error("Workshop verification timed out before completion.")
	quit(1)

func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func frames(count: int) -> void:
	for i: int in count: await physics_frame

func run() -> void:
	var session: Node3D = (load("res://scenes/test_brindle.tscn") as PackedScene).instantiate()
	root.add_child(session)
	world = session.get_node("World")
	player = world.get_node("Characters/Player")
	camera = world.get_node("PlayerCamera")
	ground = world.get_node("Terrain")
	camera.set_process_unhandled_input(false)
	await frames(35)
	check(int(ground.get("chunk_count")) > 0, "terrain chunks loaded")
	check(int(ground.get("water_triangle_count")) > 0, "water mesh loaded")
	check(player.is_on_floor(), "character spawn rests on terrain")
	for path: String in ["Decor/ForetsBrindle", "Decor/ForetsNordEst", "Decor/MineAcierie"]:
		check(world.get_node_or_null(path) != null, "sector present: " + path)
	check(not world.find_children("*", "MultiMeshInstance3D", true, false).is_empty(), "saved vegetation instances present")
	var smokes: Array[Node] = world.find_children("FumeeResiduelle", "CPUParticles3D", true, false)
	check(smokes.size() == 2, "two residual smoke emitters")
	for smoke: CPUParticles3D in smokes:
		check(smoke.emitting and smoke.amount > 0, "smoke active: " + str(smoke.get_parent().name))
	var ground_material: ShaderMaterial = ground.get("grass_material")
	check(ground_material.get_shader_parameter("scorch_enabled") == true, "burned ground enabled")
	var mask: Texture2D = ground_material.get_shader_parameter("scorch_mask")
	# Read the source PNG: a fresh headless import can return GPU-compressed pixels.
	var pixels: Image = Image.load_from_file(mask.resource_path)
	var houses: Node3D = world.get_node("Decor/Brindle/Maisons")
	check(houses.get_child_count() == 6, "six saved ruin instances")
	for house: Node3D in houses.get_children():
		check(house.get_node_or_null("FondationOrigine") != null, "source foundation retained: " + str(house.name))
		check(house.find_children("*", "Light3D", true, false).is_empty(), "no habitation lights: " + str(house.name))
		var uv := Vector2i((Vector2(house.position.x, house.position.z) - Vector2(102, 193)) * 8)
		check(pixels.get_pixel(uv.x, uv.y).r > .7, "scorch mask covers house: " + str(house.name))
		# Approach through each building's own doorway orientation. Moving the real
		# capsule catches lips and overhead debris that a single ray can miss.
		var start: Vector3 = house.to_global(Vector3(0, 0, 3.5))
		start.y = ground.call("height_at_world", start.x, start.z) + .12
		player.position = start; player.velocity = Vector3.ZERO
		camera.set("azimuth_degrees", house.rotation_degrees.y)
		await frames(20)
		Input.action_press("move_up")
		await frames(45)
		Input.action_release("move_up")
		await frames(12)
		var local: Vector3 = house.to_local(player.position)
		check(local.z < 1.75 and local.y > .20, "character crosses entrance: " + str(house.name))
		if local.z >= 1.75: print("Blocked position: ", local)
	# Keep the final character position from contaminating route queries.
	player.collision_layer = 0
	await frames(2)
	check_paths()
	print("WORKSHOP_CHECK_RESULT ", "PASS" if failures == 0 else "FAIL", " failures=", failures)
	quit(0 if failures == 0 else 1)

func check_paths() -> void:
	var sphere := SphereShape3D.new(); sphere.radius = .30
	var blocked: Array[String] = []
	var samples: int = 0
	for path: Path3D in world.get_node("Decor/Brindle/TraceDesChemins").get_children():
		var points: PackedVector3Array = path.curve.get_baked_points()
		# Door approaches are covered by the physical walk above. Exclude only the
		# terminal samples that enter a building footprint or the well itself.
		var skip: int = 6 if str(path.name).begins_with("acces_") or path.name == "puits" else 0
		for i: int in range(0, points.size() - skip, 3):
			var p: Vector3 = points[i]
			p.y = ground.call("height_at_world", p.x, p.z) + .95
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = sphere; query.transform = Transform3D(Basis.IDENTITY, p); query.collision_mask = 1
			if not world.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
				blocked.append(str(path.name))
			samples += 1
	check(samples > 0 and blocked.is_empty(), "village paths remain passable")
	if not blocked.is_empty(): print("Blocked routes: ", blocked)
