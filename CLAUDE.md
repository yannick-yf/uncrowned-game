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
| `docs/DEMO_TASKS.md` | The work, as lettered groups of tasks with their checks — *Where the work actually stands*, below, says which are built |

`docs/SIMULATION_AS_BUILT.md` records what the old simulation did, so that what is
dropped is dropped on purpose and not by accident.

**Reading order for a new session:** this file, then `docs/V3.md` (what the game is
today, and the map it runs on), then `docs/SIMULATION_MODEL.md`, then only the section
of `SPECS.md` the task actually needs. **Never read SPECS whole** — it is 4,000 lines
and much of its simulation half is now superseded.

**Precedence.** `SPECS.md` wins on *what the game is*, except where the four documents
above supersede it. This file wins on *how we work* and *which phase we are in*. Where
a genuine conflict crosses that line, Yannick decides — do not silently pick.

## Working with Yannick

Written into the repo on 2026-09-29, when he changed Claude accounts: until then it
lived in one account's private memory, and a new account starts with none. It is how he
wants the work run, learned from his corrections — not a style guide.

- **Speak to him in French, plain and short.** Docs, code and commit messages stay in
  English; game strings are French first. He corrected the French five times in two days
  (*« ton français sonne faux »*, *« je ne comprends pas cette phrase »*), and every time
  it was a metaphor, a compressed clause or a term used without being defined — twice it
  hid a real bug in what was being described. Short sentences, one idea each, no figures
  of speech; define a term the first time it appears (*la coupe* = where the workers
  cut); when he asks what a phrase meant, rewrite the thing rather than explain the
  phrase.
- **Autonomy, a task at a time.** *« Go, stop only if you have an important
  question. »* One commit per task with its docs, both worlds green, the game launching;
  then a short report. Ask only at a real fork — one that touches his brother's work
  qualifies — in plain words, with the recommended option first.
- **Measurements, not adjectives**: tests, seconds, tiles. **Pictures for anything
  visual**: he decides visual questions from frames, not prose, so render them before
  recommending (`tools/shot.sh`, the debug tools below).
- **A big request is run the way group O was** (approved 2026-09-29, *« globalement tu
  as fait du très bon travail »*): planned as numbered tasks in `docs/DEMO_TASKS.md`, each
  with its check; one commit each; frames of every screen in both languages
  (`tools/opening_frames.sh` for the opening); a fresh-eyes review sub-agent walking the
  result at the end, which he allows for reviews and asset research; then his open
  questions in **one numbered list**, which he answers by number in one message.
- **When he is handed a commit to push**: its hash, the one command, and in advance any
  CI step that will be red and why. He reads an unannounced red CI as *everything is
  broken*. A worktree is not private — GitKraken lists every one, and an untracked log
  left in a scratch worktree was once committed and pushed by him in good faith — so a
  worktree is left with `git status --short` empty, and its logs go to the scratchpad.

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

   > **6 and 7 are ruled out, and not yet removed (Yannick, 2026-09-28).** *There are
   > no predefined routes to the king.* How the player reaches him will depend on the
   > player's status and on the kingdom's status against each town's. So Access,
   > Exposure and the third route — and the performer chains and the walk that test
   > them — go, with the rest of C3, **run together with C2 and C4 after P2**. Until
   > then the tests stay green and nothing new is built on the routes. What replaces
   > invariant 7 (*killing somebody never makes the game unfinishable*) is written
   > when the new way to the king is.
8. **The LLM never decides anything mechanical.** `core/rules/` issues the verdict;
   the model phrases it. Its output is text plus enums of ids that already exist.
9. **The player never types free text.** Dialogue is always a choice among generated
   options, each mapping to a known intent.
10. **There are no children in this game.** No child characters, in any role, ever.
11. **Static typing on every function signature and member variable.**
12. **No unseeded randomness.** Use `sim.rng`, never global `randf()`.

## Art rule

**Rewritten 2026-09-30, by Yannick: we draw too, and the rule is coherence.** *« On peut
dessiner tout ce dont on a besoin. Juste on doit avoir une cohérence graphique. »* His
brother makes the world's 3D art — with Codex too — and we may now make 2D sprites and 3D
pieces ourselves wherever the game needs them. What may not happen is a second style:
anything of ours must read as his hand at fifty paces. Mixing styles is the mark of an
amateur game, in meshes exactly as in pixels. Until that day the rule was stricter — his
art only, a plain block in his rock paint where he had drawn nothing, and three
exceptions Yannick made one by one; those three are simply things we made now, listed
below with the fourth.

**What keeps it coherent** — these stand:

