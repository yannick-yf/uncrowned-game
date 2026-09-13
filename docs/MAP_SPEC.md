# Uncrowned — High-level map specification

> **Purpose.** This document is the brief for building the real map. It is written
> to be handed to a model working autonomously, which means every requirement here
> must be either a stated constant or a **machine-checkable assertion**. Anything
> that can only be judged by eye belongs in §11, not in the criteria.
>
> **Status: delivered, 2026-09-13.** The map was built to this brief and all twelve
> of §10's criteria pass — see `test_map.gd` and `tools/map_criteria.gd`. The
> `[DECIDE]` markers below were answered by the build rather than by a conversation,
> and the answers are constants in `core/region.gd` (`SEA_WEST`, `SEA_SOUTH`,
> `MOUNTAIN_NORTH`, `MOUNTAIN_EAST`, `KETTLE`, `THICKET_DEPTH`), which is where to
> read them. They are left in place because the brief is kept as written: this is a
> record of what was asked for, not a description of what exists. For that, read
> `docs/V1.md` and §4 of `SPECS.md`.
>
> `[DERIVED]` marks a value taken from the build that preceded it.
>
> **v3 (2026-09-13).** The map's target is now the 3D world in `prototypes/brindle_3d`,
> baked into a 384 × 384 tile grid at 2 m per tile (`docs/MIGRATION_3D.md`). Every
> criterion in §9 keeps its meaning and is measured against that grid; the tile
> coordinates in this file describe the 2D map until the bake exists and are rewritten
> when it does. §5's road ratio, §4's two crossings and §6's Thornwood rule are the
> parts of the brief the 3D world does not yet meet.

---

## 1. Coordinate system and scale

| | |
|---|---|
| Tile size | 16 × 16 px `[DERIVED]` |
| Viewport | 640 × 360, smooth-scrolling camera `[DERIVED]` |
| Region size | 280 × 200 tiles `[DERIVED]` |
| Origin | `(0,0)` is the **north-west** corner; x increases east, y increases south |
| Walk speed | 6 tiles/sec on road `[DERIVED]` |
| Screens | A "screen" is 40 × 22 tiles. Used for **estimating only** — the camera never snaps to it and nothing divides by it |

> The camera scrolls freely, so tiles-per-screen need not be a whole number. Do not
> change the viewport to make it divide.

**If the region is resized**, every coordinate below is expressed as a fraction of
region width/height as well as absolute tiles, and the fractions are authoritative.

---

## 2. Boundaries

The playable area is closed on all four sides by impassable terrain, so no invisible
walls are needed anywhere.

| Edge | Terrain | Depth |
|---|---|---|
| North | Mountains | `[DECIDE]` — at least 6 tiles |
| East | Mountains (the Iron Spine) | `[DECIDE]` |
| South | Open sea | `[DECIDE]` |
| West | Open sea | `[DECIDE]` |

**Assertion:** no walkable tile touches the region edge.

---

## 3. Anchors — the eight zones

Positions are the zone **centre**, in tiles, with the fraction of region size in
brackets. Footprints are the walkable extent of the settlement.

| Zone | Position | Footprint | Power base | Notes |
|---|---|---|---|---|
| **Brindle** | `[DERIVED]` south-east, inland of the coast | | — | Player start. Ruins. Must be in sight of the Cinderworks |
| **The Cinderworks** | adjacent to Brindle, on its ground | | Stone & steel | Furnaces visible from Brindle's first screen |
| **Harrowgate** | south-centre, on the road | | The town | Entered through a gate; the road passes *beside*, not through |
| **The Wide Acres** | centre-south | | The farms | |
| **The Muster** | centre, on the crossroads | 13 × 9 `[DERIVED]` | The army | A four-way junction, not a spur |
| **Saltmarch & Greyhold** | south-west coast | | The sub-castle | Port; on a spur off the Muster junction |
| **Cairnwell** | centre-north-west | | The bank | Capital. The counting house is the tallest building |
| **Blackcairn** | north-west, against the mountains | | — | The castle. Reachable from minute one |

**Optional zones**, cut first if behind: **the Redcut** (iron quarry, eastern
mountains), **the Thornwood depths**.

**Assertions:**
- Every zone is reachable from Brindle over passable ground
- No zone footprint overlaps another
- No building or landmark footprint sits on the road, on a crossing, or within
  2.5 tiles of a zone centre `[DERIVED]`

---

## 4. Hydrology — the Kettle

Runs from the northern mountains to the southern sea, down the eastern side,
dividing the map.

