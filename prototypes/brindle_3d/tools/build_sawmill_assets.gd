extends SceneTree
## Offline native Godot kit for the sawmill village, inspired by the user's image.
const OUT: String="res://assets/sawmill/"
var rng: RandomNumberGenerator=RandomNumberGenerator.new()
var mats: Dictionary={}
var batches: Dictionary={}
var item: Node3D
var catalog: Array[Dictionary]=[]
var item_id: String
var family: String
var item_label: String
var purpose: String
var placement: String
var model_transform: Transform3D=Transform3D.IDENTITY
var selected_assets: Dictionary={}
var architecture: RefCounted

func _initialize() -> void:call_deferred("build")

func build() -> void:
	DirAccess.make_dir_recursive_absolute(OUT+"materials")
	DirAccess.make_dir_recursive_absolute(OUT+"meshes")
	architecture=load("res://tools/sawmill_architecture.gd").new(self)
	_load_materials()
	load("res://tools/sawmill_designs.gd").new(self).build()
	for id: String in ["logis_porte_basse","maison_aux_deux_volumes","baraquement_des_equipes","logis_a_colombages","baraquement_a_galerie","logis_du_contremaitre_en_l","maison_des_charretiers","maison_au_toit_decale"]:selected_assets[id]=true
	load("res://tools/sawmill_housing.gd").new().build_housing(self)
	selected_assets.clear()
	var f: FileAccess=FileAccess.open(OUT+"catalog.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"version":1,"units":"meters","front":"+Z","origin":"ground center","style":"Sawmill village: dark oak, warm lime, limestone bases, steep slate and ochre roofs","reference":"User-provided village image, September 16 2026; inspiration only","assets":catalog},"  "))
	f.close()
	_build_gallery()
	print("SAWMILL_BUILD_OK assets=",catalog.size())
	quit()

func _load_materials() -> void:
	var shader: Shader=load("res://shaders/sawmill_surface.gdshader")
	for spec: Array in [["wood","756048",0],["dark_wood","382d24",0],["rock","857e70",1],
		["stone","a29985",1],["plaster","b8a27d",4],["pale_plaster","d3c097",4],["glass","53605b",3],
		["roof","53595f",2],["rust_roof","9e7852",2],["dark","111518",1],
		["iron","242b2e",3],["metal","5c686c",3],["rope","8c775a",0],
		["clay","92725a",1],["soot","252729",1],["mortar","696456",1],
		["ore","775440",1],["charcoal","23282b",1],["slag","43474c",1],
		["straw","97855e",0],["leather","443932",0],["linen","a99b7b",1],["earth","605346",1],["bark","554435",0],["endgrain","b28e57",0],["fresh_wood","b59762",0]]:
		var mat: ShaderMaterial=ShaderMaterial.new();mat.shader=shader
		mat.set_shader_parameter("tint",Color(spec[1]));mat.set_shader_parameter("surface_kind",spec[2])
		mat.set_shader_parameter("roughness",.67 if spec[2]==3 else .94)
		mat.set_shader_parameter("metalness",.65 if spec[2]==3 else 0.0)
		mat.set_shader_parameter("variation",.22 if spec[2]==0 else .14)
		assert(ResourceSaver.save(mat,OUT+"materials/"+spec[0]+".tres")==OK)
		mats[spec[0]]=load(OUT+"materials/"+spec[0]+".tres")
	var water: StandardMaterial3D=StandardMaterial3D.new()
	water.albedo_color=Color("435f63");water.roughness=.3
	assert(ResourceSaver.save(water,OUT+"materials/water.tres")==OK)
	mats["water"]=load(OUT+"materials/water.tres")

func _start(id: String, group: String, label: String, use_text: String, place_text: String) -> void:
	item_id=id;family=group;item_label=label;purpose=use_text;placement=place_text
	rng.seed=abs(id.hash())+14092026;batches={};model_transform=Transform3D.IDENTITY
	item=Node3D.new();item.name=id.to_pascal_case();root.add_child(item)
	item.set_meta("art_direction","reference_village_2026_09_16")
	item.set_meta("asset_id",id);item.set_meta("family",group);item.set_meta("label",label)
	item.set_meta("purpose",use_text);item.set_meta("placement",place_text)

func _save() -> void:
	if not selected_assets.is_empty() and not selected_assets.has(item_id):
		item.free();return
	for key: String in batches:
		var data: Dictionary = batches[key]
		var st: SurfaceTool = data.tool;st.generate_normals()
		var mesh: ArrayMesh = st.commit()
		var mesh_path: String = OUT+"meshes/"+item_id+"_"+key+".res"
		assert(ResourceSaver.save(mesh,mesh_path,ResourceSaver.FLAG_COMPRESS)==OK)
		var node: MeshInstance3D = MeshInstance3D.new();node.name=key.to_pascal_case()
		node.mesh=load(mesh_path);node.material_override=data.material;item.add_child(node)
	_own(item,item)
	var bounds: AABB = _bounds(item)
	var count: int = item.find_children("*","CollisionShape3D",true,false).size()
	var path: String = OUT+family+"/"+item_id+".tscn"
	DirAccess.make_dir_recursive_absolute(OUT+family)
	var packed: PackedScene = PackedScene.new();assert(packed.pack(item)==OK)
	assert(ResourceSaver.save(packed,path)==OK)
	catalog.append({"id":item_id,"label":item_label,"family":family,"scene":path,"purpose":purpose,
		"placement":placement,"size_m":[snappedf(bounds.size.x,.01),snappedf(bounds.size.y,.01),snappedf(bounds.size.z,.01)],
		"bounds_center_m":[bounds.get_center().x,bounds.get_center().y,bounds.get_center().z],
		"collision_shapes":count,"triangles":_triangles(item),"ground_pivot":true,"building_design":item.get_meta("building_design",""),"building_kind":item.get_meta("building_kind","")})
	print("ASSET_SAVED ",item_id," colliders=",count)
	item.free()

func _own(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner=owner_node
		if child.scene_file_path.is_empty():_own(child,owner_node)

func _bounds(node: Node3D, parent_transform: Transform3D = Transform3D.IDENTITY) -> AABB:
	var tr: Transform3D = parent_transform*node.transform
	var b: AABB = tr*node.get_aabb() if node is MeshInstance3D else AABB()
	for child: Node in node.get_children():
		if child is Node3D:
			var c: AABB = _bounds(child,tr)
			if c.size.length_squared()>0: b=c if b.size.length_squared()==0 else b.merge(c)
	return b

func _triangles(node: Node) -> int:
	var count: int=0
	for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		for s: int in mesh.mesh.get_surface_count():
			var arrays: Array=mesh.mesh.surface_get_arrays(s)
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			count+=indices.size()/3 if not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size()/3
	return count

func _surface(group: String, mat: String) -> SurfaceTool:
	var key: String=group+"_"+mat
	if not batches.has(key):
		var st: SurfaceTool=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_smooth_group(-1)
		batches[key]={"tool":st,"material":mats[mat]}
	return batches[key].tool

func _mesh(group: String, mesh: Mesh, tr: Transform3D, mat: String, tone: float=1.0) -> void:
	var st: SurfaceTool=_surface(group,mat)
	for s: int in mesh.get_surface_count():
		var arrays: Array=mesh.surface_get_arrays(s)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		if indices.is_empty():
			for i: int in vertices.size():indices.append(i)
		for index: int in indices:
			st.set_color(Color(tone,tone,tone));st.add_vertex(model_transform*tr*vertices[index])

func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,tone: float=1.0) -> void:
	for v: Vector3 in [a,b,c]:st.set_color(Color(tone,tone,tone));st.add_vertex(model_transform*v)

func _box(group: String, size: Vector3, at: Vector3, mat: String, rot: Vector3=Vector3.ZERO, collide: bool=false) -> void:
	var mesh: BoxMesh=BoxMesh.new();mesh.size=size
	var tr: Transform3D=Transform3D(Basis.from_euler(rot),at)
	if mat=="stone":
		_beveled_block(group,size,tr,mat)
	else:_mesh(group,mesh,tr,mat,rng.randf_range(.86,1.08))
	if collide:
		var shape: BoxShape3D=BoxShape3D.new();shape.size=size;_collision(group,shape,tr)

func _beveled_block(group: String,size: Vector3,tr: Transform3D,mat: String) -> void:
	var st: SurfaceTool=_surface(group,mat)
	var half: Vector3=size*.5
	var bevel: float=minf(.024,minf(size.x,minf(size.y,size.z))*.12)
	var inner: Vector3=half-Vector3.ONE*bevel
	var tone: float=rng.randf_range(.83,1.09)
	for axis: int in 3:
		var u: int=(axis+1)%3;var v: int=(axis+2)%3
		for side: float in [-1.0,1.0]:
			var corners: Array[Vector3]=[]
			for pair: Vector2 in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
				var p: Vector3=Vector3.ZERO;p[axis]=side*half[axis];p[u]=pair.x*inner[u];p[v]=pair.y*inner[v];corners.append(tr*p)
			_quad_out(st,corners,tr.basis[axis]*side,tone)
		for su: float in [-1.0,1.0]:
			for sv: float in [-1.0,1.0]:
				var corners: Array[Vector3]=[]
				for end: float in [-1.0,1.0]:
					var a: Vector3=Vector3.ZERO;a[axis]=end*inner[axis];a[u]=su*half[u];a[v]=sv*inner[v]
					var b: Vector3=a;b[u]=su*inner[u];b[v]=sv*half[v]
					corners.append(tr*a);corners.append(tr*b)
				_quad_out(st,[corners[0],corners[1],corners[3],corners[2]],(tr.basis[u]*su+tr.basis[v]*sv).normalized(),tone*.98)
	for sx: float in [-1.0,1.0]:
		for sy: float in [-1.0,1.0]:
			for sz: float in [-1.0,1.0]:
				var a: Vector3=tr*Vector3(sx*half.x,sy*inner.y,sz*inner.z)
				var b: Vector3=tr*Vector3(sx*inner.x,sy*half.y,sz*inner.z)
				var c: Vector3=tr*Vector3(sx*inner.x,sy*inner.y,sz*half.z)
				var outward: Vector3=tr.basis*Vector3(sx,sy,sz)
				if (b-a).cross(c-a).dot(outward)>0:_tri(st,a,c,b,tone)
				else:_tri(st,a,b,c,tone)

func _quad_out(st: SurfaceTool,vertices: Array,outward: Vector3,tone: float) -> void:
	if (vertices[1]-vertices[0]).cross(vertices[2]-vertices[0]).dot(outward)>0:
		_tri(st,vertices[0],vertices[2],vertices[1],tone);_tri(st,vertices[0],vertices[3],vertices[2],tone)
	else:
		_tri(st,vertices[0],vertices[1],vertices[2],tone);_tri(st,vertices[0],vertices[2],vertices[3],tone)

func _collision(label: String, shape: Shape3D, tr: Transform3D) -> void:
	var body: StaticBody3D=StaticBody3D.new();body.name=label+"Collision";body.transform=model_transform*tr;body.collision_mask=0;item.add_child(body)
	var node: CollisionShape3D=CollisionShape3D.new();node.shape=shape;body.add_child(node)

func _beam(group: String,a: Vector3,b: Vector3,thickness: float,mat: String="wood",collide: bool=false) -> void:
	var direction: Vector3=b-a
	var axis: Vector3=direction.normalized();var right: Vector3=axis.cross(Vector3.FORWARD).normalized()
	if right.length_squared()<.1:right=axis.cross(Vector3.RIGHT).normalized()
	var basis: Basis=Basis(right,axis,right.cross(axis).normalized())
	_box(group,Vector3(thickness,direction.length(),thickness),(a+b)*.5,mat,basis.get_euler(),collide)

func _cylinder(group: String,at: Vector3,radius: float,height: float,mat: String,top_radius: float=-1,rot: Vector3=Vector3.ZERO,collide: bool=false) -> void:
	var mesh: CylinderMesh=CylinderMesh.new();mesh.bottom_radius=radius;mesh.top_radius=radius if top_radius<0 else top_radius
	mesh.height=height;mesh.radial_segments=12;mesh.rings=1
	var tr: Transform3D=Transform3D(Basis.from_euler(rot),at);_mesh(group,mesh,tr,mat)
	if collide:
		var shape: CylinderShape3D=CylinderShape3D.new();shape.radius=maxf(radius,mesh.top_radius);shape.height=height;_collision(group,shape,tr)

func _ring(group: String,at: Vector3,outer: float,inner: float,height: float,mat: String,rot: Vector3=Vector3.ZERO) -> void:
	var st: SurfaceTool=_surface(group,mat);var tr: Transform3D=Transform3D(Basis.from_euler(rot),at)
	for i: int in 16:
		var a: float=TAU*i/16.0;var b: float=TAU*(i+1)/16.0
		var v: Array[Vector3]=[]
		for h: float in [-height*.5,height*.5]:
			for r: float in [outer,inner]:
				v.append(tr*Vector3(sin(a)*r,h,cos(a)*r));v.append(tr*Vector3(sin(b)*r,h,cos(b)*r))
		for face: Array in [[0,1,5,4],[2,6,7,3],[0,2,3,1],[4,5,7,6]]:
			_tri(st,v[face[0]],v[face[1]],v[face[2]]);_tri(st,v[face[0]],v[face[2]],v[face[3]])

func _stone(group: String,at: Vector3,size: Vector3,mat: String="stone") -> void:
	var mesh: SphereMesh=SphereMesh.new();mesh.radius=.5;mesh.height=1;mesh.radial_segments=7;mesh.rings=3
	var tr: Transform3D=Transform3D(Basis.from_euler(Vector3(rng.randf()*.8,rng.randf()*TAU,rng.randf()*.7)).scaled(size),at)
	_mesh(group,mesh,tr,mat,rng.randf_range(.66,1.15))

func _pile(at: Vector3,span: Vector2,mat: String,count: int=50,height: float=.8) -> void:
	# A solid mound supports the visible lumps; no suspended stones or hollow heaps.
	var st: SurfaceTool=_surface("HeapCore",mat)
	for row: int in 5:
		var r0: float=1.0-row/5.0;var r1: float=1.0-(row+1)/5.0
		for i: int in 18:
			var a: float=TAU*i/18.0;var b: float=TAU*(i+1)/18.0
			var v0: Vector3=at+Vector3(cos(a)*span.x*.48*r0,.015+height*(1-r0*r0),sin(a)*span.y*.48*r0)
			var v1: Vector3=at+Vector3(cos(b)*span.x*.48*r0,.015+height*(1-r0*r0),sin(b)*span.y*.48*r0)
			var v2: Vector3=at+Vector3(cos(a)*span.x*.48*r1,.015+height*(1-r1*r1),sin(a)*span.y*.48*r1)
			var v3: Vector3=at+Vector3(cos(b)*span.x*.48*r1,.015+height*(1-r1*r1),sin(b)*span.y*.48*r1)
			_tri(st,v0,v1,v2,.72);_tri(st,v1,v3,v2,.76)
	for i: int in count:
		var u: float=rng.randf()*TAU;var d: float=sqrt(rng.randf())
		var p: Vector3=at+Vector3(cos(u)*span.x*.48*d,.035+height*(1-d*d),sin(u)*span.y*.48*d)
		_stone("LooseMaterial",p,Vector3(rng.randf_range(.16,.38),rng.randf_range(.12,.32),rng.randf_range(.17,.36)),mat)
	var shape: BoxShape3D=BoxShape3D.new();shape.size=Vector3(span.x*.7,height*.65,span.y*.7)
	_collision("Pile",shape,Transform3D(Basis.IDENTITY,at+Vector3(0,height*.3,0)))

func _marker(label: String,p: Vector3) -> void:
	var suffix: int=1
	var unique: String=label
	while item.has_node(unique):suffix+=1;unique=label+str(suffix)
	var node: Marker3D=Marker3D.new();node.name=unique;node.transform=model_transform*Transform3D(Basis.IDENTITY,p);item.add_child(node)

func _roof(at: Vector3,width: float,depth: float,eave: float,rise: float,mat: String="rust_roof") -> void:
	var half: float=width*.5+.14;var slope: float=atan2(rise,half)
	var rows: int=ceili(Vector2(half,rise).length()/.29);var columns: int=ceili((depth+.34)/.32)
	for side: float in [-1.0,1.0]:
		_box("RoofDeck",Vector3(Vector2(half,rise).length(),.11,depth+.34),at+Vector3(side*half*.5,eave+rise*.5,0),"dark_wood",Vector3(0,0,-side*slope))
		for row: int in rows:
			var x: float=half*(row+.5)/rows
			var step: float=(depth+.34)/columns
			for col: int in range(-1,columns+1):
				var left: float=maxf(-(depth+.34)*.5,-(depth+.34)*.5+(col+.5*(row%2))*step)
				var right: float=minf((depth+.34)*.5,-(depth+.34)*.5+(col+1+.5*(row%2))*step)
				if right-left<.03:continue
				# Offset along the sloping deck's normal: steep roofs must not cut through their tiles.
				_box("SlateCourses",Vector3(half/rows/cos(slope)+.055,.023,right-left-.008),at+Vector3(side*x,eave+rise-x*rise/half+.11/cos(slope),(left+right)*.5),mat,Vector3(0,0,-side*(slope-.018)))
		for z: float in [-(depth+.38)*.5,(depth+.38)*.5]:
			_beam("TimberVerge",at+Vector3(side*half,eave+.045,z),at+Vector3(0,eave+rise+.10,z),.12,"dark_wood")
	for i: int in ceili(depth/.42):
		_box("RidgeTiles",Vector3(.24,.10,.40),at+Vector3(0,eave+rise+.17,-depth*.5+.21+i*.42),mat)

func _lean_roof(at: Vector3,width: float,depth: float,eave: float,rise: float,mat: String="roof") -> void:
	var slope: float=atan2(rise,depth);var extent: float=depth+.5
	_box("SinglePitchDeck",Vector3(width+.45,.12,extent/cos(slope)),at+Vector3(0,eave+rise*.5,0),"dark_wood",Vector3(slope,0,0))
	var rows: int=ceili(extent/.34);var cols: int=ceili((width+.45)/.40)
	for row: int in rows:
		var z: float=-extent*.5+(row+.5)*extent/rows
		var step: float=(width+.45)/cols
		for col: int in range(-1,cols+1):
			var left: float=maxf(-(width+.45)*.5,-(width+.45)*.5+(col+.5*(row%2))*step)
			var right: float=minf((width+.45)*.5,-(width+.45)*.5+(col+1+.5*(row%2))*step)
			if right-left<.03:continue
			_box("SlateLeanCourses",Vector3(right-left-.01,.023,extent/rows/cos(slope)+.035),at+Vector3((left+right)*.5,eave+rise*.5-z*tan(slope)+.075,z),mat,Vector3(slope-.055,0,0))
	for x: float in [-width*.5,width*.5]:
		_beam("RoofEdge",at+Vector3(x,eave+rise,-depth*.5-.15),at+Vector3(x,eave,depth*.5+.15),.17,"dark_wood")
	for z: float in [-depth*.5,depth*.5]:
		var y: float=eave+rise*.5-z*tan(slope)
		_beam("FrontFascia",at+Vector3(-width*.5-.2,y,z),at+Vector3(width*.5+.2,y,z),.18,"dark_wood")

func _shed(at: Vector3,width: float,depth: float,eave: float=2.75,rise: float=1.3,back: bool=true,roof_mat: String="rust_roof",attached_rise: float=-1) -> void:
	if attached_rise<0 and depth>2.5:
		architecture.hall(at,width,depth,eave,back)
		return
	roof_mat=architecture.roof_material()
	var roof_rise: float=attached_rise if attached_rise>=0 else maxf(rise*.78,depth*.48)
	for x: float in [-width*.5,width*.5]:
		for z: float in [-depth*.5,0.0,depth*.5]:
			var top: float=eave+roof_rise*.5-z/depth*roof_rise
			_box("MasonryPier",Vector3(.52,.70,.52),at+Vector3(x,.35,z),"stone",Vector3.ZERO,true)
			for y: float in [.23,.48]:_box("PierMortar",Vector3(.525,.022,.525),at+Vector3(x,y,z),"mortar")
			_beam("HeavyPost",at+Vector3(x,.55,z),at+Vector3(x,top,z),.29,"dark_wood",true)
			for y: float in [.82,top-.22]:_box("PostIronCollar",Vector3(.32,.08,.32),at+Vector3(x,y,z),"iron")
			_beam("KneeBrace",at+Vector3(x,top-.62,z),at+Vector3(x-signf(x)*.7,top,z),.17,"wood")
		_beam("Purlin",at+Vector3(x,eave+roof_rise,-depth*.5),at+Vector3(x,eave,depth*.5),.27,"dark_wood")
	for z: float in [-depth*.5,0.0,depth*.5]:
		var y: float=eave+roof_rise*.5-z/depth*roof_rise-.22
		_beam("CrossBeam",at+Vector3(-width*.5,y,z),at+Vector3(width*.5,y,z),.25,"dark_wood")
	if back:
		_box("RearWallBody",Vector3(width,1.3,.35),at+Vector3(0,.65,-depth*.5),"mortar",Vector3.ZERO,true)
		_masonry_face(at+Vector3(0,0,-depth*.5+.20),width,1.3,0)
		_boarding(at+Vector3(0,1.3,-depth*.5),width,eave+roof_rise-1.35)
	_lean_roof(at,width,depth,eave,roof_rise,roof_mat)
	_marker("Entrance",at+Vector3(0,0,depth*.5+1.0))

func _masonry_face(at: Vector3,width: float,height: float,yaw: float=0) -> void:
	var basis: Basis=Basis(Vector3.UP,yaw)
	var rows: int=ceili(height/.32)
	for row: int in rows:
		var x: float=-width*.5
		while x<width*.5-.01:
			var w: float=minf(rng.randf_range(.40,.78),width*.5-x)
			var h: float=height/rows
			_box("RubbleMasonry",Vector3(maxf(.02,w-.025),h-.024,.15),at+basis*Vector3(x+w*.5,(row+.5)*h,0),"stone",Vector3(0,yaw,0))
			x+=w

func _boarding(at: Vector3,width: float,height: float,rot: float=0) -> void:
	var basis: Basis=Basis(Vector3.UP,rot)
	for i: int in ceili(width/.25):
		var count: int=ceili(width/.25)
		_box("Boarding",Vector3(width/count-.018,height,.1),at+basis*Vector3(-width*.5+(i+.5)*width/count,height*.5,0),"wood",Vector3(0,rot,0))
	_box("BoardingBody",Vector3(width,height,.09),at+Vector3(0,height*.5,0),"dark_wood",Vector3(0,rot,0),true)

func _door(at: Vector3,width: float=1.05,height: float=1.9) -> void:
	_box("DoorRecess",Vector3(width+.16,height+.15,.13),at+Vector3(0,height*.5,0),"dark")
	for i: int in 6:_box("DoorPlanks",Vector3(width/6-.018,height,.10),at+Vector3(-width*.5+(i+.5)*width/6,height*.5,.10),"wood")
	for y: float in [height*.25,height*.75]:_box("DoorHinges",Vector3(width*.9,.06,.035),at+Vector3(0,y,.17),"iron")
	_ring("DoorPull",at+Vector3(width*.27,height*.50,.20),.06,.039,.035,"iron",Vector3(PI*.5,0,0))
	architecture.doorway(at,width,height)
	_marker("Entrance",at+Vector3(0,0,1.0));_marker("DoorFace",at+Vector3(0,0,.20))

func _window(at: Vector3,width: float=.7) -> void:
	architecture.window(at,width)

func _room(at: Vector3,width: float,depth: float,height: float,roof_mat: String="roof",timber: bool=false) -> void:
	var planked: bool=timber and item_id.begins_with("latrines")
	architecture.walls(at,width,depth,height,planked)
	var rise: float=architecture.rise_for(width,.95)
	var saved: Transform3D=model_transform
	model_transform=saved*Transform3D(Basis.IDENTITY,at)
	architecture.gable(width,depth,height,rise)
	_roof(Vector3.ZERO,width,depth,height,rise,architecture.roof_material())
	model_transform=saved
	_door(at+Vector3(0,.17,depth*.5+.18),.97,minf(1.92,height-.23))
	if width>2.6:
		for x: float in [-width*.32,width*.32]:_window(at+Vector3(x,minf(1.53,height-.48),depth*.5+.035),.47)

func _timber_window(at: Vector3) -> void:
	architecture.window(at,.40,.62)

func _chimney(at: Vector3,height: float=2.8) -> void:
	height+=.45
	_box("ChimneyCore",Vector3(.78,height,.74),at+Vector3(0,height*.5,0),"mortar")
	var courses: int=ceili(height/.27)
	for y: int in courses:
		for x: float in [-.2,.2]:
			_box("ChimneyFace",Vector3(.36,height/courses-.018,.79),at+Vector3(x,(y+.5)*height/courses,0),"stone")
	for z: float in [-.43,.43]:_box("ChimneyCoping",Vector3(1.02,.18,.20),at+Vector3(0,height+.1,z),"stone")
	for x: float in [-.43,.43]:_box("ChimneyCoping",Vector3(.20,.18,.67),at+Vector3(x,height+.1,0),"stone")
	_box("ChimneyBlackOpening",Vector3(.68,.016,.65),at+Vector3(0,height+.015,0),"dark")

func _barrel(at: Vector3,scale_value: float=1.0) -> void:
	var tr: Transform3D=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale_value),at)
	var mesh: CylinderMesh=CylinderMesh.new();mesh.bottom_radius=.35;mesh.top_radius=.35;mesh.height=.90;mesh.radial_segments=12
	_mesh("BarrelStaves",mesh,tr*Transform3D(Basis.IDENTITY,Vector3(0,.45,0)),"wood")
	for y: float in [.12,.45,.78]:_ring("BarrelBands",at+Vector3(0,y*scale_value,0),.367*scale_value,.348*scale_value,.08*scale_value,"iron")
	var shape: CylinderShape3D=CylinderShape3D.new();shape.radius=.36*scale_value;shape.height=.90*scale_value
	_collision("Barrel",shape,Transform3D(Basis.IDENTITY,at+Vector3(0,.45*scale_value,0)))

