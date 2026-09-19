class_name World3d
extends Node3D

## The 3D window over the baked world (MIGRATION_3D §6, M2–M3).
##
## A **window, not a world**: it reads the simulation and places things. The ground,
## the water, the woods, the ruins and every building his library holds are **his** —
## the workshop's scenes, loaded from the generated copy under `view3d/workshop/`.
## **Nothing of the 2D game's art appears here** (Yannick, 2026-09-14): where his
## library has no piece yet, a plain block of the footprint's size stands in his rock
## paint, visibly provisional; every person is his own traveller sprite until he draws
## the cast; the brief's woods and the simulation's roads are not drawn at all — they
## are his to plant and to lay, and the bake's report names them. Without the copy the
## window builds the bake's ground itself, coloured by terrain and by nothing else.
##
## Nothing here moves anybody: the player's position arrives from `main.gd` every
## frame, already interpolated, and goes nowhere but into a transform.
##
## Coordinates are BakeRules' contract: his metres, origin at the centre, north at
## -Z; a tile's centre is `origin + (tile + 0.5) * 2 m`, and a height comes from his
## terrain once it stands, or from his grid bilinearly before that.

## His camera, in numbers: orthographic, tilted, following. The numbers are the
## workshop's `follow_camera` as the Brindle scene sets it.
const TILT_DEGREES: float = 48.0
const AZIMUTH_DEGREES: float = 0.0
## **Where the lens goes for a fight** (F3, 2026-09-19; `SPECS.md` §10 as rewritten).
## Nearly side-on and tight enough that two people fill the frame. **The azimuth is not
## here and never will be**: the traveller's four facings are keyed to the world's axes,
## so a camera that turned would draw every fighter looking the wrong way, and the fix
## for that is eight drawn rotations per character — the largest art request in the
## project. Because it never turns, a fight runs east-west and uses the `left` and
## `right` frames his brother has already made.
const FIGHT_TILT_DEGREES: float = 27.0
## How far a fighter leans and lunges, in tiles, so a blow can be seen coming. A tile is
## two metres, so this is about forty-five centimetres at full thrust. **A placeholder
## and visibly one**: `traveler_walk_frames.tres` holds idle and walk in four directions
## and nothing else, so until his brother draws an attack and a guard the only honest
## tell is the figure he did draw, moved. The timing of it is `CombatRules.lunge_at`.
const FIGHT_LUNGE_TILES: float = 0.30
## And how far he sinks, in metres. A blow is a gather and a release, and the gather is
## the half of it a person reads first.
##
## **Deliberately small.** A single sprite has no knees: lower it far and it reads as a
## figure sinking into the ground rather than one bending. Thirty centimetres looked like
## sinking in a photograph, so it is fifteen. Up and down only, never a squash — a pixel
## figure stretched to sell a movement stops being pixel art.
const FIGHT_DIP_M: float = 0.15
const FIGHT_SIZE_M: float = 7.0
const CAMERA_SIZE: float = 24.0
const CAMERA_DISTANCE: float = 45.0
## The same easing as the 2D camera, so the two windows feel alike.
const CAMERA_CATCHES_UP: float = 7.0
## A billboard's feet, just off the ground so they never z-fight with it.
const FOOT_CLEARANCE: float = 0.04
## Terrain is built in chunks of this many cells a side (the fallback ground only).
const CHUNK_CELLS: int = 48
## A film of water thinner than this is a wet bank, not water.
const WATER_SHOWS_FROM: float = 0.02
## The escort's ranks in front of the gate, as the 2D window draws them.
const ESCORT_FILES: int = 5

## His world, once the workshop has been vendored (`tools/vendor_workshop.sh`): the
## map plate — his terrain and water with their shaders, the relief stamps, his
## Brindle, his forests, the mine and the bridge, his sun and sky — minus his map
## camera and its labels. Nothing of his is edited: it is a copy with its paths
## repointed.
const HIS_MAP: String = "res://view3d/workshop/scenes/map_plate.tscn"
const HIS_LIBRARY: String = "res://view3d/workshop/prototype_3d/assets/library/"
## His traveller: the one person he has drawn, and so, until the cast is drawn in his
## style, everyone — the player, the twenty-five, the strangers, the crowd, the guards,
## the traffic. His frames, his material, his pixel size (a 197-pixel frame stands
## 1.53 m), his billboard trick. §13's *nobody shares a face* is a debt he settles.
const HIS_FRAMES: String = "res://view3d/workshop/prototype_3d/assets/traveler_walk_frames.tres"
## **Ours, and it says so.** Six frames of his traveller fighting, built from his own
## pixels by `tools/draw_fight_frames.gd` because he has drawn no attack and no guard.
## Yannick's call on 2026-09-19, over the art rule and knowing a second hand would show;
## the reasoning is in that tool's header and in `docs/POUR_SLOSINIO.md` §8. The day his
## sheet grows an `attack_left` of its own, delete this and the tool with it.
const OUR_FIGHT_FRAMES: String = "res://view3d/fight/traveler_sheet.png"
const OUR_CELL: Vector2i = Vector2i(160, 200)
const OUR_POSES: Array[StringName] = [&"attack", &"guard", &"hurt"]
const OUR_WAYS: Array[StringName] = [&"right", &"left"]
const HIS_FIGURE_MATERIAL: String = "res://view3d/workshop/prototype_3d/materials/traveler_sprite.tres"
const HIS_FIGURE_PIXEL_SIZE: float = 0.0077832513
const FIGURE_HEIGHT_M: float = 1.55
## His walk cycle turns over every three metres, as his `player_walk_animation` does.
const WALK_CYCLE_M: float = 3.0
## A placeholder block wears his rock paint, so even what is not drawn is in his hand.
const HIS_BLOCK_MATERIAL: String = "res://view3d/workshop/prototype_3d/materials/styled_rock.tres"

## Our kit, drawn with his library where a kind fits: a cottage for a house, the
## storehouse for a barn, his well, his barrels, his fence. The table is the brief's
## `kit_library` — the bake opens the walls round such a piece to the piece's own size
## from the same table, so the two never disagree — and he can change a match in a line.
const BRIEF: String = "res://content/bake_brief.json"
## The pieces a place stops putting out once it falls below the threshold (P3). The
## list is `content/towns.json`'s and **belongs to his brother**: art direction, one
## line to change, no code. Two rules this file enforces whatever the list says —
## nothing is hidden off a tile the player could not already walk on, so no invisible
## thing is ever left blocking the way; and a building is never in the list, because a
## place that has stopped is empty rather than demolished.
const TOWNS: String = "res://content/towns.json"
## Walls the simulation has and his map does not show yet — the castle's ramparts —
## stand as blocks this tall, so a wall you cannot pass is a wall you can see.
const WALL_HEIGHT_M: float = 3.0
## **The light a place stands in** (M3, 2026-09-18). Allégeance's half of the four
## appearances: warm where the king is supported, cold where he is not.
##
## **A tint over his light, never a replacement.** The sun and the sky are his — his
## map plate carries them — so these multiply what he chose, and their midpoint is
## exactly white. A place with no opinion, and the wild, therefore look precisely as he
## drew them, and what the window adds is a lean rather than a look of its own.
const TINT_LOYAL: Color = Color(1.10, 1.02, 0.90)
const TINT_HOSTILE: Color = Color(0.90, 0.98, 1.10)
const ENERGY_LOYAL: float = 1.08
const ENERGY_HOSTILE: float = 0.92
## How fast the light settles when the player walks in or out of a place. Eased rather
## than switched: a hard flip at a zone's edge reads as a bug rather than as a mood.
const LIGHT_SETTLES: float = 1.6

## The lens zooms as his camera does: size in metres, two at a time, between his limits.
const ZOOM_MIN: float = 14.0
const ZOOM_MAX: float = 48.0
const ZOOM_STEP: float = 2.0
## Small things are turned a quarter at a time by their tile, so a row of barrels is
## not a row of identical barrels; buildings keep his facing.
const TURNED_BY_TILE: Array[StringName] = [&"barrels", &"crates", &"logs", &"overgrowth"]
## How tall a placeholder block is, by kind, in metres. What his library lacks stands
## as a block of its footprint and roughly its height, until he draws it.
const BLOCK_HEIGHT: Dictionary = {
	&"kiln": 3.0, &"tent": 2.4, &"tent_b": 2.4, &"boat": 1.2, &"counting_house": 6.0,
	&"keep": 10.0, &"tower": 8.0, &"gatehouse": 5.0, &"muster_rolls": 1.5, &"stall": 1.2,
	&"campfire": 0.5, &"papers": 0.3, &"ruin_house": 2.5, &"produce": 0.8, &"oven": 1.6,
}
const BLOCK_HEIGHT_DEFAULT: float = 3.5

