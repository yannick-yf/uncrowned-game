# The demo, as tasks

Date: 2026-09-18, and three groups added on 2026-09-23. The specs turned into work.

**J, K and W are new and nothing in them is started.** They come from two designs
settled that day — [the player model](PLAYER_MODEL.md) and [combat's second
design](COMBAT_V2.md) — and they are the consequence of one idea Yannick returned to:
**you can kill everyone**. M, P, Q and F are built; their entries say so.

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

> **Moved into the tutorial's redo (Yannick, 2026-09-29)** — group **O**, steps O18 and O19. The whole tutorial of the
> demo is to be redone — **meeting the fairy, the combat tutorial, the departure for the
> Cinderworks** — and the dialogue is rewritten then, as part of it, rather than as a
> task of its own. So P2 is no longer "forty lines for the works" on its own: it is the
> writing of that redo. C2, C3 and C4 still wait on it, because they delete the lines
> and the readings it replaces.

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

### Q1 · The production area is closed — **built 2026-09-19, rebuilt 2026-09-21**

> **Read this before the paragraph below.** What Q1 first built was a computed rectangle
> of a generic `fence_2m`, stamped one tile at a time on two corners, with a gap for a
> gate and ten pieces standing in the river. Yannick rejected it on sight. It was rebuilt
> in **G2–G3** out of his brother's own courtyard pieces — 39 `soubassement_2m`, his
> `portail_cour` with the gatekeeper standing in its 2.6 m passage, his `enseigne_forge`
> — and the bake now reads his `catalog.json` so every piece stands at his metres, turned
> his way, blocking what its own collision shapes cover. The account is
> `docs/DEMO_POLISH.md` §0, §1 and §6. **The ruling at the foot of this task still
> stands: the gate is a man, not a lock.**

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

## J — the player's own simulation

**New, 2026-09-23.** Reads from [the player model](PLAYER_MODEL.md), which is the piece
`SIMULATION_MODEL.md` left open. The places are simulated; the player is not, and every
consequence of *you can kill everyone* lands here rather than in the fight.

### J1 · The purse — **built 2026-09-24**

Est. 2 h. Depends on: —.

One integer for the player's gold, moved only through the event log and rebuilt by
replay like every other store. `SPECS` §12's currency and nothing more: no prices, no
market, no items. It exists now because the fight needs somewhere for a dead man's gold
to go, not because v1 spends it.

**Check:** a run that earns and spends and then replays its log lands on the same
number; a purse cannot go below zero.

**Delivered 2026-09-24.** `core/player_state.gd` — **the player's own store**, built
where the model says the player is shaped like a town: `TownState` holds two numbers
for a place, this holds the player's. `core/systems/player_system.gd` is the only thing
that writes it, and only from `move_purse`, so a replay rebuilds the same purse.
Overdrawing takes what is there rather than refusing — refusing is a price check, and
§5 says there are no prices — and the event records what actually moved, not what was
asked for, so a journal reading it cannot claim a price the player never paid.

**The four bands are not built**, deliberately: §7's first open question is their
thresholds and they are Yannick's numbers. Nothing waits on them.

**Checked:** 5 new tests. 54 suites, 585 tests, 0 failed on both worlds.

### J2 · A deed moves the town, not the person — **built 2026-09-24**

Est. 3 h. Depends on: —.

`Deeds` and `DeedRules` shift a faction and a witness's regard today. They shift the
standing of **the place the deed happened in** instead. A deed nobody saw moves nothing,
which `RumourSystem` already decides — so stealing stays a choice about where and when
rather than a slider.

**Check:** a theft in the Cinderworks moves the Cinderworks and no other town; the same
theft unwitnessed moves nothing; both suites green.

**Delivered 2026-09-24, beside the old model and not on top of it** (rule 4). The
player's standing is a new dictionary on `core/player_state.gd`, for the same five
places `TownState` carries and read from the same file, so the two can never disagree
about which places exist. `PlayerSystem` listens for **`deed_witnessed`** — which
`Deeds` derives only when somebody saw it — and moves the town the deed names, once,
and no other. `core/rules/player_rules.gd` is the new table's seam; its numbers are
still `DeedRules`' until **J3**.

`DeedRules`' factions and witnesses still move, and `RumourSystem` still carries a
story into `Standing.by_town` as it arrives. All of that goes with **C3**, not here:
`test_factions`, `test_deeds` and `test_rumour` are untouched and green.

**Checked:** 9 new tests, plus three assertions in `test_journeys`' replay test, where
the walk to the stall is in the log and a replay can be proved. 55 suites, 594 tests,
0 failed on both worlds.

### J3 · The scale's two ends — **built 2026-09-24**

Est. 2 h. Depends on: J2.

A theft is about **−10**, killing somebody innocent about **−80** (Yannick,
2026-09-23). Which forces the deeds table to know what *innocent* means: somebody who
drew on you first is a different deed from a bystander.

**Check:** both numbers, written out in a test; and killing an opponent who attacked
first costs less than killing a bystander, with the two named in one test so the
distinction cannot quietly disappear.

**Delivered 2026-09-24.** `PlayerRules` prices the four deeds the model names: a theft
at **−10**, putting it back at **+6**, killing somebody innocent at **−80**, and
killing a man who drew on you first at **−20**. *Innocent* is answered as **two deed
ids** rather than as a judgement made at the moment of the blow, because the town's
opinion is the only place the distinction can show and one `i_killed_somebody` would
have to guess. They live in `PlayerRules` and not in `DeedRules`, whose docstring
promises every deed's effects are written in one place and which has no faction,
witness or hardship row for either — the three columns that go with C3.

**−20 is ours, not Yannick's**, and it is the first number in the model that is: he set
the two ends and not the middle. A quarter of the murder and twice the theft — there is
still a body in the street, and everyone standing there saw who reached first.

**The old twenty-four keep their numbers** and fall through to `DeedRules.town_effect`
until C3. Re-pricing acts that are on their way out is work thrown away, and dropping
them to zero would quietly remove every way a town's opinion can go **up** — §8's Q38
defect, reintroduced.

**Nothing performs a killing yet.** `K3` is where a fight can end in one; this is the
table it will read, exercised through the same `Deeds.perform` pipe every deed uses.

**Checked:** 6 new tests. 55 suites, 600 tests, 0 failed on both worlds.

### J4 · Blackcairn reads the mean — **built 2026-09-24**

Est. 1 h. Depends on: J2.

One pure function. The royal city's regard for the player is the mean of every town's
standing, **including the towns never visited**, which sit at neutral and pull it
toward zero. No place → place propagation: the player travels the same star the kingdom
does (`SIMULATION_MODEL.md` §3, guardrail 1).