func _crate(at: Vector3,scale_value: float=1.0) -> void:
	_box("Crate",Vector3(.78,.65,.72)*scale_value,at+Vector3(0,.325*scale_value,0),"wood",Vector3.ZERO,true)
	for x: float in [-.29,.29]:_box("CrateStraps",Vector3(.07,.67,.75)*scale_value,at+Vector3(x,.325,0)*scale_value,"iron")

func _trough(at: Vector3,width: float=1.8,depth: float=.8) -> void:
	_box("TroughBase",Vector3(width,.14,depth),at+Vector3(0,.14,0),"stone",Vector3.ZERO,true)
	for x: float in [-width*.5,width*.5]:_box("TroughSides",Vector3(.13,.54,depth+.12),at+Vector3(x,.34,0),"stone")
	for z: float in [-depth*.5,depth*.5]:_box("TroughSides",Vector3(width,.54,.13),at+Vector3(0,.34,z),"stone")
	_box("StillWater",Vector3(width-.15,.01,depth-.13),at+Vector3(0,.47,0),"water")
	for x: float in [-width*.32,width*.32]:_box("TroughFeet",Vector3(.27,.16,depth*.8),at+Vector3(x,.08,0),"stone")

func _bench(at: Vector3,tools: bool=true) -> void:
	_box("BenchTop",Vector3(1.65,.15,.74),at+Vector3(0,.93,0),"wood",Vector3.ZERO,true)
	for x: float in [-.63,.63]:
		for z: float in [-.24,.24]:_beam("BenchLegs",at+Vector3(x,0,z),at+Vector3(x,.88,z),.12)
	_box("LowerShelf",Vector3(1.40,.10,.55),at+Vector3(0,.25,0),"wood")
	if tools:
		for i: int in 4:
			_beam("ToolHandle",at+Vector3(-.54+i*.30,1.025,-.2),at+Vector3(-.54+i*.30,1.025,.21),.035)
			_box("ToolHead",Vector3(.18,.06,.07),at+Vector3(-.54+i*.3,1.06,-.17),"metal")
		_box("BenchVice",Vector3(.16,.26,.12),at+Vector3(.64,1.06,.31),"metal")
		_beam("ViceScrew",at+Vector3(.64,1.02,.25),at+Vector3(.64,1.02,.57),.04,"iron")

