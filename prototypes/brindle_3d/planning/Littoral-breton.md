# Breton-inspired coastline

The existing west and south shores now form approximately **1.361 km of continuous
coastline**, with seven coves, exposed granite headlands, sandy pockets and rocky
foreshores. The strongest cliffs stand south of Brindle and reach approximately
**66.7 m above sea level**. This is the workshop's existing shoreline; the northern
and eastern map edges have not been converted into additional coast.

## Open and explore

Run **Ouvrir-littoral-breton.cmd** with Godot 4.7.2. It opens the actual playable
workshop in free map view, looking at the cliffs south of Brindle. The character
is placed at world XZ **(140, 305)**, where the coastal routes meet the village
approach. Press **Tab** to walk from that point. In free map view, **L** frames
the southern cliffs and **B** returns the camera to Brindle.

The two accessible routes are `SentierDesCaps`, following the high headlands,
and `DescenteDeLaCrique`, descending to Brindle's sheltered cove. Both connect to
the existing southern village approach. Their widths, elevations and junctions
are authored together so the visible paths follow the actual walkable terrain.

The seven coves, in shoreline order, are `AnseDuNordOuest`, `CriqueDesGranit`,
`AnseDesPres`, `CriqueSudOuest`, `AnseBasseDuSud`, `CriqueDeBrindle` and
`CriqueDuLevant`. Their names remain in French to match the planning data.

## Terrain, water and protected places

`planning/coastline.json` controls the coastal profile, coves, routes and protected
areas. The original shoreline points come from
`assets/landscape/landscape.json:coastline_xz`. This is an open polyline: its closing
edges must never be treated as additional shoreline.

`tools/prepare_coastline.py` generates `assets/coastline/terrain_edits.f32`, a sparse
list of **index, target height, blend weight** float32 records, and
`assets/coastline/coastal_control.png`, the coastal material mask. Runtime
`scripts/coastal_terrain.gd` applies those height edits after the settlement and
bridge grading, before recalculating slope paint. The terrain keeps its original
**385 × 385 grid at 2 m spacing**. The rendered surface and physical collisions
are rebuilt from the same vertices and triangle topology, including chunk edges.
There is no second floating cliff surface or independent cliff collision shell.

The regional source files `height.f32`, `water_level.f32`, `terrain_paint.f32` and
`water_flow.f32` remain intact. The coast overlay changes the runtime height array;
it does not replace river water levels. The southwest estuary, around XZ
**(-215.56, 311.58)**, retains its river-to-sea connection. Its protected corridor
continues from **(-211, 288)** to **(-225, 350)**, with a 32 m clear half-width and
a further 20 m blend. Nearby Brindle foundations and yards also have protection
areas. The approach junction is deliberately graded for access; it is distinct
from foundation anchors that must retain their original heights.

| Plan field | Editable purpose |
|---|---|
| `priority_center_xz`, `priority_radius_m`, `priority_cliff_height_m` | Main southern cliff emphasis; final height also follows the shaped coastal profile |
| `landward_blend_m`, `seaward_blend_m` | Transition from existing inland terrain to coast and seabed |
| `coves` | Cove position, radius, inset and sand character |
| `protected_estuary`, `protected_anchors`, `protected_paths` | Water outlet, foundations, yards and existing access corridors |
| `trails`, `approach_grading` | Coastal routes and their connection to Brindle; `profile_xzy` entries are **[X, Z, altitude]** in metres |
| `review_spawn_xz` | Character starting point for the coastal review launcher |
| `rock_budget` | Upper limits and batching distance for procedural granite dressing |

Keep descending profiles and adequate walking shoulders when editing a trail.
The 2 m grid cannot accurately represent a very narrow switchback or a sharp
height change between adjacent routes. Rerun the physical route checks after
changing routes, cove positions or protected areas.

## Granite assets and placement budgets

`tools/build_coastal_rocks.gd` creates six original native Godot granite pieces:
eroded blocks, inclined blocks, stepped slabs, split rocks, maritime stacks and
pebble clusters. Their saved scenes, shared material, indexed meshes, bounds and
triangle counts are listed in `assets/coastline/catalog.json`.

`scripts/coastal_dressing.gd`, attached to `World/CoastlineDecor`, places these
pieces deterministically from the plan's seed. It seats them against the real
terrain and groups visible pieces in spatial MultiMeshes. Route and estuary
clearances reject obstructing placements; larger usable rocks receive simplified
physical colliders. Small pebbles do not need individual colliders.

