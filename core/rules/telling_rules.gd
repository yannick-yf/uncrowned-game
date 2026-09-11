class_name TellingRules
extends RefCounted

## When what you know is worth saying, and to whom.


## A warning needs a town, an audience, the fact, and for the fraud to be untold.
##
## The audience is the part that is not like exposing at the Muster: you can commit
## a theft in an empty street, but you cannot *tell* an empty street anything. The
## witnesses are the people you are talking to, which is why the same marks that
## mean "who can see this" over a stall mean "who will hear this" here.
##
## §8's availability rule is the reason this takes no quest, no grant and no
## permission — only standing somewhere with people in it. An act you have to be
## given is not a counterweight to an act you can simply take.
static func can_warn(
	town: StringName,
	told_to: StringName,
	witnesses: PackedStringArray,
	facts: FactBase,
) -> bool:
	if town == &"" or told_to != &"":
		return false
	# The camp is where you expose it, not where you warn anybody about it — the
	# men are the thing being warned of.
	if town == &"muster":
		return false
	if witnesses.is_empty():
		return false
	return facts.has(ArmyRules.FACT_PAY_FRAUD)
