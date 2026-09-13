@tool
extends CSGMesh3D
## Closed piece of the real hillside, cut with editable native CSG subtraction.
@export var bounds := Rect2(300,70,28,20)
var _ground: Node3D
func _ready() -> void: call_deferred("_connect_ground")
func _connect_ground() -> void:
	_ground=get_tree().get_first_node_in_group("world_terrain") as Node3D
	if _ground != null:
		if not _ground.is_connected("rebuilt",rebuild_hillside): _ground.connect("rebuilt",rebuild_hillside)
		rebuild_hillside()
func rebuild_hillside() -> void:
	if _ground==null: return
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx:int=roundi(bounds.size.x/2); var nz:int=roundi(bounds.size.y/2)
	for z: int in nz:
		for x: int in nx:
			var a:Vector3=_top(x,z); var b:Vector3=_top(x+1,z)
			var c:Vector3=_top(x,z+1); var d:Vector3=_top(x+1,z+1)
			_triangle(surface,a,b,c); _triangle(surface,b,d,c)
	var border:Array[Vector3]=[]
	for x: int in range(nx+1): border.append(_top(x,0))
	for z: int in range(1,nz+1): border.append(_top(nx,z))
	for x: int in range(nx-1,-1,-1): border.append(_top(x,nz))
	for z: int in range(nz-1,0,-1): border.append(_top(0,z))
	var floor_y:float=38.0
	var center:=Vector3(bounds.get_center().x,floor_y,bounds.get_center().y)
	for i: int in border.size():
		var a:Vector3=border[i]; var b:Vector3=border[(i+1)%border.size()]
		var ab:=Vector3(a.x,floor_y,a.z); var bb:=Vector3(b.x,floor_y,b.z)
		_triangle(surface,b,a,ab); _triangle(surface,b,ab,bb)
		_triangle(surface,ab,center,bb)
	surface.generate_normals()
	mesh=surface.commit()
func _top(x:int,z:int)->Vector3:
	var xx:float=bounds.position.x+x*2.0; var zz:float=bounds.position.y+z*2.0
	return Vector3(xx,float(_ground.call("height_at_world",xx,zz)),zz)
func _triangle(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
	st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