func _sacks(at: Vector3) -> void:
	for i: int in 3:
		var p: Vector3=at+Vector3((i%2)*.48,0,(i/2)*.4)
		var mesh: SphereMesh=SphereMesh.new();mesh.radius=.30;mesh.height=.85;mesh.radial_segments=9;mesh.rings=5
		_mesh("SackCloth",mesh,Transform3D(Basis.IDENTITY,p+Vector3(0,.40,0)),"linen",rng.randf_range(.8,1.0))
		_cylinder("TiedMouth",p+Vector3(0,.79,0),.12,.17,"linen",.08)
		_ring("SackTie",p+Vector3(0,.81,0),.105,.08,.05,"rope")

func _balance(at: Vector3) -> void:
	_box("ScalesBase",Vector3(.45,.06,.3),at+Vector3(0,.03,0),"metal")
	_beam("ScalesStand",at,at+Vector3(0,.8,0),.055,"iron")
	_beam("ScalesArm",at+Vector3(-.50,.74,0),at+Vector3(.5,.80,0),.045,"iron")
	for x: float in [-.46,.46]:
		for z: float in [-.15,.15]:_beam("PanChains",at+Vector3(x,.76,0),at+Vector3(x,.28,z),.014,"iron")
		_cylinder("WeighingPans",at+Vector3(x,.28,0),.20,.055,"metal",.24)

