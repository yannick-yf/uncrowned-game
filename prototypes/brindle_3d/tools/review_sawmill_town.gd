extends SceneTree
## Camera review of the integrated, playable village. --capture writes real renders.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var session: Node3D=(load("res://scenes/test_brindle.tscn") as PackedScene).instantiate();root.add_child(session)
	for i: int in 45:await process_frame
	var world: Node3D=session.get_node("World")
	session.call("set_playing",false)
	world.get_node("MapInfo").visible=not ("--capture" in OS.get_cmdline_user_args())
	world.get_node("Terrain/Landscape/SiteGuides").visible=false
	var camera: Camera3D=world.get_node("MapCamera")
	camera.call("set_view",Vector2(235,-157),102,49,25)
	var player: CharacterBody3D=world.get_node("Characters/Player")
	player.position=Vector3(234,float(world.get_node("Terrain").call("surface_height_at_world",234,-131))+.12,-131);player.velocity=Vector3.ZERO
	if "--capture" in OS.get_cmdline_user_args():
		var out: String=ProjectSettings.globalize_path("user://previews/scierie/")
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with("--out="):out=arg.trim_prefix("--out=").trim_suffix("/")+"/"
		DirAccess.make_dir_recursive_absolute(out)
		for view: Array in [["01-village",235,-157,102,49,25],["02-scie-et-eau",253,-150,44,39,40],["03-quartiers",224,-146,66,44,20],["04-depots",239,-185,48,40,30],["05-hydrologie",248,-171,132,65,5]]:
			camera.call("set_view",Vector2(view[1],view[2]),view[3],view[4],view[5])
			for i: int in 10:await process_frame
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png(out+view[0]+".png")==OK)
		print("SAWMILL_TOWN_CAPTURE_OK");quit()
	else:print("SAWMILL_REVIEW_READY")
