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

> **Not accepted, 2026-09-18.** Yannick is unsure about the colour cast and wants to
> look at it with his brother, whose the map's light is. It is left in place, working
> and tested, and it is **one commit to undo**. Three ways out when they decide: keep
> it, soften the lean, or drop it and carry allégeance some other way — the king's
> banner and the presence of his guard being the obvious one, and both are things his
> brother can draw.

**Delivered 2026-09-18, in half.** The colour cast is built: standing in a place the
king still holds, the light leans **warm**; in one that has turned, **cold**; in the
wild and anywhere outside the system it is exactly his light and nothing of ours.

**It is a tint over his sun and his sky, never a replacement.** His map plate carries
both, so the window remembers what he chose and multiplies it, and the midpoint of the
two leans is white — his look is the neutral state. The first frame lands on its light
rather than fading into it, as the camera in that file already does; after that it
eases, because a hard flip at a zone's edge reads as a bug rather than as a mood.

**Checked:** four frames at **(299,206)**. **Honestly: they sort into two, not four.**
Warm against cold is unmistakable. The richesse axis makes no difference at this
viewpoint, because no furnace is in frame and nothing else reads richesse yet — that is
**P3**, when the carts and the woodpiles stop being placed. 44 suites, 438 tests, 0
failed on both worlds.

**Deferred, with a reason: the king's guard standing or absent.** Whether the crown's
men are in a place is the *simulation's* answer, not the window's — the window would be
hiding somebody the simulation says is there. It belongs with **P1**, which is where
who is present and what they are doing lives.

### M4 · The kingdom's two values

**Delivered 2026-09-18, and smaller than it was estimated.** **Force** is the average
of the steel it receives and how far its places are with it; **trésor** is what the
places send, on the same 0–10 scale as everything else. What each place sends is in
`content/towns.json` — which place grows food and which makes steel is design, not
arithmetic. Two goods and no more; wood waits for the sawmill, where it will be the
fuel steel is made with rather than a third flow.

**Derived, never stored** — and that is the whole design of it. There is no kingdom
store, no kingdom event and nothing to replay. A number that cannot be written cannot
drift out of step with the towns that make it, which is exactly how the twelve
quantities this replaces went wrong. `core/rules/kingdom_rules.gd`, and nothing else.

**Checked:** stopping the works costs the crown its force; **every place turning
against the king costs him force with not a furnace having moved**, which is the
argument of the whole game in one number; a rich Muster is not a rich crown, because
the camp sends nothing; both numbers reach 0 and 10 and no further. 46 suites, 449
tests, 0 failed on both worlds.

**Nothing of this is visible yet.** It is the hop that turns *the ironworks has
stopped* into *the crown is short of steel*, and somebody has to say that sentence
before a player meets it — that is Q6.

### M5 · What the kingdom sends back, and how slowly

Est. 2–3 h. Depends on: M4.

Food and weapons, **and nothing else**. The drift goes **both ways**: a place badly
fed loses richesse, a place well fed gains it, **over days**, on a slow tick — never in
the same instant as the cause.

**And the kingdom redistributes only what it receives.** It creates nothing, so a
place grows rich on what another place produced. This is what stops everything
drifting to the ceiling, and it is what makes the ironworks' last two furnaces worth
helping the farms for: a quest's ±3 takes the works to 7 of 10, and only the kingdom
can carry it the rest of the way.

**Check:** a test at tick granularity: the cause lands on day 1 and the effect is still
arriving on day 3. A test that the kingdom cannot give out more than it took in.
Played with `T`, a day at a time, the change is watchable.

**Delivered 2026-09-18** (`core/systems/kingdom_system.gd`, 9 tests in
`test/test_redistribution.gd`), and **the first build of it was wrong**: pulling every
place toward the average flattened the whole kingdom to one number within two in-game
days. `TownRules.PULLS_FROM` is the fix — the crown only moves a place across a gap of
three or more, and never further in a day than the player moves one by hand.

*This block went unmarked until 2026-09-19, when the plan was read back and found to be
claiming work that was done. The record is the plan's only job.*

### M6 · One table for the arithmetic

