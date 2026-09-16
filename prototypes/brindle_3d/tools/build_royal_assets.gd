extends "res://tools/build_sawmill_assets.gd"
## Original native 3D architecture for the mountain capital; no external art pack.
const ROYAL_OUT: String="res://assets/royal_city/"
var layout: Dictionary
var royal: RefCounted

func build() -> void:
	for folder: String in ["meshes","materials","buildings","fortifications","props"]:DirAccess.make_dir_recursive_absolute(ROYAL_OUT+folder)
	architecture=load("res://tools/sawmill_architecture.gd").new(self)
	royal=load("res://tools/royal_architecture.gd").new(self)
	_load_materials()
	layout=JSON.parse_string(FileAccess.get_file_as_string("res://planning/royal-city.json"))
	for spec: Dictionary in layout.buildings:
		_start(spec.asset,"buildings",spec.id,"Bâtiment de la ville royale, silhouette et façade propres.","Façade sur +Z, origine au sol.")
		royal.house(spec)
		_save()
	_start("chateau_de_montagne","fortifications","Château de montagne","Donjon, palais, tours, cour et enceinte haute.","Terrasse de la montagne à 94 m.")
	royal.castle();_save()
	_start("porte_royale","fortifications","Porte royale","Porte charretière à deux tours, herse levée.","Passage de 7 m sur l'avenue principale.")
	royal.gate(7.0,14.0,3.4);_save()
	_start("porte_haute","fortifications","Porte de la montée","Porte haute ouverte vers le château.","Passage de 6 m.")
	royal.gate(6.0,10.0,2.4);_save()
	_start("pont_royal_18m","fortifications","Pont des douves","Pont de pierre à deux arches et tablier de 5,8 m.","Origine au centre du tablier, axe Z.")
	royal.bridge();_save()
	DirAccess.make_dir_recursive_absolute("res://assets/bridges/pierre")
	assert(ResourceSaver.save(load(ROYAL_OUT+"fortifications/pont_royal_18m.tscn"),"res://assets/bridges/pierre/pont_royal_18m.tscn")==OK)
	_start("fontaine_de_la_place","props","Fontaine de la place","Bassin de pierre et colonne centrale.","Eau décorative, hors circulation.")
	royal.fountain();_save()
	for i: int in 4:
		_start("etal_marche_"+str(i),"props","Étal du marché "+str(i+1),"Étal vide de personnages, marchandises et auvent.","À placer sur le bord de la place.")
		royal.stall(i);_save()
	var f: FileAccess=FileAccess.open(ROYAL_OUT+"catalog.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"version":1,"units":"metres","provenance":"Original procedural geometry made for this workshop from the user's castle reference. Shared construction helpers, no downloaded pack.","assets":catalog},"  "));f.close()
	print("ROYAL_ASSETS_OK assets=",catalog.size());quit()

func _load_materials() -> void:
	var shader: Shader=load("res://shaders/royal_surface.gdshader")
	for spec: Array in [["stone","b7ad96",1],["mortar","858070",1],["rock","787968",1],["plaster","c1ac86",4],["pale_plaster","dbc9a4",4],["wood","745842",0],["dark_wood","3e3025",0],["roof","535861",2],["rust_roof","927354",2],["dark","172022",3],["glass","354c52",3],["iron","343a3b",3],["metal","8c866e",3],["rope","8c775a",0],["linen","b8aa86",4],["banner","792c34",4],["gold","c2a069",3],["water","40696b",3],["earth","665b46",1],["straw","a28a5b",0]]:
		var material: ShaderMaterial=ShaderMaterial.new();material.shader=shader
		material.set_shader_parameter("tint",Color(spec[1]));material.set_shader_parameter("surface_kind",spec[2])
		assert(ResourceSaver.save(material,ROYAL_OUT+"materials/"+spec[0]+".tres")==OK)
		mats[spec[0]]=load(ROYAL_OUT+"materials/"+spec[0]+".tres")

func _start(id: String,group: String,label: String,use_text: String,place_text: String) -> void:
	super._start(id,group,label,use_text,place_text)
	item.set_meta("art_direction","mountain_capital_reference_2026_09_16")

func _save() -> void:
	for key: String in batches:
		var data: Dictionary=batches[key];var st: SurfaceTool=data.tool;st.generate_normals()
		var mesh: ArrayMesh=st.commit();var path: String=ROYAL_OUT+"meshes/"+item_id+"_"+key+".res"
		assert(ResourceSaver.save(mesh,path,ResourceSaver.FLAG_COMPRESS)==OK)
		var node: MeshInstance3D=MeshInstance3D.new();node.name=key.to_pascal_case();node.mesh=load(path);node.material_override=data.material;item.add_child(node)
	_own(item,item)
	var bounds: AABB=_bounds(item);var scene_path: String=ROYAL_OUT+family+"/"+item_id+".tscn"
	var scene: PackedScene=PackedScene.new();assert(scene.pack(item)==OK);assert(ResourceSaver.save(scene,scene_path)==OK)
	catalog.append({"id":item_id,"label":item_label,"scene":scene_path,"size_m":[bounds.size.x,bounds.size.y,bounds.size.z],"bounds_center_m":[bounds.get_center().x,bounds.get_center().y,bounds.get_center().z],"triangles":_triangles(item),"collision_shapes":item.find_children("*","CollisionShape3D",true,false).size()})
	print("ROYAL_ASSET ",item_id);item.free()

func _roof(at: Vector3,width: float,depth: float,eave: float,rise: float,mat: String="roof") -> void:
	# Large roofs use a tiled shader plus modeled ridges/courses, not thousands of tiny boxes.
	var half: float=width*.5+.28;var length: float=depth+.58;var angle: float=atan2(rise,half)
	for side: float in [-1.0,1.0]:
		_box("RoofDeck",Vector3(Vector2(half,rise).length(),.18,length),at+Vector3(side*half*.5,eave+rise*.5,0),mat,Vector3(0,0,-side*angle))
		for z: float in [-length*.5,length*.5]:_beam("RoofVerge",at+Vector3(side*half,eave,z),at+Vector3(0,eave+rise,z),.12,"dark_wood")
	_beam("RidgeCap",at+Vector3(0,eave+rise+.11,-length*.5),at+Vector3(0,eave+rise+.11,length*.5),.22,mat)
