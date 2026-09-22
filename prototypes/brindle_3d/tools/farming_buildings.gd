extends RefCounted
## Original rural architecture. Ground pivots, metres and +Z entrance faces.
## Closed houses are exterior shells; open barns retain their cart aisle.
var b: Variant

func _init(builder: Variant) -> void:
	b = builder

func build() -> void:
	_house("chaumiere_du_potager", "Chaumière du potager", 0)
	_house("maison_a_appentis", "Maison à appentis", 1)
	_house("longere_des_moissons", "Longère des moissons", 2)
	_house("ferme_en_l", "Ferme en L", 3)
	_house("maison_du_verger", "Maison du verger", 4)
	_house("logis_a_auvent", "Logis à auvent", 5)
	_house("maison_a_pignon_decale", "Maison au pignon décalé", 6)
	_house("logis_des_journaliers", "Logis des journaliers", 7)
	_barn(false)
	_barn(true)
	_granary()
	_grain_store()
	_mill()
	_wheel_asset()
	_headrace_asset()

func _house(id: String, label: String, design: int) -> void:
	b._start(id, "maisons", label, "Habitation rurale extérieure fermée, à disposer dans le quartier habité.", "Entrée +Z, sol sec et presque plat; ménager 1,2 m devant le repère Entrance.")
	b.item.set_meta("building_kind", "rural_house")
	b.item.set_meta("building_design", ["porche_latéral", "appentis_de_bois", "longère_transversale", "plan_en_L", "deux_volumes_étagés", "galerie_de_façade", "faîtage_décalé", "porche_en_avancée"][design])
	match design:
		0:
			_volume(Vector3.ZERO, 5.4, 4.8, 2.65, 2.15)
			_front_door(Vector3(-.55, .08, 2.48), 1.0, 1.91)
			_front_window(Vector3(1.54, 1.53, 2.43), .66)
			_porch(Vector3(-.55, 0, 3.12), 2.05, 1.3, 2.18, .65)
			_chimney(Vector3(1.63, 1.6, -.70), 3.35)
			_bench(Vector3(1.6, 0, 2.85), 1.45)
		1:
			_volume(Vector3(-1.05, 0, 0), 5.1, 5.6, 2.95, 2.35)
			_lean_store(Vector3(2.71, 0, -.3), 2.42, 4.5, 2.20, .72)
			_front_door(Vector3(-1.55, .08, 2.88), 1.02, 1.98)
			_front_window(Vector3(.25, 1.6, 2.83), .62)
			_chimney(Vector3(-2.05, 1.8, -1.45), 3.80)
			b._barrel(Vector3(4.05, 0, 2.35), .82)
		2:
			_volume(Vector3.ZERO, 10.1, 4.9, 2.72, 2.18, true)
			_front_door(Vector3(-1.75, .07, 2.53), 1.06, 1.97)
			_front_window(Vector3(-3.55, 1.51, 2.48), .60)
			_front_window(Vector3(.42, 1.51, 2.48), .64)
			_front_window(Vector3(3.2, 1.51, 2.48), .57)
			_chimney(Vector3(2.28, 1.75, -.50), 3.70)
			_bench(Vector3(1.25, 0, 2.9), 1.8)
		3:
			_volume(Vector3(.9, 0, -.65), 6.0, 5.7, 3.05, 2.55)
			_volume(Vector3(-3.18, 0, 1.55), 3.72, 7.05, 2.62, 1.75)
			_front_door(Vector3(1.00, .08, 2.28), 1.1, 2.04)
			_front_window(Vector3(2.68, 1.57, 2.23), .64)
			_front_window(Vector3(-3.18, 1.45, 5.12), .58)
			_chimney(Vector3(2.35, 1.65, -1.40), 4.10)
			_bench(Vector3(-.30, 0, 3.40), 1.25)
		4:
			_volume(Vector3(-1.2, 0, -.45), 4.7, 5.4, 3.65, 2.3)
			_volume(Vector3(2.26, 0, .60), 2.75, 4.45, 2.4, 1.4)
			_front_door(Vector3(-1.6, .08, 2.33), .98, 1.97)
			_front_window(Vector3(.15, 1.56, 2.28), .54)
			_front_window(Vector3(-1.30, 2.83, 2.28), .51)
			_front_window(Vector3(2.30, 1.40, 2.87), .53)
			_chimney(Vector3(-2.05, 2.6, -.95), 3.80)
			b._barrel(Vector3(3.25, 0, 3.17), .8)
		5:
			_volume(Vector3.ZERO, 6.6, 5.4, 2.87, 2.55)
			_front_door(Vector3(-1.10, .08, 2.78), 1.05, 2.0)
			_front_window(Vector3(1.60, 1.56, 2.73), .65)
			_porch(Vector3(0, 0, 3.48), 6.15, 1.55, 2.35, .6)
			_chimney(Vector3(-1.60, 1.80, -.95), 3.95)
			_bench(Vector3(1.55, 0, 3.23), 1.70)
		6:
			_volume(Vector3.ZERO, 5.8, 5.3, 3.12, 2.45, false, .77)
			_front_door(Vector3(.75, .08, 2.73), 1.02, 2.02)
			_front_window(Vector3(-1.48, 1.58, 2.68), .68)
			_front_window(Vector3(.77, 3.82, 2.68), .48)
			_chimney(Vector3(-1.50, 1.80, -.35), 3.45)
			b._barrel(Vector3(-2.18, 0, 3.03), .9)
		7:
			_volume(Vector3.ZERO, 6.8, 5.8, 3.35, 2.52)
			_volume(Vector3(1.35, 0, 3.55), 2.65, 2.80, 2.3, 1.48)
			_front_door(Vector3(1.35, .08, 5.03), 1.10, 1.95)
			_front_window(Vector3(-1.67, 1.55, 2.95), .61)
			_front_window(Vector3(-1.67, 2.72, 2.95), .47)
			_chimney(Vector3(-1.75, 2.0, -.65), 4.0)
			_bench(Vector3(-1.40, 0, 3.48), 1.9)
	b._save()

