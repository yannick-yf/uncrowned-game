extends SceneTree
## Verify the placed village, its hydraulic levels and actual walking access.
var checks: int=0
var failures: int=0
var world: Node3D
var ground: Node3D
var village: Node3D
var camera: Camera3D
var player: CharacterBody3D
var layout: Dictionary={}
var route_curves: Dictionary={}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		print("FAIL ",label)

func run() -> void:
	var plan_path: String="res://planning/farming-town.json"
	check(FileAccess.file_exists(plan_path),"Farming town plan exists")
	if failures>0:
		_finish();return
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(plan_path))
	check(parsed is Dictionary,"Farming plan parses as JSON")
	if not parsed is Dictionary:
		_finish();return
	layout=parsed
	_check_flow_data()
	var packed: PackedScene=load("res://scenes/test_brindle.tscn")
	check(packed!=null,"Workshop play scene loads")
	if packed==null:
		_finish();return
	var session: Node3D=packed.instantiate();root.add_child(session)
	world=session.get_node("World");ground=world.get_node("Terrain")
	player=world.get_node("Characters/Player");camera=world.get_node("PlayerCamera")
	camera.set_process_unhandled_input(false)
	for i: int in 45:await physics_frame
	village=world.get_node_or_null("Decor/VillageFermier")
	check(village!=null,"VillageFermier sector is integrated into the workshop world")
	if village==null:
		session.queue_free();await process_frame;_finish();return
	_check_buildings()
	_check_props_and_crops()
	for route: Dictionary in layout.paths:
		check(route.get("points_xz",[]).size()>=2 and float(route.get("width_m",0))>0,"Authored route "+str(route.id))
		if route.get("points_xz",[]).size()<2:continue
		var curve: Curve3D=_curve(route.points_xz)
		route_curves[route.id]=curve
		_check_route(route,curve)
	_check_route_connections()
	_check_mill()
	_check_well_sightline()
	await _check_door_approaches()
	if route_curves.has("TourDuPuitsEst") and route_curves.has("TourDuPuitsOuest"):
		var loop: Array=_walk_curve(route_curves.TourDuPuitsEst,true)
		loop.append_array(_walk_curve(route_curves.TourDuPuitsOuest,false))
		if not loop.is_empty():loop.append(loop[0])
		check(await walk(loop),"Real player completes the well-square loop")
	else:check(false,"Both paths around the well are present")
	var bridges: Array=layout.get("terrain",{}).get("bridges",[])
	check(bridges.size()==3,"Three connected village crossings")
	for data: Dictionary in bridges:
		var bridge: Node3D=village.get_node_or_null("Ponts/"+str(data.id))
		check(bridge!=null,"Placed bridge "+str(data.id))
		if bridge==null:continue
		check(absf(bridge.global_position.y-float(data.altitude))<.035,str(data.id)+" authored deck altitude")
		var half_length: float=float(data.length_m)*.5
		var crossing: Array=[]
		for z: float in [-half_length-2.5,-half_length+.8,0.,half_length-.8,half_length+2.5]:
			var point: Vector3=bridge.to_global(Vector3(0,0,z));crossing.append([point.x,point.z])
		check(await walk(crossing),str(data.id)+" real player crosses between both banks")
		var center: Vector3=bridge.global_position
		var water: float=_water(center.x,center.z)
		check(water>_ground(center.x,center.z)+.08,str(data.id)+" spans an excavated water channel")
		check(_walk_height(center.x,center.z)>water+.30,str(data.id)+" deck above water")
	Input.action_release("move_down")
	session.queue_free();await process_frame;_finish()

