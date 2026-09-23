extends RefCounted
## Native, merged geometry for the farming kit: metres, ground pivot, +Z front.
## Fields remain walk-through; only fruit-tree trunks carry a simple collider.
var b: Variant

func _init(builder: Variant) -> void:
	b = builder

func build() -> void:
	_small_crops()
	_fields()
	_harvest()
	_trees()
	_orchards()

func _begin(id: String, family: String, label: String, use_text: String, place_text: String) -> void:
	b._start(id, family, label, use_text, place_text)
	b.item.set_meta("ground_conforming", false)
	b.item.set_meta("walk_through", family != "vergers")
	if family == "vergers":
		b.item.set_meta("canopy_walk_through", true)
		b.item.set_meta("trunk_solid", true)
	b.item.set_meta("geometry_policy", "merged surfaces per material; no per-stalk nodes")

func _small_crops() -> void:
	_begin("rangee_ble_3m", "cultures", "Rangée de blé de 3 mètres", "Module doré pour prolonger les sillons des champs.", "Terrain plat ; aligner les pivots tous les 3 m suivant X.")
	for i: int in 7:
		_wheat(Vector3(-1.3 + i * .43, 0, b.rng.randf_range(-.12, .12)), .94, 3)
	b._marker("RaccordGauche", Vector3(-1.5, 0, 0))
	b._marker("RaccordDroit", Vector3(1.5, 0, 0))
	b._save()
	_begin("touffe_ble", "cultures", "Touffe de blé", "Petite touffe pour les lisières courbes et les trous entre modules.", "Pivot au sol ; varier rotation et échelle entre 0,85 et 1,1.")
	_wheat(Vector3.ZERO, 1.03, 7)
	b._save()
	_begin("rangee_choux_3m", "cultures", "Rangée de choux de 3 mètres", "Six choux aux feuilles épaisses pour le potager.", "Terrain plat ; espacement de plantation de 50 cm.")
	for i: int in 6:
		_cabbage(Vector3(-1.25 + i * .5, 0, b.rng.randf_range(-.04, .04)), b.rng.randf_range(.9, 1.1))
	b._marker("RaccordGauche", Vector3(-1.5, 0, 0))
	b._marker("RaccordDroit", Vector3(1.5, 0, 0))
	b._save()
	_begin("rangee_poireaux_3m", "cultures", "Rangée de poireaux de 3 mètres", "Légumes à feuilles longues, lisibles en vue de jeu.", "Terrain plat ; espacer les rangs de 55 cm.")
	for i: int in 10:
		_leek(Vector3(-1.35 + i * .3, 0, b.rng.randf_range(-.035, .035)), b.rng.randf_range(.85, 1.13))
	b._marker("RaccordGauche", Vector3(-1.5, 0, 0))
	b._marker("RaccordDroit", Vector3(1.5, 0, 0))
	b._save()

