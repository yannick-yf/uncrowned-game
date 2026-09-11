# Uncrowned — working agreement

An open-world RPG about holding a king to account. The player can walk from Brindle
to Blackcairn within minutes of starting and attack the king, and will lose.
Progress comes from power, knowledge and social access — never from a flag.

**`docs/SPECS.md` is the source of truth.** Read it before designing anything. If
the code and the spec disagree, one of them is wrong and Yannick decides which —
do not silently pick.

**Precedence.** `SPECS.md` wins on *what the game is*. This file wins on *how we
work* and *which phase we are in*. Neither overrules the other inside its own
half; where a genuine conflict crosses the line, Yannick decides.

## The one architectural rule

This is a deterministic simulation with a Godot window attached, not a Godot game
with logic sprinkled through nodes. `core/` never imports from `view/`. `view/`
reads `core/` and never writes to it.

That split is what makes the world reactive, the dialogue deterministic, and the
rendering layer replaceable. Everything below protects it.

## Invariants — never violate these

1. **`view/` never mutates `core/`.** It observes and draws. Input becomes an event
   submitted to the sim.
2. **No game logic in `_process()` or `_ready()`.** The simulation advances only
   through `Sim.advance()`.
3. **All persistent state goes through the event log and the fact base.** Nothing
   important is stored on a node — zones unload, and their nodes with them.
4. **No progression check may gate an action.** No `if quest_12_done` in front of a
   door. Gate with power, knowledge or reputation, which are facts.
5. **Quests are reactions to fact patterns, not scripts.** A quest that can only
   start one way is a bug.
6. **Redundancy covers facts and route-critical performers.** A route needs facts,
   and it needs people who *perform an act* — papers granted, a congregation
   convened. Both need redundancy, but only to the depth invariant 7 demands.
7. **At least one route always survives.** Killing any combination of NPCs must
   leave *at least one* route to the confrontation open — **not all three**. Losing
   a route to a death is intended: kill Mother Crowe and Exposure closes, and that
   is the design working. The check is a living-performer-chain walk per route, not
   an enumeration of kill sets. This is a test, not a wish.
8. **The LLM never decides anything mechanical.** `core/rules/` issues the verdict;
   the model phrases it. Its output is text plus enums of ids that already exist.
9. **The player never types free text.** Dialogue is always a choice among generated
   options, each mapping to a known intent.
10. **There are no children in this game.** No child characters, in any role, ever.
11. **Static typing on every function signature and member variable.**
12. **No unseeded randomness.** Use `sim.rng`, never global `randf()`.

## Art rule

Free assets may be used, but only from the packs approved in `docs/SPECS.md` §13.
**Never mix packs from different artists** — palettes, pixel densities and light
angles do not reconcile, and mixing them is the clearest mark of an amateur game.
Anything off-palette or off-grid should fail a validator, not reach the screen.

## Naming

The king's six power bases are referred to **by name only** — the Cinderworks, the
Wide Acres, the Muster, Greyhold, Harrowgate, the bank. Never "Pillar N". "Pillar"
alone means one of the five design pillars in SPECS §1, and nothing else. Two
numbered series called "Pillar" in one codebase is a bug waiting for a typo.

## Layout

```
core/      Engine-agnostic simulation. No Node, no Sprite, no Input.
  systems/   React to events and ticks. Read events, write facts.
  rules/     Pure functions returning verdicts. The symbolic layer.
view/      Godot nodes. Replaceable.
tools/     Headless entry points: sim_runner.gd, test_runner.gd.
test/      Each file extends TestCase; methods named test_*.
content/   Cast sheets, facts, baked dialogue. Version controlled.
docs/      SPECS.md — the source of truth.
```

## Commands

```bash
godot --headless --path . --import                      # once after cloning
godot --headless --path . -s tools/test_runner.gd       # the feedback loop
godot --headless --path . -s tools/sim_runner.gd -- --ticks 5000
```

One tick is one in-game minute and the overworld runs 4 ticks per real second, so
`--ticks 5000` is 3.5 in-game days — about 21 real minutes of play. See SPECS §8.

## How to work here

Write the test first. Run the suite after every meaningful change — it takes
milliseconds and it is the only thing that tells you whether something broke.

If verifying a change requires opening the editor, ask whether the logic belongs in
`core/` instead.

## Effort discipline

Do not spawn subagents or parallel workflows unless I explicitly ask, or unless
the task genuinely requires reading more than fits in one context. Analysis of
documents in this repo does not qualify — I wrote them and can hold them in my
head. Default to answering directly. If you think a task warrants fan-out, say
what it would cost in time and tokens and ask first.

## Current phase

**Phase 0 — vertical slice.** Brindle, a player who walks, the King's Road running
north-west, Blackcairn at the end of it, and a king who kills the player in three
hits. Coloured rectangles. No NPCs, no LLM, no art.

Proof required: "I walk straight there and lose" is playable and makes you want to
try again differently. It also calibrates the walk: the scale is settled (SPECS §4 —
~280×200 tiles at 6 tiles/sec, 8-way movement), so what Phase 0 measures is whether
that *pace* feels right, not how long the crossing takes. Expect the bare diagonal to
read about 40 seconds.

### Phase 0 exceptions — deliberate, temporary, and only these three

These three things contradict SPECS on purpose. They are scoped to Phase 0, and each
names the decision that replaces it. Do not generalise from them, and do not add a
fourth without asking.

1. **No combat screen.** SPECS §10 rules that fights happen never in the overworld.
   Phase 0 breaches that: the king kills the player **on contact in the overworld,
   three touches**. The real side-on combat screen is Phase 3+, and nothing in
   Phase 0 may assume its shape.
2. **No save system. Death respawns the player in Brindle with everything kept.**
   There is no cost, no reload, no lost progress. The real death and save policy is
   a later decision (SPECS §19) — Phase 0 must not encode one, and the respawn goes
   through the event log like any other event.
3. **Movement is 8-way**, which is a decision rather than a breach, recorded here
   because Phase 0's whole measurement depends on it (SPECS §4).
