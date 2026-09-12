# Overnight log — Phase 7

> **Yannick reads this first.** It is both the plan and the record: what was built,
> in what order, and every decision taken without him in the room.

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
| 1 | **The opening** — stages 1–5 below | **stages 1 and 4 done**; 2, 3, 5 next |
| 2 | **The map** — refine against the thesis, close MAP_SPEC's 12 criteria | not started |
| 3 | **Factions** — two sides; mechanism **plus** ranks, jobs and quests | not started |
| 4 | **Polish** — collision, enterability, suite, validator, no script errors | not started |
| 5 | **The look** — the cheap five. Real 2D lighting is **out of v1** | not started |

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
| 7 | `_stamp_clearing` only ever overwrites `FOREST` | So the river, the road and every settlement are safe from it by construction rather than by getting the arithmetic right. Asserted anyway, for whoever moves the clearing next |

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
