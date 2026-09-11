extends Node2D

## The window. It reads the simulation and draws it.
##
## Everything that decides anything lives in core/. This file does three things:
## turn key state into submitted events, drive the clock by calling Sim.advance(),
## and draw what the world currently is. It never writes to core/ and it holds no
## game state — the interpolation cache below is render-only, and throwing it away
## would cost one frame of smoothing and nothing else.
##
## _process() here is not game logic. It is the crank.

const TILE: int = Art.TILE
const FIGURE: float = 16.0
## Interpolating across a respawn or a zone change would streak the player over
## the whole map for a frame.
const TELEPORT_TILES: float = 2.0

## Somewhere you cannot enter should still say what it is.
const ZONE_NAMES: Dictionary = {
	&"brindle": "Brindle",
	&"cinderworks": "the Cinderworks",
	&"harrowgate": "Harrowgate",
	&"wide_acres": "the Wide Acres",
	&"muster": "the Muster — an army camp, not a town",
	&"saltmarch": "Saltmarch",
	&"cairnwell": "Cairnwell, the capital",
	&"blackcairn": "Blackcairn",
}

var _sim: Sim = null
var _world: WorldState = null
var _cast: Cast = null
var _art: Art = null

var _accumulator: float = 0.0
var _seconds_per_step: float = 1.0 / 60.0
var _held_dir: Vector2i = Vector2i.ZERO
var _real_seconds: float = 0.0
var _render_from: Vector2 = Vector2.ZERO
var _render_to: Vector2 = Vector2.ZERO

var _terrain_colours: PackedColorArray = PackedColorArray([
	Color(0.29, 0.38, 0.23),  # WILD      — open grass
	Color(0.55, 0.47, 0.33),  # ROAD      — drawn from the atlas, not this
	Color(0.35, 0.29, 0.27),  # RUINS
	Color(0.29, 0.27, 0.36),  # CASTLE
	Color(0.11, 0.17, 0.28),  # SEA
	Color(0.22, 0.21, 0.24),  # MOUNTAIN
	Color(0.45, 0.40, 0.29),  # TOWN
	Color(0.42, 0.39, 0.36),  # WALL
	Color(0.38, 0.31, 0.24),  # CAMP
	Color(0.16, 0.31, 0.45),  # WATER     — the Kettle
	Color(0.36, 0.44, 0.47),  # FORD
	Color(0.15, 0.25, 0.16),  # FOREST    — the Thornwood
	Color(0.27, 0.31, 0.26),  # MARSH
	Color(0.47, 0.45, 0.24),  # FARMLAND
	Color(0.68, 0.62, 0.44),  # SAND
])
@onready var _info: Label = $HUD/Info
@onready var _box: ColorRect = $HUD/DialogueBox
@onready var _speaker: Label = $HUD/DialogueBox/Speaker
@onready var _line: Label = $HUD/DialogueBox/Line
@onready var _choices: Label = $HUD/DialogueBox/Choices
@onready var _prompt: Label = $HUD/Prompt


## Wiring, not logic: one call into core/, then cache what is read every frame.
func _ready() -> void:
	_art = Art.new()
	_seconds_per_step = Game.seconds_per_step()
	_sim = Game.build()
	_world = _sim.store(&"world") as WorldState
	_cast = _sim.store(&"cast") as Cast
	_render_from = _world.player_pos
	_render_to = _world.player_pos


func _process(delta: float) -> void:
	_real_seconds += delta
	_read_input()

	_accumulator += delta
	while _accumulator >= _seconds_per_step:
		_accumulator -= _seconds_per_step
		_render_from = _world.player_pos
		_sim.advance(1)
		_render_to = _world.player_pos

	position = (get_viewport_rect().size * 0.5 - _draw_position() * float(TILE)).round()
	queue_redraw()
	_draw_hud()


# ------------------------------------------------------------------- input ---

func _read_input() -> void:
	if _world.in_dialogue():
		if _held_dir != Vector2i.ZERO:
			_held_dir = Vector2i.ZERO
			_sim.submit(&"move_intent", {"x": 0, "y": 0})
		for index: int in _world.options.size():
			if Input.is_action_just_pressed(StringName("option_%d" % (index + 1))):
				_sim.submit(&"choose_intent", {"intent": String(_world.options[index].intent)})
		if Input.is_action_just_pressed(StringName("option_%d" % _exit_slot())) \
				or Input.is_action_just_pressed(&"interact") \
				or Input.is_action_just_pressed(&"back"):
			_sim.submit(&"end_talk")
		return

	var dir: Vector2i = _read_direction()
	if dir != _held_dir:
		_held_dir = dir
		_sim.submit(&"move_intent", {"x": dir.x, "y": dir.y})

	if Input.is_action_just_pressed(&"interact"):
		var npc: Npc = _nearby_npc()
		if npc != null:
			_sim.submit(&"talk", {"npc": String(npc.id)})
		elif _can_expose():
			_sim.submit(&"expose_fraud")


