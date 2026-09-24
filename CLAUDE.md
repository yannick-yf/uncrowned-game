# Uncrowned — working agreement

An open-world RPG about holding a king to account. The player can walk from Brindle
to Blackcairn within minutes of starting and attack the king, and will lose.
Progress comes from power, knowledge and social access — never from a flag.

**Two sources of truth, and the newer one wins where they overlap.** `docs/SPECS.md`
was the source of truth and still governs most of what the game is. **The simulation
was redesigned on 2026-09-18**, and four documents now supersede it wherever they touch
the same ground — the kingdom's quantities, the places' states, the deeds, the traits,
the dialogue:

| Read | For |
|---|---|
| `docs/SIMULATION_MODEL.md` | **What the simulation is.** Two values per place, two for the kingdom, the star, the look, the routines, where the player enters |
| `docs/QUEST_CINDERWORKS.md` | The demo's quest, settled on paper |
| `docs/SIMULATION_KEEP_OR_DROP.md` | What survives of the old simulation, component by component |
| `docs/DEMO_TASKS.md` | The work, as 47 tasks with their checks |

`docs/SIMULATION_AS_BUILT.md` records what the old simulation did, so that what is
dropped is dropped on purpose and not by accident.

**Reading order for a new session:** this file, then `docs/V3.md` (what the game is
today, and the map it runs on), then `docs/SIMULATION_MODEL.md`, then only the section
of `SPECS.md` the task actually needs. **Never read SPECS whole** — it is 4,000 lines
and much of its simulation half is now superseded.

**Precedence.** `SPECS.md` wins on *what the game is*, except where the four documents
above supersede it. This file wins on *how we work* and *which phase we are in*. Where
a genuine conflict crosses that line, Yannick decides — do not silently pick.

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

**One exception, and Yannick made it deliberately (2026-09-19).** His brother had drawn
no attack and no guard — eight animations, idle and walk in four directions — so a fight
showed three different actions as a person standing still. Yannick was told plainly that
a second hand on his brother's character would show, and said to do it anyway. So
`tools/draw_fight_frames.gd` builds **eight** frames — a cocked arm, an attack, a guard
and a flinch, left and right — and `view3d/fight/traveler_sheet.png` is the result. It
was six until Yannick played it and said the animation was very slight: the wind-up had
no drawing at all, which is the half of a blow a person reads.

Three things keep it honest, and none of them makes it *not* an exception:

- **No colour is invented.** His hand is copied to a new place, his sleeve lengthened by
  repeating one of its own columns, his outline sampled from his own line. His figure is
  painted rather than flat — the hair alone runs to thousands of browns — so a flat
  rectangle beside it would read as somebody else's hand at fifty paces.
- **His files are never touched.** `prototypes/` is his, the tool only reads it, and the
  combined sheet and the extra animations are ours.
- **It is written down where he will see it**, in `docs/POUR_SLOSINIO.md` §8, so he does
  not discover it. `test_his_brother_has_not_drawn_a_blow` fails the day his own sheet
  grows a ninth animation, and on that day this tool and this exception are deleted.

The sheet is **not** in `assets/`: that folder is the approved 2D pack's family and
`tools/asset_validator.gd` rightly refuses a file made of his palette. The 3D world's art
has never lived there — his own sheet is in `prototypes/`.

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
docs/      SIMULATION_MODEL.md — what the simulation is, since 2026-09-18.
           QUEST_CINDERWORKS.md — the demo's quest. DEMO_TASKS.md — the work, as tasks.
           SIMULATION_KEEP_OR_DROP.md — what survives of the old simulation.
           SIMULATION_AS_BUILT.md — what the old simulation did, recorded before it goes.
           V3.md — what the game is today. MIGRATION_3D.md — the map, and who does what.
           SPECS.md — the old source of truth; superseded where the four above touch it.
           V1.md, V2.md — what shipped on 2026-09-13.
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

