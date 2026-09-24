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
## **The blow goes further out than the wind-up goes back** (H4, 2026-09-21). Every
## blow in a played fight lands at the very edge of its reach — the player's at
## 1,520–1,550 mm of 1,550, his at 2,410–2,450 of 2,450 — and at 0.30 tiles his fist
## stopped a metre short of the man it had just hit. The draw-back stays small so the
## figure stays on its foot mark; the thrust is half again as far.
const FIGHT_THRUST_TILES: float = 0.45
## And how far he sinks, in metres. A blow is a gather and a release, and the gather is
## the half of it a person reads first.
##
## **Deliberately small.** A single sprite has no knees: lower it far and it reads as a
## figure sinking into the ground rather than one bending. Thirty centimetres looked like
## sinking in a photograph, so it is fifteen. Up and down only, never a squash — a pixel
## figure stretched to sell a movement stops being pixel art.
const FIGHT_DIP_M: float = 0.15
const FIGHT_SIZE_M: float = 7.0
## **And how much of it a fight on the grid needs** (K4). Seven metres is three and a
## half tiles of height, which was right for two men on one line and is wrong the
## moment a turn buys four tiles in every direction: the field of tiles a turn reaches
## is nine tiles across and ran off all four edges of the first photograph. The drop
## and the azimuth are unchanged — the ruling of 2026-09-19 is about the angle, and
## this is the framing.
const DUEL_SIZE_M: float = 15.0

## **The fight, drawn** (H group, 2026-09-21). Everything under these constants is a
## mark of ours and reads as one — a line on the ground, a ring filling, a spark, a
## flash — and none of it is a thing of his library or a thing pretending to be. It is
## the same kind of thing as the darkened edge of the screen: a picture of what the
## simulation already knows, drawn against numbers `CombatRules` decides.
##
## How far the arena's floor reaches either side of the fight's line, in tiles. The
## wall is only along the line (`CombatRules.inside_arena`); the depth is the floor's
## shape and nothing more.
const ARENA_DEPTH_TILES: float = 1.35
## Marks float this far above his ground so they neither z-fight with it nor hover.
const MARK_LIFT_M: float = 0.06
## The telegraph ring at a fighter's feet, in metres, and the height a blow's swipe is
## drawn at — about the hip of a 1.53 m figure.
const TELEGRAPH_RADIUS_M: float = 0.62
const SWIPE_HEIGHT_M: float = 0.85
const SWIPE_THICKNESS_M: float = 0.16
## How far the fighter who was hit is drawn shoved, in tiles, on the frame the blow
## lands, easing back over the hitstop — so the freeze both share is *felt* as an
## impact rather than seen as a pause.
const FIGHT_SHOVE_TILES: float = 0.16
## The lens jolts this far, in metres, on a clean hit, and settles in a third of a second.
const SHAKE_M: float = 0.09
const SHAKE_SECONDS: float = 0.32
## Sparks kept in a pool; a burst uses a handful and they live a third of a second.
const SPARK_POOL: int = 36
const SPARK_SECONDS: float = 0.5
## How far the fighter who is down sinks over the beat, in metres. Small, for the same
## reason as `FIGHT_DIP_M`: a sprite has no knees, and a figure lowered far reads as one
## sinking into the ground rather than one going down.
const KO_SINK_M: float = 0.42
## How long a hit's white flash and its bruise-red tint stay on the figure, in seconds.
const FLASH_SECONDS: float = 0.22
const BRUISE_SECONDS: float = 0.45
## The marks' colours are the HUD's, so what the ground says and what the bars say
## read as one voice: gold is yours, ember is his, sage is a guard, ink is neutral.
const MARK_MINE: Color = Color(1.0, 0.847, 0.443)
const MARK_HIS: Color = Color(1.0, 0.42, 0.28)
const MARK_GUARD: Color = Color(0.694, 0.851, 0.804)
const MARK_INK: Color = Color(0.94, 0.93, 0.88)
## How dark the fight's floor is laid. The second design lays it lighter — see `K4`.
const ARENA_FILL: Color = Color(0.02, 0.02, 0.03, 0.30)

## **A flash on his figure, in a shader of ours.** His `traveler_sprite.gdshader` puts
## the sheet's colour straight into `ALBEDO`, so `modulate` does nothing to it and a hit
## could not be shown on the man who took it. This is his shader — his billboard trick,
## his rule for what is background — with three uniforms added: `flash` lerps the figure
## toward `flash_colour` on the frame a blow lands, and `tint` multiplies it for the
## bruise after and the dimming of a fighter who is down. His file is not touched; two
## fighters wear this for the length of a fight and his material again after.
const FIGHTER_SHADER: String = """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D sprite_sheet : source_color, filter_nearest, repeat_disable;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec3 flash_colour : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);

void vertex() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * scale.x, INV_VIEW_MATRIX[1] * scale.y, INV_VIEW_MATRIX[2] * scale.z, MODEL_MATRIX[3]);
}

void fragment() {
	vec4 ink = texture(sprite_sheet, UV);
	float high = max(ink.r, max(ink.g, ink.b));
	float low = min(ink.r, min(ink.g, ink.b));
	if (ink.a < 0.5 || (high > 0.35 && (high - low) / max(high, 0.001) < 0.22)) { discard; }
	ALBEDO = mix(ink.rgb * tint, flash_colour, flash);
	ALPHA = ink.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
"""
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
const OUR_POSES: Array[StringName] = [&"ready", &"attack", &"guard", &"hurt"]
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
## How tight the lens closes for a fight, which is not the same for the two designs —
## see `DUEL_SIZE_M`. Set from the reading at the top of every `sync`.
var _fight_size_m: float = FIGHT_SIZE_M
## A framing snap asked for before the reading arrived, replayed on the next `sync`.
var _snap_wanted: float = -1.0
## The tilt the lens returns to when nobody is fighting — his 48°, or whatever
## `UNCROWNED_LENS` asked for, so the debug tool still wins.
var _rest_tilt: float = TILT_DEGREES
## The opponent's walk cycle, kept the same way the player's is. One fight at a time,
## so one phase.
var _foe_last: Vector3 = Vector3.ZERO
var _foe_placed: bool = false
var _foe_phase: float = 0.0
## **The fight's picture** (H group). The arena's floor and its marks, the sparks, and
## what the two fighters wear for the length of it. All of it is built the first time a
## fight needs it and hidden after; nothing here is asked of the simulation.
var _arena: Node3D = null
var _arena_floor: MeshInstance3D = null
var _arena_floor_at: Vector2 = Vector2(INF, INF)
var _arena_marks: MeshInstance3D = null
var _arena_mesh: ImmediateMesh = null
var _mark_material: StandardMaterial3D = null
var _sparks: Array[Sprite3D] = []
var _spark_state: Array[Dictionary] = []
var _spark_next: int = 0
## The window's own clock, in seconds of frames drawn. Every effect below is a function
## of it and of the simulation's state, never of a timer of its own.
var _now: float = 0.0
## Per fighter — `&"mine"` and `&"his"` — when they were last hit and how, for the
## flash and the bruise; and the shader material each wears while fighting.
var _struck: Dictionary = {}
var _fight_paint: Dictionary = {}
var _fighting_was: bool = false
var _shake_at: float = -10.0
var _shake_amp: float = 0.0
## Who was shoved by the last blow, which way, and for how many frames of hitstop.
var _shove: Dictionary = {}
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

