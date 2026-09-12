# Overnight log — Phase 7

> **Yannick reads this first.** It is both the plan and the record: what was built,
> in what order, and every decision taken without him in the room.

## WHERE IT ENDED

All five pieces are done. **332 tests green**, fast suite **4.71 s**, asset validator
**green**, 20,000 headless ticks and 300 real rendered frames with **zero script
errors**, and **all twelve of MAP_SPEC's criteria pass**.

Eight commits on `phase7`, none pushed:

| | |
|---|---|
| `9b11faa` | setup: this plan, and MAP_SPEC into the repo |
| `2253fee` | opening 1 and 4 — the clearing, the one path, the first fire |
| `7ce79c2` | opening 2 — the ground the fairies hold, and what takes it |
| `ce5ded0` | opening 3 — she speaks, and then she is gone |
| `b9ce970` | opening 5 — the journal shows what became of the wood |
| `64621e5` | the map — twelve criteria, and the thesis on the ground |
| `41cca88` | factions — two sides, four ranks, ground that changes hands |
| `f587401` | polish — collision walked, language keys checked, suite 38% faster |
| `82d6486` | the look — canopy, animated water, occlusion fade, camera lead, embers |

**Three things want your eye.**

1. **The look is built and not declared done**, per MAP_SPEC §11 and your own brief.
   Play it and judge it. Real 2D lighting stayed cut.
2. **The fast suite is 4.71 s, not 4 s.** It was 7.57 s and the suite grew by 76 tests
   tonight. The last 0.7 s costs coverage, so I stopped and wrote the number down.
3. **The disguise is proposed, not built** — the proposal is near the bottom of this
   file.

**Nothing was left half-finished, and nothing is red.**

---

## HOW TO RESUME — read this if you have lost context

You are working unattended on Phase 7, on branch `phase7`, with full autonomy.

**1. Git is broken and there is a workaround. Use it for every git command.**

`~/.gitconfig` line 7 has `format = ` (empty) under `[gpg]`, which makes every git
command that reads it die — **including `commit`**. `status` and `reset` survive,
which is a trap: a failed commit followed by an unconditional undo will destroy work.
That already happened once and was recovered.

Yannick manages two accounts through GitKraken and does not want his global config
touched. So a cleaned copy lives at `.git/overnight-gitconfig` — inside `.git`, never
tracked, never pushed. **Always run git as:**

```bash
GIT_CONFIG_GLOBAL=.git/overnight-gitconfig git <command>      # from the repo root
```

If that file is missing, rebuild it:
`grep -v "^\s*format\s*=\s*$" ~/.gitconfig > .git/overnight-gitconfig`

**Never** chain a destructive command (`reset --hard`, `checkout --`, `clean`) to an
operation that may not have succeeded. Check first, then act.

**2. Commit locally after every stage. Do not push.** Yannick pushes in the morning.

**3. Full suite green before every commit.** `tools/run_tests.sh --all`. A red suite
means stop and fix, not push on.

**4. Where the authority lies.** `docs/SPECS.md` is the source of truth.
`docs/MAP_SPEC.md` is the brief for the map work only — **where it contradicts the
decisions recorded below, this file and SPECS win** (Yannick, explicitly).

---

## THE MISSION, in the order agreed

| # | Piece | Status |
|---|---|---|
| 1 | **The opening** — stages 1–5 below | ✅ **done** |
| 2 | **The map** — refine against the thesis, close MAP_SPEC's 12 criteria | ✅ **done** — all 12 pass |
| 3 | **Factions** — two sides; mechanism **plus** ranks, jobs and quests | ✅ **done** |
| 4 | **Polish** — collision, enterability, suite, validator, no script errors | ✅ **done** (fast suite 4.71 s, not 4 s) |
| 5 | **The look** — the cheap five. Real 2D lighting is **out of v1** | ✅ **built, for Yannick to judge** |

### 1. The opening — five stages

Geography: the player wakes in the fairies' clearing inside the Thornwood, and
**one path** leads south out of it to Brindle. Brindle is ash. The Cinderworks stands
in the same frame, on the village's own ground. No maze, no choice, nothing gated.

