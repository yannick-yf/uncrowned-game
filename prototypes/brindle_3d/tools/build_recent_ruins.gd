extends SceneTree
## Offline assembly of six recent-collapse variants from the existing house meshes.
## Keeps the source library intact. Generated ruins use hollow walls and real collisions.
const LIB := "res://prototype_3d/assets/library/houses/"
const OUT := "res://assets/brindle_ruins/"
const VARIANTS := [
	["MaisonDuHaut", "cottage_village", 2101],
	["MaisonDuChemin", "cottage_village", 2102],
	["MaisonDesBouleaux", "cottage_village", 2103],
	["MaisonBasse", "cottage_fisher", 2104],
	["MaisonDuSud", "cottage_fisher", 2105],
	["Grange", "storehouse", 2106]
]
var rng := RandomNumberGenerator.new()
var batches: Dictionary
var profiles: Dictionary
var ruin: Node3D
var width: float
var depth: float
var eave: float
var rise: float
var floor_y: float
var retained_side: float
var kind: String
var building: String
var recipe: Dictionary
var roof_slope: float
var roof_intercept: float
var roof_shift: float
var materials: Dictionary = {}
var report: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	for label: String in ["wood", "rock", "plaster", "roof", "dark", "iron"]:
		materials[label] = load("res://prototype_3d/materials/styled_" + label + ".tres")
	materials["roof_rust"] = load("res://prototype_3d/materials/library_roof_rust.tres")
	var fresh: ShaderMaterial = materials.plaster.duplicate()
	fresh.set_shader_parameter("tint", Color("a89b80"))
	fresh.set_shader_parameter("texture_strength", .42)
	fresh.set_shader_parameter("moss_amount", 0.0)
	assert(ResourceSaver.save(fresh, OUT + "cassure_enduit.tres") == OK)
	materials["fresh"] = load(OUT + "cassure_enduit.tres")
	for data: Array in VARIANTS:
		build_variant(data)
	var file := FileAccess.open("res://planning/ruines-brindle.json", FileAccess.WRITE)
	var fire_present:bool=ResourceLoader.exists("res://scripts/burned_ruin_look.gd")
	file.store_string(JSON.stringify({"state":"incendie_recent" if fire_present else "effondrement_recent", "source_assets_preserved":true,
		"smoke_houses":["MaisonDuChemin","MaisonBasse"] if fire_present else [],
		"scorch_mask":"res://assets/landscape/brindle_scorch_mask.png" if fire_present else "", "variants":report}, "  "))
	file.close()
	print("RECENT_RUINS_BUILD_OK variants=", report.size())
	quit()

func build_variant(data: Array) -> void:
	rng.seed = int(data[2]); kind = data[1]; building = data[0]
	recipe = _recipe(building)
	width = 4.3 if kind == "cottage_village" else (6.0 if kind == "storehouse" else 4.5)
	depth = 3.6 if kind == "storehouse" else 3.8
	eave = 2.975 if kind == "cottage_village" else 2.55
	rise = 1.75 if kind == "storehouse" else 1.65
	floor_y = .35 if kind == "cottage_village" else .30
	retained_side = float(recipe.side)
	batches = {}; profiles = {}
	ruin = Node3D.new(); ruin.name = data[0] + "Ruinee"; root.add_child(ruin)
	ruin.set_meta("collapse_design", recipe.description)
	ruin.set_meta("asset_id", kind + "_ruine_" + str(data[2]))
	ruin.set_meta("source_asset", LIB + kind + ".tscn")
	ruin.set_meta("state", "Ruine récente ; effondrement, sans repousse de végétation")
	ruin.set_meta("placement", "Même pivot et même emprise que la maison intacte ; façade +Z")
	var original: Node3D = (load(LIB + kind + ".tscn") as PackedScene).instantiate()
	root.add_child(original)
	var foundation := original.find_child("Foundation", true, false) as MeshInstance3D
	var preserved := foundation.duplicate() as MeshInstance3D
	preserved.name = "FondationOrigine"; ruin.add_child(preserved)
	preserved.transform = original.global_transform.affine_inverse() * foundation.global_transform
	_measure_roof(original)
	_build_walls()
	_reuse_parts(original)
	_add_structure()
	_add_rubble()
	_add_entrance()
	var mesh_count := _flush_batches()
	if ResourceLoader.exists("res://scripts/burned_ruin_look.gd"):
		var fire_look:RefCounted=load("res://scripts/burned_ruin_look.gd").new()
		fire_look.apply(ruin,str(data[0]))
	_own(ruin, ruin)
	var packed := PackedScene.new()
	assert(packed.pack(ruin) == OK)
	var path := OUT + str(data[0]).to_snake_case() + ".tscn"
	assert(ResourceSaver.save(packed, path) == OK)
	report.append({"building":data[0], "intact_asset":LIB+kind+".tscn", "ruined_asset":path,
		"seed":data[2], "batch_meshes":mesh_count, "width_m":width, "depth_m":depth,
		"fire_damage":ResourceLoader.exists("res://scripts/burned_ruin_look.gd"),
		"residual_smoke":ruin.get_node_or_null("FumeeResiduelle")!=null,
		"damage":recipe.description, "chimney_height_m":recipe.chimney,
		"roof_pattern":recipe.roof, "rubble_count":recipe.rubble})
	print("RUIN_SAVED ", path, " batches=", mesh_count)
	original.free(); ruin.free()

