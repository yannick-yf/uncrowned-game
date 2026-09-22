extends RefCounted
## Offline placement of the authored farm plan; no positions are invented here.
## Fields bake terrain height into private meshes. Orchards share source meshes
## through MultiMesh, with individual trunk colliders and editable plan markers.
const MESH_OUTPUT: String = "res://assets/farming_village/meshes/"
const SOIL_EDGE_LENGTH_M: float = .85
const SOIL_LIFT_M: float = .045
var b: Variant
var field_count: int = 0
var tree_count: int = 0
var multimesh_count: int = 0

func _init(builder: Variant) -> void:
	b = builder

func build() -> void:
	assert(b.sector is Node3D, "Planting requires builder.sector: Node3D")
	assert(b.ground != null, "Planting requires builder.ground")
	assert(b.asset_catalog is Dictionary, "Planting requires the farm catalogue keyed by asset ID")
	assert(b.layout is Dictionary, "Planting requires the authored layout")
	assert(DirAccess.make_dir_recursive_absolute(MESH_OUTPUT) == OK)
	field_count = 0
	tree_count = 0
	multimesh_count = 0
	var cultures: Node3D = _get_group(b.sector, "Cultures")
	var orchards: Node3D = _get_group(b.sector, "Vergers")
	cultures.set_meta("placement_mode", "vertex heights baked from terrain; regenerate after terrain edits")
	orchards.set_meta("placement_mode", "MultiMesh transforms baked from individual terrain samples")
	for spec: Dictionary in b.layout.get("fields", []):
		_build_field(cultures, spec)
	for spec: Dictionary in b.layout.get("orchards", []):
		_build_orchard(orchards, spec)
	b.sector.set_meta("farm_field_count", field_count)
	b.sector.set_meta("farm_fruit_tree_count", tree_count)
	b.sector.set_meta("farm_orchard_multimesh_count", multimesh_count)
	print("FARM_PLANTING_OK fields=", field_count, " trees=", tree_count, " multimeshes=", multimesh_count)

func _get_group(parent: Node3D, group_name: String) -> Node3D:
	var existing: Node = parent.get_node_or_null(NodePath(group_name))
	if existing != null:
		assert(existing is Node3D)
		return existing as Node3D
	var group: Node3D = Node3D.new()
	group.name = group_name
	parent.add_child(group)
	return group

func _asset_scene(asset_id: String) -> PackedScene:
	assert(b.asset_catalog.has(asset_id), "Unknown farming asset: " + asset_id)
	var entry: Variant = b.asset_catalog[asset_id]
	var path: String = str(entry.get("scene", "")) if entry is Dictionary else str(entry)
	assert(not path.is_empty(), "Missing scene for farming asset: " + asset_id)
	var scene: PackedScene = load(path) as PackedScene
	assert(scene != null, "Could not load farming asset: " + path)
	return scene