var _bridge_decks: Array[Dictionary] = []
## His delivered heat, **grouped by the piece it belongs to**, so a works can have
## some furnaces burning and some cold rather than all or nothing. Each row is
## {place, index, nodes, coals}; `index` is the furnace's place in its works, or -1
## for heat that is not a furnace.
var _workshop_heat: Array[Dictionary] = []
## Furnace tile -> its index in its own works, and how many each works has. Built once
## with the embers, and read by his delivered effects, so the two never disagree about
## which furnace is the third one.
var _kiln_index: Dictionary = {}
var _kilns_in: Dictionary = {}

var _region: Region = null
var _sim: Sim = null
var _art: Art = null
var _heights: PackedFloat32Array = PackedFloat32Array()
var _waters: PackedFloat32Array = PackedFloat32Array()
var _paint: PackedFloat32Array = PackedFloat32Array()
var _samples: int = 0
var _origin_m: Vector2 = Vector2.ZERO
var _metres_per_tile: float = BakeRules.METRES_PER_TILE

var _camera: Camera3D = null
## The camera's own up, in world space. Fixed, because the camera's tilt and azimuth
## are; billboards are lifted along it so their feet stay on the ground however the
## sprite leans toward the lens — the workshop's `sprite_billboard.gd` trick.
var _lens_up: Vector3 = Vector3.UP
## The tilt the lens returns to when nobody is fighting — his 48°, or whatever
## `UNCROWNED_LENS` asked for, so the debug tool still wins.
var _rest_tilt: float = TILT_DEGREES
## The opponent's walk cycle, kept the same way the player's is. One fight at a time,
## so one phase.
var _foe_last: Vector3 = Vector3.ZERO
var _foe_placed: bool = false
var _foe_phase: float = 0.0
var _lens_offset: Vector3 = Vector3.UP
var _focus: Vector3 = Vector3.ZERO
var _focus_placed: bool = false

## His world, when vendored; his terrain node, whose heights his relief stamps have
## shaped; his frames and materials, when the copy has them.
var _his: Node3D = null
var _his_terrain: Node3D = null
var _his_pieces: Dictionary = {}
var _kit_library: Dictionary = {}
var _frames: SpriteFrames = null
var _figure_material: Material = null
var _block_material: Material = null
var _zoom: float = CAMERA_SIZE

var _player: Node3D = null
var _player_last: Vector3 = Vector3.ZERO
var _player_placed: bool = false
var _walk_phase: float = 0.0
var _people: Dictionary = {}
var _traffic: Dictionary = {}
## The people of a place walking to work (P1), by their id. Drawn exactly as the road's
## travellers are, because that is what they are: furniture that moves.
var _folk: Dictionary = {}
var _guards: Array[Node3D] = []
var _sun: DirectionalLight3D = null
var _air: Environment = null
var _sun_base: Color = Color.WHITE
var _sun_energy_base: float = 1.0
var _air_base: Color = Color.WHITE
## The first frame lands on its light rather than fading into it: walking into a game
## already standing in a town that has turned should look that way at once. The same
## rule the camera and the player already follow in this file.
var _warmth_placed: bool = false
## Prop kind -> true, from the file. And every piece that can go, with the place it
## stands in: his, found in his scene by its id, and ours, found in `_props`.
var _poverty: Dictionary = {}
var _fading: Array[Dictionary] = []
## 0 is a place that has turned against the king, 1 is one that has not, and 0.5 is
## anywhere with no opinion — the wild, or a place outside the system.
var _warmth: float = 0.5
## One entry per prop of the region: the prop, the node standing for it, and how far
## above its feet the node's origin sits.
var _props: Array[Dictionary] = []
var _fairy: OmniLight3D = null
var _fairy_glow: Sprite3D = null
## The marks over the heads of whoever can see you, and the embers over fires and
## kilns — the 2D window's immediate register and its particles, in the window. Drawn
## with one soft disc made here, because the pack's art is not allowed in and his has
## no such thing yet.
var _marks: Array[Sprite3D] = []
var _embers: Array[Dictionary] = []
var _dot: Texture2D = null

var chunk_count: int = 0
var water_triangles: int = 0
var his_props_skipped: int = 0
var his_kit_count: int = 0
var block_count: int = 0
var wall_count: int = 0


# ------------------------------------------------------------------ building ---

## Everything that does not move: his world (or the bake's ground), the props, the
## lights and the camera. `landscape` is `RegionBake.read_landscape()`.
func build(region: Region, landscape: Dictionary, art: Art, sim: Sim) -> void:
	_region = region
	_art = art
	_sim = sim
	var meta: Dictionary = landscape.get("meta", {}) as Dictionary
	_samples = int(meta.get("grid_size", 0))
	var extent: float = float(meta.get("extent_m", 0.0))
	_heights = landscape.get("heights", PackedFloat32Array()) as PackedFloat32Array
	_waters = landscape.get("waters", PackedFloat32Array()) as PackedFloat32Array
	_paint = landscape.get("paint", PackedFloat32Array()) as PackedFloat32Array
	if _samples >= 2 and extent > 0.0:
		_metres_per_tile = extent / float(_samples - 1)
		_origin_m = Vector2(-extent * 0.5, -extent * 0.5)
	_build_camera()
	_load_poverty()
	_load_his_materials()
	_adopt_his_world()
	if _his == null:
		_build_light()
		_build_ground()
		_build_water()
	_build_props()
	_build_walls()
	_build_fairy()
	_build_embers()


## Zoom, as his camera zooms: the same actions, the same limits, the same step.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"zoom_in"):
		_zoom = clampf(_zoom - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
	elif event.is_action_pressed(&"zoom_out"):
		_zoom = clampf(_zoom + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)


## `UNCROWNED_LENS=tilt,size` moves his camera for one frame, and for nothing else.
##
## **Not a feature and not the combat camera.** `docs/COMBAT.md` §1 asks whether a fight
## happens on a separate 2D screen or in place in his world, and that is Yannick's to
## settle — but it is a question about a *picture*, and the suite cannot draw. This is
## the same gate and the same reason as `UNCROWNED_FREE`: one frame, so the thing can be
## looked at instead of argued about.
##
##     UNCROWNED_LENS=27,10 tools/shot.sh /tmp/arene.png play 150,174
##
## **The azimuth is deliberately not offered.** His traveller has four facings keyed to
## the world's axes, so a turned camera draws every fighter looking the wrong way. Tilt
## and framing are free; the turn is the one that would cost him the largest piece of art
## in the project.
func _debug_lens() -> Vector2:
	if not OS.has_feature("debug"):
		return Vector2.ZERO
	var asked: String = OS.get_environment("UNCROWNED_LENS")
	if asked.is_empty():
		return Vector2.ZERO
	var parts: PackedStringArray = asked.split(",")
	if parts.size() != 2 or not parts[0].is_valid_float() or not parts[1].is_valid_float():
		push_warning("UNCROWNED_LENS wants tilt,size in degrees and metres: '%s'" % asked)
		return Vector2.ZERO
	return Vector2(parts[0].to_float(), parts[1].to_float())


func _build_camera() -> void:
	var lens: Vector2 = _debug_lens()
	_rest_tilt = lens.x if lens.x > 0.0 else TILT_DEGREES
	_aim_lens(0.0)
	_camera = Camera3D.new()
	_camera.name = "Lens"
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = lens.y if lens.y > 0.0 else CAMERA_SIZE
	_zoom = _camera.size
	_camera.near = 0.5
	_camera.far = 400.0
	_camera.current = true
	add_child(_camera)


## His frames for the figures and his paint for the blocks, when the copy has them;
## and the brief's table of which kinds his library stands for.
func _load_his_materials() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BRIEF))
	if parsed is Dictionary:
		_kit_library = (parsed as Dictionary).get("kit_library", {}) as Dictionary
	if ResourceLoader.exists(HIS_FRAMES):
		_frames = load(HIS_FRAMES) as SpriteFrames
	if ResourceLoader.exists(HIS_FIGURE_MATERIAL):
		_figure_material = load(HIS_FIGURE_MATERIAL) as Material
	# After both, because it re-points his frames *and* his material at one sheet.
	_add_our_fight_frames()
	if ResourceLoader.exists(HIS_BLOCK_MATERIAL):
		_block_material = load(HIS_BLOCK_MATERIAL) as Material


