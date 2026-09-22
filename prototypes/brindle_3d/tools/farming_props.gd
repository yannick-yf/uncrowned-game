extends RefCounted
## Original rural workaday props, authored in metres with a ground-level pivot.
var b: Variant

func _init(builder: Variant) -> void:
	b=builder

func build() -> void:
	_well()
	_cart(false)
	_cart(true)
	_fence(2.0)
	_fence(4.0)
	_corner()
	_gate(false)
	_gate(true)
	_barrels()
	_sacks()
	_basket_asset(false)
	_basket_asset(true)
	_crate_asset(false)
	_crate_asset(true)
	_ladder(false)
	_ladder(true)
	_tools()
	_plough()
	_water_trough()

func _solid(label: String,size: Vector3,at: Vector3,rot: Vector3=Vector3.ZERO) -> void:
	var shape: BoxShape3D=BoxShape3D.new();shape.size=size
	b._collision(label,shape,Transform3D(Basis.from_euler(rot),at))

func _ellipsoid(label: String,at: Vector3,size: Vector3,mat: String,rotation: Vector3=Vector3.ZERO) -> void:
	var mesh: SphereMesh=SphereMesh.new();mesh.radius=.5;mesh.height=1.0
	mesh.radial_segments=8;mesh.rings=3
	b._mesh(label,mesh,Transform3D(Basis.from_euler(rotation).scaled(size),at),mat,b.rng.randf_range(.88,1.06))

func _fruit(at: Vector3,pear: bool=false,scale_value: float=1.0) -> void:
	if pear:
		_ellipsoid("PearBody",at,Vector3(.17,.21,.16)*scale_value,"pear")
		_ellipsoid("PearNeck",at+Vector3(0,.10,0)*scale_value,Vector3(.105,.12,.105)*scale_value,"pear")
	else:
		_ellipsoid("AppleBody",at,Vector3(.17,.155,.17)*scale_value,"apple")
	b._beam("FruitStem",at+Vector3(0,.075 if not pear else .155,0)*scale_value,at+Vector3(.016,.115 if not pear else .19,0)*scale_value,.015*scale_value,"bark")

func _well() -> void:
	b._start("puits_couvert_de_chaume","accessoires","Puits couvert de chaume","Point d'eau de cour, avec margelle, treuil et seau.","Sur terrain horizontal ; réserver 1,2 m de passage autour de la margelle.")
	b._ring("StoneFoot",Vector3(0,.13,0),1.0,.63,.26,"stone")
	for row: int in 3:
		for i: int in 12:
			var angle: float=TAU*(i+.5*(row%2))/12.0
			b._box("WellRubble",Vector3(.395,.265,.29),Vector3(sin(angle)*.77,.39+row*.28,cos(angle)*.77),"stone",Vector3(0,angle,0))
	b._ring("Coping",Vector3(0,1.075,0),.98,.61,.19,"stone")
	b._cylinder("DeepWater",Vector3(0,.19,0),.64,.035,"water")
	var shape: CylinderShape3D=CylinderShape3D.new();shape.radius=.98;shape.height=1.17
	b._collision("WellRim",shape,Transform3D(Basis.IDENTITY,Vector3(0,.585,0)))
	for x: float in [-1.11,1.11]:
		b._box("Uprights",Vector3(.20,2.55,.22),Vector3(x,1.275,0),"dark_wood",Vector3.ZERO,true)
		b._beam("KneeBraces",Vector3(x,1.99,0),Vector3(x-signf(x)*.42,2.48,0),.12,"wood")
	b._beam("WellCrosspiece",Vector3(-1.25,2.5,0),Vector3(1.25,2.5,0),.20,"dark_wood")
	b._cylinder("Windlass",Vector3(0,1.84,0),.10,2.56,"wood",.10,Vector3(0,0,PI*.5))
	for i: int in 8:b._ring("WindlassRope",Vector3(-.14+i*.04,1.84,0),.115,.097,.024,"rope",Vector3(0,0,PI*.5))
	b._beam("HangingRope",Vector3(.04,1.73,0),Vector3(.04,.52,0),.028,"rope")
	b._beam("Crank",Vector3(1.35,1.84,0),Vector3(1.35,1.56,0),.058,"iron")
	b._beam("CrankGrip",Vector3(1.34,1.56,0),Vector3(1.56,1.56,0),.065,"wood")
	b._roof(Vector3.ZERO,2.2,1.6,2.55,.91)
	_open_vessel(Vector3(.58,1.17,.50),.20,.32,"wood")
	_arch_handle(Vector3(.58,1.47,.50),.17,.22,"iron")
	b._marker("UsePoint",Vector3(0,0,1.45));b._save()