func _recipe(id: String) -> Dictionary:
	# Authored destruction patterns. Heights go left-to-right on front/rear,
	# and rear-to-front on the side walls. Randomness only chips their edges.
	match id:
		"MaisonDuHaut": return {
			"description":"Pignon arrière ébréché encore debout, toiture tombée à droite, façade éventrée.",
			"walls":[[2.95,3.4,4.05,3.72,2.6,1.3,.65], [.78,.60,.50,.50,.50,.56,.9], [2.95,2.5,1.8,.9,.6,.5,.78], [.65,.5,.5,.5,.8,1.05,.9]],
			"side":-1, "roof":"gable", "chimney":.62, "rubble":42, "beams":7, "scatter":.13,
			"pile":Vector2(1.30,-.2), "spread":Vector2(.8,1.15), "door":0}
		"MaisonDuChemin": return {
			"description":"Maison presque rasée, soubassements très bas, amas central de poutres et cendres fumantes.",
			"walls":[[.62,.78,.56,.5,.6,.88,.70], [.48,.62,.49,.45,.45,.57,.52], [.62,.55,.78,.62,.46,.52,.48], [.7,.93,.7,.53,.44,.50,.52]],
			"side":1, "roof":"razed", "chimney":.38, "rubble":82, "beams":15, "scatter":.25,
			"pile":Vector2(.05,-.28), "spread":Vector2(1.75,1.35), "door":-1}
		"MaisonDesBouleaux": return {
			"description":"Angle en L préservé, large morceau du versant gauche du toit sur ses chevrons, moitié droite ouverte.",
			"walls":[[2.98,3.30,3.7,3.0,1.3,.7,.53], [2.72,2.18,.60,.5,.5,.62,.55], [2.98,2.97,2.98,2.94,2.84,2.4,2.72], [.53,.67,.51,.46,.7,.58,.55]],
			"side":-1, "roof":"shelter", "chimney":1.48, "rubble":34, "beams":5, "scatter":.10,
			"pile":Vector2(1.25,-.3), "spread":Vector2(.8,1.25), "door":1}
		"MaisonBasse": return {
			"description":"Façade avec une fenêtre vide et un linteau brûlé ; arrière et appentis écroulés vers le jardin.",
			"walls":[[.57,.43,.45,.62,.5,.48,.7], [2.38,2.54,2.32,2.38,2.03,1.65,1.15], [.57,.6,.7,1.15,1.9,2.45,2.38], [.7,.43,.54,.57,.7,.9,1.15]],
			"side":1, "roof":"rear", "chimney":.85, "rubble":53, "beams":8, "scatter":.13,
			"pile":Vector2(.35,-1.48), "spread":Vector2(1.55,.7), "door":2}
		"MaisonDuSud": return {
			"description":"Cheminée haute isolée, murs au ras des fondations, grand pan de mur couché et tuiles dispersées.",
			"walls":[[.55,.48,.62,.77,.64,.5,.42], [.52,.64,.45,.42,.5,.44,.54], [.55,.72,.55,.43,.52,.45,.52], [.42,.44,.52,.45,.47,.5,.54]],
			"side":-1, "roof":"chimney", "chimney":3.35, "rubble":39, "beams":4, "scatter":.10,
			"pile":Vector2(-1.10,-.7), "spread":Vector2(.85,1.35), "door":-1}
		_: return {
			"description":"Grange ouverte : portique arrière et ossature calcinée, bardage arraché, couverture affaissée sur un côté.",
			"walls":[[2.42,2.15,1.3,.62,.60,.70,1.55], [.55,.43,.43,.4,.4,.48,.68], [2.42,1.85,1.4,.92,.72,.52,.55], [1.55,1.30,.65,.55,.62,.72,.68]],
			"side":1, "roof":"frame", "chimney":0.0, "rubble":36, "beams":11, "scatter":.11,
			"pile":Vector2(1.8,-.2), "spread":Vector2(.65,1.5), "door":3}

func _profile_value(heights: Array, t: float) -> float:
	var f: float = t*(heights.size()-1)
	var i: int = mini(int(f),heights.size()-2)
	return lerpf(float(heights[i]),float(heights[i+1]),f-i)

