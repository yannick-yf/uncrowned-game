class_name DeedRules
extends RefCounted

## What a witnessed deed does to how people regard you.
##
## One table, because §8's counterpart rule is only checkable if every deed's
## effects are written in the same place: a change with no counterpart is not
## finished, and that is far easier to miss when each system carries its own
## arithmetic. Adding a row here is what adding a verb costs.
##
## Two sides to a deed and they resolve at different moments. **Factions move once,
## at the act** — a faction is not a place and cannot hear the same story eight
## times. **Towns move as the story arrives**, which is the delay §8's first
## consequence is made of.

const DEED_THEFT: StringName = &"i_stole_in_public"
const DEED_RESTITUTION: StringName = &"i_gave_it_back"
const DEED_WARNING: StringName = &"i_warned_the_town"

## Acts against the six power bases (§3). These are what give the tracked
## quantities inputs that are not somebody's dialogue — which is the whole of why
## Phase 5 was reshaped. Each is a row here rather than a system of its own.
const DEED_SABOTAGE: StringName = &"i_wrecked_a_furnace"
const DEED_BURN_STORES: StringName = &"i_burned_the_stores"
const DEED_ROB_BANK: StringName = &"i_emptied_the_vault"
const DEED_WRECK_ROLLS: StringName = &"i_destroyed_the_muster_rolls"
## Reading a document aloud where people can hear it. It returns to the table now
## that there is evidence to read — it was cut when nothing could perform it.
const DEED_MAKE_PUBLIC: StringName = &"i_made_it_public"
## §3's second lever against the Cinderworks, and the first that is a thing you say
## rather than a thing you break. Sena is organising the others; what she has never
## had is a number to organise them around.
const DEED_TURN_WORKERS: StringName = &"i_turned_the_workers"
## §3's second lever against the Wide Acres, and its third against the Muster. Both
## are things you say to somebody who was already most of the way there.
const DEED_WITHHOLDING: StringName = &"i_organised_a_withholding"
const DEED_RECRUIT: StringName = &"i_recruited_deserters"
## §3's remaining two spoken levers: a convoy that goes the wrong way, and the
## softest ★ deciding not to sign the next one.
const DEED_CONVOY: StringName = &"i_redirected_a_convoy"
const DEED_TURN_LORD: StringName = &"i_turned_the_lord"

## Telling the crown something you know.
##
## **The mirror of making a thing public**, and the only act in the game that helps
## him. Everything else in this table costs him something, which was fine while the
## player could only be against him — and stopped being fine the moment they could
## join. The same fact, spent the other way: it buys you standing with the crown and
## it is gone, exactly as telling a town is (§8's one-shot rule).
const DEED_INFORM: StringName = &"i_informed_the_crown"

const FACTION_TOWNS: StringName = &"towns"
const FACTION_UNDERWORLD: StringName = &"the unlawful"
const FACTION_CROWN: StringName = &"the crown"
## The people the king's project ruined — the razed villages, the men the
## Cinderworks used up. The player is one of them, which is why damage to the crown
## buys standing here that damage to a town never does.
const FACTION_DISPOSSESSED: StringName = &"the dispossessed"


## What the town where the story lands thinks, once it lands.
##
## Theft costs more than a warning gains is *not* the shape here — the warning is
## worth more, and deliberately. Subtraction is free and available; if addition were
## also smaller, the arithmetic would teach the same lesson the gating did.
static func town_effect(deed: StringName) -> float:
	if deed == DEED_THEFT:
		return -22.0
	if deed == DEED_RESTITUTION:
		return 14.0
	# Nobody likes an informer, including the people the crown is protecting. This
	# is what stops the crown route being free: every step up costs you the ground
	# you are standing on, and a crown officer can be despised in every town he has
	# jurisdiction over.
	if deed == DeedRules.DEED_INFORM:
		return -20.0
	if deed == DEED_WARNING:
		return 30.0
	# Acts against the power bases cost you with the place they happen in. The
	# works is the Cinderworks' living, the stores are the Wide Acres' winter, and
	# nobody thanks the man who burned either — however much the crown needed it.
	if deed == DEED_SABOTAGE:
		return -18.0
	if deed == DEED_BURN_STORES:
		return -25.0
	if deed == DEED_ROB_BANK:
		return -20.0
	if deed == DEED_WRECK_ROLLS:
		return -12.0
	if deed == DEED_MAKE_PUBLIC:
		return 25.0
	if deed == DEED_TURN_WORKERS:
		return 15.0
	if deed == DEED_WITHHOLDING:
		return 12.0
	if deed == DEED_RECRUIT:
		return -6.0
	if deed == DEED_CONVOY:
		return -4.0
	if deed == DEED_TURN_LORD:
		return 20.0
	return 0.0


