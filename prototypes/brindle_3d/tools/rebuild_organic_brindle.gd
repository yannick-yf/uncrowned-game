extends "res://tools/build_brindle_sectors.gd"
## Current Brindle recipe. Rebuilds only the village, its ground mask and its woods.
const REGION:=Rect2(102,193,145,120)
const PIXELS_PER_METRE:float=8.0
const LAYOUT:Array=[
	["MaisonDuHaut","houses/cottage_village",157,234,125],
	["MaisonDuChemin","houses/cottage_village",170,242,48],
	["MaisonDesBouleaux","houses/cottage_village",193,244,-82],
	["MaisonBasse","houses/cottage_fisher",197,257,-102],
	["MaisonDuSud","houses/cottage_fisher",166,282,-146],
	["Grange","houses/storehouse",143,270,78]
]
var organic_noise:=FastNoiseLite.new()
var mask:Image
var route_curves:Array[Dictionary]=[]
var mask_values:=PackedFloat32Array()
var route_curve_nodes:Array[Path3D]=[]
var forest_cells:Dictionary={}

func build()->void:
	if DisplayServer.get_name()=="headless":push_error("Use Godot's graphics renderer to save vegetation.");quit(1);return
	rng.seed=194621
	organic_noise.seed=44621;organic_noise.frequency=.055
	organic_noise.noise_type=FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_prepare_routes()
	_make_ground_mask()
	world=(load("res://scenes/map_plate.tscn") as PackedScene).instantiate()
	ground=world.get_node("Terrain")
	for old_name:String in ["Brindle","ForetsBrindle"]:
		var old:Node=world.get_node("Decor/"+old_name);old.get_parent().remove_child(old);old.free()
	root.add_child(world)
	for i:int in 6:await process_frame
	var village:=Node3D.new();village.name="Brindle";village.set_script(load("res://scripts/sector_tools.gd"));world.add_child(village)
	_build_village(village)
	var forest:=Node3D.new();forest.name="ForetsBrindle";forest.set_script(load("res://scripts/sector_tools.gd"));world.add_child(forest)
	_build_organic_forest(forest)
	for i:int in 12:await process_frame
	_save_sector(village,"brindle.tscn");_save_sector(forest,"forets_brindle.tscn")
	var before:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://planning/brindle-sectors-v1.json"))
	before["buildings"]=buildings;before["routes"]=routes;before["Brindle_trees"]=trees.size()
	before["tree_count"]=trees.size()+int(before.get("NordEst_trees",295))
	before["revision"]="Brindle organique : implantation, sol intégré, cours et bois recomposés"
	before["ground_mask_bounds"]=[REGION.position.x,REGION.position.y,REGION.size.x,REGION.size.y]
	var file:=FileAccess.open("res://planning/brindle-sectors-v1.json",FileAccess.WRITE);file.store_string(JSON.stringify(before,"  "));file.close()
	var previous_trees:Array=JSON.parse_string(FileAccess.get_file_as_string("res://planning/forest-placements-v1.json"))
	for tree:Dictionary in previous_trees:
		if tree.sector=="NordEst":trees.append(tree)
	file=FileAccess.open("res://planning/forest-placements-v1.json",FileAccess.WRITE);file.store_string(JSON.stringify(trees));file.close()
	print("ORGANIC_BUILD_OK buildings=",buildings.size()," forest=",before.Brindle_trees," mask=",mask.get_size())
	quit()

func _prepare_routes()->void:
	routes=[
		{"id":"chemin_traversant","width":3.05,"strength":1.0,"points":[[147,205],[151,213],[154,222],[161,230],[174,237],[181,244],[182,250],[178,258],[168,264],[159,272],[154,283],[147,294],[140,305]]},
		{"id":"sentier_bois_est","width":1.45,"strength":.87,"points":[[181,244],[186,237],[198,230],[211,226],[225,214],[236,207]]},
		{"id":"acces_MaisonDuHaut","width":1.25,"strength":.91,"points":[[164,231.5],[161.5,231],[159.62,232.17]]},
		{"id":"acces_MaisonDuChemin","width":1.35,"strength":.92,"points":[[179.5,242.7],[178,245],[175.5,245.4],[172.38,244.14]]},
		{"id":"acces_MaisonDesBouleaux","width":1.4,"strength":.93,"points":[[182,247],[186,248.7],[188.5,247],[189.83,244.45]]},
		{"id":"acces_MaisonBasse","width":1.45,"strength":.91,"points":[[181,253],[185.4,254.5],[190,255.4],[193.87,256.33]]},
		{"id":"acces_MaisonDuSud","width":1.3,"strength":.89,"points":[[156.1,278],[159.8,279.6],[162,280],[164.21,279.35]]},
		{"id":"acces_Grange","width":2.25,"strength":.96,"points":[[159,272],[154.2,270.8],[150.7,271.3],[146.13,270.67]]},
		{"id":"puits","width":1.1,"strength":.83,"points":[[180.5,254],[177.2,253.5],[174.5,251.8]]}
	]
	for route:Dictionary in routes:
		var curve:=Curve3D.new();curve.bake_interval=.55
		for i:int in route.points.size():
			var p:Array=route.points[i];var prev:Array=route.points[maxi(0,i-1)];var next:Array=route.points[mini(i+1,route.points.size()-1)]
			var tangent:=Vector3(float(next[0])-float(prev[0]),0,float(next[1])-float(prev[1]))/6.0
			curve.add_point(Vector3(p[0],0,p[1]),-tangent,tangent)
		route_curves.append({"id":route.id,"curve":curve,"points":curve.get_baked_points(),"width":route.width,"strength":route.strength})