**Delivered 2026-09-18, and it was almost already true.** A hunt through the model's
six files turned up no loose balancing number at all — everything there is a 0, a 1 or
a 2, which is a counter or an index rather than a setting.

**Two places, because they are two kinds of thing.** `core/rules/town_rules.gd` holds
the rules' numbers: floor 0, ceiling 10, threshold 5, the player's step 3, the food
floor, the gap the kingdom pulls across. `content/towns.json` holds the world's: where
each place starts, what it sends, how many people walk, what disappears when it is
poor. One is design and the other is data, and **neither is code anybody has to read to
change a balance.**

What was actually built is the guard, because *almost* true decays. `test_model_numbers`
scans the model's files and fails naming the file and the line, the way
`test_workshop_provenance` does for his library. One exception exists and is a **named
declaration rather than a wider list of tolerated numbers** — a tolerated number is a
door — and it is `ASKED_EVERY`, how often the walking population is recounted, which is
a cost and not a balance.

**Checked:** 4 new tests. 48 suites, 464 tests, 0 failed on both worlds.

**This closes the M group.** M1–M6 and P1, P3 are built; P2 is Yannick's writing and
the Q and F groups are untouched.

---

## P — the people and their routines

### P1 · Routine people, who go somewhere

**Delivered 2026-09-18, and it is the one that works.** Twelve people walk out of the
works to the cutting face and back. **Richesse decides how many go** — the same rule
that lights the furnaces, so a place's two halves never disagree about how it is doing.
At the ceiling, everybody. At the floor, **nobody**.

**They walk to the cutting face, not to the mine.** The mine's road is a point of his
map and does not exist on the 2D one; the cutting face exists on both. It is also the
better fiction: the people walking out there **are the ones eating the forest**, which
is the link between this quest and the fairy's that `QUEST_CINDERWORKS.md` §9 records
as open.

`core/folk.gd`, `core/systems/folk_system.gd`, the `routines` block of
`content/towns.json` — count and destination are content, not code — and the window.
They reuse the road travellers' walk rather than a second one that would drift.

**Measured against the other two:**

| | share of the picture that changes |
|---|---|
| P3, the props fading | 0.35% |
| **P1, the people** | **2.33%** |

Seven times as much, and the frames are not close: a dozen figures on the road and
three on the bridge, against an empty road. **This is what a town that has stopped
looks like.** 45 suites, 444 tests, 0 failed on both worlds, including a replay that
puts the same people on the same stones.

### P2 · Their lines, by state

Est. 3 h. Depends on: P1. **Yannick writes, French first.**

Ten lines per state, four states, **forty for the Cinderworks**, written for the
Cinderworks and shared with nowhere else. English in the same change.

**Check:** talk to four of them in each state. Nothing repeats twice in a row, and
none of the four states' lines would make sense in another state.

### P3 · Abandonment is absence

**Delivered 2026-09-18, and it is not enough on its own — measured.** Below the
threshold a place stops putting its work out: the ore cart, the bundled bars, the hot
bloom, the firewood stacked ready. The buildings stay, the slag stays, the chimneys
stay. A works that has stopped is **empty, not demolished**.

**The list lives in `content/towns.json` and belongs to slosinio.** It is art
direction: one line to change, no code. Two rules the window enforces whatever the list
says — a piece is hidden only if the player could already walk on its tile, so nothing
invisible is ever left blocking the way, and a building is never in the list.

**Measured, and this is the part that matters: it changes 0.35% of the picture.** Five
pieces fade in the whole works and they are small. **P3 does not make a poor works
readable**, and no list of his props will: what a stopped town looks like is **nobody
walking to the mine**. That is **P1**, and it has just become the most important task
in the M/P group rather than the third one.

What P3 is worth keeping for: it is the mechanism, and it grows for free. Every piece
his brother adds to the list, or to the works, is carried by it without code.

**Checked:** frames at (313,220) rich and poor, a pixel count between them, and a test
that no hidden piece ever stood on ground the simulation refuses. 44 suites, 438 tests,
0 failed on both worlds.

---

## Q — the quest

### Q1 · The production area is closed — **built 2026-09-19**

