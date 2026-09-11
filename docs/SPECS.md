# Uncrowned — Design Document

> **How to use this doc.** It is the source of truth: when the code and this
> document disagree, one of them is wrong and you decide which. Leave `TBD`
> everywhere you're unsure — an empty section is information.
>
> **Precedence.** This file wins on *what the game is*. `CLAUDE.md` wins on *how we
> work* and *which phase we are in*, including any phase exceptions it declares.
>
> **Sections marked 🟡 were invented by Claude at Yannick's request** and need his
> approval or rejection. Everything else came from him.

**Status:** draft — sections 1, 3, 5, 8, 9, 10, 11 populated
**Last updated:** 2026-09-10
**Version:** 0.7
**Location:** this file, `uncrowned-game/docs/SPECS.md`, is the single source of
truth. `SPECS_wild_notes.md` holds the original raw notes for reference only.

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

**Session loop (1h):** study or damage one of the king's six pillars, and watch the
region react to it over the following in-game days.

**Full playthrough:** arrive with nothing and no memory. Learn what the king did and
why he became the man who did it. Dismantle enough of his power that a confrontation
is survivable. Decide, standing in front of him, what you actually came for.

**After the ending:** the world continues (see §5, Endings).

**Expected playthrough length:** TBD

**What makes a player start a second run:** TBD

---

## 3. The king

**Who he is, in one paragraph:**
> TBD — needs a name. His argument is written in §5.

**Why the player wants him dead:**
The player's village was a small farming community, destroyed by the king's men to
clear ground for a steel works. Everyone the player loved was killed. The player
survived, barely, and lost most of their memory — but not that.

**Why attempt #1 fails:**
> TBD — write the exact first-attempt experience: what the player sees, tries, and
> loses to. This is the tutorial whether you intend it or not.

At the start the player has 10 HP; the king has 1000, and ten guards. That gap is
the design's opening statement, and the player is allowed to walk into it.

### How the difficulty gap actually closes 🟡

Three levers, deliberately unequal:

| Lever | What it changes | How much of the gap it closes |
|---|---|---|
| **Pillars** | The king's *escort*: ten guards at full power, roughly one and a half fewer per pillar damaged, down to a bare handful | Most of it |
| **Knowledge** | Fights the king's tells and phases — knowing how he fights turns a wall into a duel | A lot |
| **Levels & equipment** | Player HP and damage | The rest |

The king's own 1000 HP does not change. What changes is how many people are standing
between the player and him, and how well the player understands the man they're
fighting. This keeps grinding from being the answer, which matters — a game where
levelling closes a 100× gap is a game about levelling.

> **Design rule:** the pillars are the difficulty curve. Levelling is the fine
> adjustment, never the strategy.

### The six pillars of his power 🟡

> Each is a place the player can go, study and damage. The "teaches" column is not
> flavour — it is the evidence Route C (Exposure) is assembled from.
>
> **Naming rule (hard).** These six are referred to **by name** — the Cinderworks,
> the Wide Acres, the Muster, Greyhold, Harrowgate, the bank — and never as
> "Pillar N". "Pillar" alone means one of the five design pillars in §1. The
> numbers below are row labels for this table only; nothing else may cite them.

| # | Power base | What it is | How it can be weakened | What it teaches |
|---|---|---|---|---|
| 1 | **The Cinderworks** — stone & steel | The industry the villages were razed for; the kingdom's furnaces | Sabotage the furnaces; turn the workers; cut its ore supply from the quarry; expose its death toll | The ledger of what the works cost in lives — and that the king kept that ledger himself, and considered the price worth paying |
| 2 | **The Wide Acres** — the farms | Consolidated estates feeding the capital and the standing army | Burn stores; organise a withholding; redirect a supply convoy; buy the harvest out from under the crown | That the estates sit on the ground of specific razed villages, named in the land grants. This is where the player can find their own village on paper |
| 3 | **The Muster** — the military camp | The standing force, and the officers who executed the clearances | Kill the commander; expose the pay fraud; recruit deserters; destroy the muster rolls | The names of the men who burned the player's village, and the orders they were given, signed |
| 4 | **Greyhold** — the sub-castle | The regional seat and its lord — the king's enforcer of the wealth-tiered law | Turn the lord; blackmail him; kill him; discredit him publicly | How the tiered law is actually administered, and that the lord privately believes it is indefensible |
| 5 | **Harrowgate** — the town | The civil population whose loyalty the crown assumes | Shift its reputation of the king; expose the tiered law's local effects; provoke or prevent a riot | That consent is manufactured, and how — which is also the mechanism Route C exploits |
| 6 | **The bank**, at Cairnwell | Where the war gold sits, and the debts that finance the works | Rob it; expose the debts; ruin its confidence; hand its records to the right person | That the whole industrial project is leveraged, and that the king is personally afraid of one specific creditor |

