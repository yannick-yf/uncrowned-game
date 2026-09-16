extends RefCounted
## Individually authored silhouettes for the settlement. Reuses construction
## primitives and materials, but never instances or recolours a finished house.
var b: Variant

func build_housing(builder: SceneTree) -> void:
	b=builder
	# Narrow gate house: deep stone gable, offset door, small side woodshed.
	start("logis_porte_basse","Logis de la porte basse","Deep stone gable with a recessed side store.")
	shell(Vector3.ZERO,3.5,4.7,2.50,"stone","gable",0,1.32)
	door(Vector3(-.42,0,2.35));window_at(Vector3(.98,1.45,2.35),.50)
	b._chimney(Vector3(-.92,1.2,.6),3.1)
	side_shed(Vector3(-2.24,0,-.75),-90,2.2,1.0,1.95)
	b._seat(Vector3(1.10,0,2.95));finish("stone_gable_with_side_store","house")

	# Compact hipped house with a lower stone entrance wing on its right.
	start("maison_aux_deux_volumes","Maison aux deux volumes","Hipped main roof and a stepped entrance wing.")
	shell(Vector3(-.55,0,-.30),3.6,3.5,2.65,"stone","gable",0,1.13)
	shell(Vector3(1.55,0,.42),1.7,2.15,2.16,"timber","lean",0,.70)
	door(Vector3(1.55,0,1.495),.85,1.72)
	window_at(Vector3(-1.25,1.48,1.45),.62)
	b._chimney(Vector3(-1.55,1.1,-1.15),3.0)
	b._barrel(Vector3(-2.8,0,1.25),.78);finish("hipped_house_and_lower_entry_wing","house")

	# Long low barrack: roof ridge parallel to the street, two separate entrances.
	start("baraquement_des_equipes","Baraquement des bûcherons","Low timber barrack with two entrances and end chimneys.")
	shell(Vector3.ZERO,6.4,3.8,2.28,"timber","gable",90,1.13)
	door(Vector3(-1.58,0,1.90),.90,1.82);door(Vector3(1.62,0,1.90),.90,1.82)
	for x: float in [-2.62,0.0,2.63]:window_at(Vector3(x,1.39,1.90),.42,true)
	b._chimney(Vector3(-2.57,.80,-.78),3.18);b._chimney(Vector3(2.52,.65,-.68),3.1)
	b._seat(Vector3(0,0,2.38));finish("long_low_dual_entry_barrack","barrack")

	# Tall corner lodging: half-timber floor, hip roof and a small entrance canopy.
	start("logis_a_colombages","Logis d’angle à colombages","Tall half-timber lodging under a hipped roof.")
	shell(Vector3.ZERO,3.35,3.85,3.52,"half_timber","gable",0,1.12)
	door(Vector3(.24,0,1.925),.95,1.90)
	window_at(Vector3(-1.01,1.35,1.925),.42)
	for x: float in [-.85,.84]:window_at(Vector3(x,2.88,1.925),.43,true)
	canopy(Vector3(.24,0,2.30),1.65,.95,2.18,.37)
	b._chimney(Vector3(.95,1.8,-1.1),3.3);finish("tall_half_timber_hipped_corner","house")

	# Two staggered workers' rooms: one gable, one lower lean-to, no identical wings.
	start("baraque_jumelee_de_la_cour","Baraque décalée de la cour","Staggered timber rooms with two different roof heights.")
	shell(Vector3(-1.20,0,-.15),3.1,4.0,2.37,"timber","gable",0,1.12)
	shell(Vector3(1.56,0,.30),2.45,3.05,2.05,"timber","lean",0,.78)
	door(Vector3(-1.23,0,1.85),.90,1.85);door(Vector3(1.61,0,1.825),.83,1.68)
	window_at(Vector3(-2.24,1.42,1.85),.40,true)
	window_at(Vector3(.65,1.25,1.825),.35,true)
	b._chimney(Vector3(-.50,1.0,-.95),3.05);finish("staggered_gable_and_lean_barrack","barrack")

	# Street bend: broad hip and a low enclosed front bay, entry kept beside it.
	start("maison_du_virage","Maison du virage","Broad stone house with a projecting timber bay.")
	shell(Vector3(0,0,-.25),4.1,3.7,2.57,"stone","hip",90,1.12)
	shell(Vector3(1.16,0,1.70),1.50,1.08,2.04,"timber","lean",0,.42)
	door(Vector3(-.78,0,1.60),.98,1.88)
	window_at(Vector3(1.16,1.35,2.24),.56,true)
	b._chimney(Vector3(-1.35,1.3,-1.1),3.08);finish("broad_hip_with_projecting_bay","house")

	# Narrow two-storey house: high gable, upper window and external stone chimney.
	start("maison_haute_de_la_venelle","Maison haute de la venelle","Narrow two-storey masonry house with an external chimney.")
	shell(Vector3.ZERO,3.05,3.8,3.96,"stone","gable",0,1.19)
	door(Vector3(-.43,0,1.90),.92,1.90)
	window_at(Vector3(.81,1.37,1.90),.38)
	window_at(Vector3(0,2.99,1.90),.68)
	b._chimney(Vector3(1.66,0,-.60),5.25)
	b._barrel(Vector3(-1.90,0,-.9),.85);finish("narrow_two_storey_external_stack","house")

	# Large communal barrack: long hipped roof, three doors and a covered porch.
	start("baraquement_de_la_grande_cour","Baraquement de la grande cour","Long communal lodging with a continuous covered entrance porch.")
	shell(Vector3(0,0,-.25),8.0,4.25,2.70,"timber","hip",90,1.38)
	for x: float in [0.0,-2.62,2.62]:door(Vector3(x,0,1.875),.92,1.93)
	for x: float in [-1.30,1.30]:window_at(Vector3(x,1.51,1.875),.49,true)
	canopy(Vector3(0,0,2.44),7.55,1.2,2.19,.48)
	b._chimney(Vector3(-2.25,1.3,-.95),3.2)
	b._chimney(Vector3(2.42,1.4,-.95),3.04)
	finish("long_hipped_three_entry_porch_barrack","barrack")

	# Large two-level barrack, with a left-hand stair and a street-parallel ridge.
	start("baraquement_a_galerie","Baraquement à galerie","Logement des scieurs, galerie et escalier latéral.")
	shell(Vector3.ZERO,7.0,4.0,4.55,"half_timber","gable",90,1.30)
	door(Vector3(.30,0,2.0),1.0,1.93)
	for x: float in [-2.33,2.37]:window_at(Vector3(x,1.45,2.0),.63)
	for x: float in [-.60,1.58,2.80]:window_at(Vector3(x,3.44,2.0),.42,true)
	gallery_left()
	b._chimney(Vector3(2.5,2.0,-.65),3.65)
	finish("two_storey_gallery_left_stair_barrack","barrack")

	# Foreman's L-shaped stone house: a taller front room beside a covered entrance.
	start("logis_du_contremaitre_en_l","Logis du maître scieur en L","L-shaped masonry residence with a taller front room.")
	shell(Vector3(0,0,-.45),4.70,4.20,3.0,"stone","hip",0,1.38)
	shell(Vector3(-1.12,0,1.43),2.35,2.15,3.72,"half_timber","hip",0,1.05)
	door(Vector3(1.24,0,1.65),.96,1.92)
	window_at(Vector3(-1.12,1.46,2.505),.64)
	window_at(Vector3(-1.12,2.83,2.505),.57,true)
	canopy(Vector3(1.28,0,2.16),1.50,1.0,2.25,.45)
	b._chimney(Vector3(.9,1.5,-1.6),3.55);finish("l_shaped_house_with_raised_front_room","house")

	# Cart workers' house: wide low cross-gable with a smaller rear store.
	start("maison_des_charretiers","Maison des voituriers","Wide low gable with a small rear storage projection.")
	shell(Vector3.ZERO,4.60,3.35,2.34,"stone","gable",90,1.24)
	shell(Vector3(-1.14,0,-1.69),2.04,1.6,1.85,"timber","lean",180,.65)
	door(Vector3(.72,0,1.675),.95,1.86)
	window_at(Vector3(-1.02,1.38,1.675),.68)
	b._chimney(Vector3(1.60,1.0,-.7),3.1)
	b._seat(Vector3(-.70,0,2.28));finish("wide_cross_gable_with_rear_store","house")

	# Garden lodging: asymmetric roof, low timber upper walls and a side bench.
	start("maison_au_toit_decale","Maison au toit décalé","Asymmetric gable with a short sheltered bench.")
	shell(Vector3.ZERO,4.0,3.35,2.44,"half_timber","offset",0,1.19)
	door(Vector3(.58,0,1.675),.94,1.91)
	window_at(Vector3(-1.0,1.42,1.675),.56,true)
	canopy(Vector3(-1.64,0,2.15),1.75,1.0,2.02,.40)
	b._seat(Vector3(-1.65,0,2.12));b._chimney(Vector3(1.1,1.1,-.85),3.0)
	finish("offset_ridge_with_sheltered_bench","house")

