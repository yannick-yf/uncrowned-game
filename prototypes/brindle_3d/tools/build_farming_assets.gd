extends "res://tools/build_sawmill_assets.gd"
## Offline original farming kit. Reuses construction primitives, never writes older kits.
const FARM_OUT: String="res://assets/farming/"
func build() -> void:
	for folder: String in ["meshes","materials","village","buildings","production","stockage","accessoires","modules","champs","vergers"]:DirAccess.make_dir_recursive_absolute(FARM_OUT+folder)
	architecture=load("res://tools/sawmill_architecture.gd").new(self)
	_load_materials()
	load("res://tools/farming_buildings.gd").new(self).build()
	load("res://tools/farming_props.gd").new(self).build()
	load("res://tools/farming_crops.gd").new(self).build()
	var manifest: Dictionary={"version":1,"units":"metres","front":"+Z","origin":"ground centre","style":"Original stylized rural valley kit: thatch, pale fieldstone, oak, golden wheat and fruit orchards","provenance":"Original native Godot geometry authored for the user's farming-village commission, 2026-09-21. Shared construction primitives from the user's own workshop. No third-party model or texture downloads.","usage":"Uncrowned project assets; original project content, no third-party licence claim.","optimization":"Merged by material, indexed compressed meshes; simple collisions, walk-through crops, no per-frame generation.","assets":catalog}
	var file: FileAccess=FileAccess.open(FARM_OUT+"catalog.json",FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"  "));file.close()
	print("FARMING_BUILD_OK assets=",catalog.size());quit()
func _load_materials() -> void:
	var shader: Shader=load("res://shaders/farming_surface.gdshader")
	for spec: Array in [["stone","a9a38d",1],["mortar","756f5f",1],["wood","806247",0],["dark_wood","4c3b2c",0],["plaster","c6b68e",4],["pale_plaster","ddcfaa",4],["thatch","b7974e",2],["thatch_dark","91703b",2],["roof","7d6c52",0],["rust_roof","98764e",2],["glass","4a615b",3],["dark","242a23",3],["iron","414441",3],["metal","6c716b",3],["rope","ac9360",0],["earth","6c5033",5],["soil_dry","765b3b",5],["soil_wet","4e3c29",5],["straw","c2a357",2],["linen","c1b08b",9],["water","538480",3],["bark","665038",0],["grain","d4b858",7],["leaf","597144",6],["leaf_light","829452",6],["apple","ac4936",8],["pear","c5ae53",8],["vegetable","709456",6],["clay","a36d4e",1],["endgrain","b48b53",0],["fresh_wood","a78150",0],["leather","66503a",0]]:
		var mat: ShaderMaterial=ShaderMaterial.new();mat.shader=shader
		mat.set_shader_parameter("tint",Color(spec[1]));mat.set_shader_parameter("surface_kind",spec[2]);mat.set_shader_parameter("roughness",.38 if spec[0]=="water" else .94)
		assert(ResourceSaver.save(mat,FARM_OUT+"materials/"+spec[0]+".tres")==OK);mats[spec[0]]=load(FARM_OUT+"materials/"+spec[0]+".tres")
func _start(id: String,group: String,label: String,use_text: String,place_text: String) -> void:
	super._start(id,group,label,use_text,place_text)
	item.set_meta("art_direction","farming_valley_2026_09_21")
	item.set_meta("source","Original Uncrowned farming kit")
func _surface(_group: String,mat: String) -> SurfaceTool:
	# A single batch per material replaces the older one-batch-per-detail approach.
	return super._surface("Merged",mat)
func _save() -> void:
	DirAccess.make_dir_recursive_absolute(FARM_OUT+family)
	for key: String in batches:
		var data: Dictionary=batches[key];var st: SurfaceTool=data.tool;st.generate_normals();st.index()
		var mesh: ArrayMesh=st.commit();var mesh_path: String=FARM_OUT+"meshes/"+item_id+"_"+key+".res"
		assert(ResourceSaver.save(mesh,mesh_path,ResourceSaver.FLAG_COMPRESS)==OK)
		var node: MeshInstance3D=MeshInstance3D.new();node.name=key.to_pascal_case();node.mesh=load(mesh_path);node.material_override=data.material
		item.add_child(node)
	_own(item,item)
	var bounds: AABB=_bounds(item);var triangles: int=_triangles(item)
	var path: String=FARM_OUT+family+"/"+item_id+".tscn"
	var packed: PackedScene=PackedScene.new();assert(packed.pack(item)==OK);assert(ResourceSaver.save(packed,path)==OK)
	var budget: int=15000 if item_id.contains("moulin") else 8000
	if family=="champs":budget=8000
	if family=="vergers":budget=15000 if item_id.contains("verger") or item_id.contains("bosquet") else 2500
	catalog.append({"id":item_id,"label":item_label,"family":family,"scene":path,"purpose":purpose,"placement":placement,"size_m":[bounds.size.x,bounds.size.y,bounds.size.z],"bounds_center_m":[bounds.get_center().x,bounds.get_center().y,bounds.get_center().z],"triangles":triangles,"triangle_budget":budget,"mesh_budget":16,"mesh_instances":item.find_children("*","MeshInstance3D",true,false).size(),"collision_shapes":item.find_children("*","CollisionShape3D",true,false).size(),"ground_pivot":true})
	print("FARM_ASSET ",item_id," triangles=",triangles);item.free()
func _roof(at: Vector3,width: float,depth: float,eave: float,rise: float,_mat: String="thatch") -> void:
	var half: float=width*.5+.38;var angle: float=atan2(rise,half);var slope_length: float=Vector2(half,rise).length()
	for side: float in [-1.,1.]:
		_box("ThickThatch",Vector3(slope_length,.27,depth+.75),at+Vector3(side*half*.5,eave+rise*.5,0),"thatch",Vector3(0,0,-side*angle))
		for row: int in 4:
			var t: float=(row+.15)/4.;var p: Vector3=at+Vector3(side*half*t,eave+rise*(1-t)+.16/cos(angle),0)
			_box("TiedThatchCourses",Vector3(.075,.06,depth+.70),p,"thatch_dark",Vector3(0,0,-side*angle))
		for z: float in [-depth*.5-.34,depth*.5+.34]:_beam("Verge",at+Vector3(side*half,eave,z),at+Vector3(0,eave+rise,z),.14,"dark_wood")
	_beam("RidgeRoll",at+Vector3(0,eave+rise+.2,-depth*.5-.38),at+Vector3(0,eave+rise+.2,depth*.5+.38),.32,"thatch_dark")
func _lean_roof(at: Vector3,width: float,depth: float,eave: float,rise: float,_mat: String="thatch") -> void:
	var angle: float=atan2(rise,depth)
	_box("LeanThatch",Vector3(width+.6,.23,(depth+.5)/cos(angle)),at+Vector3(0,eave+rise*.5,0),"thatch",Vector3(angle,0,0))
	for x: float in [-width*.5-.25,width*.5+.25]:_beam("LeanVerge",at+Vector3(x,eave+rise,-depth*.5-.25),at+Vector3(x,eave,depth*.5+.25),.13,"dark_wood")
