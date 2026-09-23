extends Node3D
## Small ambient GPU effects, authored from farming-town.json's orchards array.
## Usage: add_child(effects); effects.configure(layout.orchards, terrain).
## Tree xz/altitude/y values are WORLD coordinates. Missing height is sampled
## through terrain.surface_height_at_world(x, z). Configuration also works
## before add_child. Construction is deferred past terrain initialization.
## Selection uses the viewed terrain point, not an orthographic camera's retreat.
## A parent camera_subject(camera) method is used when available, otherwise a
## camera ray is intersected with the orchard's mean ground plane. set_focus()
## can explicitly override that world point; clear_focus() restores inference.
## This module owns only its emitter children and never edits the scene terrain.

const LEAF_SHADER: Shader=preload("res://shaders/farming_falling_leaves.gdshader")
const DUST_SHADER: Shader=preload("res://shaders/farming_dust.gdshader")
const LEAVES_PER_TREE: int=6
const DUST_PER_TREE: int=5
const MAX_PREPARED_TREES: int=48

@export_range(1,16,1) var max_active_trees: int=10
@export_range(15.0,120.0,1.0) var activation_distance: float=75.0
@export var effects_enabled: bool=true

var _orchards: Array=[]
var _ground: Node3D
var _camera: Camera3D
var _patches: Array[Dictionary]=[]
var _elapsed: float=0.0
var _leaf_mesh: ArrayMesh
var _dust_mesh: QuadMesh
var _focus_override: Vector3=Vector3.INF
var _last_focus: Vector3=Vector3.ZERO
var _mean_ground_y: float=0.0
var _rebuild_pending: bool=false

func configure(orchard_data: Array, ground: Node3D) -> void:
	_orchards=orchard_data.duplicate(true)
	_ground=ground
	if is_inside_tree():_request_rebuild()

## Optional override for a preview camera; null restores the current viewport camera.
func set_camera(camera: Camera3D) -> void:
	_camera=camera
	if is_inside_tree():_update_activation()

func set_focus(world_point: Vector3) -> void:
	_focus_override=world_point

func clear_focus() -> void:
	_focus_override=Vector3.INF

func get_budget() -> Dictionary:
	var active: int=0
	for patch: Dictionary in _patches:
		if patch.active:active+=1
	return {"prepared_trees":_patches.size(),"active_trees":active,
		"active_emitters":active*2,"active_particles":active*(LEAVES_PER_TREE+DUST_PER_TREE),
		"maximum_active_particles":clampi(max_active_trees,1,16)*(LEAVES_PER_TREE+DUST_PER_TREE),"focus_world":_last_focus}

func _ready() -> void:
	if is_instance_valid(_ground):_request_rebuild()

func _request_rebuild() -> void:
	if _rebuild_pending:return
	_rebuild_pending=true
	call_deferred("_rebuild")

func _rebuild() -> void:
	_rebuild_pending=false
	if not is_inside_tree():return
	for patch: Dictionary in _patches:
		for emitter: GPUParticles3D in [patch.leaves,patch.dust]:
			remove_child(emitter);emitter.queue_free()
	_patches.clear()
	_mean_ground_y=0.0
	if not is_instance_valid(_ground):return
	if _leaf_mesh==null:_leaf_mesh=_make_leaf_mesh()
	if _dust_mesh==null:
		_dust_mesh=QuadMesh.new();_dust_mesh.size=Vector2(.075,.075)
	for orchard: Dictionary in _orchards:
		for tree: Dictionary in orchard.get("trees",[]):
			if _patches.size()>=MAX_PREPARED_TREES:break
			var xz: Array=tree.get("xz",[])
			if xz.size()!=2:continue
			var x: float=float(xz[0]);var z: float=float(xz[1])
			var y: float=float(tree.get("altitude",tree.get("y",NAN)))
			if not is_finite(y):
				if not _ground.has_method("surface_height_at_world"):continue
				y=float(_ground.call("surface_height_at_world",x,z))
			if not is_finite(y):continue
			var scale_factor: float=clampf(float(tree.get("scale",1.0)),.5,1.8)
			var asset: String=str(tree.get("asset",""))
			var crown_y: float=2.95 if asset=="pommier_jeune" else 3.8 if asset=="poirier_fuseau" else 3.45
			var radius: float=1.0 if asset=="pommier_jeune" or asset=="poirier_fuseau" else 1.45
			var anchor: Vector3=Vector3(x,y,z)
			var stable_seed: int=absi(hash(str(orchard.get("id","orchard"))+":"+str(xz)))
			var leaves: GPUParticles3D=_make_emitter(true,anchor+Vector3(0,crown_y*scale_factor,0),y,radius*scale_factor,stable_seed)
			var dust: GPUParticles3D=_make_emitter(false,anchor+Vector3(0,1.25,0),y,radius*scale_factor+0.5,stable_seed+37)
			_patches.append({"center":anchor+Vector3(0,1.8,0),"leaves":leaves,"dust":dust,"active":false})
			_mean_ground_y+=y
	if not _patches.is_empty():_mean_ground_y/=_patches.size()
	_elapsed=0.0
	_update_activation()

