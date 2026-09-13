# Uncrowned — migrating onto the 3D world

> **What this is.** The analysis and plan for making the Brindle 3D workshop
> (`prototypes/brindle_3d/`, slosinio, 2026-09-13) the foundation of the game's world
> and look, while keeping every capability v1 and v2 built. Written 2026-09-13 on
> `art/ameliorations-graphiques`, documents only. Yannick decided the direction; this
> says how to get there without breaking the simulation. It becomes history when the
> last phase below is delivered.
>
> **Who does what.** The map and the graphics are the brother's. The systems, the
> content and the bridge between the two are ours — the player creation engine, the
> spec, the French of every line, quests, factions and rank, lore, the cast's
> backgrounds, the endings, fighting. This plan is the contract between the two, and
> the one rule it never bends is the one everything else already rests on: **`core/`
> never imports from `view/`; `view/` reads `core/` and never writes to it.**

---

## 1. The decision, in one paragraph

The game's world becomes a **stylised 3D landscape walked by 2D characters** — the
look the workshop demonstrates: a 768 × 768 m terrain with water, a burned Brindle
with six individually collapsed ruins, a mine, forests, a billboarded sprite walking
paths between them. SPECS §13's *top-down, one pack, 340 colours* was the right rule
for v1 and v2 and is retired as the target; the validator's job survives in a new form
(§8 below). Nothing about *what the game is* changes: §1's five pillars, the twelve
quantities, hardship, the four places and their two states, rank, the readings, the
endings, the journal, French first. What changes is what it looks like and how far you
walk to see it.

---

## 2. What each side is

### 2.1 Ours: a deterministic grid simulation with a window on it

- **`core/region.gd`** owns the world's geometry as a **tile grid**: 280 × 200 tiles,
  a terrain kind per tile, passability from terrain, zones baked from eight sites,
  the King's Road as waypoints, two crossings of the Kettle, props with footprints,
  five documents, twelve campfires, stalls, watch posts. It is built procedurally
  (`_stamp_*`) and read through a small API — `terrain_at`, `is_passable`,
  `zone_at`, `props`, `zone_sites`, `road_waypoints`, `nearest_site`,
  `nearest_document`, `nearest_campfire`, `nearest_stall`, `is_watched`,
  `speed_multiplier` — which is what the 21 systems, the rules and the 39 suites use
  (about 250 call sites; none of them care how the grid was made).
- **Movement** is the simulation's: `MovementRules.step` moves the player 6 tiles/s,
  8-way, slowed by terrain, slid along walls, once per 60 Hz step, from a `move_intent`
  event the view submits. The view never moves anybody.
- **Positions** are tiles everywhere: the 25 cast and 8 strangers stand on tiles in
  `content/cast.*.json`; deeds, witnesses, telling and the watch measure reach in
  tiles; `Navigation` searches the grid; travellers walk the road's waypoints.
- **`view/main.gd`** (1,640 lines) draws all of it in 2D from tiles — ground, scatter,
  props, actors, travellers, escort, particles, the fairy — and carries the HUD, the
  dialogue box and the journal as Control nodes. `view/art.gd` maps every kind of thing
  to a sprite in the one approved pack. `view/screens.gd` routes title → creation →
  play.
- **Determinism and the save** rest on the view being read-only: a save is the event
  log, loading is replaying, and a replay lands on the same tick because nothing
  outside `Sim.advance()` changes the world.

### 2.2 His: a 3D terrain from data, editable sectors, a self-moving character

- **Terrain** — `scripts/flat_ground.gd` builds 576 mesh chunks with trimesh
  collision from four arrays in `assets/landscape/`: `height.f32`, `water_level.f32`,
  `terrain_paint.f32`, `water_flow.f32`, a **385 × 385 grid at 2 m** over 768 m,
  described by `landscape.json`; `tools/build_landscape.py` (NumPy) regenerates them
  from `planning/geographie-v1.json`. `terrain_stamp.gd` nodes flatten pads for
  buildings; `height_at_world(x, z)` and `water_at_world(x, z)` sample the grid.
