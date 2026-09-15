extends SceneTree
## Regressions found during close visual review: terrain contacts, real door access,
## stair arrival height, sheltered supplies and connected forge air supply.
var checks: int=0
var failures: int=0
var world: Node3D
var ground: Node3D
var player: CharacterBody3D
var camera: Camera3D

func _initialize() -> void:
	create_timer(180).timeout.connect(func() -> void:push_error("Ironworks coherence verification timed out");quit(1))
	call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;print("FAIL ",label)

func frames(count: int) -> void:
	for i: int in count:await physics_frame

func run() -> void:
	var session: Node3D=(load("res://scenes/test_brindle.tscn") as PackedScene).instantiate();root.add_child(session)
	world=session.get_node("World");ground=world.get_node("Terrain")
	player=world.get_node("Characters/Player");camera=world.get_node("PlayerCamera")
	camera.set_process_unhandled_input(false);await frames(40)
	var layout: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://planning/ironworks-town.json"))
	var town: Node3D=world.get_node("Decor/Acierie")
	for record: Dictionary in layout.buildings+layout.props:
		var obj: Node3D=town.get_node(record.group+"/"+record.id)
		_check_ground_contacts(obj)
		for face: Marker3D in obj.find_children("DoorFace*","Marker3D",false,false):
			if face.position.y>1.0:continue
			var outward: Vector3=face.global_basis.z.normalized()
			var target: Vector3=face.global_position+outward*(.25 if record.asset=="grenier_vivres" else .48)
			var start: Vector3=target+outward*3.0;start.y=ground.call("height_at_world",start.x,start.z)
			await _walk(start,target,record.id+" "+str(face.name),face.global_position.y-.24)
		if obj.has_node("StairStart"):
			var start: Vector3=obj.get_node("StairStart").global_position;start.y=ground.call("height_at_world",start.x,start.z)
			var landing: Vector3=obj.get_node("GalleryArrival").global_position
			await _walk(start,landing,record.id+" staircase",landing.y-.16)
			var upper: Marker3D=obj.get_node("UpperDoor")
			await _walk(player.position,upper.global_position+upper.global_basis.z*.25,record.id+" upper door",landing.y-.16,false)
		if obj.has_node("HearthAirIntake"):
			var outlet: Vector3=obj.get_node("BellowsAirOutlet").global_position
			var intake: Vector3=obj.get_node("HearthAirIntake").global_position
			check(outlet.distance_to(intake)<.08,record.id+" bellows joins hearth")
		if record.has("sheltered_by"):
			var host: Node3D=town.find_child(record.sheltered_by,true,false)
			var covered: bool=host!=null
			for x: float in [-.48,.48]:
				for z: float in [-.48,.48]:
					var p: Vector3=obj.to_global(Vector3(record.bounds_center_m[0]+record.size_m[0]*x,record.size_m[1]+.1,record.bounds_center_m[2]+record.size_m[2]*z))
					covered=covered and _roof_above(host,p)
			check(covered,record.id+" supplies entirely below "+str(record.sheltered_by)+" roof")
	print("IRONWORKS_COHERENCE ","PASS" if failures==0 else "FAIL"," checks=",checks," failures=",failures)
	session.queue_free();await process_frame;quit(0 if failures==0 else 1)

func _walk(start: Vector3,target: Vector3,label: String,min_height: float,reset: bool=true) -> void:
	if reset:player.position=start+Vector3(0,.12,0);player.velocity=Vector3.ZERO;await frames(20)
	var reached: bool=false
	for i: int in 420:
		var delta: Vector2=Vector2(target.x-player.position.x,target.z-player.position.z)
		if delta.length()<.18:reached=player.position.y>=min_height;break
		camera.set("azimuth_degrees",rad_to_deg(atan2(delta.x,delta.y)))
		Input.action_press("move_down");await physics_frame
	Input.action_release("move_down");await frames(4)
	check(reached and player.is_on_floor(),label+" reached on its floor at "+str(player.position))

func _check_ground_contacts(obj: Node3D) -> void:
	var floating: float=0.0;var buried: float=0.0;var samples: int=0
	for mesh: MeshInstance3D in obj.find_children("*","MeshInstance3D",true,false):
		for surface: int in mesh.mesh.get_surface_count():
			var arrays: Array=mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			for i: int in range(0,vertices.size(),3):
				var p: Vector3=mesh.global_transform*vertices[i];var local: Vector3=obj.to_local(p)
				if local.y<-.07 or local.y>.16:continue
				var gap: float=p.y-float(ground.call("surface_height_at_world",p.x,p.z))-local.y
				floating=maxf(floating,gap);buried=maxf(buried,-gap);samples+=1
	check(samples>0 and floating<.25 and buried<.26,str(obj.name)+" terrain contacts float="+str(floating)+" burial="+str(buried))

func _roof_above(host: Node3D,p: Vector3) -> bool:
	if host==null:return false
	for mesh: MeshInstance3D in host.find_children("*","MeshInstance3D",true,false):
		if not (str(mesh.name).contains("RoofDeck") or str(mesh.name).contains("SinglePitchDeck")):continue
		for surface: int in mesh.mesh.get_surface_count():
			var arrays: Array=mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			if indices.is_empty():
				for i: int in vertices.size():indices.append(i)
			for i: int in range(0,indices.size(),3):
				var a: Vector3=mesh.global_transform*vertices[indices[i]]
				var b: Vector3=mesh.global_transform*vertices[indices[i+1]]
				var c: Vector3=mesh.global_transform*vertices[indices[i+2]]
				if Geometry3D.segment_intersects_triangle(p,p+Vector3.UP*12.0,a,b,c)!=null:return true
	return false
