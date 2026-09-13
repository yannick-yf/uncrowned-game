extends RefCounted
## Shared finishing pass, also used by the ruin builder after a reconstruction.
const DIR := "res://assets/brindle_ruins/burned_materials/"
const SMOKING_HOUSES := ["MaisonDuChemin", "MaisonBasse"]
var cache: Dictionary = {}

func burned_material(source: Material, ground_only: bool = false) -> Material:
	if not source is ShaderMaterial: return source
	if source.resource_path.begins_with(DIR): return source
	var key: String = source.resource_path + ("_ground" if ground_only else "")
	if cache.has(key): return cache[key]
	DirAccess.make_dir_recursive_absolute(DIR)
	var source_shader := source as ShaderMaterial
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/burned_surface.gdshader")
	for uniform: Dictionary in source_shader.shader.get_shader_uniform_list():
		material.set_shader_parameter(uniform.name, source_shader.get_shader_parameter(uniform.name))
	var amount: float = .82
	var basename: String = source.resource_path.get_file().get_basename()
	if "wood" in basename: amount = .99
	elif "roof" in basename: amount = .99
	elif "plaster" in basename: amount = .87
	elif "cassure" in basename: amount = .67
	material.set_shader_parameter("burn_amount", amount)
	material.set_shader_parameter("moss_amount", 0.0)
	material.set_shader_parameter("ground_charring",ground_only)
	if ground_only:
		material.set_shader_parameter("scorch_mask",load("res://assets/landscape/brindle_scorch_mask.png"))
	var path: String = DIR + basename + ("_ground" if ground_only else "") + ".tres"
	assert(ResourceSaver.save(material,path)==OK)
	cache[key] = load(path)
	return cache[key]

func apply(house: Node3D, building_name: String) -> void:
	for node: MeshInstance3D in house.find_children("*","MeshInstance3D",true,false):
		if node.material_override != null:
			node.material_override = burned_material(node.material_override)
		elif node.mesh != null:
			for surface: int in node.mesh.get_surface_count():
				var material: Material = node.get_active_material(surface)
				if material != null: node.set_surface_override_material(surface,burned_material(material))
	house.set_meta("state","Ruine récemment incendiée ; bois carbonisé et suie")
	if building_name in SMOKING_HOUSES and house.get_node_or_null("FumeeResiduelle") == null:
		var smoke: Node3D = (load("res://scenes/effects/fumee_ruine.tscn") as PackedScene).instantiate()
		smoke.name = "FumeeResiduelle"
		smoke.position = Vector3(.3,.72,-.4) if building_name=="MaisonDuChemin" else Vector3(-.55,.65,-.35)
		house.add_child(smoke)
