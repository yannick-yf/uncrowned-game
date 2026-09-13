# Uncrowned — Design Document

> **The game is not about weakening the king. It is about what the kingdom becomes.
> Breaking it and strengthening it are both real plays, both cost someone, and the
> ending is a reading of the state left behind — including the reading where the
> player is the one on the throne.** *(The thesis, 2026-09-13. Everything below is it,
> made mechanical.)*

> **How to use this doc.** It is the source of truth: when the code and this
> document disagree, one of them is wrong and you decide which. Leave `TBD`
> everywhere you're unsure — an empty section is information.
>
> **Precedence.** This file wins on *what the game is*. `CLAUDE.md` wins on *how we
> work* and *which phase we are in*, including any phase exceptions it declares.
>
> **Sections marked 🟡 were invented by Claude at Yannick's request** and need his
> approval or rejection. Everything else came from him.

**Status:** **v1 delivered, 2026-09-13; v2 specified in this document the same day**,
from `docs/history/V2_INTENT.md`, moved there the same day once every passage below carried it.
Everything dated 2026-09-13 and marked v2 is *specified, not built*: §18 has the
roadmap. Five sections still carry 🟡 — they were invented by Claude, they were
*built* anyway because v1 needed them, and they still want Yannick's yes or no. §3's
power bases, §6's roster and §8's world tick were approved long ago.
**Last updated:** 2026-09-13
**Version:** 2.0 — specified, not built
**Location:** this file, `uncrowned-game/docs/SPECS.md`, is the single source of
truth on *what the game is*. For *what currently exists* — which is the question you
have if you have just arrived — read `docs/V1.md` first; it is two pages. `CLAUDE.md`
wins on how we work. Finished working logs and the original raw notes are in
`docs/history/` and are never authoritative.

---

## 0. Glossary

Every invented proper noun in this document, in one line each. **Names are
placeholders** and may change; what each thing *is* should not.

### Places

| Name | What it is | Defined in |
|---|---|---|
| **Erileo** | The region the whole game takes place in. One region, bounded by sea and mountains | §4 |
| **Brindle** | The player's village, burned to clear ground for the works. Where they wake, and where they respawn | §4, §5 |
| **The Cinderworks** | The stone and steel works, built on Brindle's own ground. Holds the death ledger | §3, §4 |
| **Harrowgate** | The first town, south-centre on the road. Market, gossip, the tiered law in daily practice | §3, §4, §6 |
| **The Wide Acres** | Consolidated farm estates feeding the capital and the army. Holds the land grants | §3, §4 |
| **The Muster** | The standing army's camp, at the road's crossroads. Muster rolls, pay fraud, signed orders | §3, §4 |
| **Saltmarch & Greyhold** | One zone, two names: the port town (Saltmarch) and the sub-castle above it (Greyhold) | §3, §4 |
| **Cairnwell** | The capital, north-west. The bank is in it | §3, §4 |
| **Blackcairn** | The castle, against the northern mountains. The king is here, reachable from minute one | §4 |
| **The Kettle** | The river, running from the northern mountains to the southern sea. One guarded bridge, one ford downstream | §4 |
| **The Thornwood** | The wood off the road: unwatched, slow, the short way — and where magic still lives | §4, §5 |
| **The Iron Spine** | The impassable mountains along the eastern edge | §4 |
| **The Redcut** | The iron quarry in the eastern mountains. An optional zone, cut first if behind | §4 |
| **The King's Road** | The paved, patrolled route across the region. Fast and watched; everything done on it is seen | §4 |

### People

★ marks route-critical. Every ★ fact has a second source **except Hesper**, which
is deliberate — see §6.

| Name | Who they are | Where |
|---|---|---|
| **Wren** | Scavenger picking Brindle's ruins. Not from there; arrived after | Brindle |
| ★ **Foreman Halgrave** | Runs the Cinderworks and believes in it. Keeps the death ledger, proudly | The Cinderworks |
| **Sena** | Furnace worker, lost a hand, organising the others. Has copied ledger pages | The Cinderworks |
| **Doctor Ivo Marsh** | The works' physician. Knows the true death count, including the unrecorded | The Cinderworks |
| **Maddox** | Innkeeper. Knows everyone, believes nothing. The cheapest way into almost any thread | Harrowgate |
| **Tovin the Reeve** | Administers the tiered law locally, apologetically | Harrowgate |
| **Bell** | Apprentice scribe, an adult. Has the wealth tiers memorised | Harrowgate |
| **Ossa** | Herbalist. Treats everyone, deserters included — which is how she knows about the pay fraud | Harrowgate |
| **Garrick** | Caravan master. Moves between zones and carries rumour physically | Harrowgate |
| ★ **Estate Lord Cadan Vale** | Holds the land grants naming the razed villages | The Wide Acres |
| **Nessa Vale** | His steward and daughter. Keeps the actual paperwork | The Wide Acres |
| **Old Pell** | Tenant farmer who worked Brindle's soil before and after the burning. Knew the player's family; does not recognise them | The Wide Acres |
| ★ **Commander Ryse** | Led the clearances and sleeps fine. Holds the signed orders — and, having drilled against the king, how he fights | The Muster |
| **Quartermaster Odile** | Running the pay fraud. Holds the muster rolls and her own crime | The Muster |
| **Kell** | A deserter hiding in the Thornwood. He was at Brindle that night — the closest thing to a witness | The Thornwood |
| ★ **Lord Aurel Greyhold** | Administers the tiered law and privately believes it indefensible. The softest ★ to turn | Greyhold |
| **Harbourmaster Til** | Smuggler by preference. Knows what leaves the region and on whose order | Saltmarch |
| **Mira Sand** | Advocate for the poor under the tiered law. Evidence with faces on it | Saltmarch |
| ★ **Corvin Ash** | Banker holding the crown's debts | Cairnwell |
| **Archivist Peyre** | The crown's record keeper. Second source for the debts *and* the land grants | Cairnwell |
| ★ **Hesper** | Court steward. Controls who gets papers into Blackcairn — the key to Route B, and its single point of failure by design | Cairnwell |
| **Brother Anselm** | Her secretary. The way in to her, and a second source on the church's ledgers | Cairnwell |
| **The King** | Name TBD. Believes he was right, and can produce the orders he signed | Blackcairn |
| **Captain of the Guard** | Name TBD. Commands the escort, which shrinks as power bases fall | Blackcairn |

### Things worth naming

| Name | What it is | Defined in |
|---|---|---|
| **The tiered law** | Law that sorts people by wealth and origin, so the same act costs different people differently. The king's argument's weakest point | §3, §5 |
| **The death ledger** | The Cinderworks' record of what the works cost in lives. The king required it and thought the price worth paying | §3, §6 |
| **The land grants** | The papers naming the razed villages, Brindle among them, with a date and a signature. Where the player finds their own village | §3, §6 |
| **The signed orders** | The clearance orders, signed by the king himself | §3, §5, §6 |
| **The fairies** | What lives in the Thornwood, and the only magic in the game. They raised the player because the king is clearing the forest and killing them with it, and they needed somebody with cause to stop him | §5 |
| **The raising** | The one miracle. The player died at Brindle and came back months later, paying their memory for it | §5 |
| **The muster rolls** | The army's own pay records — fat with men who are dead or never existed | §3, §6 |
| **Route A / Force** | Fight through the door | §3 |
| **Route B / Access** | Be admitted: become someone the castle lets in | §3 |
| **Route C / Exposure** | The bloodless route: assemble the evidence and put it in front of him | §3 |
| **The six power bases** | The Cinderworks, the Wide Acres, the Muster, Greyhold, Harrowgate, the bank. **Never** "Pillar N". In v2 four are built deeply and carry a state; Greyhold and Harrowgate are deferred | §3 |
| **The five design pillars** | §1's numbered pillars — the only thing "Pillar" ever means | §1 |
| **Hardship** | What an act costs the people who live in a place, held per town beside the twelve quantities. Up is worse. The second axis, which makes both directions cost something | §8 |
| **Crown-held / free** | The two states a place can be in — never a third, never better than it started. Four places carry one; Blackcairn has one state and never flips | §8, §3, §4 |
| **The decisive change** | One act per place, at its landmark, with the thing the place holds — the grants, the ledger, the rolls, the debts — whose outcome lands crown-held or free | §3 |
| **The freeze window** | 2 in-game days = 2880 ticks = 12 real minutes. How long a state the player set holds against everything — the sentiment band and the opposite decisive act alike; also what "recently" means to Blackcairn | §8, §4 |
| **The throne reading** | Deposed, with the player's handprint, at high crown standing: the player takes the throne. A reading of one ending, not a sixth | §3 |

---

## 1. Pillars

**Pitch (one sentence):**
An open-world RPG about holding a king to account: he is reachable from the first
minute, killing him is only one of the ways it can end, and the hardest ending is
making him answer for what he did.

**Player fantasy** — you arrive as nobody, with half your memory gone, and become
someone the world has to reckon with. Not through levels, but through what you
learn, who you side with, and what you turn out to be willing to do.

**Pillar 1 — The king is reachable from minute one.**
No progression flag ever gates an action. If the player finds a way into the castle
on day one, they get their confrontation. What stops them is their own weakness,
their ignorance of why any of this happened, and the fact that nobody will let them
through a door. Never a locked quest step.

**Pillar 2 — Accountability, not assassination.**
The goal is to face the king with what he did and what it cost. Killing him is one
resolution among several, and not the richest one. A run in which nobody dies is a
complete, intended way to play — not a self-imposed challenge.

**Pillar 3 — Total permissiveness, no dead ends.**
Every NPC in the game can be killed, including quest-critical ones. The design never
protects itself by making someone invulnerable. Instead every objective has more
than one path, so the world absorbs the player's violence rather than refusing it.

**Pillar 4 — The world runs without you.**
It drifts on its own clock whether or not the player acts, and it reacts to what the
player did and to who saw them do it.

**Pillar 5 — You are what they can see and hear.**
An NPC's behaviour is decided by the player's traits, appearance, reputation, and
what the two of them have said before. The same sentence lands differently coming
from a stranger, a local hero, and a known killer.

### What this game is not

- Not a linear story RPG. There is no correct order and no intended path.
- Not a roguelike. One long save-based playthrough, not repeated runs.
- Not a game that punishes "wrong" choices by blocking progress. Choices close
  paths and open others; they never strand the player.
- Not a game whose ending is a cutscene earned by levelling.

---

## 2. Core loop

**Moment to moment (30s):** move through a zone, look at who's there, talk, take,
fight if it comes to that.

**Short loop (10 min):** follow one thread — a rumour, a person, a building — and
come away with a fact, an item, or a changed relationship.

**Session loop (1h):** study, break or strengthen one of the four places, and watch
the region react to it over the following in-game days — including the people it cost.

**Full playthrough:** arrive with nothing and no memory. Learn what the king did and
why he became the man who did it. Move the kingdom — break what holds him up, or
build it, or some of each — until a confrontation is survivable or unnecessary.
Decide, standing in front of him or in his place, what you actually came for, and
read what the kingdom became.

### Three phases of play — a description, never gates (2026-09-13)

A playthrough tends to take this shape, the way §3 says routes are names for what
tends to work. Nothing checks which phase you are in; nothing opens or closes on it.

| | Phase | What it tends to be |
|---|---|---|
| 1 | **Creation, the fairy, the tutorial** | Six traits and a pool of ten; seven things said once; the walk out of the clearing with the furnaces in frame. Ninety seconds that must point both ways (§5) |
| 2 | **The organic world** | The four places, the twelve quantities and hardship, the two directions, rank, rumour on the road. Most of a game is here, and none of it is a step |
| 3 | **Confront the king** | Blackcairn, by any of the three ways in, with whatever the kingdom has become behind you — or the reading where the throne is yours and there is nobody left to confront (§3) |

**Phase 3 is available in minute one.** That is Pillar 1 and it is not negotiable. A
player who walks there at 10 HP gets their confrontation and loses it; the phases
describe when a confrontation tends to *go well*, never when it is *allowed*.

**After the ending:** the world continues (see §5, Endings).

**Expected playthrough length:** TBD

**What makes a player start a second run:** TBD

---

## 3. The king

**Who he is, in one paragraph:**
> TBD — needs a name. His argument is written in §5.

