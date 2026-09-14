extends SceneTree
## Offline, seeded construction of the ironworking town kit with the mining settlement's own masonry, slate and iron identity.
## One unit is one meter. Assets are static saved scenes; no builder runs in the game.
const OUT: String = "res://assets/ironworks/"
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var mats: Dictionary = {}
var batches: Dictionary = {}
var item: Node3D
var catalog: Array[Dictionary] = []
var item_id: String
var family: String
var item_label: String
var purpose: String
var placement: String
var model_transform: Transform3D = Transform3D.IDENTITY
var selected_assets: Dictionary = {}
var previous_assets: Dictionary = {}

func _initialize() -> void: call_deferred("build")

func build() -> void:
	if "--used-only" in OS.get_cmdline_user_args():
		var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OUT+"catalog.json"))
		for a: Dictionary in previous.assets:previous_assets[a.id]=a
		var town: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://planning/ironworks-town.json"))
		for a: Dictionary in town.buildings+town.props:selected_assets[a.asset]=true
	DirAccess.make_dir_recursive_absolute(OUT+"materials")
	DirAccess.make_dir_recursive_absolute(OUT+"meshes")
	_load_materials()
	_production()
	_storage()
	(load("res://tools/ironworks_building_designs.gd") as GDScript).new().build_industry(self)
	_town()
	_props()
	_modules()
	var file: FileAccess = FileAccess.open(OUT+"catalog.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":4,"units":"meters","front":"+Z","origin":"ground center",
		"style":"Mining settlement: dark coursed stone, slate, heavy timber and black iron; charcoal-fired bloomeries",
		"assets":catalog},"  "));file.close()
	_build_gallery()
	print("IRONWORKS_BUILD_OK assets=",catalog.size())
	quit()

func _load_materials() -> void:
	var shader: Shader=load("res://shaders/ironworks_surface.gdshader")
	for spec: Array in [["wood","615447",0],["dark_wood","3d3832",0],["rock","63696a",1],
		["stone","687172",1],["plaster","626465",1],["pale_plaster","717778",1],
		["roof","3e535e",2],["rust_roof","505b64",2],["dark","111518",1],
		["iron","242b2e",3],["metal","5c686c",3],["rope","8c775a",0],
		["clay","876653",1],["soot","252729",1],["mortar","424a4c",1],
		["ore","775440",1],["charcoal","23282b",1],["slag","43474c",1],
		["straw","97855e",0],["leather","443932",0],["linen","a99b7b",1],["earth","605346",1]]:
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
	var heat: ShaderMaterial=ShaderMaterial.new();heat.shader=load("res://shaders/ironworks_embers.gdshader")
	assert(ResourceSaver.save(heat,OUT+"materials/embers.tres")==OK)
	mats["embers"]=load(OUT+"materials/embers.tres")

func _start(id: String, group: String, label: String, use_text: String, place_text: String) -> void:
	item_id=id;family=group;item_label=label;purpose=use_text;placement=place_text
	rng.seed=abs(id.hash())+14092026;batches={};model_transform=Transform3D.IDENTITY
	item=Node3D.new();item.name=id.to_pascal_case();root.add_child(item)
	item.set_meta("asset_id",id);item.set_meta("family",group);item.set_meta("label",label)
	item.set_meta("purpose",use_text);item.set_meta("placement",place_text)

func _save() -> void:
	if not selected_assets.is_empty() and not selected_assets.has(item_id) and previous_assets.has(item_id):
		catalog.append(previous_assets[item_id]);item.free();return
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

func _instance(path: String,at: Vector3,rot: float=0,scale_value: float=1) -> void:
	var scene: Node3D=(load(path) as PackedScene).instantiate();item.add_child(scene)
	scene.position=at;scene.rotation.y=rot;scene.scale=Vector3.ONE*scale_value

func _roof(at: Vector3,width: float,depth: float,eave: float,rise: float,mat: String="rust_roof") -> void:
	var half: float=width*.5+.14;var slope: float=atan2(rise,half)
	var rows: int=ceili(half/.30);var columns: int=ceili((depth+.34)/.40)
	for side: float in [-1.0,1.0]:
		_box("RoofDeck",Vector3(Vector2(half,rise).length(),.11,depth+.34),at+Vector3(side*half*.5,eave+rise*.5,0),"dark_wood",Vector3(0,0,-side*slope))
		for row: int in rows:
			var x: float=half*(row+.5)/rows
			var step: float=(depth+.34)/columns
			for col: int in range(-1,columns+1):
				var left: float=maxf(-(depth+.34)*.5,-(depth+.34)*.5+(col+.5*(row%2))*step)
				var right: float=minf((depth+.34)*.5,-(depth+.34)*.5+(col+1+.5*(row%2))*step)
				if right-left<.03:continue
				_box("SlateCourses",Vector3(half/rows/cos(slope)+.035,.023,right-left-.01),at+Vector3(side*x,eave+rise-x*rise/half+.074,(left+right)*.5),mat,Vector3(0,0,-side*(slope-.055)))
		for z: float in [-(depth+.38)*.5,(depth+.38)*.5]:
			_beam("StoneVerge",at+Vector3(side*half,eave+.045,z),at+Vector3(0,eave+rise+.10,z),.15,"stone")
	for i: int in ceili(depth/.42):
		_box("StoneRidgeCaps",Vector3(.28,.14,.40),at+Vector3(0,eave+rise+.1,-depth*.5+.21+i*.42),"stone")

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
	_marker("Entrance",at+Vector3(0,0,1.0));_marker("DoorFace",at+Vector3(0,0,.20))

func _window(at: Vector3,width: float=.7) -> void:
	at+=Vector3(0,0,.16)
	_box("WindowRecess",Vector3(width,.82,.08),at,"dark")
	for x: float in [-width*.5-.06,width*.5+.06]:_box("StoneWindowJamb",Vector3(.16,1.01,.18),at+Vector3(x,0,0),"stone")
	for y: float in [-.47,.47]:_box("StoneWindowLintel",Vector3(width+.32,.16,.22),at+Vector3(0,y,.01),"stone")
	for x: float in [-width*.22,width*.22]:_box("IronWindowBars",Vector3(.025,.83,.025),at+Vector3(x,0,.07),"iron")
	_box("WindowCrossbar",Vector3(width,.024,.025),at+Vector3(0,.05,.07),"iron")

