extends RefCounted
## Native, reusable geometry inspired by the user's September 16 village image.
## Warm lime infill, dark framing, limestone bases and steep tiled/slate roofs.
## No source photograph is baked into materials; dimensions remain in meters.
var b: Variant

func _init(builder: Variant) -> void:
	b=builder

func roof_material() -> String:
	return "rust_roof" if b.item_id in ["logis_porte_basse","baraquement_des_equipes","baraque_jumelee_de_la_cour","maison_des_charretiers","logis_du_contremaitre_en_l","cuisine_commune","grenier_vivres","halle_tri_minerai","reserve_barres_longue","bureau_pesee","remise_des_betes_de_trait","scierie_hydraulique","atelier_charpentier","atelier_charron","halle_sechage","bureau_bois","depot_grumes"] else "roof"

func rise_for(width: float, rise: float) -> float:
	return maxf(rise,width*.59)

func walls(at: Vector3,width: float,depth: float,height: float,boarding: bool=false) -> void:
	b._box("Foundation",Vector3(width+.22,.22,depth+.22),at+Vector3(0,.11,0),"stone",Vector3.ZERO,true)
	b._box("SolidWalls",Vector3(width,height-.22,depth),at+Vector3(0,(height+.22)*.5,0),"mortar",Vector3.ZERO,true)
	var base: float=.68 if height<3.3 else 1.00
	for side: float in [-1.0,1.0]:
		face(at+Vector3(0,0,side*depth*.5),width,height,base,0 if side>0 else PI,boarding,false)
		face(at+Vector3(side*width*.5,0,0),depth,height,base,side*PI*.5,boarding,true)
	# Paired corbels emphasize the upper storey without widening the footprint.
	if height>3.3:
		for side: float in [-1.0,1.0]:
			for x: float in [-width*.38,0.0,width*.38]:
				b._beam("UpperStoreyCorbels",at+Vector3(x,2.13,side*(depth*.5+.035)),at+Vector3(x,2.38,side*(depth*.5+.17)),.105,"dark_wood")

func face(at: Vector3,width: float,height: float,base: float,yaw: float,boarding: bool,side_windows: bool) -> void:
	var saved: Transform3D=b.model_transform
	b.model_transform=saved*Transform3D(Basis(Vector3.UP,yaw),at)
	b._masonry_face(Vector3(0,0,.02),width,base)
	if boarding:b._boarding(Vector3(0,base,.015),width,height-base)
	else:
		b._box("LimeInfill",Vector3(width,height-base,.095),Vector3(0,(height+base)*.5,.015),"pale_plaster" if abs(b.item_id.hash())%3!=0 else "plaster")
	var floors: Array[float]=[base,height]
	if height>3.3:floors=[base,2.38,height]
	var bays: int=maxi(2,roundi(width/1.15))
	for y: float in floors:
		b._beam("WallRails",Vector3(-width*.5,y,.10),Vector3(width*.5,y,.10),.15,"dark_wood")
	for i: int in bays+1:
		var x: float=-width*.5+width*i/bays
		b._beam("WallStuds",Vector3(x,base,.10),Vector3(x,height,.10),.115,"dark_wood")
	for floor_index: int in floors.size()-1:
		var lo: float=floors[floor_index];var hi: float=floors[floor_index+1]
		# Short corner braces leave the central door/window band unobstructed.
		for side: float in [-1.0,1.0]:
			b._beam("FrameKnees",Vector3(side*(width*.5-.06),hi-.70,.115),Vector3(side*(width*.5-minf(.82,width*.28)),hi-.06,.115),.10,"dark_wood")
		if floor_index>0 or side_windows:
			for i: int in bays:
				var x: float=-width*.5+width*(i+.5)/bays
				b._beam("InfillDiagonal",Vector3(x-width/bays*.37,lo+.07,.105),Vector3(x+width/bays*.37,lo+minf(.67,(hi-lo)*.48),.105),.075,"dark_wood")
	if side_windows and width>2.5 and height>2.15 and not boarding:
		for x: float in [-width*.25,width*.25]:window(Vector3(x,1.5,.04),.52,.72)
		if height>3.3:
			for x: float in [-width*.25,width*.25]:window(Vector3(x,(2.38+height)*.5,.04),.52,.68)
	b.model_transform=saved

