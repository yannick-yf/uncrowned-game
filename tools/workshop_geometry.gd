extends RefCounted

## Only the build tool loads nodes (2026-09-15). Core receives plain obstacle
## polygons; roof envelopes must not turn open halls and porches into solid boxes.
const FOLDERS: Array[String] = ["assets", "materials", "planning", "prototype_3d", "scenes", "scripts", "shaders"]


static func town_with_collisions(town: Dictionary) -> Dictionary:
	var out: Dictionary = town.duplicate(true)
	for item: Dictionary in (out.get("buildings", []) as Array) + (out.get("props", []) as Array):
		var path: String = String(item["scene"])
		var copied: String = path.replace("res://", "res://view3d/workshop/")
		var source: String = path.replace("res://", RegionBake.WORKSHOP)
		var expected: String = FileAccess.get_file_as_string(source)
		for folder: String in FOLDERS:
			expected = expected.replace("res://%s/" % folder, "res://view3d/workshop/%s/" % folder)
		if not FileAccess.file_exists(copied) or FileAccess.get_file_as_string(copied) != expected:
			push_error("stale workshop scene %s; run tools/vendor_workshop.sh" % source)
			return {}
		var scene: PackedScene = load(copied) as PackedScene
		if scene == null:
			return {}
		var root: Node3D = scene.instantiate() as Node3D
		var at: Array = item["xz"]
		var placement := Transform3D(Basis(Vector3.UP, deg_to_rad(float(item.get("yaw", 0)))),
			Vector3(float(at[0]), 0.0, float(at[1])))
		var polygons: Array = []
		if not _collect(root, placement, polygons):
			root.free()
			return {}
		item["obstacles"] = polygons
		root.free()
	return out


static func _collect(node: Node, parent: Transform3D, polygons: Array) -> bool:
	var transform: Transform3D = parent * (node as Node3D).transform if node is Node3D else parent
	if node is CollisionShape3D and not (node as CollisionShape3D).disabled:
		var shape: Shape3D = (node as CollisionShape3D).shape
		var vertices := PackedVector3Array()
		if shape is BoxShape3D:
			var half: Vector3 = (shape as BoxShape3D).size * 0.5
			for x: float in [-half.x, half.x]:
				for y: float in [-half.y, half.y]:
					for z: float in [-half.z, half.z]:
						vertices.append(Vector3(x, y, z))
		elif shape is CylinderShape3D:
			var cylinder := shape as CylinderShape3D
			for i: int in 16:
				for y: float in [-cylinder.height * 0.5, cylinder.height * 0.5]:
					vertices.append(Vector3(cos(TAU * i / 16.0) * cylinder.radius, y,
						sin(TAU * i / 16.0) * cylinder.radius))
		elif shape is ConvexPolygonShape3D:
			vertices = (shape as ConvexPolygonShape3D).points
		else:
			push_error("unsupported workshop obstacle: %s" % node.name)
			return false
		var low: float = INF
		var high: float = -INF
		var footprint := PackedVector2Array()
		for vertex: Vector3 in vertices:
			var world: Vector3 = transform * vertex
			low = minf(low, world.y)
			high = maxf(high, world.y)
			footprint.append(Vector2(world.x, world.z))
		# The walker can pass below a roof and over a shallow floor slab.
		if low < 1.8 and high > 0.35 and footprint.size() >= 3:
			var polygon: Array = []
			for point: Vector2 in Geometry2D.convex_hull(footprint):
				polygon.append([point.x, point.y])
			polygons.append(polygon)
	for child: Node in node.get_children():
		if not _collect(child, transform, polygons):
			return false
	return true
