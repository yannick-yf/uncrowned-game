# The simulation as built — a record before it is simplified

Date: 2026-09-17. Written at Yannick's request, before the simulation is replaced by
a simpler and more readable model.

## Why this exists

Yannick has decided to simplify the back end: a smaller, legible model his brother,
he and the players can all hold in their heads. **This document is the record of what
the back end does today**, so that what is dropped is dropped on purpose and what is
kept is kept for a reason. It is not an argument for keeping any of it.

Read it the way you read an inventory, not a proposal. Every line is what the code
does on 2026-09-17, measured or read, not what a spec hoped for. `SPECS.md` says what
was intended; this says what exists.

**The size of the thing:** 20 systems, 24 rule modules, 9 stores, 24 deeds, 8 quests,
25 named people with 93 dialogue options teaching 24 facts, 5 documents, 8 places,
44 test suites, 431 tests.

---

## The spine — the part that is not gameplay

This is the machinery the game runs on rather than anything a player meets. It is
also the part that would cost the most to rebuild and the least to keep.

| Piece | What it does | Where |
|---|---|---|
| **The clock** | 60 steps a second, a world tick every 15 — 4 ticks a second, one tick one in-game minute. A day of play is six real minutes | `core/sim.gd` |
| **The event log** | Everything that happens is an event appended to a log. Systems react to events and ticks; nothing mutates outside that path | `core/sim.gd`, `core/event_log.gd` |
| **Save is the log** | A save is the event log and nothing else; loading is replaying. This is why randomness is seeded (`sim.rng`) and why no state lives on a node | `core/save_file.gd` |
| **Facts** | What the world remembers: `cinderworks:death_toll`, `met:kell`. Not progression flags — quests are predicates over these | `core/fact_base.gd` |
| **Rules and systems** | A rule is a pure function returning a verdict; a system applies it and writes events. The split is what makes the verdicts testable | `core/rules/`, `core/systems/` |
| **Anchors** | Every position is *what a thing stands next to*, in `content/places.json`, never a tile in code. This is what let two of his map deliveries land without touching content | `core/places.gd`, `Region.resolve` |
| **The view reads, never writes** | Input becomes an event; the window draws the simulation and cannot change it | `view/main.gd`, `view/world3d.gd` |

**This spine is the reason the world moved from a 2D procedural map to his 3D
workshop without the game noticing, twice in five days.** Whatever the simpler model
becomes, it is worth asking what of this it still wants.

---

## The world model

### The twelve quantities

