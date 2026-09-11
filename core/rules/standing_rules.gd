class_name StandingRules
extends RefCounted

## How a number becomes a word.
##
## Standing is stored as a float because arithmetic needs one. It is *shown* as a
## word, and the reason is §8's reading of what a visible meter does to a social
## system: a number with legible increments stops being a reputation and becomes a
## score, and the player starts farming it rather than deciding things. Red Dead
## Redemption's honour meter is the worked example — its crime-and-witness system
## is excellent and its honour bar is the part everybody games.
##
## The thresholds live here, with the words, and not in DialogueRules where the
## first one was written. The HUD saying "wary" while a trader refuses to serve you
## would be a lie the player cannot audit, and keeping both readings on one set of
## constants is what makes that impossible rather than merely unlikely.

## Above this a place is glad to see you. Nothing in the game produces town
## standing above neutral yet — see §19 Q38.
const WELCOME: float = 5.0
## Below this a place has heard something and has not decided it does not matter.
const WARY: float = -5.0
## Below this doors start shutting: the trade a stranger will not offer you.
const UNWELCOME: float = -20.0
## Below this you are the thing that happened to the town, not a person in it.
const HATED: float = -60.0


## The five words, worst first. Ordered so a caller can find where it sits.
static func scale() -> Array[StringName]:
	return [&"hated", &"unwelcome", &"wary", &"unknown", &"welcome"]


static func word_for(amount: float) -> StringName:
	if amount <= HATED:
		return &"hated"
	if amount <= UNWELCOME:
		return &"unwelcome"
	if amount <= WARY:
		return &"wary"
	if amount < WELCOME:
		return &"unknown"
	return &"welcome"


## The one place the mechanical threshold is decided. Content names the condition,
## §9's rules layer defines it, and the word on the HUD comes off the same number.
static func is_unwelcome(amount: float) -> bool:
	return amount <= UNWELCOME


static func is_welcome(amount: float) -> bool:
	return amount >= WELCOME


## Past a point somebody will not have the conversation at all. The top of the
## scale has to do something or the scale stops at "chilly".
static func refuses_to_talk(amount: float) -> bool:
	return amount <= HATED
