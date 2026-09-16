extends RefCounted
## Individually composed timber-industry assets, built and saved offline.
var b: Variant

func _init(builder: Variant) -> void:b=builder

func start(id: String,label: String,group: String,description: String) -> void:
	b._start(id,group,label,description,"Asset de la scierie, à placer sur une assise adaptée ; 1 unité = 1 mètre.")

func finish() -> void:b._save()

func build() -> void:
	start("scierie_hydraulique","Grande scierie à roue à eau","production","Halle de sciage, chariot de grume, scie verticale, transmission, roue et arrivée d’eau. Mécanisme statique pour le décor.")
	mill();finish()
	start("roue_a_aubes","Roue à augets et palier","production","Roue indépendante de 4,3 m de diamètre ; axe horizontal et supports.")
	wheel(Vector3(0,2.25,0))
	for x: float in [-.98,.98]:b._box("BearingPier",Vector3(.65,2.12,.70),Vector3(x,1.06,0),"stone",Vector3.ZERO,true)
	finish()
	start("atelier_charpentier","Atelier du maître charpentier","production","Maison-atelier à colombages, grand auvent de taille et poutre en cours d’équarrissage.")
	b._room(Vector3(0,0,-1),5.6,4.2,3.0)
	b._shed(Vector3(0,0,2.5),6.0,2.4,2.6,.65,false,"rust_roof",.7)
	sawhorse(Vector3(-1.1,0,2.45));sawhorse(Vector3(1.1,0,2.45))
	b._box("BeamOnHorses",Vector3(3.7,.29,.32),Vector3(0,1.00,2.45),"fresh_wood",Vector3.ZERO,true)
	b._bench(Vector3(-1.6,0,-.15),true);b._chimney(Vector3(1.6,1,-1.8),3.8);finish()
	start("atelier_charron","Halle du charron","production","Atelier ouvert pour assembler roues, essieux et véhicules de transport du bois.")
	b.architecture.hall(Vector3.ZERO,6.4,4.8,3.1,true)
	b._bench(Vector3(-1.9,0,-1),true)
	for z: float in [-.8,.5]:cartwheel(Vector3(2.0,.80,z),.78)
	b._box("AxleBlank",Vector3(2.8,.19,.22),Vector3(-1.3,1.10,-1),"fresh_wood")
	finish()
	start("fosse_sciage","Banc de sciage de long","production","Plateforme surélevée : un scieur au-dessus, un passage libre au-dessous. Peut être enfoncée dans une fosse de terrain.")
	for x: float in [-1.3,1.3]:
		for z: float in [-2.1,2.1]:b._beam("PitPosts",Vector3(x,0,z),Vector3(x,2.1,z),.22,"dark_wood",true)
		b._box("PitWalkway",Vector3(.65,.17,4.8),Vector3(x,2.1,0),"wood",Vector3.ZERO,true)
	for z: float in [-1.8,1.8]:b._beam("CrossBunks",Vector3(-1.6,1.98,z),Vector3(1.6,1.98,z),.19,"dark_wood")
	log_at(Vector3(0,2.50,0),4.7,.31)
	sawblade(Vector3(0,1.75,0),2.3,.25)
	ladder(Vector3(-1.3,0,3.65),2.2,1.2)
	finish()
	start("halle_sechage","Grand séchoir à planches","stockage","Halle ventilée ; planches empilées sur tasseaux et passage central libre.")
	b.architecture.hall(Vector3.ZERO,7.0,5.0,3.3,true)
	for x: float in [-2.25,2.25]:planks(Vector3(x,0,-.1),4.1,1.55,7)
	finish()
	start("depot_grumes","Dépôt couvert des grumes","stockage","Réserve de troncs sous charpente, buttées latérales et allée de manutention.")
	b.architecture.hall(Vector3.ZERO,7.8,5.7,3.6,true)
	logs(Vector3(-1.8,0,-.3),4.8,.30,3)
	for z: float in [-2.25,1.8]:
		for x: float in [-3.1,-.5]:b._beam("LogStop",Vector3(x,0,z),Vector3(x,1.35,z),.18,"dark_wood",true)
	finish()
	start("bureau_bois","Comptoir et bureau du bois","village","Petit bâtiment de gestion des livraisons ; comptoir et registre de coupe sans PNJ.")
	b._room(Vector3(0,0,-.5),3.9,3.4,2.9)
	b._shed(Vector3(0,0,1.85),4.2,1.25,2.25,.5,false,"rust_roof",.5)
	b._bench(Vector3(-1.10,0,1.75),false)
	b._box("Ledger",Vector3(.43,.06,.32),Vector3(-1.05,1.035,1.75),"leather")
	finish()
	start("hangar_charrettes_bois","Remise des charrettes","stockage","Hangar traversant à trois travées, pour manœuvrer les véhicules et protéger les harnais.")
	b.architecture.hall(Vector3.ZERO,7.6,5.2,3.25,false)
	b._barrel(Vector3(3,0,-1.8),1);b._crate(Vector3(-3,0,-1.7),1);finish()
	start("portique_chargement","Portique de levage à treuil","production","Palan et tambour manuel au-dessus d’un passage de charrette ; hauteur libre 3 m.")
	gantry();finish()
	start("charrette_grumes","Charrette de débardage","stockage","Véhicule à quatre roues de bois avec timon, arrimages et trois grumes.")
	cart();finish()
	start("grumes_longues","Grumes longues empilées","accessoires","Troncs écorcés partiellement, coupes claires et cales de retenue.")
	logs(Vector3.ZERO,5.2,.32,4);finish()
	start("grumes_courtes","Billons de réserve","accessoires","Billons courts triés, destinés aux petites pièces et au charronnage.")
	logs(Vector3.ZERO,2.2,.27,3);finish()
	start("tas_planches","Planches sur tasseaux","accessoires","Planches espacées par des tasseaux : l’air circule entre les lits.")
	planks(Vector3.ZERO,4.2,1.6,6);finish()
	start("poutres_equarries","Poutres équarries","accessoires","Longues poutres de charpente rangées sur traverses.")
	for z: float in [-1.8,1.8]:b._box("Bearers",Vector3(1.9,.19,.23),Vector3(0,.095,z),"dark_wood",Vector3.ZERO,true)
	for y: int in 3:
		for x: int in 4:b._box("SquaredBeam",Vector3(.30,.28,4.9),Vector3(-.52+x*.35,.33+y*.30,0),"fresh_wood")
	finish()
	start("chevalets_sciage","Paire de chevalets de sciage","accessoires","Chevalets assemblés, billon et scie à cadre.")
	for z: float in [-1.0,1.0]:sawhorse(Vector3(0,0,z))
	log_at(Vector3(0,1.0,0),3.0,.19);handsaw(Vector3(.53,.68,.4));finish()
	start("etabli_menuisier","Établi de menuisier","accessoires","Établi, rabot, maillet, serre-joint et pièce en travail.")
	b._bench(Vector3.ZERO,false)
	b._box("PlaneBody",Vector3(.32,.12,.13),Vector3(-.4,1.08,.06),"dark_wood")
	b._box("PlaneIron",Vector3(.09,.13,.035),Vector3(-.39,1.18,.05),"metal",Vector3(.25,0,0))
	b._beam("MalletHandle",Vector3(.3,1.04,-.2),Vector3(.3,1.04,.22),.035,"wood")
	b._box("MalletHead",Vector3(.22,.12,.12),Vector3(.3,1.09,-.2),"wood")
	finish()
	start("ratelier_outils_bois","Râtelier du bûcheron","accessoires","Haches, cognée, scie à cadre et perche de manutention.")
	toolrack();finish()
	start("tas_chutes","Chutes et copeaux","accessoires","Petites chutes de taille regroupées hors des circulations.")
	for i: int in 24:
		b._box("Offcut",Vector3(b.rng.randf_range(.1,.22),.07,b.rng.randf_range(.2,.7)),Vector3(b.rng.randf_range(-.6,.6),.08+(i/8)*.08,b.rng.randf_range(-.6,.6)),"fresh_wood",Vector3(0,b.rng.randf_range(-1.5,1.5),0))
	finish()
	start("tonneaux_resine","Tonneaux et petit seau","accessoires","Récipients pour résine et produits d’entretien du bois.")
	b._barrel(Vector3(-.45,0,0),1.0);b._barrel(Vector3(.50,0,.14),.75);finish()
	start("traineau_debardage","Traîneau de débardage","stockage","Deux patins relevés, traverses et cordage de traction pour amener le bois.")
	for x: float in [-.55,.55]:
		b._beam("Runner",Vector3(x,.15,-1.3),Vector3(x,.15,1.05),.16,"dark_wood",true)
		b._beam("RunnerToe",Vector3(x,.15,1.05),Vector3(x,.42,1.6),.16,"dark_wood")
	for z: float in [-.85,0,.85]:b._box("SledCross",Vector3(1.4,.15,.26),Vector3(0,.28,z),"wood",Vector3.ZERO,true)
	for x: float in [-.55,.55]:b._beam("TowRope",Vector3(x,.4,1.6),Vector3(0,.08,2.6),.035,"rope")
	finish()
	start("billot_fendage","Billot de fendage","accessoires","Billot haut, hache posée et bois fendu.")
	b._cylinder("ChoppingBlock",Vector3(0,.35,0),.42,.7,"bark",.39,Vector3.ZERO,true)
	b._cylinder("BlockEnd",Vector3(0,.709,0),.37,.022,"endgrain",.37)
	b._beam("AxeHandle",Vector3(.1,.72,0),Vector3(.2,1.48,.08),.045,"wood")
	b._box("AxeBlade",Vector3(.30,.21,.035),Vector3(.1,.78,0),"metal")
	for x: float in [.63,.84]:b._box("SplitWood",Vector3(.14,.16,.65),Vector3(x,.09,.13),"fresh_wood",Vector3(0,x,0))
	finish()
	start("quai_bois","Quai de chargement en bois","modules","Plateforme de rive avec poteaux, planches et anneaux d’amarrage.")
	deck(5.2,3.4,1.0,true);finish()
	start("passerelle_bois","Passerelle à garde-corps","modules","Petite passerelle de 5,5 m à poser entre deux berges.")
	deck(1.9,5.5,.38,false)
	for x: float in [-.91,.91]:
		for z: float in [-2.65,0,2.65]:b._beam("BridgePosts",Vector3(x,.35,z),Vector3(x,1.52,z),.105,"dark_wood",true)
		for y: float in [.88,1.5]:b._beam("BridgeRail",Vector3(x,y,-2.7),Vector3(x,y,2.7),.095,"wood",true)
	finish()
	start("canal_amenee","Canal d’amenée sur chevalets","modules","Tronçon de 4 m, ouverture de 0,85 m ; raccorder sa sortie au niveau de la roue.")
	flume(Vector3.ZERO,4.0,2.9);finish()
	start("vanne_bois","Vanne et crémaillère en bois","modules","Vanne verticale guidée entre deux montants ; panneau statique réglable dans l’éditeur.")
	for x: float in [-.67,.67]:b._beam("GateGuide",Vector3(x,0,0),Vector3(x,2.3,0),.18,"dark_wood",true)
	b._box("GateLintel",Vector3(1.62,.17,.22),Vector3(0,2.28,0),"dark_wood")
	for y: int in 6:b._box("GatePlanks",Vector3(1.18,.17,.11),Vector3(0,.42+y*.18,0),"wood",Vector3.ZERO,true)
	b._beam("GateLiftRod",Vector3(0,1.3,.02),Vector3(0,2.7,.02),.085,"wood")
	for y: int in 10:b._box("WoodenRackTeeth",Vector3(.09,.035,.045),Vector3(.05,1.65+y*.08,.02),"dark_wood")
	b._beam("GateHandle",Vector3(-.48,2.0,.16),Vector3(.48,2.0,.16),.075,"wood")
	finish()