**Check:** hated in one town and liked in four arrives positive; mildly disliked in all
five arrives lower than that. Two tests with the numbers written out, because the
second result is the counter-intuitive one and it is the design working.

**Delivered 2026-09-24.** `PlayerRules.at_blackcairn()` — one pure function over the
store, so nothing is kept and nothing can drift. The numbers, written out:

- A murder in the works and four towns you have done right by:
  `(−80 + 30 + 30 + 30 + 30) / 5 = +8`, which reads **welcome**. One terrible town is
  survivable.
- One theft in each of the five: `(−10 × 5) / 5 = −10`, which reads **wary** — *lower
  than the murderer's*. Consistency matters more than any single act.
- And the half that is easy to leave out: hated in the works alone is `−80 / 5 = −16`,
  because the four towns never visited are counted at neutral.

**Checked:** 4 new tests. 55 suites, 604 tests, 0 failed on both worlds.

### J5 · Dialogue reads the town — **built 2026-09-24**

Est. 1 h. Depends on: J2.

`DialogueSystem` reads `with_person`; it reads the town's standing instead. **That is
the whole of what standing does in v1** — no hostile watch, no prices, no closed doors.

**Check:** the `they_think_ill_of_me` greeting fires on a town's standing and not on a
person's; a frame of it, because a greeting that silently never fires is invisible to
the suite.

**Delivered 2026-09-24. The one replacement in this group**, and deliberate: everything
else was built beside the old model, this reads the new number instead of the old one.
`DialogueSystem` asks `PlayerRules.regard_in()` for the town the player is standing in —
the same place the speaker is, because you have to be within `Game.TALK_REACH` to talk at
all. **The HUD moved with it**, to the same function: `StandingRules`' own docstring says
why — *"the HUD saying 'wary' while a trader refuses to serve you would be a lie the
player cannot audit"* — and two readings of one idea is how that lie gets written.

Cairnwell and Blackcairn carry no standing, so a conversation there takes **J4's mean**.
Brindle and the road read neutral: a ruin has nobody in it to have an opinion.

**Photographed**, both halves, with a new debug tool — `UNCROWNED_TALK=maddox[:standing]`,
listed in `CLAUDE.md`. At neutral Maddox opens with *« Vous êtes venu à pied »* and the
HUD reads *Harrowgate, inconnu*; at −45 he opens with *« Maddox ne vous rend pas votre
salut »* and the HUD reads *Harrowgate, indésirable*. Same person, same tile, one number.

**One consequence of J3's scale, and it is the design**: a theft is −10 and
`StandingRules.UNWELCOME` is −20, so **one theft no longer shuts a door — two do.**
§3 says the player who takes things is a nuisance. The first one is still legible the
first time: it carries the town from `unknown` to `wary`, which the HUD says out loud.

**Checked:** 3 new tests; four existing ones updated where the reading deliberately
moved (below). 55 suites, 607 tests, 0 failed on both worlds.

### J6 · The journal shows what you did and what it cost — **built 2026-09-24**

Est. 3 h. Depends on: J2.

The standings, and beside them the acts that moved them — saving somebody, killing
somebody (Yannick, 2026-09-23). Not a new machine: `core/journal.gd` already keeps one
chronological list carrying facts rather than phrasing, and every deed that moves a
standing is already an event in it. This is the reading.

**Check:** a frame of the page after a theft and after a killing, with the number and
its cause on the same screen. A town that hates you and will not say why is a bug.

**Delivered 2026-09-24, and it is a reading and not a machine**, as the entry says:
`Journal.standings()` walks the log for `standing_moved` and hangs each deed under the
town it moved, with what it cost. A seventh journal page draws it, best town first so
the worst survives the page's cut with its reasons under it, and under the five towns
the two readings that are not a place's own: **the court's mean** (J4) and **the purse**
(J1), which had no way of being seen at all before this.

**Photographed**, on the baked world, standing in Harrowgate:

- after a theft — *Harrowgate : méfiance* / *vous avez pris quelque chose sur un étal,
  devant des gens   −10* / *À la cour : inconnu.*
- after a theft and a killing — *Harrowgate : haï*, both causes under it with −10 and
  −80, and *À la cour : méfiance*, because four towns that never heard pull −90 to −18.

Two things were needed to take those frames and both are new debug tools, gated and
listed in `CLAUDE.md`: **`UNCROWNED_DID=deed[,deed]`**, which does deeds where the
player stands through the real pipe — a killing has no key until K3 — and
**`UNCROWNED_SCREEN=journal:<page>`**, which is the existing screen knob extended,
because the journal is seven pages and the one being photographed is rarely the first.

**Checked:** 4 new tests in `test_journal`. 55 suites, 611 tests, 0 failed on both
worlds.

---

## K — combat, second version

**New, 2026-09-23.** Reads from [the combat design](COMBAT_V2.md). It replaces the
fighting-game system, which was not broken — it was the wrong game for *you can kill
everyone*. `docs/COMBAT.md` stays as the record of what was built and why it went.

### K1 · A fight on the world grid, turn by turn — **built 2026-09-24, beside the first**

Est. 6 h. Depends on: —.

**Built as new files rather than as edits**, because K6 is the deletion and nothing is
deleted until the demo runs on the new model: `core/duel.gd`, `core/duel_fighter.gd`,
`core/rules/duel_rules.gd`, `core/systems/duel_system.gd`, `content/duel.json`,
`tools/duel_player.gd`, `tools/play_duel.gd`, `test/test_duel.gd`. The first design's
four files are untouched and still run. The paragraph below describes the cut-over, and
it is K6's to make.

`core/fight.gd`'s millimetre line becomes tiles of the world grid, and
`CombatSystem`'s sixty steps a second becomes turns. Everyone acts once per round in a
fixed order and **whoever started the fight acts first** — there is no initiative roll
because there are no dice. The world clock stays held (`Sim.ticks_held`).

**One event per turn**, which is fewer events than the first design rather than more.

**Check:** a fight of twenty turns is twenty events; the same log replays to the same
tiles; the fourteen combat tests that survive stay in the fast suite and it stays fast.

### K2 · Move and act, and the three actions — **built 2026-09-24**

Est. 4 h. Depends on: K1.

Two numbers of the table are ours rather than this list's, and `content/duel.json` says
which and why. **`follows_tiles`** — how far from where a fight began an opponent will
chase — because both sides move four tiles a turn, so a chaser who never gives up can
never be outrun and *nobody could ever leave*, which is K4's rule and §7's ending.
**`leaves_after_rounds`** — because "out of reach **and staying there**" is one round
longer than the end of the round somebody happened to move last in: a wounded man who
ran four tiles escaped a player who had not yet had a turn to follow him.

