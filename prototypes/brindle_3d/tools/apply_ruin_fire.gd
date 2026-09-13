extends SceneTree
const BOUNDS := Rect2(102,193,145,120)
const SCALE := 8.0

func _initialize() -> void: call_deferred("build")

func build() -> void:
	if "--mask-only" in OS.get_cmdline_user_args():
		make_scorch_mask()
		make_smoke()
		quit(); return
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://planning/ruines-brindle.json"))
	var look: RefCounted = load("res://scripts/burned_ruin_look.gd").new()
	for variant: Dictionary in report.variants:
		var house: Node3D = (load(variant.ruined_asset) as PackedScene).instantiate()
		look.apply(house,variant.building)
		own(house,house)
		var packed := PackedScene.new(); assert(packed.pack(house)==OK)
		assert(ResourceSaver.save(packed,variant.ruined_asset)==OK)
		variant["fire_damage"] = true
		variant["residual_smoke"] = variant.building in ["MaisonDuChemin","MaisonBasse"]
		house.free()
	# Burn the low vegetation only where the terrain mask says it was scorched.
	var substitutions: Dictionary = {}
	for name: String in ["styled_plants","styled_leaves_light","styled_wood"]:
		var source_path: String = "res://prototype_3d/materials/"+name+".tres"
		var material: Material = look.burned_material(load(source_path),true)
		substitutions[source_path] = material.resource_path
	var village_path := "res://scenes/sectors/brindle.tscn"
	var text: String = FileAccess.get_file_as_string(village_path)
	for key: String in substitutions: text = text.replace('path="'+key+'"','path="'+substitutions[key]+'"')
	var file := FileAccess.open(village_path,FileAccess.WRITE);file.store_string(text);file.close()
	report["state"] = "incendie_recent"
	report["smoke_houses"] = ["MaisonDuChemin","MaisonBasse"]
	report["scorch_mask"] = "res://assets/landscape/brindle_scorch_mask.png"
	report["scorch_bounds_xz"] = [102,193,145,120]
	file=FileAccess.open("res://planning/ruines-brindle.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	print("FIRE_APPLIED houses=6 smoke_emitters=2")
	quit()

func make_scorch_mask() -> void:
	var village: Node3D = (load("res://scenes/sectors/brindle.tscn") as PackedScene).instantiate()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://planning/ruines-brindle.json"))
	var size := Vector2i(BOUNDS.size*SCALE)
	var image := Image.create(size.x,size.y,false,Image.FORMAT_RGB8)
	image.fill(Color.BLACK)
	var noise := FastNoiseLite.new(); noise.seed=902147; noise.frequency=.8
	for house: Node3D in village.get_node("Maisons").get_children():
		var variant: Dictionary = {}
		for row: Dictionary in data.variants:
			if row.building==str(house.name): variant=row;break
		var half_size := Vector2(float(variant.width_m),float(variant.depth_m))*.5
		var center := Vector2(house.position.x,house.position.z)
		var low := Vector2i(((center-Vector2.ONE*8-BOUNDS.position)*SCALE).floor()).max(Vector2i.ZERO)
		var high := Vector2i(((center+Vector2.ONE*8-BOUNDS.position)*SCALE).ceil()).min(size-Vector2i.ONE)
		for y: int in range(low.y,high.y+1):
			for x: int in range(low.x,high.x+1):
				var p: Vector2 = BOUNDS.position+(Vector2(x,y)+Vector2.ONE*.5)/SCALE
				var local: Vector3 = house.basis.inverse()*Vector3(p.x-center.x,0,p.y-center.y)
				var q: Vector2 = Vector2(local.x,local.z).abs()-half_size
				var distance: float = q.max(Vector2.ZERO).length()+minf(maxf(q.x,q.y),0.0)
				var n: float = noise.get_noise_2d(p.x*1.4,p.y*1.4)
				var ragged: float = distance+n*.63+noise.get_noise_2d(p.x*.42,p.y*.42)*.6
				var core: float = 1.0-smoothstep(-.25,1.9,ragged)
				var burn: float = core*(.84+noise.get_noise_2d(p.x*4,p.y*4)*.14)
				var ash: float = smoothstep(-.1,.52,noise.get_noise_2d(p.x*2.7,p.y*2.7))*core
				var dry: float = 1.0-smoothstep(.4,2.7,ragged)
				var old: Color = image.get_pixel(x,y)
				image.set_pixel(x,y,Color(maxf(old.r,burn),maxf(old.g,ash),maxf(old.b,dry)))
	assert(image.save_png("res://assets/landscape/brindle_scorch_mask.png")==OK)
	village.free()
	print("SCORCH_MASK_SAVED ",size)

func make_smoke() -> void:
	DirAccess.make_dir_recursive_absolute("res://scenes/effects")
	var smoke := CPUParticles3D.new();smoke.name="FumeeResiduelle"
	smoke.amount=18;smoke.lifetime=4.4;smoke.preprocess=5.0
	smoke.randomness=.4;smoke.lifetime_randomness=.2
	smoke.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE;smoke.emission_sphere_radius=.17
	smoke.direction=Vector3.UP;smoke.spread=9.0
	smoke.gravity=Vector3(.025,.075,-.008)
	smoke.initial_velocity_min=.28;smoke.initial_velocity_max=.42
	smoke.scale_amount_min=.65;smoke.scale_amount_max=.93
	var scale_curve:=Curve.new();scale_curve.add_point(Vector2(0,.27));scale_curve.add_point(Vector2(.35,.68));scale_curve.add_point(Vector2(1,1.0))
	smoke.scale_amount_curve=scale_curve
	var gradient:=Gradient.new();gradient.offsets=PackedFloat32Array([0,.12,.50,1])
	gradient.colors=PackedColorArray([Color(1,1,1,0),Color(1,1,1,.27),Color(1,1,1,.15),Color(1,1,1,0)])
	smoke.color_ramp=gradient
	var mesh:=QuadMesh.new();mesh.size=Vector2(1.5,1.5)
	var material:=ShaderMaterial.new();material.shader=load("res://shaders/ruin_smoke.gdshader")
	mesh.material=material;smoke.mesh=mesh;smoke.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var scene:=PackedScene.new();assert(scene.pack(smoke)==OK)
	assert(ResourceSaver.save(scene,"res://scenes/effects/fumee_ruine.tscn")==OK)
	smoke.free();print("SMOKE_SCENE_SAVED")

func own(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():child.owner=owner_node;own(child,owner_node)
