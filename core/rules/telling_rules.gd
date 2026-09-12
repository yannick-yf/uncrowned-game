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
## The document you are holding, have not yet made public, and are somewhere with
## people to say it to. Proof rather than testimony: §3's `discredited` ending is
## the world *knowing* what he did, and your word alone has never been evidence.
static func tellable_document(
	town: StringName,
	witnesses: PackedStringArray,
	world: WorldState,
	facts: FactBase,
) -> StringName:
	if town == &"" or witnesses.is_empty() or world == null or facts == null:
		return &""
	for fact: String in world.documents:
		var held: StringName = StringName(fact)
		if not facts.has(DocumentRules.made_public(held)):
			return held
	return &""


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