func window(at: Vector3,width: float=.62,height: float=.82) -> void:
	# Recess is in front of decorative framing, so no brace crosses the opening.
	at+=Vector3(0,0,.205)
	b._box("WindowRecess",Vector3(width+.13,height+.13,.07),at,"dark")
	b._box("DullGlass",Vector3(width-.04,height-.04,.015),at+Vector3(0,0,.042),"glass")
	for x: float in [-width*.5,width*.5]:b._box("OakWindowJamb",Vector3(.075,height+.18,.11),at+Vector3(x,0,.055),"dark_wood")
	for y: float in [-height*.5,height*.5]:b._box("OakWindowRail",Vector3(width+.12,.075,.12),at+Vector3(0,y,.055),"dark_wood")
	b._box("WindowMullion",Vector3(.032,height,.045),at+Vector3(0,0,.082),"wood")
	b._box("WindowTransom",Vector3(width,.032,.045),at+Vector3(0,-.02,.082),"wood")
	b._box("WindowSill",Vector3(width+.28,.08,.23),at+Vector3(0,-height*.5-.05,.08),"wood")
	for side: float in [-1.0,1.0]:
		var x: float=side*(width*.5+.17)
		b._box("OpenShutters",Vector3(.24,height,.055),at+Vector3(x,0,-.015),"wood",Vector3(0,side*.18,0))
		for y: float in [-height*.32,height*.32]:b._box("ShutterIron",Vector3(.24,.035,.027),at+Vector3(x,y,.024),"iron")

func doorway(at: Vector3,width: float,height: float) -> void:
	for side: float in [-1.0,1.0]:b._box("OakDoorJamb",Vector3(.13,height+.10,.14),at+Vector3(side*(width*.5+.12),height*.5,.11),"dark_wood")
	b._box("OakDoorLintel",Vector3(width+.40,.15,.19),at+Vector3(0,height+.12,.11),"dark_wood")

func gable(width: float,depth: float,eave: float,rise: float,offset: float=0.0) -> void:
	var st: SurfaceTool=b._surface("LimeGable","pale_plaster")
	for side: float in [-1.0,1.0]:
		var z: float=side*(depth*.5+.03)
		var a: Vector3=Vector3(-width*.5,eave,z)
		var c: Vector3=Vector3(width*.5,eave,z)
		var top: Vector3=Vector3(offset,eave+rise,z)
		b._tri(st,a,top,c)
		z+=side*.06
		b._beam("GableTie",Vector3(-width*.5,eave,z),Vector3(width*.5,eave,z),.14,"dark_wood")
		b._beam("GableRafter",Vector3(-width*.5,eave,z),Vector3(offset,eave+rise,z),.13,"dark_wood")
		b._beam("GableRafter",Vector3(width*.5,eave,z),Vector3(offset,eave+rise,z),.13,"dark_wood")
		var posts: int=maxi(4,ceili(width/.58))
		for i: int in range(1,posts):
			var x: float=-width*.5+width*i/posts
			var fraction: float=(x+width*.5)/(offset+width*.5) if x<offset else (width*.5-x)/(width*.5-offset)
			b._beam("GableStuds",Vector3(x,eave,z),Vector3(x,eave+rise*fraction-.045,z),.08,"dark_wood")
		if rise>1.55:
			b._beam("AtticRail",Vector3(-width*.26+offset*.48,eave+rise*.48,z),Vector3(width*.26+offset*.48,eave+rise*.48,z),.10,"dark_wood")
			var saved: Transform3D=b.model_transform
			b.model_transform=saved*Transform3D(Basis(Vector3.UP,0 if side>0 else PI),Vector3(offset,eave+rise*.31,side*depth*.5))
			window(Vector3.ZERO,minf(.52,width*.19),minf(.66,rise*.38))
			b.model_transform=saved

