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


## The same, for pieces of his catalogue that *we* place (G1, 2026-09-21): each
## placement names his scene, where it stands in his metres and how it is turned, and
## comes back with the collision polygons his scene carries at that placement — so the
## bake blocks what his shapes block and not a box round them. Refuses a stale copy,
## as above. Returns the placements, or an empty array when a scene cannot be read.
static func pieces_with_collisions(pieces: Array) -> Array:
	var out: Array = []
	var loaded: Dictionary = {}
	for raw: Variant in pieces:
		var piece: Dictionary = (raw as Dictionary).duplicate(true)
		var path: String = String(piece["scene"])
		var copied: String = path.replace("res://", "res://view3d/workshop/")
		if not loaded.has(copied):
			var source: String = path.replace("res://", RegionBake.WORKSHOP)
			if not FileAccess.file_exists(source):
				push_error("no such scene of his: %s" % source)
				return []
			var expected: String = FileAccess.get_file_as_string(source)
			for folder: String in FOLDERS:
				expected = expected.replace("res://%s/" % folder, "res://view3d/workshop/%s/" % folder)
			if not FileAccess.file_exists(copied) or FileAccess.get_file_as_string(copied) != expected:
				push_error("stale workshop scene %s; run tools/vendor_workshop.sh" % source)
				return []
			loaded[copied] = load(copied) as PackedScene
		var scene: PackedScene = loaded[copied] as PackedScene
		if scene == null:
			return []
		var root: Node3D = scene.instantiate() as Node3D
		var xz: Vector2 = piece["xz"] as Vector2
		var placement := Transform3D(Basis(Vector3.UP, deg_to_rad(float(piece.get("yaw", 0.0)))),
			Vector3(xz.x, float(piece.get("lift", 0.0)), xz.y))
		var polygons: Array = []
		if not _collect(root, placement, polygons):
			root.free()
			return []
		piece["obstacles"] = polygons
		root.free()
		out.append(piece)
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