**Delivery ingestion (2026-09-15).** Run `tools/vendor_workshop.sh` before baking or
checking a bake: `tools/workshop_geometry.gd` reads the copied ironworks collision
scenes and refuses stale copies. Only the build tool loads those nodes; core receives
plain polygons. The bake hashes the town and river data and each used collision scene,
and checks that the landscape's resolved crossings agree with the river layout.
**Since 2026-09-21 (G1) the bake also reads his catalogues** — the brief's `catalogs`,
today `assets/ironworks/catalog.json` — and every piece of his it places (the works'
yard: `YardRules`, `CatalogRules`) is stood at his metres and yaw, blocks what its own
collision shapes cover, and has its catalogue and its scene hashed into the bake. **Read
his catalogue before placing anything of his**: its `placement` note is the only document
that says how a piece is meant to be used, and the first yard was built without it.
`tools/bake_region.gd -- --check` remains the freshness check; both worlds remain the
commit checks. The current baked run prints **ten** DEBT lines for **six** claims and
four OFF lines. Five claims are the map's and the brief's; the sixth is **his brother's
figures** — `traveler_walk_frames.tres` holds idle and walk in four directions and no
attack, no guard and no flinch, so a fight's blows are shown by moving the figure he did
draw (2026-09-19, F5). The procedural world prints one, for the same reason.

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
walks, no asset pack — in about **12 s**, which is the one to run without
thinking. `--all` adds the journeys, the asset pack and the days of weather, and takes
about **42 s** on the baked world and **36 s** on the 2D map.
(It was 0.9 s and 5.8 s when the map was a greybox and the cast was eight people;
4.7 s and 18 s when v1 shipped; 9 s and 25 s before the simplified simulation, which
added a system running sixty times a second and tests that advance whole in-game days.
The numbers are here to be kept true, not to be admired: if the fast suite ever
stops being the thing you run without thinking, that is the thing to fix. Two things
were already done for that on 2026-09-18 — the walking population is matched once an
in-game hour rather than once a minute, and each day a test simulates is a day it
actually needs. The 4 s the full suites gained on 2026-09-19 is **not** the fight:
`--all` was measured at 42.2 s with `CombatSystem` taken out of `Game.build()` and
42.8 s with it in, so a system on the step costs the other 478 tests nothing
measurable. The fourteen combat tests are in the **fast** suite for the same reason.)
A suite marked `const SLOW := true` is in the second group.

**Two worlds, since M1 (2026-09-13); the baked one is the game since M4 (2026-09-14).**
`run_tests.sh` runs on the baked world (about **12 s** fast, **42 s** all);
`tools/run_tests.sh --procedural --all` runs the same suite on the 2D map (about
**36 s**), and both have to be green before a commit that touches the map, the kit, a
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

**`G` makes the player unkillable.** Added 2026-09-19 so Yannick could walk the demo
without dying to it. **A development tool and not a difficulty setting**: nothing can take
a point off him, and the HUD says `[G] INVULNÉRABLE` while it is on, because a switch
nobody can see is a switch nobody turns off.
>
> It is submitted as an **event**, not set as a flag by the window. A flag would not be in
> the log, and a run played through it would not replay through it — the save would
> quietly disagree with the game it came from. `WorldState.hurt` is the only thing that
> reads it, which is the same reason everything else that can hurt you goes through there.

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

**`UNCROWNED_TOWN=place:allegiance/richesse`** (2026-09-18) sets a place's two numbers
for the frame, comma-separated for more than one — `UNCROWNED_TOWN=cinderworks:9/7`.
The same gate and the same reason as `UNCROWNED_FREE`, which it will outlive: an
outcome has to be lookable at before there is a quest to play to it, and until Q5 lands
there is no other way to see the works working. **It writes the store directly and is
therefore not a save-able state** — it is one frame, for one photograph. **It then runs
an in-game hour** (2026-09-19), because writing the two numbers is not the picture: how
many people walk to work is matched when a place *moves*, and a value set straight into
the store moves nothing. Six photographs of the three states were taken before that
existed and every one showed a full shift standing in front of cold furnaces — a picture
of the tool rather than of the game.

**The journal's last section lists who is where.** Every named person, the town
they stand in, the distance and the compass direction. Phase 6 brings eighteen more
of them and "walk about until you find him" is not a way to review a character.

**`UNCROWNED_LENS=tilt,size`** (2026-09-19) moves the 3D camera for the frame `shot.sh`
takes — a tilt in degrees and an orthographic size in metres. Added for one question and
no other: `docs/COMBAT.md` §1 asks whether a fight happens on a separate 2D screen or in
place in his world, that is a question about a *picture*, and `--headless` never draws.
**The azimuth is deliberately not offered**, because his traveller's four facings are
keyed to the world's axes and a turned camera draws every fighter looking the wrong way.

