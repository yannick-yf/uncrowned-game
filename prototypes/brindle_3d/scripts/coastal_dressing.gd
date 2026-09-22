@tool
extends Node3D
## Deterministic native rock dressing of the existing open west/south coastline.
## Attach to World/CoastlineDecor; only generated children belong to this script.
## Terrain remains authoritative, including seabed support beneath marine stacks.
const PLAN_PATH: String="res://planning/coastline.json"
const META_PATH: String="res://assets/landscape/landscape.json"
const CATALOG_PATH: String="res://assets/coastline/catalog.json"
const GENERATED: StringName=&"generated_coastal_dressing"
const IDS: Array[String]=["bloc_granit_erode","bloc_granit_oblique","dalle_granit_etagee","rocher_granit_fendu","aiguille_maritime","amas_galets_granit"]

var _ground: Node3D
var _plan: Dictionary={}
var _assets: Dictionary={}
var _coast: PackedVector2Array=PackedVector2Array()
var _lengths: PackedFloat32Array=PackedFloat32Array()
var _routes: Array[Dictionary]=[]
var _placements: Array[Dictionary]=[]
var _pending: bool=false
var _sea: float=0.0
var _rng: RandomNumberGenerator=RandomNumberGenerator.new()
var _rejections: Dictionary={}
var _stack_count: int=0

func _ready() -> void:
	_ground=get_node_or_null("../Terrain")
	if _ground==null:return
	if _ground.has_signal("rebuilt") and not _ground.is_connected("rebuilt",_request_rebuild):
		_ground.connect("rebuilt",_request_rebuild)
	_request_rebuild()

func _request_rebuild() -> void:
	if _pending or not is_inside_tree():return
	_pending=true;call_deferred("rebuild")