func _finish() -> void:
	print("FARMING_TOWN_CHECK ","PASS" if failures==0 else "FAIL"," checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)

func _ground(x: float,z: float) -> float:
	return float(ground.call("surface_height_at_world",x,z))

func _water(x: float,z: float) -> float:
	return float(ground.call("water_at_world",x,z))

func _check_flow_data() -> void:
	var courses: Array=layout.get("terrain",{}).get("watercourses",[])
	check(courses.size()>=3,"Stream, mill bypass and irrigation channel are authored")
	for course: Dictionary in courses:
		var points: Array=course.get("points_xzy",[])
		var monotone: bool=points.size()>=2
		for i: int in range(1,points.size()):
			monotone=monotone and float(points[i][2])<=float(points[i-1][2])+.002
		check(monotone,str(course.id)+" downstream water never climbs")
		if points.size()>=2:check(float(points[0][2])-float(points[-1][2])>.02,str(course.id)+" has a net downstream fall")
		check(float(course.get("half_width",0))>0 and float(course.get("depth",0))>0,str(course.id)+" channel width and bed depth")
	var main_course: Dictionary=_course("RuisseauDesPres")
	for id: String in ["BiefDuMoulin","RigoleDesVergers"]:
		var branch: Dictionary=_course(id)
		check(not main_course.is_empty() and not branch.is_empty(),id+" connects to the main stream")
		if main_course.is_empty() or branch.is_empty():continue
		var points: Array=branch.points_xzy
		for index: int in [0,points.size()-1]:
			var endpoint: Vector3=Vector3(points[index][0],points[index][2],points[index][1])
			var distance: float=INF
			for main_point: Array in main_course.points_xzy:
				distance=minf(distance,endpoint.distance_to(Vector3(main_point[0],main_point[2],main_point[1])))
			check(distance<.12,id+" shares the main stream's position and water level at endpoint "+str(index))

func _course(id: String) -> Dictionary:
	for course: Dictionary in layout.get("terrain",{}).get("watercourses",[]):
		if str(course.id)==id:return course
	return {}

func _check_buildings() -> void:
	var seen: Dictionary={}
	var foundations: int=0
	check(layout.get("buildings",[]).size()==13,"Thirteen distinct agricultural village buildings")
	for data: Dictionary in layout.get("buildings",[]):
		var complete: bool=data.has("scene") and data.has("size_m") and data.has("bounds_center_m") and data.has("altitude")
		check(complete,str(data.id)+" complete scene, bounds and seating data")
		if not complete:continue
		check(not seen.has(data.scene),str(data.id)+" uses distinct architecture");seen[data.scene]=true
		var obj: Node3D=village.get_node_or_null(str(data.group)+"/"+str(data.id))
		check(obj!=null,str(data.id)+" exists in its planned district")
		if obj==null:continue
		check(absf(obj.global_position.y-float(data.altitude))<.05,str(data.id)+" agrees with planned altitude")
		if str(data.id)=="MoulinDesPres":continue
		foundations+=1
		var low: float=INF;var high: float=-INF;var wet: bool=false
		for x: float in [-.40,0.,.40]:
			for z: float in [-.40,0.,.40]:
				var at: Vector3=obj.to_global(Vector3(float(data.bounds_center_m[0])+float(data.size_m[0])*x,0,float(data.bounds_center_m[2])+float(data.size_m[2])*z))
				var y: float=_ground(at.x,at.z);low=minf(low,y);high=maxf(high,y)
				wet=wet or _water(at.x,at.z)>y+.01
		check(not wet,str(data.id)+" foundation remains dry")
		check(high-obj.global_position.y<.30 and obj.global_position.y-low<.35,str(data.id)+" seated foundation low="+str(low)+" high="+str(high)+" root="+str(obj.global_position.y))
	check(foundations==12,"Twelve dry building foundations examined outside the hydraulic mill")

func _check_props_and_crops() -> void:
	for data: Dictionary in layout.get("props",[]):
		var obj: Node3D=village.get_node_or_null(str(data.group)+"/"+str(data.id))
		check(obj!=null,str(data.id)+" placed prop")
		if obj!=null:check(data.has("altitude") and absf(obj.global_position.y-float(data.get("altitude",INF)))<.05,str(data.id)+" agrees with authored prop altitude")
	for data: Dictionary in layout.get("fields",[]):
		var field: Node3D=village.get_node_or_null("Cultures/"+str(data.id))
		check(field!=null,str(data.id)+" visible crop parcel")
		if field!=null:check(field.find_children("*","CollisionShape3D",true,false).is_empty(),str(data.id)+" crops remain traversable")
	var orchards: Array=layout.get("orchards",[])
	check(not orchards.is_empty(),"Authored orchard groups contain individual trees")
	for data: Dictionary in orchards:
		var orchard: Node3D=village.get_node_or_null("Vergers/"+str(data.id))
		check(orchard!=null,str(data.id)+" placed orchard")
		if orchard==null:continue
		var tree_count: int=data.get("trees",[]).size()
		var colliders: Array[Node]=orchard.find_children("*","CollisionShape3D",true,false)
		var trunk_count: int=0
		for collider: CollisionShape3D in colliders:
			if not collider.disabled and collider.shape is CylinderShape3D:
				var cylinder: CylinderShape3D=collider.shape
				if cylinder.radius>=.10 and cylinder.height>=.70:trunk_count+=1
		check(tree_count>0 and trunk_count>=tree_count,str(data.id)+" every authored tree has a solid trunk: "+str(trunk_count)+" / "+str(tree_count))

func _curve(points: Array) -> Curve3D:
	var result: Curve3D=Curve3D.new();result.bake_interval=.8
	for i: int in points.size():
		var p: Array=points[i];var previous: Array=points[maxi(0,i-1)];var next: Array=points[mini(i+1,points.size()-1)]
		var tangent: Vector3=Vector3(float(next[0])-float(previous[0]),0,float(next[1])-float(previous[1]))/6.0
		result.add_point(Vector3(p[0],0,p[1]),-tangent,tangent)
	return result

func _walk_height(x: float,z: float) -> float:
	var terrain_y: float=_ground(x,z);var water_y: float=_water(x,z)
	var ray: PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(Vector3(x,maxf(terrain_y,water_y)+4.0,z),Vector3(x,terrain_y-.45,z),1,[player.get_rid()])
	var hit: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		var path: String=str(hit.collider.get_path())
		# A railing is an obstacle, never an artificial walkable floor above the road.
		if path.contains("/VillageFermier/Ponts/") and str(hit.collider.name).contains("ContinuousDeck") and hit.normal.y>.7:
			return float(hit.position.y)
	return terrain_y

func _check_route(data: Dictionary,curve: Curve3D) -> void:
	var capsule: CapsuleShape3D=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.3
	var points: PackedVector3Array=curve.get_baked_points()
	var previous: Array[Vector3]=[Vector3.INF,Vector3.INF,Vector3.INF]
	var steep: int=0;var wet: int=0;var blocked: Array[String]=[]
	var gradients: Array[String]=[]
	for i: int in points.size():
		var direction: Vector3=(points[mini(points.size()-1,i+1)]-points[maxi(0,i-1)]).normalized()
		var side: Vector3=Vector3(direction.z,0,-direction.x)
		for lane: int in 3:
			var at: Vector3=points[i]+side*float(data.width_m)*(lane-1)*.25
			at.y=_walk_height(at.x,at.z)
			if _water(at.x,at.z)>at.y+.01:wet+=1
			if previous[lane]!=Vector3.INF:
				var distance: float=Vector2(at.x-previous[lane].x,at.z-previous[lane].z).length()
				if distance>.01 and absf(at.y-previous[lane].y)>distance*.50+.001:
					steep+=1
					if gradients.size()<4:gradients.append(str(previous[lane])+" -> "+str(at)+" grade="+str(absf(at.y-previous[lane].y)/distance))
			previous[lane]=at
			var query: PhysicsShapeQueryParameters3D=PhysicsShapeQueryParameters3D.new()
			query.shape=capsule;query.collision_mask=1;query.exclude=[player.get_rid()]
			query.transform=Transform3D(Basis.IDENTITY,at+Vector3(0,.70,0))
			var hits: Array[Dictionary]=world.get_world_3d().direct_space_state.intersect_shape(query,1)
			if not hits.is_empty() and blocked.size()<4:blocked.append(str(at)+" "+str(hits[0].collider.get_path()))
	check(wet==0 and steep==0 and blocked.is_empty(),str(data.id)+" three-lane access wet="+str(wet)+" steep="+str(steep)+" gradients="+str(gradients)+" collisions="+str(blocked))

func _distance_to_route(point: Vector3,points: PackedVector3Array) -> float:
	var distance: float=INF
	for i: int in range(1,points.size()):
		var nearest: Vector3=Geometry3D.get_closest_point_to_segment(point,points[i-1],points[i])
		distance=minf(distance,point.distance_to(nearest))
	return distance

func _check_route_connections() -> void:
	var ids: Array=route_curves.keys()
	check(not ids.is_empty(),"Village has a road network")
	if ids.is_empty():return
	var graph: Dictionary={}
	for id: String in ids:graph[id]=[]
	for i: int in ids.size():
		var a: PackedVector3Array=(route_curves[ids[i]] as Curve3D).get_baked_points()
		for j: int in range(i+1,ids.size()):
			var c: PackedVector3Array=(route_curves[ids[j]] as Curve3D).get_baked_points()
			var distance: float=minf(minf(_distance_to_route(a[0],c),_distance_to_route(a[-1],c)),minf(_distance_to_route(c[0],a),_distance_to_route(c[-1],a)))
			if distance<=3.0:
				graph[ids[i]].append(ids[j]);graph[ids[j]].append(ids[i])
	var origin: String="RueDuMarche" if route_curves.has("RueDuMarche") else str(ids[0])
	var visited: Dictionary={origin:true};var queue: Array[String]=[origin]
	while not queue.is_empty():
		var current: String=queue.pop_front()
		for neighbour: String in graph[current]:
			if visited.has(neighbour):continue
			visited[neighbour]=true;queue.append(neighbour)
	for id: String in ids:check(visited.has(id),id+" connected to the village by endpoint/projection within 3 m")

func _check_mill() -> void:
	var mill: Node3D=village.get_node_or_null("RiveDuMoulin/MoulinDesPres")
	check(mill!=null,"Hydraulic grain mill exists")
	if mill==null:return
	var markers: bool=mill.has_node("WaterIn") and mill.has_node("WaterOut") and mill.has_node("WheelAxis")
	check(markers,"Mill inlet, outlet and wheel axis markers")
	if not markers:return
	var bypass: Dictionary=_course("BiefDuMoulin")
	for name: String in ["WaterIn","WaterOut"]:
		var point: Vector3=mill.get_node(name).global_position
		check(absf(point.y-30.48)<.035,"Mill "+name+" is at the 30.48 m design water level")
		check(absf(_water(point.x,point.z)-point.y)<.08,"Mill "+name+" matches landscape water")
		check(_ground(point.x,point.z)<point.y-.08,"Mill "+name+" has a channel below the water")
		var nearest: float=INF
		for p: Array in bypass.get("points_xzy",[]):nearest=minf(nearest,point.distance_to(Vector3(p[0],p[2],p[1])))
		check(nearest<.12,"Mill "+name+" aligns with the planned upstream/downstream channel")
	var axis: Vector3=mill.get_node("WheelAxis").global_position
	var immersion: float=_water(axis.x,axis.z)-(axis.y-2.05)
	check(immersion>.05 and immersion<.35,"Undershot wheel dips into the current: "+str(immersion)+" m")

func _check_well_sightline() -> void:
	var well: Node3D=village.get_node_or_null("PlaceDuPuits/PuitsCentral")
	check(well!=null,"Well remains the square's visual landmark")
	if well==null:return
	var viewpoint: Vector3=Vector3(-159,_ground(-159,40)+2.0,40)
	var target: Vector3=well.global_position+Vector3(0,1.55,0)
	var query: PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(viewpoint,target,1,[player.get_rid()])
	var hit: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(query)
	var clear: bool=hit.is_empty() or well.is_ancestor_of(hit.collider)
	check(clear,"Eye-height view from (-159,40) reaches the well"+("" if hit.is_empty() else ": "+str(hit.collider.get_path())))

func _check_door_approaches() -> void:
	# A path that stops outside the existing Entrance marker can pass every road
	# test while leaving an unpainted gap or hiding a sack across the real doorway.
	# Use the native visual threshold and stair foot as independent references.
	var wear: Image=Image.new()
	var wear_error: Error=wear.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/farming_village/ground_wear.png"))
	check(wear_error==OK and not wear.is_empty(),"Village ground-wear PNG decodes for threshold checks: "+str(wear_error))
	var checked_doors: int=0
	var checked_annexes: int=0
	# These annexes have visible doors but no DoorFace marker. Keep the checked
	# facade coordinates independent of the generated path data.
	var annex_faces: Dictionary={"MaisonAppentis":Vector2(2.71,2.06),"MoulinDesPres":Vector2(4.8,2.36)}
	for data: Dictionary in layout.get("buildings",[]):
		var obj: Node3D=village.get_node_or_null(str(data.group)+"/"+str(data.id))
		if obj==null:continue
		var door: Node3D=obj.get_node_or_null("DoorFace")
		check(door!=null,str(data.id)+" native visual doorway marker")
		if door==null:continue
		var front: Vector3=(obj.global_basis*Vector3.BACK).normalized()
		var stair: Node3D=obj.get_node_or_null("StairFoot")
		var stair_base: Node3D=obj.get_node_or_null("StairBase")
		if str(obj.get_meta("building_kind",""))=="raised_granary":check(stair_base!=null,str(data.id)+" native marker locates the visible first stair")
		var open_barn: bool=str(obj.get_meta("building_kind",""))=="open_barn"
		var expected: Vector3=door.global_position if open_barn else door.global_position+front*.42
		if stair!=null:expected=stair.global_position
		var approaches: Array=data.get("door_approaches",[])
		check(not approaches.is_empty(),str(data.id)+" has an authored approach to its real entrance")
		if approaches.is_empty():continue
		checked_doors+=1
		for approach: Array in approaches:
			check(approach.size()>=2,str(data.id)+" usable approach control points")
			if approach.size()<2:continue
			var endpoint: Array=approach[-1]
			var endpoint_xz: Vector2=Vector2(endpoint[0],endpoint[1])
			check(endpoint_xz.distance_to(Vector2(expected.x,expected.z))<.08,str(data.id)+" approach ends at the native threshold or stair foot; end="+str(endpoint_xz)+" expected="+str(Vector2(expected.x,expected.z)))
			var query: PhysicsShapeQueryParameters3D=PhysicsShapeQueryParameters3D.new()
			var capsule: CapsuleShape3D=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.3
			query.shape=capsule;query.collision_mask=1;query.exclude=[player.get_rid()]
			var standing: Vector3=Vector3(expected.x,_walk_height(expected.x,expected.z),expected.z)
			query.transform=Transform3D(Basis.IDENTITY,standing+Vector3(0,.70,0))
			var hits: Array[Dictionary]=world.get_world_3d().direct_space_state.intersect_shape(query,3)
			var obstacles: Array[String]=[]
			for hit: Dictionary in hits:obstacles.append(str(hit.collider.get_path()))
			check(hits.is_empty(),str(data.id)+" actual doorway waiting space is clear for a 0.28 m capsule: "+str(obstacles))
			var curve: Curve3D=_curve(approach)
			var walked: bool=await walk(_walk_curve(curve),.16)
			check(walked,str(data.id)+" real player follows its approach and reaches the entrance")
			if walked:
				check(Vector2(player.global_position.x,player.global_position.z).distance_to(Vector2(expected.x,expected.z))<.22,str(data.id)+" player actually arrives beside the visual doorway")
			if wear!=null and not wear.is_empty():
				var paint_target: Vector3=stair_base.global_position if stair_base!=null else stair.global_position if stair!=null else door.global_position
				var painted: bool=true
				for fraction: float in [0.,.25,.50,.75,1.]:
					painted=painted and _wear_coverage(wear,expected.lerp(paint_target,fraction),front)>.12
				check(painted,str(data.id)+" visible dirt reaches the threshold without a grass gap")
		if stair!=null:
			# The approach alone stops before the stairs. Walk up them as well, so
			# a sack on a tread cannot be overlooked by a ground-level endpoint test.
			var upper: Vector3=door.global_position+front*.42
			var ascent: Array=[[stair.global_position.x,stair.global_position.z],[upper.x,upper.z]]
			var climbed: bool=await walk(ascent,.16)
			check(climbed,str(data.id)+" player climbs the unobstructed grain-store stair")
			if climbed:check(player.global_position.y>obj.global_position.y+.65,str(data.id)+" player reaches the elevated stair rather than standing below it")
		if annex_faces.has(str(data.id)):
			var accesses: Array=data.get("secondary_accesses",[])
			check(accesses.size()==1,str(data.id)+" visible store annex has an authored approach")
			var local_face: Vector2=annex_faces[str(data.id)]
			var annex_face: Vector3=obj.to_global(Vector3(local_face.x,0,local_face.y))
			var annex_target: Vector3=annex_face+front*.42
			for access: Dictionary in accesses:
				var label: String=str(data.id)+"/"+str(access.id)
				var points: Array=access.get("points_xz",[])
				check(points.size()>=2,label+" usable secondary approach")
				if points.size()<2:continue
				checked_annexes+=1
				var end: Vector2=Vector2(points[-1][0],points[-1][1])
				check(end.distance_to(Vector2(annex_target.x,annex_target.z))<.08,label+" reaches the actual annex facade")
				var shape: CapsuleShape3D=CapsuleShape3D.new();shape.radius=.28;shape.height=1.3
				var query: PhysicsShapeQueryParameters3D=PhysicsShapeQueryParameters3D.new()
				query.shape=shape;query.collision_mask=1;query.exclude=[player.get_rid()]
				query.transform=Transform3D(Basis.IDENTITY,Vector3(annex_target.x,_walk_height(annex_target.x,annex_target.z)+.70,annex_target.z))
				var hits: Array[Dictionary]=world.get_world_3d().direct_space_state.intersect_shape(query,3)
				var obstacles: Array[String]=[]
				for hit: Dictionary in hits:obstacles.append(str(hit.collider.get_path()))
				check(hits.is_empty(),label+" store doorway is clear for a 0.28 m capsule: "+str(obstacles))
				var walked: bool=await walk(_walk_curve(_curve(points)),.16)
				check(walked,label+" real player reaches the annex without hitting stored goods")
				if walked:check(Vector2(player.global_position.x,player.global_position.z).distance_to(Vector2(annex_target.x,annex_target.z))<.22,label+" player arrives beside the annex door")
				if wear!=null and not wear.is_empty():
					var painted: bool=true
					for fraction: float in [0.,.25,.50,.75,1.]:painted=painted and _wear_coverage(wear,annex_target.lerp(annex_face,fraction),front)>.12
					check(painted,label+" dirt reaches the visible annex threshold")
	check(checked_doors==13,"All thirteen agricultural buildings have tested doorstep access")
	check(checked_annexes==2,"Both visible store annexes have tested doorstep access")

func _wear_coverage(wear: Image,point: Vector3,front: Vector3) -> float:
	var bounds: Array=layout.bounds_xz
	var side: Vector3=Vector3(front.z,0,-front.x)
	var coverage: float=0.0
	for offset: float in [-.20,0.,.20]:
		var sample: Vector3=point+side*offset
		var u: float=(sample.x-float(bounds[0]))/float(bounds[2])
		var v: float=(sample.z-float(bounds[1]))/float(bounds[3])
		if u<0 or u>=1 or v<0 or v>=1:continue
		var pixel: Vector2i=Vector2i(clampi(roundi(u*wear.get_width()),0,wear.get_width()-1),clampi(roundi(v*wear.get_height()),0,wear.get_height()-1))
		coverage=maxf(coverage,wear.get_pixelv(pixel).r)
	return coverage

func _walk_curve(curve: Curve3D,reverse: bool=false) -> Array:
	var points: Array=[];var length: float=curve.get_baked_length()
	for i: int in ceili(length/2.5)+1:
		var distance: float=minf(i*2.5,length)
		var point: Vector3=curve.sample_baked(length-distance if reverse else distance)
		points.append([point.x,point.z])
	return points

func walk(points: Array,final_radius: float=.42) -> bool:
	if points.size()<2:return false
	var first: Array=points[0]
	player.global_position=Vector3(first[0],_walk_height(first[0],first[1])+.12,first[1]);player.velocity=Vector3.ZERO
	for i: int in 16:await physics_frame
	for index: int in range(1,points.size()):
		var target: Vector2=Vector2(points[index][0],points[index][1]);var reached: bool=false
		for i: int in 500:
			var delta: Vector2=target-Vector2(player.global_position.x,player.global_position.z)
			if delta.length()<(final_radius if index==points.size()-1 else .42):
				reached=true;break
			camera.set("azimuth_degrees",rad_to_deg(atan2(delta.x,delta.y)))
			Input.action_press("move_down");await physics_frame
		Input.action_release("move_down")
		if not reached:
			print("WALK_STOP ",player.global_position," target=",target);return false
	return true
