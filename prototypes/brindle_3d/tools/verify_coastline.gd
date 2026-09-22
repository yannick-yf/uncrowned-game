extends SceneTree
## Exercise the real terrain, collision meshes and playable coastal approaches.
## Run with --headless --fixed-fps 60 --script res://tools/verify_coastline.gd.
const PLAN: String = "res://planning/coastline.json"
const EDITS: String = "res://assets/coastline/terrain_edits.f32"
const SOURCE_FILES: Array[String] = ["height", "water_level", "terrain_paint", "water_flow"]
var checks: int = 0
var failures: int = 0
var started: int = 0
var layout: Dictionary = {}
var original_hashes: Dictionary = {}
var baseline_height: PackedFloat32Array
var baseline_water: PackedFloat32Array
var height: PackedFloat32Array
var water: PackedFloat32Array
var n: int = 0
var extent: float = 768.0
var world: Node3D
var terrain: Node3D
var player: CharacterBody3D
var camera: Camera3D

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", label)

func run() -> void:
	started = Time.get_ticks_msec()
	check(FileAccess.file_exists(PLAN), "Coastline plan exists")
	check(FileAccess.file_exists(EDITS), "Sparse coastal terrain exists")
	if failures > 0:
		_finish(); return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLAN))
	check(parsed is Dictionary, "Coastline plan parses")
	if not parsed is Dictionary:
		_finish(); return
	layout = parsed
	extent = float(layout.get("extent_m", 768.0))
	for filename: String in SOURCE_FILES:
		original_hashes[filename] = FileAccess.get_sha256("res://assets/landscape/" + filename + ".f32")
	# Disable the overlay before _ready/rebuild; the baseline includes all other stamps.
	var map_scene: PackedScene = load("res://scenes/map_plate.tscn")
	var baseline: Node3D = map_scene.instantiate()
	var base_ground: Node3D = baseline.get_node("Terrain")
	base_ground.set("coastline_enabled", false)
	root.add_child(baseline)
	for frame: int in 4:
		await process_frame
	baseline_height = (base_ground.get("_height") as PackedFloat32Array).duplicate()
	baseline_water = (base_ground.get("_water") as PackedFloat32Array).duplicate()
	n = int(base_ground.get("_n"))
	check(n > 1 and baseline_height.size() == n * n, "Baseline terrain finished rebuilding")
	baseline.queue_free()
	await process_frame
	if failures > 0:
		_finish(); return
	var play_scene: PackedScene = load("res://scenes/test_brindle.tscn")
	var session: Node3D = play_scene.instantiate()
	root.add_child(session)
	world = session.get_node("World")
	terrain = world.get_node("Terrain")
	player = world.get_node("Characters/Player")
	camera = world.get_node("PlayerCamera")
	session.call("set_playing", true)
	camera.set_process_unhandled_input(false)
	for frame: int in 20:
		await physics_frame
	height = terrain.get("_height")
	water = terrain.get("_water")
	check(bool(terrain.get("coastline_enabled")), "Playable scene enables coastline")
	check(height.size() == n * n and water.size() == n * n, "Both terrain grids have matching dimensions")
	if height.size() != n * n or water.size() != n * n:
		session.queue_free(); await process_frame; _finish(); return
	_check_sparse_overlay()
	_check_hydrology()
	_check_protected_anchors()
	_check_chunk_seams()
	await _check_coastal_dressing()
	var trails: Array = layout.get("trails", [])
	check(trails.size() == 2, "Two authored coastal trails")
	for trail: Dictionary in trails:
		var profile: Array = trail.get("profile_xzy", [])
		check(profile.size() >= 2, str(trail.get("id", "trail")) + " has a route profile")
		if profile.size() < 2: continue
		var route: PackedVector2Array = _route_samples(profile)
		var label: String = str(trail.id)
		_check_route(route, label, minf(.65, float(trail.get("width_m", 3.0)) * .20))
		check(await _walk(route), label + " real player completes forward route")
		route.reverse()
		check(await _walk(route), label + " real player completes return route")
	var old_route: PackedVector2Array = _route_samples([[154, 283, 0], [147, 294, 0], [140, 305, 0]])
	_check_route(old_route, "Existing Brindle approach", .60)
	check(await _walk(old_route), "Real player reaches the coast from Brindle's existing path")
	old_route.reverse()
	check(await _walk(old_route), "Real player returns to Brindle's existing path")
	Input.action_release("move_down")
	for filename: String in SOURCE_FILES:
		check(FileAccess.get_sha256("res://assets/landscape/" + filename + ".f32") == original_hashes[filename], filename + " source file stays unchanged")
	session.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	Input.action_release("move_down")
	print("COASTLINE_CHECK ", "PASS" if failures == 0 else "FAIL", " checks=", checks, " failures=", failures, " elapsed_ms=", Time.get_ticks_msec() - started)
	quit(0 if failures == 0 else 1)

