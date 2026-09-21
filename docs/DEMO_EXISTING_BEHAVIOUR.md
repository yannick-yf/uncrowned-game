# What the demo's first two needs already do

> **Superseded, 2026-09-18.** Its measurements hold — six dialogue options of ninety-three
> read a trait, three of six traits are read by nothing — and they are what argued for the
> redesign. Its keep/adapt/replace verdicts are replaced by
> [SIMULATION_KEEP_OR_DROP.md](SIMULATION_KEEP_OR_DROP.md), and its five cards by
> [DEMO_TASKS.md](DEMO_TASKS.md).

Date: 2026-09-16. Author: Claude, for Yannick.

## Why this document exists

Yannick asked on 2026-09-15 whether much of the simulation should be deleted and
rebuilt, keeping his brother's 3D foundation, because systems written fast may not
match the game he means. The answer to that question is not an opinion about the
codebase; it is a verdict per component, against a concrete thing the player must
be able to do. This is the first such pass, over the demo's **two earliest needs**:

1. **Creation** — the screen the demo opens on (route row R01).
2. **The first conversation and the dispute it belongs to** — the Cinderworks
   workers-versus-management quest (R05–R09).

Nothing here is authorized work. Nothing here was changed: this pass read source
and measured the checked-in bake headless. Its verdicts are **keep / adapt /
replace / outside the demo**, and "outside the demo" never means "delete from the
full game". Route facts and frames are in [the walkthrough](DEMO_WALKTHROUGH.md);
scope and attributed decisions are in [the audit](V2_VISION_AUDIT.md).

Measured on `6b71e3e`, baked world, pace 2.50 tiles/s. Fast suite green at the
time: 34 suites, 345 tests, 10,380 assertions, 0 failed, 3 map debts, 2 switched
off, 9,147.9 ms.

---

## 1. Creation

### What is there

[`TraitRules`](../core/rules/trait_rules.gd) is a small, closed design and a good
one: six traits, floor 1, cap 5, a pool of 10, `SPEAKS_AT = 3`, and traits that
**never rise**, which is what keeps a trait gate from being the progression check
invariant 4 forbids. `why_not()` returns the reason the button refuses rather than
a bool. [`CreationSystem`](../core/systems/creation_system.gd) applies the choice
through the simulation, and the run's save is written at creation.

The six have real French voices already: *Esprit*, *Prestance*, *Colère*, *Mains*,
*Corps*, *Accord*, each with a note — *« Vous savez comment marchent les fours, les
champs et les registres »* for Mains, and so on.

### What it is worth in play, measured

| Trait | What reads it today | Reach |
|---|---|---|
| **Esprit** (wits) | `DialogueRules` gates an option tagged `Wits` at level 3 | **5 options of 93** in the cast |
| **Colère** (temper) | The same gate | **1 option of 93** |
| **Accord** (attunement) | `MovementSystem` — off-road walking speed only | **Nothing**, while `Region.TERRAIN_SLOWS_YOU = false` |
| **Prestance** (presence) | — | Nothing reads it |
| **Mains** (hands) | — | Nothing reads it |
| **Corps** (body) | — | Nothing reads it |

