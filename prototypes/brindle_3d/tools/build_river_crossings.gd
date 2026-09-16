extends SceneTree
## Offline composition of selected bridge scenes, terrain-seated paths and local footing extensions.
var world: Node3D
var ground: Node3D
var routes: Array=[]
var curve_samples: Array[Dictionary]=[]
var excluded_trees: Array[Vector2]=[]
var village: Dictionary={}
var removed_instances: int=0
var removed_colliders: int=0

func _initialize() -> void:call_deferred("run")
func run() -> void:
	create_timer(55).timeout.connect(func():push_error("Crossing build timed out");quit(1))
	if DisplayServer.get_name()=="headless":push_error("Use a renderer to preserve MultiMesh buffers");quit(1);return
	world=(load("res://scenes/map_plate.tscn") as PackedScene).instantiate();root.add_child(world)
	ground=world.get_node("Terrain")
	for i: int in 30:await process_frame
	var meta: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/landscape/landscape.json"))
	village=JSON.parse_string(FileAccess.get_file_as_string("res://planning/sawmill-town.json"))
	routes=JSON.parse_string(FileAccess.get_file_as_string("res://planning/river-routes-v2.json")).routes
	var sector: Node3D=Node3D.new();sector.name="Franchissements";world.add_child(sector)
	var bridges: Node3D=Node3D.new();bridges.name="Ponts";sector.add_child(bridges)
	for crossing: Dictionary in meta.crossings:
		var bridge: Node3D=(load("res://assets/bridges/"+str(crossing.asset)+".tscn") as PackedScene).instantiate()
		bridge.name=str(crossing.id);bridges.add_child(bridge)
		bridge.position=Vector3(crossing.center_xyz[0],crossing.center_xyz[1],crossing.center_xyz[2]);bridge.rotation.y=crossing.yaw_radians
		bridge.set_meta("length_m",float(crossing.length_m));bridge.set_meta("label",str(crossing.label))
		var footings: Node3D=Node3D.new();footings.name="Fondations_"+str(crossing.id);footings.transform=bridge.transform;sector.add_child(footings)
		_foundations(footings,crossing)
	var paths: Node3D=Node3D.new();paths.name="Chemins";sector.add_child(paths)
	for route: Dictionary in routes:
		var path: MeshInstance3D=MeshInstance3D.new();path.name=route.id
		path.set_script(load("res://scripts/ground_path.gd"))
		var points: PackedVector2Array=[]
		var curve: Curve3D=Curve3D.new();curve.bake_interval=.75
		for i: int in route.points_xz.size():
			var p: Array=route.points_xz[i];points.append(Vector2(p[0],p[1]))
			var prev: Array=route.points_xz[maxi(0,i-1)];var next: Array=route.points_xz[mini(route.points_xz.size()-1,i+1)]
			var tangent: Vector3=Vector3(next[0]-prev[0],0,next[1]-prev[1])/6.0
			curve.add_point(Vector3(p[0],0,p[1]),-tangent,tangent)
		path.set("points",points);path.set("width_m",float(route.width_m));path.material_override=load("res://materials/brindle_path.tres");paths.add_child(path)
		curve_samples.append({"width":float(route.width_m),"points":curve.get_baked_points()})
	for i: int in 10:await process_frame
	# The path script rebuilds its draped ribbon on load; do not duplicate that cache in Git.
	for path: MeshInstance3D in paths.get_children():path.mesh=null
	_own(sector,sector)
	_save(sector,"res://scenes/sectors/franchissements.tscn")
	_save(world.get_node("Decor/MineAcierie"),"res://scenes/sectors/mine_acierie.tscn")
	# Remove only vegetation newly inside water or a crossing approach; preserve the composition elsewhere.
	for name: String in ["ForetsBrindle","ForetsNordEst"]:
		var forest: Node3D=world.get_node("Decor/"+name)
		var removed_before: int=removed_instances+removed_colliders
		_clear_vegetation(forest)
		if removed_before==removed_instances+removed_colliders:continue
		_save(forest,"res://scenes/sectors/"+("forets_brindle.tscn" if name=="ForetsBrindle" else "forets_nord_est.tscn"))
	print("RIVER_CROSSINGS_BUILD_OK bridges=",meta.crossings.size()," routes=",routes.size()," removed_visual_instances=",removed_instances," removed_trunks=",removed_colliders)
	world.queue_free();await process_frame;quit(0)

func _save(node: Node,path: String) -> void:
	var scene: PackedScene=PackedScene.new();assert(scene.pack(node)==OK);assert(ResourceSaver.save(scene,path)==OK)