func _fields() -> void:
	var wheat_bank: PackedVector2Array = PackedVector2Array([
		Vector2(-4.9, -3.6), Vector2(-2.4, -4.0), Vector2(1.2, -3.85),
		Vector2(4.8, -3.1), Vector2(4.15, -1.35), Vector2(2.95, .2),
		Vector2(3.5, 2.0), Vector2(4.3, 3.3), Vector2(.75, 3.95),
		Vector2(-3.6, 3.4), Vector2(-4.75, 1.8)])
	_begin("champ_ble_rive_concave", "champs", "Champ de blé à rive concave", "Parcelle de blé mûr, ouverte autour d'une courbe de rivière.", "Poser sur une terrasse sèche ; le creux du bord est se tourne vers la rivière.")
	_soil(wheat_bank, true, .8)
	# Closer rows and four substantial stems make ripe wheat read as a crop mass
	# from the game camera. All geometry remains merged and walk-through.
	var wx: float = -4.35
	while wx < 4.5:
		var wz: float = -3.25
		while wz < 3.6:
			var point: Vector2 = Vector2(wx + b.rng.randf_range(-.13, .13), wz + b.rng.randf_range(-.12, .12))
			if _inside_margin(point, wheat_bank, .32):
				_wheat(Vector3(point.x, .075, point.y), b.rng.randf_range(.98, 1.17), 4, true)
			wz += .66
		wx += .68
	b._save()
	var veg_bend: PackedVector2Array = PackedVector2Array([
		Vector2(-4.15, -2.75), Vector2(-1.5, -3.3), Vector2(1.5, -2.9),
		Vector2(3.8, -1.65), Vector2(4.15, .35), Vector2(2.6, 2.45),
		Vector2(.1, 3.1), Vector2(-2.2, 2.8), Vector2(-3.65, 1.1)])
	_begin("champ_legumes_boucle", "champs", "Potager arrondi du méandre", "Choux et poireaux répartis en planches cultivées avec une allée centrale.", "Terrain sec et plat ; allée centrale de 1,2 m, ouverte sur +Z et -Z.")
	_soil(veg_bend, true, .68)
	for xi: int in range(-5, 6):
		var x: float = xi * .66
		if absf(x) < .8:
			continue
		for zi: int in range(-4, 5):
			var point: Vector2 = Vector2(x, zi * .61)
			if _inside_margin(point, veg_bend, .4):
				if x < 0:
					_cabbage(Vector3(point.x, .08, point.y), b.rng.randf_range(.92, 1.1))
				else:
					_leek(Vector3(point.x, .08, point.y), b.rng.randf_range(.9, 1.2))
	b.item.set_meta("central_aisle_width_m", 1.2)
	b._marker("EntreePotager", Vector3(0, .06, 3.1))
	b._marker("SortiePotager", Vector3(0, .06, -3.1))
	b._save()
	var ploughed_edge: PackedVector2Array = PackedVector2Array([
		Vector2(-5.0, -2.8), Vector2(-2.0, -3.5), Vector2(1.6, -3.2),
		Vector2(4.65, -1.9), Vector2(3.75, -.3), Vector2(3.2, 1.2),
		Vector2(2.0, 3.0), Vector2(-1.9, 3.2), Vector2(-4.3, 2.2)])
	_begin("champ_laboure_lisiere", "champs", "Champ labouré de lisière", "Sillons de terre fraîche dans une parcelle organique prête à semer.", "Terrasse plane ; conserver une bande herbeuse entre la parcelle et l'eau.")
	_soil(ploughed_edge, true, .55)
	b._save()
	_begin("parcelle_labouree_rectangulaire", "champs", "Parcelle labourée 4 × 4 m", "Module de remplissage pour agrandir les champs.", "Aligner les raccords ; laisser des passages entre les blocs de cultures.")
	_soil(PackedVector2Array([Vector2(-2, -2), Vector2(2, -2), Vector2(2, 2), Vector2(-2, 2)]), true, .55)
	for p: Vector3 in [Vector3(-2, 0, 0), Vector3(2, 0, 0), Vector3(0, 0, -2), Vector3(0, 0, 2)]:
		b._marker("RaccordParcelle", p)
	b._save()
	var curved_edge: PackedVector2Array = PackedVector2Array([
		Vector2(-3, -1.0), Vector2(-1.5, -.8), Vector2(0, -.1), Vector2(1.5, .35), Vector2(3, .3),
		Vector2(3, 1.65), Vector2(1.5, 1.7), Vector2(0, 1.2), Vector2(-1.5, .55), Vector2(-3, .35)])
	_begin("bordure_courbe_champ", "champs", "Bordure cultivée courbe", "Ruban de terre qui raccorde les parcelles le long des berges.", "Tourner le bord concave vers la rivière ; pas de collision.")
	_soil(curved_edge, false)
	b._marker("RaccordGauche", Vector3(-3, 0, -.3))
	b._marker("RaccordDroit", Vector3(3, 0, 1))
	b._save()
	_begin("sol_cultive_raccord", "champs", "Raccord de terre irrégulier", "Petit sol meuble pour les angles, les abords du puits et les entrées de champs.", "Surface plane ; superposition limitée au bord, hauteur de sol 4 cm.")
	_soil(PackedVector2Array([Vector2(-1.4, -.75), Vector2(-.4, -1.25), Vector2(1.35, -.8), Vector2(1.5, .4), Vector2(.3, 1.05), Vector2(-1.25, .6)]), false)
	b._save()
	var fallow: PackedVector2Array = PackedVector2Array([
		Vector2(-3.2, -2.1), Vector2(-1.2, -2.5), Vector2(1.4, -2.3), Vector2(3.1, -1.2),
		Vector2(2.7, 1.25), Vector2(.65, 2.6), Vector2(-1.7, 2.2), Vector2(-3.0, .8)])
	_begin("jachere_irreguliere", "champs", "Jachère et chaumes irréguliers", "Parcelle récoltée, chaumes courts et herbes clairsemées.", "Terrain plat ; utile entre verger, chemin et champs actifs.")
	_soil(fallow, true, .7)
	for i: int in 115:
		var point: Vector2 = Vector2(b.rng.randf_range(-3, 3), b.rng.randf_range(-2.3, 2.3))
		if _inside_margin(point, fallow, .16):
			var height: float = b.rng.randf_range(.11, .26)
			_cross_blade("Chaumes", Vector3(point.x, .07, point.y), height, .025, "straw")
			if i % 7 == 0:
				_leek(Vector3(point.x, .06, point.y), .32)
	b._save()

