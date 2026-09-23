extends RefCounted
## Static, terrain-seated library greenery from authored points and seeded patches.
## Input: layout.greenery = [{id, scene, xz:[X,Z], yaw:degrees, scale:number}].
## No small-plant collision; birches retain the source asset's solid trunk.
const LIBRARY: String="res://prototype_3d/assets/library/"
const OUTPUT: String="res://assets/farming_village/meshes/"
const ALLOWED: Array[String]=[
	"trees/birch_twin.tscn", "plants/shrub_hazel.tscn",
	"plants/grass_meadow.tscn", "plants/flowers_daisy.tscn", "plants/fern_fan.tscn"
]
const BUILDING_MARGIN: float=.90
var b: Variant
var paths: Array[Dictionary]=[]
var buckets: Dictionary={}
var rejected: Dictionary={}
var accepted: int=0
var accepted_trees: int=0
var rejected_ids: Array[Dictionary]=[]
var meadow_counts: Dictionary={}

func _init(builder: Variant) -> void:
	b=builder

func build() -> void:
	assert(b.sector is Node3D and b.ground!=null and b.layout is Dictionary)
	assert(not b.sector.has_node("Verdure"),"Build greenery once per fresh village sector")
	assert(DirAccess.make_dir_recursive_absolute(OUTPUT)==OK)
	paths.clear();buckets.clear();rejected_ids.clear();meadow_counts.clear()
	rejected={"water":0,"path":0,"building":0,"field":0,"yard":0,"slope":0,"invalid":0};accepted=0;accepted_trees=0
	_prepare_paths()
	var group: Node3D=Node3D.new();group.name="Verdure";b.sector.add_child(group)
	group.set_meta("placement_source","res://planning/farming-town.json:greenery")
	group.set_meta("placement_policy","Authored dry points outside path clearance and building footprints")
	var inverse_group: Transform3D=_world_transform(group).affine_inverse()
	var ids: Dictionary={}
	var entries: Array=b.layout.get("greenery",[]).duplicate()
	entries.append_array(_meadow_entries())
	for entry: Dictionary in entries:
		var id: String=str(entry.get("id",""))
		var path: String=_source_path(str(entry.get("scene","")))
		var xz: Array=entry.get("xz",[])
		var scale_value: float=float(entry.get("scale",1.0))
		if id.is_empty() or id!=id.validate_node_name() or ids.has(id) or path.is_empty() or xz.size()!=2 or not is_finite(scale_value) or scale_value<=0:
			_reject(id,"invalid");continue
		ids[id]=true
		var point: Vector2=Vector2(float(xz[0]),float(xz[1]))
		var altitude: float=float(b.ground.call("surface_height_at_world",point.x,point.y))
		var yaw: float=deg_to_rad(float(entry.get("yaw",0.0)))
		if not point.is_finite() or not is_finite(altitude) or not is_finite(yaw):
			_reject(id,"invalid");continue
		var water: float=float(b.ground.call("water_at_world",point.x,point.y))
		if water>altitude+.01:
			_reject(id,"water");continue
		var birch: bool=path.ends_with("/birch_twin.tscn")
		# The mandatory .70 m verge also accommodates the ordinary birch trunk.
		# Oversized authored trees receive the additional radius they require.
		var extra_clearance: float=maxf(0.0,.47*scale_value-.42) if birch else 0.0
		if _on_path(point,extra_clearance):
			_reject(id,"path");continue
		if _inside_building(point,BUILDING_MARGIN+extra_clearance):
			_reject(id,"building");continue
		if entry.has("patch"):
			if _inside_field(point,.65):
				_reject(id,"field");continue
			if _inside_yard(point):
				_reject(id,"yard");continue
			var dx: float=float(b.ground.call("surface_height_at_world",point.x+.4,point.y))-float(b.ground.call("surface_height_at_world",point.x-.4,point.y))
			var dz: float=float(b.ground.call("surface_height_at_world",point.x,point.y+.4))-float(b.ground.call("surface_height_at_world",point.x,point.y-.4))
			if Vector2(dx,dz).length()/.8>.75:
				_reject(id,"slope");continue
		var packed: PackedScene=load(path) as PackedScene
		if packed==null:
			_reject(id,"invalid");continue
		var source: Node3D=packed.instantiate() as Node3D
		if source==null:
			_reject(id,"invalid");continue
		var world_transform: Transform3D=Transform3D(Basis(Vector3.UP,yaw)*Basis.from_scale(Vector3.ONE*scale_value),Vector3(point.x,altitude,point.y))
		var local_transform: Transform3D=inverse_group*world_transform
		_collect_meshes(source,local_transform,path)
		if birch:
			_copy_trunk(source,group,local_transform,id);accepted_trees+=1
		if entry.has("patch"):
			var label: String=path.get_file().get_basename()
			meadow_counts[label]=int(meadow_counts.get(label,0))+1
		else:
			var marker: Marker3D=Marker3D.new();marker.name=id;marker.transform=local_transform
			marker.set_meta("source_scene",path)
			marker.set_meta("editing","Move the plan entry and regenerate; this marker does not control saved MultiMesh transforms")
			group.add_child(marker)
		source.free();accepted+=1
	_save_batches(group)
	group.set_meta("authored_count",b.layout.get("greenery",[]).size())
	group.set_meta("accepted_count",accepted);group.set_meta("birch_count",accepted_trees)
	group.set_meta("rejected_counts",rejected);group.set_meta("rejected_entries",rejected_ids)
	group.set_meta("multimesh_count",buckets.size())
	group.set_meta("meadow_instances",meadow_counts)
	b.sector.set_meta("farm_greenery_count",accepted)
	b.sector.set_meta("farm_birch_count",accepted_trees)
	print("FARM_GREENERY_OK accepted=",accepted," birches=",accepted_trees," multimeshes=",buckets.size()," rejected=",JSON.stringify(rejected))
	print("FARM_MEADOW_OK ",JSON.stringify(meadow_counts))
	# Thousands of optional scatter candidates are deliberately filtered at build
	# time; aggregate rejection counts are more useful than their generated IDs.
	if not rejected_ids.is_empty():print("FARM_GREENERY_REJECTED ",JSON.stringify(rejected_ids))

