# Making the demo look and feel like a game

Written 2026-09-21, after Yannick played it. Two things are not ready and both are
mine: **the works' yard is placed geometry rather than designed place**, and **the
fight is a working simulation with no presentation on top of it**.

This document is the diagnosis, the plan, and the prompts to run it. **No code has been
written for any of it.**

---

## 0. The root cause, because it changes how the work is done

His brother ships **`prototypes/brindle_3d/assets/ironworks/catalog.json`**: 62 assets,
each with `size_m`, `bounds_center_m`, `collision_shapes`, `ground_pivot`, a `family`,
and a **`placement`** note written by him, in French. The file's header says
`units: meters`, `origin: ground center`, `front: +Z`.

Three of those assets exist for precisely the job Q1 invented a system for:

| Asset | `size_m` | What his own note says |
|---|---|---|
| `soubassement_2m` | 1.98 × 0.68 × 0.40 | *Module de soubassement et de **séparation de cour**.* *Extrémités à X = ±1 m ; dupliquer pour prolonger.* |
| `cloture_2m` | 2.13 × 1.15 × 0.13 | *Barrière de bois pour **limites de cour** et petits enclos.* |
| `portail_cour` | 3.26 × 1.50 × 1.37 | *Deux battants ouverts avec ferrures et poteaux.* ***Passage central de 2,6 m** pour charrettes et piétons.* |

And beside them: `enseigne_forge`, `quai_chargement`, `rigole_pierre_2m`, and in the
royal-city set a `corpsdegarde` and an `enceinte_de_la_ville`.

**None of this was used.** Q1 looked in `assets/library/modules/`, found one generic
`fence_2m`, concluded the library had no gate, and placed tile-sized abstractions on a
computed rectangle — no facing, no metre dimensions, no gate, no guardhouse. A tile is
2 m and his modules are 2 m: they would have tiled exactly.

**The rule this earns:** *read his catalogue before placing anything of his.* It is the
only document that says how his pieces are meant to be used, and it is written to be
read.

---

## 1. What is actually wrong with the yard

Judged from `UNCROWNED_LENS="48,42" tools/shot.sh … play 316,206`:

1. **It is a rectangle on a map that has no rectangles.** His village is composed —
   buildings at angles, paths that bend. The fence runs dead straight north–south and
   east–west through all of it.
2. **It attaches to nothing.** A boundary ends at a building, a gatepost, a bank. This
   one starts in a field and stops in a field.
3. **It encloses an abstraction.** Which of his sheds fall inside is an accident of the
   two corners in the brief. Nothing on the ground says *this is the production yard*.
4. **There is no gate** — only a gap where the street crosses, with a man in it who
   introduces himself as a bridge guard.
5. **The ground does not change** across the boundary, so the yard is not a place.
6. **The pieces do not read as one fence**: 1×1 props with no facing, so the run looks
   like separate posts rather than a line.

---

## 2. What is actually wrong with the fight

The simulation is sound — deterministic, replayable, frame-data driven, and it survives
being played. **Everything a player reads it through is missing.**

1. **The opponent's health is nowhere on screen.** You cannot tell if you are winning.
2. **The player's own health is a line of small HUD text**, unchanged from exploration.
3. **A hit, a blocked hit and a whiff look the same** apart from hitstop. No flash, no
   sound, no shake, no number.
4. **The wind-up telegraph is a 0.3-tile lean.** It is the whole basis of the design —
   28 frames to read a blow — and it is nearly invisible.
5. **Nothing shows range.** The player cannot tell when they are in reach, so spacing,
   which is most of the fight, is guesswork.
6. **The arena is a vignette and nothing else.** No floor, no boundary you can see; you
   walk into an invisible wall at two tiles.
7. **Winning and losing happen in one frame** with no beat.

---

## 3. The plan

Two groups. **G depends on G1**; H is independent and can run in parallel.

### G — the works, made of his own pieces