Est. 2–3 h. Depends on: —. **Needs his brother's fence line, or ours from his pieces.**
— *his: `modules/fence_2m.tscn`, which his own ironworks delivery already stands
elsewhere on the same site.*

A fence with one gate between the quarter and the works, and a guard on the gate. The
furnaces are **unreachable**: not gated by a flag, simply behind something.

**Check:** walk from the quarter and fail to reach a furnace. The wall that stops you
is drawn — nothing invisible. A frame of the gate. — ***met***, 5 tests in
`test/test_works_yard.gd`, and the frame is taken.

**The gate is a man, not a lock** (Yannick, 2026-09-19). His street runs north–south
straight through where the west wall wants to be, and this map's oldest rule is that a
wall never closes a road — it has already caught a curtain wall sealing the only way into
Blackcairn. So the road keeps its gap, `WardRules` puts somebody in it, and what gets you
past him is a **fact**: invariant 4 working rather than being bent, and two keys rather
than one so that a death cannot close the works for ever (invariant 6).

  - `content/bake_brief.json` — a `yards` block: two corners, a kind, a gate side
  - `BakeRules.yard_of` — the geometry, pure. **A ring, never a line**: a fence straight
    across open country is walked round in four seconds, which is why the castle's
    curtain is a ring. Checked before building: sealed it holds 368 tiles, open 6483
  - `core/rules/ward_rules.gd` — which fact opens which gateway
  - `MovementSystem._past_the_watch` — per axis, so you slide along the fence

**Three things the guards caught, all mine:** nothing knew how to draw the kind I first
chose; the fence was being drawn across his street where `place()` rightly refuses to
wall a road — *a fence you walk through is worse than a wall you cannot see*; and
`fence` as a kind would have made the works' yard vanish whenever the Wide Acres turned
free, which is that place's business and not this one's.

**Two things left, both content:** the man in the gateway speaks the bridge guard's
lines and announces himself as *« un garde du pont »*, and the procedural map has no yard
— its corners are offsets tuned to his buildings, and the kit stands nothing there. The
tests say `DEBT` on that world rather than pretending.

### Q2 · Tom and Sena stand in the quarter — **built 2026-09-19**

Est. 2 h. Depends on: M1, Q1, and the naming review.

**Drissa is Sena, and that was already the recorded decision** — SPECS §6's budget of 27
names Tom as "the one person the demo's quest genuinely adds", because the foreman and
the worker it needs are `harry` and `sena`. Her existing sheet makes the part better
than the draft did: a woman who left her hand in furnace four and still says the fires
must not go out is a stronger argument for the works than somebody merely glad of the
money.

Two key people at agreed spots, each with their position, **and each telling the
player about the other**, so neither is a single point of failure.

**Check:** find both without the debug list; hear about Sena from Tom and about Tom
from Sena; a frame of each where they stand. — ***met***, 4 tests in
`test/test_cinderworks.gd`, and Tom's frame is taken.

**The dialogue box holds three lines, and that shaped the whole task.** Sena already had
three, so every line she gained pushed one out: the first attempt gave her two and pushed
`ask_organise` — which a route needs — out of reach entirely, and two old tests said so at
once. She names Tom in the line she already had instead. Her hand *is* her position, so he
belongs in the same breath.

**Sena also moved.** She stood at offset +4,+1, which is where Q1's yard fence now runs:
she would have been inside her own workplace's wall. She is by the common kitchen, in the
quarter, where Tom says to look for her.

**Four content guards fired, every one of them right:** the packet leaked the new fact
ids until they had sayable descriptions; the font has no em dash; a joined line ran past
its word budget twice; and **invariant 6** caught that `cinderworks:tom_wants_it_down` had
one source behind a goodwill gate, so a rude player could never learn the other side
existed. Tom's line is `costs: free` now, which is also true of him: he needs help.

### Q3 · Choosing a side, and getting in — **built 2026-09-19**

Est. 3 h. Depends on: Q1, Q2.

The choice is explicit, in conversation. Choosing is what opens the gate — **Tom
brings you through, Drissa vouches for you.**