func _own(node: Node,base: Node) -> void:
	for child: Node in node.get_children():
		child.owner=base
		if child.scene_file_path.is_empty():_own(child,base)

func _foundations(parent: Node3D,crossing: Dictionary) -> void:
	var length: float=float(crossing.length_m);var width: float=float(crossing.clear_width_m)
	var positions: Array[Vector3]=[];var sizes: Array[Vector2]=[]
	var stone: bool=str(crossing.asset).begins_with("pierre/")
	for side: float in [-1.0,1.0]:positions.append(Vector3(0,-3.3,side*(length*.5-.42)));sizes.append(Vector2(width+.85,.85))
	if stone:
		if length>18:
			for z: float in [-3.16667,3.16667]:positions.append(Vector3(0,-3.3,z));sizes.append(Vector2(width+.9,1.10))
		else:positions.append(Vector3(0,-3.3,0));sizes.append(Vector2(width+.9,1.10))
	else:
		var zs: Array=[-2.0,2.0] if length>10 else [0.0]
		for z: float in zs:
			for side: float in [-1.0,1.0]:positions.append(Vector3(side*(width*.39+.25),-3.3,z));sizes.append(Vector2(.48,.48))
	for i: int in positions.size():
		var p: Vector3=positions[i];var at: Vector3=parent.to_global(p)
		var floor_y: float=float(ground.call("height_at_world",at.x,at.z))-.25
		var height: float=at.y-floor_y+.04
		if height<.06:continue
		var body: StaticBody3D=StaticBody3D.new();body.name="Appui_%02d"%i;body.position=p-Vector3(0,height*.5-.02,0);body.collision_mask=0;parent.add_child(body)
		var box: BoxMesh=BoxMesh.new();box.size=Vector3(sizes[i].x,height,sizes[i].y)
		var mesh: MeshInstance3D=MeshInstance3D.new();mesh.mesh=box;mesh.material_override=load("res://assets/bridges/materials/stone.tres");body.add_child(mesh)
		var collider: CollisionShape3D=CollisionShape3D.new();var shape: BoxShape3D=BoxShape3D.new();shape.size=box.size;collider.shape=shape;body.add_child(collider)

func _clear_at(p: Vector3,padding: float=1.5) -> bool:
	var h: float=ground.call("height_at_world",p.x,p.z);var w: float=ground.call("water_at_world",p.x,p.z)
	if w>0 and h<w+.60:return true
	for route: Dictionary in curve_samples:
		for sample: Vector3 in route.points:
			if Vector2(sample.x-p.x,sample.z-p.z).length()<float(route.width)*.5+padding:return true
	for b: Dictionary in village.get("buildings",[])+village.get("props",[]):
		var at: Vector3=Vector3(b.xz[0],0,b.xz[1])
		var local: Vector3=Basis(Vector3.UP,-deg_to_rad(b.yaw))*(p-at)
		if absf(local.x-b.bounds_center_m[0])<b.size_m[0]*.5+2.4 and absf(local.z-b.bounds_center_m[2])<b.size_m[2]*.5+2.4:return true
	for r: Dictionary in village.get("paths",[]):
		for i: int in range(1,r.points_xz.size()):
			var a: Vector2=Vector2(r.points_xz[i-1][0],r.points_xz[i-1][1]);var b: Vector2=Vector2(r.points_xz[i][0],r.points_xz[i][1])
			if Geometry2D.get_closest_point_to_segment(Vector2(p.x,p.z),a,b).distance_to(Vector2(p.x,p.z))<r.width_m*.5+padding+1.0:return true
	return false

func _clear_vegetation(forest: Node3D) -> void:
	for node: Node in forest.find_children("*","CollisionShape3D",true,false):
		if node.has_meta("ground_offset") and _clear_at(node.global_position):
			excluded_trees.append(Vector2(node.global_position.x,node.global_position.z));node.get_parent().remove_child(node);node.free();removed_colliders+=1
	for batch: MultiMeshInstance3D in forest.find_children("*","MultiMeshInstance3D",true,false):
		if not batch.has_meta("ground_batch"):continue
		batch.remove_meta("private_buffer")
		var kept: Array[Transform3D]=[]
		for i: int in batch.multimesh.instance_count:
			var tr: Transform3D=batch.multimesh.get_instance_transform(i)
			var world_at: Vector3=batch.global_transform*tr.origin
			if _clear_at(world_at):removed_instances+=1;continue
			kept.append(tr)
		if kept.size()==batch.multimesh.instance_count:continue
		var copy: MultiMesh=batch.multimesh.duplicate();copy.instance_count=kept.size()
		for i: int in kept.size():copy.set_instance_transform(i,kept[i])
		batch.multimesh=copy
