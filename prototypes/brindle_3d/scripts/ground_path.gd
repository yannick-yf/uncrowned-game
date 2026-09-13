@tool
extends MeshInstance3D
@export var points := PackedVector2Array():
	set(value):
		points=value
		_refresh()
@export var width_m: float = 3.0:
	set(value):
		width_m=value
		_refresh()
@export var plaza_radius: float = 0.0
var _ground: Node3D
func _ready() -> void:
	call_deferred("_connect_ground")
func _connect_ground() -> void:
	_ground=get_tree().get_first_node_in_group("world_terrain") as Node3D
	if _ground != null:
		if not _ground.is_connected("rebuilt",_refresh): _ground.connect("rebuilt",_refresh)
		_refresh()
func _refresh() -> void:
	if _ground==null or points.size()<2: return
	var ribbon:=SurfaceTool.new()
	ribbon.begin(Mesh.PRIMITIVE_TRIANGLES)
	var samples:=PackedVector2Array()
	var curve:=Curve3D.new()
	curve.bake_interval=.8
	for i:int in points.size():
		var p:Vector2=points[i]
		var tangent:Vector2=(points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)])/6.0
		var handle:=Vector3(tangent.x,0,tangent.y)
		curve.add_point(Vector3(p.x,0,p.y),-handle,handle)
	for p:Vector3 in curve.get_baked_points(): samples.append(Vector2(p.x,p.z))
	for i: int in range(samples.size()-1):
		var d:Vector2=(samples[i+1]-samples[maxi(0,i-1)]).normalized()
		var d_next:Vector2=(samples[mini(samples.size()-1,i+2)]-samples[i]).normalized()
		var side:=Vector2(-d.y,d.x)*width_m*.5
		var side_next:=Vector2(-d_next.y,d_next.x)*width_m*.5
		for band: int in 2:
			var left:float=float(band)-1.0; var right:float=float(band)
			var a:Vector2=samples[i]+side*left; var b:Vector2=samples[i]+side*right
			var c:Vector2=samples[i+1]+side_next*left; var e:Vector2=samples[i+1]+side_next*right
			var positions:Array[Vector2]=[a,b,c,b,e,c]
			var strengths:Array[float]=[1-absf(left),1-absf(right),1-absf(left),1-absf(right),1-absf(right),1-absf(left)]
			for j: int in positions.size():
				var v:Vector2=positions[j]
				var at:Vector3=global_transform*Vector3(v.x,0,v.y)
				at.y=_ground.call("surface_height_at_world",at.x,at.z)+.09
				ribbon.set_color(Color(1,1,1,strengths[j]))
				ribbon.set_uv(v*.3)
				ribbon.add_vertex(global_transform.affine_inverse()*at)
	ribbon.generate_normals()
	mesh=ribbon.commit()
	cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
