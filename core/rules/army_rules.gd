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

## Exposing needs the fact, the place, and for the fraud not to have been told to
## anybody yet. Knowing is not enough and standing there is not enough: SPECS §7's
## redundancy rule is about *reaching* the fact, and this is what the fact is for.
##
## `told_to` is the whole of §8's opportunity cost. Warn a town and the army keeps
## its men: a quartermaster who has heard she was named does not leave the books
## where she left them, and the second audience gets a story rather than proof.
static func can_expose(in_muster: bool, told_to: StringName, facts: FactBase) -> bool:
	return in_muster and told_to == &"" and facts.has(FACT_PAY_FRAUD)
