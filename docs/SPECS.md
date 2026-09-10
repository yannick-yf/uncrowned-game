# Uncrowned — Design Document

> **How to use this doc.** It is the source of truth: when the code and this
> document disagree, one of them is wrong and you decide which. Leave `TBD`
> everywhere you're unsure — an empty section is information.
>
> **Sections marked 🟡 were invented by Claude at Yannick's request** and need his
> approval or rejection. Everything else came from him.

**Status:** draft — sections 1, 3, 5, 8, 9, 10, 11 populated
**Last updated:** 2026-09-10
**Version:** 0.4
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

| # | Pillar | What it is | How it can be weakened | What it teaches |
|---|---|---|---|---|
| 1 | **The stone & steel works** | The industry the villages were razed for; the kingdom's furnaces | Sabotage the furnaces; turn the workers; cut its ore supply from the quarry; expose its death toll | The ledger of what the works cost in lives — and that the king kept that ledger himself, and considered the price worth paying |
| 2 | **The farms** | Consolidated estates feeding the capital and the standing army | Burn stores; organise a withholding; redirect a supply convoy; buy the harvest out from under the crown | That the estates sit on the ground of specific razed villages, named in the land grants. This is where the player can find their own village on paper |
| 3 | **The military camp** | The standing force, and the officers who executed the clearances | Kill the commander; expose the pay fraud; recruit deserters; destroy the muster rolls | The names of the men who burned the player's village, and the orders they were given, signed |
| 4 | **The sub-castle** | The regional seat and its lord — the king's enforcer of the wealth-tiered law | Turn the lord; blackmail him; kill him; discredit him publicly | How the tiered law is actually administered, and that the lord privately believes it is indefensible |
| 5 | **The town** | The civil population whose loyalty the crown assumes | Shift its reputation of the king; expose the tiered law's local effects; provoke or prevent a riot | That consent is manufactured, and how — which is also the mechanism Route C exploits |
| 6 | **The bank** | Where the war gold sits, and the debts that finance the works | Rob it; expose the debts; ruin its confidence; hand its records to the right person | That the whole industrial project is leveraged, and that the king is personally afraid of one specific creditor |

### Routes to the confrontation

> Three at launch, each using a different verb.

**Route A — Force.** Reduce the escort, level, equip, fight through the door.
- Requires knowing: how he fights (from Pillar 3)
- Requires having: equipment and levels
- Requires being: nothing — this route accepts a monster
- How it can fail: arriving too early, escort intact

**Route B — Access.** Be admitted. Become someone the castle lets in — a supplier, a
lord's man, a hero the crown wants to be seen with.
- Requires knowing: who grants access, and what they want (Pillars 4, 6)
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
> east, 10–20 minutes corner to corner. Names are placeholders — change freely.

### Bounds and scale

One region, bounded on all four sides so the playable area needs no invisible walls:

- **South** — the open sea
- **West** — the open sea
- **East** — the Iron Spine, impassable mountains
- **North** — mountains, with the castle set against them

**Scale target:** 10–20 minutes to walk corner to corner, ignoring encounters. As a
starting figure, a grid of roughly 9×9 overworld screens at 40×22 tiles each.
Tunable — walk it early and adjust, this number is a guess until it is played.

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

| # | Zone | Where | Pillar | Its job in the design |
|---|---|---|---|---|
| 1 | **Brindle** — the ruins | South-east, inland of the coast | — | Where the player wakes. Their village, burned. In sight of the furnaces built on it |
| 2 | **The Cinderworks** | South-east, on Brindle's ground | 1 — stone & steel | The thing that killed the player's family, running day and night. Holds the death ledger |
| 3 | **Harrowgate** | South-centre, on the road | 5 — the town | The first town. Market, gossip, the tiered law in daily practice |
| 4 | **The Wide Acres** | Centre-south | 2 — the farms | Consolidated estates. The land grants naming razed villages, Brindle among them |
| 5 | **The Muster** | Centre, on the crossroads | 3 — the army | The standing force. Muster rolls, pay fraud, the signed orders |
| 6 | **Saltmarch & Greyhold** | South-west, on the coast | 4 — the sub-castle | Port town and the lord who administers the tiered law, and privately loathes it |
| 7 | **Cairnwell** | Centre-north-west | 6 — the bank | The capital. Money, debts, the creditor the king fears |
| 8 | **Blackcairn** | North-west, against the mountains | — | The castle. The king. Reachable from minute one |

**Optional zones** (cut first if behind): **The Redcut**, the iron quarry in the
eastern mountains — cutting the Cinderworks' ore supply; **the Thornwood depths**,
wild and unpatrolled, where things that are not people live.

### The opening 🟡

The player wakes in Brindle, and from the first screen can see the Cinderworks
smoking on their village's ground, half an hour's walk away. No exposition is
needed: the crime and the industry it served are in the same frame.

