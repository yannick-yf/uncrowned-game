@tool
extends Node3D
## Terrain and connected water from editable source data. Decor stays independent.
signal rebuilt

@export_range(16.0, 1024.0, 1.0) var width_m: float = 768.0:
	set(value):
		width_m = clampf(value, 16.0, 1024.0)
		_request_rebuild()
@export_range(16.0, 1024.0, 1.0) var depth_m: float = 768.0:
	set(value):
		depth_m = clampf(value, 16.0, 1024.0)
		_request_rebuild()
@export_range(16.0, 128.0, 1.0) var chunk_size_m: float = 32.0:
	set(value):
		chunk_size_m = clampf(value, 16.0, 128.0)
		_request_rebuild()
@export_range(0.2, 2.0, 0.05) var elevation_scale: float = 1.0:
	set(value):
		elevation_scale = clampf(value, 0.2, 2.0)
		_request_rebuild()
@export var grass_material: Material = preload("res://materials/brindle_landscape.tres")
@export var water_material: Material = preload("res://materials/brindle_water.tres")
@export var mine_cutout := Rect2()
@export_tool_button("Recharger le relief") var reload_button: Callable = rebuild_ground

var _pending: bool = false
var _n: int = 0
var _height: PackedFloat32Array
var _water: PackedFloat32Array
var _paint: PackedFloat32Array
var _flow: PackedFloat32Array
var _meta: Dictionary = {}
var chunk_count: int = 0
var water_triangle_count: int = 0

func _ready() -> void:
	add_to_group("world_terrain")
	_request_rebuild()

func _request_rebuild() -> void:
	if not is_inside_tree() or _pending:
		return
	_pending = true
	call_deferred(&"rebuild_ground")

func _read_floats(filename: String) -> PackedFloat32Array:
	return FileAccess.get_file_as_bytes("res://assets/landscape/" + filename + ".f32").to_float32_array()

func rebuild_ground() -> void:
	_pending = false
	_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/landscape/landscape.json")) as Dictionary
	_n = int(_meta.get("grid_size", 0))
	_height = _read_floats("height")
	_water = _read_floats("water_level")
	_paint = _read_floats("terrain_paint")
	_flow = _read_floats("water_flow")
	if _n < 2 or _height.size() != _n * _n or _water.size() != _height.size() or _paint.size() != _height.size() * 3 or _flow.size() != _paint.size():
		push_error("Données de relief incomplètes. Relancer tools/build_landscape.py.")
		return
	_apply_godot_relief_tools()
	if grass_material is ShaderMaterial and ResourceLoader.exists("res://assets/landscape/royal_ground_mask.png"):
		(grass_material as ShaderMaterial).set_shader_parameter("royal_ground_mask",load("res://assets/landscape/royal_ground_mask.png"))
		(grass_material as ShaderMaterial).set_shader_parameter("royal_mask_enabled",true)
	if grass_material is ShaderMaterial and ResourceLoader.exists("res://assets/landscape/sawmill_ground_mask.png"):
		(grass_material as ShaderMaterial).set_shader_parameter("sawmill_ground_mask",load("res://assets/landscape/sawmill_ground_mask.png"))
		(grass_material as ShaderMaterial).set_shader_parameter("sawmill_mask_enabled",true)
	if grass_material is ShaderMaterial and ResourceLoader.exists("res://assets/landscape/ironworks_ground_mask.png"):
		(grass_material as ShaderMaterial).set_shader_parameter("ironworks_ground_mask",load("res://assets/landscape/ironworks_ground_mask.png"))
		(grass_material as ShaderMaterial).set_shader_parameter("ironworks_mask_enabled",true)
	if grass_material is ShaderMaterial and ResourceLoader.exists("res://assets/landscape/brindle_ground_mask.png"):
		var mask_texture:Texture2D=load("res://assets/landscape/brindle_ground_mask.png")
		(grass_material as ShaderMaterial).set_shader_parameter("brindle_ground_mask",mask_texture)
		(grass_material as ShaderMaterial).set_shader_parameter("brindle_mask_enabled",true)
	if grass_material is ShaderMaterial and ResourceLoader.exists("res://assets/landscape/brindle_scorch_mask.png"):
		(grass_material as ShaderMaterial).set_shader_parameter("scorch_mask",load("res://assets/landscape/brindle_scorch_mask.png"))
		(grass_material as ShaderMaterial).set_shader_parameter("scorch_enabled",true)
	for child: Node in get_children():
		if child.has_meta(&"generated_ground"):
			remove_child(child)
			child.queue_free()
	var landscape := Node3D.new()
	landscape.name = "Landscape"
	landscape.set_meta(&"generated_ground", true)
	add_child(landscape)
	var cells: int = maxi(4, roundi(chunk_size_m / maxf(width_m, depth_m) * (_n - 1)))
	chunk_count = 0
	for z0: int in range(0, _n - 1, cells):
		for x0: int in range(0, _n - 1, cells):
			_build_chunk(landscape, x0, z0, mini(x0 + cells, _n - 1), mini(z0 + cells, _n - 1))
	_build_water(landscape)
	_build_guides(landscape)
	rebuilt.emit()

