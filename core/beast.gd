class_name Beast
extends RefCounted

## One animal, somewhere in the wild.
##
## Derived state, not authored: beasts are spawned near the player from sim.rng
## and forgotten when they are left behind, so replaying a run reproduces the same
## encounters without the world ever storing a population.

var id: int = 0
var kind: StringName = &""
var pos: Vector2 = Vector2.ZERO
var facing: Vector2i = Vector2i(0, 1)
var heading: Vector2 = Vector2.ZERO
## Where it lives. A wandering animal keeps to a patch rather than walking out of
## the world, which is also what stops the wood emptying if the player waits.
var home: Vector2 = Vector2.ZERO
var turn_at_step: int = 0
var hunting: bool = false


func tile() -> Vector2i:
	return Vector2i(floori(pos.x), floori(pos.y))
