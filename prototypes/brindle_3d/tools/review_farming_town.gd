extends SceneTree
## Review the real integrated map; Tab uses the existing playable character.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var session: Node3D=(load("res://scenes/test_brindle.tscn") as PackedScene).instantiate();root.add_child(session)
	for i: int in 45:await process_frame
	var world: Node3D=session.get_node("World")
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://planning/farming-town.json"))
	var ground: Node3D=world.get_node("Terrain")
	var player: CharacterBody3D=world.get_node("Characters/Player")
	player.position=Vector3(plan.spawn_xz[0],float(ground.call("surface_height_at_world",plan.spawn_xz[0],plan.spawn_xz[1]))+.12,plan.spawn_xz[1]);player.velocity=Vector3.ZERO
	session.call("set_playing",false)
	world.get_node("Terrain/Landscape/SiteGuides").visible=false
	var camera: Camera3D=world.get_node("MapCamera")
	camera.call("set_view",Vector2(plan.focus_xz[0],plan.focus_xz[1]),142,48,-22)
	if "--capture" in OS.get_cmdline_user_args():
		world.get_node("MapInfo").visible=false
		var out: String=ProjectSettings.globalize_path("user://previews/village-fermier/")
		for arg: String in OS.get_cmdline_user_args():
			if arg.begins_with("--out="):out=arg.trim_prefix("--out=").trim_suffix("/")+"/"
		DirAccess.make_dir_recursive_absolute(out)
		for view: Array in [
			["01-village-fermier",-177,38,146,49,-22],
			["02-place-du-puits",-174,34,48,40,-22],
			["03-moulin-et-bief",-214,33,48,43,-35],
			["04-champs-et-ponts",-219,76,92,52,-15],
			["05-vergers",-137,74,71,45,-20],
			["06-plan-ensemble",-178,44,190,78,0],
			["07-acces-grenier",-134,20,22,40,-45],
			["08-porches-moulin",-207,40,25,35,-15],
			["09-maison-appentis",-195,51,24,35,85]
		]:
			camera.call("set_view",Vector2(view[1],view[2]),view[3],view[4],view[5])
			var atmosphere: Node = world.get_node_or_null("FarmingAtmosphere")
			if atmosphere != null:atmosphere.call("refresh",true)
			for i: int in 32:await process_frame
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png(out+view[0]+".png")==OK)
		print("FARM_TOWN_CAPTURE_OK ",out);quit()
	else:print("FARM_TOWN_REVIEW_READY — Tab pour explorer, V pour revenir au village en vue libre")
