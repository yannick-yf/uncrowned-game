extends SceneTree
## Render actual saved meshes, not an illustrative concept image.
var output: String="res://previews/"
var catalog: Dictionary={}
var board: Control

func _initialize() -> void:call_deferred("run")

func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=").trim_suffix("/")+"/"
	DirAccess.make_dir_recursive_absolute(output)
	for a: Dictionary in JSON.parse_string(FileAccess.get_file_as_string("res://assets/sawmill/catalog.json")).assets:catalog[a.id]=a
	await sheet("01-scierie-hydraulique","SCIERIE   /   LA GRANDE HALLE À ROUE À EAU",["scierie_hydraulique"],1,1)
	await sheet("02-selection","SCIERIE   /   BOIS, CHARPENTES & COLOMBAGES",[
		"scierie_hydraulique","atelier_charpentier","halle_sechage",
		"logis_a_colombages","baraquement_a_galerie","charrette_grumes"],3,2)
	await sheet("03-production","SCIERIE   /   ATELIERS & STOCKAGE",[
		"atelier_charpentier","atelier_charron","fosse_sciage",
		"halle_sechage","depot_grumes","bureau_bois",
		"hangar_charrettes_bois","portique_chargement","roue_a_aubes"],3,3)
	await sheet("04-logements","SCIERIE   /   MAISONS & LOGEMENTS DES OUVRIERS",[
		"logis_porte_basse","maison_aux_deux_volumes","logis_a_colombages","baraquement_des_equipes",
		"baraquement_a_galerie","logis_du_contremaitre_en_l","maison_des_charretiers","maison_au_toit_decale"],4,2)
	await sheet("05-accessoires","SCIERIE   /   MATÉRIAUX, OUTILS & AMÉNAGEMENTS",[
		"grumes_longues","tas_planches","poutres_equarries","chevalets_sciage",
		"etabli_menuisier","ratelier_outils_bois","traineau_debardage","billot_fendage",
		"quai_bois","passerelle_bois","canal_amenee","vanne_bois"],4,3)
	print("SAWMILL_RENDER_OK ",output)
	quit()

func sheet(filename: String,title: String,ids: Array,cols: int,rows: int) -> void:
	var cell: Vector2i=Vector2i(1440,940) if cols==1 else Vector2i(520,420)
	root.size=Vector2i(cols*cell.x,rows*cell.y+142)
	root.content_scale_size=root.size
	board=Control.new();root.add_child(board)
	var bg: ColorRect=ColorRect.new();bg.color=Color("e6e0d4");bg.size=Vector2(root.size);board.add_child(bg)
	label(title,Vector2(28,20),28,Color("322c25"))
	label("Pierre calcaire · chêne sombre · enduits à la chaux · ardoise et tuiles ocre",Vector2(30,61),18,Color("655b4c"))
	for i: int in ids.size():
		var id: String=ids[i];var a: Dictionary=catalog[id]
		var pos: Vector2=Vector2((i%cols)*cell.x,92+(i/cols)*cell.y)
		var viewport: SubViewport=SubViewport.new();viewport.size=Vector2i(cell.x-8,cell.y-54)
		viewport.own_world_3d=true;viewport.msaa_3d=Viewport.MSAA_4X;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		board.add_child(viewport)
		var world: Node3D=Node3D.new();viewport.add_child(world)
		var obj: Node3D=(load(a.scene) as PackedScene).instantiate();world.add_child(obj)
		var env: WorldEnvironment=WorldEnvironment.new();env.environment=Environment.new();world.add_child(env)
		env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("e6e0d4")
		env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("c1c9d0");env.environment.ambient_light_energy=.65
		env.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
		env.environment.ssao_enabled=true;env.environment.ssao_radius=.8;env.environment.ssao_intensity=1.1
		var sun: DirectionalLight3D=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-38,0);sun.light_energy=1.7;sun.light_color=Color("ffefda");sun.shadow_enabled=true;world.add_child(sun)
		var floor_mesh: MeshInstance3D=MeshInstance3D.new();var plane: PlaneMesh=PlaneMesh.new();plane.size=Vector2(200,200);floor_mesh.mesh=plane;floor_mesh.position.y=-.025
		var mat: StandardMaterial3D=StandardMaterial3D.new();mat.albedo_color=Color("b9b3a4");mat.roughness=1.0;floor_mesh.material_override=mat;world.add_child(floor_mesh)
		var cam: Camera3D=Camera3D.new();cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.current=true;cam.rotation_degrees=Vector3(-24,32,0)
		var dims: Vector3=Vector3(a.size_m[0],a.size_m[1],a.size_m[2]);var focus: Vector3=Vector3(a.bounds_center_m[0],a.bounds_center_m[1],a.bounds_center_m[2])
		var aspect: float=float(viewport.size.x)/viewport.size.y
		cam.size=maxf(cam.basis.y.abs().dot(dims)*1.12,cam.basis.x.abs().dot(dims)/aspect*1.15)
		cam.position=focus+cam.basis.z*40;cam.far=180;world.add_child(cam)
		var rect: TextureRect=TextureRect.new();rect.texture=viewport.get_texture();rect.position=pos+Vector2(4,0);rect.size=Vector2(viewport.size);board.add_child(rect)
		label(a.label,pos+Vector2(18,cell.y-45),18,Color("322c25"))
		label("%.1f × %.1f × %.1f m"%[dims.x,dims.y,dims.z],pos+Vector2(18,cell.y-21),13,Color("756953"))
	label("UNCROWNED  •  Modèles 3D rendus dans Godot  •  16 septembre 2026",Vector2(30,root.size.y-33),15,Color("655b4c"))
	for i: int in 16:await process_frame
	await RenderingServer.frame_post_draw
	var result: Error=root.get_texture().get_image().save_png(output+filename+".png")
	assert(result==OK)
	board.queue_free();await process_frame

func label(value: String,at: Vector2,size: int,color: Color) -> void:
	var node: Label=Label.new();node.text=value;node.position=at;node.add_theme_font_size_override("font_size",size);node.add_theme_color_override("font_color",color);board.add_child(node)
