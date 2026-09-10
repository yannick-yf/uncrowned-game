# Uncrowned — working agreement

An open-world RPG about holding a king to account. The player can walk from Brindle
to Blackcairn in the first twenty minutes and attack the king, and will lose.
Progress comes from power, knowledge and social access — never from a flag.

**`docs/SPECS.md` is the source of truth.** Read it before designing anything. If
the code and the spec disagree, one of them is wrong and Yannick decides which —
do not silently pick.

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
6. **Every required fact has at least two independent sources.** No single NPC's
   death may remove a fact from the world.
7. **The reachability test must pass.** Killing any combination of NPCs must leave
   at least one route to the confrontation open. This is a test, not a wish.
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

## How to work here

Write the test first. Run the suite after every meaningful change — it takes
milliseconds and it is the only thing that tells you whether something broke.

If verifying a change requires opening the editor, ask whether the logic belongs in
`core/` instead.

## Current phase

**Phase 0 — vertical slice.** Brindle, a player who walks, the King's Road running
north-west, Blackcairn at the end of it, and a king who kills the player in three
hits. Coloured rectangles. No NPCs, no LLM, no art.

Proof required: "I walk straight there and lose" is playable and makes you want to
try again differently. Also settles the map scale (SPECS §4, open question 7) by
letting Yannick time the walk.