func _check_sparse_overlay() -> void:
	var records: PackedFloat32Array = FileAccess.get_file_as_bytes(EDITS).to_float32_array()
	check(records.size() > 0 and records.size() % 3 == 0, "Sparse records have index, target and weight")
	if records.size() % 3 != 0: return
	var edited: PackedByteArray = PackedByteArray(); edited.resize(n * n)
	var valid: bool = true
	var duplicate_indices: int = 0
	for i: int in range(0, records.size(), 3):
		if not is_finite(records[i]) or not is_finite(records[i + 1]) or not is_finite(records[i + 2]):
			valid = false; continue
		var index: int = int(records[i])
		if index < 0 or index >= n * n or float(index) != records[i] or records[i + 2] < 0.0 or records[i + 2] > 1.0:
			valid = false; continue
		duplicate_indices += int(edited[index] != 0)
		edited[index] = 1
	check(valid and duplicate_indices == 0, "Sparse indices, targets and weights are finite, bounded and unique")
	var finite: bool = true
	var outside_changes: int = 0
	var changes: int = 0
	var peak: float = -INF
	for index: int in height.size():
		finite = finite and is_finite(height[index]) and is_finite(water[index])
		if height[index] != baseline_height[index]:
			changes += 1
			if edited[index] == 0: outside_changes += 1
		var point: Vector2 = _grid_point(index)
		if point.x >= 110 and point.x <= 240 and point.y >= 310 and point.y <= 345:
			peak = maxf(peak, height[index])
	check(finite, "Every terrain and water sample is finite")
	check(changes > 0, "Overlay changes the actual terrain: " + str(changes) + " vertices")
	check(outside_changes == 0, "Height outside sparse indices is exactly unchanged: " + str(outside_changes))
	check(water == baseline_water, "All original water levels remain exactly unchanged")
	check(peak > 45.0, "Headland south of Brindle rises above 45 m: " + str(peak))
	print("COASTLINE_TERRAIN records=", records.size() / 3, " changed=", changes, " priority_peak=", peak)

func _check_hydrology() -> void:
	var altered_wet_beds: int = 0
	for index: int in height.size():
		# Seafloor shaping is allowed; freshwater river/lake beds must stay intact.
		if baseline_water[index] > .05 and baseline_water[index] > baseline_height[index] + .02 and height[index] != baseline_height[index]:
			altered_wet_beds += 1
	check(altered_wet_beds == 0, "Existing freshwater beds remain unchanged: " + str(altered_wet_beds))
	var points: Array = layout.get("protected_estuary", {}).get("points_xz", [])
	check(points.size() >= 2, "Marine estuary has a protected centerline")
	if points.size() < 2: return
	var route: PackedVector2Array = _route_samples(points)
	var dry: int = 0
	var altered: int = 0
	for point: Vector2 in route:
		var y: float = _sample(height, point)
		if _sample(water, point) <= y + .02: dry += 1
		if absf(y - _sample(baseline_height, point)) > .001: altered += 1
	check(dry == 0, "Estuary stays visibly wet from river to sea: " + str(dry) + " dry samples")
	check(altered == 0, "Protected estuary profile is unchanged: " + str(altered))
	check(_wet_connection(route[0], route[-1]), "Wet grid stays connected between both estuary endpoints")

func _wet_connection(start: Vector2, end: Vector2) -> bool:
	var first: int = _grid_index(start)
	var last: int = _grid_index(end)
	if water[first] <= height[first] + .02 or water[last] <= height[last] + .02: return false
	var visited: PackedByteArray = PackedByteArray(); visited.resize(n * n)
	var queue: PackedInt32Array = PackedInt32Array([first]); visited[first] = 1
	var cursor: int = 0
	while cursor < queue.size():
		var index: int = queue[cursor]; cursor += 1
		if index == last: return true
		for offset: int in [-1, 1, -n, n]:
			var neighbour: int = index + offset
			if neighbour < 0 or neighbour >= n * n: continue
			if absi(offset) == 1 and absi(neighbour % n - index % n) != 1: continue
			if visited[neighbour] != 0 or water[neighbour] <= height[neighbour] + .02: continue
			visited[neighbour] = 1; queue.append(neighbour)
	return false

