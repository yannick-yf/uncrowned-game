extends SceneTree
## Integration check with the workshop's real player, actual terrain and bridge collisions.
var failures: int=0
var checks: int=0
var player: CharacterBody3D
var camera: Camera3D
var ground: Node3D
var world: Node3D
func _initialize() -> void:
	create_timer(900).timeout.connect(func():push_error("River verification timed out");quit(1))
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;print("FAIL ",message)
func frames(n: int) -> void:
	for i: int in n:await physics_frame
func run() -> void:
	var session: Node3D=(load("res://scenes/test_brindle.tscn") as PackedScene).instantiate();root.add_child(session)
	world=session.get_node("World");ground=world.get_node("Terrain");player=world.get_node("Characters/Player");camera=world.get_node("PlayerCamera")
	camera.set_process_unhandled_input(false)
	await frames(35)
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/landscape/landscape.json"))
	var planned: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://planning/river-layout-v2.json"))
	check(data.crossings.size()==planned.crossings.size(),"all planned crossings")
	check(not world.has_node("Decor/MineAcierie/AccesEtPont"),"old blockout bridge removed")
	for c: Dictionary in data.crossings:
		var bridge: Node3D=world.get_node("Decor/Franchissements/Ponts/"+str(c.id))
		check(bridge!=null,str(c.id)+" scene")
		var direction: Vector3=Vector3(c.direction_xz[0],0,c.direction_xz[1]);var lateral: Vector3=Vector3(direction.z,0,-direction.x)
		for sign: float in [-1.0,1.0]:
			for lane: float in [-.28,0.0,.28]:
				var start: Vector3=bridge.global_position-direction*sign*(float(c.length_m)*.5+5.0)+lateral*(float(c.clear_width_m)*lane)
				start.y=ground.call("height_at_world",start.x,start.z)+.12
				player.position=start;player.velocity=Vector3.ZERO
				camera.set("azimuth_degrees",rad_to_deg(float(c.yaw_radians))+(180.0 if sign<0 else 0.0))
				await frames(18)
				Input.action_press("move_down")
				var passed: bool=false;var fell: bool=false
				for i: int in 600:
					await physics_frame
					if (player.position-bridge.global_position).dot(direction)*sign>float(c.length_m)*.5+3.8:passed=true;break
					if player.position.y<float(c.water_y)+.15:fell=true;break
				Input.action_release("move_down")
				check(passed and not fell,str(c.id)+" approach to approach direction="+str(sign)+" lane="+str(lane)+" final="+str(player.position))
				await frames(3)
		# All upstream/downstream probes go through the centre of real arch openings, not piers.
		for z: float in ([-6.33,0.0,6.33] if c.id=="PontRouteRoyale" else ([-3.25,3.25] if c.id=="PontMine" else [-1.3,1.3])):
			var local_y: float=float(c.water_y)-bridge.position.y+.10
			var a: Vector3=bridge.to_global(Vector3(-float(c.clear_width_m)*.5-.8,local_y,z))
			var b: Vector3=bridge.to_global(Vector3(float(c.clear_width_m)*.5+.8,local_y,z))
			var query: PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(a,b,1)
			var hit: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(query)
			check(hit.is_empty(),str(c.id)+" open water under bridge z="+str(z)+(" hit="+str(hit.collider.name) if not hit.is_empty() else ""))
	# Sample the visible route curves above terrain for water, obstructing trunks and steep lips.
	player.collision_layer=0;await frames(2)
	var route_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://planning/river-routes-v2.json"))
	var sphere: SphereShape3D=SphereShape3D.new();sphere.radius=.22
	for route: Dictionary in route_data.routes:
		var curve: Curve3D=Curve3D.new();curve.bake_interval=1.0
		for i: int in route.points_xz.size():
			var p: Array=route.points_xz[i];var prev: Array=route.points_xz[maxi(0,i-1)];var next: Array=route.points_xz[mini(i+1,route.points_xz.size()-1)]
			var tangent: Vector3=Vector3(next[0]-prev[0],0,next[1]-prev[1])/6.0;curve.add_point(Vector3(p[0],0,p[1]),-tangent,tangent)
		var blocked: int=0;var wet: int=0;var steep: int=0;var previous: Vector3=Vector3.INF
		var points: PackedVector3Array=curve.get_baked_points()
		for i: int in range(2,points.size()-2):
			var p: Vector3=points[i];p.y=ground.call("height_at_world",p.x,p.z)
			if float(ground.call("water_at_world",p.x,p.z))>p.y+.08:wet+=1
			if previous!=Vector3.INF and absf(p.y-previous.y)>Vector2(p.x-previous.x,p.z-previous.z).length()*.55:
				steep+=1
				if steep<4:print("ROUTE_SLOPE ",route.id," at ",p," previous=",previous)
			previous=p
			var query: PhysicsShapeQueryParameters3D=PhysicsShapeQueryParameters3D.new();query.shape=sphere;query.collision_mask=1;query.transform=Transform3D(Basis.IDENTITY,p+Vector3(0,.90,0))
			var hits: Array[Dictionary]=world.get_world_3d().direct_space_state.intersect_shape(query,1)
			if not hits.is_empty():
				blocked+=1
				if blocked<3:print("ROUTE_OBSTRUCTION ",route.id," at ",p," collider=",hits[0].collider.get_path())
		check(wet==0,str(route.id)+" dry path wet="+str(wet))
		check(blocked==0,str(route.id)+" clear path obstructions="+str(blocked))
		check(steep==0,str(route.id)+" walkable slopes steep="+str(steep))
	print("RIVER_INTEGRATION ","PASS" if failures==0 else "FAIL"," checks=",checks," failures=",failures)
	session.queue_free();await process_frame;quit(0 if failures==0 else 1)
