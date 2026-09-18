# The simulation model — v1

Date: 2026-09-18. Yannick's design, written down by Claude as it was settled.
**Draft: settled where it says settled, open where it says open.** No code has been
written against it.

What it replaces is recorded in [SIMULATION_AS_BUILT.md](SIMULATION_AS_BUILT.md).
Read that to know what is being given up; read this to know what is being built.
What survives it is proposed in
[SIMULATION_KEEP_OR_DROP.md](SIMULATION_KEEP_OR_DROP.md).

**Scope: this is the simulation of *places*.** How the player influences it, and what
the player's own reputation and status are, is a second document Yannick will draft
(2026-09-18). The direction is already set and it is a good one: **treat the player as
a town, with a status of the same shape.** Same two values, same thresholds, same ways
of moving — nothing new for anyone to learn.

## The rule that governs every decision below

**Many simple systems that combine, never one complicated system** (Yannick,
2026-09-17). If a gameplay or simulation rule stops fitting in a sentence, it is
wrong, and the fix is to split it rather than to document it better.

A second rule, and it is the point of the whole model: **the numbers must be
locatable.** The model it replaces has twelve quantities for the whole kingdom —
`faction_tension`, `bank_confidence`, `patrol_density` — abstractions no player can
go and look at. This model has twelve too, and every one of them belongs to a place a
player can stand in and see. **The gain is not fewer numbers. It is numbers with an
address.**

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

**Five places carry them.** The Cinderworks, the Wide Acres, Harrowgate, the Muster
and Saltmarch. Brindle does not (below), and Cairnwell and Blackcairn do not because
together they are the kingdom (§2).

**Brindle is outside the system** (Yannick, 2026-09-18). It is a ruined village with
one inhabitant: it carries no values, sends nothing and receives nothing. The door
this closes, knowingly: **the model cannot show Brindle recovering.** Reopening it
later means giving Brindle the two values like anywhere else, which is cheap in code
and not free in design — a village that can be rebuilt is a different game from a
village that stands as the reason you set out.

## 2. Two values for the kingdom — settled

**There is one kingdom, and it is the king's castle plus the castle's city**
(Yannick, 2026-09-18): Blackcairn and Cairnwell together. They do not carry a
place's two values; they carry the kingdom's:

**The kingdom has the same shape as a place** (Yannick, 2026-09-18): two numbers, and
those two decide how it looks. One rule learnt once and used twice.

| Value | Fed by |
|---|---|
| **Allégeance** | The average of the allégeance its places send it. *Toutes les villes envoient une valeur d'allégeance* |
| **Trésor** | The **sum of the goods** the places send — food, steel, later wood — normalised onto the same 0–10 scale. The works sends 8 of steel and the farm 7 of food, so the trésor is 7.5 |

**Force is a reading of those two, not a third number.** It can be worked out from
allégeance and trésor, so it carries nothing of its own, and the whole game stays at
twelve numbers rather than thirteen. It is what the confrontation will read: how hard
the king is to put down.

**And the capital is read like any other place**: allégeance × trésor, the same four
appearances, the same thresholds. A player who has learnt to read a town has learnt to
read the kingdom. What those four look like — and the routines of the people in the
capital — is a spec of its own, and his brother's work; the rules are what is settled
here.

**Two goods in v1, food and steel.** Wood waits for the sawmill, which is neither
ingested nor in the demo; when it arrives it is **the fuel steel is made with**, which
is its true relation, and it is one line rather than a third flow.

**The king himself has no state.** His kingdom has one, and it shows on him: his
royal guard, who stands at the gate, and what the capital looks like.

**Twelve numbers in total.** 5 × 2 + 2 — and no more, because force and the four
appearances are readings of those twelve rather than numbers beside them.

**Which way the arrows go, checked in the code on 2026-09-18.** Today only one of the
two exists: **place → kingdom**. Nothing the kingdom does can change a place's numbers,
because the kingdom's own two are *derived* and `KingdomRules` writes nothing anywhere.
The complete list of what can move a place's richesse is the `move_town_value` event
and the `UNCROWNED_TOWN` debug hook, and nothing else.

**M5 is that missing arrow**, and after it the answer changes on purpose: destroy the
farms, the crown's trésor falls, the works is fed worse, its richesse drifts down over
days, it crosses the threshold and furnaces go out. **With one limit, Yannick's own**:
food never falls below a floor in v1, so the kingdom can make a works suffer and cannot
starve it to death. The player stays responsible for what they break.

**One place is one fifth.** With five places, a quest that moves the works' allégeance
by 3 moves the kingdom's by 0.6, and its force by 0.3 of 10. **That is intended**
(Yannick, 2026-09-18): a change in steel does not change the other towns and the crown
stays nearly as strong. The demo's feedback is not about force — it is about the steel
supply, which falls from 4 to 1 and is loud. A weighting, so that one place counts for
more than another, stays open and is one line when it is wanted.

**Open:** a kingdom whose every place has turned is a king alone in his own capital.
Yannick wants a guardrail against allégeance reaching 0 everywhere, and hardcoded rules
for what happens if it does. Neither is designed, and it is not the demo's problem. (It read fourteen until M1 was built and the
count was done against the code: Brindle had already been ruled out of the system and
the arithmetic had not followed.)

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
redistributes **food and weapons, and nothing else in v1** (§7). A place never sends
anything to another place.

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
   **And the kingdom redistributes what it receives — it never creates** (Yannick,
   2026-09-18). A place can only grow rich on what another place produced, so *help
   the farms and the ironworks feels it* is a trade rather than free money, and
   nothing drifts to 10 everywhere unless the player has helped everywhere. It is
   also what the old model got wrong: everything started at its ceiling, so building
   the kingdom up could not be felt.
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