The plan caps dressing at **1,000 instances** and **110 collision shapes**, with
80 m shoreline batches by default. These are ceilings, not promised placement
counts or hardware performance guarantees. Read the current runtime metadata
`coast_rock_instances`, `coast_rock_batches`, `coast_rock_tris`,
`coast_rock_colliders` and `coast_rock_rebuild_ms` on `CoastlineDecor`, or the
`COAST_DRESSING_READY` log. Counts can change as profiles and clearances improve.

An outer sea backdrop continues the existing water beyond the western and southern
map edges, hiding the exposed edge of the submerged terrain. It reuses the water
material and adds six triangles in one surface, with no physics or inland edits.

## Rebuild and verify

Saved assets open without Python. Regeneration requires Python with **NumPy** and
**Pillow**, plus Godot 4.7.2. Run the following from `prototypes/brindle_3d`:

```sh
python tools/prepare_coastline.py
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tools/build_coastal_rocks.gd
godot --headless --editor --path . --import --quit
godot --headless --path . --fixed-fps 60 --script res://tools/verify_coastline.gd
```

Terrain preparation rewrites the sparse overlay, material mask and generated
metadata in the plan. The rock builder rewrites its generated library under
`assets/coastline`. Preserve any manual changes to generated files before
regenerating. Changing only route heights or cove parameters does not require
rebuilding the rock mesh library. Runtime dressing follows the updated terrain
when the scene rebuilds. Do not regenerate the global regional landscape merely
to adjust this coast.

`verify_coastline.gd` compares actual scene loads with the coastal overlay disabled
and enabled. It checks finite values, exact water preservation, unchanged heights
outside sparse edit indices, protected places, wet estuary connectivity, shared
chunk vertices/normals and collision continuity. It samples the routes at intervals
below one metre, checks slopes and capsule clearance, and walks the real
`CharacterBody3D` along both coastal routes and the Brindle approach in both
directions. It also checks that the regional source files have not changed.
Rock checks cover real base support, emerging silhouettes, protected clearances,
geometry and collider budgets, deterministic rebuilding and duplicate prevention.

For visual review, run:

```sh
godot --path . --script res://tools/review_coastline.gd
godot --path . --script res://tools/review_coastline.gd -- --capture --out=/absolute/preview/folder
godot --path . --resolution 1440x900 --script res://tools/review_coastline.gd -- --benchmark --out=/absolute/preview/folder
```

The capture command needs the actual renderer, not headless mode. It records
the southern cliffs, both coast orientations, estuary and selected coves. Without
`--out`, captures go to `user://previews/coastline/`. Inspect the views as well as
the physical checks; neither a headless pass nor the instance budget measures
GPU performance or proves that every cliff composition reads well from the camera.
The benchmark writes `performance.json`: warmed, uncapped visible/hidden dressing
passes for three views, with frame and GPU timing. The terrain stays identical in
both cases. Results depend on the hardware and other open editor/game windows.

## Measured validation — 2026-09-22

- Full `tools/check_workshop.sh`: exit 0, **68.07 s**. The coastline contributes
  **81 passing checks**, including real forward/return traversal, in **7.77 s**.
  River/bridge, ironworks, sawmill, capital, farming, lighting and Brindle checks
  also pass in the same wrapper run.
- Current dressing: **390 instances**, **122 spatial batches**, **64,928 instanced
  rock triangles**, **43 convex collision shapes** and the six-triangle sea
  backdrop. Largest measured base support gap: **0.30 mm**. The coastal asset
  directory totals **437,542 bytes**, excluding Godot's import cache and source code.
- D3D12 Forward+, RTX 5080, 1440 × 900, 180 frames per warmed pass: median frame
  time with dressing **4.995–8.362 ms** across the three views; p95 **7.386–11.196 ms**.
  GPU medians: south **5.074–5.347 ms**, cove **1.542–1.543 ms**, west
  **1.799–1.800 ms**. An existing editor and its play window remained open.
  The visible/hidden comparison includes only dressing/backdrop, not the terrain
  shader; differences on the southern view were within background-run variance.
  These are local measurements, not a performance guarantee on other hardware.
- Main production fast wrapper: **345 tests / 10,380 assertions / one pre-existing
  failure**, `test_every_landmark_kind_has_art` (`MaisonEntreeNord`), in **18.34 s**
  test time / **19.11 s** wall time. No production files were changed for this pass.