func _harvest() -> void:
	_begin("gerbe_ble_liee", "recoltes", "Gerbe de blé liée", "Gerbe verticale resserrée par une corde de chanvre.", "Pivot au sol ; accessoire traversable pour la récolte et les charrettes.")
	_sheaf(Vector3.ZERO, 1.0)
	b._save()
	_begin("faisceau_gerbes", "recoltes", "Faisceau de six gerbes", "Gerbes disposées en petit groupe de séchage après moisson.", "Terrain sec ; laisser le passage aux charrettes.")
	for i: int in 6:
		var a: float = TAU * i / 6.0
		_sheaf(Vector3(cos(a) * .41, 0, sin(a) * .41), b.rng.randf_range(.91, 1.08))
	b._save()

func _trees() -> void:
	var designs: Array[Array] = [
		["pommier_etale", "Pommier à large ramure", "apple", 0],
		["pommier_jeune", "Jeune pommier", "apple", 1],
		["pommier_penche", "Vieux pommier penché", "apple", 2],
		["poirier_fuseau", "Poirier en fuseau", "pear", 3],
		["poirier_ancien", "Poirier à deux cimes", "pear", 4]]
	for design: Array in designs:
		_begin(design[0], "vergers", design[1], "Arbre fruitier aux branches visibles et fruits cueillables visuellement.", "Pivot au pied du tronc ; collider uniquement sur le tronc, couronne traversable.")
		_tree(Vector3.ZERO, design[2], design[3], 1.0)
		b.item.set_meta("walk_through", false)
		b.item.set_meta("collision_policy", "one cylinder per trunk; no canopy collision")
		b.item.set_meta("fruit_species", design[2])
		b._save()

func _orchards() -> void:
	_begin("verger_aligne_6arbres", "vergers", "Verger de six arbres alignés", "Deux rangs de trois fruitiers, avec une large allée pour la récolte.", "Terrain plat ; allée centrale suivant X, 3 m libres entre les couronnes.")
	for row: int in 2:
		for col: int in 3:
			var variant: int = (row + col) % 2
			_tree(Vector3((col - 1) * 5.1, 0, (row * 2 - 1) * 3.15), "apple" if row == 0 else "pear", variant if row == 0 else 3, .83)
	b.item.set_meta("walk_through", false)
	b.item.set_meta("minimum_trunk_spacing_m", 5.1)
	b.item.set_meta("central_aisle_clearance_m", 3.0)
	b._marker("EntreeAllee", Vector3(-7.4, 0, 0))
	b._marker("SortieAllee", Vector3(7.4, 0, 0))
	b._save()
	_begin("bosquet_fruitier_4arbres", "vergers", "Bosquet fruitier de quatre arbres", "Petit verger irrégulier pour les abords de maisons et les courbes des chemins.", "Terrain plat ; quatre troncs séparés de plus de 4 m, passage central libre.")
	_tree(Vector3(-2.6, 0, -2.2), "apple", 2, .83)
	_tree(Vector3(2.45, 0, -2.85), "pear", 3, .88)
	_tree(Vector3(-1.9, 0, 2.65), "apple", 1, 1.03)
	_tree(Vector3(2.8, 0, 1.55), "pear", 4, .81)
	b.item.set_meta("walk_through", false)
	b.item.set_meta("minimum_trunk_spacing_m", 4.0)
	b._marker("PassageCentral", Vector3.ZERO)
	b._save()