func _apply_godot_relief_tools() -> void:
	var stamps: Node = get_node_or_null("../ReliefGodot")
	if stamps == null: return
	for stamp: Node in stamps.get_children():
		if not stamp.has_method("sample_height"): continue
		var center: Vector3 = stamp.global_position
		var footprint: Vector2 = stamp.get("footprint_m")
		var reach: float = footprint.length()*.5 + float(stamp.get("blend_m"))
		var start_x: int = maxi(0,floori((center.x-reach+384.0)/2.0))
		var end_x: int = mini(_n-1,ceili((center.x+reach+384.0)/2.0))
		var start_z: int = maxi(0,floori((center.z-reach+384.0)/2.0))
		var end_z: int = mini(_n-1,ceili((center.z+reach+384.0)/2.0))
		for z: int in range(start_z,end_z+1):
			for x: int in range(start_x,end_x+1):
				var i: int = z*_n+x
				if not bool(stamp.get("affect_water_banks")) and _water[i] > 0 and _height[i] < _water[i]+2: continue
				_height[i] = stamp.call("sample_height",x*2.0-384.0,z*2.0-384.0,_height[i])
	if stamps.get_node_or_null("Royal_CourChateau")!=null:
		var royal: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://planning/royal-city.json"))
		preload("res://scripts/royal_ascent.gd").grade(_height,_n,royal.ramp_xyz)
	_apply_bridge_approaches()
	# Repaint slopes after editing a terrace; retain the original sand and bank channels.
	for z: int in _n:
		for x: int in _n:
			var gx: float = (_height[z*_n+mini(x+1,_n-1)]-_height[z*_n+maxi(0,x-1)])*.25
			var gz: float = (_height[mini(z+1,_n-1)*_n+x]-_height[maxi(0,z-1)*_n+x])*.25
			_paint[(z*_n+x)*3] = maxf(smoothstep(.45,1.05,Vector2(gx,gz).length()),smoothstep(92,155,_height[z*_n+x])*.88)

func _apply_bridge_approaches() -> void:
	# Apply after artistic terrace stamps so an old mine terrace cannot lower a bridge landing.
	for crossing: Dictionary in _meta.get("crossings",[]):
		var center: Vector2=Vector2(crossing.center_xyz[0],crossing.center_xyz[2])
		var direction: Vector2=Vector2(crossing.direction_xz[0],crossing.direction_xz[1])
		var deck: float=float(crossing.center_xyz[1]);var half: float=float(crossing.length_m)*.5
		var width: float=float(crossing.clear_width_m)*.5
		var reach: float=half+26
		for z: int in range(maxi(0,floori((center.y-reach+384)/2)),mini(_n,ceili((center.y+reach+384)/2))):
			for x: int in range(maxi(0,floori((center.x-reach+384)/2)),mini(_n,ceili((center.x+reach+384)/2))):
				var offset: Vector2=Vector2(x*2.0-384,z*2.0-384)-center
				var along: float=absf(offset.dot(direction))-half
				var lateral: float=absf(offset.cross(direction))
				var weight: float=(1-smoothstep(width+.85,width+7,lateral))*(1-smoothstep(3,22,along))*smoothstep(-2.3,-1.6,along)
				_height[z*_n+x]=lerpf(_height[z*_n+x],deck,weight)