**Check:** both ways, in two fresh runs. Before choosing, the gate refuses; after, it
does not. The refusal says nothing about a quest. — ***met***, 5 tests in
`test/test_cinderworks.gd`.

**No new machinery was needed.** Taking a side is a line that teaches a fact, and Q1's
ward already reads the two facts. `side_with_tom` teaches `cinderworks:brought_through`,
`side_with_sena` teaches `cinderworks:vouched_for`, and each `hides_after` the other, so
choosing closes the other door.

**Each is only offered once you have heard what that person wants** — which is both good
sense and the thing that frees the slot: the box holds three lines, and the one that
taught you is spent by the time this one appears. Both are `costs: free`, because both of
them want something from the player and neither is doing a favour; two goodwill gates
would have closed the works to a rude player entirely (invariant 6).

**The words are placeholders and say so in the file.** They are Yannick's, in P2. What is
tested is the shape, not the wording.

### Q4 · The act at the furnaces — **built 2026-09-19**

Est. 2 h. Depends on: Q3.

**Put out the ones still burning, or relight the cold ones** — a row in the landmark
table the game already has. It is one act, in two directions.

**Offered inside the yard *and* only after the facing** (Yannick, 2026-09-19; it was
"offered only inside", which was too thin). §4's spine is **get in → face whoever stands
in the way → act**, and *the fight is not an addition: it is the moment somebody puts
themselves physically between the player and the act*. Walking through the gate straight
to a furnace, with nothing in between, reads as a hole where the quest should be.

So Q4 builds the act **and the gate in front of it** — a fact that says the player has
faced whoever was in the way. **F6 is what fills that fact**, and that is the order: the
act with its gate first, the fight wired into it after. Not the other way round, or Q4
would be waiting on a fight that has nothing to decide.

**Check:** perform each in its own run. Repeating it does not count twice. The prompt
appears only inside the works, and only once somebody has been faced. — ***met***, 5 tests
in `test/test_cinderworks.gd`.

**Two gates, different in kind.** Whose side you took decides the *direction*; having
faced somebody decides whether it is offered *at all*. A side on its own is not enough,
and there is a test that says so.

**Once, however many furnaces you walk to.** `spent_sites` is per tile, which is right for
a lever against the crown — six furnaces are six things you can wreck — and wrong for
this. Putting the fires out is one decision about the works, so it is remembered as a fact
and the second furnace has nothing left to offer. That fact is what Q5 reads.

**`cinderworks:faced_them` is written by nobody yet.** F6 wires the fight into it. Until
then the act is reachable in a test and not in play, which is the honest state: the gate
is built and the thing that opens it is not.

### Q5 · The outcome moves the two values, once — **built 2026-09-19**

Est. 2 h. Depends on: Q4, M1.

Tom: 6 → 3 and 4 → 1. Sena: 6 → 9 and 4 → 7. Applied once, as events, so the log
replays to the same state.

**Check:** both outcomes from a fresh run, then replay each log. No double
application, no drift afterwards. — ***met, except the replay***, 5 tests in
`test/test_cinderworks.gd`.

`core/systems/outcome_system.gd` hears `works_act` and asks for three things: a step on
each of the two values, and **rule 6's freeze**. It writes nothing itself — `TownSystem`
is the only thing allowed to touch `TownState`, and it is reached the way everything
reaches it, by an event. Both outcomes are exactly one `TownRules.STEP` on each value,
which is not a coincidence: the step is what one act of the player's is worth, and this is
one act of the player's.

**Three days of the kingdom change nothing afterwards**, and there is a test that runs
them.

**The replay half is owed to F6**, and the test says so with a `DEBT` line rather than
passing. Nothing writes `cinderworks:faced_them` into the log yet, so a test that wants to
reach the act has to hand itself the fact — and a fact set by hand is not in the log, so a
replay of that run does not do the act at all. An assertion that passed there would be
measuring the test. When F6 gives the facing an event of its own, this becomes a real
end-to-end replay and the debt goes.

### Q6 · What the works looks like, and what people say, after — **built 2026-09-19, except the lines**

Est. 3 h. Depends on: Q5, M2, M3, P1, P2.