func _check_protected_anchors() -> void:
	for anchor: Dictionary in layout.get("protected_anchors", []):
		var center: Vector2 = Vector2(anchor.xz[0], anchor.xz[1])
		var radius: float = maxf(0.0, float(anchor.get("radius_m", 1.0)) - 2.0)
		# Trail junctions are explicitly regraded; building footprints remain exact.
		if anchor.get("kind", "") == "graded_junction":radius = 0.0
		var greatest: float = 0.0
		for offset: Vector2 in [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var point: Vector2 = center + offset * radius
			greatest = maxf(greatest, absf(_sample(height, point) - _sample(baseline_height, point)))
		check(greatest < .04, str(anchor.id) + " protected footprint retains its ground: delta=" + str(greatest))

func _check_chunk_seams() -> void:
	var seams: Array[Vector2] = [Vector2(160, 320), Vector2(192, 320), Vector2(224, 320), Vector2(-320, -256), Vector2(-320, 192), Vector2(-128, 352)]
	var copies: Dictionary = {}
	for point: Vector2 in seams: copies[point] = []
	for body: Node in terrain.get_node("Landscape").get_children():
		if not str(body.name).begins_with("Ground_"): continue
		var surface: MeshInstance3D = body.get_node("Surface")
		var arrays: Array = surface.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for i: int in vertices.size():
			var point: Vector2 = Vector2(vertices[i].x, vertices[i].z)
			if copies.has(point): copies[point].append([vertices[i], normals[i]])
	for point: Vector2 in seams:
		var values: Array = copies[point]
		var matches: bool = values.size() >= 2
		for value: Array in values:
			matches = matches and (value[0] as Vector3).is_equal_approx(values[0][0]) and (value[1] as Vector3).is_equal_approx(values[0][1]) and absf((value[1] as Vector3).length() - 1.0) < .001
		check(matches, "Shared chunk vertices/normals agree at " + str(point) + " copies=" + str(values.size()))
		var collides: bool = true
		for offset: Vector2 in [Vector2.ZERO, Vector2(.025, 0), Vector2(-.025, 0), Vector2(0, .025), Vector2(0, -.025)]:
			var at: Vector2 = point + offset
			var y: float = _sample(height, at)
			var hit: Dictionary = _terrain_ray(at, y)
			collides = collides and not hit.is_empty()
			if not hit.is_empty(): collides = collides and absf(float(hit.position.y) - y) < .025
		check(collides, "Terrain collision is continuous on both sides of seam " + str(point))

func _terrain_ray(point: Vector2, y: float) -> Dictionary:
	var ignored: Array[RID] = [player.get_rid()]
	for attempt: int in 8:
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(point.x, y + .35, point.y), Vector3(point.x, y - .35, point.y), 1, ignored)
		var hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty(): return {}
		if str(hit.collider.name).begins_with("Ground_"): return hit
		ignored.append(hit.rid)
	return {}

func _route_samples(points: Array) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	for i: int in range(1, points.size()):
		var a: Vector2 = Vector2(points[i - 1][0], points[i - 1][1])
		var b: Vector2 = Vector2(points[i][0], points[i][1])
		var steps: int = maxi(1, ceili(a.distance_to(b) / .8))
		for step: int in steps: result.append(a.lerp(b, float(step) / steps))
	if not points.is_empty(): result.append(Vector2(points[-1][0], points[-1][1]))
	return result

