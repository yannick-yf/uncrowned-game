extends SceneTree
## Open the actual workshop preview at the new town without changing the usual spawn.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var session: Node3D=(load("res://scenes/test_brindle.tscn") as PackedScene).instantiate();root.add_child(session)
	for i: int in 40:await process_frame
	var world: Node3D=session.get_node("World")
	var player: CharacterBody3D=world.get_node("Characters/Player")
	var ground: Node3D=world.get_node("Terrain")
	player.position=Vector3(218,float(ground.call("height_at_world",218,27))+.12,27);player.velocity=Vector3.ZERO
	for i: int in 12:await physics_frame
	session.call("set_playing",false)
	world.get_node("MapCamera").call("set_view",Vector2(218,27),74,42,-18)
	ground.call("toggle_guides")
	world.get_node("Decor/MineAcierie/RepereMine").visible=false
	print("IRONWORKS_REVIEW_READY")