### Routes to the confrontation

> Three at launch, each using a different verb.

**Route A — Force.** Reduce the escort, level, equip, fight through the door.
- Requires knowing: how he fights (from the Muster)
- Requires having: equipment and levels
- Requires being: nothing — this route accepts a monster
- How it can fail: arriving too early, escort intact

**Route B — Access.** Be admitted. Become someone the castle lets in — a supplier, a
lord's man, a hero the crown wants to be seen with.
- Requires knowing: who grants access, and what they want (Greyhold, the bank)
- Requires being: a reputation that survives scrutiny
- How it can fail: a reputation that contradicts itself; someone recognises you

**Route C — Exposure.** The bloodless route. Assemble the evidence the pillars hold
— the ledger, the land grants, the signed orders, the debts — and put it in front of
him where it cannot be denied.
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
- **Everything else** — the Thornwood, the hill tracks, the river bank — is slower,
  holds wild animals and monsters, and is **unwatched**.

Speed versus witnesses. That single trade-off connects the map directly to the
reputation and rumour systems, and it means the map itself makes the player choose
what kind of person they are being today.

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
wild and unpatrolled, where things that are not people live.

### The opening 🟡

The player wakes in Brindle, and from the first screen can see the Cinderworks
smoking on their village's ground, a minute or two's walk away. No exposition is
needed: the crime and the industry it served are in the same frame.

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
| Open grass, farmland | 0.80 | 4.8 |
| Coast sand | 0.75 | 4.5 |
| Thornwood | 0.55 | 3.3 |
| The ford (wading) | 0.50 | 3.0 |
| Marsh | 0.45 | 2.7 |

The road is the **1.00 reference rather than a bonus**: 6 tiles/sec is the speed
that was tuned and approved, so every other surface is a penalty. Were the wild
1.00 and the road faster, the approved feel would become the slow case.

### The Kettle, the bridge and the ford

The river runs from the northern mountains to the southern sea down the east of the
map, dividing the eastern strip — Brindle, the Cinderworks, the near Thornwood —
from everything else. **It is a real barrier:** dam both crossings and Blackcairn
becomes unreachable from Brindle, which is a test rather than a claim.

Both crossings are **bands, not tiles** (§19 Q28b), and both are sized to span the
river's *slant* rather than its width — a crossing measured against the width alone
leaves water on the far side and the road stops in the river. The first one did.

---

## 5. Story & fiction

**Premise** — the player wakes with no possessions and half their memory gone. Their
village is ash. They remember the king's men, and that the people they loved were
killed. They do not yet remember much else, including who they were.

**Tone** — TBD (three adjectives, and one work of fiction that has it).

**Themes** — what industrialisation costs and who pays it; law written to favour the
people who wrote it; whether revenge and justice are the same act; what a person is
without their memory.

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

**Magic** — exists, but is not widely practised. This is enforced systemically
rather than by fiat: magic is one trait among six, and most builds won't take it
(see §11).

### Endings

The game does not end. The king is resolved — killed, spared, publicly broken, or
walked away from — and play continues in a changed region.

**What concretely changes afterwards:**
- The world tick values shift permanently: prices, patrol density, faction tension.
- Who is in charge changes, per the resolution taken. A killed king leaves a vacuum
  someone fills; a broken king leaves an administration that has to answer for
  itself.
