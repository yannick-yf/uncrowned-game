extends SceneTree
## Manual initial assembly. Saved sectors remain editable; this never runs in gameplay.
const LIB := "res://prototype_3d/assets/library/"
const TREE_ASSETS: Array[String] = ["fir_mature","spruce_slender","pine_coastal","birch_twin"]
const PLANTS: Array[String] = ["fern_fan","grass_meadow","shrub_hazel","flowers_daisy"]
var world: Node3D
var ground: Node3D
var rng := RandomNumberGenerator.new()
var trees: Array[Dictionary] = []
var buildings: Array[Dictionary] = []
var routes: Array[Dictionary] = []
var report: Dictionary = {}
var cache: Dictionary = {}

func _initialize() -> void: call_deferred("build")
func build() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Use a graphics renderer to save native MultiMesh buffers.")
		quit(1); return
	rng.seed=9132026
	var original_water:ShaderMaterial=load("res://prototype_3d/materials/styled_water.tres")
	var adapted_water:ShaderMaterial=load("res://materials/brindle_water.tres")
	for parameter:String in ["deep_color","shallow_color","foam_color","wave_height","wave_speed"]:
		adapted_water.set_shader_parameter(parameter,original_water.get_shader_parameter(parameter))
	ResourceSaver.save(adapted_water,"res://materials/brindle_water.tres")
	world=(load("res://scenes/map_plate.tscn") as PackedScene).instantiate()
	root.add_child(world)
	ground=world.get_node("Terrain")
	for i: int in 6: await process_frame
	DirAccess.make_dir_recursive_absolute("res://scenes/sectors")
	_prepare_routes()
	var village:=Node3D.new(); village.name="Brindle"; world.add_child(village)
	village.set_script(load("res://scripts/sector_tools.gd"))
	_build_village(village)
	var forest:=Node3D.new(); forest.name="ForetsBrindle"; world.add_child(forest)
	forest.set_script(load("res://scripts/sector_tools.gd"))
	_build_forest(forest,true)
	var northern:=Node3D.new(); northern.name="ForetsNordEst"; world.add_child(northern)
	northern.set_script(load("res://scripts/sector_tools.gd"))
	_build_forest(northern,false)
	var mine:=Node3D.new(); mine.name="MineAcierie"; world.add_child(mine)
	_build_mine(mine)
	for i: int in 40: await process_frame
	_save_sector(village,"brindle.tscn")
	_save_sector(forest,"forets_brindle.tscn")
	_save_sector(northern,"forets_nord_est.tscn")
	_save_sector(mine,"mine_acierie.tscn")
	report["tree_count"]=trees.size(); report["buildings"]=buildings; report["routes"]=routes
	report["mine_entrance_xyz"]=[308.5,46,80]
	report["bridge_endpoints_xzy"]=[[252,62,44],[286,62,44]]
	var file:=FileAccess.open("res://planning/brindle-sectors-v1.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	var placements:=FileAccess.open("res://planning/forest-placements-v1.json",FileAccess.WRITE)
	placements.store_string(JSON.stringify(trees)); placements.close()
	print("BRINDLE_BUILD_OK ",JSON.stringify({"trees":trees.size(),"buildings":buildings.size(),"brindle":report.get("Brindle_trees"),"nord":report.get("NordEst_trees")}))
	quit()

func height_at(p: Vector2) -> float: return ground.call("height_at_world",p.x,p.y)
func water_at(p: Vector2) -> float: return ground.call("water_at_world",p.x,p.y)
func _node(name:String,parent:Node)->Node3D:
	var n:=Node3D.new(); n.name=name; parent.add_child(n); return n
func _asset(path: String)->PackedScene:
	if not cache.has(path): cache[path]=load(LIB+path+".tscn")
	return cache[path] as PackedScene
func _place(parent:Node,asset:String,name:String,p:Vector2,yaw:float=0,scale_factor:float=1)->Node3D:
	var obj:Node3D=_asset(asset).instantiate()
	obj.name=name; parent.add_child(obj)
	obj.position=Vector3(p.x,height_at(p)-.03,p.y)
	obj.rotation.y=deg_to_rad(yaw); obj.scale=Vector3.ONE*scale_factor
	obj.set_meta("ground_offset",-.03)
	return obj
func _path(parent:Node,name:String,pts:Array,width:float)->void:
	var path:=MeshInstance3D.new(); path.name=name
	path.set_script(load("res://scripts/ground_path.gd"))
	var pp:=PackedVector2Array()
	for p: Array in pts: pp.append(Vector2(p[0],p[1]))
	path.set("points",pp); path.set("width_m",width)
	path.material_override=load("res://materials/brindle_path.tres")
	parent.add_child(path)
func _prepare_routes()->void:
	routes=[
		{"id":"entree_nord","points":[[175,172],[175,194],[175,216],[175,225],[175,243],[172,253],[175,267],[173,289]],"width":4.6},
		{"id":"lisiere_ouest","points":[[175,244],[153,242],[137,235],[124,229],[113,239],[115,262],[135,278],[157,281],[173,277]],"width":3.2},
		{"id":"lisiere_est","points":[[184,252],[208,251],[222,240],[238,224],[239,207]],"width":3.0}
	]

func _build_village(parent:Node3D)->void:
	var houses:=_node("Maisons",parent)
	var layout:Array=[
		["MaisonOuest","houses/cottage_village",150,252,90],
		["MaisonNord","houses/cottage_village",184,232,0],
		["MaisonEst","houses/cottage_village",196,243,-60],
		["MaisonSudOuest","houses/cottage_fisher",153,269,115],
		["MaisonSudEst","houses/cottage_fisher",196,272,-135],
		["Grange","houses/storehouse",185,283,180]
	]
	for data: Array in layout:
		var at:=Vector2(data[2],data[3])
		_place(houses,data[1],data[0],at,data[4])
		buildings.append({"id":data[0],"asset":data[1],"center_xz":[at.x,at.y],"yaw":data[4]})
		var facing:=Vector2(sin(deg_to_rad(float(data[4]))),cos(deg_to_rad(float(data[4]))))
		var door:Vector2=at+facing*3.2
		var junction:Vector2=Vector2(175,255)+(door-Vector2(175,255)).normalized()*5.0
		routes.append({"id":"acces_"+str(data[0]),"points":[[junction.x,junction.y],[door.x,door.y]],"width":2.5})
	var paths:=_node("CheminsEtPlace",parent)
	for route: Dictionary in routes: _path(paths,route.id,route.points,float(route.width))
	_path(paths,"Place",[[168,255],[182,255]],17)
	var props:=_node("Details",parent)
	_place(props,"props/well","Puits",Vector2(170,252))
	_place(props,"props/bench","Banc",Vector2(182,258),-90)
	_place(props,"props/woodpile","BuchesGrange",Vector2(191,285),90)
	_place(props,"props/barrel_closed","Tonneau",Vector2(149,269))
	_place(props,"props/crate_single","Caisse",Vector2(189,287),15)
	for n: int in 5:
		_place(props,"modules/fence_2m","CloturePotager_%d"%n,Vector2(143+n*2,246))
	for n: int in 4:
		_place(props,"modules/fence_2m","ClotureGrange_%d"%n,Vector2(180+n*2,289))
	var accents:=_node("ArbresDeLisiere",parent)
	_place(accents,"trees/birch_twin","BouleauPlace",Vector2(185,246),25,1.1)
	_place(accents,"trees/pine_coastal","PinEntreeSud",Vector2(203,285),-30,1.1)
	_place(accents,"plants/shrub_hazel","HaieOuest",Vector2(147,248),35)
	_place(accents,"plants/shrub_hazel","HaieEst",Vector2(201,242),-15)

func _segment_distance(p:Vector2,a:Vector2,b:Vector2)->float:
	var ab:Vector2=b-a
	return p.distance_to(a+ab*clampf((p-a).dot(ab)/maxf(ab.length_squared(),.0001),0,1))
func _near_path(p:Vector2,padding:float)->bool:
	for route:Dictionary in routes:
		for i:int in range(route.points.size()-1):
			var a:Array=route.points[i];var b:Array=route.points[i+1]
			if _segment_distance(p,Vector2(a[0],a[1]),Vector2(b[0],b[1]))<float(route.width)*.5+padding: return true
	return false
func _is_dry_gentle(p:Vector2)->bool:
	var h:float=height_at(p)
	if h<6 or h>115 or h<water_at(p)+2: return false
	for d:Vector2 in [Vector2(5,0),Vector2(-5,0),Vector2(0,5),Vector2(0,-5)]:
		if height_at(p+d)<water_at(p+d)+1.6: return false
	var slope:Vector2=Vector2(height_at(p+Vector2(2,0))-height_at(p-Vector2(2,0)),height_at(p+Vector2(0,2))-height_at(p-Vector2(0,2)))/4
	return slope.length()<.60
func _ellipse(p:Vector2,c:Vector2,r:Vector2)->float: return ((p-c)/r).length()
func _forest_weight(p:Vector2,brindle:bool)->float:
	var dist:float
	if brindle:
		dist=minf(_ellipse(p,Vector2(167,194),Vector2(104,36)),minf(_ellipse(p,Vector2(93,253),Vector2(49,70)),_ellipse(p,Vector2(254,263),Vector2(53,64))))
		if absf(p.x-175)<42 and absf(p.y-255)<36: return 0
	else:
		dist=minf(_ellipse(p,Vector2(229,-236),Vector2(99,61)),_ellipse(p,Vector2(15,-251),Vector2(103,37)))
		if absf(p.x-235)<57 and absf(p.y+125)<57: return 0
		if absf(p.x+150)<114 and absf(p.y+180)<100: return 0
	var ripple:float=sin(p.x*.065+p.y*.031)*.065+cos(p.y*.087-p.x*.022)*.065
	return 1.0-smoothstep(.70,1.0,dist+ripple)
func _build_forest(parent:Node3D,brindle:bool)->void:
	var batches:Dictionary={}
	var collisions:Dictionary={}
	var count:int=0
	var min_z:float=151 if brindle else -303
	var max_z:float=332 if brindle else -158
	var start_x:float=38 if brindle else -104
	var spacing:float=5.1 if brindle else 5.8
	var z:float=min_z
	while z<max_z:
		var x:float=start_x
		while x<310:
			var p:=Vector2(x+rng.randf_range(-1.65,1.65),z+rng.randf_range(-1.65,1.65))
			x+=spacing
			if rng.randf()>_forest_weight(p,brindle)*.94 or not _is_dry_gentle(p) or _near_path(p,3.2): continue
			var roll:float=rng.randf()
			var type:int=0 if roll<.53 else (1 if roll<.8 else (2 if roll<.91 else 3))
			if brindle and p.y>285 and roll>.45: type=2
			var s:float=rng.randf_range(.90,1.25)
			var basis:=Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*s)
			var at:=Vector3(p.x,height_at(p)-.03,p.y)
			var key:String="%d_%d_%d"%[floori(p.x/64),floori(p.y/64),type]
			if not batches.has(key): batches[key]={"asset":"trees/"+TREE_ASSETS[type],"placements":[],"trees":true}
			batches[key].placements.append(Transform3D(basis,at))
			var cell:String="Cell_%d_%d"%[floori(p.x/64),floori(p.y/64)]
			if not collisions.has(cell):
				var body:=StaticBody3D.new();body.name=cell;body.collision_mask=0;parent.add_child(body);collisions[cell]=body
			var shape:=CollisionShape3D.new();shape.name="Tronc_%d"%count
			var cylinder:=CylinderShape3D.new();cylinder.radius=.3*s;cylinder.height=3*s
			shape.shape=cylinder;shape.position=at+Vector3(0,1.5*s,0);shape.set_meta("ground_offset",1.5*s-.03)
			collisions[cell].add_child(shape)
			trees.append({"sector":"Brindle" if brindle else "NordEst","asset":TREE_ASSETS[type],"xz":[snappedf(p.x,.001),snappedf(p.y,.001)],"scale":s})
			count+=1
			if brindle:
				for plant_index:int in rng.randi_range(2,5):
					var pp:Vector2=p+Vector2(rng.randf_range(-3.2,3.2),rng.randf_range(-3.2,3.2))
					if not _is_dry_gentle(pp) or _near_path(pp,1.0): continue
					var species:int=0 if rng.randf()<.52 else (1 if rng.randf()<.75 else 2)
					var plant_key:String="plant_%d_%d_%d"%[floori(pp.x/32),floori(pp.y/32),species]
					if not batches.has(plant_key): batches[plant_key]={"asset":"plants/"+PLANTS[species],"placements":[],"trees":false}
					var plant_s:float=rng.randf_range(.8,1.25)
					batches[plant_key].placements.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*plant_s),Vector3(pp.x,height_at(pp)-.03,pp.y)))
		z+=spacing
	for key:String in batches:
		_batch_asset(parent,key,batches[key].asset,batches[key].placements)
	if brindle:
		var detail:=_node("BoisMortEtRochers",parent)
		_place(detail,"props/fallen_log","TroncLisiere",Vector2(124,263),25)
		_place(detail,"props/stump","SoucheSentier",Vector2(138,230),40)
		_place(detail,"rocks/boulder_round","RocheMoussue",Vector2(231,232),15,1.2)
		_place(detail,"rocks/boulder_cluster","RochersCotiers",Vector2(268,303),70,1.3)
		var flowers:Array=[]
		for i:int in 95:
			var p:=Vector2(rng.randf_range(143,207),rng.randf_range(221,288))
			if _near_path(p,.5): continue
			var clear:bool=true
			for house:Dictionary in buildings:
				if p.distance_to(Vector2(house.center_xz[0],house.center_xz[1]))<5.2:clear=false
			if not clear: continue
			flowers.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU),Vector3(p.x,height_at(p),p.y)))
		_batch_asset(parent,"FleursClairiere","plants/flowers_daisy",flowers)
	report[("Brindle" if brindle else "NordEst")+"_trees"]=count
	report[("Brindle" if brindle else "NordEst")+"_batches"]=batches.size()
	print(parent.name," trees=",count," batches=",batches.size())

