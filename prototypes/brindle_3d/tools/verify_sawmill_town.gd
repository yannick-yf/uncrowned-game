extends SceneTree
var checks: int=0
var failures: int=0
var ground: Node3D
var world: Node3D
var camera: Camera3D
var player: CharacterBody3D
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;print("FAIL ",label)
func run() -> void:
	var session: Node3D=(load("res://scenes/test_brindle.tscn") as PackedScene).instantiate();root.add_child(session)
	world=session.get_node("World");ground=world.get_node("Terrain");player=world.get_node("Characters/Player")
	camera=world.get_node("PlayerCamera");camera.set_process_unhandled_input(false)
	for i: int in 45:await physics_frame
	var layout: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://planning/sawmill-town.json"))
	var used: Dictionary={}
	for b: Dictionary in layout.buildings:
		var obj: Node3D=world.get_node("Decor/Scierie/"+b.group+"/"+b.id)
		check(not used.has(b.scene),b.id+" unique scene");used[b.scene]=true
		if b.id=="GrandeScierie":continue # Feet and floor span the wheel channel.
		var low: float=INF;var high: float=-INF;var wet: bool=false
		for x: float in [-.40,0.0,.40]:
			for z: float in [-.40,0.0,.40]:
				var at: Vector3=obj.to_global(Vector3(b.bounds_center_m[0]+b.size_m[0]*x,0,b.bounds_center_m[2]+b.size_m[2]*z))
				var y: float=ground.call("surface_height_at_world",at.x,at.z)
				low=minf(low,y);high=maxf(high,y)
				if float(ground.call("water_at_world",at.x,at.z))>y:wet=true
		check(not wet,b.id+" dry foundation")
		check(high-obj.global_position.y<.30 and obj.global_position.y-low<.35,b.id+" foundation low="+str(low)+" high="+str(high)+" root="+str(obj.global_position.y))
	for r: Dictionary in layout.paths:_check_route(r)
	var mill: Node3D=world.get_node("Decor/Scierie/RiveDuMoulin/GrandeScierie")
	check(absf(mill.global_position.y-44.2)<.10,"Mill sits at hydraulic design height: "+str(mill.global_position.y))
	check(mill.has_node("RoueAnimee") and mill.get_node("RoueAnimee").get_child_count()>0,"Wheel assembled")
	check(absf(mill.get_node("WaterIn").global_position.y-48.76)<.12,"Inlet joins the elevated flume")
	var intake_ray: PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(Vector3(254.65,48.78,-158.1),Vector3(254.65,48.78,-156.9),1)
	check(world.get_world_3d().direct_space_state.intersect_ray(intake_ray).is_empty(),"Open sluice leaves a clear water aperture")
	check(float(ground.call("water_at_world",255,-163))>mill.get_node("WheelAxis").global_position.y,"Pond above wheel axis")
	check(float(ground.call("water_at_world",254.65,-145))<mill.get_node("WheelAxis").global_position.y-1.7,"Tailrace below wheel axis")
	var angle: float=mill.get_node("RoueAnimee").rotation.x
	for i: int in 20:await physics_frame
	check(absf(mill.get_node("RoueAnimee").rotation.x-angle)>.01,"Wheel animates in game")
	for b: Dictionary in layout.buildings:
		for ps: Array in b.door_approaches:
			check(await walk(ps),b.id+" real player reaches front approach")
	check(await walk([[250,-140.8],[250,-143.3]]),"Real player climbs mill loading ramp")
	print("SAWMILL_TOWN_CHECK ","PASS" if failures==0 else "FAIL"," checks=",checks," failures=",failures)
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
			# The last path sample overlaps the bridge's collision slab by design.
			var ray: PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(p+Vector3(0,.4,0),p-Vector3(0,.2,0),1,[player.get_rid()])
			var floor_hit: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(ray)
			if not floor_hit.is_empty() and str(floor_hit.collider.get_path()).contains("/Ponts/"):p.y=floor_hit.position.y
			var q: PhysicsShapeQueryParameters3D=PhysicsShapeQueryParameters3D.new();q.shape=sphere;q.collision_mask=1;q.exclude=[player.get_rid()];q.transform=Transform3D(Basis.IDENTITY,p+Vector3(0,.70,0))
			var hits: Array[Dictionary]=world.get_world_3d().direct_space_state.intersect_shape(q,1)
			if not hits.is_empty() and blocked.size()<4:blocked.append(str(p)+" "+str(hits[0].collider.get_path()))
	check(wet==0 and steep==0 and blocked.is_empty(),r.id+" access: wet="+str(wet)+" steep="+str(steep)+" collisions="+str(blocked))


func walk(points: Array) -> bool:
	var first: Array=points[0]
	player.position=Vector3(first[0],ground.call("surface_height_at_world",first[0],first[1])+.12,first[1]);player.velocity=Vector3.ZERO
	for i: int in 16:await physics_frame
	for index: int in range(1,points.size()):
		var target: Vector2=Vector2(points[index][0],points[index][1]);var reached: bool=false
		for i: int in 500:
			var delta: Vector2=target-Vector2(player.position.x,player.position.z)
			if delta.length()<.42:reached=true;break
			camera.set("azimuth_degrees",rad_to_deg(atan2(delta.x,delta.y)))
			Input.action_press("move_down");await physics_frame
		Input.action_release("move_down")
		if not reached:print("WALK_STOP ",player.position," target=",target);return false
	return true