func rebuild() -> void:
	_pending=false
	if not is_inside_tree() or not is_instance_valid(_ground):return
	var start: int=Time.get_ticks_usec()
	for child: Node in get_children():
		if child.has_meta(GENERATED):remove_child(child);child.queue_free()
	_placements.clear();_assets.clear();_routes.clear();_coast.clear();_lengths.clear();_rejections.clear();_stack_count=0
	for key: String in ["coast_rock_instances","coast_rock_batches","coast_rock_tris","coast_rock_colliders"]:set_meta(key,0)
	if _ground.get("coastline_enabled")==false:return
	if not FileAccess.file_exists(PLAN_PATH) or not FileAccess.file_exists(CATALOG_PATH):return
	_plan=JSON.parse_string(FileAccess.get_file_as_string(PLAN_PATH))
	var landscape: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(META_PATH))
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	for row: Dictionary in catalog.assets:
		var mesh: Mesh=load(row.mesh)
		var footprint: PackedVector3Array=PackedVector3Array()
		var silhouette: PackedVector3Array=PackedVector3Array()
		var seen: Dictionary={}
		for surface: int in mesh.get_surface_count():
			var arrays: Array=mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			silhouette.append_array(vertices)
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			if indices.is_empty():
				for i: int in vertices.size():indices.append(i)
			# Sample the complete bottom faces so concave terrain cannot leave their interiors floating.
			for i: int in range(0,indices.size(),3):
				var a: Vector3=vertices[indices[i]]
				var b: Vector3=vertices[indices[i+1]]
				var c: Vector3=vertices[indices[i+2]]
				if absf(a.y)>.01 or absf(b.y)>.01 or absf(c.y)>.01:continue
				for point: Vector3 in PackedVector3Array([a,b,c,(a+b)*.5,(b+c)*.5,(c+a)*.5,(a+b+c)/3.0]):
					var key: Vector3=point.snapped(Vector3.ONE*.001)
					if not seen.has(key):seen[key]=true;footprint.append(point)
		_assets[str(row.id)]={"mesh":mesh,"scene":row.scene,"triangles":int(row.triangles),"bounds":mesh.get_aabb(),"footprint":footprint,"vertices":silhouette,"hulls":_collision_hulls(str(row.scene))}
	var distance: float=0.0
	for value: Array in landscape.get("coastline_xz",[]):
		var point: Vector2=Vector2(value[0],value[1])
		if not _coast.is_empty():distance+=point.distance_to(_coast[-1])
		_coast.append(point);_lengths.append(distance)
	if _coast.size()<2:return
	_sea=float(_plan.get("sea_level_m",0.0));_rng.seed=int(_plan.get("seed",64217))+70631
	_load_protection()
	var maximum: int=clampi(int(_plan.get("rock_budget",{}).get("maximum_instances",1000)),1,1000)
	var along: float=7.0
	while along<distance-7.0 and _placements.size()<maximum:
		var shore: Dictionary=_shore_at(along)
		var cove_sand: float=_sand_at(along)
		var count: int=_rng.randi_range(5,8)
		# Sandier coves retain open pockets; their flanking rock packs continue.
		if cove_sand>.65:count=_rng.randi_range(2,4)
		for i: int in count:
			var choice: float=_rng.randf()
			var id: String=IDS[0] if choice<.30 else IDS[1] if choice<.52 else IDS[2] if choice<.74 else IDS[3] if choice<.86 else IDS[5]
			var shift: float=_rng.randf_range(-5.5,5.5)
			var lateral: float=_rng.randf_range(-6.0,4.0)
			if id==IDS[5]:lateral=_rng.randf_range(0.0,4.5)
			var point: Vector2=shore.point+shore.tangent*shift+shore.inland*lateral
			var size: float=_rng.randf_range(.42,1.45) if id!=IDS[5] else _rng.randf_range(.65,1.6)
			if i==0 and cove_sand<.55:size=_rng.randf_range(1.7,2.75)
			_try_place(id,point,along+shift,Vector3(size*_rng.randf_range(.87,1.15),size*_rng.randf_range(.88,1.14),size),"foot",maximum)
		if _rng.randf()<.64 and cove_sand<.55:
			var point: Vector2=shore.point+shore.inland*_rng.randf_range(4.5,9.0)
			var size: float=_rng.randf_range(.75,1.65)
			_try_place(IDS[2],point,along,Vector3(size,size*_rng.randf_range(1.1,1.75),size),"face",maximum)
		if _rng.randf()<.43 and cove_sand<.55:
			var point: Vector2=shore.point+shore.inland*_rng.randf_range(11.5,15.0)
			var size: float=_rng.randf_range(.40,.82)
			_try_place(IDS[0] if _rng.randf()<.5 else IDS[1],point,along,Vector3.ONE*size,"land",maximum)
		if _stack_count<14 and _rng.randf()<.16 and cove_sand<.30:
			var point: Vector2=shore.point-shore.inland*_rng.randf_range(3.0,7.0)
			var size: float=_rng.randf_range(.95,1.65)
			if _try_place(IDS[4],point,along,Vector3(size,size*_rng.randf_range(1.05,1.30),size),"stack",maximum):_stack_count+=1
		along+=_rng.randf_range(8.0,12.0)
	_build_batches()
	_build_collisions()
	_build_ocean_backdrop()
	set_meta("coast_rock_instances",_placements.size())
	set_meta("coast_rock_stacks",_stack_count)
	set_meta("coast_rock_rejections",_rejections)
	set_meta("coast_rock_rebuild_ms",(Time.get_ticks_usec()-start)/1000.0)
	print("COAST_DRESSING_READY instances=",_placements.size()," batches=",get_meta("coast_rock_batches")," tris=",get_meta("coast_rock_tris")," colliders=",get_meta("coast_rock_colliders")," rebuild_ms=",get_meta("coast_rock_rebuild_ms"))

func _shore_at(distance: float) -> Dictionary:
	distance=clampf(distance,0.0,_lengths[-1])
	for i: int in range(1,_coast.size()):
		if _lengths[i]<distance:continue
		var tangent: Vector2=(_coast[i]-_coast[i-1]).normalized()
		return {"point":_coast[i-1].lerp(_coast[i],(distance-_lengths[i-1])/maxf(.001,_lengths[i]-_lengths[i-1])),"tangent":tangent,"inland":Vector2(tangent.y,-tangent.x)}
	return {}