## Who is offended and who is impressed — §8's hard rule, as data. Every deed names
## both, and a deed that names only one has not been finished.
static func faction_effects(deed: StringName) -> Dictionary:
	if deed == DEED_THEFT:
		return {FACTION_TOWNS: -11.0, FACTION_UNDERWORLD: 14.0}
	if deed == DEED_RESTITUTION:
		# More than the theft gained. A thief who gives things back is no use to
		# anybody, and the door that opened shuts harder than it opened.
		return {FACTION_TOWNS: 7.0, FACTION_UNDERWORLD: -18.0}
	if deed == DEED_WARNING:
		# Telling a town the king's army is rotting is sedition, whoever it helps.
		return {FACTION_TOWNS: 15.0, FACTION_CROWN: -25.0}
	if deed == DEED_SABOTAGE:
		return {FACTION_TOWNS: -9.0, FACTION_CROWN: -20.0, FACTION_DISPOSSESSED: 26.0}
	if deed == DEED_BURN_STORES:
		return {FACTION_TOWNS: -14.0, FACTION_CROWN: -22.0, FACTION_DISPOSSESSED: 18.0}
	if deed == DEED_ROB_BANK:
		return {FACTION_TOWNS: -10.0, FACTION_CROWN: -28.0, FACTION_UNDERWORLD: 30.0}
	if deed == DEED_WRECK_ROLLS:
		return {FACTION_CROWN: -24.0, FACTION_TOWNS: 6.0, FACTION_DISPOSSESSED: 14.0}
	if deed == DEED_MAKE_PUBLIC:
		return {FACTION_CROWN: -30.0, FACTION_DISPOSSESSED: 22.0, FACTION_TOWNS: 8.0}
	if deed == DEED_TURN_WORKERS:
		return {FACTION_CROWN: -26.0, FACTION_DISPOSSESSED: 24.0, FACTION_TOWNS: -8.0}
	if deed == DEED_WITHHOLDING:
		return {FACTION_CROWN: -24.0, FACTION_DISPOSSESSED: 20.0, FACTION_TOWNS: -6.0}
	if deed == DEED_RECRUIT:
		return {FACTION_CROWN: -28.0, FACTION_UNDERWORLD: 16.0, FACTION_TOWNS: -10.0}
	if deed == DEED_CONVOY:
		return {FACTION_CROWN: -22.0, FACTION_UNDERWORLD: 20.0, FACTION_TOWNS: -6.0}
	if deed == DEED_TURN_LORD:
		return {FACTION_CROWN: -32.0, FACTION_DISPOSSESSED: 26.0, FACTION_TOWNS: 12.0}
	if deed == DEED_INFORM:
		# The only row that moves the crown *up*. It costs you with the people it is
		# about, which is the price of it being worth anything.
		return {FACTION_CROWN: 28.0, FACTION_DISPOSSESSED: -30.0, FACTION_TOWNS: -12.0}
	return {}


## What somebody who *watched you do it* thinks, personally.
##
## Worse than what their town thinks, and better when it is good: seeing a thing
## is not hearing about it. Everyone else in the town moves with the town, because
## a town's opinion is the aggregate of the people in it — so the two track each
## other until somebody is standing there, and from then on that one person's
## opinion is their own.
static func witness_effect(deed: StringName) -> float:
	if deed == DEED_THEFT:
		return -30.0
	if deed == DEED_RESTITUTION:
		return 20.0
	if deed == DEED_WARNING:
		return 35.0
	if deed == DEED_SABOTAGE:
		return -34.0
	if deed == DEED_BURN_STORES:
		return -40.0
	if deed == DEED_ROB_BANK:
		return -36.0
	if deed == DEED_WRECK_ROLLS:
		return -20.0
	if deed == DEED_MAKE_PUBLIC:
		return 30.0
	if deed == DEED_TURN_WORKERS:
		return 22.0
	if deed == DEED_WITHHOLDING:
		return 18.0
	if deed == DEED_RECRUIT:
		return -10.0
	if deed == DEED_CONVOY:
		return -8.0
	if deed == DEED_TURN_LORD:
		return 26.0
	return 0.0


