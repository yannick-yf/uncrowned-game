extends SceneTree
## Contact sheets rendered from the saved game meshes, outside the repository by default.
var output: String="user://farming-previews/"
var catalog: Dictionary={}
var board: Control
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=").trim_suffix("/")+"/"
	DirAccess.make_dir_recursive_absolute(output)
	for a: Dictionary in JSON.parse_string(FileAccess.get_file_as_string("res://assets/farming/catalog.json")).assets:catalog[a.id]=a
	await sheet("01-pack-fermier","VILLAGE FERMIER  /  LE PACK MODULAIRE",["chaumiere_du_potager","ferme_en_l","moulin_a_grain_hydraulique","grange_traversante","grenier_sur_piliers","reserve_a_grain_octogonale","champ_ble_rive_concave","champ_legumes_boucle","verger_aligne_6arbres"],3,3)
	var houses: Array=[];var props: Array=[]
	for a: Dictionary in catalog.values():
		if a.family=="maisons":houses.append(a.id)
		if a.family in ["accessoires","modules","stockage"]:props.append(a.id)
	await sheet("02-maisons","HABITATIONS  /  HUIT SILHOUETTES RURALES",houses,4,2)
	await sheet("03-cultures-vergers","CULTURES & VERGERS  /  PARCELLES ORGANIQUES",["champ_ble_rive_concave","champ_legumes_boucle","champ_laboure_lisiere","bordure_courbe_champ","pommier_etale","pommier_penche","poirier_fuseau","bosquet_fruitier_4arbres","faisceau_gerbes"],3,3)
	await sheet("04-accessoires","LA VIE DES CHAMPS  /  ACCESSOIRES MODULAIRES",props.slice(0,20),4,ceili(props.size()/4.0))
	var gallery: Node3D=(load("res://scenes/catalogue_fermier.tscn") as PackedScene).instantiate();root.add_child(gallery)
	root.size=Vector2i(1440,1000);root.content_scale_size=root.size
	for i: int in 18:await process_frame
	gallery.canvas.visible=false;gallery.zoom=70;gallery.call("_update_camera")
	for i: int in 8:await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output+"05-assemblage-fermier.png")==OK)
	gallery.canvas.visible=true;gallery.call("_update_camera")
	for i: int in 4:await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output+"06-catalogue.png")==OK)
	for i: int in gallery.catalog.size():
		if gallery.catalog[i].id=="moulin_a_grain_hydraulique":gallery.select_asset(i);break
	for i: int in 4:await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output+"07-moulin-detail.png")==OK)
	print("FARMING_RENDER_OK ",output);quit()
func sheet(filename: String,title: String,ids: Array,cols: int,rows: int) -> void:
	var cell: Vector2i=Vector2i(500,380)
	root.size=Vector2i(cols*cell.x,rows*cell.y+122);root.content_scale_size=root.size
	board=Control.new();root.add_child(board)
	var background: ColorRect=ColorRect.new();background.color=Color("e2e4d7");background.size=Vector2(root.size);board.add_child(background)
	label(title,Vector2(25,16),26,Color("2c392b"))
	label("Pierre claire · chêne · chaume · terre cultivée · fruitiers   /   pièces 3D réelles",Vector2(26,54),17,Color("59644e"))
	for i: int in ids.size():
		var a: Dictionary=catalog[ids[i]];var pos: Vector2=Vector2((i%cols)*cell.x,88+(i/cols)*cell.y)
		var viewport: SubViewport=SubViewport.new();viewport.size=Vector2i(cell.x-8,cell.y-50);viewport.own_world_3d=true;viewport.msaa_3d=Viewport.MSAA_4X;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;board.add_child(viewport)
		var world: Node3D=Node3D.new();viewport.add_child(world);world.add_child((load(a.scene) as PackedScene).instantiate())
		var env: WorldEnvironment=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("e2e4d7");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("d2d8df");env.environment.ambient_light_energy=.6;env.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.environment.ssao_enabled=true;env.environment.ssao_radius=.6;env.environment.ssao_intensity=1.1;world.add_child(env)
		var sun: DirectionalLight3D=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-47,-34,0);sun.light_energy=1.65;sun.light_color=Color("fff0d8");sun.shadow_enabled=true;world.add_child(sun)
		var floor_node: MeshInstance3D=MeshInstance3D.new();var floor_mesh: PlaneMesh=PlaneMesh.new();floor_mesh.size=Vector2(160,160);floor_node.mesh=floor_mesh;floor_node.position.y=-.035;var mat: StandardMaterial3D=StandardMaterial3D.new();mat.albedo_color=Color("adb79c");mat.roughness=1.;floor_node.material_override=mat;world.add_child(floor_node)
		var cam: Camera3D=Camera3D.new();cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.current=true;cam.rotation_degrees=Vector3(-28,-35 if str(a.id).contains("moulin") else 30,0)
		var dims: Vector3=Vector3(a.size_m[0],a.size_m[1],a.size_m[2]);var at: Vector3=Vector3(a.bounds_center_m[0],a.bounds_center_m[1],a.bounds_center_m[2]);var aspect: float=float(viewport.size.x)/viewport.size.y
		cam.size=maxf(cam.basis.y.abs().dot(dims)*1.2,cam.basis.x.abs().dot(dims)/aspect*1.2);cam.position=at+cam.basis.z*50;cam.far=200;world.add_child(cam)
		var rect: TextureRect=TextureRect.new();rect.texture=viewport.get_texture();rect.position=pos+Vector2(4,0);rect.size=Vector2(viewport.size);board.add_child(rect)
		label(a.label,pos+Vector2(15,cell.y-44),18,Color("2c392b"));label("%.1f × %.1f × %.1f m"%[dims.x,dims.y,dims.z],pos+Vector2(15,cell.y-21),13,Color("657052"))
	label("UNCROWNED   /   Bibliothèque fermière   /   Rendu Godot · 21 septembre 2026",Vector2(26,root.size.y-27),14,Color("59644e"))
	for i: int in 12:await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output+filename+".png")==OK)
	board.queue_free();await process_frame
func label(value: String,at: Vector2,size: int,color: Color) -> void:
	var node: Label=Label.new();node.text=value;node.position=at;node.add_theme_font_size_override("font_size",size);node.add_theme_color_override("font_color",color);board.add_child(node)
