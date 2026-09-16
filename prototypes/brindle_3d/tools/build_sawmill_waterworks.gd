extends "res://tools/build_sawmill_assets.gd"
## Saved masonry, millpond gate and flume connection at the approved hydraulic levels.
func build() -> void:
	architecture=load("res://tools/sawmill_architecture.gd").new(self)
	_load_materials()
	mats["water"]=load("res://materials/sawmill_flow.tres")
	var world: Node3D=(load("res://scenes/map_plate.tscn") as PackedScene).instantiate();root.add_child(world)
	for i: int in 35:await process_frame
	var ground: Node3D=world.get_node("Terrain")
	_start("ouvrages_hydrauliques_scierie","modules","Bief et fondations de la scierie","Raccord de la retenue, flume et canal de fuite.","Positions mondiales liées à planning/sawmill-town.json.")
	# Short flume extension overlaps the asset's inlet at Z=-154.25.
	_box("FlumeBed",Vector3(1.1,.13,3.35),Vector3(254.65,48.64,-155.83),"wood")
	for x: float in [254.10,255.20]:_box("FlumeWalls",Vector3(.13,.37,3.35),Vector3(x,48.82,-155.83),"dark_wood")
	_box("SupplyWater",Vector3(.90,.025,3.40),Vector3(254.65,48.775,-155.84),"water")
	for x: float in [253.94,255.36]:
		var base: float=ground.call("surface_height_at_world",x,-155.4)
		_beam("SupplyPosts",Vector3(x,base-.08,-155.4),Vector3(x,48.54,-155.4),.18,"dark_wood",true)
	# Stone shoulders of the intake leave the open water aperture between them.
	for x: float in [252.80,256.5]:
		_box("WeirShoulder",Vector3(2.0,1.25,.62),Vector3(x,48.57,-157.55),"stone",Vector3.ZERO,true)
		_box("WeirCoping",Vector3(2.12,.15,.75),Vector3(x,49.24,-157.55),"stone")
	var gate: Node3D=(load("res://assets/sawmill/modules/vanne_bois.tscn") as PackedScene).instantiate()
	# Save the local open-gate pose, including its collider, while sharing the meshes.
	gate.scene_file_path=""
	gate.position=Vector3(254.65,48.5,-157.55);item.add_child(gate)
	for node: Node3D in gate.find_children("GatePlanks*","Node3D",false,false):node.position.y+=.42
	# The wheel bay has a low stone retaining edge; never dam the outflow.
	for x: float in [253.05,256.35]:
		_box("WheelBayWall",Vector3(.35,.95,8.1),Vector3(x,43.92,-146.5),"stone",Vector3.ZERO,true)
	# Extend the mill's riverside masonry feet to the actual channel bed.
	for x: float in [246.568,253.432]:
		for z: float in [-149.709,-144.291]:
			var base: float=minf(44.18,ground.call("surface_height_at_world",x,z))-.10
			_box("MillFootExtension",Vector3(.50,44.22-base,.50),Vector3(x,(base+44.22)*.5,z),"stone",Vector3.ZERO,true)
	# Bank-side log boom, downstream from the wheel, stays out of its working bay.
	for p: Vector2 in [Vector2(258,-133),Vector2(260,-131)]:
		var base: float=ground.call("surface_height_at_world",p.x,p.y)
		_beam("TailraceGuidePost",Vector3(p.x,base-.2,p.y),Vector3(p.x,44.5,p.y),.14,"dark_wood")
	_save()
	var saved: PackedScene=load(OUT+"modules/ouvrages_hydrauliques_scierie.tscn")
	assert(ResourceSaver.save(saved,"res://scenes/sectors/scierie_eau.tscn")==OK)
	world.queue_free();await process_frame
	print("SAWMILL_WATERWORKS_OK");quit()