func _check_route(route: PackedVector2Array, label: String, side_width: float) -> void:
	var capsule: CapsuleShape3D = CapsuleShape3D.new(); capsule.radius = .28; capsule.height = 1.3
	var wet: int = 0
	var steep: int = 0
	var maximum_grade: float = 0.0
	var issues: Array[String] = []
	var blockers: Array[String] = []
	for i: int in route.size():
		var direction: Vector2 = (route[mini(route.size() - 1, i + 1)] - route[maxi(0, i - 1)]).normalized()
		var side: Vector2 = Vector2(direction.y, -direction.x)
		var center_y: float = _sample(height, route[i])
		if i > 0:
			var distance: float = route[i].distance_to(route[i - 1])
			var grade: float = absf(center_y - _sample(height, route[i - 1])) / maxf(distance, .001)
			maximum_grade = maxf(maximum_grade, grade)
			if grade > .501:
				steep += 1
				if issues.size() < 4: issues.append(str(route[i - 1]) + " -> " + str(route[i]) + " grade=" + str(grade))
		for offset: float in [-side_width, 0.0, side_width]:
			var at: Vector2 = route[i] + side * offset
			var y: float = _sample(height, at)
			if float(terrain.call("water_at_world", at.x, at.y)) > y + .01: wet += 1
			var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
			query.shape = capsule; query.collision_mask = 1; query.exclude = [player.get_rid()]
			query.transform = Transform3D(Basis.IDENTITY, Vector3(at.x, y + .70, at.y))
			var hits: Array[Dictionary] = world.get_world_3d().direct_space_state.intersect_shape(query, 1)
			if not hits.is_empty() and blockers.size() < 4: blockers.append(str(at) + " " + str(hits[0].collider.get_path()))
	check(wet == 0, label + " three lanes stay dry: wet=" + str(wet))
	check(steep == 0, label + " actual terrain grade <=0.5: maximum=" + str(maximum_grade) + " excess=" + str(steep) + " " + str(issues))
	check(blockers.is_empty(), label + " three lanes admit the player's capsule: " + str(blockers))
	print("COASTLINE_ROUTE ", label, " samples=", route.size(), " max_grade=", maximum_grade)

func _walk(route: PackedVector2Array) -> bool:
	if route.size() < 2: return false
	Input.action_release("move_down")
	player.global_position = Vector3(route[0].x, _sample(height, route[0]) + .12, route[0].y)
	player.velocity = Vector3.ZERO
	for frame: int in 16: await physics_frame
	for index: int in range(1, route.size()):
		var reached: bool = false
		for frame: int in 180:
			var delta: Vector2 = route[index] - Vector2(player.global_position.x, player.global_position.z)
			if delta.length() < .26:
				reached = true; break
			camera.set("azimuth_degrees", rad_to_deg(atan2(delta.x, delta.y)))
			Input.action_press("move_down")
			await physics_frame
		Input.action_release("move_down")
		if not reached:
			var contacts: Array[String] = []
			for i: int in player.get_slide_collision_count():
				var collision: KinematicCollision3D = player.get_slide_collision(i)
				var collider: Object = collision.get_collider()
				contacts.append(str(collider.get_path()) if collider is Node else str(collider))
			print("COASTLINE_WALK_STOP position=", player.global_position, " target=", route[index], " contacts=", contacts)
			return false
	return true