- **Sectors** — `scenes/sectors/*.tscn`: Brindle (six ruins as instanced scenes,
  path curves, a well, yards), two forests (602 + 295 trees as MultiMeshes with
  cylinder collisions), the mine and bridge. Their placement data is in
  `planning/brindle-sectors-v1.json` (building centres, yaws, routes) and
  `forest-placements-v1.json`. `sector_tools.gd` re-seats them on the terrain after a
  relief edit.
- **Geography** — `planning/geographie-v1.json`: five sites (city and castle, farming
  village, sawmill village, steel village, Brindle), a lake, four watercourses, four
  roads as point lists. Metres, centre origin, north = −Z.
- **Character** — `prototype_3d/scripts/player_controller.gd`: a `CharacterBody3D`
  moved by `Input.get_vector` at 5 m/s with acceleration, gravity and
  `move_and_slide()`; an `AnimatedSprite3D` billboard with a distance-driven walk
  cycle (`player_walk_animation.gd`); `follow_camera.gd`, orthographic, tilt 48°,
  size 24 m, following the body.
- **Verification** — `tools/verify_workshop.gd` loads the scene, walks the real
  capsule through six doorways and sphere-casts the paths; `check_workshop.sh` wraps
  it for CI, scanning stderr for script errors exactly as `run_tests.sh` does.
- **Isolation** — a separate `project.godot`, `prototypes/.gdignore`, its own
  `.gitignore`. It touched nothing in `core/`, `view/`, `test/` or `content/`.

### 2.3 Where they meet, and where they collide

| Concern | Ours | His | Verdict |
|---|---|---|---|
| Who moves the player | The simulation, from `move_intent` | The body, from `Input` | **Invert his.** The 3D view submits intents and places the sprite where the sim says. His controller is retired; his animation and camera stay |
| Where the ground is | A terrain kind per tile | A height per 2 m, paint, water | **Bake his into ours.** Terrain kinds derive from paint, slope and water; height is view-only |
| Collision | `is_passable(tile)` | Trimesh + capsule physics | **Ours decides.** Passability is baked (water, slope, building footprints, thicket); his collision shapes become decoration or are dropped |
| Coordinates | Tiles, origin top-left, y down | Metres, origin centre, north −Z | One conversion, defined once (§4) |
| Places | Eight zones (§4) | Five sites | **Brief for the brother** (§5): three places missing, one adjacency wrong |
| Roads and crossings | Waypoints, a bridge and a ford, ratio 1.41 held by test | Four point lists, one bridge | Bake roads from his lists; the ford and the ratio go in the brief |
| Look | 16 px sprites, one pack, 340 colours | Painterly 3D, one traveller sprite | The direction changes (§8); the *rule* — one family, provenance, a validator — survives |
| UI | Control nodes: HUD, dialogue, journal | Two labels | **Reuse ours** unchanged |
| Screens | title → creation → play | one scene | Keep ours; `play` opens the 3D view |
| Determinism | Read-only view | Physics in `_physics_process` | Kept, because the sim never sees a metre |
| Godot | 4.7.2, Forward+, 640 × 360 integer-scaled | 4.7.2, Forward+, 1440 × 900, D3D12 on Windows | One project, one display setting; Metal on Mac to check |

---

## 3. What must stay true — the invariants the migration is measured against

1. **`core/` never imports from `view/`.** The 3D scene is a window. It may read
   every store; it may submit events; it may never set a position, a fact or a
   quantity. (The debug screenshot pokes are the one existing exception and stay
   debug-gated.)
2. **The simulation stays a grid.** Tiles, `is_passable`, `terrain_at`, `zone_at`
   and 8-way movement at one speed constant are what every rule, every test and every
   reachability walk is written against. Height, meshes and metres never enter
   `core/`.
3. **All 39 suites stay green at every phase.** A phase that needs a red suite to
   land is cut differently.
4. **A save replays identically.** Baking the region is a build step with a fixed
   input; the same data produces the same grid, and a replay lands on the same tick.
5. **Nothing gates on progression**, and no place-of-the-map fact changes: the king
   is reachable from minute one on the new map too, on foot, over passable ground.
6. **French first.** Any new string — a place name, a sign — is written FR then EN.
7. **One asset family, with provenance.** The rule that mixing artists is the mark of
   an amateur game does not die with the pixel pack; it moves (§8).

---

## 4. The coordinate contract