## His map plate as the world, with his lights and sky, minus his map camera and its
## labels. The copy under `view3d/workshop/` is his tree with its paths repointed.
## Adds `attack_*`, `guard_*` and `hurt_*` to a **copy** of his frames, so his own
## resource is never touched and a clone without our sheet simply has eight animations
## and the fight's lean to tell a blow by, as it did before.
##
## **Every one of his frames is re-pointed at the combined sheet too**, and that is not
## optional. His material hands the whole sheet to his shader as a uniform and the frames
## index into it by UV, so a frame whose atlas is one image and a uniform that is another
## do not agree: six frames of ours in their own file drew the entire file, shrunk, onto
## every fighter. One sheet, his pixels at their original coordinates, ours below.
func _add_our_fight_frames() -> void:
	if _frames == null or not ResourceLoader.exists(OUR_FIGHT_FRAMES):
		return
	var sheet: Texture2D = load(OUR_FIGHT_FRAMES) as Texture2D
	if sheet == null:
		return
	_frames = _frames.duplicate(true) as SpriteFrames
	for named: StringName in _frames.get_animation_names():
		for i: int in _frames.get_frame_count(named):
			var slice := _frames.get_frame_texture(named, i) as AtlasTexture
			if slice != null:
				slice.atlas = sheet
	var below: int = int(sheet.get_height()) - OUR_CELL.y * OUR_WAYS.size()
	for row: int in OUR_WAYS.size():
		for col: int in OUR_POSES.size():
			var named := StringName("%s_%s" % [OUR_POSES[col], OUR_WAYS[row]])
			if _frames.has_animation(named):
				continue
			_frames.add_animation(named)
			_frames.set_animation_loop(named, false)
			var slice := AtlasTexture.new()
			slice.atlas = sheet
			slice.region = Rect2(
				Vector2(col * OUR_CELL.x, below + row * OUR_CELL.y), Vector2(OUR_CELL))
			_frames.add_frame(named, slice)
	# And the shader has to be handed the same sheet, or it samples his and finds his
	# walk cycle where our fist should be.
	var paint := _figure_material as ShaderMaterial
	if paint != null:
		_figure_material = paint.duplicate(true)
		(_figure_material as ShaderMaterial).set_shader_parameter("sprite_sheet", sheet)


func _adopt_his_world() -> void:
	if not ResourceLoader.exists(HIS_MAP):
		push_warning("his scenes are not vendored at %s — showing the bake's ground; run tools/vendor_workshop.sh" % HIS_MAP)
		return
	var scene: PackedScene = load(HIS_MAP) as PackedScene
	if scene == null:
		return
	var world: Node3D = scene.instantiate() as Node3D
	if world == null:
		return
	for extra_name: String in ["MapCamera", "MapInfo"]:
		var extra: Node = world.get_node_or_null(extra_name)
		if extra != null:
			world.remove_child(extra)
			extra.free()
	world.name = "HisWorld"
	add_child(world)
	_his = world
	_read_bridge_decks()
	_read_workshop_heat()
	# His sun and his sky, to be leaned warm or cold by allégeance and by nothing else.
	_sun = world.get_node_or_null("Sun") as DirectionalLight3D
	var his_air := world.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if his_air != null:
		_air = his_air.environment
	_remember_light()
	# His site labels are editor guides — a forty-eight-point "Brindle" over the
	# ruins — and his playtest hides them the moment play starts. They are built when
	# his terrain rebuilds, a frame later, so they are hidden then; and everything
	# footed before that stood on the raw heights, so it is footed again.
	var terrain: Node = world.get_node_or_null("Terrain")
	if terrain != null and terrain.has_signal("rebuilt"):
		_his_terrain = terrain as Node3D
		terrain.connect("rebuilt", _hide_his_guides)
		terrain.connect("rebuilt", _refoot)


func _hide_his_guides() -> void:
	if _his == null:
		return
	for path: String in ["Terrain/Landscape/SiteGuides", "Decor/MineAcierie/RepereMine"]:
		var guide: Node3D = _his.get_node_or_null(path) as Node3D
		if guide != null:
			guide.visible = false


## Stand everything static on his ground again, now that his ground is built.
func _refoot() -> void:
	for entry: Dictionary in _props:
		_stand(entry)


func _build_light() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 1.1
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = false
	sun.transform = Transform3D(Basis.looking_at(Vector3(-0.5, -1.0, -0.35).normalized(), Vector3.UP), Vector3.ZERO)
	add_child(sun)
	_sun = sun
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.62, 0.72, 0.80)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.76, 0.80)
	environment.ambient_light_energy = 0.9
	var world_environment := WorldEnvironment.new()
	world_environment.name = "Air"
	world_environment.environment = environment
	add_child(world_environment)
	_air = environment
	_remember_light()


## The fallback ground, for a clone without his scenes: his heights as chunks of
## triangles, coloured by the *baked* terrain kind — the map screen's colours, no
## texture — shaded by his slope paint so a bank reads as a bank.
func _build_ground() -> void:
	if _samples < 2:
		return
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var ground := Node3D.new()
	ground.name = "Ground"
	add_child(ground)
	for z0: int in range(0, _samples - 1, CHUNK_CELLS):
		for x0: int in range(0, _samples - 1, CHUNK_CELLS):
			_build_chunk(ground, material, x0, z0, mini(x0 + CHUNK_CELLS, _samples - 1),
				mini(z0 + CHUNK_CELLS, _samples - 1))


func _build_chunk(parent: Node3D, material: Material, x0: int, z0: int, x1: int, z1: int) -> void:
	var columns: int = x1 - x0 + 1
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colours := PackedColorArray()
	var indices := PackedInt32Array()
	for z: int in range(z0, z1 + 1):
		for x: int in range(x0, x1 + 1):
			vertices.append(_sample_point(x, z))
			var along_x: Vector3 = _sample_point(mini(x + 1, _samples - 1), z) - _sample_point(maxi(0, x - 1), z)
			var along_z: Vector3 = _sample_point(x, mini(z + 1, _samples - 1)) - _sample_point(x, maxi(0, z - 1))
			normals.append(along_z.cross(along_x).normalized())
			colours.append(_ground_colour(x, z))
	for z: int in range(z1 - z0):
		for x: int in range(x1 - x0):
			var a: int = z * columns + x
			var b: int = a + 1
			var c: int = a + columns
			var d: int = c + 1
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
	var surface := MeshInstance3D.new()
	surface.name = "Chunk_%d_%d" % [x0, z0]
	surface.mesh = mesh
	parent.add_child(surface)
	chunk_count += 1


func _sample_point(x: int, z: int) -> Vector3:
	return Vector3(_origin_m.x + float(x) * _metres_per_tile, _heights[z * _samples + x],
		_origin_m.y + float(z) * _metres_per_tile)


func _ground_colour(x: int, z: int) -> Color:
	var tile := Vector2i(mini(x, _region.width - 1), mini(z, _region.height - 1))
	var kind: Region.Terrain = _region.terrain_at(tile)
	var colour: Color = _art.colour_for(kind)
	var p: int = (z * _samples + x) * 3
	var rock: float = _paint[p] if p < _paint.size() else 0.0
	var sand: float = _paint[p + 1] if p + 1 < _paint.size() else 0.0
	if kind == Region.Terrain.WILD or kind == Region.Terrain.MOUNTAIN or kind == Region.Terrain.SAND:
		colour = colour.lerp(Color(0.46, 0.45, 0.44), rock * 0.7)
		colour = colour.lerp(Color(0.72, 0.66, 0.48), sand * 0.6)
	if kind == Region.Terrain.WATER or kind == Region.Terrain.SEA:
		colour = colour.darkened(0.35)
	return colour


## The fallback water: a second surface at his water level, wherever it stands above
## the ground.
func _build_water() -> void:
	if _samples < 2 or _waters.size() != _heights.size():
		return
	var vertices := PackedVector3Array()
	var colours := PackedColorArray()
	var sea: Color = _art.colour_for(Region.Terrain.SEA)
	var river: Color = _art.colour_for(Region.Terrain.WATER)
	for z: int in _samples - 1:
		for x: int in _samples - 1:
			var i: int = z * _samples + x
			var depth: float = maxf(maxf(_waters[i] - _heights[i], _waters[i + 1] - _heights[i + 1]),
				maxf(_waters[i + _samples] - _heights[i + _samples], _waters[i + _samples + 1] - _heights[i + _samples + 1]))
			if depth <= WATER_SHOWS_FROM:
				continue
			var colour: Color = sea if _waters[i] <= BakeRules.SEA_LEVEL_BAND else river
			colour.a = 0.72
			var a: Vector3 = _water_point(x, z)
			var b: Vector3 = _water_point(x + 1, z)
			var c: Vector3 = _water_point(x, z + 1)
			var d: Vector3 = _water_point(x + 1, z + 1)
			for point: Vector3 in [a, c, b, b, c, d]:
				vertices.append(point)
				colours.append(colour)
	if vertices.is_empty():
		return
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colours
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.2
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, material)
	var water := MeshInstance3D.new()
	water.name = "Water"
	water.mesh = mesh
	add_child(water)
	water_triangles = vertices.size() / 3


