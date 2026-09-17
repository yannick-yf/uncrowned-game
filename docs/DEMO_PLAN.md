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

## What landed on 2026-09-17, and what is left of his map

**His delivery is in `main`** (PR #9, squash-merged as `0f1f49b`): the v4 ironworks
layout, the sawmill village and the royal mountain city, together with the ingestion
that makes the first of them playable. `main` is green — the bake is deterministic at
93,218 bytes, `--check` is clean, and both suites pass.

| His settlement | In the window | In the simulation |
|---|---|---|
| **Ironworks (Cinderworks)** | his meshes | **ingested** — 27 buildings, 43 props, read by his building ids; the six furnaces in their ordered grid; zone (55 × 52) centred (312,213) |
| **Sawmill village** | **drawn** — his map plate carries `scierie.tscn` | **not ingested** — `village_scierie` is still ignored by the brief; the HUD calls it *les terres sauvages* and his walls stop nobody |
| **Royal city and castle** | **drawn** — his map plate carries `ville_royale.tscn` | **not ingested** — Cairnwell still wears our scaffold kit *on top of* his city |

He has already done his half of the contract: `geographie-v1.json` now names both with
`built_scene`, `built_bounds_xz` and `built_buildings`, and the buildings themselves
are in `sawmill-town.json` (15) and `royal-city.json` (34), in the same shape as
`ironworks-town.json`. **Reading them is one session apiece** — W1 and W2 below.

**One branch note, so it does not bite twice.** PR #9 was squash-merged, so
`chore/ingest-recent-map-changes` has content identical to `main` but an unrelated
history: that is the "conflict" GitHub reports, and there is nothing in the branch
worth rescuing. Close its pull request and delete it. Work continues on
`chore/ingest-sawmill-and-royal-city`, branched from `main`.

**And a recurring hygiene note.** Opening his Godot project re-imports his textures
and dirties tracked `.import` files — it has happened three times now. After looking
at his workshop, run `git checkout -- prototypes/`.

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

**W — his map into the simulation.** W0 is delivered; W1 and W2 remain, one settlement
each. Not on the demo's critical path, because the demo happens at Brindle and the
ironworks, and both are ingested.

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

### The next six sessions

**Revised 2026-09-17,** now that his delivery is in `main` and the branch tangle is
behind us. W0 is delivered. Nothing below waits on anybody else.

| # | Item | Whose hands | Est. | Depends on |
|---|---|---|---|---|
| 1 | **A1** — the quest's spine, on paper | Yannick + Claude | 1–2 h | — |
| 2 | **W1** — the sawmill enters the simulation | Claude | 2–3 h | — |
| 3 | **W2** — the royal city enters the simulation | Claude | 3–4 h | — |
| 4 | **A2** — an anchor can name one of his buildings | Claude | 2 h | — |
| 5 | **A3** — the three speakers stand where we meet them | Yannick chooses, Claude places | 1–2 h | A1, A2 |
| 6 | **A4** — one conversation gives one actionable fact | Claude, Yannick reviews the French | 2–3 h | A3 |

Then **A5, the first moment the demo exists**: the player walks in, learns something,
goes somewhere, does something, and the furnaces go out.

**A1 is first and it is paper.** It needs nothing from the map, and every implementation
item after it is a bet until it is answered. Its four questions are prepared below.

**W1 and W2 can slide.** They are not on the demo's critical path — the demo happens at
Brindle and the ironworks, both ingested. They are here early because his art is worth
more in the game than in his workshop, and because W2 is what finally replaces our
scaffold kit standing on top of his capital. If the demo presses, they move.

**B1 — what a fight is, on paper — should be scheduled the moment A1 is done**, because
it is what lets his brother start the prototype combat figures. It is the only work that
can genuinely run in parallel, since it is in his hands, not ours.

## The items

Specified in full down to A5. Beyond that they are named with an estimate and are
specified when we reach them — a card written three weeks early is a card written
before we know what we learned.

### W0 — The game plays his current factory — **delivered 2026-09-17**

His v4 ironworks is ingested and `main` carries it. What it cost, recorded because the
next delivery will cost the same kind of thing: the factory itself landed for nothing —
the town is read by his building ids, so no content named a tile that moved — and three
things broke that were ours, not his. `alone_on_the_road` sampled 34 thinned waypoints
and 23 of them fell inside his new royal city's 100 × 90 zone; the river-barrier
criterion probed east-west only, and his royal moat is crossed north-south; and the bake
assumed that once he delivers any crossing, every wet road tile is one of his bridges —
his royal feeder channel crossed the King's Road twenty-five tiles from the nearest, and
the road to the capital was cut in silence. All three fixed, both suites green.

### W1 — The sawmill village enters the simulation

Owner: Claude. Estimate: 2–3 h. Depends on: —.

**Player-visible result:** standing in his sawmill, the HUD names the place instead of
saying *les terres sauvages*, and his fifteen buildings stop you the way his ironworks
does.

**What it involves:** read `planning/sawmill-town.json` the way `ironworks-town.json` is
read — his building ids, their scenes, their collision — and stop ignoring
`village_scierie` in `content/bake_brief.json`. The site is his, so the settlement kit
must not stamp over it. Expect the same class of fallout as W0: something of ours that
assumed the old map.

**Exact check:** the bake reports the sawmill's buildings instead of ignoring the site;
`test_anchors` names nothing; both full suites green; `--check` clean; a frame at the
sawmill showing the HUD naming it, and a walk into one of his walls.

### W2 — The royal city and castle enter the simulation

Owner: Claude. Estimate: 3–4 h. Depends on: —.

**Player-visible result:** Cairnwell stops being our placeholder town standing on top of
his city. His thirty-four buildings, his curtain wall and his gate are what the
simulation sees, and the climb to the castle is walkable.

**What it involves:** `planning/royal-city.json`, his `built_bounds_xz`, and dropping the
scaffold kit for `cairnwell`. This one is larger than W1 because the castle is not a
settlement: there is a terrace at 94 m, a switchback climb, a curtain wall with a gate,
and the simulation's own castle and rampart terrain already claim that ground.
Blackcairn's anchors and the king's escort stand there.

**Exact check:** the bake stands his city instead of the kit; every anchor in Cairnwell
and Blackcairn still resolves, by name; a walker can reach the castle courtyard; both
suites green; frames of the city and the climb.

**If this one grows past a session, split it** — the lower town first, the castle after.

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
