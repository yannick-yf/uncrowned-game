@tool
extends Node3D
## Native Godot level-design handle: move Y for altitude; adjust Slope for ramps.
@export var footprint_m := Vector2(20,20):
	set(value):
		footprint_m = value.max(Vector2(2,2))
		_changed()
@export_range(1.0,40.0,0.5) var blend_m: float = 6.0:
	set(value):
		blend_m = value
		_changed()
@export var slope := Vector2.ZERO:
	set(value):
		slope = value
		_changed()
@export var affect_water_banks: bool = false
@export_enum("Rectangle", "Ellipse") var outline: String = "Rectangle":
	set(value):
		outline=value
		_changed()
@export_range(0.0,2.0,.05) var undulation_m: float = 0.0:
	set(value):
		undulation_m=value
		_changed()
@export_tool_button("Appliquer au terrain") var apply: Callable = _changed
var _preview_pending:bool=false

func _ready() -> void:
	set_notify_transform(true)
	_changed()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint(): _changed()

func _changed() -> void:
	if not is_inside_tree(): return
	var ground: Node = get_tree().get_first_node_in_group("world_terrain")
	if ground != null: ground.call("_request_rebuild")
	if Engine.is_editor_hint() and not _preview_pending:
		_preview_pending=true
		call_deferred("_draw_preview")

func _draw_preview()->void:
	_preview_pending=false
	var old:Node=get_node_or_null("ContourOutil")
	if old!=null: remove_child(old);old.queue_free()
	var guide:=ImmediateMesh.new()
	guide.surface_begin(Mesh.PRIMITIVE_LINES)
	var extent:Vector2=footprint_m*.5
	var corners:Array[Vector2]=[Vector2(-extent.x,-extent.y),Vector2(extent.x,-extent.y),Vector2(extent.x,extent.y),Vector2(-extent.x,extent.y)]
	if outline=="Ellipse":
		corners.clear()
		for i:int in 40:corners.append(Vector2(cos(i*TAU/40),sin(i*TAU/40))*extent)
	for i:int in corners.size():
		for p:Vector2 in [corners[i],corners[(i+1)%corners.size()]]:
			var variation:float=undulation_m*(sin((global_position.x+p.x)*.107+(global_position.z+p.y)*.071)*.58+cos((global_position.z+p.y)*.137-(global_position.x+p.x)*.045)*.42)
			guide.surface_add_vertex(Vector3(p.x,p.dot(slope)+variation+.3,p.y))
	guide.surface_end()
	var view:=MeshInstance3D.new();view.name="ContourOutil";view.mesh=guide
	var ink:=StandardMaterial3D.new();ink.albedo_color=Color(.3,.85,1);ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.no_depth_test=true;view.material_override=ink
	add_child(view)

func sample_height(x: float, z: float, current: float) -> float:
	var local: Vector3 = global_transform.affine_inverse() * Vector3(x,global_position.y,z)
	var edge: float = maxf(absf(local.x)-footprint_m.x*.5,absf(local.z)-footprint_m.y*.5)
	if outline=="Ellipse":
		edge=(Vector2(local.x,local.z)/(footprint_m*.5)).length()-1.0
		edge*=minf(footprint_m.x,footprint_m.y)*.5
	var weight: float = 1.0-smoothstep(0.0,blend_m,edge)
	var target: float = global_position.y + local.x*slope.x + local.z*slope.y
	target+=undulation_m*(sin(x*.107+z*.071)*.58+cos(z*.137-x*.045)*.42)
	return lerpf(current,target,weight)