| | Task | Depends |
|---|---|---|
| **G1** | **The bake reads his catalogue.** `catalog.json` becomes the source of truth for every piece of his the bake places: `size_m` → footprint in tiles, `front: +Z` → a rotation, `ground_pivot`, and `collision_shapes` → what actually blocks. Today the bake assumes 1×1 tiles and no facing. | — |
| **G2** | **The boundary, rebuilt from his separation modules.** `soubassement_2m` where it meets stone and buildings, `cloture_2m` for the light runs, each duplicated end to end as his note says. It **follows the site**: it attaches to his buildings, uses the river as the east edge with no fence at all, and encloses the production ground rather than a rectangle. | G1 |
| **G3** | **The gate is `portail_cour`**, one piece, with its 2.6 m carriage passage on his street. The `corpsdegarde` beside it, and the guard standing in the passage rather than in a gap — with lines of his own, not the bridge guard's. | G2 |
| **G4** | **The threshold reads without a word.** The ground changes across it (his coal and packed earth inside, the quarter's outside), `enseigne_forge` at the gate, and the approach composed so a player walking up knows this is somewhere else. | G3 |

### H — the fight, presentable

> **Built 2026-09-21**, all five, and recorded in `docs/COMBAT.md` §12 with the frames.
> Two things the presentation proved the simulation wrong about were changed there and
> nowhere else — how close two fighters may stand, and where a killed player wakes up —
> and both are rows in `content/moves.json` or bugs, not balance.

| | Task | Depends |
|---|---|---|
| **H1** | **Both fighters' health on screen**, the opponent named. It appears when the fight does and goes with it. ✅ `view/fight_hud.gd` | — |
| **H2** | **A hit reads as a hit.** Clean hit, blocked hit and whiff are three different things to look at: colour, shake, particle, sound. Hitstop already exists and should be felt rather than merely present. ✅ | — |
| **H3** | **The telegraph you can read.** The wind-up must announce itself at the frame it starts — the research says 28 frames and a human needs 16 of them. The lean is not enough. ✅ `CombatRules.telegraph_at` | — |
| **H4** | **Spacing made legible**, and the arena given a floor. The player must be able to see when they are in reach and where the boundary is, without a tutorial. ✅ and a pushbox of 900 mm | — |
| **H5** | **An ending with a beat.** Winning and losing each get a moment before the world comes back. ✅ `Fight.settling` | H1 |

---

## 4. The prompts

Each is self-contained. Paste one per agent. **They all inherit `CLAUDE.md`** — do not
paste it in.

### Prompt G1 — the bake reads his catalogue

> You are working in the Uncrowned repository. Read `CLAUDE.md` first, then
> `docs/MIGRATION_3D.md` §6.2, then this task.
>
> **The job.** `prototypes/brindle_3d/assets/ironworks/catalog.json` is the brother's own
> asset catalogue: 62 pieces with `size_m` in metres, `bounds_center_m`, `ground_pivot`,
> `collision_shapes`, a `family`, and a French `placement` note. Its header declares
> `units: meters`, `origin: ground center`, `front: +Z`. **The bake does not read it.**
> `core/region_bake.gd` places his props as 1×1 tiles with no facing, which is why a run
> of his 2 m fence modules renders as spaced posts rather than a line.
>
> Make the bake read it. A tile is 2 m (`BakeRules.METRES_PER_TILE`), so his modules tile
> exactly. At minimum: a piece's footprint in tiles comes from `size_m`; a piece placed
> along a run is rotated so its `+Z` faces the way the run faces; `ground_pivot` is
> honoured; and what a piece blocks comes from its own `collision_shapes` rather than
> from its bounding box.
>
> **Do not change anything in `prototypes/`.** It is his. Read it only.
>
> **Checks.** Both suites green (`tools/run_tests.sh --all` and
> `--procedural --all`). Re-bake and confirm `tools/bake_region.gd -- --check` is clean.
> And **look at it**: `tools/shot.sh` a run of his modules before and after, and put the
> two frames in the report. A suite cannot see a fence that renders as posts.

### Prompt G2–G4 — the yard, designed rather than computed

> You are a level designer working in the Uncrowned repository, composing with somebody
> else's art kit. Read `CLAUDE.md`, then `docs/QUEST_CINDERWORKS.md`, then
> `docs/DEMO_POLISH.md` §0–§1, then this task. **G1 must be done first.**
>
> **The job.** The Cinderworks' production yard is currently a one-tile-thick rectangle
> of generic fence stamped on computed corners. Rebuild it as a place, out of the
> brother's own courtyard vocabulary, which he documented in
> `prototypes/brindle_3d/assets/ironworks/catalog.json`:
> `soubassement_2m` (low stone wall, *séparation de cour*, duplicate to extend),
> `cloture_2m` (wooden fence for yard limits), `portail_cour` (open gate, 2.6 m carriage
> passage), `enseigne_forge`, `quai_chargement`, and `corpsdegarde` from the royal-city
> set.
>
> **What it has to achieve**, in order of importance:
> 1. A player walking up knows they have arrived somewhere different, without being told.
> 2. The boundary **attaches**: it ends at his buildings, at the gate, at the riverbank.
>    It never starts or stops in open ground.
> 3. **The river is the east edge.** No fence on or beside it.
> 4. **One gate**, on the street that already runs into the works, built from
>    `portail_cour`, with the guard standing in its passage.
> 5. The ground changes across the threshold.
> 6. It reads as composed by the same hand as the rest of the village. If a frame of your
>    yard next to a frame of his village looks like two people worked on it, it is wrong.
>
> **Constraints.** Nothing of the 2D pack, ever (`CLAUDE.md`'s art rule). Nothing invented
> where one of his pieces exists. Positions are anchors in `content/places.json` or
> entries in `content/bake_brief.json`, never constants in a `.gd`. What stops the player
> must be visible, and what does not stop them must not be drawn as though it does — both
> halves have already cost a session.
>
> **Checks.** Both suites green. `test/test_works_yard.gd` still passes and gains whatever
> new rules you rely on. Walk it: the existing end-to-end test
> (`test_the_whole_quest_replays_from_its_log`) must still walk in through the gate.
> And **six frames in the report**: the approach, the gate from outside, the gate from
> inside, the boundary where it meets a building, the river edge, and a wide shot beside
> an equivalent wide shot of his untouched village.

### Prompt H — the fight, presentable

> You are a game-feel engineer working in the Uncrowned repository. Read `CLAUDE.md`,
> then `docs/COMBAT.md` whole, then `docs/DEMO_POLISH.md` §2, then this task.
>
> **The job.** The fight's simulation is sound: deterministic, replayable, driven by frame
> data in `content/moves.json`, and it survives being played. Everything a player reads it
> *through* is missing, and Yannick's verdict after playing was that it looks like five
> minutes of work. Fix the presentation, and change the simulation only where the
> presentation proves it wrong.
>
> **What it has to achieve:**
> 1. **Both fighters' health on screen**, the opponent named, appearing and leaving with
>    the fight.
> 2. **A hit reads as a hit**, and a clean hit, a blocked hit and a whiff are three
>    different things to look at. The hitstop already in `CombatRules` should be felt.
> 3. **The wind-up announces itself** at the frame it starts. §2 of `docs/COMBAT.md` is
>    built on the player having 28 frames to read a blow and needing 16 of them; today the
>    whole telegraph is a 0.3-tile lean and it is nearly invisible.
> 4. **Spacing is legible.** Reach is most of this fight and the player currently cannot
>    see it.
> 5. **The arena has a floor**, not only a darkened edge. The player walks into an
>    invisible wall at two tiles.
> 6. **Winning and losing get a beat** before the world returns.
>
> **Constraints.** `core/` never imports from `view/`; presentation lives in `view/`, and
> anything the simulation must agree about (timings, states) is a pure function in
> `core/rules/`. No Godot physics. No unseeded randomness. Every timing in steps, never in
> seconds. All tuning stays in `content/moves.json` — the whole of balance is editing one
> row, and that must remain true.
>
> **Checks.** Both suites green, and the fight's existing tests still pass unchanged
> unless you can say why one was wrong. **Play it, do not only test it**: `docs/COMBAT.md`
> §5 records two bugs a green suite could not see, and §10 four more. Use
> `UNCROWNED_FIGHT=bram:<steps>` with `tools/shot.sh` for frames, and report frames of: a
> wind-up, a clean hit, a blocked hit, and the moment of winning.

---

## 5. What is deliberately not in here

- **The fight's animation frames.** Eight exist and they are ours, drawn from his pixels
  under Yannick's explicit exception (`CLAUDE.md`, art rule). They are crude and both of
  us know it. Three real frames from his brother replace them and the test that waits for
  that is already written.
- **P2, the quest's words.** Yannick's, and the placeholders are marked `_p2` in the cast
  files.
- **M3's colour cast**, which he has not accepted.
