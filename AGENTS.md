# Uncrowned — Codex instructions

## Read first, in this order

1. Read `CLAUDE.md` in full. Its working agreement, architecture, twelve invariants,
   commands, testing switches and commit rules bind Codex exactly as they bind Claude.
2. Read `docs/V3.md` for what the game is today.
3. Read only §6.2 and §9 of `docs/MIGRATION_3D.md` for the ingestion contract and
   decisions in force.
4. Open only the section of `docs/SPECS.md` needed by the task. Never read it whole.

Read nothing else until the task needs it. Do not re-derive settled decisions.
`SPECS.md` governs what the game is; `CLAUDE.md` governs how we work. If code and
spec disagree, or a conflict crosses those domains, Yannick decides. Follow his
current instructions. Start with V3 even where an older paragraph points to V2.

This file is the Codex entry point, not a copy of the shared agreement: keeping
`CLAUDE.md` authoritative avoids two versions drifting apart (2026-09-15).

## Ownership and boundaries

Yannick owns systems, content and design. Codex works on player creation, spec
revision and alignment, French dialogue, quests, factions and rank, lore, cast
backgrounds, endings and combat. Implementation belongs in `core/`, `core/rules/`,
`core/systems/`, `content/` and `test/`, with the corresponding documentation.
Nothing may assume the future combat screen's shape.

The brother (slosinio) owns all of `prototypes/`. Never edit anything there.
`view3d/workshop/` is generated: never edit or commit it. `view/` is outside Codex's
lane unless Yannick's task explicitly includes it. Our side never adds graphics.

Claude owns the current map-ingestion work. Do not edit these files:

- `core/region_bake.gd`
- `core/rules/bake_rules.gd`
- `content/bake_brief.json`
- `content/region.json` (generated; never hand-edit)
- `view/world3d.gd`
- `test/test_bake.gd`
- `test/test_world3d.gd`
- `test/test_overworld.gd`
- `docs/MIGRATION_3D.md`

If a task needs a file outside your lane, stop and name it to Yannick. Do not work
around the boundary by changing another layer. Preserve other contributors' work.

## Task workflow

- Work directly. Do not spawn subagents or parallel agent workflows unless Yannick
  explicitly asks. Keep investigation limited to the task.
- Inspect the working tree before editing. Start each task from `main` on a branch
  named `codex/<task>`. Keep changes and local commits small.
- Write the test before the implementation. Run `tools/run_tests.sh` after every
  step; use the wrapper, never `test_runner.gd` directly. A runtime error or a test
  with no assertions is a failure.
- Before committing, run both `tools/run_tests.sh --all` and
  `tools/run_tests.sh --procedural --all`. Report measured counts and durations;
  old counts in documentation are not a new measurement.
- Never turn a failure into `DEBT` to get green. New `DEBT` or `OFF` entries need a
  written reason. Preserve switched-off layers and their tests; consult the current
  testing-switch list in `CLAUDE.md`.
- Positions belong in `content/places.json` as anchors, never coordinates in `.gd`.
  Tests use `TestCase` world helpers such as `at_a_stall()`,
  `in_town(&"harrowgate")`, `alone_on_the_road()`, `in_the_wood()` and `beside_npc()`.
  Scale walking time budgets with `_at_pace()` for both worlds.
- Game strings are French first, English second; update both languages in the same
  commit. Documents are English. Comments explain why; date decisions.
- Record each decision in `docs/SPECS.md` §20 with its date, rejected alternatives
  and reason. Update `docs/V3.md` when what the game is changes, and `CLAUDE.md` when
  how we work changes. Keep Codex-specific ownership and onboarding here.

## Git and handoff

Every git command that writes must use `GIT_CONFIG_GLOBAL=.git/overnight-gitconfig`.
Run from the repository root so that path resolves correctly. Never edit or inherit
Yannick's shared `~/.gitconfig` for writes; use the same override for reads if needed.

Write commit messages to a file and pass it with `-F`. End every message with a
`Co-Authored-By:` line naming Codex, for example:

```text
Co-Authored-By: Codex <noreply@openai.com>
```

Never chain a destructive command after a command that might fail. Never stage
`project.godot` changes caused by the editor reordering it. Yannick pushes and merges;
Codex never pushes.

Finish each task with five lines: what changed, what was measured (counts, seconds,
tiles as applicable), and what remains. Name any ownership boundary that blocked work.
