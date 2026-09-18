# What we keep of the simulation that exists

Date: 2026-09-18. **A proposal from Claude for Yannick to accept, change or reject,
component by component.** Nothing has been deleted.

The inventory it works from is [SIMULATION_AS_BUILT.md](SIMULATION_AS_BUILT.md).
What replaces it is [SIMULATION_MODEL.md](SIMULATION_MODEL.md).

## The headline

Yannick's expectation — *probably not much* — is **right about two thirds of it and
wrong about the third that matters least to look at**.

The code splits in two, and the split is not "good code / bad code". It is **what a
player meets and what a player never meets**:

- **The spine** — the clock, the event log, save-by-replay, facts, the rules/systems
  split, anchors, the map, the view that cannot write. **A player never meets any of
  it.** It has no opinion about the game's design, so the new model cannot conflict
  with it, and rebuilding it would cost weeks and buy nothing in legibility. It is
  also the entire reason his brother's map landed twice in five days without the game
  noticing. **Keep.**
- **The world model and the content** — twelve quantities, twenty-four deeds,
  factions and ranks, rumours, documents, ninety-three dialogue options. **This is
  what the new model replaces**, and Yannick has already ruled that the writing is to
  be redone. **Replace.**

One sentence for the whole review: **keep the machine, replace the game.**

---

## Component by component

### Keep — the player never meets it, and it has no opinion

| Component | Why |
|---|---|
| `Sim`: steps, ticks, the day | 4 ticks a second, one tick a minute. Movement and the day cycle need it and the new model does not touch it |
| The event log and `SaveFile` replay | A save is the log; loading is replaying. It is what makes a bug reproducible and a save honest. Rebuilding this is a week that buys nothing |
| `FactBase` | The mechanism stays; **its contents are rewritten** with the quests |
| The rules / systems split | A pure verdict, then a system that applies it. It is why anything here can be tested at all |
| Anchors, `places.json`, `Region.resolve` | Content names what it stands next to, never a tile. **Proven twice** — his ironworks v4 moved sixteen buildings and cost content nothing |
| `Region`, the bake, `region.json` | This *is* the map. Untouchable for other reasons |
| `Navigation`, `MovementRules` | Walking. No opinion about the design |
| The view reads and never writes | The rule that let the world go from 2D to his 3D without the game noticing |

### Keep and use — small, cheap, and the new model needs them

| Component | Why |
|---|---|
| `SiteRules` + `ActSystem` | **An act at a landmark is already a system**: reach, prompt, the guard who stands over a post, a spent site staying spent. The new model's deciding physical act is exactly this, and adding one is a row in a table |
| Zones and places | Where a place begins and ends, which the look and the routines both need |

### Adapt — the idea survives, the code shrinks

| Component | What happens to it |
|---|---|
| `PlaceRules`, two states per place | Becomes **the threshold on allégeance**. Crown-held / free stops being a pair of states and becomes above 5 / below 5. Most of the file goes |
| Quests as fact patterns | The **mechanism** is right and fits *one quest per place, two outcomes*. The **eight quests** go |
| `DialogueRules` | The machinery that builds options from sheets and gates them on facts stays. **Every line it serves is rewritten.** Its trait gates move to the four new traits |
| `Traits`, `TraitRules` | Four traits — Force, Intelligence, Agilité, Prestance — and a pool of 8 instead of six and 10 |

### Replace — this is what the new model is for

| Component | Replaced by |
|---|---|
| The twelve quantities (`WorldTick`, `WorldRules` drift) | Two values per place, two for the kingdom |
| `DeedRules` — 24 acts and their effect tables | Two outcomes per place, ±3, in one table |
| Hardship per town | Folded into **richesse** |
| `Standing`, `Allegiance`, faction ranks | One allégeance per place. Whether the *player's own* standing with the crown survives for the endings is open and outside the demo |
| Rumours and travellers carrying news | The intent survives as guardrail 3 — **propagation takes days** — but as a slow kingdom tick, not a system that walks stories along roads |
| The five documents | The decisive act is now the quest. A1 may reuse the idea that evidence sits in a place rather than in a person; the mechanism as it stands does not survive |
| `GrainSystem`, `UnrestSystem`, `ArmySystem`, `CastleRules` | Organs of the old kingdom model. The two kingdom values do their work |

### Delete outright

| Component | Why |
|---|---|
| The LLM layer — `context.gd`, `prose_rules.gd`, `phrasebook.gd`, `PhrasingSystem`, `view/phraser.gd`, `tools/phrase.py` | Inert since 2026-09-12, switched off, and the ruling that switched it off is recorded in `CLAUDE.md`. Dead weight in a codebase being simplified |
| The 93 dialogue options and the 21 reactions | **Yannick, 2026-09-18: all of it is to be rewritten.** The roles may survive as a starting point; the writing does not |

### Leave alone for now — not in the way, decide after the demo

Endings · crime, theft and the watch · recovery and rest · zones and portals ·
travellers as road traffic. None of it conflicts with the new model, none of it is on
the demo's path, and deleting it costs time that buys nothing this month.

---

## What this actually buys

**Deleting is not free.** Every component removed is a file to remove, tests to
remove with it, and a suite that has to stay green through the removal. The gain is
real but it is legibility, not speed: a smaller model that Yannick, his brother and a
player can each hold in their heads.

So the order matters, and it is the opposite of the tempting one:

1. **Build the new model first, beside the old one.** Two values per place, the star,
   the look, the routines.
2. **Then let the demo's quest run on the new model**, and see it work.
3. **Then delete**, component by component, with the suite green at each step.

Deleting first leaves a game that does not run and a month spent getting back to
where it was. Building first means that on any morning the game still plays.

**The one exception:** the LLM layer can go now. Nothing calls it, nothing depends on
it, and it is the only thing here whose removal cannot break anything.

---

## What is open in this review

- **The player's own standing with the crown.** The new model gives allégeance to
  places, not to the player. The endings need to know whether the king counts the
  player as his. Out of the demo's scope, but it decides whether `Standing` dies or
  shrinks.
- **The documents.** A1 decides. If the ironworks' deciding act turns out to be
  reading the ledger somewhere, the mechanism earns its keep; if it is a physical act
  at a landmark, it does not.
- **`Region.TERRAIN_SLOWS_YOU`, `Sound.MUSIC`, `Screens.QUICK_START`.** Three testing
  switches with working code behind them. Simplifying is a good moment to decide
  whether the layers they hide come back or go.