## **The threshold** (G4, 2026-09-21): his packed earth over a yard's floor, so the
## ground changes where the wall does. The geometry is `YardFloor`'s; the material is
## his `ironworks_path.tres`, the ground his own paths at the works are drawn with.
const HIS_FLOOR_MATERIAL: String = "res://view3d/workshop/materials/ironworks_path.tres"
var _floors: Array[MeshInstance3D] = []

var chunk_count: int = 0
var water_triangles: int = 0
var his_props_skipped: int = 0
var his_kit_count: int = 0
## Pieces of his catalogue the bake placed — the yard's walls, gate and sign (G1–G3).
var catalog_count: int = 0
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
	_build_floors()
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
	_build_floors()


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
		elif _his != null and prop.has("scene") and prop.has("xz"):
			# A piece of his catalogue the bake placed (G1): his scene from the vendored
			# copy, stood where the brief put it in his metres and turned as the brief
			# turned it — never by tile, never by our footprint.
			var piece: Node3D = _catalog_piece(String(prop["scene"]))
			if piece != null:
				piece.rotation.y = deg_to_rad(float(prop.get("yaw", 0.0)))
				entry["node"] = piece
				entry["placed"] = true
				entry["lift"] = float(prop.get("lift", 0.0))
				catalog_count += 1
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
	elif bool(entry.get("placed", false)):
		# His catalogue's origin is the ground under the piece's centre: it stands on his
		# relief exactly where the brief says, in his metres.
		var xz: Vector2 = prop["xz"] as Vector2
		node.position = Vector3(xz.x, height_at(xz.x, xz.y) + float(entry["lift"]), xz.y)
	else:
		node.position = _feet_of(_prop_centre(prop)) + Vector3.UP * float(entry["lift"])


## One of his catalogue's scenes, from the vendored copy, or null when the copy lacks it.
func _catalog_piece(scene_path: String) -> Node3D:
	var copied: String = scene_path.replace("res://", "res://view3d/workshop/")
	if not _his_pieces.has(copied):
		_his_pieces[copied] = load(copied) as PackedScene if ResourceLoader.exists(copied) else null
	var scene: PackedScene = _his_pieces[copied] as PackedScene
	return scene.instantiate() as Node3D if scene != null else null


## The yards' floors (G4), rebuilt whenever his terrain is, because they stand on it.
func _build_floors() -> void:
	for old: MeshInstance3D in _floors:
		old.queue_free()
	_floors.clear()
	if _his == null or _region.yards.is_empty() or not ResourceLoader.exists(HIS_FLOOR_MATERIAL):
		return
	var material: Material = load(HIS_FLOOR_MATERIAL) as Material
	if material != null:
		var water: Callable = func(tile: Vector2i) -> bool:
			return _region.in_bounds(tile) and Art.is_water(_region.terrain_at(tile))
		_floors = YardFloor.build(_region.yards, material, height_at, water, _origin_m, _metres_per_tile, self)


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
	# How tight the lens closes, read off the reading before anything is placed: the
	# first design's fight runs along one line and the second's covers a grid.
	_fight_size_m = DUEL_SIZE_M \
		if bool((frame.get("fight", {}) as Dictionary).get("turn_based", false)) else FIGHT_SIZE_M
	if _snap_wanted >= 0.0:
		snap_framing(_snap_wanted)
		_snap_wanted = -1.0
	_aim_lens(float(frame.get("fight_lens", 0.0)))
	_now += delta
	var world := _sim.store(&"world") as WorldState
	var cast := _sim.store(&"cast") as Cast
	var road := _sim.store(&"travellers") as Travellers
	var folk := _sim.store(&"folk") as Folk
	# The blows land before the figures are placed, so the frame a blow lands is the
	# frame its shove, its flash and its spark are drawn.
	_take_blows(frame.get("fight", {}) as Dictionary, frame.get("blows", []) as Array)
	_sync_player(frame)
	_sync_people(cast, world, frame.get("fight", {}) as Dictionary)
	_sync_fight(frame.get("fight", {}) as Dictionary, float(frame.get("fight_lens", 0.0)))
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
	_foot_figure(_player, at + _offset_of(fighting, true), _dip_of(fighting, true))
	_wear_fight_paint(_player, true, fighting)


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
			stands_at += _offset_of(fighting, false)
			_foot_figure(figure, stands_at, _dip_of(fighting, false))
			_wear_fight_paint(figure, false, fighting)
			figure.visible = true
			continue
		if figure.material_override != _figure_material and _figure_material != null:
			# The man you fought last time takes his own material back.
			figure.material_override = _figure_material
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
	# A blow taken on the guard leaves stun too, and it is shown braced, not flinching:
	# the guard is what you did, and the picture should say it worked.
	if mine and bool(fighting.get("blockstun", false)):
		stunned = 0
		guarding = true
	# **Down stays down** (H5). The beat outlasts the last blow's stun, and a man who
	# stood back up before the world came back would say he had not lost.
	if bool(fighting.get("felled" if mine else "his_down", false)):
		stunned = maxi(stunned, 1)
	var pose: StringName = CombatRules.pose_of(move, at_frame, stunned, guarding)
	# **The second design decides its own poses** (K4). A turn-based fight has no frame
	# data to read them out of, so the reading carries the pose itself — `DuelRules`
	# worked it out, and the window is handed it like everything else.
	if bool(fighting.get("turn_based", false)):
		pose = StringName(String(fighting.get("my_pose" if mine else "his_pose", "")))
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


