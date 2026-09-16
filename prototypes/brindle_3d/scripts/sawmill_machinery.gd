extends Node3D
## Decorative motion only; no production, resource or NPC simulation.
var wheel: Node3D
var elapsed: float=0.0
var blade_parts: Array[Node3D]=[]
func _ready() -> void:
	set_process(false)
	call_deferred("_assemble")
func _assemble() -> void:
	var mill: Node3D=get_parent()
	wheel=Node3D.new();wheel.name="RoueAnimee";mill.add_child(wheel);wheel.position=Vector3(4.65,2.25,-.65)
	for node: Node in mill.get_children():
		if not node is MeshInstance3D:continue
		if str(node.name).begins_with("Wheel"):node.reparent(wheel,true)
		elif str(node.name).begins_with("SawBlade") or str(node.name).begins_with("SawTeeth") or str(node.name).begins_with("ReciprocatingFrame"):blade_parts.append(node)
		if str(node.name).begins_with("FlumeWater") or str(node.name).begins_with("WaterDischarge"):node.material_override=load("res://materials/sawmill_flow.tres")
	set_process(true)
func _process(delta: float) -> void:
	elapsed+=delta
	wheel.rotation.x=elapsed*.26
	for part: Node3D in blade_parts:part.position.y=sin(elapsed*1.8)*.10
