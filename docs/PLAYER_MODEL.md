# The player's own simulation

Settled with Yannick on 2026-09-23, and it is the piece `SIMULATION_MODEL.md` left
open: that document simulates *places*, and said the player would be treated as a town
with a status of the same shape. This is that draft.

**It does not restate the simulation's rules.** Where the player follows a rule the
kingdom already has, this document points at it. Two documents holding one rule is how
they come to disagree.

**Status: a draft for Yannick.** Section 7 holds what is still open. Nothing is built.

---

## 1. The decision, in one line

**The town is the unit of account.** A deed moves the standing of the *place* it
happened in. It does not move the opinion of the person it happened to.

Yannick, 2026-09-23: *"on traite le joueur comme une ville et du coup les NPC itself
ne sont pas dans l'équation. En gros je vole quelqu'un, alors pour le player,
reputation city 1 −10."*

A per-person ledger is a second economy to balance, and the player cannot see it —
they can see a town turn cold.

## 2. What the player is made of

Three dimensions. **The player is shaped like a town**, which is the whole idea:
something you decide, and something that moves with what happens.

| | What it is | Where it lives | Moves how |
|---|---|---|---|
| **Allégeance** | The side the player *chose*. Visible to everyone | `core/allegiance.gd`, `side` — **exists** | Only when the player says so. Never drifts |
| **Standing, per town** | What each place thinks of the player | `core/standing.gd`, `by_town` — **exists** | By deeds done there, and only by deeds |
| **Richesse** | **The gold the player has.** One number | **new — see §6** | By earning, taking, being given, spending |

The first two were already written with the right split, in September:

> *"Joining is deliberately **not** standing. Standing is what a place thinks of you
> and it moves on its own; this is a thing you chose."* — `core/allegiance.gd`

