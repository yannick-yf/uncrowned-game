extends SceneTree
## Real renderer views and a playable review at the foot of the castle.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var session: Node3D=(load("res://scenes/test_brindle.tscn") as PackedScene).instantiate();root.add_child(session)
	for i: int in 45:await process_frame
	var world: Node3D=session.get_node("World");var ground: Node3D=world.get_node("Terrain")
	var player: CharacterBody3D=world.get_node("Characters/Player")
	player.position=Vector3(-168,ground.call("surface_height_at_world",-168,-145)+.12,-145);player.velocity=Vector3.ZERO
	session.call("set_playing",false)
	world.get_node("Terrain/Landscape/SiteGuides").visible=false
	world.get_node("Decor/MineAcierie/RepereMine").visible=false
	var camera: Camera3D=world.get_node("MapCamera")
	camera.call("set_view",Vector2(-177,-232),230,38,-18)
	if "--capture" in OS.get_cmdline_user_args():
		world.get_node("MapInfo").visible=false
		var out: String=ProjectSettings.globalize_path("user://previews/ville-royale/")
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with("--out="):out=arg.trim_prefix("--out=").trim_suffix("/")+"/"
		DirAccess.make_dir_recursive_absolute(out)
		for view: Array in [["01-ville-et-chateau",-177,-232,230,38,-18],["02-chateau",-193,-278,135,34,-24],["03-ville",-171,-178,112,48,-15],["04-porte-et-douves",-168,-127,65,34,-26],["05-vue-de-dessus",-178,-228,230,76,0],["06-montagne",-177,-245,240,28,-14]]:
			camera.call("set_view",Vector2(view[1],view[2]),view[3],view[4],view[5])
			for i: int in 12:await process_frame
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png(out+view[0]+".png")==OK)
		print("ROYAL_CITY_CAPTURE_OK");quit()
	else:print("ROYAL_CITY_REVIEW_READY")
