extends Node3D
## Decorative motion; the art preview introduces no production simulation.
@onready var wheel: Node3D = get_parent().get_node("Wheel")
func _process(delta: float) -> void:
	wheel.rotate_x(-delta*.22)