func _make_ground_mask()->void:
	var dimensions:=Vector2i(REGION.size*PIXELS_PER_METRE)
	mask_values.resize(dimensions.x*dimensions.y);mask_values.fill(0.0)
	for route:Dictionary in route_curves:
		var length:float=0
		for i:int in range(route.points.size()-1):
			var a3:Vector3=route.points[i];var b3:Vector3=route.points[i+1]
			var a:=Vector2(a3.x,a3.z);var b:=Vector2(b3.x,b3.z)
			length+=a.distance_to(b)
			var radius:float=float(route.width)*.5*(1.+sin(length*.16)*.10+sin(length*.047+1.7)*.13)
			_paint_segment(a,b,radius,float(route.strength),dimensions)
	# Small, separate areas of wear: thresholds, shared yards and the well.
	for patch:Array in [
		[159.7,232.1,2.4,1.6,.83],[173.4,244.4,2.4,2.0,.78],
		[189.6,246.1,2.8,2.2,.82],[193.8,256.2,2.6,2.1,.83],
		[164.0,279.5,2.3,1.9,.76],[147.9,270.1,4.6,3.3,.85],
		[174.2,251.2,2.7,2.1,.75],[139.4,270.6,2.6,3.3,.54]]:
		_paint_patch(Vector2(patch[0],patch[1]),Vector2(patch[2],patch[3]),patch[4],dimensions)
	mask=Image.create(dimensions.x,dimensions.y,false,Image.FORMAT_RGB8)
	for y:int in dimensions.y:
		for x:int in dimensions.x:
			var p:Vector2=REGION.position+(Vector2(x,y)+Vector2.ONE*.5)/PIXELS_PER_METRE
			var texture_noise:float=organic_noise.get_noise_2d(p.x*8,p.y*8)*.5+.5
			var dry:float=smoothstep(-.4,.5,organic_noise.get_noise_2d(p.x*.65,p.y*.65))
			var floor_mix:float=_grove_weight(p)*.65
			mask.set_pixel(x,y,Color(mask_values[y*dimensions.x+x]*(.88+texture_noise*.12),dry,floor_mix,1))
	assert(mask.save_png("res://assets/landscape/brindle_ground_mask.png")==OK)
	print("Organic ground mask generated")

func _paint_segment(a:Vector2,b:Vector2,radius:float,strength:float,dimensions:Vector2i)->void:
	var low:Vector2i=Vector2i(((a.min(b)-Vector2.ONE*(radius+1.1)-REGION.position)*PIXELS_PER_METRE).floor()).max(Vector2i.ZERO)
	var high:Vector2i=Vector2i(((a.max(b)+Vector2.ONE*(radius+1.1)-REGION.position)*PIXELS_PER_METRE).ceil()).min(dimensions-Vector2i.ONE)
	for y:int in range(low.y,high.y+1):
		for x:int in range(low.x,high.x+1):
			var p:Vector2=REGION.position+(Vector2(x,y)+Vector2.ONE*.5)/PIXELS_PER_METRE
			var dist:float=_segment_distance(p,a,b)
			var edge_noise:float=organic_noise.get_noise_2d(p.x*13,p.y*13)*.42+organic_noise.get_noise_2d(p.x*3,p.y*3)*.42
			var coverage:float=(1.-smoothstep(radius*.58,radius+.62,dist+edge_noise))*strength
			var regrowth:float=(1.-smoothstep(.02,.23,dist))*smoothstep(.08,.5,organic_noise.get_noise_2d(p.x*2,p.y*2))*.17
			var index:int=y*dimensions.x+x
			mask_values[index]=maxf(mask_values[index],coverage*(1.-regrowth))

