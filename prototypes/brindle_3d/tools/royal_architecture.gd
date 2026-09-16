extends RefCounted
## Low-poly architectural forms with modeled openings, stone trim and roof silhouettes.
var b: Variant
func _init(builder: Variant) -> void:b=builder

func house(spec: Dictionary) -> void:
	var w: float=spec.width;var d: float=spec.depth;var h: float=spec.height;var f: int=int(spec.form)
	if spec.kind=="hall" or spec.kind=="stable":
		b.architecture.hall(Vector3.ZERO,w,d,h,true)
		if spec.kind=="stable":
			for x: float in [-w*.36,0,w*.36]:b._trough(Vector3(x,0,-d*.32),1.6,.8)
		else:
			for x: float in [-w*.33,w*.33]:b._box("MarketCounter",Vector3(2.6,.95,.9),Vector3(x,.48,0),"wood",Vector3.ZERO,true)
		return
	if spec.kind=="chapel":chapel(w,d,h);return
	var roof: String="roof" if f%3==0 else "rust_roof"
	if f%4==0 or spec.kind=="civic" or spec.kind=="guard":stone_house(w,d,h,roof)
	else:
		b.architecture.walls(Vector3.ZERO,w,d,h)
		b.architecture.gable(w,d,h,w*.58)
		b._roof(Vector3.ZERO,w,d,h,w*.58,roof)
		b._door(Vector3(-w*.12,.12,d*.5+.15),1.13,2.12)
		for y: float in [1.7,4.4,7.2]:
			if y+.5>h:continue
			for x: float in [-w*.32,w*.29]:b.architecture.window(Vector3(x,y,d*.5+.02),.68,.96)
	# Distinct massing, not just different colours on the same house.
	if f%6==0:
		var old: Transform3D=b.model_transform
		b.model_transform=Transform3D(Basis(Vector3.UP,PI*.5),Vector3(w*.29,h*.70,-d*.04))
		b._box("CrossGableBody",Vector3(d*.65,1.4,w*.84),Vector3(0,.70,0),"plaster")
		b.architecture.gable(d*.65,w*.84,1.4,d*.35)
		b._roof(Vector3.ZERO,d*.65,w*.84,1.4,d*.35,roof);b.model_transform=old
	elif f%6==1:
		b._box("JettiedUpperBay",Vector3(w*.35,2.5,.6),Vector3(w*.27,h-1.25,d*.5+.21),"pale_plaster")
		b.architecture.window(Vector3(w*.27,h-1.3,d*.5+.56),.80,1.15)
		for x: float in [w*.12,w*.42]:b._beam("BayBrackets",Vector3(x,h-2.85,d*.5),Vector3(x,h-2.40,d*.5+.58),.17,"dark_wood")
	elif f%6==2:
		b.architecture.dormer(Vector3.ZERO,w,d,h,w*.58,-w*.23)
		b.architecture.dormer(Vector3.ZERO,w,d,h,w*.58,w*.25)
	elif f%6==3:
		b._roof(Vector3(w*.28,0,d*.34),w*.43,d*.40,h*.64,w*.27,roof)
		b._box("LowerFrontBay",Vector3(w*.42,h*.63,d*.30),Vector3(w*.28,h*.315,d*.37),"stone",Vector3.ZERO,true)
	elif f%6==4:
		for side: float in [-1.0,1.0]:b._box("SteppedGableCoping",Vector3(.35,1.1,.30),Vector3(side*w*.30,h+w*.25,d*.5+.08),"stone")
	else:
		b.architecture.dormer(Vector3.ZERO,w,d,h,w*.58,w*.05,-1)
	b._chimney(Vector3(w*.29,h*.6,-d*.23),h*.40+w*.30+1.4)
	if spec.kind=="civic":
		tower(Vector3(-w*.28,0,-d*.28),2.0,h+5.0,5.0,false)
		banner(Vector3(w*.33,h-1,d*.5+.35),2.5)
	if spec.kind=="granary":
		b._beam("HoistBeam",Vector3(0,h-1,d*.5),Vector3(0,h-1,d*.5+1.3),.16,"dark_wood")
		b._beam("HoistRope",Vector3(0,h-1,d*.5+1.1),Vector3(0,1.6,d*.5+1.1),.025,"rope")

