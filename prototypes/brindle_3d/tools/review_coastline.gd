extends SceneTree
## Review the continuous coastline in the playable workshop, not a separate mockup.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var session: Node3D=load("res://scenes/test_brindle.tscn").instantiate();root.add_child(session)
	for i: int in 45:await process_frame
	var world: Node3D=session.get_node("World")
	var ground: Node3D=world.get_node("Terrain")
	var player: CharacterBody3D=world.get_node("Characters/Player")
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://planning/coastline.json"))
	var spawn: Vector2=Vector2(plan.review_spawn_xz[0],plan.review_spawn_xz[1])
	player.position=Vector3(spawn.x,ground.call("surface_height_at_world",spawn.x,spawn.y)+.15,spawn.y);player.velocity=Vector3.ZERO
	session.call("set_playing",false)
	world.get_node("Terrain/Landscape/SiteGuides").visible=false
	var camera: Camera3D=world.get_node("MapCamera")
	camera.call("set_view",Vector2(175,321),138,31,-10)
	camera.far=480
	if "--capture" not in OS.get_cmdline_user_args() and "--benchmark" not in OS.get_cmdline_user_args():
		print("COASTLINE_REVIEW_READY — Tab : explorer · L : littoral · B : Brindle");return
	world.get_node("MapInfo").visible=false
	var out: String=ProjectSettings.globalize_path("user://previews/coastline/")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=").trim_suffix("/")+"/"
	DirAccess.make_dir_recursive_absolute(out)
	if "--benchmark" in OS.get_cmdline_user_args():
		await benchmark(world,camera,out)
		quit();return
	for view: Array in [["01-falaises-sud-brindle",175,321,138,31,-10],["02-cote-sud",30,305,350,43,0],["03-cote-ouest",-315,20,330,38,-90],["04-estuaire",-240,270,140,38,-45],["05-crique-brindle",84,310,100,43,-12],["06-nord-ouest",-304,-283,175,42,-75],["07-crique-levant",290,309,74,35,-28]]:
		camera.call("set_view",Vector2(view[1],view[2]),view[3],view[4],view[5]);camera.far=maxf(300,view[3]*3.2)
		for i: int in 35:await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(out+view[0]+".png")==OK)
	print("COASTLINE_CAPTURE_OK ",out);quit()

func benchmark(world: Node3D,camera: Camera3D,out: String) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	var dressing: Node3D=world.get_node("CoastlineDecor")
	var report: Dictionary={"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"viewport":root.size,"samples_per_pass":180,"scope":"Same continuous coast terrain; rock dressing and outer sea backdrop visible/hidden. Other editor windows may remain open.","passes":[]}
	for view: Array in [["south",175,321,138,31,-10],["cove",84,310,100,43,-12],["west",-315,20,200,38,-90]]:
		camera.call("set_view",Vector2(view[1],view[2]),view[3],view[4],view[5])
		for active: bool in [true,false,true,false]:
			dressing.visible=active
			for i: int in 60:await process_frame
			var frame_ms: Array[float]=[];var gpu_ms: Array[float]=[]
			for i: int in 180:
				var start: int=Time.get_ticks_usec()
				await RenderingServer.frame_post_draw
				await process_frame
				frame_ms.append((Time.get_ticks_usec()-start)/1000.0)
				gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
			frame_ms.sort();gpu_ms.sort()
			report.passes.append({"view":view[0],"rocks":active,"median_frame_ms":snappedf(frame_ms[90],.001),"p95_frame_ms":snappedf(frame_ms[171],.001),"median_gpu_ms":snappedf(gpu_ms[90],.001),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
	FileAccess.open(out+"performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("COASTLINE_BENCHMARK ",JSON.stringify(report))