func _volume(at: Vector3, width: float, depth: float, height: float, rise: float, transverse: bool=false, ridge_offset: float=0.0, boarded: bool=false) -> void:
	# A single closed collider avoids cracks between decorative wall panels.
	b._box("Footing", Vector3(width+.15, .24, depth+.15), at+Vector3(0,.12,0), "stone", Vector3.ZERO, true)
	b._box("WallCore", Vector3(width, height-.24, depth), at+Vector3(0,(height+.24)*.5,0), "wood" if boarded else "pale_plaster", Vector3.ZERO, true)
	b._box("StonePlinth", Vector3(width+.025, .48, depth+.025), at+Vector3(0,.42,0), "stone")
	for x: float in [-width*.5, width*.5]:
		for z: float in [-depth*.5, depth*.5]:
			b._beam("CornerPosts", at+Vector3(x,.6,z), at+Vector3(x,height+.025,z), .18, "dark_wood")
	for z: float in [-depth*.5-.015, depth*.5+.015]:
		b._beam("WallPlates", at+Vector3(-width*.5,height,z), at+Vector3(width*.5,height,z), .16,"dark_wood")
		b._beam("SoleRails", at+Vector3(-width*.5,.68,z), at+Vector3(width*.5,.68,z), .12,"wood")
		for side: float in [-1.0, 1.0]:
			b._beam("CornerBraces", at+Vector3(side*(width*.5-.12),height-.65,z), at+Vector3(side*(width*.5-.75),height-.05,z), .10,"wood")
	for side: float in [-1.0, 1.0]:
		b._beam("SidePlates",at+Vector3(side*width*.5,height,-depth*.5),at+Vector3(side*width*.5,height,depth*.5),.16,"dark_wood")
		b._beam("SideSoleRails",at+Vector3(side*width*.5,.68,-depth*.5),at+Vector3(side*width*.5,.68,depth*.5),.12,"wood")
		for z: float in [-depth*.22, depth*.22]:
			var saved: Transform3D = b.model_transform
			b.model_transform = saved*Transform3D(Basis(Vector3.UP, side*PI*.5),at+Vector3(side*width*.5,0,z))
			if not boarded:_front_window(Vector3(0,1.52,.02), .51)
			b.model_transform = saved
	var previous: Transform3D = b.model_transform
	b.model_transform = previous*Transform3D(Basis(Vector3.UP, PI*.5 if transverse else 0),at)
	var rw: float = depth if transverse else width
	var rd: float = width if transverse else depth
	_gables(rw,rd,height,rise,ridge_offset,"wood" if boarded else "pale_plaster")
	if absf(ridge_offset)>.01:_offset_roof(rw,rd,height,rise,ridge_offset)
	else:b._roof(Vector3.ZERO,rw,rd,height,rise,"thatch")
	b.model_transform = previous