func _room(at: Vector3,width: float,depth: float,height: float,roof_mat: String="roof",timber: bool=false) -> void:
	_box("Foundation",Vector3(width+.22,.22,depth+.22),at+Vector3(0,.11,0),"stone",Vector3.ZERO,true)
	_box("SolidWalls",Vector3(width,height-.22,depth),at+Vector3(0,(height+.22)*.5,0),"dark_wood" if timber else "mortar",Vector3.ZERO,true)
	if timber:
		var roof_rise: float=maxf(.45,depth*.48)
		_boarding(at+Vector3(0,.22,depth*.5),width,height-.22)
		_boarding(at+Vector3(0,.22,-depth*.5),width,height+roof_rise-.22)
		for x: float in [-width*.5,width*.5]:
			_boarding(at+Vector3(x,.22,0),depth,height-.22,PI*.5)
			_roof_infill(at+Vector3(x,height,0),depth,roof_rise)
		_lean_roof(at,width,depth,height,roof_rise,roof_mat)
	else:
		_masonry_face(at+Vector3(0,0,depth*.5+.015),width,height)
		_masonry_face(at+Vector3(0,0,-depth*.5-.015),width,height,PI)
		for x: float in [-width*.5-.015,width*.5+.015]:_masonry_face(at+Vector3(x,0,0),depth,height,PI*.5)
		var rise: float=maxf(.95,width*.29)
		var gable: PrismMesh=PrismMesh.new();gable.size=Vector3(width,rise,depth)
		_mesh("StoneGable",gable,Transform3D(Basis.IDENTITY,at+Vector3(0,height+rise*.5,0)),"stone")
		for side: float in [-1.0,1.0]:
			for z: float in [-depth*.5,depth*.5]:
				_box("CornerButtress",Vector3(.32,height+.12,.34),at+Vector3(side*width*.5,height*.5,z),"stone")
		_roof(at,width,depth,height,rise,roof_mat)
	_door(at+Vector3(0,.17,depth*.5+.18),.97,minf(1.92,height-.23))
	if width>2.6:
		for x: float in [-width*.32,width*.32]:
			if timber:_timber_window(at+Vector3(x,minf(1.45,height-.48),depth*.5+.08))
			else:_window(at+Vector3(x,1.53,depth*.5+.035),.47)
		if not timber:
			var saved: Transform3D=model_transform
			model_transform=saved*Transform3D(Basis(Vector3.UP,-PI*.5),at+Vector3(-width*.5,1.53,-depth*.15))
			_window(Vector3.ZERO,.53);model_transform=saved

func _timber_window(at: Vector3) -> void:
	_box("TimberWindowRecess",Vector3(.40,.50,.07),at,"dark")
	for x: float in [-.23,.23]:_box("TimberWindowFrame",Vector3(.06,.62,.12),at+Vector3(x,0,.015),"dark_wood")
	for y: float in [-.28,.28]:_box("TimberWindowFrame",Vector3(.52,.06,.12),at+Vector3(0,y,.015),"dark_wood")
	for x: float in [-.13,0.0,.13]:_box("TimberShutters",Vector3(.12,.50,.04),at+Vector3(x,0,.045),"wood")


func _chimney(at: Vector3,height: float=2.8) -> void:
	_box("ChimneyCore",Vector3(.78,height,.74),at+Vector3(0,height*.5,0),"mortar")
	var courses: int=ceili(height/.27)
	for y: int in courses:
		for x: float in [-.2,.2]:
			_box("ChimneyFace",Vector3(.36,height/courses-.018,.79),at+Vector3(x,(y+.5)*height/courses,0),"stone")
	for z: float in [-.43,.43]:_box("ChimneyCoping",Vector3(1.02,.18,.20),at+Vector3(0,height+.1,z),"stone")
	for x: float in [-.43,.43]:_box("ChimneyCoping",Vector3(.20,.18,.67),at+Vector3(x,height+.1,0),"stone")
	_box("ChimneyBlackOpening",Vector3(.68,.016,.65),at+Vector3(0,height+.015,0),"dark")

func _smoke(at: Vector3) -> void:
	var node: CPUParticles3D=(load("res://scenes/effects/fumee_ruine.tscn") as PackedScene).instantiate()
	node.name="FumeeFourneau";node.position=model_transform*at;node.amount=22;node.scale=Vector3.ONE*.7
	item.add_child(node)

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

func _furnace(at: Vector3,radius: float=.72,height: float=1.8,stone: bool=false,active: bool=false) -> void:
	var st: SurfaceTool=_surface("FurnaceShell","stone" if stone else "clay")
	var rings: Array[Vector2]=[Vector2(0,radius),Vector2(.22,radius*1.10),Vector2(height*.45,radius*.92),Vector2(height*.82,radius*.70),Vector2(height,radius*.69)]
	for row: int in range(rings.size()-1):
		for i: int in 20:
			var a: float=TAU*i/20.0;var b: float=TAU*(i+1)/20.0
			# The bottom front segments are absent: an actual extraction/tapping mouth.
			if row<2 and (i==0 or i==19):continue
			var a0: Vector3=at+Vector3(sin(a)*rings[row].y,rings[row].x,cos(a)*rings[row].y)
			var b0: Vector3=at+Vector3(sin(b)*rings[row].y,rings[row].x,cos(b)*rings[row].y)
			var a1: Vector3=at+Vector3(sin(a)*rings[row+1].y,rings[row+1].x,cos(a)*rings[row+1].y)
			var b1: Vector3=at+Vector3(sin(b)*rings[row+1].y,rings[row+1].x,cos(b)*rings[row+1].y)
			var tone: float=rng.randf_range(.84,1.10)*(1.0-float(row)*.055)
			_tri(st,a0,a1,b1,tone);_tri(st,a0,b1,b0,tone)
	_ring("BlackenedThroat",at+Vector3(0,height-.09,0),radius*.71,radius*.46,.20,"soot")
	_cylinder("DarkInterior",at+Vector3(0,height-.40,0),radius*.47,.02,"charcoal")
	# Refractory inner lining, visible below the open charging throat.
	_ring("InnerLining",at+Vector3(0,height-.29,0),radius*.48,radius*.42,.32,"soot")
	for x: float in [-1.0,1.0]:
		_box("MouthJamb",Vector3(.20,.55,.26),at+Vector3(x*radius*.37,.275,radius*.92),"soot")
	_box("MouthLintel",Vector3(radius*.95,.20,.29),at+Vector3(0,.62,radius*.87),"soot")
	_box("SlagApron",Vector3(.60,.07,.95),at+Vector3(0,.035,radius+.38),"slag")
	_cylinder("FurnaceFloor",at+Vector3(0,.027,0),radius,.05,"charcoal")
	_box("InnerBack",Vector3(radius*1.2,height*.46,.04),at+Vector3(0,height*.23,-radius*.25),"soot")
	for i: int in 14:
		_stone("FurnaceBed",at+Vector3(rng.randf_range(-.30,.30),.12,rng.randf_range(.10,.72)),Vector3(.19,.13,.21),"embers" if active else "charcoal")
	_cylinder("Tuyere",at+Vector3(radius*.93,.46,0),.105,.42,"clay",.065,Vector3(0,0,PI*.5))
	if stone:
		for row: int in 4:
			for i: int in 11:
				var angle: float=TAU*(i+.5*(row%2))/11.0
				if absf(wrapf(angle,-PI,PI))<.33:continue
				_box("StoneFacing",Vector3(.32,.18,.16),at+Vector3(sin(angle)*radius*.99,.12+row*.2,cos(angle)*radius*.99),"stone",Vector3(0,angle,0))
	var collision: CylinderShape3D=CylinderShape3D.new();collision.radius=radius*1.07;collision.height=height
	_collision("Furnace",collision,Transform3D(Basis.IDENTITY,at+Vector3(0,height*.5,0)))
	_marker("ChargingPoint",at+Vector3(0,height+.4,0));_marker("ExtractionSide",at+Vector3(0,0,radius+1.2))
	if active:
		_smoke(at+Vector3(0,height+.04,0))
		_firelight(at+Vector3(0,.34,radius*.91))

func _firelight(at: Vector3) -> void:
	var glow: OmniLight3D=OmniLight3D.new();glow.name="ForgeGlow";glow.position=model_transform*at
	glow.light_color=Color(1,.35,.075);glow.light_energy=.60;glow.omni_range=2.4
	item.add_child(glow)