func _logs(at: Vector3,width: float=1.8,length: float=2.0) -> void:
	var columns: int=ceili(width/.28)
	for row: int in 3:
		for col: int in columns-row:
			var p: Vector3=at+Vector3(-width*.5+.14+col*.28+row*.14,.14+row*.235,0)
			_cylinder("CordwoodBark",p,.125,length,"dark_wood",.12,Vector3(PI*.5,0,0))
			_cylinder("CutEnds",p+Vector3(0,0,length*.5+.009),.107,.015,"wood",.104,Vector3(PI*.5,0,0))

func _own_gallery(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner=owner_node
		if child.scene_file_path.is_empty():_own_gallery(child,owner_node)

func _seat(at: Vector3) -> void:
	_box("Seat",Vector3(1.65,.13,.48),at+Vector3(0,.47,0),"wood")
	for x: float in [-.6,.6]:_box("SeatSupports",Vector3(.20,.42,.40),at+Vector3(x,.21,0),"stone")

func _roof_infill(at: Vector3,depth: float,rise: float) -> void:
	var vertices: Array[Vector3]=[]
	for x: float in [-.07,.07]:
		vertices.append(at+Vector3(x,0,-depth*.5))
		vertices.append(at+Vector3(x,rise,-depth*.5))
		vertices.append(at+Vector3(x,0,depth*.5))
	var st: SurfaceTool=_surface("WeatherproofRoofInfill","dark_wood")
	for tri: Array in [[0,2,1],[3,4,5],[0,1,4],[0,4,3],[1,2,5],[1,5,4],[2,0,3],[2,3,5]]:
		_tri(st,vertices[tri[0]],vertices[tri[1]],vertices[tri[2]])
	var shape: ConvexPolygonShape3D=ConvexPolygonShape3D.new();shape.points=PackedVector3Array(vertices)
	_collision("RoofInfill",shape,Transform3D.IDENTITY)
	var count: int=ceili(depth/.22)
	for i: int in count:
		var z: float=-depth*.5+(i+.5)*depth/count
		var height: float=maxf(.015,rise*(.5-(z+depth/count*.5)/depth))
		_box("InfillPlanks",Vector3(.16,height,depth/count-.016),at+Vector3(0,height*.5,z),"wood")
	_beam("RoofWallPlate",at+Vector3(0,rise,-depth*.5),at+Vector3(0,0,depth*.5),.13,"dark_wood")

func _stair_ramp(label: String,x: float,width: float,start_z: float,end_z: float,height: float) -> void:
	# Smooth collision under the visible treads: the controller has no artificial step climbing.
	var shape: ConvexPolygonShape3D=ConvexPolygonShape3D.new();var points: PackedVector3Array=[]
	for side: float in [-1.0,1.0]:
		for p: Vector2 in [Vector2(start_z,-.12),Vector2(start_z,.02),Vector2(end_z,height),Vector2(end_z,height-.14)]:points.append(Vector3(x+side*width*.5,p.y,p.x))
	shape.points=points;_collision(label,shape,Transform3D.IDENTITY)

func _hay(at: Vector3,width: float,depth: float) -> void:
	_box("HayCore",Vector3(width,.14,depth),at+Vector3(0,.07,0),"straw")
	for i: int in 42:
		var p: Vector3=at+Vector3(rng.randf_range(-width*.48,width*.48),rng.randf_range(.12,.17),rng.randf_range(-depth*.44,depth*.44))
		var d: Vector3=Vector3(rng.randf_range(-.15,.15),.01,rng.randf_range(-.09,.09))
		_beam("HayStrands",p-d,p+d,.018,"straw")
func _build_gallery() -> void:
	var gallery: Node3D=Node3D.new();gallery.name="CatalogueScierie"
	gallery.set_script(load("res://scripts/sawmill_catalog.gd"))
	var assets: Node3D=Node3D.new();assets.name="Assets";gallery.add_child(assets)
	for i: int in catalog.size():
		var obj: Node3D=(load(catalog[i].scene) as PackedScene).instantiate();assets.add_child(obj)
		obj.position=Vector3((i%8)*14,0,(i/8)*14);obj.set_meta("catalog_index",i)
	var demonstration: Node3D=Node3D.new();demonstration.name="Demonstration";gallery.add_child(demonstration)
	var layout: Array=[
		["scierie_hydraulique",-1,-8,0],["atelier_charpentier",-14,4,.12],
		["halle_sechage",13,5,-.1],["depot_grumes",12,-7,0],
		["portique_chargement",12,14,0],["charrette_grumes",6,14,.25],
		["logis_a_colombages",-8,18,.12],["maison_aux_deux_volumes",0,20,-.12],
		["baraquement_des_equipes",-14,17,.05],["bureau_bois",-15,-7,.1],
		["tas_planches",9,1,0],["chevalets_sciage",-10,8,.12]
	]
	for data: Array in layout:
		for record: Dictionary in catalog:
			if record.id!=data[0]:continue
			var obj: Node3D=(load(record.scene) as PackedScene).instantiate();demonstration.add_child(obj)
			obj.position=Vector3(data[1],0,data[2]);obj.rotation.y=data[3];break
	var floor_node: MeshInstance3D=MeshInstance3D.new();floor_node.name="Ground"
	var plane: PlaneMesh=PlaneMesh.new();plane.size=Vector2(260,220);floor_node.mesh=plane;floor_node.position=Vector3(35,-.07,25)
	var mat: StandardMaterial3D=StandardMaterial3D.new();mat.albedo_color=Color("8f9179");mat.roughness=1.0
	floor_node.material_override=mat;gallery.add_child(floor_node)
	var sun: DirectionalLight3D=DirectionalLight3D.new();sun.name="Sun";sun.rotation_degrees=Vector3(-52,-35,0)
	sun.light_color=Color(1.0,.97,.91);sun.light_energy=1.25;sun.shadow_enabled=true;sun.directional_shadow_max_distance=250;gallery.add_child(sun)
	var sky: WorldEnvironment=WorldEnvironment.new();sky.name="WorldEnvironment"
	var environment: Environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("a9b6ab")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("a1b1ba");environment.ambient_light_energy=.52
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;environment.ssao_enabled=true;environment.ssao_radius=1.4;environment.ssao_intensity=1.3
	sky.environment=environment;gallery.add_child(sky)
	var camera_node: Camera3D=Camera3D.new();camera_node.name="Camera";camera_node.projection=Camera3D.PROJECTION_ORTHOGONAL;camera_node.current=true
	camera_node.far=450;gallery.add_child(camera_node)
	_own_gallery(gallery,gallery)
	var packed: PackedScene=PackedScene.new();assert(packed.pack(gallery)==OK)
	assert(ResourceSaver.save(packed,"res://scenes/catalogue_scierie.tscn")==OK)
	gallery.free()