func _soil(poly: PackedVector2Array, furrows: bool, spacing: float = .6) -> void:
	var outline: Array = []
	for p: Vector2 in poly:
		outline.append([p.x, p.y])
	b.item.set_meta("outline_xz", outline)
	b.item.set_meta("placement_surface", "flat or terraced; does not sculpt terrain")
	var st: SurfaceTool = b._surface("Terre", "earth")
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(poly)
	for i: int in range(0, indices.size(), 3):
		_face(st, Vector3(poly[indices[i]].x, .045, poly[indices[i]].y), Vector3(poly[indices[i + 1]].x, .045, poly[indices[i + 1]].y), Vector3(poly[indices[i + 2]].x, .045, poly[indices[i + 2]].y), Vector3.UP, b.rng.randf_range(.91, 1.05))
	for i: int in poly.size():
		var p: Vector2 = poly[i]
		var q: Vector2 = poly[(i + 1) % poly.size()]
		var p3: Vector3 = Vector3(p.x, .045, p.y)
		var q3: Vector3 = Vector3(q.x, .045, q.y)
		var outward: Vector3 = Vector3(q.y - p.y, 0, p.x - q.x).normalized()
		_face(st, p3, q3, Vector3(q.x, .003, q.y), outward, .82)
		_face(st, p3, Vector3(q.x, .003, q.y), Vector3(p.x, .003, p.y), outward, .82)
	if not furrows:
		return
	var rect: Rect2 = _polygon_bounds(poly)
	var x: float = rect.position.x + spacing * .55
	while x < rect.end.x:
		var in_run: bool = false
		var start_z: float = rect.position.y
		var z: float = rect.position.y
		while z <= rect.end.y + .22:
			var inside: bool = _inside_margin(Vector2(x, z), poly, .14)
			if inside and not in_run:
				start_z = z
				in_run = true
			elif not inside and in_run:
				_ridge(Vector3(x, .045, start_z), Vector3(x, .045, z - .22), .16)
				in_run = false
			z += .22
		x += spacing

func _polygon_bounds(poly: PackedVector2Array) -> Rect2:
	var rect: Rect2 = Rect2(poly[0], Vector2.ZERO)
	for p: Vector2 in poly:
		rect = rect.expand(p)
	return rect

func _inside_margin(p: Vector2, poly: PackedVector2Array, margin: float) -> bool:
	if not Geometry2D.is_point_in_polygon(p, poly):
		return false
	for i: int in poly.size():
		var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(p, poly[i], poly[(i + 1) % poly.size()])
		if nearest.distance_to(p) < margin:
			return false
	return true

func _ridge(a: Vector3, c: Vector3, half_width: float) -> void:
	if a.distance_to(c) < .18:
		return
	var st: SurfaceTool = b._surface("Sillons", "earth")
	var side: Vector3 = Vector3(half_width, 0, 0)
	var lift: Vector3 = Vector3(0, .055, 0)
	_face(st, a - side, c - side, c + lift, Vector3.UP, .76)
	_face(st, a - side, c + lift, a + lift, Vector3.UP, .76)
	_face(st, a + lift, c + lift, c + side, Vector3.UP, 1.06)
	_face(st, a + lift, c + side, a + side, Vector3.UP, 1.06)

func _wheat(at: Vector3, height: float, stalks: int, dense_crop: bool = false) -> void:
	for i: int in stalks:
		var spread: float = .23 if dense_crop else .17
		var offset: Vector3 = Vector3(b.rng.randf_range(-spread, spread), 0, b.rng.randf_range(-spread, spread))
		var h: float = height * b.rng.randf_range(.91 if dense_crop else .8, 1.09 if dense_crop else 1.12)
		var tip: Vector3 = at + offset + Vector3(b.rng.randf_range(-.10, .10), h, b.rng.randf_range(-.08, .08))
		_cross_stem("TigesDeBle", at + offset, tip, .020 if dense_crop else .013, "straw")
		var grain_st: SurfaceTool = b._surface("Epis", "grain")
		var head_size: Vector3 = Vector3(.083, .18, .080) if dense_crop else Vector3(.048, .17, .047)
		_octa(grain_st, tip, head_size, b.rng.randf_range(.82, 1.14))
		var leaf_st: SurfaceTool = b._surface("FeuillesDeBle", "straw")
		var base: Vector3 = (at + offset).lerp(tip, .5)
		var leaf_end: Vector3 = base + (Vector3(.24, .22, -.11) if dense_crop else Vector3(.13, .17, -.065))
		var leaf_edge: Vector3 = base + (Vector3(.07, .19, .045) if dense_crop else Vector3(.022, .13, .025))
		_face(leaf_st, base, leaf_end, leaf_edge, Vector3.UP, .87)
		_face(leaf_st, base, leaf_edge, leaf_end, Vector3.DOWN, .87)

