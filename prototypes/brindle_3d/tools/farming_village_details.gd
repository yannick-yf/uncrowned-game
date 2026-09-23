extends RefCounted
## Scene dressing only: the village plan owns every placement and quantity.
## dressing entry: {id: String, kind: stall|bench|sign|sluice,
##                  xz: [X, Z], altitude: Y, yaw: degrees}.
## Geometry and collisions join the builder's current item; this helper never saves.
var b: Variant
var detail_id: String=""

func _init(builder: Variant) -> void:
	b=builder

func build() -> void:
	var previous_transform: Transform3D=b.model_transform
	for entry: Dictionary in b.layout.get("dressing",[]):
		detail_id=str(entry["id"])
		var xz: Array=entry["xz"]
		var origin: Vector3=Vector3(float(xz[0]),float(entry["altitude"]),float(xz[1]))
		var yaw: float=deg_to_rad(float(entry.get("yaw",0.0)))
		# The existing primitive builder applies this transform to both vertices and
		# collision bodies. Local rotations therefore remain local to each detail.
		b.model_transform=previous_transform*Transform3D(Basis(Vector3.UP,yaw),origin)
		match str(entry["kind"]):
			"stall":_stall(posmod(detail_id.hash(),3))
			"bench":_bench(posmod(detail_id.hash(),2))
			"sign":_sign(posmod(detail_id.hash(),3))
			"sluice":_sluice()
			_:push_error("Unknown farming dressing kind for "+detail_id+": "+str(entry["kind"]))
		b.model_transform=previous_transform
	detail_id=""

func _box(label: String,size: Vector3,at: Vector3,mat: String,rot: Vector3=Vector3.ZERO,collide: bool=false) -> void:
	b._box(detail_id+"_"+label,size,at,mat,rot,collide)

func _beam(label: String,a: Vector3,end: Vector3,width: float,mat: String="wood",collide: bool=false) -> void:
	b._beam(detail_id+"_"+label,a,end,width,mat,collide)

func _cylinder(label: String,at: Vector3,radius: float,height: float,mat: String,top_radius: float=-1.0,rot: Vector3=Vector3.ZERO) -> void:
	b._cylinder(detail_id+"_"+label,at,radius,height,mat,top_radius,rot)