func log_at(at: Vector3,length: float,radius: float) -> void:
	b._cylinder("LogBark",at,radius,length,"bark",radius*.88,Vector3(PI*.5,0,0))
	for side: float in [-1.0,1.0]:
		var p: Vector3=at+Vector3(0,0,side*(length*.5+.008))
		b._cylinder("CutEnd",p,radius*.85,.018,"endgrain",radius*.85,Vector3(PI*.5,0,0))
		for ratio: float in [.30,.55,.76]:b._ring("GrowthRings",p+Vector3(0,0,side*.013),radius*ratio,radius*ratio-.012,.01,"wood",Vector3(PI*.5,0,0))

func logs(at: Vector3,length: float,radius: float,base_count: int) -> void:
	for z: float in [-length*.32,length*.32]:b._box("LogBearers",Vector3(base_count*radius*2+.4,.18,.24),at+Vector3(0,.09,z),"dark_wood",Vector3.ZERO,true)
	for row: int in base_count:
		var count: int=base_count-row
		for i: int in count:log_at(at+Vector3((i-(count-1)*.5)*radius*1.92,.18+radius+row*radius*1.68,0),length+b.rng.randf_range(-.18,.18),radius)
	var shape: BoxShape3D=BoxShape3D.new();shape.size=Vector3(base_count*radius*2,base_count*radius*1.68,length)
	b._collision("LogStack",shape,Transform3D(Basis.IDENTITY,at+Vector3(0,.18+shape.size.y*.5,0)))