func _bellows(at: Vector3,yaw: float=0) -> void:
	var tr: Transform3D=Transform3D(Basis(Vector3.UP,yaw),at)
	var outline: PackedVector2Array=PackedVector2Array([Vector2(-.09,-.87),Vector2(.09,-.87),Vector2(.36,-.10),Vector2(.40,.46),Vector2(.24,.70),Vector2(-.24,.70),Vector2(-.40,.46),Vector2(-.36,-.10)])
	for y: float in [.54,.91]:
		var st: SurfaceTool=_surface("BellowsBoards","wood")
		for i: int in range(1,outline.size()-1):
			_tri(st,tr*Vector3(outline[0].x,y,outline[0].y),tr*Vector3(outline[i].x,y,outline[i].y),tr*Vector3(outline[i+1].x,y,outline[i+1].y))
	for row: int in 5:
		var y0: float=.54+row*.074;var y1: float=y0+.074
		var st: SurfaceTool=_surface("LeatherPleats","leather")
		for i: int in outline.size():
			var next: int=(i+1)%outline.size();var u: Vector2=outline[i];var v: Vector2=outline[next]
			var f0: float=1.0 if row%2==0 else 1.08;var f1: float=1.08 if row%2==0 else 1.0
			_tri(st,tr*Vector3(u.x*f0,y0,u.y),tr*Vector3(u.x*f1,y1,u.y),tr*Vector3(v.x*f1,y1,v.y),.9)
			_tri(st,tr*Vector3(u.x*f0,y0,u.y),tr*Vector3(v.x*f1,y1,v.y),tr*Vector3(v.x*f0,y0,v.y))
	for x: float in [-.30,.30]:
		var foot: Vector3=tr*Vector3(x,0,.30);foot.y=0
		_beam("BellowsLegs",foot,tr*Vector3(x,.57,.30),.12)
	_marker("BellowsAirOutlet",tr*Vector3(0,.49,-1.22))
	_beam("BellowsHandle",tr*Vector3(0,.94,.5),tr*Vector3(0,1.02,1.14),.085)
	_beam("BellowsNozzle",tr*Vector3(0,.66,-.8),tr*Vector3(0,.49,-1.22),.12,"clay")
	var shape: BoxShape3D=BoxShape3D.new();shape.size=Vector3(.85,.94,1.7)
	_collision("Bellows",shape,Transform3D(tr.basis,tr*Vector3(0,.47,0)))

func _anvil(at: Vector3) -> void:
	_cylinder("AnvilStump",at+Vector3(0,.32,0),.32,.64,"wood",.29,Vector3.ZERO,true)
	_ring("StumpHoop",at+Vector3(0,.48,0),.316,.294,.06,"iron")
	_box("AnvilFoot",Vector3(.46,.09,.34),at+Vector3(0,.685,0),"metal")
	_box("AnvilWaist",Vector3(.23,.22,.22),at+Vector3(0,.82,0),"metal")
	_box("AnvilFace",Vector3(.65,.14,.27),at+Vector3(0,.99,0),"metal")
	_cylinder("AnvilHorn",at+Vector3(-.48,.98,0),.13,.40,"metal",.008,Vector3(0,0,PI*.5))
	_box("AnvilHeel",Vector3(.18,.10,.21),at+Vector3(.40,1.0,0),"metal")
	_box("HardyHole",Vector3(.06,.003,.06),at+Vector3(.35,1.054,0),"dark")
	_beam("HammerHandle",at+Vector3(.10,1.09,-.25),at+Vector3(.1,1.12,.25),.04)
	_box("HammerHead",Vector3(.18,.09,.09),at+Vector3(.10,1.12,-.22),"metal")

func _hearth(at: Vector3) -> void:
	_box("HearthBase",Vector3(1.45,.74,1.10),at+Vector3(0,.37,0),"stone",Vector3.ZERO,true)
	for x: float in [-.65,.65]:_box("HearthSides",Vector3(.18,.25,1.1),at+Vector3(x,.85,0),"soot")
	_box("HearthBack",Vector3(1.45,.55,.20),at+Vector3(0,1.0,-.47),"stone")
	for i: int in 22:_stone("HearthCoals",at+Vector3(rng.randf_range(-.53,.53),.77,rng.randf_range(-.35,.32)),Vector3(.15,.08,.17),"embers")
	var hood: SurfaceTool=_surface("OpenForgeHood","soot")
	var low: Array[Vector3]=[];var high: Array[Vector3]=[]
	for c: Vector2 in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
		low.append(at+Vector3(c.x*.90,1.54,c.y*.72))
		high.append(at+Vector3(c.x*.38,2.57,-.10+c.y*.36))
	for i: int in 4:
		var j: int=(i+1)%4
		_tri(hood,low[i],high[i],high[j]);_tri(hood,low[i],high[j],low[j])
		_beam("HoodRim",low[i],low[j],.07,"iron")
	for x: float in [-.73,.73]:_beam("HoodSupports",at+Vector3(x,.8,-.4),at+Vector3(x,1.7,-.4),.10,"iron")
	_chimney(at+Vector3(0,2.5,-.10),2.2)
	_smoke(at+Vector3(0,4.82,-.10));_firelight(at+Vector3(0,1.01,.32))
	_marker("WorkPosition",at+Vector3(0,0,1.15));_marker("HearthAirIntake",at+Vector3(.06,.73,0))

func _bin(at: Vector3,width: float,depth: float,mat: String="ore") -> void:
	for z: float in [-depth*.5,depth*.5]:
		for i: int in 3:_box("BinBoards",Vector3(width,.20,.10),at+Vector3(0,.15+i*.22,z),"wood")
	for x: float in [-width*.5,width*.5]:
		for i: int in 3:_box("BinBoards",Vector3(.10,.20,depth),at+Vector3(x,.15+i*.22,0),"wood")
		for z: float in [-depth*.5,depth*.5]:_beam("BinPosts",at+Vector3(x,0,z),at+Vector3(x,.80,z),.12)
	_pile(at,Vector2(width*.83,depth*.83),mat,34,.63)

func _bars(at: Vector3,length: float=2.3,rows: int=5) -> void:
	for z: float in [-length*.32,length*.32]:_box("Dunnage",Vector3(1.05,.14,.15),at+Vector3(0,.07,z),"wood")
	for row: int in rows:
		for col: int in 5:
			_box("ForgedBars",Vector3(.075,.08,length+rng.randf_range(-.10,.10)),at+Vector3(-.34+col*.16,.18+row*.085,0),"metal",Vector3(0,rng.randf_range(-.014,.014),0))
	for z: float in [-length*.25,length*.25]:_box("BundleStraps",Vector3(.80,.025,.045),at+Vector3(0,.233+(rows-1)*.085,z),"iron")