- All existing side quests remain playable. No content is closed off by the ending.
- NPC dialogue acknowledges the new state.

> This is the cheap version, deliberately. No new zones, no new quest lines, no
> epilogue content. See §21 for what was cut.

---

## 6. Characters 🟡

> Roster drafted by Claude. 25 named NPCs across 8 zones. Names are placeholders.
> ★ = route-critical, and every ★ fact has at least one other source.

**Named NPCs are people with a sheet**: a voice, wants, facts, and social edges.
Monsters, wolves, bandits and generic guards are enemy *types*, budgeted separately
(§17) and reused across the region.

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
| **Wren** | A scavenger picking the ruins. Not from Brindle; she arrived after | The Cinderworks' shift patterns — she sells them scrap. The first practical fact in the game |

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

> **Proposed, needs approval 🟡 — who tells the player about the pay fraud.**
> §3 lists "expose the pay fraud" as one of four ways to weaken the Muster and
> §6 gives the fraud to Odile, but **no Harrowgate NPC is specified as knowing
> about it**, so Phase 1 had to assign it. Nobody new was invented; two people
> already here fit the text:
>
> - **Ossa** (primary) — she already "treats everyone, including deserters", and
>   men desert because they are not being paid. She hears why from the people it
>   happened to.
> - **Garrick** (second source) — he already "moves between zones"; a caravan
>   master who supplied the camp would notice the rolls outrunning the mouths.
>
> Two sources, so §7's redundancy rule holds: killing either leaves the fact in
> the world. Reject this and the chain needs a different first link.

| Name | Role | Holds |
|---|---|---|
| ★ **Estate Lord Cadan Vale** | Holds the land grants | The grants naming razed villages, Brindle among them |
| **Nessa Vale** | His steward and daughter; keeps the actual paperwork | The same grants. Second source, and easier to reach |
| **Old Pell** | Tenant farmer. Worked Brindle's soil before the burning and after | That this ground was Brindle. He knew the player's family. He does not recognise the player |

**The Muster — the army**

| Name | Role | Holds |
|---|---|---|
| ★ **Commander Ryse** | Led the clearances. Sleeps fine | The signed orders, and the names of the men who burned Brindle |
| **Quartermaster Odile** | Running the pay fraud | The muster rolls, and her own crime — leverage |
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
| **Hesper** | Court steward. Controls who gets papers into Blackcairn | The key to Route B |
| ★★ **Mother Sabine Crowe** | Leader of the church. **The creditor the king fears** | The debt that could break him — and the church's own complicity in financing the works |
| **Brother Anselm** | Her secretary | The way in to her, and a second source on the church's ledgers |

**Blackcairn — the castle**

| Name | Role | Holds |
|---|---|---|
| **The King** | TBD name | His argument (§5), and his records |
| **Captain of the Guard** | TBD name | The escort. Reduced as pillars fall |

### Mother Crowe and the shape of Route C 🟡

The church financed the furnaces. Mother Crowe is simultaneously the only audience
the crown cannot buy, and an accomplice. The player cannot simply hand her the
evidence — she is in it.

Two ways through, and they should feel different:

- **Absolution** — give her a way to repent publicly, and she convenes the reckoning
  herself. She keeps her authority; the player gives up the satisfaction of naming
  her.
- **Coercion** — take the church's own ledgers (via Anselm) and hold them over her.
  She convenes it under duress, and the player has made an enemy of the one
  institution that outlives kings.

> Route C's venue, previously open: **the church, before a congregation Mother Crowe
> convenes.** Not a court — the king owns the courts.

### How the player recovers their own past

With no survivors from Brindle, the player's history is reconstructed entirely from
the records of the people who erased it. Three independent sources, none of whom
loved them:

1. **Old Pell** — worked the soil, knew the family, does not recognise the face
2. **Kell** — was there that night, on the wrong side
3. **The land grants** — Brindle, named on paper, with a date and a signature

> This is the thematic centre of the game and should be protected: you find out who
> you were by reading the paperwork of your own erasure.

