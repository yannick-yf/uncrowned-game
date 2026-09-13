# Contributing to Uncrowned

Two people work on this repository. These rules exist so that neither of us has to
read the other's mind, and so `main` is always something you can clone and play.

---

## The three rules

1. **Nobody commits to `main`.** Every change arrives through a pull request.
2. **`main` is always green and always playable.** If it is not, fixing it comes
   before anything else.
3. **One pull request does one thing.** A PR that changes the spec *and* the map
   *and* a bug cannot be reviewed; it can only be approved on trust.

---

## Getting set up

```bash
git clone git@github.com:yannick-yf/uncrowned-game.git
cd uncrowned-game

godot --headless --path . --import      # once after cloning
tools/run_tests.sh                      # fast suite, ~5 s
tools/run_tests.sh --all                # everything, ~18 s — before every push
godot --path . &                        # play it
```

Godot **4.7.2**. The version matters: the project file pins it and CI installs
exactly that.

`tools/shot.sh out.png [title|creation|play|pause|journal|map] [x,y]` takes one
frame without playing. Use it. `--headless` never calls `_draw()`, so **the suite
cannot see the screen** — every visual bug this project has shipped was invisible
to the tests and obvious in a picture.

---

## Branches

```
feat/<short-name>     new behaviour
fix/<short-name>      something was wrong
docs/<short-name>     SPECS.md, CLAUDE.md, and friends
chore/<short-name>    tooling, CI, dependencies
art/<short-name>      sprites, palette, tilesets
```

Branch off `main`, keep it short-lived, delete it after merge (GitHub does this
automatically).

---

## Pull requests

- Fill in the template. It is four lines and it is what makes review possible.
- **One approval from the other person** before merge.
- **Squash merge only.** One branch becomes one commit on `main`, so the history
  reads as a list of changes rather than a list of saves.
- CI must be green. It runs `tools/run_tests.sh --all` on Linux.
- If a PR sits for more than a day, it is too big. Split it.

### Reviewing

You are not checking whether it works — CI does that. You are checking:

- Does it match what `SPECS.md` says, and if it changes that, does the PR say so?
- Does it break an invariant? (`CLAUDE.md` has all twelve.)
- Will someone understand this in three months?

"I would have done it differently" is not a reason to block. "This contradicts
§8" is.

---

## Working with Claude Code

- **Always on a branch, never on `main`.** Start the session with the branch
  already checked out.
- Point it at `CLAUDE.md` and the relevant section of `SPECS.md` before asking for
  code. It is a large document; naming the section is most of the prompt.
- A session that changes documents and code at once produces a spec that describes
  whatever was easiest to build. Keep them in separate PRs.
- Read the diff before opening the PR. Claude Code is fast and confident, and both
  of those are reasons to look.

---

## The invariants, in short

The full list is in `CLAUDE.md` and it is not negotiable. The four that get broken
most often:

- **`view/` never writes to `core/`.** Input becomes an event; the simulation
  advances only through `Sim.advance()`.
- **No progression check gates an action.** No `if quest_done` in front of a door.
- **No unseeded randomness.** `sim.rng`, never global `randf()`.
- **Every fact has at least two sources.** It is what makes killing an NPC
  survivable.

---

## Language

- **Documents, code comments, commit messages, PRs, issues: English.**
- **Game content: French first, then English.** `content/text.fr.json` is written
  first and `content/text.en.json` is the translation. A test asserts every key
  exists in both.

---

## Assets

The asset pack is CC0 and the palette is locked to 340 colours, enforced by the
validator (invariant 10). Off-palette colour or an off-grid tile source fails the
suite. Before adding art from anywhere new, raise it as an issue — the licence
matters as much as the look, because this is intended to ship on Steam.