func planks(at: Vector3,length: float,width: float,rows: int) -> void:
	for z: float in [-length*.35,length*.35]:b._box("PlankBearers",Vector3(width+.18,.18,.22),at+Vector3(0,.09,z),"dark_wood",Vector3.ZERO,true)
	for row: int in rows:
		for col: int in 5:b._box("SeasoningBoards",Vector3(width/5-.026,.08,length),at+Vector3(-width*.5+(col+.5)*width/5,.22+row*.15,0),"fresh_wood")
		for z: float in [-length*.34,0,length*.34]:b._box("AirSpacers",Vector3(width,.066,.075),at+Vector3(0,.293+row*.15,z),"wood")
	var shape: BoxShape3D=BoxShape3D.new();shape.size=Vector3(width,.21+rows*.15,length)
	b._collision("PlankStack",shape,Transform3D(Basis.IDENTITY,at+Vector3(0,shape.size.y*.5,0)))

func sawhorse(at: Vector3) -> void:
	for z: float in [-.29,.29]:
		for side: float in [-1.0,1.0]:b._beam("HorseLeg",at+Vector3(side*.45,0,z),at+Vector3(side*.19,.91,z),.10,"wood",true)
	b._beam("HorseTop",at+Vector3(-.57,.87,0),at+Vector3(.57,.87,0),.14,"dark_wood")
	b._beam("HorseBrace",at+Vector3(-.31,.35,0),at+Vector3(.31,.35,0),.07,"wood")

