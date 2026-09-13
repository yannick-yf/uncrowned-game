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
godot --headless --path . --import          # once after cloning
tools/run_tests.sh                          # the feedback loop — after every change
tools/run_tests.sh --all                    # before committing
godot --headless --path . -s tools/sim_runner.gd -- --ticks 5000
godot --headless --path . -s tools/measure_routes.gd
godot --headless --path . -s tools/validate_assets.gd -- --no-cache
```

**Run the suite through `tools/run_tests.sh`, never `test_runner.gd` directly.**
The script is part of the check, not a convenience. A GDScript runtime error does
not unwind — it prints to stderr, abandons the function and returns as if nothing
happened — so a crashed test records no failures and reads as a pass. The runner
catches the common case by failing any test that asserts nothing, but **it cannot
see its own stderr**. The script fails on any `SCRIPT ERROR` in the run, which is
the only thing that closes the gap.

Two speeds. `run_tests.sh` runs the **fast suite** — bare simulations, no map
walks, no asset pack — in about **4.7 s**, which is the one to run without
thinking. `--all` adds the journeys and the asset pack and takes about **18 s**.
(It was 0.9 s and 5.8 s when the map was a greybox and the cast was eight people.
The numbers are here to be kept true, not to be admired: if the fast suite ever
stops being the thing you run without thinking, that is the thing to fix.)
A suite marked `const SLOW := true` is in the second group.

One tick is one in-game minute and the overworld runs 4 ticks per real second, so
`--ticks 5000` is 3.5 in-game days — about 21 real minutes of play. See SPECS §8.

## How to work here

Write the test first. Run the suite after every meaningful change — it takes
milliseconds and it is the only thing that tells you whether something broke.

If verifying a change requires opening the editor, ask whether the logic belongs in
`core/` instead.

## Development tools that must never ship

**`T` skips one in-game day.** Every consequence left in §8 happens *later* — a
rumour arriving three days after a theft, grain rising a week after the desertions
— and none of them can be judged by hand without skipping forward. It advances
through the ordinary tick path, so a skipped day is identical to a waited one:
same drift, same events, same replay. Which also means a day skipped standing in
the Thornwood is a day of being eaten.

**`M` opens the map of Erileo.** Every tile in its terrain colour, the eight places
named, the fairies' clearing, and where you are standing. Asked for as a debug tool
and kept as a real one: a game whose argument is *the road against the forest* should
let you see the shape of the argument. It is painted once into a texture rather than
redrawn, because 56,000 rectangles a frame is a slideshow.

**`tools/shot.sh out.png [title|creation|play|pause|journal|map] [x,y]`** renders one
frame of a screen to a file and quits. It is the only check that catches what the
suite cannot see — the ocean shipped covered in shoreline tiles because "300 frames,
zero script errors" was reported as though it meant the picture was right. Under it:
`UNCROWNED_SHOT` names the file, `UNCROWNED_SCREEN` the screen, `UNCROWNED_AT` the
tile to stand on.
This exists because a night was spent shipping things that drew wrong without
erroring — `--headless` never calls `_draw()`, so the test suite cannot see the
screen at all, and "no script errors" says nothing about what is on it.

**The journal's last section lists who is where.** Every named person, the town
they stand in, the distance and the compass direction. Phase 6 brings eighteen more
of them and "walk about until you find him" is not a way to review a character.

Both are gated on `OS.has_feature("debug")`, so they are absent from a release
export. Anything else of this kind goes behind the same gate and gets listed here.
A debug tool that is not written down is a debug tool that ships.

> `Engine.time_scale` was considered and rejected: it accelerates the player too,
> so you cannot walk anywhere while time passes, which is the whole point.

## Effort discipline

Do not spawn subagents or parallel workflows unless I explicitly ask, or unless
the task genuinely requires reading more than fits in one context. Analysis of
documents in this repo does not qualify — I wrote them and can hold them in my
head. Default to answering directly. If you think a task warrants fan-out, say
what it would cost in time and tokens and ask first.

## Current phase

**Phase 7 — art, audio and polish.** Phases 0, 1, 2, 3, 5 and 6 are delivered.
Phase 4, combat, is **out of v1 or its very last step** (Yannick, 2026-09-12).
Four of the five endings need no fighting; the fifth, killing him, is the one that
waits. Plan for v1 shipping with four endings and treat combat as the thing that
happens only if everything else is finished.

**There is no LLM in v1, decided 2026-09-12 and tested rather than argued.** Two
local models, sixteen real packets, four prompt designs, on this machine. The
finding that settled it: the door can check figures, names, register and formatting,
and **none of that catches a line that says the opposite of what it was told**.
Shrinking the model's job to one fact-free sentence removed that failure by
construction and it still got the sign backwards 5 times in 6 — while the pass rate
went *up* to 94%. A measurement that reads *ready* over inverted output is worse than
one that reads *broken*.

The machinery stays: `core/context.gd` (the packet), `core/rules/prose_rules.gd`
(the door), `core/phrasebook.gd`, `PhrasingSystem`, `view/phraser.gd` and
`tools/phrase.py`. All inert, all tested, all switched off. `Phraser.phrase()`
returns `""` and nothing asks it anything.

**What replaced it, and it is built** (2026-09-12): the reactive **openers**, hand
written. A `reactions` block beside `dispositions` in the cast sheets — 3 shared
bands plus 9 people with their own, 21 lines a language — joined by
`ProseRules.joined()` and said **once per conversation**, on the first answer. See
SPECS §9 *Reactions* for the four rules, and `test/test_reactions.gd`.

> Do not reopen the model question by adding a check, a prompt or a bigger model
> without new evidence. The three things already tried and recorded in SPECS §9 are
> whole-line generation, few-shot examples (which made it *worse*), and opener-only
> generation.

### Standing exceptions — deliberate, temporary, and only these three

Carried forward from Phase 0. They contradict SPECS on purpose, and each names the
decision that replaces it. Numbers 1 and 2 are retired by Phase 4. Do not generalise from them, and do not add a
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