func _production() -> void:
	_start("bas_fourneau_argile","production","Bas fourneau en argile","Réduction du minerai au charbon ; gorge de chargement et bouche d’extraction.","Aire minérale ouverte, accès devant et sur le côté du soufflet.")
	_furnace(Vector3.ZERO);_bellows(Vector3(1.62,0,0),PI*.5);_save()
	_start("bas_fourneau_actif","production","Bas fourneau en activité","Même four avec braises et fumée légère ; la loupe reste un métal solide.","Version allumée, effet décoratif réglable sous FumeeFourneau.")
	_furnace(Vector3.ZERO,.72,1.8,false,true);_bellows(Vector3(1.62,0,0),PI*.5);_save()
	_start("bas_fourneau_pierre","production","Bas fourneau chemisé de pierre","Four trapu à parement de pierre et tuyère, variante d’atelier.","Garder une cour de travail devant la bouche.")
	_furnace(Vector3.ZERO,.86,2.12,true);_bellows(Vector3(1.82,0,0),PI*.5);_save()
	_start("grillage_minerai","production","Foyer de grillage du minerai","Préparation du minerai sur un lit de bois avant concassage.","Zone de préparation extérieure, distincte du charbon stocké.")
	for x: float in [-1.15,1.15]:_box("RoastWalls",Vector3(.3,.35,2.5),Vector3(x,.175,0),"stone",Vector3.ZERO,true)
	for i: int in 8:_cylinder("RoastLogs",Vector3(-.83+i*.24,.18,0),.10,2.15,"dark_wood",.09,Vector3(PI*.5,0,0))
	_pile(Vector3(0,.17,0),Vector2(1.9,2.0),"ore",55,.38);_save()
	_start("concassage_minerai","production","Poste de concassage et tamisage","Dalle, masses, tamis incliné et paniers pour préparer le minerai.","Entre l’aire de tri et les fourneaux.")
	_box("CrushingSlab",Vector3(1.8,.25,1.3),Vector3(0,.125,0),"stone",Vector3.ZERO,true)
	_pile(Vector3(-.35,.24,0),Vector2(.7,.7),"ore",20,.24)
	_beam("SledgeHandle",Vector3(.55,.26,.5),Vector3(.68,.30,-.5),.05)
	_box("SledgeHead",Vector3(.28,.16,.13),Vector3(.68,.30,-.5),"metal")
	for i: int in 13:_beam("SieveWeave",Vector3(1.10,.77,-.6+i*.10),Vector3(2.14,.35,-.6+i*.10),.023,"rope")
	for i: int in 12:
		var x: float=1.10+i*1.04/11.0;var y: float=.77-i*.42/11.0
		_beam("SieveWeaveCross",Vector3(x,y,-.66),Vector3(x,y,.66),.022,"rope")
	for z: float in [-.70,.70]:
		_beam("SieveFrame",Vector3(1.05,.79,z),Vector3(2.19,.33,z),.09)
	for p: Vector2 in [Vector2(1.05,.79),Vector2(2.19,.33)]:
		_beam("SieveEndFrame",Vector3(p.x,p.y,-.70),Vector3(p.x,p.y,.70),.10)
		for z: float in [-.62,.62]:_beam("SieveLeg",Vector3(p.x,0,z),Vector3(p.x,p.y,z),.10)
	_beam("SieveStretcher",Vector3(1.05,.18,-.62),Vector3(2.19,.18,-.62),.075);_save()
	_start("soufflets_jumeles","production","Soufflets jumelés","Deux soufflets manuels pour un apport d’air alterné.","Orienter les buses vers la tuyère du four ou du foyer.")
	_bellows(Vector3(-.53,0,0));_bellows(Vector3(.53,0,0));_save()
	_start("forge_affinage","production","Halle de martelage de la loupe","Halle basse sur piles de pierre avec foyer, enclume, outils et cuve.","Proche des fourneaux, accès large pour manipuler les loupes chaudes.")
	_shed(Vector3.ZERO,5.8,4.4,2.8,1.5,true)
	_hearth(Vector3(-1.45,0,-1.20));_anvil(Vector3(.10,0,.45));_bellows(Vector3(-.18,.24,-1.20),PI*.5)
	_trough(Vector3(1.9,0,-.4),1.2,.7);_tool_rack(Vector3(1.8,0,-2.08));_save()
	_start("atelier_outilleur","production","Atelier du taillandier","Bâtiment de finition : outils, ferrures et entretien du matériel de la mine.","Façade sur la rue de travail ; cour devant l’auvent.")
	_room(Vector3(0,0,-.7),5.2,3.7,2.75,"rust_roof")
	_shed(Vector3(0,0,2.0),5.3,1.5,2.25,.7,false,"rust_roof",.50)
	_anvil(Vector3(-1.25,0,2.2));_bench(Vector3(1.3,0,2.0));_chimney(Vector3(1.5,1.0,-1.55),3.5);_save()
	_start("meule_charbonniere","production","Meule de charbonnier","Empilement de bois couvert de terre pour produire le charbon de bois.","À l’écart des logements, sur un sol nu, près des réserves de bois.")
	_cylinder("EarthCover",Vector3(0,.48,0),1.75,.96,"earth",1.15)
	_cylinder("EarthDome",Vector3(0,1.08,0),1.15,.35,"earth",.35)
	_cylinder("CenterVent",Vector3(0,1.29,0),.18,.06,"charcoal")
	for i: int in 18:
		var a: float=TAU*i/18.0
		_beam("ExposedWood",Vector3(sin(a)*1.74,.06,cos(a)*1.74),Vector3(sin(a)*1.04,.93,cos(a)*1.04),.14,"dark_wood")
	var shape: CylinderShape3D=CylinderShape3D.new();shape.radius=1.73;shape.height=1.2;_collision("Kiln",shape,Transform3D(Basis.IDENTITY,Vector3(0,.6,0)));_save()