func _water_point(x: int, z: int) -> Vector3:
	return Vector3(_origin_m.x + float(x) * _metres_per_tile, _waters[z * _samples + x],
		_origin_m.y + float(z) * _metres_per_tile)


# -------------------------------------------------------------------- props ---

## Every prop the region records: a piece of his library where it has one, a block
## in his rock paint where it does not, a figure of his for the crowd. A building his
## own data stands is his mesh already and gets nothing. Which ones show is decided
## each frame (`sync`): tents by the army, fences by who holds the Acres, the crowd
## by how many left the Muster.
func _build_props() -> void:
	var stand := Node3D.new()
	stand.name = "Props"
	add_child(stand)
	for prop: Dictionary in _region.props:
		var kind: StringName = prop["kind"] as StringName
		var at: Vector2i = prop["at"] as Vector2i
		if _his != null and bool(prop.get("his", false)):
			his_props_skipped += 1
			_note_fading(prop, null)
			continue
		var entry: Dictionary = {"prop": prop, "node": null, "lift": 0.0, "figure": false}
		if kind == &"townsfolk":
			entry["node"] = _figure()
			entry["figure"] = true
		elif _his != null and _kit_library.has(String(kind)):
			var piece: Node3D = _his_piece(kind)
			if piece != null:
				if TURNED_BY_TILE.has(kind):
					piece.rotation.y = float(Art.scatter_hash(at.x, at.y) % 4) * TAU / 4.0
				entry["node"] = piece
				his_kit_count += 1
		if entry["node"] == null:
			var height: float = float(BLOCK_HEIGHT.get(kind, BLOCK_HEIGHT_DEFAULT))
			entry["node"] = _block(prop, height)
			entry["lift"] = height * 0.5
			block_count += 1
		var node: Node3D = entry["node"] as Node3D
		node.name = "%s_%d_%d" % [kind, at.x, at.y]
		stand.add_child(node)
		_stand(entry)
		_note_fading(prop, entry["node"] as Node3D)
		_props.append(entry)


## Put a prop's node where it belongs: a figure footed on its tile, anything else on
## the middle of its footprint, lifted by half its height if it is a block.
func _stand(entry: Dictionary) -> void:
	var prop: Dictionary = entry["prop"] as Dictionary
	var node: Node3D = entry["node"] as Node3D
	if bool(entry["figure"]):
		_foot_figure(node, Vector2(prop["at"] as Vector2i) + Vector2(0.5, 1.0))
	else:
		node.position = _feet_of(_prop_centre(prop)) + Vector3.UP * float(entry["lift"])


## One of his library pieces for a kind, or null when the copy lacks it.
func _his_piece(kind: StringName) -> Node3D:
	if not _his_pieces.has(kind):
		var path: String = HIS_LIBRARY + String(_kit_library.get(String(kind), ""))
		_his_pieces[kind] = load(path) as PackedScene if ResourceLoader.exists(path) else null
	var scene: PackedScene = _his_pieces[kind] as PackedScene
	return scene.instantiate() as Node3D if scene != null else null


## A block of the footprint's size and the kind's height, in his rock paint — what
## stands for a thing he has not drawn, and reads as exactly that.
func _block(prop: Dictionary, height: float) -> MeshInstance3D:
	var size: Vector2i = prop.get("size", Vector2i(1, 1)) as Vector2i
	var box := BoxMesh.new()
	box.size = Vector3(float(size.x) * _metres_per_tile * 0.9, height, float(size.y) * _metres_per_tile * 0.9)
	var block := MeshInstance3D.new()
	block.mesh = box
	block.material_override = _block_material if _block_material != null else _plain_grey()
	return block


func _plain_grey() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.55, 0.56, 0.58)
	material.roughness = 1.0
	return material


## Walls the simulation has and nothing of his shows: the castle's ramparts. A block
## a tile square and a wall high on each, in his rock paint, so what stops you is
## seen — Yannick walked into the invisible kind (2026-09-14). His own walls are his
## meshes; the kit's building footprints are covered by the pieces and blocks above.
func _build_walls() -> void:
	var walls := Node3D.new()
	walls.name = "Walls"
	add_child(walls)
	var box := BoxMesh.new()
	box.size = Vector3(_metres_per_tile * 0.98, WALL_HEIGHT_M, _metres_per_tile * 0.98)
	var material: Material = _block_material if _block_material != null else _plain_grey()
	for y: int in _region.height:
		for x: int in _region.width:
			if _region.terrain_at(Vector2i(x, y)) != Region.Terrain.RAMPART:
				continue
			var wall := MeshInstance3D.new()
			wall.name = "Wall_%d_%d" % [x, y]
			wall.mesh = box
			wall.material_override = material
			wall.position = _feet_of(Vector2(x, y) + Vector2(0.5, 0.5)) + Vector3.UP * WALL_HEIGHT_M * 0.5
			walls.add_child(wall)
			wall_count += 1


## The middle of a prop's footprint, in tiles — where a mesh stands.
func _prop_centre(prop: Dictionary) -> Vector2:
	var at: Vector2i = prop["at"] as Vector2i
	var size: Vector2i = prop.get("size", Vector2i(4, 3)) as Vector2i
	return Vector2(at) + Vector2(size) * 0.5


# ------------------------------------------------------------------ figures ---

## A person: his traveller, standing, facing the lens — the one figure he has drawn.
## Without his frames (a clone without the copy), a plain capsule in his rock paint.
func _figure() -> Node3D:
	if _frames == null:
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.3
		capsule.height = FIGURE_HEIGHT_M
		var body := MeshInstance3D.new()
		body.mesh = capsule
		body.material_override = _block_material if _block_material != null else _plain_grey()
		return body
	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = _frames
	sprite.animation = &"idle_down"
	sprite.pixel_size = HIS_FIGURE_PIXEL_SIZE
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if _figure_material != null:
		sprite.material_override = _figure_material
	sprite.pause()
	return sprite


## Which of his four facings a direction is, with the 2D window's precedence.
static func _facing_name(facing: Vector2i) -> String:
	if facing.y < 0:
		return "up"
	if facing.x < 0:
		return "left"
	if facing.x > 0:
		return "right"
	return "down"


## Show a figure standing still, facing this way.
func _idle(node: Node3D, facing: Vector2i) -> void:
	var sprite: AnimatedSprite3D = node as AnimatedSprite3D
	if sprite == null:
		return
	var wanted := StringName("idle_" + _facing_name(facing))
	if sprite.sprite_frames.has_animation(wanted) and sprite.animation != wanted:
		sprite.animation = wanted
	sprite.pause()
	sprite.set_frame_and_progress(0, 0.0)


## Show a figure walking this way, `phase` turns of his cycle along.
func _walk(node: Node3D, facing: Vector2i, phase: float) -> void:
	var sprite: AnimatedSprite3D = node as AnimatedSprite3D
	if sprite == null:
		return
	var wanted := StringName("walk_" + _facing_name(facing))
	if not sprite.sprite_frames.has_animation(wanted):
		_idle(node, facing)
		return
	if sprite.animation != wanted:
		sprite.animation = wanted
	sprite.pause()
	var count: int = sprite.sprite_frames.get_frame_count(wanted)
	var along: float = fposmod(phase, 1.0) * float(count)
	sprite.set_frame_and_progress(floori(along) % maxi(count, 1), fposmod(along, 1.0))


## Put a figure's feet on the ground at a tile position (fractional tiles). His
## sprite is lifted along the lens's up by half its frame so it stands; a capsule by
## half its height.
func _foot_figure(node: Node3D, at_tiles: Vector2, dip: float = 0.0) -> void:
	var sprite: AnimatedSprite3D = node as AnimatedSprite3D
	if sprite == null:
		node.position = _feet_of(at_tiles) + Vector3.UP * FIGURE_HEIGHT_M * 0.5
		return
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var height_px: float = float(texture.get_height()) if texture != null else FIGURE_HEIGHT_M / HIS_FIGURE_PIXEL_SIZE
	node.position = _feet_of(at_tiles) \
		+ _lens_up * (height_px * sprite.pixel_size * 0.5 - dip * FIGHT_DIP_M)