func _stall(variant: int) -> void:
	var width: float=2.32+variant*.10
	var half: float=width*.5
	# A small stall faces +Z. The customer edge stays clear of crates and braces.
	for x: float in [-half,half]:
		for z: float in [-.72,.66]:
			var top: float=2.58 if z<0 else 2.35
			_box("OakUpright",Vector3(.105,top,.105),Vector3(x,top*.5,z),"dark_wood",Vector3.ZERO,true)
			_box("FootCollar",Vector3(.12,.09,.12),Vector3(x,.13,z),"iron")
		_beam("SideAwningRail",Vector3(x,2.58,-.84),Vector3(x,2.32,.82),.087,"wood")
		_beam("RearKneeBrace",Vector3(x,2.10,-.72),Vector3(x-signf(x)*.37,2.53,-.72),.07,"wood")
	for p: Vector2 in [Vector2(-.77,2.59),Vector2(.76,2.34)]:
		_beam("ClothCrossbar",Vector3(-half-.15,p.y,p.x),Vector3(half+.15,p.y,p.x),.072,"wood")
	var rise: float=.28
	var canopy_depth: float=1.87
	var slope: float=atan2(rise,canopy_depth)
	_box("LinenAwning",Vector3(width+.40,.035,canopy_depth/cos(slope)),Vector3(0,2.465,-.015),"linen",Vector3(slope,0,0))
	# Short overlapping hems give the linen a soft silhouette at map scale.
	for i: int in 11:
		var hem_height: float=.14+.032*sin(PI*(i+.5)/11.0)
		var x: float=-(width+.40)*.5+(i+.5)*(width+.40)/11.0
		_box("AwningHem",Vector3((width+.40)/11.0+.008,hem_height,.028),Vector3(x,2.325-hem_height*.5,.926),"linen")
	for x: float in [-half-.07,half+.07]:
		_beam("LinenSideBinding",Vector3(x,2.615,-.947),Vector3(x,2.335,.92),.019,"rope")
	# One tabletop collider and the visible uprights are the entire stall obstacle.
	_box("CounterBody",Vector3(width-.18,.12,.72),Vector3(0,.91,.31),"dark_wood",Vector3.ZERO,true)
	for plank: int in 3:_box("CounterPlanks",Vector3(width-.13,.055,.226),Vector3(0,.998,.07+plank*.24),"wood")
	for x: float in [-half+.18,half-.18]:
		for z: float in [.05,.55]:_box("CounterLeg",Vector3(.09,.88,.09),Vector3(x,.44,z),"dark_wood")
	_box("RearShelf",Vector3(width-.32,.055,.23),Vector3(0,.65,-.53),"wood")
	for x: float in [-half+.18,half-.18]:_beam("RearShelfBracket",Vector3(x,.41,-.68),Vector3(x,.63,-.42),.06,"wood")
	match variant:
		0:
			# Wooden scoops and grain trays: no loose object receives its own collider.
			_tray(Vector3(-.54,1.027,.30),Vector2(.69,.43),"grain")
			_tray(Vector3(.32,1.027,.30),Vector2(.62,.43),"grain")
			_box("MeasureCup",Vector3(.20,.18,.18),Vector3(.85,1.116,.28),"wood")
			_beam("ScoopHandle",Vector3(.60,1.12,.36),Vector3(.79,1.13,.60),.035,"wood")
		1:
			_tray(Vector3(-.56,1.027,.32),Vector2(.66,.46),"apple")
			_tray(Vector3(.29,1.027,.32),Vector2(.66,.46),"pear")
			_cylinder("ClayMeasure",Vector3(.94,1.12,.23),.09,.19,"clay",.11)
		2:
			_tray(Vector3(-.53,1.027,.29),Vector2(.74,.43),"vegetable")
			for x: float in [.18,.48,.78]:
				_cylinder("HarvestPot",Vector3(x,1.13,.29),.11,.20,"clay",.14)
				_cylinder("PotRim",Vector3(x,1.24,.29),.148,.033,"clay",.148)
				_cylinder("PotInterior",Vector3(x,1.254,.29),.119,.006,"dark",.119)

func _tray(at: Vector3,size: Vector2,produce: String) -> void:
	_box("TrayFloor",Vector3(size.x,.035,size.y),at+Vector3(0,.0175,0),"wood")
	for x: float in [-size.x*.5,size.x*.5]:_box("TrayEnd",Vector3(.035,.095,size.y),at+Vector3(x,.060,0),"wood")
	for z: float in [-size.y*.5,size.y*.5]:_box("TraySide",Vector3(size.x+.035,.095,.035),at+Vector3(0,.060,z),"wood")
	if produce=="grain":
		_box("GrainFill",Vector3(size.x-.06,.035,size.y-.06),at+Vector3(0,.068,0),"grain")
		for i: int in 6:_cylinder("GrainRidges",at+Vector3(-size.x*.32+i*size.x*.128,.092,0),.027,size.y*.64,"grain",.027,Vector3(PI*.5,0,.07))
	else:
		for row: int in 2:
			for col: int in 4:
				var p: Vector3=at+Vector3((col-1.5)*size.x*.22,.104,(row-.5)*size.y*.42)
				if produce=="vegetable":
					_cylinder("Greens",p,.07,.11,"vegetable",.10)
					_cylinder("GreensTop",p+Vector3(0,.07,0),.10,.075,"leaf_light",.03)
				else:
					_cylinder("FruitLower",p,.044,.065,produce,.073)
					_cylinder("FruitUpper",p+Vector3(0,.055,0),.073,.059 if produce=="apple" else .084,produce,.022 if produce=="pear" else .038)
					_beam("Stem",p+Vector3(0,.084,0),p+Vector3(.01,.124,0),.012,"bark")