- **His style is the reference.** A 3D piece of ours is low-poly and wears his materials
  (`styled_rock`, `styled_wood`, `styled_dark`, his furnaces' `embers`); a person is his
  billboard traveller. A sprite of ours keeps his dark outline, his light from the top
  left, his painted grain, and his shader's rule for what is background — a flat fill
  beside his figure reads as somebody else's hand at once.
- **Nothing of the 2D pack appears, ever** (2026-09-14): it is another style. The HUD's
  font is the pack's, and an open question.
- **Nothing downloaded.** A third artist's hand is the mix this rule is for; the wolf was
  *made* rather than found for that reason (2026-09-26), and Yannick confirmed it when
  he widened the rule: *« que des dessins faits par toi, pas de dessins téléchargés »*
  (2026-09-30).
- **His files are never touched.** `prototypes/` is his and our tools only read it; what
  we make lives beside the window (`view3d/fight/`, `view3d/cast/`, the made pieces in
  `view/world3d.gd`). His library carries a provenance-and-licence manifest and
  `test_workshop_provenance` refuses a file without one.
- **What we made is written down for him**, in `docs/POUR_SLOSINIO.md`, so he does not
  discover it; and a test watches his library for each thing we made in his place (a
  blow, a beast, a grave): it fails the day he delivers one, so that somebody chooses
  between his and ours. **These are watches, not debts** — since 2026-09-30 nothing is
  owed.

**What we have made:**

1. **The fight frames** (2026-09-19, widened 2026-09-24). He had drawn no attack and no
   guard — eight animations, idle and walk in four directions — so a fight showed three
   actions as a person standing still. `tools/draw_fight_frames.gd` builds **twelve**
   frames — a cocked arm, a blow and a flinch in all four facings, plus the two guards
   drawn before the guard was cut — into `view3d/fight/traveler_sheet.png`. It was six
   until Yannick played it and said the animation was very slight: the wind-up had no
   drawing at all, which is the half of a blow a person reads. **North and south were
   added because the grid needed them (K5)**: his figure fills the cell from hair to
   boots, so the axial frames cannot lunge up or down the screen; what carries the blow
   is the arm's direction, and the northward one goes **behind his hair**. **The row
   order in the tool is load-bearing** — right and left are the last two rows, so
   `view/world3d.gd`, which counts our block up from the bottom of the sheet, finds the
   first eight where it left them. **No colour is invented**, and that is a test:
   `test_no_colour_of_ours_is_absent_from_his_own_frame` walks all sixteen cells.
2. **The wolf** (2026-09-26). A plain block in his rock paint read as two rocks biting the
   player; Yannick asked for better, *« créer ou trouver »*, and finding was refused. So
   `_wolf()` in `view/world3d.gd` is eleven boxes in the low-poly language his props
   speak, **coloured only with `styled_rock` and `styled_dark`**.
3. **The graves' markers and the fires** (2026-09-29). `_headstone()` (a rounded stele on
   a plinth, his `styled_rock` only) and `_grave_board()` (a plank cut to a point, his
   `styled_wood` only), placed by the brief as `"made"` pieces; and `_campfire()`,
   **composed from his pieces** — his `boulder_round` small, his `fallen_log` cut to
   firewood, his `embers`, his `fumee_ruine` smoke — with only the flames ours.
   `test_world3d` fails on a marker surface that wears anything but his two paints.
4. **The cast's looks** (2026-09-30, group L of `docs/DEMO_TASKS.md`). Every man was his
   one traveller, six of him in one fight. `tools/draw_cast_looks.gd` dresses him as each
   kind of person the demo shows — the king's guards in blackened plate a fifth taller,
   the watch, the works' guards and archers, the ironworks' workers and their foreman,
   the villagers, Bram and Wren — into `view3d/cast/<look>.png`, one sheet per look in his sheet's layout.
   **Recoloured, not repainted**: each region of him moves to another hue with the
   values of his brush scaled, not replaced, so the shape of his shading stays; what he never drew (a helm, a cap, a hood, a hat, an apron,
   a beard, a sword, a bow) is painted over him in his manner and measured on each frame.
   The recipes and who wears which are `content/looks.json`, read by `view/cast_looks.gd`.
   The player stayed exactly as he drew him, until group A. Yannick chose every look from
   `docs/frames/cast/L1_proposals.png`.
5. **The player's layers** (2026-10-01, groups A and E). His traveller split by
   `tools/draw_player_layers.gd` into body, skin, hair, tunic, trousers, boots and pack —
   **his pixels, cut apart, not redrawn** — plus what he never drew: a head under his hair,
   five hair styles and three beards painted from his own hair's texture, and the items
   (a sword at the belt and in the hand, a bow, the works' guards' cap, the king's guards'
   helm and breastplate), each baked from the very piece group L dresses the cast in, a
   helm's hiding of the hair kept as a mask, and a second skin (`skin_bare`) without the
   shadow his fringe casts, for every cut but his. `view3d/layers/`, stacked and coloured
   live by the paper-doll shader; his traveller is the default look, exactly. And **the
   sword lying on a grave** (`_lying_sword()` in `view/world3d.gd`), four boxes in his stone,
   wood and dark paints — `test_world3d` fails on any other.

The sheets are **not** in `assets/`: that folder is the approved 2D pack's family and
`tools/asset_validator.gd` rightly refuses a file made of his palette. The 3D world's art
has never lived there — his own sheet is in `prototypes/`.