func _paint_patch(center:Vector2,radii:Vector2,strength:float,dimensions:Vector2i)->void:
	var low:=Vector2i(((center-radii*1.45-REGION.position)*PIXELS_PER_METRE).floor()).max(Vector2i.ZERO)
	var high:=Vector2i(((center+radii*1.45-REGION.position)*PIXELS_PER_METRE).ceil()).min(dimensions-Vector2i.ONE)
	for y:int in range(low.y,high.y+1):
		for x:int in range(low.x,high.x+1):
			var p:Vector2=REGION.position+(Vector2(x,y)+Vector2.ONE*.5)/PIXELS_PER_METRE
			var d:float=((p-center)/radii).length()+organic_noise.get_noise_2d(p.x*9,p.y*9)*.25
			var amount:float=(1.-smoothstep(.53,1.25,d))*strength
			var index:int=y*dimensions.x+x;mask_values[index]=maxf(mask_values[index],amount)

func _build_village(parent:Node3D)->void:
	var houses:=_node("Maisons",parent)
	for data:Array in LAYOUT:
		_place(houses,data[1],data[0],Vector2(data[2],data[3]),data[4])
		var building_info:Dictionary={"id":data[0],"asset":data[1],"center_xz":[data[2],data[3]],"yaw":data[4]}
		var ruin_path:String="res://assets/brindle_ruins/"+str(data[0]).to_snake_case()+".tscn"
		if ResourceLoader.exists(ruin_path):
			building_info["state"]="ruine_recente";building_info["ruined_asset"]=ruin_path
		buildings.append(building_info)
	var paths:=_node("TraceDesChemins",parent)
	for route:Dictionary in route_curves:
		var line:=Path3D.new();line.name=route.id;line.curve=route.curve;line.set_meta("width_m",route.width)
		paths.add_child(line)
	var details:=_node("CoursEtJardins",parent)
	for item:Array in [
		["props/well","Puits",174.2,250.6,-12,1],
		["props/bench","BancSousBouleau",172.0,254.1,105,1],
		["props/woodpile","BoisGrange",140,266.2,73,1.2],
		["props/woodpile","BoisMaisonHaut",154,237.3,32,.9],
		["props/crate_single","CaissesGrange",139.1,272,17,1],
		["props/barrel_closed","TonneauCourEst",199.6,259.7,-24,1],
		["rocks/boulder_round","RocheDuTournant",177.1,263.9,62,.8],
		["rocks/boulder_cluster","PierreLisiere",145.5,255.7,-18,.8],
		["props/stump","SoucheJardin",163.8,251.5,25,.8],
		["props/fallen_log","BoisSousFougeres",150.7,264.9,37,.8]]:
		_place(details,item[0],item[1],Vector2(item[2],item[3]),item[4],item[5])
	var fences:=_node("CloturesCourtes",parent)
	for item:Array in [[149.2,236.9,32],[148.0,238.4,49],[147.2,240.2,71],[138.6,263.8,12],[140.6,264.1,5],[142.6,264.2,-4],[200.5,263.5,-12],[202.4,263.0,-22],[203.9,261.7,-58]]:
		_place(fences,"modules/fence_2m","Cloture_%02d"%fences.get_child_count(),Vector2(item[0],item[1]),item[2])
	var accents:=_node("BosquetsDuVillage",parent)
	for item:Array in [["trees/birch_twin",148,250,22,1.13],["trees/birch_twin",144,258,-39,1.03],["trees/pine_coastal",189,270,47,1.18],["trees/birch_twin",169,254.8,-45,.95],["trees/pine_coastal",206.5,251.0,30,1.17],["trees/fir_mature",156,285,29,.92],["trees/birch_twin",180.8,228.5,54,1.12]]:
		_place(accents,item[0],"Arbre_%02d"%accents.get_child_count(),Vector2(item[1],item[2]),item[3],item[4])
	_make_meadows(parent)

func _near_path(p:Vector2,padding:float)->bool:
	for route:Dictionary in route_curves:
		for i:int in range(route.points.size()-1):
			var a:Vector3=route.points[i];var b:Vector3=route.points[i+1]
			if _segment_distance(p,Vector2(a.x,a.z),Vector2(b.x,b.z))<float(route.width)*.5+padding:return true
	return false
func _near_house(p:Vector2,padding:float)->bool:
	for house:Array in LAYOUT:
		var local:Vector2=(p-Vector2(house[2],house[3])).rotated(deg_to_rad(float(house[4])))
		if absf(local.x)<3.65+padding and absf(local.y)<2.8+padding:return true
	return false
func _grove_weight(p:Vector2)->float:
	var field:float=0
	for patch:Array in [[129,210,62,37],[102,259,47,60],[244,266,58,59],[215,210,48,29],[146,253,12,18],[187,273,12,11]]:
		var d:float=_ellipse(p,Vector2(patch[0],patch[1]),Vector2(patch[2],patch[3]))
		field=maxf(field,1.-smoothstep(.35,1.16,d+organic_noise.get_noise_2d(p.x*1.4,p.y*1.4)*.22))
	return field