func stone_house(w: float,d: float,h: float,roof: String) -> void:
	b._box("Foundation",Vector3(w+.25,.24,d+.25),Vector3(0,.12,0),"stone",Vector3.ZERO,true)
	b._box("SolidWalls",Vector3(w,h,d),Vector3(0,h*.5,0),"stone",Vector3.ZERO,true)
	for y: float in [2.8,5.7,h-.25]:b._box("StoneStringCourse",Vector3(w+.15,.15,d+.15),Vector3(0,y,0),"stone")
	stone_gable(w,d,h,w*.58);b._roof(Vector3.ZERO,w,d,h,w*.58,roof)
	b._door(Vector3(-w*.16,.12,d*.5+.1),1.25,2.25)
	for side: float in [-1.0,1.0]:
		for y: float in [1.65,4.55,7.3]:
			if y+.8>h:continue
			for x: float in [-w*.31,w*.26]:window(Vector3(x,y,side*(d*.5+.03)),.78,1.2,0 if side>0 else PI)
		for z: float in [-d*.26,d*.26]:
			for y: float in [2.0,5.2]:
				if y+.7<h:window(Vector3(side*(w*.5+.03),y,z),.74,1.3,side*PI*.5)
	if h>15:
		# Tall royal facades receive full storeys and a carved attic, not a blank scaled house.
		for y: float in [10.5,15.2,20.0,24.0]:
			if y+1.3>=h:continue
			b._box("PalaceCornice",Vector3(w+.22,.23,d+.22),Vector3(0,y-1.9,0),"stone")
			for side: float in [-1.0,1.0]:
				for x: float in [-w*.33,-w*.11,w*.11,w*.33]:window(Vector3(x,y,side*(d*.5+.04)),1.05,2.0,0 if side>0 else PI)
				for z: float in [-d*.31,0,d*.31]:window(Vector3(side*(w*.5+.04),y,z),.95,2.0,side*PI*.5)
		for side: float in [-1.,1.]:
			for x: float in [-w*.13,0,w*.13]:window(Vector3(x,h+w*.18,side*(d*.5+.05)),1.15,2.1,0 if side>0 else PI)
		arch(Vector3(-w*.16,0,d*.5+.3),1.55,2.1,.45,.45)

func stone_gable(w: float,d: float,eave: float,rise: float) -> void:
	var st: SurfaceTool=b._surface("StoneGable","stone")
	for side: float in [-1.,1.]:
		var a: Vector3=Vector3(-w*.5,eave,side*d*.5);var c: Vector3=Vector3(w*.5,eave,side*d*.5);var top: Vector3=Vector3(0,eave+rise,side*d*.5)
		b._tri(st,a,top,c)

func window(at: Vector3,w: float,h: float,yaw: float=0) -> void:
	var saved: Transform3D=b.model_transform;b.model_transform=saved*Transform3D(Basis(Vector3.UP,yaw),at)
	b._box("DeepWindow",Vector3(w,h,.08),Vector3(0,0,.05),"dark")
	for x: float in [-w*.5,w*.5]:b._box("WindowQuoins",Vector3(.15,h+.26,.24),Vector3(x,0,.12),"stone")
	for y: float in [-h*.5,h*.5]:b._box("WindowLintels",Vector3(w+.28,.15,.25),Vector3(0,y,.12),"stone")
	b._box("WindowMullion",Vector3(.065,h,.13),Vector3(0,0,.15),"stone")
	b._box("WindowTransom",Vector3(w,.065,.13),Vector3(0,-h*.13,.15),"stone")
	b.model_transform=saved