func _build_walls() -> void:
	for side: int in 4:
		var length: float = width if side < 2 else depth
		var samples := PackedVector2Array()
		for i: int in 25:
			var t: float = float(i)/24.0
			var height: float = _profile_value(recipe.walls[side],t)
			# Only the broken lip varies; intact roof bearings stay at the eave.
			if building == "MaisonDesBouleaux" and side == 2 and t < .55: height = eave
			else: height += rng.randf_range(-.095,.08)
			samples.append(Vector2(lerpf(-length*.5,length*.5,t),maxf(height,floor_y+.10)))
		profiles[side] = samples
		var parts: Array[Vector2] = [Vector2(-length*.5,length*.5)]
		if side == 1: parts = [Vector2(-length*.5,-.94),Vector2(.94,length*.5)]
		if building == "MaisonDuHaut" and side == 3: parts = [Vector2(-length*.5,-.80),Vector2(.60,length*.5)]
		if building == "MaisonDuChemin" and side == 2: parts = [Vector2(-length*.5,-.9),Vector2(.75,length*.5)]
		if building == "MaisonDuSud" and side == 3: parts = [Vector2(-length*.5,-1.1),Vector2(1.0,length*.5)]
		if building == "MaisonBasse" and side == 1:
			parts = [Vector2(-length*.5,-1.88),Vector2(-1.16,-.94),Vector2(.94,length*.5)]
		for segment: Vector2 in parts:
			var polygon := PackedVector2Array([Vector2(segment.x,floor_y),Vector2(segment.y,floor_y),Vector2(segment.y,_height_on(side,segment.y))])
			for i: int in range(samples.size()-1,-1,-1):
				if samples[i].x > segment.x and samples[i].x < segment.y: polygon.append(samples[i])
			polygon.append(Vector2(segment.x,_height_on(side,segment.x)))
			var basis := Basis.IDENTITY
			var at := Vector3.ZERO
			if side < 2: at.z = (-1 if side == 0 else 1)*depth*.5
			else:
				basis = Basis(Vector3.UP,PI*.5)
				for i: int in polygon.size(): polygon[i].x *= -1
				at.x = (-1 if side == 2 else 1)*width*.5
			var wall := _wall_mesh(polygon,.25,materials.wood if kind == "storehouse" else materials.plaster)
			var node := MeshInstance3D.new(); node.name = "MurBrise_%d_%d" % [side,ruin.get_child_count()]
			node.mesh = wall; node.transform = Transform3D(basis,at); ruin.add_child(node)
			_collision(node, wall.create_trimesh_shape())

func _height_on(side: int, x: float) -> float:
	var samples: PackedVector2Array = profiles[side]
	for i: int in range(samples.size()-1):
		if x <= samples[i+1].x:
			return lerpf(samples[i].y,samples[i+1].y,clampf((x-samples[i].x)/(samples[i+1].x-samples[i].x),0,1))
	return samples[-1].y

func _wall_mesh(polygon: PackedVector2Array, thickness: float, exterior: Material) -> ArrayMesh:
	var faces := SurfaceTool.new(); faces.begin(Mesh.PRIMITIVE_TRIANGLES)
	var edges := SurfaceTool.new(); edges.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices := Geometry2D.triangulate_polygon(polygon)
	for side: float in [-1.0,1.0]:
		for i: int in range(0,indices.size(),3):
			var vertices: Array[Vector3] = []
			for k: int in 3:
				var p: Vector2 = polygon[indices[i+k]]
				vertices.append(Vector3(p.x,p.y,side*thickness*.5))
			_triangle(faces,vertices[0],vertices[1] if side>0 else vertices[2],vertices[2] if side>0 else vertices[1],Color.WHITE)
	for i: int in polygon.size():
		var a: Vector2 = polygon[i]; var b: Vector2 = polygon[(i+1)%polygon.size()]
		var p := Vector3(a.x,a.y,-thickness*.5); var q := Vector3(b.x,b.y,-thickness*.5)
		var r := Vector3(b.x,b.y,thickness*.5); var s := Vector3(a.x,a.y,thickness*.5)
		_triangle(edges,p,q,r,Color.WHITE); _triangle(edges,p,r,s,Color.WHITE)
	faces.generate_normals(); edges.generate_normals()
	var mesh: ArrayMesh = faces.commit(); mesh.surface_set_material(0,exterior)
	edges.commit(mesh); mesh.surface_set_material(1,materials.fresh if kind != "storehouse" else materials.wood)
	return mesh