func start(id: String,label: String,description: String,family: String="village") -> void:
	b._start(id,family,label,description,"Bâtiment unique de l’scierie ; conserver son accès et sa fondation.")

func finish(design: String,kind: String) -> void:
	b.item.set_meta("building_design",design);b.item.set_meta("building_kind",kind)
	b._save()

func shell(at: Vector3,width: float,depth: float,height: float,wall: String,roof: String,axis: float=0,rise: float=1.2) -> void:
	b.architecture.walls(at,width,depth,height,b.item_id.begins_with("latrines"))
	var slope_width: float=depth if int(axis)%180!=0 else width
	if roof!="lean":rise=b.architecture.rise_for(slope_width,rise)
	roof_on(at,width,depth,height,roof,axis,rise,true,wall)
	if b.item_id in ["baraquement_des_equipes","baraquement_de_la_grande_cour","baraquement_a_galerie"]:
		for x: float in [-width*.26,width*.26]:b.architecture.dormer(at,width,depth,height,rise,x)

func roof_on(at: Vector3,width: float,depth: float,eave: float,roof: String,axis: float,rise: float,closed: bool,wall: String="timber") -> void:
	var saved: Transform3D=b.model_transform
	b.model_transform=saved*Transform3D(Basis(Vector3.UP,deg_to_rad(axis)),at)
	var w: float=depth if int(axis)%180!=0 else width
	var d: float=width if int(axis)%180!=0 else depth
	if roof=="lean":
		if closed:
			b._boarding(Vector3(0,eave,-d*.5),w,rise)
			for x: float in [-w*.5,w*.5]:b._roof_infill(Vector3(x,eave,0),d,rise)
		b._lean_roof(Vector3.ZERO,w,d,eave,rise,b.architecture.roof_material())
	elif roof=="hip":hip_roof(w,d,eave,rise)
	else:
		var offset: float=-.68 if roof=="offset" else 0.0
		if closed:gable_infill(w,d,eave,rise,offset,"stone" if wall=="stone" else "dark_wood")
		if roof=="offset":
			roof_face(Vector3(-w*.5-.18,eave,-d*.5-.18),Vector3(-w*.5-.18,eave,d*.5+.18),Vector3(offset,eave+rise,-d*.5-.18),Vector3(offset,eave+rise,d*.5+.18))
			roof_face(Vector3(w*.5+.18,eave,d*.5+.18),Vector3(w*.5+.18,eave,-d*.5-.18),Vector3(offset,eave+rise,d*.5+.18),Vector3(offset,eave+rise,-d*.5-.18))
			b._beam("OffsetRidge",Vector3(offset,eave+rise+.06,-d*.5-.2),Vector3(offset,eave+rise+.06,d*.5+.2),.12,b.architecture.roof_material())
		else:b._roof(Vector3.ZERO,w,d,eave,rise,b.architecture.roof_material())
	b.model_transform=saved