func tower(at: Vector3,r: float,h: float,roof_h: float,crenellated: bool=true) -> void:
	var mesh: CylinderMesh=CylinderMesh.new();mesh.bottom_radius=r*1.04;mesh.top_radius=r;mesh.height=h;mesh.radial_segments=28;mesh.rings=1
	b._mesh("RoundTower",mesh,Transform3D(Basis.IDENTITY,at+Vector3(0,h*.5,0)),"stone")
	var shape: CylinderShape3D=CylinderShape3D.new();shape.radius=r;shape.height=h;b._collision("Tower",shape,Transform3D(Basis.IDENTITY,at+Vector3(0,h*.5,0)))
	for y: float in [1.0,h*.54,h-.6]:b._ring("TowerBands",at+Vector3(0,y,0),r*1.08,r*.93,.28,"stone")
	for level: float in [h*.30,h*.64]:
		for i: int in 8:
			var a: float=TAU*i/8.;window(at+Vector3(sin(a)*(r+.02),level,cos(a)*(r+.02)),.38,1.55,a)
	if crenellated:
		for i: int in 14:
			var a: float=TAU*i/14.;b._box("TowerMerlons",Vector3(.68,1.05,.65),at+Vector3(sin(a)*r,h+.35,cos(a)*r),"stone",Vector3(0,a,0))
	if roof_h>0:
		var cone: CylinderMesh=CylinderMesh.new();cone.bottom_radius=r*1.25;cone.top_radius=.06;cone.height=roof_h;cone.radial_segments=28
		b._mesh("ConicalRoof",cone,Transform3D(Basis.IDENTITY,at+Vector3(0,h+roof_h*.5+.9,0)),"rust_roof")
		b._cylinder("RoofFinial",at+Vector3(0,h+roof_h+1.3,0),.09,.9,"gold",.02)

func wall(a: Vector3,c: Vector3,height: float,thickness: float=1.5) -> void:
	var center: Vector3=(a+c)*.5;var length: float=a.distance_to(c);var yaw: float=atan2(c.x-a.x,c.z-a.z)
	b._box("CurtainWall",Vector3(thickness,height,length+.15),center+Vector3(0,height*.5,0),"stone",Vector3(0,yaw,0),true)
	b._box("WallWalk",Vector3(thickness+.55,.30,length+.25),center+Vector3(0,height-.3,0),"stone",Vector3(0,yaw,0))
	var count: int=maxi(1,floori(length/1.7))
	for i: int in count:
		var p: Vector3=a.lerp(c,(i+.5)/count)
		b._box("WallMerlons",Vector3(thickness+.20,1.05,.82),p+Vector3(0,height+.35,0),"stone",Vector3(0,yaw,0))

func arch(at: Vector3,r: float,spring: float,thickness: float,depth: float,rot: Vector3=Vector3.ZERO) -> void:
	var saved: Transform3D=b.model_transform;b.model_transform=saved*Transform3D(Basis.from_euler(rot),at)
	var st: SurfaceTool=b._surface("ArchVoussoirs","stone")
	for i: int in 18:
		var a: float=PI*i/18.;var c: float=PI*(i+1)/18.;var vertices: Array[Vector3]=[]
		for z: float in [-depth*.5,depth*.5]:
			for rad: float in [r,r+thickness]:
				vertices.append(Vector3(cos(a)*rad,spring+sin(a)*rad,z));vertices.append(Vector3(cos(c)*rad,spring+sin(c)*rad,z))
		for q: Array in [[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]]:
			b._tri(st,vertices[q[0]],vertices[q[1]],vertices[q[2]],.9+float(i%3)*.06);b._tri(st,vertices[q[0]],vertices[q[2]],vertices[q[3]],.9+float(i%3)*.06)
	b.model_transform=saved

func gate(opening: float,h: float,r: float) -> void:
	for side: float in [-1.,1.]:tower(Vector3(side*(opening*.5+r),0,0),r,h,6.0)
	var spring: float=3.8;var arch_top: float=spring+opening*.5
	arch(Vector3.ZERO,opening*.5,spring,.65,4.0)
	b._box("GateUpperRoom",Vector3(opening+1.2,h-arch_top-1.0,4),Vector3(0,(h+arch_top)*.5-.5,0),"stone",Vector3.ZERO,true)
	for side: float in [-1.,1.]:b._box("GateInnerJamb",Vector3(.6,spring,4),Vector3(side*(opening*.5+.25),spring*.5,0),"stone",Vector3.ZERO,true)
	for i: int in 9:b._box("RaisedPortcullisBars",Vector3(.10,3.0,.10),Vector3(-opening*.44+i*opening*.11,arch_top+1.7,1.6),"iron")
	for x: float in [-opening*.32,opening*.32]:window(Vector3(x,h-2.2,2.05),.72,1.45)
	b._box("GateCrown",Vector3(opening+1.5,.28,4.6),Vector3(0,h-.10,0),"stone")
	for i: int in 6:b._box("GateCrenels",Vector3(.8,.95,.9),Vector3(-opening*.48+i*opening*.19,h+.4,2),"stone")
	banner(Vector3(-opening*.37,h-3,2.3),2.0);banner(Vector3(opening*.37,h-3,2.3),2.0)
	b._marker("GatePassage",Vector3(0,0,0))