func _reuse_parts(original: Node3D) -> void:
	for node: Node in original.find_children("*","MeshInstance3D",true,false):
		if not str(node.name).begins_with("Architecture_"): continue
		var source := node as MeshInstance3D
		var material: Material = source.material_override
		var name: String = str(node.name).trim_prefix("Architecture_")
		if name in ["window","dark","iron","rope"]: continue
		var transform: Transform3D = original.global_transform.affine_inverse()*source.global_transform
		for part: Dictionary in _components(source.mesh,transform):
			var bounds: AABB = part.bounds; var center: Vector3 = bounds.get_center()
			var roof_piece: bool = name in ["roof","roof_rust"]
			if roof_piece:
				# Long ridge pieces are beams, not loose individual tiles.
				if bounds.size.length() > 1.35: continue
				if _retained_roof(center):
					_append_part("ToitRestant",material,part,Transform3D(Basis.IDENTITY,Vector3(0,roof_shift,0)))
					_append_part("VoligeSousToit",materials.wood,part,Transform3D(Basis.IDENTITY,Vector3(0,roof_shift-.10,0)))
				elif _in_roof_sheet(center) and rng.randf() > .13:
					_append_part("ToitureEffondree",material,part,_roof_fall(center))
				elif rng.randf() < float(recipe.scatter):
					var p: Vector3 = _debris_point()
					p.y += .085
					var slope: float = atan(roof_slope)
					var rot := Basis.from_euler(Vector3(rng.randf_range(-.12,.12),rng.randf()*TAU,0))
					var flattened := Basis(Vector3.BACK,(-1.0 if center.x<0 else 1.0)*slope)
					var basis: Basis = rot*flattened
					_append_part("TuilesDisloquees",material,part,Transform3D(basis,p-basis*center))
			elif name == "rock" and bounds.end.y < .64:
				_append_part("PierresOrigine",material,part,Transform3D.IDENTITY)
			elif name == "wood" and _supported(bounds):
				_append_part("PansDeBoisOrigine",material,part,Transform3D.IDENTITY)
			elif name == "shutters":
				var target := Vector3(retained_side*(width*.5+.38),.15,rng.randf_range(-.9,.5))
				var rot := Basis.from_euler(Vector3(PI*.5,0,rng.randf_range(-.6,.6)))
				_append_part("VoletsTombes",material,part,Transform3D(rot,target-rot*center))
			elif name == "rock" and center.y > eave and float(recipe.chimney) < 2.0:
				var target := Vector3(width*.28+rng.randf_range(-.45,.55),floor_y+.18,-.9+rng.randf_range(-.45,.45))
				var rot := Basis.from_euler(Vector3(rng.randf_range(-.3,.3),rng.randf()*TAU,rng.randf_range(-.3,.3)))
				_append_part("ChemineeEffondree",material,part,Transform3D(rot,target-rot*center))
			elif name == "wood" and bounds.size.length() < 2.2 and minf(bounds.size.x,minf(bounds.size.y,bounds.size.z)) < .24 and rng.randf() < .15:
				var target := Vector3(rng.randf_range(-width*.42,width*.42),floor_y+.24,rng.randf_range(-depth*.38,depth*.28))
				var rot := Basis.from_euler(Vector3(1.45,rng.randf()*TAU,rng.randf_range(-.2,.2)))
				_append_part("BoisTombes",material,part,Transform3D(rot,target-rot*center))

func _retained_roof(center: Vector3) -> bool:
	if recipe.roof == "shelter": return center.x < -width*.24 and center.z < -.05+sin(center.x*6.0)*.07
	return false

func _measure_roof(original: Node3D) -> void:
	# Fit the actual source tile centers: the village roof was previously raised
	# and has a different pitch from the fisher cottage. This keeps reused panels
	# on their timbers, and lands fallen sheets on the debris instead of in midair.
	var sum_x: float = 0.0; var sum_y: float = 0.0
	var sum_xx: float = 0.0; var sum_xy: float = 0.0; var n: int = 0
	var label: String = "Architecture_roof_rust" if kind == "storehouse" else "Architecture_roof"
	var source: MeshInstance3D = original.find_child(label,true,false)
	for part: Dictionary in _components(source.mesh,source.transform):
		var bounds: AABB = part.bounds; var c: Vector3 = bounds.get_center()
		if bounds.size.length()>1.35 or c.x>-.5: continue
		var x: float = absf(c.x)
		sum_x+=x;sum_y+=c.y;sum_xx+=x*x;sum_xy+=x*c.y;n+=1
	assert(n>5)
	roof_slope=-(n*sum_xy-sum_x*sum_y)/(n*sum_xx-sum_x*sum_x)
	roof_intercept=(sum_y+roof_slope*sum_x)/n
	roof_shift=eave+.16-(roof_intercept-roof_slope*width*.5)

func _roof_bearing(x: float) -> float:
	return roof_intercept-roof_slope*absf(x)+roof_shift-.18

func _in_roof_sheet(center: Vector3) -> bool:
	match str(recipe.roof):
		"gable": return center.x > .6 and center.z < .30 and center.z > -1.5
		"shelter": return center.x > 1.2 and center.z < -.50
		"rear": return center.z < -.9 and center.x < -.3
		"frame": return center.x > 1.0 and absf(center.z) < 1.65
		_: return false

