extends "res://tools/build_royal_assets.gd"
## Saved city walls and retaining walls of the ascent. All passages remain open.
func build() -> void:
	royal=load("res://tools/royal_architecture.gd").new(self)
	_load_materials()
	layout=JSON.parse_string(FileAccess.get_file_as_string("res://planning/royal-city.json"))
	_start("enceinte_de_la_ville","fortifications","Enceinte de la ville","Courtines, tours, portes et soutènements de la montée.","Coordonnées mondiales de la ville royale.")
	var points: Array=layout.wall_polygon
	for i: int in points.size():
		if i in [5,14]:continue
		var a: Array=points[i];var c: Array=points[(i+1)%points.size()]
		royal.wall(Vector3(a[0],58,a[1]),Vector3(c[0],58,c[1]),15.0,1.75)
	for i: int in [0,1,2,3,4,7,8,9,10,11,12]:
		var p: Array=points[i]
		royal.tower(Vector3(p[0],60.5,p[1]),2.65+float(i%3)*.18,15+float(i%3)*.7,5.0+float(i%2)*.6)
	var gate: Node3D=(load(ROYAL_OUT+"fortifications/porte_royale.tscn") as PackedScene).instantiate();gate.name="PorteRoyale";gate.position=Vector3(-168,64.2,-126);item.add_child(gate)
	var upper: Node3D=(load(ROYAL_OUT+"fortifications/porte_haute.tscn") as PackedScene).instantiate();upper.name="PorteHaute";upper.position=Vector3(-213.95,68.5,-216);upper.rotation_degrees.y=30;item.add_child(upper)
	# Stone guard walls on the exposed switchbacks, above the town and below the castle.
	var ramp: Curve3D=preload("res://scripts/royal_ascent.gd").curve(layout.ramp_xyz)
	for j: int in range(ceili(ramp.get_baked_length()/1.25)):
		var p: Vector3=ramp.sample_baked(j*1.25);var q: Vector3=ramp.sample_baked(minf((j+1)*1.25,ramp.get_baked_length()))
		if p.y<70 or p.z< -244:continue
		var direction: Vector3=(q-p).normalized();var side: Vector3=Vector3(direction.z,0,-direction.x).normalized()*3.85
		for sign: float in [-1.0,1.0]:
			var at: Vector3=(p+q)*.5+side*sign
			var yaw: float=atan2(q.x-p.x,q.z-p.z)
			_box("RampRetainingMasonry",Vector3(.40,6.6,p.distance_to(q)+.10),at+Vector3(0,-2.70,0),"stone",Vector3(0,yaw,0),true)
			_beam("RampCoping",p+side*sign+Vector3(0,.65,0),q+side*sign+Vector3(0,.65,0),.48,"stone")
	_save()
	assert(ResourceSaver.save(load(ROYAL_OUT+"fortifications/enceinte_de_la_ville.tscn"),"res://scenes/sectors/ville_royale_enceinte.tscn")==OK)
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROYAL_OUT+"catalog.json"))
	manifest.assets=manifest.assets.filter(func(a: Dictionary):return a.id!="enceinte_de_la_ville")
	manifest.assets.append(catalog[0])
	var file: FileAccess=FileAccess.open(ROYAL_OUT+"catalog.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"  "));file.close()
	print("ROYAL_FORTIFICATIONS_OK");quit()