func _batch_asset(parent:Node3D,name:String,asset:String,placements:Array)->void:
	if placements.is_empty(): return
	var model:Node3D=_asset(asset).instantiate()
	var pieces:Array[MeshInstance3D]=[]
	_collect_meshes(model,pieces)
	var group:=_node(name,parent)
	for part_index:int in pieces.size():
		var part:MeshInstance3D=pieces[part_index]
		var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=part.mesh
		multi.instance_count=placements.size()
		for i:int in placements.size(): multi.set_instance_transform(i,placements[i])
		var node:=MultiMeshInstance3D.new();node.name="Mesh_%d"%part_index;node.multimesh=multi
		node.material_override=part.material_override;node.cast_shadow=part.cast_shadow
		node.set_meta("ground_batch",true)
		group.add_child(node)
	model.free()
func _collect_meshes(node:Node,result:Array[MeshInstance3D])->void:
	if node is MeshInstance3D: result.append(node)
	for child:Node in node.get_children():_collect_meshes(child,result)

func _box(parent:Node,name:String,at:Vector3,size:Vector3,material:Material,collides:bool=true)->CSGBox3D:
	var box:=CSGBox3D.new();box.name=name;box.position=at;box.size=size;box.material=material;box.use_collision=collides
	parent.add_child(box);return box