## **How far a fighter is drawn from where he stands**, as an offset in tiles.
##
## The first design's fight runs along the world's east-west axis and nothing else, so
## its offset is one number on x — the lunge of a blow plus the shove of one taken.
## The second design is on the grid and a blow can be thrown in any of eight
## directions, so its offset is a vector along the striker's own facing; and **a blow
## does not move you** there (Yannick, 2026-09-24), so there is no shove in it at all.
func _offset_of(fighting: Dictionary, mine: bool) -> Vector2:
	if not bool(fighting.get("turn_based", false)):
		return Vector2(_lunge_of(fighting, mine) + _shove_of(fighting, mine), 0.0)
	var shape: float = float(fighting.get("my_lunge" if mine else "his_lunge", 0.0))
	if is_zero_approx(shape):
		return Vector2.ZERO
	var way: Vector2 = fighting.get("my_face" if mine else "his_face", Vector2.ZERO) as Vector2
	return way * shape * (FIGHT_THRUST_TILES if shape > 0.0 else FIGHT_LUNGE_TILES)


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
	if mine and move == &"" and (bool(fighting.get("guarding", false)) or bool(fighting.get("blockstun", false))):
		shape = CombatRules.guard_lean()
	# Back is short and forward is long: the wind-up keeps him on his foot mark, and the
	# blow is thrown far enough to be seen reaching the man it lands on.
	return shape * (FIGHT_THRUST_TILES if shape > 0.0 else FIGHT_LUNGE_TILES) * forward


## **How low he is carried this frame.** The other half of the tell, and the half a
## person reads first: he gathers through the wind-up and comes up as the blow goes out.
## A fighter who is down sinks a little further over the beat, and stays there.
func _dip_of(fighting: Dictionary, mine: bool) -> float:
	if fighting.is_empty():
		return 0.0
	var move := StringName(String(fighting.get("my_move" if mine else "his_move", "")))
	var at_frame: int = int(fighting.get("my_frame" if mine else "his_frame", 0))
	if bool(fighting.get("turn_based", false)) \
			and not bool(fighting.get("felled" if mine else "his_down", false)):
		return float(fighting.get("my_dip" if mine else "his_dip", 0.0))
	if bool(fighting.get("felled" if mine else "his_down", false)):
		var beat: int = int(fighting.get("settle_steps", 1))
		var left: int = int(fighting.get("settling", 0))
		var through: float = 1.0 - float(left) / float(maxi(beat, 1))
		return (KO_SINK_M / FIGHT_DIP_M) * minf(through * 2.5, 1.0)
	if mine and move == &"" and (bool(fighting.get("guarding", false)) or bool(fighting.get("blockstun", false))):
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
## **It is asked for again on the next `sync`**, because which of the two fights is
## running is in the reading and the reading has not arrived yet when this is called.
## Snapping to the first design's framing and then easing to the second's would put the
## camera halfway through moving in exactly the photograph this exists to prevent.
func snap_framing(fight_lens: float) -> void:
	_aim_lens(fight_lens)
	if _camera != null:
		_camera.size = lerpf(_zoom, _fight_size_m, clampf(fight_lens, 0.0, 1.0))
	_snap_wanted = fight_lens


## The lens follows the same eased point the 2D camera does, handed over in tiles.
func _sync_camera(eye_tiles: Vector2, fight_lens: float, delta: float) -> void:
	var want: Vector3 = _feet_of(eye_tiles)
	if not _focus_placed or _focus.distance_to(want) > 12.0:
		_focus = want
		_focus_placed = true
	else:
		_focus = _focus.lerp(want, 1.0 - exp(-CAMERA_CATCHES_UP * delta))
	var framing: float = lerpf(_zoom, _fight_size_m, clampf(fight_lens, 0.0, 1.0))
	_camera.size = lerpf(_camera.size, framing, 1.0 - exp(-10.0 * delta))
	# **The jolt of a hit** (H2): a decaying wobble of the lens on the frame a blow
	# lands, in the lens's own plane so the ground never appears to tilt. A function of
	# the window's clock and nothing random — the same hit jolts the same way twice.
	var jolt: Vector3 = Vector3.ZERO
	var since: float = _now - _shake_at
	if since >= 0.0 and since < SHAKE_SECONDS and _shake_amp > 0.0:
		var ease_out: float = 1.0 - since / SHAKE_SECONDS
		var strength: float = _shake_amp * ease_out * ease_out
		var right: Vector3 = _lens_up.cross(-_lens_offset).normalized()
		jolt = right * sin(since * 71.0) * strength + _lens_up * cos(since * 53.0) * strength * 0.55
	_camera.transform = Transform3D(Basis.looking_at(-_lens_offset, Vector3.UP),
		_focus + jolt + _lens_offset * CAMERA_DISTANCE)


# ----------------------------------------------------------------- the fight ---
#
# H group, 2026-09-21. The simulation of the fight was sound and nothing a player reads
# it through existed: no health, no tell, no reach, no floor, no beat. Everything below
# is a picture of what `Fight` and `CombatRules` already say, drawn once a frame from
# the reading `main.gd` hands over, and it writes nothing back.