func _roof_fall(center: Vector3) -> Transform3D:
	var side: float = -1.0 if center.x < 0 else 1.0
	var slope: float = atan(roof_slope)
	var pivot := Vector3(side*width*.32,roof_intercept-roof_slope*width*.32,-.60)
	var target := Vector3(float(recipe.pile.x),floor_y+.25,float(recipe.pile.y))
	var tilt: float = -.13 if recipe.roof == "frame" else .12
	var rotation := Basis.from_euler(Vector3(.03, .10 if recipe.roof == "rear" else -.13,side*slope+tilt))
	if recipe.roof == "rear": target.z = -1.6
	return Transform3D(rotation,target-rotation*pivot)

func _debris_point() -> Vector3:
	# A dominant collapse direction replaces the old uniform ring of debris.
	var at: Vector2 = recipe.pile
	var spread: Vector2 = recipe.spread
	var p := Vector3(at.x+rng.randf_range(-spread.x,spread.x),0,at.y+rng.randf_range(-spread.y,spread.y))
	p.x = clampf(p.x,-width*.5-.60,width*.5+.60)
	p.z = clampf(p.z,-depth*.5-.65,depth*.5+.40)
	if p.z > depth*.5-.75 and absf(p.x) < 1.0: p.z = depth*.5-.85
	p.y = floor_y if absf(p.x)<width*.5+.12 and absf(p.z)<depth*.5+.12 else .04
	return p

func _supported(bounds: AABB) -> bool:
	var c: Vector3 = bounds.get_center()
	if bounds.size.x > width*.8 or bounds.size.z > depth*.8: return bounds.end.y < .7 and c.z < depth*.35
	var side: int = 0 if c.z < 0 else 1
	var coord: float = c.x
	if absf(c.x) > width*.43 and absf(c.z) < depth*.48:
		side = 2 if c.x < 0 else 3; coord = c.z
	if side == 1 and absf(c.x) < .78: return false
	return bounds.end.y < _height_on(side,coord)-.03 and (absf(c.x)>width*.40 or absf(c.z)>depth*.40)

func _add_structure() -> void:
	for x: float in [-width*.5,width*.5]:
		for z: float in [-depth*.5,depth*.5]:
			var side: int = 0 if z < 0 else 1
			var top: float = _height_on(side,x)+.04
			_beam("CharpenteDebout",Vector3(x,floor_y,z),Vector3(x,top,z),.19,materials.wood,true)
	match building:
		"MaisonDuHaut":
			_beam("PignonEventre",Vector3(-width*.5,eave,-depth*.5),Vector3(-.72,3.93,-depth*.5),.16,materials.wood,true)
			_beam("PignonEventre",Vector3(-.62,floor_y,-depth*.5),Vector3(-.62,3.9,-depth*.5),.16,materials.wood,true)
			_beam("PignonEventre",Vector3(-width*.5,2.3,-depth*.5),Vector3(.42,2.3,-depth*.5),.17,materials.wood,true)
			_beam("ChevronRompu",Vector3(-width*.5,2.8,-1.25),Vector3(-1.12,3.6,-1.4),.16,materials.wood,true)
		"MaisonDuChemin":
			# One low timber pile, with a split ridge beam across it.
			_beam("FaitiereTombee",Vector3(-1.7,.55,-1.2),Vector3(1.6,.83,.6),.24,materials.wood,true)
			_beam("FaitiereTombee",Vector3(-1.5,.73,.4),Vector3(.7,.6,-1.25),.2,materials.wood,true)
		"MaisonDesBouleaux":
			for z: float in [-1.9,-1.05,-.15]:
				_beam("ChevronsSurMur",Vector3(-width*.5,_roof_bearing(-width*.5),z),Vector3(-.78,_roof_bearing(-.78),z),.17,materials.wood,true)
			_beam("SabliereConservee",Vector3(-width*.5,eave,-1.9),Vector3(-width*.5,eave,.65),.2,materials.wood,true)
			_beam("Contreventement",Vector3(-width*.5,1.10,-1.85),Vector3(-width*.5,2.7,-.4),.14,materials.wood,true)
		"MaisonBasse":
			# The surviving empty window is an actual hole, including its sill and lintel.
			_box("AllegeFenetre",Vector3(.72,.77,.25),Vector3(-1.52,.685,depth*.5),materials.plaster,Vector3.ZERO,true)
			_box("DessusFenetre",Vector3(.72,.27,.25),Vector3(-1.52,2.235,depth*.5),materials.plaster,Vector3.ZERO,true)
			for x: float in [-1.90,-1.14]:
				_beam("FenetreVide",Vector3(x,1.05,depth*.5+.05),Vector3(x,2.14,depth*.5+.05),.11,materials.wood,true)
			_box("FenetreVide",Vector3(.86,.11,.30),Vector3(-1.52,1.06,depth*.5+.05),materials.wood,Vector3.ZERO,true)
			_box("LinteauBrule",Vector3(2.03,.17,.25),Vector3(-.06,2.26,depth*.5),materials.wood,Vector3(0,0,-.04),true)
			for i: int in 7:
				_box("AppentisAffaisse",Vector3(.22,.10,1.22),Vector3(-.3+i*.25,.14+i*.013,-2.55),materials.wood,Vector3(.10,.20,-.02),false)
			_beam("AppentisAffaisse",Vector3(-.4,.13,-3.02),Vector3(1.7,.34,-2.65),.17,materials.wood,true)
		"MaisonDuSud":
			_fallen_wall()
		"Grange":
			# Two different remnants of timber bents, anchored on the old foundation.
			for x: float in [-width*.5,width*.5]:
				_beam("PortiqueGrange",Vector3(x,floor_y,-1.5),Vector3(x,eave,-1.5),.23,materials.wood,true)
			_beam("PortiqueGrange",Vector3(-width*.5,eave,-1.5),Vector3(width*.5,eave,-1.5),.21,materials.wood,true)
			_beam("PortiqueGrange",Vector3(-width*.5,eave,-1.5),Vector3(0,eave+rise,-1.5),.2,materials.wood,true)
			_beam("PortiqueGrange",Vector3(0,eave+rise,-1.5),Vector3(width*.5,eave,-1.5),.2,materials.wood,true)
			_beam("PortiqueGrange",Vector3(0,eave,-1.5),Vector3(0,eave+rise,-1.5),.17,materials.wood,true)
			_beam("PortiqueRompu",Vector3(-width*.5,floor_y,.90),Vector3(-width*.5,2.83,.90),.23,materials.wood,true)
			_beam("PortiqueRompu",Vector3(-width*.5,eave,.90),Vector3(-1.52,3.40,.90),.18,materials.wood,true)
			_beam("SabliereGrange",Vector3(-width*.5,eave,-1.5),Vector3(-width*.5,eave,.90),.22,materials.wood,true)
			_beam("LienGrange",Vector3(-width*.5,1.6,.90),Vector3(-width*.5,2.55,-.10),.17,materials.wood,true)
			for i: int in 6:
				_box("BardageArrache",Vector3(.22,1.0+i*.14,.12),Vector3(-width*.5+.13,.82+i*.04,-1.2+i*.23),materials.wood,Vector3(0,PI*.5,.11),false)
	for i: int in int(recipe.beams):
		var a: Vector3 = _debris_point(); a.y += .10
		var b: Vector3 = a+Vector3(rng.randf_range(-1.1,1.1),rng.randf_range(.10,.34),rng.randf_range(-.7,.7))
		b.x = clampf(b.x,-width*.5-.6,width*.5+.6)
		b.z = minf(b.z,depth*.5-.85)
		_beam("PoutresBrisees",a,b,rng.randf_range(.11,.19),materials.wood,i<4)
	_build_chimney()
	_add_door_remains()