The outcome's signals and routines, and the lines that follow it — including, on
Sena's path, **that Tom and his people are not there any more, and that those who
remain know it.**

**Check:** the six frames — quarter and production, in each of the three states. —
***taken***, and 5 tests in `test/test_cinderworks.gd`.

**Most of this was already built and had never been checked together.** M2 lights the
furnaces off richesse, P1 walks people to work off the same number, Q5 moves it. Measured
on a played run rather than assumed:

| | fires lit | on the road |
|---|---|---|
| before | 4 of 6 | 4 |
| put out | **0 of 6** | **1** |
| lit again | 4 of 6 | **8** |

**One thing was missing and is now built: Tom is not there any more** once the works runs
again. Read from a fact, through the same one question the fairy answers — *should the
world still draw this person* — so the window and the conversation cannot disagree. His
people go with him without being modelled one by one, because richesse decides how many
walk to work.

**The production frame reads at a glance. The quarter frame does not**, and that is not
news: P3 measured its props at 0.35% of the picture, and the only other thing that changes
there is M3's colour cast, which Yannick has not accepted. Both are his brother's to
improve, and both were already written down.

**What is left is the lines**, which are P2 and Yannick's — including, on Sena's path,
that those who remain know Tom is gone.
Both brothers can tell which is which with no overlay. Save, reload, and they hold.

---

## F — the fight

### F1 · A fight resolves, with no screen — **built 2026-09-19**

Est. 3–4 h. Depends on: —.

Two combatants, one attack, damage, a defence, a result — as simulation state,
advanced through `Sim`. **World time pauses for the fight and resumes after.**

**Check:** headless. The same inputs replay to the same health, the same result and
the same world tick; different advance chunk sizes agree. — *met; 14 tests in
`test/test_combat.gd`, in the fast suite.* See `docs/COMBAT.md` §5 for what playing it
found that the tests did not.

### F2 · An opponent, an option, two keys — **the way in** — **built 2026-09-19**

Est. 2–3 h. Depends on: F1. **New on 2026-09-19**, and it is why the old F2 could not
be played: nothing in the game submits `fight_began`, and no key is bound to a blow.

A **neutral sparring partner** stands within a minute's walk of where the game starts.
He belongs to no side and no quest — he exists so the fight can be reached, played and
retuned long before the quest does. Talking to him offers **one dialogue option that
begins a fight** (`DialogueRules`' intents, so the player never types and the option is
part of the closed set). Two keys are bound: **strike** and **guard**.

**Check:** from a fresh game, reach a fight in under a minute and land a blow — the
HUD's health falls and the opponent's does too. The same key presses replay to the same
health. — ***met***: **Bram**, survivor of Brindle, stands at the village crossroads
**30 tiles / 12 s** from where a new run wakes, on both worlds. `ask_bram_spar` begins
the fight and closes the conversation on the same step. Played end to end headless:
**won, 8 of 10 health left, nobody dead.** Five tests in `test/test_combat.gd`.

**Three things this turned up**, each caught by a guard that already existed:

- **§6 budgeted twenty-five named people and Bram is the twenty-sixth.** Yannick moved
  the budget to **27** the same day — Bram and Tom, both named in §6 rather than
  absorbed. The tripwire still fails on the twenty-eighth.
- **His first tile put him behind one of his brother's trees**, and the tile was not
  clear on the procedural map at all. The offset is now chosen by asking both worlds for
  a prop-free tile — `region.props` alone does not know about the kit's trees, so the
  check was the screenshot.
- **Every `Villager` sheet in the 2D pack is already somebody**, so his placeholder face
  is a man who trains with a weapon and reads as wrong on purpose. M3b settles it.

### F3 · The camera drops, and does not turn — **built 2026-09-19**

Est. 3 h. Depends on: F2. **Yannick ruled for the in-place arena on 2026-09-19**, so
this is no longer a separate screen: `SPECS.md` §10 was rewritten and `docs/COMBAT.md`
§1 carries the argument.