func _check_coastal_dressing() -> void:
	var decor: Node3D = world.get_node_or_null("CoastlineDecor")
	check(decor != null, "Coastline dressing is integrated")
	if decor == null: return
	var placements: Array = decor.get("_placements")
	var assets: Dictionary = decor.get("_assets")
	var maximum: int = mini(1000, int(layout.get("rock_budget", {}).get("maximum_instances", 1000)))
	check(not placements.is_empty() and placements.size() <= maximum, "Native coastline instances stay within budget: " + str(placements.size()))
	check(int(decor.get_meta("coast_rock_instances", -1)) == placements.size(), "Rock instance metadata matches placement records")
	var geometry: Dictionary = {}
	for id: String in assets:
		var mesh: Mesh = assets[id].mesh
		var vertices: PackedVector3Array = PackedVector3Array()
		var bases: PackedVector3Array = PackedVector3Array()
		var triangles: int = 0
		for surface: int in mesh.get_surface_count():
			var arrays: Array = mesh.surface_get_arrays(surface)
			var source: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			vertices.append_array(source)
			if indices.is_empty():
				for i: int in source.size(): indices.append(i)
			triangles += indices.size() / 3
			for i: int in range(0, indices.size(), 3):
				var a: Vector3 = source[indices[i]]; var b: Vector3 = source[indices[i + 1]]; var c: Vector3 = source[indices[i + 2]]
				if absf(a.y) > .01 or absf(b.y) > .01 or absf(c.y) > .01: continue
				# Real bottom triangles, including their interiors, catch support gaps
				# between a few rock corners on the triangulated coastal terrain.
				bases.append_array(PackedVector3Array([a, b, c, (a+b)*.5, (b+c)*.5, (c+a)*.5, (a+b+c)/3.0]))
		geometry[id] = {"vertices":vertices, "bases":bases, "triangles":triangles, "bounds":mesh.get_aabb()}
		check(mesh.get_surface_count() == 1 and triangles <= 500 and triangles == int(assets[id].triangles), id + " native mesh/material budget and triangle accounting")
		check(not bases.is_empty(), id + " has a real ground-facing base")
	var coast: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://assets/landscape/landscape.json")) as Dictionary).coastline_xz
	var routes: Array = []
	var estuary: Dictionary = layout.protected_estuary
	routes.append({"points":estuary.points_xz, "width":float(estuary.clear_half_width_m)+float(estuary.blend_m), "id":"estuary"})
	for route: Dictionary in layout.get("trails", []): routes.append({"points":route.profile_xzy, "width":float(route.width_m)*.5+2.0, "id":route.id})
	for route: Dictionary in layout.get("protected_paths", []): routes.append({"points":route.points_xz, "width":float(route.clear_half_width_m)+2.0, "id":"protected approach"})
	for path: String in ["res://planning/river-routes-v2.json", "res://planning/brindle-sectors-v1.json"]:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		for route: Dictionary in data.get("routes", []): routes.append({"points":route.get("points_xz",route.get("points",[])), "width":float(route.get("width_m",route.get("width",3.0)))*.5+2.0, "id":route.id})
	var clearance_issues: Array[String] = []; var support_issues: Array[String] = []; var accounting_issues: Array[String] = []
	var total_triangles: int = 0; var stacks: int = 0; var maximum_gap: float = 0.0
	var sea: float = float(layout.get("sea_level_m", 0.0))
	for record: Dictionary in placements:
		var id: String = str(record.asset)
		if not geometry.has(id):
			accounting_issues.append("Missing mesh " + id); continue
		var tr: Transform3D = record.transform
		var point: Vector2 = Vector2(tr.origin.x, tr.origin.z)
		var data: Dictionary = geometry[id]
		total_triangles += int(data.triangles)
		var bounds: AABB = Transform3D(tr.basis, Vector3.ZERO) * data.bounds
		var radius: float = 0.0
		for corner: int in 8:
			var p: Vector3 = bounds.get_endpoint(corner)
			radius = maxf(radius, Vector2(p.x, p.z).length())
		if not tr.is_finite() or tr.basis.determinant() <= 0.0 or float(record.radius)+.001 < radius:
			if accounting_issues.size() < 4: accounting_issues.append(id + " invalid transform or underestimated footprint at " + str(point))
		if _signed_shore_distance(point, coast)+radius > 18.02:
			if clearance_issues.size() < 4: clearance_issues.append(id + " exceeds the 18 m landward band at " + str(point))
		for route: Dictionary in routes:
			if _polyline_distance(point, route.points) + .002 < float(route.width) + radius:
				if clearance_issues.size() < 4: clearance_issues.append(id + " intrudes into " + str(route.id) + " at " + str(point))
		for anchor: Dictionary in layout.get("protected_anchors", []):
			if point.distance_to(Vector2(anchor.xz[0],anchor.xz[1])) + .002 < float(anchor.radius_m)+float(anchor.get("blend_m",0.0))+radius:
				if clearance_issues.size() < 4: clearance_issues.append(id + " intrudes into " + str(anchor.id))
		var ground_y: float = _sample(height, point)
		if absf(float(record.ground_y)-ground_y) > .025 or tr.origin.y > ground_y+.025:
			if support_issues.size() < 4: support_issues.append(id + " pivot disagrees with terrain at " + str(point))
		var top: float = -INF
		for vertex: Vector3 in data.vertices: top = maxf(top, (tr*vertex).y)
		if top < sea+.10:
			if support_issues.size() < 4: support_issues.append(id + " completely hidden below the sea at " + str(point))
		for vertex: Vector3 in data.bases:
			var base: Vector3 = tr*vertex
			var gap: float = base.y-_sample(height,Vector2(base.x,base.z))
			maximum_gap = maxf(maximum_gap,gap)
			if gap > .04 and support_issues.size() < 4: support_issues.append(id + " unsupported base at " + str(base) + " gap=" + str(gap))
		if record.role == "stack":
			stacks += 1
			if ground_y < sea-4.025:
				if support_issues.size() < 4: support_issues.append(id + " marine stack starts beyond the shallow anchored band")
	check(accounting_issues.is_empty(), "Rock transforms and all four footprint corners are valid: " + str(accounting_issues))
	check(clearance_issues.is_empty(), "Complete rock footprints preserve estuary, trails and buildings: " + str(clearance_issues))
	check(support_issues.is_empty(), "Native rock bases are seated on terrain/seabed: max_gap=" + str(maximum_gap) + " " + str(support_issues))
	check(total_triangles == int(decor.get_meta("coast_rock_tris", -1)) and total_triangles <= maximum*500, "Instanced triangle accounting and maximum geometry budget: " + str(total_triangles))
	check(stacks <= 14 and stacks == int(decor.get_meta("coast_rock_stacks", -1)), "Marine stacks remain sparse: " + str(stacks))
	var batches: int = decor.find_children("*", "MultiMeshInstance3D", true, false).size()
	var colliders: Array[Node] = decor.find_children("*", "CollisionShape3D", true, false)
	check(batches > 0 and batches == int(decor.get_meta("coast_rock_batches", -1)), "Batch node count matches metadata without GPU getters: " + str(batches))
	check(colliders.size() < 110 and colliders.size() <= int(layout.rock_budget.collision_budget) and colliders.size() == int(decor.get_meta("coast_rock_colliders", -1)), "Convex rock collider budget and accounting: " + str(colliders.size()))
	var convex: bool = true
	for collider: CollisionShape3D in colliders: convex = convex and collider.shape is ConvexPolygonShape3D and not collider.disabled
	check(convex, "Rock obstacles use active native convex colliders")
	var fingerprint: PackedByteArray = var_to_bytes(placements)
	var child_count: int = decor.get_child_count()
	decor.call("rebuild")
	for frame: int in 3: await physics_frame
	check(var_to_bytes(decor.get("_placements")) == fingerprint, "Rebuild reproduces every rock transform and variant deterministically")
	check(decor.get_child_count() == child_count and decor.find_children("*", "MultiMeshInstance3D", true, false).size() == batches and decor.find_children("*", "CollisionShape3D", true, false).size() == colliders.size(), "Rebuild replaces generated batches/colliders without duplication")
	print("COASTLINE_ROCKS instances=", placements.size(), " triangles=", total_triangles, " batches=", batches, " colliders=", colliders.size(), " max_support_gap=", maximum_gap)