# --------------------------------------------------------------------- glows ---

## Light and movement, not a body — the 2D window's rule for her. A light on the
## ground and a soft glow that breathes, dimmer and slower than anything else here,
## because she is dying.
func _build_fairy() -> void:
	_fairy = OmniLight3D.new()
	_fairy.name = "Fairy"
	_fairy.light_color = Color(0.78, 0.94, 0.80)
	_fairy.light_energy = 2.0
	_fairy.omni_range = 7.0
	_fairy.visible = false
	add_child(_fairy)
	_fairy_glow = _dot_sprite()
	_fairy_glow.name = "FairyGlow"
	_fairy_glow.pixel_size = 0.15
	_fairy_glow.modulate = Color(0.80, 0.96, 0.82, 0.55)
	_fairy_glow.visible = false
	_fairy.add_child(_fairy_glow)


## A 16-pixel soft disc, made once: no art of ours may stand in his world, and his
## has no such thing yet. Used for the fairy's glow, the marks over witnesses' heads
## and the embers.
func _soft_dot() -> Texture2D:
	if _dot != null:
		return _dot
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y: int in 16:
		for x: int in 16:
			var away: float = Vector2(x + 0.5, y + 0.5).distance_to(Vector2(8.0, 8.0)) / 8.0
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(1.0 - away, 0.0, 1.0) ** 1.5))
	_dot = ImageTexture.create_from_image(image)
	return _dot


func _dot_sprite() -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = _soft_dot()
	sprite.pixel_size = 0.03
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.double_sided = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return sprite


## Embers over every kiln and every fire: a handful of dots each, on their own
## periods, so the group never pulses together — which is the thing that reads as fake.
##
## **Whether a furnace glows is richesse's to say** (M2, 2026-09-18): a works at 4 of
## 10 burns two of its six, at 1 none, at 7 four. A campfire is not production and is
## never touched — a place can be ruined and still have somebody cooking.
func _build_embers() -> void:
	var hearths := Node3D.new()
	hearths.name = "Embers"
	add_child(hearths)
	for prop: Dictionary in _region.props:
		var kind: StringName = prop["kind"] as StringName
		var count: int = 5 if kind == &"kiln" else (3 if kind == &"campfire" else 0)
		if count == 0:
			continue
		var at: Vector2i = prop["at"] as Vector2i
		var size: Vector2i = prop.get("size", Vector2i(1, 1)) as Vector2i
		var dots: Array[Sprite3D] = []
		for i: int in count:
			var dot: Sprite3D = _dot_sprite()
			dot.name = "Ember_%d_%d_%d" % [at.x, at.y, i]
			dot.pixel_size = 0.025
			hearths.add_child(dot)
			dots.append(dot)
		var hearth: Dictionary = {"kind": kind, "dots": dots,
			"at": Vector2(at) + Vector2(float(size.x) * 0.5, float(size.y) * 0.5)}
		if kind == &"kiln":
			# Only production carries a place: a hearth without one always burns.
			var place: StringName = _region.zone_at(at)
			var index: int = int(_kilns_in.get(place, 0))
			_kilns_in[place] = index + 1
			_kiln_index[at] = index
			hearth["place"] = place
			hearth["index"] = index
		_embers.append(hearth)


# ------------------------------------------------------------------- ground ---

## A tile position (fractional tiles) as a point on his ground.
func _feet_of(at_tiles: Vector2) -> Vector3:
	var metres: Vector2 = _origin_m + at_tiles * _metres_per_tile
	return Vector3(metres.x, height_at(metres.x, metres.y) + FOOT_CLEARANCE, metres.y)


## His ground's height at a point, bilinearly, as his `flat_ground.gd` samples it —
## and from his terrain itself once it stands, because his relief stamps shape it.
func height_at(x_m: float, z_m: float) -> float:
	var ground: float = _ground_height_at(x_m, z_m)
	for deck: Dictionary in _bridge_decks:
		var inverse: Transform3D = deck["inverse"] as Transform3D
		var local: Vector3 = inverse * Vector3(x_m, 0.0, z_m)
		var bounds: AABB = deck["bounds"] as AABB
		if local.x < bounds.position.x or local.x > bounds.end.x or local.z < bounds.position.z or local.z > bounds.end.z:
			continue
		# Planks and paving have deliberate visual seams. Their continuous deck
		# carries the walker across those gaps instead of dropping to the water.
		ground = maxf(ground, (deck["transform"] as Transform3D).origin.y)
		var origin := Vector3(local.x, bounds.end.y + 1.0, local.z)
		var faces: PackedVector3Array = deck["faces"] as PackedVector3Array
		for i: int in range(0, faces.size(), 3):
			var hit: Variant = Geometry3D.ray_intersects_triangle(origin, Vector3.DOWN, faces[i], faces[i + 1], faces[i + 2])
			if hit != null:
				ground = maxf(ground, ((deck["transform"] as Transform3D) * (hit as Vector3)).y)
	return ground


func _ground_height_at(x_m: float, z_m: float) -> float:
	if _his_terrain != null and int(_his_terrain.get("chunk_count")) > 0:
		return float(_his_terrain.call("height_at_world", x_m, z_m))
	if _samples < 2:
		return 0.0
	var u: float = clampf((x_m - _origin_m.x) / _metres_per_tile, 0.0, float(_samples - 1))
	var v: float = clampf((z_m - _origin_m.y) / _metres_per_tile, 0.0, float(_samples - 1))
	var x0: int = floori(u)
	var z0: int = floori(v)
	var x1: int = mini(x0 + 1, _samples - 1)
	var z1: int = mini(z0 + 1, _samples - 1)
	var top: float = lerpf(_heights[z0 * _samples + x0], _heights[z0 * _samples + x1], u - float(x0))
	var bottom: float = lerpf(_heights[z1 * _samples + x0], _heights[z1 * _samples + x1], u - float(x0))
	return lerpf(top, bottom, v - float(z0))


# --------------------------------------------------------------------- frame ---

## Everything that moves, once a frame, from what the simulation says. `frame` is
## built by `main.gd`: the player's interpolated tile position and facing, where the
## camera wants to look, how many tents stand, how big the crowd is, which places are
## free, whether the castle is shuttered, the escort at the gate, who can see you, and
## the clock. Nothing here writes back.
func sync(frame: Dictionary, delta: float) -> void:
	if _region == null or _sim == null:
		return
	_aim_lens(float(frame.get("fight_lens", 0.0)))
	var world := _sim.store(&"world") as WorldState
	var cast := _sim.store(&"cast") as Cast
	var road := _sim.store(&"travellers") as Travellers
	var folk := _sim.store(&"folk") as Folk
	_sync_player(frame)
	_sync_people(cast, world, frame.get("fight", {}) as Dictionary)
	_sync_traffic(road, world)
	_sync_folk(folk, world)
	_sync_guards(world, int(frame.get("escort", 0)), int(frame.get("extra_guards", 0)))
	_sync_props(frame)
	_sync_marks(cast, frame.get("witnesses", []) as Array)
	_sync_embers(frame)
	_sync_light(frame, delta)
	_sync_camera(frame.get("camera", frame.get("player", Vector2.ZERO)) as Vector2,
		float(frame.get("fight_lens", 0.0)), delta)


## The player: his traveller, walking when the simulation moves them — the cycle
## driven by the distance actually covered, as his own controller drives it — and
## standing when it does not.
func _sync_player(frame: Dictionary) -> void:
	if _player == null:
		_player = _figure()
		_player.name = "Player"
		add_child(_player)
	var facing: Vector2i = frame.get("facing", Vector2i(0, 1)) as Vector2i
	var at: Vector2 = frame.get("player", Vector2.ZERO) as Vector2
	var feet: Vector3 = _feet_of(at)
	var moved: float = Vector2(feet.x, feet.z).distance_to(Vector2(_player_last.x, _player_last.z)) if _player_placed else 0.0
	_player_last = feet
	_player_placed = true
	var fighting: Dictionary = frame.get("fight", {}) as Dictionary
	if not _fight_pose(_player, fighting, true, facing):
		if moved > 0.002:
			_walk_phase = fposmod(_walk_phase + moved / WALK_CYCLE_M, 1.0)
			_walk(_player, facing, _walk_phase)
		else:
			_idle(_player, facing)
	# The lunge is added to where he is *drawn* and not to where he is: the walk cycle is
	# driven by ground covered, and a blow that made his feet turn over would read as a
	# man walking on the spot.
	_foot_figure(_player, at + Vector2(_lunge_of(fighting, true), 0.0), _dip_of(fighting, true))