func gable_infill(width: float,depth: float,eave: float,rise: float,offset: float,_mat: String) -> void:
	b.architecture.gable(width,depth,eave,rise,offset)

func hip_roof(width: float,depth: float,eave: float,rise: float) -> void:
	var x: float=width*.5+.18;var z: float=depth*.5+.18
	var ridge: float=maxf(.16,depth*.5-minf(width*.46,depth*.35))
	var a: Vector3=Vector3(-x,eave,-z);var c: Vector3=Vector3(x,eave,-z)
	var d: Vector3=Vector3(x,eave,z);var e: Vector3=Vector3(-x,eave,z)
	var p: Vector3=Vector3(0,eave+rise,-ridge);var q: Vector3=Vector3(0,eave+rise,ridge)
	roof_face(a,e,p,q);roof_face(d,c,q,p);roof_face(c,a,p,p);roof_face(e,d,q,q)
	for pair: Array in [[a,p],[c,p],[d,q],[e,q],[p,q]]:b._beam("HipCaps",pair[0]+Vector3.UP*.07,pair[1]+Vector3.UP*.07,.11,b.architecture.roof_material())
	for pair: Array in [[a,c],[c,d],[d,e],[e,a]]:b._beam("HipEave",pair[0],pair[1],.12,"dark_wood")