Global: `steel_output`, `worker_morale`, `patrol_density`, `guard_alertness`,
`crown_treasury`, `bank_confidence`, `army_strength`, `faction_tension`,
`rumour_spread`, `held_ground` (how much of the fairies' wood is left).
Per town: `grain_price`, `town_sentiment`, `guard_alertness_by_town`, `hardship`.

They start at a ceiling of 100 (or a neutral 50) and **drift slowly on their own**;
a player's act moves them sharply. `WorldRules` holds the drift; `WorldTick` holds
the values. The ceiling is deliberate: a place is never pushed past its starting
state.

### The four places, two states each

`wide_acres`, `cinderworks`, `muster`, `cairnwell` — crown-held or free, never a
third. Each holds **one document**; reading it aloud *in that place* frees it, and
spending the same knowledge the crown's way holds it. A decision is frozen for two
in-game days so neither the world nor the player can immediately undo it.
`core/rules/place_rules.gd`

### Deeds — the one table

24 acts, ten that break the kingdom and ten that build it, plus theft, restitution,
warning and informing. **One table** says, for each: what it does to the quantities,
what it does to your standing with factions and towns, and **who it makes suffer**
(hardship, per town). The hard rule: an act that changes the kingdom must cost
somebody named. `core/rules/deed_rules.gd`

### The delay

Factions move at the moment of the act; towns move as the story reaches them, carried
by travellers on the road and not through the Thornwood. A rumour takes days. This is
half of what the game is about, and it is why `T` skips a day.
`core/systems/rumour_system.gd`, `traveller_system.gd`

### Acts at a landmark

`SiteRules` maps a landmark kind to a deed — kiln, granary, counting house, muster
rolls. `ActSystem` handles reach (2.4 tiles), the prompt, the watch standing over a
guarded post, and the rule that a spent site stays spent. **Adding a lever is a row in
a table.** This is the cheapest thing in the codebase and the most useful to the demo.

### Documents

Five, each answering one place where the king's argument breaks. **They live in
places, not in people** — kill whoever would have told you and the paper is still in
the room — and nothing can take one off you once held. `core/rules/document_rules.gd`

---

## The people

**25 named characters** in `content/cast.fr.json` and `.en.json`, plus 8 strangers.
Each has a role, dispositions toward the crown and the player, a greeting, alternate
greetings conditioned on the world, and dialogue options. **93 options, teaching 24
facts.** Six options are gated on a trait.

Conversation is generated, never typed: `DialogueRules` decides which options exist
given the facts, the world's conditions, the speaker's regard and the player's
traits; the system looks up the line. A **reaction** — one of 21 hand-written opener
lines — is said once per conversation.

**Standing** turns a number into a word (how a faction or a town regards you);
**allegiance** tracks which side you have joined and what rank you hold.

### Quests

8, and none is a script: each is a **pattern of facts** — what the player needs to
know for it to be open, and what closes it. Several close by either of two different
acts. `core/rules/quest_rules.gd`

### Endings

Watched for continuously from the world's conditions rather than triggered by a
final scene. `core/rules/end_rules.gd`, `ending_system.gd`

---

## What the player actually meets, measured

This is the part worth reading twice, because it is the argument for simplifying.

| | |
|---|---|
| Dialogue options that read a trait | **6 of 93** |
| Traits read by anything at all | **3 of 6** — and one of those three is switched off |
| Quantities the demo needs | **2 of 12** |
| Places with the full two-state treatment | 4 of 8 |
| Combat | none: the king's contact damage is the oldest standing exception in the project |

**Most of this machinery is never met by a player in an hour of play.** That is not an
argument that it is wrong — it is an argument that its cost is invisible, and that a
smaller model could deliver the same felt experience.

---

## The inert machinery, already switched off

Kept here so the record is complete. None of it runs.

- **The LLM layer** — `core/context.gd`, `core/rules/prose_rules.gd`,
  `core/phrasebook.gd`, `PhrasingSystem`, `view/phraser.gd`, `tools/phrase.py`.
  Tested, switched off, `Phraser.phrase()` returns `""`. The reason it was switched
  off is in `CLAUDE.md` and is still the reason: the door can check figures, names and
  register, and none of that catches a sentence that means the opposite of what it
  was given.
- **Terrain speeds** (`Region.TERRAIN_SLOWS_YOU`), **music** (`Sound.MUSIC`), and the
  **title and creation screens** (`Screens.QUICK_START`) — one word each.

---

## What a simpler model would be giving up, in one list

Neither a defence nor a recommendation. Just the bill, so it is paid knowingly.

1. Save-by-replay, and with it the guarantee that a bug reproduces exactly.
2. Anchors, and with them the ability to absorb a map change without touching content.
3. The one-table rule for acts, and with it the check that every act costs somebody.
4. The delay — consequences arriving days later, carried by people on the road.
5. Fact-pattern quests, and with them the rule that a quest can start more than one way.
6. Documents that survive the death of everyone who knew about them.
7. 93 written dialogue options and 21 reaction lines in two languages.
8. 431 tests, which test the rules above and nothing else.

**Items 1 to 3 are spine, not gameplay** — a simpler model can keep them at almost no
cost in legibility, because the player never sees them. Items 4 to 7 are gameplay
policy and content, and are exactly what a simpler model is entitled to replace.

---

## Where to find the rest

`docs/V3.md` says what the game is now. `docs/SPECS.md` says what was intended, at
4,000 lines. `docs/DEMO_EXISTING_BEHAVIOUR.md` reviews the two systems the demo needs
first — creation and the Cinderworks dispute — with a keep / adapt / replace verdict
on each. `docs/DEMO_PLAN.md` is the order of work.