## The slot that leaves the conversation. One function, used by both the keybind
## and the line the dialogue box prints, because the first version computed it in
## two places: the box offered "4. (say nothing and go)" and nothing was bound to
## 4, so the only way out was a key the game never mentioned.
func _exit_slot() -> int:
	return mini(_world.options.size() + 1, DialogueRules.MAX_OPTIONS)


func _read_direction() -> Vector2i:
	var dir := Vector2i.ZERO
	if Input.is_action_pressed(&"move_right"):
		dir.x += 1
	if Input.is_action_pressed(&"move_left"):
		dir.x -= 1
	if Input.is_action_pressed(&"move_down"):
		dir.y += 1
	if Input.is_action_pressed(&"move_up"):
		dir.y -= 1
	return dir


func _nearby_npc() -> Npc:
	return _cast.nearest_to(_world.current_zone, _world.player_pos, Game.TALK_REACH)


## Asking the rules layer a question. Reading a pure predicate is not mutating.
func _can_expose() -> bool:
	if _world.current_zone != WorldState.OVERWORLD:
		return false
	var in_muster: bool = _world.region().is_in_muster(_world.player_tile())
	return ArmyRules.can_expose(in_muster, _world.pay_fraud_exposed, _sim.facts)


# ----------------------------------------------------------------- drawing ---

func _draw_position() -> Vector2:
	if _render_from.distance_to(_render_to) > TELEPORT_TILES:
		return _render_to
	var t: float = clampf(_accumulator / _seconds_per_step, 0.0, 1.0)
	return _render_from.lerp(_render_to, t)


func _draw() -> void:
	if _world == null:
		return
	var region: Region = _world.region()
	var centre: Vector2 = _draw_position()
	var half: Vector2 = get_viewport_rect().size * 0.5 / float(TILE)
	var min_x: int = maxi(floori(centre.x - half.x) - 1, 0)
	var max_x: int = mini(ceili(centre.x + half.x) + 1, region.width - 1)
	var min_y: int = maxi(floori(centre.y - half.y) - 2, 0)
	var max_y: int = mini(ceili(centre.y + half.y) + 1, region.height - 1)

	# Ground first, then everything that stands on it, so a tree drawn at the top
	# of one tile overlaps the tile behind it rather than being clipped by it.
	for x: int in range(min_x, max_x + 1):
		for y: int in range(min_y, max_y + 1):
			_draw_ground(region, x, y)

	for x: int in range(min_x, max_x + 1):
		for y: int in range(min_y, max_y + 1):
			_draw_scatter(region, x, y)

	for prop: Dictionary in region.props:
		_draw_prop(prop, min_x, max_x, min_y, max_y)

	for npc: Npc in _cast.in_zone(_world.current_zone):
		_draw_actor(npc.centre(), npc.id, Art.FACE_DOWN)

	if _world.current_zone == WorldState.OVERWORLD:
		_draw_escort()
		_draw_actor(_world.king_pos, &"king", Art.FACE_DOWN)

	_draw_actor(centre, &"player", Art.column_for(_world.player_facing))


func _draw_ground(region: Region, x: int, y: int) -> void:
	var dest := Rect2(float(x * TILE), float(y * TILE), float(TILE), float(TILE))
	var terrain: int = region.terrain_at(Vector2i(x, y))

	var entry: Array = _art.terrain_tiles.get(terrain, []) as Array
	if entry.is_empty():
		draw_rect(dest, _terrain_colours[terrain], true)
		return

	var column: int = entry[1] as int
	var row: int = entry[2] as int
	# Break up the flat fills so ground does not read as graph paper.
	if terrain == Region.Terrain.WILD or terrain == Region.Terrain.FOREST:
		if Art.scatter_hash(x + 7, y + 3) < 90:
			column = 15
	elif terrain == Region.Terrain.FARMLAND:
		# Crop rows, which is what tells a field from a lawn at a glance.
		row = 4 if (y / 2) % 2 == 0 else 1
	draw_texture_rect_region(
		_art.atlas(entry[0] as StringName), dest, Art.tile_rect(column, row))


func _draw_scatter(region: Region, x: int, y: int) -> void:
	var entry: Array = _art.scatter_at(region.terrain_at(Vector2i(x, y)), x, y)
	if entry.is_empty():
		return
	var source: Rect2i = entry[1] as Rect2i
	# Anchored by the foot, not the corner, so a tree stands on its tile.
	var at := Vector2(
		float(x * TILE) + float(TILE) * 0.5 - float(source.size.x) * 0.5,
		float((y + 1) * TILE) - float(source.size.y),
	)
	draw_texture_rect_region(
		_art.atlas(entry[0] as StringName),
		Rect2(at.round(), Vector2(source.size)),
		Rect2(source))