**Strike and wait, and there is no guard** (Yannick, 2026-09-24) — Baldur's Gate 3 has
no block button and neither does this. Defence is position and initiative. **Fixed
damage, no dice.** Reach is one tile, diagonals included, because the game's movement is
8-way. All of balance stays **one small table** — the rule worth keeping from the first
design.

**A blow does not move you**: the one who takes it plays the flinch and stays on their
tile. No knockback, no pushbox (Yannick, 2026-09-24).

The first pass at the table, and the four settled values are Yannick's of 2026-09-24:

| | |
|---|---|
| Tiles per turn | **4** — 8 m. Ten was proposed and measured out: it is three screen-widths and position stops existing |
| Player hit points | **100, and deliberately a formality** for development. The shipped number is still open — 30 is the recommendation — and S4 is when it has to be settled |
| Opponent and monster hit points | 10 |
| Damage of a strike | 5 |

**A turn is move *and* act** (Yannick, 2026-09-24), with the movement **capped** at a
number of tiles. The cap is not a comfort setting: moving and acting in one turn is the
faster game to play, and it would make the grid meaningless if a fighter could cross it.
That number *is* what spacing means here, and it lives in the table with everything else.

**Check:** editing the table alone changes the outcome of a scripted fight; a test plays
the same five turns twice and gets the same result to the tile; and a fighter cannot
reach across the arena and strike in the same turn.

### K3 · Killing — **built 2026-09-25**, and fleeing is deferred

Est. 4 h. Depends on: K1, J2.

> `core/systems/felling_system.gd`: a death writes a fact `OpeningRules.is_gone`
> reads, the body's purse goes to the player, and the town prices it by who drew
> first — −80 for murder, −20 for finishing what somebody else began.
> **Invariant 6 is now proved against a real death**: kill Tom and the works still
> opens to somebody the office vouched for. **Fleeing is not built** — Yannick cut
> the threshold on 2026-09-24 because at ten points and five damage everything ran
> after one hit, Bram included. The machinery stands and is tested under an override.

Anybody can be attacked, from the world or from a conversation, and nothing checks who
they are. A killed person is **gone** through `OpeningRules.is_gone`, which reads a fact
rather than keeping a flag in step — written for the fairy, reused for Tom. A wounded
NPC spends its turn moving away and leaves the fight once it is out of reach. A body
carries its gold.

**Check:** kill one of the quest's people and the quest still finishes by another route
(invariant 6, proved against a real death rather than structurally); attack the works'
people and they flee rather than die in place; the standing moves by J3's numbers.

### K4 · The picture, adapted — **built 2026-09-24**

Est. 3 h. Depends on: K1.

Five frames in `docs/frames/duel/`, taken with the new `UNCROWNED_DUEL` (written into
`CLAUDE.md` beside `UNCROWNED_FIGHT`): `turn.png`, `blow.png`, `fleeing.png`,
`walking_out.png`, `end.png`.

Two things the picture asked for that the design had not:

- **The ground's rim is gone entirely**, not softened. A circle drawn on his grass says
  *this is where it stops* every frame, and there is no longer anywhere it stops. What
  is left of the ring is the darkened edge of the screen, dimmed to 0.55, and a floor
  that moves with the two people in it. The winner's colour, which the rim used to say
  on the beat, is said by the ground under their feet instead.
- **The lens closes to 15 m and not 7.** The drop and the azimuth are untouched — the
  ruling of 2026-09-19 is about the angle — but seven metres is three and a half tiles
  of height, and a turn that buys four tiles in every direction is a field nine tiles
  across. The first photograph had it running off all four edges.

The camera that drops and never turns stays. The ring is **softened and stops being a
boundary** — nothing prevents the player leaving or an enemy fleeing, which is this
map's oldest rule applied once more. Both healths, the damage numbers, the hit flash,
the sparks and the ending's beat are kept as they are.

**Check:** four frames — a turn being taken, a blow landing, somebody fleeing, the end
— and in one of them the player walks out of a fight that is still going.

### K5 · Six more frames: wind-up, attack and flinch, north and south

Est. 4 h. Depends on: —.

`tools/draw_fight_frames.gd` built eight from his brother's own pixels, under Yannick's
explicit exception. **Six more — wind-up, attack and flinch, up and down — which makes
twelve in all**, built from the up and down walk frames his brother drew. It was eight
until the guard was cut on 2026-09-24; the two guard frames already drawn go unused.

Yannick was offered the free answer, a blow thrown north drawn side-on, and refused it
twice: first choosing to draw rather than accept (2026-09-23), then raising the count
himself (2026-09-24) — *"Ok pour huit images, et même plus si nécessaire. On veut un
rendu assez propre pour la demo v1."* **That last sentence is the brief**: the bar is
how it looks, not how many files there are.

Three actions rather than one, and the reason is his own playtest. He found the first
animation too slight because **the wind-up had no drawing**, and the wind-up is the half
of a blow a player reads. An attack thrown north with a wind-up drawn west would break
the telegraph in the exact facing these frames exist for; a flinch that recoils west
from a blow struck from the north reads as a bug.

The art rule's three conditions hold unchanged: **no colour is invented**, **his files
are never touched**, and the whole thing is deleted the day he draws his own.

**Check:** **a photograph of a blow struck north, and one of a blow taken from the
north** — a back view is the hard one to draw and a file count proves nothing about it.
Then the sheet holds twelve, every `AtlasTexture` points at the combined sheet, and
`test_his_brother_has_not_drawn_a_blow` still fails the day his own sheet grows an
attack.

### K6 · The first design comes out — **built 2026-09-26**

Est. 2 h. Depends on: K1–K4.

> Yannick played the turn-based fight several times and said the real-time one could
> go. About 2,500 lines went: `core/fight.gd`, `CombatRules`, `CombatSystem`,
> `content/moves.json`, `test_combat.gd`, the two fight tools, `UNCROWNED_FIGHT`, the
> `evade` key, the `DuelRules.TURN_BASED` switch and every first-design branch in the
> two windows. **One trap, and a test now holds it shut**: `CombatSystem` was the half
> of `Sim.ticks_held` that turned the hold *off*, so `DuelSystem` became its only
> writer — without that, the first fight of the game would stop the world's clock for
> good (`test_the_clock_is_recomputed_every_step_by_the_duel_alone`). Four tests about
> *any* fight moved to `test_duel.gd`, and the art exception's guard
> (`test_his_brother_has_not_drawn_a_blow`) to `test_fight_frames.gd`. Fast suite
> 29 s before, 28 s after.

`CombatRules`' frame data, the millimetre line, the sixty-steps system, the frame counts
in `content/moves.json`, and the tests that assert them. Last, like every deletion in
this list.

**Check:** both suites green with none of it; the fast suite no slower than it was with
it.