## The blows this frame brought — `blow_landed`, `blow_missed`, `fight_decided` — read
## off the log by `main.gd` since the last frame drawn. Each becomes a shove, a flash,
## a spark, a jolt, or nothing, according to what it was.
func _take_blows(fighting: Dictionary, blows: Array) -> void:
	if fighting.is_empty() or blows.is_empty():
		return
	if _arena == null:
		# A blow on the fight's first drawn frame — a photograph asks for exactly that —
		# needs the spark pool the arena carries before the arena has been laid.
		_build_arena()
	var toward: int = int(fighting.get("toward", 1))
	for row: Variant in blows:
		var blow: Dictionary = row as Dictionary
		var kind: StringName = StringName(String(blow.get("type", "")))
		var by_me: bool = String(blow.get("by", "")) == "player"
		var move := StringName(String(blow.get("move", "")))
		if kind == &"blow_landed":
			var guarded: bool = bool(blow.get("guarded", false))
			var heavy: bool = int(blow.get("damage", 0)) >= 2 and not guarded
			var target: StringName = &"his" if by_me else &"mine"
			_struck[target] = {"at": _now, "guarded": guarded}
			# Shoved away from the man who hit them, for the hitstop the blow has —
			# except in the second design, where **a blow does not move you** and the
			# recoil is the flinch frame and nothing else (Yannick, 2026-09-24).
			if not bool(fighting.get("turn_based", false)):
				_shove = {"who": target, "dir": float(toward if by_me else -toward),
					"frames": maxi(CombatRules.hitstop(move), 1)}
			var between: Vector3 = _between(fighting, by_me)
			if guarded:
				_spark_burst(between, MARK_GUARD, 6, 1.6)
				_shake_at = _now
				_shake_amp = SHAKE_M * 0.3
			else:
				_spark_burst(between, MARK_INK, 10 if heavy else 7, 2.6 if heavy else 2.0)
				_spark_burst(between, MARK_MINE if by_me else MARK_HIS, 5, 1.4)
				_shake_at = _now
				_shake_amp = SHAKE_M * (1.0 if heavy else 0.6)
		elif kind == &"fight_decided" or kind == &"duel_decided":
			_shake_at = _now
			_shake_amp = SHAKE_M * 0.5


## Where a blow meets: at the defender's near edge, hip high, on the fight's line.
##
## On the grid there is no line, so it is simply between the two of them — which is the
## same place, said in a way that works when the blow is thrown north.
func _between(fighting: Dictionary, by_me: bool) -> Vector3:
	if bool(fighting.get("turn_based", false)):
		var mine: Vector2 = fighting.get("my_at", Vector2.ZERO) as Vector2
		var his: Vector2 = fighting.get("at", Vector2.ZERO) as Vector2
		return _ground(mine.lerp(his, 0.5), SWIPE_HEIGHT_M)
	var toward: int = int(fighting.get("toward", 1))
	var defender: Vector2 = (fighting.get("at", Vector2.ZERO) as Vector2) if by_me \
		else (fighting.get("my_at", Vector2.ZERO) as Vector2)
	var pushback: float = float(toward if by_me else -toward) * 0.22
	return _ground(defender - Vector2(pushback, 0.0), SWIPE_HEIGHT_M)


## How far the fighter who was just hit is drawn shoved, in tiles: the whole of
## `FIGHT_SHOVE_TILES` on the frame the blow lands, and back to nothing as the hitstop
## runs out. Drawn and not simulated — the knockback the simulation applies is where
## they *are*; this is the impact being felt.
func _shove_of(fighting: Dictionary, mine: bool) -> float:
	if fighting.is_empty() or _shove.is_empty():
		return 0.0
	if (_shove["who"] as StringName) != (&"mine" if mine else &"his"):
		return 0.0
	var freeze: int = int(fighting.get("freeze", 0))
	if freeze <= 0:
		return 0.0
	return float(_shove["dir"]) * FIGHT_SHOVE_TILES * float(freeze) / float(int(_shove["frames"]))


## The two fighters wear a shader of ours for the length of the fight, and his again
## after: it is what lets a hit show on the man who took it.
func _wear_fight_paint(figure: Node3D, mine: bool, fighting: Dictionary) -> void:
	var sprite := figure as AnimatedSprite3D
	if sprite == null or _figure_material == null:
		return
	if fighting.is_empty():
		if sprite.material_override != _figure_material:
			sprite.material_override = _figure_material
		return
	var who: StringName = &"mine" if mine else &"his"
	var paint: ShaderMaterial = _fight_paint_for(who)
	if sprite.material_override != paint:
		sprite.material_override = paint
	var flash: float = 0.0
	var tint: Color = Color.WHITE
	var struck: Dictionary = _struck.get(who, {}) as Dictionary
	if not struck.is_empty():
		var since: float = _now - float(struck["at"])
		var guarded: bool = bool(struck["guarded"])
		if since < FLASH_SECONDS:
			flash = (1.0 - since / FLASH_SECONDS) * (0.55 if guarded else 0.95)
			paint.set_shader_parameter("flash_colour", MARK_GUARD if guarded else Color.WHITE)
		if not guarded and since < BRUISE_SECONDS:
			var bruise: float = 1.0 - since / BRUISE_SECONDS
			tint = Color.WHITE.lerp(Color(1.0, 0.55, 0.5), bruise * 0.7)
	# **The wind-up shows on the body too** (H3): the figure warms toward its own colour
	# as the blow nears release — his toward ember, yours toward gold — on the same clock
	# as the ring at his feet. A second tell, on the thing the eye is already on.
	var move := StringName(String(fighting.get("my_move" if mine else "his_move", "")))
	var through: float = CombatRules.telegraph_at(move, int(fighting.get("my_frame" if mine else "his_frame", 0)))
	if through >= 0.0 and flash < 0.05:
		flash = 0.12 + 0.30 * through
		paint.set_shader_parameter("flash_colour", MARK_MINE if mine else MARK_HIS)
	if bool(fighting.get("felled" if mine else "his_down", false)):
		tint = tint * Color(0.5, 0.45, 0.45)
	paint.set_shader_parameter("flash", flash)
	paint.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))


func _fight_paint_for(who: StringName) -> ShaderMaterial:
	if _fight_paint.has(who):
		return _fight_paint[who] as ShaderMaterial
	var shader := Shader.new()
	shader.code = FIGHTER_SHADER
	var paint := ShaderMaterial.new()
	paint.shader = shader
	var his := _figure_material as ShaderMaterial
	if his != null:
		paint.set_shader_parameter("sprite_sheet", his.get_shader_parameter("sprite_sheet"))
	paint.set_shader_parameter("flash", 0.0)
	paint.set_shader_parameter("flash_colour", Color.WHITE)
	paint.set_shader_parameter("tint", Vector3.ONE)
	_fight_paint[who] = paint
	return paint