Method: `Traits.level_of()` has no caller outside its own file; `speaks_with()` has
exactly one, [`dialogue_rules.gd:137`](../core/rules/dialogue_rules.gd#L137);
`is_attuned()` has exactly one, [`movement_system.gd:31`](../core/systems/movement_system.gd#L31).
Tag counts are from `content/cast.fr.json` and `content/cast.en.json`, which agree.

### The verdict

**Keep the engine. The gap is content and combat, not architecture.** The creation
screen asks the player to become a particular person, and the game can currently
honour that claim in six lines out of ninety-three, for two traits of six — with
the third, Accord, switched off by a testing switch and the other three waiting on
a combat system that does not exist. That is not a wrong design; it is an unwired
one, and rebuilding it would rebuild the part that is right.

**What this means for the demo.** Restoring the screen (Y04) is the smaller half of
R01. The question the demo has to answer is *what a trait buys in the demo's own
hour* — and the honest options are to wire a few (the dispute is a natural place
for Esprit and Colère, and combat for Corps and Mains), or to show fewer traits in
the demo than the full game will have. Both are Yannick's call; neither is a
rewrite. **Do not present six defining choices the demo cannot honour.**

---

## 2. The first conversation, and the dispute it belongs to

### What is there — more than the backlog assumes

The Cinderworks dispute is **already written in French, with three voices and the
redundancy invariant 6 asks for**:

- **Contremaître Halgrave** — management. Gives the death toll (381 in 11 years)
  freely, keeps the register, and offers `settle_wage`.
- **Sena** — a worker, injured at furnace four six years ago, paid eleven days'
  wages. Offers `ask_organise`: *« Je n'ai jamais eu de chiffre à leur donner.
  Personne n'arrête de travailler pour un sentiment. 381, c'est différent. »*
- **Docteur Ivo Marsh** — the independent account: the register is *« honnête et
  faux »*, because it counts the men who die at the furnaces and not those who die
  at home eighteen months later, coughing.

**The fact `cinderworks:death_toll` has three sources** (Halgrave `ask_cost`, Sena
`ask_toll`, Ivo `ask_true_count`). The evidence side of Y15 is largely built, and
killing any one of the three leaves it reachable.

**The ledger is a place, not a person.** `cinderworks:ledger` lies at
`cinderworks+(-4,7)` → tile (305,220); `ActSystem` picks it up where it lies, and
`DocumentRules` guarantees nothing can take it off you.

### The three resolutions that exist today

| Chain | What the player does | What the world does |
|---|---|---|
| **A — free the works** | Take the ledger at (305,220), then read it aloud inside the Cinderworks (`TellingSystem` → `document_read`, `PlaceRules.frees`) | The works goes **free**. The furnaces go **cold** and the entrance line changes — *this is the visible shutdown, and it renders today* |
| **B — the workers' lever** | Sena's `ask_organise`, which requires the death toll | `i_turned_the_workers`: `steel_output −15`, `worker_morale −30`, `town_sentiment −10`, hardship `cinderworks +12`. **The works stays crown-held and the furnaces stay lit** |
| **C — management** | Halgrave's `settle_wage`, which requires the **ledger** | `i_settled_the_wage`: `worker_morale +22`, `steel_output +8`, `crown_treasury −8`, hardship `brindle +10`, `cinderworks −12`. The works is **held** |

### The four findings

1. **The demo's workers' victory is chain A, not chain B.** Yannick confirmed that
   a workers' victory *stops production*. Stopping production is what freeing the
   place does; the deed actually named "I turned the workers" moves a number and
   leaves the furnaces burning. The demo needs these to be **one outcome**, and
   deciding how is a design act, not an implementation detail.
2. **Both resolutions are things you say.** Chain A ends in speech, chain C ends in
   speech. Taking the ledger is a real act at a real tile, which is more than the
   audit's G07 credits — but the *deciding* moment is still a dialogue option, and
   Yannick asked for a resolution the player has to go and perform. This is the
   single largest gameplay gap between what exists and what the demo promises.
3. **Lost wages are not modelled as wages.** The nearest thing is hardship at the
   Cinderworks (`+12` under chain B) and `worker_morale`. If a worker must say
   *"we are not paid now"* and mean it, the demo needs either a quantity that says
   so or an explicit agreement that hardship is what it means.
4. **A free sabotage stands beside the quest.** *« E, éteindre le four »*
   (`i_wrecked_a_furnace`) is offered at every furnace with no gate, and
   `QuestRules` already treats it and `i_turned_the_workers` as two ways to finish
   *the_wood_is_going*. A player can stop the clearing without meeting anybody.
   That is the open world working as designed, and it is also a demo whose quest
   can be bypassed in ten seconds by the first thing the player walks past.

### The verdict, per component

| Component | Verdict | Why |
|---|---|---|
| `Sim`, the event log, replay, `SaveFile` | **Keep** | Determinism and save-by-replay are the foundation the demo's persistence check (Y21) stands on. Nothing found argues against them |
| Anchors, `Places`, `Region.resolve` | **Keep, extend by one form** | The anchor contract is what let the ironworks delivery land without touching content. It cannot yet name his stable building ids — GAP-04, one bounded change |
| `DocumentRules` / `ActSystem` (evidence as a place) | **Keep** | It already gives the demo a physical evidence act and satisfies invariant 7 |
| The three voices and the death toll's redundancy | **Keep as structure, review as writing** | The roles and the three-source fact are right. The names, the recent history and whether these are the demo's cast is Yannick's editorial call (Y02) |
| `PlaceRules` two-state model | **Adapt** | It is what makes the shutdown visible. Whether "free" is the demo's workers' victory is finding 1 |
| `DeedRules.world_effects` for the two levers | **Adapt** | The numbers exist and are in one table, which is the right shape. They do not yet say what Yannick confirmed |
| Resolution by dialogue option | **Replace for the demo** | Finding 2. The replacement is an act at a place, not a new quest system |
| Ungated `i_wrecked_a_furnace` in the demo's yard | **Decide** | Finding 4. Gate, remove from the demo, or let the quest own it — all three are defensible |
| Combat | **Absent** | `ContactSystem` is the king's contact damage, the project's oldest standing exception. Nothing here is a foundation to extend |

**Nothing in this pass argues for a wholesale rewrite.** It argues that the
simulation's *spine* — events, facts, replay, anchors, documents, one table of
effects — is worth keeping and is the reason the ironworks delivery cost an
afternoon rather than a week, and that the *policy written on top of it* (what an
act is, what an outcome is, what a trait buys) is where the game diverges from
Yannick's description. That is a content-and-rules conversation, and it is
cheaper than a rebuild, not more expensive.

---

## 3. The first session-sized cards this produces

Proposals for Yannick to accept, re-order or cut. Each one is one session
including review and its check. **None is started.** Estimates are first-pass.

### S1 — An anchor can name one of his buildings by its stable id

Owner: Yannick + the map-ingestion agent (Claude). Estimate: 2 h. Depends on: —.
Files: `core/places.gd`, `core/region.gd`, `test/test_anchors.gd`.

**Player-visible result:** none directly — this is the foundation S2 needs, and it
is listed because without it every demo placement is a bet on prop order.

**Existing behaviour:** `Region.resolve` matches a `feature` by **kind** and returns
the *first* prop of that kind in the place. Halgrave stands at `FourneauUn` only
because it is first in the baked list; the bake already carries `source_id` on all
74 delivered ironworks props.

**Small change:** accept `{"place": …, "prop": "BureauPesee", "offset": [dx, dy]}`
as a third anchor form, resolving against `source_id`.

**Exact check:** a new test resolves a `prop:` anchor to (310,218) and
`unresolved_anchors()` names it — **by name** — when the id is absent. Both full
suites green.

**Ownership note:** `core/` is Codex's lane and the bake is Claude's. This card
touches `core/`. Assign it to one agent explicitly before it starts.

### S2 — The three speakers stand where the demo meets them

Owner: Yannick + agent. Estimate: 1 h. Depends on: S1, and B01's chosen spots.
Files: `content/places.json`, `test/test_anchors.gd`.

**Player-visible result:** walking into the inhabited quarter, the player finds
someone to talk to. Today the quarter is empty and all three resolve into the
production band.

**Exact check:** the three anchors resolve within one tile of their named building;
`tools/shot.sh out.png play 299,206` shows the speakers standing there.

**Blocked until** slosinio and Yannick pick the spots (B01). Do not pre-empt it.

### S3 — Decide what the workers' victory is, in the rules' own terms

Owner: Yannick, on paper. Estimate: 2 h. Depends on: —. Files: none yet.

**Result:** a written decision answering findings 1–4 above: which chain is the
workers' victory, whether `i_turned_the_workers` frees the works, what "they lose
their wages" is among the twelve quantities, what the deciding physical act is,
and what happens to the ungated furnace sabotage during the demo.

**Exact check:** a design review with the two paths walked on paper, each with an
act beyond speaking, a cost, and a visible result — then a SPECS §20 entry
*prepared*, not applied. This is the narrowed form of Y01: the open questions are
now four, not "design the quest".

### S4 — A fresh run reaches the fairy through creation

Owner: Yannick + agent. Estimate: 2 h. Depends on: —. Files: `view/screens.gd`,
`test/test_screens.gd`.

**Player-visible result:** starting the game gives the title screen and creation,
and the traits chosen are the traits the run has. The development quick launch
survives as its own path.

**Exact check:** a fresh run, allocate the pool, meet the fairy; quit, rest, and
Continue; in French and in English. `tools/shot.sh out.png creation`. Both suites
green.

**Note:** this restores *access*. Whether six traits should be offered in a demo
that can honour two is section 1's question, and is S5.

### S5 — Decide what a trait buys in the demo's hour

Owner: Yannick, on paper. Estimate: 1 h. Depends on: S4, and section 1's table.

**Result:** a decision on whether the demo wires more traits into the dispute and
the fight, or offers fewer traits and says so. Either closes the gap between what
creation promises and what the demo can deliver.

**Exact check:** a review against the measured table above; the chosen traits each
name where they are read.

---

## 4. What this pass did not look at, and still matters

This was two needs of the demo. **The full-v1 milestone is not addressed here at
all** and must not be assumed feasible because a demo backlog exists: the other
places' quests, the cast's authored identities, combat depth, the confrontation
and the endings, and the audit's unreconciled conflicts (the loyal conservation
route, the opening's silence about the king, the fixed combat presentation) remain
open. The next passes of this same kind that the demo needs are combat's absence
(nothing to review — it must be designed) and the journal and kingdom feedback
(R09's second half).