func _build_field(parent: Node3D, spec: Dictionary) -> void:
	var field_id: String = _safe_id(str(spec["id"]))
	assert(not parent.has_node(NodePath(field_id)), "Repeated field ID: " + field_id)
	var field: Node3D = _asset_scene(str(spec["asset"])).instantiate() as Node3D
	assert(field != null)
	# This becomes a baked, local node subtree rather than a linked asset scene:
	# otherwise a PackedScene save could retain the source meshes instead of the
	# per-field warped replacements on its descendants.
	field.scene_file_path = ""
	field.name = field_id
	parent.add_child(field)
	var xz: Vector2 = Vector2(float(spec["xz"][0]), float(spec["xz"][1]))
	var scale_xz: Array = spec.get("scale", [1.0, 1.0])
	assert(scale_xz.size() == 2 and float(scale_xz[0]) > 0 and float(scale_xz[1]) > 0)
	var ground_offset: float = float(spec.get("ground_offset", 0.0))
	var yaw: float = deg_to_rad(float(spec.get("yaw", 0.0)))
	var basis: Basis = Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(float(scale_xz[0]), 1, float(scale_xz[1])))
	var anchor: Vector3 = Vector3(xz.x, _ground_height(xz) + ground_offset, xz.y)
	field.transform = _world_transform(parent).affine_inverse() * Transform3D(basis, anchor)
	field.set_meta("layout_id", field_id)
	field.set_meta("source_asset", str(spec["asset"]))
	field.set_meta("ground_conforming", true)
	field.set_meta("terrain_conformed", true)
	field.set_meta("terrain_height_baked", true)
	field.set_meta("walk_through", true)
	field.set_meta("placement_mode", "baked_mesh_vertices")
	field.set_meta("baked_ground_offset_m", ground_offset)
	field.set_meta("soil_sampling_edge_m", SOIL_EDGE_LENGTH_M)
	field.set_meta("soil_surface_lift_m", SOIL_LIFT_M)
	field.set_meta("authored_xz", [xz.x, xz.y])
	field.set_meta("authored_yaw_degrees", float(spec.get("yaw", 0.0)))
	field.set_meta("authored_scale_xz", scale_xz)
	# No sector_tools script is attached: re-grounding this root would apply the
	# elevation a second time after its individual vertices have been conformed.
	var height_cache: Dictionary = {}
	var mesh_index: int = 0
	for child: Node in field.find_children("*", "MeshInstance3D", true, false):
		var mesh_node: MeshInstance3D = child as MeshInstance3D
		if mesh_node.mesh == null:
			continue
		var original: Mesh = mesh_node.mesh
		var warped: ArrayMesh = ArrayMesh.new()
		var mesh_world: Transform3D = _world_transform(mesh_node)
		var mesh_inverse: Transform3D = mesh_world.affine_inverse()
		for surface_index: int in original.get_surface_count():
			assert(original.surface_get_primitive_type(surface_index) == Mesh.PRIMITIVE_TRIANGLES,
				"Farming field surfaces must use triangles")
			var arrays: Array = original.surface_get_arrays(surface_index).duplicate(true)
			var is_soil: bool = _is_soil_surface(mesh_node, surface_index)
			if is_soil:
				arrays = _subdivide_soil(arrays, mesh_world.basis)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for vertex_index: int in vertices.size():
				var world_vertex: Vector3 = mesh_world * vertices[vertex_index]
				var sample_xz: Vector2 = Vector2(world_vertex.x, world_vertex.z)
				if not height_cache.has(sample_xz):
					height_cache[sample_xz] = _ground_height(sample_xz)
				# Keep the original stem/leaf/soil height above the asset's pivot.
				var height_above_pivot: float = world_vertex.y - anchor.y
				world_vertex.y = float(height_cache[sample_xz]) + ground_offset + height_above_pivot + (SOIL_LIFT_M if is_soil else 0.0)
				vertices[vertex_index] = mesh_inverse * world_vertex
			arrays[Mesh.ARRAY_VERTEX] = vertices
			# Rebuild normals after warping while retaining colours and UVs.
			arrays[Mesh.ARRAY_NORMAL] = null
			arrays[Mesh.ARRAY_TANGENT] = null
			var intermediate: ArrayMesh = ArrayMesh.new()
			intermediate.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var surface: SurfaceTool = SurfaceTool.new()
			surface.create_from(intermediate, 0)
			surface.generate_normals()
			if arrays[Mesh.ARRAY_TEX_UV] != null and not (arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array).is_empty():
				surface.generate_tangents()
			surface.set_material(original.surface_get_material(surface_index))
			surface.commit(warped)
		var mesh_path: String = MESH_OUTPUT + field_id + "_" + str(mesh_index) + ".res"
		assert(ResourceSaver.save(warped, mesh_path, ResourceSaver.FLAG_COMPRESS) == OK)
		mesh_node.mesh = ResourceLoader.load(mesh_path, "ArrayMesh", ResourceLoader.CACHE_MODE_REPLACE) as ArrayMesh
		mesh_index += 1
	# The authored field kit is deliberately collider-free. Fail visibly if a
	# different kind of asset is accidentally entered as a walk-through field.
	assert(field.find_children("*", "CollisionShape3D", true, false).is_empty(), "A field asset unexpectedly includes a collider")
	field.set_meta("terrain_sample_count", height_cache.size())
	field_count += 1

func _is_soil_surface(mesh_node: MeshInstance3D, surface_index: int) -> bool:
	var material: Material = mesh_node.get_active_material(surface_index)
	var description: String = str(mesh_node.name).to_lower()
	if material != null:
		description += " " + material.resource_path.to_lower() + " " + material.resource_name.to_lower()
	return "earth" in description or "soil" in description