func _gables(width: float, depth: float, eave: float, rise: float, offset: float=0, mat: String="pale_plaster") -> void:
	var st: SurfaceTool = b._surface("Gables", mat)
	for side: float in [-1.0, 1.0]:
		var z: float = side*(depth*.5+.02)
		var left: Vector3 = Vector3(-width*.5,eave,z)
		var right: Vector3 = Vector3(width*.5,eave,z)
		var apex: Vector3 = Vector3(offset,eave+rise,z)
		if side>0:b._tri(st,left,apex,right)
		else:b._tri(st,right,apex,left)
		b._beam("GableTie",left, right,.15,"dark_wood")
		b._beam("GableFrame",left,apex,.14,"wood")
		b._beam("GableFrame",right,apex,.14,"wood")
		b._beam("GableKingpost",Vector3(offset,eave,z),apex,.12,"dark_wood")
		for t: float in [.25,.75]:
			var x: float = lerpf(-width*.5,width*.5,t)
			var fraction: float = (x+width*.5)/(offset+width*.5) if x<offset else (width*.5-x)/(width*.5-offset)
			b._beam("GableStuds", Vector3(x,eave,z),Vector3(x,eave+rise*fraction,z),.095,"wood")

func _offset_roof(width: float, depth: float, eave: float, rise: float, offset: float) -> void:
	# Modest asymmetric rural ridge; thick continuous thatch with a dressed edge.
	for side: float in [-1.0,1.0]:
		var edge: float = side*(width*.5+.36)
		var distance: float = absf(edge-offset)
		var angle: float = atan2(rise,distance)
		b._box("ThatchSlope", Vector3(Vector2(distance,rise).length(),.25,depth+.72),Vector3((edge+offset)*.5,eave+rise*.5,0),"thatch",Vector3(0,0,-side*angle))
		for z: float in [-depth*.5-.33,depth*.5+.33]:
			b._beam("ThatchVerge",Vector3(edge,eave,z),Vector3(offset,eave+rise,z),.23,"thatch_dark")
		for fraction: float in [.24,.50,.76]:
			var x: float = lerpf(edge,offset,fraction)
			b._beam("ThatchBindings",Vector3(x,eave+rise*fraction+.16,-depth*.5-.30),Vector3(x,eave+rise*fraction+.16,depth*.5+.30),.045,"thatch_dark")
	b._beam("ThatchedRidge",Vector3(offset,eave+rise+.13,-depth*.5-.34),Vector3(offset,eave+rise+.13,depth*.5+.34),.32,"thatch_dark")

func _front_door(at: Vector3, width: float, height: float) -> void:
	b._door(at,width,height)
	b._box("Threshold",Vector3(width+.33,.10,.30),at+Vector3(0,-.025,.15),"stone")

func _front_window(at: Vector3, width: float) -> void:
	b.architecture.window(at,width,.68 if width>.55 else .59)

func _chimney(at: Vector3, height: float) -> void:
	# Simple substantial plastered flue, with protected stone cap and a dark opening.
	b._box("ChimneyShaft",Vector3(.67,height,.65),at+Vector3(0,height*.5,0),"stone")
	for z: float in [-.31,.31]:b._box("ChimneyCap",Vector3(.86,.15,.19),at+Vector3(0,height+.08,z),"stone")
	for x: float in [-.34,.34]:b._box("ChimneyCap",Vector3(.18,.15,.5),at+Vector3(x,height+.08,0),"stone")
	b._box("ChimneyOpening",Vector3(.47,.02,.42),at+Vector3(0,height+.025,0),"dark")

