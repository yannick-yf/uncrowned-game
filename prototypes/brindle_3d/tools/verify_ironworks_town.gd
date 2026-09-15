extends SceneTree
## Validate authored foundations and actual access through the populated terrain.
var checks: int=0
var failures: int=0
var ground: Node3D
var world: Node3D
var player: CharacterBody3D
var camera: Camera3D
var layout: Dictionary
func _initialize() -> void:
	create_timer(900).timeout.connect(func():push_error("Town verification timed out");quit(1))
	call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;print("FAIL ",label)
func frames(count: int) -> void:
	for i: int in count:await physics_frame
func run() -> void:
	var session: Node3D=(load("res://scenes/test_brindle.tscn") as PackedScene).instantiate();root.add_child(session)
	world=session.get_node("World");ground=world.get_node("Terrain");player=world.get_node("Characters/Player");camera=world.get_node("PlayerCamera")
	camera.set_process_unhandled_input(false)
	layout=JSON.parse_string(FileAccess.get_file_as_string("res://planning/ironworks-town.json"))
	await frames(40)
	player.collision_layer=0
	check(world.has_node("Decor/Acierie"),"saved ironworks sector loaded")
	check(layout.buildings.size()>=world.get_node("Decor/Brindle/Maisons").get_child_count()*4,"settlement at least four times Brindle's building count")
	var material: ShaderMaterial=ground.get("grass_material")
	check(material.get_shader_parameter("ironworks_mask_enabled")==true,"industrial ground paint active")
	var used_scenes: Dictionary={};var structural_shapes: Dictionary={};var barracks: int=0
	for b: Dictionary in layout.buildings:
		var node: Node3D=world.get_node("Decor/Acierie/"+b.group+"/"+b.id)
		check(not used_scenes.has(b.scene),b.id+" uses a unique building scene")
		used_scenes[b.scene]=true
		var shape: String=_structural_signature(node)
		check(not structural_shapes.has(shape),b.id+" has a distinct structural shape")
		structural_shapes[shape]=b.id
		if b.get("building_kind","")=="barrack":barracks+=1
		var low: float=INF;var high: float=-INF;var wet: bool=false
		for x: float in [-.45,0.0,.45]:
			for z: float in [-.45,0.0,.45]:
				var at: Vector3=node.to_global(Vector3(b.bounds_center_m[0]+float(b.size_m[0])*x,0,b.bounds_center_m[2]+float(b.size_m[2])*z))
				var y: float=ground.call("surface_height_at_world",at.x,at.z)
				low=minf(low,y);high=maxf(high,y)
				if float(ground.call("water_at_world",at.x,at.z))>y:wet=true
		check(not wet,b.id+" dry foundation")
		check(high-node.global_position.y<.28 and node.global_position.y-low<.32,b.id+" seated level foundation low="+str(low)+" high="+str(high)+" root="+str(node.global_position.y))
	check(barracks==4,"four individually designed workers' barracks")
	var latrines: Array=[]
	for p: Dictionary in layout.props:
		if str(p.asset).begins_with("latrines"):latrines.append(p.asset)
	check(latrines.size()==2 and latrines[0]!=latrines[1],"the two small latrine buildings are also distinct")
	for r: Dictionary in layout.paths:_check_route(r)
	var regional: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://planning/river-routes-v2.json"))
	for r: Dictionary in regional.routes:
		var local_points: Array=[]
		for p: Array in r.points_xz:
			if Rect2(185,-14,103,114).has_point(Vector2(p[0],p[1])):local_points.append(p)
		if local_points.size()>1:
			var local_route: Dictionary=r.duplicate(true);local_route.points_xz=local_points
			_check_route(local_route)
	# Move the same capsule and input controller used in play, along every front approach.
	for b: Dictionary in layout.buildings:
		if not b.has("entrance_xz"):continue
		var ps: Array=b.approach_xz
		var p: Array=ps[0];player.position=Vector3(p[0],float(ground.call("height_at_world",p[0],p[1]))+.12,p[1]);player.velocity=Vector3.ZERO
		await frames(16)
		var passed: bool=true
		for i: int in range(1,ps.size()):
			var target: Vector2=Vector2(ps[i][0],ps[i][1]);var reached: bool=false
			for step: int in 360:
				var delta: Vector2=target-Vector2(player.position.x,player.position.z)
				if delta.length()<.48:reached=true;break
				camera.set("azimuth_degrees",rad_to_deg(atan2(delta.x,delta.y)))
				Input.action_press("move_down");await physics_frame
			Input.action_release("move_down")
			if not reached:passed=false;break
		check(passed,b.id+" player reaches entrance at "+str(player.position))
	# Cross the actual porch plane in the open working halls; closed houses stay exterior scenery.
	for name: String in ["Production/HalleMartelage","Production/ForgeFinition","Production/TriArriveeMine","Production/TriReserveMinerai","Services/RelaisCharrettes"]:
		var building: Node3D=world.get_node("Decor/Acierie/"+name)
		var start: Vector3=building.to_global(Vector3(0,0,4.6))
		start.y=ground.call("height_at_world",start.x,start.z)
		player.position=start+Vector3(0,.12,0);player.velocity=Vector3.ZERO
		camera.set("azimuth_degrees",building.rotation_degrees.y+180)
		await frames(16);Input.action_press("move_down")
		var crossed: bool=false
		var finish_z: float=-4.0 if name=="Services/RelaisCharrettes" else 1.4
		for i: int in 200:
			await physics_frame
			if building.to_local(player.position).z<finish_z:crossed=true;break
		Input.action_release("move_down")
		check(crossed,name+" open hall traversable, local="+str(building.to_local(player.position)))
	print("IRONWORKS_TOWN_CHECK ","PASS" if failures==0 else "FAIL"," checks=",checks," failures=",failures)
	session.queue_free();await process_frame;quit(0 if failures==0 else 1)
