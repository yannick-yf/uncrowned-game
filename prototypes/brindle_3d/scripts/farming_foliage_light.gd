extends RefCounted
## Local, shared foliage shading for the farming village. No asset files are
## mutated and no mesh, MultiMesh, transform, collision or node is added/changed.
## Usage: preload("res://scripts/farming_foliage_light.gd").new().apply(village)
const FOLIAGE_SHADER: Shader = preload("res://shaders/farming_foliage.gdshader")
const PLAN: String = "res://planning/farming-town.json"
const FARM_LEAF: String = "res://assets/farming/materials/leaf.tres"
const FARM_LIGHT_LEAF: String = "res://assets/farming/materials/leaf_light.tres"
const LIBRARY_LIGHT_LEAF: String = "res://prototype_3d/materials/styled_leaves_light.tres"
const ALLOWED_SOURCES: Array[String] = [FARM_LEAF, FARM_LIGHT_LEAF, LIBRARY_LIGHT_LEAF]
var _materials: Dictionary = {}

func apply(root: Node3D) -> Dictionary:
	var result: Dictionary = {"matched_nodes": 0, "changed_nodes": 0, "material_count": 0,
		"sources": [], "scope": "VillageFermier/Vergers + VillageFermier/Verdure"}
	var village: Node3D = _find_village(root)
	if village == null:
		push_warning("Farming foliage: VillageFermier was not found; no material was changed")
		return result
	var used_sources: Dictionary = {}
	for group_name: String in ["Vergers", "Verdure"]:
		var group: Node = village.get_node_or_null(NodePath(group_name))
		if group == null:
			continue
		for node: Node in group.find_children("*", "GeometryInstance3D", true, false):
			if not (node is MeshInstance3D or node is MultiMeshInstance3D):
				continue
			var geometry: GeometryInstance3D = node as GeometryInstance3D
			var original: ShaderMaterial = geometry.material_override as ShaderMaterial
			if original == null:
				continue
			var source: String = _source_path(original)
			if source not in ALLOWED_SOURCES:
				continue
			result.matched_nodes += 1
			used_sources[source] = true
			if original.shader == FOLIAGE_SHADER:
				# Reapplying, including with a new helper, creates no extra clones.
				_materials[source] = original
				continue
			if not _materials.has(source):
				_materials[source] = _make_local_material(original, source)
			geometry.material_override = _materials[source]
			result.changed_nodes += 1
	result.material_count = used_sources.size()
	result.sources = used_sources.keys()
	return result

func _find_village(root: Node3D) -> Node3D:
	if root == null:
		return null
	if str(root.get_meta("layout_source", "")) == PLAN or str(root.name) == "VillageFermier":
		return root
	for path: String in ["Decor/VillageFermier", "World/Decor/VillageFermier"]:
		var candidate: Node3D = root.get_node_or_null(NodePath(path)) as Node3D
		if candidate != null:
			return candidate
	return null

func _source_path(material: ShaderMaterial) -> String:
	if material.shader == FOLIAGE_SHADER:
		return str(material.get_meta("farming_foliage_source", ""))
	return material.resource_path

func _make_local_material(original: ShaderMaterial, source: String) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.resource_name = "FarmLocal_" + source.get_file().get_basename()
	material.shader = FOLIAGE_SHADER
	material.render_priority = original.render_priority
	material.set_meta("farming_foliage_source", source)
	material.set_meta("scope", "living leaves inside VillageFermier only")
	var tinted: Variant = original.get_shader_parameter("tint")
	if tinted is Color:
		material.set_shader_parameter("tint", tinted)
	var painted: bool = source == LIBRARY_LIGHT_LEAF
	material.set_shader_parameter("style_family", 1 if painted else 0)
	material.set_shader_parameter("wind_strength", .012 if painted else .009)
	material.set_shader_parameter("transmission_strength", .12)
	material.set_shader_parameter("scattering_strength", .035)
	material.set_shader_parameter("transmission_depth", .22)
	material.set_shader_parameter("backlight_strength", .08)
	if painted:
		for parameter: String in ["texture_strength", "facet_softness", "vertex_srgb"]:
			var value: Variant = original.get_shader_parameter(parameter)
			if value != null:
				material.set_shader_parameter(parameter, value)
	else:
		var roughness: Variant = original.get_shader_parameter("roughness")
		if roughness != null:
			material.set_shader_parameter("roughness", roughness)
	return material
