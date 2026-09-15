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

**Amended 2026-09-13 (v3), sharpened 2026-09-14.** The pack rule below describes the 2D
map, which is no longer the game. In the 3D world the rule is stricter than "one
family": **nothing of the 2D pack appears, ever** — no pixel figure, tree, house, stall
or path, not even as a placeholder (Yannick, on seeing them). The assets are the
brother's: his library, his traveller for every person until he draws the cast, and a
plain block in his rock paint where he has not drawn a thing yet. What he has not made
is *visibly missing*, and the bake's report and the suite's DEBT lines say what. His
library carries a provenance-and-licence manifest and `test_workshop_provenance` refuses
a file without one. Mixing artists is the mark of an amateur game in meshes exactly as
in pixels. (The HUD's font is the pack's, and an open question.)

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
           places.json — where everything stands, as anchors. No .gd carries a position.
           bake_brief.json — what we propose on the 3D map where his data is silent.
           region.json — the baked world. Never edited: re-run tools/bake_region.gd.
docs/      SPECS.md — the source of truth. V2.md — what the game is now, read this first.
           MIGRATION_3D.md — how the world moves onto the 3D workshop, and who does what.
           V1.md — what shipped the morning before v2.
  history/   Finished working logs. Never authoritative; kept for the reasoning.
prototypes/  The Brindle 3D workshop: a separate Godot project, kept out of the game's
           import by `.gdignore`. His; open its own `project.godot`. Never edited by us.
view3d/workshop/  A generated copy of his project with its paths repointed, so his
           scenes load in ours (tools/vendor_workshop.sh). Never committed, never edited.
```

## Commands

```bash
godot --headless --path . --import          # once after cloning
tools/run_tests.sh                          # the feedback loop — after every change
tools/run_tests.sh --all                    # before committing
tools/shot.sh /tmp/a.png play 150,174       # look at it — see "Development tools"
godot --headless --path . -s tools/sim_runner.gd -- --ticks 5000
godot --headless --path . -s tools/measure_routes.gd
godot --headless --path . -s tools/validate_assets.gd -- --no-cache
tools/vendor_workshop.sh                                    # after cloning, and after each delivery of his:
                                                            # his scenes into view3d/workshop/, then import