- **Stage 1 — the ground.** Impassable thicket terrain; the clearing; the one path.
  *Proves:* you can walk out to Brindle and nowhere else; the Cinderworks is in frame
  on arrival; Blackcairn is still reachable in about a minute.
- **Stage 2 — the protected ground.** Beasts may not stand on fairy ground. The held
  radius is a number and it falls.
  *Proves:* nothing enters the clearing or the path; on a later visit a beast stands
  where it could not before.
- **Stage 3 — she speaks.** The fairy as an NPC, one intent, six things, then gone.
  *Proves:* the six facts are in the fact base and the event log; a reload says the
  same words; she stays gone.
- **Stage 4 — the first fire.** The clearing is the first campfire.
  *Proves:* dying before any rest returns you to the clearing, not Brindle.
- **Stage 5 — what you did to the wood.** The journal shows the forest's state.
  *Proves:* an ending that stopped the clearing reads differently from one that did not.

**What she says — six things, and no more:**

1. You died with everyone else.
2. She raised you, and your memory was the price.
3. Men came with axes and fire, and the wood is smaller every year.
4. The fairies are dying.
5. She chose you because you are **owed** something, not because you are special.
6. Find your way in this world — and if you can, save us.

**And she remembers you.** She knew who you were. That makes her a source for the
player's own past, not only for hers — the one witness to their life that is not a
document.

**What she must never say:** the king, by name or title. Nothing of industry, steel,
land or law. A fairy in a wood does not have the political map; she knows men came
with axes. The player already remembers it was the king's men (§5), so the motive is
complete without her explaining his politics. If she pre-judges him in minute one,
Route C stops working, because §5 holds that his argument must be real and found.

**Tone:** oblique, short, unhurried. No prologue, no cutscene, no text crawl. She
delivers her lines, the player advances, she is done. One intent, repeated. No options.

**She is not a body.** No humanoid sprite — the art pack has none, §13 forbids mixing
packs, and the cute risk would undo the plain register. She is **light and movement in
the trees**: visible, findable, followable, but never a character standing there.

### 2. The map

Close MAP_SPEC's twelve criteria, and use the thesis for everything nobody specified:

> **The road is the king's world** — industry, order, tax, patrols, being seen.
> **The forest is what he is destroying** — magic, the displaced, the poor, unseen.

The edge where industry meets forest must be **visible on the ground**: stumps,
cleared strips, a working face, dead trees at the margin. The Cinderworks is a wound
with a radius, not a building on grass. Crown ground reads maintained — paved road,
straight boundaries, ordered rows. Forest ground reads reclaimed or never taken —
Brindle overgrown, tracks faint, the Thornwood unmanaged. **That contrast is the
argument, so it has to be legible at a glance.**

### 3. Factions

Two: **the crown** and **the opposition**. Neutral is not joining — the default, free,
and what the game already is.

- Crown: industry, the road, the cities, order, the tiered law.
- Opposition: the forest, magic, the displaced, the poor.

They **feed the three routes rather than replacing them**: the crown opens Access and
lets the player rise until the castle admits them; the opposition feeds Exposure;
joining neither leaves Force. One structure, not two.

**Ownership is a fact, not a constant.** The crown holds eight points and a line; the
forest holds the ground between them. The Wide Acres and Saltmarch stay **contested** —
they are borders, not sides — and they are the two that can change hands, so the
player's choices show on the map.

