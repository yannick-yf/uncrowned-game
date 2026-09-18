# The demo, as tasks

Date: 2026-09-18. The specs turned into work. **Nothing is started.**

Reads from: [the simulation model](SIMULATION_MODEL.md) · [the Cinderworks
quest](QUEST_CINDERWORKS.md) · [what we keep](SIMULATION_KEEP_OR_DROP.md) ·
[the plan's order and rules](DEMO_PLAN.md).

This list supersedes the Y/B numbering of [DEMO_WORK_ITEMS.md](DEMO_WORK_ITEMS.md)
for everything it covers. That document keeps its capacity table and its brother's
items.

**Done before the list started (2026-09-18):** `CLAUDE.md`'s reading order, precedence,
testing switches and current phase were rewritten for this design, and the five
superseded planning documents each carry a banner saying what of them still holds. A
session that reads `CLAUDE.md` first — which every session does — now lands on the new
model instead of the old one.

## How to run this list

1. **One task at a time.** Never two.
2. **Both suites green before the next one starts** — `--all` and
   `--procedural --all`. A task that leaves red is not finished.
3. **The check in the task is the definition of done.** Where it says a frame, a frame
   is taken and looked at, because `--headless` never draws.
4. **Build beside the old model. Delete nothing until the demo runs on the new one.**
   The clean-up tasks are last on purpose, except **C1**, which is safe today.
5. A task that turns out to be two tasks **is split before it is coded**, not after.

Estimates are first-pass owner time and will be wrong until three of them are
measured. Names of new files are proposals; the shape is what matters.

---

## M — the model

### M1 · A place has two values

Foundation. Enables everything below. Est. 2 h. Depends on: —.

**Delivered 2026-09-18.** A store holding **allégeance** and **richesse** for the
**five** places that carry them — the Cinderworks at its settled 6 and 4, the other
four proposed in the file and changed in one place. Brindle is absent, and asking
about it returns −1 rather than 0, because a ruin has no standing to report and that
is not the same as having a low one. Cairnwell and Blackcairn are absent too: they are
the kingdom.

`content/towns.json`, `core/rules/town_rules.gd` (floor, ceiling, the threshold at 5,
the ±3, the four appearances), `core/town_state.gd`, `core/systems/town_system.gd` —
the only thing that writes a number, and only from an event, so a replay rebuilds the
same kingdom.

**Checked:** 7 new tests. 44 suites, 438 tests, 0 failed on both worlds.

### M2 · Richesse lights or cools the furnaces

**Delivered 2026-09-18.** The window reads richesse and it decides **how many of his
six furnaces burn** — proportional rather than all-or-nothing, which was the task's
first wording and would have given a working works and a dead one and nothing between.
Of six: **none at 1, two at 4, four at 7, all six at 10.** The works spends the whole
quest in between, and that is how the player knows there is an argument before anybody
speaks.

His delivered heat is now grouped per furnace rather than flattened into one list, and
numbered by the same pass that builds our embers so the two can never disagree about
which furnace is the third one. A campfire is never touched: somebody still has to eat
in a town that has stopped. `view/world3d.gd`, the frame dictionary in `view/main.gd`,
and `TownRules.lit_of`.

**Checked:** three frames at **(320,207)** — richesse 1, 4 and 7 — and they read as
dead, going badly, and working. **Honestly: cold-versus-lit is unmistakable; 4 against
7 is visible but quiet.** What will make *going badly* loud is P3, the props of daily
life going away. 44 suites, 438 tests, 0 failed on both worlds.

`UNCROWNED_TOWN=cinderworks:9/7` was added to take those frames, gated on debug and
listed in `CLAUDE.md`: an outcome has to be lookable at before there is a quest.

### M3 · Allégeance shows on a place

Est. 2–3 h. Depends on: M1.

The second axis becomes visible: **the colour cast, warm where the king is supported
and cold where he is not**, plus the king's guard standing or absent. The banner
itself waits for his brother.

**Check:** four frames at the quarter viewpoint **(299,206)** — the four combinations
of the two thresholds. A stranger shown them in a random order can sort them.

### M4 · The kingdom's two values

Est. 2 h. Depends on: M1.

**Force** = the average of the steel received and the places' allégeance. **Trésor** =
the sum of the goods sent, normalised to 0–10. Places send; the kingdom holds.

**Check:** a test: drop the Cinderworks' richesse and the kingdom's force falls;
every place turning against the king lowers it too, with no steel having moved.

### M5 · What the kingdom sends back, and how slowly

Est. 2–3 h. Depends on: M4.

Food and weapons, **and nothing else**. A place badly fed loses richesse, **over
days**, on a slow tick — never in the same instant as the cause.

**Check:** a test at tick granularity: the cause lands on day 1 and the effect is
still arriving on day 3. Played with `T`, a day at a time, the change is watchable.

### M6 · One table for the arithmetic

Est. 1 h. Depends on: M1, M4, M5.

Every number in the model — the ±3, the thresholds, the floors and ceilings, the
weights inside force, the normalisation of trésor — in **one file**, so balancing is
one line and never a hunt.

**Check:** a test asserts no magic number lives outside it.

---

## P — the people and their routines

### P1 · Routine people, who go somewhere

Est. 3 h. Depends on: M1.

A family of unnamed people — the existing *strangers* shape — who **have a destination
that depends on the place's state.** The works runs: they walk to the mine and back.
The works has stopped: they are at the riverside, in the wood, **or gone**.

**Check:** two frames of the same street, works running and works stopped. In the
first, people on the road to the mine; in the second, the street empty. And a walk,
because a frame does not show that they move.

### P2 · Their lines, by state

Est. 3 h. Depends on: P1. **Yannick writes, French first.**

Ten lines per state, four states, **forty for the Cinderworks**, written for the
Cinderworks and shared with nowhere else. English in the same change.

**Check:** talk to four of them in each state. Nothing repeats twice in a row, and
none of the four states' lines would make sense in another state.

### P3 · Abandonment is absence

Est. 2 h. Depends on: M1, P1.

Below the richesse threshold the props of daily life stop being placed: no carts, no
woodpiles, no washing, no fires. **The chimneys stay, cold.** No building gets a
second version.

**Check:** the two frames of M2 again, now with the yard emptied. Collision agrees
with what is drawn.

---

## Q — the quest

### Q1 · The production area is closed

Est. 2–3 h. Depends on: —. **Needs his brother's fence line, or ours from his pieces.**

A fence with one gate between the quarter and the works, and a guard on the gate. The
furnaces are **unreachable**: not gated by a flag, simply behind something.

**Check:** walk from the quarter and fail to reach a furnace. The wall that stops you
is drawn — nothing invisible. A frame of the gate.

### Q2 · Tom and Drissa stand in the quarter

Est. 2 h. Depends on: M1, Q1, and the naming review.

Two key people at agreed spots, each with their position, **and each telling the
player about the other**, so neither is a single point of failure.

**Check:** find both without the debug list; hear about Drissa from Tom and about Tom
from Drissa; a frame of each where they stand.

### Q3 · Choosing a side, and getting in

Est. 3 h. Depends on: Q1, Q2.

The choice is explicit, in conversation. Choosing is what opens the gate — **Tom
brings you through, Drissa vouches for you.**

**Check:** both ways, in two fresh runs. Before choosing, the gate refuses; after, it
does not. The refusal says nothing about a quest.

### Q4 · The act at the furnaces

Est. 2 h. Depends on: Q3.

**Put out the ones still burning, or relight the cold ones** — a row in the landmark
table the game already has, offered only inside. It is one act, in two directions.

**Check:** perform each in its own run. Repeating it does not count twice. The prompt
appears only inside the works.

### Q5 · The outcome moves the two values, once

Est. 2 h. Depends on: Q4, M1.

Tom: 6 → 3 and 4 → 1. Drissa: 6 → 9 and 4 → 7. Applied once, as events, so the log
replays to the same state.

**Check:** both outcomes from a fresh run, then replay each log. No double
application, no drift afterwards.

### Q6 · What the works looks like, and what people say, after

Est. 3 h. Depends on: Q5, M2, M3, P1, P2.

The outcome's signals and routines, and the lines that follow it — including, on
Drissa's path, **that Tom and his people are not there any more, and that those who
remain know it.**

**Check:** the six frames — quarter and production, in each of the three states.
Both brothers can tell which is which with no overlay. Save, reload, and they hold.

---

## F — the fight

### F1 · A fight resolves, with no screen

Est. 3–4 h. Depends on: —.

Two combatants, one attack, damage, a defence, a result — as simulation state,
advanced through `Sim`. **World time pauses for the fight and resumes after.**

**Check:** headless. The same inputs replay to the same health, the same result and
the same world tick; different advance chunk sizes agree.

### F2 · The arena

Est. 3 h. Depends on: F1.

A separate screen, side-on: a short load out of the world, **his traveller against a
different traveller**, a floor, two health bars. Move, face, and strike a still
opponent.

**Check:** played. Strike in range, miss out of range, hold the button and gain
nothing. Damage follows the fight's own cadence, not the frame rate.

### F3 · Into the fight and back out

Est. 3 h. Depends on: F2, Q3.

The quest enters the fight and receives one result. Victory and defeat both return to
the right place, with the right health, and defeat obeys the checkpoint rule.

**Check:** win once and lose once from the same starting point. World time resumes.
Nothing is applied twice.

### F4 · The opponent does something

Est. 3 h. Depends on: F3.

One approach, one attack with a readable wind-up, and one defensive action for the
player. Driven by the fight's state, never by a scene timer.

**Check:** avoid or block the signalled attack, then punish its recovery. Slow the
rendering down and the timings do not change.

### F5 · The fight belongs to the quest

Est. 2 h. Depends on: F4, Q4.

Tom's side: a foreman or the gate's guard. Drissa's side: **Tom**. The fight happens
where the act happens, and its result decides whether the act goes through.

**Check:** both sides played end to end, from the quarter to the changed works.

---

## S — the shell

### S1 · Four traits, a pool of 8

Est. 2 h. Depends on: —.

Force, Intelligence, Agilité, Prestance. Floor 1, cap 5, **pool 8** — which buys two
specialisms and nothing else. The French names and notes rewritten with them.

**Check:** a character made on the screen is one the simulation accepts; 9 points is
refused with a reason; both languages.

### S2 · A fresh run reaches the fairy through creation

Est. 2 h. Depends on: S1.

The public build opens on the title and creation. The quick launch survives as a
development path only.

**Check:** start fresh, allocate, meet the fairy; quit, rest, Continue. Both
languages. A frame of the creation screen.

### S3 · A Windows build, and a machine to run it on

Est. 2–3 h. Depends on: —. **Windows only** — macOS was dropped on 2026-09-16.

A repeatable export, with no editor tooling and no workshop source in the package.
**And the test machine identified**, which is the one platform risk with no fallback.

**Check:** build, extract elsewhere, and it runs without the repository. The Windows
host is named in writing.

### S4 · A stranger plays it

Est. 2 h. Depends on: everything above.

One person who does not know the quest, no coaching, watched.

**Check:** they describe both sides, their own choice, and what changed. Every blocker
becomes a small task.

---

## C — the clean-up, last

**Nothing here starts before the demo runs on the new model**, except C1.

### C1 · Delete the LLM layer — safe today

Est. 1 h. Depends on: —.

`core/context.gd`, `core/rules/prose_rules.gd`, `core/phrasebook.gd`,
`PhrasingSystem`, `view/phraser.gd`, `tools/phrase.py`, and their tests. Inert since
2026-09-12; nothing calls it.

**Check:** both suites green with fewer tests and no `SCRIPT ERROR`. The ruling that
switched it off stays in `CLAUDE.md` as history.

### C2 · Delete the twelve quantities and their organs

Est. 3 h. Depends on: M1–M6, Q5. `WorldTick`'s quantities, `WorldRules`' drift,
hardship, grain, unrest, army, the castle reading.

### C3 · Delete the deeds, the documents, the factions and the old quests

Est. 3 h. Depends on: Q1–Q6. `DeedRules`' 24 acts, `DocumentRules` and the reading of
papers, `Standing` and the ranks, the eight fact-pattern quests. The **mechanisms**
that survive are named in the keep-or-drop review.

### C4 · Delete the old dialogue and the layers behind the switches

Est. 2 h. Depends on: P2, Q6. The 93 options and 21 reactions; the terrain speed table
and the music tables, with their tests.

---

## Order, and what it adds up to

**M1 → M2** first: two sessions to the moment the works *looks* like it is going
badly, with no quest in the game at all. That is the model earning its place before
anything is built on it.

Then **M3–M6** and **P1**, then the quest **Q1–Q6**, then the fight **F1–F5**, then
the shell, then the deletions. **F1 can be pulled forward at any time** — it depends
on nothing and it is the only part of the demo built from zero.

Roughly **60 hours** of sessions, twenty-six tasks. That is more than the 45–55 the
plan estimated before the model was designed, and the difference is the model itself:
six tasks that did not exist when the demo was going to run on the old simulation.

**What is not in this list:** his brother's fence, gate and pollution (Q1, and the
model's §4 signals), and the answer to the quest's one open question — what ties this
dispute to the player's own grievance.