**Why the player has cause against him** *(retitled 2026-09-13; was "why the player
wants him dead")*:
The player's village was a small farming community, cleared by the king's men because
the steel works needed the ground. Everyone the player loved was killed. The player
survived, barely, and lost most of their memory — but not that. It was policy, not
malice, and that is the point (§5): the grievance is whole, the target is a decision
and the man who signed it, and it can be answered by breaking him or by changing what
the kingdom does with its ground.

**Why attempt #1 fails:**
> TBD — write the exact first-attempt experience: what the player sees, tries, and
> loses to. This is the tutorial whether you intend it or not.

At the start the player has 10 HP; the king has 1000, and ten guards. That gap is
the design's opening statement, and the player is allowed to walk into it.

### How the difficulty gap actually closes 🟡

Three levers, deliberately unequal:

| Lever | What it changes | How much of the gap it closes |
|---|---|---|
| **Power bases** | The king's *escort*, derived from army strength (§8): ten men at full, five once the pay fraud is public, two when nothing is left | Most of it |
| **Knowledge** | Fights the king's tells and phases — knowing how he fights turns a wall into a duel | A lot |
| **Levels & equipment** | Player HP and damage | The rest |

The king's own 1000 HP does not change. What changes is how many people are standing
between the player and him, and how well the player understands the man they're
fighting. This keeps grinding from being the answer, which matters — a game where
levelling closes a 100× gap is a game about levelling.

> **Design rule:** the power bases are the difficulty curve. Levelling is the fine
> adjustment, never the strategy.

### The four places, and what can be done to them (2026-09-13)

> Approved 2026-09-11 as *the six pillars of his power*; retitled and given its
> second direction 2026-09-13. Each is a place the player can go, study, **break or
> strengthen**. The "teaches" column is not flavour — it is the evidence Route C
> (Exposure) is assembled from — and the old "how it can be weakened" column is now
> one half of a pair.
>
> **Naming rule (hard).** These are referred to **by name** — the Cinderworks, the
> Wide Acres, the Muster, the bank, and the two deferred, Greyhold and Harrowgate —
> and never as "Pillar N". "Pillar" alone means one of the five design pillars in §1.

**Four places, deeply — not six thinly.** Each supplies the crown with one thing,
carries one of two **states** (§8: crown-held or free, never a third, never better
than it started), and can be moved either way by acts that cost somebody with a face
(§8's hard rule). They are already the four landmarks `SiteRules` reaches — kiln,
granary, counting house, muster rolls — so the spine needs no new landmark machinery.

| Place | Supplies | States | Break it | Strengthen it |
|---|---|---|---|---|
| **The Wide Acres** | Food — the capital and the army eat what the estates grow | crown-held, or **free**: the land back with the smallholders who farmed it | Burn the stores; organise a withholding; redirect a convoy; return the land to smallholders | Enforce the grants; get the convoys moving |
| **The Cinderworks** | Steel — and it eats the Thornwood for fuel | crown-held, or **free**: the furnaces cold, or the works run by the men who work it | Sabotage the furnaces; turn the workers; cut the ore from the quarry | Deliver labour; settle the wage dispute; **feed it the forest** |
| **The Muster** | Force — the standing army, and the escort derived from it (§8) | crown-held, or **free**: the camp hollow, the captains turned | Expose the pay fraud; starve it; turn the captains; recruit deserters; destroy the rolls | Pay it; feed it; hand it the deserters |
| **The bank at Cairnwell** | Money — the debts that finance the works | crown-held, or **free**: the crown's credit gone, and the creditor's word the only one that counts | Rob it; hand over the records; expose the debts | Restore confidence; bring it the crown's creditors |

**The decisive change is one act with two outcomes, not two acts.** Each place holds
one thing — the grants, the ledger and the men who keep it running, the rolls and the
fraud in them, the debts — and the decisive change is what the player does with that
thing *at the landmark*. Spent one way it frees the place; spent the other it holds
the place for the crown. It is the same shape §8 already has for a fact — told once,
to one audience, chosen — and the same shape as making a thing public against
informing on it. That is what lets invariant 5 stay literally true with one quest's
worth of writing per place: nothing about the deed says which way it will land, and
what decides it is what the player brought — facts held, standing, whose side they
said they were on. Never a menu at the landmark.

| Place | The decisive change — one act, two outcomes | What it teaches | Whose face the cost has |
|---|---|---|---|
| **The Wide Acres** | The **land grants** at the estate: read to the tenants, the land goes back — **free**. Enforced for Vale, the estates stay his and produce for the crown — **crown-held** | The estates sit on razed villages, named in the grants. This is where the player finds their own village on paper | Free it and the Muster and the towns go hungry — Ossa's patients, the bread price. Hold it and Pell works razed ground for the man who owns it, harder |
| **The Cinderworks** | The **ledger and the wage** at the works: the ledger read to the men who are in it, they walk — **free**. The wage settled and labour delivered, the furnaces run hotter — **crown-held** | What the works cost in lives, that Arthur kept the ledger himself, and that he considered the price worth paying | Free it and the men Sena organises lose the only wage on this ground. Hold it and the wood shrinks faster — Kell's fire, the fairies' clearing — and the ledger grows |
| **The Muster** | The **rolls** at the pay tent: the fraud exposed and the rolls destroyed, the camp empties — **free**. The camp paid and the deserters handed back, the rolls made honest — **crown-held** | The names of the men who burned Brindle, the orders they were given, signed — **and how the king fights** | Free it and deserters buy the bread the towns ate (§8's second consequence). Hold it and the men Ossa hides are handed back, Kell first |
| **The bank at Cairnwell** | The **debts** at the counting house: the records handed to the creditor, he calls them in — **free**. The creditors brought to the table, the crown's credit stands — **crown-held** | The whole project is leveraged, and the king is personally afraid of one specific creditor | Free it and the works stop paying and the towns pay in kind. Hold it and the debt is serviced from the tiered law's fees — Mira's clients |

**The other acts move the quantities; only the decisive one moves the state.** Burn
the stores and grain rises and hardship lands, and the Wide Acres is still the
crown's. That is deliberate: a place should be able to be *hurt* without being
*decided*, or every act at a landmark would be the last one, and the freeze window
(§8) would be doing the work the player's judgement should.

**Wood gets no town of its own.** The Thornwood is terrain and the Cinderworks needs
fuel, so felling the forest is a *Cinderworks* consequence: feed it the forest and
`held_ground` (§4) falls faster; put the furnaces out and it stops. The factory eating
the forest that saved the player's life becomes a mechanic rather than backstory, at
the cost of one belt of tile work (§4, §13) rather than a whole zone.

**Greyhold and Harrowgate are deferred, not cut.** Greyhold has no location (Q40) and
its lord stands in Cairnwell; Harrowgate is the first town, and what it taught — that
consent is manufactured, and how — is now taught at every gate by the entrance signs
(§15). Neither carries a state in v2. Their v1 rows are kept here so that nothing is
lost if either is built:

| Deferred | What it was | How it could be weakened | What it teaches |
|---|---|---|---|
| **Greyhold** — the sub-castle | The regional seat and its lord, the king's enforcer of the wealth-tiered law | Turn the lord; blackmail him; kill him; discredit him publicly | How the tiered law is actually administered, and that the lord privately believes it indefensible |
| **Harrowgate** — the town | The civil population whose loyalty the crown assumes | Shift its reputation of the king; expose the tiered law's local effects; provoke or prevent a riot | That consent is manufactured, and how — which is also the mechanism Route C exploits |

### How a reign ends (2026-09-11)

**The goal is not to kill the king. It is that he stops being king.** Killed,
ruined, deposed, discredited, abandoned — the game is over when the world has
reached a state he cannot hold.

That is expressed as **predicates over the tracked quantities**, never as a
completed route. Nothing is scripted, nothing has required steps, and any
combination of acts that reaches one of these states finishes the game:

| Ending | The world has reached |
|---|---|
| **Dead** | His health is gone. *(Needs the combat screen, §10)* |
| **Ruined** | The treasury is empty and the bank has no confidence left |
| **Deposed** | The army is hollow and faction tension is high enough for somebody to move |
| **Discredited** | Enough of what he did is public, and enough towns have turned |
| **Abandoned** | The escort is a bare handful and the place he stands has turned on him |

This is invariants 4 and 5 applied to the ending itself. An earlier version of this
section wrote the three routes as recipes with required steps, which is exactly the
"quest that can only start one way" invariant 5 calls a bug — the contradiction was
in the spec, not in the code.

#### The handprint rule (hard)

**Drift alone must never end the game.** The world moves on its own, and if a reign
could fall out of ambient motion the player would be a spectator at their own story.

So every tracked quantity carries a second figure beside it: **how much of where it
stands is the player's doing.** A deed writes both the quantity and the handprint; a
drift writes only the quantity. An ending requires *both* its threshold **and** a
minimum handprint on the quantities it reads.

> This is §8's "push the ambient, pull the attribution" turned around. The world
> never tells the player what they caused — but the game has to know, or it cannot
> tell a reign the player brought down from one that fell over on its own.

#### Taking the throne is a reading, not a sixth ending (2026-09-13)

The thesis at the top of this document says the ending is a reading of the state left
behind, *including the reading where the player is the one on the throne*. Nothing new
is needed to express it: `EndRules` already reads predicates over the quantities, the
handprint already says how much of each is the player's doing, and crown standing is
a faction standing that already exists. **Deposed** is the predicate; two figures
beside it say who fills the vacancy.

| State at the end | Reads as |
|---|---|
| Deposed · high handprint · **high crown standing** | **The player takes the throne.** The army is hollow, the court already calls them by its last rank (§11), and the one who hollowed it is the one the crown knows |
| Deposed · high handprint · low crown standing | The player made a vacancy, and somebody else filled it |
| Deposed · low handprint | It fell over. Already forbidden — an ending needs a handprint |

"High crown standing" is the standing that earns the crown's last rank (§11) — the
same number, read once, so the throne cannot be reached by a player the gate does not
know. No new predicate, no new quantity, no sixth row in `EndRules.endings()`: the
reading is taken *after* the predicate fires, from figures the journal's second page
(§15) already shows.

**And it must show what they do with it.** If the player can take the throne, the
ending shows one thing: the **hardship figures** (§8) in the towns they changed, the
morning after. Not a verdict — a reading, in the towns' own words (§15), of what the
kingdom became. A player who freed the Wide Acres and starved the Muster is shown the
Muster; one who fed the Cinderworks the forest is shown the wood.

**A loyal run keeps every ending.** High crown standing never removes the others
(invariant 7): a player loyal all game can still turn at the end — read the ledger
aloud, empty the vault. Rank opens the gate; it closes nothing.

> **What was rejected.** A sixth ending, `crowned` — a new predicate needs a new
> threshold and a new row on the journal's page, and it would make the throne a
> *goal* with a correct path rather than a reading of what was left. A stored "the
> player is the heir" flag — invariant 4; it is a progression flag by another name.
> Reading crown *rank* rather than crown *standing* — they are one number, rank being
> derived from standing (§11), and naming the standing keeps one source.

#### Routes are descriptions, not machinery

> Three at launch, each using a different verb. **They are ways of thinking about
> the game and names for what tends to work — they are not requirements, not
> checklists, and nothing in the code asks which one you are on.** A run that uses
> all three, or none of them recognisably, ends the same way: on a predicate.

**Route A — Force.** Reduce the escort, level, equip, fight through the door.
- Requires knowing: how he fights (from the Muster — Ryse, or Odile)
- Requires having: equipment and levels
- Requires being: nothing — this route accepts a monster
- How it can fail: arriving too early, escort intact

**Route B — Access.** Be admitted. Become someone the castle lets in — a supplier, a
lord's man, a hero the crown wants to be seen with.
- Requires knowing: who grants access, and what they want (Greyhold, the bank)
- Requires being: a reputation that survives scrutiny
- Requires being, in v2: **the crown's last rank** (§11) is the gate knowing your face — derived from crown standing, gating nothing, one of the three ways in
- How it can fail: a reputation that contradicts itself; someone recognises you

**Route C — Exposure.** The bloodless route. Assemble the evidence the pillars hold
and put it in front of him where it cannot be denied.

> **Each document answers one break in his argument** (settled 2026-09-12, §19 Q18).
> Before this the debts rebutted nothing and the tiered law — the break §5 calls the
> one that gives him away — had no document at all.
>
> | Where his argument breaks (§5) | What proves it | Where it is |
> |---|---|---|
> | He counts the aggregate, never the individual | The land grants, naming the razed villages — including the player's | The Wide Acres |
> | The tiered law gives him away | The record of how the law is actually administered | **Cairnwell** — the capital is where law is written |
> | The wealth went upward, and he knew | The Cinderworks ledger of what the works cost in lives | The Cinderworks |
> | The whole thing was borrowed | The debts, and the one creditor he is afraid of | The bank |
> | Your village is the counterexample | The signed orders, and the names of the men | The Muster |
>
> The tiered-law record moved to Cairnwell because Greyhold is a power base with no
> location on the map — and **Lord Aurel Greyhold moved with it** (Q40, 2026-09-12).
> Greyhold is deferred rather than cut; if it is ever built, the lord and the record
> both go back to it.

- Requires knowing: enough from at least four pillars
- Requires having: a venue and an audience that cannot be dismissed
- How it can fail: incomplete evidence; an audience the crown can buy
> TBD: what is that venue? A court, a market square, the creditor's house?

---

## 4. World & map 🟡

> Topology drafted by Claude from Yannick's constraints: start in the south-east,
> castle centre-north-west, sea to the south and west, mountains to the north and
> east, a region crossable in a couple of minutes on a straight line. Names are
> placeholders — change freely.

### Bounds and scale

One region, bounded on all four sides so the playable area needs no invisible walls:

- **South** — the open sea
- **West** — the open sea
- **East** — the Iron Spine, impassable mountains
- **North** — mountains, with the castle set against them

**Scale (settled):** the region is roughly **280 × 200 tiles** — a grid of **7 × 9
overworld screens at 40 × 22 tiles each** — walked at **6 tiles per second**.
The *screens* are a planning unit for laying the region out on paper, not an engine
concept: the camera scrolls smoothly and follows the player, so tiles-per-screen
never has to be a whole number (§13).

Two numbers follow from that, and only the second is a design target:

- **Brindle to Blackcairn, straight line: ~43 seconds.** Movement is **8-way**,
  and the two sit 255 tiles apart — Brindle in the south-east, Blackcairn
  centre-north-west — which at 6 tiles/sec is 42.5 seconds.
  The map's *own* diagonal, (0,0) to (279,199), is 343 tiles: that figure bounds
  the region but measures no route, because no settlement stands in a corner.
  A short crossing is *by design*, not a shortfall — the king is reachable from
  minute one, and a map that took a quarter of an hour to cross would be arguing
  with Pillar 1.
- **Actual travel along the King's Road: 45–90 seconds.** The road dog-legs south
  and west before it turns north, and real travel carries terrain, the river
  crossings and encounters. **This is the figure to tune**, and the only one worth
  timing.

> **The 4–6 minute figure was wrong, and wrong in an instructive way.** It was
> reasoned from the map's dimensions rather than from anyone walking it, and a
> minute of empty walking was already boring in play. Session length comes from
> encounters, stops and detours — from things being *in the way* — not from
> distance. A map tuned to fill an hour with travel is a map that makes travel the
> content. See §20.

> Consequence for Phase 0. The vertical slice has no terrain and no encounters, so
> the walk it measures is the bare straight line: expect roughly 40 seconds
> (255 tiles at 6 tiles/sec), and read that as the instrument reading correctly. What Phase 0 settles is whether 4
> tiles/sec *feels* right at 40 × 22 tiles a screen — the pace of the walk, not its
> duration. The 4–6 minute target is measured later, once the road has something on
> it.

### The road and the wild

The single most important thing about this map is that there are two ways to cross
it, and the choice is a *systemic* one:

- **The King's Road** runs from the Cinderworks in the south-east, north-west
  through Harrowgate and the Muster, to Cairnwell and the castle. It is fast, it is
  paved, and it is patrolled. Everything the player does on it is **seen**.
- **Everything else** — the Thornwood, the hill tracks, the river bank — is slower
  and is **unwatched**. *(It also held monsters until 2026-09-13; see "The wild is
  slow and unwatched" below.)*

Speed versus witnesses. That single trade-off connects the map directly to the
reputation and rumour systems, and it means the map itself makes the player choose
what kind of person they are being today.

### The map's thesis: the road and the forest (2026-09-12)

Every zone belongs to one side or the other, and **the map is the argument between
them**:

- **The road is the king's world** — industry, order, tax, patrols, being seen.
- **The forest is what he is destroying** — magic, the displaced, the poor, being
  unseen.

This was already true mechanically from Phase 2, and that order matters: it was a
systems decision before it was a thematic one, so the theme is something the player
*does* rather than something they are told. Every crossing is the argument in
miniature. Take the road and you move through his world on his terms and are counted;
take the forest and you are with what he is clearing, and nobody sees you at all.

| Zone | Side | |
|---|---|---|
| **Brindle** | the forest's | The ruins the road was built over, and where the fairies raised the player |
| **The Thornwood** | the forest's | Where magic still lives, and where the deserter hides |
| **The Kettle's ford** | the forest's | The crossing nobody watches. The bridge is the road's |
| **The Cinderworks** | the king's | Built on Brindle's own ground: the conversion, in one image |
| **Harrowgate** | the king's | The road's first town, the tiered law in daily practice |
| **The Wide Acres** | the king's, **contested** | Estates on razed villages, worked by the people who were razed |
| **The Muster** | the king's | The road's crossroads, and the force that does the clearing |
| **Saltmarch** | the king's, **barely** | Off the trunk road, which is exactly why nobody checks its books |
| **Cairnwell** | the king's | Where the law is written and the money is owed |
| **Blackcairn** | the king's | The end of the road, literally |
| **The Redcut** | the king's | Ore. Optional zone |

**What this costs, stated rather than discovered later.** The argument is lopsided:
**nine zones are the king's and two are the forest's**, and one of the two —
the Thornwood's depths — is on §4's optional list, cut first if behind. A map whose
thesis is an argument between two sides, where one side has two locations and might
have one, is not staging an argument; it is staging a rout. Phase 7 either gives the
forest enough presence to answer back or the thesis stays a caption. See §19.

> The two **contested** rows are the interesting ones and should stay contested. The
> Wide Acres is the king's order imposed on the forest's people — Pell works ground
> that was a village, for the man who owns it now. Saltmarch is the king's town that
> his own order has stopped reaching. Neither is a side; both are the border.

> **v2 (2026-09-13).** Four of the king's rows — the Cinderworks, the Wide Acres, the
> Muster and Cairnwell's bank — now carry a state the player can set (§8): crown-held,
> which is the side above, or free, which is the forest's. So the argument can be won
> ground by ground, and the lopsidedness stated above is the *starting* position rather
> than the fixed one. The Wide Acres and Saltmarch keep their band; the other three
> move only by the player's hand.

### Barriers that are knowledge, not walls

Consistent with Pillar 1: nothing is locked, some things are simply unknown.

| Barrier | The wall version | The knowledge version |
|---|---|---|
| **The Kettle** (the river) | One guarded bridge on the King's Road | A ford exists downstream, shallow only in dry weeks. Learning it exists is a fact; knowing the weather makes it usable |
| **The Redcut pass** | A rockfall blocks the quarry road | It can be cleared, or bypassed by a miners' path only miners know |
| **Blackcairn castle** | The gate, which turns away nobodies | Three ways in: the gate with papers, the river culvert, and a cliff path from the north mountains |

### Zone roster

| # | Zone | Where | Power base | Its job in the design |
|---|---|---|---|---|
| 1 | **Brindle** — the ruins | South-east, inland of the coast | — | Where the player wakes. Their village, burned. In sight of the furnaces built on it |
| 2 | **The Cinderworks** | South-east, on Brindle's ground | the Cinderworks | The thing that killed the player's family, running day and night. Holds the death ledger |
| 3 | **Harrowgate** | South-centre, on the road | Harrowgate | The first town. Market, gossip, the tiered law in daily practice |
| 4 | **The Wide Acres** | Centre-south | the Wide Acres | Consolidated estates. The land grants naming razed villages, Brindle among them |
| 5 | **The Muster** | Centre, on the crossroads | the Muster | The standing force. Muster rolls, pay fraud, the signed orders |
| 6 | **Saltmarch & Greyhold** | South-west, on the coast | Greyhold | Port town and the lord who administers the tiered law, and privately loathes it |
| 7 | **Cairnwell** | Centre-north-west | the bank | The capital. Money, debts, the creditor the king fears |
| 8 | **Blackcairn** | Centre-north-west, against the mountains | — | The castle. The king. Reachable from minute one |

**Optional zones** (cut first if behind): **The Redcut**, the iron quarry in the
eastern mountains — cutting the Cinderworks' ore supply; **the Thornwood depths**,
wild and unpatrolled, where the fairies' ground is.

### Two ground states, four places (2026-09-13)

The four places §3 names carry a state — **crown-held or free** (§8) — and the state
is on the ground before it is in any journal. §13 says how each is drawn; this is
what is *there*.

| Place | Crown-held | Free |
|---|---|---|
| **The Wide Acres** | The estate's fences, the granary row under its watch, convoys loading for the road, Vale's house lit | Fences down, the fields cut into smallholdings, the granary open and unwatched, the convoys gone from the road — and the Muster's queue longer |
| **The Cinderworks** | Four furnaces alight, smoke over Brindle, the cleared ground widening into the Thornwood — faster when it is fed the forest | Furnaces cold, or the works run by the men who work it; the smoke thin; the clearing stops where it stood |
| **The Muster** | Tents in rows, the pay tent with a queue and money in it, patrols leaving for the road | Half the tents down, the pay tent shut, the rolls gone, fewer men on the road and more in Harrowgate's crowd |
| **The bank at Cairnwell** | The counting house open, the tallest thing in Erileo, the crown's men at its door | The counting house shuttered, and the creditor's men at its door instead |

**The starting state is crown-held for all four**, and the ground at the start is the
crown-held column — which is what v1 built. The free column is new tile work, one
variant per place. Nothing is a third variant.

**The Thornwood belt is the Cinderworks' second face.** `Terrain.CLEARED` already
draws the works as a wound with a radius; in v2 that radius is what "feeding it the
forest" moves, and `held_ground` (§8) is the number under it. A player who strengthens
the works watches the belt widen toward the clearing they woke in. That is the one
belt of tile work the wood costs, and it is a Cinderworks consequence rather than a
zone of its own (§3).

**Every place has a voice at its gate** (§15): a sign or a speaker stating its status
in its own words — propaganda, a claim the player can doubt and later find false —
and a place strengthened for the crown boasts differently from one that was always
loyal.

### Blackcairn — one state, two readings (2026-09-13)

**Blackcairn cannot be taken and has one state.** It is the end of the road and the
place the king stands; it is not one of the four and never flips. What it carries
instead is two **derived** readings, both legible from anywhere in the region:

| Reading | Derived from | Shows as, on the ground | Shows as, in the towns |
|---|---|---|---|
| **Wealth** | Crown treasury, steel output, grain supply | Scaffolding and new stone on the walls; or shuttered works and unfinished walls | What people say about the king's building — the new tower, or the tower that stopped |
| **Instability** | How many places have flipped, **how recently** (inside §8's freeze window), and how far apart they are | Banners down, more guards on the wall, the gate shut in daylight | What people say about the castle — the gate, the guards, who has been seen leaving |

**Recency is what makes it political rather than statistical.** Four places flipping
in a week is a crisis; the same four over a season is policy. A flip counts toward
instability whichever path moved it (§8) — to the men on the wall a flip is a flip —
and the window it counts for is §8's freeze window and no other.

**Both readings need a second channel**, per §8's rule that a change the player cannot
perceive is identical to no change: the castle's face for a player standing at it, and
what people in the towns say about it for a player who is not. Neither reading is a
number on the HUD (§15).

> **On the word "capital".** §0 calls Cairnwell the capital and Blackcairn the castle,
> and this document keeps to that: the two readings are **Blackcairn's**. Where v2's
> working notes say "the capital's readings" they mean the castle.

### The opening (2026-09-12)

The player wakes in Brindle, and from the first screen can see the Cinderworks
smoking on their village's ground, a minute or two's walk away. No exposition is
needed: the crime and the industry it served are in the same frame.

**One fairy, once, and then never again.** She is there when the player wakes, because
she is the reason they woke. She is the only fairy in the game and the only time one
appears. That is the one miracle, spent in front of you.

**She does not leave until she has finished**, so a player who walks away without
listening loses nothing and is forced into nothing — Pillar 1 holds. She is gone when
the player knows her last word, which means the facts the player holds *are* the
state: there is no flag, and nothing to keep in step.

**Seven things only she can tell you, and nothing else:**

1. You died with the others.
2. I brought you back. It cost you your memory.
3. Men came with axes and fire. The wood is smaller every year.
4. We are dying.
5. **I knew you, before.**
6. I did not pick someone special. I picked someone who is owed.
7. Find your way in this world. And if you can, save us.

**Five is the one that does the most work.** She knew them. That makes her a source
for the player's own past and not only for hers — and §6's *"three independent
sources, none of whom loved them"* now has a fourth who did. It is deliberately the
only warm thing in the recovery of their history, and the only witness to their life
that is not a piece of paper.

**Seven is answerable.** The wood stops shrinking when the furnaces stop (§8), so
*"save us"* is a request the player can satisfy with the levers they already have —
and §15's journal shows what became of it, so it is a request they can satisfy and
*find out about*.

**She names no enemy, and that is now load-bearing (2026-09-13).** Checked against
the seven: *men came with axes*, never *the king*; *save us*, never *stop him*. Seven
is answerable from either side — put the furnaces out, or make the works efficient
enough to stop expanding — and §5's reworked opening depends on her staying exactly
this neutral. Any edit to the seven is checked against that as well as against the
list of what she must not say.

**What he must not say**, and this is the hard part of the decision: who the king is,
what he did to the villages, why he thinks he was right, the tiered law, the works,
the routes, where to go, or what to do. Not because they are secrets — **because they
are the game.**

> The paragraph above this one has said since the first draft that *no exposition is
> needed*. A fairy who explains the king is exposition, and it would spend §5's whole
> design in ninety seconds: the king's argument has to be **discovered, and believed,
> before it can be broken**, or Route C is exposing a pantomime villain. It would also
> undo the one thing keeping the player from being a chosen one. Being **owed** is not
> the same as being **briefed**. He tells you what was done *to you* and leaves what
> was done to everyone else where you have to go and find it.

**It is a conversation, not a cutscene.** Invariant 9 already has the player choosing
among options, and the game has a dialogue system, a fact base and an event log. The
fairy is an NPC who exists for one scene; what he tells you are facts in the fact base
like any other, and they are the player's opening hand. A cutscene would be new
machinery, unreplayable, and outside the log.

**He is outside the invariants, deliberately.** He performs nothing route-critical —
his four facts are in the player's hand from the first minute and §7 says nothing can
take a fact away. So he is not a link in invariant 7's reachability walk and needs no
redundancy under invariant 6. He is the prologue, not a performer.

**He must not be cute.** The register settled on 2026-09-12 is plain speech a ten year
old can read, with no metaphor and no styling, and it cost two rewrites to get. A
twinkling sprite talking in riddles would undo all of it in one scene, and invariant
10 means he must not read as a child either. He is a dying thing asking for help,
and he should sound like one.

The King's Road runs past Brindle toward Harrowgate. A player who follows it
north-west reaches the castle in minutes, not hours, and can attempt the king
immediately, exactly as intended — through ten guards, at 10 HP.

### Map sketch

```
            ^^^^^^^^^^  NORTHERN MOUNTAINS  ^^^^^^^^^^
        ~   ^^^  [BLACKCAIRN]  ^^^^                ^^^
        ~     \                                 [REDCUT]
        ~   [CAIRNWELL]         ) Kettle )         ^^^
   sea  ~        |                 )                ^^
        ~        |  bridge*      )      #############
        ~        +--- road ---[THE MUSTER]## THORNWOOD #
        ~       /                 )  ford*  ###########
        ~  [SALTMARCH]            )              ####
        ~   +GREYHOLD  [THE WIDE ACRES]  )
        ~        \           |            )   [CINDERWORKS]
        ~         +--- road -+--- road --------+   |
        ~                  [HARROWGATE]         [BRINDLE]*
        ~~~~~~~~~~~~~~  SOUTHERN SEA  ~~~~~~~~~~~~~~~~
```

`*` = the player's start, and the two knowledge-gated crossings.
`road` = the King's Road: fast, paved, patrolled, watched.

> This is topology, not layout. Exact tile placement, terrain painting, collision
> and transitions are production work for the agent, once this shape is approved.

### Resolved: the road's route (settled 2026-09-11)

**The prose wins over the sketch.** The King's Road runs Cinderworks → the bridge →
Harrowgate → the Wide Acres → **the Muster** → Cairnwell → Blackcairn, and
**Saltmarch hangs off the Muster junction on a spur**. Four reasons: the prose is
the only place the route is stated in words; the sketch disclaims itself two lines
above; §4's own roster calls the Muster "on the crossroads", which a dead-end spur
is not; and the road is the *watched* route, so putting the standing army
physically on it is what makes "everything you do here is seen" concrete.

**The road is a deliberate dog-leg, and that is load-bearing.** It bows west along
the south to Harrowgate, out to the farms, then back north-east to the Muster
before turning north-west — **354 tiles against a 251-tile direct line, a ratio of
1.41**. Without that bow the wild costs time and blood and saves no distance, which
makes it strictly worse forever, witnesses or not. Any future change to zone
placement must keep this ratio between 1.30 and 1.50; there is a test.

**The road passes beside Harrowgate's gate, not through it.** "Through Harrowgate"
is true at map scale, but a trunk crossing the portal footprint means nobody can
travel past the town without being pulled inside it, and there is no far-side exit
to come back out of. A gate is a doorway off the road.

### Towns are on the map; transitions are for interiors (settled 2026-09-11)

**A transition means a change of scale or of rules — never a change of place.**

Countryside into a town is the same scale under the same rules, so towns are laid
out on the overworld at the size they actually are and you simply walk in.
Outside into inside is a real change of scale — a house three tiles wide outside
is twelve across inside, and the two cannot share a grid — so buildings, dungeons
and the castle keep are separate zones. §4's three ways into Blackcairn are three
entrances to one interior, which is exactly what a transition is for.

| Place | Footprint | Why |
|---|---|---|
| Harrowgate | 40 × 28 | One of the two you spend time in (§6) |
| Cairnwell | 40 × 28 | The capital, and the bank is in it |
| Saltmarch | 26 × 18 | A port, passed through |
| The Cinderworks, the Wide Acres | 24 × 16 | Visited for one thing each |
| Blackcairn's courtyard | 24 × 18 | The keep's inside is a zone, later |
| The Muster | 20 × 14 | A camp, not a town |
| Brindle | 15 × 11 | Small, and meant to feel it |

Towns keep the ground they were built on and get **streets** through it — a main
street each way and a back lane either side. Paving the whole footprint turns a
village into a warehouse yard, which is what the first attempt looked like.

**What this replaced, and why it had to go.** Harrowgate was a 40 × 28 room entered
through a 5 × 5 rectangle on the road — the town was **45 times bigger inside than
out**, and the seam produced four separate bugs in two sittings: the King's Road
ran through the portal footprint so travelling the road pulled you into the town;
the exit put you on the wrong side of the gate so leaving bounced you back in;
portals landed on impassable tiles; the footprint clipped the next road leg. All
four were bugs in the *doorway*, not in the town. The mechanism survives, tested,
for the interiors that genuinely need it.

### Terrain speeds (settled)

| Ground | × | tiles/sec |
|---|---:|---:|
| Road, town streets, camp, castle | 1.00 | 6.0 |
| Ruins | 0.90 | 5.4 |
| Farmland | 0.80 | 4.8 |
| Open country — heath, hill tracks | **0.65** | 3.9 |
| Coast sand | 0.75 | 4.5 |
| Thornwood | 0.55 | 3.3 |
| The ford (wading) | 0.50 | 3.0 |
| Marsh | 0.45 | 2.7 |

The road is the **1.00 reference rather than a bonus**: 6 tiles/sec is the speed
that was tuned and approved, so every other surface is a penalty. Were the wild
1.00 and the road faster, the approved feel would become the slow case.

> **Open country was 0.80 and is 0.65** (Yannick, 2026-09-13, measured). The table was
> reasoned about while speeds were off and never measured against the claim it exists
> for. Measured with the beasts gone, the least-watched line from Brindle to the castle
> is 208 tiles of open ground and 29 of wood, and at 0.80 the road beat a plain walker
> by 2.4 s and *lost* to an attuned one. At 0.65 the road wins by 12 s and 9 s — a fifth
> of the walk. Farmland keeps 0.80: fields have paths, and the Wide Acres is a place you
> walk around in. Cleared ground and the clearing are not in the table and walk at 1.00
> until it matters.

> **Terrain speeds are currently off** (2026-09-11). Everything walkable moves at
> the road's 6 tiles/sec: a forest should be dangerous, not tiring, and trudging
> was making the interesting route the annoying one. The table above is kept rather
> than deleted — `Region.TERRAIN_SLOWS_YOU` turns it back on in one word, with the
> reasoned numbers intact.
>
> **What this does to §4's trade-off.** "Speed versus witnesses" loses its speed
> half — and what replaces it is sharper. The King's Road is a deliberate dog-leg,
> 351 tiles against a 250-tile wild line, so the road now costs **~17 seconds of
> detour and buys safety**, while cutting through the Thornwood saves those seconds
> and draws blood. **Distance against danger**, and later against being seen. The
> dog-leg stops being flavour and becomes the entire price of the safe route, which
> is why its 1.30–1.50 ratio is guarded by a test.

> **Switched back on for v2 (2026-09-13).** The beasts are out (below), so "dangerous,
> not tiring" has no first half left, and tiring is the price the table was reasoned
> for. `Region.TERRAIN_SLOWS_YOU` is the one word. "Distance against danger" goes back
> to being what this section said first: **speed against witnesses**.
> One exception, by trait: an attuned character is not slowed by the wood, or not as
> much (§11, Q50).

### The wild is slow and unwatched (2026-09-13; was *dangerous*, settled 2026-09-11)

**Monsters are out of the whole map** — not only the forests. The bear, the spider
and the bat go, and with them `BeastRules`, `core/beast.gd`, `core/wildlife.gd`,
`WildlifeSystem`, their tests, and every beast entry in the region, the world state,
the art table, the text files and the journeys. §21 has the row.

**What it costs, and why the choice survives it.** The terrain table called the wild
*slow, unwatched, dangerous*; it is now **slow and unwatched**. The road keeps its
teeth because it is *fast and watched* — the choice moves from "will I survive it" to
"will I be seen", which was always the half of the trade the reputation system was
built for (§8's first consequence, and the travellers who made the wild a real choice
on 2026-09-11). **Time is now the only price of the wild**, so two things that were
switched off or optional become load-bearing:

- **Terrain speeds come back on.** They were turned off on 2026-09-11 because *"a
  forest should be dangerous, not tiring"*. With danger gone, tiring is the price, and
  the tuned table above is the one that was reasoned about: a wood at 0.55 is walked
  at 3.3 tiles/sec against a road at 6. The road is faster and seen; the wood is slower
  and not. `Region.TERRAIN_SLOWS_YOU` turns it back on in one word, which is why the
  table was kept.
- **MAP_SPEC's road ratio matters more, not less.** The road is 1.41 times the wild
  line. With the wood slowed the road should still come out faster — that is the whole
  of its case now, since a road that is neither faster nor unwatched is a road nobody
  takes — and the 1.30–1.50 band the test guards is guarding the choice itself.

**Measured, 2026-09-13**, with the speeds on and the wood empty
(`tools/measure_routes.gd`; two `SLOW` tests in `test_journeys.gd` hold the same three
relationships). Brindle to the castle gate, stopping short of the man at the end:

| Route | Distance | Time | Cost |
|---|---:|---:|---|
| The King's Road | 342 tiles | **57 s** | seen the whole way |
| The wild — the least-watched line, over the ford | 269 tiles | **69 s** | 17 tiles of road, crossed where it must |
| The wild, attuned (§11) | 268 tiles | **66 s** | the same, and the wood slows you less |

Twelve seconds slower and unseen; nine for the forest build. That is the trade the map
is for. The v1 figures — 57 s against 43 s and 8 of 10 health — measured a different
game and are in §20.

**The instrument was wrong twice, and both are worth keeping.** The "wild line" had
always been `Navigation`'s shortest *walkable* path, and on this map that path is
**42% King's Road** — 118 of 280 tiles, plus the Muster's camp and a town street — so
v1 never measured the wild at all, and the first v2 measurement had the road winning by
2 s against a route that was mostly road. Forbidding the road outright is not the
repair: **no walk from Brindle reaches Blackcairn without crossing the King's Road**,
because the road runs from the south-east coast to the castle against the mountains and
seals the east. So the wild line is the *least-watched* path — a road tile costs ten
wild tiles (`Navigation.WATCHED_COST`) — which crosses the road where it must, never
runs along it, and takes the ford because the bridge is the road's. Crossing a road is
a moment of being seen; walking one is a route.

> **What v1 had, kept for the reasoning.** Three beasts, all slower than the player,
> spawned on a ring just past sight and biased toward where you were going, keeping a
> three-tile margin from the road, with territory so the wood did not empty while you
> waited. Each of those was learned the hard way and each stays true of anything that
> ever hunts in the wood again: danger has to be ahead, the road has to be safe by
> margin and not by tile, and waiting must never make the dangerous route safe. The
> beasts went because a wild whose cost is blood asks "will I survive" — a question the
> combat screen (§10) answers, not the map — and the map's question is "will I be
> seen". Recorded in §20 and §21.

### The Kettle, the bridge and the ford

The river runs from the northern mountains to the southern sea down the east of the
map, dividing the eastern strip — Brindle, the Cinderworks, the near Thornwood —
from everything else. **It is a real barrier:** dam both crossings and Blackcairn
becomes unreachable from Brindle, which is a test rather than a claim. And the measured wild line crosses at the ford (above), as §4 always said it would.

Both crossings are **bands, not tiles** (§19 Q28b), and both are sized to span the
river's *slant* rather than its width — a crossing measured against the width alone
leaves water on the far side and the road stops in the river. The first one did.

---

## 5. Story & fiction

**Premise** — the player **died** when Brindle burned, and was raised months later in
its ruins, with no possessions and half their memory gone. Their village is ash. They
remember the king's men, and that the people they loved were killed. They do not yet
remember much else, including who they were — or that on every roll the kingdom
keeps, they are still dead.

**Tone** — TBD (three adjectives, and one work of fiction that has it).

**Themes** — what industrialisation costs and who pays it; law written to favour the
people who wrote it; whether revenge and justice are the same act; what a person is
without their memory.

### Who raised the player, and what it cost (2026-09-12)

The premise had a hole in it. The village burned, the family died, and the player
walked out of it with half a memory and no account of how. This is the account.

**The fairies of the Thornwood raised them.** Magic lives in the forest and nowhere
else, and the raising is the only one it has performed in living memory.

> **One of them appears, once, in the opening, and never again** (2026-09-12). **She**
> tells the player seven things and is forbidden the rest. See §4's *The opening* for
> the seven, for what she may not say, and for why that restriction is the whole
> design. Built 2026-09-12: `core/rules/opening_rules.gd`, and a test asserts her
> silence word by word in both languages rather than trusting it.

**Their motive was not kindness.** The king is clearing the forest for stone, coal
and land, and the fairies are what lives in it. He is killing them — steadily, and
mostly as a side effect — and they cannot stop him themselves. So they raised the
one person in the region with cause to.

> **Chosen for being owed, not for being special.** This matters more than it looks.
> A player raised because they are the prophesied someone is a player on rails, and
> Pillar 1 spends its whole budget on the opposite. A player raised because the
> fairies needed somebody with a grievance and a corpse to hand is a player who can
> still walk to Blackcairn and lose in three hits. **The fairies made a bet. Nothing
> in the game makes it pay off.**

**The memory is the price, not bad luck.** Coming back cost what the player knew
about themselves. This turns the game's oldest design note — *recovering memory and
acquiring world knowledge are the same system* — from a convenience into the story:
the thing you are trying to get back is the thing you paid, and you buy it back from
the records of the people who erased you.

**And the ending can give it back** (2026-09-12) — how much of it depending on which
ending. The fairies did not raise the player to punish a man; they raised them to
stop the clearing. So the memory returns to the degree the bet paid off, and the five
predicates stop being five ways to win:

> Killing Arthur removes the man and leaves the forest being cleared by whoever
> takes his place. It gives back least. Breaking him, deposing him or turning the
> country against him changes the policy rather than the officeholder, and gives back
> most. **The ending that satisfies the player is not the same as the ending that
> satisfies the things that raised them**, and the player finds that out by which
> parts of themselves come back.

The mapping from each predicate to how much returns is Phase 7's work, not written
here. What is decided is the principle.

**The player is legally dead.** No papers, no record, no name on any roll. This is
the real reason they are nobody, and it is load-bearing in three places:

- **Hesper's problem becomes existential rather than bureaucratic.** A supply pass
  needs a name, a trade and her mark (§6, Anselm). The player has none of the first
  and no way to acquire one honestly. She is not being difficult; there is nothing
  for her to write.
- **The tiered law cannot classify them.** Bell's three columns are *what you own,
  where you come from, what you owe* — and the third is worked out from the first
  two. A dead man has no row. Whether that is a hole to walk through or a hole to
  fall into is not yet decided (§19).
- **It is the same erasure, twice.** The land grants removed Brindle from the map and
  the rolls removed the player from the list. The paperwork of their erasure is
  literally the thing they read to find out who they were.

**The church is against magic** (2026-09-12). It is not the king's ally — it is a
third power that happens to agree with him about exactly one thing, and disagrees
about the rest, which is why its accounts can still break him.

Three things follow, and they are why this answer is worth more than its opposite:

- **Route C acquires a cost it did not have.** Its climax is the player standing in
  that church, before that congregation, reading the king's own records aloud
  (Q3). The player is a thing the congregation would condemn. They are using a
  pulpit that would turn on them if it knew what they are, and *the fairies' bet
  works only because nobody in the room can see it.*
- **The church's complicity gets worse in the right way.** §6 has the church
  financing the furnaces. So it paid for the clearing that is killing the thing it
  preaches against, and got what it wanted by means it would not sanction. That is a
  second person in this game holding a coherent argument and an indefensible ledger,
  which is the shape the king already has.
- **It keeps the fairies from becoming allies.** Nobody in the built world is on
  their side. The player is not joining a faction; they are the only overlap between
  two things that would each disown them.

**Magic is the one miracle.** It is rare because the king has been killing it, not
because it was ever common — which is a better reason than the systemic one §11
gives, and replaces it. One raising, in the forest, by the things that live there.
Nothing else in the game does anything a reasonable person would call magic.

### The opening points two ways (2026-09-13)

v1's opening pointed one way: the king destroyed your village, so go and kill him. If
serving the crown is a real play — and the thesis at the top of this document says it
is — then the first ninety seconds must not close that door. **Nothing that happened
is softened.** What changes is what *kind* of thing it was.

**Policy, not malice.** Brindle was cleared because the Cinderworks needed the ground,
not because the king hated it. That is worse in some ways — nobody even decided to
hurt you — and it is what leaves the door open: people in this game already serve a
system that did this, and none of them is a monster. §3's *why the player wants him
dead* is retitled accordingly; the grievance is intact, the target is a policy and the
man who signed it, and both can be answered by breaking him or by changing what the
kingdom does with its ground.

**The fairy wants something; she does not name an enemy.** Checked against §4's
seven: she says *men came with axes and fire*, never *the king*, and her last word is
*save us*, which is a goal rather than a target. The wood stops shrinking when the
furnaces stop — **or when the works are made efficient enough to stop expanding**.
Both plays answer her. A player who strengthens the Cinderworks and settles its wage
so that it stops eating the Thornwood has done what she asked by a road she would
never have taken, and the game must let that count: `held_ground` (§8) is the number,
and it does not ask who moved it.

**One credible pro-works voice in the first hour, who is not a fool.** §5's king's
argument, below, exists in full and is audible only at Blackcairn. In v2 it is audible
at the Cinderworks, a minute's walk from where the player wakes, in **Halgrave's**
mouth: a man who keeps the death ledger because he thinks the record matters, who
answers in figures, and who will tell anybody what the works has paid for — the road,
the bread, the years added to a life — before anybody has read the ledger. He is ★,
he is the open source of the fact that damns Arthur, and he is not ashamed of it,
which is exactly the shape that makes him credible: the argument and the indefensible
ledger in one man, as §5 already gives to the king and to the church. He is not
written as right. He is written as somebody a reasonable person could follow, in the
first hour, before the case against him has been assembled.

**The test.** After the tutorial — creation, the fairy, the walk out of the clearing —
a player who wants to *serve* the crown can say what their first step would be,
**without the game having offered it**: walk to the works and offer their hands; walk
to Harrowgate and let Tovin write them down. If a playtester who wants that play
cannot name a first step, the opening still points one way, whatever this section
says.

> **What was rejected.** Softening the burning — a cleared village is the premise and
> the counterexample the king will name to your face (below); take it away and there
> is nothing to hold him to account for. A fairy who names the king — she would be
> exposition, which §4 has forbidden since the first draft, and she would be picking a
> side in a game whose thesis is that both are plays. A crown voice in the clearing —
> the miracle is one, and the crown's voice belongs in the crown's world, which is the
> works, one frame away. Making Halgrave sympathetic by making him doubt — a man who
> half-believes is a fool with a ledger; the version that costs the player something
> is the one who believes completely and can show you the figures.

### The king's argument 🟡

He is not a cruel man in his own account, and the spec must be able to state his
reasoning in a paragraph a reasonable person could follow. It is this:

*Poverty is the enemy.* Subsistence farming is not a way of life, it is a way of
dying — short lives, buried children, a bad harvest away from famine, and no way out
for anyone born into it. The romance of the peaceful village is a story told by
people who have never had to live one. Industry is the only mechanism in history
that has ever lifted a population out of that, and industry needs stone, steel,
coal, and land. The villages that refused to move were not choosing peace; they were
choosing poverty, for their children and their children's children. Some of them had
to be moved by force, and the king has never pretended otherwise. He signed those
orders himself and can produce them on request.

The forest is the same argument continued. It is standing fuel, standing stone and
standing land, and what lives in it is in the way exactly as the villages were. He
does not think of himself as at war with magic; he thinks of himself as clearing
ground, and the fact that something dies when he clears it is a cost he has already
accepted once and sees no reason to reconsider.

> **Keep him reasonable.** §5's protected note is that Route C only works if his
> argument is real, and *"he hunts fairies"* is the fastest way to hand the player a
> pantomime villain. He is not hunting them. He is clearing land and they are on it,
> which is precisely what he did to Brindle — and the player, who *is* Brindle, is
> the one person who can see that the two are the same act.

**Where the argument breaks**, and where the player's case lives:

- He counts the aggregate and never the individual. The kingdom is richer. The
  people who were burned out of it are not part of the calculation, and he has never
  found a way to make them part of it.
- The tiered law gives him away. If the goal were to end poverty, the law would not
  sort people by wealth and origin — you don't lift people up by writing down that
  they are worth less. He wanted productivity, and told himself it was compassion.
- The wealth went upward. The works made the kingdom richer and the workers poor in
  a new way; the Cinderworks ledger shows he knew.
- The player's village is the counterexample and he will say so out loud: *they were
  happy, and poor, and dead at forty.* The player has to decide whether that's an
  answer.
- **He calls it clearing, and it is killing** (added 2026-09-12). He accepted that
  cost once, for the villages, and produced an argument for it. He has never made the
  argument a second time for the forest, because he has never counted what is in it
  as the kind of thing that can be counted. That is the same blind spot as the first
  break — he counts aggregates, never individuals — arriving somewhere he cannot
  dismiss as sentiment about peasants.
- **The whole thing was borrowed** (added 2026-09-12). He says industry is the only
  mechanism that has ever lifted a population out of poverty — and he mortgaged the
  kingdom to one creditor to build it. His certainty was a bet, and other people's
  villages were the stake. It is the break the bank's records answer, and it makes
  him a gambler rather than a monster, which is worse for him.

> This matters because Route C only works if his argument is real. Exposing a
> pantomime villain is not a climax. Exposing a man who believed he was right, using
> his own records, is.

**Recent history** — the five events everyone in the region remembers: TBD.

**What the player character knows at the start:** the destruction of their village
and the death of their family. Nothing else is reliable.

**Who the player character is** — largely the player's, expressed through traits at
creation, dialogue, and what they do. Their forgotten past is authored and recovered
as facts during play.
> Design note worth protecting: recovering memory and acquiring world knowledge are
> the same system. A recovered memory is a fact in the fact base like any other.

**Magic** — lives in the forest, and is rare **because the king has been killing it**
(2026-09-12). The earlier reason — one trait among six, most builds won't take it —
was a systemic dodge for a question the fiction should answer, and the fiction now
answers it. The systemic version still holds underneath and is still worth having;
it is no longer the *reason*.

> This leaves a question §11 has to settle: whether the Attunement trait's magic and
> the miracle that raised the player are the same substance. See §19.

### Endings

The game does not end. The king is resolved — killed, spared, publicly broken,
walked away from, or **succeeded** (§3, 2026-09-13) — and play continues in a
changed region.

**What concretely changes afterwards:**
- The world tick values shift permanently: prices, patrol density, faction tension.
- Who is in charge changes, per the resolution taken. A killed king leaves a vacuum
  someone fills; a broken king leaves an administration that has to answer for
  itself.
- **Or the player is in charge** (2026-09-13): deposed at the crown's last rank is
  §3's throne reading, and what changes first is what the ending shows — the
  hardship (§8) in the towns they changed, the morning after.
- All existing side quests remain playable. No content is closed off by the ending.
- NPC dialogue acknowledges the new state.

> This is the cheap version, deliberately. No new zones, no new quest lines, no
> epilogue content. See §21 for what was cut.

---

## 6. Characters

> 25 named NPCs across 8 zones, approved 2026-09-11. Names remain placeholders.
> ★ = route-critical, and every ★ fact has at least one other source.

**Named NPCs are people with a sheet**: a voice, wants, facts, and social edges.
> **Generic types now carry dialogue** (2026-09-11). A stranger has a trade, a line
> set shared by everyone of that trade, and no name — ids are `trade@n`, and they
> are outside the twenty-five. Placed so far: a trader in Cairnwell, a guard at the
> Kettle bridge. They exist so the world can react to the player through somebody
> who has never met them, and so that "he needs something to say" cannot turn a
> prop into a named character by degrees.

Generic guards and strangers are *types*, budgeted separately (§17) and reused across
the region. Monsters and animals were cut from the whole map on 2026-09-13 (§4, §21).

**Townsfolk are scenery, and are not cast.** The figures standing about in a town
have no names, no sheets, no dialogue and no facts, and they are **not part of the
25**. They exist to be counted: Harrowgate's crowd is drawn from the army strength
the Muster has lost, so emptying the camp visibly fills the town. That is the
ambient register doing the work a number cannot — the extra mouths explain the
bread price by being *there*, rather than by anyone mentioning them.

If one of them ever needs a name, it stops being scenery and joins the roster with
a sheet like everybody else. Do not let one acquire dialogue by degrees.

### Template — copy per character

**[Name] — [role], [zone]**
- **One line:**
- **Wants / Fears:**
- **Occupation** (drives combat loadout, §10):
- **Knows:** (facts, and under what conditions they part with them)
- **Leverage:** money / threat / affection / shared enemy / debt
- **Part in a route:**
- **Redundancy** — who else supplies their facts if killed:
- **Social edges** — family, employer, debts, rivalries (this is the graph):
- **Voice** — three lines of them speaking:

### Roster

**Brindle — the ruins**

| Name | Role | Holds |
|---|---|---|
| **Wren** | A scavenger picking the ruins. Not from Brindle; she arrived after | **Where nobody is looking** — the unwatched stall in the Wide Acres. Still the first practical fact in the game, and now one that needs no NPC routine to be true (Q11, 2026-09-11) |

**The Cinderworks — stone & steel**

| Name | Role | Holds |
|---|---|---|
| ★ **Foreman Halgrave** | Runs the works. Believes in them, completely | The death ledger. He keeps it because the crown requires it, and because he thinks the record matters. He is not hiding it — he is *proud* of the accounting |
| **Sena** | Furnace worker, lost a hand, organising the others | Copied pages of the ledger. Second source |
| **Doctor Ivo Marsh** | The works' physician; signs the certificates | The true count, including the ones that never reached the ledger. Third source |

**Harrowgate — the town, and the first one**

| Name | Role | Holds |
|---|---|---|
| **Maddox** | Innkeeper. Knows everyone, believes nothing | Gossip hub — the cheapest entry point to almost any thread |
| **Tovin the Reeve** | Administers the tiered law locally, apologetically | How the law is applied in practice, and to whom |
| **Bell** | Apprentice scribe; copies the law for the town | Has the wealth tiers memorised. Tier 0 in a fight |
| **Ossa** | Herbalist. Treats everyone, including deserters | Where Kell is hiding |
| **Garrick** | Caravan master, moves between zones | The ford. Also carries rumour physically across the map |

> **Who tells the player about the pay fraud (approved 2026-09-11).**
> §3 lists "expose the pay fraud" as one of four ways to weaken the Muster and
> §6 gives the fraud to Odile, but no Harrowgate NPC was specified as knowing
> about it, so Phase 1 had to assign it. Nobody new was invented; two people
> already here fit the text:
>
> - **Ossa** (primary) — she already "treats everyone, including deserters", and
>   men desert because they are not being paid. She hears why from the people it
>   happened to.
> - **Garrick** (second source) — he already "moves between zones"; a caravan
>   master who supplied the camp would notice the rolls outrunning the mouths.
>
> Two sources, so §7's redundancy rule holds: killing either leaves the fact in
> the world.

| Name | Role | Holds |
|---|---|---|
| ★ **Estate Lord Cadan Vale** | Holds the land grants | The grants naming razed villages, Brindle among them |
| **Nessa Vale** | His steward and daughter; keeps the actual paperwork | The same grants. Second source, and easier to reach |
| **Old Pell** | Tenant farmer. Worked Brindle's soil before the burning and after | That this ground was Brindle. He knew the player's family. He does not recognise the player |

**The Muster — the army**

| Name | Role | Holds |
|---|---|---|
| ★ **Commander Ryse** | Led the clearances. Sleeps fine | The signed orders, and the names of the men who burned Brindle. **How the king fights** — Ryse drilled against him for years |
| **Quartermaster Odile** | Running the pay fraud | The muster rolls, and her own crime — leverage. **How the king fights**, second source: she kitted the guard that drilled against him |
| **Kell** | A deserter hiding in the Thornwood. He was at Brindle that night | The orders, from memory. And what actually happened. The closest thing to a witness the player will ever find |

**Saltmarch & Greyhold — the sub-castle**

| Name | Role | Holds |
|---|---|---|
| ★ **Lord Aurel Greyhold** | Administers the tiered law. Privately believes it indefensible | How it is enforced, and his own disgust — the softest ★ to turn |
| **Harbourmaster Til** | Smuggler by preference | What leaves the region, and by whose order |
| **Mira Sand** | Advocate for the poor under the tiered law | Documented effects, case by case. Evidence with faces on it |

**Cairnwell — the bank, and the capital**

| Name | Role | Holds |
|---|---|---|
| ★ **Corvin Ash** | Banker. Holds the crown's debts | That the industrial project is leveraged, and to whom |
| **Archivist Peyre** | The crown's record keeper | Second source for the debts *and* the land grants |
| ★ **Hesper** | Court steward. Controls who gets papers into Blackcairn | The key to Route B. **Deliberately the only source** — see below |
| **Brother Anselm** | Her secretary | The way in to her, and a second source on the church's ledgers |

**Blackcairn — the castle**

| Name | Role | Holds |
|---|---|---|
| **The King** | TBD name | His argument (§5), and his records |
| **Captain of the Guard** | TBD name | The escort. Reduced as pillars fall |

### Hesper is a single point of failure on purpose (decided 2026-09-11)

Every other ★ has a second source. Hesper does not, and that is a decision rather
than an oversight.

Invariant 7 says **at least one** route survives any set of deaths — not every
route. Kill Hesper and Access closes. Force always remains, because fighting through
a door needs nobody's permission, and so does Exposure, because reading a document
out loud needs nobody's permission either. That is the rule working, not failing.

> **Updated 2026-09-12.** This used to read *"exactly as killing Mother Crowe closes
> Exposure"*, and that is no longer true in either direction: Crowe is cut, and Route
> C as built has no performer to kill. Hesper is now the **only** route a death can
> close, which makes her single point of failure more deliberate rather than less —
> it is the one door in the game that can be shut for good, and the player shuts it
> themselves.

It also earns its keep dramatically: the player who murders their way toward the
castle finds the polite door has quietly shut behind them, and nobody announces
it. A world in which every route has a spare is a world where nothing you do to it
matters.

> The redundancy rule still applies to **facts**: what Hesper knows is not lost
> with her, only her willingness to act on it. What dies with Hesper is a
> *performer*, not a piece of knowledge.

### The shape of Route C (rewritten 2026-09-12)

**It has no performer, and that is the finding rather than the design.** Route C is
`DEED_MAKE_PUBLIC` — reading a document aloud where people can hear it — and the
built version has no gate, no convener and nobody to persuade. It needs two things
the world already provides: **evidence**, which lies in places and cannot be taken
from you (§7), and **an audience**, which is anywhere there are people.

So Route C cannot be closed by killing anyone. That is worth stating plainly because
it changes invariant 7's shape: **Exposure and Force both survive any set of deaths,
and Access is the only route a death can shut.**

**The church is the best room, not a door.** Largest audience, and the one the crown
cannot buy. Nothing gates it — the player walks in and reads. What the church buys
is **cost rather than permission**: it is against magic (Q47), the player was raised
by it (§5), and they are using a pulpit that would condemn them if it knew. The
fairies' bet works only because nobody in that room can see what is standing in it.

**Corvin Ash holds the break, not the venue.** The debt is his, in `bank:debts` and in
Peyre's dialogue: the king mortgaged the kingdom to one creditor to build the thing
he says lifted it out of poverty. That is §5's fifth break, and it is the strongest
thing to read aloud.

**A story spreads about as far as the next town** (§7), so Route C is a *tour* rather
than a scene, and travellers on the King's Road are what carries it. Reading the
ledger in Harrowgate reaches Harrowgate.

> **What was lost, recorded honestly.** The cut version had Mother Crowe as an
> accomplice who had to be either absolved or coerced into convening the reckoning —
> a real choice about *how you get the room*, with a different enemy at the end of
> each. Route C is dramatically poorer without it. It went because the performer it
> needed was never built and the deed that replaced it needs nobody, and inventing a
> convener now would be adding a gate to a route whose whole strength is that it has
> none. It returns if the church ever gets a leader. See §21.

### How the player recovers their own past

With no survivors from Brindle, the player's history is reconstructed almost entirely
from the records of the people who erased it. Three independent sources, none of whom
loved them:

1. **Old Pell** — worked the soil, knew the family, does not recognise the face
2. **Kell** — was there that night, on the wrong side
3. **The land grants** — Brindle, named on paper, with a date and a signature

**And a fourth, who did** (2026-09-12). The fairy knew them before the fire and says
so — *"I knew you, before"* — in the first minute of the game. She is the only
witness to their life that is not a document, and she is gone by the second minute.
The note below said *none of whom loved them*, and it is better for having exactly
one exception that walks away immediately: the warmth is real, it is offered once, and
it cannot be gone back to for more.

> This is the thematic centre of the game and should be protected: you find out who
> you were by reading the paperwork of your own erasure.

---

## 7. Knowledge & information

**What counts as a fact:** anything the world knows and the player might not — a
secret, a relationship, a routine, a location, a document, and the player's own
recovered memories.

**How facts are acquired:** overheard, told, bought, extorted, read, witnessed,
recovered as memory.

### Documents: knowledge and proof are different things (2026-09-12)

A document is **both**, and the two halves do different work.

> **Reading** it puts the fact in your head: you can talk about it, ask about it,
> and it unlocks what knowing unlocks.
> **Holding** it is what lets you *prove* it. Your word has never been evidence.

That is the distinction the game already had between knowing the pay fraud and
being able to say it, one level up. §3's `discredited` ending counts what the
kingdom has been *shown*, not what the player happens to know.

**Documents lie in places, not in people.** A paper does not die with whoever owned
it. Kill Hesper and her letters are still in her house — you have lost the person
who would have told you where to look, or let you in, not the letters.

> This is what makes **invariant 7 structural rather than hopeful**: violence can
> never close Route C, only make it harder. It is the same guarantee the power bases
> gave — *a place cannot be murdered* — and a test asserts no NPC's dialogue ever
> hands one over, because a document that arrives through a person is a document a
> death can destroy.

**Nothing takes one off you.** Not stolen, not burned, not confiscated. Evidence that
can be lost is a route that can be closed, and §7 does not allow that. The list is
append-only and a test tries every way the world has of hurting you before checking
it is still there.

**Route C needs the road.** A story spreads about as far as the next town on its own,
so reading the ledger aloud in Harrowgate reaches Harrowgate. The kingdom learns what
the king did because people walking the King's Road carry it — which makes the
bloodless route a *tour*, and makes travellers matter to a player who never steals
anything.

> **Not built, and why:** copies. Bell is a copyist and the obvious use is "give the
> original away, keep the copy" — but the reason for a copy was to hedge against
> losing the original, and nothing can take one. It returns the day handing a
> document to somebody becomes an act.

**Redundancy rule (hard).** Redundancy applies to **facts** and to
**route-critical performers** — the people who perform an act a route needs, such
as Hesper granting papers. **She is now the only one** (2026-09-12): Route C's
convener was cut with Mother Crowe, and reading a document aloud needs nobody's
permission. It applies
**only to the degree that one route survives**, not to the degree that every route
does. A fact or a performer with a single source is acceptable when the route it
serves is not the last one standing.

**Reachability test (hard).** After any set of deaths, **at least one ending
remains reachable**. Losing a way in to a death is intended and is the design
working: kill Hesper and the polite door shuts for good, and the player can still
empty his treasury or read his own ledgers out in the street. What must never happen is every ending closing.

> **Restated 2026-09-11.** This used to ask whether each of three authored routes
> was still open, which only made sense while the routes were machinery. Now the
> ending is a predicate over world state, so the question is whether the world can
> still be *moved* to satisfy any of them — which is a smaller test and a truer one.

The check is a **living-performer-chain walk per route**, not an enumeration of kill
sets. For each of the three routes, walk its required facts and its required
performers and ask whether every link still has at least one living or otherwise
obtainable source; if any route answers yes for every link, the assertion holds.
That is O(routes × chain length) and runs in milliseconds. The exhaustive sweep it
replaces — 2²⁵ = 33,554,432 kill sets over the 25-name roster — does not, and
measures the wrong thing anyway: because killing grants XP and loot, Force gets
*more* open as the kill set grows, so the interesting cases are never the extremes.

Total permissiveness is not a wish; it is a test that fails the build.

**How the player sees what they know:** TBD — journal, board, memory map?

**Can facts be wrong?** TBD — rumours, lies, deliberate misinformation.

**Fact list:**

| Fact | Held by | Second source | How to get it | Unlocks |
|---|---|---|---|---|
| | | | | |

---

## 8. Reputation, factions & world reaction

**What the world tracks about the player:**
- Reputation, per town and per faction (not one global number)
- Appearance — what the player is visibly wearing and carrying
- Notoriety — what they have been *seen* doing, by whom
- What each NPC personally knows about them

### The world tick

**The tick, defined (settled).** One tick is **one in-game minute**. The simulation
advances **4 ticks per real second** while the player is in the overworld. So:

| | |
|---|---|
| 1 tick | 1 in-game minute |
| 1 real second | 4 in-game minutes |
| 1 in-game day | 6 real minutes |
| `--ticks 5000` | 3.5 in-game days ≈ 21 real minutes |

Every drift rate in the table below is therefore expressed per in-game minute, and
"over the following in-game days" (§2) means the player watches a pillar's fallout
land over the next half-hour of play.

**Two clocks (settled).** A *step* is the simulation's own heartbeat at **60 a
second**; a *world tick* is one in-game minute and fires **every 15th step**. That
is exactly the 4 in-game minutes per real second above — the world clock did not
change — but the simulation no longer resolves the player's hands at its speed.

| | |
|---|---|
| 1 step | 1/60 s. Movement, collision, input, dialogue |
| 15 steps | 1 world tick = 1 in-game minute. The twelve drifting quantities |
| 1 real second | 60 steps, 4 world ticks, 4 in-game minutes |

Why two, recorded because it was the wrong call first time: a single 4 Hz clock is
right for grain prices and wrong for a walking man. Every key press waited up to
250 ms and a quarter of a second of input lag distorts every judgement made while
playing — including the judgement about walk speed this phase exists to settle. A
system says which clock it is on: anything the player's hands can feel is on the
step, anything that drifts is on the tick.

**Combat runs beside the sim, and the world clock stops during a fight.** A fight is
not advanced by world ticks and does not advance them; when it resolves, the sim
resumes from the tick it stopped on. Real-time combat therefore never needs a second
world clock, and never drifts prices while the player is blocking.

The world advances on a coarse clock, not a life simulation. Twelve tracked
quantities drift on their own and are pushed by the player's actions — **in either
direction** (2026-09-13). The "breaks it by" column is v1's; "builds it by" is v2's,
and the two are the same kind of thing: a deed, at a landmark or in a conversation,
that writes the quantity and the player's handprint.

Read the first of those columns as a list of verbs and v1 was nine ways to damage the
kingdom and none to build it. That was not a missing feature but a missing **sign**.
The store already takes one — `push()` is signed and clamped, and `credit_from()`
already carries the handprint along a coupling — so the second direction costs no
engine work. It is rows in this table, and every row must satisfy the two hard rules
further down: *every door that shuts opens another*, and *every act that moves the
kingdom names who it costs*.

| # | Quantity | Drifts because | Player breaks it by | Player builds it by |
|---|---|---|---|---|
| 1 | Grain price **(per town)** | Season, supply, **and mouths to feed — deserters buy the food they used to be issued** | Burning stores, redirecting convoys | Enforcing the grants; getting the convoys moving; warning a town in time, so it lays in stores |
| 2 | Steel output | Ore supply, worker morale | Sabotage, turning workers | Delivering labour; **feeding it the forest** — the Thornwood is the works' fuel, so felling it is a Cinderworks act and its cost lands in the wood |
| 3 | Worker morale | Wages, accidents | Agitation, exposure of the ledger | Settling the wage dispute; labour delivered, which is shorter shifts |
| 4 | Patrol density | Crime reports | Being seen committing violence — and it widens how far along the King's Road a traveller will recognise you | Informing the crown; handing deserters back to the Muster, which puts men on the road. Its cost lands on everyone who lives by being unseen |
| 5 | Guard alertness **(per town)** | Recent incidents | Any witnessed crime — and above a threshold the watch stands over what it guards and the act is refused | Informing the crown about this place — the watch is roused where you point it, and stands over the granary against the hungry as well as against you |
| 6 | Crown treasury | Taxes, war costs | Robbery, exposing debts | Bringing the bank the crown's creditors; the grants enforced and the convoys moving, which is rent and sale |
| 7 | Bank confidence | Treasury, rumour | Robbery, handing over records | Restoring confidence — the creditors brought to the table, the treasury refilled. It follows the treasury in both directions |
| 8 | Town sentiment **(per town)** | Prices, patrols, law | Almost everything | Almost everything, the other way: cheap bread, wages paid, a town warned in time |
| 9 | Army strength *(global — there is one army)* | Pay, food, desertion | The Wide Acres, the Muster, the bank | Paying it, feeding it, handing it the deserters |
| 10 | Faction tension | The above | Taking sides | Settling what it feeds on — the wage dispute, the unpaid army, the empty granary. Downstream of the others in both directions |
| 11 | Rumour spread | Time | Being witnessed | Neither direction pushes it: **a readout** (2026-09-11) of how many stories are in the air |
| 12 | King's escort | **Derived from army strength** (below), not stored | Whatever hollows the army | Whatever fills it |

Each is a number the simulation core owns, updated on tick, and readable by
dialogue, prices, spawn tables and the pillar system. Nothing here requires
simulating a person's day.

**Quantity #12, the escort, is derived rather than stored** (2026-09-11). It reads
off army strength: ten men at full, five at the strength a camp is left with once
the pay fraud is public, and two — §3's "bare handful" — when there is nothing
left. §3's "roughly one and a half fewer per power base damaged" never worked: six
bases at 1.5 leaves one man, and 1.5 is not a person. Reading it off the army makes
it continuous, integral, and a consequence of the world rather than a tally of the
player's achievements.

**Drift rules arrive one consequence at a time.** Stage 1 gives only army strength
a rule; the other eleven are declared, addressable and at their baseline. Inventing
eleven more drift rates would be inventing eleven numbers nobody had reasoned
about, and §8's "drifts because" column is a cause, not a rate.

**Two of the twelve are per town, not global** (decided 2026-09-11). Grain price
and town sentiment are held once per settlement. §8's own opening already said
reputation is "per town and per faction, not one global number", and a single
sentiment number contradicted it; consequences 1 and 4 both fail without the fix.
Prices are per town for the same reason — consequence 2 asks for grain "in
Harrowgate", not in the abstract. **Army strength stays global: there is one army.**

**Desertion feeds grain demand, explicitly.** Army strength falling means men who
were issued food now buy it, so the towns nearest the Muster see grain rise. This
coupling is not a detail — **it is the whole mechanism of consequence 2**, the one
where the world reacts to what the player broke without ever mentioning them. An
implicit link would be no link at all.

**How reputation is earned and lost:** TBD in detail. Principle: reputation is a
consequence of *witnessed* actions, never of a quest completion flag.

**Who witnesses what, and how word travels:** witnesses record what they saw;
rumours propagate on a delay; a crime nobody saw did not happen.

### Hardship — a reading about a place, beside the twelve (2026-09-13)

**What an act costs the people who live somewhere, held apart from what it costs the
crown.** One figure per town, in the same store as grain price and town sentiment.
It is the keystone of v2: with one bidirectional axis the game is a scoreboard with
two ends and the player picks an end. Hardship is the second axis — the one that
makes both ends cost something and neither of them correct.

**It is not a thirteenth quantity, and the twelve are untouched.** They are not
renamed, renumbered or merged. Hardship stands beside them the way `held_ground`
already does: a reading about a *place*, kept where readings live. The refusal
further down this section ("Can the twelve quantities carry these five?") does not
reach it, and now says so.

**Up is worse.** Like grain price, and unlike the global figures where 100 is as good
as it gets for whoever owns them, hardship is a cost: it rises when the people of a
place are worse off. Named here so nobody inverts it by accident.

**Raised from either direction.** The crown's policies raise it — the grants enforced
on the people who work razed ground, the works fed with longer shifts. The player's
disruptions raise it too — a granary burned is the Wide Acres' winter, a cold furnace
is the Cinderworks' wage. Strengthening a place for the crown and breaking it both
cost the people in it, and often the people somewhere else: free the Wide Acres and
the Muster goes hungry; feed the Cinderworks the forest and Kell's fire has less wood
around it. **An act writes hardship where its cost lands, which is frequently not
where the act was done.** That is the hard rule below — *a cost has a face* — made
into a number.

**It barely drifts and moves sharply when acted on.** §8's own warning applies with
full force: a world where everything drifts is a world where nothing reads as caused,
and hardship exists to read as caused. So it has no lively drift rate and must never
acquire one. What moves it is a deed, through `push()`, with the handprint written
beside it. Whatever small easing it turns out to need gets its rate the way the twelve
got theirs — when the consequence that needs it is built, not here.

**What reads it.** In v2 it is not a predicate input: an ending reads it *out*, never
*in*. Making it a threshold would hand it a correct direction, which is the one thing
it exists not to have. It is *shown* — in the place (§13: a shuttered works, a queue at
the granary), in what people say (§9: a condition content may name, like
`grain_is_dear_here`), in the journal (§15), and at the end, where a player who takes
the throne (§3) is shown the hardship figures in the towns they changed, the morning
after. Those channels are later items of the v2 rewrite; the figure is defined here
so that all of them read one thing.

> **What was rejected.** Folding it into town sentiment — sentiment is what a town
> thinks of the crown, and a town can be loyal and hungry, which is the whole of the
> Wide Acres. Folding it into the player's per-town standing — that is what a town
> thinks of *you*, and a place can love the man who ruined it. One global figure — it
> is about a place, and a global misery index would be the thirteenth quantity the
> refusal is actually about. A third state for a place, "ruined" — hardship is a
> reading, not a state, and a state would freeze what should keep costing.

### A change the player cannot perceive is identical to no change

The governing principle of this whole section. A quantity that moves correctly and
is never felt has not happened, and the simulation is only as good as its narrowest
channel to the player.

Feedback comes in **three registers, and all three are needed**:

| Register | What it is | Example |
|---|---|---|
| **Immediate** | Something happens as I act | The escort drops from ten to eight the night I expose the fraud |
| **Ambient** | The world looks different when I return | Half the tents are down; the town has more people in it |
| **Narrated** | Something eventually tells me it was me | The journal, when I go looking |

**Most systemic games do the first two and skip the third, which is why their
players never feel their choices mattered.** The world changed and nothing ever
connected it back. Narration is not a nicety on top of simulation; it is the half
that turns simulation into experience.

#### Push the ambient, pull the attribution

The world **shows** change without explaining it. The journal **explains** it when
asked. Nothing ever announces *"your actions caused X"*.

Maddox not knowing it was you is the entire pleasure of consequence 2. A banner
reading "Your exposure of the pay fraud has raised grain prices by 24%" would
destroy it, and it would destroy it *while technically providing more information*.
The player assembles the connection themselves; the journal is there for when they
want to check they were right.

#### Ambient drift stays slow and small; player-caused change is large, fast, local

**A constraint on the twelve, and the reason ten of them have no drift rule yet.**

If everything drifts constantly, nothing reads as caused. A world where every
quantity wanders is a world where a player cannot tell their own handprint from the
weather — and the handprint is the entire point. Resist the urge to give the twelve
lively drift rates because a still number looks unfinished. A still number is the
background against which a moved one is legible.

So: ambient movement is slow, small, and regional at most. Player-caused movement
is **large, fast and local** — grain in the towns near the camp, not grain
everywhere; the escort now, not the escort eventually.

### The five consequences — the specification for the reactivity system

Not examples. Each one exists to prove a different mechanism, and Phase 3 is done
when all five happen in play. They are also not a closed list: what the system
should *be* stays open, and these are the five that pin it down first.

**1. Word outruns me.** I steal from a stall in Harrowgate in front of Maddox.
Three days later I walk into Cairnwell and a trader I have never met will not sell
to me. The story got there before I did.
> *Proves:* witnesses → rumour travelling on a delay → reputation in a town I have
> never visited.
>
> **Theft rather than murder, deliberately.** Stealing is a verb the finished game
> needs anyway, so building it now is building the game rather than scaffolding;
> murder would drag combat forward a whole phase to be thrown away again. The chain
> it exercises is identical — witness, rumour, delay, reputation somewhere else —
> and **killing arrives in Phase 4 through exactly these pipes**, as a heavier act
> on the same machinery, not as a second machinery.

**2. The world reacts to what I broke, not to me.** I expose the fraud at the
Muster. A week later grain prices in Harrowgate have risen, because deserters are
buying food they used to be issued. Nobody mentions me. Nobody thanks me.
> *Proves:* systems reacting to systems. This is what the external-versus-derived
> event split unblocks, and it is the most satisfying kind **precisely because the
> player gets no credit** — the world is not a scoreboard.

**3. Someone who liked me changes.** Ossa helped me once. Later I do something that
hurts the people she treats. Next time her dialogue options are fewer and colder —
not hostile, just closed.
> *Proves:* per-NPC relationship, distinct from town reputation, visibly shaping
> which lines exist.

**4. Being known opens one door and shuts another.** After exposing the fraud,
Harrowgate treats me as somebody. The same reputation means the guard at the bridge
recognises me and will not let me pass.
> *Proves:* reputation is per-faction and never a single score. This is the heart
> of §8.

**5. The world moves without me.** I do nothing for a week. I come back to the
Muster and there are fewer tents. The desertions I started kept going without me.
> *Proves:* the world tick drifting under its own momentum.

### Drift may move the world; only the player may end it (hard rule, 2026-09-11)

Every quantity carries a **handprint** beside it: how much of where it stands the
player put there. Deeds write both; drift writes only the number. §3's end
conditions require a minimum handprint as well as a threshold, so **a reign can
never fall out of ambient motion**.

This is what keeps the twelve from becoming weather the player watches. It also
gives the journal something true to show — see §15.

### Two sides, and not joining either (2026-09-12)

**The crown** is industry, the road, the cities, order and the tiered law. **The
opposition** is the forest, magic, the displaced and the poor. That is §4's thesis
with people in it: the map already argues, and this is who is arguing.

**Neutral is not a third faction.** It is the default, it is free, and it is what the
game already was — everything that worked before joining exists still.

**They feed the three routes; they do not replace them.** The crown opens Access and
lets the player rise until the castle admits them. The opposition feeds Exposure. And
joining neither leaves Force, which needs nobody's permission. **One structure, not
two** — which is what keeps invariant 7 true when a player joins the crown and helps
it hunt the opposition to nothing. A test does exactly that.

**Joining is not standing**, and the distinction is load-bearing. Standing is what a
place thinks of you and it moves on its own; joining is a thing you chose, it changes
only when you say so, and **everyone can see it** (§8's appearance register — the
context packet carries `SEES YOU AS`). A crown officer can be despised in Harrowgate
and still get through the gate at Blackcairn.

**Four ranks a side, read off service rather than stored**, so there is one number to
replay and no way for the two to disagree. Service comes off the **deed table**: every
act already in the game counts as work for the opposition without being authored
twice, which is why joining them needed no new verbs at all.

**The crown needed exactly one new act.** Every one of the thirteen deeds cost the
king something — fine while the player could only be against him, and untenable the
moment they could join. Rather than invent ten pro-crown systems, there is one act:
**informing**, the mirror of making a thing public. The same fact, spent the other way.
It is one-shot, it requires actually knowing something, and **it costs you the town**,
because nobody likes an informer. That last part is what stops the crown route being
free: every step up costs you the ground you are standing on.

> **v1's answer, and v2 extends it (2026-09-13).** One act was enough to make joining
> the crown *possible*; it was never enough to make it a *play*. Informing stays, with
> its cost. The rest of the crown's service is the "builds it by" column of the table
> above — the grants enforced, the convoys moving, the works fed, the army paid, the
> creditors brought in — each a deed with a face, each worth rank (§11). Eleven ways to
> serve the opposition against two to serve the crown was the count when v1 shipped;
> the second direction fixes the count by fixing its cause.

**You join by saying so to somebody** — Tovin writes you down, Kell takes you in —
never from a menu, so it is in the log and there is a person who took your name.

**Ownership is a fact, not a constant.** Blackcairn does not move — you do not take
the castle by being disliked there — and neither does Brindle, which was never his.
In v1 only the two borders, the **Wide Acres and Saltmarch**, changed hands, on the
sentiment of the town under them — on a band rather than a line, so a border cannot
flicker. **v2 keeps that band and adds a second way for a place to change hands**
(2026-09-13), below.

> **The disguise is proposed and not built**, by decision. See `docs/history/OVERNIGHT.md`:
> worn rather than toggled, fools strangers and never the twenty-five named people,
> broken by being seen acting, and gating nothing.

### A place changes hands two ways, and holds for two days (2026-09-13)

Two models of a place changing hands existed — the band above, and v2's decisive act
— and both are kept, as the two paths the hard rule above already names: *drift may
move the world; only the player may end it.*

**Four places carry a state: the Wide Acres, the Cinderworks, the Muster and the bank
at Cairnwell.** The state is binary — **crown-held or free** (the code's
"opposition") — and there is no third. A place is never pushed past its starting
state: all four start crown-held, because that is what a power base is, and you
either **liberate** one or **restore** it. The Wide Acres never becomes better than it
has ever been, and nothing may build a "held by the player" or "better than the crown
had it" state by accident. Harrowgate and Greyhold are deferred, not cut, and carry no
state in v2; Blackcairn cannot be taken and has one state (§4).

| Path | What moves it | Handprint | Stamp |
|---|---|---|---|
| **Drift** | The sentiment band, unchanged from v1: below 30 the town under a place turns it free, above 70 turns it back. **The two borders only** — the Wide Acres and Saltmarch | None | None |
| **Player** | **One decisive act per place** — a deed at its landmark (`SiteRules` already reaches all four: kiln, granary, counting house, muster rolls), whose outcome can land either way. Sets the state directly | Written | The tick it happened on, in the event log |

**One decisive change per place, two directions.** Not two quests per place — one
deed, whose outcome is crown-held or free depending on what the player did with it.
Invariant 5 stays literally true (*a quest that can only start one way is a bug*), the
writing is halved, and there is still no quest store: a decisive change is a deed, not
a quest object. The other acts for and against a place — burn the stores, get the
convoys moving — move the quantities and write hardship; they do not flip the state.
Which act is decisive for which place, and what decides which way it lands, is §3's
table.

**The freeze window — one constant, defined here and nowhere else.**

> **2 in-game days = 2 × 1440 = 2880 world ticks = 12 real minutes.**

A state the player set holds for that long, **against everything** (Yannick,
2026-09-13): the town's sentiment cannot move the place back, whatever it reads, and
the opposite decisive act is **refused** for the length of the hold — the way a roused
watch refuses an act (above). That is world state refusing a deed, the same shape v1
already has, not a progression gate: the place has just been decided and stays decided
for two days, and everything else at the place still works — the other acts move the
quantities and write hardship as before. As with the roused watch, the ambient shows
the door shut and the journal says what shut it; the landmark never advertises an act
it will refuse. After the hold both paths apply again. A place is **reversible**: a
freed Wide Acres whose town swings above 70 goes back to the crown by drift, exactly as
v1 would have moved it, and the player may restore it by hand. The hold is what makes a
decisive act decisive — without it a band at 70 could undo a liberation on the next
tick, or the player could flip a place twice in a minute, and the largest act in a
place would read as a switch.

The window is **a tick stamp in the event log** and nothing else — no timer, no node,
no second clock — so a replay lands on the same tick in the same state.
`Game.TICKS_PER_IN_GAME_DAY` is 1440; the constant is that, twice, defined once in
`core/` and read by everything that needs a window. §4's instability reading for Blackcairn
uses **this window and no other** for "how recently": a flip inside the last window is
recent, and four of them inside one window is a crisis.

**What each path leaves behind.** A drift flip writes no handprint, so a place the
world moved is a place the player did not move — the journal (§15) can say *the Wide
Acres turned* and cannot say *you turned it*, which is the truth. A player flip writes
the handprint and the stamp, and the stamp is what Blackcairn reads. Both raise the
instability reading: a flip is a flip to the men on the wall, whoever caused it. Only
the player's counts toward an ending, per the hard rule.

> **What was rejected.** Keeping only the decisive act — the band is v1's honest model
> of a border, it is tested, and it is the one way a place moves *without* the player,
> which Pillar 4 requires. Keeping only the band — a band writes no handprint, so a
> player who freed the Wide Acres by souring it would be indistinguishable from
> weather, and the throne reading (§3) would never fire. A longer freeze — a season
> makes the first flip final in practice, and a place that cannot be restored is a
> ratchet. A shorter one — under two days the band could reverse a liberation before
> the player had walked to the next town. Extending the band to all four — a
> Cinderworks that went free on a bad week of bread would be a power base falling to
> weather; drift is for borders, not for what holds a reign up. The borders' neutral
> start — *a border is not a side* was v1's and is retired by the binary rule: the Wide
> Acres and Saltmarch start crown-held (§4: *the king's, contested*; *the king's,
> barely*), and what makes them borders is that they are the two the band can still
> move.

### Every door that shuts opens another (hard rule)

**A reputation change is never only a loss.** Kill the people Ossa treats and she
closes to you — and someone else, very likely someone worse, approves. Whatever
standing you lose with one town, faction or person is standing gained with another.

This is what keeps §1's Pillar 3 honest at the level of *reputation* rather than
only of NPC deaths: permissiveness means the world absorbs what you do and rearranges
itself around it, not that it punishes you into a corner. A system that only ever
subtracts turns into a morality meter, and a morality meter has exactly one correct
way to play.

Practically: every reaction rule names who is offended *and* who is impressed. If a
change has no counterpart, it is not finished.

### Every act that moves the kingdom names who it costs, and the cost has a face (hard rule, 2026-09-13)

The companion to the rule above, and it binds **both directions**. That rule says a
reputation change is never only a loss; this one says a change to the kingdom is never
free — not for the player, for *somebody* — and the game must be able to say who.

Not "steel +20": a valley that cannot drink its water because the works' runoff is in
it; a garrison that goes hungry because the estates that fed it went back to the
people who farmed them; a family an NPC can name. A cost with no face is a scoreboard,
and a scoreboard has exactly one correct way to play — the failure the rule above was
written against, one level up.

Practically: **every deed row names where its cost lands and who there can say it.**
Where it lands is a hardship push in a town (above), and *who* is one of the
twenty-five or a place's own people, in their own words — Pell for the Wide Acres,
Sena or Ivo for the Cinderworks, Kell and the men Ossa treats for the Muster, Mira's
clients for the bank. A deed that moves a quantity and writes hardship nowhere is not
finished, in either direction, and the test that already walks every deed for its
counterpart must walk it for its face too.

> This is why the second direction needed hardship before it needed acts. Nine ways
> to break the kingdom and none to build it was a missing sign, and filling in the
> sign alone gives a scoreboard with two ends. The face is what makes strengthening
> the Cinderworks cost the Thornwood and freeing the Wide Acres cost the Muster — so
> that a loyal run and a rebel run are both *plays*, and neither is the answer.

### What raises a town: giving away what you know (2026-09-11)

Reputation was one-way. Every act in the system subtracted, the `welcome` band was
unreachable, and the counterpart rule was honoured only *across* factions — theft
costs the town and buys you the unlawful — never *within* one. That is the shape
that teaches a player to do nothing, and it is the failure mode a morality meter
has: if addition is gated and subtraction is free, the optimal play is to stand
still.

**Availability is the hard part of this rule, not the arithmetic.** The positive
acts must be as available as theft: things you can do *because you are standing
there*, needing no grant, no quest and no permission. An act you have to be given
is not a counterweight to an act you can simply take.

**The primary positive act is telling people what you know.** This is not a
consolation mechanic bolted on to balance a meter — it is the thesis of the game
stated as a verb. Information is the currency here and the king falls to what people
know, so the act that raises a town is the act the whole design is about.

It is the exact mirror of theft. Theft takes and is witnessed; telling gives and is
witnessed. Same machinery, opposite sign: a deed, the people near enough to see it,
a story that travels, and standing that moves as the story arrives.

**Act 1 — warn a town.** The player holds the Muster's pay fraud. Until now it had
exactly one use: tell the Muster and the army collapses. It now has two. Tell
**Harrowgate** instead — the deserters are coming, here is why bread is about to
rise, lay in stores now. The town's opinion of you rises. The army does not
collapse. The town is *prepared*, and takes less of the grain pressure whenever the
Muster does empty out, by whatever hand.

**The fact becomes a resource with an opportunity cost.** It can be told once, to
one audience. Spend it on the king — collapse the army, shorten the escort — or
spend it on the town. That is a dilemma; a fact with two independent uses is a menu.
In the fiction, speaking it aloud anywhere is what reaches Odile, and a
quartermaster who knows she has been named does not leave the books where she left
them; the second audience gets a story rather than a revelation.

> **What is spent is the telling, never the knowing.** The fact stays in the fact
> base permanently. Route C needs the player to *know* the fraud and put it in front
> of the king, and nothing here touches that — nor invariant 6's redundancy, nor
> invariant 7's reachability, both of which are claims about reaching a fact rather
> than about having spent it.

**Act 2 — give back what you took.** Smaller, and the precise mirror of theft: put
it back on the stall you took it from, in front of whoever is standing there. It
raises the town, costs you with the unlawful by more than the theft gained — a thief
who returns things is no use to anybody — and does not fully undo the loss, because
the town remembers that you took it. It also cannot catch the story: a rumour
already walking toward Cairnwell keeps walking. **You can repair the place, not the
past.** That is the point of having it — a way to answer for a mistake rather than
only to accumulate them.

> **A deed travels if it is worth repeating.** A theft is, three days' walk away.
> So is a man standing in a square saying the king's army is rotting. Somebody
> quietly putting something back on a stall is not — it is news to the people who
> watched it and to nobody else. That single rule is what makes restitution local
> without making it a special case.

**What this seeds.** If evidence can buy standing, then every document the player
finds carries a temptation, and Route C's assembly becomes a running series of small
refusals rather than a collection quest. That is the intended pressure.

### Reactive dialogue: content names a condition, the rules layer defines it

A line may be gated on a **named world condition** — `grain_is_dear_here`,
`the_army_is_shrinking` — and an NPC may have alternative greetings gated the same
way, so a town can tell you it has changed before you ask it anything. Content
names the condition; `core/rules/` decides what the name means. A line that read
the world directly would put game logic in `content/`, where it cannot be reasoned
about or tested, and §9's whole point is that the rules layer issues the verdict
and the words only phrase it.

**A conditional line outranks a standing one.** §9 allows three or four options and
the fourth is always the way out, so there are three slots for anything else. A
line that exists *because the world changed* takes its slot first; the standing
filler yields. Otherwise the cap fills with what is always there and the reactive
line — authored last, by nature — is never seen, which is reactivity nobody can
reach.

More lines may be authored than are ever shown at once. What §9 constrains is what
the player is *offered*.

### Can the twelve quantities carry these five?

Asked and answered honestly: **one of the five, as they stand.**

| | Consequence | Verdict |
|---|---|---|
| 1 | Word outruns me | **No** |
| 2 | The world reacts to what I broke | **Partly** |
| 3 | Someone who liked me changes | **No** |
| 4 | One door opens, another shuts | **No** |
| 5 | The world moves without me | **Yes, today** |

**The pattern, which matters more than the individual gaps.** The twelve are all
*how the world is doing* — global scalars, one number each. Four of the five
consequences are about *the player's standing in the world*, which is a different
kind of thing: it is indexed by town, by faction and by person. It does not belong
in the tick table at all, and adding a thirteenth, fourteenth and fifteenth quantity
would be the wrong repair.

> **What that refusal covers, and what it does not (2026-09-13).** It refuses
> *standing-shaped* numbers — what each town, faction and person thinks of the player,
> which is indexed three ways and lives in its own structure. It was never a refusal
> of a reading about a *place*. Three of the twelve are already held per town in the
> same store — grain price, town sentiment, guard alertness — and so is `held_ground`,
> which the code itself marks as *not a thirteenth quantity* for this exact reason.
> **Hardship is that kind of number**: a condition of a place, defined earlier in this
> section, and the refusal does not reach it. `core/world_tick.gd` repeats the refusal
> on `held_ground`; read it the same way.

So Phase 3 keeps the twelve as the world's vital signs and adds a **second
structure** beside them — standing and knowledge, indexed rather than global:

- **Reputation per town** and **per faction**. §8's own opening already says "not
  one global number", and quantity #8 "Town sentiment" is a single global number,
  which contradicts it. That contradiction is why consequences 1 and 4 fail.
- **Relationship per NPC**, which nothing currently tracks. Consequence 3 needs it.
- **Rumours as travelling items** — each carrying what happened, where, who saw it
  and how far it has got — not quantity #11's single "rumour spread" scalar. A
  scalar cannot arrive in Cairnwell three days later.
- **Witnesses**, recorded per event rather than tracked as a quantity at all. This
  is event-log data and belongs there.

Two of the twelve also need to stop being global, because consequences 1 and 2 ask
for them per place: **#1 Grain price** ("prices *in Harrowgate*") and **#8 Town
sentiment**. Consequence 2 additionally needs an explicit coupling from **#9 Army
strength** to **#1 Grain price** — desertion is not currently listed among grain's
inputs, and that link is the whole of the consequence.

Consequence 5 needs nothing new: #9 already drifts on "pay, food, desertion". It
wants the drift implemented and the Muster's tents drawn from the number.

---

## 9. Dialogue & NPC interaction

### The input model

**The player never types.** There is no free text box, ever. When the player opens a
conversation, the system offers **three or four options**, generated from the
player's accumulated context, their traits, and the relationship between these two
characters.

> The single most important technical decision in the game, and a strong one: every
> possible player utterance maps to a known intent, so nothing can be talked into
> existence that the systems did not already permit.

**Trait-gated options are visibly tagged**, in the manner of *Fallout*. The player
sees that an option exists *because* of who they built:

- *[Wits]* "Hello — I'm lost. Where am I?"
- *[Temper]* "My town was destroyed by the king. I need to find him."
- (a third, untagged, neutral option)

**Locked information.** Facts can be withheld from the generator on both sides:
options the player cannot yet say, and things the NPC cannot yet reveal, regardless
of how the conversation goes.

### What each side knows

**An NPC who has never met the player has no access to the player's context.** They
know what anyone in the region would know, plus what is visible: appearance,
weapons, blood.

**An NPC who has met the player remembers** their previous exchanges, what was
promised, and what was done.

**Quests emerge from NPC context, not from a quest list.** *Tom lives in town ABC.
Tom lost his sister in the forest. Tom is rich and looking for help.* If the player
arrives and the conversation goes a certain way, that thread opens; otherwise it
doesn't.

### The context layer — deterministic assembly, not vector RAG ✅ (built 2026-09-12)

**Decision: no embeddings, no vector search.** Build a *context assembler*: a pure
function

```
build_context(npc_id, player_state, world_state, history) -> ContextPacket
```

that walks fixed, ordered sources and renders them into a deterministic string:

1. The NPC's authored sheet — identity, wants, fears, voice
2. Their social edges from the relationship graph, 1–2 hops (family, employer,
   debts, rivalries)
3. The facts they know, from the fact base, filtered by their `knows` relations
4. What they know *about the player* — met, witnessed, heard by rumour, or nothing
5. The world-tick values that touch them — their town's sentiment, local prices
6. The conversation history between these two, if any

Each source has a fixed token budget and a stable sort order, so identical state
always renders an identical packet.

**Why not RAG.** Three reasons, in order of weight:

1. **Determinism.** The packet is hashed to key the dialogue cache. Vector recall
   can drift between runs, hardware and index builds; a drifting packet is a
   drifting hash, a cache miss, and a broken determinism guarantee — at exactly the
   layer we most need it.
2. **Scale.** With 20–40 NPCs, the entire cast's context fits in a context window
   many times over. Retrieval solves a problem this game does not have.
3. **Shape.** What Yannick described — "family links, relations to other NPCs and to
   the player" — is a *graph traversal*, which a query answers exactly and an
   embedding answers approximately. The graph intuition was right; the embeddings
   were an unnecessary layer under it.

**When RAG would earn its place** — revisit if either becomes true:
- The cast passes roughly 150–200 NPCs with substantial individual histories, or
- The player can search a large corpus of in-world documents (archives, letters,
  ledgers) that cannot be enumerated by traversal.

In that case: hybrid. Deterministic graph traversal for the NPC, vector search
*only* over the document corpus, with a fixed top-k and a stable tie-break so the
retrieved set still hashes consistently.

### How standing changes a conversation (2026-09-11)

Found in play: steal from the Harrowgate market in front of Maddox, Bell and Tovin,
then walk up to any of them. All three opened exactly as they had the first time.
The machinery was correct — Maddox at −30, the town at −22, every resident
ill-disposed — and **reaction was something each individual line had to opt into**,
so silence was the default and four of the five named cast had never opted in.

Writing more alt-greetings would not have fixed that. It would have postponed it
until the next NPC. So the default is inverted: **the rules layer changes every
conversation from one number, before content is consulted.** Authored lines
override; they are no longer what makes reaction happen.

**One number.** A conversation reads what *the person in front of you* thinks.
Their own standing already carries their town's through hearsay, so gating some
content on the town and some on the person was a distinction the player could not
see and an author had to guess between. Per-town standing stays for content about a
*place* rather than a person.

| Band | How they open | What is offered |
|---|---|---|
| **hated** ≤ −60 | turns away | nothing — the conversation is refused |
| **unwelcome** ≤ −20 | does not return your greeting | anything costing goodwill is withdrawn |
| **wary** ≤ −5 | watches you a moment too long | unchanged |
| **unknown** | their everyday greeting | unchanged |
| **welcome** ≥ +5 | glad to see you, and shows it | plus anything they will only volunteer to a friend |

**The shared lines are narration, not speech.** A line in nobody's voice sounds flat
coming out of a named character; a line about a *stance* works in everyone's mouth.
Four sentences cover the entire cast, for ever, and authored greetings become where
the good writing goes rather than the only thing standing between the player and a
world that does not notice them.

**Options carry a cost.** `goodwill` means answering costs the listener something —
a fact confided, a name given up, a lead handed over — and people do not do that for
somebody they think ill of. **Anything that teaches a fact costs goodwill by
default**, so the rule reaches new content automatically. `costs: "free"` marks the
one source of a fact that stays open however badly the conversation is going, and a
test fails the build if a fact has no such source. Invariant 6's redundancy is what
makes a door shutting affordable at all.

> **The coverage test is the deliverable, not the table.** No speaker may present an
> identical conversation at `unwelcome` and at `unknown`, or at `welcome` and at
> `unknown`. It walks every speaker at every band through a real conversation, and
> it is what stops this returning the next time somebody is added to the cast.

### House style, and the generation constraints (2026-09-12)

**Plain words. Short sentences. No metaphor. Every line understandable on its own.**
A 10 year old should be able to read any line in the game, in either language.

That is not a simplification of the writing, it *is* the writing. These are busy
people saying what happened, and the job of a line is to be true and clear, not to
be well turned.

**French is written first, then English.** Neither is a translation of the other.
The line that settled this was *"chaque peine de plus de 4 mois porte ma main au
bas"*, which is not French at all. It existed because an English image had been
translated word for word, and a 25 word sentence gave it somewhere to live.

**Every line must stand on its own.** The player chooses options in any order, so no
reply may assume another has been read. Not "7 years" but 7 years *in prison*; not
"more stone" but stone *to make the works bigger*; not "at the furnace" unless the
furnaces have been named in the same breath. Plain language is not only short words,
it is giving the player enough to understand what is being said.

**Counts are figures**, in both languages: 381 dead, 11 years, 9 villages, 4000
acres, 40 men at the gate. A game about ledgers and tolls should read like one, and
digits are language-neutral when the same content ships twice.

| Rule | Why |
|---|---|
| No em dash | The most recognisable tell in English, and French uses it differently |
| No line over 420 characters | The dialogue box holds four lines of about 120 |
| No sentence over 24 words | A short sentence can be wrong. It cannot be ornate, and it survives being written in one language and checked in the other |
| Under 4.6 letters a word | Long words are where the literary register creeps back, and the first thing a model reaches for when asked to sound serious |
| No reply over 48 words, no voice averaging over 44 | Nobody makes a speech |

#### Two rules were deleted, not relaxed

Both were built for a register that is gone, and one of them caused the damage.

*At most a quarter of replies may end on the speaker* was a proxy for the wry,
self-aware coda. The plain register removes that by construction, and in plain
speech people say "I" constantly: "give me a week" is not a flourish.

*The cast must span a wide range of sentence lengths* was worse than useless. It
pushed characters into 27 word built sentences, and a built sentence is exactly
where a metaphor hides. **A rule that fights the register is a bad rule however well
it measures.**

> These rules are the generation constraints. A model will imitate the corpus, so
> the corpus had to be clean before it is ever used as an example, and
> `test/test_prose.gd` is the reject filter on anything generated. Every rule is
> checkable without a human reading the line.

### Where a generated line would enter the world (built 2026-09-12, model absent)

The whole path exists and **the model slot is empty**. The game ships today with
every line hand-written and this switched off, which is the point of building it in
this order: turning a model on later is replacing one function rather than opening
up the dialogue system.

**The window asks; the simulation is told.** A model is not repeatable and `core/`
must replay exactly, so nothing inside the simulation may ask one anything. The
window asks whoever chooses words and then **submits the answer as an ordinary
external event**. That single shape keeps everything true at once:

- it is logged, so a save contains the words and a reload says the same thing
- it is replayed rather than recomputed, so a model is never asked twice for the
  same moment
- it can be deleted and the game does not notice, because every line has an
  authored version behind it

**The door is inside the simulation, not outside it.** Every line is checked against
`ProseRules` before anybody hears it, at the point it enters rather than where it
was produced: whoever generated it may be careless or absent, and the rule that a
line may only name people who exist has to hold at the door. A refused line is
dropped and the authored one stands.

**The key is the packet fingerprint plus the intent.** Same person, same world, same
question, same words. This is the determinism guarantee §9 refused retrieval to
protect, and the hit rate on it is the number that decides whether a model ever
needs to run while somebody is playing.

**Voice notes** (`content/voices.json`) say how each person talks, in plain terms a
person or a model can both follow: *"answers with figures"*, *"says as little as
possible"*. English only and never shown to a player, so it is not translated. A
packet that says only "a foreman" is not enough to put words in anybody's mouth.

### What is actually in a packet (2026-09-12)

Four things, in this order, and it is worth naming them because the shape was
arrived at rather than designed:

| | Source | Changes |
|---|---|---|
| **Who they are** | `WHO`, `VOICE` | never |
| **What they have** | `KNOWS` (the relationship web), `HOLDS` (facts they can hand over) | never |
| **What they know about you** | `REGARDS YOU`, `HAS MET YOU`, `HAS HEARD` (every deed), `YOU KNOW` (what the player has learned) | every act |
| **Where you are in the talk** | `ALREADY ASKED`, `SO FAR IN THIS TALK` | every line |
| **The task** | `ASKED`, `MUST BE TRUE` | every question |

The third block is the one that was missing until 2026-09-12, and its absence is
why every answer read as though written for somebody who had just walked in off the
road. The packet described the person in detail and the player not at all. **Whether
you have read the ledger is the difference between being told the number and being
asked what you intend to do with it** — and when the player's own options are
generated, `YOU KNOW` is the source they are generated from.

The fourth block exists because the `asked:` facts are a set: they have no order and
hold no answers, so a packet built from them can say what was asked and never what
was said. The thread is held on `WorldState` for the length of one conversation and
cleared when it closes, because the thread is the conversation and not the
relationship.

### Two statements about one thing have to agree (2026-09-12)

`cinderworks:death_toll` described the works as having killed *"près de 400 hommes"*
while the brief for the question that teaches it said **381**. Both land in the same
packet — one under `YOU KNOW` or `HOLDS`, one under `MUST BE TRUE` — so the model
wrote 400 and looked as though it were inventing figures. It was reading ours.

That was the **second** time in one session that a model was nearly blamed for a
defect in the packet, the first being `HOLDS: thornwood:kell` becoming *"il est dans
Thornwood"* in a French line. The pattern is worth naming: **when generated output is
wrong, the packet is the first suspect, not the model.** A test now holds the
specific case — a fact description and the brief for the answer that hands it over
must agree on their figures.

### The brief is facts, never the finished sentence (2026-09-12)

The packet used to end with `MUST SAY:` and the whole hand-written reply. That is a
brief to **rephrase**, and rephrasing is safe and nearly worthless: if the sentence
is already written, writing it again buys nothing, and every situation still has to
be hand-written first. It also quietly decided that the answer to "is generation
worth having" was no.

It now ends with `MUST BE TRUE:` and the facts the answer has to contain
(`content/answers.json`, English only and untranslated, like the voice notes). The
line is then **written in the player's language from the facts**, not translated
from an English original — which is the same rule the register correction of
2026-09-12 imposed on the hand-written corpus, for the same reason.

**Every fact carries why, not only what.** *"the works has killed 381 men"* leaves a
player asking 381 of what; *"and Arthur reads the number every spring and orders the
works made bigger"* is the half that makes the first half mean anything. A line can
only be self-contained if the brief was.

**No facts, no generation.** An option with nothing declared for it keeps its
hand-written reply and the window never asks for words at all
(`Answers.may_be_written`, checked in `view/main.gd` before a packet is even built).
So this turns on one line at a time, and everything it is not turned on for is
untouched.

**What it is worth, measured** (16 lines written from real packets, 2026-09-12).
Against the hand-written reply for the same question, character overlap was:

| The world | Overlap with the written line | What that means |
|---|---|---|
| Nothing has happened | 74% | Generation reproduces what is already there. No gain. |
| They think well of you | 75% | Same. |
| The town is hungry | 50% | The line starts using the town's numbers. |
| They know you as a thief | 50% | The line answers *and* reacts. |

So the value is not spread across the cast — **it is concentrated entirely in the
half of the world the authored line cannot see**. Today every question has exactly
one written answer serving four materially different situations (71 questions, 284
packets, 284 distinct fingerprints, 71 distinct replies). Characters whose voice is
terse or numeric — Til at *"says as little as possible"*, Halgrave at *"answers with
figures"* — reached 85–91% overlap, meaning there is one way to say it and it is
already said. That is a reason to brief the reactive questions first and possibly
never brief the rest.

### The door was mis-calibrated, and only the corpus could show it (2026-09-12)

`ProseRules` was written before anything had been generated, so the only lines it
had ever judged were the bad ones its own test feeds it, written to fail. Run over
the 95 hand-written replies (`tools/prose_check.gd`) it **refused 8% of them**, and
every refusal was the rule being wrong rather than the line being bad:

- *One word-length ceiling for two languages.* French words are longer than English
  words for reasons that have nothing to do with register. English averages 3.85
  letters a word and peaks at 5.00; French averages 4.28 and peaks at 5.46. A single
  threshold at 5.4 refused two plain French lines while leaving English 0.4 of slack
  it never used. It is now per language.
- *Names that exist but nothing declares.* A role capitalised in French (*le
  Prévôt*), a wood that is not a town (*la Ronceraie*), four burned villages that
  appear only inside the sentence naming them. Content now declares them
  (`names` in the cast sheets), because a name the world contains and nothing
  declares cannot be told apart from one a model invented.

Both fixed, both languages now at 0% refused. **A door calibrated only against lines
written to fail is not calibrated**, and had this gone unmeasured the first thing a
model produced would have been blamed for the door's own faults.

### The figures are checkable because they are digits (2026-09-12)

`ProseRules` now also refuses a line that **drops a figure it was given** or
**invents one it was not**. This is the only part of "it must state the facts" that
is checkable without a person reading it, and it is checkable *because content
writes numbers as digits* — a decision taken for the player, which turns out to be
the one rule that survives being written in one language and checked in the other.
381 is 381 in French. Facts that spell a number out (*two winters*) are checked by
neither direction, which is correct: content spells a number out exactly where the
number is not the point.

An invented figure is worse than a dropped one. A figure is why a player believes
the rest of the line, so a made-up one spends trust the game cannot earn back.

### What the register actually is, judged by ear (2026-09-12)

Two rounds of blind and semi-blind comparison with the person who will play the
game in French. Both rounds were lines written from real packets and passed through
the door first, so nothing below is about correctness — it is about which of two
correct lines is the one to write.

**Round 1, six pairs, hand-written against written-from-facts, labels hidden.** The
hand-written line was preferred in 4 of 6. All six were the *plain* world, where
nothing has happened — which is exactly where the overlap measurement said
generation reproduces what is already there. The measurement and the ear agreed.
**A caveat worth keeping**: the answer came as an aggregate ("mostly B") rather than
per pair, so preference and position bias are not separable at n=6. Future rounds
ask per pair.

**Round 2, four situations where the world had moved**, two written versions each,
differing on one axis. The results are rules:

- **The reaction opens the line; it does not close it.** Chosen 3 times out of 3
  where that was the axis. A line that answers the question and then adds *"and I
  know what you took"* reads as an afterthought bolted on — the same coda tic the
  voice-range rule was deleted for encouraging. When the world has changed, say so
  first, then answer.
- **A signpost has to point somewhere useful.** Maddox's voice note says he answers
  by pointing at somebody else, and the version that sent the player to Tovin about
  the price of bread *lost* to the version that just gave the price. Tovin runs the
  law, not the granary. The note is not wrong; the referral was. A name offered that
  cannot help is worse than no name.
**Round 3, four more, testing whether the rule survives a *good* reaction and a terse
voice.** It does, 3 of 4 — and the one exception sharpened the rule rather than
weakening it.

- **The opener states the terms, not the opinion.** The three chosen openers all say
  what the speaker will *give*: *"À vous, je peux le dire"*, *"Vous, vous écoutez,
  alors je vais vous le dire"*, *"À vous, je le dis une fois"*. The rejected one says
  what the speaker *thinks of you*: *"Vous, vous regardez les fours au lieu de
  regarder ailleurs"*. That single distinction explains 6 of the 7 reaction-position
  answers across both rounds, including the ones that looked like exceptions. A
  reaction is a change in what is on offer. It is not a character noticing you.
- **A terse voice still reacts.** Til's note is *"says as little as possible, often
  three words"*, and four words of reaction still beat none. Terseness governs the
  answer, not whether the relationship is acknowledged.

- **Blunter wins where bluntness costs no fact.** The shorter, flatter version won
  where the two said the same things. It did **not** win where the longer version
  was the one that opened with the reaction, so this ranks below the first rule.

### Which model, measured rather than researched (2026-09-12)

Both candidates run locally on the M4 Pro through llama.cpp's prebuilt arm64 build,
same sixteen packets, same prompt, same grammar, temperature 0.3.

| | Through the door | Mean | Size |
|---|---|---|---|
| Ministral 3 8B, Q4_K_M | 44% | 1.30 s | 4.8 GB |
| Ministral 3 8B, with 3 examples | 44% | 1.31 s | 4.8 GB |
| **Qwen3.5 4B, Q4_K_M** | **81%** | **1.21 s** | **2.6 GB** |
| Qwen3.5 4B, with 3 examples | 62% | 1.24 s | 2.6 GB |

**The 4B beats the 8B decisively, at half the size and the same speed.** The desk
research recommended the Mistral model on the reasoning that a French company makes
the best French, while flagging as a surprise that one French tester had found the
opposite. The tester was right and the reasoning was wrong. *Nothing published about
these models predicted this; sixteen packets and an afternoon did.*

**Examples made it worse, not better.** Three hand-written lines shown as prior turns
cost the 4B 19 points. The most likely reading is that a model given a finished line
in this register starts reaching for the *contents* of the example, not its shape —
the same failure as a finished French sentence in the background beating an English
instruction in the task. Not investigated further; recorded so it is not tried again
by assumption.

**Two of the three refusals were the same fault**: the model wrote *onze*, *quatre*,
*deux* where the brief gave 11, 4 and 2. It is not wrong French. It is wrong for this
game, where a figure is evidence and has to be repeatable, and it is the single
easiest thing to fix with a grammar.

### The door cannot see meaning, and that is now the gap (2026-09-12)

Of the thirteen lines the door accepted from the better model, perhaps **two** are
usable. What passed:

- *"Je ne défends pas ceux qui n'ont pas d'argent"* — Mira, whose entire brief is
  that she defends people who cannot pay. **The exact inverse of the fact**, with no
  figure in it, so nothing caught it.
- *"Ils n'ont pas le courage mais ils ont une raison"* — the brief says what they
  lack is *not* courage but a reason. Inverted again.
- *"Je peux faire la pluie"* — *arrange bad weather* is what Til calls sinking a
  cargo. Read literally it is weather magic.
- *"J'ai tué 381 hommes en 11 ans"* — the works killed them. Halgrave keeps the
  count. Every figure correct, the agent wrong.

The door checks figures, names, formatting and register, and all four of those lines
are clean on all four counts. **A fact check that only understands numbers cannot see
a sentence that says the opposite of what it was told**, and roughly half the briefs
carry no figures at all. Nothing should be generated into the game until this is
answered, and it is the open question this phase now turns on.

### Shrinking the job does not shrink the problem (2026-09-12)

The obvious repair for "the model gets meaning wrong and nothing catches it" is to
give it less meaning to get wrong. So: the model writes **only the opening reaction**
— one sentence under 14 words, no figures, no names, saying what this person will or
will not give you — and the hand-written line supplies every fact, unchanged. A model
that never states a fact cannot state one backwards. Everything left is checkable to
the last rule, and `ProseRules.opener_faults` checks it.

It works exactly as designed and it fails anyway.

| | |
|---|---|
| Through the door | **94%** |
| Actually right | **about 20%** |
| Speed | 0.5 s |

Five of the six openers written for a character who **likes** the player refused to
help them: *"Je ne vous aiderai pas"*, *"Je ne vous aide pas"*. One sentence, plain
French, no figure, no invented name — clean on every rule there is, and the opposite
of what the packet said.

**The pass rate went up as the lines got worse.** That is the finding, and it is a
worse result than the 81% that preceded it: a measurement that reads *ready* while
the output is inverted is more dangerous than one that reads *broken*. The meaning
problem did not shrink with the job. It only got harder to see.

**What this settles.** The value generation was for is real and was measured — the
divergence between worlds is 50% where the player has acted and 74% where they have
not, and all of it lives in the opener. But the opener is one sentence chosen from a
small set of stances, and something small enough for a 4B model to get backwards is
small enough to write by hand. Generation stays built, tested and switched off.

### Reactions: what replaced the model (built 2026-09-12)

Every answer in this game is fixed. Ask Halgrave how many men the works has killed
and the sentence is identical whether he trusts you, has never met you, or watched
you take something off a stall. That is the 50%-against-74% divergence measured
during the generation experiment, and **all of it lives in the first sentence.**

So the first sentence is written by hand. A `reactions` block in the cast sheets,
beside the `dispositions` block — which is the *narrated* version of the same idea
and belongs to the greeting, where this one is **spoken** and belongs to the answer.

| Standing | Halgrave, asked what the works makes |
|---|---|
| unknown | *Du fer et de l'acier. Des rails, des plaques…* |
| unwelcome | **Je ne cache rien, même à vous.** *Du fer et de l'acier…* |
| welcome | **Alors je vous donne tout le détail.** *Du fer et de l'acier…* |

**Four rules, three of them learned rather than chosen.**

1. **It says what they will or will not give you. Never what they think of you.**
   Settled by ear: *"À vous, je peux le dire"* was chosen and *"Vous, vous regardez
   les fours au lieu de regarder ailleurs"* rejected, by the same reader in one
   sitting. One is a change in what is on offer; the other is a remark.
2. **Once per conversation, on the first answer.** A man who says *"vous payez
   d'avance"* to all three questions is a machine with a stuck key. Leaving and
   coming back acknowledges it again, because the thread is the conversation and the
   standing is the relationship.
3. **One line per person per band, not per question** — so it has to work in front of
   *every* answer that person has. Halgrave's first draft was *"Vous aurez le chiffre
   quand même"*, which fits *how many men has it killed* and not *what do you make
   here*. Caught by reading all three side by side, and not checkable by machine:
   the note lives in the cast files where the next line will be written.
4. **A neutral standing gets nothing**, so every line the game already shipped is
   untouched and nothing regresses. `hated` gets nothing either — at that standing
   there is no conversation at all.

**Size: 3 shared bands and 9 people with their own, 21 lines a language.** Held by
`test/test_reactions.gd`, including the one real risk in joining two written things —
that French runs long and the pair overflows the box — checked against every
combination that can actually occur rather than against a worst case that pairs a
long reply with an opener that person never says.

### What the world can say about itself in v2 (2026-09-13)

§8's rule stands — *content names a condition, the rules layer defines it* — and v2
adds the conditions its new state produces. Content may name these, and `core/rules/`
decides what each means:

| Condition | About | Reads |
|---|---|---|
| `this_place_is_free` / `this_place_is_crown_held` | The place the speaker stands in (§8's state) | A worker at cold furnaces has a different answer from one at lit ones |
| `<place>_is_free` | Any of the four, from anywhere | Maddox can mention that the Acres went to the smallholders, three days after they did |
| `hardship_is_high_here` | The speaker's town (§8) | The loyal-and-hungry line, which is the whole of the Wide Acres |
| `crown_rank_is_at_least_N` | The player's crown standing, read as rank (§11) | Greeting, offers, assumptions, what is told — never a gate |
| `blackcairn_is_unstable` / `blackcairn_is_rich` | The castle's two readings (§4) | The second channel for both readings: what towns say about the castle |

A conditional line outranks a standing one, as before, so each of these takes its slot
the day it applies. None of them gates a fact: invariant 6's `costs: "free"` source
still exists for every fact whatever the state or the rank.

**Travellers are never conversational, never named, never part of the twenty-five.**
Kept in v2 by decision (§20): they are how rumour physically travels between towns,
and removing them would remove rumour propagation, the point of the Thornwood and the
reason MAP_SPEC's road ratio exists. They have no sheet, no voice note and no line,
and nothing in this section applies to them. If they read as fake, that is a
presentation problem for §13 — draw them as traffic — and never a reason to give them
words.

### Determinism rules

- The model never decides a mechanical outcome. The rules layer issues the verdict;
  the model phrases it and proposes the player's options.
- All model output is constrained to a schema. Anything with a mechanical effect is
  an enum of identifiers that already exist.
- Responses are cached against the context packet hash: same situation, same words.
- Dialogue is generated **offline and reviewed** wherever possible, and shipped as
  reviewed content.
  > Commercially relevant: pre-generated, human-reviewed content is a lighter
  > disclosure category on Steam than live generation.

---

## 10. Combat

**Where it happens.** Never in the overworld. Any fight transitions to a dedicated
combat screen, in the manner of *Pokémon* or a classic *Final Fantasy*.

**The combat screen.** Side-on 2D. Player on the right, one or more opponents on the
left.

**The genre.** A real-time fighting game — *Dragon Ball Budokai*, *Street Fighter* —
not turn-based. Movement, blocking, timing.

**Version 1 scope:** brutally simple. Light attack, heavy attack, block, dodge, one
special. Equipment modifies reach, speed and damage on both sides.

### Everyone is fightable, and the fight tells you who they are 🟡

Every NPC can be fought, and the difficulty comes from what they do for a living. An
NPC's occupation determines their loadout and threat tier, as data, so the roster
never needs hand-balancing:

| Tier | Who | What they bring | Feel |
|---|---|---|---|
| 0 | A milk seller, a scribe, an elderly weaver, a servant | Nothing | Over in one hit. It should feel bad |
| 1 | Farmer, miner, smith's apprentice | A tool — pitchfork, pick, hammer | Clumsy but it hurts |
| 2 | Hunter, caravan guard, foreman | A real weapon, some training | A fight |
| 3 | Soldier, town guard | Weapon, armour, discipline | Loses to a prepared player |
| 4 | Officer, knight, lord | Everything, plus reach | A set piece |
| 5 | The king | 1000 HP, escort, phases | The point |

> Tier 0 exists on purpose. If murdering a defenceless person is mechanically
> trivial and socially expensive, the game has said something without a cutscene.

**Hard rule: there are no children in this game.** No child characters exist in the
world — not as combatants, not as NPCs, not as scenery. This is not a targeting
restriction to be worked around; they are simply not part of the cast. Any content
that would imply harm to a child is out of scope, permanently.

**Experience.** Kills grant XP scaled by the opponent's tier, so a milk seller is
worth approximately nothing and the optimal strategy is never "kill everyone."
Quests, discovered facts and damaged pillars also grant XP, so a pacifist run
progresses at a comparable rate.
> Violence carries **no karma meter and no progression gate** — nothing is withheld
> from a violent player that a peaceful one is given, and no counter silently marks
> them down. It is punished *socially*: a witnessed kill moves reputation, notoriety
> and the rumour tick, poisons every NPC socially linked to the victim, and thickens
> the patrols. **That last one is mechanical and is meant to be** (amended
> 2026-09-11, §19 Q7): the world reacting is the punishment, and a world that
> noticed nothing would not be one.

**Numbers.** Player starts at 10 HP. Levelling raises health and attributes.
Equipment carries at least as much of the player's power as levels do.
> TBD: the actual curve. Target endgame player HP, and damage scaling.

**Magic** — **there is none for the player** (2026-09-12). The raising is the one
miracle in the game, it lives in the forest, and it happened *to* the player before
the first frame rather than being something they perform. Attunement buys the ability
to notice magic, never to cast it. Nothing the player does in a fight is magical.

**Death of the player:** TBD

**The king fight:** phases and tells, with knowledge from the Muster changing what the
player can read. TBD in detail.

---

## 11. Progression

**Character creation** follows *Fallout*'s logic: a fixed pool of points allocated
across traits at the start.

### The six traits 🟡

Six rather than seven, each doing double duty — dialogue and combat — so no point is
ever wasted:

| Trait | Dialogue | Combat |
|---|---|---|
| **Wits** | Deduction, spotting lies, analytical options, reading documents | Reading tells, counter windows |
| **Presence** | Command, charm, authority; the Route B (Access) trait | Intimidation; can end some fights without violence |
| **Temper** | Accusation, threat, fury; the emotional register, not an ability | Higher damage, less control — a real trade-off |
| **Hands** | Craft knowledge — how the works, the farms and the ledgers actually function | Speed, blocking, precision |
| **Body** | Physical presence in a room | Health, stamina, carrying |
| **Attunement** | The forest's register: you can read what is dying and who is doing it, and some people only speak to somebody who can | **The wood does not slow you** (2026-09-13): at 3 or more the Thornwood's speed penalty does not apply, or applies less — a cost you do not pay, rather than damage you deal |

**Point-buy:** each trait starts at 1, with a pool of **10** to distribute; maximum
**5** at creation (settled 2026-09-13, closing §19 Q6 and Q22).

> Q22's complaint was right: **no pool size forces a count, only a cap does.** At 4
> points to take a trait from 1 to 5, twelve buys *three* maxed traits and leaves
> three at the floor, which is a shopping list rather than a choice. Ten buys two at
> 5 with two spare, or one at 5 and two at 3, or a flat spread of mediocrity — and
> each of those is a different person to play.

**`tag` gates now.** It was always meant to be the visibly trait-gated marker Fallout
uses and was display-only because traits did not exist. A line leans on a trait at
**3 or more** — one threshold for all six, because six numbers would be six things
nobody had reasoned about, and 3 means "you put points here".

> **This is not the progression check invariant 4 forbids.** Traits are chosen once
> and never rise (§19 Q23), so nothing opens because you did the previous thing; it
> is the same kind of gate as being unwelcome in a town. What keeps it legal is
> invariant 6 — **redundancy counts a trait gate as a gate**, so no fact can sit
> behind one, and a character made at the floor of all six can still finish the game.

**Why this list.** *Temper* is a disposition rather than an ability, which is what
makes it interesting: it opens doors that *Presence* closes, and vice versa.
*Attunement* was described here as how magic stays rare without a fiat rule, and
that was a systemic dodge for a question the fiction now answers: magic is rare
because the king has been killing it (§5). **Rewritten 2026-09-12.** It is not a
spell list and never was one — there is no player magic, because the raising is the
one miracle and it happened to the player rather than being performed by them.
Attunement is the ability to *notice* it: what the clearing is doing, what is in the
wood, and what the people pushed into it will say to somebody who can tell.

Its second half is the same sensitivity pointed at the ground: **the wood does not
slow you** (Yannick, 2026-09-13, closing Q50). v1 had *the wild stops treating you as
prey* — fights you never have — and the beasts went with v2 (§4), so the price of the
wild is now time, and an attuned character does not pay all of it: at Attunement 3 or
more — the one threshold every tag uses — the Thornwood's speed penalty does not
apply, or applies less: **0.80 in the wood, a worked field's pace** (measured
2026-09-13, `MovementRules.ATTUNED_WOOD_MULTIPLIER`). On the shipped map the shortcut
holds 29 tiles of wood, so the trait buys about 3 s of a 69 s crossing — real, small,
and it grows with the forest, which is the deferred map question (Q42/Q43).
The precedent is still *Presence*, whose second use is ending fights without violence:
a trait's second half is a cost you do not pay, not damage you deal. And it makes the
two social traits the map's two sides: **Presence is the road build** (the Access
route, papers, being seen and being let in) and **Attunement is the forest build**
(unwatched, unslowed, and able to hear the half of the region the king is clearing).
§4's thesis, bought at character creation.

> **Still open, and downstream of Q42/Q43**: *who* only speaks to somebody attuned.
> The forest has no people in it yet, so the dialogue half of this trait currently
> has nobody to talk to. That is the deferred map question, not a hole in the trait. *Hands* exists so a player can be technically literate
about the king's industry, which Route C needs.

**What levelling raises:** health and attributes. XP from kills (tier-scaled),
quests, discovered facts, and damaged pillars.

**What the player accumulates besides levels:** knowledge, reputation, equipment,
allies, recovered memory.

### Rank — derived, never gating (2026-09-13)

`FactionRules` already has four crown ranks read off service — at 0, 25, 60 and 110 —
and its own comment says *"the crown's last rank is the castle door."* That is the
design. It is written down here and extended; nothing new is invented.

**Rank is derived, exactly as the escort is derived from army strength.** Nothing
stores "you are a Baron". The title is what the court calls somebody at a given
**crown standing** — the faction standing that already exists (§8) — and it is
recomputed from that number every time it is asked for. It therefore **falls as well
as rises**: burn the crown's granary and the court stops using the title, because the
number it was read from went down. A rank that can only climb is a ratchet, and a
court that kept calling a man Baron after he burned its stores would be storing
something.

| Rank | Crown standing | What changes |
|---|---|---|
| 0 | 0 | Nobody. The everyday greeting; the gate turns you away; nothing assumed |
| 1 | 25 | Known to the crown's people. Greeted as someone; offered what a stranger is not |
| 2 | 60 | Trusted. What people will *tell* you changes — the crown's side of a thing, said openly |
| 3 | 110 | **The castle door.** The guard knows your face and the gate opens without papers |

The thresholds are v1's and stay. The words are content — `rank.crown.0` to
`rank.crown.3`, written French first — and "Baron" in this document is a placeholder,
not a title.

**What rank changes.** How you are greeted, what is offered, what is assumed, and what
people will tell you — all of it through §9's existing machinery: the rank is a
**condition content may name**, the way `grain_is_dear_here` is, and the rules layer
decides what the name means. A conditional line outranks a standing one, so a rank
line takes its slot the day it applies.

**It never gates.** Invariant 4 is absolute here. At high standing the gate at
Blackcairn opens because the guard knows your face; at low standing you climb the wall
— the culvert, the cliff path, Hesper's papers (§4's three ways in). **Same
destination, different route.** Rank is one more way through a door that already had
others, and it is never the only one. A test asserts that every place a rank opens
has at least one way in that reads no rank at all.

**High crown standing never removes the other endings** (invariant 7). A player loyal
all game can still turn at the end — read the ledger aloud, empty the vault, depose
the man who knighted them. That last case is §3's throne reading: Deposed, with the
handprint, at the crown's last rank. Rank is what makes taking the throne
*expressible*; it is not what makes it happen.

**The crown's service is a real list now.** v1 had two acts that served the crown —
`i_gave_it_back` and `i_informed_the_crown` — against eleven that served the
opposition, and `FactionRules.WORTH` says so in its own comment. In step with §8's
second direction, every act in the "builds it by" column is crown service: the grants
enforced, the convoys moving, labour delivered, the wage dispute settled, the forest
fed to the works, the Muster paid and fed, deserters handed back, confidence restored,
the creditors brought in. Each is a deed row with a face (§8), and each is worth
standing with the crown as the opposition's acts are worth standing with the
dispossessed. Worths are tuning and live in the table, not here.

**The opposition's ladder is unchanged.** Four ranks, same thresholds, and its last
rank is still a room to read in rather than a door — the shape v1 gave it in §8.

> **What was rejected.** A stored rank, awarded by an event — invariant 4, a
> progression flag by another name, and a second number that could disagree with the
> standing it was meant to summarise. Reading rank off the **service tally**
> (`Allegiance.served`) as v1's code does — it only ever rises, so a man who served
> the crown for a week and then burned its granary would still be its Baron; standing
> moves both ways and is the number the court would actually be reading. Letting the
> last rank *be* the way in — the gate opening only at rank 3 is a gate, and the
> culvert and cliff path exist so that it is never the only one. A fifth rank above
> the castle door — there is nothing above the door but the throne, and the throne is
> a reading (§3), not a rank.

---

## 12. Economy & items

**Currency:** gold. The king's is in the bank — one of the six pillars.

**Equipment matters mechanically in combat**, for the player and the opponent, and
is visible to NPCs (feeding appearance, §8).

Everything else: TBD.

---

## 13. Art direction

**Target look:** *The Legend of Zelda: Echoes of Wisdom*.

**Starting point:** *A Link to the Past* — top-down, grid-based, readable.

**Camera:** top-down in the overworld; side-on for the combat screen. Two visual
registers, deliberately.

**Polish is a version-1 requirement, not a version-3 one.** The first playable
version has to be pleasant enough that Yannick wants to play it.

**Asset sourcing rule (hard).** The agent may use free assets, but only from an
**approved list of one or two packs** recorded in this document. Assets from
different artists are never mixed: different palettes, pixel densities and light
angles do not reconcile, and mixing packs is the most recognisable mark of an
amateur-looking game. A validator rejects any asset that is off-palette or off-grid.

### Invariant 10 is enforced by the machine (2026-09-11)

The approved pack shipped `Child/`, `EggBoy/`, `EggGirl/` and `LionBoy/` sprite
folders. **All four are deleted from `assets/`**, and the validator now fails the
build if any of them reappears or if any source file names one.

CLAUDE.md invariant 10 is absolute and permanent — "no child characters, in any
role, ever" — and the palette check cannot see it, because a child sprite from the
approved pack is perfectly on-palette. A rule that depends on remembering is a rule
that fails the first time somebody is tired. Matched as path segments
(`Character/Child`, not `Child`) so that `get_child()` does not trip it: a denylist
that cries wolf gets switched off.

### One face each, and one kit per place (2026-09-13)

Two rules about *identity*, added after playing: "each town and village needs its
own identity, same for specific characters."

**Nobody in the cast shares a face.** Twenty-nine roles shared eighteen sprite
sheets, so Bell, Sena and Mira were the same woman standing in three towns, and the
bank and the estate were run by the same man in a hat. The pack ships 94 character
sheets, most of them ninjas and robots; what is left that can stand in a kingdom is
about thirty, which is exactly enough. `Art.CASTING` is now one-to-one and a test
fails if two roles are cast the same. When the cast grows past thirty this test is
what will say so.

**No two settlements are built out of the same kit.** `Region.BUILDINGS_AT` gives
each place the kinds of building it puts up, `Region.SCENERY_AT` what it leaves
lying in the street, and `Art.TOWN_GROUND` the floor underfoot. A test refuses two
places the same kit. What each says about itself:

| | Built of | In the street |
|---|---|---|
| **Harrowgate** | houses, shops, a workshop, an inn | a well, market produce, barrels |
| **Cairnwell** | stone houses, shops, and the bank, the tallest thing in Erileo | a well, crates |
| **Cinderworks** | workshops round four furnaces | log piles, a bread oven |
| **Wide Acres** | a farmhouse and a barn, four times, in fields that are left alone | fences, crates |
| **Saltmarch** | stone on planks over the marsh, and boats | crates, barrels |
| **Blackcairn** | a keep against the north wall, four towers, a gate | crates, a well |
| **Brindle** | what is left of it | — |
| **the Muster** | tents, in rows | — |

**A settlement's ground is a ragged ellipse, never a rectangle.** A straight edge is
a town somebody laid out with a ruler and nobody has ever walked on. The fray may
only eat ground the town could sit beside — grass, field, marsh — because skipping
whatever it landed on left a corner of the Thornwood's thicket standing inside the
Muster, impassable, with a watchman posted in it.

### Two ground states × four places, and the castle's two faces (2026-09-13)

§4 says what is on the ground in each state; this says what is drawn. **One kit per
place still holds** — a free Wide Acres is built from the Wide Acres' kit with things
missing and things moved, not from another place's. The free variant of each place is
one authored arrangement, and the test that refuses two places the same kit also
refuses a place a third variant.

| | Crown-held (v1, as built) | Free (v2, new) |
|---|---|---|
| **Wide Acres** | Farmhouse and barn ×4 in fenced fields; the granary row with a watchman | Fences gone; fields cut smaller; the granary door open and no watchman; no carts on the road leg |
| **Cinderworks** | Four furnaces lit, smoke, the cleared ring | Furnaces unlit — the same sprites with the fire frames off; smoke gone; the cleared ring stopped |
| **Muster** | Tents in rows; the pay tent with its queue | Half the tent rows gone; the pay tent shut; the crowd figures the Muster lost stand in Harrowgate (§6) |
| **The bank** | The counting house open, the tallest thing in Erileo | Shutters on the counting house; different men at its door |

**Blackcairn's two readings are drawn on the castle** (§4): wealth as scaffolding and
new stone against the north wall, or shuttered works and an unfinished course;
instability as banners down, more guards on the wall, the gate shut in daylight. Each
is a handful of props toggled by a reading, on the same rule as the Muster's tents —
drawn from the number, never stored on a node.

**The Thornwood belt** is the cleared ring's radius, already drawn by
`Terrain.CLEARED`. Widening it is a number, not new art.

**Travellers are drawn as traffic, not as characters.** They are kept (§9) and they
are furniture. If they read as fake it is a presentation problem, and the answer is to
draw them as what they are — a cart, a pair at a distance, somebody leaving a gate —
never to give them a face from the cast's thirty or a routine that makes them look
like people with somewhere to be. **Built 2026-09-13**: a pack horse, from the pack's `Animal/Horse` side sheet, flipped for the direction of travel — and looked at with `tools/shot.sh` before it was called done.

### Approved asset pack (settled) — exactly one

| | |
|---|---|
| **Pack** | Ninja Adventure Asset Pack |
| **Authors** | Pixel-boy and AAA |
| **Licence** | **CC0 1.0 Universal** — commercial use permitted, modification permitted, attribution appreciated but not required |
| **Source** | <https://pixel-boy.itch.io/ninja-adventure-asset-pack> |
| **Vendored at** | `assets/NinjaAdventure/`, downloaded 2026-09-10 |
| **Licence evidence** | `assets/NinjaAdventure/LICENCE-as-downloaded.md`, alongside the pack's own `LICENSE.txt` and `README.md` |

The pack ships its own full CC0 text and an explicit statement from the authors,
which is why it was accepted: the licence travels with the files rather than living
on a store page that can change.

> **Do not source this pack from GitHub.** The mirror at `pixel-boy/NinjaAdventure`
> carries no licence file and no stated terms — checked 2026-09-10. Absence of a
> licence is not permission. See the licence-evidence file for the full check.

**One pack, and swapping it is an edit to this table.** No asset by any other
artist may enter `assets/` while this entry stands. Adding a second artist means
**replacing** the entry above, not appending to it, and re-extracting the palette
below from whatever replaces it. That is deliberately awkward: the rule exists
because mixing packs is the most recognisable mark of an amateur game, and it
happens one borrowed sprite at a time, never as a decision anyone announces.

Credit the authors in the shipped game regardless. CC0 does not require it; we do
it anyway, and it costs a line.

**Resolution & pixel grid (settled):** internal resolution **640 × 360**, **16 px**
tiles.

**Character height (settled):** **16 px** — the pack's characters are 16 × 16
frames, so a character occupies exactly one tile. Sprite sheets are 64 × 112, laid
out 4 columns × 7 rows of those frames. Within the frame the figure is
bottom-aligned and 13–16 px tall, most commonly 15. Dialogue portraits ("facesets")
are 38 × 38 and are *not* on the tile grid, by the pack's design.

360 is non-negotiable — it scales ×2 to 720p and ×3 to 1080p, and integer scaling
matters more than the half tile left over at the viewport edge (360 ÷ 16 = 22.5).
Because the camera scrolls and follows the player, tiles-per-screen is a planning
number rather than a constraint, so nothing has to divide evenly. If snapped
interiors are wanted later, rooms are 40 × 22 tiles centred, with a 4 px letterbox.

### Palette (locked) — 340 colours

The palette is **`content/palette.txt`**: 340 colours, extracted from every opaque
pixel of the 1899 art PNGs in the approved pack.

**No colour in it was invented, and none may be.** The pack's palette *is* the
palette — that is the whole rule. The file is generated, not authored: the only
legitimate way to change it is to replace the approved pack above and re-extract.

Two things the extraction deliberately excludes, both worth knowing:

- **The 16 `*Preview*.png` contact sheets.** These are scaled marketing composites
  — the itch.io store images — and their resampling invents 193 blended colours
  that appear in no actual art file. Including them would have locked a 533-colour
  palette, 193 of which are artefacts of image scaling rather than choices anyone
  made. They are skipped by the validator for the same reason.
- **Fully transparent pixels**, which have no colour to check.

340 is a large palette for pixel art because this is a large pack with several
sub-themes, not a single 32-colour ramp. That is a fact about the pack rather than
a decision, and it is recorded rather than tidied. If a tighter palette is wanted
later, that is a new pack, not a new spreadsheet.

### What the pack is used for (Phase 2)

Ground comes from `TilesetFloor`, `TilesetFloorB`, `TilesetWater` and `TilesetField`
(crop rows, which is what tells a field from a lawn at a glance). Landmarks come
from `TilesetHouse` (the counting house in Cairnwell, the kilns at the
Cinderworks), `tileset_camp` (the Muster's tents), `TilesetVillageAbandoned`
(Brindle's ruins) and `Vehicles/Boat` (Saltmarch). Trees, bushes and boulders come
from `TilesetNature`.

**Landmarks are solid; scatter is not.** A building is an obstacle you walk around
— §4's towns get "walkable exteriors" — and its footprint is recorded in `core/` so
a test can assert every zone has one. Trees and rocks are decided per tile from a
hash of its coordinates rather than stored, so a wood can be dense without the
world holding a hundred thousand objects, and they are **deliberately walk-through**:
a forest you cannot cross is a maze, and the Thornwood's cost is meant to be time
and blood, not navigation. Revisit that if the wood ever needs to funnel movement.

### The validator

`tools/asset_validator.gd`, wired into the test suite as `test/test_assets.gd` and
runnable on its own with `godot --headless --path . -s tools/validate_assets.gd`.
It fails the build if any image in `assets/` uses a colour outside the locked
palette, or if a tile source is off the 16 px grid.

**The approved pack is the palette source, so it passes by construction.** That is
not a weakness in the check — it is the point. The validator exists for what gets
added *later*: the sprite borrowed from another artist in six months, which is
exactly when nobody is looking. It has its own negative tests, because a validator
that has never rejected anything is not known to work.

#### What it catches, and what it does not

340 colours is a **loose net**, and a later reader should not trust it further
than it goes.

**It catches:** another artist's pack dropped into `assets/` wholesale. Two
independently-authored pixel-art packs essentially never share a palette, so a
foreign pack fails on its first file. That is the failure this rule was written
for, because it is the one that happens by accident.

**It does not catch:**

- **A single asset tweaked or generated to sit inside the palette.** Recolour
  anything to the nearest of 340 pack colours — by hand, by a tool, by a model —
  and it passes silently. The net is wide enough to walk through on purpose.
- **Anything about style.** Pixel density, outline convention, light angle,
  dithering, shading ramp, the number of colours *per sprite* — §13's actual
  reasons for one-pack discipline — are invisible to it. A 32 px-detail sprite
  squeezed onto a 16 px tile passes every check here and still looks wrong.
- **Off-grid free-standing sprites**, by design: the grid rule binds tile sources
  only, for the reason below.
- **Anything not a PNG**, and anything outside `assets/`.

So: this validator is a tripwire against the accident, not a guarantee of
coherence. It cannot tell you the art is right — only that it is not obviously
from somewhere else. **Only a person looking at the screen catches the rest**, and
nothing here removes that job.

Two scoping facts, stated rather than buried:

- **The 16 px grid is checked for tile sources only** — currently
  `Backgrounds/Tilesets/`. Free-standing sprites are not laid on the grid and the
  approved pack does not pretend otherwise: 812 of its 1899 art files are not
  multiples of 16, because a 38 × 38 portrait or a 13 × 13 UI arrow has no reason
  to be. A blanket grid rule would reject the approved pack itself.
- **One recorded exception:** `TilesetFloor.png` is 352 × 417 — one pixel taller
  than 26 tiles. A flaw in the pack, not in the project. The validator prints every
  exception on every run so that the list cannot quietly grow.

### The pack and the palette are locked for v2; v3 replaces both (2026-09-13)

**v2 changes what the world means; v3 changes what it looks like.** They are kept
apart on purpose: an art swap during a systems rewrite makes every visual bug
ambiguous between the two. So for v2, Ninja Adventure is the pack and the 340 colours
are the palette, and every new thing v2 draws — the free variants, the castle's two
faces, the entrance signs — comes out of that pack or is not drawn.

A real graphics jump is a wall rather than a download, and the wall is the four rules
above: one approved pack, a locked palette extracted from it, the validator enforcing
both by test, and one kit per place with one face each. **The validator is what makes
a replacement safe, not what blocks it** — a new pack that covers all four places, the
castle and thirty faces goes in by replacing the table above and re-extracting the
palette, and the suite says immediately what it does not cover. Licence matters as
much as looks: CC0, or a licence that survives a Steam release, checked before
anything is drawn against it.

**Path to the final look:** placeholder → approved pack (v1, v2) → a new pack or
commissioned art (v3), through the validator.

---

## 14. Audio

Settled 2026-09-13. Everything comes out of the approved pack (§13), which shipped 41
tracks, nine ambient loops and a folder of menu noises — **the same never-mix rule as
the art**, and for the same reason: a score from one artist under tiles from another
is audible immediately even to people who could not say why.

**Three layers, and each is a table in `view/sound.gd`.**

| | |
|---|---|
| **Music** | one track for where you are. `MUSIC_AT` by zone, `MUSIC_ON` by terrain when you are in none, and the travelling track for everywhere else |
| **Ambience** | one loop under it, by terrain: wind in the wood, water at the river and the marsh, waves at the coast. A town is silent underneath, because a town has the music |
| **Cues** | one-shots named by *what happened* — `cue(&"refused")`, `cue(&"seen")` — so a caller never learns which file that is |

**The map's argument is audible.** §4 says the road and the forest are two worlds; the
score does not share a single track between them. The clearing has its own music, the
Thornwood has its own, and the ground the Cinderworks has already taken plays a
lament — the one piece of the map that is nothing but a loss, said before it is
explained.

**Two rules that stop it becoming noise.** A track crossfades over 1.4 seconds, and a
track holds the floor for at least six — without the second, walking the line between
the wood and the road turns the score into a stutter. And the music sits well under
the cues on purpose: this game is read, and a score that competes with the dialogue
box is a score somebody switches off.

**Sound can be switched off**, from the title screen and the pause menu, and the
choice is kept in `user://settings.cfg` beside the language. Muting does not stop the
music, it silences it, so unmuting picks the place up rather than starting the track
again.

There is one `Sound` node, installed by `screens.gd` under the root and never
replaced, so walking out of a town does not restart anything and neither does opening
the pause menu. It is reached through a static façade that answers null when there is
no tree to speak into — which is what makes the headless suite silent instead of
broken.

**Not built, on purpose:** per-bus volume sliders, footsteps, and any sound for
combat, which does not exist yet (§10).

---

## 15. UI & UX

**Screens:** title, character creation, overworld HUD, dialogue, journal/knowledge,
map, inventory, combat, pause.

### The journal — the only screen that answers "why" (2026-09-11)

**The journal / knowledge screen** is the most important screen in this game — it is
where the player's real progression is visible.

It is §8's third register. IMMEDIATE is the act confirmed as you do it; AMBIENT is
the world quietly changing its mind; **NARRATED is this**, and it is the only thing
in the game permitted to join an act to its consequence. Most systemic games ship
the first two, which is why their players never feel their choices mattered.

**Behind a key (`J`), never a notification.** The world does not announce that you
caused something — Maddox not knowing it was you is the entire pleasure of it — so
the causal chain is *pulled*. A rumour arriving reads:

> `day 3, 19:31   Cairnwell has heard about it.`
> `               3 days after you took something, in Harrowgate.`

The first line is the ambient register written down. The second line exists nowhere
else in the game.

**Read from the event log and nothing else.** This is what the external/derived
split was paid for: `submit()` is what the player did, `derive()` is a system's
answer, both are logged, and the journal reconstructs the chain from them. A test
walks to the market, steals, waits, replays the run from its log alone and asserts
the journal is word for word identical — which is the proof that the log really is
the authoritative record and a save file can be a log rather than a snapshot.

**It never scores you.** No numbers, no standing, no "+22", no "your actions caused".
A test forbids the vocabulary. It explains; it does not accuse.

**A second page: what holds him up.** The ending is a predicate over ten or so
numbers, and a predicate is invisible — without this page the player cannot aim, and
"push the world until he cannot hold it" becomes guesswork. So the journal lists the
quantities that decide it, where each stands, and **which of them carry the player's
handprint**. It shows state and attribution, never advice: it will say the treasury
is low and that you emptied it, and never that you should rob the bank next.

> The handprint column is the guardrail made visible. A number the world drifted to
> reads differently from one you pushed, and the player can see at a glance how much
> of this is theirs — which is the same fact the end conditions are checking.

**The other half is what you know**, with who told you — and which facts only one
person has ever told you. That makes invariant 6 the player's problem as well as the
designer's: the journal is where you find out that the thing you know would die with
the woman who said it.

### The journal gains the kingdom's state (2026-09-13)

The thesis says the ending is a reading of what the kingdom became; the journal is
where the player reads it before the end. One more page, pulled like the others and
never pushed:

- **Each of the four places**: its state — crown-held or free — and, if the player set
  it, when, in the same voice as the rumour lines: *day 9, 06:12 — the Wide Acres went
  to the smallholders. You read them the grants.* If the band moved it, the second line
  says *it turned*, and nothing about you.
- **Hardship, per town**, in words rather than figures — the same discipline the HUD
  uses for standing — and beside it *whose doing*, exactly as the second page shows the
  handprint.
- **Blackcairn's two readings**, in words: what the walls look like, what the gate is
  doing.

It still never scores. The vocabulary test that forbids "+22" and "reputation" covers
this page too. It explains what the kingdom is and how much of it is yours; it never
says what to do about it.

### The overworld HUD tells you how you are regarded, never what you did (2026-09-11)

§8 requires all three feedback registers, and the HUD carries two of them. What it
must never carry is the third.

**Standing is shown as a word, for the place you are standing in.** The place line
reads `Harrowgate — wary`. Walk west and it reads `Cairnwell — unknown`, and three
days later that changes on its own while you watch. The scale is five words, worst
to best:

> hated · unwelcome · wary · unknown · welcome

Shown from the first minute, neutral included: a baseline is what makes a change
legible, and a readout that appears only once something has gone wrong gives the
player nothing to compare against.

**Three things it deliberately is not.**

*Not global.* One meter for the whole region says the world has one mind, and
per-town standing is the entire proof of §8's first consequence — Cairnwell refusing
you while Saltmarch has not heard.

*Not a number.* A visible scalar with legible increments stops being a reputation
and becomes a score, and the player farms it instead of deciding things. Red Dead
Redemption is the worked example in both directions: its crime-and-witness system is
close to what §8 specifies and is the part that works; its honour meter is global,
numeric and immediate, and is the part players game.

*Not moved at the moment of the act.* The readout changes when the story arrives,
which may be days after you left the town it is about. The delay is the consequence.

**Witnesses are marked over their heads, and only while an act is possible.** A mark
appears over anyone who can see you when there is something in front of you worth
taking. No count and no number: *who* is the part that matters — Maddox seeing you
is not the same event as a stranger seeing you — and the sight radius is learnt by
walking until the marks go out. A permanent readout of who can see you is
surveillance furniture; this answers a question the player is asking at that moment.

**The HUD never attributes.** It shows state, not causation. Nothing on it says
"your actions caused" anything, and nothing announces a change as it is made. The
journal is the only place that joins an act to its consequence, and the player has
to go and open it.

### The entrance sign is a voice, not a readout (2026-09-13)

Each of the four places, and Blackcairn, carries a sign or a speaker at its entrance
stating the place's status **in its own words** — a claim the player can doubt and
later find false. *"CornTown, proud to provide food to our lovely king"* is exactly the
register: it is propaganda, and propaganda is a fact about a place.

A status readout — `Wide Acres: crown-held` — would flatten discovery and break §8's
*push the ambient, pull the attribution*. The sign is the ambient register speaking:
the player reads it, walks in, and finds out whether it is true. So:

- A place that was **always loyal** boasts the way it always did.
- A place the player **strengthened** for the crown boasts *differently* — newer,
  louder, with a figure in it the player recognises, because they put it there.
- A **freed** place says something careful if the patrols still ride past, and
  something plainer once they stop.
- Blackcairn's gate says what a castle says about itself, and the wall behind it may
  disagree (§4's two readings).

Every sign is written **French first, then English**, in the house register (§9), and
a test asserts both exist for every place × state. The words are content
(`sign.<place>.<state>`); which one shows is the rules layer's verdict.

Everything else: TBD.

---

## 16. Accessibility & options

TBD.

---

## 17. Scope budget

| Thing | v1 shipped | v2 target | Notes |
|---|---|---|---|
| Region | 1 | 1 | Settled |
| Zones | 8 | 8 | Settled, §4. The Redcut and the Thornwood depths stay optional |
| Power bases | 6 named | **4 deep**, 2 deferred | The Cinderworks, the Wide Acres, the Muster, the bank. Greyhold and Harrowgate deferred, not cut (§3) |
| Place states | — | **2 × 4** | crown-held / free, never a third (§8) |
| Decisive changes | — | **4** | One per place, two outcomes each (§3) |
| Routes to the confrontation | 3 | 3 | Force / Access / Exposure — descriptions, not machinery |
| Endings | 5 | 5 | No sixth; the throne is a reading of one (§3) |
| Traits | 6 | 6 | Settled |
| World-tick quantities | 12 | 12 + **hardship per town** | The twelve untouched; hardship beside them (§8) |
| Crown ranks | 4 | 4 | Kept; derived from standing, never gating (§11) |
| Named NPCs | 25 | 25 | No new cast. The second direction is spoken by people who already exist |
| Facts / secrets | 32 | TBD | each needs ≥2 sources |
| Entrance signs | — | 4 places × 2 states, plus Blackcairn | A voice each, French first (§15) |
| Free-state ground variants | — | 4 | One per place, plus the Thornwood belt as a radius (§13) |
| Beasts | 3 | **0** | Cut 2026-09-13 (§21) |
| Enemy tiers | 6, unused | 6 | 0–5, occupation-driven; waits on combat |
| Combat moves | 0 | 0 | Combat stays out of v2 unless Yannick says otherwise (§18) |
| Playtime | TBD | TBD | |

**What gets cut first if behind, in v2** 🟡: Blackcairn's readings drawn on the castle
(keep the towns' talk about it, the cheaper channel); the free-state ground variants
(keep the entrance signs, which carry the state in words); the Thornwood belt widening
(keep `held_ground` falling faster, which is the number). **Never cut:** hardship, the
second direction's rows and their faces, the decisive acts, the freeze window, rank
never gating.

---

## 18. Roadmap

Eight phases, each with the proof that closes it. **A phase is done when its proof
is playable, not when its code is written** — which is why every one of them below
ends in something Yannick can sit down and do, rather than a list of systems.

The order has changed twice and the current order is the one that matters; see §20
for what moved and why.

**Phase 0 — vertical slice. ✅**
Brindle, a player who walks, the King's Road running north-west, Blackcairn at the
end of it, and a king who kills the player in three hits. Coloured rectangles.
> **Proof:** "I walk straight there and lose" is playable, and makes you want to
> try again differently.

**Phase 1 — Harrowgate alive. ✅**
The town on its own grid, entered from the road. The five NPCs §6 names, with
hand-written dialogue: three or four options, each mapping to a known intent, the
verdict issued by the rules layer. One fact worth learning and one consequence
that reaches the king — the pay fraud, and an escort of ten becoming five.
> **Proof:** a fact learned from a person changes a number the king depends on, and
> you can watch it change.

**Phase 2 — the world, greyboxed. ✅**
Every zone exists and is walkable, the terrain is real, the art is applied, and the
wild is dangerous — but nothing in it is finished. All eight zones from §4, each
recognisable on sight; every power base visible as a landmark and nothing more; the
Kettle, the bridge, the ford, the Thornwood, the mountains, the coast; the road and
its Saltmarch spur; real terrain speeds; animals that chase and hurt. No new NPCs,
no new dialogue, no interiors, no reputation, no combat screen.
> **Proof:** one run visits all eight zones and each is recognisable on sight
> alone; **the costs of both routes are measurable and legible** — the Thornwood is
> the short way and draws blood, the road is the long way and is safe; road travel
> from Brindle to Blackcairn can be timed by hand; and it looks like a game rather
> than a test harness.
>
> Note what this proof deliberately does *not* claim. The wild's whole payoff is
> being unwatched, and nothing watches yet, so in Phase 2 the wild is strictly the
> worse choice and is meant to be. Viability is Phase 3's proof, not this one.

**Phase 3 — the world reads you. ✅**
Reputation per town and per faction, not one global number. Witnesses that record
what they saw. Rumour propagating on a delay. The journal screen §15 calls the most
important in the game.

**The event debt is paid** (2026-09-11). `submit()` is external — what happened *to*
the world, logged and replayed. `derive()` is a system's answer — logged so a
journal can explain why something happened, and recomputed rather than replayed,
because re-injecting it would produce it twice. That is what lets systems react to
systems, which is the whole of consequence 2.

The five consequences in §8 are this phase's specification, and four of the five
need a structure the twelve tracked quantities do not have — standing indexed by
town, faction and person rather than global scalars. See §8.
> **Proof:** a killing witnessed in one town changes how a stranger in another town
> opens a conversation, and the journal tells you why — **and the wild becomes a
> real choice**, because the slow dangerous track through the trees is now the one
> nobody can report you on. Phase 2 builds the cost; this phase pays it.

**Delivered 2026-09-11**, in five stages: (1) the plumbing — stores, the two clocks,
the external/derived split; (2) systems answering systems — the army empties, bread
rises a week later, and nobody mentions the player; (3) witnesses, theft and rumour
as a travelling object, with per-town standing; (4) the positive acts that raise a
town, standing per person and per faction, and disposition as the default for every
conversation; (5) the journal.

Theft stands in for the witnessed killing — the same pipes, a permanent verb, and no
need to drag combat forward a phase (§20, 2026-09-11).

**The wild became a real choice on 2026-09-11**, with travellers. A story used to
spread as a circle of fixed radius, so it reached every town whichever way the player
walked and the road cost nothing. It now carries about as far as the next town on its
own, and any further than that has to be **carried by somebody who walked there**.
Stand where you can be seen after doing something and word goes wherever the road
goes; take the Thornwood and it never leaves the county. Both halves of the proof now
hold.

**Phase 4 — combat.** *(deferred by decision, 2026-09-11 — four of the five endings need no fighting)*

The dedicated side-on real-time screen (§10), the occupation-driven enemy tiers 0-5,
and the king fight with its phases and tells. Retires Phase 0's contact-damage
exception.
> **Proof:** the king is beatable by a prepared player and lethal to an unprepared
> one, and the same five moves carry both a tier-0 servant and a tier-4 knight.

**Phase 5 — the world can be moved, and the king can fall out of it. ✅**
*Reshaped 2026-09-11 — it used to read "the three routes, end to end".*
*Delivered 2026-09-12: all four items built and held by tests.*

Two of the twelve tracked quantities move; ten are inert, and dialogue is the only
input to the only one that matters. That is why the game had begun to feel like
matching people to states: **there was no other way in.** This phase gives the other
ten inputs — mostly **deeds against the power bases**, which §3 already lists and
which run on the machinery Phase 3 built — and expresses the ending as §3's
predicates rather than as three authored chains.

1. The handprint, and the end conditions as predicates (§3).
2. The journal's second page, so a predicate over ten numbers is something a player
   can aim at (§15).
3. The ten inert quantities get inputs. Burn stores, turn workers, cut ore, rob the
   bank, expose the debts — rows in the deed table, not new systems.
4. §7's reachability test restated: can the world still reach *any* ending?

> **Proof:** three runs finish the game three different ways without any of them
> following a script, the journal shows why each one worked, and a run that does
> nothing at all never ends — because drift cannot end a reign.

**Phase 6 — the full cast and deterministic dialogue. ✅ (cast and assembler)**
All 25 NPCs with sheets. The context assembler (§9) as a pure function over fixed,
ordered sources. Dialogue baked offline and reviewed; a runtime model only if
baking demonstrably cannot cover the packet space.
> **Proof:** the same situation produces the same words twice, and a stranger who
> has heard of you opens differently from one who has not.

**Delivered 2026-09-12**, in seven stages: (6a) the Cinderworks; (6b) the Wide
Acres; (6c) the Muster and the Thornwood; (6d) Saltmarch; (6e) Cairnwell, with Lord
Aurel Greyhold moved into it; (6f) Blackcairn — **Arthur** and Captain Dray; (6g) the
relationship web and §9's context assembler.

**Twenty-four named people, thirty-two facts, forty-two relationship edges**, every
line hand-written in French and English. Six of §3's levers are now things you
*say* rather than things you break.

**No model, on purpose.** The assembler is a pure function and the packet is worth
having without one: it is what a hand-written line chooses between, what a dialogue
cache would be keyed on, and the thing to *read* before deciding whether a model
should ever see it. `tools/packet.gd` prints one.

**And the decision is now taken: no model in v1** (2026-09-12). It was tested rather
than argued — two models, sixteen real packets, four prompt designs, on the machine
the game will run on. The spec's own condition was *"a runtime model only if baking
demonstrably cannot cover the packet space"*, and what the experiment found is worse
than that: the packet space is coverable, but **nothing cheap can tell a right line
from a line that says the exact opposite**. Reducing the model's job to one
fact-free sentence removed the unfixable failure by construction and it still got
the sign backwards 5 times in 6, at 94% through the door.

What replaces it is small and was measured, not guessed: the whole value sat in the
**opening reaction**, and that is written by hand — a `reactions` block beside the
`dispositions` block the cast sheets already carry, joined by `ProseRules.joined()`.
Under 30 lines a language.

Everything built for the model stays: the packet, the door, the phrasebook, the
`phrased` event path, and `tools/phrase.py`. It is inert, tested, and costs nothing
to keep. Re-running the whole experiment against a better small model later is one
command, and the door got materially stricter for having been pointed at real
generated text.

**Phase 7 — the opening, the map, factions, quests, character creation, the front of
the game, identity and audio. Delivered 2026-09-13.**
> **Proof:** Yannick wants to play it in front of someone else.

Three nights, in three parts. **2026-09-12**: the opening, the map, factions, polish
and the look — itemised below. **2026-09-13, after he played it**: the ocean bug, the
Thornwood closed with ways through it, campfires and beasts given reasons, Blackcairn
made a castle, a floor for every place, and the map screen. **2026-09-13, the five
that make it a game**: quests, character creation, a title screen, identity, audio.

Commissioned art replacing the approved pack and the accessibility pass §16 defers are
**not** in v1 and were never started. Audio was, out of the approved pack — see §14.

**Delivered 2026-09-12**, overnight, in five pieces — the running record, with every
decision taken without him in the room, is `docs/history/OVERNIGHT.md`:

1. **The opening.** The player wakes in the fairies' clearing, one corridor leads out
   to the ruins with the furnaces in the same frame, the ground the fairies hold is a
   number that falls as the furnaces run, she tells them seven things and is gone, the
   clearing is the first fire, and the journal says what became of the wood.
2. **The map.** All twelve of MAP_SPEC's criteria pass, and the thesis is on the
   ground: `Terrain.CLEARED`, the Cinderworks as a wound with a radius that stops four
   tiles short of the fairies.
3. **Factions**, above.
4. **Polish.** Collision walked as reachability, a test that every line the code asks
   for exists in both languages, and the fast suite 38% faster with no test cut.
5. **The look.** Canopy, animated water, occlusion fade, camera lead and embers.
   **Real 2D lighting is cut from v1.** Built and *not declared done* — that is
   Yannick's to judge, per MAP_SPEC §11.

**Combat is out of v1 or its very last step** (Yannick, 2026-09-12). Plan for four
endings and treat the fifth as the thing that happens only if everything else is
finished.

---

### v1 ends here

Phase 7 was the last of it. **The roadmap above is complete apart from Phase 4**, and
is kept as finished work: nothing in it is a plan any more. The v2 specification is now
in this document, dated 2026-09-13 throughout, and its roadmap is the next section.
The two largest things v1 left on the table, in the order they would change the game
most:

1. **Combat**, and with it the fifth ending and the standing exception that has
   outlived every phase since Phase 0.
2. **The other two ways into Blackcairn** — the culvert and the cliff path §4
   promises. Only the gate exists, which is why it stands open.

`docs/V1.md` lists the rest of what v1 does not have, plainly and in one place.

---

### v2 — the roadmap 🟡 (2026-09-13)

**v2 is a content and coupling change**, and it does not touch: the `core/` / `view/`
split and the event log; the twelve quantities as a set; the handprint rule;
standing's three indexes; quests as predicates; determinism; the twelve invariants;
French first. Everything below is rows, readings and words on machinery that exists.

Five phases, each with the proof that closes it, in the same rule as v1: **a phase is
done when its proof is playable, not when its code is written.** The order is a
proposal — Yannick's to change — and the reasoning for it is under the table.

| | Phase | What it builds | Proof |
|---|---|---|---|
| **A** ✅ | **The wild without teeth** — delivered 2026-09-13 | Beasts out of the whole map; `TERRAIN_SLOWS_YOU` on and open country retuned to 0.65 on the measurement; `Navigation` given the least-watched path and the wild line measured with it; travellers drawn as a pack horse; Attunement's speed half (§4, §11, §13) | **Held:** road 57 s, wild 69 s, attuned wild 66 s, no blood on any; two `SLOW` tests assert the three relationships. The instrument had measured a 42%-road line as "the wild" since Phase 2 and is fixed |
| **B** | **The second axis** | Hardship per town; the "builds it by" rows for every quantity, each with a face and a hardship push; the counterpart test extended to faces; §9's conditions (§8, §9) | Burn the stores and feed the works the forest in one run; the journal shows two towns worse off in two different ways, and a named person in each says so without naming you |
| **C** | **Four places, two states** | Binary state per place; the decisive act with two outcomes at each landmark; the freeze window as a tick stamp; the band kept for the borders; the free-state ground; the entrance sign as a voice (§3, §8, §13, §15) | Free the Wide Acres, watch the band fail to take it back for two days, then restore it; a replay from the log lands on the same tick; the sign says something different each time |
| **D** | **The crown as a play** | Rank from crown standing, falling as well as rising; the gate knowing your face as one of the three ways in; the crown's service list; the reworked opening — Halgrave audible in the first hour, the fairy checked (§5, §11) | §5's test: a playtester who wants to serve can name a first step unprompted. A loyal run reaches the throne reading and is shown hardship the morning after — and the same run can still turn |
| **E** | **Blackcairn reads the kingdom** | Wealth and instability as derived readings, on the castle and in the towns' talk; the journal's kingdom page (§4, §15) | Four flips in one window and the same four over a season look different at the gate and sound different in Harrowgate |

**Why this order.** A is a removal, and deleting before adding means every later
measurement is taken against the map v2 will actually have. B before C because a
decisive act writes hardship and needs the store to exist. C before D because rank's
"what people tell you" reads place state, and the throne reading is shown against
hardship in *changed* towns. E last because it reads flips, which C produces.

**Combat is not in this roadmap.** Phase 4 stays where v1 left it — out, by decision —
and the standing exception in CLAUDE.md stands with it. v2 does not open it; if Yannick
does, it is a sixth phase and goes after E, because the wild's question is "will I be
seen" until a fight is something the player can do.

**When this is done**, `docs/V1.md` gets a sibling that says what v2 is. The intent this
was written from is already `docs/history/V2_INTENT.md`.

---

## 19. Open questions

### Register

| # | Question | Raised | Blocking? |
|---|---|---|---|
| 1 | ~~The king's name, and the region's~~ — **Arthur**, and the region is **Erileo** (2026-09-12). Closed | 2026-09-10 | Closed |
| 2 | Why attempt #1 fails — the exact first-attempt experience | 2026-09-10 | It's the tutorial |
| 3 | ~~Route C's venue~~ — answered: **the church**, the largest room the crown cannot buy. Not a court, because the king owns the courts. Originally *"before Mother Crowe's congregation"*; she is cut and the church is a room rather than a door (2026-09-12) | 2026-09-10 | Closed |
| 4 | The levelling curve: target endgame HP and damage scaling | 2026-09-10 | Yes — combat |
| 5 | ~~What happens when the player dies?~~ — answered 2026-09-12: **you wake where you last slept, as you were when you slept.** Saving happens at beds and camps, not anywhere; the save is the event log, with a snapshot written alongside it so loading need not replay the whole run | 2026-09-10 | Closed |
| 6 | ~~Trait point pool size (12?)~~ — **10, with a cap of 5** (2026-09-13). See §11 and Q22 | 2026-09-10 | Closed |
| 7 | **Closed 2026-09-11, see Q7b.** ~~Is the 9×9 screen grid the right scale?~~ — answered: 7×9 screens, ~280×200 tiles, ~4 tiles/sec. Phase 0 now measures the *pace* of the walk; the 4–6 min road-travel target is timed later | 2026-09-10 | Closed |
| 8 | The five consequences that specify the reactivity system (§8) | 2026-09-10 | |
| 9 | ~~Approved asset packs~~ — answered: Ninja Adventure Asset Pack, CC0 1.0, one pack only (§13) | 2026-09-10 | Closed |
| 10 | Can facts be wrong? Rumours, lies, misinformation | 2026-09-10 | Yes — see Q25 |

> Row 5 closed 2026-09-12. Phase 0's "respawn in Brindle keeping everything" is
> retired by it. Row 6 closed 2026-09-13 with Q22 — its original rationale was wrong,
> and the correction is in Q22 rather than here.

### Decision queue — from the 2026-09-10 spec audit

Ranked by how much they block, not by how interesting they are. Recorded unfixed and
deliberately: none of these is decided. Q1–Q5 block the first test that gets written;
Q6–Q12 block the simulation core; Q13–Q17 block dialogue; Q18–Q27 block content
authoring; Q28–Q34 are later phases and bookkeeping.

| # | Decision needed | Where | Blocks |
|---|---|---|---|
| Q1 | **Populate the fact table.** §7's fact list is one empty row and §6's `Redundancy` field is unfilled for all 25 NPCs, so the redundancy validator and the reachability test have nothing to read. §6's "Holds" prose already names second sources for four facts — transcription, not invention | §7, §6 | Invariants 6, 7 |
| Q2 | **Define "a route is open" as a predicate**, per route, as a list of required facts and required performers. Exposure's "enough from at least four power bases" is the worst gap — "enough from one" is defined nowhere | §3, §7 | The reachability test |
| Q3 | ~~**Who holds "how he fights"?**~~ — answered 2026-09-11: the Muster teaches it, Ryse primary and Odile second, because the king trained with his own guard. Still open, separately: §3's "requires knowing / having / being" mixes facts, traits, items and levels in one vocabulary, and redundancy can only apply to facts | §3, §6 | Partly closed |
| Q4 | **Where does the authoritative fact list live** — §7's table or `content/facts` — and who fills it? | §7 | The fact base |
| Q5 | ~~**Quests.** No quest, fact pattern or quest count exists anywhere.~~ — answered 2026-09-13: **eight quests, and a quest is a predicate over the fact base.** `core/rules/quest_rules.gd` and nothing else: no store, no system, no migration. A quest is two fact patterns — what you must know for it to be a question you could be asking, and what makes it answered — so the state *is* the fact base and a reloaded save has exactly the quests its facts imply. Invariant 5 falls out of the shape rather than being policed: because §7 requires every fact to have more than one source, every quest has more than one way in for free | §9, §17 | Closed |
| Q6 | **Who witnesses a fight?** Combat now runs beside the sim, so nothing says how the witness set is derived — line-of-sight snapshot at transition, or something else — and whether that snapshot is an event | §8, §10 | Reputation, rumour |
| Q7 | ~~**§10's "Violence is never mechanically punished" is false against §8**~~ — answered 2026-09-11: §10's wording was wrong, not §8's. It means **no karma meter and no progression gate** — patrols thickening after a witnessed crime is the *social* punishment §10 itself describes, made visible and escapable. §10 amended; patrol density and guard alertness now respond to any witnessed deed | §8, §10 | Closed |
| Q8 | **World-tick persistence.** Are the twelve quantities event-sourced, snapshotted or stored? Invariant 3 routes all persistent state through the event log; SPECS never mentions the log | §8 | Save format |
| Q9 | **Player↔NPC relationships and allies** (§2, §11) are tracked by nothing in §8, and §9's graph edges are NPC-to-NPC only | §8, §9 | Dialogue context |
| Q10 | ~~**Three of the twelve are global where the consequences need them per place.**~~ — answered 2026-09-11: grain price and town sentiment are per town, army strength stays global, and desertion is now an explicit input to grain demand. See §8 | §8 | Closed |
| Q10old | **Town sentiment is one global quantity** while §8's own opening says reputation is per town and §9 reads "their town's sentiment" | §8 | Per-town reactivity |
| Q11 | ~~**Do NPCs have routines?**~~ — answered 2026-09-11: **no**, and Wren sells something else. Her fact is now the location of the unwatched stall, which needs no routine, is worth buying the moment you hear it, and is still "the first practical fact in the game". §21's cut stands | §6, §8, §21 | Closed |
| Q12 | **Weather and season.** The ford is passable only in dry weeks and no tracked quantity models either | §4, §8 | A knowledge-gated crossing |
| Q13 | **Cache-miss policy.** §9 names the miss as what breaks determinism and never says what happens on one. No seed, temperature, decode mode or pinned model version anywhere, so invariant 12 is unsatisfiable in the dialogue path | §9 | Invariant 12, §18 |
| Q14 | **Where the model runs** — local with pinned weights, hosted, or a baked cache with no runtime model at all | §9, §18 | The whole dialogue pipeline |
| Q15 | **Who authors the option set?** Does `core/rules/` compute the legal intent set and the model only phrase it, or does the model choose which options exist? Invariant 8 against §9's "proposes the player's options" | §9 | Invariant 8 |
| Q16 | **Prose leakage.** The schema constrains only mechanical output, so model prose can state a fact the fact base is deliberately withholding. What enforces the withholding? | §9 | Locked information |
| Q17 | **Conversation history against a fixed token budget** — what gets dropped, and does dropping it change the packet hash? | §9 | Cache determinism |
| Q18 | ~~**Exposure's evidence set does not match the argument it must rebut.**~~ — answered 2026-09-12: a fifth break added to §5 (*the whole thing was borrowed*), which is what the debts prove; and the tiered-law record moved to Cairnwell so the strongest break has a document without needing Greyhold. Each break now has exactly one document and each document a job — see §3 | §3, §5 | Closed |
| Q19 | **Four resolutions, three routes, no mapping.** Killed / spared / publicly broken / walked away from, against Force / Access / Exposure — an ending state machine nobody has sized | §5, §17 | Endings |
| Q20 | **The escort schedule is not integral.** "Roughly one and a half fewer per power base damaged" removes 9 of 10 across six, leaving one guard, not "a bare handful" — and 1.5 is not a person | §3 | The difficulty curve |
| Q21 | **What is a guard worth?** The king's 1000 HP never changes, so the power bases close "most of" the gap only if the escort carries most of the threat. The third column has no unit | §3, §10 | Combat balance |
| Q22 | ~~**Trait pool and cap together.** 12 does not force two specialisms — it buys three at 5. No pool size forces a count; only a cap does.~~ — answered 2026-09-13: **pool 10, cap 5.** The complaint was right, and 10 is the number at which two specialisms cost 8 and three cost 12, so the third is out of reach. Ten buys two at five with two spare, or one at five and two at three, or a flat spread — and each of those is a different person, which twelve was not | §11 | Closed |
| Q23 | ~~**Can traits rise after creation?**~~ — answered 2026-09-13: **no.** The six are chosen once and do not move, which is what keeps a trait gate legal under invariant 4: nothing opens because you did the previous thing. What levelling raises is left to v2 and is not the six. The store therefore holds no history — `core/traits.gd` is six numbers and a flag | §11 | Closed |
| Q24 | ~~**Is a document a fact, an item, or both** — and does it survive its holder's death?~~ — answered 2026-09-12: **both.** Reading it is knowledge, holding it is proof, and they are different things — the same distinction the game already had between knowing the pay fraud and being able to say it. **Documents lie in places, not in people**, so no death destroys one; and nothing takes one off you once it is in your hands. See §7 | §7 | Closed |
| Q25 | **Can facts be wrong?** Rumours already ship in §8. Decides the fact-base type | §7, §8 | The fact base |
| Q26 | ~~**The road's shape.**~~ — answered 2026-09-11: the prose wins, trunk through the Muster, Saltmarch on a spur, and the dog-leg is held to a 1.30–1.50 ratio by test. See §4 | §4 | Closed |
| Q26old | **The road's shape.** The prose routes the King's Road through the Muster; the sketch routes it through Saltmarch & Greyhold and leaves the Muster a dead-end spur, and "the Muster, on the crossroads" has no crossroads. Since on-road means seen, this decides which power bases can be reached unwatched | §4 | The map |
| Q27 | **Kell lives in a zone marked "cut first".** He is one of three sources of the player's own past. The optional zones are "Settled" scope in §17 and absent from §21's cut list | §4, §6, §17, §21 | The player's past |
| Q28 | ~~**Zone or screen as the loadable unit.**~~ — answered 2026-09-11: **neither.** The overworld is one region and the towns are in it; a zone is an *interior*, entered when the scale or the rules change. Screen-by-screen transitions were considered and rejected: §13's target is *Echoes of Wisdom*, which scrolls, the map is 7.0 × 8.9 screens so it does not divide, and a diagonal road with 8-way movement crosses boundaries constantly. Orientation is the map screen's job (§15) | §4, §22 | Closed |
| Q36 | ~~**Health never comes back.**~~ — answered before v1 shipped: it does. `RecoverySystem` mends you slowly in the open and faster in a town, and never while something is biting you; resting at a campfire mends you fully and moves the world eight hours. The premise this was raised on is gone. What is *not* answered is the balance question underneath it — what a fight costs — and that waits on Phase 4 with the rest of combat | §10, §11 | Closed; balance waits on Phase 4 |
| Q7b | ~~**Is the map the right size?**~~ — answered by playing rather than by arithmetic: a ~60-second empty walk was already too long, so the road-travel target came *down* to 45–90 seconds and the map keeps its 280×200. Length belongs in what is in the way, not in distance | §4 | Closed |
| Q28b | **Gates must be bands, not tiles.** A walker covers 6 tiles a second, so a one-tile doorway can be stepped clean over — you walk through the wall of a town and nothing happens. Every transition needs to be at least two tiles deep in the direction of travel. Recorded because it will bite again for the culvert, the ford and the cliff path | §4 | A rule for every future transition |
| Q28old | **Zone or screen as the loadable unit.** Invariant 3 says "zones unload"; zone boundaries are undefined, and §22's inspirations table is the only place that states how a zone is entered | §4, §22 | Streaming, invariant 3 |
| Q29 | ~~**The journal screen is TBD, and no save/load screen is listed at all.**~~ — answered 2026-09-13: both are built. The journal is **six pages turned with left and right** — what you have done, what holds him up, what you are looking for, what you are, what you know, and a debug roll of who is where — and **every page is cut to the box rather than trusted to fit**, because a Label given more lines than it has room for draws the ones that fit and says nothing about the rest. Save and load are the title screen: New, Continue, and a confirmation before a run in progress is replaced | §15 | Closed |
| Q30 | ~~**Asset validator inputs:** palette and approved pack list are still TBD.~~ — answered: Ninja Adventure (CC0), palette locked at 340 colours in `content/palette.txt`, validator in `tools/asset_validator.gd` | §13 | Closed |
| Q31 | **§8's five consequences** are an empty list declared to be "the specification for the reactivity system", while §17 already marks the twelve quantities "Settled" | §8, §17 | Reactivity |
| Q32 | **§12 economy is a bare TBD** while money is load-bearing in five places: a weakening lever, a fact-acquisition path, an Exposure failure mode, a leverage type, and five of the twelve tick quantities | §12 | Prices, bribery, the bank |
| Q33 | **§16 accessibility is a bare TBD** against a real-time, timing-based fighter | §16 | Combat design |
| Q34a | ~~**Invariant 11 was convention, not enforcement.** `project.godot` warned on untyped declarations instead of erroring, so nothing stopped an untyped member variable reaching main.~~ — answered: `gdscript/warnings/untyped_declaration=2`. Recorded here because the audit surfaced it and I left it out of this queue when I wrote it | project.godot | Closed |
| Q37 | ~~**An unwitnessed theft is specified but unreachable.**~~ — answered 2026-09-11: a stall in the Wide Acres, which has no cast in it. Theft becomes a decision about *where*, made on the map, which is the same shape as road against wild. Wren sells the location | §8, §6 | Closed |
| Q38 | ~~**Nothing earns a town's good opinion.**~~ — answered 2026-09-11: the act that raises a town is **giving away what you know**. Warn a town of what is coming (the pay fraud, told to Harrowgate instead of the Muster) and, smaller, give back what you stole. Both witnessed, both available because you are standing there. The fact becomes a resource with an opportunity cost: told once, to one audience. See §8 | §8, §15 | Closed |
| Q39 | **Nothing warns the player that a telling is one-shot before they spend it.** Deliberately not fixed: they learn it the first time it costs them, and the camp and the journal now make that legible after the fact. Considered and rejected for v1 — having Ossa explain the rule when she gives the fact would teach a mechanic by exposition and pre-empt the discovery. Revisit **after** Q5 (death and save policy), because "permanent" means something different with and without a reload | §8, §15 | Whether a one-shot resource is fair unannounced |
| Q40 | ~~**Greyhold is a power base with no location.**~~ — answered 2026-09-12: **Lord Aurel Greyhold moves to Cairnwell for v1.** The tiered-law record is already there, the capital is where the law is written, and a ninth zone is a great deal of map for one man. Greyhold as a place is not cut — it is deferred, and if it is ever built the lord and the record go back to it | §3, §4 | Closed |
| Q41 | ~~**Is the player's magic the fairies' magic?**~~ — answered 2026-09-12: **Attunement is attunement to the forest.** Not a spell list: a register. One substance, one source, and a player without it is deaf to the thing that raised them. §11's combat column for Attunement is now wrong and needs rewriting, and that is the real cost of the answer | §5, §11 | Closed; §11 owes a rewrite |
| Q42 | **Deferred to Phase 7's map work** (Yannick, 2026-09-12: *"not sure, and we are going to change the map a bit and improve it"*). The forest's scope is a map question before it is a content question, so it waits for the map. **What the opening already settles**: the player learns they were raised, by whom and why, in the first minute, so the premise reaches them whatever happens to the forest. What stays open is whether the king's motive becomes *actionable* — see the three sizes below. ~~Magic is central to the king's motive and absent from the built world.~~ Twenty-four NPCs, thirty-two facts, eight zones, ten deeds: none of them mention magic, the forest's people or the fairies. A motive with no presence is a motive the player cannot act on, and none of §3's five endings currently moves when the fairy-killing is exposed | §3, §5, §6 | Whether the new lore reaches play at all |
| Q43 | **Deferred with Q42, same reason.** Recorded so the map work has it in hand: the thesis needs the Thornwood off §4's cut-first list, and Q27 (Kell lives there) is a second reason. ~~The forest cannot answer back.~~ The map's thesis is an argument between two sides and the forest holds two zones, one of them optional and cut-first (§4). Q27 already flagged Kell living there; this promotes that from a content worry to a structural one | §4, §17, §21 | The thesis, and Phase 7's scope |
| Q44 | ~~**If memory was the price, can it be bought back?**~~ — answered 2026-09-12: **yes, and how much depends on the ending.** The fairies raised the player to stop the clearing, so the memory comes back to the degree the bet paid off. Removing the man is not the same as stopping the thing: killing Arthur leaves the forest still being cleared by whoever follows, and gives back least; breaking or deposing him changes the policy, and gives back most. The mapping from the five predicates to how much returns is Phase 7's, not written here | §5, §7 | Closed in principle |
| Q45 | ~~**Legally dead: a hole to walk through, or to fall into?**~~ — answered 2026-09-12: **both, and which one depends on where you are standing.** In Harrowgate the law is a local fee and a man with no row cannot be assessed, so it is a hole to walk through. In Cairnwell the law is *written*, and a man with no row has no standing to be wronged — so it is a hole to fall into. The same fact, read by two institutions, which is the tiered law's own argument turned on the player | §5, §6 | Closed |
| Q46 | **Every death is a resurrection.** Yannick, 2026-09-12: *"not sure — when the player is dead we come back to the last saving point."* So the mechanic stands and the fiction is undecided. **Recommendation, cheapest and it protects the one miracle: the fiction never narrates the player's death at all.** Waking at the last camp is a *save being loaded*, not an event in the world — the save is the event log (Q5), and the log does not contain a second death. Nothing to acknowledge, nothing cheapened, no rule needed. Left open because it is a choice about whether death means anything, and that is worth making deliberately | §5, §10 | Whether the one miracle stays one |
| Q47 | ~~**Which side is the church on?**~~ — answered 2026-09-12: **the church is against magic.** It is not the king's ally; it is a third power that agrees with him about exactly one thing. See §5 for what that buys | §5, §6 | Closed |
| Q48 | ~~**Mother Crowe does not exist, and somebody else has her job.**~~ — answered 2026-09-12: **Route C rebuilds around Corvin Ash.** He is built, he is good, and the debt is already his in dialogue and in `bank:debts`. The church keeps the *venue* — it is a better church for being against magic (Q47) than it ever was for being a creditor. Crowe is cut, and §6's ★★ row and §7's redundancy prose both name her and must be rewritten before invariant 7's walk can run | §6, §7 | Closed 2026-09-12 |
| Q49 | **Does the raising survive being said out loud?** The church is against magic, the player was raised by it, and Route C's climax happens in that church before its congregation. Whether the congregation can learn what the player is — and what happens if they do — is the most interesting consequence of Q47 and is unwritten | §5, §6 | Route C's cost |
| Q34 | ~~**Bookkeeping.** The header's populated-sections list is stale; §20 omits decisions taken in the body; the repo carries an empty tracked `test.py` and none of the declared directories.~~ — swept 2026-09-13, at the end of v1: the header says v1 rather than draft, §20 gained the seventeen decisions that had been recorded only in a working log, §19 closed the questions the code had already answered, and the directories all exist and are full. **It came back three times**, which is the real finding: a document that is edited faster than it is re-read goes stale in the places nobody looks, and only a pass with a date on it fixes that. §17's "Settled" rows inside 🟡 sections are still there and are still the same complaint | header, §17, §20, repo | Closed; §17 outstanding |
| Q50 | ~~**Attunement's combat half has nothing to point at.**~~ — answered 2026-09-13: **the wood does not slow you.** Time is the wild's price now, and an attuned character does not pay all of it, at Attunement 3 or more. The same shape as before — a cost you do not pay — pointed at the new price. Measured: 0.80 in the wood, about 3 s on the shipped map's shortcut, more as the forest grows | §11, §4 | Closed |

---

## 20. Decision log

| Date | Decision | Alternatives considered | Why |
|---|---|---|---|
| 2026-09-10 | Godot, at least for the first versions | Unity, Bevy | Text project files, agent-friendly, MIT |
| 2026-09-10 | Long save-based RPG | Repeatable runs | Sandbox continues past the main quest |
| 2026-09-10 | Player never types free text | Free-form chat | Every utterance maps to a known intent |
| 2026-09-10 | Every NPC killable, no dead ends | Invulnerable quest NPCs | Permissiveness is a pillar; redundancy solves it |
| 2026-09-10 | Art target: Echoes of Wisdom, from ALttP | Octopath / HD-2D | Top-down matches the grid overworld; cheaper |
| 2026-09-10 | Coarse world tick, 12 quantities | Full NPC life simulation | Feels alive at a fraction of the cost |
| 2026-09-10 | Pillars reduce the king's escort, not his HP | Pillars reduce his HP; levelling closes the gap | Keeps grinding from being the strategy |
| 2026-09-10 | Deterministic context assembly, no vector RAG | Graph RAG with embeddings | Determinism, small cast, graph shape |
| 2026-09-10 | Combat screen for every fight, tiered by occupation | Overworld resolution for weak NPCs | Consistency; tier 0 makes a point |
| 2026-09-10 | XP scales with opponent tier | Flat XP per kill | Stops "kill everyone" being optimal |
| 2026-09-10 | No children in the game at all | Children present but untargetable | Permissiveness has one limit, and this is it |
| 2026-09-10 | Title: *Uncrowned* | Regicide, The Whisper Campaign, Hearsay | Regicide was taken; Uncrowned reads as both threat and outcome |
| 2026-09-10 | The Cinderworks stands on Brindle's ground, visible from the start | Works elsewhere in the region | The crime and the industry it served share the first frame; no exposition needed |
| 2026-09-10 | Two ways to cross the map: watched road vs unwatched wild | One road network | Ties the map itself to reputation and rumour |
| 2026-09-10 | Static typing enforced by the compiler: `untyped_declaration=2` | Leaving it at warning level and relying on review | Invariant 11 is a hard rule and a warning does not stop anything. Errors do |
| 2026-09-10 | Precedence: SPECS wins on what the game is, CLAUDE.md on how we work and which phase we are in | Single source of truth for everything | The two documents answer different questions; the audit found an agent hitting a cross-document conflict had no rule and was told not to pick |
| 2026-09-10 | The king's six power bases are named, never numbered — the Cinderworks, the Wide Acres, the Muster, Greyhold, Harrowgate, the bank | Keeping "Pillar N" for both series; renaming the design pillars instead | Two numbered series called "Pillar" collided in one document — both containing a 3 and a 5 — and the words become identifiers |
| 2026-09-10 | Reachability means *at least one* route survives, not all three; redundancy covers facts and route-critical performers, to that same depth; the check is a living-performer-chain walk per route | Every route stays open (invariant 7 as originally written); a 2²⁵ kill-set enumeration | Killing Mother Crowe *should* close Exposure — that is permissiveness working. The old wording forbade it, and the exhaustive sweep both missed the budget and measured the wrong thing, since killing grants XP and so opens Force. **The example is superseded (2026-09-12): Crowe is cut and Exposure has no performer to kill. The decision stands; only the illustration was wrong** |
| 2026-09-10 | 1 tick = 1 in-game minute; 4 ticks per real second in the overworld; 1 in-game day = 6 real minutes; the world clock stops during a fight and combat runs beside the sim | Ticks as frames; a coarse day-tick; combat inside the world clock | Nothing in the doc gave the tick a duration, which left all twelve drift rates unwritable and `--ticks 5000` meaningless. §2's "watch the region react over the following in-game days" inside a one-hour session already constrained the ratio |
| 2026-09-11 | Feedback is specified in three registers — immediate, ambient, narrated — and all three are required | Treating the simulation as sufficient; a notification when the world changes | A change the player cannot perceive is identical to no change. Most systemic games do the first two and skip narration, which is why their players never feel their choices mattered. And the attribution is *pulled* through the journal, never pushed: Maddox not knowing it was you is the entire pleasure of consequence 2 |
| 2026-09-11 | Ambient drift stays slow and small; player-caused change is large, fast and local | Giving all twelve quantities lively drift rates | If everything drifts, nothing reads as caused and the player cannot tell their handprint from the weather. A still number is the background that makes a moved one legible — which is also why ten of the twelve still have no drift rule |
| 2026-09-11 | Harrowgate's crowd is drawn from army strength lost — scenery, unnamed, outside the 25-NPC budget | Leaving the bread price as a number; adding named townsfolk | Deserters have to go somewhere, and bodies explain a price better than a number does. Same body-over-number pattern the tents already proved. Keeping them nameless is what stops them acquiring dialogue by degrees and becoming cast |
| 2026-09-11 | Grain's reach from the Muster falls off with the square of distance, and the price drifts at 2.5/day rather than 5 | A linear falloff; matching the army's own drift rate | Linear gave Harrowgate — seventy tiles out, and one of the two towns the player lives in — a fifth of the pressure, not enough for anyone to notice. And at 5/day the price finished climbing on day three, tracking the army so closely it read as the same event; at 2.5 it is still moving on day six, which is a consequence |
| 2026-09-11 | A dialogue line gated on a world condition takes a slot ahead of an ungated one | First-authored-first-shown, as before | §9 leaves three slots and the reactive line is authored last by nature, so it was never reachable. Reactivity nobody can reach is reactivity nobody has |
| 2026-09-11 | A debug day-skip on `T`, through the ordinary tick path, gated on a debug build | `Engine.time_scale`; a faster world clock while testing | time_scale accelerates the player too, so you cannot move while time passes. Going through the tick path means a skipped day is identical to a waited one — same drift, same events, same replay — and every consequence left in §8 happens later than the act that caused it |
| 2026-09-11 | The suite is split: fast (0.9 s, bare sims) and `--all` (5.8 s, journeys and the asset pack), and `tools/run_tests.sh` is the only sanctioned way to run either | One suite; running `test_runner.gd` directly | 7.6 s was past the point of running it without thinking, and it only grows. The script is part of the check rather than a convenience: the runner cannot see its own stderr, so a test that crashes after its first assertion would still report "ok" |
| 2026-09-11 | The escort is derived from army strength, not stored: 10 at full, 5 after the fraud, 2 at nothing | §3's "1.5 fewer per power base"; keeping the escort as its own number | §3's schedule was never integral and never reached "a bare handful". Deriving it makes the escort a consequence of the world rather than a scoreboard, and closes the arithmetic defect the audit found |
| 2026-09-11 | Exposing the fraud costs 25 army strength immediately and eases to 40 over days | A single instant drop, as Phase 1 had it; pure drift with no immediate loss | Instant is legible but has no momentum; pure drift means nothing visibly happens when you act. Both: the men already on the edge go tonight, the rest over the following week — which is consequence 5 |
| 2026-09-11 | The witnessed crime that proves consequence 1 is **theft**, not murder | Killing, as first written; a minimal strike built in Phase 3 and deleted in Phase 4 | Theft is a permanent verb the game needs, exercises the identical witness-rumour-reputation chain, and does not drag combat forward a phase. Killing arrives in Phase 4 through the same pipes |
| 2026-09-11 | The guard at the bridge is a generic enemy type with a small shared line set, not a 26th named NPC | Adding a named character to §6's roster | §6 already rules that generic guards are enemy types budgeted separately. Giving the type a few shared lines is what stops "he needs something to say" turning it into a named character by the back door |
| 2026-09-11 | The Muster teaches how the king fights: Ryse primary, Odile second | Kell as the source | Route A's only knowledge requirement had no holder anywhere. Kell was rejected deliberately: one killable man already carries the player's past, and making him Force's sole requirement too puts more weight on a single death than §7 should allow |
| 2026-09-11 | Hesper is ★ and deliberately has no second source | Giving her a second source like every other ★ | Invariant 7 is "at least one route survives", not "every route". Killing her closes Access exactly as killing Crowe closes Exposure, and Force always remains. A world where every route has a spare is one where nothing you do to it matters. **Superseded in its example (2026-09-12): Crowe is cut, so Hesper is now the only route a death can close — which makes this decision stronger, not weaker** |
| 2026-09-11 | Grain price and town sentiment become per-town; army strength stays global; desertion is an explicit input to grain demand | Keeping all twelve global; making army strength per-region too | Consequences 1, 2 and 4 all fail against global scalars, and §8's own opening already said reputation is per town. There is only one army, so army strength has nothing to be indexed by. The desertion-to-grain link is consequence 2's entire mechanism and cannot stay implicit |
| 2026-09-11 | Events are external or derived: `submit()` from outside the sim is replayed, `derive()` from a system is logged but recomputed | Systems never raising events, as before; replaying everything; not logging derived events at all | Systems reacting to systems is §8's second consequence and cannot be built without it. Logging derived events too is what lets the journal answer "why did this happen"; recomputing rather than replaying them is what stops each one happening twice |
| 2026-09-11 | Health mends on its own — six calm seconds, then a point per 20 s outside and per 6 s in a town — as a Phase 3 stopgap | Potions and an inventory economy; no healing at all | Without healing the wild's cost ratchets and dying is the only reset; with an item economy it becomes a Phase 4 design problem dragged forward. This is the cheapest thing that makes the wild survivable and a town worth returning to |
| 2026-09-11 | The four child sprite folders are deleted from the pack, and a denylist fails the build if they return or are named in code | Leaving them unused; relying on review | Invariant 10 is absolute, and the palette validator cannot see it — a child sprite from the approved pack is perfectly on-palette. A rule enforced by memory is a rule that fails once |
| 2026-09-11 | The wild holds three beasts, all slower than the player, spawned near them and biased toward their heading, keeping a 3-tile margin from the road and a territory of their own | Beasts placed across the whole map; beasts that can outrun you; beasts merely kept off road tiles | Everything slower than the player means anything behind is scenery, so the danger has to be ahead. A margin rather than a tile is what makes the road genuinely safe. Territory is what stops the wood emptying while the player waits — otherwise waiting defeats the whole route |
| 2026-09-11 | Terrain no longer slows the player: everything walks at the road's 6 tiles/sec. The tuned table is kept behind `TERRAIN_SLOWS_YOU` | Keeping the multipliers; deleting the table outright | A forest should be dangerous, not tiring — the slog was making the interesting route the annoying one. §4's trade-off becomes distance against danger instead of speed against witnesses, which makes the road's dog-leg the whole price of safety rather than a detail |
| 2026-09-11 | Towns are laid out on the overworld at real size; transitions are reserved for interiors — a change of scale or rules, never of place | Every town its own zone behind a portal, as Harrowgate was; ALttP-style screen-by-screen transitions for the whole overworld | Harrowgate was 45× bigger inside than out, and the doorway itself caused four bugs in two sittings. Screens were rejected separately: the target art direction scrolls, 280×200 does not divide into screens vertically, and a diagonal road with 8-way movement would cross a boundary every few seconds |
| 2026-09-11 | Landmark buildings are impassable; scattered trees and rocks are walk-through scenery decided per tile by hash | Solid trees; no scatter at all; storing every tree as an object | A dense wood as solid objects is a maze and a memory cost. §4 prices the Thornwood in time and blood, not in navigation |
| 2026-09-11 | A town gate is placed on the far side of the road from the country beyond it | Gate between the road and the north, which is where it started | Otherwise every route out of the town crosses the doorway again and bounces the player straight back inside. Found by a test walking the road and arriving back in Harrowgate |
| 2026-09-11 | The King's Road runs through the Muster with Saltmarch on a spur; the trunk is a deliberate dog-leg at 1.41× the direct line | The sketch's route through Saltmarch; a direct road | §4's prose is the only worded statement of the route and the sketch disclaims itself. The bow is the point: without it the wild saves no distance and is strictly worse forever |
| 2026-09-11 | Terrain speed multipliers, road = 1.00 as the reference | Making the road a bonus above open ground | 6 tiles/sec is the tuned and approved speed. If the wild were the reference the approved feel would become the slow case |
| 2026-09-11 | Road-travel target cut from 4–6 minutes to 45–90 seconds; the map keeps its 280×200 | Growing the map roughly 36× in area to make the old figure reachable; slowing the walk | A ~60-second empty walk was already boring in play. The old figure had been reasoned from the map's dimensions rather than from anyone walking it, and reaching it by distance alone would have made travel the content. Session length comes from encounters, stops and detours |
| 2026-09-11 | Phases 2 and 3 swapped: the greyboxed world comes before reputation | Reputation, witnesses and rumour next, on the one zone that exists | Word travelling needs somewhere to travel to. Rumour on a delay, reputation per town and witnesses who saw you *there* are all claims about a map, and with one town built there was nothing to test them against. Traversal is a property of the whole map rather than of one zone, so the map comes first |
| 2026-09-11 | Two clocks: the sim steps at 60 Hz, the world tick fires every 15th step (unchanged at 4 in-game minutes per real second). Movement, collision, input and dialogue run on the step; the twelve drifting quantities run on the tick | One clock at 4 Hz, as first settled; a second clock only for combat | 4 Hz meant up to 250 ms of input lag on every direction change. That distorts every playtest, including the ones meant to settle walk speed. Measured after: one frame |
| 2026-09-11 | The zone is the loadable unit: a town is its own Region, entered through portal tiles on the overworld | One continuous grid with towns painted into it; screens as the unit | §19 Q28 was open. Towns want their own coordinate space and their own art, and CLAUDE.md invariant 3 already says "zones unload, and their nodes with them" |
| 2026-09-11 | Exposing the pay fraud takes the escort from 10 to 5 | §3's "roughly one and a half fewer per power base damaged", which would give 8.5 | Yannick's call for Phase 1. Note this contradicts §3's schedule and makes one power base worth more than three of §3's steps — see Q20, which is still open on the schedule being non-integral |
| 2026-09-11 | Transitions are bands at least two tiles deep, never single tiles | A one-tile doorway | A 1.5-tile step can skip a one-tile trigger entirely |
| 2026-09-10 | Approved pack: Ninja Adventure (CC0 1.0), vendored to `assets/` with its licence recorded beside it; palette locked at the 340 colours extracted from it; character height 16 px | Sourcing the same pack from its GitHub mirror; commissioning art now; a hand-authored palette | The pack ships its own CC0 text, so the licence travels with the files. The GitHub mirror states no terms at all, and absence of a licence is not permission. The palette is extracted rather than chosen so that "the pack's palette is the palette" is enforceable rather than aspirational |
| 2026-09-10 | The 16 px grid rule binds tile sources only, not every image | Every image in `assets/` must be a multiple of 16 | 812 of the approved pack's 1899 art files are off-grid by design — portraits, UI icons, FX sheets. A blanket rule would reject the pack it was written to protect |
| 2026-09-10 | Walk speed 6 tiles/sec (1.5 tiles/tick), and Blackcairn sits centre-north-west at 28% across, 12% down — 255 tiles from Brindle | 4 tiles/sec with the castle in the far north-west corner | Both from playing Phase 0: 4 tiles/sec was a trudge against the ~5.3 of *A Link to the Past*, and a castle in the literal corner contradicted §4's own "castle centre-north-west" |
| 2026-09-10 | Movement is 8-way | 4-way, tile-locked | Makes the corner-to-corner diagonal the true 343 tiles (~86 s) rather than the 478-tile Manhattan path, and fixes what Phase 0's stopwatch is compared against |
| 2026-09-10 | Phase 0 exception: no combat screen — the king kills on contact in the overworld, three touches | Building the side-on combat screen for the slice | §10's screen is the largest unbuilt system in the game and would swallow the slice. Deferred to Phase 3+ and recorded as an exception in CLAUDE.md so nothing generalises from it |
| 2026-09-10 | Phase 0 exception: death respawns the player in Brindle keeping everything; no save system | Reload-from-save; a death cost | The slice needs a loss the player can retry, not a persistence layer. The real death and save policy stays open (§19 row 5) |
| 2026-09-10 | Internal resolution 640×360, 16 px tiles, smooth scrolling camera that follows the player | A 640×352 viewport; forcing an integer tile count per screen | 360 scales ×2 to 720p and ×3 to 1080p; integer scaling beats a whole-number tile count. A following camera makes tiles-per-screen a planning unit, not an engine constraint. Snapped interiors, if ever wanted, are 40×22 rooms centred with a 4 px letterbox |
| 2026-09-10 | Region ~280×200 tiles (7×9 screens of 40×22) at ~4 tiles/sec; the tuned target is 4–6 min of road travel, not corner to corner | 9×9 screens with a 10–20 min corner-to-corner target | The old pair was arithmetically impossible: 478 tiles at 4 tiles/sec is 2 minutes, and 10–20 minutes would have needed a 0.5–0.9 tiles/sec crawl. Corner to corner *should* be short — the king is reachable from minute one — so length belongs in terrain, crossings and encounters on the road, not in the dimensions |
| 2026-09-11 | A rumour is an object — what happened, where, who saw it, how far it has got — not §8's single "rumour spread" scalar | Keeping the eleventh quantity as a number and adding a per-town delay beside it | A scalar cannot arrive in Cairnwell three days after a theft in Harrowgate: it has no origin to travel from and no distance to have covered. The number was the *report* of the thing, and consequence 1 needs the thing |
| 2026-09-11 | Standing lives beside the twelve tracked quantities, indexed by town and by faction, rather than becoming a thirteenth | Adding reputation to the twelve; one global reputation scalar | The twelve describe how the *world* is doing; standing describes where the *player* stands in it. Different kinds of thing, and the arithmetic that suits a drifting price does not suit an opinion |
| 2026-09-11 | A town's opinion moves when the story **arrives**, not when the crime happens | Moving every town's standing at the moment of the act, with a delay only on the dialogue | The delay *is* the consequence. If Cairnwell turns the instant Maddox looks up, the player learns that the world has one mind and nothing was ever travelling |
| 2026-09-11 | Witnesses are named cast only; the crowd sees nothing | Letting townsfolk witness; giving the crowd sheets so they could | A witness has to be able to repeat the story to somebody, and §6's scenery has no name to repeat it to. Making the crowd witnesses is the first step toward making them cast |
| 2026-09-11 | Word travels 45 tiles per in-game day, and stops being repeated past 220 tiles | A fixed per-town delay table; instant propagation to adjacent towns | Distance-based means the map's geometry decides who hears and when, which is the same thing that already decides the road's cost. Harrowgate to Cairnwell is ~127 tiles, so the story arrives on day three — ahead of a player who stops anywhere |
| 2026-09-11 | A robbed stall is bare for a quarter of an in-game day | No limit; one theft per town per day; a stolen-goods inventory | A consequence you can spam is not one — holding E starts fifty stories in a second and floors every reputation in the region. Ninety seconds is long enough that theft is a decision about where to be, short enough that it is not a punishment for trying it |
| 2026-09-11 | Generic strangers are types with a shared line set, placed by instance, with ids of the form `trade@n` — outside §6's twenty-five | A 26th named NPC in Cairnwell; townsfolk with dialogue bolted on | Extends the bridge-guard decision from enemies to civilians. The world has to be able to react to you through somebody who has never met you — that is the whole of consequence 1 — and a name would make that person cast |
| 2026-09-11 | Content can gate a line on a condition being **false** (`forbids_condition`), not only true | Authoring the inverse condition for every door that shuts | Every door that shuts opens another, so both halves have to be expressible. "He no longer offers to sell" is a consequence in exactly the way "he now mentions the bread" is |
| 2026-09-11 | A deed travels only if it is worth repeating: theft and a public warning do, restitution does not | Every deed propagating; nothing propagating but the first | One rule instead of a special case. A theft is news three days' walk away and so is a man saying the king's army is rotting; somebody quietly putting something back on a stall is news to the people who watched and nobody else. It is also what makes "repair the place, not the past" true in the code |
| 2026-09-11 | Standing is also per person: whoever **watched** you forms their own, stronger opinion; everybody else in the town moves with their town when word arrives; nobody is counted twice for one deed | Per-person standing only for witnesses; leaving relationships as a global town number | A town's opinion is the aggregate of the people in it, so the two should track by default and diverge only where somebody was actually standing. Witness-only would have left Ossa — ten tiles from the market, so never a witness — permanently neutral about a town that had turned, which is the case that showed the model was wrong |
| 2026-09-11 | Ossa stops sharing what she knows once she thinks ill of you, and that is legal only because Garrick teaches the same fact ungated | Gating nothing she says; gating only flavour lines | The door shutting has to be able to cost something real or it is decoration. Invariant 6's redundancy is exactly what makes it safe, which is the first time that rule has paid for itself. A content test now asserts every taught fact keeps at least one source nothing can gate shut — the luck of authoring is not a mechanism |
| 2026-09-11 | A second key: `E` is what is in front of you, `F` is what you carry in your head | One contextual key with a priority order | They were fighting over one key, and §8's availability rule says the act that raises a town must not queue behind whatever stall happens to be nearer. The split is also the clearer mental model — the world, and your knowledge of it |
| 2026-09-11 | A story carries about as far as the next town on its own; beyond that somebody has to walk it there. Rumour range 220 tiles → 80 | Leaving the uniform circle; making the circle slower; making the circle bigger | At 220 tiles a story reached all eight towns unaided, so it arrived in Cairnwell whether the player took the King's Road or the Thornwood — the road cost nothing and §18's proof for the phase was simply false. Distance is covered by people now, which is what makes the two routes differ by something other than animals |
| 2026-09-11 | **Travellers carry stories and can never be a source.** No name, no home, no routine, no opinion, never in the fact base or the standing tables | Letting travellers witness deeds; giving them ids and personal standing; no travellers at all | A story needs somebody who can be named and asked, and you never meet the same traveller twice — an opinion you cannot encounter is not an opinion, and a source you cannot question is not a source. So they only ever carry a story a named person already started. What is attributed is the **route**: the journal says "carried up the King's Road", and a route is better attribution than a name you would never meet again, because you can choose to avoid a route |
| 2026-09-11 | Travellers are simulated for the whole map always; only their drawing is culled. Movement runs per step, everything else per tick | Spawning them around the player like wildlife; running all of it per step | A carrier who stops existing when you look away cannot deliver anything, which is the one thing they are for. Deciding per step whether somebody recognises you cost more than the rest of the simulation put together, and a story does not need deciding sixty times a second |
| 2026-09-11 | A stall in the Wide Acres, where no cast stands, and Wren sells its location | Leaving §8's "a crime nobody saw did not happen" with no reachable case; NPC schedules so the market empties at some hour | Closes Q37 and Q11 with one piece of content and no new machinery. Theft stops being a flat tax and becomes a decision about *where* — the same shape as road against wild, made on the map. And it fits who Wren is: she picks over ruins, so she knows where nobody is looking |
| 2026-09-11 | **The player outruns gossip by ~35× and always will.** Not a defect | Raising rumour speed; slowing the player | For word to beat a 29-second walk it would need ~1,500 tiles a day, which is "instantly everywhere". Outrunning news is realistic and fine — you simply can never go back. What the wild buys is not outrunning the story but starving it, which is what travellers made true |
| 2026-09-12 | A document is **both** knowledge and proof, lies in a **place** rather than with a person, and can never be taken from you | Documents as facts only; as items only; confiscation as drama | Knowledge alone makes "put it in front of him where it cannot be denied" into "know four things", which is no climax. Living in places is what makes invariant 7 structural — violence can never close Route C, only make it harder — and it is the same guarantee the power bases gave. Confiscation was considered and rejected by Yannick: evidence that can be lost is a route that can be closed |
| 2026-09-12 | Reading a document aloud is what makes it public, and the news spreads as a rumour that turns towns against **the crown** — a different number from how they regard the player | Making a fact public by knowing it; turning only the town you stand in | Route C becomes a tour rather than an errand, and the King's Road matters to a player who never steals anything. It also gave `discredited` its first reachable path: five documents, read out where people can hear, and six towns had turned within a day of the last one |
| 2026-09-12 | No copies, though Bell is a copyist | Building copies now, since the character exists | The reason for a copy was to hedge against losing the original, and nothing can take one — so it would be building the answer to a question the game does not ask. It returns the day handing a document to somebody becomes an act |
| 2026-09-12 | **The dialogue pipeline is built with the model slot empty** | Building the model first; building the pipeline only when a model exists | The game runs today entirely on authored lines with the whole path inert, so attaching a model later is replacing one function. It is also the only way the decision in step 5 gets made on evidence: everything except the model is finished, tested and reversible |
| 2026-09-12 | A generated line enters as an **external event submitted by the window**, never produced inside a system | A system calling the model; the view substituting the line without logging it | A model is not repeatable and `core/` must replay exactly. Submitting the words as an ordinary event means they are logged, saved, replayed rather than re-asked, and removable without the game noticing |
| 2026-09-12 | Lines are checked **at the door**, inside the simulation, against one shared `ProseRules` | Checking where the line is produced; a second copy of the rules for generated text | Whoever produced it may be careless or absent. Two copies of the rules would drift, and the one that drifted would be the copy guarding the generated text |
| 2026-09-12 | Voice notes live in their own English-only file | Inside `cast.*.json`; as prose direction | They are instructions to a writer, never shown to a player, so a translated copy would be two things to keep in step for nothing. Plain and followable on purpose: "answers with figures" is something a person and a model can both do, "wry and world-weary" is how 24 characters end up sounding like 1 |
| 2026-09-12 | **The register is plain: short sentences, common words, no metaphor, readable by a 10 year old in both languages** | The literary register the whole cast was first written in | Yannick's call, on an example that proved it: "chaque peine de plus de 4 mois porte ma main au bas" is not French. It existed because an English image was translated word for word, and a long sentence gave it somewhere to live. French is written first now and neither language is a translation |
| 2026-09-12 | **Every line must stand on its own** | Lines that assume an earlier question was asked | The player picks options in any order. "7 years" has to be 7 years *in prison*, "more stone" has to say what the stone is for, and "at the furnace" needs the furnaces named. Plain language is not only short words, it is giving the player enough to understand the sentence |
| 2026-09-12 | Two prose rules **deleted** rather than relaxed: the coda cap and the voice-range rule | Keeping them and tuning the thresholds | The coda cap was a proxy for a register that no longer exists, and in plain speech everybody says "I". The range rule actively caused the damage: it pushed characters into 27 word sentences, which is where a metaphor hides. A rule that fights the register is a bad rule however well it measures |
| 2026-09-12 | **Counts are figures, not words**, in both languages | Prose convention, spelled out | A game about ledgers, death tolls and escort numbers should read like one, a figure lands where a spelled-out number reads past, and digits are language-neutral when the same content ships twice. The conversion had to be done by hand in the end: a regex cannot tell a count from an article, and French makes that worse because "un" is both — fifteen men became "1 homme" before it was caught |
| 2026-09-12 | **Voice range is a rule, because ceilings cannot see uniformity** | Caps alone, as the first pass had | Cutting every coda left the whole cast speaking in six words: 40% of sentences four words or fewer, spread 3.6 to 10.2. Every line passed every cap and the cast still had one voice, hard-boiled pastiche instead of rueful pastiche. A test now fails if the shortest and longest voices are less than 7 words a sentence apart. Spread is now 3.6 to 27.0, deviation 5.9 against 1.6 |
| 2026-09-12 | **A house style, machine-checked, and it doubles as the generation constraints** | Style by review; fixing it after the model exists | Measured: 53% of replies ended on a self-aware coda and Arthur's argument was twice the size of the dialogue box. One writer's tic applied twenty-four times is the same failure as a model's, and it is invisible line by line — only listing the closing sentences side by side shows it. A model will imitate the corpus, tics included, so the corpus had to be cleaned before it is ever used as an example |
| 2026-09-12 | Each character gets **one concrete verbal habit that is not wit** | Distinguishing voices by what they say rather than how | Halgrave answers in figures, Sena in under a dozen words, Dray in orders, Pell repeats himself, Wren prices everything. Ivo and Mira keep the self-examining close because it is what their work is. Wit was the only register the whole cast had, and wit is the easiest thing for a model to over-supply |
| 2026-09-12 | Arthur's argument is **six short beats** the player asks for, not one speech | One long reply, as written | It was 987 characters in a box that holds 420, so half of §5's case was never on screen. Split, the player assembles his argument by asking for it, which is also a better scene than being lectured |
| 2026-09-12 | **The cast is complete: twenty-four named people across all eight zones**, every line written in French and English | Writing English first and translating; leaving towns empty until later | Six of §3's levers are now things you *say* — turn the workers, organise a withholding, recruit deserters, redirect a convoy, turn the lord, read a document out — which is what stops twenty-four people being lore |
| 2026-09-12 | The Captain of the Guard is **Dray**; Arthur stands at `king_pos` and is the king you already walk up to | A separate NPC beside the king entity | Drawing him twice put a second king half a pixel behind the first. And nobody is stabbed mid-sentence now: contact damage and wildlife both stand down while a conversation is open, which is what makes Arthur a person you can speak to rather than a wall that hurts |
| 2026-09-12 | **§9's context assembler is built, and there is no model anywhere** | Building the model first; building the assembler only as a model input | The packet is worth having on its own: it is what a hand-written line chooses between, what a cache would be keyed on, and the thing to *read* before deciding whether a model should ever see it. A thin packet means no model would save it; a rich one makes the bake-versus-runtime decision worth having with evidence rather than opinion |
| 2026-09-12 | The relationship web is **ids only, in its own file** | Edges inside the cast sheets; edges in code | It needs no translation, which is the whole reason to keep it out of `cast.*.json` — and it lets an NPC be told who their neighbours are without any of it being written into their dialogue |
| 2026-09-12 | The unwatched stall moved a second time, and is now verified against a **roused** watch | Checking it against a calm watch, as before | It has been displaced twice by the world filling up — out of the Wide Acres when the granaries got a watch, out of southern Saltmarch when Til and Mira arrived. Checking it at the calmest moment was how it stopped being true the first time |
| 2026-09-12 | The Wide Acres and the Muster get their five, and Kell the Thornwood — **twelve of twenty-five now exist** | Writing all eighteen before playing any | Two more levers that are things you *say*: a withholding at the Acres, deserters recruited in the wood. Both need a reason the other person can repeat out loud — Pell will not move for a feeling and neither will eleven men hiding in a forest |
| 2026-09-12 | **The unashamed one is the open source**, in every town | Picking the open source at random; gating everything | Halgrave, Nessa and Ryse each give away the fact that damns their side, because none of them thinks it needs hiding. Invariant 6 needs one source nothing can gate shut, and characterisation was already deciding which — so the two rules turn out to be the same rule. It is also why the game has no "good" informants: the people who talk are the ones who are not ashamed |
| 2026-09-12 | A man hiding in a wood gets a fire | Leaving Kell in open forest | "He is out in the Thornwood" is otherwise an instruction to search a forest. The fire is the only landmark out there, it is what a deserter would have, and it doubles as a save point — one prop doing three jobs |
| 2026-09-12 | An intent that is not being offered is not spoken | Speaking the line and teaching nothing, as it did | Choosing an unoffered intent read the reply aloud and taught nothing, because the verdict refused it and the line printed anyway — indistinguishable from a fact failing to register. A keyboard cannot reach one; a tool can, and did |
| 2026-09-12 | Documents look like a book | Reusing the muster-rolls art, as it did | The five documents lay on the ground as pots and barrels, so the player walked up to some crockery and was told they had taken a ledger. Found by looking at the sprite rather than the code |
| 2026-09-12 | **The king is Arthur.** The region is still unnamed | — | Q1, open since the first day. Nothing had needed it because nobody in the game had cause to say his name; from the Cinderworks onward they do — Halgrave says it while defending him |
| 2026-09-12 | **French is the default language.** The machine's language is not consulted | Defaulting to the OS language; English first | The game is authored in French and translated into English, not the other way round, because that is how it is played. One line to change the day that stops being true |
| 2026-09-12 | **A spoken line can cause a deed** (`causes` on an option) | Levers only as acts at landmarks; a system per lever | §3 lists levers like "turn the workers" that are plainly things you *say*, and until now nothing in a conversation could cause anything — which is most of why a cast risked being lore. The rules layer still decides whether the line is offered; `causes` only names what saying it does |
| 2026-09-12 | The Cinderworks' three: **Halgrave ★, Sena, Ivo Marsh**, and the death toll has three sources of which only Halgrave's is ungated | Sena or Marsh as the open source | §5 is explicit that exposing a pantomime villain is not a climax. Halgrave gives you the number that damns Arthur **freely, to anybody**, because he is not ashamed of it and thinks the record matters — so characterisation and invariant 6 are doing the same job, and the fact stays reachable however badly the player has behaved |
| 2026-09-12 | Every `causes` id is checked against the deed table by a test | Trusting the id typed in content | Sena's line said `turn_the_workers` and the deed is `i_turned_the_workers`, so choosing it ran a deed nobody had written: no error, no effect, the furnaces merrily alight. An id typed in content and never compared against anything is a lever that silently does nothing |
| 2026-09-12 | Campfires **built**, twelve of them — one beside every place worth being and four on the road between | Beds in inns; one save point; saving anywhere | Recorded on 2026-09-12 and then not built for a day, which Yannick found by looking for them in play. They have to be common enough that reaching one is a plan rather than a pilgrimage: rare fires make death a punishment instead of a cost |
| 2026-09-12 | The save file is the event log and nothing else; loading is replaying it | A snapshot of the world; both | Everything in the world is derived from the events, so there is no snapshot that can drift out of step with it — and loading is not a feature with its own bugs, it is the thing every replay test has exercised since Phase 0. The snapshot beside it stays the obvious optimisation when a long run gets slow to load: measure first |
| 2026-09-12 | A test run forces English, whatever the machine or the player's saved language says | Letting the suite read the setting | Found the hard way: content tests assert on the words — that Maddox blames the soldiers and never the player — so the suite passed or failed depending on which language somebody last pressed `L` in. A test that reads a user preference is not a test |
| 2026-09-12 | Trait brackets and document titles are keys, not words built in `core/` | Leaving `label()` to compose "[Wits] …" | `[Wits]` was still English in a French game because `DialogueOption.label()` was building the string — the same layering leak the journal had, found the same way, in play |
| 2026-09-12 | **The game ships in French and English, and the split was done now rather than after Phase 6** | Doing it once the cast is written; writing the content in French only; Godot's CSV translations | 150 strings today against 25 NPCs and tens of thousands of generated lines later — the same job, about a day now and about a month after. Hand-rolled tables rather than Godot's CSV import because they load like any other content file, need no import step, and a test can read them. Godot's system is still the right answer the day this needs plurals, genders and right-to-left |
| 2026-09-12 | **`core/` never chooses words.** It returns ids, counts and kinds; the window makes the sentence | Leaving the journal and the region to phrase things, as they did | `core/journal.gd` was building English prose and `Region.place_name()` was naming its own places — presentation inside the simulation, and the thing that would have made the game untranslatable. Localisation exposed a layering mistake that was worth fixing on its own merits |
| 2026-09-12 | Languages are compared to each other on every test run: same keys, same cast shape, and the French must not still be the English | Trusting a translator to keep up; checking by playing | A missing line does not crash. It shows a key, or an English sentence in a French game, on one screen nobody opened while testing. The cheapest way for a translation to look complete is to paste the English in, so that is tested too |
| 2026-09-12 | **A question answered is a question spent** — options disappear once asked, unless marked repeatable | Letting every line be asked for ever; a cooldown | Found in play: you could ask Maddox the same thing forty times and get the same answer, which is what talking to a machine feels like. A person is a finite resource in a game about information — you should leave a conversation having used somebody up. Three lines in the game are repeatable, all of them questions whose answer genuinely changes |
| 2026-09-12 | **You save at a campfire, and dying puts you back at the last one you used, as you were.** One at every key location | Beds in inns; saving anywhere; autosave; no save at all (Phase 0's exception) | A campfire works in a town and in the wild, needs no interior, and can be placed wherever a save point should be — which a bed cannot. Death finally costs something, measured in the thing the game is made of: time and position. And it gives the phase its shape — do something, get away, rest — with the clock advancing as you rest, so the save point and the payoff are the same moment |
| 2026-09-12 | The save is the **event log**, with a snapshot beside it | Snapshot only; log only | The log stays the authority — replay is what every test and the journal depend on — and the snapshot is a shortcut so loading does not have to replay hours. Build the log first and measure; add the snapshot when loading is actually slow rather than before |
| 2026-09-12 | §5 gains a fifth break — **the whole thing was borrowed** — and each of Route C's documents answers exactly one break | Dropping the debts from Route C; leaving the tiered law without a document | The debts rebutted nothing and the tiered law, which §5 calls the break that gives him away, had no document anywhere reachable. The fifth break also makes him a gambler rather than a monster, which is worse for him and better for §5's rule that exposing a pantomime villain is not a climax |
| 2026-09-11 | The **deed** carries a reign's fall and the coupling only garnishes it: robbing the bank goes to −40/−52, and coupled quantities follow at 5 a day rather than 3 | Leaving the balance as it was; shortening the in-game day | §8's own rule — ambient drift slow and small, player-caused change large, fast and local — and it was backwards. Robbing the bank took 34 points off bank confidence and the *coupling* carried the other 41, so most of a reign's fall was the world doing it rather than the player. Measured: a full run went from 84 real minutes to 30, and most of what was removed was waiting |
| 2026-09-11 | Patrol density is read by the **road**: the busier the crown has made it, the further along it somebody puts your face to the story | Leaving it unread until Phase 4's spawn tables; inventing a consumer for it | It had been moving with nothing reading it — the same defect its neighbour had, which is how the defect gets caught twice in a week. Deliberately the same shape as the watch's sight: two dials on how hard it is to go unnoticed, one for the places you act in and one for the road between them, and both push the player toward the trees |
| 2026-09-11 | Every power base is watched: watchmen posted at the kilns, the granaries, the counting house and the muster rolls | Leaving the levers unguarded; guards that fight you | Measured: eight of the ten levers stood in places with **no cast at all**, so wrecking a furnace or burning a winter's stores cost precisely nothing — no witness, no story, no standing, and a watch that never woke. A reign could be ended by walking to ten places and touching each. Guards as *witnesses* make acts cost without needing combat, which is what lets Phase 4 stay deferred |
| 2026-09-11 | **A roused watch stands over what it guards and the act is refused.** Three acts in a place, then it shuts until things go quiet | Widening a watchman's sight only; a failure roll; guards that attack | §8's fifth quantity was an input with no output — built and read by nothing, the same defect the twelve had one level up. Widening sight alone barely changed the witness count on the shipped map, because posts stand near what they guard. Refusing the act is what makes a roused watch something to wait out, and it gives the phase a rhythm — act, move on, come back — that needs no fighting |
| 2026-09-11 | Guard alertness becomes **per town** | Keeping §8's single global figure | A granary burned in the Wide Acres closed the bank a hundred and twenty tiles away, which no player could read as anything but a bug. Third quantity to take this change, after grain price and town sentiment, and for the same reason: it is about a place. §8's single figure survives as the worst-watched place in the kingdom, recomputed rather than accumulated |
| 2026-09-11 | The unwatched stall moves from the Wide Acres to Saltmarch | Leaving it where it was; removing the Wide Acres watch | The granaries got a watch and the stall stood in the middle of the granary row, so Q37's answer stopped being true the moment resistance existed. Saltmarch has no cast, no power base and no trunk road, so nothing that happens there is seen *or* carried — which makes it the one genuinely unwatched place, and a better answer than the first one |
| 2026-09-11 | §3's levers against the power bases are **acts at landmarks**, one row each in the deed table | Dialogue options that damage a pillar; a system per power base | This is the whole of why Phase 5 was reshaped. Every one of §3's levers reads as a thing you do to a place, not a thing you say to a person — and building them as rows means adding a lever costs a table entry rather than a subsystem. Five of the six power bases; Greyhold has no location (Q40) |
| 2026-09-11 | A wrecked site stays wrecked — no cooldown, no repair | A restock timer like the market stalls; repairable sites | A cold furnace is cold. It is also what caps how far each quantity can be driven by hand: four kilns is how much steel output the player can take out, and the cap is a count of things on the map rather than a number somebody tuned. And it is legible — you can see which ones you have already done |
| 2026-09-11 | A quantity dragged by another **inherits its handprint** | Crediting only the quantity directly pushed | Bank confidence follows the treasury, town sentiment follows bread, and both are two steps from the act that caused them. Without inheritance, coupling launders the player's hand out of every consequence more than one step deep — and §3's endings would stop firing for exactly the runs that earned them |
| 2026-09-11 | An act must move a quantity's **target** as well as its value | Pushing the value alone | Found in play: destroying the muster rolls took eighteen men off the strength and the world quietly recruited them back over the following week, which made the act theatre. A quantity that eases toward a target is undone by its own drift unless the target moves with it |
| 2026-09-11 | Quantity #11, rumour spread, becomes a **readout** of how many stories are in the air | Keeping it as a stored scalar nothing writes | It stopped being a number the day rumours became objects that travel. This is what the scalar was always reporting, and it stops a declared quantity sitting at zero for ever pretending to be simulated |
| 2026-09-11 | The end conditions and the journal's page read **one table**, so a predicate over a number the player cannot see is not expressible | Two lists kept in step; a test asserting they match | Legibility as a structure rather than a promise. A test that checks two lists agree passes until somebody forgets it exists; a single table cannot disagree with itself. A predicate over an invisible number is a trapdoor, not a goal |
| 2026-09-11 | A quantity moves by `push()` (moves it and credits the player) or by assignment (weather). Changes the player sets in motion but that arrive later are credited with `credit()` at the act | One write path with a boolean; crediting drift per tick as it arrives | Two different calls is what stops the distinction being a comment somebody forgets. Exposing the fraud drops the army twenty-five tonight and forty more over the week — all of it the player's doing, so it is credited at the decision, and the drift that delivers it stays weather in the code |
| 2026-09-11 | Handprint needed is 25, well under every threshold | Requiring the player to have caused the whole movement | The world helping is the entire point of having a simulation. The rule is that a reign cannot fall over on its own, not that the player must do it unaided |
| 2026-09-11 | **The ending is a predicate over world state, not a completed route.** Killed, ruined, deposed, discredited, abandoned — any combination of acts that reaches one of those states finishes the game | Keeping §3's three routes as machinery with required steps; one authored ending | §3 wrote Force/Access/Exposure as recipes with required steps, which is exactly the "quest that can only start one way" invariant 5 calls a bug — the contradiction was in the spec, not the code. Predicates are about forty lines against three authored chains, they make any combination count, and four of the five need no combat, so deferring Phase 4 now costs one ending rather than the climax. Routes survive as fiction and as names for what tends to work |
| 2026-09-11 | **The handprint: drift may move the world, only the player may end it.** Every quantity carries a second figure for how much of it the player put there, and an ending needs a minimum handprint as well as a threshold | Thresholds alone; requiring a named act per ending | Yannick's guardrail. Without it a reign could fall out of ambient motion and the player would be a spectator at their own story. It is also §8's "push the ambient, pull the attribution" turned around — the world never tells the player what they caused, but the game has to know, or it cannot tell a reign that was brought down from one that fell over |
| 2026-09-11 | The journal gets a second page: the quantities that decide the ending, where each stands, and which carry the player's handprint | Leaving the predicate invisible; a progress bar; hints | A predicate over ten numbers cannot be aimed at. The page shows state and attribution and never advice — it will say the treasury is empty and that you emptied it, never that you should rob the bank next. It is the guardrail made visible: the same fact the end conditions check |
| 2026-09-11 | §7's reachability test asks whether **any ending is still reachable**, not whether each authored route is still open | Keeping the living-performer-chain walk per route | The per-route walk only made sense while routes were machinery. Asking whether the world can still be *moved* to satisfy any predicate is a smaller test and a truer one |
| 2026-09-11 | Phase 5 becomes "the world can be moved", and its first work is giving the ten inert quantities inputs | Building the three routes as planned; more NPCs first | Measured: two of twelve quantities are ever touched by a system, and everything that has felt alive comes from army strength alone. Dialogue is the only input to the only mover, which is why the game had started to feel like matching people to states. The fix is not more content — §3 already lists the acts for every power base and none are built, and they are rows in the deed table rather than new systems |
| 2026-09-11 | **Reaffirmed for v1: the world runs on the coarse tick and nobody has a day.** §21's first row stays cut | Un-cutting NPC routines; a cheap middle path of three or four posts per person by time of day | The cut list's trigger — "the coarse tick proves too thin" — arguably fired three times in one session: an unwitnessed theft is unreachable (Q37), Ossa can never witness anything from ten tiles away, and nobody walks the road. Weighed and declined anyway. Simplicity is what has kept every phase buildable, and the world-state simulation is what makes the player a nobody or a hero — a person's day is not. The three symptoms have answers that need no routines: a stall where nobody stands, the hearsay path already built, and travellers, which are moving furniture rather than people with lives |
| 2026-09-11 | A place must never describe an opportunity the player no longer has; when an act is spent, the ambient shows the door shut and the journal says what shut it | Leaving the prompt to vanish silently; a message on screen explaining the cost | Found in play: warn Harrowgate, walk to the camp, and the option to expose the fraud was simply gone while the camp still read "the pay tent has a queue and no money in it". An absent prompt is indistinguishable from a bug, and a world still advertising the thing is worse than silence. The camp now reads "the pay tent is shut, and the ledgers are not in it" and never says why — the journal does, and only if asked |
| 2026-09-11 | The journal is read from the event log alone, behind a key, and never announces anything | Rebuilding it from live state; a notification when a consequence lands; a feed | §8's narrated register has to be *pulled* or the attribution is pushed and the pleasure of consequence 2 is gone. Reading it from the log is also the proof that the log is the authoritative record of a run: a test replays a walk and asserts the journal comes back word for word |
| 2026-09-11 | The journal shows which facts have only ever had one source | Showing facts as a flat list | Invariant 6 is a design rule the player has no way to see, and it is their problem too — the thing you know dies with the only person who told you it. A test forbids the screen from ever printing a number or the word "reputation": it explains, it does not score |
| 2026-09-11 | Reaction to standing is the **default** for every conversation, with authored lines as overrides — not something each line opts into | Writing alt-greetings for all 25; leaving reactivity per line | Found in play: three people watched a theft and all three greeted the thief as a stranger. Opt-in reactivity makes silence the default, so coverage gaps are not an accident but the resting state — and writing more lines postpones the problem to the next NPC rather than fixing it. Same shape as the reactive line that could not get a slot, one level up: the mechanism was right and the default was wrong |
| 2026-09-11 | The shared band lines are **narration, not speech** | A generic spoken greeting per band; a spoken line per band per role | A line in nobody's voice sounds flat coming out of a named character. A line about a stance — "Maddox does not return your greeting" — works in everyone's mouth, so four sentences cover the whole cast for ever |
| 2026-09-11 | A conversation reads **one** number: what the person in front of you thinks | Keeping town standing and personal standing both live in dialogue | Personal standing already carries the town's through hearsay. Two numbers was a distinction the player could not see and an author had to guess between — the trader gated on the town, Ossa on the person, and nothing explained why. Per-town standing stays for content about a place |
| 2026-09-11 | Options carry a goodwill cost; teaching a fact costs goodwill by default; `costs: "free"` marks the source that must stay open | Gating each line by hand; withdrawing all teaching lines when disliked | By hand is what produced the defect. A default that reaches new content automatically is the only version that survives more content, and the free marker makes invariant 6's redundancy explicit instead of accidental — there must be somebody who will tell anybody |
| 2026-09-11 | Reach to a stall is measured to its **footprint**, not its anchor tile | Leaving point distance; moving the stalls apart | The anchor is the top-left corner of a 4×5 block and the sprite is drawn footed and centred on it, so the only usable spot was the back corner of something five tiles tall. In play the whole Harrowgate market was unreachable except one corner that happened to sit beside Bell, which read as "you can only steal from Bell" |
| 2026-09-11 | The act that raises a town is **giving away what you know** — warn a town of what is coming; secondarily, give back what you stole | A quest granted by an NPC; paying money; charity or almsgiving; leaving reputation one-way | A quest or a payment makes addition *gated* while subtraction stays free, and players optimise toward doing nothing. Telling is the exact mirror of theft — takes/gives, both witnessed, same machinery opposite sign — and it is the thesis of the game as a verb: information is the currency and the king falls to what people know |
| 2026-09-11 | The pay fraud can be told **once, to one audience**: the Muster or a town, never both | Two independent uses of the same fact; a weaker second telling; making the choice only a matter of order | Two uses is a menu, not a dilemma. Spend it on the king (collapse the army, shorten the escort) or spend it on the town (standing, and a town that has laid in stores). In the fiction, speaking it aloud anywhere reaches Odile, who then does not leave the books where she left them |
| 2026-09-11 | What is spent is the **telling**, never the **knowing** — the fact stays in the fact base permanently | Consuming the fact; introducing documents as a separate spendable resource | Route C needs the player to *know* the fraud and put it in front of the king. Invariants 6 and 7 are claims about *reaching* a fact, not about having spent it, so a consumable fact would have made the reachability test mean something different from what it says |
| 2026-09-11 | Faction standing moves **once, at the deed**; town standing moves **as the story arrives** | Shifting factions on every arrival, as the first version did | A faction is not a place and cannot hear the same story eight times. The old behaviour multiplied every faction shift by the number of towns the rumour reached and clamped at the ends of the range — found while giving the positive acts their counterparts |
| 2026-09-11 | Giving something back repairs the place, not the past: it raises the town, costs more with the unlawful than the theft gained, does not fully undo the loss, and never catches a rumour already travelling | A full undo; no restitution at all | A way to answer for a mistake rather than only accumulate them — but an act that erased its own consequence would make theft free, and a story already walking to Cairnwell is exactly the thing the player should learn they do not control |
| 2026-09-11 | Standing is shown on the HUD as a **word**, for the **place you are in**, and never as a global meter | An RDR-style global honour bar; a per-town bar; showing nothing until the journal exists | Legibility was a real gap — three in-game days between act and effect with nothing on screen. But one meter says the world has one mind, a needle that moves when Maddox looks up deletes the delay that *is* the consequence, and a visible number with known increments gets farmed rather than read. Words are as legible and are not optimisable. RDR2's crime-and-witness system is the part worth copying; its honour bar is the part players game |
| 2026-09-11 | Anyone who can see you is marked over their head, but only while an act is possible, and never counted | A permanent "who can see me" readout; keeping the "N people watching" text; showing nothing | *Who* is the part that matters — Maddox seeing you is not the same event as a stranger seeing you — and a mark teaches the sight radius by going out as you walk, which a number cannot. Permanent would be surveillance furniture rather than an answer to a question being asked |
| 2026-09-11 | The standing thresholds live in `StandingRules` beside the words, not in `DialogueRules` where the first one was written | Leaving the dialogue threshold where it was and giving the HUD its own bands | The HUD reading "wary" while a trader refuses to serve you is a lie the player cannot audit. One set of constants feeding both readings makes that impossible rather than merely unlikely, and a property test sweeps the whole range to hold it there |
| 2026-09-11 | One witnessed theft costs the town 22 and buys 14 with the unlawful; unwelcome starts at −20 | A smaller first offence with escalation on repetition | The first consequence has to be legible the first time, not on the third repetition. The counterpart is not decoration: without somebody who approves, the number is a morality meter |
| 2026-09-12 | The packet's brief is **facts** (`MUST BE TRUE`), never the finished reply (`MUST SAY`) | Handing the model the written line to rephrase; giving it no target at all | Rephrasing a sentence that is already written buys nothing and still needs every situation hand-written first. Facts are the brief that pays: measured overlap with the written line is 74% where nothing has happened and 50% where the player is known as a thief, so the whole gain sits in the half of the world an authored line cannot see |
| 2026-09-12 | An answer with no facts declared is **never generated** and keeps its written reply | Generating everything; generating nothing | Lets generation be turned on one question at a time instead of all at once, and makes "the game is complete without it" true by construction rather than by intention |
| 2026-09-12 | The prose door's word-length ceiling is **per language** — 5.4 English, 5.9 French | One ceiling for both; dropping the rule | Measured over the 95 written replies: English peaks at 5.00 letters a word, French at 5.46. One number refused two plain French lines and gave English slack it never used. French words are longer for reasons that are not register |
| 2026-09-12 | Content **declares** the proper nouns the world contains that are neither a person nor a zone | Inferring them; loosening the invented-name rule | A name that appears only inside the sentence naming it is indistinguishable from a hallucination. Declaring it is the only way to keep the rule strict and still let Nessa name four burned villages |
| 2026-09-12 | The door refuses a line that drops a given figure **or invents one** | Checking neither; checking only omissions | The only half of "state the facts" that is machine-checkable, and only because numbers are digits — 381 is 381 in either language. An invented figure is the worse of the two: a figure is why the player believes the rest of the line |
| 2026-09-12 | Calibrate the door against the **hand-written corpus** before ever pointing it at a model | Trusting the rules as written; calibrating on generated output | As written it refused 8% of lines a person wrote and shipped. A door judged only by the bad lines its own test feeds it is not judged at all, and the first generated line would have been blamed for the door's faults |
| 2026-09-12 | A reaction to the world **opens** a line rather than closing it | Answering first and adding the reaction as a tail; not reacting at all | Chosen 3 of 3 by ear where that was the axis. A reaction at the end reads as an afterthought bolted onto a stock answer — the same coda tic the voice-range rule was deleted for encouraging |
| 2026-09-12 | A name offered in an answer must be somebody who can actually help with *that* question | Following the voice note literally wherever it applies | The version sending the player to Tovin about bread lost to one that just gave the price. Tovin runs the law, not the granary. A voice note describes a habit, not a licence to point anywhere |
| 2026-09-12 | Rewrote 8 French lines carrying units and words a 10 year old cannot read: `sous`/`livre`, `arpents`, `laitier` (reads as milkman, not slag), `camp sale`, `fourniture` | Leaving approved content alone; changing only the line that was reported | The reported line was an instance of a class, and fixing only the instance leaves the rest for the next playtest to find. Same number written two ways by different characters (`Neuf`/`9`, `Quarante`/`40`) fixed in the same pass |
| 2026-09-12 | Run llama.cpp from the **official prebuilt macOS arm64 binary**, not from this machine's Homebrew | `brew install llama.cpp`; building from source; Ollama | This machine's Homebrew is the Intel one under Rosetta 2 (`HOMEBREW_PREFIX: /usr/local`, `macOS: …-x86_64`). Installing from it yields an x86 binary with no Metal, which would have made the speed test meaningless. The prebuilt arm64 tarball touches nothing else on the machine and is deleted by removing one folder |
| 2026-09-12 | An opening reaction says **what the speaker will or will not give**, never what they think of the player | Any reaction at the start; a reaction that observes the player | Explains 6 of 7 answers across two A/B rounds, including the one that looked like an exception. *"À vous, je peux le dire"* was chosen; *"Vous, vous regardez les fours"* was rejected by the same ear in the same session. A reaction is a change in what is on offer, not a character noticing you |
| 2026-09-12 | **Everything in the packet that names a thing is rendered in the player's language**; English survives only as instruction — the labels, the voice note, the facts | Leaving the packet as ids because it was only ever read by a person | The first real model run wrote *"il est dans Thornwood"* into a French line, from `HOLDS: thornwood:kell`. Anything in the packet may be repeated, so anything that names a thing must be sayable. Cost: the cast, the relation verbs and the fact descriptions all render per language, and 26 relation verbs became translated content |
| 2026-09-12 | The brief the model gets puts the **task first and the background last**, the reverse of the packet's own order | Sending the packet as built; trusting the instruction to win from the bottom | Maddox, asked the price of bread, explained where the deserter lives — his `HOLDS` line was a finished French sentence and the task was English fifteen lines below it. A finished sentence in the background beats an instruction in the task. Costs the cacheable prefix, which is a second ordering problem rather than a reason to keep a worse prompt |
| 2026-09-12 | The door refuses **formatting and stage directions** outright, and a GBNF grammar makes them unemittable | Stripping them after the fact; trusting the prompt | A model asked to write dialogue reaches for `*se retourne vers la mer*` and `**381**` immediately. Stripping is a guess about intent; a grammar that cannot express the character is a guarantee. Both are cheap, so both |
| 2026-09-12 | The packet carries **what the player knows and has done**, not only who the NPC is | Leaving the player out, as before; passing the whole fact base | Every answer was written for somebody who had just walked in off the road. Whether the player has read the ledger is the difference between being told the number and being asked what they mean to do with it. Clipped to 6, because the fact base is unbounded and most of it has nothing to do with the person in front of you |
| 2026-09-12 | A conversation carries its own **thread** — the last exchanges in full — on `WorldState`, cleared when the talk ends | Rebuilding it from the `asked:` facts; keeping it forever | A set of asked questions has no order and holds no answers, so a packet built from it can say what was asked and never what was said. It is cleared on close because the thread is the conversation, not the relationship |
| 2026-09-12 | When generated output is wrong, **the packet is the first suspect, not the model** | Tuning the model, the temperature or the prompt first | Twice in one session: `thornwood:kell` became "il est dans Thornwood" in a French line, and a fact description saying "près de 400" produced a 400 where the brief said 381. Both looked exactly like a model inventing things. Both were ours |
| 2026-09-12 | **Qwen3.5 4B over Ministral 3 8B** for generated dialogue | The desk research's primary recommendation; the 8B at a better quant; either with examples | Measured on sixteen real packets: 81% through the door against 44%, at half the size and the same 1.2 s. The research reasoned that a French company makes the best French and flagged one French tester who disagreed; the tester was right. Nothing published predicted this |
| 2026-09-12 | Showing hand-written lines as examples is **not** used | Three examples as prior turns, the standard fix | It cost the better model 19 points. A finished line in the target register appears to pull the model toward the example's *contents* rather than its shape, which is the same failure as a finished French sentence in the background beating an English instruction in the task |
| 2026-09-12 | Qwen's thinking mode is turned off with `--reasoning off --reasoning-budget 0` on llama.cpp b10930 | Accepting the empty output; a larger token budget; abandoning Qwen | The first run scored Qwen 0%, with every line empty and 3.5 s spent: the whole budget went on reasoning tokens and `content` came back blank. The research cited an open issue saying the flag was ignored. On this build it works. **Third time in one session that a model looked broken and the harness was at fault** |
| 2026-09-12 | Generation stays **off** for v1; the reactive openers are hand-written instead | Whole-line generation; opener-only generation; a second model to check meaning | Opener-only removed the unfixable part by construction and still got the sign backwards 5 times out of 6, at 94% through the door. A metric reading *ready* over inverted output is worse than one reading *broken*. The thing small enough for a model to invert is small enough to write: 4 standing bands, shared per band like `dispositions` already are |
| 2026-09-12 | Reactive **openers are hand-written**: 3 shared bands plus 9 characters with their own, 21 lines a language | Generated openers; no reaction at all; a reaction per question | The measured value of generation was entirely in this sentence, and 21 lines is smaller than the verification problem generating them creates. Every one can be read before it ships, which is the argument — not that models are bad, but that this is small |
| 2026-09-12 | A reaction is said **once per conversation**, on the first answer | On every answer; on the greeting | Four identical openers in one exchange is a stuck key. The greeting already has a narrated disposition line, and this one is spoken |
| 2026-09-12 | **The fairies of the Thornwood raised the player**, because the king is clearing the forest and killing them with it | Leaving the survival unexplained; a human rescuer; the player never died | The premise had the village burned and the player walking out of it with no account of how. A motive that is self-interested rather than kind keeps the player **owed** rather than **chosen**, which is the only version Pillar 1 survives: the fairies made a bet and nothing in the game makes it pay off |
| 2026-09-12 | **The memory loss is the price of the raising**, not separate misfortune | Leaving it as trauma or as unexplained amnesia | Turns the oldest design note — recovering memory and acquiring world knowledge are one system — from a convenience into the story. What you are trying to get back is what you paid, and you buy it from the records of the people who erased you |
| 2026-09-12 | **The player is legally dead**: no papers, no record, no name on any roll | "Nobody" as social standing only | Makes Hesper's refusal existential rather than bureaucratic — there is nothing for her to write on a pass — and gives the tiered law a person it cannot classify. The same erasure twice: the grants removed the village, the rolls removed the man |
| 2026-09-12 | **Magic is rare because the king has been killing it**, not because most builds skip Attunement | The systemic reason alone | The systemic version was a dodge for a question the fiction should answer. It still holds underneath and is no longer the reason |
| 2026-09-12 | **The map's thesis: the road is the king's world, the forest is what he is destroying** | Leaving road-against-wild as a pure systems trade-off | It was already true mechanically from Phase 2 — and that order is what makes it good. The theme is something the player *does* on every crossing rather than something the game tells them. Recorded with its cost: nine zones are his and two are the forest's, one of those optional |
| 2026-09-12 | The king is **clearing ground, not hunting magic** | Making the fairy-killing deliberate and personal | §5's protected note is that Route C only works if his argument is real, and a king who hunts fairies is a pantomime villain. Clearing land that something lives on is precisely what he did to Brindle — which is why the player, who *is* Brindle, is the one person who can see the two are the same act |
| 2026-09-12 | **The ending gives the memory back, in proportion to whether the clearing stopped** | All or nothing; never; the same for every ending | The fairies raised the player to stop the clearing, not to punish a man. Killing Arthur leaves the forest being cleared by his successor and gives back least; breaking or deposing him changes the policy and gives back most. It makes the five endings mean different things without adding a sixth, and the player learns which one they chose by what comes back |
| 2026-09-12 | **The church is against magic** | Neutral; secretly sympathetic; aligned with the king | It is a third power agreeing with the king about one thing only. It gives Route C a cost it lacked — the player reads the king's records from a pulpit that would condemn what they are — and makes the church's financing of the furnaces worse in the right way: it paid for the clearing that kills the thing it preaches against. And it leaves the fairies with no allies, so the player is an overlap between two things that would each disown them |
| 2026-09-12 | The region is **Erileo**; the king is **Arthur** | — | Closes the last naming question. Erileo is the one that shows up on a title screen |
| 2026-09-12 | **One fairy, in the opening, once**, telling the player four things and forbidden the rest | No fairy at all; a fairy who explains the situation; a fairy companion | The player has to be able to learn why they are alive, and nobody else in the world can tell them — everyone who knew them is dead. But a fairy who explains the *king* is exposition, and §4 has said since the first draft that none is needed. His argument must be discovered and believed before it can be broken, or Route C exposes a pantomime villain. **Being owed is not the same as being briefed** |
| 2026-09-12 | The opening is a **conversation, not a cutscene** | A scripted intro sequence | Invariant 9 already has the player choosing among options, and the four things he says are facts in the fact base like any other — the player's opening hand. A cutscene is new machinery, unreplayable, and outside the event log |
| 2026-09-12 | **Attunement is attunement to the forest**, a register rather than a spell list | A separate combat magic; dropping the trait | One substance, one source. A player without it is deaf to the thing that raised them, which is a far better trait than a damage type. §11's combat column for Attunement is now wrong and owes a rewrite |
| 2026-09-12 | **Legally dead is a hole to walk through in Harrowgate and a hole to fall into in Cairnwell** | Pick one reading | Harrowgate's law is a local fee and cannot assess a man with no row; Cairnwell's law is written, and a man with no row has no standing to be wronged. The same fact read by two institutions — the tiered law's own argument, turned on the player |
| 2026-09-12 | **Route C rebuilds around Corvin Ash; Mother Crowe is cut** | Building Crowe; leaving the spec stale | The spec made her the creditor the king fears and the built game gave that to Ash, in dialogue and in `bank:debts`. The church keeps the venue and is better for it: against magic (Q47) is a stronger reason to be the room than being the lender ever was |
| 2026-09-12 | **The forest's scope is deferred to Phase 7's map work** | Deciding it now | Yannick: the map is being changed and improved in Phase 7, and how much forest there is is a map question before it is a content question. The opening already guarantees the premise reaches the player regardless |
| 2026-09-12 | **Route C has no performer**, and the spec is corrected to match the code rather than the code to match the spec | Building a convener; inventing a replacement for Crowe | `DEED_MAKE_PUBLIC` is reading a document aloud where people can hear, and it gates on nothing. Route C therefore cannot be closed by any death, which makes **Hesper the only route a death can shut** — deliberate, and stronger for being the only one. The cost is the cut Absolution/Coercion choice, recorded in §21 rather than quietly dropped |
| 2026-09-12 | **Attunement is a register, not a spell list**, and its combat half is that the wild stops treating you as prey | Keeping combat magic; dropping the trait; giving it a damage type | There is no player magic — the one miracle happened *to* the player. Fights you never have is real double duty and has a precedent in Presence. It also makes the two social traits the map's two sides: Presence is the road build, Attunement the forest build, §4's thesis bought at character creation |
| 2026-09-13 | **The Thornwood is closed wood with ways carved through it** | A lawn with trees drawn on it; a wall around it | A wood you cross in a straight line costs only teeth. Carved rather than blocked, so connectivity holds by construction instead of by luck |
| 2026-09-13 | **Blackcairn is a wall with a gate**, not a town stamp in a pale colour | Four houses in a white rectangle | The gate is the whole reason Route B exists: Hesper's papers get you through a door, and a door you can walk round is not a door |
| 2026-09-13 | **The map of Erileo ships, on `M`** | Debug only; no map at all | A game whose argument is the road against the forest should let you see the shape of the argument |
| 2026-09-13 | **Looking at a screenshot is part of the check**, and `tools/shot.sh` exists to make it cheap | Trusting "no script errors over 300 frames" | `--headless` never calls `_draw()`. The ocean shipped covered in shoreline tiles, the granaries were statues for two nights, and every one of those was invisible to the suite and obvious in a picture |
| 2026-09-13 | **No two settlements are built out of the same kit** — buildings, street scenery and floor all differ by place | One set of houses everywhere | Yannick, after playing: the capital and the market town were the same picture with a different name over it |
| 2026-09-13 | **A settlement's ground is a ragged ellipse, never a rectangle**, and the fray may only eat natural ground | A rectangle stamp; fraying over anything | A straight edge is a town laid out with a ruler that nobody has walked on. Fraying over anything left a corner of thicket inside the Muster with a watchman posted in it |
| 2026-09-13 | **Nobody in the cast shares a sprite** | Reusing eighteen sheets across twenty-nine roles | Three women in three towns were the same woman. For a game about walking up to twenty-five specific people, the name over their head cannot be the only thing telling them apart |
| 2026-09-13 | **A quest is a predicate over the fact base** — no store, no system, no migration | A quest store with its own state; scripted steps | The state *is* the fact base, so a reloaded save has exactly the quests its facts imply, and invariant 5 falls out of the shape rather than being policed (Q5) |
| 2026-09-13 | **Trait pool 10, cap 5, chosen once and never raised** | A pool of 12; traits that level with the character | Twelve buys three maxed traits and leaves three at the floor, which is a shopping list rather than a choice. Not raising them is what keeps a trait gate legal under invariant 4 (Q22, Q23) |
| 2026-09-13 | **A trait tag gates a line at 3 or more, and invariant 6 counts a trait gate as a gate** | Display-only tags; putting facts behind traits | A character at the floor of all six must still be able to finish the game, so no fact sits behind a tag — each has a plain teacher as well |
| 2026-09-13 | **The game has a front — title, character creation, pause — and `screens.gd` owns which screen is up** | Booting straight into the world, as it did | The save system existed and was unreachable: no way to say *new*, no way to say *continue*. Screens emit `chose(what, carrying)` and know nothing about each other |
| 2026-09-13 | **One save slot; a new run asks before replacing it, then writes itself at creation** | Silently overwriting; writing only at the first campfire | The file otherwise still holds the previous run, so dying before the first rest drops you into somebody else's afternoon |
| 2026-09-13 | **The game is set in the pack's own typeface** | Godot's fallback sans | §13's one-pack rule covers a typeface exactly as it covers a tileset, and the fallback sans was the clearest amateur mark left on the screen. A test now refuses any line using a glyph the face lacks |
| 2026-09-13 | **The journal is paged, and every page is cut to the box** | One long scrolling list | A Label given more lines than it has room for draws the ones that fit and says nothing about the rest. It had been overflowing since the faction sections arrived and nobody could have known (Q29) |
| 2026-09-13 | **§14 Audio: three tables — music by place, ambience by ground, cues by what happened** | A sound call at each site that makes one | `core/` says you are standing in Saltmarch and must never learn that Saltmarch sounds like water. A cue is named by the event, so no caller knows which file it is |
| 2026-09-13 | **The score shares no track between the road and the forest** | One overworld theme | §4's thesis is that they are two worlds, and music is the one place that can say so without a caption. The ground the works has taken plays a lament |
| 2026-09-13 | **The audio is committed to the repo**, and sound can be switched off from the title and the pause menu | Leaving it re-downloadable from itch.io, as the art rule had it | A clone without it is a silent game with three tests that pass only on the machine the files happen to be on, which is worse than having no tests |
| 2026-09-13 | **The thesis: the game is about what the kingdom becomes, not about weakening the king.** Breaking and strengthening are both plays, both cost someone, and the ending is a reading of the state left behind — including the player on the throne | Keeping "weaken the king" as the frame, with pro-crown acts as flavour | Nine deeds, every effect negative, eleven ways to serve the opposition against two for the crown: the game could express breaking the kingdom in nine ways and building it in none. That is a missing sign, not a missing feature, and a game with one direction has one correct way to play |
| 2026-09-13 | **Hardship is a per-town reading beside the twelve**, and the thirteenth-quantity refusal is amended to cover standing-shaped numbers only | Folding it into town sentiment; into the player's standing; one global figure; a genuine thirteenth quantity | Sentiment is what a town thinks of the crown and a town can be loyal and hungry; standing is what it thinks of *you*. The refusal was about numbers indexed by town, faction and person — a condition of a *place* is what grain price already is, and `held_ground` had already set the precedent |
| 2026-09-13 | **Every quantity has a "builds it by" direction, as rows, and every act that moves the kingdom names who it costs — with a face** | Ten pro-crown systems; informing alone; "steel +20" with no cost | `push()` is signed and `credit_from()` carries the hand along a coupling, so the second direction is table rows. Without the face it is a scoreboard with two ends and the player picks an end; hardship is what makes both ends cost something and neither correct |
| 2026-09-13 | **A place changes hands two ways, and both are kept**: the sentiment band (drift, no handprint, the two borders) and one decisive act per place (handprint, tick stamp) | Only the band; only the act; the band extended to all four | The band is v1's honest model of a border and the one way a place moves without the player (Pillar 4). The act is the only way a flip can carry a handprint, without which the throne reading never fires. A Cinderworks that went free on a bad week of bread would be a power base falling to weather |
| 2026-09-13 | **The freeze window is 2 in-game days — 2880 ticks, 12 real minutes — one constant, a tick stamp in the log, and during it nothing moves the place: not the band, not the player** | A season; under a day; a timer; a hold that binds the band only and lets the player reverse at once | A season makes the first flip final and a place that cannot be restored is a ratchet; under a day the band could reverse a liberation before the player reached the next town. A stamp replays; a timer does not. Blocking the player too was Yannick's call: a place flipped twice in a minute is a switch, not a decision. It is the roused-watch shape — world state refusing an act, with the door shown shut — and not a progression gate, so it is no new exception |
| 2026-09-13 | **Four places, deeply — not six thinly.** The Cinderworks, the Wide Acres, the Muster, the bank; Greyhold and Harrowgate deferred; **wood gets no town** | Six places each with two directions; a Thornwood zone for fuel | Four is what `SiteRules` already reaches and what can be written to depth. Felling the forest is a Cinderworks consequence — the works needs fuel — so the factory eating the forest becomes a mechanic for one belt of tile work instead of a zone |
| 2026-09-13 | **One decisive change per place, with two outcomes** — a deed at the landmark with the thing the place holds, spent one way or the other | Two quests per place; a quest store; a menu at the landmark | Halves the writing and keeps invariant 5 literally true. The shape already exists twice: a fact told once to one audience, and making a thing public against informing on it. What decides the outcome is what the player brought, never a choice offered at the door |
| 2026-09-13 | **Two states per place, crown-held or free, with a ceiling at the starting state**; the borders' neutral start is retired | A third state; a "held by the player" state; "better than the crown had it" | You restore or you liberate; the Wide Acres never becomes better than it has ever been. Neutral was v1's "a border is not a side", and a binary rule has no room for it — what makes the borders borders is that the band can still move them |
| 2026-09-13 | **Rank is derived from crown standing, falls as well as rises, and never gates**; the crown's service becomes the whole "builds it by" column | A stored rank; rank from the service tally (`Allegiance.served`); the last rank as the only way through the gate | A stored rank is a progression flag by another name. The service tally only rises, so a man who burned the crown's granary would still be its Baron. Rank is one more way through a door that already had others — the guard knows your face at high standing, you climb the wall at low |
| 2026-09-13 | **Blackcairn cannot be taken and has one state; it carries two derived readings**, wealth and instability, with instability read from **recency** inside the freeze window | A flippable castle; a stored instability score; instability as a count | You do not take the castle by being disliked there. Recency is what makes it political: four towns in a week is a crisis, the same four over a season is policy. Both readings get a second channel — what towns say about it — because a change the player cannot perceive is no change |
| 2026-09-13 | **Taking the throne is a reading, not a sixth ending**: Deposed × high handprint × high crown standing, and it must show the hardship in the towns the player changed | A `crowned` predicate; an heir flag; reading rank instead of standing | A new predicate needs a new threshold and a page row and makes the throne a goal with a correct path. The reading is taken after Deposed fires from figures the journal already shows, and showing hardship the morning after is what stops it being a victory screen |
| 2026-09-13 | **The entrance sign is a voice, not a readout** — propaganda in the place's own words, different for always-loyal, strengthened and freed | A status line at the gate; no sign | A readout flattens discovery and breaks "push the ambient, pull the attribution". A claim the player can doubt and later find false is the ambient register speaking |
| 2026-09-13 | **Three phases of play are a description, never gates**, and phase 3 is available in minute one | Gating the confrontation on the world's state | Pillar 1. The phases say when a confrontation tends to go well, never when it is allowed |
| 2026-09-13 | **The opening points two ways**: policy not malice, the fairy names no enemy, Halgrave's argument audible in the first hour | Softening the burning; a fairy who names the king; a doubting Halgrave | The village stays cleared — it is the counterexample the king names to your face. A fairy who names him is exposition and a side taken. A man who half-believes is a fool with a ledger; the one who believes completely and can show figures is the one who costs the player something |
| 2026-09-13 | **Monsters are out of the whole map, and terrain speeds come back on** | Beasts in the forests only; keeping speeds off | The wild becomes slow and unwatched against a fast and watched road: the choice moves from "will I survive" to "will I be seen", which is the half the reputation system was built for. Blood asks a combat question the map should not be answering; time is the price the speed table was reasoned for |
| 2026-09-13 | **Road travellers are kept**, never conversational, never named, drawn as traffic | Removing them with the beasts; making them people | They are how rumour physically travels; before them a story reached every town whichever way the player walked. Removing them removes rumour propagation, the point of the Thornwood and the reason the road ratio exists. If they read as fake it is a drawing problem |
| 2026-09-13 | **The pack and the palette are locked for v2; a v3 art pass replaces both**, and the validator is what makes that safe | Swapping art during the systems rewrite | An art swap during a rewrite makes every visual bug ambiguous between the two. The four rules — one pack, a locked palette, the validator, one kit per place — are the wall a new pack has to clear, and the validator says immediately what it does not cover. Licence checked before anything is drawn |
| 2026-09-13 | **v2 is a content and coupling change** and does not touch the split, the log, the twelve as a set, the handprint, standing's three indexes, quests as predicates, determinism, the invariants or French-first | A snapshot save; renaming quantities; a new standing index; a quest store | Every one of those is load-bearing and finished, and every v2 change is expressible as rows, readings and words on it. The freeze window is a tick stamp so that a replay lands identically |
| 2026-09-13 | **Attunement's second half is "the wood does not slow you"**, at 3 or more | Accepting one trait doing one thing; leaving it open until Phase A is measured | The beasts took its combat half with them. Time is the wild's price now, so the forest build not paying all of it is the same idea — a cost you do not pay, Presence's shape — pointed at the new price. Six traits keep their double duty (Q50) |
| 2026-09-13 | **Open country walks at 0.65, not 0.80; farmland keeps 0.80** | 0.70 (the least change that passes); 0.60; keeping 0.80 and widening the Thornwood instead | Measured, with the beasts gone and speeds on: the least-watched line from Brindle to the castle is 208 tiles of open ground and 29 of wood, and at 0.80 the road beat a plain walker by 2.4 s and lost to an attuned one. At 0.65 it wins by 12 s and 9 s, a fifth of the walk. The table had been reasoned about while speeds were off and never measured against the claim it exists for. Widening the wood is Phase-7-scale map work and the forest's size is already Q42/Q43 |
| 2026-09-13 | **The wild line is the least-watched path**, not the shortest walkable one: a road tile costs ten wild tiles | The shortest walkable path (v1's instrument); forbidding the road outright | The shortest walkable path from Brindle to the castle is 42% King's Road, so v1 never measured the wild. Forbidding the road finds no path at all: the road runs from the south-east coast to the castle and seals the east, so every way to Blackcairn crosses it once. Dear rather than forbidden crosses where it must, never runs along, and takes the ford — which is what §4 always said the wild did |
| 2026-09-13 | **Travellers are drawn as a pack horse** from the approved pack's `Animal/Horse` side sheet | The crowd's sheets, as before; a cart (the pack has none); a pair of figures | A face is how furniture becomes a character by being looked at often enough, and the crowd's faces are shared with the cast on purpose. An animal on the road is traffic. Checked with a screenshot, not with the suite, because `--headless` never draws |

---

## 21. Cut list

| Idea | Why it's out | Could return if |
|---|---|---|
| Full daily schedules for every NPC | Cost far exceeds the felt benefit. **Reconsidered and re-cut 2026-09-11** against three symptoms of nobody moving; each had an answer that needed no routines | The coarse tick proves too thin *in a way a static answer cannot fix* — v2, not v1 |
| HD-2D / Octopath look | Wrong camera for a top-down grid overworld | A later version changes the camera |
| Epilogue content after the king | The world changes state; it does not gain new zones or quest lines | The ending proves to be the hook |
| Vector RAG for NPC context | Non-deterministic, and unnecessary at this cast size | Cast > ~150, or a searchable document corpus |
| Child characters | Out of scope permanently, by decision | Never |
| Mother Sabine Crowe | Cut 2026-09-12. The spec made her the creditor the king fears; the built game gave that to Corvin Ash at the bank, and Ash is good. The church keeps Route C's venue | The church ever gets a leader |
| **Absolution or Coercion** — Route C's choice of *how you get the room* | Went with Crowe. She was an accomplice who had to be either absolved into convening the reckoning or coerced into it, with a different enemy left standing at the end of each. A real choice, and Route C is dramatically poorer without it | A convener exists again. Not before: the deed that replaced her needs nobody's permission, and adding a gate to the one route no death can close would be spending its best property for drama |
| **The beasts** — the bear, the spider, the bat | Cut 2026-09-13, from the whole map. A wild whose cost is blood asks "will I survive", which is a combat question; the map's question is "will I be seen". The three lessons they taught — danger ahead, safety by margin not tile, waiting must not make the route safe — are kept in §4 for whatever hunts there next. Attunement's combat half went with them and was replaced (Q50: the wood does not slow you) | Combat exists (Phase 4) and the wild is meant to draw blood again — through the combat screen, not on contact |
| **A Thornwood town for wood** | Wood gets no town of its own (2026-09-13). The Cinderworks needs fuel, so felling the forest is a Cinderworks consequence and one belt of tile work | The forest gets people (Q42/Q43) and needs a place for them to stand — which is a different reason from fuel |

---

## 22. Inspirations & references

| Work | What exactly I'm taking | What I'm deliberately not taking |
|---|---|---|
| *Zelda: Breath of the Wild* | The final target is reachable immediately; you simply lose | Its traversal, physics, scale |
| *Assassin's Creed Odyssey* | Weaken a leader's assets before confronting them | Its combat, scale, structure |
| *Fallout* | Point-buy creation; visibly trait-gated dialogue | Its setting and tone |
| *Zelda: A Link to the Past* | Top-down grid overworld, zone entry | — |
| *Zelda: Echoes of Wisdom* | Target art direction | — |
| *Pokémon* / classic *Final Fantasy* | Transition from overworld into a dedicated combat screen | Turn-based combat itself |
| *Dragon Ball Budokai*, *Street Fighter* | Real-time side-on fighting | Their depth and frame data |
| *GTA* | Public violence has immediate, escalating consequences | — |