func _subdivide_soil(source_arrays: Array, world_basis: Basis) -> Array:
	# The source earth surface contains long polygon triangles. Moving only their
	# corners lets terrain pass through the middle. Split every long edge before
	# sampling elevation, including the low ridges of the ploughed-soil material.
	# Longest-edge bisection keeps narrow furrow triangles economical. Shared
	# source edges get the same dyadic split points, so there are no open seams.
	var data: Dictionary = {"positions": [], "colors": [], "uv": [], "uv2": []}
	for p: Vector3 in source_arrays[Mesh.ARRAY_VERTEX]:
		data["positions"].append(p)
	if source_arrays[Mesh.ARRAY_COLOR] != null:
		for color: Color in source_arrays[Mesh.ARRAY_COLOR]:
			data["colors"].append(color)
	if source_arrays[Mesh.ARRAY_TEX_UV] != null:
		for uv: Vector2 in source_arrays[Mesh.ARRAY_TEX_UV]:
			data["uv"].append(uv)
	if source_arrays[Mesh.ARRAY_TEX_UV2] != null:
		for uv: Vector2 in source_arrays[Mesh.ARRAY_TEX_UV2]:
			data["uv2"].append(uv)
	var source_indices: PackedInt32Array = PackedInt32Array()
	if source_arrays[Mesh.ARRAY_INDEX] != null:
		source_indices = source_arrays[Mesh.ARRAY_INDEX]
	if source_indices.is_empty():
		for i: int in data["positions"].size():
			source_indices.append(i)
	var finished_indices: PackedInt32Array = PackedInt32Array()
	var midpoint_cache: Dictionary = {}
	var edge_limit_squared: float = SOIL_EDGE_LENGTH_M * SOIL_EDGE_LENGTH_M
	for i: int in range(0, source_indices.size(), 3):
		var source_triangle: Vector3i = Vector3i(source_indices[i], source_indices[i + 1], source_indices[i + 2])
		# Native earth tops sit at .045 m, their perimeter skirts at .003 m and
		# raised plough furrows at .100 m. Taller brown props are not a soil mesh.
		var max_height: float = maxf(data["positions"][source_triangle.x].y,
			maxf(data["positions"][source_triangle.y].y, data["positions"][source_triangle.z].y))
		if max_height > .14:
			finished_indices.append_array(PackedInt32Array([source_triangle.x, source_triangle.y, source_triangle.z]))
			continue
		var pending: Array[Vector3i] = [source_triangle]
		while not pending.is_empty():
			var triangle: Vector3i = pending.pop_back()
			var a: Vector3 = data["positions"][triangle.x]
			var c: Vector3 = data["positions"][triangle.y]
			var d: Vector3 = data["positions"][triangle.z]
			var ac: float = _projected_edge_squared(world_basis * (c - a))
			var cd: float = _projected_edge_squared(world_basis * (d - c))
			var da: float = _projected_edge_squared(world_basis * (a - d))
			if maxf(ac, maxf(cd, da)) <= edge_limit_squared:
				finished_indices.append_array(PackedInt32Array([triangle.x, triangle.y, triangle.z]))
			elif ac >= cd and ac >= da:
				var middle: int = _soil_midpoint(data, midpoint_cache, triangle.x, triangle.y)
				pending.append(Vector3i(triangle.x, middle, triangle.z))
				pending.append(Vector3i(middle, triangle.y, triangle.z))
			elif cd >= da:
				var middle: int = _soil_midpoint(data, midpoint_cache, triangle.y, triangle.z)
				pending.append(Vector3i(triangle.x, triangle.y, middle))
				pending.append(Vector3i(triangle.x, middle, triangle.z))
			else:
				var middle: int = _soil_midpoint(data, midpoint_cache, triangle.z, triangle.x)
				pending.append(Vector3i(triangle.x, triangle.y, middle))
				pending.append(Vector3i(middle, triangle.y, triangle.z))
	var arrays: Array = source_arrays.duplicate(true)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(data["positions"])
	arrays[Mesh.ARRAY_INDEX] = finished_indices
	arrays[Mesh.ARRAY_NORMAL] = null
	arrays[Mesh.ARRAY_TANGENT] = null
	if not data["colors"].is_empty():
		arrays[Mesh.ARRAY_COLOR] = PackedColorArray(data["colors"])
	if not data["uv"].is_empty():
		arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(data["uv"])
	if not data["uv2"].is_empty():
		arrays[Mesh.ARRAY_TEX_UV2] = PackedVector2Array(data["uv2"])
	return arrays

