class_name Phraser
extends RefCounted

## Whatever chooses the words, if anything does.
##
## Lives in `view/` on purpose. Asking a model is not part of the simulation: it is
## slow, it is not repeatable, and `core/` must be both. The window asks, and submits
## the answer back as an ordinary event so it is logged and replayed like a keypress.
##
## **The default asks nothing and returns nothing**, which means the game ships today
## with every line hand-written and this whole path switched off. That is the point of
## building it now: the pipeline is finished, tested and inert, and turning a model on
## later is replacing one function rather than opening up the dialogue system.

## Words for this situation, or "" to keep the authored line.
##
## `packet` is what Context.build produced. `option` is the line being answered.
## Anything returned is checked before anybody hears it (ProseRules), so an
## implementation may be as careless as it likes without being dangerous.
func phrase(_packet: String, _option: DialogueOption, _language: String) -> String:
	return ""


## Whether this phraser can answer at all. A model that is missing, still loading or
## switched off says no, and the game carries on with the authored lines.
func ready() -> bool:
	return false


func describe() -> String:
	return "authored lines only"