func _bench(variant: int) -> void:
	var width: float=1.66+.18*variant
	for z: float in [-.13,.13]:_box("SeatPlanks",Vector3(width,.085,.24),Vector3(0,.47,z),"wood")
	for x: float in [-width*.34,width*.34]:
		_box("SeatBearer",Vector3(.15,.105,.55),Vector3(x,.385,0),"dark_wood")
		for side: float in [-1.,1.]:_beam("SplayedLeg",Vector3(x,.05,side*.25),Vector3(x,.405,side*.17),.11,"dark_wood")
	_beam("BenchStretcher",Vector3(-width*.34,.22,0),Vector3(width*.34,.22,0),.082,"wood")
	if variant==1:
		for x: float in [-width*.36,width*.36]:_beam("BackUpright",Vector3(x,.22,-.20),Vector3(x,1.02,-.31),.074,"dark_wood")
		_box("BackRest",Vector3(width-.11,.21,.065),Vector3(0,.87,-.28),"wood",Vector3(-.14,0,0))

func _sign(variant: int) -> void:
	_box("SignPost",Vector3(.135,1.92,.15),Vector3(0,.96,0),"dark_wood")
	_cylinder("PostCap",Vector3(0,1.97,0),.104,.11,"wood",.015)
	for row: int in 2:
		var side: float=1.0 if (row+variant)%2==0 else -1.0
		var y: float=1.38+row*.31
		_box("DirectionBoard",Vector3(.87,.195,.052),Vector3(side*.23,y,.107),"wood",Vector3(0,0,side*.025))
		_box("ArrowTip",Vector3(.139,.139,.050),Vector3(side*.67,y,.108),"wood",Vector3(0,0,PI*.25))
		for x: float in [-.035,.035]:_cylinder("Nail",Vector3(x,y,.145),.012,.015,"iron",.012,Vector3(PI*.5,0,0))
	# No invented names or text: sign faces remain available for later art/content.

func _sluice() -> void:
	# Water crosses along Z below the raised shutter; there is no floor or dam box.
	for x: float in [-.90,.90]:
		_box("SluiceFoot",Vector3(.32,.19,.49),Vector3(x,.095,0),"stone",Vector3.ZERO,true)
		_box("GuidePost",Vector3(.17,1.92,.23),Vector3(x,1.15,0),"dark_wood",Vector3.ZERO,true)
		for z: float in [-.165,.165]:_box("SlidingGuide",Vector3(.085,1.53,.05),Vector3(x-signf(x)*.098,1.09,z),"wood")
		_box("IronPostBand",Vector3(.195,.074,.255),Vector3(x,1.88,0),"iron")
	_box("SluiceHeader",Vector3(2.10,.18,.24),Vector3(0,2.05,0),"dark_wood")
	for i: int in 8:_box("RaisedShutterBoards",Vector3(.195,.69,.14),Vector3(-.70+i*.20,1.45,0),"wood")
	for y: float in [1.16,1.72]:_box("ShutterBrace",Vector3(1.62,.09,.05),Vector3(0,y,.099),"dark_wood")
	_cylinder("Windlass",Vector3(0,2.19,0),.065,2.14,"wood",.065,Vector3(0,0,PI*.5))
	for x: float in [-.40,.40]:
		_beam("LiftingRope",Vector3(x,1.76,.06),Vector3(x,2.21,.06),.024,"rope")
		for offset: float in [-.036,0.,.036]:_cylinder("RopeCoils",Vector3(x+offset,2.19,0),.078,.021,"rope",.078,Vector3(0,0,PI*.5))
	_beam("WinderArm",Vector3(1.13,2.19,0),Vector3(1.13,1.92,0),.047,"iron")
	_beam("WinderHandle",Vector3(1.13,1.92,0),Vector3(1.32,1.92,0),.062,"wood")