func _mask_at(p:Vector2)->float:
	var pixel:=Vector2i((p-REGION.position)*PIXELS_PER_METRE)
	if pixel.x<0 or pixel.y<0 or pixel.x>=mask.get_width() or pixel.y>=mask.get_height():return 0
	return mask.get_pixelv(pixel).r

func _make_meadows(parent:Node3D)->void:
	var groups:Dictionary={}
	for attempt:int in 8000:
		var p:=Vector2(rng.randf_range(130,216),rng.randf_range(219,297))
		var n:float=organic_noise.get_noise_2d(p.x*3.5,p.y*3.5)
		if rng.randf()>smoothstep(-.35,.35,n)*.62 or _mask_at(p)>.17 or _near_house(p,.65) or _near_path(p,.3):continue
		var type:int=1
		var woods:float=_grove_weight(p)
		if woods>.36 and rng.randf()<.6:type=0
		elif n>.08 and rng.randf()<.045:type=2
		elif n<-.02 and rng.randf()<.22:type=3
		var key:String="Meadow_%d_%d_%d"%[floori(p.x/32),floori(p.y/32),type]
		if not groups.has(key):groups[key]={"asset":"plants/"+PLANTS[type],"placements":[]}
		var scale_factor:float=rng.randf_range(.52,.98) if type==1 else rng.randf_range(.65,1.05)
		groups[key].placements.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_factor),Vector3(p.x,height_at(p)-.03,p.y)))
	for key:String in groups:_batch_asset(parent,key,groups[key].asset,groups[key].placements)

func _build_organic_forest(parent:Node3D)->void:
	var groups:Dictionary={};var collision_groups:Dictionary={};var kept:int=0
	for attempt:int in 16000:
		var p:=Vector2(rng.randf_range(61,300),rng.randf_range(172,324))
		var weight:float=_grove_weight(p)*(.7+organic_noise.get_noise_2d(p.x*.7,p.y*.7)*.4)
		if rng.randf()>weight*.8 or not _is_dry_gentle(p) or _near_house(p,4.0) or _near_path(p,2.7):continue
		var cell:=Vector2i((p/4.3).floor());var crowded:bool=false
		for dz:int in range(-1,2):
			for dx:int in range(-1,2):
				for other:Vector2 in forest_cells.get(cell+Vector2i(dx,dz),[]):
					if p.distance_to(other)<rng.randf_range(3.5,4.5):crowded=true
		if crowded:continue
		if not forest_cells.has(cell):forest_cells[cell]=[]
		forest_cells[cell].append(p)
		var roll:float=rng.randf();var type:int=0 if roll<.43 else (1 if roll<.69 else (2 if roll<.84 else 3))
		if p.y>283 and rng.randf()<.55:type=2
		var s:float=rng.randf_range(.96,1.43)
		var t:=Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*s),Vector3(p.x,height_at(p)-.03,p.y))
		var key:String="Grove_%d_%d_%d"%[floori(p.x/64),floori(p.y/64),type]
		if not groups.has(key):groups[key]={"asset":"trees/"+TREE_ASSETS[type],"placements":[]}
		groups[key].placements.append(t)
		trees.append({"sector":"Brindle","asset":TREE_ASSETS[type],"xz":[p.x,p.y],"scale":s})
		var collision_key:String="Troncs_%d_%d"%[floori(p.x/64),floori(p.y/64)]
		if not collision_groups.has(collision_key):
			var body:=StaticBody3D.new();body.name=collision_key;body.collision_mask=0;parent.add_child(body);collision_groups[collision_key]=body
		var shape:=CollisionShape3D.new();var cylinder:=CylinderShape3D.new();cylinder.radius=.31*s;cylinder.height=3*s
		shape.shape=cylinder;shape.position=t.origin+Vector3(0,1.5*s,0);shape.set_meta("ground_offset",1.5*s-.03)
		collision_groups[collision_key].add_child(shape)
		kept+=1
		if kept>=650:break
	for key:String in groups:_batch_asset(parent,key,groups[key].asset,groups[key].placements)
	print("Organic woodland trees=",kept)

func _place(parent:Node,asset:String,node_name:String,p:Vector2,yaw:float=0,scale_factor:float=1)->Node3D:
	var ruin_path:String="res://assets/brindle_ruins/"+node_name.to_snake_case()+".tscn"
	if asset.begins_with("houses/") and ResourceLoader.exists(ruin_path):
		var obj:Node3D=(load(ruin_path) as PackedScene).instantiate()
		obj.name=node_name;parent.add_child(obj)
		obj.position=Vector3(p.x,height_at(p)-.03,p.y)
		obj.rotation.y=deg_to_rad(yaw);obj.scale=Vector3.ONE*scale_factor
		obj.set_meta("ground_offset",-.03);obj.set_meta("building_state","ruine_recente")
		return obj
	return super._place(parent,asset,node_name,p,yaw,scale_factor)