func _cart(loaded: bool) -> void:
	var id: String="charrette_de_recolte_chargee" if loaded else "charrette_de_recolte_vide"
	b._start(id,"accessoires","Charrette de récolte chargée" if loaded else "Charrette de récolte vide","Transport des sacs et des gerbes ; roues pleines à rayons et timon jumelé.","Sur chemin sec ou sous grange ; le timon indique l'avant +Z.")
	for x: float in [-.51,.51]:b._box("Chassis",Vector3(.16,.19,2.22),Vector3(x,.56,0),"dark_wood")
	for z: float in [-.84,.78]:b._box("Crossmember",Vector3(1.34,.14,.17),Vector3(0,.60,z),"dark_wood")
	for i: int in 7:b._box("BedPlanks",Vector3(.18,.12,2.14),Vector3(-.6+i*.2,.75,0),"wood")
	for side: float in [-1.,1.]:
		for row: int in 3:b._box("SideBoards",Vector3(.075,.16,2.16),Vector3(side*.69,.88+row*.185,0),"wood")
		for z: float in [-.95,.02,.96]:b._box("CartStakes",Vector3(.12,.82,.11),Vector3(side*.74,.99,z),"dark_wood")
		b._beam("Shaft",Vector3(side*.48,.59,.83),Vector3(side*.47,.58,2.64),.105,"wood")
		b._box("RestingLeg",Vector3(.09,.50,.09),Vector3(side*.48,.25,1.54),"dark_wood")
	for row: int in 3:
		for z: float in [-1.03,1.03]:b._box("TailBoards",Vector3(1.31,.16,.075),Vector3(0,.88+row*.185,z),"wood")
	b._beam("Axle",Vector3(-1.00,.56,-.12),Vector3(1.00,.56,-.12),.13,"dark_wood")
	for side: float in [-1.,1.]:
		var center: Vector3=Vector3(side*.90,.57,-.12)
		b._ring("WheelFelloe",center,.57,.465,.14,"wood",Vector3(0,0,PI*.5))
		b._ring("WheelTyre",center,.584,.56,.145,"iron",Vector3(0,0,PI*.5))
		b._cylinder("WheelHub",center,.135,.24,"dark_wood",.135,Vector3(0,0,PI*.5))
		for spoke: int in 10:
			var angle: float=TAU*spoke/10.0
			b._beam("WheelSpokes",center,center+Vector3(0,cos(angle)*.48,sin(angle)*.48),.053,"wood")
	_solid("CartBody",Vector3(1.58,1.36,2.2),Vector3(0,.68,0))
	# Separate slender shaft colliders leave the space between the two timbers open.
	for side: float in [-1.,1.]:_solid("CartShaft",Vector3(.12,.14,1.56),Vector3(side*.47,.58,1.87))
	if loaded:
		for p: Vector3 in [Vector3(-.26,.82,-.56),Vector3(.25,.82,-.49),Vector3(-.24,.82,.04),Vector3(.27,.82,.13)]:_sack(p,.86)
		for x: float in [-.30,.0,.30]:
			b._cylinder("Sheaf",Vector3(x,1.1,.76),.17,.58,"straw",.22)
			b._ring("SheafTie",Vector3(x,1.02,.76),.181,.16,.055,"rope")
			for i: int in 4:b._beam("SheafStems",Vector3(x-.11+i*.07,.82,.76),Vector3(x-.12+i*.08,1.46,.76),.025,"grain")
	b._marker("TowPoint",Vector3(0,.58,2.65));b._save()