func _soil_midpoint(data: Dictionary, cache: Dictionary, a: int, c: int) -> int:
	var edge: Vector2i = Vector2i(mini(a, c), maxi(a, c))
	if cache.has(edge):
		return int(cache[edge])
	var next: int = data["positions"].size()
	data["positions"].append((data["positions"][a] + data["positions"][c]) * .5)
	for attribute: String in ["colors", "uv", "uv2"]:
		if not data[attribute].is_empty():
			data[attribute].append(data[attribute][a].lerp(data[attribute][c], .5))
	cache[edge] = next
	return next

func _projected_edge_squared(edge: Vector3) -> float:
	return edge.x * edge.x + edge.z * edge.z

func _build_orchard(parent: Node3D, spec: Dictionary) -> void:
	var orchard_id: String = _safe_id(str(spec["id"]))
	assert(not parent.has_node(NodePath(orchard_id)), "Repeated orchard ID: " + orchard_id)
	var orchard: Node3D = Node3D.new()
	orchard.name = orchard_id
	parent.add_child(orchard)
	orchard.set_meta("layout_id", orchard_id)
	orchard.set_meta("placement_mode", "shared_mesh_multimeshes")
	orchard.set_meta("canopy_walk_through", true)
	orchard.set_meta("trunk_solid", true)
	orchard.set_meta("tree_count", spec.get("trees", []).size())
	var buckets: Dictionary = {}
	var inverse_orchard: Transform3D = _world_transform(orchard).affine_inverse()
	var index: int = 0
	for tree_spec: Dictionary in spec.get("trees", []):
		var asset_id: String = str(tree_spec["asset"])
		var source: Node3D = _asset_scene(asset_id).instantiate() as Node3D
		assert(source != null)
		var scale_factor: float = float(tree_spec.get("scale", 1.0))
		assert(scale_factor > 0, "Fruit-tree scale must be positive")
		var xz: Vector2 = Vector2(float(tree_spec["xz"][0]), float(tree_spec["xz"][1]))
		var offset: float = float(tree_spec.get("ground_offset", 0.0))
		var yaw: float = deg_to_rad(float(tree_spec.get("yaw", 0.0)))
		var tree_world: Transform3D = Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale_factor),
			Vector3(xz.x, _ground_height(xz) + offset, xz.y))
		var tree_local: Transform3D = inverse_orchard * tree_world
		var tree_name: String = _safe_id(str(tree_spec.get("id", asset_id + "_" + str(index))))
		var marker: Marker3D = Marker3D.new()
		marker.name = tree_name + "_Emplacement"
		marker.transform = tree_local
		marker.set_meta("source_asset", asset_id)
		marker.set_meta("authored_xz", [xz.x, xz.y])
		marker.set_meta("editing", "Edit planning layout then regenerate; this marker does not move MultiMesh instances")
		orchard.add_child(marker)
		for child: Node in source.find_children("*", "MeshInstance3D", true, false):
			var mesh_node: MeshInstance3D = child as MeshInstance3D
			if mesh_node.mesh == null:
				continue
			# Farm assets have their materials on each merged MeshInstance3D.
			# Unsupported overrides fail explicitly rather than changing a tree.
			for surface_index: int in mesh_node.mesh.get_surface_count():
				assert(mesh_node.get_surface_override_material(surface_index) == null,
					"Farm MultiMesh expects mesh materials or a whole-node override")
			var key: String = _resource_key(mesh_node.mesh) + "|" + _resource_key(mesh_node.material_override)
			if not buckets.has(key):
				buckets[key] = {"mesh": mesh_node.mesh, "material": mesh_node.material_override,
					"transforms": [], "label": asset_id + "_" + str(mesh_node.name), "cast_shadow": mesh_node.cast_shadow}
			buckets[key]["transforms"].append(tree_local * _relative_transform(source, mesh_node))
		_copy_trunk_collisions(source, orchard, tree_local, tree_name)
		source.free()
		index += 1
		tree_count += 1
	var bucket_index: int = 0
	for key: String in buckets:
		var bucket: Dictionary = buckets[key]
		var mesh: Mesh = bucket["mesh"]
		var transforms: Array = bucket["transforms"]
		var multimesh: MultiMesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = false
		multimesh.use_custom_data = false
		multimesh.mesh = mesh
		multimesh.instance_count = transforms.size()
		var bounds: AABB = AABB()
		for instance_index: int in transforms.size():
			var tr: Transform3D = transforms[instance_index]
			multimesh.set_instance_transform(instance_index, tr)
			var transformed_bounds: AABB = tr * mesh.get_aabb()
			bounds = transformed_bounds if instance_index == 0 else bounds.merge(transformed_bounds)
		multimesh.custom_aabb = bounds.grow(.04)
		var resource_path: String = MESH_OUTPUT + orchard_id + "_multimesh_" + str(bucket_index) + ".res"
		assert(ResourceSaver.save(multimesh, resource_path, ResourceSaver.FLAG_COMPRESS) == OK)
		var renderer: MultiMeshInstance3D = MultiMeshInstance3D.new()
		renderer.name = _safe_id(str(bucket["label"])) + "_" + str(bucket_index)
		renderer.multimesh = ResourceLoader.load(resource_path, "MultiMesh", ResourceLoader.CACHE_MODE_REPLACE) as MultiMesh
		renderer.material_override = bucket["material"]
		renderer.cast_shadow = bucket["cast_shadow"]
		renderer.set_meta("instances", transforms.size())
		renderer.set_meta("source_mesh", mesh.resource_path)
		orchard.add_child(renderer)
		bucket_index += 1
		multimesh_count += 1