## `fighting` is empty unless somebody is squared up with the player, in which case it
## carries that one person's id, where they stand on the fight's line, and which way
## they are looking. Everybody else is drawn at their anchor, as always.
func _sync_people(cast: Cast, world: WorldState, fighting: Dictionary) -> void:
	var present: Dictionary = {}
	var fairy_seen: bool = false
	var foe: StringName = StringName(String(fighting.get("who", "")))
	for npc: Npc in cast.in_zone(world.current_zone):
		if OpeningRules.is_gone(npc.id, _sim.facts):
			continue
		if npc.id == OpeningRules.FAIRY:
			# Light and movement, not a body (the 2D window's rule): a glow where she is.
			fairy_seen = true
			var feet: Vector3 = _feet_of(npc.centre())
			var breath: float = float(Time.get_ticks_msec()) * 0.0011
			_fairy.position = feet + Vector3.UP * (1.2 + 0.25 * sin(breath))
			_fairy_glow.visible = true
			_fairy_glow.pixel_size = 0.13 + 0.03 * sin(breath)
			continue
		present[npc.id] = true
		var figure: Node3D = _people.get(npc.id, null) as Node3D
		if figure == null:
			figure = _figure()
			figure.name = "Person_%s" % npc.id
			add_child(figure)
			_people[npc.id] = figure
			_idle(figure, Vector2i(0, 1))
		# Footed every frame, not once: the ground under them is his and is built a
		# frame after they are, and thirty-three figures are nothing.
		var stands_at: Vector2 = npc.centre()
		if npc.id == foe:
			stands_at = fighting.get("at", stands_at) as Vector2
			_step_the_foe(figure, stands_at,
				fighting.get("facing", Vector2i(0, 1)) as Vector2i, fighting)
			stands_at += Vector2(_lunge_of(fighting, false), 0.0)
			_foot_figure(figure, stands_at, _dip_of(fighting, false))
			figure.visible = true
			continue
		_foot_figure(figure, stands_at)
		figure.visible = true
	_fairy.visible = fairy_seen
	for id: StringName in _people.keys():
		if not present.has(id):
			(_people[id] as Node3D).visible = false


## The man in front of you: walking when the fight moves him, and always looking at
## you. The cycle is driven by the ground he actually covers, the same rule the player
## and the road's travellers are drawn by, so nothing about a fight animates on a timer.
func _step_the_foe(figure: Node3D, at: Vector2, facing: Vector2i, fighting: Dictionary) -> void:
	var feet: Vector3 = _feet_of(at)
	var moved: float = Vector2(feet.x, feet.z).distance_to(
		Vector2(_foe_last.x, _foe_last.z)) if _foe_placed else 0.0
	_foe_last = feet
	_foe_placed = true
	if _fight_pose(figure, fighting, false, facing):
		return
	if moved > 0.002:
		_foe_phase = fposmod(_foe_phase + moved / WALK_CYCLE_M, 1.0)
		_walk(figure, facing, _foe_phase)
	else:
		_idle(figure, facing)


## Puts one of our three fight poses on a figure, and says whether it did. `false` means
## nobody is fighting or this frame has no pose of its own, and the caller draws them
## standing or walking as usual.
func _fight_pose(figure: Node3D, fighting: Dictionary, mine: bool, facing: Vector2i) -> bool:
	if fighting.is_empty():
		return false
	var move := StringName(String(fighting.get("my_move" if mine else "his_move", "")))
	var at_frame: int = int(fighting.get("my_frame" if mine else "his_frame", 0))
	var stunned: int = int(fighting.get("my_stun" if mine else "his_stun", 0))
	var guarding: bool = mine and bool(fighting.get("guarding", false))
	var pose: StringName = CombatRules.pose_of(move, at_frame, stunned, guarding)
	if pose == &"":
		return false
	var named := StringName("%s_%s" % [pose, _facing_name(facing)])
	var sprite := figure as AnimatedSprite3D
	if sprite == null or not sprite.sprite_frames.has_animation(named):
		return false
	if sprite.animation != named:
		sprite.animation = named
	sprite.pause()
	sprite.set_frame_and_progress(0, 0.0)
	return true


## **How far a fighter is drawn from where he stands**, in tiles along the fight's line.
## Negative is drawn back — the wind-up, and the guard's stance — and positive is thrust
## forward. `CombatRules.lunge_at` decides the shape; this only decides how far.
func _lunge_of(fighting: Dictionary, mine: bool) -> float:
	if fighting.is_empty():
		return 0.0
	var toward: int = int(fighting.get("toward", 1))
	var forward: float = float(toward if mine else -toward)
	var move := StringName(String(fighting.get("my_move" if mine else "his_move", "")))
	var at_frame: int = int(fighting.get("my_frame" if mine else "his_frame", 0))
	var shape: float = CombatRules.lunge_at(move, at_frame)
	if mine and move == &"" and bool(fighting.get("guarding", false)):
		shape = CombatRules.guard_lean()
	return shape * FIGHT_LUNGE_TILES * forward


## **How low he is carried this frame.** The other half of the tell, and the half a
## person reads first: he gathers through the wind-up and comes up as the blow goes out.
func _dip_of(fighting: Dictionary, mine: bool) -> float:
	if fighting.is_empty():
		return 0.0
	var move := StringName(String(fighting.get("my_move" if mine else "his_move", "")))
	var at_frame: int = int(fighting.get("my_frame" if mine else "his_frame", 0))
	if mine and move == &"" and bool(fighting.get("guarding", false)):
		return CombatRules.guard_dip()
	return CombatRules.dip_at(move, at_frame)


## Traffic: his traveller walking the road, the cycle read off where they stand.
func _sync_traffic(road: Travellers, world: WorldState) -> void:
	if road == null:
		return
	var line: Array[Vector2i] = world.region().road_waypoints()
	var seen: Dictionary = {}
	for walker: Traveller in road.walkers:
		seen[walker.id] = true
		var figure: Node3D = _traffic.get(walker.id, null) as Node3D
		if figure == null:
			figure = _figure()
			figure.name = "Traffic_%d" % walker.id
			add_child(figure)
			_traffic[walker.id] = figure
		var facing := Vector2i(-1, 0)
		if not line.is_empty():
			var target: int = clampi(walker.leg + walker.heading, 0, line.size() - 1)
			var to: Vector2 = Vector2(line[target]) + Vector2(0.5, 0.5) - walker.pos
			if absf(to.y) > absf(to.x):
				facing = Vector2i(0, 1 if to.y > 0.0 else -1)
			else:
				facing = Vector2i(1 if to.x > 0.0 else -1, 0)
		_walk(figure, facing, fposmod((walker.pos.x + walker.pos.y) * _metres_per_tile / WALK_CYCLE_M, 1.0))
		_foot_figure(figure, walker.pos + Vector2(0.0, 0.5))
		figure.visible = true
	for id: int in _traffic.keys():
		(_traffic[id] as Node3D).visible = seen.has(id)


## The escort in two ranks before the gate, and the wall's extra guards, drawn as
## the 2D window draws them and from the same numbers.
func _sync_guards(world: WorldState, escort: int, extra: int) -> void:
	var posts: Array[Vector2] = [Vector2(-5.0, 9.0), Vector2(3.0, 9.0), Vector2(-8.0, 9.0), Vector2(11.0, 9.0)]
	var wanted: int = escort + mini(extra, posts.size())
	while _guards.size() < wanted:
		var guard: Node3D = _figure()
		guard.name = "Guard_%d" % _guards.size()
		add_child(guard)
		_idle(guard, Vector2i(0, 1))
		_guards.append(guard)
	for i: int in _guards.size():
		var guard: Node3D = _guards[i]
		guard.visible = i < wanted and world.current_zone == WorldState.OVERWORLD
		if not guard.visible:
			continue
		if i < escort:
			var rank: int = i / ESCORT_FILES
			var file: int = i % ESCORT_FILES
			_foot_figure(guard, world.king_pos + Vector2(float(file) - 2.0, 2.0 + float(rank) * 1.2))
		else:
			_foot_figure(guard, world.king_pos + posts[i - escort])