func _fence_run(a: Vector3,end: Vector3,include_start: bool=true) -> void:
	var posts: Array[Vector3]=[]
	if include_start:posts.append(a)
	posts.append(end)
	for point: Vector3 in posts:
		b._box("FencePosts",Vector3(.15,1.28,.16),point+Vector3(0,.64,0),"dark_wood")
	for y: float in [.42,.94]:b._beam("SplitRails",a+Vector3(0,y,0),end+Vector3(0,y,0),.11,"wood")
	b._beam("DiagonalBrace",a+Vector3(0,.35,.015),end+Vector3(0,1.01,.015),.072,"wood")
	var direction: Vector3=end-a
	_solid("Fence",Vector3(.16,1.28,direction.length()+.15),(a+end)*.5+Vector3(0,.64,0),Vector3(0,atan2(direction.x,direction.z),0))

func _fence(length: float) -> void:
	var id: String="cloture_rustique_2m" if length<3.0 else "cloture_rustique_4m"
	b._start(id,"modules","Clôture rustique de 2 m" if length<3.0 else "Clôture rustique de 4 m","Clôture de prairie et bordure de cultures, à deux lisses et contreventement.","Emboîter les marqueurs ConnectorStart et ConnectorEnd ; longueur mesurée entre axes des poteaux.")
	var count: int=roundi(length/2.0)
	for i: int in count:_fence_run(Vector3(-length*.5+i*2,0,0),Vector3(-length*.5+(i+1)*2,0,0),i==0)
	b._marker("ConnectorStart",Vector3(-length*.5,0,0));b._marker("ConnectorEnd",Vector3(length*.5,0,0));b._save()

func _corner() -> void:
	b._start("cloture_angle_90","modules","Angle de clôture à 90°","Retour de deux travées pour cour, potager ou pré.","Deux branches de 2 m, connecteurs à leurs extrémités ; rotation libre sur Y.")
	_fence_run(Vector3(-2,0,0),Vector3.ZERO)
	_fence_run(Vector3.ZERO,Vector3(0,0,2),false)
	b._marker("ConnectorStart",Vector3(-2,0,0));b._marker("ConnectorEnd",Vector3(0,0,2));b._save()

func _gate(opened: bool) -> void:
	b._start("portail_fermier_ouvert" if opened else "portail_fermier_ferme","modules","Portail fermier ouvert" if opened else "Portail fermier fermé","Portail de ferme à deux vantaux de bois, avec pivots en fer.","Ouverture utile de 2,02 m ; passage orienté sur Z ; les vantaux ouverts longent les poteaux.")
	for side: float in [-1.,1.]:
		b._box("GatePost",Vector3(.22,1.47,.24),Vector3(side*1.12,.735,0),"dark_wood",Vector3.ZERO,true)
		b._cylinder("PostCap",Vector3(side*1.12,1.5,0),.158,.095,"wood",.03)
		var saved: Transform3D=b.model_transform
		var hinge: Vector3=Vector3(side*1.0,0,0)
		var leaf_rotation: float=(-side*PI*.5) if opened else 0.
		b.model_transform=saved*Transform3D(Basis(Vector3.UP,leaf_rotation),hinge)
		for y: float in [.28,1.13]:b._box("GateRail",Vector3(.97,.12,.11),Vector3(-side*.48,y,0),"wood")
		for i: int in 5:b._box("GateSlats",Vector3(.10,1.04,.075),Vector3(-side*(.09+i*.19),.69,.015),"wood")
		b._beam("GateBrace",Vector3(-side*.91,.28,-.035),Vector3(-side*.045,1.13,-.035),.078,"dark_wood")
		for y: float in [.29,1.10]:b._box("StrapHinges",Vector3(.28,.055,.04),Vector3(-side*.13,y,.087),"iron")
		_solid("GateLeaf",Vector3(.96,1.16,.15),Vector3(-side*.49,.68,0))
		b.model_transform=saved
	if not opened:b._box("Latch",Vector3(.27,.055,.05),Vector3(0,.89,.10),"iron")
	b._marker("ConnectorStart",Vector3(-1.12,0,0));b._marker("ConnectorEnd",Vector3(1.12,0,0))
	if opened:
		b._marker("AisleStart",Vector3(0,0,-1.5));b._marker("AisleEnd",Vector3(0,0,1.5))
	b._save()