---

## W — the wild, and the demo's road

**New, 2026-09-23.** Monsters live in the forest and never in the towns (Yannick). This
is the group that makes the demo's walk a journey instead of a corridor, and it is where
the demo's funnel lives — made of wolves, never of walls.

### W1 · A wolf — **built 2026-09-25**

Est. 3 h. Depends on: K1, K2.

> Most of it was already standing: `DuelRules.decide` is one rule for anybody's turn.
> What it needed was numbers that are not a man's — **ten points where a man is
> fifteen** — and a way to be more than one. `_named` refused every duplicate, which
> is right for a person and wrong for a species, so three wolves were one wolf.

Hit points, one damage number, a reach, and one rule for what it does on its turn. That
is the whole of a monster, and it is why turn-based makes them cheap enough to have.

**Check:** a wolf fights, kills, and can be killed; the same fight played twice comes
out the same.

### W2 · Wolves on the roads, never in the towns — **built 2026-09-25**

Est. 3 h. Depends on: W1.

> Three packs as anchors in `content/places.json`, `core/wild.gd`,
> `core/systems/wild_system.gd`, and a block in his rock paint because **his brother
> has drawn no animal** — a DEBT, and `POUR_SLOSINIO.md` asks him for one. **It found
> the worst bug of the group**: a fight held its fighters by the name of their kind,
> so every blow aimed at the second wolf landed on the first, which was dead.
> Fighters carry a seat now. The pack also had to move twice — a third of the way out
> of Brindle is the way out to *everywhere*, and six journey tests walked into it.

Where they stand is **content, not code**, the same discipline the routines already
follow. The road to the works is plainly the safe one; the others are where the wolves
are.

**No gate anywhere in `core/`** (`PLAYER_MODEL.md` §8). A check that asks *have you
finished the tutorial* is invariant 4 broken, in a demo or out of one.

**Check:** a walk from Brindle to the works meets wolves and survives at the demo's
numbers; **nothing refuses to let the player walk anywhere**; a frame of the road that
shows why a first-time player takes it.

### W3 · The tutorial fight, against Bram — **superseded by O8** (2026-09-29)

Est. 4 h. Depends on: K1–K4.

> Its step 2 — Bram walks a few tiles away so the first turn needs a move — is kept,
> walked rather than teleported, in O8's sword drill.

**The same sparring partner as the first design** (Yannick, 2026-09-24), which keeps
everything F2 built for getting into a fight from a conversation. The shape he asked
for:

1. The player talks to Bram.
2. **Bram walks a few tiles away**, and the fight starts.
3. Explanations are laid over the fight itself, as it is played.

Step 2 is the one doing the teaching and it is worth saying why: with reach at one tile
and movement at four, a Bram who has stepped away **cannot be hit on the first turn**.
The player has to move before they can strike, so the first thing the fight teaches is
the thing the grid is for, and it teaches it by making them do it rather than by saying
it.

Bram already spares the player (`spares` in `content/moves.json`), so a beginner who
loses does not die in the tutorial.

**Open:** which explanations, and how they leave the screen. The words are Yannick's,
like every other line — **P2**.

**Check:** somebody who has never played finishes it without being told the keys, and
moves before their first blow. That is **S4's tester**, not a test — a suite cannot see
whether a person understood.

### W4 · The funnel comes out in one change — **built 2026-09-26, and there is no funnel**

Est. 1 h. Depends on: W2.

> **The task's premise was false and a test found it.** Walking from Brindle to
> Blackcairn, to Harrowgate and to the Muster meets **no pack at all**; only the road to
> the works does. The two "dangerous road" packs stand beside named points that the real
> shortest paths go round, so W2's *the others are where the wolves are* was never true
> in play. What W4 pins instead is what *is* true: Pillar 1 is whole, the whole of the
> constraint is the `wild` list in `content/places.json`, and nothing in `core/` asks
> whether a tutorial is finished. **Whether to build a real funnel is Yannick's call** —
> and a real one would put wolves on the very roads the journey tests measure.
>
> **His call, 2026-09-26: not now.** The demo's pack stands **before the bridge** on the
> road to the works (two wolves, three tiles short of the deck, on the drawn road). The
> funnel will be built later, in a game-design pass, *through game-design elements* —
> once the first tasks are done.

Written the day W2 is written, never afterwards. Taking the demo's constraint out must
be an afternoon and not an excavation.

**Check:** the change exists and is named; applied, the player can walk to Blackcairn in
minute one and Pillar 1 is whole again.

---

> **C3 is unblocked.** *Delete the deeds, the documents, the factions and the old
> quests* depends on Q1–Q6, and all six are built. Yannick confirmed the factions go on
> 2026-09-23. It stays where it is — deletions are last — but J2 and J3 rewire what C3
> then removes, so the two are read together.

---

## O — the opening, redone: the cemetery, the hail, three drills

**Asked 2026-09-29 (Yannick), planned the same day.** The first ten to fifteen minutes
of the demo, made to feel finished: the player wakes in a **cemetery south of Brindle**,
a **path** leads him into the ruined village, **Bram hails him** the way a Pokémon
trainer spots you (a "!", the player held, Bram walks up, the conversation opens, once),
and the combat tutorial becomes **three drills** in the manner of *Bannerlord*'s
training grounds — **sword** (Bram), **bow** (Wren), **magic** (the fairy's gift). The
dialogue of the fairy and of the tutors is rewritten last, by Yannick (this is where
**P2** now lives). The turn-based duel is kept and extended, never rewritten.

The plan came out of a read-only analysis of the code (seven readers, a planner and an
adversarial reviewer); its findings are the reason for each step's shape.

### His rulings, 2026-09-29

| Question | Ruling |
|---|---|
| Bow and magic now, against CLAUDE.md's "a later workstream, on its own branch"? | **Now, in a version scoped to the tutorial, on `feat/playable-demo`.** Real depth — AI, ranged balance — is still later |
| Where does the player's spell come from? (SPECS §5: "magic is the one miracle") | **The fairy's gift**: one spell, taught with her last word, and kept after the tutorial. Its name is his |
| Who is the archer? (the named cast is full at 27) | **Wren** — already in Brindle, adult, a scavenger who also hunts |
| Does the bake learn his coast? | **Only around Brindle**, not the whole coast |

**Defaults taken, which he may overturn** (stated to him the same day):

- The hail **forces the conversation to open, not to finish** — "not now" is an answer,
  and Bram goes back to his post. A hail you cannot leave would be a gate (invariant 4).
  It is a demo-only scripted beat against SPECS' *"a conversation, not a cutscene"*
  (2026-09-12), made replayable and removable in one change (the `hails` list).
- The fairy and her fire move to the cemetery; a death before any rest wakes you among
  the graves.
- **A spar never kills, and Bram can still be killed** — Pillar 3 (SPECS §1: nobody is
  made invulnerable) holds: a partner who yields can still be fought for real, and that
  is murder.
- **No downloaded art.** The web research found Kenney, KayKit, Quaternius and Poly Pizza
  candidates, every one a third artist's hand, and his own catalogues say *no
  third-party model or texture downloads*. The cemetery is his pieces; the "!", the
  arrow and the spell are marks of ours drawn in code; the tutors are told apart by a
  name-and-role plate and their reach mark, not by a drawn weapon.
- The fifteen minutes end at the works' gate.
- **The clearing is not deleted by this group.** His "OK to delete once the redo is
  done" answered C2–C4; deleting the clearing needs its own OK.

**Still his, and flagged:** the player's shipped HP (100 is a development value; at 100
the bridge wolves carry no threat, so a finished-feeling fifteen minutes needs S4's
figure first); music and ambience (the pack's tables go in C4 — real tracks or a
chosen silence); SPECS §5's *"one raising, in the forest"* against waking among graves
(his writing settles it in O18); §9b, now urgent — the coast's granite dressing is one
of the three sectors we drop, so the first frame would show bare cliffs until his
brother fixes the compressed meshes.