func _porch(at: Vector3, width: float, depth: float, eave: float, rise: float) -> void:
	for x: float in [-width*.5+.11,width*.5-.11]:
		var p: Vector3 = at+Vector3(x,0,depth*.5-.08)
		b._box("PorchFoot",Vector3(.34,.21,.34),p+Vector3(0,.105,0),"stone",Vector3.ZERO,true)
		b._beam("PorchPost",p+Vector3(0,.20,0),p+Vector3(0,eave,0),.16,"wood",true)
		b._beam("PorchBrace",p+Vector3(0,eave-.55,0),p+Vector3(-signf(x)*.52,eave,0),.09,"wood")
	var slope: float = atan2(rise,depth)
	b._box("PorchThatch",Vector3(width+.28,.23,Vector2(depth,rise).length()+.2),at+Vector3(0,eave+rise*.5,0),"thatch",Vector3(slope,0,0))
	b._beam("PorchFrontRail",at+Vector3(-width*.5,eave,depth*.5),at+Vector3(width*.5,eave,depth*.5),.16,"wood")

func _lean_store(at: Vector3,width: float,depth: float,eave: float,rise: float) -> void:
	b._box("StorePlinth",Vector3(width+.1,.2,depth+.1),at+Vector3(0,.1,0),"stone",Vector3.ZERO,true)
	b._box("StoreWalls",Vector3(width,eave,depth),at+Vector3(0,eave*.5,0),"wood",Vector3.ZERO,true)
	for x: float in [-width*.5,width*.5]:
		for z: float in [-depth*.5,depth*.5]:b._beam("StorePosts",at+Vector3(x,.1,z),at+Vector3(x,eave,z),.15,"dark_wood")
	var slope: float = atan2(rise,width)
	b._box("StoreThatch",Vector3(Vector2(width,rise).length()+.30,.26,depth+.45),at+Vector3(0,eave+rise*.5,0),"thatch",Vector3(0,0,-slope))
	# Thin triangular cheeks keep this lean-to weather-tight.
	var st: SurfaceTool = b._surface("StoreGables","wood")
	for side: float in [-1.0,1.0]:
		var a: Vector3 = at+Vector3(-width*.5,eave,side*depth*.5)
		var c: Vector3 = at+Vector3(width*.5,eave,side*depth*.5)
		var high: Vector3 = at+Vector3(-width*.5,eave+rise,side*depth*.5)
		if side>0:b._tri(st,a,high,c)
		else:b._tri(st,c,high,a)
	b._box("StoreDoor",Vector3(.92,1.66,.10),at+Vector3(0,.92,depth*.5+.055),"dark_wood")
	for y: float in [.49,1.48]:b._box("StoreDoorRail",Vector3(.93,.09,.04),at+Vector3(0,y,depth*.5+.125),"wood")

func _bench(at: Vector3,width: float) -> void:
	b._box("BenchSeat",Vector3(width,.11,.42),at+Vector3(0,.47,0),"wood",Vector3.ZERO,true)
	for x: float in [-width*.36,width*.36]:b._box("BenchFeet",Vector3(.15,.42,.37),at+Vector3(x,.21,0),"dark_wood")