## The arena and its marks, once a frame while somebody is fighting; hidden otherwise.
func _sync_fight(fighting: Dictionary, fight_lens: float) -> void:
	var fighting_now: bool = not fighting.is_empty()
	if fighting_now and not _fighting_was:
		_struck = {}
		_shove = {}
	_fighting_was = fighting_now
	if _arena == null:
		if not fighting_now and fight_lens <= 0.002:
			return
		_build_arena()
	_arena.visible = fighting_now or fight_lens > 0.002
	if _arena_floor != null:
		_arena_floor.visible = fighting_now
	if fighting_now:
		var centre: Vector2 = fighting.get("centre", Vector2.ZERO) as Vector2
		var radius: float = float(fighting.get("radius_tiles", 2.0))
		var turn_based: bool = bool(fighting.get("turn_based", false))
		if centre.distance_to(_arena_floor_at) > 0.01:
			# **Softened, and no longer a boundary** (K4). The fight moves with the
			# people in it, so its floor is laid wherever they are and lighter than the
			# first design's — it says *you are in a fight*, not *you cannot leave*.
			_lay_floor(centre, radius, ARENA_FILL * 0.55 if turn_based else ARENA_FILL)
		if turn_based:
			_draw_duel_marks(fighting)
		else:
			_draw_marks(fighting)
	elif _arena_mesh != null:
		_arena_mesh.clear_surfaces()
	_sync_sparks()


func _build_arena() -> void:
	_arena = Node3D.new()
	_arena.name = "Arena"
	add_child(_arena)
	_mark_material = StandardMaterial3D.new()
	_mark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mark_material.vertex_color_use_as_albedo = true
	_mark_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mark_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mark_material.no_depth_test = false
	_mark_material.render_priority = 2
	_arena_floor = MeshInstance3D.new()
	_arena_floor.name = "Floor"
	_arena_floor.material_override = _mark_material
	_arena.add_child(_arena_floor)
	_arena_mesh = ImmediateMesh.new()
	_arena_marks = MeshInstance3D.new()
	_arena_marks.name = "Marks"
	_arena_marks.mesh = _arena_mesh
	_arena_marks.material_override = _mark_material
	_arena.add_child(_arena_marks)
	for i: int in SPARK_POOL:
		var spark: Sprite3D = _dot_sprite()
		spark.name = "Spark_%d" % i
		spark.visible = false
		spark.render_priority = 3
		_arena.add_child(spark)
		_sparks.append(spark)
		_spark_state.append({})