Tilt from 48° to about 27°, tighten the framing, and **never touch the azimuth** — the
traveller's four facings are keyed to the world's axes, so a turned camera draws every
fighter looking the wrong way. It eases in when the fight begins and back out when it
ends. No load, no cut: same region, same simulation, same sprites.

**And a darkened edge, Yannick's on 2026-09-19.** As the lens drops, the borders of the
screen darken into an arena that is not there. It answers what the ring of onlookers in
`docs/COMBAT.md` §6 could not: **it needs nobody**, so it works on empty ground, in a
wood, anywhere — and it generalises to fights against whatever the open world grows
later, which a ring of townspeople never would. The onlookers become a layer on top,
where there really are people.

**The wall is a rule, not a picture.** `CombatRules.inside_arena` bounds both fighters
to two tiles either side of the middle, in the simulation — because a boundary drawn in
the window is a boundary a replay would not have. **No fleeing in the demo** (Yannick):
walking into it for ten seconds never ends a fight.

**Check:** played. Strike in range, miss out of range, hold the button and gain nothing.
Damage follows the fight's own cadence, not the frame rate. The camera returns to
exactly where exploration left it. — ***met***: 7 more tests in `test/test_combat.gd`,
and photographed with `UNCROWNED_FIGHT=bram tools/shot.sh`. The two stand in profile
facing each other, which is the payoff of never turning the azimuth: those are the
`left` and `right` frames his brother already drew.

**What F3 turned up and fixed on the way:** the opponent was being drawn at his anchor
in `content/places.json` — where he stood *before* squaring up — so he would never have
moved on screen. And `Escape` had stopped working during a fight, which left the player
unable to pause; it opens the pause menu now, which is not fleeing.

### F4 · Into the fight and back out — **built 2026-09-19**

Est. 3 h. Depends on: F3. *(Was F3, and depended on Q3 — it no longer does, because F2's
sparring partner gives it a fight to enter without the quest.)*

Whoever asked for the fight receives one result. Victory and defeat both return to the
right place, with the right health, and defeat obeys the checkpoint rule.

**Losing is not always dying** (2026-09-19). Whether an opponent finishes you is a fact
about *him*, in `content/moves.json`'s new `opponents` block, not a branch in the code.
Bram spares you — he says so in his own line — so losing to him leaves you standing in
the village on one health. Anybody not listed does not spare you: the default kills, and
the checkpoint rule takes over.

**Check:** win once and lose once from the same starting point. World time resumes.
Nothing is applied twice. — ***met***: lose → `lost`, 1 health, **no death**, still in
Brindle; win → `won`, 8 health; one `fight_ended` each, carrying the answer, the opponent
and **who asked** (`ask_bram_spar`), which is the hook F6 needs. 6 more tests.

**Two things fixed on the way:**

- **The loss was being read back out of `WorldState`** — full health, a death on the
  counter, and still in hitstun. Three conditions that are each true for other reasons,
  and none of which hold when the opponent spares you. `Fight.player_felled` is set by
  the blow that did it, which is the only place that knows.
- **A blow now costs what the file says it costs.** `WorldState.hurt` had half a second
  of grace after every wound — *contact's* rule, because standing inside the king drains
  ten health in three frames. A fight's blows are spaced by frame data and already cannot
  land twice, so the window has nothing to protect and would silently eat blows. Measured
  honestly: it eats none of Bram's, whose swings are seventy-four frames apart. It is a
  trap closed before F5 and F6 add a faster opponent, not a bug that was biting.

### F5 · The opponent does something — **built 2026-09-19**

Est. 2–3 h. Depends on: F4. *(Was F4.)*

One approach, one attack with a readable wind-up, and one defensive action for the
player. Driven by the fight's state, never by a scene timer.

**Half of this arrived with F1 and was not planned to.** The opponent had to walk, or
his first knockback ended the fight in a deadlock, and he had to choose when to swing,
or he was a post. So the approach, the twenty-four frame wind-up and the guard all
exist and are tested headless. What F5 still owes is the player's *evasion*, the
opponent's second option, and the part that can only be judged by playing it.