func _storage() -> void:
	_start("halle_tri_minerai","stockage","Halle de tri du minerai","Trois casiers couverts pour séparer minerai brut, préparé et gangue.","À l’arrivée de la mine, avant grillage et concassage.")
	_shed(Vector3.ZERO,7.2,3.6,2.7,1.4)
	for i: int in 3:_bin(Vector3(-2.4+i*2.4,0,-.45),1.9,1.65,"slag" if i==2 else "ore")
	_save()
	_start("depot_charbon","stockage","Réserve de charbon au sec","Hangar ventilé avec deux casiers de charbon et sacs sous toiture.","Cour de production ; réserver une séparation avec les foyers ouverts.")
	_shed(Vector3.ZERO,5.4,3.9,2.55,1.0,true,"roof")
	_bin(Vector3(-1.25,0,-.5),2.0,2.2,"charcoal");_bin(Vector3(1.2,0,-.5),1.9,2.2,"charcoal")
	_sacks(Vector3(1.8,0,1.25));_save()
	_start("depot_barres","stockage","Dépôt de barres de fer","Halle avec râteliers et lots de barres prêts à être chargés.","Entre la forge de finition et l’aire des charrettes.")
	_shed(Vector3.ZERO,5.7,4.6,2.7,1.3)
	for x: float in [-1.6,1.6]:
		_bars(Vector3(x,0,-.2),2.7,4)
		for z: float in [-1.2,1.1]:
			for side: float in [-.52,.52]:_beam("RackPost",Vector3(x+side,0,z),Vector3(x+side,1.55,z),.14)
		var shape: BoxShape3D=BoxShape3D.new();shape.size=Vector3(1.2,1.5,2.75)
		_collision("LoadedBarRack",shape,Transform3D(Basis.IDENTITY,Vector3(x,.75,-.05)))
		_box("RackShelf",Vector3(1.2,.12,2.65),Vector3(x,1.15,-.05),"wood")
		_bars(Vector3(x,1.20,-.05),2.45,2)
	_save()
	_start("hangar_charrettes","stockage","Hangar à charrettes","Grand abri traversant pour chargement, entretien et rangement.","Connexion à la route de la mine ; conserver une voie traversante.")
	_shed(Vector3.ZERO,6.8,5.2,3.0,1.4,false);_crate(Vector3(2.35,0,-1.65));_barrel(Vector3(2.3,0,1.35));_save()
	_start("bureau_pesee","stockage","Bureau de pesée et des stocks","Comptoir couvert, balance et réserve fermée pour compter les livraisons.","À l’entrée de la cour industrielle.")
	_room(Vector3(0,0,-.7),4.0,3.1,2.65,"rust_roof")
	_shed(Vector3(0,0,1.55),4.05,1.25,2.20,.65,false,"rust_roof",.45)
	_box("Counter",Vector3(1.25,.12,.8),Vector3(-1.10,.95,1.75),"wood",Vector3.ZERO,true)
	for x: float in [-1.60,-.60]:
		for z: float in [1.46,2.04]:_beam("CounterLegs",Vector3(x,0,z),Vector3(x,.91,z),.12,"dark_wood",true)
	_box("CounterShelf",Vector3(1.15,.10,.65),Vector3(-1.10,.25,1.75),"wood")
	model_transform=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*.8),Vector3(-1.10,1.01,1.75))
	_balance(Vector3.ZERO);model_transform=Transform3D.IDENTITY;_crate(Vector3(1.25,0,2.0),.72);_save()
	_mine_entrance()
	_start("portique_treuil_mine","stockage","Portique et treuil de mine","Cadre en bois, tambour manuel, corde et palan pour les charges.","Devant une entrée de mine existante ; le centre reste libre.")
	for x: float in [-1.7,1.7]:
		_beam("MinePosts",Vector3(x,0,0),Vector3(x,2.7,0),.29,"wood",true)
		_beam("MineBraces",Vector3(x,1.65,0),Vector3(x-signf(x)*.7,2.7,0),.17)
	_box("MineLintel",Vector3(3.85,.30,.35),Vector3(0,2.75,0),"wood",Vector3.ZERO,true)
	_ring("Pulley",Vector3(.3,2.53,.05),.23,.10,.18,"wood",Vector3(PI*.5,0,0))
	_beam("HangingRope",Vector3(.3,2.55,.17),Vector3(.3,.48,.17),.033,"rope")
	_ring("LoadHook",Vector3(.3,.42,.17),.10,.065,.04,"iron",Vector3(PI*.5,0,0))
	_beam("WinchRope",Vector3(2.4,.96,.50),Vector3(.3,2.53,.05),.033,"rope")
	_cylinder("WinchDrum",Vector3(2.4,.75,.5),.27,.9,"wood",.27,Vector3(0,0,PI*.5),true)
	for x: float in [1.88,2.94]:_beam("WinchFrame",Vector3(x,0,.5),Vector3(x,1.05,.5),.16)
	_beam("WinchCrank",Vector3(3.0,.75,.5),Vector3(3.0,1.15,.5),.06,"iron")
	_beam("WinchHandle",Vector3(3.0,1.15,.5),Vector3(3.25,1.15,.5),.08);_save()
	for cargo: String in ["ore","bars"]:
		_start("charrette_"+cargo,"stockage","Charrette de minerai" if cargo=="ore" else "Charrette de barres","Transport à roues en bois, sans rail, avec chargement adapté.","Chemins entre mine, ateliers et dépôt ; timons vers +Z.")
		_cart(cargo);_save()

func _mine_entrance() -> void:
	_start("entree_mine_roche","stockage","Entrée de mine dans la roche","Bouche de galerie boisée avec trois cadres de soutènement et un court tunnel sombre.","À encastrer dans le flanc de montagne ; fond fermé, intérieur de mine à construire séparément.")
	var outside: Array[Vector3]=[]
	var inside: Array[Vector3]=[]
	for i: int in 11:
		var angle: float=PI*i/10.0
		outside.append(Vector3(cos(angle)*rng.randf_range(3.15,3.55),1.4+sin(angle)*rng.randf_range(2.45,3.05),rng.randf_range(-.20,.15)))
		inside.append(Vector3(cos(angle)*1.58,1.4+sin(angle)*1.65,.08))
	var st: SurfaceTool=_surface("MineRock","rock")
	for i: int in 10:
		var v: Array[Vector3]=[inside[i],inside[i+1],outside[i+1],outside[i]]
		for j: int in 4:v.append(Vector3(v[j].x,v[j].y,-2.9))
		for face: Array in [[0,1,2,3],[4,7,6,5],[0,4,5,1],[3,2,6,7]]:
			var tone: float=rng.randf_range(.74,1.12)
			_tri(st,v[face[0]],v[face[1]],v[face[2]],tone);_tri(st,v[face[0]],v[face[2]],v[face[3]],tone)
		var shape: ConvexPolygonShape3D=ConvexPolygonShape3D.new();shape.points=PackedVector3Array(v)
		_collision("ArchRock",shape,Transform3D.IDENTITY)
	for side: float in [-1.0,1.0]:
		_box("RockPiers",Vector3(1.7,1.4,3.05),Vector3(side*2.43,.70,-1.42),"rock",Vector3.ZERO,true)
		for i: int in 5:_stone("Scree",Vector3(side*rng.randf_range(2.0,3.4),.24,rng.randf_range(.04,.55)),Vector3(.9,.55,.80),"rock")
	for z: float in [.25,-1.25,-2.6]:
		for x: float in [-1.31,1.31]:
			_beam("TunnelPosts",Vector3(x,0,z),Vector3(x,2.48,z),.23,"wood",true)
			_beam("TunnelBraces",Vector3(x,1.86,z),Vector3(x-signf(x)*.48,2.48,z),.12)
		_box("TunnelHeader",Vector3(2.98,.25,.30),Vector3(0,2.53,z),"wood",Vector3.ZERO,true)
	_box("TunnelShadow",Vector3(3.2,3.05,.12),Vector3(0,1.525,-3.0),"dark",Vector3.ZERO,true)
	_box("TunnelFloor",Vector3(3.2,.06,3.35),Vector3(0,.005,-1.35),"slag")
	_marker("Approach",Vector3(0,0,2.2));_marker("TunnelEnd",Vector3(0,0,-2.5));_save()

func _cart(cargo: String) -> void:
	_box("CartBed",Vector3(1.25,.13,1.85),Vector3(0,.78,0),"wood",Vector3.ZERO,true)
	for x: float in [-.68,.68]:
		for row: int in 3:_box("CartSides",Vector3(.08,.17,1.95),Vector3(x,.95+row*.19,0),"wood")
		_beam("Shaft",Vector3(x*.75,.76,.5),Vector3(x*.65,.64,3.05),.10)
		for z: float in [-.88,.88]:_beam("CartCorner",Vector3(x,.78,z),Vector3(x,1.52,z),.09)
	for z: float in [-.92,.92]:
		for row: int in 3:_box("CartEnd",Vector3(1.36,.17,.08),Vector3(0,.95+row*.19,z),"wood")
	_beam("ParkingProp",Vector3(0,.025,1.35),Vector3(0,.76,.78),.10,"wood")
	_beam("Axle",Vector3(-1,.58,0),Vector3(1,.58,0),.10,"iron")
	for x: float in [-.87,.87]:
		_ring("WheelRim",Vector3(x,.58,0),.56,.46,.13,"dark_wood",Vector3(0,0,PI*.5))
		_ring("IronTire",Vector3(x,.58,0),.576,.553,.135,"iron",Vector3(0,0,PI*.5))
		for i: int in 8:
			var a: float=TAU*i/8.0
			_beam("WheelSpokes",Vector3(x,.58,0),Vector3(x,.58+sin(a)*.50,cos(a)*.50),.06)
		_cylinder("WheelHub",Vector3(x,.58,0),.13,.23,"wood",.11,Vector3(0,0,PI*.5))
	if cargo=="ore":_pile(Vector3(0,.84,0),Vector2(1.07,1.65),"ore",50,.62)
	else:_bars(Vector3(0,.84,0),1.65,4)
	_marker("Hitch",Vector3(0,.65,3.0))

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

