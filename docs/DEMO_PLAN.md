# The demo plan — what we build, in what order

Date: 2026-09-16. Author: Claude, for Yannick. Supersedes the *ordering* of
[DEMO_WORK_ITEMS.md](DEMO_WORK_ITEMS.md), which remains the wider inventory and
the brother's B-item list. Evidence is in
[the walkthrough](DEMO_WALKTHROUGH.md) and
[the existing-behaviour review](DEMO_EXISTING_BEHAVIOUR.md).

**Claude Code is the only agent on this work from 2026-09-16** (Yannick). The lane
reservations in `AGENTS.md` are dormant, not deleted; nothing in this plan is
assigned to Codex.

## How we work, so that this stops being vibe coding

Five rules. They are the answer to "small work items", and they are the plan's
only process.

1. **One item in flight.** Never two.
2. **A design decision is its own item, on paper, before the code that depends on
   it.** Most of what Yannick calls vibe coding is code written while the design
   was still open. A paper item has no code and is not a lesser item.
3. **Every item ends on one sentence a player could say**, plus the exact check
   that proves it. If the sentence needs two sessions, the item is two items.
4. **Every item that touches an existing system names its verdict** — keep, adapt,
   replace — and says what it leaves alone. Nothing is deleted because it looks
   unloved.
5. **A frame or a played run, not a green suite.** `--headless` never draws.

---

## The state that reorders everything: his current factory is not in the game

Checked 2026-09-16. `content/region.json` is **up to date with the workshop data on
this branch** (`bake_region.gd -- --check` passes) — but that data is one delivery
behind him.

`origin/art/ameliorations-graphiques` carries **`4f4d13e`, "art: order ironworks
factory layout", slosinio, 2026-09-15**, which is not in `main` and not here. It is
**version 4** of the ironworks town; the game plays version 3. Content difference,
six files: `ironworks-town.json`, `acierie.tscn`, `relief_godot.tscn`,
`ironworks_ground_mask.png`, `Ironworks-town.md`, `build_ironworks_town.py`.

What moved, in the tiles the simulation uses:

| Building | Tile today | Tile in his v4 |
|---|---|---|
| `DortoirNord` | (294, 200) | **(311, 203)** — right across the site |
| `MaisonContremaitre` | (310, 205) | **(311, 211)** |
| `DortoirPlace` | (308, 206) | **(304, 211)** |
| `CuisineCommune` | (300, 218) | **(304, 218)** |
| `BureauPesee`, `HalleMartelage`, `ForgeFinition` | unchanged | unchanged |
| The six furnaces | scattered | **an ordered 3 × 2 grid**, rows 202 and 209, columns 319 / 323 / 327 |

16 of 27 buildings moved, up to 35 m; four garden-fence props removed; the town
bounds widened from 100 m to 110 m.

**Consequence for the plan: no placement work happens before this is ingested.**
Choosing meeting spots against version 3 would choose spots that have already
moved.

**How it reaches us (Yannick, 2026-09-16):** his brother opens a pull request for
`art/ameliorations-graphiques`, because the git history is kept clean and a branch's
author opens its own PR. So **W0 is blocked on somebody else**, and the plan is
ordered so that nothing else waits with it.

**Unrelated, and worth clearing:** the local change to
`prototypes/brindle_3d/assets/landscape/ironworks_ground_mask.png.import` is not
work. It is Godot re-importing his texture with VRAM compression because his
project was opened on this machine. It is a change inside his project, which we
never edit. Recommended: revert it before it travels.

---

## Platform: Windows only

**Decided 2026-09-16 by Yannick: the public demo is Windows only. macOS is dropped
for now.** He asked first whether macOS could join if the cost were low, and
dropped it on seeing the two real costs — Gatekeeper blocking an unsigned `.app`
(the player must right-click → Open, or the archive needs an Apple Developer
account at 99 €/year to notarize), and every release check running twice.