### The order, and why combat comes before the map

**The drills do not need the map.** They can be built and tested at Bram's present post
from `ask_bram_spar`, while the map depends on the riskiest step here (his coast). So:
foundations, then the fight, then the map, then the hail on the new map, then the
words, then the check. Every step leaves both suites green and the game launchable, and
a mechanic lands together with its picture — nothing the player can reach is ever
invisible.

**Size, honestly: about 130 h of sessions**, not counting his writing. The heavy items
are the coast (O11), the hail (O16), drawing several opponents (O6) and the bow (O9).

### O1 · A spar never kills — and the partner can still be killed — **built 2026-09-29**

Est. 3 h. Depends on: —.

**A live defect, and ours (K3).** Winning the spar writes `killed:bram`, a witnessed
`i_killed_somebody_innocent` in Brindle and a rumour: `FellingSystem` answers every
`duel_down`, and `spares` only ever protected the player.

- `Duel.spar`, set from `duel_began.spar` and in the fingerprint; `DialogueSystem._choose`
  passes it when `DuelRules.spares(option.fights)`.
- In `DuelSystem._end_turn`, an **opponent** of a spar at 0 goes out `yielded` and
  derives `duel_yielded` — never `duel_down`, so `FellingSystem` does not run. The
  **player** still goes out `down` (the spar floor in `_end` is unchanged), or a lost
  spar reads as `left`.
- A yielded partner's next conversation offers, beside the rest, one option to fight
  him for real (`fights`, no spar) — which is murder, through `FellingSystem`, as any
  other killing.
- `fight.yielded` banner words in both languages. `SaveFile.VERSION` bumped.

**Tests first:** winning a spar kills nobody (no `killed:bram`, no deed, no rumour);
the partner can be talked to again; **Bram can still be killed** (the real fight, then
`killed:bram` and the murder deed); a lost spar still reads `lost`
(`test_a_sparring_partner_stops_when_you_go_down`); test_wild's K3 killings unchanged.

**Check:** both suites; `tools/play_duel.gd -- press 400` ends with Bram yielded; a
frame of Bram standing after the beat.

### O2 · The first frame says what E does — **built 2026-09-29**

Est. 1 h. Depends on: —.

The HUD offers the fire ("E, sit down and rest") while E actually opens the fairy:
`_read_input` tries talk before rest and the prompt checks rest first. The prompt takes
`_read_input`'s order.

**Test first:** a fresh run's first prompt names the fairy. **Check:** a frame at the wake.

### O3 · Where you wake is its own name — **built 2026-09-29**

Est. 4–5 h. Depends on: —.

`Region.START` / `start_centre()` split from `Region.CLEARING` (equal to it for now), read
by `Game.build_world`, the respawn before any rest (`WorldState.hurt`), the map's dot and
`tools/map_criteria.gd`; `TestCase.where_the_game_starts()`. Every test that means *the
start* is repointed (test_opening, test_phase_0, test_journeys, test_saving,
test_collision, test_map, test_duel, test_world3d, test_screens); the claims that mean
*the fairies' ground* keep reading CLEARING. **No time band changes here** — the walk
figures are restated in O12 against his pace, with bands he rules on, rather than
converted and turned into debts.

**Check:** both suites green with the same DEBT and OFF counts; the wake frame unchanged.

### O4 · A re-bake cannot replay an old save onto new ground — **built 2026-09-29**

Est. 1 h. Depends on: —.

> Built as `SaveFile.world_key()`: the world's name and a hash of `region.json` (baked)
> and `places.json` (both) — the bake's own `source` block hashes only his inputs, not
> our brief, so the produced file is what is hashed. 0.6 ms. **And a defect found on
> the way:** `test_saving` discarded the save before and after each test, and a headless
> run shares `user://` with the game, so every suite run deleted the player's own save.
> Tests now write to `user://save_under_test.json` (`SaveFile.path`).

The save's world id is the constant `baked`. It takes the bake's `source` hash, which
`region.json` already carries, so any re-bake (O11, O12) refuses old logs by itself;
manual `SaveFile.VERSION` bumps stay for rule changes.

**Test first:** a save written against one bake hash is refused under another.

### O5 · One door for every blow — **built 2026-09-29**

Est. 1–2 h. Depends on: O1.