func _tool_rack(at: Vector3) -> void:
	for x: float in [-.75,.75]:_beam("RackLegs",at+Vector3(x,0,0),at+Vector3(x,1.5,0),.12)
	for y: float in [.35,1.15]:_box("RackRail",Vector3(1.7,.11,.16),at+Vector3(0,y,0),"wood")
	for i: int in 5:
		var x: float=-.64+i*.32
		_beam("Handles",at+Vector3(x,.10,.19),at+Vector3(x,1.53,.12),.041)
		if i%2==0:
			_beam("PickHead",at+Vector3(x-.24,1.4,.12),at+Vector3(x,1.52,.12),.055,"metal")
			_beam("PickHead",at+Vector3(x,1.52,.12),at+Vector3(x+.24,1.4,.12),.055,"metal")
		else:
			_box("SpadeBlade",Vector3(.23,.31,.04),at+Vector3(x,.22,.2),"metal",Vector3(.10,0,0))
	var shape: BoxShape3D=BoxShape3D.new();shape.size=Vector3(1.8,1.55,.32)
	_collision("Rack",shape,Transform3D(Basis.IDENTITY,at+Vector3(0,.77,.10)))

func _balance(at: Vector3) -> void:
	_box("ScalesBase",Vector3(.45,.06,.3),at+Vector3(0,.03,0),"metal")
	_beam("ScalesStand",at,at+Vector3(0,.8,0),.055,"iron")
	_beam("ScalesArm",at+Vector3(-.50,.74,0),at+Vector3(.5,.80,0),.045,"iron")
	for x: float in [-.46,.46]:
		for z: float in [-.15,.15]:_beam("PanChains",at+Vector3(x,.76,0),at+Vector3(x,.28,z),.014,"iron")
		_cylinder("WeighingPans",at+Vector3(x,.28,0),.20,.055,"metal",.24)

func _oven(at: Vector3) -> void:
	_box("OvenPlinth",Vector3(1.7,.45,1.7),at+Vector3(0,.225,0),"stone",Vector3.ZERO,true)
	# Omit the lower front sector so the mouth opens into the oven's dark cavity.
	var dome: SurfaceTool=_surface("BreadOvenDome","clay")
	for row: int in 8:
		var a: float=row*PI/16.0;var b: float=(row+1)*PI/16.0
		for col: int in 24:
			if row<3 and (col<2 or col>=22):continue
			var c: float=col*TAU/24.0;var d: float=(col+1)*TAU/24.0
			var p: Vector3=at+Vector3(sin(c)*cos(a)*.84,.46+sin(a)*.90,cos(c)*cos(a)*.84)
			var q: Vector3=at+Vector3(sin(d)*cos(a)*.84,.46+sin(a)*.90,cos(d)*cos(a)*.84)
			var r: Vector3=at+Vector3(sin(c)*cos(b)*.84,.46+sin(b)*.90,cos(c)*cos(b)*.84)
			var s: Vector3=at+Vector3(sin(d)*cos(b)*.84,.46+sin(b)*.90,cos(d)*cos(b)*.84)
			_tri(dome,p,r,q,.91);_tri(dome,q,r,s,.91)
	_box("OvenInterior",Vector3(.67,.48,.04),at+Vector3(0,.70,.35),"soot")
	_box("OvenFloor",Vector3(.68,.04,.65),at+Vector3(0,.48,.64),"soot")
	for x: float in [-.36,.36]:_box("MouthJambs",Vector3(.16,.33,.42),at+Vector3(x,.63,.78),"clay")
	for i: int in 9:
		var a: float=i*PI/8.0
		_box("MouthArch",Vector3(.16,.16,.42),at+Vector3(cos(a)*.34,.76+sin(a)*.25,.78),"clay",Vector3(0,0,a))
	_box("OvenShelf",Vector3(.86,.10,.45),at+Vector3(0,.48,.93),"stone")
	_cylinder("OvenFlue",at+Vector3(0,1.47,-.38),.18,.87,"clay",.17)
	_ring("FlueLip",at+Vector3(0,1.93,-.38),.22,.13,.10,"soot")
	_marker("OvenAccess",at+Vector3(0,0,1.6))

func _town() -> void:
	(load("res://tools/ironworks_building_designs.gd") as GDScript).new().build_housing(self)
	_start("cuisine_commune","village","Cuisine commune et four à pain","Salle commune, auvent de repas, four maçonné et réserve de tonneaux.","Côté logements, à proximité d’une réserve d’eau propre.")
	_room(Vector3(-.5,0,-.6),5.8,4.0,2.8,"roof")
	_shed(Vector3(0,0,2.2),5.8,1.5,2.30,.6,false,"roof",.50)
	_bench(Vector3(1.60,0,2.25),false);_oven(Vector3(3.3,0,-.7))
	_barrel(Vector3(-3.1,0,1.95),.8);_barrel(Vector3(-3.1,0,2.65),.75);_save()
	_start("grenier_vivres","village","Grenier à vivres sur plots","Réserve surélevée pour céréales et provisions de la communauté.","Cour sèche près de la cuisine, distincte des stocks miniers.")
	for x: float in [-1.8,1.8]:
		for z: float in [-1.35,1.35]:
			_cylinder("GranaryStaddle",Vector3(x,.30,z),.22,.6,"stone",.16,Vector3.ZERO,true)
			_cylinder("GranaryCap",Vector3(x,.63,z),.40,.15,"stone",.31)
	_room(Vector3(0,.7,0),3.9,3.0,2.1,"rust_roof",true)
	for i: int in 5:_box("GranarySteps",Vector3(1.2,.12,.38),Vector3(0,.11+i*.175,3.20-i*.34),"wood")
	for x: float in [-.49,.49]:_beam("GranaryStringers",Vector3(x,.04,3.37),Vector3(x,.79,1.7),.14,"dark_wood")
	# The granary ascends toward -Z; a smooth collider follows its visible treads.
	var ramp: ConvexPolygonShape3D=ConvexPolygonShape3D.new();var vertices: PackedVector3Array=[]
	for x: float in [-.60,.60]:
		for p: Vector2 in [Vector2(3.42,-.10),Vector2(3.42,.02),Vector2(1.65,.92),Vector2(1.65,.78)]:vertices.append(Vector3(x,p.y,p.x))
	ramp.points=vertices;_collision("GranaryAccessRamp",ramp,Transform3D.IDENTITY)
	_save()
	_start("remise_ecurie","village","Remise et écurie","Abri ouvert avec mangeoires, séparations de stalles et réserve de foin.","À la sortie du quartier logistique ; animaux à ajouter séparément.")
	_shed(Vector3.ZERO,6.2,4.2,2.65,1.3)
	for x: float in [-1.05,1.05]:_boarding(Vector3(x,0,-.45),2.9,1.35,PI*.5)
	for x: float in [-2.05,0,2.05]:
		_box("Manger",Vector3(1.45,.52,.65),Vector3(x,.4,-1.7),"wood",Vector3.ZERO,true)
		for side: float in [-.50,.50]:_box("MangerFeet",Vector3(.14,.22,.45),Vector3(x+side,.11,-1.7),"wood")
		_hay(Vector3(x,.65,-1.7),1.2,.42)
	_save()
	_start("latrines_bois","village","Latrines en bois","Petit édicule ventilé, posé sur une base de pierre.","À l’écart du puits et des cuisines ; position à définir avec le terrain.")
	_room(Vector3.ZERO,1.65,1.75,1.95,"rust_roof",true)
	_cylinder("Vent",Vector3(0,1.70,.91),.115,.025,"dark",.115,Vector3(PI*.5,0,0));_save()
	_start("puits_abreuvoir","village","Puits maçonné et treuil","Margelle carrée en pierre sombre, treuil manuel et auge massive.","Point d’eau du quartier de vie ; éviter les déchets métallurgiques.")
	for x: float in [-1.25,.25]:_box("WellSide",Vector3(.25,.90,1.70),Vector3(x,.45,0),"stone",Vector3.ZERO,true)
	for z: float in [-.73,.73]:_box("WellEnds",Vector3(1.35,.90,.25),Vector3(-.5,.45,z),"stone",Vector3.ZERO,true)
	_box("WellDarkWater",Vector3(1.21,.025,1.18),Vector3(-.5,.17,0),"dark")
	for x: float in [-1.22,.22]:_beam("WellWinchPosts",Vector3(x,.86,0),Vector3(x,1.85,0),.16,"dark_wood")
	_cylinder("WellDrum",Vector3(-.5,1.73,0),.13,1.64,"wood",.13,Vector3(0,0,PI*.5))
	_beam("WellCrank",Vector3(.45,1.73,0),Vector3(.45,1.39,0),.055,"iron")
	_beam("WellCrankHandle",Vector3(.45,1.39,0),Vector3(.69,1.39,0),.07)
	_beam("WellRope",Vector3(-.5,1.7,.12),Vector3(-.5,.23,.12),.025,"rope")
	_trough(Vector3(1.45,0,.3),1.65,.78)
	_cylinder("Bucket",Vector3(.3,.22,1.25),.23,.42,"wood",.28)
	_cylinder("BucketInterior",Vector3(.3,.433,1.25),.245,.01,"dark",.245)
	_ring("BucketRim",Vector3(.3,.44,1.25),.29,.25,.05,"iron");_save()