## What stands and what has gone: the visible half of §8's consequences, as the 2D
## window shows them. A piece of his or a block cannot be tinted; it shows or it does
## not, and the darkened readings wait for his scenes of the two states.
## The people of a place, walking to work or not walking at all. The simulation decides
## how many there are; this only puts them where it says.
func _sync_folk(folk: Folk, world: WorldState) -> void:
	if folk == null:
		return
	var seen: Dictionary = {}
	for walker: Dictionary in folk.walkers:
		var id: int = int(walker["id"])
		seen[id] = true
		var figure: Node3D = _folk.get(id, null) as Node3D
		if figure == null:
			figure = _figure()
			figure.name = "Folk_%d" % id
			add_child(figure)
			_folk[id] = figure
		var pos: Vector2 = walker["pos"] as Vector2
		var route: Array[Vector2] = folk.route_in(world.region(), walker["place"] as StringName)
		var facing := Vector2i(0, 1)
		if route.size() > 1:
			var target: int = clampi(int(walker["leg"]) + int(walker["heading"]), 0, route.size() - 1)
			var to: Vector2 = route[target] - pos
			if absf(to.y) > absf(to.x):
				facing = Vector2i(0, 1 if to.y > 0.0 else -1)
			else:
				facing = Vector2i(1 if to.x > 0.0 else -1, 0)
		_walk(figure, facing, fposmod((pos.x + pos.y) * _metres_per_tile / WALK_CYCLE_M, 1.0))
		_foot_figure(figure, pos + Vector2(0.0, 0.5))
	# Somebody the works no longer sends is not hidden, they are gone.
	for id: Variant in _folk.keys():
		if not seen.has(id):
			(_folk[id] as Node3D).queue_free()
			_folk.erase(id)


## How many of a place's people the window is standing. For the suite.
func folk_shown() -> int:
	return _folk.size()


func _sync_props(frame: Dictionary) -> void:
	var tents_standing: int = int(frame.get("tents", 0))
	var crowd: int = int(frame.get("crowd", 0))
	var free: Dictionary = frame.get("free", {}) as Dictionary
	var tent: int = 0
	var folk: int = 0
	for entry: Dictionary in _props:
		var prop: Dictionary = entry["prop"] as Dictionary
		var node: Node3D = entry["node"] as Node3D
		var kind: StringName = prop["kind"] as StringName
		var shown: bool = true
		if kind == &"fence" and bool(free.get(&"wide_acres", false)):
			shown = false
		elif kind == &"tent" or kind == &"tent_b":
			tent += 1
			shown = tent <= tents_standing
		elif kind == &"townsfolk":
			folk += 1
			shown = folk <= crowd
		node.visible = shown
	# **Last**, so it has the last word. The loop above sets every one of our own props
	# visible again each frame, and a piece that a poor place has stopped putting out
	# would have come straight back.
	_sync_fading(frame)


## Who can see you, marked over their heads while there is an act in front of you
## that they would see you do — the 2D window's rule, with the same ids handed over.
func _sync_marks(cast: Cast, witnesses: Array) -> void:
	while _marks.size() < witnesses.size():
		var mark: Sprite3D = _dot_sprite()
		mark.name = "Mark_%d" % _marks.size()
		mark.pixel_size = 0.035
		mark.modulate = Color(0.93, 0.88, 0.68, 0.95)
		add_child(mark)
		_marks.append(mark)
	for i: int in _marks.size():
		var mark: Sprite3D = _marks[i]
		mark.visible = i < witnesses.size()
		if not mark.visible:
			continue
		var npc: Npc = cast.get_npc(StringName(String(witnesses[i])))
		if npc == null:
			mark.visible = false
			continue
		mark.position = _feet_of(npc.centre()) + _lens_up * (FIGURE_HEIGHT_M + 0.4)


func _sync_embers(frame: Dictionary) -> void:
	var now: float = float(frame.get("now", 0.0))
	# **How many furnaces burn is richesse's to say** (M2). The frame carries each
	# place's two numbers; nothing here asks the store.
	var towns: Dictionary = frame.get("towns", {}) as Dictionary
	var burning: Dictionary = {}
	for place: StringName in _kilns_in.keys():
		var row: Dictionary = towns.get(place, {}) as Dictionary
		burning[place] = TownRules.lit_of(int(_kilns_in[place]),
			int(row.get("richesse", TownRules.CEILING)))
	for group: Dictionary in _workshop_heat:
		var on: bool = _burns(burning, group)
		for node: Node3D in (group["nodes"] as Array[Node3D]):
			node.visible = on
			if node is CPUParticles3D:
				(node as CPUParticles3D).emitting = on
		for coals: ShaderMaterial in (group["coals"] as Array[ShaderMaterial]):
			coals.set_shader_parameter("glow_strength", null if on else 0.0)
	for hearth: Dictionary in _embers:
		var dots: Array[Sprite3D] = hearth["dots"] as Array[Sprite3D]
		var lit: bool = _burns(burning, hearth)
		var colour: Color = Color(1.0, 0.62, 0.28) if (hearth["kind"] as StringName) == &"kiln" else Color(1.0, 0.74, 0.40)
		var base: Vector3 = _feet_of(hearth["at"] as Vector2)
		var lift: float = float(BLOCK_HEIGHT.get(hearth["kind"] as StringName, 0.5))
		for i: int in dots.size():
			var dot: Sprite3D = dots[i]
			dot.visible = lit
			if not lit:
				continue
			var life: float = fposmod(now * (0.34 + float(i) * 0.07) + float(i) * 0.41, 1.0)
			var rise: float = life * 2.2
			var sway: float = sin((now + float(i) * 2.1) * 1.7) * (0.2 + life * 0.4)
			dot.position = base + Vector3(sway, lift, 0.0) + _lens_up * rise
			dot.modulate = Color(colour.r, colour.g, colour.b, 0.75 * (1.0 - life) * (1.0 - life))
			dot.pixel_size = 0.02 + (1.0 - life) * 0.02


## **Where the lens is pointing from**, given how far into a fight we are: 0 is
## exploration and 1 is squared up. The easing is not done here — `view/main.gd` owns
## that one number, because the darkened edge of the screen has to come up on exactly
## the same frame as the camera drops, and two easings of one idea drift visibly.
##
## Called at the top of `sync()` rather than with the camera at the bottom, so the
## billboards placed in between are lifted along the lens they will actually be seen
## through and not along last frame's.
func _aim_lens(fight_lens: float) -> void:
	var tilt: float = deg_to_rad(lerpf(_rest_tilt, FIGHT_TILT_DEGREES, clampf(fight_lens, 0.0, 1.0)))
	var azimuth: float = deg_to_rad(AZIMUTH_DEGREES)
	_lens_offset = Vector3(sin(azimuth) * cos(tilt), sin(tilt), cos(azimuth) * cos(tilt))
	var forward: Vector3 = -_lens_offset
	_lens_up = (Vector3.UP - forward * Vector3.UP.dot(forward)).normalized()


## **Already squared up, on the first frame drawn.** For `shot.sh` and nothing else:
## the picture is taken twelve frames in, and the lens takes about a second to drop, so
## a photograph of a fight would otherwise always be a photograph of a camera halfway
## through moving. Debug-gated at the caller.
func snap_framing(fight_lens: float) -> void:
	_aim_lens(fight_lens)
	if _camera != null:
		_camera.size = lerpf(_zoom, FIGHT_SIZE_M, clampf(fight_lens, 0.0, 1.0))


## The lens follows the same eased point the 2D camera does, handed over in tiles.
func _sync_camera(eye_tiles: Vector2, fight_lens: float, delta: float) -> void:
	var want: Vector3 = _feet_of(eye_tiles)
	if not _focus_placed or _focus.distance_to(want) > 12.0:
		_focus = want
		_focus_placed = true
	else:
		_focus = _focus.lerp(want, 1.0 - exp(-CAMERA_CATCHES_UP * delta))
	var framing: float = lerpf(_zoom, FIGHT_SIZE_M, clampf(fight_lens, 0.0, 1.0))
	_camera.size = lerpf(_camera.size, framing, 1.0 - exp(-10.0 * delta))
	_camera.transform = Transform3D(Basis.looking_at(-_lens_offset, Vector3.UP),
		_focus + _lens_offset * CAMERA_DISTANCE)


# ------------------------------------------------------------------ counting ---

func his_present() -> bool:
	return _his != null


func figures_are_his() -> bool:
	return _frames != null


func prop_count() -> int:
	return _props.size()


func people_count() -> int:
	var shown: int = 0
	for id: StringName in _people.keys():
		if (_people[id] as Node3D).visible:
			shown += 1
	return shown