---

## 7. Knowledge & information

**What counts as a fact:** anything the world knows and the player might not — a
secret, a relationship, a routine, a location, a document, and the player's own
recovered memories.

**How facts are acquired:** overheard, told, bought, extorted, read, witnessed,
recovered as memory.

**Redundancy rule (hard).** Redundancy applies to **facts** and to
**route-critical performers** — the people who perform an act a route needs, such
as Hesper granting papers or Mother Crowe convening a congregation. It applies
**only to the degree that one route survives**, not to the degree that every route
does. A fact or a performer with a single source is acceptable when the route it
serves is not the last one standing.

**Reachability test (hard).** After any set of deaths, **at least one** route to the
confrontation remains open. *At least one* — not all three. Losing a route to a
death is intended and is the design working: kill Mother Crowe and Exposure closes,
and the player still has Force and Access. What must never happen is the last route
closing.

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

### The world tick 🟡

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
quantities drift on their own and are pushed by the player's actions:

| # | Quantity | Drifts because | Player pushes it by |
|---|---|---|---|
| 1 | Grain price | Season, supply | Burning stores, redirecting convoys |
| 2 | Steel output | Ore supply, worker morale | Sabotage, turning workers |
| 3 | Worker morale | Wages, accidents | Agitation, exposure of the ledger |
| 4 | Patrol density | Crime reports | Being seen committing violence |
| 5 | Guard alertness | Recent incidents | Any witnessed crime |
| 6 | Crown treasury | Taxes, war costs | Robbery, exposing debts |
| 7 | Bank confidence | Treasury, rumour | Robbery, handing over records |
| 8 | Town sentiment | Prices, patrols, law | Almost everything |
| 9 | Army strength | Pay, food, desertion | The Wide Acres, the Muster, the bank |
| 10 | Faction tension | The above | Taking sides |
| 11 | Rumour spread | Time | Being witnessed |
| 12 | King's escort | Pillar states | Damaging pillars |

Each is a number the simulation core owns, updated on tick, and readable by
dialogue, prices, spawn tables and the pillar system. Nothing here requires
simulating a person's day.

**How reputation is earned and lost:** TBD in detail. Principle: reputation is a
consequence of *witnessed* actions, never of a quest completion flag.

**Who witnesses what, and how word travels:** witnesses record what they saw;
rumours propagate on a delay; a crime nobody saw did not happen.

**The five most satisfying consequences you want a player to notice:**
> These five are the specification for the reactivity system.

1.
2.
3.
4.
5.

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

### The context layer — deterministic assembly, not vector RAG 🟡

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
> Violence is never mechanically punished. It is socially punished: a witnessed kill
> moves reputation, notoriety and the rumour tick, and poisons every NPC socially
> linked to the victim.

**Numbers.** Player starts at 10 HP. Levelling raises health and attributes.
Equipment carries at least as much of the player's power as levels do.
> TBD: the actual curve. Target endgame player HP, and damage scaling.

**Magic** is available to players who took Attunement (§11), and is rare precisely
because most builds won't.

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
| **Attunement** | The rare register; some NPCs only speak to those who have it | Magic |

**Point-buy:** each trait starts at 1, with a pool to distribute; maximum 5 at
creation.
> TBD: the pool size. 12 is a reasonable start — it forces two real specialisms.

**Why this list.** *Temper* is a disposition rather than an ability, which is what
makes it interesting: it opens doors that *Presence* closes, and vice versa.
*Attunement* is how magic stays rare without a fiat rule — it competes with five
traits people want more. *Hands* exists so a player can be technically literate
about the king's industry, which Route C needs.

**What levelling raises:** health and attributes. XP from kills (tier-scaled),
quests, discovered facts, and damaged pillars.

**What the player accumulates besides levels:** knowledge, reputation, equipment,
allies, recovered memory.

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

**Path to the final look:** placeholder → approved pack → commissioned art.

---

## 14. Audio

TBD.

---

## 15. UI & UX

**Screens:** title, character creation, overworld HUD, dialogue, journal/knowledge,
map, inventory, combat, pause.