func _polyline_distance(point: Vector2, points: Array) -> float:
	var distance: float = INF
	for i: int in range(1,points.size()): distance = minf(distance, point.distance_to(Geometry2D.get_closest_point_to_segment(point,Vector2(points[i-1][0],points[i-1][1]),Vector2(points[i][0],points[i][1]))))
	return distance

func _signed_shore_distance(point: Vector2, points: Array) -> float:
	var best: float = INF; var signed_distance: float = INF
	for i: int in range(1,points.size()):
		var a: Vector2 = Vector2(points[i-1][0],points[i-1][1]); var b: Vector2 = Vector2(points[i][0],points[i][1])
		var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(point,a,b)
		var distance: float = point.distance_squared_to(nearest)
		if distance < best:
			best = distance
			var tangent: Vector2 = (b-a).normalized()
			signed_distance = (point-nearest).dot(Vector2(tangent.y,-tangent.x))
	return signed_distance

func _grid_point(index: int) -> Vector2:
	return Vector2(float(index % n), float(index / n)) * (extent / float(n - 1)) - Vector2.ONE * extent * .5

func _grid_index(point: Vector2) -> int:
	var grid: Vector2 = (point + Vector2.ONE * extent * .5) * float(n - 1) / extent
	return clampi(roundi(grid.y), 0, n - 1) * n + clampi(roundi(grid.x), 0, n - 1)

func _sample(data: PackedFloat32Array, point: Vector2) -> float:
	# Match the rendered/colliding two triangles, rather than bilinear interpolation.
	var grid: Vector2 = (point + Vector2.ONE * extent * .5) * float(n - 1) / extent
	var x: int = clampi(floori(grid.x), 0, n - 2)
	var z: int = clampi(floori(grid.y), 0, n - 2)
	var fx: float = clampf(grid.x - x, 0.0, 1.0)
	var fz: float = clampf(grid.y - z, 0.0, 1.0)
	var a: float = data[z * n + x]
	var b: float = data[z * n + x + 1]
	var c: float = data[(z + 1) * n + x]
	var d: float = data[(z + 1) * n + x + 1]
	return a + fx * (b - a) + fz * (c - a) if fx + fz <= 1.0 else d + (1.0 - fx) * (c - d) + (1.0 - fz) * (b - d)