func _meadow_entries() -> Array:
	var entries: Array=[]
	for patch: Dictionary in b.layout.get("meadow_patches",[]):
		var rng: RandomNumberGenerator=RandomNumberGenerator.new();rng.seed=int(patch.seed)
		var radii: Vector2=Vector2(patch.radii[0],patch.radii[1])
		for i: int in int(patch.count):
			var angle: float=rng.randf()*TAU
			var radius: float=sqrt(rng.randf())
			var offset: Vector2=(Vector2(cos(angle),sin(angle))*radii*radius).rotated(deg_to_rad(float(patch.get("yaw",0))))
			var scale_range: Array=patch.get("scale_range",[.65,1.05])
			entries.append({"id":"Prairie_"+str(patch.id)+"_"+str(i),"patch":patch.id,"scene":patch.scene,"xz":[patch.xz[0]+offset.x,patch.xz[1]+offset.y],"yaw":rng.randf()*360.0,"scale":rng.randf_range(scale_range[0],scale_range[1])})
	return entries

func _inside_field(point: Vector2,margin: float) -> bool:
	for field: Dictionary in b.layout.get("fields",[]):
		var asset: Dictionary=b.asset_catalog[field.asset]
		var offset: Vector3=Vector3(point.x-float(field.xz[0]),0,point.y-float(field.xz[1]))
		var local: Vector3=Basis(Vector3.UP,deg_to_rad(float(field.yaw))).inverse()*offset
		local.x/=float(field.scale[0]);local.z/=float(field.scale[1])
		local.x-=float(asset.bounds_center_m[0]);local.z-=float(asset.bounds_center_m[2])
		if absf(local.x)<float(asset.size_m[0])*.5+margin and absf(local.z)<float(asset.size_m[2])*.5+margin:return true
	return false

