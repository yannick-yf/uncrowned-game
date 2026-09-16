extends SceneTree
## Geometry, water and real-player access through the fortified capital.
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
	world=session.get_node("World");ground=world.get_node("Terrain");player=world.get_node("Characters/Player");camera=world.get_node("PlayerCamera")
	camera.set_process_unhandled_input(false)
	for i: int in 45:await physics_frame
	var layout: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://planning/royal-city.json"))
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/royal_city/catalog.json"))
	check(manifest.assets.size()==44,"Complete 44-piece native asset kit")
	for asset: Dictionary in manifest.assets:
		check(load(asset.scene) is PackedScene and int(asset.triangles)>0,"Loadable mesh geometry "+asset.id)
	var seen: Dictionary={}
	for b: Dictionary in layout.buildings:
		var obj: Node3D=world.get_node("Decor/VilleRoyale/"+b.group+"/"+b.id)
		check(not seen.has(b.scene),b.id+" distinct architecture");seen[b.scene]=true
		var low: float=INF;var high: float=-INF;var wet: bool=false
		for x: float in [-.40,0,.40]:
			for z: float in [-.40,0,.40]:
				var at: Vector3=obj.to_global(Vector3(b.bounds_center_m[0]+b.size_m[0]*x,0,b.bounds_center_m[2]+b.size_m[2]*z))
				var y: float=ground.call("surface_height_at_world",at.x,at.z);low=minf(low,y);high=maxf(high,y)
				wet=wet or float(ground.call("water_at_world",at.x,at.z))>y
		check(not wet,b.id+" dry foundation")
		check(high-obj.global_position.y<.32 and obj.global_position.y-low<.35,b.id+" seated low="+str(low)+" high="+str(high)+" root="+str(obj.global_position.y))
	for r: Dictionary in layout.paths:_check_route(r)
	var castle: Node3D=world.get_node("Decor/VilleRoyale/Chateau/Citadelle")
	check(castle.global_position.y>=93.9,"Castle terrace above the city")
	var top: float=0
	for m: MeshInstance3D in castle.find_children("*","MeshInstance3D",true,false):top=maxf(top,(m.global_transform*m.get_aabb()).end.y)
	check(top>150,"Keep dominates skyline: "+str(top))
	for local: Vector2 in [Vector2(-36,29),Vector2(-42,4),Vector2(-38,-26),Vector2(-22,-35),Vector2(24,-35),Vector2(41,-14),Vector2(39,13),Vector2(34,29)]:
		var at: Vector3=castle.to_global(Vector3(local.x,0,local.y))
		check(float(ground.call("surface_height_at_world",at.x,at.z))>=79.8,"Castle tower footing supported at "+str(at))

	check(await walk([[-168,-109],[-168,-128],[-168,-139]]),"Real player enters through the royal gate")
	var walking_curve: Curve3D=preload("res://scripts/royal_ascent.gd").curve(layout.ramp_xyz)
	var walking_points: Array=[]
	for i: int in ceili(walking_curve.get_baked_length()/1.5)+1:
		var p: Vector3=walking_curve.sample_baked(minf(i*1.5,walking_curve.get_baked_length()));walking_points.append([p.x,p.z])
	check(await walk(walking_points),"Real player reaches castle courtyard through the switchbacks")
	print("ROYAL_CITY_CHECK ","PASS" if failures==0 else "FAIL"," checks=",checks," failures=",failures)
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
		if previous!=Vector3.INF and absf(center.y-previous.y)>Vector2(center.x-previous.x,center.z-previous.z).length()*.50:
			steep+=1
			print("STEEP ",r.id," ",center," rise=",center.y-previous.y)
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