func _build_chimney() -> void:
	var height: float = float(recipe.chimney)
	if height <= 0.0: return
	var count: int = ceili(height/.23)
	for i: int in count:
		# Slight offsets and a broken upper lip distinguish masonry from a perfect column.
		var c := Vector3(width*.25+sin(i*2.4)*.012,floor_y+.115+i*.23,-.9)
		if i >= count-2 and height>2.0:
			_box("ChemineeIsolee",Vector3(.66,.23,.20),c+Vector3(0,0,-.23),materials.rock,Vector3.ZERO,true)
			_box("ChemineeIsolee",Vector3(.19,.23,.48),c+Vector3(-.235,0,.07),materials.rock,Vector3.ZERO,true)
			if i == count-2: _box("ChemineeIsolee",Vector3(.19,.23,.48),c+Vector3(.235,0,.07),materials.rock,Vector3.ZERO,true)
		else: _box("ChemineeIsolee" if height>2 else "BaseCheminee",Vector3(.66,.23,.67),c,materials.rock,Vector3.ZERO,true)
	if height>2:
		_box("SocleCheminee",Vector3(.92,.25,.91),Vector3(width*.25,floor_y+.125,-.9),materials.rock,Vector3.ZERO,true)

func _fallen_wall() -> void:
	var polygon := PackedVector2Array([Vector2(-1.0,0),Vector2(1.0,0),Vector2(.90,.72),Vector2(.38,1.12),Vector2(.12,1.02),Vector2(-.38,1.32),Vector2(-1.0,.84)])
	var mesh := _wall_mesh(polygon,.24,materials.plaster)
	var node := MeshInstance3D.new(); node.name="PanDeMurCouche"; node.mesh=mesh
	# Fell outward beside the house, leaving the original entrance clear.
	node.transform=Transform3D(Basis.from_euler(Vector3(-PI*.5,.27,0)),Vector3(-.65,.23,-depth*.5-.12))
	ruin.add_child(node);_collision(node,mesh.create_trimesh_shape())
	_beam("ColombageAuSol",Vector3(-1.6,.39,-2.1),Vector3(.30,.39,-2.61),.16,materials.wood,true)