func _logs(at: Vector3,width: float=1.8,length: float=2.0) -> void:
	var columns: int=ceili(width/.28)
	for row: int in 3:
		for col: int in columns-row:
			var p: Vector3=at+Vector3(-width*.5+.14+col*.28+row*.14,.14+row*.235,0)
			_cylinder("CordwoodBark",p,.125,length,"dark_wood",.12,Vector3(PI*.5,0,0))
			_cylinder("CutEnds",p+Vector3(0,0,length*.5+.009),.107,.015,"wood",.104,Vector3(PI*.5,0,0))

func _props() -> void:
	for spec: Array in [["tas_minerai","Minerai brut","ore"],["tas_charbon","Charbon de bois","charcoal"],["tas_scories","Scories refroidies","slag"]]:
		_start(spec[0],"accessoires",spec[1],"Tas distinct par matière et couleur, modulable par répétition et rotation.","Minerai près du tri, charbon au sec, scories en aire de rebut séparée.")
		_pile(Vector3.ZERO,Vector2(2.5,2.0),spec[2],90,.9);_save()
	_start("loupe_fer_brute","accessoires","Loupe brute sur dalle","Masse spongieuse de fer avant consolidation, différente d’un lingot coulé.","Entre extraction au fourneau et martelage.")
	_box("BloomSlab",Vector3(.85,.10,.75),Vector3(0,.05,0),"stone")
	_stone("BloomCore",Vector3(0,.21,0),Vector3(.49,.31,.43),"metal")
	for i: int in 16:_stone("RawBloom",Vector3(rng.randf_range(-.20,.20),rng.randf_range(.13,.28),rng.randf_range(-.17,.17)),Vector3(.27,.21,.23),"metal")
	_save()
	_start("barres_fer_liees","accessoires","Lot de barres de fer","Barres forgées regroupées sur traverses de bois.","Dépôts, quais de chargement et ateliers de finition.")
	_bars(Vector3.ZERO);_save()
	_start("bacs_minerai","accessoires","Bac à minerai","Casier ouvert avec renforts et chargement de minerai.","À combiner dans les zones de tri et les dépôts.")
	_bin(Vector3.ZERO,1.65,1.3);_save()
	_start("billot_enclume","accessoires","Enclume sur billot","Enclume à corne, talon, trou carré et petit marteau.","Prévoir la place du forgeron sur les côtés.")
	_anvil(Vector3.ZERO);_save()
	_start("etabli_outils","accessoires","Établi et outils de forge","Table de travail renforcée avec outils et étau.","Sous un auvent de finition ou dans une remise.")
	_bench(Vector3.ZERO);_save()
	_start("cuve_trempe","accessoires","Cuve d’eau de forge","Auge maçonnée pour refroidissement et travail de forge.","Près du foyer ; indépendante du puits domestique.")
	_trough(Vector3.ZERO,1.35,.84);_save()
	_start("outils_mine","accessoires","Râtelier d’outils de mine","Pioches, pelles et rangement à la hauteur du personnage.","Mine, remise d’entretien et cour de préparation.")
	_tool_rack(Vector3.ZERO);_save()
	_start("sacs_reserve","accessoires","Sacs de réserve","Trois sacs en toile serrés au col par une corde.","À utiliser sous abri pour vivres ou approvisionnements secs.")
	_sacks(Vector3(-.25,0,-.25));_save()
	_start("buches_rangees","accessoires","Réserve de bûches","Bois coupé avec extrémités claires et écorce sombre.","Charbonnière, cuisine, four à pain et préparation du minerai.")
	_logs(Vector3.ZERO);_save()
	_start("balance_plateaux","accessoires","Balance à plateaux","Balance de comptoir à deux plateaux suspendus.","À poser sur un comptoir ; pivot à la base.")
	_balance(Vector3.ZERO);_save()
	_start("meule_manivelle","accessoires","Meule d’affûtage à manivelle","Roue abrasive montée sur un bâti en bois avec axe et manivelle.","Atelier d’entretien des outils, à l’abri.")
	for x: float in [-.55,.55]:
		for z: float in [-.35,.35]:_beam("GrinderLegs",Vector3(x,0,z),Vector3(x*.85,.83,z*.65),.10)
	for x: float in [-.49,.49]:
		_beam("GrinderCrossMembers",Vector3(x,.78,-.30),Vector3(x,.78,.30),.12,"wood")
		_box("AxleBearings",Vector3(.16,.15,.19),Vector3(x,.86,0),"iron")
	for z: float in [-.29,.29]:_beam("GrinderBraces",Vector3(-.52,.33,z),Vector3(.52,.33,z),.085,"wood")
	_cylinder("Grindstone",Vector3(0,.86,0),.49,.25,"stone",.49,Vector3(0,0,PI*.5),true)
	_beam("GrindingAxle",Vector3(-.67,.86,0),Vector3(.67,.86,0),.055,"iron")
	_beam("Crank",Vector3(.68,.86,0),Vector3(.68,1.12,.13),.045,"iron")
	_beam("CrankGrip",Vector3(.68,1.12,.13),Vector3(.90,1.12,.13),.07);_save()
	_start("tuyeres_argile","accessoires","Tuyères et argile de réparation","Tuyères de rechange et argile rangées sur une table basse.","Réserve technique pour entretenir les bas fourneaux.")
	_box("DryingTable",Vector3(1.25,.12,.8),Vector3(0,.32,0),"wood",Vector3.ZERO,true)
	for x: float in [-.47,.47]:_box("DryingFeet",Vector3(.12,.26,.65),Vector3(x,.13,0),"wood")
	for i: int in 4:_ring("SpareTuyeres",Vector3(-.42+i*.27,.50,0),.11,.05,.45,"clay",Vector3(PI*.5,0,0))
	_save()