func castle() -> void:
	# Palace and high keep rise from one defensible, walkable rock terrace.
	stone_house(31,23,26,"roof")
	for p: Vector2 in [Vector2(-16,-12),Vector2(16,-12),Vector2(-16,12),Vector2(16,12)]:tower(Vector3(p.x,0,p.y),3.4,32+(2 if p.y<0 else 0),9.5)
	var saved: Transform3D=b.model_transform
	b.model_transform=Transform3D(Basis.IDENTITY,Vector3(-5,0,-15))
	b._box("GreatKeep",Vector3(11.5,51,12),Vector3(0,25.5,0),"stone",Vector3.ZERO,true)
	for y: float in [4.0,13.0,23.0,34.0,44.0]:
		b._box("KeepBands",Vector3(11.9,.3,12.4),Vector3(0,y,0),"stone")
		for x: float in [-3.1,0,3.1]:window(Vector3(x,y+2.4,6.08),.70,2.0)
	stone_gable(11.5,12,51,9);b._roof(Vector3.ZERO,11.5,12,51,9,"roof")
	banner(Vector3(0,61.2,0),3.5,true)
	b.model_transform=saved
	# Lower residential/service wing gives the keep an asymmetric castle silhouette.
	b.model_transform=Transform3D(Basis(Vector3.UP,PI*.5),Vector3(-25,0,2));stone_house(17,10,17,"rust_roof");b.model_transform=saved
	var points: Array[Vector3]=[Vector3(-36,0,29),Vector3(-42,0,4),Vector3(-38,0,-26),Vector3(-22,0,-35),Vector3(24,0,-35),Vector3(41,0,-14),Vector3(39,0,13),Vector3(34,0,29)]
	for i: int in points.size()-1:wall(points[i],points[i+1],10.5,2.0)
	wall(Vector3(-36,0,29),Vector3(6,0,29),10.5,2.0);wall(Vector3(16,0,29),Vector3(34,0,29),10.5,2.0)
	for i: int in points.size():tower(points[i],3.2+float(i%3)*.22,14.0+float(i%3)*1.6,6.3+float(i%2))
	# Footings below the visible curtain follow the rock even beside the cut switchbacks.
	for i: int in points.size()-1:wall(points[i]-Vector3(0,14,0),points[i+1]-Vector3(0,14,0),14.0,1.9)
	wall(Vector3(-36,-14,29),Vector3(6,-14,29),14,1.9);wall(Vector3(16,-14,29),Vector3(34,-14,29),14,1.9)
	for p: Vector3 in points:b._cylinder("CastleTowerFoot",p-Vector3(0,7,0),3.25,14,"stone",3.25,Vector3.ZERO,true)
	b.model_transform=Transform3D(Basis.IDENTITY,Vector3(11,0,29));gate(8.0,18.0,3.0);b.model_transform=saved
	for p: Vector3 in [Vector3(-33,23,-18),Vector3(36,22,12)]:banner(p,2.6,true)
	b._marker("CastleGate",Vector3(11,0,29));b._marker("PalaceApproach",Vector3(0,0,15.5))

