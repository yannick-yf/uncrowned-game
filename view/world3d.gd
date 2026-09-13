class_name World3d
extends Node3D

## The 3D window over the baked world (MIGRATION_3D §6, M2a).
##
## A **window, not a world**: it reads the simulation and places things. The ground is
## his — the workshop's heights, water and paint, read from the same four files the
## bake reads — built here as plain meshes with vertex colours; the people, the fires,
## the buildings and the trees are the pixel figures the 2D window draws, stood up as
## billboards on that ground, because §13's default until the cast is redrawn in his
## style is *the pixel figures ride the 3D world and the mismatch is listed as
## transition*. His own meshes and shaders come in at M2b; nothing here depends on
## them, and nothing here moves anybody: the player's position arrives from
## `main.gd` every frame, already interpolated, and goes nowhere but into a
## transform.
##
## Coordinates are BakeRules' contract: his metres, origin at the centre, north at
## -Z; a tile's centre is `origin + (tile + 0.5) * 2 m`, and a height comes from his
## grid bilinearly, as his `flat_ground.gd` samples it.

## His camera, in numbers: orthographic, tilted, following. The numbers are the
## workshop's `follow_camera` as the Brindle scene sets it.
const TILT_DEGREES: float = 48.0
const AZIMUTH_DEGREES: float = 0.0
const CAMERA_SIZE: float = 24.0
const CAMERA_DISTANCE: float = 45.0
## The same easing as the 2D camera, so the two windows feel alike.
const CAMERA_CATCHES_UP: float = 7.0
## Sixteen pixels stand 1.6 metres: a figure as tall as a person.
const PIXEL_METRES: float = 0.1
## A billboard's feet, just off the ground so they never z-fight with it.
const FOOT_CLEARANCE: float = 0.04
## Terrain is built in chunks of this many cells a side.
const CHUNK_CELLS: int = 48
## A film of water thinner than this is a wet bank, not water.
const WATER_SHOWS_FROM: float = 0.02
## The escort's ranks in front of the gate, as the 2D window draws them.
const ESCORT_FILES: int = 5

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
var _lens_offset: Vector3 = Vector3.UP
var _focus: Vector3 = Vector3.ZERO
var _focus_placed: bool = false

var _player: Sprite3D = null
var _people: Dictionary = {}
var _traffic: Dictionary = {}
var _guards: Array[Sprite3D] = []
## One entry per prop of the region: the prop itself and the sprite standing for it.
var _props: Array[Dictionary] = []
var _fairy: OmniLight3D = null
var _fairy_glow: Sprite3D = null
## The marks over the heads of whoever can see you, and the embers over fires and
## kilns — the 2D window's immediate register and its particles, in the window.
var _marks: Array[Sprite3D] = []
var _embers: Array[Dictionary] = []
var _dot: Texture2D = null
## How far a sprite standing between the player and the lens fades, and the 2D rule
## it copies: a building you are behind goes part transparent so walking behind the
## counting house does not mean disappearing.
const OCCLUDED_ALPHA: float = 0.45

var chunk_count: int = 0
var water_triangles: int = 0
var tree_count: int = 0


# ------------------------------------------------------------------ building ---

## Everything that does not move: his ground and water, the trees, the props, the
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
	_build_light()
	_build_ground()
	_build_water()
	_build_trees()
	_build_props()
	_build_fairy()
	_build_embers()


func _build_camera() -> void:
	var tilt: float = deg_to_rad(TILT_DEGREES)
	var azimuth: float = deg_to_rad(AZIMUTH_DEGREES)
	_lens_offset = Vector3(sin(azimuth) * cos(tilt), sin(tilt), cos(azimuth) * cos(tilt))
	var forward: Vector3 = -_lens_offset
	_lens_up = (Vector3.UP - forward * Vector3.UP.dot(forward)).normalized()
	_camera = Camera3D.new()
	_camera.name = "Lens"
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = CAMERA_SIZE
	_camera.near = 0.5
	_camera.far = 400.0
	_camera.current = true
	add_child(_camera)


func _build_light() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 1.1
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = false
	sun.transform = Transform3D(Basis.looking_at(Vector3(-0.5, -1.0, -0.35).normalized(), Vector3.UP), Vector3.ZERO)
	add_child(sun)
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


