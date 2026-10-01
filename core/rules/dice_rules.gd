class_name DiceRules
extends RefCounted

## **The simulation's dice that are not `sim.rng`** (R2, R4; mixed since the review of R).
##
## A pack's wandering and a blow's chance to miss are drawn from what the simulation already
## knows — the run's seed, the step, who — so that a replay draws them again and no other
## system's draws are shifted by them. The first version hashed those as a string with
## Godot's `String.hash()`, and that hash moves by exactly one when its last character
## does: a pack's two draws for a goal's x and y differed by one, every pack walked one
## diagonal of its ground, and two blows a few steps apart missed together less often than
## chance. So the parts are mixed here by the finaliser of MurmurHash3 — well known, small,
## and with every bit of the input reaching every bit of the output.
##
## In 32 bits, inside GDScript's 64-bit integers: every product is split so it cannot
## overflow.

const MASK: int = 0xFFFFFFFF


## **A number from these parts**, 0 to 2^32 - 1: integers as they are, names by their hash.
static func mixed(parts: Array) -> int:
	var h: int = 0x9E3779B9
	for part: Variant in parts:
		var value: int = 0
		if part is String or part is StringName:
			value = String(part).hash()
		else:
			value = int(part)
		h = _fmix32((((h ^ _fmix32(value & MASK)) + 0x9E3779B9) & MASK))
	return h


## A die of `sides` faces, 0 to sides - 1, from these parts.
static func die(sides: int, parts: Array) -> int:
	return mixed(parts) % maxi(sides, 1)


## MurmurHash3's finaliser on 32 bits.
static func _fmix32(x: int) -> int:
	var h: int = x & MASK
	h ^= h >> 16
	h = _mul32(h, 0x85EBCA6B)
	h ^= h >> 13
	h = _mul32(h, 0xC2B2AE35)
	h ^= h >> 16
	return h


## `a * b` modulo 2^32, both under 2^32, without ever leaving 64 bits.
static func _mul32(a: int, b: int) -> int:
	var low: int = (a & 0xFFFF) * b
	var high: int = (((a >> 16) * b) & 0xFFFF) << 16
	return (low + high) & MASK
