@tool
extends Node3D
## Keep each saved, editable sector seated on Godot's terrain after a relief edit.
@export_tool_button("Reposer sur le terrain") var align_sector: Callable = conform_to_terrain
var _ground: Node3D
func _ready() -> void:
	call_deferred("_connect_ground")
func _connect_ground() -> void:
	_ground = get_tree().get_first_node_in_group("world_terrain") as Node3D
	if _ground != null:
		if not _ground.is_connected("rebuilt",conform_to_terrain): _ground.connect("rebuilt",conform_to_terrain)
		if int(_ground.get("chunk_count"))>0: conform_to_terrain()
func conform_to_terrain() -> void:
	if _ground == null: return
	_conform_node(self)
func _conform_node(node: Node) -> void:
	if node is Node3D and node.has_meta("ground_offset"):
		var at: Vector3 = node.global_position
		at.y = _ground.call("height_at_world",at.x,at.z) + float(node.get_meta("ground_offset"))
		node.global_position = at
	if node is MultiMeshInstance3D and node.has_meta("ground_batch"):
		# A local copy avoids changing the shared scene resource in another open view.
		if not node.has_meta("private_buffer"):
			node.multimesh = node.multimesh.duplicate()
			node.set_meta("private_buffer",true)
		for i: int in node.multimesh.instance_count:
			var placement: Transform3D = node.multimesh.get_instance_transform(i)
			var at: Vector3 = node.global_transform * placement.origin
			at.y = _ground.call("height_at_world",at.x,at.z) - .03
			placement.origin = node.global_transform.affine_inverse() * at
			node.multimesh.set_instance_transform(i,placement)
	for child: Node in node.get_children(): _conform_node(child)