## His heights as chunks of triangles, coloured by the *baked* terrain kind — the
## same colours the map screen uses — shaded by his slope paint so a bank reads as
## a bank. The colour is what the simulation says the ground is, so a road laid by
## the bake is a road here too, whatever his paint says under it.
func _build_ground() -> void:
	if _samples < 2:
		return
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	# Both faces, so the winding of the triangles can never turn the ground into sky —
	# which is exactly what the first frame of this window was: sprites on a blue field.
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
	# Open ground takes his paint: rock greys it, sand pales it. Anything the bake or
	# the kit laid — road, town, wood, field — keeps its own colour, because that is
	# what the ground *is* now.
	if kind == Region.Terrain.WILD or kind == Region.Terrain.MOUNTAIN or kind == Region.Terrain.SAND:
		colour = colour.lerp(Color(0.46, 0.45, 0.44), rock * 0.7)
		colour = colour.lerp(Color(0.72, 0.66, 0.48), sand * 0.6)
	# Under water the ground is drawn anyway; darkened, so the shallows read as depth.
	if kind == Region.Terrain.WATER or kind == Region.Terrain.SEA:
		colour = colour.darkened(0.35)
	return colour


## Water is a second surface at his water level, wherever it stands above the ground.
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


## Trees and scrub, one billboard per tile the 2D window would scatter on — the same
## hash, the same sprite — as one MultiMesh per sprite, because a wood is thousands.
func _build_trees() -> void:
	var groups: Dictionary = {}
	for y: int in _region.height:
		for x: int in _region.width:
			var entry: Array = _art.scatter_at(_region.terrain_at(Vector2i(x, y)), x, y)
			if entry.is_empty():
				continue
			var key: String = "%s:%s" % [String(entry[0]), str(entry[1])]
			if not groups.has(key):
				# A plain Array, which is a reference: a packed array pulled out of a
				# dictionary is a copy, and appending to the copy planted nothing.
				groups[key] = {"atlas": entry[0], "rect": entry[1], "tiles": [] as Array[Vector2i]}
			(groups[key]["tiles"] as Array[Vector2i]).append(Vector2i(x, y))
	var scrub := Node3D.new()
	scrub.name = "Scrub"
	add_child(scrub)
	for key: String in groups.keys():
		var group: Dictionary = groups[key] as Dictionary
		var atlas: Texture2D = _art.atlas(group["atlas"] as StringName)
		if atlas == null:
			continue
		var rect: Rect2i = group["rect"] as Rect2i
		var tiles: Array[Vector2i] = group["tiles"] as Array[Vector2i]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = _quad_for(atlas, rect)
		multimesh.instance_count = tiles.size()
		var half_height: float = float(rect.size.y) * PIXEL_METRES * 0.5
		for i: int in tiles.size():
			var tile: Vector2i = tiles[i]
			var feet: Vector3 = _feet_of(Vector2(tile) + Vector2(0.5, 1.0))
			multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, feet + _lens_up * half_height))
		var instance := MultiMeshInstance3D.new()
		instance.name = "Scrub_%s" % key.replace(":", "_").replace(" ", "")
		instance.multimesh = multimesh
		instance.material_override = _sprite_material(atlas)
		scrub.add_child(instance)
		tree_count += tiles.size()


## A quad showing one rectangle of an atlas, its size that of the sprite in metres.
func _quad_for(atlas: Texture2D, rect: Rect2i) -> ArrayMesh:
	var w: float = float(rect.size.x) * PIXEL_METRES
	var h: float = float(rect.size.y) * PIXEL_METRES
	var size: Vector2 = atlas.get_size()
	var u0: float = float(rect.position.x) / size.x
	var v0: float = float(rect.position.y) / size.y
	var u1: float = float(rect.end.x) / size.x
	var v1: float = float(rect.end.y) / size.y
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(-w * 0.5, h * 0.5, 0.0), Vector3(w * 0.5, h * 0.5, 0.0),
		Vector3(w * 0.5, -h * 0.5, 0.0), Vector3(-w * 0.5, -h * 0.5, 0.0)])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([
		Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 2, 1, 0, 3, 2])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Pixels stood up: unshaded, nearest-filtered, cut at the alpha edge, always facing