func _point(x: int, z: int, water: bool = false) -> Vector3:
	var y: float = _water[z * _n + x] if water else _height[z * _n + x]
	return Vector3((float(x) / (_n - 1) - 0.5) * width_m, y * elevation_scale, (float(z) / (_n - 1) - 0.5) * depth_m)

func _build_chunk(parent: Node3D, x0: int, z0: int, x1: int, z1: int) -> void:
	var columns: int = x1 - x0 + 1
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for z: int in range(z0, z1 + 1):
		for x: int in range(x0, x1 + 1):
			vertices.append(_point(x, z))
			var tx: Vector3 = _point(mini(x + 1, _n - 1), z) - _point(maxi(0, x - 1), z)
			var tz: Vector3 = _point(x, mini(z + 1, _n - 1)) - _point(x, maxi(0, z - 1))
			normals.append(tz.cross(tx).normalized())
			var p: int = (z * _n + x) * 3
			colors.append(Color(_paint[p], _paint[p + 1], _paint[p + 2], 1.0))
	for z: int in range(z1 - z0):
		for x: int in range(x1 - x0):
			var cell_center := Vector2((x0+x)*2.0-383.0,(z0+z)*2.0-383.0)
			if mine_cutout.has_point(cell_center): continue
			var a: int = z * columns + x
			indices.append_array(PackedInt32Array([a, a + 1, a + columns, a + 1, a + columns + 1, a + columns]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, grass_material)
	var body := StaticBody3D.new()
	body.name = "Ground_%03d_%03d" % [x0, z0]
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var surface := MeshInstance3D.new()
	surface.name = "Surface"
	surface.mesh = mesh
	body.add_child(surface)
	var collision := CollisionShape3D.new()
	collision.name = "GroundCollision"
	collision.shape = mesh.create_trimesh_shape()
	body.add_child(collision)
	chunk_count += 1

func _water_vertex(x: int, z: int) -> Array:
	var i: int = z * _n + x
	var depth: float = (_water[i] - _height[i]) * elevation_scale
	var tx: Vector3 = _point(mini(x + 1, _n - 1), z, true) - _point(maxi(0, x - 1), z, true)
	var tz: Vector3 = _point(x, mini(z + 1, _n - 1), true) - _point(x, maxi(0, z - 1), true)
	return [_point(x, z, true), depth, Color(clampf(depth / (6.0 * elevation_scale), 0, 1), (_flow[i * 3] + 1) * 0.5, (_flow[i * 3 + 1] + 1) * 0.5, _flow[i * 3 + 2]), tz.cross(tx).normalized()]

func _emit_water_triangle(a: Array, b: Array, c: Array, vertices: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray) -> void:
	var polygon: Array = [a, b, c]
	var clipped: Array = []
	var previous: Array = polygon[-1]
	for current: Array in polygon:
		var pin: bool = float(previous[1]) > 0.02
		var cin: bool = float(current[1]) > 0.02
		if pin != cin:
			var t: float = (0.02 - float(previous[1])) / (float(current[1]) - float(previous[1]))
			clipped.append([(previous[0] as Vector3).lerp(current[0] as Vector3, t), 0.02, (previous[2] as Color).lerp(current[2] as Color, t), (previous[3] as Vector3).lerp(current[3] as Vector3, t).normalized()])
		if cin:
			clipped.append(current)
		previous = current
	for i: int in range(1, clipped.size() - 1):
		var pa: Vector3 = clipped[0][0]
		var pb: Vector3 = clipped[i][0]
		var pc: Vector3 = clipped[i + 1][0]
		var normal: Vector3 = (pc - pa).cross(pb - pa).normalized()
		if normal.length_squared() < 0.1:
			continue
		for v: Array in [clipped[0], clipped[i], clipped[i + 1]]:
			vertices.append(v[0])
			normals.append(v[3])
			colors.append(v[2])

func _build_water(parent: Node3D) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	for z: int in _n - 1:
		for x: int in _n - 1:
			var i: int = z * _n + x
			if maxf(maxf(_water[i] - _height[i], _water[i + 1] - _height[i + 1]), maxf(_water[i + _n] - _height[i + _n], _water[i + _n + 1] - _height[i + _n + 1])) <= 0.02:
				continue
			var a: Array = _water_vertex(x, z)
			var b: Array = _water_vertex(x + 1, z)
			var c: Array = _water_vertex(x, z + 1)
			var d: Array = _water_vertex(x + 1, z + 1)
			_emit_water_triangle(a, b, c, vertices, normals, colors)
			_emit_water_triangle(b, d, c, vertices, normals, colors)
	water_triangle_count = vertices.size() / 3
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, water_material)
	var water := MeshInstance3D.new()
	water.name = "LakeRiversAndSea"
	water.mesh = mesh
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(water)