**What F5 added:** his **jab** (18/3/12, reach 1300) beside the swing, chosen by the
distance between them — inside 1550 mm he answers short, beyond it he must wind up the
heavy one. And the player's **backstep** on `I`: four frames of startup, ten of travel at
twice walking speed, **invulnerable for exactly those ten**, eight of recovery.

**The relationship, which is the actual design:** the guard answers the jab, the jab
answers the backstep, and the backstep answers the swing. It holds because human reaction
is about 16 frames — step on seeing the heavy blow and you are invulnerable on frame 20,
before it lands on 24; step on seeing the short one and it lands on 18, two frames before
you are safe.

**Check:** avoid or block the signalled attack, then punish its recovery. Slow the
rendering down and the timings do not change. — ***met***: a blocked swing leaves him
owing 11 frames against a strike that takes 8, and both are tested; the dodge is tested
in play. 11 more tests. Timings are in steps and nothing reads a clock, which
`test_how_the_caller_chunks_its_steps_changes_nothing` has covered since F1.

**Four things playing it found that the frame data did not**, each one a number that
looked right on paper:

1. **The heavy blow was thrown exactly zero times.** He waited 24 frames and then wound
   up for 24 more, and the player walked 1080 mm through the whole band in the gap. His
   decision delay is now its own number (10), separate from any move's startup.
2. **And its reach was too short** — the band between the jab's threshold and his own was
   200 mm wide, crossed in five frames. 1500 → 2000, so closing on him is the dangerous
   part, which is what a heavy weapon ought to mean.
3. **The jab was thrown zero times too**, at reach 1100: he stands at the edge of his
   swing, the player at the edge of theirs, and the band was below both. Its reach is now
   the player's own (1300) — the moment you can hit him, he answers short.
4. **The backstep was not a dodge.** Travel alone had carried the player 360 mm when the
   heavy blow landed, which is nowhere near out of a blow reaching two metres: the dodging
   player lost at 1 health having landed nothing. Invulnerable frames fixed it.

**Easier, on Yannick's call (2026-09-19), and measured.** His heavy blow winds up for 28
frames instead of 24 and costs 2 instead of 3; he commits every 16 frames instead of 10.
The jab stays at 18 — it is the floor of the readable band and the only thing keeping the
backstep honest. Against a scripted player, by reaction speed:

| Reaction | Guarding | Backstepping |
|---|---|---|
| 16 frames | won, 9 of 10 | won, 10 of 10 |
| 22 frames | won, 9 of 10 | won, 10 of 10 |
| 28 frames | won, 8 of 10 | won, 8 of 10 |
| 34 frames | won, 8 of 10 | won, 8 of 10 |

**No losing case at any reaction speed**, where before a 22-frame dodger lost at 1 health.
Two numbers had to move with it and both were caught by tests rather than by eye: his
reach (2000 → 2200), because the band a heavy blow lives in must be wider than the ground
the player covers while he thinks; and the starting distance (2400 → 2800), because they
must begin outside the longest reach in the game.

**And the backstep's invulnerable frames grew 10 → 14**, because slowing the heavy blow
had quietly broken the dodge: its last two active frames landed after the window closed.
That relation is now its own test.

### A blow you can see coming — and what his brother owes

**There is no attack animation and no guard animation.** `traveler_walk_frames.tres` holds
eight: idle and walk, four directions. A strike, a guard and a backstep all looked like a
person standing still, and the 28 frames of wind-up the whole fight is built to be read
were **invisible** — which is most of why it felt hard with hands on it.

Until he draws them, the figure he *did* draw is moved: drawn back through the wind-up,
thrust forward on the blow, leaning away behind a guard. `CombatRules.lunge_at` decides
the timing (pure, tested) and the window decides the distance (0.3 tiles). **A placeholder
and visibly one**, and it prints a `DEBT` line in every run so it is not forgotten.

**What would replace it: three frames.** An attack, a guard, and a flinch — `left` and
`right` only, because the camera never turns.

### F6 · The fight belongs to the quest — **built 2026-09-19**

Est. 2 h. Depends on: F5, Q4. *(Was F5.)*

Tom's side: a foreman or the gate's guard. Drissa's side: **Tom**. The fight happens
where the act happens, and its result decides whether the act goes through.