godot --headless --path . -s tools/bake_region.gd          # his data + the brief -> content/region.json
godot --headless --path . -s tools/bake_region.gd -- --check   # is the checked-in bake stale? (CI)
tools/run_tests.sh --procedural --all                       # the same suite on the 2D map v1/v2 were built on
UNCROWNED_WORLD=procedural tools/shot.sh /tmp/m.png map     # any tool, on the 2D map
UNCROWNED_VIEW=2d tools/shot.sh /tmp/m.png play 292,290     # the baked world, flat
```

**The world is the one baked from the 3D workshop** (M4 cut-over, 2026-09-14), seen in
3D (`view/world3d.gd`). `UNCROWNED_WORLD=procedural` is a **world selector, not a debug
tool**: read once by `Places`, it puts the whole process on the 2D map v1 and v2 were
built on — kept for its tests and its history. A process is one world. `UNCROWNED_VIEW=2d`
keeps the baked world flat, which is what a look at the bake itself wants. The 3D window
reads his landscape files from `prototypes/brindle_3d/` and his scenes from the
generated `view3d/workshop/`; a clone without the copy says so and shows the bake's own
ground.

**What stops you must be seen (2026-09-14).** On the baked world the simulation may
refuse a tile only where the player can see why: his water, his rock at
`BakeRules.ROCK_IMPASSABLE` (0.85) and above, his meshes, or a plain block of ours. The
kit's thicket ring round the clearing is left as open wood until he plants it (a DEBT),
a footprint shrinks to the piece his library stands for it (`kit_library` in the brief),
and the castle's ramparts stand as blocks. `test_bake` fails on any wall tile the window
does not draw. Do not fix an invisible wall by drawing something of ours — that is the
art rule the other way round; open it, report it in the bake, and name the debt.

### Committing — read this before your first `git commit`

**Every git command that writes runs with `GIT_CONFIG_GLOBAL=.git/overnight-gitconfig`.**

```bash
GIT_CONFIG_GLOBAL=.git/overnight-gitconfig git commit -F /tmp/message.txt
```

Yannick's `~/.gitconfig` is managed by GitKraken across **two accounts, one of them
professional**, and it must not be edited or inherited. That file pins the personal
identity, turns off signing, and touches nothing else. It is not optional and it is
not a preference: committing without it either fails or writes the wrong author.

Three habits that come from getting this wrong:

- **Write the message to a file and use `-F`.** Passing it inline lets the shell eat
  backticks and `$`; one commit message shipped with a word silently deleted.
- **Never chain a destructive command to one that may not have succeeded.**
  `git commit … && git reset --hard HEAD~1` destroyed a commit when the commit half
  failed and the reset half did not. Run them separately and read the output.
- **Never restore a file from a backup you took earlier without checking what is in
  it.** `cp /tmp/region_new.gd core/region.gd` silently reverted an hour of work,
  because the backup predated it. `git diff` first, or use `git show HEAD:path`.

Yannick pushes; this repo does not. Commit locally and stop.

**Run the suite through `tools/run_tests.sh`, never `test_runner.gd` directly.**
The script is part of the check, not a convenience. A GDScript runtime error does
not unwind — it prints to stderr, abandons the function and returns as if nothing
happened — so a crashed test records no failures and reads as a pass. The runner
catches the common case by failing any test that asserts nothing, but **it cannot
see its own stderr**. The script fails on any `SCRIPT ERROR` in the run, which is
the only thing that closes the gap.

Two speeds. `run_tests.sh` runs the **fast suite** — bare simulations, no map
walks, no asset pack — in about **7.5 s**, which is the one to run without
thinking. `--all` adds the journeys and the asset pack and takes about **21 s**.
(It was 0.9 s and 5.8 s when the map was a greybox and the cast was eight people,
and 4.7 s and 18 s when v1 shipped; v2's place tests each build a full world.
The numbers are here to be kept true, not to be admired: if the fast suite ever
stops being the thing you run without thinking, that is the thing to fix.)
A suite marked `const SLOW := true` is in the second group.

**Two worlds, since M1 (2026-09-13); the baked one is the game since M4 (2026-09-14).**
`run_tests.sh` runs on the baked world (about **8 s** fast, **24 s** all);
`tools/run_tests.sh --procedural --all` runs the same suite on the 2D map (about
**20 s**), and both have to be green before a commit that touches the map, the kit, a
position or the pace. A test says where it stands in the world's terms —
`at_a_stall()`, `in_town(&"harrowgate")`, `alone_on_the_road()`, `in_the_wood()`, all on
`TestCase` — and never as a tile; a time budget written for six tiles a second is
scaled by the world's pace (`_at_pace`), never hard-coded. A line marked **`DEBT`** in
the run is the map's or the brief's, not the code's: a claim the spec makes that the
baked world does not yet meet (`TestCase.debt`), printed so it is read and counted
apart so the suite stays green while `docs/MIGRATION_3D.md` §5 is open. Four stand
today: the works far from Brindle, §4's 45–90 s road band at his pace, the clearing's
ring of wood, and the north his rivers close with no crossing. Never turn a failure
into a debt to get green; a debt names something a person has to settle. A line marked **`OFF`** is the third kind
(`TestCase.off`): a claim that holds only while one of the testing switches below is
on, printed so the switch is not forgotten and counted apart so the claim is not lost.

One tick is one in-game minute and the overworld runs 4 ticks per real second, so
`--ticks 5000` is 3.5 in-game days — about 21 real minutes of play. See SPECS §8.

## How to work here

**Codex onboarding (2026-09-15).** Root `AGENTS.md` is Codex's automatically loaded
entry point. It requires this agreement in full, then `docs/V3.md`, then
`docs/MIGRATION_3D.md` §6.2 and §9, and only the task's needed SPECS section. This
agreement remains shared and binding; `AGENTS.md` records Codex's lanes and the files
reserved for Claude's map ingestion, so the two agents do not edit the same work.

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

**`UNCROWNED_FREE=zone[,zone]`** (2026-09-13) frees one or more of the four places for the frame
`shot.sh` takes, so the free-state ground and its sign can be looked at without playing
to them. Same gate, same reason: `--headless` never draws, and a fence that fails to go
missing is invisible to the suite.

**The journal's last section lists who is where.** Every named person, the town
they stand in, the distance and the compass direction. Phase 6 brings eighteen more
of them and "walk about until you find him" is not a way to review a character.

**All four are gated on `OS.has_feature("debug")`**, so they are absent from a
release export. Anything else of this kind goes behind the same gate and gets listed
here. A debug tool that is not written down is a debug tool that ships.

> `Engine.time_scale` was considered and rejected: it accelerates the player too,
> so you cannot walk anywhere while time passes, which is the whole point.

## Testing switches — not debug tools, and on in every build for now

The 2D game's layers come off one by one while the 3D world is tested (Yannick,
2026-09-14, MIGRATION_3D §9 decision 8). Each is one word, kept in the code beside what
it switches and listed here so none is forgotten when the game is shown to anybody. A
test that claims something only true while a switch is on says `OFF` in the run
(`TestCase.off`) instead of failing or quietly passing. Never delete the layer: it is
v2's tested work and the spec still argues for it; what a switch decides is what the
game does *now*.

**`Screens.QUICK_START` (2026-09-14).** The game opens straight into a fresh run with
every trait at the floor: no title menu, no character creation. Yannick asked for it
because both slowed every test launch. The two screens still exist, route and are
tested; the constant is one word to flip when the game is shown to anybody. The
screenshot harness names the screen it wants and is unaffected.

**`Region.TERRAIN_SLOWS_YOU = false` (2026-09-14).** The ground does not slow the
walker: every terrain walks at the world's pace. Yannick found open country at 0.65 of
2.5 tiles a second a crawl, and useless for now. §4's speed table stands and is tested
as a table; the four tests that measure the wild's price in time say `OFF`.

**`Sound.MUSIC = false` (2026-09-14).** No music. The ambience loops and the menu cues
still play; the tracks are the 2D pack's. The tables stand and `test_assets` still
checks the files exist.

## Effort discipline

Do not spawn subagents or parallel workflows unless I explicitly ask, or unless
the task genuinely requires reading more than fits in one context. Analysis of
documents in this repo does not qualify — I wrote them and can hold them in my
head. Default to answering directly. If you think a task warrants fan-out, say
what it would cost in time and tokens and ask first.

## Current phase

**v1 was delivered on 2026-09-13, and v2 on the same day.** Phases 0–3 and 5–7 of v1,
then v2's Phases A–E (SPECS §18). **Start at `docs/V2.md`** — two pages on what the
game actually is now, what is built, what is deliberately inert, and what v2 does not
have; `docs/V1.md` is the same for the morning before. Read them before `SPECS.md`,
which is 4,000 lines and answers a different question.

**v2 is delivered (2026-09-13).** It lives in `SPECS.md` — everything dated 2026-09-13
and marked *built* — and the intent it was written from is `docs/history/V2_INTENT.md`.
A: beasts out, terrain speeds on, the wild measured. B: hardship and the second
direction. C: four places, two states. D: rank from standing and the throne reading.
E: Blackcairn's two readings and the journal's kingdom page.

**v3: the game plays on the world baked from the Brindle 3D workshop** (decided
2026-09-13; M1–M2, M3a and the M4 cut-over delivered by 2026-09-14). The workshop in
`prototypes/brindle_3d/` is Yannick's brother's — a stylised 3D landscape walked by 2D
characters. **Start at `docs/V3.md`**, then `docs/MIGRATION_3D.md`, which is the plan and
the record of each phase; read it before touching anything the map or the view depends
on. The map and the graphics are the brother's; the systems, the content and the bridge
are ours, and the bridge is the one architectural rule below applied once more: the
simulation keeps its grid, the 3D data is *baked* into a `Region` (`content/region.json`),
and a 3D window (`view/world3d.gd`) reads the sim and never moves the player. What waits
on him: his props and the 25 faces in his style (M3b) and the map's own fill (M5). Combat is still the oldest debt in the project. Nothing structural moves
without asking Yannick. **One discipline, in force since M1a (2026-09-13):** anything
positional — a person, a paper, a fire, a stall, a site — is an *anchor* in
`content/places.json` (a place or point plus an offset, or a feature standing in a
place) and never a tile constant in a `.gd`. `Region.resolve()` turns an anchor into a
tile and `test_anchors` fails **by name** on one that resolves nowhere. The offsets
inside `_stamp_landmarks` are the exception on purpose: they are the shape of a
scaffold settlement, not where content stands. The map is about to move, and content
that names what it stands next to survives the move.

Phase 4, combat, is **out of v1** (Yannick, 2026-09-12) and shipped that way: four of
the five endings need no fighting, and the fifth — killing him — is the one that
waits. **It is out of v2 as well** (Yannick, 2026-09-13): §18's roadmap is A–E, and
combat would be a phase after it, or v3.

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

**What "new evidence" means, for v2** (noted 2026-09-13, because the ruling is about
to be read by a different model). The evidence that settled this was *two local models
on this machine*, and it is tempting to conclude that a larger or hosted model settles
it the other way. It does not, and the reason is in the finding: **the failure was the
door, not the writer.** `ProseRules` can check figures, names, register and formatting,
and none of those catch a sentence that means the opposite of what it was given — the
pass rate went *up* to 94% while the meaning went backwards 5 times in 6.

So the experiment that would reopen this is **"can anything catch an inverted line
automatically"**, not "is this model better at writing". Until something answers that,
a better model produces better prose with the same unverifiable failure mode, which is
the worse of the two states because it looks fine.

### Standing exceptions — deliberate, and now only one

Carried forward from Phase 0. An exception contradicts SPECS on purpose and names the
decision that will replace it. Do not generalise from it, and do not add a second
without asking.

1. **No combat screen.** SPECS §10 rules that fights happen never in the overworld.
   Phase 0 breaches that and v1 still does: the king kills the player **on contact in
   the overworld, three touches**. The real side-on combat screen is Phase 4, which is
   out of v1 and out of v2 — so this exception outlived the phase that created it and
   is now the oldest debt in the project. Nothing may assume the combat screen's shape.

**Retired, kept here so the history reads straight:**

- ~~*No save system. Death respawns the player in Brindle with everything kept.*~~
  **Retired 2026-09-12**, when SPECS §19 row 5 settled it: you save by resting at a
  campfire, and dying puts you back at the last one. The save is the event log and
  nothing else, so loading is replaying — see `core/save_file.gd`. Since 2026-09-13 a
  new run writes its save at character creation, because the file otherwise still held
  the previous run and dying before the first rest reloaded somebody else's afternoon.
- ~~*Movement is 8-way, recorded because Phase 0's measurement depends on it.*~~
  **Retired 2026-09-13.** It was never a breach, and it is not provisional any more —
  it is simply how the game moves (SPECS §4). Arrow keys were added beside WASD when
  the menus arrived.
