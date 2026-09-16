extends "res://tools/build_sawmill_assets.gd"
## Small shared places and private yards, outside the working cartways.
var ground: Node3D
func build() -> void:
	_load_materials()
	var world: Node3D=(load("res://scenes/map_plate.tscn") as PackedScene).instantiate();root.add_child(world)
	for i: int in 35:await process_frame
	ground=world.get_node("Terrain")
	_start("cours_et_jardins_scierie","modules","Cours et jardins de la scierie","Puits, potagers, limites des cours et arbres d'ombrage.","Composition du village, positions mondiales.")
	# The communal well sits beside the square, leaving its diagonal cart route open.
	var well: Vector3=at(230.7,-137.8)
	_ring("WellMasonry",well+Vector3(0,.49,0),.86,.60,.98,"stone")
	_cylinder("WellInterior",well+Vector3(0,.11,0),.60,.06,"dark")
	for side: float in [-1.0,1.0]:_beam("WellPosts",well+Vector3(side,0,0),well+Vector3(side,2.3,0),.14,"dark_wood",true)
	_beam("WellWinch",well+Vector3(-1.15,1.9,0),well+Vector3(1.15,1.9,0),.12,"wood")
	_beam("WellRope",well+Vector3(0,.20,0),well+Vector3(0,1.92,0),.027,"rope")
	var shape: CylinderShape3D=CylinderShape3D.new();shape.radius=.86;shape.height=.98
	_collision("Well",shape,Transform3D(Basis.IDENTITY,well+Vector3(0,.49,0)))
	# Three modest enclosed gardens behind the homes, with open gates toward their yards.
	garden(Vector2(202,-155),Vector2(4.4,5.0))
	garden(Vector2(206,-168),Vector2(4.0,4.2))
	garden(Vector2(215,-176),Vector2(4.0,4.0))
	fence(Vector2(206,-141),Vector2(204,-131))
	fence(Vector2(204,-131),Vector2(216,-125))
	fence(Vector2(257,-193),Vector2(249,-198))
	fence(Vector2(237,-205),Vector2(246,-205))
	for p: Vector2 in [Vector2(206,-146),Vector2(215.5,-144)]:
		var q: Vector3=at(p.x,p.y)
		_box("YardBench",Vector3(1.5,.12,.42),q+Vector3(0,.48,0),"wood",Vector3.ZERO,true)
		for x: float in [-.54,.54]:_box("BenchLegs",Vector3(.14,.45,.34),q+Vector3(x,.22,0),"dark_wood")
	for spec: Array in [[200,-145,.75],[204,-177,.85],[219,-121,.62],[238,-155,.60]]:
		var tree: Node3D=(load("res://prototype_3d/assets/library/trees/birch_twin.tscn") as PackedScene).instantiate()
		tree.name="BouleauCour"+str(item.get_child_count());tree.position=at(spec[0],spec[1]);tree.scale=Vector3.ONE*spec[2]
		tree.set_meta("ground_offset",-.02);item.add_child(tree)
	_save()
	assert(ResourceSaver.save(load(OUT+"modules/cours_et_jardins_scierie.tscn"),"res://scenes/sectors/scierie_cours.tscn")==OK)
	world.queue_free();await process_frame;print("SAWMILL_COURTYARDS_OK");quit()

func at(x: float,z: float) -> Vector3:return Vector3(x,ground.call("surface_height_at_world",x,z),z)
func fence(a: Vector2,b: Vector2) -> void:
	var count: int=ceili(a.distance_to(b)/1.7)
	for i: int in count+1:
		var p: Vector2=a.lerp(b,float(i)/count);var q: Vector3=at(p.x,p.y)
		_beam("FencePosts",q-Vector3(0,.1,0),q+Vector3(0,1.05,0),.10,"dark_wood")
		if i<count:
			var r: Vector2=a.lerp(b,float(i+1)/count);var s: Vector3=at(r.x,r.y)
			for y: float in [.38,.83]:_beam("FenceRails",q+Vector3(0,y,0),s+Vector3(0,y,0),.075,"wood",true)
func garden(center: Vector2,size: Vector2) -> void:
	var a: Vector2=center-size*.5;var b: Vector2=center+size*.5
	fence(a,Vector2(b.x,a.y));fence(a,Vector2(a.x,b.y));fence(Vector2(a.x,b.y),b)
	# Leave a 1.5 m gate in the eastern side.
	fence(Vector2(b.x,a.y),Vector2(b.x,center.y-.75));fence(Vector2(b.x,center.y+.75),b)
	for row: int in 3:
		for col: int in 9:
			var p: Vector3=at(center.x-1.0+row*.90,center.y-size.y*.37+col*size.y*.085)
			_box("GardenBed",Vector3(.58,.07,.36),p+Vector3(0,.025,0),"earth")
			var mesh: SphereMesh=SphereMesh.new();mesh.radius=.16;mesh.height=.20;mesh.radial_segments=6;mesh.rings=2
			var leaves: StandardMaterial3D=StandardMaterial3D.new();leaves.albedo_color=Color("617044")
			mats["garden_green"]=leaves
			_mesh("Vegetables",mesh,Transform3D(Basis.IDENTITY,p+Vector3(0,.13,0)),"garden_green")