**The journal / knowledge screen** is the most important screen in this game — it is
where the player's real progression is visible.

Everything else: TBD.

---

## 16. Accessibility & options

TBD.

---

## 17. Scope budget

| Thing | Launch target | Notes |
|---|---|---|
| Region | 1 | Settled |
| Zones | 8 core + 2 optional | Settled, see §4 |
| Pillars | 6 | Settled |
| Routes to the confrontation | 3 | Force / Access / Exposure |
| Traits | 6 | Settled |
| World-tick quantities | 12 | Settled |
| Named NPCs | 25 | Drafted, §6 |
| Facts / secrets | TBD | each needs ≥2 sources |
| Enemy tiers | 6 | 0–5, occupation-driven |
| Enemy types (monsters, animals, generic) | 8–12 | Separate from named NPCs; reused region-wide |
| Combat moves (v1) | 5 | light, heavy, block, dodge, special |
| Playtime | TBD | |

**What gets cut first if I'm behind:** TBD

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

**Phase 2 — the world, greyboxed.**
Every zone exists and is walkable, the terrain is real, the art is applied, and the
wild is dangerous — but nothing in it is finished. All eight zones from §4, each
recognisable on sight; every power base visible as a landmark and nothing more; the
Kettle, the bridge, the ford, the Thornwood, the mountains, the coast; the road and
its Saltmarch spur; real terrain speeds; animals that chase and hurt. No new NPCs,
no new dialogue, no interiors, no reputation, no combat screen.
> **Proof:** one run visits all eight zones and each is recognisable on sight
> alone; **the costs of both routes are measurable and legible** — the Thornwood is
> slower and draws blood, the road is fast and safe; road travel from Brindle to
> Blackcairn can be timed by hand; and it looks like a game rather than a test
> harness.
>
> Note what this proof deliberately does *not* claim. The wild's whole payoff is
> being unwatched, and nothing watches yet, so in Phase 2 the wild is strictly the
> worse choice and is meant to be. Viability is Phase 3's proof, not this one.

**Phase 3 — the world reads you.**
Reputation per town and per faction, not one global number. Witnesses that record
what they saw. Rumour propagating on a delay. The journal screen §15 calls the most
important in the game. Pays the **external-versus-derived event debt** — systems
currently cannot submit events, because replay re-injects everything logged and
would double them — and cannot be built without paying it.
> **Proof:** a killing witnessed in one town changes how a stranger in another town
> opens a conversation, and the journal tells you why — **and the wild becomes a
> real choice**, because the slow dangerous track through the trees is now the one
> nobody can report you on. Phase 2 builds the cost; this phase pays it.

**Phase 4 — combat.**
The dedicated side-on real-time screen (§10), the occupation-driven enemy tiers 0-5,
and the king fight with its phases and tells. Retires Phase 0's contact-damage
exception.
> **Proof:** the king is beatable by a prepared player and lethal to an unprepared
> one, and the same five moves carry both a tier-0 servant and a tier-4 knight.

**Phase 5 — the three routes, end to end.**
Force, Access and Exposure each completable. The reachability test as a living
performer-chain walk per route (§7).
> **Proof:** three runs reach the confrontation by three different verbs, and
> killing any combination of NPCs still leaves at least one route open — as a test
> that fails the build, not a wish.

**Phase 6 — the full cast and deterministic dialogue.**
All 25 NPCs with sheets. The context assembler (§9) as a pure function over fixed,
ordered sources. Dialogue baked offline and reviewed; a runtime model only if
baking demonstrably cannot cover the packet space.
> **Proof:** the same situation produces the same words twice, and a stranger who
> has heard of you opens differently from one who has not.

**Phase 7 — art, audio and polish.**
Commissioned art replacing the approved pack, audio, and the accessibility pass
§16 defers.
> **Proof:** Yannick wants to play it in front of someone else.

---

## 19. Open questions

### Register

