extends RefCounted
## Sparse edits share the terrain's vertices and collision triangles: no overlay seams.
static func apply(height: PackedFloat32Array, n: int) -> void:
	var records: PackedFloat32Array = FileAccess.get_file_as_bytes("res://assets/coastline/terrain_edits.f32").to_float32_array()
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://planning/coastline.json"))
	assert(n == int(plan.source_grid_size) and records.size()%3 == 0, "Coastal overlay must match the regional grid")
	for i: int in range(0, records.size(), 3):
		var index: int = int(records[i])
		height[index] = lerpf(height[index], records[i+1], records[i+2])
