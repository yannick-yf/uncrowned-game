extends SceneTree
## Offline native coastal granite kit. Writes only assets/coastline.
const OUT: String="res://assets/coastline/"
const GRANITE_SHADER: String="res://shaders/coastal_rock_surface.gdshader"
var material: ShaderMaterial
var catalog: Array[Dictionary]=[]
var triangles: Array[Vector3]=[]
var normals: Array[Vector3]=[]
var tones: Array[Color]=[]
var hulls: Array[PackedVector3Array]=[]
var rng: RandomNumberGenerator=RandomNumberGenerator.new()
var item_id: String
var item_label: String

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	for folder: String in ["meshes","materials","rocks"]:DirAccess.make_dir_recursive_absolute(OUT+folder)
	assert(ResourceLoader.exists(GRANITE_SHADER),"Coastal granite shader must be available before building the kit")
	material=ShaderMaterial.new();material.shader=load(GRANITE_SHADER)
	# The shared coastal shader supplies the painted granite palette and scale.
	material.set_shader_parameter("painted_texture",load("res://assets/brindle/painted_cliff.png"))
	material.set_shader_parameter("painted_scale",.035)
	material.set_shader_parameter("wet_base_enabled",true)
	material.set_shader_parameter("wet_height_m",.65)
	material.set_shader_parameter("wet_darkening",.24)
	material.set_shader_parameter("facet_strength",.45)
	assert(ResourceSaver.save(material,OUT+"materials/coastal_granite.tres")==OK)
	material=load(OUT+"materials/coastal_granite.tres")
	_block();_wedge();_slab();_split();_stack();_pebbles()
	var manifest: Dictionary={"version":1,"units":"metres","origin":"ground centre; minimum mesh Y=0","style":"Painted coastal granite: angular eroded masses, fracture faces, low shore stacks and granite shingle","provenance":"Original native Godot geometry authored for Uncrowned; no downloaded meshes or raster textures.","optimization":"One indexed compressed ArrayMesh and one shared material per asset; direct mesh paths for MultiMesh placement. Optional simple convex colliders in the scenes; pebbles have no collider.","material":OUT+"materials/coastal_granite.tres","assets":catalog}
	var file: FileAccess=FileAccess.open(OUT+"catalog.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"  "));file.close()
	print("COASTAL_ROCK_BUILD_OK assets=",catalog.size())
	quit()

func _begin(id: String,label: String) -> void:
	item_id=id;item_label=label
	triangles.clear();normals.clear();tones.clear();hulls.clear()
	rng.seed=absi(id.hash())+22092026

func _outline() -> PackedVector2Array:
	# Cut corners and long straight edges establish block-like fracture planes.
	return PackedVector2Array([Vector2(-1,-.62),Vector2(-.83,-.94),Vector2(-.31,-1),Vector2(.66,-.95),Vector2(.97,-.66),Vector2(1,-.13),Vector2(.93,.58),Vector2(.56,.93),Vector2(-.20,1),Vector2(-.82,.88),Vector2(-1,.39),Vector2(-.98,-.14)])

func _block() -> void:
	_begin("bloc_granit_erode","Bloc de granite érodé")
	_piece(_outline(),[[0,2.00,1.54,0,0],[.24,2.26,1.74,-.08,.04],[1.15,2.17,1.62,.04,-.05],[2.13,1.81,1.42,.18,-.10],[2.65,1.28,1.13,.06,-.02]],Vector3.ZERO,.09,1.0)
	_save("Bloc large aux épaules coupées, pour les hauts de grève et pieds de falaise.",true)

func _wedge() -> void:
	_begin("bloc_granit_oblique","Bloc de granite oblique")
	_piece(_outline(),[[0,1.62,1.13,0,0],[.18,1.84,1.32,-.06,0],[1.03,1.94,1.30,.12,-.06],[2.53,1.61,1.10,.37,-.20],[3.16,1.03,.81,.63,-.31],[3.47,.57,.64,.83,-.32]],Vector3.ZERO,-.17,.97)
	_save("Fracture inclinée et sommet tronqué ; silhouette haute et dissymétrique.",true)

func _slab() -> void:
	_begin("dalle_granit_etagee","Dalle de granite à gradins")
	_piece(_outline(),[[0,2.62,1.63,0,0],[.20,2.94,1.79,-.04,.02],[.46,2.73,1.65,.08,-.02]],Vector3.ZERO,.05,1.0)
	_piece(_outline(),[[0,2.42,1.49,0,0],[.15,2.61,1.61,.03,0],[.47,2.35,1.43,-.03,.08]],Vector3(.05,.32,.02),-.03,1.03)
	_piece(_outline(),[[0,1.96,1.22,0,0],[.14,2.27,1.37,.03,-.06],[.36,1.97,1.13,-.09,-.02]],Vector3(-.23,.72,-.19),.06,1.06)
	_save("Trois dalles jointées par fractures horizontales, pour un estran bas et rocheux.",true)

func _split() -> void:
	_begin("rocher_granit_fendu","Rocher de granite fendu")
	var left: PackedVector2Array=PackedVector2Array([Vector2(-1,-.66),Vector2(-.63,-1),Vector2(.51,-.94),Vector2(.98,-.47),Vector2(.91,.21),Vector2(.86,.84),Vector2(.12,1),Vector2(-.69,.87),Vector2(-1,.31),Vector2(-1,-.2)])
	var right: PackedVector2Array=PackedVector2Array([Vector2(-.99,-.64),Vector2(-.95,-.14),Vector2(-.87,.81),Vector2(-.22,1),Vector2(.69,.78),Vector2(1,.21),Vector2(.81,-.74),Vector2(.28,-1),Vector2(-.27,-.94),Vector2(-.91,-.88)])
	_piece(left,[[0,1.16,1.66,0,0],[.22,1.23,1.76,0,0],[1.75,1.12,1.67,.05,-.02],[3.53,.74,1.27,.17,-.13]],Vector3(-1.43,0,0),-.03,1.01)
	_piece(right,[[0,1.14,1.50,0,0],[.20,1.26,1.59,0,0],[1.52,1.07,1.48,.05,.03],[2.99,.64,1.04,.09,.12]],Vector3(1.36,0,.07),.025,.94)
	_save("Deux masses réellement séparées par une faille irrégulière, avec deux colliders distincts.",true)

func _stack() -> void:
	_begin("aiguille_maritime","Aiguille maritime de granite")
	_piece(_outline(),[[0,2.04,1.78,0,0],[.38,2.28,1.91,-.08,.04],[1.40,1.92,1.60,.06,.04],[2.65,1.57,1.38,.11,-.05],[4.18,1.66,1.44,.30,-.12],[5.85,1.30,1.20,.53,-.08],[7.52,1.17,.99,.66,-.22],[9.37,.78,.77,.67,-.32],[10.42,.42,.57,.83,-.26]],Vector3.ZERO,-.10,.98)
	_piece(_outline(),[[0,.86,1.13,0,0],[.42,1.01,1.19,.06,0],[1.73,.59,.79,.18,-.09],[2.82,.23,.42,.22,-.12]],Vector3(-1.56,0,.55),-.15,.91)
	_save("Repère littoral élancé avec contrefort détaché et sommet biseauté ; à employer avec parcimonie.",true)

func _pebbles() -> void:
	_begin("amas_galets_granit","Amas de galets de granite")
	var contour: PackedVector2Array=PackedVector2Array([Vector2(-1,-.38),Vector2(-.51,-1),Vector2(.64,-.78),Vector2(1,.24),Vector2(.26,1),Vector2(-.77,.76)])
	var pebbles: Array=[[-.96,.38,.54,.39,.38],[-.25,.70,.61,.45,.46],[.61,.70,.49,.34,.35],[1.10,.05,.47,.36,.40],[.29,-.12,.70,.57,.58],[-.53,-.22,.49,.41,.37],[-1.06,-.56,.35,.29,.26],[.46,-.83,.50,.32,.34]]
	for i: int in pebbles.size():
		var p: Array=pebbles[i];var h: float=p[4]
		_piece(contour,[[0,p[2]*.76,p[3]*.74,0,0],[h*.22,p[2],p[3],0,0],[h*.76,p[2]*.77,p[3]*.72,.025,-.01],[h,p[2]*.35,p[3]*.38,.015,.015]],Vector3(p[0],0,p[1]),i*.72,rng.randf_range(.88,1.07))
	_save("Huit galets anguleux aplatis, réunis dans un seul mesh sans collision pour décorer la grève.",false)

func _piece(outline: PackedVector2Array,profile: Array,origin: Vector3,yaw: float,tone: float) -> void:
	var rotation: Basis=Basis(Vector3.UP,yaw)
	var rings: Array[PackedVector3Array]=[]
	var hull: PackedVector3Array=PackedVector3Array()
	var rough: PackedFloat32Array=PackedFloat32Array()
	for i: int in outline.size():rough.append(rng.randf_range(.975,1.025))
	for ring_index: int in profile.size():
		var layer: Array=profile[ring_index]
		var ring: PackedVector3Array=PackedVector3Array()
		for i: int in outline.size():
			var local: Vector3=Vector3(outline[i].x*float(layer[1])*rough[i]+float(layer[3]),float(layer[0]),outline[i].y*float(layer[2])*rough[i]+float(layer[4]))
			if ring_index>0:local.y+=sin(i*1.47+ring_index*.83)*minf(float(layer[0])*.04,.055)
			var point: Vector3=origin+rotation*local
			ring.append(point);hull.append(point)
		rings.append(ring)
	for level: int in range(rings.size()-1):
		var centre: Vector3=Vector3.ZERO
		for p: Vector3 in rings[level]:centre+=p
		centre/=rings[level].size()
		for i: int in outline.size():
			var next: int=(i+1)%outline.size()
			var a: Vector3=rings[level][i];var c: Vector3=rings[level][next]
			var d: Vector3=rings[level+1][i];var e: Vector3=rings[level+1][next]
			var outward: Vector3=(a+c)*.5-centre;outward.y=0
			var face_tone: float=tone*rng.randf_range(.975,1.025)
			if (i+level)%2==0:
				_face(a,c,e,outward,face_tone);_face(a,e,d,outward,face_tone)
			else:
				_face(a,c,d,outward,face_tone);_face(c,e,d,outward,face_tone)
	for end: int in [0,rings.size()-1]:
		var centre: Vector3=Vector3.ZERO
		for point: Vector3 in rings[end]:centre+=point
		centre/=rings[end].size()
		for i: int in outline.size():_face(centre,rings[end][i],rings[end][(i+1)%outline.size()],Vector3.DOWN if end==0 else Vector3.UP,tone)
	hulls.append(hull)

func _face(a: Vector3,b: Vector3,c: Vector3,outward: Vector3,tone: float) -> void:
	var normal: Vector3=(b-a).cross(c-a).normalized()
	if normal.dot(outward)<0:
		var swap: Vector3=b;b=c;c=swap;normal=-normal
	# Godot uses clockwise front faces; the explicit normal remains outward.
	for point: Vector3 in [a,c,b]:
		triangles.append(point);normals.append(normal);tones.append(Color(tone,tone,tone))

func _save(purpose: String,collide: bool) -> void:
	var surface: SurfaceTool=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in triangles.size():
		surface.set_normal(normals[i]);surface.set_color(tones[i]);surface.set_uv(Vector2(triangles[i].x,triangles[i].z));surface.add_vertex(triangles[i])
	surface.index()
	var mesh: ArrayMesh=surface.commit();mesh.surface_set_material(0,material)
	var count: int=triangles.size()/3
	assert(count<=500,"Coastal mesh exceeds its triangle budget")
	var bounds: AABB=mesh.get_aabb()
	assert(absf(bounds.position.y)<.001,"The asset must touch its ground pivot")
	var mesh_path: String=OUT+"meshes/"+item_id+".res"
	assert(ResourceSaver.save(mesh,mesh_path,ResourceSaver.FLAG_COMPRESS)==OK)
	var item: Node3D=Node3D.new();item.name=item_id.to_pascal_case()
	item.set_meta("asset_id",item_id);item.set_meta("label",item_label)
	item.set_meta("source","Original Uncrowned coastal granite kit")
	item.set_meta("ground_pivot",true);item.set_meta("triangle_count",count)
	var visual: MeshInstance3D=MeshInstance3D.new();visual.name="Granite";visual.mesh=load(mesh_path)
	item.add_child(visual);visual.owner=item
	if collide:
		var body: StaticBody3D=StaticBody3D.new();body.name="RockCollision";body.collision_mask=0
		item.add_child(body);body.owner=item
		for i: int in hulls.size():
			var shape: ConvexPolygonShape3D=ConvexPolygonShape3D.new();shape.points=hulls[i]
			var collider: CollisionShape3D=CollisionShape3D.new();collider.name="Mass"+str(i+1);collider.shape=shape
			body.add_child(collider);collider.owner=item
	var scene_path: String=OUT+"rocks/"+item_id+".tscn"
	var packed: PackedScene=PackedScene.new();assert(packed.pack(item)==OK)
	assert(ResourceSaver.save(packed,scene_path)==OK)
	catalog.append({"id":item_id,"label":item_label,"scene":scene_path,"mesh":mesh_path,"material":OUT+"materials/coastal_granite.tres","triangles":count,"surfaces":1,"mesh_instances":1,"bounds_min_m":[bounds.position.x,bounds.position.y,bounds.position.z],"size_m":[bounds.size.x,bounds.size.y,bounds.size.z],"bounds_center_m":[bounds.get_center().x,bounds.get_center().y,bounds.get_center().z],"collision_shapes":hulls.size() if collide else 0,"purpose":purpose,"ground_pivot":true})
	print("COAST_ROCK ",item_id," triangles=",count," bounds=",bounds)
	item.free()
