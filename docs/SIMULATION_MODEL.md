# The simulation model — v1

Date: 2026-09-18. Yannick's design, written down by Claude as it was settled.
**Draft: settled where it says settled, open where it says open.** No code has been
written against it.

What it replaces is recorded in [SIMULATION_AS_BUILT.md](SIMULATION_AS_BUILT.md).
Read that to know what is being given up; read this to know what is being built.

## The rule that governs every decision below

**Many simple systems that combine, never one complicated system** (Yannick,
2026-09-17). If a gameplay or simulation rule stops fitting in a sentence, it is
wrong, and the fix is to split it rather than to document it better.

A second rule, and it is the point of the whole model: **the numbers must be
locatable.** The model it replaces has twelve quantities for the whole kingdom —
`faction_tension`, `bank_confidence`, `patrol_density` — abstractions no player can
go and look at. This model has fourteen, which is barely fewer, and every one of them
belongs to a place a player can stand in and see. **The gain is not fewer numbers.
It is numbers with an address.**

---

## 1. Two values per place — settled

Every place carries exactly two, each **out of 10**:

| Value | What it means |
|---|---|
| **Allégeance** | How far this place is with the king, or against him |
| **Richesse** | How well this place is doing |

Nothing else. `strength level` and `happiness` were in the first draft and are cut:
strength belongs to the kingdom, not to a town, and happiness was doing the same job
as richesse. The draft's own visual grid used only these two.

**Six places carry them**, because the seventh and eighth are the kingdom (§2):
Brindle, the Cinderworks, Harrowgate, the Wide Acres, the Muster, Saltmarch.

**Brindle is an open question.** It is a ruined village with one inhabitant. Is its
richesse simply 0, or is a ruin outside the system until it is rebuilt? The answer
decides whether the model can ever show Brindle recovering.

## 2. Two values for the kingdom — settled

**There is one kingdom, and it is the king's castle plus the castle's city**
(Yannick, 2026-09-18): Blackcairn and Cairnwell together. They do not carry a
place's two values; they carry the kingdom's:

| Value | Fed by |
|---|---|
| **Force** | What the places send — steel above all |
| **Trésor** | What the places send — food, and what they are worth |

**The king himself has no state.** His kingdom has one, and it shows on him: his
royal guard, who stands at the gate, and what the capital looks like.

**Fourteen numbers in total.** 6 × 2 + 2.

## 3. The star — settled

**Everything is centralised, and no place ever talks to another place.**

```
   Wide Acres ─── food ──┐                  ┌── food ──→ Cinderworks
   Saltmarch  ─── … ─────┤                  │
   Harrowgate ─── … ─────┼──→  THE KINGDOM ─┼── … ────→ Harrowgate
   Muster     ─── … ─────┤    (castle +     │
   Cinderworks ── steel ─┘     capital)     └── … ────→ every other place
```

Each place sends what it produces **and its allégeance** to the kingdom. The kingdom
redistributes — food, weapons, and what else the design later needs. A place never
sends anything to another place.

This is the single most important simplification on the page: **eight places make
eight links instead of sixty-four.** Keep it even when it itches.

### What this buys, and it is what Yannick wanted from the start

Effects reach across the map *through the kingdom*:

> Destroy the place that grows the food → less food in the kingdom → less food in
> **every** place.
>
> Stop the ironworks → less steel in the kingdom → fewer weapons → the soldiers in
> every place are weaker.

That is city → kingdom → cities. It is not a loop, because no place ever changes
another place directly, and every hop is one the player can be told in a sentence.

### Three guardrails, so it cannot run away — settled

1. **Propagation is always place → kingdom → places.** Never place → place.
2. **Every value has a floor and a ceiling.** Food in particular can never fall below
   a threshold in v1 (Yannick, 2026-09-18). Without floors a bad turn becomes a
   spiral nobody can stop, and the player watches a machine instead of playing.
3. **Propagation takes days, not an instant.** A consequence the player did not see
   *arrive* is a consequence they find already there, and it reads as the game having
   always been that way. This is what makes the demo legible: the furnaces go cold
   now, and somebody tells you the crown is short of steel later.

## 4. What the two values drive

### The look of a place — settled in principle

**Allégeance × richesse = four appearances**, and a colour cast on top: **warm and
bright where the king is supported, cold where he is not** — which amounts to the
king's banner being up or down.

| | Riche | Pauvre |
|---|---|---|
| **Allégeance haute** | 1 | 3 |
| **Allégeance basse** | 2 | 4 |

**These are not four versions of every building.** The first draft said "graphics
every house", and the bill for that is 27 buildings × 4 states for the ironworks
alone. Instead the state switches a small number of **signals** that combine:

| Signal | Driven by |
|---|---|
| Fire, glow and smoke at the furnaces | richesse |
| Shutters, repairs, the state of the roofs | richesse |
| The king's banner, the guard's presence | allégeance |
| The colour cast, warm or cold | allégeance |
| People working, idling, or gone | both |

**Four or five signals at two positions give sixteen-plus readable appearances from
a handful of assets**, instead of four towns redrawn. It is the "simple systems that
combine" rule applied to art, and it is what makes the model affordable for one
artist. One signal already works: his furnaces go cold today.

Yannick is asking his brother to reduce the building count; the signal approach is
what he meant by physical appearance.

### The NPCs — settled in principle, open in detail

**Two families:**

| Family | What they are | What the state does to them |
|---|---|---|
| **Key NPCs** | A real role in the kingdom or the story. They *perform acts*: grant papers, convene a meeting, call a shift back | Their availability and what they will do for you |
| **Routine NPCs** | The place's texture | **Their routine changes with the place's state** |

The second is the new idea and the best one on the page, because it makes a
consequence visible without a line of text: **a place that has stopped is a place
where people have stopped doing what they were doing.**

**Open: what a routine is, in v1.** The recommendation is *where someone stands at
what hour*, not what they animate — it asks nothing new of the artist and already
shows a town at work or at a standstill.

## 5. Where the player enters — settled

**One quest per place. Two outcomes. Each outcome has something good and something
bad in it.**

That is the whole hook, and it is the same at every place, which is what makes
extending the model a matter of adding data rather than writing code.

Worked example, the Cinderworks, and the demo's own quest:

> Either I help the workers free themselves of their chains — with positive and
> negative consequences — or I help the industry become stronger — with positive and
> negative consequences.

An outcome moves that place's two values, and the place then sends its new
contribution to the kingdom, which redistributes. Nothing else is needed for an act
to be felt across the map.

**Open: how much an outcome moves a value**, and whether it moves both.

---

## What is still open, gathered

1. **Brindle in ruins** — richesse 0, or outside the system?
2. **What a routine is** in v1.
3. **How far a quest outcome moves a value.**
4. **`strength level` as one variable for steel and wood** — Yannick's first draft
   folded both into one number. Cut from §1 as a place value; whether the kingdom's
   **force** should be fed by wood as well as steel is not decided.
5. **The "average of three drives"** of the first draft — parked by Yannick as
   possibly too complex, to be revisited when the simulation rules are planned.
6. **What the kingdom redistributes beyond food and weapons.**

## What this does not say

It says nothing about combat, about dialogue, or about the endings. It says nothing
about which parts of the existing simulation are kept — that decision follows this
document, using [SIMULATION_AS_BUILT.md](SIMULATION_AS_BUILT.md) as the inventory,
and it is a decision per component rather than a single verdict.