| # | Question | Raised | Blocking? |
|---|---|---|---|
| 1 | The king's name, and the region's | 2026-09-10 | Naming |
| 2 | Why attempt #1 fails — the exact first-attempt experience | 2026-09-10 | It's the tutorial |
| 3 | ~~Route C's venue~~ — answered: the church, before Mother Crowe's congregation | 2026-09-10 | Closed |
| 4 | The levelling curve: target endgame HP and damage scaling | 2026-09-10 | Yes — combat |
| 5 | What happens when the player dies? | 2026-09-10 | Yes |
| 6 | Trait point pool size (12?) | 2026-09-10 | |
| 7 | **Closed 2026-09-11, see Q7b.** ~~Is the 9×9 screen grid the right scale?~~ — answered: 7×9 screens, ~280×200 tiles, ~4 tiles/sec. Phase 0 now measures the *pace* of the walk; the 4–6 min road-travel target is timed later | 2026-09-10 | Closed |
| 8 | The five consequences that specify the reactivity system (§8) | 2026-09-10 | |
| 9 | ~~Approved asset packs~~ — answered: Ninja Adventure Asset Pack, CC0 1.0, one pack only (§13) | 2026-09-10 | Closed |
| 10 | Can facts be wrong? Rumours, lies, misinformation | 2026-09-10 | Yes — see Q25 |

> Row 5 is now scoped rather than closed: Phase 0 respawns the player in Brindle and
> keeps everything (CLAUDE.md, Phase 0 exceptions), but the real death and save
> policy is still open. Row 6 is still open and its rationale was wrong — see Q22.

### Decision queue — from the 2026-09-10 spec audit

Ranked by how much they block, not by how interesting they are. Recorded unfixed and
deliberately: none of these is decided. Q1–Q5 block the first test that gets written;
Q6–Q12 block the simulation core; Q13–Q17 block dialogue; Q18–Q27 block content
authoring; Q28–Q34 are later phases and bookkeeping.

