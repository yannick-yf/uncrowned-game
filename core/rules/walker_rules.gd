class_name WalkerRules
extends RefCounted

## How somebody the world has displaced gets back to their post (O7).

## How long a person stays where a fight left them before walking back, in real seconds.
## Long enough for the player to turn and speak to them — a man who strides off the
## instant the last blow lands reads as a machine being reset.
const LINGER_SECONDS: float = 4.0


static func linger_steps() -> int:
	return int(round(LINGER_SECONDS * float(Sim.STEPS_PER_REAL_SECOND)))


## Steps to cross one tile at the world's own walking pace — 24 on his map, 10 on the
## 2D one — so a person walking home walks exactly as the player does.
static func steps_per_tile() -> int:
	return maxi(int(round(float(Sim.STEPS_PER_REAL_SECOND) / MovementRules.tiles_per_second())), 1)