func _barrel(at: Vector3,scale_value: float) -> void:
	var st: SurfaceTool=b._surface("BarrelStaves","wood")
	var heights: Array[float]=[0.,.18,.45,.73,.9]
	var radii: Array[float]=[.28,.33,.355,.33,.28]
	for side: int in 12:
		var a: float=TAU*(side+.018)/12.0;var c: float=TAU*(side+.982)/12.0
		for row: int in 4:
			var vertices: Array[Vector3]=[]
			for point: Vector2 in [Vector2(a,row),Vector2(c,row),Vector2(c,row+1),Vector2(a,row+1)]:
				var j: int=int(point.y)
				vertices.append(at+Vector3(sin(point.x)*radii[j],heights[j],cos(point.x)*radii[j])*scale_value)
			b._quad_out(st,vertices,Vector3(sin((a+c)*.5),0,cos((a+c)*.5)),b.rng.randf_range(.80,1.10))
	for row: int in [1,3]:b._ring("BarrelHoops",at+Vector3(0,heights[row],0)*scale_value,.342*scale_value,.326*scale_value,.065*scale_value,"iron")
	b._cylinder("Lid",at+Vector3(0,.895,0)*scale_value,.28*scale_value,.026*scale_value,"wood")
	for z: float in [-.11,.10]:b._box("LidSeams",Vector3(.48,.006,.009)*scale_value,at+Vector3(0,.91,z)*scale_value,"dark_wood")
	b._cylinder("Bung",at+Vector3(.10,.921,0)*scale_value,.035*scale_value,.027*scale_value,"dark_wood")
	var shape: CylinderShape3D=CylinderShape3D.new();shape.radius=.355*scale_value;shape.height=.93*scale_value
	b._collision("Barrel",shape,Transform3D(Basis.IDENTITY,at+Vector3(0,.465*scale_value,0)))

func _barrels() -> void:
	b._start("tonneaux_de_ferme","stockage","Trois tonneaux de ferme","Réserves de cidre, eau ou provisions, à cerclages de fer.","Sur sol sec, de préférence sous auvent ; groupe de trois contenants distincts.")
	_barrel(Vector3(-.37,0,-.23),1.0);_barrel(Vector3(.35,0,-.15),.84);_barrel(Vector3(-.02,0,.38),.65);b._save()

func _sack(at: Vector3,scale_value: float) -> void:
	_ellipsoid("SackLinen",at+Vector3(0,.35,0)*scale_value,Vector3(.49,.69,.43)*scale_value,"linen",Vector3(0,b.rng.randf_range(-.35,.35),.05))
	b._cylinder("SackNeck",at+Vector3(.017,.70,0)*scale_value,.085*scale_value,.15*scale_value,"linen",.12*scale_value)
	b._ring("SackTie",at+Vector3(.017,.683,0)*scale_value,.092*scale_value,.065*scale_value,.03*scale_value,"rope")
	for side: float in [-1.,1.]:b._beam("TieEnds",at+Vector3(.017,.685,0)*scale_value,at+Vector3(side*.11,.62,.05)*scale_value,.016*scale_value,"rope")

func _sacks() -> void:
	b._start("sacs_de_recolte","stockage","Sacs de récolte sur caillebotis","Quatre sacs de toile noués, tenus hors de la terre humide.","À proximité du grenier ou de l'entrée du moulin, sur une surface plane.")
	for x: float in [-.42,.42]:b._box("Skids",Vector3(.12,.10,1.0),Vector3(x,.05,0),"dark_wood")
	for z: float in [-.40,-.20,0.,.20,.40]:b._box("RaisedSlats",Vector3(1.2,.065,.16),Vector3(0,.13,z),"wood")
	for p: Vector3 in [Vector3(-.3,.163,-.24),Vector3(.25,.163,-.23),Vector3(-.27,.163,.23),Vector3(.30,.163,.23)]:_sack(p,b.rng.randf_range(.86,1.07))
	_solid("SackGroup",Vector3(1.18,.82,.97),Vector3(0,.48,0));b._save()