func _draw_prop(prop: Dictionary, min_x: int, max_x: int, min_y: int, max_y: int) -> void:
	var at: Vector2i = prop["at"] as Vector2i
	var size: Vector2i = prop.get("size", Vector2i(4, 3)) as Vector2i
	if at.x > max_x or at.y > max_y or at.x + size.x < min_x or at.y + size.y < min_y:
		return
	var entry: Array = _art.props.get(prop["kind"] as StringName, []) as Array
	if entry.is_empty():
		return
	var source: Rect2i = entry[1] as Rect2i
	# Footed on the bottom of its footprint and centred across it, so a tall
	# building overhangs the tiles behind rather than floating above them.
	var dest := Vector2(
		float(at.x * TILE) + float(size.x * TILE) * 0.5 - float(source.size.x) * 0.5,
		float((at.y + size.y) * TILE) - float(source.size.y),
	)
	draw_texture_rect_region(
		_art.atlas(entry[0] as StringName),
		Rect2(dest.round(), Vector2(source.size)),
		Rect2(source))


func _draw_actor(at: Vector2, role: StringName, column: int) -> void:
	var sheet: Texture2D = _art.sheet_for(role)
	if sheet == null:
		return
	var top_left: Vector2 = at * float(TILE) - Vector2(FIGURE, FIGURE) * 0.5
	draw_texture_rect_region(
		sheet,
		Rect2(top_left.round(), Vector2(FIGURE, FIGURE)),
		Art.tile_rect(column, 0),
	)


## The escort, drawn because it has to be *seen* to drop. Ten bodies in two ranks
## in front of the gate; five after the Muster empties.
func _draw_escort() -> void:
	for i: int in _world.king_escort:
		var rank: int = i / 5
		var file: int = i % 5
		var at: Vector2 = _world.king_pos + Vector2(float(file) - 2.0, 2.0 + float(rank) * 1.2)
		_draw_actor(at, &"guard", Art.FACE_DOWN)


# --------------------------------------------------------------------- hud ---

## Somewhere you cannot enter should still say what it is. The Muster is a camp on
## the road, not a town, and looking identical to Harrowgate's gate while refusing
## to open is the kind of thing a player reasonably reads as broken.
func _place_name() -> String:
	if _world.current_zone == &"harrowgate":
		return "Harrowgate"
	var zone: StringName = _world.region().zone_at(_world.player_tile())
	if ZONE_NAMES.has(zone):
		return String(ZONE_NAMES[zone])
	match _world.region().terrain_at(_world.player_tile()):
		Region.Terrain.ROAD:
			return "the King's Road"
		Region.Terrain.FORD:
			return "the ford"
		Region.Terrain.FOREST:
			return "the Thornwood"
		Region.Terrain.MARSH:
			return "the marshes"
		Region.Terrain.FARMLAND:
			return "the Wide Acres"
		Region.Terrain.SAND:
			return "the coast"
	return "the wild"


func _draw_hud() -> void:
	var walked: int = int(_real_seconds)
	var where: String = _place_name()
	var lines: Array[String] = [
		"%s   ·   HP %d/%d   ·   deaths %d" % [
			where, _world.player_hp, WorldState.MAX_HP, _world.deaths,
		],
		"the king's escort: %d" % _world.king_escort,
	]
	if _world.current_zone == WorldState.OVERWORLD:
		lines.append("%d tiles to Blackcairn" % int(round(_world.tiles_to_blackcairn())))
	lines.append("%s   ·   walked %d:%02d" % [Game.in_game_clock(_sim.tick), walked / 60, walked % 60])
	_info.text = "\n".join(lines)

	_box.visible = _world.in_dialogue()
	if _world.in_dialogue():
		_speaker.text = _world.speaker_name
		_line.text = _world.current_line
		var rows: Array[String] = []
		for index: int in _world.options.size():
			rows.append("%d. %s" % [index + 1, _world.options[index].label()])
		rows.append("%d. (say nothing and go)     — or E, or Esc" % _exit_slot())
		_choices.text = "\n".join(rows)
		_prompt.text = ""
		return

	var rows: Array[String] = []
	var mood: String = _atmosphere()
	if mood != "":
		rows.append(mood)

	var npc: Npc = _nearby_npc()
	if npc != null:
		rows.append("E — speak to %s, %s" % [npc.display_name, npc.role.to_lower()])
	elif _can_expose():
		rows.append("E — say what you know")
	_prompt.text = "\n".join(rows)


## What a place looks like, which is not the same as what to do about it.
##
## The line below reads as scenery if you know nothing and as confirmation if
## Ossa has already told you, and it is the same line either way — the world
## shows, people explain. It must never become an instruction: the moment the
## camp tells the player to expose the fraud, the fact stops being something
## found from a person who was there, which is the thread §6 hangs on.
##
## Authored here rather than in content/ because it is one line. The second or
## third of these earns a file.
func _atmosphere() -> String:
	if _world.current_zone != WorldState.OVERWORLD:
		return ""
	if not _world.region().is_in_muster(_world.player_tile()):
		return ""
	if _world.pay_fraud_exposed:
		return "half the tents are down, and nobody is striking the rest"
	return "the pay tent has a queue and no money in it"