func dormer(at: Vector3,wall_width: float,wall_depth: float,eave: float,rise: float,x: float,side: float=1.0) -> void:
	# A roof-side projection with closed cheeks. Roof behind it stays watertight.
	var saved: Transform3D=b.model_transform
	var z: float=side*wall_depth*.32
	b.model_transform=saved*Transform3D(Basis(Vector3.UP,0 if side>0 else PI),at+Vector3(x,eave+rise*.22,z))
	var w: float=.88;var d: float=.80;var h: float=.80;var r: float=.50
	b._box("DormerCheeks",Vector3(w,h,d),Vector3(0,h*.5,0),"plaster")
	for sx: float in [-w*.5,w*.5]:b._beam("DormerPosts",Vector3(sx,0,d*.5+.025),Vector3(sx,h,d*.5+.025),.075,"dark_wood")
	gable(w,d,h,r)
	b._roof(Vector3.ZERO,w,d,h,r,roof_material())
	window(Vector3(0,.4,d*.5),.43,.50)
	b.model_transform=saved

func hall(at: Vector3,width: float,depth: float,eave: float,back: bool) -> void:
	# Reference's long timber halls: transverse ridge and unobstructed cart aisle.
	var rise: float=depth*.57
	for x: float in [-width*.5,width*.5]:
		for z: float in [-depth*.5,0.0,depth*.5]:
			b._box("MasonryPier",Vector3(.52,.70,.52),at+Vector3(x,.35,z),"stone",Vector3.ZERO,true)
			b._beam("HeavyPost",at+Vector3(x,.55,z),at+Vector3(x,eave,z),.25,"dark_wood",true)
			b._beam("KneeBrace",at+Vector3(x,eave-.65,z),at+Vector3(x-signf(x)*.68,eave,z),.15,"dark_wood")
	for z: float in [-depth*.5,depth*.5]:
		b._beam("LongHallPlate",at+Vector3(-width*.5,eave,z),at+Vector3(width*.5,eave,z),.23,"dark_wood")
	for x: float in [-width*.5,0.0,width*.5]:
		b._beam("HallTie",at+Vector3(x,eave,-depth*.5),at+Vector3(x,eave,depth*.5),.19,"dark_wood")
		b._beam("KingPost",at+Vector3(x,eave,0),at+Vector3(x,eave+rise,0),.16,"dark_wood")
		for side: float in [-1.0,1.0]:b._beam("PrincipalRafter",at+Vector3(x,eave,side*depth*.5),at+Vector3(x,eave+rise,0),.18,"dark_wood")
	if back:
		b._box("RearLowWall",Vector3(width,1.0,.28),at+Vector3(0,.50,-depth*.5),"mortar",Vector3.ZERO,true)
		b._masonry_face(at+Vector3(0,0,-depth*.5+.16),width,1.0)
		b._boarding(at+Vector3(0,1.0,-depth*.5),width,eave-1.0)
	var saved: Transform3D=b.model_transform
	b.model_transform=saved*Transform3D(Basis(Vector3.UP,PI*.5),at)
	if b.item_id in ["depot_grumes","halle_sechage"]:
		# Closed loft above the work floor gives the dormer an actual room to light.
		b._box("LoftFloor",Vector3(depth,.13,width),Vector3(0,eave+.025,0),"wood")
		gable(depth,width,eave,rise)
	b._roof(Vector3.ZERO,depth,width,eave,rise,roof_material())
	b.model_transform=saved
	if b.item_id in ["depot_grumes","halle_sechage"]:
		dormer(at,width,depth,eave,rise,width*.23)
	b._marker("Entrance",at+Vector3(0,0,depth*.5+1.0))