func _add_door_remains() -> void:
	var style: int = int(recipe.door)
	if style < 0: return
	var center := Vector3(-1.55,.12,depth*.5+.48)
	var rotation := Vector3(0,-.35,0)
	var count: int = 5
	if style == 1:
		center=Vector3(-width*.5-.35,.75,.95); rotation=Vector3(1.05,PI*.5,.12); count=3
	elif style == 2:
		center=Vector3(1.55,.10,depth*.5+.32); rotation=Vector3(.06,.85,.05); count=2
	elif style == 3:
		center=Vector3(-1.55,.16,.75); rotation=Vector3(.13,-.17,0); count=8
	var basis := Basis.from_euler(rotation)
	for i: int in count:
		var at: Vector3 = center+basis*Vector3((i-(count-1)*.5)*.16,0,0)
		_box("PorteArrachee",Vector3(.145,.065,1.55 if style!=2 else .72),at,materials.wood,rotation,false)
	if style in [0,3]:
		for z: float in [-.55,.55]:
			_box("PorteArrachee",Vector3(count*.16,.03,.07),center+basis*Vector3(0,.05,z),materials.iron,rotation,false)

func _add_rubble() -> void:
	for i: int in int(recipe.rubble):
		var p: Vector3 = _debris_point()
		# A few chips still mark the fractured wall bases, away from the main pile.
		if i%4 == 0:
			p = Vector3(rng.randf_range(-width*.55,width*.55),.04,-depth*.5+rng.randf_range(-.4,.25))
			if absf(p.x)<width*.5 and absf(p.z)<depth*.5: p.y=floor_y
		var size := Vector3(rng.randf_range(.14,.46),rng.randf_range(.09,.28),rng.randf_range(.15,.44))
		p.y += size.y*.5
		var mat: Material = materials.wood if kind=="storehouse" else (materials.fresh if i%3 else materials.rock)
		_shard("GravatsFrais",p,size,mat,i%13==0)
	for i: int in (23 if recipe.roof=="razed" else 9):
		var p: Vector3 = _debris_point(); p.y += .10
		_shard("TuilesEparses",p,Vector3(.27,.06,.32),materials.roof_rust if kind=="storehouse" else materials.roof,false)

func _add_entrance() -> void:
	# Sloped rubble apron over the original 30–35 cm foundation lip.
	var t := SurfaceTool.new(); t.begin(Mesh.PRIMITIVE_TRIANGLES)
	var z0: float = depth*.5+.30; var z1: float = depth*.5+1.22
	_triangle(t,Vector3(-.86,floor_y+.025,z0),Vector3(.86,floor_y+.025,z0),Vector3(.86,.015,z1),Color.WHITE)
	_triangle(t,Vector3(-.86,floor_y+.025,z0),Vector3(.86,.015,z1),Vector3(-.86,.015,z1),Color.WHITE)
	var zi: float = depth*.5-.42
	_triangle(t,Vector3(-.86,floor_y+.025,zi),Vector3(.86,floor_y+.025,zi),Vector3(.86,floor_y+.025,z0),Color.WHITE)
	_triangle(t,Vector3(-.86,floor_y+.025,zi),Vector3(.86,floor_y+.025,z0),Vector3(-.86,floor_y+.025,z0),Color.WHITE)
	t.generate_normals()
	var ramp := MeshInstance3D.new(); ramp.name = "SeuilDegage"; ramp.mesh = t.commit(); ramp.material_override = materials.rock; ruin.add_child(ramp)
	_collision(ramp,ramp.mesh.create_trimesh_shape())

func _components(mesh: Mesh, transform: Transform3D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for s: int in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(s)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR]!=null else PackedColorArray()
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		if indices.is_empty():
			for i: int in vertices.size(): indices.append(i)
		var count: int = indices.size()/3
		var parents := PackedInt32Array(); parents.resize(count)
		for i: int in count: parents[i] = i
		var seen: Dictionary = {}
		for i: int in count:
			for k: int in 3:
				var p: Vector3 = vertices[indices[i*3+k]]
				var key := Vector3i((p*10000.0).round())
				if seen.has(key): parents[_find(parents,i)] = _find(parents,int(seen[key]))
				else: seen[key] = i
		var groups: Dictionary = {}
		for i: int in count:
			var id: int = _find(parents,i)
			if not groups.has(id): groups[id] = {"vertices":PackedVector3Array(),"colors":PackedColorArray()}
			for k: int in 3:
				var index: int = indices[i*3+k]
				groups[id].vertices.append(transform*vertices[index])
				groups[id].colors.append(colors[index] if not colors.is_empty() else Color.WHITE)
		for part: Dictionary in groups.values():
			var bounds := AABB(part.vertices[0],Vector3.ZERO)
			for p: Vector3 in part.vertices: bounds = bounds.expand(p)
			part["bounds"] = bounds; result.append(part)
	return result