func roof_face(a: Vector3,c: Vector3,p: Vector3,q: Vector3) -> void:
	var deck: SurfaceTool=b._surface("RoofDeck","dark_wood")
	b._tri(deck,a,p,c);b._tri(deck,c,p,q)
	var tiles: SurfaceTool=b._surface("HipSlate",b.architecture.roof_material())
	var rows: int=maxi(3,ceili(a.distance_to(p)/.31))
	for row: int in rows:
		var lower: float=float(row)/rows;var upper: float=float(row+1)/rows
		var left: Vector3=a.lerp(p,lower);var right: Vector3=c.lerp(q,lower)
		var tl: Vector3=a.lerp(p,upper);var tr: Vector3=c.lerp(q,upper)
		var cols: int=maxi(1,ceili(left.distance_to(right)/.42))
		for col: int in cols:
			var u: float=(col+.016)/cols;var v: float=(col+.984)/cols
			var ll: Vector3=left.lerp(right,u)+Vector3.UP*.045;var lr: Vector3=left.lerp(right,v)+Vector3.UP*.045
			var ul: Vector3=tl.lerp(tr,u)+Vector3.UP*.060;var ur: Vector3=tl.lerp(tr,v)+Vector3.UP*.060
			var tone: float=b.rng.randf_range(.88,1.06)
			b._tri(tiles,ll,ul,lr,tone);b._tri(tiles,lr,ul,ur,tone)
			b._tri(tiles,ll-Vector3.UP*.035,ll,lr,tone*.75)
			b._tri(tiles,ll-Vector3.UP*.035,lr,lr-Vector3.UP*.035,tone*.75)

func door(at: Vector3,width: float=.94,height: float=1.87) -> void:
	b._door(at+Vector3(0,.17,.18),width,height)

func window_at(at: Vector3,width: float=.55,timber: bool=false,yaw: float=0) -> void:
	var saved: Transform3D=b.model_transform
	b.model_transform=saved*Transform3D(Basis(Vector3.UP,deg_to_rad(yaw)),at)
	if timber:
		var scaling: Transform3D=b.model_transform
		b.model_transform=scaling*Transform3D(Basis.IDENTITY.scaled(Vector3(width/.40,1,1)),Vector3(0,0,.08))
		b._timber_window(Vector3.ZERO)
	else:b._window(Vector3.ZERO,width)
	b.model_transform=saved

func side_shed(at: Vector3,yaw: float,width: float,depth: float,height: float) -> void:
	var saved: Transform3D=b.model_transform
	b.model_transform=saved*Transform3D(Basis(Vector3.UP,deg_to_rad(yaw)),at)
	b._shed(Vector3.ZERO,width,depth,height,.55,false,"rust_roof")
	b._logs(Vector3.ZERO,width*.75,depth*.65)
	b.model_transform=saved

func canopy(at: Vector3,width: float,depth: float,height: float,rise: float) -> void:
	# Only the two outer posts touch the ground; the back ledger fixes to the wall.
	for x: float in [-width*.5,width*.5]:
		b._box("PorchFoot",Vector3(.33,.38,.33),at+Vector3(x,.19,depth*.5),"stone",Vector3.ZERO,true)
		b._beam("PorchPost",at+Vector3(x,.32,depth*.5),at+Vector3(x,height,depth*.5),.17,"wood",true)
		b._beam("PorchBrace",at+Vector3(x,height-.40,depth*.5),at+Vector3(x-signf(x)*.36,height,depth*.5),.10,"wood")
	b._lean_roof(at,width,depth,height,rise,b.architecture.roof_material())
	b._beam("PorchLintel",at+Vector3(-width*.5,height-.10,depth*.5),at+Vector3(width*.5,height-.10,depth*.5),.17,"dark_wood")