func _signed_coast(point: Vector2) -> float:
	var best: float=INF;var signed_distance: float=INF
	for i: int in range(1,_coast.size()):
		var near: Vector2=Geometry2D.get_closest_point_to_segment(point,_coast[i-1],_coast[i])
		var distance: float=point.distance_squared_to(near)
		if distance<best:
			best=distance
			var tangent: Vector2=(_coast[i]-_coast[i-1]).normalized()
			signed_distance=(point-near).dot(Vector2(tangent.y,-tangent.x))
	return signed_distance

func _sand_at(along: float) -> float:
	var sand: float=0.0
	for cove: Dictionary in _plan.get("coves",[]):
		var radius: float=float(cove.get("radius_m",1.0))
		sand=maxf(sand,float(cove.get("sand",0.0))*(1.0-smoothstep(radius*.35,radius,absf(along-float(cove.get("along_m",-10000))))))
	return sand

func _add_route(points: Array,clearance: float,kind: String) -> void:
	var line: PackedVector2Array=PackedVector2Array()
	for p: Array in points:line.append(Vector2(p[0],p[1]))
	if line.size()>1:_routes.append({"points":line,"clearance":clearance,"kind":kind})

func _load_protection() -> void:
	var estuary: Dictionary=_plan.get("protected_estuary",{})
	_add_route(estuary.get("points_xz",[]),float(estuary.get("clear_half_width_m",32))+float(estuary.get("blend_m",20)),"estuary")
	for path: Dictionary in _plan.get("trails",[]):_add_route(path.get("profile_xzy",[]),float(path.width_m)*.5+2.0,"trail")
	for path: Dictionary in _plan.get("protected_paths",[]):_add_route(path.get("points_xz",[]),float(path.get("clear_half_width_m",3.6))+2.0,"original_path")
	for source: Array in [["res://planning/river-routes-v2.json","routes"],["res://planning/brindle-sectors-v1.json","routes"]]:
		if not FileAccess.file_exists(source[0]):continue
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source[0]))
		for path: Dictionary in data.get(source[1],[]):_add_route(path.get("points_xz",path.get("points",[])),float(path.get("width_m",path.get("width",3.0)))*.5+2.0,"original_path")

func _route_distance(point: Vector2,line: PackedVector2Array) -> float:
	var best: float=INF
	for i: int in range(1,line.size()):best=minf(best,point.distance_to(Geometry2D.get_closest_point_to_segment(point,line[i-1],line[i])))
	return best

func _protected(point: Vector2,radius: float) -> String:
	for route: Dictionary in _routes:
		if _route_distance(point,route.points)<float(route.clearance)+radius:return str(route.kind)
	for anchor: Dictionary in _plan.get("protected_anchors",[]):
		if point.distance_to(Vector2(anchor.xz[0],anchor.xz[1]))<float(anchor.radius_m)+float(anchor.get("blend_m",0.0))+radius:return "anchor"
	return ""

func _reject(reason: String) -> bool:
	_rejections[reason]=int(_rejections.get(reason,0))+1
	return false

func _height(point: Vector2) -> float:
	return float(_ground.call("surface_height_at_world",point.x,point.y))