Everything below is one rule, defined once in `core/` (a `WorldScale` or on
`Region`), read by the bake tool and the 3D view, and nowhere else.

- **Metres per tile: 2.** His heightmap is 385 × 385 at 2 m; one tile per height
  sample means the bake is a lookup, not a resample, and 768 m becomes **384 × 384
  tiles** (147k, against 56k today — `PackedByteArray` and the zone bake are fine;
  `Navigation` is BFS over passable tiles and was already the slow part of the SLOW
  suites, so measure it).
- **Origin:** his `(x, z)` in metres, centre origin, maps to our tile
  `(x/2 + 192, z/2 + 192)`; north stays up (his −Z is our −y). Height `y` is sampled
  by the view from `height_at_world` and never stored.
- **Time — decided 2026-09-13: walking follows the workshop.** The world is measured in
  his metres and walked at his speed (5 m/s today), so the simulation's speed constant
  becomes *derived*: tiles per second = his metres per second ÷ metres per tile — 2.5
  tiles/s at today's figures, against 6 today. The consequence is stated rather than
  hidden: on the current geography Brindle (175, 255) to the castle (−150, −180) is
  543 m and about **108 s**, not the 45 s the 2D map walks. §4's 45–90 s road target and
  MAP_SPEC's criterion 6 are therefore **re-measured against the baked grid and
  renegotiated with the map**, not defended: the brother can shorten distances, the
  speed can be revisited once the sprite has been watched walking, and Pillar 1 — the
  castle reachable in *minutes* — still holds at two.

---

## 5. The brief for the map — what the world has to contain

His five sites against §4's eight, in the coordinates of `geographie-v1.json`:

| §4's place | His site | State |
|---|---|---|
| **Brindle** | `brindle` (175, 255) | Built. The ruins are exactly §4's opening; the clearing the player wakes in and the corridor out are missing (§4: one corridor south to Brindle, thicket closing it) |
| **The Cinderworks** | `village_acierie` (255, 65) — the mine at (308, 80) | **Wrong adjacency.** §4: *built on Brindle's own ground, smoking a minute's walk away, in the first frame*. It is 200 m north of Brindle now. Either the works moves to Brindle's edge, or Brindle moves to the works' — the first frame is the game's one piece of exposition and it is not negotiable |
| **The Wide Acres** | `village_fermier` (−170, 40) | Envelope only. Fields, a granary row with its watch, Vale's house, Pell's ground |
| **Cairnwell** and **the bank** | `ville_chateau` (−150, −180), the city | Envelope only. §0: Cairnwell is the capital and the bank is in it |
| **Blackcairn** | `ville_chateau`, the castle on its spur | Envelope only. §4 has the castle *against the northern mountains* with the city below; his spur above the city is the same idea. One state, two faces (§4) |
| **Harrowgate** | — | **Missing.** The first town, five of the cast, the market, the tiered law in practice; the road passes *beside* its gate |
| **The Muster** | — | **Missing.** The army's camp *on the road's crossroads*; a four-way junction, tents in rows, the pay tent |
| **Saltmarch** | — | **Missing.** The port on the south-west coast, on a spur off the Muster junction; where nothing is watched |
| *(none)* | `village_scierie` (235, −125) | **Goes** (Yannick, 2026-09-13). §3: *wood gets no town of its own* — felling the forest is a Cinderworks consequence. If any of it survives it is the works' fuel yard, beside the works |

And the constraints MAP_SPEC already states, which are tests and not wishes:

- The King's Road: Cinderworks → bridge → Harrowgate → Wide Acres → Muster (a
  junction) → Cairnwell → Blackcairn, Saltmarch on a spur, **ratio 1.30–1.50** against
  the straight line, travel 45–90 s. His four road lists become the trunk.
- The Kettle divides the east: **one bridge on the road and one ford downstream**, both
  bands two tiles deep, dam both and the castle is unreachable. His main river is the
  Kettle; the ford is missing.
- **The Thornwood lies across the shortcut**, east of the river, the fairies' clearing
  inside it; the works has eaten a ring out of it. §4 needs the wild line to cross it.
- Every zone reachable from Brindle over passable ground; nothing built on the road, a
  crossing, or within 2.5 tiles of a site; a town gate on the far side of the road.