func _cabbage(at: Vector3, scale_factor: float) -> void:
	var st: SurfaceTool = b._surface("Choux", "vegetable")
	_faceted_lobe(st, at + Vector3(0, .15 * scale_factor, 0), Vector3(.22, .17, .21) * scale_factor, 7, 3, .96)
	for i: int in 5:
		var angle: float = TAU * i / 5.0
		var outward: Vector3 = Vector3(cos(angle), 0, sin(angle))
		var side: Vector3 = Vector3(-sin(angle), 0, cos(angle))
		var center: Vector3 = at + Vector3(0, .105 * scale_factor, 0)
		var tip: Vector3 = center + (outward * .29 + Vector3(0, -.035, 0)) * scale_factor
		_face(st, center, center + (outward * .12 + side * .14) * scale_factor, tip, Vector3.UP, .75)
		_face(st, center, tip, center + (outward * .12 - side * .14) * scale_factor, Vector3.UP, .84)

func _leek(at: Vector3, scale_factor: float) -> void:
	var st: SurfaceTool = b._surface("Poireaux", "leaf_light")
	_cross_blade("PiedsPoireaux", at, .20 * scale_factor, .04 * scale_factor, "linen")
	for i: int in 5:
		var a: float = TAU * i / 5.0 + .24
		var outward: Vector3 = Vector3(cos(a), 0, sin(a))
		var side: Vector3 = Vector3(-sin(a), 0, cos(a)) * .025 * scale_factor
		var low: Vector3 = at + Vector3(0, .13 * scale_factor, 0)
		var mid: Vector3 = at + (outward * .12 + Vector3(0, .4 + .035 * (i % 2), 0)) * scale_factor
		var tip: Vector3 = at + (outward * .23 + Vector3(0, .44, 0)) * scale_factor
		_face(st, low - side, mid - side, mid + side, Vector3.UP, .87)
		_face(st, low - side, mid + side, low + side, Vector3.UP, .87)
		_face(st, mid - side, tip, mid + side, Vector3.UP, 1.03)
		_face(st, low - side, mid + side, mid - side, Vector3.DOWN, .81)
		_face(st, mid - side, mid + side, tip, Vector3.DOWN, .92)

func _sheaf(at: Vector3, scale_factor: float) -> void:
	# Sixteen angular stems are visually tied at their narrow waist.
	for i: int in 16:
		var a: float = TAU * i / 16.0
		var bottom: Vector3 = at + Vector3(cos(a) * .20, 0, sin(a) * .20) * scale_factor
		var waist: Vector3 = at + Vector3(cos(a) * .07, .47, sin(a) * .07) * scale_factor
		var top: Vector3 = at + Vector3(cos(a) * .25, .98 + b.rng.randf_range(-.07, .1), sin(a) * .25) * scale_factor
		_cross_stem("Gerbes", bottom, waist, .018 * scale_factor, "straw")
		_cross_stem("Gerbes", waist, top, .018 * scale_factor, "straw")
		_octa(b._surface("EpisGerbes", "grain"), top, Vector3(.05, .15, .05) * scale_factor, b.rng.randf_range(.88, 1.08))
	b._ring("LiensGerbes", at + Vector3(0, .47, 0) * scale_factor, .103 * scale_factor, .075 * scale_factor, .045 * scale_factor, "rope")