func open_hall(width: float,depth: float,eave: float,roof: String,axis: float,rise: float) -> void:
	rise=b.architecture.rise_for(depth if int(axis)%180!=0 else width,rise)
	for x: float in [-width*.5,width*.5]:
		for z: float in [-depth*.5,depth*.5]:
			b._box("MasonryPier",Vector3(.48,.66,.48),Vector3(x,.33,z),"stone",Vector3.ZERO,true)
			b._beam("HallPost",Vector3(x,.52,z),Vector3(x,eave,z),.25,"dark_wood",true)
			b._beam("HallKneeBrace",Vector3(x,eave-.62,z),Vector3(x-signf(x)*.7,eave,z),.14)
	for z: float in [-depth*.5,depth*.5]:b._beam("HallTie",Vector3(-width*.5,eave-.1,z),Vector3(width*.5,eave-.1,z),.20,"dark_wood")
	b._box("RearLowWall",Vector3(width,1.0,.28),Vector3(0,.50,-depth*.5),"stone",Vector3.ZERO,true)
	b._boarding(Vector3(0,1.0,-depth*.5),width,eave-1.0)
	roof_on(Vector3.ZERO,width,depth,eave,roof,axis,rise,false)
	if roof=="gable":
		var saved: Transform3D=b.model_transform
		b.model_transform=saved*Transform3D(Basis(Vector3.UP,deg_to_rad(axis)),Vector3.ZERO)
		var w: float=depth if int(axis)%180!=0 else width
		var d: float=width if int(axis)%180!=0 else depth
		for z: float in [-d*.5,d*.5]:
			b._beam("RoofTrussTie",Vector3(-w*.5,eave,z),Vector3(w*.5,eave,z),.18,"dark_wood")
			b._beam("RoofKingPost",Vector3(0,eave,z),Vector3(0,eave+rise,z),.13,"dark_wood")
			for side: float in [-1.0,1.0]:b._beam("RoofRafters",Vector3(side*w*.5,eave,z),Vector3(0,eave+rise,z),.14,"dark_wood")
		b.model_transform=saved
	b._marker("Entrance",Vector3(0,0,depth*.5+1))

func gallery_left() -> void:
	b._box("GalleryDeck",Vector3(8.0,.18,1.15),Vector3(-.50,2.49,2.55),"wood",Vector3.ZERO,true)
	for x: float in [-4.37,-3.3,-1.55,1.55,3.35]:b._beam("GalleryPosts",Vector3(x,0,2.98),Vector3(x,2.40,2.98),.17,"wood",true)
	b._door(Vector3(-2.03,2.58,2.16),.91,1.74)
	b._marker("UpperDoor",Vector3(-2.03,2.58,2.36))
	b._beam("GalleryHandrail",Vector3(-4.42,3.36,3.02),Vector3(3.42,3.36,3.02),.08,"wood",true)
	for i: int in 18:b._beam("GalleryBalusters",Vector3(-4.34+i*.451,2.58,3.02),Vector3(-4.34+i*.451,3.36,3.02),.052)
	for x: float in [-4.43,3.43]:b._beam("GalleryEnds",Vector3(x,3.36,2.05),Vector3(x,3.36,3.02),.08,"wood",true)
	for i: int in 13:b._box("GallerySteps",Vector3(1.0,.12,.38),Vector3(-3.96,.14+i*.20,-2.17+i*.34),"wood")
	for x: float in [-4.39,-3.53]:
		b._beam("StairStringer",Vector3(x,.02,-2.37),Vector3(x,2.45,2.07),.17,"dark_wood")
		b._beam("StairRail",Vector3(x,.94,-2.37),Vector3(x,3.5,2.07),.075,"wood",true)
		for i: int in [0,4,8,12]:b._beam("StairPosts",Vector3(x,.18+i*.20,-2.17+i*.34),Vector3(x,1.10+i*.20,-2.17+i*.34),.06)
	b._stair_ramp("StairRamp",-3.96,1.0,-2.51,1.85,2.62)
	var join: BoxShape3D=BoxShape3D.new();join.size=Vector3(1,.12,.4)
	b._collision("StairTopJoin",join,Transform3D(Basis.IDENTITY,Vector3(-3.96,2.56,2.04)))
	b._marker("StairStart",Vector3(-3.96,0,-2.95));b._marker("GalleryArrival",Vector3(-3.96,2.58,2.55))