func _find(parents: PackedInt32Array, at: int) -> int:
	while parents[at] != at: at = parents[at]
	return at

func _batch(group: String, material: Material) -> SurfaceTool:
	var key: String = group+"|"+material.resource_path
	if not batches.has(key):
		var tool := SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches[key] = {"group":group,"material":material,"tool":tool}
	return batches[key].tool

func _append_part(group: String, material: Material, part: Dictionary, transform: Transform3D) -> void:
	if group == "ToitureEffondree":
		var bounds := AABB(transform*part.vertices[0],Vector3.ZERO)
		for vertex: Vector3 in part.vertices: bounds = bounds.expand(transform*vertex)
		# Keep low roofing away from the opening, including clearance for the player's head.
		if bounds.position.x < .95 and bounds.end.x > -.95 and bounds.end.z > depth*.5-.8:
			transform.origin.z -= bounds.end.z-(depth*.5-.8)
	var tool := _batch(group,material)
	for i: int in part.vertices.size():
		tool.set_color(part.colors[i]); tool.add_vertex(transform*part.vertices[i])

func _triangle(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,color: Color) -> void:
	for p: Vector3 in [a,b,c]: tool.set_color(color); tool.add_vertex(p)

func _box(group: String,size: Vector3,at: Vector3,material: Material,rotation: Vector3,collide: bool) -> void:
	var box := BoxMesh.new(); box.size = size
	var transform := Transform3D(Basis.from_euler(rotation),at)
	for part: Dictionary in _components(box,Transform3D.IDENTITY): _append_part(group,material,part,transform)
	if collide:
		var body := StaticBody3D.new(); body.name = group+"Collision"; body.transform = transform; body.collision_mask = 0; ruin.add_child(body)
		var shape := CollisionShape3D.new(); var box_shape := BoxShape3D.new(); box_shape.size = size; shape.shape = box_shape; body.add_child(shape)

func _beam(group: String,a: Vector3,b: Vector3,thickness: float,material: Material,collide: bool) -> void:
	var direction: Vector3 = b-a
	var axis: Vector3 = direction.normalized()
	var right: Vector3 = axis.cross(Vector3.FORWARD).normalized()
	if right.length_squared()<.1: right = axis.cross(Vector3.RIGHT).normalized()
	var basis := Basis(right,axis,right.cross(axis).normalized())
	_box(group,Vector3(thickness,direction.length(),thickness),(a+b)*.5,material,basis.get_euler(),collide)

func _shard(group: String,p: Vector3,size: Vector3,material: Material,collide: bool) -> void:
	var pts := PackedVector2Array([Vector2(-.5,-.32),Vector2(.22,-.5),Vector2(.50,.16),Vector2(.12,.47),Vector2(-.4,.25)])
	var tool := _batch(group,material)
	var basis := Basis.from_euler(Vector3(rng.randf_range(-.2,.2),rng.randf()*TAU,rng.randf_range(-.2,.2)))
	var top := PackedVector3Array(); var bottom := PackedVector3Array()
	for point: Vector2 in pts:
		top.append(p+basis*Vector3(point.x*size.x,size.y*.5,point.y*size.z))
		bottom.append(p+basis*Vector3(point.x*size.x,-size.y*.5,point.y*size.z))
	for i: int in range(1,pts.size()-1):
		_triangle(tool,top[0],top[i+1],top[i],Color.WHITE)
		_triangle(tool,bottom[0],bottom[i],bottom[i+1],Color(.85,.85,.85))
	for i: int in pts.size():
		var next: int = (i+1)%pts.size()
		_triangle(tool,top[i],top[next],bottom[next],Color(.9,.9,.9))
		_triangle(tool,top[i],bottom[next],bottom[i],Color(.9,.9,.9))
	if collide:
		var body := StaticBody3D.new(); body.name="GravatCollision"; body.collision_mask=0; ruin.add_child(body)
		var shape := CollisionShape3D.new(); var convex := ConvexPolygonShape3D.new(); var all := top; all.append_array(bottom); convex.points=all; shape.shape=convex; body.add_child(shape)

func _flush_batches() -> int:
	var count: int = 0
	for batch: Dictionary in batches.values():
		var tool: SurfaceTool = batch.tool; tool.generate_normals()
		var node := MeshInstance3D.new(); node.name = batch.group+"_%02d"%count
		node.mesh = tool.commit(); node.material_override = batch.material; ruin.add_child(node)
		if batch.group in ["ToitRestant","ToitureEffondree","ChemineeEffondree"]:
			_collision(node,node.mesh.create_trimesh_shape())
		count += 1
	return count

func _collision(node: Node3D, shape: Shape3D) -> void:
	var body := StaticBody3D.new(); body.name="Collision"; body.collision_mask=0; node.add_child(body)
	var child := CollisionShape3D.new(); child.shape=shape; body.add_child(child)

func _own(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children(): child.owner=owner_node; _own(child,owner_node)