func _barn(large: bool) -> void:
	var id: String = "grange_traversante" if large else "grange_a_foin_ouverte"
	b._start(id,"agricole","Grange traversante à charrettes" if large else "Grange ouverte à foin","Stockage couvert avec nef centrale réellement praticable.","Terrain sec; maintenir libre l'axe Entrance–Exit et son passage de 3,2 m minimum.")
	b.item.set_meta("building_kind","open_barn")
	b.item.set_meta("aisle_clear_width_m",3.2 if large else 3.4)
	b.item.set_meta("aisle_clear_height_m",3.3 if large else 2.75)
	var width: float = 9.2 if large else 7.4
	var depth: float = 10.8 if large else 6.6
	var height: float = 4.1 if large else 3.25
	var rise: float = 2.80 if large else 2.30
	for x: float in [-width*.5,width*.5]:
		for z: float in [-depth*.5,0.0,depth*.5]:
			b._box("BarnStoneFeet",Vector3(.54,.42,.54),Vector3(x,.21,z),"stone",Vector3.ZERO,true)
			b._beam("BarnPosts",Vector3(x,.35,z),Vector3(x,height,z),.24,"dark_wood",true)
			b._beam("BarnKneeBraces",Vector3(x,height-.75,z),Vector3(x-signf(x)*.7,height,z),.15,"wood")
		b._beam("BarnLongPlate",Vector3(x,height,-depth*.5),Vector3(x,height,depth*.5),.24,"dark_wood")
		b._box("BarnLowSideWall",Vector3(.20,1.20,depth),Vector3(x,.60,0),"wood",Vector3.ZERO,true)
		if large:
			b._box("BarnSideBoards",Vector3(.16,height-1.20,depth),Vector3(x,(height+1.20)*.5,0),"wood")
			for z: float in [-depth*.35,depth*.35]:b._beam("BarnSideDiagonal",Vector3(x-.04,.8,z-1.3),Vector3(x-.04,height-.2,z+1.3),.13,"dark_wood")
	for z: float in [-depth*.5,0.0,depth*.5]:
		b._beam("BarnTieBeams",Vector3(-width*.5,height,z),Vector3(width*.5,height,z),.23,"dark_wood")
		b._beam("BarnKingPosts",Vector3(0,height,z),Vector3(0,height+rise,z),.18,"wood")
		for side: float in [-1.0,1.0]:b._beam("BarnRafters",Vector3(side*width*.5,height,z),Vector3(0,height+rise,z),.19,"wood")
	b._roof(Vector3.ZERO,width,depth,height,rise,"thatch")
	_gables(width,depth,height,rise,0,"wood")
	# Side stacks sit outside the complete central aisle. No collider spans the doors.
	for side: float in [-1.0,1.0]:
		b._box("RaisedStorageDeck",Vector3(1.55,.18,depth*.66),Vector3(side*(width*.5-1.0),.09,0),"wood",Vector3.ZERO,true)
		for z: float in [-depth*.23,depth*.10]:
			b._box("LooseHay",Vector3(1.35,.75,1.45),Vector3(side*(width*.5-1.0),.57,z),"straw",Vector3(0,side*.06,0),true)
			for r: float in [-.4,.4]:b._beam("HayTies",Vector3(side*(width*.5-1.0)+r,.94,z-.73),Vector3(side*(width*.5-1.0)+r,.94,z+.73),.035,"rope")
	if large:
		# Open door leaves folded along the facade, not across the central route.
		for side: float in [-1.0,1.0]:
			for end: float in [-1.0,1.0]:
				var x: float = side*2.95
				var z: float = end*(depth*.5+.13)
				b._box("FoldedBarnDoor",Vector3(2.1,3.25,.16),Vector3(x,1.625,z),"wood",Vector3.ZERO,true)
				b._beam("BarnDoorBrace",Vector3(x-.90,.2,z+end*.09),Vector3(x+.90,3.05,z+end*.09),.13,"dark_wood")
		# A partial side loft leaves the tall through route open.
		b._box("SideHayLoft",Vector3(2.6,.19,depth*.82),Vector3(-3.12,3.34,0),"wood")
	b._marker("Entrance",Vector3(0,0,depth*.5+1.0))
	b._marker("DoorFace",Vector3(0,0,depth*.5))
	b._marker("Exit",Vector3(0,0,-depth*.5-1.0))
	b._marker("AisleStart",Vector3(0,0,depth*.5+1.0))
	b._marker("AisleEnd",Vector3(0,0,-depth*.5-1.0))
	b._marker("AisleCenter",Vector3.ZERO)
	b._save()

