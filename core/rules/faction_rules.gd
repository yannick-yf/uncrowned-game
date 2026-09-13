class_name FactionRules
extends RefCounted

## Two sides, and not joining either.
##
## **The crown** is industry, the road, the cities, order and the tiered law. **The
## opposition** is the forest, magic, the displaced and the poor. That is §4's thesis
## with people in it: the map already argues, and this is who is arguing.
##
## **Neutral is not a third faction.** It is the default, it is free, and it is what
## the game already was — everything that worked before joining exists still.
##
## **They feed the three routes, they do not replace them.** The crown opens Access
## and lets the player rise until the castle admits them; the opposition feeds
## Exposure by carrying what the player makes public further than one town; joining
## neither leaves Force, which needs nobody's permission. **One structure, not two** —
## and that is what keeps invariant 7 true when the player joins the crown and helps
## it hunt the opposition to nothing: Force survives everything.

const NEUTRAL: StringName = &""
const CROWN: StringName = &"crown"
const OPPOSITION: StringName = &"opposition"

const SIDES: Array[StringName] = [CROWN, OPPOSITION]

## The standing dimension each side reads. Joining is what you *are*; standing is
## what they think of you, and the two are different — a crown officer can still be
## despised in Harrowgate.
const READS_STANDING: Dictionary = {
	CROWN: DeedRules.FACTION_CROWN,
	OPPOSITION: DeedRules.FACTION_DISPOSSESSED,
}

## The route each side opens. Neither *is* a route: they feed one.
const OPENS: Dictionary = {CROWN: &"access", OPPOSITION: &"exposure"}


# ------------------------------------------------------------------ ranks ---

## What you are called, and what it took. Four each, and the last one is the point:
## the crown's last rank is the castle door, the opposition's is a hearing.
const RANKS: Dictionary = {
	CROWN: [
		{"key": &"rank.crown.0", "needs": 0.0},
		{"key": &"rank.crown.1", "needs": 25.0},
		{"key": &"rank.crown.2", "needs": 60.0},
		{"key": &"rank.crown.3", "needs": 110.0},
	],
	OPPOSITION: [
		{"key": &"rank.opposition.0", "needs": 0.0},
		{"key": &"rank.opposition.1", "needs": 25.0},
		{"key": &"rank.opposition.2", "needs": 60.0},
		{"key": &"rank.opposition.3", "needs": 110.0},
	],
}

## The rank at which the crown stops asking who you are at the gate, and the rank at
## which the opposition will put a room together for you to read in.
const RANK_OPENS_THE_DOOR: int = 3


static func rank_for(side: StringName, served: float) -> int:
	var table: Array = RANKS.get(side, []) as Array
	var rank: int = 0
	for step: int in table.size():
		if served >= float((table[step] as Dictionary)["needs"]):
			rank = step
	return rank


static func rank_key(side: StringName, rank: int) -> StringName:
	var table: Array = RANKS.get(side, []) as Array
	if table.is_empty():
		return &""
	return (table[clampi(rank, 0, table.size() - 1)] as Dictionary)["key"] as StringName


# ------------------------------------------------------------------- jobs ---

## What each side counts as work, and what it is worth.
##
## The opposition's list is the deed table it already had: everything that costs the
## king something is service, which is why joining them needs no new acts. The
## crown's is shorter and deliberately so — there was **nothing pro-crown in the
## game** before this, and inventing ten new systems to fix that would have been the
## wrong repair. Two acts: give back what you took, and tell them something you know.
##
## **Extended 2026-09-13** (§8's second direction): the crown's list is now the whole
## "builds it by" column — every act that strengthens one of the four places is
## service, and each costs somebody with a face, which is what stops it being free.
const WORTH: Dictionary = {
	CROWN: {
		&"i_gave_it_back": 12.0,
		&"i_informed_the_crown": 30.0,
		&"i_enforced_the_grants": 24.0,
		&"i_got_the_convoys_moving": 20.0,
		&"i_delivered_labour": 22.0,
		&"i_settled_the_wage": 18.0,
		&"i_fed_it_the_forest": 20.0,
		&"i_paid_the_muster": 26.0,
		&"i_fed_the_muster": 18.0,
		&"i_handed_over_the_deserters": 30.0,
		&"i_restored_confidence": 24.0,
		&"i_brought_the_creditors": 28.0,
	},
	OPPOSITION: {
		&"i_wrecked_a_furnace": 26.0,
		&"i_burned_the_stores": 22.0,
		&"i_emptied_the_vault": 24.0,
		&"i_destroyed_the_muster_rolls": 24.0,
		&"i_made_it_public": 30.0,
		&"i_turned_the_workers": 28.0,
		&"i_organised_a_withholding": 26.0,
		&"i_recruited_deserters": 22.0,
		&"i_redirected_a_convoy": 20.0,
		&"i_turned_the_lord": 32.0,
		&"i_warned_the_town": 16.0,
	},
}

## Telling the crown something you know. The one act joining them adds, and the mirror
## of making a thing public: the same fact, spent the other way.
const DEED_INFORM: StringName = &"i_informed_the_crown"


static func worth_to(side: StringName, deed: StringName) -> float:
	return float((WORTH.get(side, {}) as Dictionary).get(deed, 0.0))


## Serving one side costs you with the other. Nobody is owed two loyalties.
static func costs_the_other(side: StringName) -> StringName:
	if side == CROWN:
		return OPPOSITION
	return CROWN if side == OPPOSITION else NEUTRAL


# ---------------------------------------------------------------- the map ---

## Who holds what, before anybody does anything.
##
## **Ownership is a fact, not a constant** — that is the whole point of it being here
## rather than in `Region`. The crown holds its eight points and the line between
## them; the forest holds the ground between. Two are **contested**, and they are the
## two that can change hands, so the player's choices show on the map.
const CONTESTED: Array[StringName] = [&"wide_acres", &"saltmarch"]

const CROWN_HOLDS: Array[StringName] = [
	&"cinderworks", &"harrowgate", &"muster", &"cairnwell", &"blackcairn",
]
const FOREST_HOLDS: Array[StringName] = [&"brindle"]


static func holds_at_start() -> Dictionary:
	var out: Dictionary = {}
	for zone: StringName in CROWN_HOLDS:
		out[zone] = CROWN
	for zone: StringName in FOREST_HOLDS:
		out[zone] = OPPOSITION
	# The borders start as the king's too (2026-09-13). "A border is not a side" was
	# v1's, and a place has exactly two states now — crown-held or free — so the neutral
	# start is retired. What makes these two borders is that the band can still move
	# them; the other places with a state move only by the player's hand (PlaceRules).
	for zone: StringName in CONTESTED:
		out[zone] = CROWN
	return out


static func can_change_hands(zone: StringName) -> bool:
	return CONTESTED.has(zone)


## How sour a town has to be on the crown before the ground under it changes hands,
## and how glad before it changes back. A band, not a line, so a place cannot flicker.
const TURNS_TO_OPPOSITION: float = 30.0
const TURNS_TO_CROWN: float = 70.0


static func holder_after(zone: StringName, was: StringName, sentiment: float) -> StringName:
	if not can_change_hands(zone):
		return was
	if sentiment < TURNS_TO_OPPOSITION:
		return OPPOSITION
	if sentiment > TURNS_TO_CROWN:
		return CROWN
	return was