func _open_vessel(at: Vector3,radius: float,height: float,mat: String="rope") -> void:
	var st: SurfaceTool=b._surface("VesselSides",mat)
	for i: int in 12:
		var a: float=TAU*i/12.0;var c: float=TAU*(i+1)/12.0
		var outer: Array[Vector3]=[];var inner: Array[Vector3]=[]
		for p: Vector2 in [Vector2(a,0),Vector2(c,0),Vector2(c,height),Vector2(a,height)]:
			var r: float=radius*(.74+.26*p.y/height)
			outer.append(at+Vector3(sin(p.x)*r,p.y,cos(p.x)*r))
			inner.append(at+Vector3(sin(p.x)*(r-.033),p.y+.008,cos(p.x)*(r-.033)))
		b._quad_out(st,outer,Vector3(sin((a+c)*.5),0,cos((a+c)*.5)),1.0)
		b._quad_out(st,inner,-Vector3(sin((a+c)*.5),0,cos((a+c)*.5)),.86)
		b._beam("VesselUprights",outer[0],outer[3],.018,mat)
	for t: float in [.22,.5,.78,1.0]:b._ring("WovenBands",at+Vector3(0,height*t,0),radius*(.74+.26*t)+.008,radius*(.74+.26*t)-.011,.018,mat)
	b._cylinder("BasketBase",at+Vector3(0,.019,0),radius*.74,.038,mat)

func _arch_handle(at: Vector3,halfwidth: float,rise: float,mat: String="rope") -> void:
	for i: int in 8:
		var a: float=PI*i/8.0;var c: float=PI*(i+1)/8.0
		b._beam("CarryHandle",at+Vector3(cos(a)*halfwidth,sin(a)*rise,0),at+Vector3(cos(c)*halfwidth,sin(c)*rise,0),.028,mat)

func _basket_asset(pear: bool) -> void:
	b._start("panier_de_poires" if pear else "panier_de_pommes","accessoires","Panier de poires" if pear else "Panier de pommes","Panier tressé de récolte, rempli de fruits sculptés.","Au pied d'un arbre fruitier, sur une table ou près d'une échelle.")
	_open_vessel(Vector3.ZERO,.30,.32)
	_arch_handle(Vector3(0,.32,0),.285,.34)
	for row: int in 3:
		for col: int in 3:
			var p: Vector3=Vector3((col-1)*.145,.30+b.rng.randf_range(-.01,.04),(row-1)*.145)
			_fruit(p,pear,.91)
	var shape: CylinderShape3D=CylinderShape3D.new();shape.radius=.30;shape.height=.45
	b._collision("HarvestBasket",shape,Transform3D(Basis.IDENTITY,Vector3(0,.225,0)));b._save()

func _open_crate(at: Vector3) -> void:
	for x: float in [-.40,.40]:
		for z: float in [-.29,.29]:b._box("CrateCorner",Vector3(.064,.51,.064),at+Vector3(x,.255,z),"dark_wood")
	for x: float in [-.32,-.16,0.,.16,.32]:b._box("CrateFloor",Vector3(.148,.065,.60),at+Vector3(x,.033,0),"wood")
	for y: float in [.12,.27,.425]:
		for z: float in [-.307,.307]:b._box("CrateLongSlats",Vector3(.86,.11,.045),at+Vector3(0,y,z),"wood")
		for x: float in [-.417,.417]:
			if y<.4:b._box("CrateEndSlats",Vector3(.045,.11,.56),at+Vector3(x,y,0),"wood")
			else:
				# The upper end slat leaves a real handhold, rather than a painted hole.
				for z: float in [-.22,.22]:b._box("HandleSides",Vector3(.045,.11,.15),at+Vector3(x,y,z),"wood")
				b._box("HandleTop",Vector3(.045,.035,.30),at+Vector3(x,.49,0),"wood")
	_solid("Crate",Vector3(.90,.52,.65),at+Vector3(0,.26,0))

