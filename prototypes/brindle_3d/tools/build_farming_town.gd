extends "res://tools/build_farming_assets.gd"
## Offline composition on the actual terrain. Run WITH graphics for MultiMesh saves.
const TOWN_OUT: String="res://assets/farming_village/"
var layout: Dictionary
var asset_catalog: Dictionary={}
var sector: Node3D
var ground: Node3D
var world: Node3D

func build() -> void:
	layout=JSON.parse_string(FileAccess.get_file_as_string("res://planning/farming-town.json"))
	for a: Dictionary in JSON.parse_string(FileAccess.get_file_as_string("res://assets/farming/catalog.json")).assets:asset_catalog[a.id]=a
	for path: String in DirAccess.get_files_at("res://assets/farming/materials"):
		if path.ends_with(".tres"):mats[path.get_basename()]=load("res://assets/farming/materials/"+path)
	DirAccess.make_dir_recursive_absolute(TOWN_OUT+"meshes")
	# Load the map to use exactly the terrain/collision surface seen in game.
	world=(load("res://scenes/map_plate.tscn") as PackedScene).instantiate()
	# Runtime light/foliage overrides must never be baked into source village assets.
	var atmosphere: Node=world.get_node_or_null("FarmingAtmosphere")
	if atmosphere!=null:atmosphere.free()
	root.add_child(world)
	ground=world.get_node("Terrain")
	for i: int in 6:await process_frame
	var old: Node=world.get_node_or_null("Decor/VillageFermier")
	if "--greenery-only" in OS.get_cmdline_user_args():
		assert(old is Node3D,"An existing farming village is required for a vegetation-only rebuild")
		sector=old as Node3D
		var previous: Node=sector.get_node_or_null("Verdure")
		if previous!=null:previous.free()
		load("res://tools/farming_village_greenery.gd").new(self).build()
		# Keep the original linked building ownership; own only the replaced group.
		var greenery: Node=sector.get_node("Verdure")
		greenery.owner=sector;_own(greenery,sector)
		var updated: PackedScene=PackedScene.new();assert(updated.pack(sector)==OK)
		assert(ResourceSaver.save(updated,"res://scenes/sectors/village_fermier.tscn")==OK)
		print("FARM_TOWN_GREENERY_BUILD_OK");quit();return
	if old!=null:old.free()
	sector=Node3D.new();sector.name="VillageFermier";root.add_child(sector)
	sector.set_meta("layout_source","res://planning/farming-town.json")
	for b: Dictionary in layout.buildings:place(b,true)
	for p: Dictionary in layout.props:place(p,false)
	for bridge: Dictionary in layout.terrain.bridges:
		var node: Node3D=(load(bridge.scene) as PackedScene).instantiate();node.name=bridge.id;group("Ponts").add_child(node)
		node.position=Vector3(bridge.xz[0],bridge.altitude,bridge.xz[1]);node.rotation_degrees.y=bridge.yaw
		node.set_meta("farm_bridge",true)
	# Keep path handles editable; the wear itself is painted onto terrain.
	for r: Dictionary in layout.paths:
		var route: MeshInstance3D=MeshInstance3D.new();route.name=r.id;route.set_script(load("res://scripts/ground_path.gd"))
		var points:=PackedVector2Array()
		for p: Array in r.points_xz:points.append(Vector2(p[0],p[1]))
		route.set("points",points);route.set("width_m",r.width_m);route.visible=false;group("Chemins").add_child(route)
	for p: Dictionary in layout.dressing:
		if p.id!="VanneIrrigation":p.altitude=ground.call("surface_height_at_world",p.xz[0],p.xz[1])
	_start("MobilierVillageFermier","village","Village furniture","Market, rest and orientation","Authored layout")
	load("res://tools/farming_village_details.gd").new(self).build()
	_commit_details()
	load("res://tools/farming_village_planting.gd").new(self).build()
	if FileAccess.file_exists("res://tools/farming_village_greenery.gd"):
		load("res://tools/farming_village_greenery.gd").new(self).build()
	var mill: Node3D=sector.get_node("RiveDuMoulin/MoulinDesPres")
	var motion:=Node3D.new();motion.name="AnimationRoue";motion.set_script(load("res://scripts/farming_mill.gd"));mill.add_child(motion)
	# Give the added animation explicit ownership inside an otherwise linked prefab.
	_own(sector,sector);motion.owner=sector
	var packed:=PackedScene.new();assert(packed.pack(sector)==OK)
	assert(ResourceSaver.save(packed,"res://scenes/sectors/village_fermier.tscn")==OK)
	var plan_file: FileAccess=FileAccess.open("res://planning/farming-town.json",FileAccess.WRITE)
	plan_file.store_string(JSON.stringify(layout,"  "));plan_file.close()
	print("FARM_TOWN_BUILD_OK buildings=",layout.buildings.size()," fields=",layout.fields.size()," bridges=",layout.terrain.bridges.size())
	quit()

func group(label: String) -> Node3D:
	var result: Node3D=sector.get_node_or_null(NodePath(label))
	if result==null:result=Node3D.new();result.name=label;sector.add_child(result)
	return result

func place(spec: Dictionary,building: bool) -> void:
	var node: Node3D=(load(asset_catalog[spec.asset].scene) as PackedScene).instantiate()
	node.name=spec.id;group(spec.group).add_child(node)
	var y: float=float(spec.altitude) if building else float(ground.call("surface_height_at_world",spec.xz[0],spec.xz[1]))
	spec.altitude=y
	node.position=Vector3(spec.xz[0],y,spec.xz[1]);node.rotation_degrees.y=spec.yaw
	node.set_meta("farm_layout_id",spec.id)

func _commit_details() -> void:
	for key: String in batches:
		var data: Dictionary=batches[key];var st: SurfaceTool=data.tool;st.generate_normals();st.index()
		var mesh: ArrayMesh=st.commit();var path: String=TOWN_OUT+"meshes/furniture_"+key+".res"
		assert(ResourceSaver.save(mesh,path,ResourceSaver.FLAG_COMPRESS)==OK)
		var node:=MeshInstance3D.new();node.name=key.to_pascal_case();node.mesh=load(path);node.material_override=data.material;item.add_child(node)
	item.reparent(sector);item.name="Mobilier"