func _build_guides(parent: Node3D) -> void:
	var guides := Node3D.new()
	guides.name = "SiteGuides"
	parent.add_child(guides)
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://planning/geographie-v1.json")) as Dictionary
	for site: Dictionary in spec["sites"]:
		var at: Array = site["center_xz"]
		var x: float = float(at[0]) * width_m / 768.0
		var z: float = float(at[1]) * depth_m / 768.0
		var marker := Marker3D.new()
		marker.name = String(site["id"])
		marker.position = Vector3(x, height_at_world(x, z), z)
		guides.add_child(marker)
		var label := Label3D.new()
		label.name = "Label"
		label.text = String(site["label"])
		label.position.y = 8.0
		label.font_size = 48
		label.pixel_size = 0.22
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.modulate = Color(0.98, 0.95, 0.80)
		label.outline_modulate = Color(0.12, 0.17, 0.12, 0.9)
		label.outline_size = 8
		marker.add_child(label)

func toggle_guides() -> void:
	var guides: Node3D = get_node_or_null("Landscape/SiteGuides")
	if guides != null:
		guides.visible = not guides.visible
		var mine_label: Node3D = get_node_or_null("../Decor/MineAcierie/RepereMine")
		if mine_label != null: mine_label.visible = guides.visible

func _sample(data: PackedFloat32Array, x: float, z: float) -> float:
	if data.is_empty() or _n < 2:
		return 0.0
	var u: float = clampf((x / width_m + 0.5) * (_n - 1), 0, _n - 1)
	var v: float = clampf((z / depth_m + 0.5) * (_n - 1), 0, _n - 1)
	var x0: int = floori(u)
	var z0: int = floori(v)
	var x1: int = mini(x0 + 1, _n - 1)
	var z1: int = mini(z0 + 1, _n - 1)
	return lerpf(lerpf(data[z0 * _n + x0], data[z0 * _n + x1], u - x0), lerpf(data[z1 * _n + x0], data[z1 * _n + x1], u - x0), v - z0) * elevation_scale

func height_at_world(x: float, z: float) -> float:
	return _sample(_height, x, z)

func water_at_world(x: float, z: float) -> float:
	return _sample(_water, x, z)

func surface_height_at_world(x: float,z: float) -> float:
	if _height.is_empty(): return 0
	var u:float=clampf((x/width_m+.5)*(_n-1),0,_n-1)
	var v:float=clampf((z/depth_m+.5)*(_n-1),0,_n-1)
	var ix:int=mini(floori(u),_n-2);var iz:int=mini(floori(v),_n-2)
	var fx:float=u-ix;var fz:float=v-iz;var i:int=iz*_n+ix
	var y:float
	if fx+fz<=1:
		y=_height[i]+fx*(_height[i+1]-_height[i])+fz*(_height[i+_n]-_height[i])
	else:
		y=_height[i+_n+1]+(1-fx)*(_height[i+_n]-_height[i+_n+1])+(1-fz)*(_height[i+1]-_height[i+_n+1])
	return y*elevation_scale