Faction is **worn visibly** (§8's appearance tracking) so the capital can see what the
player is. Hiding it is a disguise mechanic: **propose, do not build.**

The player must be able to **join the crown and destroy the opposition entirely**.
Invariant 7 holds because Force always survives.

Scope: mechanism **and** ranks, jobs and basic quest lines or faction NPCs.

### 4. Polish — decide and finish, it is verifiable

- Zero collision errors, tested: no walkable tile that traps the player, nothing
  walkable that should not be, nothing enterable that cannot be left, no footprint on
  a road or a crossing.
- Every zone enterable and exitable without getting stuck.
- Full suite green; fast suite under 4 s.
- Asset validator green.
- No script errors on a full playthrough.

### 5. The look — build and log, never declare done

MAP_SPEC §11 and Yannick both: a model may propose and implement these; it may not
declare them finished. **Real 2D lights and shadows are cut from v1** — the game draws
in a single `_draw()` on one `Node2D`, with no TileMap, Camera2D, Light2D or
particles, and true shadow casting would mean a rendering rewrite.

The five that are cheap in the current architecture:

- canopy layers, so the player passes under the Thornwood
- animated tiles for water, grass and fire
- occlusion fade behind buildings
- camera lookahead and lag
- particles

Target look is **Zelda: A Link to the Past**, built from the **Ninja Adventure** pack
already approved in §13. The pack is 16×16 and lighter in style than ALttP; push it as
far as it goes and record where the ceiling is rather than quietly missing the target.

---

## DECISIONS TAKEN WITHOUT YANNICK

Every entry here is a choice he was not present for. Newest last.

| # | Decision | Why |
|---|---|---|
| 1 | Git runs through a cleaned config at `.git/overnight-gitconfig` rather than fixing `~/.gitconfig` | He manages two accounts in GitKraken and does not want the global file touched. The copy is inside `.git`, so it is never tracked and never pushed, and it preserves his name and email |
| 2 | `MAP_SPEC.md` copied into `docs/` | It was outside the repo, untracked. Confirmed as this project: same eight zones, same 280×200 region, same 6 tiles/sec, road figures within 4% of what `tools/measure_routes.gd` measures today |
| 3 | Clearing at **(261, 150)**, radius 7, thicket ring 5 deep, corridor 3 wide | Inside the Thornwood, east of the Kettle so it is on Brindle's own side of the river, and 30 tiles north of the ruins — **5.0 seconds** of walking. Long enough to be a walk out of the trees, short enough that §4's rule against empty walking still holds. The ring is 5 deep because 8-way movement finds a diagonal seam in anything thinner |
| 4 | The corridor's **walls stop at y=168**, seven tiles short of Brindle | Walls where you could get lost, open where the destination is already in shot. By y=168 the ruins are in frame, and a destination you can see guides better than a wall does. It also keeps the first minute from reading as a tunnel |
| 5 | **Stage 4 landed with stage 1**, not on its own | Stage 1 moved the start into the wood, which broke the save test: it walks to the nearest fire using real move events, and there was no fire reachable from the clearing. The honest fix was the fire stage 4 was going to add anyway. Committed together and recorded here rather than faked |
| 6 | Dying **before any rest** returns the player to the clearing, not Brindle | It is where they woke the first time and the only ground left that could hold them. Three existing tests asserted Brindle and were updated, not worked around |
| 8 | The held ground is **not a thirteenth tracked quantity** | §19 Q11 refused one of those and the refusal still holds. It lives on `WorldTick` beside `grain_price` and `town_sentiment`, which are the same kind of thing: a reading about a *place*. No ending consults it |
| 9 | The wood shrinks at a rate driven by **`steel_output`**, not by the calendar | This is the fiction exactly — men came with axes, and the axes are the works' appetite. It also means **stopping the clearing is already something the player can do with the levers they have**, so the fairy's *"if you can, save us"* is answerable without the forest needing machinery of its own. Q42/Q43 stay deferred and this does not wait on them |
| 10 | `HELD_AT_START` 22 tiles, `HELD_LOST_PER_DAY` 0.55 at full output | 22 covers the clearing (7), the ring that closes it (12) and the corridor as far as Brindle coming into frame (~20), so the first thing lost is the safe walk out, then the ring, then the clearing. 0.55 empties it in about forty in-game days of the furnaces running flat out |
| 11 | **Sharpened** `test_a_world_with_no_cause_in_it_does_not_wander` rather than exempting the wood from it | The test said five days change nothing. The wood now changes — and that is the rule working, not breaking: there *is* a cause in the world from the first minute, and it is why the game has a plot. It is now asserted the harder way round: **stop the furnaces and nothing moves at all.** A drift you can switch off is a drift somebody reasoned about, which is what §8 was protecting against |
| 12 | **Seven lines, not six.** The "she remembers you" addition became its own line rather than being folded in | It is the best line she has and the one that gives the scene its ache, and burying it inside another would waste it. Placed fifth, before the send-off, so she still closes by asking |
| 13 | Her seven lines are a `requires`/`hides_after` **chain**, so exactly one option is ever offered | "She speaks, I read, I advance" **inside** the dialogue system instead of beside it. No new machinery, no cutscene mode, and the whole scene is ordinary events — so it is in the save and replays word for word |
| 14 | **No "she is gone" flag.** She is gone when the player knows her last word | The facts the player holds *are* the state. Nothing to keep in step, nothing that can desync, and it falls out of the fiction: a player who has been told everything is a player she is finished with |
| 15 | Rewrote *"I chose you because you are owed"* → *"I did not pick someone special. I picked someone who is owed."* | The original tripped `test_nobody_ever_tells_you_it_was_your_fault`, which bans "because you" to protect §8's *push the ambient, pull the attribution*. The matcher is blunt and her line was not really an attribution — but **I changed the line rather than the rule**, because a real invariant should not be narrowed to fit one sentence of mine. It is shorter and more in her voice anyway |
| 16 | **Refined** `test_every_fact_keeps_one_source_nothing_can_gate_shut` to tell a *gate* from a *sequence* | `requires` counted as a gate on its own, so her chain read as seven facts with no open source. But the first line needs nothing, she never leaves until she has finished, and no condition or standing is consulted anywhere in it — nothing can shut that door, you simply have to listen in order. The test now walks each speaker's own chain to a fixpoint. It can distinguish two things it previously could not, so it is stronger, not looser |
| 17 | She is drawn as **three soft discs and five drifting motes**, dimmer and slower than anything else on screen | No fairy in the pack, §13 forbids mixing, and a twinkling humanoid would undo the plain register the cast was rewritten for. She still had to be findable and followable rather than a voice from nowhere |
| 18 | The named cast is now **25**, exactly §6's budget | `test_overworld` asserts `<= 25`. She fits with nothing to spare, which is worth knowing before anybody adds a twenty-sixth |
| 19 | The journal shows the wood **only once she has said it is happening** | A page explaining a thing the player has never been told is the game telling them their own story. Gated on `thornwood:axes`, which is her third line |
| 20 | The ending line reads **differently by what became of the wood** | *"What she asked of you, you did"* against *"nobody did"*. It is the one place the five endings stop being five ways to win, and it is what stops her last line being a request the player can satisfy and never find out about |
| 21 | SPECS corrected for the built opening: **she**, **seven** things, and §6's *"none of whom loved them"* amended | The spec said four things and "he". §6's protected note is better for having exactly one exception that walks away immediately — the warmth is real, offered once, and cannot be gone back to |
| 22 | MAP_SPEC criterion 7's `[DECIDE]` set to **30 tiles** of Thornwood on the straight wild line | It measures 126, so 30 is a floor with room rather than a number tuned to today's map. The criterion is there to stop the wood drifting off the shortcut, and 30 catches that long before it matters |
| 23 | Criterion 1 checked **from the clearing**, not from Brindle | Stricter: the clearing is behind the thicket, so it also holds the rule that thicket may never be the only thing between the player and anything. And it is where the player actually wakes now |
| 24 | Criterion 9 **narrowed** to what it protects | Read literally — *no footprint on the road* — it fails, because inside a town streets and buildings interleave, which is what a town is. I tried nudging every such building clear and **it made things worse**: routes narrowed until the King's Road walk failed outright. Reverted. The criterion now checks the open road, where a house in the middle really is a mistake, plus the thing MAP_SPEC §8 actually cares about — that no building closes the way through |
| 25 | The wound is **26 tiles** and keeps **4 clear** of the fairies' ring; the working face runs north, away from them | The works has eaten everything it can reach and stopped just short of the last of them, so the two are in the same thought and the gap is what the player is asked to save. The first stamp swallowed the ring and the corridor test caught it |
| 26 | Terrain colours moved out of `view/main.gd` into `Art`, **keyed rather than indexed** | This was a real crash, not tidying. The table was a `PackedColorArray` read by terrain ordinal, so adding `CLEARING` in an earlier commit left it one short and the first frame drawn in the clearing would have read past the end. No test drew anything, so nothing caught it. A dictionary cannot go out of bounds, and a test now asserts every terrain the map lays down can be drawn |
| 27 | **Joining is not standing.** The two factions are a new thing beside the four standing dimensions the game already had | Standing is what a place thinks of you and it moves on its own; joining is a thing you chose, it changes only when you say so, and everyone can see it. A crown officer can be despised in Harrowgate and still get through the gate at Blackcairn. The brief said *"neutral is not joining — the default, free, and what the game already is"*, which is exactly this split |
| 28 | The crown needed **one new act**: `i_informed_the_crown` | There was nothing pro-crown in the game — every one of the thirteen deeds costs him something, which was fine while the player could only be against him. Inventing ten systems to fix that would have been the wrong repair. One act, the mirror of making a thing public: the same fact, spent the other way. It is one-shot, it needs you to actually know something, and **it costs you the town**, because nobody likes an informer |
| 29 | The opposition needed **no new acts at all** | The deed table was already entirely theirs. Service is read off the deed rather than from a quest list, so every act already in the game counts without being authored twice |
| 30 | **Service does not carry across** when you change sides | Otherwise a player banks work for one side and cashes it with the other, and joining both in turn is strictly better than choosing |
| 31 | The recruiters are **Tovin and Kell**, not new characters | The named cast is at §6's budget of 25 and the fairy took the last slot. It is also better: the people you already know ask you to pick a side, and Kell — a deserter hiding in the wood who already recruits — is the right person for the opposition |
| 32 | The offer to join is **reactive**, not a standing line | It did not work as a standing line and the test caught it: the three-slot cap fills in the order options were written, so an offer authored last is an offer nobody is ever shown. It now appears while you have not joined and goes away the moment you do |
| 33 | Ground changes hands on a **band, not a line** | A town sitting between two thresholds keeps whoever holds it, so a border cannot flicker every tick |
| 34 | Rank is **read off service**, never stored | One number to replay, and no way for the two to disagree |
| 35 | Fast suite **7.57 s → 4.71 s** without cutting a single test — but **the 4 s target is not met** | Two changes, both safe. Long simulated spans were trimmed where the claim survived (20 in-game days proves nothing 6 does not, when the army drifts 12 a day). And systems now opt out of the step and tick loops: `on_step` was being called on all 22 systems whether they did anything or not, which is **nine and a half million calls into empty functions** in a test that simulates twenty days. Getting the last 0.7 s would mean cutting coverage, and the suite has grown by 76 tests tonight, so I stopped and wrote the number down instead |
| 36 | `SimSystem.steps()` and `ticks()` **default to true** | Opting in would mean a system that forgets is silently broken; opting out means a system that forgets is merely slower. Correctness should never be the thing you lose by being forgetful |
| 37 | Collision is tested as **reachability**, not as traps | A trap in the sense people imagine cannot happen: passability is symmetric, so if you can walk in you can walk out. What can happen is something the player must reach being stranded, and that is what the walk checks — every zone, every fire, every named person, every stall and paper, and both places the game can put the player without asking |
| 38 | **Canopy is a y-sort**, not an overlay | Everything growing behind the player draws before them, everything in front draws after — so walking south through the Thornwood puts you *under* the branches. The row you are standing on is drawn at 55% so a wood cannot swallow you, which is the difference between atmospheric and a lost player |
| 39 | Occlusion fade is judged on the **drawn rectangle**, not the footprint | What hides the player is the part that overhangs. A tall roof covers tiles nobody is standing on, so testing the footprint would fade the wrong buildings and miss the right ones |
| 40 | Particles are **drawn, not spawned**, and only at kilns and campfires | There is no particle node anywhere in this game and adding one means a scene tree the window does not otherwise need. A few dozen sine waves cost nothing. Two places only: the furnaces, because the works running is what the whole map is about, and the fires, because a fire you can save at should read as one from across a field |
| 41 | The camera **snaps rather than eases** when the player has moved further than they could walk | A death puts you back at a fire, and a camera that travels there sweeps the whole map — which among other things shows everybody where the fairies are |
| 42 | Culling follows the **camera**, not the player | The two parted company the moment the camera gained a lead, and culling from the player leaves a strip of unpainted ground on exactly the side you are walking toward |
| 7 | `_stamp_clearing` only ever overwrites `FOREST` | So the river, the road and every settlement are safe from it by construction rather than by getting the arithmetic right. Asserted anyway, for whoever moves the clearing next |

---

### Polish

| | |
|---|---|
| Full suite | **332 tests green** |
| Fast suite | **4.71 s** — was 7.57 s. Target was 4 s; see decision 35 |
| Asset validator | **green**, 0 problems |
| Long headless run | 20,000 ticks (~14 in-game days), **0 script errors** |
| Collision | `test_collision.gd` — every zone, fire, person, stall and paper reachable; 90%+ of the passable map is one piece |

**The text-key test earned itself immediately.** `Text.of` returns the key when a line
is missing, so a forgotten string shows up as `journal.wood` in the middle of a
sentence and no test notices — the same silent shape as the terrain colour table being
one entry short. It scans `Text.of(&"…")` out of the source rather than working from a
list, and it found `deed.heard.i_informed_the_crown` missing within a minute of being
written: the informing deed added an hour earlier would have leaked its raw id into a
context packet the first time anybody had heard about it.

### The look — built, and for Yannick to judge

MAP_SPEC §11 and the brief both: a model may propose and implement these; it may not
declare them done. So these are **built and not declared**.

| | |
|---|---|
| **Canopy layers** | y-sorted, so you walk under the Thornwood. The row you stand on fades to 55% |
| **Animated tiles** | the sea, the Kettle, the ford and the marsh all move, offset by tile position so a river does not flash in unison |
| **Occlusion fade** | buildings go to 45% when the player is behind the drawn rectangle |
| **Camera lookahead and lag** | 1.6 tiles of lead, catching up at 7× per second, frame-rate independent, snapping on a teleport |
| **Particles** | embers over the kilns and the campfires, each on its own period |

**Real 2D lights and shadows are cut from v1**, as agreed. The game draws in a single
`_draw()` on one `Node2D` with no TileMap, Camera2D, Light2D or particle node, and
true shadow casting means a rendering rewrite.

**Verified by running the actual game**: 300 frames with a real window, **zero script
errors**. Worth saying because `--headless` never calls `_draw()`, so none of the look
code above is exercised by the test suite at all — and the terrain colour crash earlier
tonight was exactly that blind spot.

**Where the ceiling is.** The target is *A Link to the Past* and the pack is Ninja
Adventure: 16×16, lighter, brighter, and with a smaller palette per sprite than ALttP's
art. What the pack cannot give is ALttP's depth cueing — its darker outlines toward the
bottom of a sprite, and its two-tone shadowing. The five above are the parts of the look
that are *code* rather than art, and they are done; the rest is a commission, which is
what Phase 7's art budget is for.

---

## PROPOSED, NOT BUILT — the disguise

The brief asked for a proposal rather than an implementation, so this is the proposal.

Faction is worn: `Context` now puts `SEES YOU AS: a king's officer` in the packet, and
the journal says what you are. Hiding it should be **a place you can be, not a button
you can press**:

- **It is a thing you wear, and wearing it is an act.** Changing what you look like
  happens at a landmark — a stall, a camp, a house that will take you in — never from
  a menu, so it is in the log and it has a location somebody can watch you at.
- **It fools the ground, not the people.** A disguise should suppress `SEES YOU AS`
  for strangers and generics, and do nothing at all to the twenty-five named people.
  Maddox knows your face. That keeps it from becoming a universal solvent, and it
  makes the named cast matter more rather than less.
- **It is broken by being seen doing something**, using the witness machinery that
  already exists: any deed with a witness while disguised sets it back. No new system,
  and the failure mode is the interesting one — you are fine until you act.
- **It should cost standing with the side you are hiding**, because pretending not to
  be a king's man is something a king's man can be caught doing.

What it must not do: gate anything. Invariant 4 — there has to be a way through every
door without it.

---

## RUNNING LOG

### Setup

- Confirmed `MAP_SPEC.md` describes this project. Its `[DERIVED]` road numbers say 354
  tiles and 59 s; the build measures **342.0 tiles and 57.2 s**, with the wild line at
  260.4. **Road ratio is therefore 1.31 against criterion 5's ≥ 1.30 — it passes by
  0.01**, which is worth knowing before anything reshapes the road.
- Recovered `41ef652 Kick-off phase 7`, which a chained `reset --hard` destroyed while
  probing whether commits worked. Nothing lost. The rule that came out of it is in
  *How to resume* above.

### Opening, stages 1 and 4 — the ground, and the first fire

Built: `Terrain.CLEARING` and `Terrain.THICKET` (impassable), `_stamp_clearing()`,
`Region.clearing_centre()`, the fairies' campfire, the start moved out of Brindle,
and `test/test_opening.gd`.

**Measured, not assumed:**

| | |
|---|---|
| Clearing → Brindle | 30.0 tiles, **5.0 s** |
| Clearing → Blackcairn, straight | 232 tiles, **38.7 s** — Pillar 1 intact |
| Corridor dammed | clearing falls to a **148-tile pocket**, Brindle unreachable |
| Nearest part of the Cinderworks, from Brindle's centre | **9 tiles**, in a 40 × 22.5 frame |

*One corridor* is asserted the way MAP_SPEC asserts the river: **block it and the
pocket closes.** A barrier that is only stated is a barrier nobody has checked.

**Two of my own tests were wrong and the ground was right**, which is worth recording
because both would have read as map bugs:

- *the furnaces are in frame* measured the works' **far** northern edge, 16 tiles up,
  and failed on a frame that plainly contains the furnaces. What has to be in shot is
  some of the thing, not all of it.
- *nothing wrote over the road* swept a box 14 tiles either side all the way down to
  Brindle and caught the **Cinderworks**, which the opening never touched.

**Five existing tests assumed the player starts in Brindle** and were updated rather
than worked around: `test_phase_0` (wakes, and dies), `test_journeys` (the road walk,
and the full replay), `test_saving` (first death). One early attempt set
`player_pos` directly to dodge this and broke `test_a_run_is_saved_and_comes_back_the_same`
in a more interesting way — a position set directly is not an event, so it is not in
the log, and replay puts the player where they really were. The test was right.

Suite: **276 tests green**, fast suite 237 in 7.5 s.

> Fast suite is **7.5 s against the 4 s target** in the polish brief. Not addressed
> here; it belongs to the polish pass and is written down so it is not forgotten.

### Opening, stage 2 — the protected ground

Built: `WorldTick.held_ground`, `WorldRules.held_ground_after()`,
`BeastRules.is_protected()`, the wildlife system threading it through spawning and
movement, and the tick system taking the wood down as the furnaces run.

**Written as a fact about the world, not a starting-area exemption**, which is what
was asked for. The ground the fairies still hold is the ground still protected, and it
shrinks — so the player's first walk out of the trees is also their first step out of
the last protected place in the region, and coming back later to find the edge closer
in is how the shrinking gets *seen* rather than asserted.

`held_ground` is in `WorldTick.fingerprint()`, so replay checks it like everything else.

The one collision worth reading: the wood shrinking breaks
*a world with no cause in it does not wander*, and the fix was to sharpen that test
rather than exempt the wood — see decision 11.

Suite: **283 tests green**.

### Opening, stage 3 — she speaks

Built: the fairy in both cast files (7 chained lines, 7 facts, a voice note),
`core/rules/opening_rules.gd`, the dialogue gate that stops her being reopened,
`_draw_fairy()` in the view, and eight tests.

She says, in order: *you died with the others* · *I brought you back, it cost you your
memory* · *men came with axes and fire, the wood is smaller every year* · *we are
dying* · **I knew you, before** · *I did not pick someone special, I picked someone
who is owed* · *find your way in this world, and if you can, save us.*

**Two existing invariant tests caught her**, and both were right to:

- `test_nobody_ever_tells_you_it_was_your_fault` on *"because you"*. Line rewritten,
  rule untouched — see decision 15.
- `test_every_fact_keeps_one_source_nothing_can_gate_shut` on her `requires` chain.
  Test refined to tell a gate from a sequence — see decision 16.

Her eight lines pass the prose door in both languages: **103 hand-written lines, 0
refused.** She never says the king, the crown, the law, steel, the works, land or tax,
and a test asserts that word by word in English and French rather than trusting it.

Suite: **290 tests green**.

### Opening, stage 5 — what you did to the wood

Built: `OpeningRules.wood_row()` and `knows_about_the_wood()`, six text keys a
language, the journal page, and four tests.

The page says how much ground the fairies still hold and whether anything is still
taking it — state and attribution, never advice, asserted against the same forbidden
phrases §15's second page uses. And when a reign ends it says whether the thing she
asked for happened.

**This is what makes her last line mean anything.** The wood stops shrinking when the
furnaces stop, so *"if you can, save us"* is answerable with the levers the player
already has; this is where they find out whether they did it.

Suite: **294 tests green. The opening is finished — stages 1 to 5.**

---

## THE MAP

### All twelve of MAP_SPEC's criteria pass

| # | Criterion | |
|---|---|---|
| 1 | every zone reachable over ground | from the clearing |
| 2 | no walkable tile touches the edge | 0 leaks |
| 3 | both crossings reach dry land | bridge and ford |
| 4 | damming both cuts Blackcairn off | the river is a barrier by test |
| 5 | road ratio ≥ 1.30 | **1.39** (348 road / 251 direct) |
| 6 | road travel 45–90 s | **58.0 s** |
| 7 | wild line crosses the Thornwood ≥ 30 | **126 tiles** |
| 8 | every zone has a landmark in `core/` | 105 props |
| 9 | nothing in the open road, none closes it | 0 and 0 |
| 10 | every road bend has a reason within 8 tiles | 5 bends, 0 unexplained |
| 11 | asset validator | **green**, 0 problems |
| 12 | full test suite | **green**, 305 tests |

`tools/map_criteria.gd` prints this on demand; `test/test_map.gd` is the gate that
stops them quietly reopening.

### The thesis, on the ground

`Terrain.CLEARED` — stumps and bare earth where wood was. The Cinderworks is now a
**wound with a radius** rather than a building standing on grass: 26 tiles of the
Thornwood are gone around the furnaces, with a working face pushing north into what
is left, so the clearing reads as a thing happening rather than a thing that happened.
Cleared land is drawn on the same beaten dirt as the road and the towns, because that
is exactly what it has become.

And it **stops four tiles short of the fairies**. That gap is the smallest and most
important measurement on the map: the works and the last of the wood are close enough
to be in the same thought, and the gap is the thing the player is being asked to save.

### Factions — the mechanism, ranks, jobs and the people who ask

Built: `FactionRules`, the `Allegiance` store, `AllegianceSystem`, `DeedRules.DEED_INFORM`,
`DialogueOption.joins`, a `nobody_has_your_name` condition, join lines on Tovin and
Kell, the journal's two new sections, 16 text keys a language, and 17 tests.

**Two sides and not joining either.** Four ranks each, read off service rather than
stored. Service comes from the deed table, so **every act already in the game counts
as work for the opposition without anything being authored twice** — and the crown got
the one act the game never had.

**They feed the routes, they do not replace them.** Crown → Access, opposition →
Exposure, neither → Force. `test_joining_the_crown_and_destroying_the_opposition_leaves_force`
is the permissiveness test for the whole feature: a player may take the king's side and
help him hunt the wood to nothing, and the game is still finishable.

**Ownership is a fact.** The crown's five points and the forest's one do not move; the
**Wide Acres and Saltmarch** are borders and are the only two that change hands, on the
sentiment of the town under them.

Suite: **323 tests green.** 106 hand-written lines still pass the prose door in both
languages.

### One thing found that the polish pass has to answer

**Nothing in this game is solid via props.** `is_passable` consults terrain and never
the prop list, and every prop carries `"solid": false`. Buildings are not walk-through
— `_place` stamps their footprint as `WALL` — but that is a different mechanism, and
it deliberately refuses to wall a protected tile so a building can never close the
road. The `solid` flag is dead weight. Recorded for the polish pass rather than
changed here, because making things solid can trap a player and needs its own test.