This is a decision about the demo, not about the game: macOS costs almost nothing
to *build* once the templates are installed (one ~1 GB download covers every
platform, then one preset and one command per platform). Reopen it for the full
release, or the day a macOS player has to see it, and the answer may be different.

**Measured state, unchanged by the decision:** there is no `export_presets.cfg` in
the repository and no Godot export templates installed on this machine. Windows is
not set up today, and **the Windows test machine is still not identified** — which
is now the single platform risk with no fallback, since the build can no longer be
tried on the machine it is developed on. Identify that host early (C4).

---

## Should we delete the simulation and start the back end again?

Yannick's question of 2026-09-15, and my answer now that it has been measured.

**No — but not because the existing work has earned its place.** The reason is
narrower than "keep the good code". It is this: in the demo's hour the player will
meet **very little** of the simulation. Measured — six dialogue options of
ninety-three read a trait; three of the six traits are read by nothing at all; of
the twelve kingdom quantities the demo needs two. Deleting the rest costs sessions
this month and buys the demo nothing, because the demo never walks past it.

So the rule is not *keep* and not *delete*. It is **on the path, or not on the
path**:

- **On the path** — every system the demo touches gets an explicit verdict and, if
  it resists the design, gets replaced without sentiment. The
  [behaviour review](DEMO_EXISTING_BEHAVIOUR.md) lists them; the largest is
  *resolution by dialogue option*, which the demo replaces with an act at a place.
- **Off the path** — left exactly as it is, neither defended nor deleted. Its fate
  is decided after the demo, by play, when the design is settled. The rumour
  system, hardship, rank, the endings, the other seven places, the twenty-two other
  characters: not touched this month.

**One warning that the "just leave it alone" answer usually misses.** Off-path
systems can still reach *into* the demo. *« E, éteindre le four »* stands ungated
at every furnace and stops the clearing on its own: a player can finish the demo's
argument in ten seconds without meeting anybody. So every system that reaches the
demo corridor needs a decision even if it is "off the path" — that is item A1's
fourth question.

**What this plan actually changes in the simulation**, so it is not a surprise:

| Change | Verdict |
|---|---|
| The dispute resolves by an act at a place, not by choosing a dialogue line | **Replace** |
| The workers' outcome and "the works goes free" become one thing | **Adapt** — today they are two chains that contradict each other |
| Lost wages get a representation a person can perceive | **Add** |
| The ungated furnace sabotage during the demo | **Decide** — gate, remove from the demo, or let the quest own it |
| Creation reaches the player, and the demo honours the traits it offers | **Adapt** |
| Combat | **New** — there is no combat rule and no combat system, only the king's contact damage |
| Everything else | **Untouched** |

---

## The order, and why it is this order

Three tracks. They are sequenced, not parallel, except where the work is in his
brother's hands.

**W — unblock.** One item. Everything positional depends on it, and it is blocked
on his brother's PR — so it is first *in the A-track's dependency order*, not first
in the calendar.

**A — the quest.** The demo's argument: a choice, an act, and a world that changes
where you can see it. Most of it exists in some form, which is why it is second —
it is the cheapest route to a thing that plays.

**B — combat.** From zero, and the only track whose art his brother must make. Its
*design* item (B1) runs early precisely so his brother can start prototype assets
while track A is still running. That is the only real parallelism available now.

**C — the shell.** Creation on the public path, the exports, the platform checks.
Last, because a shell around nothing proves nothing — except C3, which is pulled
early because an export that has never been built is where week-four surprises
come from.

### The first six sessions

**Revised 2026-09-16.** W0 is blocked: his art branch reaches us through a pull
request his brother opens, and Yannick keeps the git history clean rather than
merging it for him. So W0 waits on someone else, and the order changes to put in
front of it the three items that need nothing from anybody — **and A2 moves ahead
of W0 on its own merits**, because an anchor that names a building by its stable id
is exactly what makes a layout change safe. Doing it first means W0 re-bakes under
content that survives the move instead of following a re-ordered list.