| | |
|---|---|
| Source | northern mountains `[DECIDE]` exact tile |
| Mouth | southern sea `[DECIDE]` |
| Width | 5 tiles `[DERIVED]` — note it runs at an angle, so it covers ~7 columns per row |
| Crossings | the guarded bridge (on the King's Road) and the ford (downstream) |

**Crossing rules:**
- Every crossing is **≥ 2 tiles deep** in the direction of travel. A 6 tiles/sec
  walker crosses a one-tile trigger in a sixth of a second and can step over it
- A bridge must span the river's **slant**, not its width

**Assertions:**
- Walking outward from each crossing reaches dry land on both sides
- Damming both crossings makes Blackcairn unreachable from Brindle — the river is
  a barrier by test, not by assertion

---

## 5. The road network

The King's Road runs **Cinderworks → Harrowgate → the Muster → Cairnwell →
Blackcairn**, with a spur from the Muster junction to Saltmarch.

The trunk bows deliberately: west along the south to Harrowgate, out to the Wide
Acres, back north-east to the Muster, then north-west for Cairnwell.

| | |
|---|---|
| Road length, Brindle → Blackcairn | 354 tiles `[DERIVED]` |
| Direct wild line | 251 tiles `[DERIVED]` |
| **Ratio** | **1.41** — target ≥ 1.3 |
| Road travel time | 59 s `[DERIVED]` — target 45–90 s |

**Why the ratio matters:** if the road's detour isn't meaningfully longer than a
direct wild crossing, the wild costs time and blood and saves no distance, so it is
strictly worse forever and the road/wild choice does not exist.

**Assertions:**
- Road ratio ≥ 1.3
- Road travel time within 45–90 s at 6 tiles/sec
- Each bend in the road has a terrain or settlement reason within 8 tiles of it —
  *the road bends around things, it does not zigzag*

---

## 6. Terrain regions

Described as areas with a purpose, not as decoration.

| Terrain | Where | Speed × | Purpose |
|---|---|---|---|
| Road, town streets, camp | see §5 | 1.00 | Fast, watched |
| Ruins | Brindle | 0.90 | |
| Farmland | the estates | 0.80 | |
| Open country | the broad middle | 0.65 *(was 0.80 — see note)* | Slow, unwatched |
| Coast sand | south and west margins | 0.75 | |
| **Thornwood** | **across the wild diagonal**, so the road bows around it | 0.55 | Slow, unwatched *(was: dangerous — see note)* |
| Ford | the crossing | 0.50 | |
| Marsh | around Saltmarch | 0.45 | |

> **The Thornwood rule:** wood *behind* the start line is scenery; wood *on the
> shortcut* is a decision. The belt must lie across the line a player would actually
> take when cutting the corner.

> **Amended 2026-09-13 (v2).** "Dangerous" is struck: monsters are out of the whole map
> (SPECS §4, §21). The wild is *slow and unwatched*; the road is *fast and watched*; the
> only price of the wild is time, so the speed multipliers in this table are **on** in
> v2 and the road ratio in §5 carries the whole of the road's case. **Measured
> 2026-09-13** with speeds on: the road 57 s, the least-watched wild line 69 s (66 s
> attuned), so open country is 0.65 rather than 0.80 — SPECS §4 has the reasoning and
> the two instrument corrections that preceded the number.

**Assertion:** the straight wild line from Brindle to Blackcairn passes through the
Thornwood for at least `[DECIDE]` tiles.

---

## 7. Legibility — each zone recognisable on sight

A player must be able to name where they are from what is drawn, without the HUD.
Each zone needs, at minimum:

1. A **landmark** unique to it (furnaces, crop rows, tent rows, boats, counting
   house, courtyard)
2. A **ground treatment** that differs from its neighbours
3. A **silhouette** readable at one screen's distance

**Assertion:** every zone has at least one landmark footprint recorded in `core/`,
so the check is structural rather than visual.

---

## 8. What must stay true — hard constraints

- **No progression flag gates movement.** Blackcairn is walkable from tick 0
- **Every zone reachable** from Brindle over passable ground
- **Crossings ≥ 2 tiles deep**
- **Nothing built on the road, a crossing, or within 2.5 tiles of a zone centre**
- **A town gate sits on the far side of the road from wherever you're going next** —
  otherwise every route out re-enters the town
- **The map is generated from code**, not hand-painted, so any of this can be
  re-run after a change

---

## 9. Machine-checkable acceptance criteria

An autonomous run is finished when all of these pass:

| # | Criterion |
|---|---|
| 1 | Every zone reachable from Brindle over passable ground |
| 2 | No walkable tile touches the region edge |
| 3 | Both crossings reach dry land on both sides |
| 4 | Damming both crossings makes Blackcairn unreachable |
| 5 | Road ratio ≥ 1.3 |
| 6 | Road travel Brindle → Blackcairn is 45–90 s at 6 tiles/sec — *on the 2D map. On the baked 3D grid the speed follows the workshop (Q51) and this band is re-measured and renegotiated with the map, not defended* |
| 7 | The straight wild line crosses the Thornwood for ≥ N tiles |
| 8 | Every zone has ≥ 1 landmark footprint in `core/` |
| 9 | No footprint on road, crossing, or within 2.5 tiles of a zone centre |
| 10 | Every bend in the road has a terrain or settlement feature within 8 tiles |
| 11 | Asset validator green — no off-palette colour, no off-grid tile source |
| 12 | Full test suite green |

---

## 10. Scope of an autonomous run

**In scope:** terrain shapes, road geometry, river course, zone placement and
footprints, landmark placement, collision, transitions, tile painting, auto-tiling.

**Out of scope, explicitly:**
- New NPCs, dialogue, facts or quests
- Any change to `core/` behaviour
- Any change to the twelve tracked quantities or standing
- Building or dungeon interiors
- The look (see §11)

---

## 11. The look — NOT autonomous

No test catches "this is ugly." The following are passes Yannick judges, not
criteria a model can close:

- Whether a scene reads well
- Whether the palette sings
- Canopy layers, animated tiles, 2D lights and shadows, occlusion fade
- Camera lookahead and lag
- Particles

A model may *propose* and implement these; it may not declare them done.

**Reference images:** `docs/references/` `[DECIDE]` — add the ones that matter.

---

## 12. Open decisions before an autonomous run

| # | Decision |
|---|---|
| 1 | Boundary depths, north / east / south / west |
| 2 | The Kettle's exact source and mouth tiles |
| 3 | Minimum Thornwood crossing length for criterion 7 |
| 4 | Exact zone centre coordinates, or the constraints that fix them |
| 5 | Whether the region is resized, and if so the new dimensions |
| 6 | Which reference images are authoritative |