## the lens.
func _sprite_material(atlas: Texture2D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = atlas
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.5
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.billboard_keep_scale = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


## Every prop the region records, as the sprite the 2D window draws for it, footed on
## the bottom of its footprint and centred across it. Which ones show is decided
## each frame (`sync`): tents by the army, fences by who holds the Acres, the crowd
## by how many left the Muster.
func _build_props() -> void:
	var stand := Node3D.new()
	stand.name = "Props"
	add_child(stand)
	var folk: int = 0
	for prop: Dictionary in _region.props:
		var kind: StringName = prop["kind"] as StringName
		var at: Vector2i = prop["at"] as Vector2i
		var size: Vector2i = prop.get("size", Vector2i(4, 3)) as Vector2i
		var sprite: Sprite3D = null
		if kind == &"townsfolk":
			folk += 1
			sprite = _figure(_art.townsfolk_sheet(folk), Art.FACE_DOWN)
			_foot(sprite, Vector2(at) + Vector2(0.5, 1.0))
		else:
			var entry: Array = _art.props.get(kind, []) as Array
			if entry.is_empty():
				continue
			var atlas: Texture2D = _art.atlas(entry[0] as StringName)
			if atlas == null:
				continue
			sprite = _billboard(atlas, Rect2(entry[1] as Rect2i))
			_foot(sprite, Vector2(at) + Vector2(float(size.x) * 0.5, float(size.y)))
		sprite.name = "%s_%d_%d" % [kind, at.x, at.y]
		stand.add_child(sprite)
		_props.append({"prop": prop, "node": sprite, "index": folk if kind == &"townsfolk" else 0})


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
	_fairy_glow = _billboard(_soft_dot(), Rect2(0.0, 0.0, 16.0, 16.0))
	_fairy_glow.name = "FairyGlow"
	_fairy_glow.pixel_size = PIXEL_METRES * 1.5
	_fairy_glow.modulate = Color(0.80, 0.96, 0.82, 0.55)
	_fairy_glow.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	_fairy_glow.visible = false
	_fairy.add_child(_fairy_glow)


## A 16-pixel soft disc, made once: the one thing here the pack does not supply, and
## §13 forbids borrowing it from another pack. Used for the fairy's glow, the marks
## over witnesses' heads and the embers.
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


## Embers over every kiln and every fire: a handful of dots each, on their own
## periods, so the group never pulses together — which is the thing that reads as
## fake. Whether a kiln glows is the frame's to say: a freed Cinderworks is cold.
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
		var base: Vector3 = _feet_of(Vector2(at) + Vector2(float(size.x) * 0.5, float(size.y) * 0.5))
		var dots: Array[Sprite3D] = []
		for i: int in count:
			var dot: Sprite3D = _billboard(_soft_dot(), Rect2(0.0, 0.0, 16.0, 16.0))
			dot.name = "Ember_%d_%d_%d" % [at.x, at.y, i]
			dot.pixel_size = PIXEL_METRES * 0.25
			dot.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
			hearths.add_child(dot)
			dots.append(dot)
		_embers.append({"kind": kind, "base": base, "dots": dots})


# ------------------------------------------------------------------- sprites ---

## A pixel sprite standing on the ground, leaning toward the lens.
func _billboard(atlas: Texture2D, rect: Rect2) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = atlas
	sprite.region_enabled = true
	sprite.region_rect = rect
	sprite.pixel_size = PIXEL_METRES
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.double_sided = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return sprite


## One of the cast, the crowd or the guard: a 16-pixel face from its sheet.
func _figure(sheet: Texture2D, column: int) -> Sprite3D:
	return _billboard(sheet, Art.tile_rect(column, 0))


## Put a sprite's feet on the ground at a tile position (tiles, fractional), lifted
## along the lens's up by half its height so it stands rather than lies.
func _foot(sprite: Sprite3D, at_tiles: Vector2) -> void:
	var half_height: float = sprite.region_rect.size.y * PIXEL_METRES * 0.5
	sprite.position = _feet_of(at_tiles) + _lens_up * half_height


## A tile position (fractional tiles) as a point on his ground.
func _feet_of(at_tiles: Vector2) -> Vector3:
	var metres: Vector2 = _origin_m + at_tiles * _metres_per_tile
	return Vector3(metres.x, height_at(metres.x, metres.y) + FOOT_CLEARANCE, metres.y)


## His ground's height at a point, bilinearly, as his `flat_ground.gd` samples it.
func height_at(x_m: float, z_m: float) -> float:
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
## free, whether the castle is shuttered, and the escort at the gate. Nothing here
## writes back.
func sync(frame: Dictionary, delta: float) -> void:
	if _region == null or _sim == null:
		return
	var world := _sim.store(&"world") as WorldState
	var cast := _sim.store(&"cast") as Cast
	var road := _sim.store(&"travellers") as Travellers
	_sync_player(frame)
	_sync_people(cast, world)
	_sync_traffic(road, world)
	_sync_guards(world, int(frame.get("escort", 0)), int(frame.get("extra_guards", 0)))
	_sync_props(frame)
	_sync_marks(cast, frame.get("witnesses", []) as Array)
	_sync_embers(frame)
	_sync_camera(frame.get("camera", frame.get("player", Vector2.ZERO)) as Vector2, delta)


## Who can see you, marked over their heads while there is an act in front of you
## that they would see you do — the 2D window's rule, with the same ids handed over.
func _sync_marks(cast: Cast, witnesses: Array) -> void:
	while _marks.size() < witnesses.size():
		var mark: Sprite3D = _billboard(_soft_dot(), Rect2(0.0, 0.0, 16.0, 16.0))
		mark.name = "Mark_%d" % _marks.size()
		mark.pixel_size = PIXEL_METRES * 0.35
		mark.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
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
		mark.position = _feet_of(npc.centre()) + _lens_up * (16.0 * PIXEL_METRES + 0.5)


func _sync_embers(frame: Dictionary) -> void:
	var now: float = float(frame.get("now", 0.0))
	var free: Dictionary = frame.get("free", {}) as Dictionary
	for hearth: Dictionary in _embers:
		var dots: Array[Sprite3D] = hearth["dots"] as Array[Sprite3D]
		var lit: bool = (hearth["kind"] as StringName) != &"kiln" or not bool(free.get(&"cinderworks", false))
		var colour: Color = Color(1.0, 0.62, 0.28) if (hearth["kind"] as StringName) == &"kiln" else Color(1.0, 0.74, 0.40)
		var base: Vector3 = hearth["base"] as Vector3
		for i: int in dots.size():
			var dot: Sprite3D = dots[i]
			dot.visible = lit
			if not lit:
				continue
			var life: float = fposmod(now * (0.34 + float(i) * 0.07) + float(i) * 0.41, 1.0)
			var rise: float = life * 2.2
			var sway: float = sin((now + float(i) * 2.1) * 1.7) * (0.2 + life * 0.4)
			dot.position = base + Vector3(sway, 0.3, 0.0) + _lens_up * rise
			dot.modulate = Color(colour.r, colour.g, colour.b, 0.75 * (1.0 - life) * (1.0 - life))
			dot.pixel_size = PIXEL_METRES * (0.2 + (1.0 - life) * 0.2)


func _sync_player(frame: Dictionary) -> void:
	if _player == null:
		_player = _figure(_art.sheet_for(&"player"), Art.FACE_DOWN)
		_player.name = "Player"
		add_child(_player)
	_player.region_rect = Art.tile_rect(Art.column_for(frame.get("facing", Vector2i(0, 1)) as Vector2i), 0)
	_foot(_player, frame.get("player", Vector2.ZERO) as Vector2)


func _sync_people(cast: Cast, world: WorldState) -> void:
	var present: Dictionary = {}
	var fairy_seen: bool = false
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
			_fairy_glow.pixel_size = PIXEL_METRES * (1.3 + 0.3 * sin(breath))
			continue
		present[npc.id] = true
		var sprite: Sprite3D = _people.get(npc.id, null) as Sprite3D
		if sprite == null:
			sprite = _figure(_art.sheet_for(npc.id), Art.FACE_DOWN)
			sprite.name = "Person_%s" % npc.id
			add_child(sprite)
			_people[npc.id] = sprite
			_foot(sprite, npc.centre())
		sprite.visible = true
	_fairy.visible = fairy_seen
	for id: StringName in _people.keys():
		if not present.has(id):
			(_people[id] as Sprite3D).visible = false


## Traffic, as the 2D window draws it: a pack horse, never a face.
func _sync_traffic(road: Travellers, world: WorldState) -> void:
	if road == null:
		return
	var sheet: Texture2D = _art.traffic_sheet()
	if sheet == null:
		return
	var line: Array[Vector2i] = world.region().road_waypoints()
	var seen: Dictionary = {}
	for walker: Traveller in road.walkers:
		seen[walker.id] = true
		var sprite: Sprite3D = _traffic.get(walker.id, null) as Sprite3D
		if sprite == null:
			sprite = _billboard(sheet, Rect2(0.0, 0.0, float(Art.TRAFFIC_FRAME.x), float(Art.TRAFFIC_FRAME.y)))
			sprite.name = "Traffic_%d" % walker.id
			add_child(sprite)
			_traffic[walker.id] = sprite
		var frame_index: int = absi(int(floorf(walker.pos.x + walker.pos.y))) % 2
		sprite.region_rect = Rect2(float(frame_index * Art.TRAFFIC_FRAME.x), 0.0,
			float(Art.TRAFFIC_FRAME.x), float(Art.TRAFFIC_FRAME.y))
		var facing_right: bool = false
		if not line.is_empty():
			var target: int = clampi(walker.leg + walker.heading, 0, line.size() - 1)
			facing_right = float(line[target].x) + 0.5 > walker.pos.x
		sprite.flip_h = facing_right
		_foot(sprite, walker.pos + Vector2(0.0, 0.5))
	for id: int in _traffic.keys():
		(_traffic[id] as Sprite3D).visible = seen.has(id)


## The escort in two ranks before the gate, and the wall's extra guards, drawn as
## the 2D window draws them and from the same numbers.
func _sync_guards(world: WorldState, escort: int, extra: int) -> void:
	var posts: Array[Vector2] = [Vector2(-5.0, 9.0), Vector2(3.0, 9.0), Vector2(-8.0, 9.0), Vector2(11.0, 9.0)]
	var wanted: int = escort + mini(extra, posts.size())
	while _guards.size() < wanted:
		var guard: Sprite3D = _figure(_art.sheet_for(&"guard"), Art.FACE_DOWN)
		guard.name = "Guard_%d" % _guards.size()
		add_child(guard)
		_guards.append(guard)
	for i: int in _guards.size():
		var guard: Sprite3D = _guards[i]
		guard.visible = i < wanted and world.current_zone == WorldState.OVERWORLD
		if not guard.visible:
			continue
		if i < escort:
			var rank: int = i / ESCORT_FILES
			var file: int = i % ESCORT_FILES
			_foot(guard, world.king_pos + Vector2(float(file) - 2.0, 2.0 + float(rank) * 1.2))
		else:
			_foot(guard, world.king_pos + posts[i - escort])


## What stands and what has gone: the visible half of §8's consequences, as the 2D
## window shows them.
func _sync_props(frame: Dictionary) -> void:
	var tents_standing: int = int(frame.get("tents", 0))
	var crowd: int = int(frame.get("crowd", 0))
	var free: Dictionary = frame.get("free", {}) as Dictionary
	var shuttered: bool = bool(frame.get("shuttered", false))
	var player: Vector2 = frame.get("player", Vector2.ZERO) as Vector2
	var tent: int = 0
	for entry: Dictionary in _props:
		var prop: Dictionary = entry["prop"] as Dictionary
		var sprite: Sprite3D = entry["node"] as Sprite3D
		var kind: StringName = prop["kind"] as StringName
		var shown: bool = true
		var tint: Color = Color.WHITE
		# **Occlusion fade**, as the 2D window does it: a sprite whose picture stands
		# between the player and the lens goes part transparent. Judged on the drawn
		# sprite, in tiles — its foot south of the player within its own height, its
		# width across them — because what hides the player is the part that leans.
		var at: Vector2i = prop["at"] as Vector2i
		var size: Vector2i = prop.get("size", Vector2i(1, 1)) as Vector2i
		var foot := Vector2(float(at.x) + float(size.x) * 0.5, float(at.y + size.y))
		var height_tiles: float = sprite.region_rect.size.y * PIXEL_METRES / _metres_per_tile
		var width_tiles: float = sprite.region_rect.size.x * PIXEL_METRES / _metres_per_tile
		if kind != &"townsfolk" and foot.y > player.y and foot.y - player.y < height_tiles \
				and absf(foot.x - player.x) < width_tiles * 0.5:
			tint.a = OCCLUDED_ALPHA
		if kind == &"fence" and bool(free.get(&"wide_acres", false)):
			shown = false
		elif kind == &"tent" or kind == &"tent_b":
			tent += 1
			shown = tent <= tents_standing
		elif kind == &"townsfolk":
			shown = int(entry["index"]) <= crowd
		elif kind == &"counting_house" and bool(free.get(&"cairnwell", false)):
			tint = tint.darkened(0.4)
		if (kind == &"keep" or kind == &"tower" or kind == &"gatehouse") and shuttered:
			tint = tint.darkened(0.35)
		sprite.visible = shown
		sprite.modulate = tint


## The lens follows the same eased point the 2D camera does, handed over in tiles.
func _sync_camera(eye_tiles: Vector2, delta: float) -> void:
	var want: Vector3 = _feet_of(eye_tiles)
	if not _focus_placed or _focus.distance_to(want) > 12.0:
		_focus = want
		_focus_placed = true
	else:
		_focus = _focus.lerp(want, 1.0 - exp(-CAMERA_CATCHES_UP * delta))
	_camera.transform = Transform3D(Basis.looking_at(-_lens_offset, Vector3.UP),
		_focus + _lens_offset * CAMERA_DISTANCE)


# ------------------------------------------------------------------ counting ---

func prop_count() -> int:
	return _props.size()


func people_count() -> int:
	var shown: int = 0
	for id: StringName in _people.keys():
		if (_people[id] as Sprite3D).visible:
			shown += 1
	return shown


func marks_shown() -> int:
	var shown: int = 0
	for mark: Sprite3D in _marks:
		if mark.visible:
			shown += 1
	return shown


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
