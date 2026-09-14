extends SceneTree
## Validate saved resources and usable openings, independently of the world map.
var failures: int=0
var checks: int=0
var total_triangles: int=0

func _initialize() -> void:
	create_timer(50).timeout.connect(func() -> void: push_error("Ironworks verification timed out");quit(1))
	call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(label)

func run() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ironworks/catalog.json"))
	var ids: Dictionary={}
	check(data.assets.size()==62,"Expected the complete 62-scene kit")
	for record: Dictionary in data.assets:
		check(not ids.has(record.id),"Duplicate identifier: "+str(record.id));ids[record.id]=true
		var scene: PackedScene=load(record.scene)
		check(scene!=null,"Missing scene: "+str(record.scene))
		if scene==null:continue
		var obj: Node3D=scene.instantiate();root.add_child(obj)
		var meshes: Array[Node]=obj.find_children("*","MeshInstance3D",true,false)
		check(not meshes.is_empty(),"Empty geometry: "+str(record.id))
		var valid: bool=true
		for mesh: MeshInstance3D in meshes:
			var bounds: AABB=mesh.global_transform*mesh.get_aabb()
			valid=valid and bounds.position.is_finite() and bounds.size.is_finite() and bounds.position.y>-.4
		check(valid,"Invalid bounds or geometry far below the ground pivot: "+str(record.id))
		total_triangles+=int(record.triangles)
		if record.id in ["hangar_charrettes","portail_cour","portique_treuil_mine","entree_mine_roche"]:
			await physics_frame;await physics_frame
			var start_z: float=3.7 if record.id=="hangar_charrettes" else 1.8
			var end_z: float=-3.7 if record.id=="hangar_charrettes" else -1.8
			if record.id=="entree_mine_roche":end_z=-2.5
			var capsule: CapsuleShape3D=CapsuleShape3D.new();capsule.radius=.30;capsule.height=1.75
			var query: PhysicsShapeQueryParameters3D=PhysicsShapeQueryParameters3D.new()
			query.shape=capsule;query.collision_mask=1
			query.transform=Transform3D(Basis.IDENTITY,Vector3(0,.98,start_z))
			query.motion=Vector3(0,0,end_z-start_z)
			var space: PhysicsDirectSpaceState3D=obj.get_world_3d().direct_space_state
			check(space.intersect_shape(query,1).is_empty(),"Blocked approach: "+str(record.id))
			var cast: PackedFloat32Array=space.cast_motion(query)
			check(cast[0]>.999,"A player-sized capsule cannot cross the opening: "+str(record.id))
			if record.id=="entree_mine_roche":
				var ray: PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(Vector3(0,1,-2.5),Vector3(0,1,-3.5),1)
				check(not space.intersect_ray(ray).is_empty(),"Decorative tunnel must stop at its closed back")
		if record.id=="bas_fourneau_actif":
			var smoke: CPUParticles3D=obj.get_node_or_null("FumeeFourneau")
			check(smoke!=null and smoke.emitting and smoke.amount==22,"Active bloomery smoke missing")
		obj.free()
		await physics_frame
	var gallery: Node3D=(load("res://scenes/catalogue_acierie.tscn") as PackedScene).instantiate();root.add_child(gallery)
	await process_frame
	check(gallery.get_node("Assets").get_child_count()==data.assets.size(),"Catalog scene is incomplete")
	for i: int in data.assets.size():gallery.call("select_asset",i)
	gallery.call("show_demo")
	check(gallery.get_node("Demonstration").visible,"Demo could not be opened")
	gallery.free()
	print("IRONWORKS_CHECK_RESULT ","PASS" if failures==0 else "FAIL"," checks=",checks," failures=",failures," assets=",ids.size()," total_triangles=",total_triangles)
	quit(0 if failures==0 else 1)