func _tree(at: Vector3, fruit: String, variant: int, scale_factor: float) -> void:
	var nodes: Array[Vector4] = []
	var lean: Vector3 = Vector3.ZERO
	var trunk_height: float = 2.15
	var trunk_radius: float = .18
	match variant:
		0:
			nodes = [Vector4(-.85, 3.05, -.38, 1.18), Vector4(.8, 3.4, -.45, 1.20), Vector4(-.5, 3.62, .65, 1.04), Vector4(.85, 2.95, .65, 1.08), Vector4(.0, 4.0, -.12, 1.05)]
			trunk_radius = .22
		1:
			nodes = [Vector4(-.42, 2.6, -.25, .88), Vector4(.48, 2.82, .22, .83), Vector4(.05, 3.47, -.03, .76)]
			trunk_radius = .13
			trunk_height = 1.95
		2:
			nodes = [Vector4(-.7, 3.02, -.75, 1.00), Vector4(.5, 3.26, -.45, 1.24), Vector4(1.35, 3.1, .3, 1.04), Vector4(-.25, 3.55, .66, 1.11), Vector4(.8, 4.0, .08, .93)]
			lean = Vector3(.5, 0, .12)
			trunk_radius = .27
			trunk_height = 1.9
		3:
			nodes = [Vector4(-.4, 2.9, -.12, .83), Vector4(.38, 3.15, .24, .91), Vector4(-.3, 3.86, .17, .84), Vector4(.34, 4.35, -.16, .72), Vector4(.05, 4.95, .06, .52)]
			trunk_radius = .17
		4:
			nodes = [Vector4(-.67, 2.88, .23, .99), Vector4(.73, 3.35, -.25, 1.0), Vector4(-.7, 3.92, .24, .8), Vector4(.67, 4.27, -.34, .85), Vector4(-.59, 4.73, .1, .55), Vector4(.68, 5.1, -.24, .59)]
			trunk_radius = .25
			trunk_height = 2.05
	var fork: Vector3 = at + (lean + Vector3(0, trunk_height, 0)) * scale_factor
	_tapered_rod("Troncs", at, fork, trunk_radius * scale_factor, trunk_radius * .68 * scale_factor, "bark", 7)
	# Root flares meet the ground and do not form a plate or a collision barrier.
	for i: int in 5:
		var a: float = TAU * i / 5.0
		_tapered_rod("Racines", at + Vector3(cos(a) * trunk_radius * 1.7, .015, sin(a) * trunk_radius * 1.7) * scale_factor, at + Vector3(0, .34, 0) * scale_factor, .05 * scale_factor, .09 * scale_factor, "bark", 5)
	for i: int in nodes.size():
		var node: Vector4 = nodes[i]
		var center: Vector3 = at + Vector3(node.x, node.y, node.z) * scale_factor
		_tapered_rod("Branches", fork - Vector3(0, .2, 0) * scale_factor, center - Vector3(0, .18, 0) * scale_factor, .095 * scale_factor, .026 * scale_factor, "bark", 6)
		var st: SurfaceTool = b._surface("Feuillage", "leaf" if i % 3 != 1 else "leaf_light")
		var stretch: Vector3 = Vector3(node.w, node.w * (.83 if fruit == "apple" else 1.10), node.w * .88) * scale_factor
		_faceted_lobe(st, center, stretch, 8, 4, b.rng.randf_range(.83, 1.06))
		for j: int in 5:
			var a: float = TAU * j / 5.0 + i * .73
			var fruit_pos: Vector3 = center + Vector3(cos(a) * stretch.x * .94, -stretch.y * (.38 + .13 * (j % 2)), sin(a) * stretch.z * .94)
			var size: Vector3 = Vector3(.095, .10, .095) * scale_factor
			if fruit == "pear":
				size = Vector3(.092, .14, .092) * scale_factor
				_octa(b._surface("Fruits", fruit), fruit_pos - Vector3(0, .025, 0) * scale_factor, size, b.rng.randf_range(.82, 1.09))
				_octa(b._surface("Fruits", fruit), fruit_pos + Vector3(0, .07, 0) * scale_factor, size * .53, 1.02)
			else:
				_octa(b._surface("Fruits", fruit), fruit_pos, size, b.rng.randf_range(.80, 1.08))
			_cross_blade("QueuesFruits", fruit_pos + Vector3(0, size.y * .8, 0), .075 * scale_factor, .009 * scale_factor, "bark")
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = (trunk_radius + lean.length() * .32) * scale_factor
	shape.height = trunk_height * scale_factor
	b._collision("Tronc", shape, Transform3D(Basis.IDENTITY, at + (Vector3(0, trunk_height * .5, 0) + lean * .45) * scale_factor))
	b._marker("PiedFruitier", at)

func _cross_blade(group: String, at: Vector3, height: float, width: float, mat: String) -> void:
	_cross_stem(group, at, at + Vector3(0, height, 0), width, mat)

func _cross_stem(group: String, a: Vector3, c: Vector3, width: float, mat: String) -> void:
	var st: SurfaceTool = b._surface(group, mat)
	for side: Vector3 in [Vector3(width, 0, 0), Vector3(0, 0, width)]:
		b._tri(st, a - side, c - side, c + side)
		b._tri(st, a - side, c + side, a + side)