**The 2D map** (the procedural world, kept for its tests and its history) still follows
the pack rule it was built on: free assets only from the packs approved in
`docs/SPECS.md` §13, never two packs from different artists, and anything off-palette or
off-grid fails a validator rather than reaching the screen.

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
view3d/fight/, view3d/cast/, view3d/layers/  His traveller's sheet with our fight frames, one
           sheet per look of the cast, and the player's layers — ours, made by
           tools/draw_fight_frames.gd, tools/draw_cast_looks.gd and tools/draw_player_layers.gd
           (see *Art rule*). Committed; re-run the tool, never edit.
```

## Commands

```bash
godot --headless --path . --import          # once after cloning
tools/run_tests.sh                          # the feedback loop — after every change
tools/run_tests.sh --all                    # before committing
godot --headless --path . -s tools/test_runner.gd -- --fast --profile   # where the suite's time goes
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
`BakeRules.ROCK_IMPASSABLE` (0.85) and above, his meshes, or a plain block of ours. A
footprint shrinks to the piece his library stands for it (`kit_library` in the brief),
and the castle's ramparts stand as blocks. `test_bake` fails on any wall tile the window
does not draw. An invisible wall is never the answer: open it, report it in the bake and
name the debt — or, since the art rule was rewritten (2026-09-30), draw what stands
there, coherent with his hand.

**Delivery ingestion (2026-09-15).** Run `tools/vendor_workshop.sh` before baking or
checking a bake: `tools/workshop_geometry.gd` reads the copied ironworks collision
scenes and refuses stale copies. Only the build tool loads those nodes; core receives
plain polygons. The bake hashes the town and river data and each used collision scene,
and checks that the landscape's resolved crossings agree with the river layout.
**Since 2026-09-21 (G1) the bake also reads his catalogues** — the brief's `catalogs`,
today `assets/ironworks/catalog.json` and, since O13, `assets/farming/catalog.json` (the
cemetery's fence, gate and earth) — and every piece of his it places (the works'
yard: `YardRules`, `CatalogRules`) is stood at his metres and yaw, blocks what its own
collision shapes cover, and has its catalogue and its scene hashed into the bake. **Read
his catalogue before placing anything of his**: its `placement` note is the only document
that says how a piece is meant to be used, and the first yard was built without it.
`tools/bake_region.gd -- --check` remains the freshness check; both worlds remain the
commit checks. The current baked run prints **six** DEBT lines — seven debts, one test owing two; the
run's last line counts debts — for **four** claims, all the map's and the brief's (five
until T2 deleted the clearing and its ring, 2026-09-29), and three OFF lines (four until
S1 took Attunement and its two terrain tests away; the third since O12 is the 2D map's
road into Brindle, which the baked world does not claim). **Three more were things his
brother had not drawn** — a blow, a beast, a grave — and since the art rule was rewritten
on 2026-09-30 they are watches and not debts: nothing is owed. The procedural world
prints **forty-two** DEBT lines (forty-three debts) that say the works' furnaces, its
yard, the wolf packs — where they stand, what they see, how they wander, how they are
surprised and chosen, where they may not go (eleven since groups R and N) —
and the opening's last two stages stand on his map and not on the 2D one, and five OFF lines — the two switches', one saying the 2D map's shore is sand and
not his cliffs, and two claims about the hail's ground that only his map's layout can
make.

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

**Reads need the variable too, for now** (found 2026-09-24). His `~/.gitconfig` carries an
empty `[gpg] format =`, and git dies *parsing* it, before any `-c` override applies — so
`git log` fails without `GIT_CONFIG_GLOBAL` while `git status` and `git add` survive. The
`git -c gpg.format=…` fallback does not work; do not try it again. **Inside a worktree** the
relative path does not resolve, because a worktree's `.git` is a file: use the absolute
`GIT_CONFIG_GLOBAL=/Users/yannickflores/PersoProject/uncrowned-game/.git/overnight-gitconfig`,
and check first how far the worktree is behind (`git rev-list --count HEAD..feat/playable-demo`
— one agent started 64 commits behind). One git command per shell call; stage and commit
in separate calls. **The override file is not versioned** — it lives in `.git/`, so a fresh
clone has none: recreate it with `[user]` name and email as on this branch's own commits
(`GIT_CONFIG_GLOBAL=/dev/null git log -1 --format='%an <%ae>'` reads them without the
broken file), `signingKey` empty, `[gpg] program = gpg`, `[commit] gpgSign = false` and
`[tag] forceSignAnnotated = false` — and never by copying anything from `~/.gitconfig`.

**Run the suite through `tools/run_tests.sh`, never `test_runner.gd` directly.**
The script is part of the check, not a convenience. A GDScript runtime error does
not unwind — it prints to stderr, abandons the function and returns as if nothing
happened — so a crashed test records no failures and reads as a pass. The runner
catches the common case by failing any test that asserts nothing, but **it cannot
see its own stderr**. The script fails on any `SCRIPT ERROR` in the run, which is
the only thing that closes the gap.