- Each place its own kit; nobody in the cast shares a face (§13).

The brother owns this list. Our side supplies the tests that hold it — MAP_SPEC's
twelve criteria run against the baked region, unchanged in meaning.

---

## 6. The plan, phase by phase

Each phase ends on something playable or measurable, in the same rule as v1 and v2:
**a phase is done when its proof is playable, not when its code is written.** Owners
are indicative; the contract is the coordinate rule (§4) and the data files (§6.1).

| | Phase | Owner | What it builds | Proof |
|---|---|---|---|---|
| **M0** | **Decide and brief** | both | This document; §13's direction changed in SPECS; the map brief (§5) handed over; the decisions taken and the defaults recorded (§9) | Yannick and the brother have each read this and agreed the contract |
| **M1** | **Bake** | ours | `tools/bake_region.gd`: reads his `assets/landscape/*` and `planning/*.json`, writes `content/region.json` — 384 × 384 terrain kinds (paint → wild / farmland / sand; water → water; slope over a threshold → mountain; building footprints → wall; his paths → road; sites → zones), roads, crossings, props by kind, documents, campfires, stalls. `Region.load()` beside the procedural builder, chosen by one flag. **Positional content moves to data**: the 25 cast tiles, the 8 strangers, the sites, in `content/places.json`, so a map change is a data change | All 39 suites green on the baked region — with his map extended to eight places, or, until it is, with the missing settlements procedurally stamped onto his terrain as a scaffold. MAP_SPEC's twelve criteria pass. `measure_routes` reports the three rows |
| **M2** | **A 3D window** | ours + his camera | `view3d/`: his `map_plate.tscn` as the world, one `SimBridge` node that owns the `Sim` as `main.gd` does, submits `move_intent` from input, and every frame places a billboard for the player and each NPC at `tile → metres` with `height_at_world`. His `follow_camera` targets the player's marker. HUD, dialogue box, journal, title and creation reused as they are. `screens.gd` opens the 3D play scene behind a project setting; `shot.sh` gets `--3d` | Wake in the clearing, walk to Brindle and up the road in 3D, driven by the sim; talk to Wren; the journal opens; the same log replays to the same frame; the 2D view still runs |
| **M3** | **Parity** | his art, our wiring | Props by kind from his library (kilns, granary, counting house, muster rolls, tents, boats, keep, towers, gates); the free-state variants (§13) as real scenes rather than skipped fences; the castle's two faces; travellers as carts; the sign as a prop at each gate; particles; the fairy as light. **The 25 faces**: a 2D sprite family in his style for the cast and the strangers — the one asset every conversation stands in front of | The v2 screenshot set reproduced in 3D: the Acres held and freed, the freed Muster, the castle in a crisis, a traveller on the road, Halgrave at the works |
| **M4** | **Cut over** | ours | The 3D window becomes `play`; the 2D view survives as the map screen (`M`) and the debug tools; display settings, CLAUDE.md's tool list, `shot.sh`; §13 rewritten with the new validator (§8); MAP_SPEC updated to the new coordinates; `docs/V3.md` | `tools/run_tests.sh --all` green; the four development tools work; a fresh clone runs `--import` and plays; Yannick wants to play it in front of someone else |
| **M5** | **Fill** | his | Harrowgate, the Muster, Saltmarch, the Wide Acres' fields, Cairnwell's streets, the castle — each its own kit, in the order the cast stands there | Every zone recognisable on sight alone, as §18's Phase 2 once proved for the 2D map |

### 6.1 The data contract

The bake reads only files that already exist and that the brother already edits:

| File | What the bake takes from it |
|---|---|
| `assets/landscape/landscape.json` | grid size, extent, sea and lake level, site centres |
| `assets/landscape/height.f32`, `water_level.f32` | passability (water, slope), the ford (shallow water on the river), the mountains |
| `assets/landscape/terrain_paint.f32`, `brindle_ground_mask.png` | terrain kind: worn dirt is a path, woodland floor is forest, grass is wild |
| `planning/geographie-v1.json` | sites → zones and footprints; roads → the King's Road and the spur; watercourses → the Kettle |
| `planning/brindle-sectors-v1.json`, `forest-placements-v1.json` | building footprints → walls and props by kind; trees → forest and thicket |