func _copy_trunk_collisions(source: Node3D, orchard: Node3D, tree_transform: Transform3D, prefix: String) -> void:
	var copied: int = 0
	for child: Node in source.find_children("*", "StaticBody3D", true, false):
		var source_body: StaticBody3D = child as StaticBody3D
		var lower_name: String = str(source_body.name).to_lower()
		assert("tronc" in lower_name or "trunk" in lower_name,
			"Fruit-tree source unexpectedly contains a non-trunk collider: " + str(source_body.name))
		var body: StaticBody3D = StaticBody3D.new()
		body.name = prefix + "_Tronc_" + str(copied)
		body.transform = tree_transform * _relative_transform(source, source_body)
		body.collision_layer = source_body.collision_layer
		body.collision_mask = source_body.collision_mask
		body.physics_material_override = source_body.physics_material_override
		body.set_meta("collision_policy", "source trunk only")
		orchard.add_child(body)
		for shape_child: Node in source_body.find_children("*", "CollisionShape3D", true, false):
			var source_shape: CollisionShape3D = shape_child as CollisionShape3D
			var shape: CollisionShape3D = CollisionShape3D.new()
			shape.name = "FormeTronc"
			shape.shape = source_shape.shape
			shape.disabled = source_shape.disabled
			# The body transform already includes source_body.transform.
			shape.transform = _relative_transform(source_body, source_shape, false)
			body.add_child(shape)
		copied += 1
	assert(copied > 0, "A fruit-tree source has no trunk collider")

func _relative_transform(ancestor: Node3D, node: Node3D, include_ancestor: bool = true) -> Transform3D:
	var transform: Transform3D = Transform3D.IDENTITY
	var current: Node = node
	while current != ancestor:
		assert(current != null, "Node is not inside the requested source asset")
		if current is Node3D:
			transform = (current as Node3D).transform * transform
		current = current.get_parent()
	return ancestor.transform * transform if include_ancestor else transform

func _world_transform(node: Node3D) -> Transform3D:
	# Also works while the builder's scene is detached from the SceneTree.
	var transform: Transform3D = Transform3D.IDENTITY
	var current: Node = node
	while current != null:
		if current is Node3D:
			transform = (current as Node3D).transform * transform
		current = current.get_parent()
	return transform

func _resource_key(resource: Resource) -> String:
	if resource == null:
		return "none"
	return resource.resource_path if not resource.resource_path.is_empty() else str(resource.get_instance_id())

func _ground_height(xz: Vector2) -> float:
	var height: float = float(b.ground.surface_height_at_world(xz.x, xz.y))
	assert(is_finite(height), "Non-finite terrain height at " + str(xz))
	return height

func _safe_id(value: String) -> String:
	assert(not value.is_empty(), "An authored placement ID is required")
	assert(value == value.validate_filename() and not "/" in value and not "\\" in value,
		"Unsafe authored placement ID: " + value)
	return value