func _inside_yard(point: Vector2) -> bool:
	for area: Dictionary in b.layout.get("meadow_clearings",[]):
		var delta: Vector2=(point-Vector2(area.xz[0],area.xz[1]))/Vector2(area.radii[0],area.radii[1])
		if delta.length_squared()<1:return true
	for prop: Dictionary in b.layout.get("props",[]):
		if point.distance_squared_to(Vector2(prop.xz[0],prop.xz[1]))<1.3*1.3:return true
	for prop: Dictionary in b.layout.get("dressing",[]):
		if point.distance_squared_to(Vector2(prop.xz[0],prop.xz[1]))<2.2*2.2:return true
	return false

func _source_path(value: String) -> String:
	var relative: String=value.trim_prefix(LIBRARY)
	return LIBRARY+relative if relative in ALLOWED else ""

func _reject(id: String,reason: String) -> void:
	rejected[reason]=int(rejected[reason])+1
	if not id.begins_with("Prairie_"):rejected_ids.append({"id":id,"reason":reason})

func _prepare_paths() -> void:
	for route: Dictionary in b.layout.get("paths",[]):
		var points: Array=route.get("points_xz",[])
		if points.size()<2:continue
		var curve: Curve3D=Curve3D.new();curve.bake_interval=.55
		for i: int in points.size():
			var p: Array=points[i];var previous: Array=points[maxi(0,i-1)];var next: Array=points[mini(points.size()-1,i+1)]
			var tangent: Vector3=Vector3(float(next[0])-float(previous[0]),0,float(next[1])-float(previous[1]))/6.0
			curve.add_point(Vector3(p[0],0,p[1]),-tangent,tangent)
		paths.append({"points":curve.get_baked_points(),"clearance":float(route.get("width_m",2.0))*.5+.70})

func _on_path(point: Vector2,extra: float) -> bool:
	for route: Dictionary in paths:
		var points: PackedVector3Array=route.points
		var clearance_squared: float=pow(float(route.clearance)+extra,2)
		for i: int in range(1,points.size()):
			var a: Vector2=Vector2(points[i-1].x,points[i-1].z)
			var c: Vector2=Vector2(points[i].x,points[i].z)
			if point.distance_squared_to(Geometry2D.get_closest_point_to_segment(point,a,c))<clearance_squared:return true
	return false

func _inside_building(point: Vector2,margin: float) -> bool:
	for building: Dictionary in b.layout.get("buildings",[]):
		assert(building.has("size_m") and building.has("bounds_center_m"),"Greenery filtering requires enriched building bounds")
		var offset: Vector3=Vector3(point.x-float(building.xz[0]),0,point.y-float(building.xz[1]))
		# Inverse yaw converts the point to the asset frame before its asymmetric
		# mesh-bound centre is subtracted; translating rotated extents is incorrect.
		var local: Vector3=Basis(Vector3.UP,deg_to_rad(float(building.get("yaw",0.0)))).inverse()*offset
		local.x-=float(building.bounds_center_m[0]);local.z-=float(building.bounds_center_m[2])
		if absf(local.x)<float(building.size_m[0])*.5+margin and absf(local.z)<float(building.size_m[2])*.5+margin:return true
	return false

func _collect_meshes(source: Node3D,placement: Transform3D,path: String) -> void:
	for child: Node in source.find_children("*","MeshInstance3D",true,false):
		var mesh_node: MeshInstance3D=child as MeshInstance3D
		if mesh_node.mesh==null or not mesh_node.visible:continue
		for surface: int in mesh_node.mesh.get_surface_count():
			assert(mesh_node.get_surface_override_material(surface)==null,"Library greenery has unexpected per-surface material overrides")
		var key: String=_resource_key(mesh_node.mesh)+"|"+_resource_key(mesh_node.material_override)
		if not buckets.has(key):
			buckets[key]={"mesh":mesh_node.mesh,"material":mesh_node.material_override,"transforms":[],"cast_shadow":mesh_node.cast_shadow,"source_scene":path}
		buckets[key].transforms.append(placement*_relative_transform(source,mesh_node,true))