## What a deed does to how a town regards **the crown**, when word of it arrives.
##
## Only one deed does anything here, and it is the whole of Route C: reading a
## document out is not news about you, it is news about *him*. A theft in Harrowgate
## says nothing about the king; the Cinderworks ledger read aloud in a market says
## everything, and it says it in every town the story reaches.
##
## Which is why Route C is a tour rather than an errand — and why the King's Road
## and the people on it matter to a player who never steals anything.
static func sentiment_on_arrival(deed: StringName) -> float:
	return -12.0 if deed == DEED_MAKE_PUBLIC else 0.0


## Whether the story goes anywhere, which is not the same as whether it mattered.
##
## A theft is worth repeating three days' walk away. So is a man standing in the
## square telling a town the king's army is rotting. Somebody quietly putting
## something back on a stall is not — it is news to the people who saw it and to
## nobody else, which is exactly why restitution repairs the place and not the past.
static func travels(deed: StringName) -> bool:
	return deed != DEED_RESTITUTION


## What a deed does to the world, as quantity -> amount. Pushed rather than
## assigned, so the player's hand is recorded and §3's endings can count it.
##
## The whole reason Phase 5 was reshaped lives in this function: two of the twelve
## quantities moved, dialogue was the only input to the only one that mattered, and
## the game had started to feel like matching people to states. These are the other
## ways in, and they are acts rather than conversations.
static func world_effects(deed: StringName) -> Dictionary:
	if deed == DEED_SABOTAGE:
		# A cold furnace makes nothing, and the men who tend it stop believing the
		# works will outlast them.
		return {&"steel_output": -22.0, &"worker_morale": -12.0}
	if deed == DEED_BURN_STORES:
		# The crown eats what the Wide Acres grow. Burn it and the crown buys it.
		return {&"crown_treasury": -18.0}
	if deed == DEED_ROB_BANK:
		# §3's sixth power base, and there is only one counting house — so this is
		# the single largest act in the game and is sized like it. It was -26/-34,
		# which left the *coupling* carrying more of the fall than the robbery did:
		# §8 says ambient drift stays small and player-caused change is large, and
		# that had it the wrong way round.
		return {&"crown_treasury": -40.0, &"bank_confidence": -52.0}
	if deed == DEED_WRECK_ROLLS:
		# You cannot pay men you cannot name, and the officers blame each other.
		return {&"army_strength": -18.0, &"faction_tension": 16.0}
	if deed == DEED_MAKE_PUBLIC:
		# What the crown did stops being what the town suspects and becomes what it
		# knows. §3's `discredited` ending is the sum of these.
		return {&"town_sentiment": -20.0, &"faction_tension": 8.0}
	if deed == DEED_TURN_WORKERS:
		# Men who know what the furnaces cost tend the furnaces worse.
		return {&"worker_morale": -30.0, &"steel_output": -15.0, &"town_sentiment": -10.0}
	if deed == DEED_WITHHOLDING:
		# The estates feed the capital and the standing army. A harvest that stays
		# in the barn is a harvest the crown has to buy at somebody else's price.
		return {&"crown_treasury": -24.0, &"town_sentiment": -8.0}
	if deed == DEED_RECRUIT:
		# One deserter who will talk to other deserters is worth more to you than
		# any document, and worth less to the man who has to replace them.
		return {&"army_strength": -20.0, &"faction_tension": 12.0}
	if deed == DEED_CONVOY:
		# A month of steel and grain that goes west and does not arrive.
		return {&"crown_treasury": -18.0, &"steel_output": -10.0}
	if deed == DEED_TURN_LORD:
		# The man who signs the sentences stops signing them. Nothing in the region
		# changes for a month and then everything does.
		return {&"faction_tension": 20.0, &"town_sentiment": -14.0}
	return {}


## Deeds nobody performed do nothing, and a deed with no counterpart is a bug. Used
## by the test that walks every deed in the table.
static func all_deeds() -> Array[StringName]:
	return [
		DEED_THEFT, DEED_RESTITUTION, DEED_WARNING,
		DEED_SABOTAGE, DEED_BURN_STORES, DEED_ROB_BANK, DEED_WRECK_ROLLS,
		DEED_MAKE_PUBLIC, DEED_TURN_WORKERS, DEED_WITHHOLDING, DEED_RECRUIT,
		DEED_CONVOY, DEED_TURN_LORD, DEED_INFORM,
	]