func _check_route(r: Dictionary) -> void:
	var curve: Curve3D=Curve3D.new();curve.bake_interval=.8
	for i: int in r.points_xz.size():
		var p: Array=r.points_xz[i];var a: Array=r.points_xz[maxi(0,i-1)];var b: Array=r.points_xz[mini(i+1,r.points_xz.size()-1)]
		var tangent: Vector3=Vector3(b[0]-a[0],0,b[1]-a[1])/6.0;curve.add_point(Vector3(p[0],0,p[1]),-tangent,tangent)
	var sphere: CapsuleShape3D=CapsuleShape3D.new();sphere.radius=.28;sphere.height=1.3
	var blocked: Array[String]=[];var steep: int=0;var wet: int=0;var previous: Vector3=Vector3.INF
	var pts: PackedVector3Array=curve.get_baked_points()
	for i: int in pts.size():
		var center: Vector3=pts[i];center.y=ground.call("surface_height_at_world",center.x,center.z)
		if previous!=Vector3.INF and absf(center.y-previous.y)>Vector2(center.x-previous.x,center.z-previous.z).length()*.50:steep+=1
		previous=center
		var direction: Vector3=(pts[mini(pts.size()-1,i+1)]-pts[maxi(0,i-1)]).normalized()
		var side: Vector3=Vector3(direction.z,0,-direction.x)
		for lane: float in [-.25,0.0,.25]:
			var p: Vector3=center+side*float(r.width_m)*lane;p.y=ground.call("surface_height_at_world",p.x,p.z)
			if float(ground.call("water_at_world",p.x,p.z))>p.y:wet+=1
			var q: PhysicsShapeQueryParameters3D=PhysicsShapeQueryParameters3D.new();q.shape=sphere;q.collision_mask=1;q.exclude=[player.get_rid()];q.transform=Transform3D(Basis.IDENTITY,p+Vector3(0,.70,0))
			var hits: Array[Dictionary]=world.get_world_3d().direct_space_state.intersect_shape(q,1)
			if not hits.is_empty() and blocked.size()<4:blocked.append(str(p)+" "+str(hits[0].collider.get_path()))
	check(wet==0 and steep==0 and blocked.is_empty(),r.id+" access: wet="+str(wet)+" steep="+str(steep)+" collisions="+str(blocked))

func _structural_signature(obj: Node3D) -> String:
	# Ignore colour, names, furniture and the placed instance's rotation. A renamed,
	# rotated or recoloured copy of the same walls and roof still fails this check.
	var points: PackedVector3Array=[]
	for mesh: MeshInstance3D in obj.find_children("*","MeshInstance3D",true,false):
		var name: String=str(mesh.name)
		if not (name.contains("Foundation") or name.contains("SolidWalls") or name.contains("RoofDeck") or name.contains("SinglePitchDeck") or name.contains("HallPost") or name.contains("MasonryPier")):continue
		for surface: int in mesh.mesh.get_surface_count():
			var data: Array=mesh.mesh.surface_get_arrays(surface)
			for p: Vector3 in data[Mesh.ARRAY_VERTEX]:points.append(obj.to_local(mesh.to_global(p)))
	var rotations: Array[String]=[]
	for angle: float in [0.0,PI*.5,PI,PI*1.5]:
		var unique: Dictionary={};var transformed: Array[Vector3i]=[]
		var low: Vector3i=Vector3i(999999,999999,999999)
		for p: Vector3 in points:
			var q: Vector3=Basis(Vector3.UP,angle)*p
			var v: Vector3i=Vector3i(roundi(q.x*100),roundi(q.y*100),roundi(q.z*100))
			transformed.append(v);low=Vector3i(mini(low.x,v.x),mini(low.y,v.y),mini(low.z,v.z))
		for v: Vector3i in transformed:unique[str(v-low)]=true
		var keys: Array=unique.keys();keys.sort()
		rotations.append(str(keys).sha256_text())
	rotations.sort();return rotations[0]