Two speeds. `run_tests.sh` runs the **fast suite** — bare simulations, no map
walks, no asset pack — in about **25 s**. `--all` adds the journeys, the asset pack and
the days of weather, and takes about **63 s** on the baked world and **55 s** on the 2D
map. `test_runner.gd -- --fast --profile` prints every suite's time and the 25 slowest
tests; `tools/profile_parts.gd` times the steps tests take and one in-game day system
by system.
(It was 0.9 s and 5.8 s when the map was a greybox and the cast was eight people;
4.7 s and 18 s when v1 shipped; 9 s and 25 s before the simplified simulation, which
added a system running sixty times a second and tests that advance whole in-game days.
The numbers are here to be kept true, not to be admired: if the fast suite ever
stops being the thing you run without thinking, that is the thing to fix. Two things
were already done for that on 2026-09-18 — the walking population is matched once an
in-game hour rather than once a minute, and each day a test simulates is a day it
actually needs. The 4 s the full suites gained on 2026-09-19 is **not** the fight:
`--all` was measured at 42.2 s with the first design's `CombatSystem` taken out of
`Game.build()` and 42.8 s with it in, so a system on the step costs the other 478 tests
nothing measurable. The duel's tests are in the **fast** suite for the same reason.
It was 41 s on 2026-09-29, after O21, and **T4 profiled it the same evening: 22 s** (about 25 s once T9's gate tests joined it).
A quarter of it was `test_screens` building his whole 3D window for tests that read
only the HUD (`draws_the_world`, 9.9 s to 0.2 s); a walk across the baked world cost a
second in `Navigation` over Dictionaries, now flat arrays in the same order, for the
same path (`test_navigation` holds it to the plain search); and every simulated step
resolved the wolf packs' anchors again (`Wild.at` keeps them). **What is left is
simulated days**, 0.44 s each: the drawn walkers on the road and in the works, the
wolves' and the hail's looks, every step. That is the next thing to cut, not a test.)
A suite that declares `const SLOW: bool = true` is in the second group.

**Two worlds, since M1 (2026-09-13); the baked one is the game since M4 (2026-09-14).**
`run_tests.sh` runs on the baked world (about **25 s** fast, **63 s** all);
`tools/run_tests.sh --procedural --all` runs the same suite on the 2D map (about
**55 s**), and both have to be green before a commit that touches the map, the kit, a
position or the pace. A test says where it stands in the world's terms —
`at_a_stall()`, `in_town(&"harrowgate")`, `alone_on_the_road()`, `in_the_wood()`, all on
`TestCase` — and never as a tile; a time budget written for six tiles a second is
scaled by the world's pace (`_at_pace`), never hard-coded. A line marked **`DEBT`** in
the run is the map's or the brief's, not the code's: a claim the spec makes that the
baked world does not yet meet (`TestCase.debt`), printed so it is read and counted
apart so the suite stays green while `docs/MIGRATION_3D.md` §5 is open. Four claims
stand today, all the map's and the brief's; they are counted above, under *Delivery
ingestion*. Never turn a failure
into a debt to get green; a debt names something a person has to settle. A line marked **`OFF`** is the third kind
(`TestCase.off`): a claim that holds only while one of the testing switches below is
on, printed so the switch is not forgotten and counted apart so the claim is not lost —
or, since O12, a claim one world makes and the other cannot (the cemetery's cliffs, the
hail's ground, the 2D map's road into Brindle).

One tick is one in-game minute and the overworld runs 4 ticks per real second, so
`--ticks 5000` is 3.5 in-game days — about 21 real minutes of play. See SPECS §8.

## How to work here

**Codex onboarding (2026-09-15).** Root `AGENTS.md` is Codex's automatically loaded
entry point. It requires this agreement in full, then `docs/V3.md`, then
`docs/MIGRATION_3D.md` §6.2 and §9, and only the task's needed SPECS section. This
agreement remains shared and binding; `AGENTS.md` records Codex's lanes and the files
reserved for Claude's map ingestion, so the two agents do not edit the same work.
(Dormant since 2026-09-18, as `AGENTS.md` itself says: its lanes and its reserved list
are out of date, and nothing in it is assigned.)

Write the test first. Run the fast suite after every meaningful change — it is the only
thing that tells you whether something broke. (About 25 s since T4: see *Two speeds*.)

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
named, the graves where you wake, and where you are standing. Asked for as a debug tool
and kept as a real one: a game whose argument is *the road against the forest* should
let you see the shape of the argument. It is painted once into a texture rather than
redrawn, because 56,000 rectangles a frame is a slideshow. Since O21 it names the graves
where you wake, keeps every name off every other, and is bound to the **letter** M
rather than the key's place — the moving keys are physical so WASD sits under an AZERTY
hand, but a key the HUD names by its letter has to be found by its letter.

**`tools/shot.sh out.png [title|creation|play|pause|journal[:page]|map|inventory[:bag]] [x,y]`** renders one
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

**`UNCROWNED_DUEL=bram[:steps[:hand]]`** (2026-09-24) squares the player up against
somebody for the frame `shot.sh` takes, with the lens already dropped and the screen
already darkened. Same gate and same reason as the two above, plus two of its own: the
fight's camera takes about a second to move, so without this every photograph of a
fight is a photograph of a camera halfway through moving; and a turn-based fight spends
most of its length with nobody doing anything, so a photograph taken at an arbitrary
step is a photograph of two people standing about. (It replaced `UNCROWNED_FIGHT`, the
first design's, deleted with it in K6 on 2026-09-26.) `bram` alone squares up and waits on the
player, which is the frame that shows the tiles a turn buys; `bram:19:press` runs
nineteen steps with one of `tools/duel_player.gd`'s hands on the keys — `press`, `hold`,
`stand`, `leave`, `cast`, `bow` — which is the step a blow lands on. `wolf,wolf` squares up against several at once (O6); `ambush:0:25` presses K at pack 0 from where `UNCROWNED_AT` stands him, the surprise attack (R3); `gatekeeper@1` against a stranger, and the yard answers as it does in play (T9); `drill:sword[:steps[:hand]]` begins a drill of the tutorial as its master's line does (O8); `drill:magic` also writes the fairy's gift straight in, and `drill:bow` a bow of your own, one frame and not a save-able state (O10, T5). **When a picture is being
taken the simulation is held on the step asked for**, or the twelve frames before the
shutter would carry the fight past it; and only the last ten steps' events are fresh, so
the picture carries one blow's spark and number and not every blow's.
`UNCROWNED_AT=280,315 godot --headless --path . -s tools/play_duel.gd -- press 400`
prints the trace that says which step is which, and it reads the same `UNCROWNED_AT` the
shot does, because the step numbers depend on how far apart the two of them start.

**`UNCROWNED_TALK=maddox[:standing]`** (2026-09-24) stands the player in front of
somebody, mid-greeting, for the frame `shot.sh` takes, and sets the standing of the town
they are both in to the number after the colon. Same gate and same reason as the three
above, plus its own: **what a town's opinion does in v1 is change what people say to
you** (J5, `docs/PLAYER_MODEL.md` §5), and a greeting that silently never fires is
precisely what `--headless` cannot see — it was added the day the reading moved from the
person to the town, to photograph both halves. Like `UNCROWNED_TOWN` it writes the store
directly and is therefore **one frame for one photograph, not a save-able state**.

**`UNCROWNED_DID=deed[,deed]`** (2026-09-24) does those deeds where the player is
standing, for the frame `shot.sh` takes, through `Deeds.perform` — the one pipe every
deed in the game uses, so the witnesses are the real witnesses. Same gate and same
reason, plus its own: J6's journal page shows **what you did and what it cost, side by
side**, and there was no way to photograph it — a killing has no key yet (K3) and a
theft needs a stall and a key press. Unlike `UNCROWNED_TOWN` it writes nothing directly;
it raises the real event, so the picture is of the game.
`UNCROWNED_DID=i_stole_in_public,i_killed_somebody_innocent UNCROWNED_AT=236,208
UNCROWNED_SCREEN=journal:standing` is the frame that settled J6.

**`UNCROWNED_QUICK=1`** (2026-09-28, S2) skips the title and the creation and opens a
fresh run at the floor of every trait, saved as Begin saves it. It is what
`Screens.QUICK_START` was for two weeks, turned from a constant that was on in every
build into a switch a debug build has to be asked for — because the public build must
open on the title (`Screens.first_screen`, and `test_the_public_build_opens_on_the_title`).
In the Godot editor it goes in the run's environment; from a terminal,
`UNCROWNED_QUICK=1 godot --path .`.

**`UNCROWNED_HAIL=bram[:steps]`** (2026-09-29, O17) stands the player on the first
tile of the ground somebody watches, on the way in from the graves, runs that many
steps and holds the simulation there for the frame `shot.sh` takes: `bram` is the step
he sees you and the '!' goes up, `bram:90` has him walking over, `bram:400` beside you
and talking. Same gate and same reason as the others — a '!' that never goes up is
exactly what `--headless` cannot see. **And the frames that stand you somewhere spend
the hail first**: `UNCROWNED_AT`, `_TALK` and `_DUEL` write `hailed:<who>` straight into
the facts, so a photograph of Brindle is of Brindle and not of Bram walking over. One
frame for one photograph, not a save-able state. A hail is spent once, so on a run that
has already been called it warns and does nothing — take it on `UNCROWNED_QUICK=1`.

**`UNCROWNED_SCREEN=journal:<page>`** (2026-09-24) is not a tool of its own but the existing
one extended: the journal is seven pages and the page being photographed is rarely the
first, so the screen name may carry the page after a colon — `journal:standing`,
`journal:kingdom`, and so on for any page in `_journal_pages`.

**`tools/opening_frames.sh [out_dir] [languages…]`** (2026-09-29, O21) photographs the
opening for a review: thirty-seven frames a language, on a made run, from the title to the fight at
the works' gate, the inventory and the equipment in play (`ONLY=<regex>` takes only the frames whose name matches),
through the tools above, with one line per frame giving its count of `SCRIPT ERROR`s — 0,
and then look at them. A shot plays the run on disk and the language is a setting on
disk, so it moves the player's `save.json` aside (every frame is then a fresh run) and
rewrites `settings.cfg` per language; it copies both first and puts them back on exit,
checked by fingerprint the day it was written. A script, not part of the game, so it
never ships; its tiles are the baked world's.

**`UNCROWNED_FACTS=fact[,fact]`** (2026-09-30, V5) writes facts straight in for the frame
`shot.sh` takes — `cinderworks:forced` is the gate taken by force, which in play is four
men beaten, and the empty gateway and the furnaces' offers after it had no other way to be
photographed. Like `UNCROWNED_TOWN`, one frame for one photograph, not a save-able state.

**`UNCROWNED_LOOK=hair_style=long,hair_colour=blond`** (2026-10-01, A6) presets what the
player looks like — on the creation screen for its photograph, and on the run
`UNCROWNED_QUICK=1` opens — so a non-default player can be photographed without playing
through creation. It is only what the creation event would have carried, and an option
that does not exist makes it ignored. `UNCROWNED_SCREEN=creation:talents` opens the
creation's second page.

**`UNCROWNED_GEAR=royal_helm,short_sword`** (2026-10-01, E4) puts items in the player's
bag and on him for a photograph — the run a shot carrying `UNCROWNED_LOOK` or `_GEAR`
starts is made, so it begins with the start kit and no sword. Each is put on as it comes,
so an item listed after another of its slot puts the first back in the bag; a find whose
item he now carries is spent, so the sword is not also lying on its grave.
`UNCROWNED_SCREEN=inventory[:bag]` opens the inventory (Tab), the cursor in the bag after
the colon. Written straight into the
store, like `UNCROWNED_TOWN`: one frame for one photograph, not a save-able state.

**`UNCROWNED_TURN=wheel[:category]`, `target:category[:rank]` or `ambush`** (2026-10-03, N3)
opens a step of the player's turn for a photograph — the wheel on a segment, an action
aimed at its n-th foe, or, outside a fight, the choice of whom to surprise. **`UNCROWNED_MOUSE=x,y`**
holds the pointer at a point of the window (wiggling a pixel so hovering answers it), for a
photograph of what the mouse does (N5).

**All seventeen in-game tools are gated on `OS.has_feature("debug")`** — `T`, `G`, the
journal's who-is-where, and the `UNCROWNED_` variables of `shot.sh`, `FREE`, `TOWN`,
`LENS`, `DUEL`, `TALK`, `DID`, `QUICK`, `HAIL`, `FACTS`, `LOOK`, `GEAR`, `TURN` and `MOUSE` — so they are absent from a release
export. **`M` is the one that is not**: kept as a real feature, it ships. Anything else of this kind goes behind the same gate and gets listed
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
| `Screens.QUICK_START` | **Gone** (S2, 2026-09-28). The public build opens on the title and passes through creation; the quick launch is `UNCROWNED_QUICK=1`, a debug tool below |

Until those tasks run the switches are as they were, and a test that claims what a
switch turns off still says `OFF` in the run (`TestCase.off`) rather than failing or
quietly passing.

## Effort discipline

Do not spawn subagents or parallel workflows unless I explicitly ask, or unless
the task genuinely requires reading more than fits in one context. **Standing, since
group O (2026-09-29):** a fresh-eyes review sub-agent at the end of a group, and research
into assets. Group O's planning fan-out (seven readers, a planner, a reviewer) was asked
for with that request and is not standing. Analysis of
documents in this repo does not qualify — I wrote them and can hold them in my
head. Default to answering directly. If you think a task warrants fan-out, say
what it would cost in time and tokens and ask first.

## Current phase

**The simulation is being rebuilt, simpler, and its design is settled** (2026-09-18).
Start at `docs/SIMULATION_MODEL.md`. The work is `docs/DEMO_TASKS.md`: **lettered groups
of tasks, one at a time, both suites green between them**, and **nothing is deleted until the demo
runs on the new model** — the clean-up tasks are last on purpose.

**The target is a Windows-only public demo**: creation, the fairy, the ruined village,
the walk to the ironworks, the workers-versus-management quest, combat, and a world
that visibly changes with the choice. macOS was dropped on 2026-09-16, and the Windows
test machine is still not identified — the one platform risk with no fallback.

**The player's own status is designed and built** (2026-09-23, built 2026-09-24).
`docs/PLAYER_MODEL.md` is the design and **J1–J6 of `docs/DEMO_TASKS.md` are done**: the
player is shaped like a town — an allégeance he chooses, a standing per town that moves
only with witnessed deeds, and a richesse that is gold. **The town is the unit of
account**: a theft moves the town it happened in and not the person it happened to.

### Where the work actually stands — 2026-10-01

The task list is the record; this is the short version, because a session that has to
reconstruct it from forty commits will get it wrong.

| Group | State |
|---|---|
| **M, P, Q** | Built, except **M3** (the colour cast — built and **not accepted**; Yannick wants to look at it with his brother), **P2** (below) and **Q6's lines**. These M's are `DEMO_TASKS.md`'s model tasks; `MIGRATION_3D.md` has its own phases M1–M5, whose **M3b** (his art) and **M5** (the map's fill) wait on his brother — two series, one letter |
| **F** | Built, and **superseded**. The first fight was real-time; Yannick played it and rejected it |
| **J** | Built. The player's own simulation |
| **K** | Built, K3 included. **K6 is done** (2026-09-26): Yannick played the turn-based fight and the real-time one is deleted |
| **W** | Built. W4 found there is no funnel; **building one is deferred** to a game-design pass once the first tasks are done (Yannick, 2026-09-26) |
| **O** | **Built, O1–O22** (2026-09-29): the cemetery south of Brindle, Bram's hail, three drills (sword, bow with Wren, the fairy's gift) in which nobody falls, then the words. Yannick validated the drafted lines (O18–O19) *for now*, French and English; O21's route review is done and its findings fixed. `docs/V3.md` *The opening, redone* is the short version. **He played it the same evening**: the combat tutorial is the one finding — group T |
| **T** | **Built, T1–T10** (2026-09-29/30), from Yannick's first play of the opening: his rulings written down, the clearing out, a page of tasks for his brother (`docs/TACHES_POUR_SLOSINIO.md`), the fast suite profiled (41 s to about 25), **the bow redone** — an arrow lands when it is shot, Bram's line hands you a bow, **U** changes the weapon in your hands — every lesson's card with **its steps and keys and a hint for where you stand** (and the first round's HUD, which drew no keys, fixed), and **the gatekeeper's guards, who keep coming**: that fight cannot be won, and the gate stays manned and shut. A fresh-eyes review walked it; its seven findings are fixed. **The check is Yannick playing the tutorial again** |
| **V** | **Built, V0–V6** (2026-09-30): Yannick's revision of the gate — three very strong king's guards (40 points, blows of 10) answer an attack; beating the four forces the gate, open and empty; then the furnaces are the player's — putting one out brings the quest's guards, a sword and two bows, easy (V6), lighting one brings Tom. A review walked it and its five findings are fixed. **The check is Yannick playing it, with G** |
| **L** | **Built, L1–L11** (2026-09-30): every type of person told apart at a glance — the king's guards heavy and armed, the quest's guards light, workers, Harry, villagers, Bram and Wren — by `tools/draw_cast_looks.gd` and `content/looks.json`, thirteen looks Yannick chose from a board; **the art rule rewritten the same day** — we may draw what the game needs, coherent with his brother's hand. Reviewed, findings fixed, his brother's task page republished. **The king's own look is a task for later** |
| **A** | **Built, A1–A7** (2026-10-01): **who you are** — the player's appearance chosen at creation (six hair styles, eight colours, five skins, four beards, six colours of clothes), drawn in layers: his traveller split by `tools/draw_player_layers.gd`, stacked and coloured live by the paper-doll shader (`view3d/layers/`, `view/paper_doll.gd`), the same drawing on the two-page creation screen and in the world. Design and Yannick's answers: `docs/CREATION_AND_GEAR.md` |
| **E** | **Built, E1–E7** (2026-10-01): **what you carry** — six slots on the same layers, ten items drawn from group L's pieces (`content/items.json`), the start kit and no weapon, **the first sword on a grave** two tiles from where you wake, fists for less without it, Wren's bow an item, a beaten fighter leaving what he wore; armour's protection off every blow and weight a tile a turn (save version 5); **Tab** opens the inventory over a stopped world. A fresh-eyes review walked creation to equipment in play. Yannick played it the same evening: hair styles validated for now, trousers grey, his own surcoat in the king's set |
| **R** | **Built, R1–R5** (2026-10-01, from his play): **R1 built** — the bow lesson is given by Wren, who keeps her distance and shoots too. **Engaging a fight yourself**, a simplified Baldur's Gate 3, his answers in hand: **R2 built** — enemies outside the towns see in a cone ahead of them and wander their ground (`DuelRules.sight_of`, `roams_of`; the wolves for now); **R3 built** — K from outside their sight, the first blow doubled (`WildSystem.ambush_target`); **R4 built** — every blow may miss by agility (80 % ± 5 a point of difference, 50–95 %, 95 % for the player in the lessons; the gift and the surprise always land), the chance shown before the blow. |
| **N** | **The work now** (2026-10-03, from his play): the fight's actions as Baldur's Gate 3 has them. **N1–N6 built**: the magic lesson repaired (E left the fairy after her first line, without her gift); a generic list of actions (`content/actions.json`, `ActionRules`); **a wheel** round the player (K) instead of U and I; **an explicit target** with its chance and damage, confirm or go back (Escape), in a fight and for the surprise attack; the mouse; the three lessons taught the new way. **N7**: frames, a review. Then **P2**, with Yannick |
| **S** | **S1 and S2 built** (2026-09-28): four traits, a pool of 8, and the public build opens on the title; **S3 needs a Windows machine nobody has**, and S4 needs a stranger |
| **C** | **C1 built** (2026-09-28): the LLM layer deleted. **C3's first half built** the same day: one quest, no opinion per person. The rest of C3 — ranks, documents, the three routes, the invariant-7 walk — goes **with C2 and C4, as one change** (Yannick, 2026-09-28). **C2–C4 validated** (2026-09-29, evening), **after P2**. The clearing is deleted (T2) |
| **P2** | **After group T, with Yannick**: a review and rewrite of every line of the demo — Claude drafts, he validates, French first. It writes the Cinderworks' lines by state (Q6's), and C4 deletes the old ones. O18–O19's drafts stand until then and keep their `_p2` marks |

