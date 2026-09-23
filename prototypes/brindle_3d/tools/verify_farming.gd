extends SceneTree
## Test the exported prefabs: geometry budgets, provenance, pivots and usable openings.
var checks: int=0
var failures: int=0
var total_triangles: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;print("FAIL ",label)
func run() -> void:
	var path: String="res://assets/farming/catalog.json"
	check(FileAccess.file_exists(path),"Saved farming kit manifest exists")
	if failures>0:quit(1);return
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	check(data.assets.size()>=50,"Complete farming, field and orchard kit")
	check(not str(data.get("provenance","")).is_empty(),"Source provenance documented")
	var seen: Dictionary={};var families: Dictionary={}
	for asset: Dictionary in data.assets:
		check(not seen.has(asset.id),"Distinct asset id "+asset.id);seen[asset.id]=true;families[asset.family]=true
		var packed: PackedScene=load(asset.scene)
		check(packed!=null,"Load "+asset.id)
		if packed==null:continue
		var obj: Node3D=packed.instantiate();root.add_child(obj)
		var meshes: Array[Node]=obj.find_children("*","MeshInstance3D",true,false)
		var valid: bool=not meshes.is_empty();var tris: int=0
		for m: MeshInstance3D in meshes:
			var bounds: AABB=m.global_transform*m.get_aabb()
			valid=valid and bounds.position.is_finite() and bounds.size.is_finite() and bounds.position.y>=-.16
			for i: int in m.mesh.get_surface_count():
				var arrays: Array=m.mesh.surface_get_arrays(i)
				var indices: Variant=arrays[Mesh.ARRAY_INDEX]
				tris+=(indices.size() if indices!=null and indices.size()>0 else arrays[Mesh.ARRAY_VERTEX].size())/3
		check(valid,"Visible finite geometry at a ground pivot "+asset.id)
		check(tris==int(asset.triangles) and tris>0,"Measured triangles agree "+asset.id)
		check(tris<=int(asset.triangle_budget),"Geometry budget "+asset.id+": "+str(tris))
		check(meshes.size()<=int(asset.mesh_budget),"Mesh batching "+asset.id+": "+str(meshes.size()))
		total_triangles+=tris
		if obj.has_meta("outline_xz"):
			check(obj.find_children("*","CollisionShape3D",true,false).is_empty(),"Fields remain walk-through "+asset.id)
		if obj.has_node("ConnectorStart") and obj.has_node("ConnectorEnd"):
			check(obj.get_node("ConnectorStart").position.distance_to(obj.get_node("ConnectorEnd").position)>1.9,"Fence connector span "+asset.id)
		await physics_frame;await physics_frame
		if obj.has_node("AisleStart") and obj.has_node("AisleEnd"):
			passage(obj,obj.get_node("AisleStart").global_position,obj.get_node("AisleEnd").global_position,asset.id)
		if obj.has_node("WheelAxis"):
			check(obj.has_node("WaterIn") and obj.has_node("WaterOut"),"Mill hydraulic markers "+asset.id)
		obj.free();await physics_frame
	check(families.size()>=5,"Separate building, storage, props, field and orchard families")
	# Exercise the catalogue as a client of the exported kit, including replace/filter.
	var gallery: Node3D=(load("res://scenes/catalogue_fermier.tscn") as PackedScene).instantiate()
	root.add_child(gallery);await process_frame
	check(gallery.catalog.size()==seen.size() and gallery.stage.get_child_count()>10,"Catalogue loads its presentation")
	for i: int in gallery.catalog.size():
		gallery.select_asset(i)
		check(gallery.stage.get_child_count()==2 and gallery.camera.size>0,"Isolated catalogue selection "+str(i))
	gallery.search.text="poirier";gallery.call("_filter")
	var visible_count: int=0
	for button: Button in gallery.entries:
		if button.visible:visible_count+=1
	check(visible_count==2,"Catalogue search finds both pear variants")
	gallery.show_demo();check(gallery.demonstration and gallery.stage.get_child_count()>10,"Catalogue restores presentation")
	gallery.free();await process_frame
	print("FARMING_CHECK ","PASS" if failures==0 else "FAIL"," checks=",checks," failures=",failures," assets=",seen.size()," triangles=",total_triangles)
	quit(0 if failures==0 else 1)
func passage(obj: Node3D,start: Vector3,finish: Vector3,label: String) -> void:
	var shape: CapsuleShape3D=CapsuleShape3D.new();shape.radius=.35;shape.height=1.8
	var query: PhysicsShapeQueryParameters3D=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1
	query.transform=Transform3D(Basis.IDENTITY,start+Vector3(0,.95,0));query.motion=finish-start
	var space: PhysicsDirectSpaceState3D=obj.get_world_3d().direct_space_state
	check(space.intersect_shape(query,1).is_empty() and space.cast_motion(query)[0]>.999,"Open aisle "+label)