func handsaw(at: Vector3) -> void:
	for x: float in [-.42,.42]:b._beam("FrameSawEnds",at+Vector3(x,-.20,0),at+Vector3(x,.42,0),.055,"wood")
	b._beam("FrameSawBrace",at+Vector3(-.42,.10,0),at+Vector3(.42,.10,0),.045,"wood")
	b._beam("FrameSawTension",at+Vector3(-.42,.37,0),at+Vector3(.42,.37,0),.018,"rope")
	b._box("FrameSawBlade",Vector3(.81,.055,.012),at+Vector3(0,-.17,0),"metal")

func sawblade(at: Vector3,height: float,width: float) -> void:
	b._box("SawBlade",Vector3(width,height,.025),at,"metal")
	var st: SurfaceTool=b._surface("SawTeeth","metal")
	for i: int in ceili(height/.09):
		var y: float=-height*.5+i*.09
		b._tri(st,at+Vector3(width*.5,y,0),at+Vector3(width*.5+.065,y+.02,0),at+Vector3(width*.5,y+.07,0))

func wheel(at: Vector3) -> void:
	for x: float in [-.42,.42]:
		b._ring("WheelRim",at+Vector3(x,0,0),2.15,1.91,.13,"dark_wood",Vector3(0,0,PI*.5))
		b._ring("WheelIronBand",at+Vector3(x,0,0),2.17,2.12,.14,"iron",Vector3(0,0,PI*.5))
		for i: int in 12:
			var a: float=TAU*i/12
			b._beam("WheelSpokes",at+Vector3(x,0,0),at+Vector3(x,sin(a)*2.0,cos(a)*2.0),.13,"wood")
	for i: int in 28:
		var a: float=TAU*i/28
		b._box("WheelBuckets",Vector3(1.02,.22,.35),at+Vector3(0,sin(a)*2.0,cos(a)*2.0),"wood",Vector3(PI*.5-a,0,0))
	b._cylinder("WheelHub",at,.33,1.18,"dark_wood",.33,Vector3(0,0,PI*.5))
	b._beam("DriveAxle",at+Vector3(-1.45,0,0),at+Vector3(1.40,0,0),.23,"dark_wood")
	var shape: CylinderShape3D=CylinderShape3D.new();shape.radius=2.19;shape.height=1.06
	b._collision("Waterwheel",shape,Transform3D(Basis(Vector3.FORWARD,PI*.5),at))
	b._marker("WheelAxis",at)