**One person fewer than the quest doc assumes.** `Contremaître Harry` is already the
works' foreman and `Sena` is already a worker there, so Tom's side has its opponent
today and Drissa's role has a body. **Tom is the only new person the quest needs.** The
naming review (`QUEST_CINDERWORKS.md` §4) decides whether Drissa *is* Sena or replaces
her.

**Check:** both sides played end to end, from the quarter to the changed works. —
***met***, 5 tests in `test/test_cinderworks.gd`.

**They come to you.** Reaching for a furnace is what brings somebody out — Yannick,
2026-09-19, on seeing the first build, and it is what §4 always said: *Tom, **come** to
stop the shift*. Sending the player off to find him and pick a fight was the weaker
scene. Going to find him still works and is a second way in; it is no longer the way.

**The middle of §4's spine.** Until this, the fight and the quest did not know each other:
you could fight Bram because he offered it, and in the quest nobody fought you at all.
Now the foreman stops Tom's man and Tom stops Sena's, each through a line that only the
other side is offered, and **only a win** writes `cinderworks:faced_them`. Losing sends
the player back to the last fire with the works still shut to them; walking away counts
for nothing. That is what makes the fight the price of the act rather than a scene in
front of it.

**And Q5's debt is paid.** `test_the_whole_quest_replays_from_its_log` walks the whole
thing from where the game begins — no hand on any position, any fact or any fight — and
rebuilds the same works from the log alone: side chosen in conversation, fight begun by a
line, every blow, the act at the furnace, 9 and 7.

Getting that test honest took two goes, and both failures were the test's. It teleported
to each person, because `_talk` does and forty other tests only care what somebody says;
a position written into the store is not in the log, so the replay walked from the wrong
field. Then it steered by eye and wedged itself in the first doorway. It follows
`Navigation.path` now, and it walks every step.

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

## B — what goes to his brother

### B00 · A spec for the NPC routines, with Yannick — **after this run**

Owner: Yannick + Claude, on paper. Est. 1–2 h. Depends on: this run ending.

P1 built the smallest thing that works: how many people walk, and where. It says
nothing about **what a routine is** in general — hours, several destinations, what
people do when they arrive, whether the key NPCs have routines too, what happens in the
other five towns. Yannick asked to sit down and write that spec **if it turns out to be
needed**, which is the right order: the thing is built and measured first, and the
general rule is written from what was learnt rather than guessed in advance.

**Check:** either a written spec, or a written decision that P1's version is enough.

### B0 · Keep the letter to slosinio current — **running, never finished**

Owner: Claude, as work happens. Est. minutes each time.

[POUR_SLOSINIO.md](POUR_SLOSINIO.md) — **in French, addressed to him.** Everything this
run is learning that changes what he should draw, measured rather than guessed: which
signals carry and which do not, what the demo needs from him, what the list in
`content/towns.json` lets him change without code, the identifier contract, and the
`.import` files his editor dirties.

**Rule: a measurement that changes what he should do goes in the letter the same day.**
Three are in it already — the furnaces carry, the fading props change 0.35% of the
picture, and the colour cast is his call and one commit to undo.

**Open, for him to answer:** the fence and gate, the visible pollution, whether
destroyed-works pieces are worth the work, and whether the building count comes down.

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

Then **M3–M6** and **P1**, then the quest **Q1–Q6**, then the fight **F1–F6**, then
the shell, then the deletions.

**The fight no longer waits for the quest** (2026-09-19). F1 is built, and F2 puts a
neutral sparring partner near the start, so **F2–F5 can run at any point** and the fight
can be played and retuned while the quest is still being written. Only **F6** needs the
quest. This was decided after Yannick walked to the works looking for a fight and found
that nothing in the game could start one.

Roughly **63 hours** of sessions, twenty-seven tasks. That is more than the 45–55 the
plan estimated before the model was designed, and the difference is the model itself:
six tasks that did not exist when the demo was going to run on the old simulation.

**What is not in this list:** his brother's fence, gate and pollution (Q1, and the
model's §4 signals), and the answer to the quest's one open question — what ties this
dispute to the player's own grievance.