func _try_place(id: String,point: Vector2,along: float,size: Vector3,role: String,maximum: int) -> bool:
	if _placements.size()>=maximum:return false
	var asset: Dictionary=_assets[id]
	var y: float=_height(point)
	if not is_finite(y):return _reject("height")
	var normal: Vector3=Vector3(-(_height(point+Vector2(.8,0))-_height(point-Vector2(.8,0)))/1.6,1,-(_height(point+Vector2(0,.8))-_height(point-Vector2(0,.8)))/1.6).normalized()
	if role=="stack":
		if y<_sea-4.0 or y>_sea+.65:return _reject("stack_seabed")
		normal=Vector3.UP
	elif id==IDS[5] and (y<_sea-.1 or normal.y<.85):return _reject("pebble_slope")
	elif role=="foot" and (y<_sea-4.0 or normal.y<.48):return _reject("foot_slope")
	elif role=="land" and normal.y<.76:return _reject("land_slope")
	var basis: Basis=Basis(Quaternion(Vector3.UP,normal))*Basis(Vector3.UP,_rng.randf_range(-PI,PI))
	basis=basis.scaled_local(size)
	var box: AABB=Transform3D(basis,Vector3.ZERO)*asset.bounds
	var radius: float=Vector2(maxf(absf(box.position.x),absf(box.end.x)),maxf(absf(box.position.z),absf(box.end.z))).length()
	var half_map: float=float(_plan.get("extent_m",768.0))*.5
	if absf(point.x)+radius>half_map-1 or absf(point.y)+radius>half_map-1:return _reject("map_edge")
	var signed_distance: float=_signed_coast(point)
	if signed_distance+radius>18.0:return _reject("inland_limit")
	var protection: String=_protected(point,radius)
	if not protection.is_empty():return _reject(protection)
	# Seat every real base vertex against the terrain. The lowest support plane
	# is chosen, so a sloping beach cannot leave the downhill half floating.
	var support: float=y
	for local: Vector3 in asset.footprint:
		var offset: Vector3=basis*local
		support=minf(support,_height(point+Vector2(offset.x,offset.z))-offset.y)
	var burial: float=y-support
	if burial>maxf(.20,box.size.y*.35):return _reject("unsupported_slope")
	var top: float=-INF
	for vertex: Vector3 in asset.vertices:top=maxf(top,(basis*vertex).y)
	if support+top<_sea+.12:return _reject("submerged")
	# Overlap within a pack is deliberate, but identical tiny pebbles do not pile.
	for existing: Dictionary in _placements:
		if point.distance_squared_to(existing.xz)<pow(minf(radius,float(existing.radius))*.32,2):return _reject("pack_spacing")
	var transform: Transform3D=Transform3D(basis,Vector3(point.x,support,point.y))
	_placements.append({"asset":id,"xz":point,"transform":transform,"along":clampf(along,0,_lengths[-1]),"radius":radius,"height":box.size.y,"ground_y":y,"burial":burial,"role":role,"tone":_rng.randf_range(.90,1.05)})
	return true

func _build_batches() -> void:
	var groups: Dictionary={}
	var length: float=maxf(40.0,float(_plan.get("rock_budget",{}).get("batch_length_m",80.0)))
	var total_triangles: int=0
	for record: Dictionary in _placements:
		var lod: String="major" if record.role=="stack" or float(record.height)>=4.0 else "pebbles" if record.asset==IDS[5] else "rock"
		var key: String=str(record.asset)+"_"+str(floori(float(record.along)/length)).pad_zeros(2)+"_"+lod
		if not groups.has(key):groups[key]={"asset":record.asset,"lod":lod,"records":[]}
		groups[key].records.append(record)
		total_triangles+=int(_assets[record.asset].triangles)
	var inverse: Transform3D=global_transform.affine_inverse()
	for key: String in groups:
		var group: Dictionary=groups[key]
		var multi: MultiMesh=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.use_colors=true
		multi.mesh=_assets[group.asset].mesh;multi.instance_count=group.records.size()
		for i: int in group.records.size():
			var record: Dictionary=group.records[i]
			multi.set_instance_transform(i,inverse*record.transform)
			var tone: float=record.tone;multi.set_instance_color(i,Color(tone,tone,tone,1))
		var node: MultiMeshInstance3D=MultiMeshInstance3D.new();node.name=key.to_pascal_case();node.multimesh=multi;node.set_meta(GENERATED,true)
		# Structural silhouettes have no distance cutoff; smaller details fade away.
		node.visibility_range_end=0.0 if group.lod=="major" else 190.0 if group.lod=="pebbles" else 490.0
		node.visibility_range_end_margin=20.0
		if group.lod=="pebbles":node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
	set_meta("coast_rock_batches",groups.size());set_meta("coast_rock_tris",total_triangles)