func _granary() -> void:
	b._start("grenier_sur_piliers","agricole","Grenier sur piliers de pierre","Grenier sec et ventilé, surélevé pour limiter l'humidité et l'accès des rongeurs.","Sur sol sec près des champs; entrée +Z par escalier de 1,3 m.")
	b.item.set_meta("building_kind","raised_granary")
	for x: float in [-1.80,1.80]:
		for z: float in [-2.0,0.0,2.0]:
			b._cylinder("StaddleStone",Vector3(x,.43,z),.25,.86,"stone",.20,Vector3.ZERO,true)
			b._cylinder("RodentCap",Vector3(x,.87,z),.46,.15,"stone",.37)
	b._box("GranaryFloor",Vector3(4.6,.26,4.85),Vector3(0,1.06,0),"dark_wood",Vector3.ZERO,true)
	_volume(Vector3(0,1.17,0),4.35,4.6,2.55,2.15,false,0,true)
	_front_door(Vector3(0,1.25,2.38),1.15,1.9)
	for x: float in [-1.2,1.2]:
		b._box("VentRecess",Vector3(.45,.34,.035),Vector3(x,3.17,2.36),"dark")
		for y: float in [-.10,0.0,.10]:b._box("VentSlats",Vector3(.49,.07,.07),Vector3(x,3.17+y,2.4),"wood",Vector3(.22,0,0))
	for i: int in 6:
		var high: float = (6-i)*.205
		b._box("GranarySteps",Vector3(1.3,high,.33),Vector3(0,high*.5,2.65+i*.33),"wood")
	# One convex envelope covers the tread noses; individual riser collisions
	# would still stop the player if a thinner ramp passed beneath the steps.
	var ramp: ConvexPolygonShape3D = ConvexPolygonShape3D.new()
	var ramp_points: PackedVector3Array = PackedVector3Array()
	for x: float in [-.65,.65]:
		for yz: Vector2 in [Vector2(-.06,2.485),Vector2(-.06,4.795),Vector2(0,4.795),Vector2(1.23,2.815),Vector2(1.23,2.485)]:
			ramp_points.append(Vector3(x,yz.x,yz.y))
	ramp.points=ramp_points
	b._collision("StepSlope",ramp,Transform3D.IDENTITY)
	b.item.get_node("Entrance").position=Vector3(0,0,5.16)
	b._marker("StairFoot",Vector3(0,0,5.16))
	b._marker("StairBase",Vector3(0,0,4.465))
	b._save()

func _grain_store() -> void:
	b._start("reserve_a_grain_octogonale","agricole","Réserve à grain octogonale","Petit silo de charpente à cuve sèche, protégé par une toiture conique en chaume.","À placer à proximité d'une grange; stockage médiéval en bois, pas de silo métallique.")
	b.item.set_meta("building_kind","wood_grain_store")
	b._cylinder("StorageFooting",Vector3(0,.18,0),2.08,.36,"stone",2.08,Vector3.ZERO,true)
	var body: CylinderMesh = CylinderMesh.new();body.top_radius=1.87;body.bottom_radius=1.87;body.height=3.85;body.radial_segments=8;body.rings=1
	b._mesh("StorageBoards",body,Transform3D(Basis.IDENTITY,Vector3(0,2.27,0)),"wood")
	var shape: CylinderShape3D = CylinderShape3D.new();shape.radius=1.87;shape.height=3.85
	b._collision("DryGrainBin",shape,Transform3D(Basis.IDENTITY,Vector3(0,2.27,0)))
	for i: int in 8:
		var a: float = TAU*(i+.5)/8.0
		var p: Vector3 = Vector3(sin(a)*1.89,0,cos(a)*1.89)
		b._beam("BinCornerPosts",p+Vector3(0,.38,0),p+Vector3(0,4.23,0),.17,"dark_wood")
	for y: float in [.65,2.2,3.92]:b._ring("WoodenBinHoops",Vector3(0,y,0),1.94,1.87,.13,"dark_wood")
	var roof: CylinderMesh = CylinderMesh.new();roof.bottom_radius=2.30;roof.top_radius=.13;roof.height=2.12;roof.radial_segments=8;roof.rings=1
	b._mesh("ConicalThatch",roof,Transform3D(Basis.IDENTITY,Vector3(0,5.18,0)),"thatch")
	b._cylinder("RoofFinial",Vector3(0,6.3,0),.15,.28,"thatch_dark",.05)
	b._box("LoadingHatch",Vector3(.88,1.3,.1),Vector3(0,1.11,1.925),"dark_wood")
	for y: float in [.7,1.5]:b._box("HatchBattens",Vector3(.94,.10,.09),Vector3(0,y,2.01),"wood")
	b._box("HatchHood",Vector3(1.2,.12,.6),Vector3(0,1.86,2.10),"wood",Vector3(.2,0,0))
	b._marker("Entrance",Vector3(0,0,2.70));b._marker("DoorFace",Vector3(0,0,1.98))
	b._save()