func _modules() -> void:
	_start("soubassement_2m","modules","Mur bas en pierre · 2 m","Module de soubassement et de séparation de cour.","Extrémités à X = ±1 m ; dupliquer pour prolonger.")
	for row: int in 3:
		for i: int in 4:_box("StoneCourses",Vector3(.48,.22,.40),Vector3(-.75+i*.5,.11+row*.23,0),"stone",Vector3.ZERO,true)
	_marker("ConnectLeft",Vector3(-1,0,0));_marker("ConnectRight",Vector3(1,0,0));_save()
	_start("cloture_2m","modules","Clôture rustique · 2 m","Barrière de bois pour limites de cour et petites enclos.","Extrémités à X = ±1 m, hauteur environ 1,1 m.")
	for x: float in [-1,1]:_beam("Posts",Vector3(x,0,0),Vector3(x,1.15,0),.13,"wood",true)
	for y: float in [.38,.86]:_beam("Rails",Vector3(-1,y,0),Vector3(1,y,0),.11,"wood",true)
	_marker("ConnectLeft",Vector3(-1,0,0));_marker("ConnectRight",Vector3(1,0,0));_save()
	_start("portail_cour","modules","Portail de cour ouvert","Deux battants ouverts avec ferrures et poteaux.","Passage central de 2,6 m pour charrettes et piétons.")
	for side: float in [-1.0,1.0]:
		_beam("GatePosts",Vector3(side*1.45,0,0),Vector3(side*1.45,1.5,0),.20,"wood",true)
		for y: float in [.4,1.15]:_beam("OpenGateRails",Vector3(side*1.45,y,0),Vector3(side*1.58,y,1.25),.10,"wood",true)
		_beam("GateDiagonal",Vector3(side*1.45,.4,0),Vector3(side*1.58,1.15,1.25),.075)
	_marker("Passage",Vector3.ZERO);_save()
	_start("quai_chargement","modules","Quai de chargement","Plateforme de bois avec rampe praticable et pieds en pierre.","Raccord de cour ou devant un dépôt ; rampe vers +Z.")
	_box("LoadingDeck",Vector3(3.6,.18,2.4),Vector3(0,.67,0),"wood",Vector3.ZERO,true)
	for x: float in [-1.5,1.5]:
		for z: float in [-.9,.9]:_box("DeckPiers",Vector3(.4,.60,.4),Vector3(x,.3,z),"stone",Vector3.ZERO,true)
	_box("LoadingRamp",Vector3(1.65,.12,2.05),Vector3(0,.37,2.05),"wood",Vector3(.32,0,0),true)
	for i: int in 8:_box("RampTreads",Vector3(1.62,.035,.055),Vector3(0,.69-i*.078,1.2+i*.235),"dark_wood")
	_marker("LoadingEdge",Vector3(0,.75,1.2));_save()
	_start("enseigne_forge","modules","Enseigne de la forge","Potence en bois et emblème d’enclume en fer forgé.","À l’entrée d’une cour ou d’un atelier, façade vers +Z.")
	_beam("SignPost",Vector3(-.75,0,0),Vector3(-.75,2.45,0),.15,"wood",true)
	_beam("SignBracket",Vector3(-.85,2.37,0),Vector3(.72,2.37,0),.12)
	_beam("SignBrace",Vector3(-.75,1.75,0),Vector3(-.05,2.37,0),.09)
	for x: float in [-.25,.38]:_beam("SignChains",Vector3(x,2.37,0),Vector3(x,2.05,0),.02,"iron")
	_box("SignBoard",Vector3(1.05,.65,.08),Vector3(.07,1.77,0),"wood")
	_box("AnvilSymbol",Vector3(.57,.13,.05),Vector3(.06,1.89,.07),"metal")
	_box("AnvilSymbol",Vector3(.23,.20,.05),Vector3(.06,1.75,.07),"metal")
	_box("AnvilSymbol",Vector3(.40,.07,.05),Vector3(.06,1.62,.07),"metal");_save()
	_start("rigole_pierre_2m","modules","Rigole en pierre · 2 m","Petit canal ouvert pour aménager les cours et évacuer l’eau.","Module vide à poser suivant une pente ; ne remplace pas le réseau de rivières.")
	_box("DrainBed",Vector3(.6,.09,2.0),Vector3(0,.045,0),"stone",Vector3.ZERO,true)
	for x: float in [-.30,.30]:_box("DrainSides",Vector3(.12,.24,2.0),Vector3(x,.12,0),"stone")
	_marker("ConnectStart",Vector3(0,0,-1));_marker("ConnectEnd",Vector3(0,0,1));_save()

func _build_gallery() -> void:
	var gallery: Node3D=Node3D.new();gallery.name="CatalogueAcierie"
	gallery.set_script(load("res://scripts/ironworks_catalog.gd"))
	var assets: Node3D=Node3D.new();assets.name="Assets";gallery.add_child(assets)
	for i: int in catalog.size():
		var obj: Node3D=(load(catalog[i].scene) as PackedScene).instantiate();assets.add_child(obj)
		obj.position=Vector3((i%8)*14,0,(i/8)*14);obj.set_meta("catalog_index",i)
	var demonstration: Node3D=Node3D.new();demonstration.name="Demonstration";gallery.add_child(demonstration)
	var layout: Array=[
		["entree_mine_roche",7,-20,0],["portique_treuil_mine",7,-15.7,0],
		["bas_fourneau_argile",-5,-6,0],["bas_fourneau_actif",0,-6,0],["bas_fourneau_pierre",5,-6,0],
		["grillage_minerai",7,-10,0],["concassage_minerai",10,-5,0],
		["halle_tri_minerai",14,-9,-.18],["depot_charbon",-11,-8,.12],
		["forge_affinage",-6,3,.12],["atelier_outilleur",-14,5,.18],
		["depot_barres",11,4,-.1],["charrette_ore",16,-.5,.7],
		["tas_scories",5,-12,0],["meule_charbonniere",-17,-10,0],
		["logis_porte_basse",-8,15,.18],["maison_aux_deux_volumes",0,17,-.15],
		["cuisine_commune",9,16,-.12],["puits_abreuvoir",1,8,0],
		["enseigne_forge",-2,1,-.05],["barres_fer_liees",8,0,0],
		["quai_chargement",13,8,0],["buches_rangees",-15,-3,0]
	]
	for data: Array in layout:
		for record: Dictionary in catalog:
			if record.id!=data[0]:continue
			var obj: Node3D=(load(record.scene) as PackedScene).instantiate();demonstration.add_child(obj)
			obj.position=Vector3(data[1],0,data[2]);obj.rotation.y=data[3];break
	var floor_node: MeshInstance3D=MeshInstance3D.new();floor_node.name="Ground"
	var plane: PlaneMesh=PlaneMesh.new();plane.size=Vector2(260,220);floor_node.mesh=plane;floor_node.position=Vector3(35,-.07,25)
	var mat: StandardMaterial3D=StandardMaterial3D.new();mat.albedo_color=Color("666963");mat.roughness=1.0
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
	assert(ResourceSaver.save(packed,"res://scenes/catalogue_acierie.tscn")==OK)
	gallery.free()

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
