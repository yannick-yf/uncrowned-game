<!-- Keep this short. A PR nobody can read in three minutes does not get reviewed. -->

## What this changes

<!-- One or two sentences. What is different after this is merged. -->

## Why

<!-- The decision behind it. If it comes from SPECS.md or V2_INTENT.md, name the section. -->

## How it was checked

- [ ] `tools/run_tests.sh --all` is green locally
- [ ] I looked at it — `tools/shot.sh` or played it (the suite cannot see the screen)
- [ ] New strings exist in **both** `content/text.fr.json` and `content/text.en.json`

## Invariants

<!-- Tick only the ones this PR could plausibly have touched. Delete the rest. -->

- [ ] `view/` does not write to `core/`
- [ ] No progression flag gates an action
- [ ] No unseeded randomness — `sim.rng`, never global `randf()`
- [ ] Every new fact has at least two sources

## Anything you want a second opinion on

<!-- Optional. The one thing you are least sure about. -->