**Only those two readings survive of those two files.** The factions and the court
ranks go — Yannick ruled it on 2026-09-18 in `SIMULATION_KEEP_OR_DROP.md` (*"`Standing`,
`Allegiance`, faction ranks — none of this file survives in its present shape"*),
confirmed on 2026-09-23 (*"on supprime les factions, ça vient du jeu en 2D"*), and the
work is **task C3**, whose dependencies Q1–Q6 are all built. So `Standing.by_faction`,
`FactionRules.rank_from`, `Allegiance.last_rank` and the tests that prove them go with
C3; `by_town` and `side` are what this model keeps.

`by_person` goes too. A witness's opinion diverging from their neighbours' was a good
idea and it is not this model's: a deed moves the town it happened in.

**Richesse is money, and nothing more** (Yannick, 2026-09-23). It is how much gold the
player has. `SPECS` §12 already settles the currency — *"Currency: gold. The king's is
in the bank — one of the six pillars."* — so this adds a purse, not an economy.

It is deliberately the simplest of the three: one integer, and a town reads which band
it falls in.

> **What richesse is *not*, so the line stays clear.** `SPECS` §12 also says
> *"equipment matters mechanically in combat, for the player and the opponent, and is
> visible to NPCs (feeding appearance, §8)"*. **Appearance is a separate thing** — what
> the player is wearing and carrying — and it is not in this model. Richesse is the
> purse; appearance is the picture. Conflating them was an error in this document's
> first draft.

## 3. What moves the town's standing

One rule, the one the code already states: **a change names who is offended and who is
impressed.** A deed never only costs.

The scale is the existing one, −100 to +100, and Yannick's two worked examples set it
end to end (2026-09-23):

| Deed | In the town where it happened |
|---|---|
| A theft | about **−10** |
| **Killing somebody innocent** | about **−80** |

That gap is the design. Ten thefts and you are hated in one town; **one murder and you
are nearly there in a single afternoon**. It also says something true about the game:
the player who takes things is a nuisance, and the player who kills is something else.

What "innocent" means is a question the deeds table answers, not this document —
killing somebody who drew on you first is not the same deed.

**Witnessing is what makes a deed count.** A deed nobody saw moves nothing. That is
already how `RumourSystem` works, and it makes stealing a choice about *where and when*
rather than a slider.

**Standing does not decay** (Yannick, 2026-09-23). A town remembers. There is no
timer that quietly forgives, because a number that drains is a number the player
cannot reason about.

## 4. How a town's opinion reaches the king

**No new rule here.** The player follows the kingdom's existing one:
`SIMULATION_MODEL.md` §3, guardrail 1 — *propagation is always place → kingdom →
places, never place → place*. Towns do not talk to each other, and the player's
standing travels the same star.

What the player model adds is only the reading at the far end:

> **Blackcairn reads the mean of every town's standing** — all of them, including the
> ones the player never went to, which sit at neutral and pull the average toward zero
> (Yannick, 2026-09-23).

Two consequences, stated because they are the design working:

- Being hated in one town and liked in four still arrives at court **slightly well
  regarded**. One terrible town is survivable.
- Being mildly disliked everywhere arrives **worse** than being loathed in one place.
  Consistency matters more than any single act, which is the right shape for a game
  about a reign.

## 5. What standing does — v1

**One thing, and no more** (Yannick, 2026-09-23): **it changes what people say to you.**

Dialogue already reads a regard value and swaps greetings on it (`alt_greetings`,
`when: they_think_ill_of_me`). It will read the town's standing instead of the
person's. That is the whole of v1.

Explicitly **not** in v1:

- **No hostile towns.** A watch does not attack on sight at any standing. Decided
  2026-09-23, and it keeps the demo from punishing a player who experiments.
- **No prices, no closed doors, no refused service.** Those need money and a market.
- Invariants 4 and 6 hold unchanged: standing may colour a route, never close the
  last one.

## 6. Richesse — the one part that needs building

**Money does not exist in the codebase.** `SPECS` §12 names the currency and leaves
everything else as TBD, and no store holds a coin today. So richesse is the only piece
of this model that is new work rather than a rewiring of what is there.

It is small, because it is one number:

| | |
|---|---|
| **A purse** | one integer on the player, moved only through the event log like everything else |
| **A reading** | which band the number falls in — *destitute / plain / comfortable / rich* |
| **A source** | somewhere for gold to come from and go to: what a body has, what a theft takes, what a quest pays |

**The bands' thresholds are open** and Yannick will set them once there is gold to
count. Nothing else in the model waits on them: the purse can be built and filled
before anybody decides what counts as rich.

**What richesse does is deliberately not answered here.** In v1 standing changes what
people say (§5); richesse changes how a place *perceives* the player, which is the
same channel and a later decision. It is modelled now because the combat design needs
somewhere for a dead man's gold to go, not because v1 spends it.

## 7. Still open

1. **The four richesse bands' thresholds.** How much gold is *comfortable*. Numbers,
   once there is gold to count, and nothing waits on them.
2. **What richesse does to a place's perception**, beyond existing (§6).

**Settled since the first draft:** the journal shows the standings **and a log of the
player's key acts** — saving somebody, killing somebody, and their like (Yannick,
2026-09-23). That log is not a new machine: `core/journal.gd` already keeps one
chronological list carrying facts rather than phrasing, and every deed that moves a
standing is already an event in it. What it needs is a page that reads *what you did
and what it cost you*, side by side, so the number and its cause are never separated.

## 8. The demo funnels the player, and Pillar 1 does not move

Yannick, 2026-09-23: *"le tuto qui couvre la démo va casser la règle du joueur qui peut
directement aller au château. Le nouveau design c'est tuto, quête 1 pour appréhender
les mécanismes du jeu et ensuite le joueur fait ce qu'il veut."*

The three phases he is returning to are already written, in `SPECS.md`, *Three phases
of play — a description, never gates (2026-09-13)*. That section says two things this
decision runs into:

> *"Nothing checks which phase you are in; nothing opens or closes on it."*
>
> *"**Phase 3 is available in minute one.** That is Pillar 1 and it is not negotiable."*

So the phases themselves are not the problem — they are a description and they still
describe what he wants. **What the demo adds is a gate**, and SPECS says there are
none.

**Settled 2026-09-23: the demo is a constrained slice, and SPECS does not change.**

The full game keeps Pillar 1 — phase 3 in minute one, nothing checks which phase you
are in. The funnel is a property of *the demo build*, written into the demo's own
tasks, and it comes out when the demo does. It exists so a first-time player meets the
tutorial and quest 1 before the map opens, and for no other reason.

Two rules follow from that, and they bind the task list:

- **No gate may be built into `core/`.** A check that asks *have you finished the
  tutorial* is invariant 4 broken, in the demo or out of it. The funnel is made of
  world — wolves on the other roads, a road that is plainly the safe one — never of a
  flag.
- **Removing the funnel must be one change**, named in its own task, so that taking it
  out after the testers' feedback is an afternoon and not an excavation.