**A routine is a destination, not a timetable** (Yannick, 2026-09-18). It is simpler
than a clock and reads just as well:

> The ironworks is running and loyal → twenty people set out for the mine and come
> back. The ironworks has stopped → they are redirected to the riverside or the
> forest, **or they are simply gone.**

Removing people is the cheapest signal in the whole model and the strongest.

**Their lines change with the state, and they belong to the place** (Yannick,
2026-09-18). Lines are **not** shared between towns with a word swapped for the local
trade — that was proposed and rejected, rightly: a farmer and a furnaceman do not
speak alike whatever their richesse or allégeance, and a town that talks like the
next one undoes the half of the model that gives places an identity. **Variety is
wanted from the start, and most of all variety by place.**

Ten sentences per state, four states, so **forty per town**, each written for that
town. For the demo's one town that is 40 lines in two languages — and the five other
towns cost what they cost, when we know how they sound.

**They need no names.** The codebase already has *strangers* — eight people addressed
by their role rather than a name — which is exactly this second family.

**Every line of dialogue already in the game is to be rewritten** (Yannick,
2026-09-18): the 93 options and 21 reactions in the cast sheets were written fast and
do not hold up. The roles may survive as a starting point; the writing does not.

## 5. What moves the two values — settled

**One value belongs to the player, the other belongs to the world.**

| Value | What moves it |
|---|---|
| **Allégeance** | **The player's act, and nothing else.** It never drifts |
| **Richesse** | The player's act, **and** a slow drift, **both ways**, on what the kingdom sends the place |

Allégeance is the moral spine: it is who this place is *with*. If it drifted on its
own, the player's choice would dilute and a town could turn back with nobody having
done anything. **It is a decision, not a weather system.**

Richesse is what makes the star do any work at all. It is what carries *destroy the
farms and the ironworks feels it*, which is the thing the whole model was built for.

### How far an act moves a value — settled for v1

**±3, against a threshold at 5.** The threshold is what turns a number into an
appearance — above 5 a place reads as loyal or rich, below it as hostile or poor —
and ±3 is chosen so that **an outcome always crosses it**. The criterion is
legibility, not balance: a choice the player cannot see is not a choice.

Worked on the Cinderworks, which starts at 7 and 7:

| | Allégeance | Richesse | What it reads as |
|---|---|---|---|
| **At the start** | 7 | 7 | loyal and rich |
| **I back the workers** | 4 | 4 | **hostile and poor** — both axes turn |
| **I back the management** | 10 | 9 | loyal and rich, locked in |

The numbers are hardcoded and live in one table, so re-balancing is one line
(Yannick, 2026-09-18). Accepted with its limits for v1.

### The hole this leaves, and why it is left

A workers' victory means they stop risking their lives (good) and lose their wages
(bad). Richesse falls, so **the bad is represented and the good is not**.

**It stays that way on purpose.** The good is shown by the routines and the lines —
the people are alive, they are at the riverside instead of at the furnace, and they
say so. That is exactly what the second family of NPCs is for.

> The two numbers run the world. The human truth is in what people do and say.
> **Not everything that matters has to be a number.**

## 6. Where the player enters — settled

**One quest per place. Two outcomes. Each outcome has something good and something
bad in it.**

That is the whole hook, and it is the same at every place, which is what makes
extending the model a matter of adding data rather than writing code.

**A quest starts in conversation** (Yannick, 2026-09-18): the player talks to the
place's key NPCs and **explicitly chooses certain actions** with them. There is no
document to find and read aloud — that mechanism is deleted (see the keep-or-drop
review). What the chosen action then *is*, physically, is A1's question.

Worked example, the Cinderworks, and the demo's own quest:

> Either I help the workers free themselves of their chains — with positive and
> negative consequences — or I help the industry become stronger — with positive and
> negative consequences.

An outcome moves that place's two values, and the place then sends its new
contribution to the kingdom, which redistributes. Nothing else is needed for an act
to be felt across the map.

**Open: how much an outcome moves a value**, and whether it moves both.

---

## 7. What the kingdom redistributes — settled

**Food and weapons, and nothing else in v1.** The first draft's diagram said "food
distribute ⊕ weapons ⊕ etc"; the *etc* is exactly where complexity gets in, and two
flows are enough to carry every consequence the demo and the first quests need.

---

## What is still open, gathered

Nothing of the model itself. What remains is tuning, and tuning is done by playing:
the exact ±3, the exact thresholds, the weighting inside **force**, and the
normalisation that puts **trésor** on a 0–10 scale. All of it lives in one table.

**Closed since the first draft:** Brindle (outside the system), what a routine is (a
destination), what the kingdom redistributes (food and weapons), what feeds the
kingdom's two values, how lines are written (by place, never shared), and the first
draft's "average of three drives" — which dissolved when the place's four values
became two, since `strength` and `happiness` no longer exist to be averaged.

## What this does not say

It says nothing about combat, about dialogue, or about the endings. It says nothing
about which parts of the existing simulation are kept — that decision follows this
document, using [SIMULATION_AS_BUILT.md](SIMULATION_AS_BUILT.md) as the inventory,
and it is a decision per component rather than a single verdict.