func _build_mine(parent:Node3D)->void:
	var stone:Material=load("res://prototype_3d/materials/styled_rock.tres")
	var wood:Material=load("res://prototype_3d/materials/styled_wood.tres")
	var iron:Material=load("res://prototype_3d/materials/styled_iron.tres")
	var dark:Material=load("res://prototype_3d/materials/styled_dark.tres")
	var dig:=CSGCombiner3D.new();dig.name="ExcavationCSG";dig.use_collision=true;parent.add_child(dig)
	var hillside:=CSGMesh3D.new();hillside.name="MorceauDeMontagne"
	var hillside_material:ShaderMaterial=(load("res://materials/brindle_landscape.tres") as ShaderMaterial).duplicate()
	hillside_material.set_shader_parameter("procedural_blend",true)
	hillside.material=hillside_material
	hillside.set_script(load("res://scripts/mine_excavation.gd"));dig.add_child(hillside)
	var bore:=_box(dig,"GalerieCreusee",Vector3(314.5,48.5,80),Vector3(21,5.2,5.8),stone,false)
	bore.operation=CSGShape3D.OPERATION_SUBTRACTION
	_box(parent,"PlancherGalerie",Vector3(314.5,45.92,80),Vector3(21,.16,5.8),stone)
	_box(parent,"FondSombre",Vector3(324.2,48.5,80),Vector3(.15,5.0,5.6),dark)
	for x:float in [309.0,313.0,317.0,321.0]:
		_box(parent,"EtaiNord_%d"%int(x),Vector3(x,48.4,77.35),Vector3(.42,4.8,.42),wood)
		_box(parent,"EtaiSud_%d"%int(x),Vector3(x,48.4,82.65),Vector3(.42,4.8,.42),wood)
		_box(parent,"Traverse_%d"%int(x),Vector3(x,50.8,80),Vector3(.55,.52,5.95),wood)
	# Two simple rails visually connect the gallery to the sorting yard.
	for z:float in [79.3,80.7]: _box(parent,"Rail_%d"%int(z*10),Vector3(312,46.08,z),Vector3(21,.10,.12),iron,false)
	for i:int in 16: _box(parent,"TraverseSol_%02d"%i,Vector3(302+i*1.3,46.04,80),Vector3(.22,.10,2.0),wood,false)
	var ramp:=_node("AccesEtPont",parent)
	_path(ramp,"CheminAciérie",[[243,60],[251,62]],5.5)
	_path(ramp,"CheminMine",[[286,62],[294,62],[298,70],[300,80],[306,80]],5.5)
	# The crossing spans the tributary diagonally and lands on dry banks.
	_box(ramp,"TablierPont",Vector3(269,43.83,62),Vector3(34,.34,4.8),wood)
	for side:float in [-1.0,1.0]:
		_box(ramp,"GardeCorps_%d"%int(side),Vector3(269,45,62+side*2.25),Vector3(34,.16,.16),wood)
		for i:int in 9:
			_box(ramp,"Poteau_%d_%d"%[int(side),i],Vector3(253+i*4,44.4,62+side*2.25),Vector3(.18,1.5,.18),wood)
	for x:float in [252.0,285.0]:
		var footing:float=height_at(Vector2(x,62))
		_box(ramp,"Culee_%d"%int(x),Vector3(x,(footing+43.7)*.5,62),Vector3(2.5,maxf(.5,43.7-footing),5.4),stone)
	# Sloped landing meshes meet the ground; their upper edge reaches the deck.
	_make_ramp(ramp,"RampeOuest",Vector3(242,height_at(Vector2(242,62)),62),Vector3(252,44,62),4.8,wood)
	_make_ramp(ramp,"RampeEst",Vector3(286,44,62),Vector3(294,height_at(Vector2(294,62)),62),4.8,wood)
	var props:=_node("CourDeTri",parent)
	props.set_script(load("res://scripts/sector_tools.gd"))
	_place(props,"props/crate_single","CaisseOutils",Vector2(302,73),15)
	_place(props,"props/woodpile","BoisEtayage",Vector2(304,87),90,1.3)
	_place(props,"rocks/boulder_cluster","MineraiExtrait",Vector2(298,86),30,1.2)
	_place(props,"props/barrel_closed","TonneauCour",Vector2(300,73),-15)
	var label:=Label3D.new();label.name="RepereMine";label.text="Mine · accès depuis l’aciérie";label.position=Vector3(305,59,80)
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.font_size=40;label.pixel_size=.15;label.no_depth_test=true
	parent.add_child(label)

func _make_ramp(parent:Node,name:String,a:Vector3,b:Vector3,width:float,mat:Material)->void:
	var mesh:=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side:=Vector3(0,0,width*.5)
	for p:Vector3 in [a-side,b-side,a+side,b-side,b+side,a+side]:mesh.add_vertex(p)
	mesh.generate_normals()
	var node:=MeshInstance3D.new();node.name=name;node.mesh=mesh.commit();node.material_override=mat;parent.add_child(node)
	var body:=StaticBody3D.new();body.collision_mask=0;node.add_child(body)
	var shape:=CollisionShape3D.new();shape.shape=node.mesh.create_trimesh_shape();body.add_child(shape)

func _own(node:Node,sector:Node)->void:
	for child:Node in node.get_children():
		child.owner=sector
		if child.scene_file_path.is_empty(): _own(child,sector)
func _save_sector(sector:Node,filename:String)->void:
	_own(sector,sector)
	var scene:=PackedScene.new()
	assert(scene.pack(sector)==OK)
	assert(ResourceSaver.save(scene,"res://scenes/sectors/"+filename)==OK)