func _copy_trunk(source: Node3D,parent: Node3D,placement: Transform3D,id: String) -> void:
	var count: int=0
	for child: Node in source.find_children("*","StaticBody3D",true,false):
		var old_body: StaticBody3D=child as StaticBody3D
		var label: String=str(old_body.name).to_lower()
		if not ("trunk" in label or "tronc" in label):continue
		var body: StaticBody3D=StaticBody3D.new();body.name=id+"_Tronc_"+str(count)
		body.transform=placement*_relative_transform(source,old_body,true)
		body.collision_layer=old_body.collision_layer;body.collision_mask=old_body.collision_mask
		body.physics_material_override=old_body.physics_material_override
		parent.add_child(body)
		for shape_node: Node in old_body.find_children("*","CollisionShape3D",true,false):
			var old_shape: CollisionShape3D=shape_node as CollisionShape3D
			if old_shape.shape==null or old_shape.disabled:continue
			var collider: CollisionShape3D=CollisionShape3D.new();collider.name="FormeTronc"
			collider.shape=old_shape.shape
			collider.transform=_relative_transform(old_body,old_shape,false)
			body.add_child(collider);count+=1
	if count==0:
		var body: StaticBody3D=StaticBody3D.new();body.name=id+"_Tronc"
		body.transform=placement*source.transform;body.collision_layer=1;body.collision_mask=0;parent.add_child(body)
		var shape: CylinderShape3D=CylinderShape3D.new();shape.radius=.47;shape.height=2.8
		var collider: CollisionShape3D=CollisionShape3D.new();collider.name="FormeTronc";collider.shape=shape
		collider.position.y=1.4;body.add_child(collider)

func _save_batches(parent: Node3D) -> void:
	var keys: Array=buckets.keys();keys.sort()
	for key: String in keys:
		var bucket: Dictionary=buckets[key]
		var mesh: Mesh=bucket.mesh;var transforms: Array=bucket.transforms
		var multimesh: MultiMesh=MultiMesh.new()
		multimesh.transform_format=MultiMesh.TRANSFORM_3D
		multimesh.use_colors=false;multimesh.use_custom_data=false
		multimesh.mesh=mesh;multimesh.instance_count=transforms.size()
		var bounds: AABB=AABB()
		for i: int in transforms.size():
			var tr: Transform3D=transforms[i];multimesh.set_instance_transform(i,tr)
			var mesh_bounds: AABB=tr*mesh.get_aabb()
			bounds=mesh_bounds if i==0 else bounds.merge(mesh_bounds)
		multimesh.custom_aabb=bounds.grow(.06)
		var label: String="greenery_"+mesh.resource_path.get_file().get_basename()+"_"+key.sha256_text().substr(0,10)
		var resource_path: String=OUTPUT+label+".res"
		assert(ResourceSaver.save(multimesh,resource_path,ResourceSaver.FLAG_COMPRESS)==OK)
		var renderer: MultiMeshInstance3D=MultiMeshInstance3D.new();renderer.name=label.to_pascal_case()
		renderer.multimesh=ResourceLoader.load(resource_path,"MultiMesh",ResourceLoader.CACHE_MODE_REPLACE) as MultiMesh
		renderer.material_override=bucket.material;renderer.cast_shadow=bucket.cast_shadow
		renderer.set_meta("instances",transforms.size());renderer.set_meta("source_mesh",mesh.resource_path)
		parent.add_child(renderer)

func _resource_key(resource: Resource) -> String:
	if resource==null:return "none"
	assert(not resource.resource_path.is_empty(),"Greenery batching requires saved library resources")
	return resource.resource_path

func _relative_transform(ancestor: Node3D,node: Node3D,include_ancestor: bool) -> Transform3D:
	var result: Transform3D=Transform3D.IDENTITY;var current: Node=node
	while current!=ancestor:
		assert(current!=null,"Source node has no requested ancestor")
		if current is Node3D:result=(current as Node3D).transform*result
		current=current.get_parent()
	return ancestor.transform*result if include_ancestor else result

func _world_transform(node: Node3D) -> Transform3D:
	var result: Transform3D=Transform3D.IDENTITY;var current: Node=node
	while current!=null:
		if current is Node3D:result=(current as Node3D).transform*result
		current=current.get_parent()
	return result