func _mill() -> void:
	b._start("moulin_a_grain_hydraulique","hydraulique","Moulin à grain et roue de plaine","Moulin rural à roue en dessous; canal porteur, axe et volume de meunerie cohérents.","Canal longitudinal sur le côté -X; raccorder WaterIn vers l'amont et WaterOut vers l'aval, cote locale 0,48 m. Le bâtiment et ses fondations restent hors du cours principal.")
	b.item.set_meta("building_kind","grain_watermill")
	b.item.set_meta("wheel_axis","X")
	b.item.set_meta("wheel_radius_m",2.05)
	b.item.set_meta("channel_water_level_m",.48)
	b.item.set_meta("channel_clear_width_m",1.68)
	b.item.set_meta("wheel_visual_path","Wheel")
	_volume(Vector3.ZERO,7.4,8.4,5.2,3.15)
	_front_door(Vector3(1.55,.08,4.28),1.22,2.14)
	for x: float in [-2.20,.1]:_front_window(Vector3(x,1.73,4.23),.66)
	for x: float in [-2.20,0.0,2.2]:_front_window(Vector3(x,3.88,4.23),.66)
	_lean_store(Vector3(4.8,0,-.7),2.16,5.9,2.85,.90)
	_chimney(Vector3(1.85,3.15,-2.05),3.95)
	_porch(Vector3(1.55,0,5.08),2.60,1.52,2.48,.50)
	# Supported head- and tail-race: the water stays strictly inside the trough.
	_trough(Vector3(-4.83,0,0),1.68,11.2,.48)
	_wheel(Vector3(-4.83,2.41,0),2.05,1.12)
	b._cylinder("Axle",Vector3(-4.01,2.41,0),.17,3.20,"dark_wood",-1,Vector3(0,0,PI*.5))
	b._box("OuterAxlePier",Vector3(.55,2.5,.65),Vector3(-6.15,1.25,0),"stone",Vector3.ZERO,true)
	b._box("AxleBearing",Vector3(.63,.34,.55),Vector3(-6.15,2.41,0),"wood")
	b._marker("WheelAxis",Vector3(-4.83,2.41,0))
	b._marker("WaterIn",Vector3(-4.83,.48,-5.6))
	b._marker("WaterOut",Vector3(-4.83,.48,5.6))
	b._marker("GrainDelivery",Vector3(2.30,0,6.25))
	b._save()

func _wheel_asset() -> void:
	b._start("roue_hydraulique_4m","hydraulique","Roue hydraulique de 4,10 m","Roue modulaire à pales pour un moulin à courant bas.","Pivot de scène au sol; centre WheelAxis (0;2,20;0), axe X, rayon 2,05 m, largeur 1,12 m. Immerger les pales basses d'environ 0,15 m.")
	b.item.set_meta("wheel_visual_path","Wheel")
	b.item.set_meta("wheel_axis","X")
	b.item.set_meta("wheel_radius_m",2.05)
	_wheel(Vector3(0,2.20,0),2.05,1.12)
	b._marker("WheelAxis",Vector3(0,2.2,0))
	b._marker("WaterIn",Vector3(0,.30,-2.25));b._marker("WaterOut",Vector3(0,.30,2.25))
	b._save()