func flume(at: Vector3,length: float,height: float) -> void:
	b._box("FlumeBed",Vector3(1.10,.13,length),at+Vector3(0,height,0),"wood")
	for side: float in [-1.0,1.0]:b._box("FlumeSide",Vector3(.13,.37,length),at+Vector3(side*.55,height+.17,0),"dark_wood")
	b._box("FlumeWater",Vector3(.91,.025,length),at+Vector3(0,height+.12,0),"water")
	for z: float in [-length*.39,length*.39]:
		for x: float in [-.70,.70]:b._beam("FlumeLegs",at+Vector3(x,0,z),at+Vector3(x*.65,height-.02,z),.18,"dark_wood",true)
		b._box("FlumeCrossSupport",Vector3(1.68,.18,.23),at+Vector3(0,height-.16,z),"wood")
	b._marker("WaterIn",at+Vector3(0,height+.12,-length*.5));b._marker("WaterOut",at+Vector3(0,height+.12,length*.5))

func mill() -> void:
	# The main hall stands on a raised riverside platform; the wheel hangs beside it.
	deck(7.8,6.3,1.08,true)
	b.architecture.hall(Vector3(0,1.08,0),7.4,5.9,3.25,true)
	var eave: float=4.33;var rise: float=5.9*.57
	b._box("LoftFloor",Vector3(7.4,.16,5.9),Vector3(0,eave+.02,0),"wood")
	var saved: Transform3D=b.model_transform
	b.model_transform=Transform3D(Basis(Vector3.UP,PI*.5),Vector3.ZERO)
	b.architecture.gable(5.9,7.4,eave,rise)
	b.model_transform=saved
	for x: float in [-2.0,2.0]:b.architecture.dormer(Vector3.ZERO,7.4,5.9,eave,rise,x)
	# Carriage and reciprocal saw are visible through the open work face.
	for x: float in [-.85,.85]:b._box("WoodCarriageWays",Vector3(.19,.20,5.3),Vector3(x,1.33,0),"dark_wood",Vector3.ZERO,true)
	for z: float in [-1.55,1.55]:b._box("CarriageBunk",Vector3(2.1,.19,.24),Vector3(0,1.65,z),"wood")
	log_at(Vector3(0,2.02,.15),4.8,.30)
	for x: float in [-1.1,1.1]:b._beam("SawFrameUpright",Vector3(x,1.1,-.35),Vector3(x,3.9,-.35),.18,"dark_wood",true)
	for y: float in [1.55,3.8]:b._box("SawCrossbar",Vector3(2.4,.18,.20),Vector3(0,y,-.35),"wood")
	sawblade(Vector3(.10,2.69,-.35),2.2,.17)
	for x: float in [-.67,.67]:b._beam("ReciprocatingFrame",Vector3(x,1.55,-.35),Vector3(x,3.8,-.35),.09,"wood")
	# Wheel axle visibly enters the building; a wooden cogwheel and crank link the saw.
	wheel(Vector3(4.65,2.25,-.65))
	b._beam("AxleToCrank",Vector3(4.65,2.25,-.65),Vector3(1.4,2.25,-.65),.20,"dark_wood")
	b._ring("DriveGear",Vector3(1.6,2.25,-.65),.66,.50,.15,"wood",Vector3(0,0,PI*.5))
	for i: int in 20:
		var a: float=TAU*i/20
		b._box("GearTeeth",Vector3(.18,.13,.13),Vector3(1.6,2.25+sin(a)*.69,-.65+cos(a)*.69),"dark_wood",Vector3(-a,0,0))
	b._beam("ConnectingRod",Vector3(1.65,1.75,-.65),Vector3(.65,1.56,-.35),.075,"iron")
	b._box("OuterWheelBearing",Vector3(.55,2.13,.65),Vector3(5.8,1.065,-.65),"stone",Vector3.ZERO,true)
	flume(Vector3(4.65,0,-4.25),6.0,4.44)
	b._box("WaterDischarge",Vector3(.82,.65,.035),Vector3(4.65,4.20,-1.23),"water")
	# Ramp reaches exactly the front floor; the saw carriage leaves a side passage.
	for i: int in 15:
		var z: float=5.8-i*.18;var y: float=.07+i*1.02/14
		b._box("LoadingRampBoards",Vector3(2.6,.09,.23),Vector3(0,y,z),"wood",Vector3(.38,0,0))
	for x: float in [-1.06,1.06]:b._beam("RampStringers",Vector3(x,.02,5.95),Vector3(x,1.00,3.12),.17,"dark_wood")
	b._stair_ramp("MillRamp",0,2.6,5.95,3.12,1.12)
	for x: float in [-3.4,3.4]:b._beam("LoadingCanopyBrace",Vector3(x,2.55,2.9),Vector3(x,3.2,3.75),.13,"dark_wood")
	b._lean_roof(Vector3(0,0,3.35),7.4,1.3,3.25,.5,"rust_roof")
	b._marker("PlayerApproach",Vector3(2.65,1.12,2.65))
	b._marker("Tailrace",Vector3(4.65,.05,2.2))