func marks_shown() -> int:
	var shown: int = 0
	for mark: Sprite3D in _marks:
		if mark.visible:
			shown += 1
	return shown


## Whether this piece of a works is alight.
##
## A furnace burns while its number is under the count richesse pays for. Heat that is
## **not** a furnace — his forges — burns while the works is working at all. Anything
## with no place at all is not production: a campfire goes on burning in a dead town,
## because somebody still has to eat.
func _burns(burning: Dictionary, piece: Dictionary) -> bool:
	var place: StringName = piece.get("place", &"") as StringName
	if not burning.has(place):
		return true
	var count: int = int(burning[place])
	var index: int = int(piece.get("index", -1))
	return index < count if index >= 0 else count > 0


## Warm or cold, by the allégeance of the place the player is standing in.
##
## The window looks up which place that is — reading the region, as it reads everything
## — and takes the number from the frame. A place with no row, and the wild, sit at the
## midpoint, which is the light this window had before there were two numbers.
func _sync_light(frame: Dictionary, delta: float) -> void:
	var towns: Dictionary = frame.get("towns", {}) as Dictionary
	var at: Vector2 = frame.get("player", Vector2.ZERO) as Vector2
	var here: StringName = _region.zone_at(Vector2i(at.floor()))
	var target: float = 0.5
	if towns.has(here):
		var allegiance: int = int((towns[here] as Dictionary).get("allegiance", TownRules.CEILING))
		target = 1.0 if TownRules.is_high(allegiance) else 0.0
	if not _warmth_placed:
		_warmth_placed = true
		_warmth = target
	else:
		_warmth = lerpf(_warmth, target, clampf(delta * LIGHT_SETTLES, 0.0, 1.0))
	var tint: Color = TINT_HOSTILE.lerp(TINT_LOYAL, _warmth)
	if _sun != null:
		_sun.light_color = Color(_sun_base.r * tint.r, _sun_base.g * tint.g, _sun_base.b * tint.b)
		_sun.light_energy = _sun_energy_base * lerpf(ENERGY_HOSTILE, ENERGY_LOYAL, _warmth)
	if _air != null:
		_air.ambient_light_color = Color(_air_base.r * tint.r, _air_base.g * tint.g, _air_base.b * tint.b)


## What he chose, kept so the tint multiplies it rather than replacing it.
func _remember_light() -> void:
	if _sun != null:
		_sun_base = _sun.light_color
		_sun_energy_base = _sun.light_energy
	if _air != null:
		_air_base = _air.ambient_light_color


## How warm the light is: 1 loyal, 0 turned, 0.5 no opinion. For the suite, which
## cannot see a colour.
func light_warmth() -> float:
	return _warmth


## The list of what a poor place stops putting out. His brother's file, not ours.
func _load_poverty() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TOWNS))
	if not (parsed is Dictionary):
		return
	var block: Dictionary = (parsed as Dictionary).get("poverty", {}) as Dictionary
	for kind: Variant in (block.get("gone_below_threshold", []) as Array):
		_poverty[StringName(String(kind))] = true


## Remember a piece that can go missing — **only if the player could already walk on
## its tile.** Some of his carts and ore heaps stand on ground the simulation refuses,
## and hiding one of those would leave a wall nobody can see, which is the rule this
## project has held since his map arrived. `node` is null for a piece of his, which is
## drawn by his own scene and has to be found in it by its id.
func _note_fading(prop: Dictionary, node: Node3D) -> void:
	var kind: StringName = prop["kind"] as StringName
	if not _poverty.has(kind):
		return
	var at: Vector2i = prop["at"] as Vector2i
	if not _region.is_passable(at):
		return
	var piece: Node3D = node
	if piece == null:
		var town: Node = _his.get_node_or_null("Decor/Acierie") if _his != null else null
		if town == null or not prop.has("source_id"):
			return
		piece = town.find_child(String(prop["source_id"]), true, false) as Node3D
		if piece == null:
			return
	_fading.append({"node": piece, "place": _region.zone_at(at), "at": at})


## A place below the threshold stops putting its work out: the carts, the bundled bars,
## the firewood stacked ready. The buildings stay, the slag stays, the walls stay — a
## works that has stopped is **empty, not demolished**.
func _sync_fading(frame: Dictionary) -> void:
	if _fading.is_empty():
		return
	var towns: Dictionary = frame.get("towns", {}) as Dictionary
	for piece: Dictionary in _fading:
		var place: StringName = piece["place"] as StringName
		var row: Dictionary = towns.get(place, {}) as Dictionary
		var richesse: int = int(row.get("richesse", TownRules.CEILING))
		(piece["node"] as Node3D).visible = TownRules.is_high(richesse)


## How many pieces are hidden because their place is poor. For the suite.
func faded_count() -> int:
	var gone: int = 0
	for piece: Dictionary in _fading:
		if not (piece["node"] as Node3D).visible:
			gone += 1
	return gone


func fading_count() -> int:
	return _fading.size()


## Where every piece that can go missing stands. For the suite, which has to be able to
## prove that none of them was ever what stopped the player.
func fading_tiles() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for piece: Dictionary in _fading:
		out.append(piece["at"] as Vector2i)
	return out


func ember_count() -> int:
	var total: int = 0
	for hearth: Dictionary in _embers:
		total += (hearth["dots"] as Array[Sprite3D]).size()
	return total


func kiln_embers() -> int:
	var total: int = 0
	for hearth: Dictionary in _embers:
		if (hearth["kind"] as StringName) == &"kiln":
			total += (hearth["dots"] as Array[Sprite3D]).size()
	return total


func embers_lit() -> int:
	var lit: int = 0
	for hearth: Dictionary in _embers:
		for dot: Sprite3D in (hearth["dots"] as Array[Sprite3D]):
			if dot.visible:
				lit += 1
	return lit


## The bridge mesh is the walking surface, never the riverbed below it. Only deck
## faces are cached, so parapets cannot lift a traveller (2026-09-15).
##
## **The list is the contract, and it is deliberately explicit** (2026-09-16). His
## royal gate bridge arrived with its walking surface named `ContinuousDeckStone`,
## and the walker fell through the moat because the list had never heard of it. The
## temptation is a rule — anything whose name contains *deck* — and the reason not to
## is `ParapetStone` standing right beside it: a guess that lifts a traveller onto a
## parapet is worse than a name nobody added. `test_world3d` walks every crossing in
## his river layout and fails **by the bridge's id**, so a name we do not know says
## so the day he delivers it.
func _read_bridge_decks() -> void:
	var bridges: Node = _his.get_node_or_null("Decor/Franchissements/Ponts")
	if bridges == null:
		return
	for bridge: Node3D in bridges.get_children():
		for child: Node in bridge.get_children():
			if child is MeshInstance3D and child.name in [&"WornPavingPaving", &"RoadBedEarth",
					&"DeckPlanksWood", &"ContinuousDeckStone"]:
				var deck := child as MeshInstance3D
				var transform: Transform3D = bridge.transform * deck.transform
				_bridge_decks.append({"transform": transform, "inverse": transform.affine_inverse(),
					"bounds": deck.mesh.get_aabb(), "faces": deck.mesh.get_faces()})


## Keep his delivered furnace and forge effects in step with our ember marks, piece by
## piece: a furnace has its own row, so richesse can cool the third one and leave the
## other two burning. Runs after `_build_embers`, which is what numbered them.
## Duplicate only the material instance; the generated workshop stays untouched.
func _read_workshop_heat() -> void:
	var town: Node = _his.get_node_or_null("Decor/Acierie")
	if town == null:
		return
	for prop: Dictionary in _region.props:
		if not prop.has("source_id"):
			continue
		var piece: Node = town.find_child(String(prop["source_id"]), true, false)
		if piece == null:
			continue
		var at: Vector2i = prop["at"] as Vector2i
		var nodes: Array[Node3D] = []
		var coals: Array[ShaderMaterial] = []
		for child: Node in piece.find_children("*", "", true, false):
			if child is CPUParticles3D or child is Light3D:
				nodes.append(child as Node3D)
			elif child is MeshInstance3D and child.name in [&"FurnaceBedEmbers", &"HearthCoalsEmbers"]:
				var mesh := child as MeshInstance3D
				var material: ShaderMaterial = (mesh.material_override as ShaderMaterial).duplicate() as ShaderMaterial
				mesh.material_override = material
				coals.append(material)
		if nodes.is_empty() and coals.is_empty():
			continue
		_workshop_heat.append({"place": _region.zone_at(at), "nodes": nodes, "coals": coals,
			"index": int(_kiln_index.get(at, -1))})
