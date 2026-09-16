extends SceneTree
## Saved-resource integrity and real clearances through the working halls.
var checks: int=0
var failures: int=0
var triangles: int=0

func _initialize() -> void:call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)

func run() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/sawmill/catalog.json"))
	check(data.assets.size()==34,"Complete 34-asset kit")
	var seen: Dictionary={}
	for entry: Dictionary in data.assets:
		check(not seen.has(entry.id),"Distinct asset: "+str(entry.id));seen[entry.id]=true
		var scene: PackedScene=load(entry.scene)
		check(scene!=null,"Load "+str(entry.id))
		if scene==null:continue
		var obj: Node3D=scene.instantiate();root.add_child(obj)
		var meshes: Array[Node]=obj.find_children("*","MeshInstance3D",true,false)
		check(not meshes.is_empty(),"Visible geometry "+str(entry.id))
		var valid: bool=true
		for mesh: MeshInstance3D in meshes:
			var aabb: AABB=mesh.global_transform*mesh.get_aabb()
			valid=valid and aabb.position.is_finite() and aabb.size.is_finite() and aabb.position.y>-.30
		check(valid,"Finite geometry and ground pivot "+str(entry.id))
		triangles+=int(entry.triangles)
		await physics_frame;await physics_frame
		if entry.id in ["hangar_charrettes_bois","portique_chargement","halle_sechage","depot_grumes"]:
			var start: Vector3=Vector3(0,.97,3.7)
			var end: Vector3=Vector3(0,.97,-3.7) if entry.id=="hangar_charrettes_bois" else Vector3(0,.97,1.1)
			passage(obj,start,end,str(entry.id)+" clear work aisle")
		if entry.id=="scierie_hydraulique":
			check(obj.has_node("WaterIn") and obj.has_node("Tailrace") and obj.has_node("WheelAxis"),"Mill water placement markers")
			passage(obj,Vector3(2.65,2.15,2.65),Vector3(2.65,2.15,-1.8),"Mill floor side aisle")
			var ray: PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(Vector3(0,5,3.2),Vector3(0,0,3.2),1)
			var hit: Dictionary=obj.get_world_3d().direct_space_state.intersect_ray(ray)
			check(not hit.is_empty(),"Ramp reaches loading floor")
		obj.free();await physics_frame
	var gallery: Node3D=(load("res://scenes/catalogue_scierie.tscn") as PackedScene).instantiate();root.add_child(gallery)
	await process_frame
	check(gallery.get_node("Assets").get_child_count()==34,"Catalog contains every saved asset")
	for i: int in data.assets.size():gallery.call("select_asset",i)
	gallery.call("show_demo");check(gallery.get_node("Demonstration").visible,"Catalog assembly available")
	gallery.free()
	print("SAWMILL_CHECK ","PASS" if failures==0 else "FAIL"," checks=",checks," failures=",failures," assets=",seen.size()," triangles=",triangles)
	quit(0 if failures==0 else 1)

func passage(obj: Node3D,start: Vector3,end: Vector3,label: String) -> void:
	var capsule: CapsuleShape3D=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.75
	var query: PhysicsShapeQueryParameters3D=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1
	query.transform=Transform3D(Basis.IDENTITY,start);query.motion=end-start
	var space: PhysicsDirectSpaceState3D=obj.get_world_3d().direct_space_state
	check(space.intersect_shape(query,1).is_empty() and space.cast_motion(query)[0]>.999,label)