| # | Item | Whose hands | Est. | Blocked by |
|---|---|---|---|---|
| 1 | **A1** — the quest's spine, on paper | Yannick + Claude | 1–2 h | — |
| 2 | **A2** — an anchor can name one of his buildings | Claude | 2 h | — |
| 3 | **B1** — what a fight is here, on paper | Yannick + Claude | 1 h | — · **unblocks his brother's prototype figures** |
| 4 | **C3** — a repeatable Windows export | Claude | 2 h | — |
| 5 | **W0** — ingest his v4 factory | Claude | 2–3 h | **his brother's PR** |
| 6 | **A3** — the three speakers stand where we meet them | Yannick chooses, Claude places | 1–2 h | W0 |

Then A4 and **A5, which is the first moment the demo exists**: the player walks in,
learns something, goes somewhere, does something, and the furnaces go out.

Nothing in this list waits on the PR except W0 and what follows it. If the PR lands
early, W0 slots in wherever it arrives — it does not have to wait for its row.

---

## The items

Specified in full down to A5. Beyond that they are named with an estimate and are
specified when we reach them — a card written three weeks early is a card written
before we know what we learned.

### W0 — The game plays his current factory

Owner: Claude. Estimate: 2–3 h. **Blocked on his brother opening a pull request**
for `art/ameliorations-graphiques` (Yannick, 2026-09-16: the git history is kept
clean, so the branch's author opens its PR). Nothing else in the plan waits on it.

**Player-visible result:** the works looks like the one his brother drew last —
the furnaces in an ordered grid, the dormitories where he put them.

**What it involves:** `tools/vendor_workshop.sh`, re-bake, then fix what moved.
Expect the existing Cinderworks anchors to need attention: Halgrave's
`feature: kiln` anchor follows whichever furnace is first in the new list, and the
works' zone grows with the widened bounds.

**Exact check:** `bake_region.gd -- --check` clean; `tools/run_tests.sh --all` and
`--procedural --all` green; `test_anchors` names nothing; a frame at the production
viewpoint showing the ordered furnaces, and one at the quarter. Any new DEBT line
gets a written reason, and no failure becomes a debt.

### A1 — The quest's spine, decided on paper

Owner: Yannick, with Claude. Estimate: 1–2 h. Depends on: nothing — **it no longer
waits for W0**. Its four questions are about rules, and the two landmarks it can
name (the ledger's tile, the furnaces) exist in both versions of his town. **No code.**

**Result:** one written page answering four questions, and nothing else:

1. **What is the workers' victory, in the rules' own terms?** Today "production
   stops" is what *freeing* the place does (take the ledger, read it aloud there),
   while the deed named `i_turned_the_workers` only moves numbers and leaves the
   furnaces lit. These must become one outcome. Which one absorbs the other?
2. **What is the deciding act, physically?** Yannick asked for something the player
   goes and does. Candidates that need no new art: the ledger already lies at a
   tile in the works; a furnace already has an act on it. What does the player
   walk to, and press?
3. **What is "they lose their wages", in the twelve quantities?** Today the nearest
   thing is hardship at the Cinderworks. Either that is the answer and someone says
   so in words, or the demo needs one more number.
4. **What happens to *« E, éteindre le four »* during the demo?** It is ungated and
   it ends the quest's own argument by itself.

**Exact check:** both paths walked on paper — each has an act beyond speaking, a
cost that lands on somebody named, and a result visible from the game camera. Then
a SPECS §20 entry **prepared, not applied**.

#### The options, prepared 2026-09-16

Prepared so the session is spent deciding rather than drafting. **The
recommendations are Claude's and none of this is decided.** One fact that shapes
all four answers, found while preparing them:

> **An act at a landmark is already a system, and adding one is a row in a table.**
> `SiteRules.deed_at(kind)` maps a landmark kind to a deed; `ActSystem` handles the
> reach (2.4 tiles to the footprint), the prompt, the watch that stands over a
> guarded post, and the rule that a spent site stays spent. Four levers exist today:
> the kiln, the granary, the counting house, the muster rolls. **So "the player goes
> and does something" is cheap.** What does not exist is a *conditional* act — every
> lever today is offered to anyone who walks up.

**Q1 — What is the workers' victory, in the rules' own terms?**

| | Option | Cost | Consequence |
|---|---|---|---|
| **1** | The workers' lever **frees the works**: the walkout is what puts the furnaces out. The ledger read aloud stays as a second route to the same outcome | Small: `i_turned_the_workers` gains the freeing effect the ledger already has | Two routes to one outcome, which is what invariant 5 asks for. **Recommended** |
| 2 | Only the ledger frees the works; drop `i_turned_the_workers` from the demo | Smallest | The "workers' victory" is then really *you published a document* — the exact narrowing you objected to |
| 3 | A third outcome: the workers run the works themselves | Large | You already ruled this out on 2026-09-15 |

**Q2 — What is the deciding act, physically?**

| | Option | Cost | Consequence |
|---|---|---|---|
| **A** | An existing building of his becomes the landmark — the weigh office or the hammering hall — and the act is *stop the shift* / *call the shift back* | One row in `SiteRules`, one deed, two label lines FR+EN. **No new art** | Works today, in both versions of his town. **Recommended for the demo** |
| B | A shift bell, as a new prop | A row, plus his brother's prop (old B03) | The most legible of the three, but it adds an art dependency to the demo's critical path |
| C | The furnaces themselves: the player banks the fires with the workers | A row | Collides head-on with the sabotage already on the kilns — see Q4 |

Note either way: the act must be offered **only to a player who has the fact**,
which is the conditional act that does not exist yet. That is legal under invariant
4 — knowledge is a fact, not a progression flag — and it is the one real piece of
new machinery in A5.

**Q3 — What is "they lose their wages"?**

| | Option | Cost | Consequence |
|---|---|---|---|
| **1** | Hardship at the Cinderworks is the representation, and a person says it in words | None: `i_turned_the_workers` already puts `cinderworks +12` hardship | The number exists; what is missing is somebody saying it. Becomes A7's job. **Recommended** |
| 2 | Add a thirteenth quantity for wages | A spec change touching the twelve | Heavy for a demo, and the twelve were closed deliberately |

**Q4 — What happens to *« E, éteindre le four »* during the demo?**

| | Option | Cost | Consequence |
|---|---|---|---|
| **1** | Gate it on **knowing what the works costs** — the same fact the quest turns on | One condition in the act path, shared with Q2's conditional act | You cannot wreck what you have not understood. Legal under invariant 4, and it makes the world better rather than smaller. **Recommended** |
| 2 | Remove the kiln row from `SiteRules` for the demo | One line | Removes a lever the full game wants, and the removal has to be remembered |
| 3 | Leave it ungated | None | A stranger finds it before they find a person, and the demo's argument is over in ten seconds |

### A2 — An anchor can name one of his buildings by its stable id

Owner: Claude. Estimate: 2 h. Depends on: W0.

**Player-visible result:** none directly. It is here because without it every
placement is a bet on the order of a generated list — and W0 has just proved that
list changes when his brother works.

**Existing behaviour:** `Region.resolve` matches a `feature` by **kind** and returns
the first prop of that kind in the place. Halgrave stands at `FourneauUn` only
because it is first. The bake already carries `source_id` on all 74 delivered props.

**Change:** a third anchor form, `{"place": …, "prop": "BureauPesee", "offset": …}`,
resolved against `source_id`.

**Exact check:** a test resolves a `prop:` anchor to his building's tile, and
`unresolved_anchors()` names it **by name** when the id is gone. Both suites green.

### A3 — The three speakers stand where the player meets them

Owner: Yannick chooses the spots, Claude places them. Estimate: 1–2 h. Depends on:
A1, A2, and the brother's view of the spots.

**Player-visible result:** walking into the works, the player finds three different
people in three different places — management where management would be, the
workers where workers would be. Today the quarter is empty and all three resolve
into the production band within ten tiles of each other.

**Exact check:** each anchor resolves within one tile of its named building;
`test_anchors` green; frames at the quarter and production viewpoints showing them.

### A4 — One conversation gives one actionable fact

Owner: Claude, Yannick reviews the French. Estimate: 2–3 h. Depends on: A3.

**Player-visible result:** the player talks to one person and comes away with the
number the dispute turns on, and knows what it is for.

**Existing behaviour to reuse, not rebuild:** `cinderworks:death_toll` already has
**three** sources — Halgrave gives it freely, Sena counts it differently, Ivo says
the register is *« honnête et faux »*. Invariant 6's redundancy already holds.
What this item does is make the demo's one conversation land: reviewed French,
a line that stands on its own, and the fact legible as something to act on.

**Exact check:** approach management first in one run and the workers first in
another; get the fact both ways. Remove one source in a test and the route
survives. Yannick reads the lines aloud without the role labels.

### A5 — The act that stops the works

Owner: Claude. Estimate: 3 h. Depends on: A1 (it implements A1's answer), A4.

**Player-visible result: the demo exists.** The player goes to the place A1 named,
does the thing A1 named, and the furnaces go out — embers gone, plumes gone, the
entrance line changed. That half already renders; what this builds is the quest
causing it.

**Exact check:** from a fresh run, perform the act and walk to the production
viewpoint. Compare frames before and after. Repeating the act does not double its
effect. Replay the log and land on the same state. A debug switch producing the
same picture is **not** this check.

### Then, named only

| Item | What it is | Est. |
|---|---|---|
| **A6** | The management side: the agreement, production continues, the danger stays | 2–3 h |
| **A7** | The two responses and the journal line: safety, wages, the crown's steel | 2 h |
| **A8** | Both outcomes survive rest, save, reload and replay | 2 h |
| **B1** | *On paper:* what a fight is here — what decides it, what the player presses, what defeat costs. **Do this early**, so his brother can start prototype figures | 1 h |
| **B2** | The fight as simulation state: two combatants, one attack, damage, a result, world time paused. Headless and deterministic | 3–4 h |
| **B3** | The first screen candidate, on plain blocks or his prototype assets | 3 h |
| **B4** | Play it, try one contrasting approach, choose by playing | 1–2 h |
| **B5** | Enter a fight from the world and return its result, defeat wired to the checkpoint | 3 h |
| **B6** | One practice encounter that teaches the controls, in French | 2 h |
| **C1** | Creation on the public path; the quick launch stays as the development path | 2 h |
| **C2** | *On paper:* what a trait buys in the demo's hour — or show fewer | 1 h |
| **C4** | Play the exported build on a real Windows machine — **the test host is still not identified, and there is no longer a second platform to fall back on** | 2 h |
| **C5** | A stranger plays it without coaching; every blocker becomes a small item | 2 h |

Roughly 45–55 hours of Yannick's sessions, inside four 24-hour weeks — before his
brother's art, the playtest fixes, and the two platform passes. It fits, and it
fits without slack. **The first thing to cut if it slips is B4's second candidate
and any extra attack**, not the visible consequence and not the Windows check.

### What his brother can start now, without waiting for us

From the walkthrough's gap register, and independent of track A:

- **Prototype combat figures** — a player, one opponent, a floor. Plain blocks are
  acceptable. Needed by B3; the real poses wait for B4's choice.
- **GAP-01, the fairy** — the demo's first character is currently a light on the
  player with no figure. Decide with him whether that *is* her, or she needs one.
- **GAP-02, the clearing** — it does not read as a clearing; the ring of thicket is
  the standing DEBT.
- **GAP-06** — our plain placeholder blocks stand in the two opening frames.
- **The works' entrance sign** as an object, since today the status is a HUD line.

---

## What this plan does not claim

It does not establish that the full three-month game fits its calendar; that needs
its own pass and has not had one. It records no approval from slosinio. It assumes
no estimate here has been measured — the first two items are the calibration, and
the rest get re-estimated after them.