func chapel(w: float,d: float,h: float) -> void:
	b._box("Nave",Vector3(w,h,d),Vector3(0,h*.5,0),"stone",Vector3.ZERO,true)
	stone_gable(w,d,h,w*.67);b._roof(Vector3.ZERO,w,d,h,w*.67,"roof")
	for side: float in [-1.,1.]:
		for z: float in [-d*.35,0,d*.35]:
			b._box("Buttresses",Vector3(.7,h*.72,1.0),Vector3(side*(w*.5+.24),h*.36,z),"stone",Vector3.ZERO,true)
			window(Vector3(side*(w*.5+.06),h*.56,z+d*.14),.95,3.3,side*PI*.5)
	b._door(Vector3(0,.12,d*.5+.13),2.0,3.1)
	window(Vector3(0,6.1,d*.5+.03),1.9,2.1)
	var saved: Transform3D=b.model_transform;b.model_transform=Transform3D(Basis.IDENTITY,Vector3(-w*.43,0,d*.25))
	b._box("BellTower",Vector3(4.6,19,4.7),Vector3(0,9.5,0),"stone",Vector3.ZERO,true)
	for side: float in [-1.,1.]:window(Vector3(0,16,side*2.4),1.5,3,0 if side>0 else PI)
	var roof: CylinderMesh=CylinderMesh.new();roof.bottom_radius=3.8;roof.top_radius=.02;roof.height=10;roof.radial_segments=4
	b._mesh("BellSpire",roof,Transform3D(Basis(Vector3.UP,PI*.25),Vector3(0,24,0)),"roof")
	b.model_transform=saved

func banner(at: Vector3,size: float,mast: bool=false) -> void:
	if mast:
		b._beam("FlagMast",at,at+Vector3(0,size*1.4,0),.10,"dark_wood")
		b._box("RoyalFlag",Vector3(size,.75*size,.035),at+Vector3(size*.5,size,0),"banner")
	else:
		b._beam("BannerArm",at+Vector3(-size*.3,.2,0),at+Vector3(size*.3,.2,0),.08,"iron")
		b._box("HangingBanner",Vector3(size*.55,size,.045),at-Vector3(0,size*.5,0),"banner")
		b._box("BannerDevice",Vector3(size*.12,size*.40,.014),at+Vector3(0,-size*.42,.034),"gold")

func bridge() -> void:
	var w: float=5.8
	b._box("ContinuousDeck",Vector3(w,.4,18),Vector3(0,-.20,0),"stone",Vector3.ZERO,true)
	for side: float in [-1.,1.]:
		b._box("Parapet",Vector3(.40,1.10,18),Vector3(side*(w*.5+.18),.55,0),"stone",Vector3.ZERO,true)
		for z: float in [-4.5,4.5]:arch(Vector3(side*(w*.5-.1),-4, z),4.0,0,.6,.65,Vector3(0,PI*.5,0))
	for z: float in [-8.65,0,8.65]:
		b._box("BridgePiers",Vector3(w+.35,6.7,.85),Vector3(0,-3.55,z),"stone",Vector3.ZERO,true)
	b._marker("Entry",Vector3(0,0,-9));b._marker("Exit",Vector3(0,0,9))

func fountain() -> void:
	b._cylinder("FountainBase",Vector3(0,.15,0),1.8,.3,"stone")
	b._ring("FountainBasin",Vector3(0,.53,0),1.65,1.40,.8,"stone")
	b._cylinder("FountainWater",Vector3(0,.72,0),1.41,.035,"water")
	b._cylinder("FountainColumn",Vector3(0,1.2,0),.25,2.3,"stone",.17)
	b._ring("UpperBowl",Vector3(0,2.16,0),.64,.49,.32,"stone")
	var shape: CylinderShape3D=CylinderShape3D.new();shape.radius=1.75;shape.height=1.0;b._collision("Basin",shape,Transform3D(Basis.IDENTITY,Vector3(0,.5,0)))

func stall(index: int) -> void:
	var w: float=2.3+index*.17
	b._box("StallCounter",Vector3(w,.85,.85),Vector3(0,.43,0),"wood",Vector3.ZERO,true)
	for x: float in [-w*.5,w*.5]:b._beam("AwningPosts",Vector3(x,0,0),Vector3(x,2.6,0),.11,"dark_wood",true)
	b._box("CanvasAwning",Vector3(w+.4,.06,1.75),Vector3(0,2.55,-.15),"banner" if index%2==0 else "linen",Vector3(.12,0,0))
	if index%2==0:
		for x: float in [-w*.29,w*.26]:b._crate(Vector3(x,.86,0),.55)
	else:b._sacks(Vector3(-.7,.86,-.12))