func cartwheel(at: Vector3,radius: float=.65) -> void:
	b._ring("CartRim",at,radius,radius-.12,.12,"wood",Vector3(0,0,PI*.5))
	b._ring("CartTyre",at,radius+.02,radius-.018,.13,"iron",Vector3(0,0,PI*.5))
	for i: int in 10:
		var a: float=TAU*i/10
		b._beam("CartSpokes",at,at+Vector3(0,sin(a),cos(a))*(radius-.06),.055,"wood")
	b._cylinder("CartHub",at,.14,.22,"dark_wood",.14,Vector3(0,0,PI*.5))

func cart() -> void:
	for z: float in [-1.45,1.45]:
		b._beam("CartAxle",Vector3(-1.13,.7,z),Vector3(1.13,.7,z),.12,"dark_wood")
		for x: float in [-1.08,1.08]:cartwheel(Vector3(x,.7,z),.67)
	for x: float in [-.68,.68]:b._beam("CartChassis",Vector3(x,.91,-1.95),Vector3(x,.91,1.95),.17,"dark_wood",true)
	for z: float in [-1.55,1.55]:
		b._box("CartBunk",Vector3(1.7,.16,.25),Vector3(0,1.07,z),"wood")
		for x: float in [-.79,.79]:b._beam("CartStake",Vector3(x,1,z),Vector3(x,1.85,z),.095,"dark_wood")
	for x: float in [-.32,.32]:log_at(Vector3(x,1.4,0),4.1,.27)
	log_at(Vector3(0,1.83,0),3.95,.25)
	for z: float in [-1.38,1.38]:
		b._beam("Lashing",Vector3(-.72,1.12,z),Vector3(0,2.11,z),.032,"rope")
		b._beam("Lashing",Vector3(0,2.11,z),Vector3(.72,1.12,z),.032,"rope")
	b._beam("CartPole",Vector3(0,.82,1.5),Vector3(0,.60,4.5),.13,"wood")