**Since 2026-10-01 a blow may miss** (R4, Yannick): the chance by agility, rolled from the
run's seed so a replay misses the same blows — `docs/COMBAT_V2.md` records the end of *no
dice*. A test about how a blow works, not about the dice, asks for `sure_hits()`.

**Two things are true of the fight and both matter.** The turn-based design of
`docs/COMBAT_V2.md` is the only fight there is — the real-time one was deleted in K6,
and `docs/COMBAT.md` records what it was. And **the player's hundred hit points are a
development value Yannick set on purpose**, so nothing in the demo can threaten him; thirty is the
recommendation and **S4** is when it has to be settled.

**One defect is open and it is ours, not his brother's**: `docs/MIGRATION_3D.md` §9b.
His merged meshes are compressed binaries carrying his project's own paths, which our
vendoring cannot rewrite. Three sectors are dropped from the copied map plate to keep
the game launchable, and that is a patch — the four real answers are in §9b and the
recommendation is to ask his brother first.

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
on him: his props and the 25 faces in his style (M3b) and the map's own fill (M5). The king's contact kill is still the oldest debt in the project (*Standing exceptions*, below). Nothing structural moves
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

**The machinery is deleted** (C1, 2026-09-28): the packet (`core/context.gd`), the
phrasebook, `PhrasingSystem`, `view/phraser.gd`, `tools/phrase.py`, the briefs
(`core/answers.gd`, `content/answers.json`), the voice reader and the packet tools. It
had been inert since 2026-09-12. **`core/rules/prose_rules.gd` stays**, trimmed to what
was never the model's: the house style every hand-written line is checked against, and
the join that puts a reaction in front of an answer. `content/voices.json` stays too, as
the writing notes for P2 — nothing reads it now.

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

   **Corrected 2026-09-29: nothing retires it now.** The F group was built, superseded
   and deleted (K6), and the turn-based duel never took the king on — `ContactSystem`
   still kills on the third touch, and no task in `docs/DEMO_TASKS.md` replaces it. It
   waits on the way to the king, which is not designed yet (invariant 7's note).

   **The screen question is settled, 2026-09-19.** Yannick ruled for the **in-place
   arena**: a fight happens in the world, with no cut and no separate screen; the
   camera drops to about 27° and **never turns**; the arena's boundary is the people
   watching. `SPECS.md` §10 has been rewritten to say so — it previously ruled the
   opposite ("never in the overworld… side-on 2D"), and the reversal is recorded in
   place rather than quietly applied. The argument is `docs/COMBAT.md` §1 and §6.

   **What is built, and the ruling owes nothing more (2026-09-21):** the fight's rules,
   headless and tested — turn-based since K6 (2026-09-26): `core/rules/duel_rules.gd`,
   `core/duel.gd`, `core/systems/duel_system.gd`, `content/duel.json`, and the world
   clock held by `Sim.ticks_held`, whose only writer is `DuelSystem` — plus everything
   the ruling asked for: the camera that drops and
   never turns (F3), the two keys and the way in (F2), the way back out (F4), an
   opponent who does something (F5), the fight's place in the quest (F6), and the
   presentation a player reads it through — both healths, the wind-up, reach, an arena
   floor and an ending with a beat (`view/fight_hud.gd`, H1–H5 of
   `docs/DEMO_POLISH.md`). Nothing may assume a *separate screen* — that shape is wrong.

   **The turn-based fight is the demo's v1, and Yannick said so on 2026-09-26**,
   having played it several times: good for a v1, and **more versatility — ranged
   combat, magic, a better AI — comes in a later workstream, on its own branch**. So do
   not build that depth onto it here. Fixing what is plainly broken is another matter.

   **Narrowed on 2026-09-29, by him:** a bow and one spell come **now**, in a version
   scoped to the tutorial's three drills (group **O** of `docs/DEMO_TASKS.md`), on this
   branch — Wren's bow and the fairy's gift. The depth — an AI worth the name, ranged
   balance, more spells — is still the later workstream. **And the bow is redone the
   same evening, having been played** (group **T**): *« je tire, ça tire »* — an arrow
   lands when it is shot, for everybody, and the player carries a bow of his own.

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