The King's Road runs past Brindle toward Harrowgate. A player who follows it
north-west reaches the castle in ten to twenty minutes and can attempt the king
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
  a new way; the ledger in Pillar 1 shows he knew.
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

**The Cinderworks — Pillar 1**

| Name | Role | Holds |
|---|---|---|
| ★ **Foreman Halgrave** | Runs the works. Believes in them, completely | The death ledger. He keeps it because the crown requires it, and because he thinks the record matters. He is not hiding it — he is *proud* of the accounting |
| **Sena** | Furnace worker, lost a hand, organising the others | Copied pages of the ledger. Second source |
| **Doctor Ivo Marsh** | The works' physician; signs the certificates | The true count, including the ones that never reached the ledger. Third source |

**Harrowgate — Pillar 5, the first town**

| Name | Role | Holds |
|---|---|---|
| **Maddox** | Innkeeper. Knows everyone, believes nothing | Gossip hub — the cheapest entry point to almost any thread |
| **Tovin the Reeve** | Administers the tiered law locally, apologetically | How the law is applied in practice, and to whom |
| **Bell** | Apprentice scribe; copies the law for the town | Has the wealth tiers memorised. Tier 0 in a fight |
| **Ossa** | Herbalist. Treats everyone, including deserters | Where Kell is hiding |
| **Garrick** | Caravan master, moves between zones | The ford. Also carries rumour physically across the map |

**The Wide Acres — Pillar 2, the farms**

| Name | Role | Holds |
|---|---|---|
| ★ **Estate Lord Cadan Vale** | Holds the land grants | The grants naming razed villages, Brindle among them |
| **Nessa Vale** | His steward and daughter; keeps the actual paperwork | The same grants. Second source, and easier to reach |
| **Old Pell** | Tenant farmer. Worked Brindle's soil before the burning and after | That this ground was Brindle. He knew the player's family. He does not recognise the player |

**The Muster — Pillar 3, the army**

| Name | Role | Holds |
|---|---|---|
| ★ **Commander Ryse** | Led the clearances. Sleeps fine | The signed orders, and the names of the men who burned Brindle |
| **Quartermaster Odile** | Running the pay fraud | The muster rolls, and her own crime — leverage |
| **Kell** | A deserter hiding in the Thornwood. He was at Brindle that night | The orders, from memory. And what actually happened. The closest thing to a witness the player will ever find |

**Saltmarch & Greyhold — Pillar 4**

| Name | Role | Holds |
|---|---|---|
| ★ **Lord Aurel Greyhold** | Administers the tiered law. Privately believes it indefensible | How it is enforced, and his own disgust — the softest ★ to turn |
| **Harbourmaster Til** | Smuggler by preference | What leaves the region, and by whose order |
| **Mira Sand** | Advocate for the poor under the tiered law | Documented effects, case by case. Evidence with faces on it |

**Cairnwell — Pillar 6, the capital**

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

**Redundancy rule (hard):** every fact required for any route has **at least two
independent sources**. No single NPC's death may remove a fact from the world.

**Reachability test (hard).** The headless harness must be able to kill every NPC in
every combination and assert that at least one route to the confrontation remains
open. Pillar 3 is not a wish; it is a test that runs in milliseconds and fails the
build.

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
| 9 | Army strength | Pay, food, desertion | Pillars 2, 3, 6 |
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

**The king fight:** phases and tells, with knowledge from Pillar 3 changing what the
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

**Approved asset packs:** TBD

**Resolution & pixel grid:** TBD — internal resolution, tile size, character height.

**Palette:** TBD — number of colours, ramps, the rule for when a colour is allowed.

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

TBD — see the agreed phase plan: vertical slice, simulation core, deterministic
dialogue, runtime model, art layer.

---

## 19. Open questions

| # | Question | Raised | Blocking? |
|---|---|---|---|
| 1 | The king's name, and the region's | 2026-09-10 | Naming |
| 2 | Why attempt #1 fails — the exact first-attempt experience | 2026-09-10 | It's the tutorial |
| 3 | ~~Route C's venue~~ — answered: the church, before Mother Crowe's congregation | 2026-09-10 | Closed |
| 4 | The levelling curve: target endgame HP and damage scaling | 2026-09-10 | Yes — combat |
| 5 | What happens when the player dies? | 2026-09-10 | Yes |
| 6 | Trait point pool size (12?) | 2026-09-10 | |
| 7 | Is the 9×9 screen grid the right scale? Only walking it will say | 2026-09-10 | Tune in Phase 0 |
| 8 | The five consequences that specify the reactivity system (§8) | 2026-09-10 | |
| 9 | Approved asset packs | 2026-09-10 | Blocks the art pass |
| 10 | Can facts be wrong? Rumours, lies, misinformation | 2026-09-10 | |

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
