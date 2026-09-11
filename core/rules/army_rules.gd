class_name ArmyRules
extends RefCounted

## What the army is worth, and what breaks it.
##
## SPECS §3 lists exposing the pay fraud as one of four ways to weaken the Muster,
## and §8's army strength drifts on "pay, food, desertion". So the chain is the
## spec's own: learn the fraud, expose it, men leave, the king has fewer bodies
## between him and the player.

const FACT_PAY_FRAUD: StringName = &"muster:pay_fraud"
const FACT_FRAUD_EXPOSED: StringName = &"muster:fraud_exposed"

const ESCORT_AT_FULL_STRENGTH: int = 10
const ESCORT_AFTER_DESERTIONS: int = 5
const ARMY_AT_FULL_STRENGTH: int = 100
const ARMY_AFTER_DESERTIONS: int = 55


## Exposing needs the fact, the place, and for it not to have happened already.
## Knowing is not enough and standing there is not enough: SPECS §7's redundancy
## rule is about *reaching* the fact, and this is what the fact is for.
static func can_expose(in_muster: bool, already_exposed: bool, facts: FactBase) -> bool:
	return in_muster and not already_exposed and facts.has(FACT_PAY_FRAUD)


static func escort_for(fraud_exposed: bool) -> int:
	return ESCORT_AFTER_DESERTIONS if fraud_exposed else ESCORT_AT_FULL_STRENGTH


static func army_strength_for(fraud_exposed: bool) -> int:
	return ARMY_AFTER_DESERTIONS if fraud_exposed else ARMY_AT_FULL_STRENGTH
