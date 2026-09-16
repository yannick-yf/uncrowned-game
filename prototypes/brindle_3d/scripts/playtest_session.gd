extends Node3D
## The playable preview wraps the editable map without changing its scene.
var playing := true
@onready var world: Node3D = $World
@onready var player: CharacterBody3D = $World/Characters/Player
@onready var player_camera: Camera3D = $World/PlayerCamera
@onready var map_camera: Camera3D = $World/MapCamera
@onready var ground: Node3D = $World/Terrain
@onready var controls: Label = $World/MapInfo/Controls
@onready var dimensions: Label = $World/MapInfo/Dimensions

func _ready() -> void:
	ground.connect("rebuilt", _ground_rebuilt)
	set_playing(true)

func _ground_rebuilt() -> void:
	_set_guides(not playing)
	_update_hud()
	if playing:
		player_camera.call("snap_to_target")

func set_playing(value: bool) -> void:
	playing = value
	player.set("controls_enabled", playing)
	map_camera.set_process(not playing)
	map_camera.set_process_unhandled_input(not playing)
	player_camera.set_process(playing)
	player_camera.set_process_unhandled_input(playing)
	if playing:
		player_camera.make_current()
		player_camera.call("snap_to_target")
	else:
		map_camera.make_current()
		map_camera.call("set_view", Vector2(player.position.x, player.position.z), 90.0, 49.0, -12.0)
	_set_guides(not playing)
	_update_hud()

func _set_guides(visible_now: bool) -> void:
	var guides := ground.get_node_or_null("Landscape/SiteGuides") as Node3D
	if guides != null:
		guides.visible = visible_now
	var mine_label := world.get_node_or_null("Decor/MineAcierie/RepereMine") as Node3D
	if mine_label != null:
		mine_label.visible = visible_now

func _update_hud() -> void:
	if playing:
		dimensions.text = "UNCROWNED  /  ESSAI DU PERSONNAGE\nExploration de la carte"
		controls.text = "ZQSD / WASD / flèches : marcher · Molette : zoom · Clic central : tourner · R : retour à Brindle · Tab : vue libre"
	else:
		dimensions.text = "UNCROWNED  /  ATELIER DE CARTE\n%.0f × %.0f m · Vue libre" % [ground.get("width_m"), ground.get("depth_m")]
		controls.text = "ZQSD / clic droit : déplacer · Molette : zoom · Clic central : tourner · B : Brindle · I : aciérie · T : scierie · C : ville/château · M : mine · P : pont suivant · R : ensemble · Tab : jouer"

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			set_playing(not playing)
			get_viewport().set_input_as_handled()
		elif playing and event.keycode == KEY_G:
			ground.call("toggle_guides")
			get_viewport().set_input_as_handled()