A pure refactor: `_land(sim, duel, world, by, victim, damage, move)` out of `_strike`,
carrying the G clamp, `world.hurt`, the flinch, facing, the felling and `blow_landed`
(now with `move` and the victim's tile). Arrows and spells inherit all of it.

**Check:** fast suite unchanged; the replay fingerprint equal.

### O6 · Every fighter drawn where he fights — **built 2026-09-29**

> Built, and it found a worse defect than the one it was for: **a pack bit its own**
> (`Duel.foes_of` meant "everybody but me"), fixed in its own commit. Measured after the
> fix at 100 HP with the PRESS hand: two wolves cost 30 HP — so at S4's 30 the bridge
> would kill a first-time player, and the figure has to be settled with the wolves.
> Beasts are named in the player's language (`beast.wolf`), never `Wolf#2`;
> `UNCROWNED_DUEL=wolf,wolf` squares up against a pack.

Est. 8 h. Depends on: O5.

**Also a live defect**: the two wolves before the bridge are drawn frozen at the pack's
spot while they fight, and a felled one does not go down. The fight reading carries
`fighters[]` (the legacy keys kept); `world3d._sync_people` and `_sync_wild` draw each
fighter at its seat, per id (walk state, paint, `_struck`); sparks go by the event's
target; the marks are drawn per fighter; the eye goes to their centroid, `_fight_size_m`
clamped 15–22 m; the HUD has one bar per foe and names who is acting.

**Tests first:** in a two-wolf fight each figure stands on its seat and a downed one is
hidden; two foes, two bars. **Check:** shots at several steps; the bridge fight by hand.

### O7 · Where a named person actually stands — **built 2026-09-29**

Est. 4 h. Depends on: O5.

**The first named people who move** are Bram and Wren — walked out by a drill, left
where a duel ended, and (O16) walking up to hail you. One store, `Walkers`, owns every
displaced named person: `DuelSystem._end` writes each non-player fighter's final tile
into it, and a walker goes home at the table's pace when nothing holds him. **`Npc` and
`Cast.shared()` are never mutated.** One `where_is(id)` — walkers first, then the anchor
— is read by `Cast.nearest_to`, the witness positions (`CrimeRules`, `WatchRules`), the
journal's who-is-where page, `main.gd`'s reach, `DuelSystem._begin` and both windows.
Registered in `Game.build()` **and** `fresh_stores()`. Pace from
`MovementRules.tiles_per_second()`, never one figure for both worlds.

**Tests first:** after a duel he is drawn and reached where it ended, not at his anchor;
he walks home; a theft counts him as a witness where he stands; replay rebuilds it.

### O8 · Drills, the sword drill, and the lesson on screen

Est. 12 h. Depends on: O6, O7.

- `content/duel.json` gets `drills` — `{_order, sword: {master: bram, opponents, first,
  stand_off, damage: 1, goal: blows, count: 3, rounds: N}}`. Balance stays in that file.
- `duel_began` carries `drill`; `Duel.drill` and `Duel.tally` are in the fingerprint;
  `DuelRules.damage_of(who, drill)`; the tally counts in `_land`; `DuelRules.drill_met`
  after each turn; **a drill that reaches its `rounds` cap is failed**, and a drill can be
  left as any fight can. `duel_ended` gains `{drill, passed}`.
- **The stand-off is walked, not teleported**: on round 0 Bram steps out to
  `stand_off_tiles` through the existing MOVING phase, so the player sees why the first
  turn needs a move (W3's step 2).
- A new `DrillSystem`, after `DuelSystem`: `drilled:<id>` when passed; **Bram mends you**
  after any drill, passed or not, so nobody meets the bridge wolves on one point; the
  transition is Bram walking back up and the next talk opening within reach.
- `DialogueOption.drill`; Bram gets a `drill_sword` option (draft words, marked as drafts)
  and **`ask_bram_spar` stays** — invariant 5, the tutorial starts more than one way.
- The HUD: a drill card under the bars — title, objective `n / N`, hint — a
  `drill.passed` banner (today anything but `won` reads *you are down*), the keys line
  per drill; the lens stays down while Bram speaks between drills. `drill.*` texts in
  both languages, in the font.
- `UNCROWNED_DUEL=drill:<id>[:steps[:hand]]`, debug-gated and listed in CLAUDE.md.

**Tests first** (`test_tutorial.gd`, with `DuelRules.override` on the player's HP so the
fast suite stays fast): PRESS passes; turn 1 cannot strike; STAND ends at the cap with
no death; `drilled:sword` written once and replayed; a failed drill writes nothing and
is offered again; only Bram's options read `drilled:*`; `ask_bram_spar` still spars; the
card shows `2 / 3`.

### O9 · The bow — Wren, the drill, and how an arrow is seen

Est. 14 h. Depends on: O8.

- **Rules.** `fighters.<kind>.weapon` (sword by default); rows `bow_reach_tiles`,
  `bow_min_tiles`, `bow_keeps_off_tiles`, `arrow_lands_at_step`. On his turn the archer
  keeps off and **aims at a tile**; the arrow **lands there when his next turn starts**,
  on whoever stands on it. **Ending your move elsewhere is the dodge.** Range only, no
  line of sight, no dice. `Duel.volleys` and a LOOSING state in the fingerprint; volleys
  of a fighter who is out are dropped; `out_of_reach` becomes reach-aware so a kiting
  archer does not "leave" (test_duel 432 and 445 stay green).
- **Wren**: `fighters.wren` (bow, spares, purse 0), her drill post as a named point, her
  sheet line; `drills.bow` {master: bram, opponents [wren], goal: dodged, count: 3,
  damage: 1}; Bram's `drill_bow` option needs `drilled:sword`.
- **Seen, in the same change**: the aimed tile marked through the player's turn (a patch,
  a crosshair ring, a dashed aim line); the arrow a raised ribbon in flight; sparks on a
  hit, ink dust on a miss; `arrow_aimed` and `arrow_dodged` added to
  `_fresh_fight_events` (or the view never sees them); a "dodged" float; name-and-role
  plates over each foe.
- `DuelPlayer` gets a DODGE hand; `tools/play_duel.gd` takes a drill.

**Tests first:** she keeps off; she stands when she already has a shot; moving off the
tile dodges and standing still is hit; a bow fight replays to the tile; DODGE passes the
drill, STAND ends with no death; the volley mark is shown; the float appears. The fast
suite is timed — whole drills move to a SLOW file if they push it far past 12 s.

### O10 · The spell — the fairy's gift, the drill, and how it is seen

Est. 10 h. Depends on: O9.

- **Rules.** A third action, CAST: `spell_reach_tiles`, `spell_damage`,
  `spell_every_rounds` (the cooldown is load-bearing — a ranged spell would make the
  one-tile sword pointless, and the spell is kept after the tutorial, so it changes the
  wolf, Tom and Harry fights); `DuelFighter.ready_round`; impossible casts become waits;
  resolved through `_land`. **The spell is a fact the fairy teaches with her last word** —
  a knowledge gate, legal under invariant 4.
- `drills.magic` {master: bram, opponents [wren], goal: spells, count: 2}; Bram's
  `drill_magic` needs `drilled:bow` and the spell.
- A `cast` input on physical **I** (free since the backstep went); `_read_duel_input`'s
  third key auto-targets like K; `duel.keys` in both languages.
- **Seen**: the fairy's sage (`MARK_GUARD`, free since the guard was cut) — a glow at the
  hand, a flash on the caster, an expanding ring, sparks and a brief light at the target;
  a spell-reach ring round the cursor while it is ready; a sound cue.
- **SPECS amended in place**: §5's *magic is the one miracle* gains *and the fairy gives
  a sliver of it to the one she raised*; the 2026-09-12 row *a register rather than a
  spell list* is recorded as narrowed to one gift, not reopened as a list; the
  2026-09-24 *two actions and no guard* becomes *three actions — strike, cast, wait — and
  no guard, no knockback*.

**Tests first:** a cast lands at range; the cooldown refuses a second cast; a cast with
nobody in reach is a wait; *guard* is still a wait; a blow still does not move you;
the actions test rewritten to three; the keys test includes cast; CAST passes the drill.

### O11 · The bake learns his coast round Brindle

Est. 8–10 h. Depends on: O3, O4.

**Ruled: around Brindle only.** Today the simulation reads his raw heights: visible
cliffs south of Brindle can be walked up, and the southern shore's pocket — whose one
way out is his own graded path, RaccordBrindle into his chemin_traversant — does not
exist. **That pocket is the funnel he asked for, already drawn by his brother.**

- **His final ground, not a copy of his formula.** His runtime applies the relief stamps
  (TerrasseBrindle's covers the exit), the royal ascent, the earthworks and the bridge
  approaches, *then* lerps the coast edits by weight, *then* repaints rock over the whole
  grid. So `tools/bake_region.gd` — the one place allowed to load his nodes — instances
  his terrain headless and takes the final `_height` and `_paint` after
  `rebuild_ground()`, inside a box round Brindle; core receives plain arrays. His
  coastline files and scripts are hashed as bake inputs.
- His coastal trails and the graded approach are ROAD inside the box.
- vendor, bake, `--check`.

**Tests first** (test_bake): his cliffs south of Brindle are MOUNTAIN; his trails there
are ROAD; the inputs are hashed; **baked MOUNTAIN equals his runtime paint ≥ 0.85 over
the box**; baked only, the southern shore is a pocket whose one way out is his approach.
**Check:** both suites; photographs of the candidate sites (the cove under his
DescenteDeLaCrique, the cape's end) for him to choose the cemetery from.

### O12 · The game starts at the cemetery

Est. 6–8 h. Depends on: O11 and his choice of site.

`points.cemetery` in the brief (his metres) and in places.json for the procedural world,
outside every zone; `Region.START` reads it; the fairy and **the fairies' fire** move
onto it (the fire within reach of the approach, more than 2.2 tiles from the wake tile,
so the first prompt is still her). Procedural: `_stamp_line(START, BRINDLE, …, ROAD)` in
`_build_overworld` (not `_stamp_road`, which stamps the fixed route); baked: the road is
his. `_place_name` and the M map name the cemetery. CLEARING stays as the held ground.

**Tests first:** the start is outside every zone; the fairy is within reach; a ROAD path
joins the start to Brindle, at most 1.3 times the straight line; the walk to Brindle and
Blackcairn *in minutes*, with bands he rules on at his pace. **Check:** vendor, bake,
`--check`; frames of the wake, the map and the procedural start; title → creation →
wake → the fairy, by hand.

### O13 · The cemetery can be seen

Est. 6–8 h. Depends on: O12.

His pieces only, read from his catalogues' `placement` notes first (G1's lesson): his
ironworks `soubassement_2m` as a low wall, `portail_cour` (or `portail_fermier_ouvert`)
as the gate, his library `fence_2m`, bench, spruce and fir, his farming
`sol_cultive_raccord` as fresh earth, and **his `boulder_round`, scaled small, as uncut
grave stones** — no exception to the art rule. `_yards` generalised into a yard on a
point. Graves adult-sized, never on his trail, tone jitter seeded from the anchor.
**POUR_SLOSINIO asks him for a cemetery kit.** Made headstones in his materials (beside
`_wolf()`) only if Yannick, seeing the frame, widens the wolf's exception.

**Tests first:** the pieces are hashed; every wall on his map is something you can see;
no piece on a ROAD tile of his; a DEBT *his brother has drawn no grave*.

### O14 · Where Bram calls from

Est. 3–4 h. Depends on: O12.

The hail's zone and Bram's new post are **named points** — in the brief for the baked
world and in places.json for the procedural one — **not Brindle + offset**: offsets are
shared between worlds and Brindle is 35×30 baked but 15×11 procedural, so one offset
lands in the sea. `test_anchors` is strengthened to **fail on an anchor that resolves
to impassable ground before being nudged**. A `hails` block (`{who, point, radius}`) with
its own row reader; `HailRules`: `in_sight`, `calls_out(who, facts)` (not hailed, not met,
not gone), `approach` (a deterministic path stopping one tile short); `content/hail.json`
holds the beat. **`hails` stays empty until O17.**

**Tests first:** the anchors resolve on both worlds; the pure rules; the start is outside
the zone and no pack or fire is in it; baked only — with the zone removed, the start
cannot reach Brindle's centre or the bridge.

### O15 · Walkers that can be spoken to

Est. 5 h. Depends on: O14.

Every scripted walker — tests and tools — gets through a conversation it did not open.
`test_cinderworks`' `_walk_to` lifts into `tools/opening_player.gd`: a Navigation path, any
duel played with PRESS, any unopened dialogue answered, and on a stall a report of tile,
zone, `talking_to`, duel phase and the last events — instead of *walk failed*.
`TestCase.past_the_hail(sim)`; `alone_on_the_road` excludes the zone. Sized from the zone
chosen: tests that teleport to Brindle's centre are far from it; walkers from the new
start, and fixtures that stand at Bram's post, are not.

**Test first:** a walker facing a dialogue it did not open fails loudly, naming it.

### O16 · Bram calls you over

Est. 10–12 h. Depends on: O7, O15.

A `Hail` store (who, phase: IDLE, SPOTTED, COMING, ARRIVED, TALKING, RETURNING; the walk;
facing; `holds_player()`) in `Game.build()` and `fresh_stores()`; a `HailSystem` after
`DuelSystem`, before `WildSystem`: on entering the zone, `hailed:<who>` and a derived
`hailed`, the player held (a third early return in `MovementSystem`, never a view flag),
Bram's beat, his walk through `Walkers`, and on arrival a derived `talk`. When the talk
ends or is refused, he walks home and the player is free. **RETURNING waits while a
`duel_began` is pending or a drill chain is open** — derived events reach the systems a
step late, and the reviewer found the race. Wolves never fire while the player is held.
`DialogueSystem._open` refuses anyone but him while held. The greeting's `called_out`
reads the **store's phase**, not the fact, or he would open with the hail line forever.
The clock is not held (`ticks_held` keeps its one writer). The exit slot stays.

**Tests first** (`test_hail.gd`): one hail, the fact written; `move_intent` refused while
held; he converges within the table's budget; the talk opens with no submitted talk;
leaving and re-entering gives no second hail; a replay and a save taken mid-approach give
the same fingerprint and the same talk step; `advance(300)` equals 300 × `advance(1)`;
`met:bram` or `killed:bram` means no hail; never during a duel or a dialogue; an empty
`hails` holds nobody, ever (the W4 one-change check); a spar is still offered by an
ordinary talk.

### O17 · The hail, seen — and switched on

Est. 5–6 h. Depends on: O16.

The `hails` list is filled here, the day it can be seen. A code-made "!" of ours (an
ember bar and dot with an ink rim, unshaded, no depth test, popping over his head along
the lens) in the 3D window, and in the flat and procedural window too; Bram visibly
walks; the keyboard is taken (only Esc passes); prompts hidden; the camera eases between
the two of them; the existing `seen` cue on `hailed` (pack audio — flagged, not
extended). `UNCROWNED_HAIL=bram[:steps]`, debug-gated and listed; the gate count in
CLAUDE.md goes up by one. Debug frames inside Brindle (`UNCROWNED_AT`, `_TALK`, `_DUEL`)
spend the hail directly — one frame, not a save — and that is written down.

**Check:** frames at the "!", mid-approach and arrived; a new run played by hand.

### O18 · The fairy's words

Est. 3 h of wiring, plus his writing. Depends on: O12, O10.

His rewrite, French first, for a meeting among the graves — and his answer to SPECS
§5's *"one raising, in the forest"*. It keeps one fairy, once, her last word opening the
one quest, nothing in `SHE_MAY_NEVER_SAY` — and now **her gift, the spell**. If he changes
the seven facts, the tests move first.

### O19 · Bram, Wren, and the way on

Est. 4 h of wiring, plus his writing. Depends on: O17, O10.

The hail, each drill's instruction and transition, Wren's lines, a farewell that points
north along his road with no marker, the departure for the Cinderworks; Wren's
*"west of here"* fixed (the works are north on the baked map). The drafts from O1, O8,
O9, O10 and O16 are replaced — they are marked as drafts so none ships.

### O20 · The first fifteen minutes, played headless

Est. 8 h. Depends on: O8 onwards, grown as each step lands; finished after O19.

`tools/play_opening.gd` and a SLOW `test_first_minutes.gd`: creation, the fairy, rest,
the path, the hail, the three drills, leaving and re-entering, the bridge wolves, the
works' gate — each stage with a budget at the world's pace and a stall watchdog that
names the stage; a replay and a save round trip equal at the end; a table of walking,
fighting and reading time per stage, and damage taken against 100 HP and against 30.
**Built from O8 with draft lines**, so stalls surface early rather than at the end. The
procedural world plays what it has and prints DEBT for the rest.

### O21 · Photographs and a fresh-eyes review

Est. 6 h, plus fixes. Depends on: O20.

About 25 frames printed by the player tool — title, creation, the wake, the fairy, the
path, the hail, each drill's first turn and key moment, the banners, the journal, the
wolves, the gate, the map, the flat bake, the procedural start — in French and English.
Then the review sub-agent Yannick allowed walks the route for bugs, stalls and
incoherence. Each defect gets a failing test first where a suite can see it, and its
own commit. **The check is Yannick playing the fifteen minutes.**

### O22 · The documents say what the game is

Est. 4 h. Depends on: O21.

CLAUDE.md (the art rule and the new marks, DEBT/OFF counts, the tools and their count,
the state table, the standing exception), SPECS §4, §5, §10, COMBAT_V2 (a section on
drills, the three actions), QUEST_CINDERWORKS §6, V3, MIGRATION_3D (the Brindle row, §9b),
POUR_SLOSINIO, the walkthrough, duel.json's notes.

**Not in this group: deleting the clearing** — its ring, its corridor, its tests. It
waits for Yannick's own OK.

---

## S — the shell

### S1 · Four traits, a pool of 8 — **built 2026-09-28**

Est. 2 h. Depends on: —.

> Only two of the six old traits were ever asked for by a line: **Wits became
> Intelligence** (sixteen lines) and **Temper — saying it to their face — became Force**
> (four). Attunement's one use was the wood slowing a walker, a layer that is switched
> off and goes in C4, so its two `OFF` tests went with it. The creation frame is two
> rows shorter. A save from before S1 still loads, with the old names ignored.

Force, Intelligence, Agilité, Prestance. Floor 1, cap 5, **pool 8** — which buys two
specialisms and nothing else. The French names and notes rewritten with them.

**Check:** a character made on the screen is one the simulation accepts; 9 points is
refused with a reason; both languages.

### S2 · A fresh run reaches the fairy through creation — **built 2026-09-28**

Est. 2 h. Depends on: S1.

> `Screens.QUICK_START` is gone. Where the game opens is `Screens.first_screen`, a pure
> function tested without a window: a release build always opens on the title, and a
> debug build does too unless the harness names a screen or `UNCROWNED_QUICK=1` asks
> for the old quick launch. The fresh-run check — allocate, wake beside the fairy, she
> speaks, Continue rebuilds the same person in the same place — is
> `test_a_fresh_run_reaches_the_fairy_through_creation`.

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

### C1 · Delete the LLM layer — safe today — **built 2026-09-28**

Est. 1 h. Depends on: —.

> About 1,500 lines. Two things were not dead and stayed: `ProseRules`, which is the
> house style every hand-written line is checked against and the join the reactions
> use (its model-only checks went), and `content/voices.json`, kept as writing notes
> for P2. `Answers` and `answers.json` went too — they were briefs for the model.

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

> **Half built, 2026-09-28 — and the other half is Yannick's call.**
>
> **Done.** The eight old quests are one: *the wood is going*, the fairy's, which the
> journal shows and which now closes on the two acts the demo's quest actually ends on
> (it closed on two old deeds nothing produces any more, so it never closed at all).
> The per-person opinion (`Standing.by_person`, `DeedRules.witness_effect`, the rumour's
> resident pass) is gone; `PLAYER_MODEL.md` §2 had already moved it to the town.
>
> **Not done, because it is not a deletion.** The factions' ranks and the documents are
> what **the three routes to the confrontation** are made of: the crown's rank opens
> *Access*, the papers are *Exposure*. Delete them and two routes of three go, and with
> them `test_factions.gd`'s invariant-7 walk. The endings (`EndRules`) read the twelve
> quantities, which are C2's; and the old dialogue gates on the ranks and the regard,
> which is C4's and waits on P2. So the rest of C3 is a question before it is a task:
> **what are the routes to the king in the new model?** Until that is answered it runs
> with C2 and C4, not before them.
>
> **Answered the same day (Yannick, 2026-09-28): there are none.** No predefined routes
> to the king — how the player reaches him depends on the player's status and on the
> kingdom's status against each town's. So the ranks, the documents, the three routes
> and the invariant-7 walk all go, and **they go with C2 and C4 after P2**, as one
> change: the endings and the old dialogue read them until then. `CLAUDE.md`'s
> invariants 6 and 7 carry the ruling.

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