func gantry() -> void:
	for x: float in [-2.0,2.0]:
		b._box("CraneFeet",Vector3(.64,.45,.68),Vector3(x,.225,0),"stone",Vector3.ZERO,true)
		b._beam("CranePosts",Vector3(x,.40,0),Vector3(x,3.5,0),.28,"dark_wood",true)
		b._beam("CraneBraces",Vector3(x,2.5,0),Vector3(x-signf(x)*.8,3.45,0),.16,"wood")
	b._box("CraneLintel",Vector3(4.65,.30,.42),Vector3(0,3.52,0),"dark_wood")
	b._ring("HoistPulley",Vector3(0,3.22,0),.25,.08,.17,"wood",Vector3(PI*.5,0,0))
	b._beam("HoistLine",Vector3(0,3.23,.13),Vector3(0,1.2,.13),.035,"rope")
	b._ring("HoistHook",Vector3(0,1.08,.13),.13,.083,.05,"iron",Vector3(PI*.5,0,0))
	b._cylinder("Winch",Vector3(2.65,.95,0),.28,.85,"wood",.28,Vector3(0,0,PI*.5))
	for x: float in [2.12,3.16]:b._beam("WinchStand",Vector3(x,0,0),Vector3(x,1.15,0),.16,"dark_wood",true)
	b._beam("WinchRope",Vector3(2.65,1.1,.18),Vector3(0,3.23,.13),.035,"rope")
	b._beam("WinchCrank",Vector3(3.25,.95,0),Vector3(3.25,1.4,0),.055,"iron")
	b._beam("WinchGrip",Vector3(3.25,1.4,0),Vector3(3.52,1.4,0),.07,"wood")

func toolrack() -> void:
	for x: float in [-.9,.9]:b._beam("ToolPosts",Vector3(x,0,0),Vector3(x,1.75,0),.10,"dark_wood",true)
	for y: float in [.35,1.3]:b._box("ToolRails",Vector3(2.0,.10,.13),Vector3(0,y,0),"wood")
	for x: float in [-.65,-.25,.22]:
		b._beam("AxeHandles",Vector3(x,.12,.13),Vector3(x+.07,1.43,.13),.045,"wood")
		b._box("AxeHeads",Vector3(.28,.17,.04),Vector3(x+.13,1.32,.13),"metal")
	handsaw(Vector3(.51,.58,.15))

func deck(width: float,depth: float,height: float,stone_feet: bool) -> void:
	for x: float in [-width*.44,width*.44]:
		for z: float in [-depth*.43,depth*.43]:
			b._box("DeckSupports",Vector3(.48,height,.48),Vector3(x,height*.5,z),"stone" if stone_feet else "dark_wood",Vector3.ZERO,true)
	var count: int=ceili(depth/.24)
	for i: int in count:b._box("DeckBoards",Vector3(width,.13,depth/count-.012),Vector3(0,height,-depth*.5+(i+.5)*depth/count),"wood")
	var shape: BoxShape3D=BoxShape3D.new();shape.size=Vector3(width,.13,depth)
	b._collision("DeckFloor",shape,Transform3D(Basis.IDENTITY,Vector3(0,height,0)))

func ladder(at: Vector3,height: float,run: float) -> void:
	for x: float in [-.37,.37]:b._beam("LadderRails",at+Vector3(x,0,0),at+Vector3(x,height,-run),.08,"wood")
	for i: int in 8:b._beam("LadderRungs",at+Vector3(-.38,height*(i+.5)/8,-run*(i+.5)/8),at+Vector3(.38,height*(i+.5)/8,-run*(i+.5)/8),.065,"wood")