func _octa(st: SurfaceTool, at: Vector3, size: Vector3, tone: float) -> void:
	var top: Vector3 = at + Vector3(0, size.y, 0)
	var bottom: Vector3 = at - Vector3(0, size.y, 0)
	for i: int in 4:
		var a: float = TAU * i / 4.0
		var c: float = TAU * (i + 1) / 4.0
		var p: Vector3 = at + Vector3(cos(a) * size.x, 0, sin(a) * size.z)
		var q: Vector3 = at + Vector3(cos(c) * size.x, 0, sin(c) * size.z)
		_face(st, top, p, q, (top + p + q) / 3.0 - at, tone)
		_face(st, bottom, q, p, (bottom + p + q) / 3.0 - at, tone * .89)

func _faceted_lobe(st: SurfaceTool, at: Vector3, size: Vector3, segments: int, rings: int, tone: float) -> void:
	# Shared vertices form a closed asymmetric crown, no gaps between random faces.
	var bands: Array[PackedVector3Array] = []
	for r: int in range(1, rings):
		var polar: float = PI * r / rings
		var band: PackedVector3Array = PackedVector3Array()
		for i: int in segments:
			var a: float = TAU * i / segments
			var irregularity: float = b.rng.randf_range(.87, 1.12)
			band.append(at + Vector3(cos(a) * sin(polar) * size.x * irregularity, cos(polar) * size.y + b.rng.randf_range(-.05, .05) * size.y, sin(a) * sin(polar) * size.z * irregularity))
		bands.append(band)
	var top: Vector3 = at + Vector3(.055 * size.x, size.y, -.045 * size.z)
	var bottom: Vector3 = at - Vector3(.04 * size.x, size.y * .95, 0)
	for i: int in segments:
		var next: int = (i + 1) % segments
		_face(st, top, bands[0][i], bands[0][next], (top + bands[0][i] + bands[0][next]) / 3.0 - at, tone * 1.07)
		_face(st, bottom, bands[-1][next], bands[-1][i], (bottom + bands[-1][i] + bands[-1][next]) / 3.0 - at, tone * .74)
		for r: int in bands.size() - 1:
			var p: Vector3 = bands[r][i]
			var q: Vector3 = bands[r][next]
			var c: Vector3 = bands[r + 1][i]
			var d: Vector3 = bands[r + 1][next]
			_face(st, p, c, d, (p + c + d) / 3.0 - at, tone * b.rng.randf_range(.91, 1.04))
			_face(st, p, d, q, (p + d + q) / 3.0 - at, tone * b.rng.randf_range(.91, 1.04))

func _tapered_rod(group: String, start: Vector3, finish: Vector3, radius: float, tip_radius: float, mat: String, segments: int) -> void:
	var axis: Vector3 = (finish - start).normalized()
	var tangent: Vector3 = axis.cross(Vector3.FORWARD).normalized()
	if tangent.length_squared() < .1:
		tangent = axis.cross(Vector3.RIGHT).normalized()
	var bitangent: Vector3 = axis.cross(tangent).normalized()
	var st: SurfaceTool = b._surface(group, mat)
	for i: int in segments:
		var a: float = TAU * i / segments
		var c: float = TAU * (i + 1) / segments
		var n0: Vector3 = tangent * cos(a) + bitangent * sin(a)
		var n1: Vector3 = tangent * cos(c) + bitangent * sin(c)
		var p: Vector3 = start + n0 * radius
		var q: Vector3 = start + n1 * radius
		var u: Vector3 = finish + n0 * tip_radius
		var v: Vector3 = finish + n1 * tip_radius
		_face(st, p, u, v, n0 + n1, .94)
		_face(st, p, v, q, n0 + n1, .94)
		_face(st, start, q, p, -axis, .75)
		_face(st, finish, u, v, axis, 1.03)

func _face(st: SurfaceTool, a: Vector3, c: Vector3, d: Vector3, outward: Vector3, tone: float = 1.0) -> void:
	# Godot's front faces are clockwise as seen from the visible side.
	if (c - a).cross(d - a).dot(outward) > 0:
		b._tri(st, a, d, c, tone)
	else:
		b._tri(st, a, c, d, tone)
