class_name DialogueOption
extends RefCounted

## One thing the player may say, and the one thing it means.
##
## SPECS §9: the player never types. Every utterance maps to a known intent, so
## nothing can be talked into existence that the systems did not already permit.
## The text is hand-written and looked up — never generated — and `tag` is the
## visibly trait-gated marker Fallout uses. Traits do not exist yet, so `tag` is
## display-only: it labels the option, it does not gate it.

var intent: StringName = &""
var text: String = ""
var reply: String = ""
var tag: StringName = &""
var teaches: StringName = &""
var requires: StringName = &""
var hides_after: StringName = &""
## A named world condition, evaluated by DialogueRules. Content names it; the
## rules layer decides what it means. Dialogue that reads the world directly would
## put game logic in content/, and content cannot be reasoned about.
var requires_condition: StringName = &""
## The same, inverted: a line that exists until the world turns against it. Needed
## because a door shutting is as much a consequence as one opening, and "you may no
## longer offer to buy anything" has to be expressible as content.
var forbids_condition: StringName = &""
## What saying this asks of the listener. `goodwill` means it costs them something
## to answer — a fact confided, a favour, a name given up — and people do not do
## that for somebody they think ill of. Anything that teaches a fact is goodwill by
## default; `costs: "free"` is how content marks the one source of a fact that must
## stay open however badly the conversation is going (invariant 6).
var costs: StringName = &""


## Some things bear asking twice — a trader's stock, a guard's "anything moving on
## the road". Most do not: a man who has told you where the ford is has told you.
var repeatable: bool = false
## A deed this line performs. §3 lists levers like "turn the workers" that are
## plainly things you *say* rather than things you do to a building, and until now
## nothing in a conversation could cause anything — which is most of why a cast
## risked being lore. The rules layer still decides whether the line is offered;
## this only names what saying it does.
var causes: StringName = &""
## A side this line joins you to. Separate from `causes`, which names a deed: joining
## is not an act against the world, it is a declaration about yourself, and the two
## want different machinery. Content names the side; `FactionRules` decides whether
## it is one.
var joins: StringName = &""


## An answer already given. Asking Maddox the same question forty times was possible
## and felt like talking to a machine, which is the opposite of what a conversation
## with a finite person should feel like: you leave having *used somebody up*.
func spent_by(npc: StringName) -> StringName:
	return StringName("asked:%s:%s" % [npc, intent])


func asks_for_goodwill() -> bool:
	if costs == &"free":
		return false
	return costs == &"goodwill" or teaches != &""


## Which trait this line visibly leans on, lowercased for lookup. The bracket and
## the word belong to the window: `[Wits]` was still English in a French game
## because core was building the string, which is the layering leak the journal had.
## The trait this line leans on, or nothing. §11 always meant `tag` to be the
## visibly trait-gated marker Fallout uses — it was display-only because traits did
## not exist. They exist now, so it gates.
func needs_trait() -> StringName:
	return StringName(String(tag).to_lower()) if tag != &"" else &""


func tag_key() -> StringName:
	return StringName("trait.%s" % String(tag).to_lower()) if tag != &"" else &""