**`UNCROWNED_FIGHT=bram[:steps[:policy]]`** (2026-09-19, extended 2026-09-21) squares
the player up against somebody for the frame `shot.sh` takes, with the lens already
dropped and the screen already darkened. Same gate and same reason as the two above,
plus one of its own: the picture is taken twelve frames in and the fight's camera takes
about a second to move, so without this every photograph of a fight is a photograph of a
camera halfway through moving. `bram:44` runs forty-four steps first, so a wind-up or a
blow can be photographed; `bram:44:guard` runs them with one of `tools/fight_player.gd`'s
scripted hands on the keys — `stand`, `guard`, `competent`, `dodger` — so a guarded blow
or the moment of winning can be. **When a picture is being taken the simulation is held
on the frame asked for**, or the twelve frames before the shutter would carry the fight
past it; and only the last ten steps' events are fresh, so the picture carries one blow's
spark and number and not every blow's. `godot --headless --path . -s tools/play_fight.gd
-- stand 200` prints the trace that says which step is which.

**`UNCROWNED_TALK=maddox[:standing]`** (2026-09-24) stands the player in front of
somebody, mid-greeting, for the frame `shot.sh` takes, and sets the standing of the town
they are both in to the number after the colon. Same gate and same reason as the three
above, plus its own: **what a town's opinion does in v1 is change what people say to
you** (J5, `docs/PLAYER_MODEL.md` §5), and a greeting that silently never fires is
precisely what `--headless` cannot see — it was added the day the reading moved from the
person to the town, to photograph both halves. Like `UNCROWNED_TOWN` it writes the store
directly and is therefore **one frame for one photograph, not a save-able state**.

**All eight are gated on `OS.has_feature("debug")`**, so they are absent from a
release export. Anything else of this kind goes behind the same gate and gets listed
here. A debug tool that is not written down is a debug tool that ships.

> `Engine.time_scale` was considered and rejected: it accelerates the player too,
> so you cannot walk anywhere while time passes, which is the whole point.

## Testing switches — all three decided on 2026-09-18

They were three words that held 2D layers off while the 3D world was tested. Yannick
has now said what becomes of each, and the removals are tasks in `docs/DEMO_TASKS.md`:

| Switch | Decision |
|---|---|
| `Region.TERRAIN_SLOWS_YOU` | **The layer goes.** The speed table and its tests are removed — task **C4**. He found the wild's price in time useless walking his brother's map |
| `Sound.MUSIC` | **The tables go** — they name the 2D pack's tracks, which the art rule now forbids anyway. Music returns one day with real tracks — task **C4** |
| `Screens.QUICK_START` | **The switch goes, the screens stay.** The public build opens on character creation, because the demo does; the quick launch survives as a development path only — task **S2** |

Until those tasks run the switches are as they were, and a test that claims what a
switch turns off still says `OFF` in the run (`TestCase.off`) rather than failing or
quietly passing.

## Effort discipline

Do not spawn subagents or parallel workflows unless I explicitly ask, or unless
the task genuinely requires reading more than fits in one context. Analysis of
documents in this repo does not qualify — I wrote them and can hold them in my
head. Default to answering directly. If you think a task warrants fan-out, say
what it would cost in time and tokens and ask first.

## Current phase

**The simulation is being rebuilt, simpler, and its design is settled** (2026-09-18).
Start at `docs/SIMULATION_MODEL.md`. The work is `docs/DEMO_TASKS.md`: **47 tasks, one
at a time, both suites green between them**, and **nothing is deleted until the demo
runs on the new model** — the clean-up tasks are last on purpose.

**The target is a Windows-only public demo**: creation, the fairy, the ruined village,
the walk to the ironworks, the workers-versus-management quest, combat, and a world
that visibly changes with the choice. macOS was dropped on 2026-09-16, and the Windows
test machine is still not identified — the one platform risk with no fallback.

**The player's own status is not designed yet.** The model covers the simulation of
*places*; Yannick will draft how the player influences it and what the player's status
is, treating the player as a town with a status of the same shape.

**What came before.** v1 and v2 shipped on 2026-09-13 (`docs/V1.md`, `docs/V2.md`,
and everything in `SPECS.md` dated that day). Their simulation is what the redesign
replaces; `docs/SIMULATION_AS_BUILT.md` records it.

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

1. **The king kills you on contact, and there is no fight.** v1's Phase 0 gave the
   king three touches and a death, and that is still what happens. It is the oldest
   debt in the project, and what retires it is the F group of `docs/DEMO_TASKS.md`.

   **The screen question is settled, 2026-09-19.** Yannick ruled for the **in-place
   arena**: a fight happens in the world, with no cut and no separate screen; the
   camera drops to about 27° and **never turns**; the arena's boundary is the people
   watching. `SPECS.md` §10 has been rewritten to say so — it previously ruled the
   opposite ("never in the overworld… side-on 2D"), and the reversal is recorded in
   place rather than quietly applied. The argument is `docs/COMBAT.md` §1 and §6.

   **What is built, and the ruling owes nothing more (2026-09-21):** the fight's rules,
   headless and tested — `core/rules/combat_rules.gd`, `core/fight.gd`,
   `core/systems/combat_system.gd`, `content/moves.json`, and the world clock held by
   `Sim.ticks_held` — plus everything the ruling asked for: the camera that drops and
   never turns (F3), the two keys and the way in (F2), the way back out (F4), an
   opponent who does something (F5), the fight's place in the quest (F6), and the
   presentation a player reads it through — both healths, the wind-up, reach, an arena
   floor and an ending with a beat (`view/fight_hud.gd`, H1–H5 of
   `docs/DEMO_POLISH.md`). Nothing may assume a *separate screen* — that shape is wrong.

   **It is a first version and not the design, and Yannick said so on 2026-09-21**,
   having played it: *« Le système de combat on va le changer je pense. »* So do not
   build depth onto what is there — more moves, weapons, stamina, a second opponent —
   until he has said what it becomes. Fixing what is plainly broken in it is another
   matter, and `docs/COMBAT.md` §12 lists what is known to be.

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