func _collision_hulls(scene_path: String) -> Array[Shape3D]:
	var result: Array[Shape3D]=[]
	var source: Node=load(scene_path).instantiate()
	for collider: CollisionShape3D in source.find_children("*","CollisionShape3D",true,false):
		if collider.shape is ConvexPolygonShape3D:result.append(collider.shape)
	source.free()
	return result

func _build_collisions() -> void:
	var candidates: Array[Dictionary]=[]
	for record: Dictionary in _placements:
		if record.asset==IDS[5] or record.role=="stack" or float(record.ground_y)<_sea+.35 or float(record.height)<.85:continue
		var nearest: float=INF
		for route: Dictionary in _routes:
			if route.kind!="estuary":nearest=minf(nearest,_route_distance(record.xz,route.points)-float(record.radius))
		if nearest<24.0 or record.role=="land":candidates.append({"record":record,"distance":nearest})
	candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:return float(a.distance)<float(b.distance))
	var limit: int=clampi(int(_plan.get("rock_budget",{}).get("collision_budget",110))-1,0,109)
	var count: int=0
	var body: StaticBody3D=StaticBody3D.new();body.name="CoastalRockCollisions";body.collision_mask=0;body.set_meta(GENERATED,true);add_child(body)
	var inverse: Transform3D=body.global_transform.affine_inverse()
	for candidate: Dictionary in candidates:
		var record: Dictionary=candidate.record
		var hulls: Array[Shape3D]=_assets[record.asset].hulls
		if count+hulls.size()>limit:continue
		for hull: Shape3D in hulls:
			var collision: CollisionShape3D=CollisionShape3D.new();collision.name="Rock"+str(count).pad_zeros(3);collision.shape=hull;collision.transform=inverse*record.transform
			body.add_child(collision);count+=1
	set_meta("coast_rock_colliders",count)

func _build_ocean_backdrop() -> void:
	# At oblique angles the submerged terrain edge projects beyond the finite
	# water edge. Continue only the existing west/south sea outside the map.
	var half_width: float=float(_ground.get("width_m"))*.5
	var half_depth: float=float(_ground.get("depth_m"))*.5
	var outer: float=maxf(1536.0,maxf(half_width,half_depth)+128.0)
	var rectangles: Array[Rect2]=[
		Rect2(-outer,-half_depth,outer-half_width,half_depth*2.0),
		Rect2(-half_width,half_depth,half_width*2.0,outer-half_depth),
		Rect2(-outer,half_depth,outer-half_width,outer-half_depth),
	]
	var vertices: PackedVector3Array=PackedVector3Array()
	var normals: PackedVector3Array=PackedVector3Array()
	var colors: PackedColorArray=PackedColorArray()
	var indices: PackedInt32Array=PackedInt32Array()
	for rectangle: Rect2 in rectangles:
		var first: int=vertices.size()
		for corner: Vector2 in [rectangle.position,Vector2(rectangle.end.x,rectangle.position.y),Vector2(rectangle.position.x,rectangle.end.y),rectangle.end]:
			vertices.append(Vector3(corner.x,_sea,corner.y))
			normals.append(Vector3.UP)
			# The connected-water shader encodes depth, flow X/Z and flow speed.
			colors.append(Color(1.0,.5,.5,0.0))
		indices.append_array(PackedInt32Array([first,first+1,first+2,first+1,first+3,first+2]))
	var arrays: Array=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh: ArrayMesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.surface_set_material(0,_ground.get("water_material") as Material)
	var ocean: MeshInstance3D=MeshInstance3D.new();ocean.name="OceanBackdrop";ocean.mesh=mesh
	ocean.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ocean.set_meta(GENERATED,true);ocean.set_meta("coast_ocean_triangles",6)
	add_child(ocean)
	ocean.global_transform=Transform3D.IDENTITY
