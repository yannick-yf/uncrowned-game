class_name RecoveryRules
extends RefCounted

## How health comes back.
##
## **A Phase 3 stopgap** (SPECS §19 Q36), deliberately the cheapest thing that
## works: no potions, no rations, no inventory. Health returns on its own once
## nothing has hurt you for a moment, and returns faster indoors among people.
##
## It exists because without it the wild's cost ratchets — your second crossing is
## far more dangerous than your first and dying in Brindle is the only reset — and
## because it gives a town a reason to be walked back to that is not a quest.
##
## Phase 4 revisits it beside combat, where being hurt has to mean more than this.

## Nothing may have hurt you for this long before anything mends.
## How close you must be to sit down at a fire, and how long a rest lasts. Eight
## in-game hours: long enough that the world moves while you sleep, which is what
## makes the save point and the payoff the same moment (§19 Q5).
const FIRE_REACH: float = 2.2
const REST_TICKS: int = 8 * 60

const CALM_SECONDS: float = 6.0
## Out in the country: a point every twenty seconds, so a full ten is three
## minutes of not being bitten. Slow enough that the Thornwood still frightens.
const WILD_SECONDS_PER_POINT: float = 20.0
## Inside a town: three times faster. Four walls and somebody who knows medicine.
const TOWN_SECONDS_PER_POINT: float = 6.0


static func calm_steps() -> int:
	return int(CALM_SECONDS * float(Sim.STEPS_PER_REAL_SECOND))


static func steps_per_point(in_town: bool) -> int:
	var seconds: float = TOWN_SECONDS_PER_POINT if in_town else WILD_SECONDS_PER_POINT
	return int(seconds * float(Sim.STEPS_PER_REAL_SECOND))


static func is_calm(step: int, last_hurt_step: int) -> bool:
	return step - last_hurt_step >= calm_steps()