func _crate_asset(filled: bool) -> void:
	b._start("caisse_de_fruits" if filled else "caisse_ouverte_en_bois","stockage","Caisse de fruits" if filled else "Caisse ouverte en bois","Caisse ajourée à poignées évidées pour trier les récoltes.","Empilable ; dimensions 0,90 × 0,65 m, pivot sous le fond.")
	_open_crate(Vector3.ZERO)
	if filled:
		for row: int in 3:
			for col: int in 4:_fruit(Vector3((col-1.5)*.16,.42+b.rng.randf_range(-.015,.03),(row-1)*.16),col==3,.97)
	b._marker("StackTop",Vector3(0,.52,0));b._save()

func _ladder(tripod: bool) -> void:
	b._start("echelle_tripode_de_verger" if tripod else "echelle_droite_de_recolte","accessoires","Échelle tripode de verger" if tripod else "Échelle droite de récolte","Échelle de récolte en frêne, à barreaux traversants.","Tripode autonome, ouvert au sol." if tripod else "Appuyer la tête contre un tronc ou un mur ; cette pièce est décorative, sans escalade automatique.")
	var height: float=2.6 if tripod else 3.1
	var foot_z: float=.50 if tripod else .47
	var top_z: float=-.22 if tripod else -.20
	for side: float in [-1.,1.]:
		var bottom: Vector3=Vector3(side*.38,.06,foot_z)
		var top: Vector3=Vector3(side*(.22 if tripod else .38),height,top_z)
		b._beam("LadderRails",bottom,top,.095,"wood")
		b._beam("IronFoot",bottom,Vector3(side*.38,.18,foot_z-.025),.103,"iron")
	for i: int in 9:
		var t: float=(i+1)/10.0;var x: float=lerpf(.38,.22 if tripod else .38,t)
		var y: float=lerpf(.06,height,t);var z: float=lerpf(foot_z,top_z,t)
		b._beam("LadderRungs",Vector3(-x,y,z),Vector3(x,y,z),.057,"wood")
	if tripod:
		b._beam("ThirdLeg",Vector3(0,.045,-1.12),Vector3(0,height-.09,top_z),.115,"dark_wood")
		b._beam("SpreadRope",Vector3(0,1.12,-.73),Vector3(0,1.12,.19),.026,"rope")
		b._cylinder("HingePin",Vector3(0,height-.13,top_z),.055,.57,"iron",.055,Vector3(0,0,PI*.5))
		_solid("LadderBase",Vector3(.87,1.12,1.76),Vector3(0,.56,-.30))
	else:
		var angle: float=atan2(foot_z-top_z,height-.06)
		_solid("LeaningLadder",Vector3(.86,height,.11),Vector3(0,height*.5,(foot_z+top_z)*.5),Vector3(-angle,0,0))
	b._save()

func _tools() -> void:
	b._start("ratelier_outils_agricoles","accessoires","Râtelier d'outils agricoles","Rangement couvert d'une houe, d'une fourche, d'une bêche et d'un râteau.","Adossable à une grange, outils visibles depuis +Z.")
	for x: float in [-.94,.94]:
		b._box("RackUprights",Vector3(.14,1.89,.14),Vector3(x,.945,0),"dark_wood")
		b._box("RackFeet",Vector3(.20,.13,.65),Vector3(x,.065,.05),"wood")
	for y: float in [.43,1.51]:b._box("RackCrossbar",Vector3(2.03,.12,.13),Vector3(0,y,0),"wood")
	for i: int in 4:
		var x: float=-.65+i*.43
		b._beam("ToolHandles",Vector3(x,.18,.18),Vector3(x+.045,1.72,.16),.045,"wood")
		b._box("ToolHooks",Vector3(.065,.09,.21),Vector3(x,1.45,.15),"iron")
		match i:
			0:
				b._box("HoeBlade",Vector3(.23,.06,.18),Vector3(x,1.75,.235),"iron",Vector3(.2,0,0))
			1:
				b._beam("ForkShoulder",Vector3(x-.14,.34,.19),Vector3(x+.14,.34,.19),.035,"iron")
				for j: int in 3:b._beam("ForkTines",Vector3(x-.12+j*.12,.34,.19),Vector3(x-.12+j*.12,.065,.25),.026,"iron")
			2:
				b._box("SpadeBlade",Vector3(.25,.32,.042),Vector3(x,.18,.19),"iron",Vector3(-.10,0,0))
				b._ring("SpadeGrip",Vector3(x+.045,1.78,.16),.09,.062,.037,"wood",Vector3(PI*.5,0,0))
			3:
				b._box("RakeHead",Vector3(.45,.07,.06),Vector3(x,1.74,.20),"wood")
				for j: int in 7:b._beam("RakeTeeth",Vector3(x-.18+j*.06,1.74,.20),Vector3(x-.18+j*.06,1.62,.30),.026,"wood")
	b._lean_roof(Vector3(0,0,0),2.06,.70,1.95,.30)
	_solid("ToolRack",Vector3(2.06,1.94,.63),Vector3(0,.97,.045));b._save()