## **The floor** (H4): the fight's ground, darkened, in the stadium shape of a line
## with a wall at each end — laid on his terrain point by point so it lies on a slope
## as it lies on the flat. It says where the fight is; the rim drawn over it says where
## it stops. Rebuilt only when the arena moves, which is once a fight.
func _lay_floor(centre: Vector2, radius: float, fill: Color = ARENA_FILL) -> void:
	_arena_floor_at = centre
	var vertices := PackedVector3Array()
	var colours := PackedColorArray()
	var indices := PackedInt32Array()
	var rings: int = 4
	var around: int = 44
	vertices.append(_ground(centre, MARK_LIFT_M * 0.5))
	colours.append(fill)
	for ring: int in range(1, rings + 1):
		var share: float = float(ring) / float(rings)
		for k: int in around:
			var angle: float = TAU * float(k) / float(around)
			var edge: Vector2 = _stadium_point(angle, radius, ARENA_DEPTH_TILES)
			vertices.append(_ground(centre + edge * share, MARK_LIFT_M * 0.5))
			colours.append(Color(fill.r, fill.g, fill.b, fill.a * (1.0 if ring < rings else 0.55)))
	for k: int in around:
		indices.append_array(PackedInt32Array([0, 1 + (k + 1) % around, 1 + k]))
	for ring: int in range(1, rings):
		var inner: int = 1 + (ring - 1) * around
		var outer: int = 1 + ring * around
		for k: int in around:
			var a: int = inner + k
			var b: int = inner + (k + 1) % around
			var c: int = outer + k
			var d: int = outer + (k + 1) % around
			indices.append_array(PackedInt32Array([a, d, c, a, b, d]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_arena_floor.mesh = mesh


## A point on a stadium — a rectangle with round ends — of half-length `radius` along
## the fight's line and half-depth `depth` across it, in tiles from its centre.
func _stadium_point(angle: float, radius: float, depth: float) -> Vector2:
	var straight: float = maxf(radius - depth, 0.0)
	var unit := Vector2(cos(angle), sin(angle))
	return Vector2(unit.x * depth + signf(unit.x) * straight, unit.y * depth)


## **The marks** (H3, H4): the rim and its two walls, a mark under each fighter's feet
## the size of the pushbox, each fighter's reach as an arc on the ground toward the
## other, the ring that fills through a wind-up, and the swipe of a blow that is out.
## Redrawn every frame from the reading, into one mesh.
func _draw_marks(fighting: Dictionary) -> void:
	_arena_mesh.clear_surfaces()
	_arena_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var centre: Vector2 = fighting.get("centre", Vector2.ZERO) as Vector2
	var radius: float = float(fighting.get("radius_tiles", 2.0))
	var toward: int = int(fighting.get("toward", 1))
	var me: Vector2 = fighting.get("my_at", Vector2.ZERO) as Vector2
	var him: Vector2 = fighting.get("at", Vector2.ZERO) as Vector2
	var apart: int = int(fighting.get("apart_mm", 0))
	var foot: float = float(fighting.get("pushbox_tiles", 0.45)) * 0.5
	var settling: bool = int(fighting.get("settling", 0)) > 0

	# The rim, and the two walls brighter — brighter still when somebody is against one.
	# Through the beat the rim takes the winner's colour: gold when he is down, ember
	# when you are, so the ring itself says how it went before a word is read.
	var rim_tone: Color = MARK_INK
	if settling:
		rim_tone = MARK_MINE if String(fighting.get("outcome", "")) == "won" else MARK_HIS
	var rim := Color(rim_tone.r, rim_tone.g, rim_tone.b, 0.55 if settling else 0.28)
	_ring(centre, radius, ARENA_DEPTH_TILES, 0.07 if settling else 0.05, rim)
	for side: int in [-1, 1]:
		var wall_x: float = centre.x + float(side) * radius
		var near: float = minf(absf(me.x - wall_x), absf(him.x - wall_x))
		var glow: float = clampf(1.0 - near / 0.6, 0.0, 1.0)
		var wall := Color(rim_tone.r, rim_tone.g, rim_tone.b, 0.45 + 0.5 * glow)
		_arc(Vector2(wall_x - float(side) * ARENA_DEPTH_TILES, centre.y), ARENA_DEPTH_TILES,
			(-70.0 if side > 0 else 110.0), (70.0 if side > 0 else 250.0), 0.09 + 0.06 * glow, wall, 18)

	# **The guard, visible while it is up** (H2): a line braced in front of you, sage,
	# hip to shoulder; white and thick through the stun a blow on it leaves, so a guarded
	# hit and a clean one are two different pictures and not one pip's difference.
	var guarding: bool = bool(fighting.get("guarding", false))
	var blockstun: bool = bool(fighting.get("blockstun", false))
	if guarding or blockstun:
		var ahead: Vector2 = me + Vector2(float(toward) * 0.36, 0.0)
		var foot_point: Vector3 = _ground(ahead, 0.55)
		var shoulder: Vector3 = foot_point + Vector3.UP * 0.75
		var tone := Color(1.0, 1.0, 1.0, 0.95) if blockstun else Color(MARK_GUARD.r, MARK_GUARD.g, MARK_GUARD.b, 0.8)
		var half := Vector3(float(toward) * (0.11 if blockstun else 0.06), 0.0, 0.0)
		_quad(foot_point - half, foot_point + half, shoulder + half, shoulder - half, tone, tone)

	# Feet: where each of them *is*, which is what every reach is measured from.
	var mine := Color(MARK_MINE.r, MARK_MINE.g, MARK_MINE.b, 0.85)
	var his := Color(MARK_HIS.r, MARK_HIS.g, MARK_HIS.b, 0.85)
	_ring(me, foot, foot * 0.72, 0.045, mine)
	_ring(him, foot, foot * 0.72, 0.045, his)

	if not settling:
		# Reach, as an arc toward the other. Yours brightens when he is inside it — the
		# whole of spacing in one glance. His two: the heavy blow's, thin and far; the
		# short one's, thicker and near, so the band between them can be seen and stood in.
		var my_reach: float = CombatRules.tiles_of(int(fighting.get("my_reach_mm", 0)))
		var can_hit: bool = apart <= int(fighting.get("my_reach_mm", 0))
		var face_him: float = 0.0 if toward > 0 else 180.0
		var my_arc := Color(MARK_MINE.r, MARK_MINE.g, MARK_MINE.b, 0.95 if can_hit else 0.38)
		_arc(me, my_reach, face_him - 52.0, face_him + 52.0, 0.075 if can_hit else 0.045, my_arc, 26)
		var face_me: float = 180.0 - face_him
		var swing: int = int(fighting.get("his_swing_mm", 0))
		var jab: int = int(fighting.get("his_jab_mm", 0))
		var in_swing: bool = apart <= swing
		var in_jab: bool = apart <= jab
		var swing_arc := Color(MARK_HIS.r, MARK_HIS.g, MARK_HIS.b, 0.75 if in_swing else 0.30)
		var jab_arc := Color(MARK_HIS.r, MARK_HIS.g, MARK_HIS.b, 0.95 if in_jab else 0.35)
		_arc(him, CombatRules.tiles_of(swing), face_me - 46.0, face_me + 46.0, 0.045 if in_swing else 0.03, swing_arc, 26)
		_arc(him, CombatRules.tiles_of(jab), face_me - 56.0, face_me + 56.0, 0.08 if in_jab else 0.05, jab_arc, 26)

		# The telegraph: a ring at the feet of whoever is winding up, filling from the
		# frame the wind-up starts to the frame the blow is out. `CombatRules.telegraph_at`
		# is the clock; this is only the picture. His is ember, yours gold.
		_telegraph(him, StringName(String(fighting.get("his_move", ""))), int(fighting.get("his_frame", 0)), MARK_HIS)
		_telegraph(me, StringName(String(fighting.get("my_move", ""))), int(fighting.get("my_frame", 0)), MARK_MINE)

	# The swipe: the blow itself, drawn out to where it reaches, on the frames it is out
	# and fading through the recovery — so a blow that lands is seen touching, and a blow
	# that misses is seen missing.
	_swipe(me, StringName(String(fighting.get("my_move", ""))), int(fighting.get("my_frame", 0)),
		float(toward), bool(fighting.get("my_connected", false)), MARK_MINE)
	_swipe(him, StringName(String(fighting.get("his_move", ""))), int(fighting.get("his_frame", 0)),
		float(-toward), bool(fighting.get("his_connected", false)), MARK_HIS)
	_arena_mesh.surface_end()


## **The second design's marks** (K4, `docs/COMBAT_V2.md`). Same mesh, same colours,
## same voice as the HUD — and a different picture, because it is a different game.
##
## What it draws, and why each of them:
##
## - **The tiles a turn buys**, faintly, under whoever is acting. The cap on movement
##   *is* what spacing means here (§4), so showing it is showing the whole of the
##   decision. It is the one mark the first design had no need of.
## - **The tile the player has chosen to stand on**, brighter, while it is their turn.
## - **A ring at each fighter's feet** — where they are, which is what reach measures
##   from — and **the reach itself**, one tile, round whoever is acting: full when
##   somebody is inside it, faint when nobody is.
## - **The soft rim**, and this is the thing that changed. The first design drew a rim
##   and two walls that brightened as a fighter was pressed against them, because there
##   *was* a wall. There is none now: nothing stops the player leaving and nothing stops
##   an enemy fleeing, so the rim is a vignette that fades outward and no wall is drawn
##   at all. A boundary drawn here would be a boundary the simulation does not have.
## - **The wind-up and the blow**, as the first design draws them.
func _draw_duel_marks(fighting: Dictionary) -> void:
	_arena_mesh.clear_surfaces()
	_arena_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var me: Vector2 = fighting.get("my_at", Vector2.ZERO) as Vector2
	var him: Vector2 = fighting.get("at", Vector2.ZERO) as Vector2
	var settling: bool = int(fighting.get("settling", 0)) > 0
	var mine_acting: bool = bool(fighting.get("my_turn", false))

	# **No rim is drawn on the ground at all**, and that is the change. The first design
	# drew one, with two walls that brightened as a fighter was pressed against them,
	# because `CombatRules.inside_arena` was a wall you could be pressed against. There
	# is none now: nothing stops the player leaving and nothing stops an enemy fleeing,
	# and a circle on his grass would say otherwise every frame. What is left of the
	# ring is the darkened edge of the screen — dimmed for this fight in `main.gd` — and
	# the floor under the two of them, which moves with them. Through the beat the floor
	# is all there is, so the winner's colour is said by the feet instead.
	if not settling:
		# What a turn buys, and where the player has decided to stand. **This is the
		# mark the first design had no need of**: the cap on movement is the whole of
		# what spacing means here (`docs/COMBAT_V2.md` §4), so the tiles a turn reaches
		# are the decision, drawn.
		var acting: Vector2 = me if mine_acting else him
		var voice: Color = MARK_MINE if mine_acting else MARK_HIS
		for row: Variant in fighting.get("moves", []) as Array:
			_tile_patch(row as Vector2, Color(voice.r, voice.g, voice.b, 0.17))
		if fighting.has("cursor"):
			_tile_patch(fighting["cursor"] as Vector2, Color(voice.r, voice.g, voice.b, 0.42))
			_ring(fighting["cursor"] as Vector2, 0.46, 0.34, 0.06,
				Color(voice.r, voice.g, voice.b, 0.95), 24)
		# Reach: one tile, round whoever is acting, full when it has somebody in it.
		var reach: float = float(fighting.get("reach_tiles", 1))
		var can_hit: bool = bool(fighting.get("in_reach", false))
		_ring(acting, reach, reach * 0.70, 0.075 if can_hit else 0.045,
			Color(voice.r, voice.g, voice.b, 0.9 if can_hit else 0.32), 36)

	# Feet: where each of them *is*, drawn last so they sit over the field of tiles. On
	# the beat they widen and take the winner's colour, which is the job the first
	# design gave its rim — said by the ground the two of them are standing on, now that
	# there is no rim to say it with.
	var mine_foot: Color = MARK_MINE
	var his_foot: Color = MARK_HIS
	var thickness: float = 0.045
	if settling:
		var won: bool = String(fighting.get("outcome", "")) == "won"
		mine_foot = MARK_MINE if won else Color(MARK_MINE.r, MARK_MINE.g, MARK_MINE.b, 0.4)
		his_foot = MARK_HIS if not won else Color(MARK_HIS.r, MARK_HIS.g, MARK_HIS.b, 0.4)
		thickness = 0.08
	_ring(me, 0.30, 0.21, thickness, Color(mine_foot.r, mine_foot.g, mine_foot.b, 0.85 * mine_foot.a))
	_ring(him, 0.30, 0.21, thickness, Color(his_foot.r, his_foot.g, his_foot.b, 0.85 * his_foot.a))

	if not settling:
		_duel_telegraph(me, float(fighting.get("my_telegraph", -1.0)), MARK_MINE)
		_duel_telegraph(him, float(fighting.get("his_telegraph", -1.0)), MARK_HIS)
	_duel_swipe(me, him, fighting, true, MARK_MINE)
	_duel_swipe(him, me, fighting, false, MARK_HIS)
	_arena_mesh.surface_end()


## One tile of the grid, laid flat on his ground. Slightly inset, so a field of them
## reads as tiles and not as one sheet.
func _tile_patch(centre_tiles: Vector2, colour: Color) -> void:
	var half: float = 0.42
	_quad(
		_ground(centre_tiles + Vector2(-half, -half), MARK_LIFT_M * 0.8),
		_ground(centre_tiles + Vector2(half, -half), MARK_LIFT_M * 0.8),
		_ground(centre_tiles + Vector2(half, half), MARK_LIFT_M * 0.8),
		_ground(centre_tiles + Vector2(-half, half), MARK_LIFT_M * 0.8),
		colour, colour)


## The telegraph, against a fraction the fight worked out rather than against frame
## data: −1 is nothing winding up, 0 is a tell just begun, 1 is the blow about to land.
func _duel_telegraph(feet: Vector2, through: float, colour: Color) -> void:
	if through < 0.0:
		return
	var radius: float = TELEGRAPH_RADIUS_M / _metres_per_tile
	_arc(feet, radius, -90.0, -90.0 + 360.0 * clampf(through, 0.0, 1.0), 0.09,
		Color(colour.r, colour.g, colour.b, 0.55 + 0.4 * through), 32)


## The blow itself, drawn from the one throwing it to the one it is thrown at, on the
## steps it is out — so a blow is seen touching the man it lands on however he is stood.
func _duel_swipe(from: Vector2, to: Vector2, fighting: Dictionary, mine: bool, colour: Color) -> void:
	if String(fighting.get("my_pose" if mine else "his_pose", "")) != "attack":
		return
	var reach: float = float(fighting.get("reach_tiles", 1))
	var way: Vector2 = (to - from)
	if way.length() < 0.001:
		return
	way = way.normalized()
	var points := PackedVector3Array([
		_ground(from + way * 0.25, SWIPE_HEIGHT_M),
		_ground(from + way * reach * 0.75, SWIPE_HEIGHT_M * 1.05),
	])
	_ribbon(points, SWIPE_THICKNESS_M, Color(colour.r, colour.g, colour.b, 0.9))


func _telegraph(feet: Vector2, move: StringName, frame: int, colour: Color) -> void:
	var through: float = CombatRules.telegraph_at(move, frame)
	var radius: float = TELEGRAPH_RADIUS_M / _metres_per_tile
	if through < 0.0:
		if move != &"" and CombatRules.is_attack(move) and CombatRules.is_active(move, frame):
			# Out: the ring is full and white for the frames the blow is live.
			_arc(feet, radius, 0.0, 360.0, 0.11, Color(1.0, 1.0, 1.0, 0.95), 32)
		return
	# The heavy blow's ring is the bigger, from its first frame, so which of the two is
	# coming can be told before either is close to landing.
	var heavy: bool = CombatRules.of(move, "startup") >= 24
	radius *= 1.4 if heavy else 1.0
	var faint := Color(colour.r, colour.g, colour.b, 0.35)
	_arc(feet, radius, 0.0, 360.0, 0.05, faint, 32)
	# The filling arc goes from the fighter's colour toward white as the blow nears, and
	# thickens: what is about to land should be the brightest thing on the ground.
	var lit: Color = colour.lerp(Color.WHITE, through * 0.6)
	lit.a = 0.8 + 0.2 * through
	_arc(feet, radius, -90.0, -90.0 + 360.0 * maxf(through, 0.04), 0.11 + 0.07 * through, lit, 32)


func _swipe(feet: Vector2, move: StringName, frame: int, forward: float, connected: bool, colour: Color) -> void:
	if move == &"" or not CombatRules.is_attack(move) or CombatRules.is_winding_up(move, frame):
		return
	var live: bool = CombatRules.is_active(move, frame)
	var strength: float = 1.0 if live else CombatRules.lunge_at(move, frame) * 0.7
	if strength <= 0.02:
		return
	var reach: float = CombatRules.tiles_of(CombatRules.of(move, "reach_mm") + CombatRules.slack_mm())
	var from: Vector3 = _ground(feet, SWIPE_HEIGHT_M) + Vector3(forward * 0.25 * _metres_per_tile, 0.0, 0.0)
	var to: Vector3 = _ground(feet + Vector2(forward * reach, 0.0), SWIPE_HEIGHT_M)
	to.y = from.y
	var tone: Color = Color(1.0, 1.0, 1.0, 0.9) if (live and connected) else Color(colour.r, colour.g, colour.b, 0.75 * strength)
	var thickness: float = SWIPE_THICKNESS_M * (1.0 if live else 0.6)
	# A ribbon standing up in the fight's plane, thick where it starts and tapering.
	var up: Vector3 = Vector3.UP * thickness * 0.5
	_quad(from - up, from + up, to + up * 0.35, to - up * 0.35, tone,
		Color(tone.r, tone.g, tone.b, tone.a * 0.25))


## A ring on the ground: an ellipse of half-width `rx` along the line and `rz` across it.
func _ring(centre: Vector2, rx: float, rz: float, thickness_m: float, colour: Color, steps: int = 40) -> void:
	var points := PackedVector3Array()
	for k: int in steps + 1:
		var angle: float = TAU * float(k) / float(steps)
		points.append(_ground(centre + Vector2(cos(angle) * rx, sin(angle) * rz), MARK_LIFT_M))
	_ribbon(points, thickness_m, colour)


## An arc on the ground, degrees from `from` to `to`, 0 being east along the line.
func _arc(centre: Vector2, radius: float, from: float, to: float, thickness_m: float, colour: Color, steps: int = 24) -> void:
	var points := PackedVector3Array()
	for k: int in steps + 1:
		var angle: float = deg_to_rad(lerpf(from, to, float(k) / float(steps)))
		points.append(_ground(centre + Vector2(cos(angle), sin(angle)) * radius, MARK_LIFT_M))
	_ribbon(points, thickness_m, colour)


## A flat ribbon along a polyline, `thickness_m` wide in the ground plane.
func _ribbon(points: PackedVector3Array, thickness_m: float, colour: Color) -> void:
	if points.size() < 2:
		return
	var half: float = thickness_m * 0.5
	for i: int in points.size() - 1:
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var along := Vector3(b.x - a.x, 0.0, b.z - a.z)
		if along.length_squared() < 0.000001:
			continue
		var side: Vector3 = along.normalized().cross(Vector3.UP) * half
		_quad(a - side, a + side, b + side, b - side, colour, colour)


func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, near: Color, far: Color) -> void:
	_arena_mesh.surface_set_color(near)
	_arena_mesh.surface_add_vertex(a)
	_arena_mesh.surface_set_color(near)
	_arena_mesh.surface_add_vertex(b)
	_arena_mesh.surface_set_color(far)
	_arena_mesh.surface_add_vertex(c)
	_arena_mesh.surface_set_color(near)
	_arena_mesh.surface_add_vertex(a)
	_arena_mesh.surface_set_color(far)
	_arena_mesh.surface_add_vertex(c)
	_arena_mesh.surface_set_color(far)
	_arena_mesh.surface_add_vertex(d)


## A point on his ground at a tile position, lifted `lift` metres.
func _ground(at_tiles: Vector2, lift: float) -> Vector3:
	var metres: Vector2 = _origin_m + at_tiles * _metres_per_tile
	return Vector3(metres.x, height_at(metres.x, metres.y) + lift, metres.y)


## Sparks: a handful of dots thrown from where a blow met, on fixed directions — the
## golden angle, so no two go the same way and no coin is tossed — falling and fading.
func _spark_burst(at: Vector3, colour: Color, count: int, speed: float) -> void:
	if _sparks.is_empty():
		return
	for i: int in count:
		var index: int = _spark_next % _sparks.size()
		_spark_next += 1
		var angle: float = float(_spark_next) * 2.399963
		var direction := Vector3(cos(angle), 0.55 + 0.45 * absf(sin(angle * 1.7)), sin(angle) * 0.5).normalized()
		_spark_state[index] = {"born": _now, "from": at, "dir": direction * speed * (0.7 + 0.3 * fposmod(angle, 1.0)), "colour": colour}
		_sparks[index].visible = true


func _sync_sparks() -> void:
	for i: int in _sparks.size():
		var state: Dictionary = _spark_state[i]
		var spark: Sprite3D = _sparks[i]
		if state.is_empty():
			spark.visible = false
			continue
		var age: float = _now - float(state["born"])
		if age > SPARK_SECONDS:
			_spark_state[i] = {}
			spark.visible = false
			continue
		var life: float = age / SPARK_SECONDS
		var velocity: Vector3 = state["dir"] as Vector3
		spark.position = (state["from"] as Vector3) + velocity * age + Vector3.DOWN * 4.0 * age * age
		var colour: Color = state["colour"] as Color
		spark.modulate = Color(colour.r, colour.g, colour.b, (1.0 - life) * (1.0 - life))
		spark.pixel_size = 0.028 * (1.0 - life * 0.6)
		spark.visible = true


## Where a point over the ground lands on the screen, for the HUD to hang a word on.
## In the viewport's own pixels, so a figure and the number it just lost line up.
func screen_of(at_tiles: Vector2, height_m: float) -> Vector2:
	if _camera == null:
		return Vector2(-1.0, -1.0)
	var point: Vector3 = _ground(at_tiles, height_m)
	if _camera.is_position_behind(point):
		return Vector2(-1.0, -1.0)
	return _camera.unproject_position(point)


## For the suite: is the fight's picture up, and how many sparks are in the air.
func arena_shown() -> bool:
	return _arena != null and _arena.visible and _arena_floor != null and _arena_floor.visible


func sparks_alive() -> int:
	var alive: int = 0
	for state: Dictionary in _spark_state:
		if not state.is_empty():
			alive += 1
	return alive


func fighters_wear_our_paint() -> bool:
	var sprite := _player as AnimatedSprite3D
	return sprite != null and sprite.material_override != null \
		and sprite.material_override != _figure_material


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