Two additions the brother makes as he goes: a `kind` on each building (`kiln`,
`granary`, `counting_house`, `muster_rolls`, `inn`, `tent`, `keep`…) so the bake can
place §3's landmarks, and a `crossings` list with the ford. Nothing else is asked of
his files.

### 6.2 Working in parallel — the ingestion loop

**The core challenge, stated (Yannick, 2026-09-13):** the map will take time, and our
side has to keep working and improving while still being able to ingest each of his
improvements as it lands. Waiting is not a plan and neither is hand-fitting content to a
map that will move. The mechanism has four parts, and every one of them is a build step
or a test rather than a habit.

**1. Positions are anchors, never coordinates.** Content names *what a thing stands
next to*, not where it is: Pell stands at `wide_acres.granary`, Halgrave at
`cinderworks.kiln.1`, Maddox at `harrowgate.inn`, the land grants lie in
`wide_acres.estate_house`, a campfire sits at `brindle.well`. An anchor is a place id
plus a named feature, with an optional small offset in tiles. `content/places.json`
holds them; no `.gd` and no cast sheet carries a tile after M1. The bake resolves every
anchor from the brother's sector data — his building ids and their `kind`, his routes,
his sites — and the same content file serves the 2D map and the 3D world alike.

**2. The bake is a build step with one input and one output.** `tools/bake_region.gd`
reads his files (§6.1) and writes `content/region.json`; `Region.load()` reads that and
nothing else. Run it whenever his data changes; check the output in, so a clone plays
without his tools. It is deterministic — same data, same grid — which is what keeps a
save replaying.

**3. Scaffolds fill what he has not built yet.** For every place and anchor the map does
not provide, the bake stamps a placeholder on *his* terrain — our procedural settlement
kit, sized from the site's envelope in `geographie-v1.json`, or a default where no
envelope exists — and marks it `scaffold: true`. Every system, test and quest works on
the mix from the first bake, and the bake prints a report of what is still scaffolded.
When he delivers a real Harrowgate, its scaffold disappears on the next bake and Maddox
is standing in the inn he drew, because Maddox never knew a coordinate.

**4. The contract is tested, by name.** One test walks every anchor content references
and fails naming the anchor that resolves nowhere — neither in his data nor in a
scaffold. MAP_SPEC's twelve criteria run against the baked grid. The whole suite runs
on the bake in CI, after his own workshop check, so a merged map change that breaks
the game says which anchor, which crossing or which criterion broke, before anyone
plays it.

**The cadence that follows.** His work merges to `main` in small pieces — a place, a
pass on Brindle, a fix — and each merge reruns the bake and the suites. Our work merges
to `main` from our own branches and never carries a coordinate. Until M2 the bake reads
his data from `prototypes/brindle_3d/` through the `.gdignore` (file access does not
care about it; only the importer does); at M2 the sectors and the library move under
the root project and the `.gdignore` goes.

**What each side never does.** Ours: hand-place anything on his map, edit his scenes,
or wait for a place to exist before writing the content that stands in it. His: rename
a building id or a site id without saying so — the one fragile point of the contract,
and the bake test names it the moment it happens.

**Our lanes, meanwhile, on `main`.** The player creation engine, spec revision and
alignment, the French of every line, quests, faction and rank, lore, the cast's
backgrounds, the endings, fighting. All of it lives in `core/`, `core/rules/` and
`content/`; none of it touches the view; after M1 none of it touches a coordinate.

## 7. Risks, and what answers them