func _plough() -> void:
	b._start("araire_de_bois","accessoires","Araire de bois à soc ferré","Outil de labour à long age, deux mancherons et sabot renforcé.","Poser à côté d'une parcelle labourée ou d'un attelage ; aucune mécanique de culture intégrée.")
	b._beam("PloughBeam",Vector3(0,.32,-.47),Vector3(0,.79,1.76),.18,"wood")
	b._beam("PloughShareStock",Vector3(0,.09,-.30),Vector3(0,.17,.46),.20,"dark_wood")
	b._box("IronShare",Vector3(.30,.07,.43),Vector3(0,.045,.42),"iron",Vector3(-.04,0,0))
	b._beam("ShareBrace",Vector3(0,.12,.11),Vector3(0,.64,.87),.11,"wood")
	for side: float in [-1.,1.]:
		b._beam("PloughHandles",Vector3(side*.12,.25,-.28),Vector3(side*.31,1.23,-1.24),.09,"wood")
		b._beam("HandleGrips",Vector3(side*.31,1.23,-1.24),Vector3(side*.31,1.20,-1.50),.075,"wood")
	b._beam("HandleTie",Vector3(-.25,.91,-.91),Vector3(.25,.91,-.91),.065,"wood")
	b._ring("HitchRing",Vector3(0,.80,1.85),.10,.061,.04,"iron",Vector3(PI*.5,0,0))
	_solid("ShareBody",Vector3(.33,.33,.92),Vector3(0,.17,.11))
	_solid("LongAge",Vector3(.20,.22,2.18),Vector3(0,.54,.69),Vector3(-.208,0,0))
	b._marker("TowPoint",Vector3(0,.8,1.90));b._save()

func _water_trough() -> void:
	b._start("auge_en_pierre","accessoires","Auge en pierre et eau","Abreuvoir évidé, alimentable par une gouttière de bois.","Placer au bord d'une cour ou d'un pré, sur un sol horizontal ; l'eau est contenue dans l'auge.")
	for x: float in [-.65,.65]:b._box("StoneFeet",Vector3(.32,.15,.76),Vector3(x,.075,0),"stone")
	b._box("TroughFloor",Vector3(2.03,.19,.92),Vector3(0,.225,0),"stone")
	for x: float in [-.955,.955]:b._box("TroughEnds",Vector3(.18,.48,.92),Vector3(x,.52,0),"stone")
	for z: float in [-.39,.39]:b._box("TroughWalls",Vector3(1.76,.48,.15),Vector3(0,.52,z),"stone")
	b._box("ContainedWater",Vector3(1.73,.015,.605),Vector3(0,.586,0),"water")
	b._cylinder("DrainPlug",Vector3(.99,.38,.03),.052,.13,"wood",.052,Vector3(0,0,PI*.5))
	_solid("StoneTrough",Vector3(2.09,.75,.92),Vector3(0,.375,0))
	b._marker("WaterInlet",Vector3(0,.76,-.43));b._marker("UsePoint",Vector3(0,0,1.0));b._save()
