extends SceneTree
## Actual rendered views and warmed, uncapped A/B frame timings on this machine.
func _initialize() -> void:call_deferred("run")

func run() -> void:
	var session: Node3D = (load("res://scenes/test_brindle.tscn") as PackedScene).instantiate()
	root.add_child(session)
	for i: int in 45:await process_frame
	var world: Node3D = session.get_node("World")
	var atmosphere: Node3D = world.get_node("FarmingAtmosphere")
	var player: CharacterBody3D = world.get_node("Characters/Player")
	var ground: Node3D = world.get_node("Terrain")
	var settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://planning/farming-lighting.json"))
	var spawn_xz: Array = settings.review_spawn_xz
	player.position = Vector3(spawn_xz[0], ground.call("surface_height_at_world", spawn_xz[0], spawn_xz[1]) + .12, spawn_xz[1])
	player.velocity = Vector3.ZERO
	session.call("set_playing",false)
	world.get_node("Terrain/Landscape/SiteGuides").visible = false
	var camera: Camera3D = world.get_node("MapCamera")
	if "--capture" not in OS.get_cmdline_user_args() and "--benchmark" not in OS.get_cmdline_user_args():
		camera.call("set_view", Vector2(-124, 91), 27.0, 31.0, 95.0)
		atmosphere.call("refresh", true)
		print("FARM_ATMOSPHERE_REVIEW_READY — Tab : explorer · V : village")
		return
	world.get_node("MapInfo").visible = false
	var out: String = ProjectSettings.globalize_path("user://previews/farm-lighting/")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=").trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(out)
	if "--capture" in OS.get_cmdline_user_args():
		for view: Array in [
			["01-place-doree",-174,34,48,40,-22],
			["02-verger-rayons",-124,91,27,31,95],
			["03-feuilles-verger",-121,92,16,28,95],
			["04-moulin-matin",-208,36,40,38,-35],
			["05-village-lumiere",-177,38,146,49,-22]
		]:
			camera.call("set_view",Vector2(view[1],view[2]),view[3],view[4],view[5])
			atmosphere.call("refresh",true)
			for i: int in 100:await process_frame
			# Warm leaf lifetimes in real time even on very fast rendering hardware.
			await create_timer(3.0).timeout
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png(out+view[0]+".png")==OK)
		print("FARM_ATMOSPHERE_CAPTURE_OK ", out)
	if "--benchmark" in OS.get_cmdline_user_args():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
		camera.call("set_view",Vector2(-124,91),24,38,128)
		RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
		var report: Dictionary = {"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"viewport":root.size,"samples_per_pass":240,"passes":[]}
		for view: Array in [["orchard",-124,91,24,38,95],["square",-174,34,48,40,-22],["village",-177,38,146,49,-22]]:
			camera.call("set_view",Vector2(view[1],view[2]),view[3],view[4],view[5])
			for active: bool in [true,false,true,false]:
				atmosphere.enabled = active
				atmosphere.call("refresh",true)
				for i: int in 90:await process_frame
				var times: Array[float] = []
				var gpu_times: Array[float] = []
				var cpu_times: Array[float] = []
				for i: int in 240:
					var start: int = Time.get_ticks_usec()
					await RenderingServer.frame_post_draw
					await process_frame
					times.append((Time.get_ticks_usec()-start)/1000.0)
					gpu_times.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
					cpu_times.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()) + RenderingServer.get_frame_setup_time_cpu())
				times.sort();gpu_times.sort();cpu_times.sort()
				report.passes.append({"view":view[0],"atmosphere":active,"median_frame_ms":snappedf(times[120],.001),"p95_frame_ms":snappedf(times[228],.001),"median_gpu_ms":snappedf(gpu_times[120],.001),"median_render_cpu_ms":snappedf(cpu_times[120],.001),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
		var file: FileAccess = FileAccess.open(out+"performance.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"  "))
		print("FARM_ATMOSPHERE_BENCHMARK ",JSON.stringify(report))
	quit()