| Risk | Why it is real | Answer |
|---|---|---|
| **The place count** | Three of eight places are envelopes or missing; the works is not in sight of Brindle; a sawmill town contradicts §3 | §5 is the brief; M1's scaffold stamps the missing places procedurally on his terrain so systems work while he builds them |
| **Walking speed** | 5 m/s on a 768 m map is 108 s from Brindle to the castle, against a 45–90 s road target | Decided: the speed is his and the target is re-measured against the baked grid, then renegotiated with the map (§4). Pillar 1 holds at two minutes |
| **Character art** | One traveller sprite exists; the cast is 25 faces plus strangers, and §13's *nobody shares a face* holds | M3's largest art task, and his. The transition shows the pixel figures on his ground and **breaks §13's one rule on purpose**, for one reason: 25 distinct faces are what the cast review and the journal need, and one sprite recoloured per role would not give them. The bake report lists it as *transition* until the last face is redrawn, and M3 does not close while it is listed |
| **Provenance and licence** | His meshes and textures come from *the Brindle test project*, hashes recorded, no third-party licence claimed | Establish the source before M3; §8's validator will refuse a file without provenance |
| **Performance and platform** | 576 chunks, 900 trees, Forward+ at 1440 × 900; his renders are Windows/D3D12, ours is a Mac | M2's proof includes running on both machines; the workshop's draw-distance and shadow tuning is his, on his terrain |
| **The 2D view's 1,640 lines** | Everything drawn from tiles has to be redrawn | Most is `_draw_*` and is replaced wholesale; the HUD, dialogue and journal are Controls and move over untouched; the map screen keeps the 2D drawing as its purpose |
| **Tests welded to coordinates** | About 70 tile literals across 15 suites, and every cast tile | M1 moves positions to data and names the hot spots (`test_deeds`'s stall, `test_zones`'s portals, the journeys' waypoints); most suites call the Region API, which does not change |
| **Two Godot projects** | `prototypes/.gdignore` keeps them apart today | Right until M2; at M2 the sector scenes and library move under the root project and the `.gdignore` goes |
| **Replay across maps** | A v2 save's move intents walk a different world | Expected; a map change invalidates saves, as §4's map changes always have |

---

## 8. The asset rule, moved rather than dropped

§13's rule was never *pixel art*; it was *one family, so nothing looks borrowed*, with
a machine that refuses the borrowed thing. Rewritten for the 3D world:

- **One family**: the workshop's library (`prototype_3d/assets/library`, its
  materials and shaders) and whatever the brother adds in the same hand. No mesh,
  texture or sprite from another source enters `assets/` — the same sentence as
  before with the nouns changed.
- **Provenance is the palette.** Every asset file is listed in a manifest with its
  origin and licence (the shape `personnage-brindle.json` already has). The validator
  refuses any file in `assets/` not in the manifest, and any manifest entry without a
  licence that survives a Steam release. That is checkable by test, as the palette
  was; *style* still is not, and only a person looking at the screen catches it.
- **The 2D character family** is one family too: one sprite sheet layout, one pixel
  size, one outline, for the player, the 25 cast, the strangers and the travellers.
- Until M4, the NinjaAdventure rule stands for the 2D view exactly as written.

---

## 9. Decisions — taken 2026-09-13, and the defaults that stand until somebody objects

1. **Walking speed: the workshop's.** Decided. The simulation's speed is derived from
   his metres per second and the metres per tile (§4); the road target is re-measured
   and renegotiated with the map, not defended.
2. **The works beside Brindle.** Still the brother's call with Yannick; the plan does
   not wait on it — the works is scaffolded beside Brindle until the map says
   otherwise, because the first frame is not negotiable.
3. **The sawmill village goes.** Decided. If any of it survives it is the works' fuel
   yard.
4. **The character sprites — a default, not a decision.** During the migration the
   existing pixel figures are shown in the 3D world and the mismatch is accepted and
   listed in the bake report as *transition*; the target is every person drawn in the
   workshop's own style, by the brother or by someone he chooses. Nothing is asked of
   Yannick here until there is something to look at.
5. **The 2D view — a default, not a decision.** It is not deleted at cut-over; it
   becomes the map screen on `M`, which is what a flat top-down picture of the region is
   for, and the debug tools' home. Nobody chooses between two ways to play.

## 10. Where this leaves the documents

- **SPECS §13** carries the new direction as of today, dated, with the old rule kept
  as history; **§4** names the 3D world as the map's target and keeps MAP_SPEC's
  criteria as the brief; **§18** gains the v3 roadmap (M0–M5); **§19** gains the
  decisions above; **§20** logs the decision and what was rejected.
- **CLAUDE.md**'s current phase points here; its layout names `prototypes/`.
- **`docs/V2.md`** says what comes next is now decided.
- **MAP_SPEC.md** keeps its criteria and gets a note that the coordinates it measures
  in will be the baked grid's.
- This file is the plan until M4 lands; then it moves to `docs/history/` and `V3.md`
  says what the game is.
