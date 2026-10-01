# The demo, as tasks

Date: 2026-09-18; J, K and W added on 2026-09-23; O, S and B since. The specs turned into
work.

> **Where it stands (2026-09-30).** M, P, Q, J, K, W, O and T are built, with the
> exceptions their entries give (M3 not accepted, P2 below, Q6's lines); F was built and
> deleted in K6; S1–S2 and C1 are built, C3 half. **Yannick played the opening** and his
> findings were group **T**, built by 2026-09-30. Next **P2**, with him, then **C2–C4**
> as one change. **CLAUDE.md's table *Where the work actually
> stands* is the short version and is kept current** — read it before this list.

J, K and W came from two designs settled on 2026-09-23 — [the player model](PLAYER_MODEL.md)
and [combat's second design](COMBAT_V2.md) — and they are the consequence of one idea
Yannick returned to: **you can kill everyone**.

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
>
> **Widened, and moved after group T (Yannick, 2026-09-29, evening).** O18–O19's drafts
> stand *for this version*. P2 is now **a review and rewrite of every line of the demo**,
> done **together, later**: Claude drafts, Yannick validates, French first. It **writes
> the Cinderworks' forty lines by state** after all (Q6's), and C4 then deletes the old
> lines they replace. It starts from what T1 records: *the works was built with the wood
> of the forest the village stood in, and that is why Brindle was destroyed.*

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

> **Built, all twenty-two steps, 2026-09-29.** The lines are drafts Yannick let stand for
> this version; the check that counts is him playing the fifteen minutes.

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

### O8 · Drills, the sword drill, and the lesson on screen — **built 2026-09-29**

> Built as planned, with three findings. **The three-line cap**: Bram's new drill line
> pushed O1's "for real" line out of his conversation, so his post question now yields
> its slot once you have bested him. **The step-back is searched, not aimed**: on the
> 2D map a straight line away ended in a wall and left him in one turn's reach, so he
> walks to the nearest tile at least `stand_off` from the player that he can reach.
> **Where he steps can be behind a tree** — his drill post (O14) is to be chosen on open
> ground. Every word is a marked draft for O19.

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

### O9 · The bow — Wren, the drill, and how an arrow is seen — **built 2026-09-29**

> Built as planned, plus one rule the tests asked for: **a drill won by beating the
> partner before the goal is failed** — the bow's lesson is the dodge, not the yield.
> A drill names who acts `first` (Wren shoots, Bram teaches). Known and left: Wren is
> set down beside you when the drill begins (she stands too far to be squared up from
> where she is), where she should walk over; and everybody is still his one traveller,
> so the HUD's bar is what names her. Words are marked drafts for O19.

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

### O10 · The spell — the fairy's gift, the drill, and how it is seen — **built 2026-09-29**

> Built. The gift (`you:the_gift`) is given with her last word through a new `gives`
> field, so she still says seven things; Bram's magic line needs the bow *and* the
> gift through a new `requires_also`. **SPECS §5 is not amended yet** — that goes with
> O22's documents, once Yannick has named the spell.

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

### O11 · The bake learns his coast round Brindle — **built 2026-09-29**

> Built as the reviewer asked: `tools/bake_region.gd` stands up his own terrain node and
> relief stamps from the copied workshop, lets his runtime make the ground (3 s), and
> takes the heights and paint inside the brief's `his_final_ground` box; the copy must
> be his bytes (JSON compared with the repointed paths put back) or the bake refuses.
> Measured before: in that box his runtime paints **1,646** tiles of rock where the raw
> files had **300**. His three coastal paths are ROAD. **The box had to reach west to
> x 200** to take in the cove's cliffs, or the shore leaked away along raw ground. Both
> pockets now hold: the cove (296 tiles) and the cape (120) reach the world only up his
> RaccordBrindle. And the first frame there shows his cliffs bare — §9b's dropped
> CoastlineDecor.

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

### O12 · The game starts at the cemetery — **built 2026-09-29**

> **Where, settled with Yannick in two passes.** He chose the cove, "but a cemetery is
> not put on a beach"; the only connected ground in the cove's pocket is its beach, and
> both grass plateaus of his promontory turned out to be islands his cliffs close all
> round (a first probe missed it by checking only that they were sealed). So it is **the
> burned village's own graveyard**, on the meadow at Brindle's southern edge above his
> cliffs, beside a ruined house: `points.cemetery` at (279, 331), moved two tiles inland
> because a spike of his cliff hid the player on the first frame. The fairy and her fire
> are among the graves; `_place_name` says *le cimetière*; the 2D map's cemetery is a
> point west of Brindle joined by a road. The journey walker learnt to fight through a
> pack (the Muster road now brushes the climb's wolves), which was O15's and is done.
> **Seen on the first frame, and his:** pale holes in the ground where sea or coast
> should be, beside the cliffs §9b leaves bare.

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

### O13 · The cemetery can be seen — **built 2026-09-29**

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

**Built.** A yard may stand on a point (`YardRules.name_of`); a point's yard has no
ward and no floor, and nothing of it stands on a road tile at all, verge included. A
piece may name his library (`"library": "rocks/boulder_round"`) as well as a catalogue
entry, stand at many points (`at`), be scaled (a number or three axes — the geometry tool
scales his collision shapes with it, the window the node), lie on the ground
(`ground`: `ROLE_GROUND`, stops nobody), and vary by `jitter` (yaw, scale, shift) from a
mixed hash of the yard, the piece and the index. The cemetery, in the brief: his farm
fence in two runs with his open farm gate between them, facing his trail; two old
graves (his boulder narrowed and stood up, his fallow narrowed over it) and three fresh
ones (the same stone, his loose earth), laid round his hazels, which keep the corner by
the trail. There were three old ones until the review found the third on the tile the
gate opens onto: the bake now reports a point yard's gate that opens onto a wall, and a
test walks through it. His farming catalogue joins the bake's catalogues. Tried and dropped: his
boulder at 0.3 even (pebbles, from the game's lens); his three-block scree for the old
mounds (strewn stones); his coastal granite shingle (its mesh names his material path,
§9b). The frame is Yannick's to judge; made headstones only if he widens the exception.

### O13b · The fires and the graves' markers — **built 2026-09-29**

Asked by Yannick after seeing O13 and O17's frames: *« pour les stèles je valide »*, and
for the fairies' fire *« on compose quelque chose qui ressemble à un feu de camp. Simple
mais beau et visuel. »* The graves' markers are **made** (`"made": "headstone"` and
`"grave_board"` in the brief; `YardRules.made_entry`; no scene, so they close their own
tile and nothing more; the window's `_headstone()` and `_grave_board()` wear only his
`styled_rock` and `styled_wood`). **Every campfire** is `_campfire()`, composed from his
pieces — a ring of his `boulder_round`, four of his `fallen_log` leaning in, a bed in his
`embers` material, his `fumee_ruine`, an `OmniLight3D` in his forge's colour that
flickers on two periods — and the flames, ours, particles over a soft quad coloured from
the hearth ember, his forge glow and his coals' emission. The fairies' fire moved one
tile west, because his hazel grew through it. The art rule in CLAUDE.md records the
widening; `test_world3d` checks the paints, the count of markers and that every fire
gives light.

### O14 · Where Bram calls from — **built 2026-09-29**

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

**Built.** `bram_post` (281, 315 baked; 264, 176 on the 2D map — the tiles Brindle+(2,−4)
already gave him, so nothing he does moved) and his ground as **two discs of radius 3** —
`brindle_hail` (277, 322; 257, 180) and `brindle_hail_east` (284, 322; 258, 180), two rows
for Bram in `hails` — across the village's south edge, where every *shortest* way north
from the graves crosses (a long way round can miss it), not its heart, so a test
or a frame standing in Brindle's centre is never called out; the table in
`content/hail.json` holds the radius beside the beat's two numbers (the '!' for one
second, twenty to reach you). **The ground was found by search, after the review**: a
3.5 disc grazed the one walk it was tested on while an equally short one passed it by,
and one big enough to cut them all reached into the graves, called you three steps from
where you wake and held the talk behind his pines. Now the ground is dammed and every
shortest walk to Brindle's heart and to the bridge must come out longer, his trail
cannot be walked from beside the graves to Bram's post out of his sight, and the start,
the cemetery and the heart are outside. Fires are allowed inside — to wake at one you must have rested there, and to
rest there you walked in and were called. `Places.hails()` reads `{who, point, radius}` rows and
hands them resolved; `hails` is empty. `HailRules`: `row`, `radius_of`, `in_sight`,
`calls_out` (not `hailed:`, not `met:`, not `killed:`), `approach` (Navigation, cut at the
first tile touching the player's). **The dam check changed, and why:** it was written
for the cove, a pocket; O12 put the graves on open meadow with his walkable wood all
round, so no disc could be passed only through. The test now asks that every
shortest walk out of the graves to Brindle's heart and to the bridge goes through it —
on the 2D map, where the graves lie between Brindle and the bridge, only the first (OFF,
said why).
**The strengthened anchor test found eight** standing on a wall, the river, the ramparts
or the mountain and nudged silently: two on his map, six on the 2D one. Seven are moved
to offsets open on both worlds (Wren's fire, the workers' fire, Blackcairn's fire, a
watchman, the ledger, the tiered law, the 2D gate point); the eighth is the 2D map's
existing debt, the first pack anchored where his bridge is.

### O15 · Walkers that can be spoken to — **built 2026-09-29**

Est. 5 h. Depends on: O14.

Every scripted walker — tests and tools — gets through a conversation it did not open.
`test_cinderworks`' `_walk_to` lifts into `tools/opening_player.gd`: a Navigation path, any
duel played with PRESS, any unopened dialogue answered, and on a stall a report of tile,
zone, `talking_to`, duel phase and the last events — instead of *walk failed*.
`TestCase.past_the_hail(sim)`; `alone_on_the_road` excludes the zone. Sized from the zone
chosen: tests that teleport to Brindle's centre are far from it; walkers from the new
start, and fixtures that stand at Bram's post, are not.

**Test first:** a walker facing a dialogue it did not open fails loudly, naming it.

**Built.** `tools/opening_player.gd` (`OpeningPlayer`): `walk_to` along
`Navigation.waypoints` (with `off_road` for the works), `follow` through a line of
points, a `DuelPlayer.PRESS` hand for any fight — whose steps are not counted against
the walk's budget, because the world's clock is held while it lasts, capped at
`FIGHT_CAP` — and `LEAVE` (default, `end_talk`, remembered in `left`) or `STOP` for a
conversation it did not open. A walk that does not arrive leaves a `report`: target,
tile, place, step, why, who is talking, the fight's phase, the last six events. The
journeys (`_walk_to`, `_follow`), `test_cinderworks`' walk and `tools/measure_routes.gd`
walk with it now — the route tool had been standing in front of the wolves until its
deadline since W2, and now fights them and arrives. `TestCase.past_the_hail(sim)`
writes each hail's fact; `alone_on_the_road` never picks a tile in a hail's ground. The
short held-direction walks (`test_harrowgate`, `test_zones`, `test_phase_0`,
`test_saving`) are left as they are: none goes near the hail's ground or a pack.

### O16 · Bram calls you over — **built 2026-09-29**

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

**Built.** `core/hail.gd` (`Hail`: `rows`, `who`, `phase`, `beat`, `spent`, `quiet`,
`facing`; `holds_player`, `walks`, `called_out`) and `core/systems/hail_system.gd`, its one
writer, between `DuelSystem` and `WildSystem`. IDLE looks only when no fight is on or
settling and no conversation is open; SPOTTED writes `hailed:<who>`, derives `hailed`, and
stands for the table's beat; COMING walks him through `Walkers` — `at`, `path`, `walked`,
exactly as `WalkerSystem` walks a man home, so both windows already draw him walking —
and `WalkerSystem` leaves alone a man the hail `walks`; ARRIVED derives `talk`; TALKING
waits for it to close; RETURNING sets his linger at once (a drill chosen in the talk
reaches the fight a step later and finds him standing there) and ends the hail after two
quiet steps. The budget gives up a walk that runs long. The player is held by a third
early return in `MovementSystem`; the wood waits; `DialogueSystem._open` refuses anyone
else while held; `called_out` is the store's phase for the speaker. Bram's hail line is a
draft marked `_p2` (O18). **The save test** round-trips the file's rows into stores given
the same hail row, because `SaveFile.read` builds from `places.json`'s list, which is
empty until O17 — the day it is filled, the same test can load through `SaveFile.read`.

### O17 · The hail, seen — and switched on — **built 2026-09-29**

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

**Built.** `hails` holds Bram's two rows. `view/world3d.gd`: the '!' is a `Sprite3D` of a
code-made 12×32 texture (the hearths' own ember, an ink rim), billboarded, unshaded, no
depth test, popping to 1.35 and back over 0.2 s along `_lens_up`; Bram faces the player
from the hail's `facing` outside his walk. `view/main.gd`: the keyboard is the hail's
while it holds the player (Escape alone opens the pause, and the held key is let go in
the log), the prompts are empty, the camera eases to the midpoint of the two of them,
the pack's `seen` cue sounds once, and the flat window draws the same mark as a bar and
a dot. The mark's age is the hail's own steps, so a photograph at a step shows what that
step shows. **One change the frames asked for**: `HailRules.approach` now ends beside the
player on the player's own row where it can — a man stopping north of you stood under
the birch his brother planted there, and the first photograph of the talk showed one
person. `UNCROWNED_HAIL=bram[:steps]` is written into CLAUDE.md, and `UNCROWNED_AT`,
`_TALK` and `_DUEL` spend the hail. Not yet played by hand: that is Yannick's.

### O18 · The fairy's words — **the drafts stand for this version** (Yannick, 2026-09-29)

Est. 3 h of wiring, plus his writing. Depends on: O12, O10.

His rewrite, French first, for a meeting among the graves — and his answer to SPECS
§5's *"one raising, in the forest"*. It keeps one fairy, once, her last word opening the
one quest, nothing in `SHE_MAY_NEVER_SAY` — and now **her gift, the spell**. If he changes
the seven facts, the tests move first.

**2026-09-29:** Yannick read the drafts (in English, his settings had flipped) and
validated them for this version: *« le texte pour le moment est validé »*. They keep
their `_p2` marks in the cast sheets, so a later rewrite finds every one of them.

### O19 · Bram, Wren, and the way on — **the drafts stand for this version** (Yannick, 2026-09-29)

Est. 4 h of wiring, plus his writing. Depends on: O17, O10.

The hail, each drill's instruction and transition, Wren's lines, a farewell that points
north along his road with no marker, the departure for the Cinderworks; Wren's
*"west of here"* fixed (the works are north on the baked map). The drafts from O1, O8,
O9, O10 and O16 are replaced — they are marked as drafts so none ships.

**2026-09-29:** validated for this version with O18's; the `_p2` marks stay. What O21's
review finds wrong in them — Wren's direction among it — is fixed there.

### O20 · The first fifteen minutes, played headless — **built 2026-09-29** (with draft lines)

Est. 8 h. Depends on: O8 onwards, grown as each step lands; finished after O19.

`tools/play_opening.gd` and a SLOW `test_first_minutes.gd`: creation, the fairy, rest,
the path, the hail, the three drills, leaving and re-entering, the bridge wolves, the
works' gate — each stage with a budget at the world's pace and a stall watchdog that
names the stage; a replay and a save round trip equal at the end; a table of walking,
fighting and reading time per stage, and damage taken against 100 HP and against 30.
**Built from O8 with draft lines**, so stalls surface early rather than at the end. The
procedural world plays what it has and prints DEBT for the rest.

**Built.** `tools/opening_run.gd` (`OpeningRun`, played by `tools/play_opening.gd`) and
the SLOW `test/test_first_minutes.gd`: eleven stages, each walk with three times its
path at the world's pace plus thirty seconds before the watchdog names the stage; the
night a rest passes is left out of the table, because the person at the keys does not
spend it. **What the first run says** (2026-09-29, drafts in place): 72 s of walking,
32 s of fighting, about 56 s of reading — **under three minutes played fast**, against
the ten to fifteen the demo wants; and **at 30 HP the wolves before the bridge kill
you** — they take 30 in one fight, the drills' three mended before it. Both are S4's and
the words' to settle, not this tool's; it says them after every change. It must be run
again when O19's words are in.

### O21 · Photographs and a fresh-eyes review — **built 2026-09-29**

Est. 6 h, plus fixes. Depends on: O20.

> **Built.** Twenty-six frames in each language, zero script errors in any of them, and
> the review sub-agent's walk of the route: 38 findings confirmed, many of them the same
> defect seen twice, fixed in `O21 review: the lessons and what Bram says around them` and
> `O21 review: what the window shows around the opening`, beside three changes the frames
> asked for on their own — the player drawn through what hides him, Wren sending you
> north, and the graves' markers and the fires (O13b). The fixes a suite can see have
> tests: a partner who cannot fall, Bram's greeting after each lesson, the summon, the
> dialogue box's height, the fight's framing, the beasts' banners, the '!' readable on
> its first frame. **Three findings were ruled on and left** (Yannick, 2026-09-29): the
> fifteen minutes' length (*« durée parfaite pour cette version »*), the hundred hit
> points (*« point de vie parfait »*; S4 still settles them for the public build), and
> the wolves a player can walk round (*« oui parfait »*). The check is still Yannick playing it.
>
> **He played it the same evening.** One finding, and it is the combat tutorial: he could
> not shoot the bow, nothing told him why, there is no choosing a weapon, an arrow can
> always be dodged, and the magic drill was never reached. It is group **T**.

Twenty-six frames a language, printed by `tools/opening_frames.sh` — title, creation, the wake, the fairy, the
path, the hail, each drill's first turn and key moment, the banners, the journal, the
wolves, the gate, the map, the flat bake, the procedural start — in French and English.
Then the review sub-agent Yannick allowed walks the route for bugs, stalls and
incoherence. Each defect gets a failing test first where a suite can see it, and its
own commit. **The check is Yannick playing the fifteen minutes.**

### O22 · The documents say what the game is — **built 2026-09-29**

Est. 4 h. Depends on: O21.

> **Built.** CLAUDE.md's art rule carries the third exception (the markers and the
> fires), the tools the hail and the map, the DEBT and OFF counts as the runs print them,
> the state table and **the suites' real timings — 41 s fast, 91 s and 64 s all — which
> are a debt of their own**; SPECS §4, §5 and §10, COMBAT_V2's drills, QUEST_CINDERWORKS
> §6, V3's *The opening, redone*, MIGRATION_3D's Brindle row, POUR_SLOSINIO §12–13, the
> walkthrough's banner and duel.json's notes. §9b stays open: it waits on his brother.

CLAUDE.md (the art rule and the new marks, DEBT/OFF counts, the tools and their count,
the state table, the standing exception), SPECS §4, §5, §10, COMBAT_V2 (a section on
drills, the three actions), QUEST_CINDERWORKS §6, V3, MIGRATION_3D (the Brindle row, §9b),
POUR_SLOSINIO, the walkthrough, duel.json's notes.

**Not in this group: deleting the clearing** — its ring, its corridor, its tests. It
waits for Yannick's own OK. *(Given the same evening: T2.)*

---

## T — after his play: the bow redone, the gate's guards, the clearing out

> **Planned 2026-09-29 (evening)**, from Yannick's first play of the opening and his
> answers the same evening. **All ten are built** (2026-09-30; T7's rules with T5, its words with T8). Then P2, with him, then C2–C4.

**What he found, playing it.** *« Le tuto combat est imparfait. Je n'arrive pas à tirer
à l'arc et rien ne me l'explique. Pas de sélection d'arme. »* The player never had a bow:
the bow drill asked him to dodge Wren's arrows, and nothing said so. And the bow itself
is wrong: *« tel quel on peut toujours éviter une flèche. Que ce soit un ennemi ou le
joueur, si je décide de tirer une flèche elle part dans le cadre de l'action. Je tire, ça
tire. »* O9's arrow landed at the start of the archer's next turn, so the gap between the
shot and the landing was a dodge anybody could always take. The magic drill asks for the
bow's, so he never reached it. *« Rajoute du contexte et des explications si nécessaire.
Ça peut même être un peu scripté. »*

### His rulings, 2026-09-29 (evening)

| Question | Ruling |
|---|---|
| The clearing — its ring, its corridor, its tests | **Delete it** — T2 |
| C2–C4 | **Validated**, as one change, **after P2** |
| P2 | **A review and rewrite of every line of the demo, together, later.** Claude drafts, Yannick validates. It writes the Cinderworks' lines by state, and C4 deletes the old ones |
| The fairy at the new start | Confirmed on the wake frames: she stands one tile north of the wake tile, among the graves (`test_she_is_standing_there_when_you_wake`) |
| The royal city, the sawmill village | **Left as they are** for now: drawn, not read |
| The way to the king, invariant 7's replacement | Not now: the demo first |
| His brother | **A list of his tasks, one page in French, ready to send** — T3 |
| The funnel (W4) | Later |
| The spell's name | *Le don*, for now |
| Music | **Silence**, for now; C4 removes the pack's tables |
| What ties the works to the player | **The works was built with the wood of the forest the village stood in, and that is why Brindle was destroyed** (QUEST_CINDERWORKS §9) |
| The works' first allégeance | **6**, which `content/towns.json` already says |
| Attacking the gatekeeper | **Other guards come and must be fought, and the fight cannot be won** — T9 |

**Defaults taken, stated to him the same evening and not contradicted:**

- **A key to change weapon during your own turn, without spending the turn**: physical
  **U**, beside I and K — free in the input map.
- **Wren gives the player a bow** when the bow drill begins, and he keeps it
  (`you:the_bow`, a fact: a possession gate, legal under invariant 4).
- **An arrow lands when it is shot, on everybody's side**, if the target is within the
  bow's reach. No delay, no dodge, no dice. What balances it: **the bow cannot shoot a
  neighbouring tile**, and it costs less than the sword. An archer is answered by closing
  on him or by staying out of his reach.
- **The drills are explained step by step**, naming each key; the first turn may be guided.
- **At the gate, guards keep coming until the player falls.** Each one can be killed, so
  Pillar 3 (*nobody is made invulnerable*, SPECS §1) holds, and the fight still cannot be
  won. He chose it over a few very strong guards: *« parfait comme idée »*.

### T1 · The rulings written down — **built 2026-09-29**

Docs only: this group, P2's entry, CLAUDE.md's table, QUEST_CINDERWORKS §9.

### T2 · The clearing comes out — **built 2026-09-29**

> **Built.** Gone: the `clearing` point (places.json and the brief), the brief's
> `clearing_corridor` road, `Region.CLEARING` and its four constants, `scaffold_clearing`,
> the bake's ring-opening, the deep wood's and the ways' exemptions round it, the
> `CLEARING` terrain (and its rows in the art and sound tables), `WorldRules.holds`, and
> seven tests — the ring, the corridor, the stamp, the held ground's geometry, the wound
> stopping short of the fairies. **Kept, because it is not the clearing**: the fairies'
> held ground *as a number* (`held_ground`, `HELD_AT_START`), which the journal's wood
> row shows — it is the fairy's quest, and C2 decides it — and the works' wound, which
> no longer keeps clear of a ring. **The bake moved 219 tiles**, all of them the clearing
> and its corridor: 145 of clearing now forest, 74 of corridor road now forest or grass,
> one road tile a wall his ruin already drew; the wound did not move. Two DEBT lines
> went with it (baked: nine lines, ten debts, seven claims); the 2D map's counts are
> unchanged. 713 tests on both worlds. **A re-bake refuses old saves** (O4), so a run
> saved before this starts fresh.

Est. 4–6 h. Depends on: T1.

`Region.CLEARING`, the ring of thicket, its corridor, `scaffold_clearing` and their tests
— `test_the_clearing_is_ringed_by_wood_you_cannot_walk_into` and
`test_one_corridor_leads_out_and_only_one`, two of the eight DEBT claims, go with it.
**What reads `CLEARING` and is not the clearing is found first and given its own name** —
the felling's direction (`scaffold_wound`), the fairies' fire, the wood's quest — rather
than deleted by accident. Twenty-seven `.gd` files name it today.

**Check:** both suites green, the DEBT and OFF counts restated in CLAUDE.md; vendor,
bake, `--check`; the map's frame without it.

### T3 · A page of tasks for his brother — **built 2026-09-29**

> **Built** as `docs/TACHES_POUR_SLOSINIO.md`, in French, one page in six parts by
> priority: §9b first, then what he has not drawn and what stands in for it (the blow,
> the bow to come, the wolf, the graves, the fires, the '!'), the works' four open
> questions, the map's three gaps, the colour cast to look at with Yannick, and what
> waits beyond the demo's route. Published as a private page for Yannick to send
> (claude.ai/artifact/3Ec4bA919TjqaGnx8zeKZ9). **B0 keeps it current with the letter.**

Est. 1–2 h. Depends on: T2, because the thicket ring stops being his to plant.

In French, addressed to him, ready to send: what the demo needs from him and in what
order — §9b first (his compressed meshes; the first frame shows his cliffs bare), then
what the DEBT lines name as his (a grave, a beast, a blow, the northern bridge, the
furnaces' distance and the road), M3b's pieces and the 25 faces, M5's fill, B0's open
questions, and M3's colour cast to look at with Yannick. Kept beside `POUR_SLOSINIO.md`,
which stays the long letter.

**Check:** Yannick reads it and sends it.

### T4 · The fast suite, profiled — **built 2026-09-29**

> **Built: 41 s to 22 s** on the baked world (2D fast suite 18.5 s); `--all` 91 s to 61 s,
> and 64 s to 53 s on the 2D map; 716 tests, the counts unchanged. The profile is one
> flag now (`test_runner.gd -- --fast --profile`) and `tools/profile_parts.gd` times the
> common steps and a day by system. Three causes, none of them one test:
> - **`test_screens` built his whole 3D window** for tests that read only the HUD and the
>   fight's reading: about a second each, 9.9 s in all. The play screen takes
>   `draws_the_world = false` before `_ready`; 0.2 s. `test_world3d` still builds it.
> - **`Navigation` searched over Dictionaries** and asked `is_passable` per neighbour: a
>   walk across the baked world was a second. Flat arrays and a terrain table, the same
>   queue, the same order, the same refusals — 320 random trips on both worlds gave the
>   very same paths, 7 times faster, and `test_navigation` keeps the plain search to hold
>   it to. `Region.passable_kind`/`watched_kind` are the one list both read.
> - **Every step resolved the wolf packs' anchors again** (`Wild.standing`): now kept per
>   world. And the road is looked up once a step rather than once a traveller.
>
> **What is left is simulated days**, 0.44 s each, spread over the systems that run every
> step — the drawn walkers (travellers, the works' folk), the wolves' and the hail's
> looks. The slowest tests now are the ones that need days. Cutting further is the
> step's cost, not the tests'.

Est. 2–4 h. Depends on: —.

41 s for the fast suite, and CLAUDE.md says the profile is owed before the next group
adds a hundred tests — this one will. By suite and by test: what is paid more than once
(a world built per test, a file read per test, days simulated that a test does not need).

**Check:** the fast suite's time before and after, measured; both suites green with the
same counts.

### T5 · An arrow lands when it is shot — **built 2026-09-29**

> **Built, and it took T7's rules with it.** Taking the dodge away left the bow drill
> with a goal nothing could reach, so the drill's new rules came here rather than leave a
> commit with a lesson nobody can pass: Bram's bow line **gives** `you:the_bow` (a line
> may now give without teaching), the drill is **three arrows that land on Bram**, who
> comes at you (`goal: arrows`), and `DuelPlayer.BOW` plays it. The rest is as planned:
> `DuelRules.reaches`/`damage_with`/`reach_with`, `bow_min_tiles` 2 and `bow_damage` 3,
> `DuelFighter.weapon` in the fingerprint, the player's weapon read from his turn,
> `AIM`, `LOOSING`, `Duel.volleys`, `arrow_aimed`, `arrow_dodged` and *Esquivé* deleted,
> `SaveFile.VERSION` 3, COMBAT_V2 §9 amended. **Until T6 the keyboard picks the weapon
> for you**: K throws the sword at the next tile, otherwise the bow at anybody in its
> band. The window draws the arrow in flight from the archer to whoever she shot, loosed
> half way through the wind-up and landing with the blow (frames at steps 60 and 66 of
> `UNCROWNED_DUEL=drill:bow:N:bow`, which now hands you the bow). 717 tests green on both
> worlds, the counts unchanged.

Est. 6–8 h. Depends on: —.

The rules only. `AIM`, `LOOSING` and `Duel.volleys` go. A bow is a **reach band**,
`bow_min_tiles` (2: never a neighbouring tile) to `bow_reach_tiles` (6), for `bow_damage`
(3, under the sword's 5), all in `content/duel.json`. A strike with a bow lands on its act
step like a blow, through `_land`. The archer's rule keeps off and shoots. **The weapon
is part of the turn**: the player's `duel_turn` carries `weapon`, a bow only if he has
one (`you:the_bow`), the sword otherwise; the fighter carries it, in the fingerprint.
`SaveFile.VERSION` bumped. COMBAT_V2 §9 amended in place.

**Tests first:** an arrow at range lands on the step it is shot, and moving after cannot
avoid it; never at a neighbour; without the bow the player strikes with the sword
whatever he asks; with it, at range; Wren keeps off and shoots; a bow fight replays to
the fingerprint; the sword and the spell unchanged.

### T6 · Choosing the weapon, and seeing the arrow — **built 2026-09-29**

> **Built.** Physical **U** (`weapon` in the input map) changes the weapon in your hands on
> your turn — a proposal like the cursor, sent with the turn (`_submit_duel_turn`), and
> opening on what you last struck with; without a bow of your own it changes nothing.
> **K strikes with what you hold**, and a bow never reaches the next tile. The keys line
> is built from parts and says what K does with what you hold and what U would put in
> your hands: *K frapper · U prendre l'arc*, *K tirer · U prendre l'épée* — U only for
> somebody with a bow, I only with the gift. On your turn the reach ring is drawn **round
> the tile you chose, with the weapon you hold**, and a bow's is a band: its outer ring
> and a faint inner one round the tiles too close to shoot. The arrow in flight is T5's.
> Frames in French and English: the sword in hand, the bow in hand, an arrow flying, an
> arrow landing (`drill:bow` at steps 47, 153, 60, 66).

Est. 6–8 h. Depends on: T5.

Physical **U** switches the proposal between sword and bow during your turn — a proposal
like the cursor, since only the turn is an event. The HUD names the weapon in hand and
draws its reach: a ring for the sword, the band for the bow. The keys line names U. The
arrow is drawn flying from the archer to the target through the wind-up and lands with
the blow's spark and number; O9's aimed-tile marks go with the delay. Both languages.

**Check:** frames of the bow in hand with its band, an arrow in flight and the hit, in
French and English.

### T7 · The bow drill, redone — **built: its rules in T5, its words in T8**

Est. 4–6 h. Depends on: T6.

Wren gives the bow as the drill begins (`you:the_bow`, through the `gives` field the
fairy's gift uses). The drill: **land three arrows on Bram, who walks at you** — so it
teaches the reach (too far: step in), the band (too close: step back, or take the sword)
and U. Goal `arrows`; `dodged` goes. The magic drill still follows the bow's.

**Tests first:** the bow and PRESS pass; standing still with the sword fails at the cap
with nobody down; `drilled:bow` written once and replayed; the magic drill offered after.

### T8 · Every drill explained, one step at a time — **built 2026-09-29**

> **Built, and it found why the first round said nothing.** The card had three colours
> for four rows; every lesson begun by its line — every lesson in play — carries what the
> master said as its fourth, so the first round's HUD stopped drawing there: no *whose
> turn*, no keys. No test draws and no photograph began a lesson by its line, so nobody
> saw it. Every row now carries its own tone and size, and `UNCROWNED_DUEL=drill:…` begins
> with the master's line as the game does.
>
> The card is: the title, the count, **the steps, each naming its key** — *[x] U : prenez
> l'arc*, *[ ] Flèches : restez à deux cases de lui ou plus*, *[ ] K : tirez* — ticked when
> where you stand and what you hold make them so, the one you are on in ink; then **a hint
> that answers where you stand**, on your turn — too close for the bow, too far for the
> sword, the gift resting, or the key when he is in reach; off your turn, the lesson in a
> line; then what he said, broken into rows short of the middle of the screen
> (`Ui.wrapped`). The reading carries `choosing` and `nearest_apart`. `play_opening`
> passes the three drills, magic included: sword 8.3 s of fighting, bow 6.8 s, magic
> 6.3 s. Frames of each lesson's first turn and of the bow too close, in French and
> English. The lines themselves are still drafts, for P2.

Est. 6–8 h. Depends on: T7.

The drill card becomes a short list of steps, each naming its key and ticked when done —
*move (arrows), take the bow (U), shoot (K)* — with a hint that answers where you stand:
out of reach, too close for the bow, the spell not ready. Bram and Wren say the lesson
before each drill (drafts marked `_p2`, for P2). The first turn of each drill may be
guided. `tools/play_opening.gd` plays the three drills, magic included.

**Check:** `play_opening` passes all three; frames of each drill's first turn and of a
hint, in both languages; Yannick plays it.

### T9 · Attack the gatekeeper, and the guards keep coming — **built 2026-09-29**

> **Built.** The gatekeeper has a line that draws on him (*(Tirer l'épée contre lui.)*,
> a draft for P2): `fights: "self"`, because a stranger's trade is one sheet for every
> placing of it — and the strangers' lines are now read by the same reader as the named
> cast's (`Cast._option`), which had read them with half the fields. `content/duel.json`
> gains `reinforcements`, keyed by the trade of the one attacked (`DuelRules.trade_of`):
> for a gatekeeper, **a works guard joins at the end of every round**, on the free tile
> nearest the gate (`DuelRules.free_near`), while fewer than five stand. They come
> through the one-tile passage one at a time, which is what a gate is. Each can be
> killed, and **a works guard is a person** (`person: true`): killing one is a killing,
> with its deed. The fight is not won while more are coming; it ends when you fall or
> leave, and the gate stays shut whoever falls — it is a fact, not a man (`WardRules`).
> Seen: the guards are his traveller (they were drawn as wolves, being nobody the cast
> names), named *Garde de l'usine*; the fallen lose their bars until the beat, or the
> list ran down the screen. Measured with PRESS from (316, 208): a guard a round, five
> standing from round five, the player losing about ten a round — at 100 HP he falls
> near round fifteen. Frames at rounds 1, 3 and 6, French and English.

Est. 8–10 h. Depends on: T5.

An option to attack him — strangers carry no `fights` today, so their sheet learns it.
The fight is against him, and **a guard joins from the yard every round** (a number in
`content/duel.json`) for as long as it lasts: each one can be killed, and the fight ends
only when you fall or leave. The deeds and the witnesses are the ordinary ones. The
guards are his traveller. `DuelSystem` learns a fighter who joins mid-fight.

**Tests first:** the gatekeeper can be attacked; a guard joins each round; each can be
killed; the fight never ends *won*; leaving and falling end it as any fight does; a
replay to the fingerprint. **Check:** frames at rounds 1, 3 and 6.

### T10 · Photographs and a fresh-eyes review — **built 2026-09-30**

> **Built.** `tools/opening_frames.sh` now takes each lesson's first turn with the card
> and its hint, the bow in hand, and the fight at the gate: twenty-eight frames a
> language, zero script errors in all fifty-six, the player's save and settings put back
> as they were. The review sub-agent (stopped once by the session's limit, then resumed)
> walked the tutorial and the gate and confirmed seven defects, all fixed in two commits:
> **the gate** — killing the gatekeeper left his ward refusing a tile nobody was drawn on,
> so the works keeps the post manned (`OpeningRules.KEPT_POSTS`); a fight's moves ignored
> wards (`WardRules.shut_tiles`); the window offered the tile where a lesson's master
> watches; the gate tests stood inside the wall — and **the words** — Bram still spoke of
> the old bow lesson, « À Le portier des Forges », a too-close hint that sent you to a
> sword that does not count, « -0 », and *flèches* meaning both the arrows and the keys.
> SPECS §10, V3, COMBAT_V2 §9 and POUR_SLOSINIO §14 say what the game now is. One frame
> taken during the review drew a hint for a tile one to the right: a real key press
> reached the window while it was open on the desktop; retaken, it was right.

Est. 4 h, plus fixes. Depends on: T8, T9.

`tools/opening_frames.sh` updated for the new drills, both languages; the review
sub-agent walks the tutorial and the gate; each defect a failing test first where a
suite can see it. CLAUDE.md, V3, COMBAT_V2, SPECS §10 and POUR_SLOSINIO (the bow is
ours: his brother drew none) say what the game now is.

---

## V — the gate taken by force

> **Asked 2026-09-30 (Yannick), after group T.** It replaces T9's endless flow of works
> guards. **Built, V0–V5, 2026-09-30.** V6 (the quest's guards at the furnace) was asked the same day.

**His ruling.** *« Si on attaque le portier, des gardes aux alentours arrivent. On va dire
3. Ce sont des types d'ennemis que l'on peut retrouver dans la cité du château. Ils sont
très très forts et trop forts pour le joueur au début du jeu. Si par miracle le joueur
arrive à tuer le portier plus les trois gardes, alors il peut faire ce qu'il veut avec
les fours. En restant simple : s'il éteint les fours, alors d'autres gardes arrivent ; si
on allume les fours, Tom arrive et bagarre. »* And the bow stays as T5 made it: two to six
tiles, three points (*« parfait »*).

**So the gate becomes a third way in**, beside Tom's and Sena's: force. §4's spine holds
on it — *get in, face whoever stands in the way, act* — with the gate itself as the
getting in.

**Defaults taken, which he may overturn:**

- **The king's guards** are a new kind of fighter (*Garde du roi*), the castle city's, not
  placed anywhere yet but the gate's answer: **40 points and blows of 10**, where a man has
  15 and 5 — at 100 HP three of them kill the player in about four rounds, and each takes
  eight sword blows. Numbers in `content/duel.json`.
- The three **arrive together at the end of the first round**, on the free tiles nearest
  the gate. Until they have come the fight cannot be won; once all four are down it is.
- **Winning forces the gate** (`cinderworks:forced`): the ward opens, and nobody stands in
  the gateway any more. Losing or leaving leaves it shut and manned, as T10 made it.
- **Whatever he wants with the furnaces**, for somebody who forced the gate without taking a
  side: **a burning furnace offers to put it out, a cold one to light it** — richesse
  decides which burn, the window's own count. A side taken keeps its own act.
- **Who comes**: putting a furnace out brings **three more king's guards**; lighting one
  brings **Tom**. The act goes through only after beating the one who came **for that act**,
  as the spine asks.

### V0 · The ruling and this plan written down — **built 2026-09-30**

### V1 · Three king's guards answer the gatekeeper — **built 2026-09-30**

> **Built**, with one change the tests asked for: the guards came first from the yard,
> on the free tiles nearest the gate, and stood for ever behind the gatekeeper, who fills
> the one-tile gateway. His words were *des gardes aux alentours* — they now come **from
> round about**, three tiles from the player (`DuelRules.free_around`). *Garde du roi* /
> *King's guard*; « Au tour du garde du roi ». Frames at steps 150 and 400: three bars of
> 40, the player at 60.

Est. 4 h. Depends on: —.

`fighters.kings_guard` (40, blows of 10, a person), and a fighter's own `damage` row; the
gatekeeper's `reinforcements` become `{kind, from_point, after_rounds: 1, total: 3}`, the
endless flow and its cap gone. **Tests first**: three join at the end of round one and no
more; each can be killed; a king's guard's blow costs 10; the fight is won once all four
are down (played with G), lost when the player falls. **Check:** frames of the fight.

### V2 · The gate taken by force — **built 2026-09-30**

> **Built.** `SiteRules.FORCED` (`cinderworks:forced`) is written by `OutcomeSystem` when
> the fight against the gatekeeper is won — which is only once the three king's guards
> are down too — with a `gate_forced` event; `WardRules` opens with it, and
> `OpeningRules.KEPT_POSTS` now names the fact that empties the post, so nobody stands in
> the gateway once it is taken. A loss or a leaving forces nothing.

Est. 3 h. Depends on: V1.

Winning the gate fight writes `cinderworks:forced` (`OutcomeSystem`); `WardRules` opens
with it; the gatekeeper's post is empty once it is written (`KEPT_POSTS`). **Tests first**:
a win forces the gate and he is gone; a loss or a leaving does neither.

### V3 · At the furnaces, whatever you want — **built 2026-09-30**

> **Built.** `Region.kiln_index` and `kilns_in` count a place's furnaces in the order they
> stand, and the window now reads them from there. `SiteRules.burns` answers whether one
> burns — richesse's `lit_of`, the first N — and `quest_deed_at` takes the site and that
> answer: with the gate forced and no side, *éteindre* at a burning furnace, *rallumer* at a
> cold one; a side taken keeps its one act. One act, once, whichever it was
> (`SiteRules.works_story_told` — a fact read, and not named like a progress flag, which
> `test_wild` rightly refuses).

Est. 4 h. Depends on: V2.

`Region.kiln_index` in core — the order the window already lights them in, which then
reads it rather than counting on its own; `SiteRules.quest_deed_at` asks the site and
whether it burns: with the gate forced and no side, a burning furnace offers *éteindre*, a
cold one *rallumer*. **Tests first**: both offers on a forced run, by furnace; a side taken
keeps its one act; the window and the rules agree on which furnaces burn.

### V4 · Who comes, for which act — **built 2026-09-30**

> **Built.** `SiteRules.who_stops(deed, facts)` names who is sent: the foreman on Tom's
> side, Tom on Sena's; with the gate forced, **three king's guards** for a furnace put out
> and **Tom** for one lit. `FACED` now keeps who was faced among its sources, and
> `faced_for(deed)` asks for the right one on a forced run — beating Tom for a cold furnace
> does not let you put a burning one out unopposed; a Tom already dead sends nobody. The
> SLOW `test_forced_path` walks the whole of it from where the game begins — G, the
> gatekeeper and his three, the walk through the gate, the guards at the furnace, the
> act — and a replay rebuilds the same works. The fight moves you, so the walk goes back
> to the furnace before the act, as a player would.

Est. 4 h. Depends on: V3.

Reaching to put a furnace out brings three king's guards; reaching to light one brings
Tom. `FACED` remembers who was faced (its sources), and an act goes through only after
beating the one who came for it. **Tests first**: each reach brings the right fight;
beating Tom does not let you put a furnace out unopposed; both acts replay from the log.
**Check:** `play_opening`-style walk of the forced path headless; frames.

### V5 · Photographs, a review, the documents — **built 2026-09-30**

> **Built.** Frames in French and English of the fight at the gate, the gate taken
> (empty), a burning furnace offering *éteindre les fours* and a cold one *rallumer les
> fours*, the three king's guards at a furnace and Tom at another — through a new debug
> tool, `UNCROWNED_FACTS`, listed in CLAUDE.md. The review sub-agent walked the forced path
> and both sides and confirmed five defects, all fixed here with a test each: **Tom set
> down beyond the yard's wall**, two tiles off through it, and the fight never ended
> (`DuelRules.set_down` and `free_around` now only choose tiles that can be walked to from
> the player); **the west furnaces could be reached from the street through the wall** —
> older than V, and it undid the gate (`SiteRules.within_reach`: a tile beside the site
> within three steps' walk); **the guards beaten, then Sena's side taken, and Tom never
> came** (on a side, a `FACED` from the king's guards is nobody's); **« Garde du roi est à
> terre »** for all three (a band of one trade falls as a band, *Les gardes du roi sont à
> terre*); and the debug tool drew the gatekeeper in a taken gate (a post taken is empty,
> whatever else the facts say). 754 tests on both worlds.

Est. 3 h. Depends on: V4.

Frames of the gate fight, the forced gate, both reaches and their fights, in French and
English; the review sub-agent; QUEST_CINDERWORKS §3, §4 and §9, COMBAT_V2, V3 and CLAUDE.md.

### V6 · The quest's guards at the furnace: a sword and two bows, easy — **built 2026-09-30**

> **Built.** `works_guard` (10 points, blows of 3) and `works_archer` (8 points, a bow),
> people both; `SiteRules.QUEST_GUARD` leads them and is the one `FACED` remembers. They
> fall as a band, *Les gardes de l'usine sont à terre*. Chasing the archers moves the
> player, so the act is done from beside the furnace again, as a player walks back to it.

Est. 2 h. Depends on: V5. **Asked by Yannick, 2026-09-30**, answering V's first question:
*« Ces gardes font partie de la quête. Ils doivent être faciles à battre : 1 garde à
l'épée, 2 gardes archers. Ce mélange doit obliger le joueur à se déplacer. »* The king's
guards stay for the gate, their numbers kept (*« on les garde »*).

`fighters.works_guard` (a sword) and `fighters.works_archer` (a bow) — people, easy: fewer
points and smaller blows than a man. Putting a furnace out on a forced run brings one of
each kind and a second archer (`SiteRules.who_stops`). **Tests first**: the three who come;
both kinds weaker than a man; beaten, the act goes through; the archers shoot at range, so
standing still costs more than moving.

---

## L — the cast, told apart at a glance

> **Asked 2026-09-30 (Yannick), before P2.** *« Pour l'instant tous les personnages se
> ressemblent. Il faut que chaque type de personnage se reconnaisse du premier coup
> d'œil. »* Every person is his brother's one traveller — red hair, blue shirt, grey
> trousers, a brown bag — and the demo now puts six of them in one fight.

| Who | His direction |
|---|---|
| **The king's guards** (invincible) | Heavy, imposing armour: they must look plainly impossible to beat |
| **The quest's guards** (sword and bows) | Simple, light clothes: they must look beatable |
| **The ironworks' workers** | Working clothes of the ironworks |
| **The villagers** | Civilian clothes, distinct from the workers |
| **Bram and Wren** | A look of their own each, easy to know |

**The method, and the art rule.** It began as a fourth exception to the art rule, and on
the same day Yannick rewrote the rule: *« On peut dessiner tout ce dont on a besoin. Juste
on doit avoir une cohérence graphique. »* — we may draw what the game needs, in 2D and 3D,
as long as it is coherent with his brother's hand (`CLAUDE.md`, *Art rule*). The method
is the one that keeps it coherent: **his painting, recoloured**. A tool reads his
traveller sheet and moves each region of it — hair, shirt, trousers, leather, skin — to
another colour while keeping every value of his brush, so the shading stays his; pieces he
never drew (a helm, a cap, a hood, a hat, an apron, a beard, a sword, a bow) are painted
over him in his manner — his outline, his light, a painted grain — and measured on each
frame. Nothing downloaded. His files untouched. Written into `POUR_SLOSINIO.md` §15.

### L1 · The method, and a board of proposals — **built 2026-09-30**

Est. 4 h. The recolouring tool (`tools/draw_cast_looks.gd`, beside `draw_fight_frames.gd`),
its region masks tested against his sheet, and **one board**: every type side by side,
front and side, at the game's size and close up, in the game's light. **Check:** Yannick
picks or corrects each look from the board before any of it reaches the game.

> **Built.** The board was prototyped first and shown as
> `docs/frames/cast/L1_proposals.png`; Yannick validated every look (*« je valide
> tout »*), asked for **Bram's sword at his belt**, kept **the player exactly as his
> brother drew him**, agreed that villagers and workers lose the backpack, and made the
> colours and the pieces ours — then rewrote the art rule. The tool is the prototype in
> GDScript: `content/looks.json` holds thirteen recipes (the king's guards, **the watch** —
> the king's ordinary men, light, added so that heavy armour means *unbeatable* and
> nothing else — the works' guards and archers, three workers, four villagers, Bram,
> Wren) and who wears which; `view/cast_looks.gd` reads it for the window and the tool;
> `view3d/cast/<look>.png` is one sheet per look in his sheet's layout, his walk frames
> and our sixteen fight cells dressed alike (a flinch is dressed as its idle frame and cut
> as `draw_fight_frames.gd` cuts it). `docs/frames/cast/looks.png` is the tool's own
> board. `test_cast_looks` holds it: every look has a sheet his size and a recipe the tool
> can follow, his frames measure as the recipes assume, a look keeps his outline, and the
> room kept round his frames (8 px, above and beside, never below) reaches no neighbour.
> The three DEBT lines for what his brother had not drawn became watches.

### L2 · Each person wears their type's look — **built 2026-09-30**

Est. 4 h. A `look` per person and per fighter kind in the content, one sheet per look, read
by the window for walking, standing and fighting alike; the fight frames made for every
look. **Tests first**: everybody the demo shows has a look; a fighter's look follows his
kind; the window loads every sheet.

> **Built.** `World3d._figure(look)` dresses every figure the window makes — the cast by
> name, trade and place (`CastLooks.of_person`), the fighters nobody names by kind, the
> king's escort, the road's traffic and the towns' crowds as villagers, and the people
> who walk to the works as its workers. A look is loaded the first time somebody wears
> it: its sheet, his frames re-pointed at it (`CastLooks.frames_for`, built afresh so the
> player's are never touched) and his material handed it. The king's guards are drawn with
> a pixel a fifth larger, and stand on the ground because the window lifts a figure by
> the size it is drawn. **A fight's seat is not a man**: the same seat holds Bram in one
> fight and a guard in the next, so the fight's paint is handed the figure's own sheet
> each time it is worn. `test_cast_looks` holds who wears what (everybody the demo shows
> wears a look of the table, the works dress their own watchmen, a fighter's look follows
> his kind, every look is worn by somebody, a look's frames keep his frames' sizes);
> `test_world3d` holds the window (Bram, Wren, the gatekeeper, the escort a fifth taller,
> the player in none). **One cost, said plainly:** a sheet is 12 MB of video memory once
> worn, and a walk through the whole demo wears all thirteen — about 156 MB. The sheets
> keep his layout so that nothing about his frames moves; packing them tighter is a
> later saving if the Windows machine asks for it.

### L3 · The king's guards — heavy armour

Est. 4 h. Steel where his shirt and trousers are, a closed helmet over the hair, a dark
tabard; drawn a little larger than a man. Frames at the gate.

### L4 · The quest's guards — a sword and two bows

Est. 3 h. Light leather and cloth; the archers carry a bow on the back, so a sword and a
bow are told apart before either acts. Frames at a furnace.

### L5 · The ironworks' workers

Est. 3 h. Sooty working clothes and a leather apron. Frames in the yard.

### L6 · The villagers

Est. 3 h. Civilian clothes in two or three palettes, so a street is not one man repeated.
Frames in Brindle and the quarter.

### L7 · Bram and Wren

Est. 3 h. Bram older and plainer, Wren the hunter — a hood and a bow. Frames of the hail
and of each lesson.

> **L3–L7 built together, 2026-09-30.** L1's tool dresses every type at once, so what
> was left of each task was its check: frames of each type where the demo shows it,
> gathered on one page, `docs/frames/cast/in_game.png` — the king's guards at the gate
> (three in blackened plate round the player, the gatekeeper in the works' ochre), the
> quest's guards at a furnace (a sword and a bow, told apart before either acts), the
> workers outside the works, Sena in the quarter, Bram and Wren at the bow lesson and at
> the hail. **One change came out of looking:** at the game's size Tom's rust scarf and
> Sena's dark red one were the same colour, and the player is sent from one to the other;
> Sena's (`worker_c`) is pale linen now. The tool is deterministic — rebuilding changed
> that one sheet and no other.

### L8 · Photographs, a review, the letter — **built 2026-09-30**

Est. 3 h. The opening's frames and the works' in both languages; the review sub-agent;
CLAUDE.md, V3 and `POUR_SLOSINIO.md` (what is ours on his figure, and what he could draw
instead).

> **Built.** `tools/opening_frames.sh` took the opening in French and English — 56 frames,
> 0 script errors — and `docs/frames/cast/in_game.png` was retaken after the fixes below.
> V3 has *Everybody told apart*; `POUR_SLOSINIO.md` §15 and his task page say what is ours
> on his figure and what he could draw instead, fight poses included.
>
> **The review** (a fresh-eyes sub-agent, sixteen findings) and what became of each:
>
> 1. **Seen from the side, the weapon jumped between hands as he walked** — the hand
>    furthest ahead changes with the swing. The weapon hand seen from the side is now the
>    hand in front (the larger blob), and in a fight cell the one that moved. Fixed.
> 2. **Seen from the side, the bow crossed Wren's and the archers' faces** — his face
>    sticks out further than his fist. At rest and seen from the side the bow is slung on
>    the back, behind him; held out in a shot it is still in the hand. Fixed.
> 3. **The king's guard's blow thrown away from us showed a floating gauntlet** — the helm
>    uncovered where his hair had hidden the arm. What a fight cell moved is never erased,
>    a raised sleeve is recoloured like the rest of him, and the arm is laid again from the
>    shoulder to the fist behind the helm or the hood. Fixed.
> 4. **Nothing told a recipe edited from a sheet rebuilt.** A full run writes
>    `view3d/cast/recipes_drawn.json`; `test_the_sheets_were_drawn_from_the_recipes_as_they_stand`
>    fails when the content has moved on, and `test_a_frame_dressed_now_is_the_one_on_disk`
>    dresses two frames in memory (the tool's painting is static for it) and holds them
>    against the sheets — it caught a stale import on its first run. Fixed.
> 5. **Tests that could not fail.** Named people must be dressed by name and strangers by
>    trade, not by the villager fallback; the works' watchmen are found from their own
>    tiles; rooms are checked widened against widened and every frame's margin; our fight
>    cells are shown not to be widened. Fixed.
> 6. **Who wears what** — the king dressed as his guards, the king's guards unarmed, Bram
>    fighting with his sword sheathed, Kell the deserter in the king's red, Harry the
>    foreman dressed as a worker. **Yannick's to decide**; asked.
> 7.–13. **Docs**: V3's stale counts, CLAUDE.md's state table (V6, L3–L8), two claims in
>    the letter that were not true (his silhouette does change under a helm; his values are
>    scaled, not kept), the same face for everybody, fight poses in what he could draw, the
>    older sections of the letter pointing at §15, and the French made plainer. Fixed.
> 14. **Traces of the pack on the back.** The whole of the pack's box is repainted evenly,
>     buckle included. Fixed; a pixel or two can remain on two side-view walk frames.
> 15. **The flinch dropped what stood outside his rectangle.** The whole dressed cell is
>     cut and moved now. Fixed; the waist cut slicing a quiver or a pauldron is the cut
>     his own body takes, and stays.
> 16. **Loading.** Every look is loaded while the world is built rather than on first wear,
>     which was in the middle of the fight at the furnace; the marks over a head are lifted
>     over the taller figures. The 156 MB of video memory stands, as L2 says.

### After L8: Yannick's answers (2026-09-30)

> He answered the review's questions by number: **the king's own look is a task of its
> own, later** (he is outside the demo); **the king's guards carry a weapon**, *« bien
> sûr »*; **Bram has his sword in his hand** when he fights; **Harry gets a look of his
> own**; Kell may stay in the king's red; **his brother's task page is updated**; and
> **nothing downloaded — only drawings made here**. Three tasks follow.

### L9 · Armed: the king's guards always, Bram and the watch in a fight

Est. 2 h. The king's guards carry a sword in the hand, walking and fighting. Bram and the
watch keep theirs at the belt and **draw it when they fight**: a recipe may name
`fight_pieces`, the tool then draws a second sheet, `<look>_fight.png`, in the same layout,
and the window hands a fighter that sheet for the length of a fight. **Check:** frames of
the gate fight and of the sword lesson; tests that every fight sheet exists and that the
window hands it to Bram in a fight and not outside one.

> **Built 2026-09-30.** `kings_guard` carries a 52-pixel sword in the hand; `bram` and
> `watch` name `fight_pieces` — their scabbard stays at the belt and the sword is drawn —
> and the tool writes `bram_fight.png` and `watch_fight.png`. `World3d._sheet_worn(figure,
> true)` hands a fighter his look's fight sheet, which the fight's paint wears for the
> length of the fight; the same frames read it, so nothing else moves. A light square left
> in the middle of the back went too: it was the pack's buckle, kept as a hand.
> `test_the_armed_ones_are_armed`, the fight sheets in `test_every_look_has_a_sheet_the_size_of_his`,
> and `test_world3d` (Bram's sheet about the village and in a fight) hold it.

### L10 · Harry, the foreman

Est. 1 h. A look of his own, `foreman`: the works' colour darker, a coat and no apron, a
felt hat with a brim — so the man who comes to stop Tom's side is told from the workers he
watches. **Check:** a frame of him at the furnaces.

> **Built 2026-09-30.** `foreman`: the works' ochre darkened to a coat, no apron, greying
> hair, and the straw hat's piece made in felt (`"weave": false`, a brass band). Harry
> wears it; `worker_a` is back in the shift's pool. Framed at the furnaces, talking. There
> are now fourteen looks and two fight sheets, sixteen sheets in all — about 190 MB of
> video memory once all are loaded, which the window does while the world is built.

### L11 · His brother's task page, brought up to date

Est. 30 min. The page Yannick sent him (`docs/TACHES_POUR_SLOSINIO.md`, published) says
nothing yet of the new art rule or of the looks. Republished at the same link.

> **Built 2026-09-30.** Republished at the same link (version 3): the date, the new rule
> in its header, point 2 renamed *what we made ourselves* with the looks' row and its
> table's headings changed, a picture of the looks in play (`docs/frames/cast/in_game.png`),
> and the faces' line made true. The page is private until shared from its Share menu.

---

## A — who you are: the appearance chosen at creation

> **Asked 2026-10-01 (Yannick), before P2**, as part of the demo and its tutorial, with
> group E. The design and the advice are `docs/CREATION_AND_GEAR.md`. **Approved the same
> day, question by question.** Block 1 is finished and the game launched before group E
> begins.

### A1 · The options, settled on paper

Est. 1 h. `content/appearance.json`: six hair styles, eight hair colours, five skin
tones, four beards, six colours for the starting clothes, each with its recolouring
numbers; the default is his traveller. **Check:** Yannick's answers to the questions in
`docs/CREATION_AND_GEAR.md` written into it.

> **Built 2026-10-01.** `content/appearance.json` holds the five lists and the default;
> `docs/CREATION_AND_GEAR.md` records his eight answers, and the first weapon is a sword
> to pick up past the fairy rather than Bram's to give (E1, E2).

### A2 · His traveller, split into layers

Est. 5 h. `tools/draw_cast_looks.gd -- --layers` writes `view3d/layers/`: body (skin,
outline, eyes), trousers, feet, tunic, backpack, his hair — every frame of his and every
fight cell — plus the shaved head his hair hides. **Tests first:** the default layers,
stacked, give his traveller **pixel for pixel**; every layer has his sheet's size; no
pixel of a layer is one his shader throws away.

> **Built 2026-10-01.** `tools/draw_player_layers.gd` (it measures with
> `draw_cast_looks.gd`'s own functions) writes seven parts into `view3d/layers/`: `body`
> (his outline and eyes), `skin`, `trousers`, `boots`, `tunic`, `pack` (with its straps
> and belt) and `hair_spiky`; `view/paper_doll.gd` names them and the order they stack
> in. **A head under his hair** is painted into `skin` only where his hair was — wide
> enough to carry his ears, down the sides of his face to the jaw — so his traveller is
> unchanged and a short cut has a skull to sit on. The palest strands of his hair are
> told from skin by what surrounds them, and every dark line in his head that is not his
> face's is his hair's. `test_paper_doll`: his parts stacked are his traveller **pixel for
> pixel** in four walk frames and three fight cells; a head stands under his hair.
> `docs/frames/creation/layers.png` shows him restacked and without his hair. Each part
> sheet is small on disk (70 KB to 800 KB) because each is mostly empty.

### A3 · The paper-doll shader

Est. 4 h. One compositing function (`view3d/layers/paper_doll.gdshaderinc`) — layers in
order, live recolouring, the head gear's hair mask — in a spatial shader for the world
(with the fight's flash and tint, and the player's ghost) and a canvas shader for the
screens. The player is drawn by it in `view/world3d.gd`. **Check:** with the default
appearance the game's frames are the same as today's, side by side; both suites green.

### A4 · Hair styles and beards — a board first

Est. 5 h. Five new hair styles and three beards, painted from his own hair's texture by
new pieces of the tool, in every frame. **Check:** a board like L1's — every style and
beard in three facings, close up and at the game's size — for Yannick to choose or
correct before they go further.

### A5 · The appearance in the simulation

Est. 2 h. `create_character` carries the five choices; an `Appearance` store holds them;
`AppearanceRules` refuses what does not exist. **Tests first:** a run replays to the same
appearance; a save from before A5 loads as his traveller; an unknown style is refused
with the traits untouched.

### A6 · The creation screen, redone

Est. 6 h. Two pages: **Appearance** (the five choices, a large preview turning through his
four facings and walking, the figure at the game's size beside it) and **Talents** (the
four traits, as today), then Begin. Keyboard throughout, French and English, the same
`Ui` as every other screen. **Check:** frames of both pages in both languages; a choice
changes the preview on the same frame.

### A7 · Seen in play

Est. 2 h. The chosen appearance in the world, in a fight, through a save and a load.
**Check:** the opening's frames with a non-default player in both languages; both suites
green; the game launches and plays from the title to the works.

---

## E — what you carry: inventory and equipment

> Group A first (Yannick: *« termine le bloc 1 avant d'attaquer le bloc 2 »*). Design in
> `docs/CREATION_AND_GEAR.md` §4. **Proposed; waiting for his go.**

### E1 · The items, settled on paper

Est. 1 h. `content/items.json`: slot, protection, weight, weapon numbers, and the layer
each item is drawn with. Cloth tunic and trousers (dyed), walking boots, short sword (to
pick up by the graves, past the fairy), bare hands' numbers, Wren's bow; a leather cap and an ochre gambeson (the works' guards); a helmet, a
breastplate and leggings (the king's guards); a hood.

### E2 · The inventory in the simulation

Est. 4 h. An `Inventory` store; `equip` and `unequip` events; `item_gained` derived from
the start kit, from the sword picked up by the graves, from Wren's gift (the `you:the_bow` fact becomes the bow) and from a beaten
fighter's table. **Save version 5.** **Tests first:** a run replays to the same
inventory; nothing equips into the wrong slot; nothing is equipped during a fight.

### E3 · What equipment does in a fight

Est. 3 h. Protection off every blow taken, never below one; two heavy pieces cost one tile
a turn; **U** switches between the weapon slot and the bow slot, and an empty bow slot
cannot be switched to. **Tests first**, in `test_duel`: each rule, and the tutorial's
drills still pass with the start kit.

### E4 · The items' layers

Est. 5 h. Every item of E1 baked as a layer by the tool, from the pieces group L made —
the head gear with its hair mask. **Check:** a board of every item worn, three facings,
close up and at the game's size.

### E5 · The inventory screen

Est. 6 h. **Tab**: the player in the middle by the paper-doll shader, the six slots round
him, what he carries on the right with its numbers and the difference against what he
wears; equip and unequip. French and English. **Check:** frames in both languages.

### E6 · Seen in play

Est. 2 h. Equipment worn in the world and in a fight; the fight's card says the
protection; loot taken from the works' guards. **Check:** frames; both suites green; the
game launches and plays.

### E7 · Photographs, a review, the letter

Est. 3 h. The opening and the works in both languages; a fresh-eyes review walking
creation → equipment in play; `CLAUDE.md`, V3 and `POUR_SLOSINIO.md`.

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

[POUR_SLOSINIO.md](POUR_SLOSINIO.md) — **in French, addressed to him** — and, since T3,
[TACHES_POUR_SLOSINIO.md](TACHES_POUR_SLOSINIO.md), the one page that lists what he owes
the demo, which changes with it. Everything this
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

> **C2–C4 validated (Yannick, 2026-09-29, evening)** — as one change, after P2, which is
> after group T.

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

> **The order below is the one planned on 2026-09-18, kept for its reasoning.** It was
> followed through M, P, Q and F; J, K, W, O and S were added and built after it, and F
> was deleted in K6. What is left is CLAUDE.md's table: **group T**, then **P2** with
> Yannick (every line of the demo, the Cinderworks' lines by state among them), then the
> rest of C (C2–C4, as one change), S3 (a Windows machine) and S4 (a stranger), M3's
> acceptance, and B00 with Yannick. Its "63 hours, twenty-seven tasks" predates every
> group after F.

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