func _make_emitter(leaves: bool, at: Vector3, ground_y: float, radius: float, stable_seed: int) -> GPUParticles3D:
	var emitter: GPUParticles3D=GPUParticles3D.new()
	emitter.name=("Leaves" if leaves else "Dust")+str(_patches.size()).pad_zeros(2)
	emitter.emitting=false
	emitter.visible=false
	emitter.speed_scale=0.0
	emitter.amount=LEAVES_PER_TREE if leaves else DUST_PER_TREE
	emitter.lifetime=8.5 if leaves else 9.0
	emitter.preprocess=1.5
	emitter.randomness=.65
	emitter.use_fixed_seed=true;emitter.seed=stable_seed
	emitter.fixed_fps=24;emitter.interpolate=true
	emitter.local_coords=true
	emitter.draw_order=GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	emitter.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Includes the maximum canopy spread, lifetime drift and shader flutter.
	emitter.visibility_aabb=AABB(Vector3(-5,-8,-5),Vector3(10,12,10))
	# Range-based renderer culling measures camera distance, which would hide
	# particles in a close orthographic view whose camera is 200 m away. Focus
	# distance is handled below; the renderer still culls each bounded AABB.
	emitter.visibility_range_end=0.0
	var process: ParticleProcessMaterial=ParticleProcessMaterial.new()
	process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents=Vector3(radius,.40 if leaves else .9,radius)
	process.direction=Vector3(.27,-1.0,.12) if leaves else Vector3(.8,.25,.2)
	process.spread=18.0 if leaves else 40.0
	process.initial_velocity_min=.24 if leaves else .025
	process.initial_velocity_max=.38 if leaves else .065
	process.gravity=Vector3(0,-.016,0) if leaves else Vector3(0,.002,0)
	process.scale_min=.70 if leaves else .65
	process.scale_max=1.05 if leaves else 1.10
	if leaves:
		process.use_rotation_velocity_3d=true
		process.rotation_velocity_3d_min=Vector3(-30,-28,-35)
		process.rotation_velocity_3d_max=Vector3(32,34,35)
		process.angle_min=0;process.angle_max=360
	var colors: Gradient=Gradient.new()
	colors.colors=PackedColorArray([Color(.27,.40,.12),Color(.52,.53,.18),Color(.74,.56,.21)]) if leaves else PackedColorArray([Color(.68,.64,.46),Color(.85,.76,.51),Color(.73,.70,.57)])
	colors.offsets=PackedFloat32Array([0.0,.58,1.0])
	var palette: GradientTexture1D=GradientTexture1D.new();palette.gradient=colors;palette.width=32
	process.color_initial_ramp=palette
	var fade: Gradient=Gradient.new()
	fade.offsets=PackedFloat32Array([0.0,.12,.78,1.0])
	fade.colors=PackedColorArray([Color(1,1,1,0),Color.WHITE,Color.WHITE,Color(1,1,1,0)])
	var opacity: GradientTexture1D=GradientTexture1D.new();opacity.gradient=fade;opacity.width=64
	process.color_ramp=opacity
	emitter.process_material=process
	emitter.draw_pass_1=_leaf_mesh if leaves else _dust_mesh
	var material: ShaderMaterial=ShaderMaterial.new()
	material.shader=LEAF_SHADER if leaves else DUST_SHADER
	material.set_shader_parameter("ground_level",ground_y)
	emitter.material_override=material
	add_child(emitter)
	emitter.global_position=at
	emitter.global_basis=Basis.IDENTITY
	return emitter

func _process(delta: float) -> void:
	_elapsed+=delta
	if _elapsed<.35:return
	_elapsed=0.0
	_update_activation()

func _notification(what: int) -> void:
	if what==NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree():_update_activation()

func _camera_focus(camera: Camera3D) -> Vector3:
	if _focus_override.is_finite():return _focus_override
	var controller: Node=get_parent()
	if controller!=null and controller.has_method("camera_subject"):
		var point: Variant=controller.call("camera_subject",camera)
		if point is Vector3 and point.is_finite():return point
	var direction: Vector3=-camera.global_basis.z
	if absf(direction.y)>.01:
		var distance: float=(_mean_ground_y-camera.global_position.y)/direction.y
		if distance>=0:return camera.global_position+direction*distance
	return camera.global_position

func _update_activation() -> void:
	var camera: Camera3D=_camera if is_instance_valid(_camera) else get_viewport().get_camera_3d()
	var candidates: Array[Dictionary]=[]
	if effects_enabled and is_visible_in_tree() and is_instance_valid(camera):
		_last_focus=_camera_focus(camera)
		for i: int in _patches.size():
			var patch: Dictionary=_patches[i]
			var center: Vector3=patch.center
			var distance: float=Vector2(_last_focus.x-center.x,_last_focus.z-center.z).length()
			var limit: float=clampf(activation_distance,15.0,120.0)+(8.0 if patch.active else 0.0)
			if distance>limit or camera.is_position_behind(patch.center):continue
			# A small preference for already active trees avoids emitter churn.
			candidates.append({"index":i,"distance":distance-(4.0 if patch.active else 0.0)})
	candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:return float(a.distance)<float(b.distance))
	var selected: Dictionary={}
	for i: int in mini(candidates.size(),clampi(max_active_trees,1,16)):selected[int(candidates[i].index)]=true
	for i: int in _patches.size():
		var patch: Dictionary=_patches[i]
		var active: bool=selected.has(i)
		if active==bool(patch.active):continue
		patch.active=active
		for emitter: GPUParticles3D in [patch.leaves,patch.dust]:
			emitter.visible=active
			emitter.speed_scale=1.0 if active else 0.0
			emitter.emitting=active
			if active:emitter.restart()

func _make_leaf_mesh() -> ArrayMesh:
	# Four shallow folded triangles form the leaf itself; no alpha texture.
	var vertices: Array[Vector3]=[Vector3(0,.14,0),Vector3(.055,.018,-.006),Vector3(0,-.11,0),Vector3(-.055,.018,-.006),Vector3(0,.018,.012)]
	var surface: SurfaceTool=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in [0,1,4,1,2,4,2,3,4,3,0,4]:
		var at: Vector3=vertices[index]
		surface.set_uv(Vector2(at.x/.11+.5,(at.y+.11)/.25))
		surface.add_vertex(at)
	surface.generate_normals()
	return surface.commit()