func _wheel(at: Vector3, radius: float, width: float) -> void:
	# Isolate rotating geometry from the building's static material batches.
	var saved_batches: Dictionary = b.batches
	var saved_transform: Transform3D = b.model_transform
	b.batches={};b.model_transform=Transform3D.IDENTITY
	for side: float in [-1.0,1.0]:
		b._ring("WheelRim",Vector3(side*width*.40,0,0),radius-.10,radius-.29,.12,"dark_wood",Vector3(0,0,PI*.5))
		for i: int in 10:
			var a: float=TAU*i/10.0
			b._beam("WheelSpokes",Vector3(side*width*.40,0,0),Vector3(side*width*.40,cos(a)*(radius-.2),sin(a)*(radius-.2)),.14,"wood")
	for i: int in 24:
		var a: float=TAU*i/24.0
		b._box("WheelPaddles",Vector3(width,.23,.38),Vector3(0,cos(a)*(radius-.115),sin(a)*(radius-.115)),"wood",Vector3(a,0,0))
	b._cylinder("WheelHub",Vector3.ZERO,.30,width+.28,"dark_wood",-1,Vector3(0,0,PI*.5))
	for side: float in [-1.0,1.0]:b._ring("HubCollar",Vector3(side*(width*.5+.06),0,0),.32,.285,.10,"iron",Vector3(0,0,PI*.5))
	var wheel: Node3D=Node3D.new();wheel.name="Wheel";wheel.position=at;b.item.add_child(wheel)
	var merged: Dictionary={}
	for key: String in b.batches:
		var data: Dictionary=b.batches[key]
		var st: SurfaceTool=data.tool;st.generate_normals()
		var material_key: String=str(data.material.get_instance_id())
		if not merged.has(material_key):
			var combined: SurfaceTool=SurfaceTool.new();combined.begin(Mesh.PRIMITIVE_TRIANGLES)
			merged[material_key]={"tool":combined,"material":data.material,"label":key}
		merged[material_key].tool.append_from(st.commit(),0,Transform3D.IDENTITY)
	for key: String in merged:
		var data: Dictionary=merged[key]
		var st: SurfaceTool=data.tool;st.index()
		var instance: MeshInstance3D=MeshInstance3D.new();instance.name=str(data.label).to_pascal_case();instance.mesh=st.commit();instance.material_override=data.material;wheel.add_child(instance)
	b.batches=saved_batches;b.model_transform=saved_transform
	var collider: CylinderShape3D=CylinderShape3D.new();collider.radius=radius;collider.height=width
	b._collision("Wheel",collider,Transform3D(Basis(Vector3.FORWARD,PI*.5),at))

func _headrace_asset() -> void:
	b._start("canal_de_moulin_5m","hydraulique","Canal de moulin modulaire de 5 m","Bief maçonné ouvert aux deux extrémités, avec lame d'eau soutenue.","Raccorder WaterIn et WaterOut (0;0,48;−2,5/+2,5). Largeur d'eau 1,68 m, encombrement avec margelles 2,16 m; garder les niveaux entre modules.")
	b.item.set_meta("channel_water_level_m",.48)
	b.item.set_meta("channel_clear_width_m",1.68)
	_trough(Vector3.ZERO,1.68,5.0,.48)
	b._marker("WaterIn",Vector3(0,.48,-2.5));b._marker("WaterOut",Vector3(0,.48,2.5))
	b._save()

func _trough(at: Vector3,clear_width: float,length: float,water_y: float) -> void:
	b._box("ChannelBed",Vector3(clear_width+.4,.17,length),at+Vector3(0,.085,0),"stone",Vector3.ZERO,true)
	for side: float in [-1.0,1.0]:
		b._box("ChannelWall",Vector3(.20,.64,length),at+Vector3(side*(clear_width*.5+.1),.32,0),"stone",Vector3.ZERO,true)
		b._box("ChannelCoping",Vector3(.28,.10,length),at+Vector3(side*(clear_width*.5+.1),.66,0),"stone")
	b._box("SupportedChannelWater",Vector3(clear_width-.018,.012,length),at+Vector3(0,water_y,0),"water")