| # | Decision needed | Where | Blocks |
|---|---|---|---|
| Q1 | **Populate the fact table.** §7's fact list is one empty row and §6's `Redundancy` field is unfilled for all 25 NPCs, so the redundancy validator and the reachability test have nothing to read. §6's "Holds" prose already names second sources for four facts — transcription, not invention | §7, §6 | Invariants 6, 7 |
| Q2 | **Define "a route is open" as a predicate**, per route, as a list of required facts and required performers. Exposure's "enough from at least four power bases" is the worst gap — "enough from one" is defined nowhere | §3, §7 | The reachability test |
| Q3 | **Who holds "how he fights"?** Force's only required fact has no holder in the roster, and the Muster's "teaches" column does not contain it. Relatedly, §3's "requires knowing / having / being" mixes facts, traits, items and levels in one vocabulary, and redundancy can only apply to facts | §3, §6 | Route A, the test |
| Q4 | **Where does the authoritative fact list live** — §7's table or `content/facts` — and who fills it? | §7 | The fact base |
| Q5 | **Quests.** No quest, fact pattern or quest count exists anywhere, though invariant 5 governs them and XP is granted for them | §9, §17 | Invariant 5 |
| Q6 | **Who witnesses a fight?** Combat now runs beside the sim, so nothing says how the witness set is derived — line-of-sight snapshot at transition, or something else — and whether that snapshot is an event | §8, §10 | Reputation, rumour |
| Q7 | **§10's "Violence is never mechanically punished" is false against §8**, where patrol density is pushed by "being seen committing violence", guard alertness by "any witnessed crime", and both feed spawn tables. That is a wanted level. Which claim stands? | §8, §10 | Reactivity, pacifist parity |
| Q8 | **World-tick persistence.** Are the twelve quantities event-sourced, snapshotted or stored? Invariant 3 routes all persistent state through the event log; SPECS never mentions the log | §8 | Save format |
| Q9 | **Player↔NPC relationships and allies** (§2, §11) are tracked by nothing in §8, and §9's graph edges are NPC-to-NPC only | §8, §9 | Dialogue context |
| Q10 | **Town sentiment is one global quantity** while §8's own opening says reputation is per town and §9 reads "their town's sentiment" | §8 | Per-town reactivity |
| Q11 | **Do NPCs have routines?** Wren's shift patterns are "the first practical fact in the game", but §21 cut daily schedules. The tick gives the world a clock; it does not give NPCs a day | §6, §8, §21 | The first fact in the game |
| Q12 | **Weather and season.** The ford is passable only in dry weeks and no tracked quantity models either | §4, §8 | A knowledge-gated crossing |
| Q13 | **Cache-miss policy.** §9 names the miss as what breaks determinism and never says what happens on one. No seed, temperature, decode mode or pinned model version anywhere, so invariant 12 is unsatisfiable in the dialogue path | §9 | Invariant 12, §18 |
| Q14 | **Where the model runs** — local with pinned weights, hosted, or a baked cache with no runtime model at all | §9, §18 | The whole dialogue pipeline |
| Q15 | **Who authors the option set?** Does `core/rules/` compute the legal intent set and the model only phrase it, or does the model choose which options exist? Invariant 8 against §9's "proposes the player's options" | §9 | Invariant 8 |
| Q16 | **Prose leakage.** The schema constrains only mechanical output, so model prose can state a fact the fact base is deliberately withholding. What enforces the withholding? | §9 | Locked information |
| Q17 | **Conversation history against a fixed token budget** — what gets dropped, and does dropping it change the packet hash? | §9 | Cache determinism |
| Q18 | **Exposure's evidence set does not match the argument it must rebut.** §5 lists four places the king's argument breaks; §3 names four documents. The debts support no break, and the tiered law — the break §5 calls the one that "gives him away" — is in neither list | §3, §5 | Route C content |
| Q19 | **Four resolutions, three routes, no mapping.** Killed / spared / publicly broken / walked away from, against Force / Access / Exposure — an ending state machine nobody has sized | §5, §17 | Endings |
| Q20 | **The escort schedule is not integral.** "Roughly one and a half fewer per power base damaged" removes 9 of 10 across six, leaving one guard, not "a bare handful" — and 1.5 is not a person | §3 | The difficulty curve |
| Q21 | **What is a guard worth?** The king's 1000 HP never changes, so the power bases close "most of" the gap only if the escort carries most of the threat. The third column has no unit | §3, §10 | Combat balance |
| Q22 | **Trait pool and cap together.** 12 does not force two specialisms — it buys three at 5. No pool size forces a count; only a cap does | §11 | Character creation |
| Q23 | **Can traits rise after creation?** Attunement gates whether some NPCs will speak at all, which is a creation-time gate. §11 says levelling raises "attributes", never defined against the six traits | §11 | Invariant 4 |
| Q24 | **Is a document a fact, an item, or both** — and does it survive its holder's death? Decides every performer-chain walk | §7 | The test, inventory |
| Q25 | **Can facts be wrong?** Rumours already ship in §8. Decides the fact-base type | §7, §8 | The fact base |
| Q26 | ~~**The road's shape.**~~ — answered 2026-09-11: the prose wins, trunk through the Muster, Saltmarch on a spur, and the dog-leg is held to a 1.30–1.50 ratio by test. See §4 | §4 | Closed |
| Q26old | **The road's shape.** The prose routes the King's Road through the Muster; the sketch routes it through Saltmarch & Greyhold and leaves the Muster a dead-end spur, and "the Muster, on the crossroads" has no crossroads. Since on-road means seen, this decides which power bases can be reached unwatched | §4 | The map |
| Q27 | **Kell lives in a zone marked "cut first".** He is one of three sources of the player's own past. The optional zones are "Settled" scope in §17 and absent from §21's cut list | §4, §6, §17, §21 | The player's past |
| Q28 | ~~**Zone or screen as the loadable unit.**~~ — answered 2026-09-11: **neither.** The overworld is one region and the towns are in it; a zone is an *interior*, entered when the scale or the rules change. Screen-by-screen transitions were considered and rejected: §13's target is *Echoes of Wisdom*, which scrolls, the map is 7.0 × 8.9 screens so it does not divide, and a diagonal road with 8-way movement crosses boundaries constantly. Orientation is the map screen's job (§15) | §4, §22 | Closed |
| Q7b | ~~**Is the map the right size?**~~ — answered by playing rather than by arithmetic: a ~60-second empty walk was already too long, so the road-travel target came *down* to 45–90 seconds and the map keeps its 280×200. Length belongs in what is in the way, not in distance | §4 | Closed |
| Q28b | **Gates must be bands, not tiles.** A walker covers 6 tiles a second, so a one-tile doorway can be stepped clean over — you walk through the wall of a town and nothing happens. Every transition needs to be at least two tiles deep in the direction of travel. Recorded because it will bite again for the culvert, the ford and the cliff path | §4 | A rule for every future transition |
| Q28old | **Zone or screen as the loadable unit.** Invariant 3 says "zones unload"; zone boundaries are undefined, and §22's inspirations table is the only place that states how a zone is entered | §4, §22 | Streaming, invariant 3 |
| Q29 | **The journal screen**, which §15 calls the most important in the game, is TBD — and no save/load screen is listed at all, while §1 commits to save-based play | §15 | The real progression UI |
| Q30 | ~~**Asset validator inputs:** palette and approved pack list are still TBD.~~ — answered: Ninja Adventure (CC0), palette locked at 340 colours in `content/palette.txt`, validator in `tools/asset_validator.gd` | §13 | Closed |
| Q31 | **§8's five consequences** are an empty list declared to be "the specification for the reactivity system", while §17 already marks the twelve quantities "Settled" | §8, §17 | Reactivity |
| Q32 | **§12 economy is a bare TBD** while money is load-bearing in five places: a weakening lever, a fact-acquisition path, an Exposure failure mode, a leverage type, and five of the twelve tick quantities | §12 | Prices, bribery, the bank |
| Q33 | **§16 accessibility is a bare TBD** against a real-time, timing-based fighter | §16 | Combat design |
| Q34a | ~~**Invariant 11 was convention, not enforcement.** `project.godot` warned on untyped declarations instead of erroring, so nothing stopped an untyped member variable reaching main.~~ — answered: `gdscript/warnings/untyped_declaration=2`. Recorded here because the audit surfaced it and I left it out of this queue when I wrote it | project.godot | Closed |
| Q34 | **Bookkeeping.** The header's populated-sections list is stale; §17 marks rows "Settled" that live in 🟡 unapproved sections; §20 omits decisions taken in the body; the repo carries an empty tracked `test.py` and none of the declared `core/ view/ tools/ test/` | header, §17, §20, repo | Nothing — but it misleads readers |

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
| 2026-09-10 | Reachability means *at least one* route survives, not all three; redundancy covers facts and route-critical performers, to that same depth; the check is a living-performer-chain walk per route | Every route stays open (invariant 7 as originally written); a 2²⁵ kill-set enumeration | Killing Mother Crowe *should* close Exposure — that is permissiveness working. The old wording forbade it, and the exhaustive sweep both missed the budget and measured the wrong thing, since killing grants XP and so opens Force |
| 2026-09-10 | 1 tick = 1 in-game minute; 4 ticks per real second in the overworld; 1 in-game day = 6 real minutes; the world clock stops during a fight and combat runs beside the sim | Ticks as frames; a coarse day-tick; combat inside the world clock | Nothing in the doc gave the tick a duration, which left all twelve drift rates unwritable and `--ticks 5000` meaningless. §2's "watch the region react over the following in-game days" inside a one-hour session already constrained the ratio |
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

---

## 21. Cut list

| Idea | Why it's out | Could return if |
|---|---|---|
| Full daily schedules for every NPC | Cost far exceeds the felt benefit | The coarse tick proves too thin |
| HD-2D / Octopath look | Wrong camera for a top-down grid overworld | A later version changes the camera |
| Epilogue content after the king | The world changes state; it does not gain new zones or quest lines | The ending proves to be the hook |
| Vector RAG for NPC context | Non-deterministic, and unnecessary at this cast size | Cast > ~150, or a searchable document corpus |
| Child characters | Out of scope permanently, by decision | Never |

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
