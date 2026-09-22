# Farming village asset kit

An original, native Godot 3D kit for the green valley: pale fieldstone, oak framing,
warm plaster, thick thatch, golden crops and faceted fruit trees. Its rural identity
is distinct from the ironworks and the timber-production town. The asset library
and inspection catalogue remain reusable, and the kit is now placed in the actual
workshop map. See [Farming village](Village-fermier.md) for that settlement's
districts, water, navigation and regeneration workflow.

## Open and use

Double-click `Ouvrir-catalogue-fermier.cmd`, or open this workshop's `project.godot`
and run `scenes/catalogue_fermier.tscn` with F6. The catalogue provides search,
family filtering, individual inspection, mouse-wheel zoom and middle-button orbit.
Left/right arrows change the selected piece; R reframes it and D restores the sample
assembly. The sample is a display of the kit, not the final farming settlement.

For the integrated settlement, launch `Ouvrir-village-fermier.cmd`, or use **V** in
the map's free camera. Its scene is `scenes/sectors/village_fermier.tscn`; **Tab**
switches to the existing playable character for scale and circulation checks.

Drag any `.tscn` from `assets/farming/` into a sector scene. Each is a self-contained
prefab using shared farming materials and saved meshes. One unit is one metre;
origins lie at ground level and building entrances generally face +Z. Dimensions,
purpose, placement notes, geometry budgets and resource paths are in `catalog.json`.
Keep the `materials/`, `meshes/` and `shaders/farming_surface.gdshader` dependencies
when transferring a piece. The offline generators are not needed to use saved assets.

## Contents: 54 prefabs

| Group | Pieces | Contents |
|---|---:|---|
| Rural architecture | 15 | Eight houses with distinct footprints or roof forms, two open barns, raised granary, octagonal grain store, grain watermill, separate wheel and 5 m channel |
| Rural life | 19 | Covered well, empty/loaded carts, 2 m/4 m/corner fences, open/closed gates, barrels, harvest sacks, apple/pear baskets, empty/fruit crates, straight/tripod ladders, tool rack, ard plough and stone trough |
| Crops and orchards | 20 | Wheat/cabbage/leek rows, wheat clump, seven soil/field modules, two tied harvest bundles, three apple trees, two pear trees, six-tree orchard and four-tree grove |

House silhouettes include a longhouse, an L-shaped farm, side annexes, broad porch,
off-centre gable and projecting entrance. Houses are closed exterior shells. The
barns have physically clear through-aisles; the open gate is a separate static state.
Ladders and tools are scenery, without new gameplay interactions or NPC logic.

## Placement and water

- Use `Entrance` and the barns' `AisleStart` / `AisleEnd` markers for approach routes.
  Keep a dry yard for carts and access around the grain stores.
- Snap fence `ConnectorStart` / `ConnectorEnd` markers together. End posts meet at
  shared positions. Open-gate clearance is 1.85 m; the barn aisles are 3.2–3.4 m.
- The watermill is an undershot-wheel mill for a lowland diversion channel. Its
  masonry and axle supports are modeled; the house must stand on dry bank terrain.
  `WaterIn` and `WaterOut` are at local Y = 0.48 m, on the -X side. Align the water
  markers of each 5 m channel; they share a 1.68 m clear water width and a 2.16 m
  outside width including coping. These prefabs do not create a river or a terrain cut.
  When placing them, connect an upstream intake and a downstream return and adjust
  the supporting bank to the level of the water. The standalone wheel has its own
  markers at Y = 0.30 m and needs a support/axle supplied by the level designer.
- Field shapes have concave/rounded edges for river bends. They are **flat pieces**,
  not automatic terrain-conforming decals: place on gentle prepared terraces and use
  the row, clump, curved-border and soil-join modules to complete irregular boundaries.
  Leave a grassy setback beside water. Avoid scaling tall buildings to fit plots.
  The integrated village separately subdivides and conforms its saved field meshes
  to the final terrain; this does not change the reusable flat source prefabs.
- Orchards include trees and grouped examples. Recompose individual trees for local
  slope and access. Foliage and crops are traversable; tree trunks have simple solid
  colliders. Keep harvesting routes and paths clear of those trunks.

## Fidelity and performance

Detail comes from silhouettes, bracing, shutters, roof courses, fruit, and shared
procedural surface shaders. Wood grain, thatch, masonry joints, linen and soil furrows
are generated in the shader, without large bitmap textures. There is no universal
"Ultra" asset switch; the catalogue uses Forward+ shadows, antialiasing and SSAO
for visual inspection.

The builder indexes and compresses meshes, groups static geometry by material, and
keeps the mill wheel separately transformable. Prefabs have no runtime generation
scripts. Crops use merged geometry rather than one scene node per stalk. The wheel
rotates in the catalogue and in the placed workshop village; that motion is visual
and does not introduce a production simulation.
The verifier enforces per-asset triangle budgets and at most 16 mesh instances.
These budgets are guardrails, not a frame-rate guarantee. The placed village uses
shared MultiMesh batches for its orchards and verge planting, with trunk collisions
kept separately. Its conformed field meshes have their own subdivision cost and
are not included in the reusable kit's triangle totals below.

## Rebuild, verify and preview

Run from this workshop directory with the Godot executable on PATH:

```sh
godot --headless --path . --script res://tools/build_farming_assets.gd
godot --headless --fixed-fps 60 --path . --script res://tools/verify_farming.gd
godot --path . --script res://tools/render_farming.gd -- --out=/absolute/preview/folder
```

Rebuilding overwrites only generated farming meshes, materials, scenes and manifest;
preserve manual edits before doing so. The source recipes are
`tools/farming_buildings.gd`, `tools/farming_props.gd`, `tools/farming_crops.gd`, with
shared assembly in `tools/build_farming_assets.gd`. Deterministic per-asset seeds
make iteration repeatable. Preview PNGs are written outside the repository to avoid
inflating the game asset pack. `tools/check_workshop.sh` runs the farming verifier
and rejects Godot script errors as well as failed checks.

These commands rebuild the library and catalogue. To update its placement on the
map, follow the separate [village rebuild sequence](Village-fermier.md#rebuild-and-verify),
which prepares `planning/farming-town.json` and builds the saved village with
graphics enabled for its MultiMeshes.

Verification loads every saved prefab, checks finite geometry, bounds, pivot level,
mesh budgets, field collisions and hydraulic markers, and sweeps a character-sized
capsule through the open barns and gate. It also exercises catalogue selection,
search and return to the assembly. Contact sheets are rendered from these actual
saved resources, not generated concept images.

Validation on 2026-09-21: 54 pieces, 80,764 triangles for one copy of every piece,
at most 13 mesh instances per prefab, approximately 1.65 MB of saved library data
including its procedural shader (excluding the Godot import cache and preview PNGs).
The farming verifier passed 402 checks; the complete workshop wrapper passed.
Actual Forward+ / D3D12 contact sheets and catalogue views were inspected.
The production fast suite retained its pre-existing `test_every_landmark_kind_has_art`
failure on Brindle house names (present both before and after this kit); this pass
does not change the production map or its landmark mapping.

## Provenance

Original Godot geometry and procedural materials authored for this Uncrowned asset
commission on 2026-09-21. The builder reuses geometric construction helpers from
the existing workshop. No third-party model or texture downloads were introduced.
`assets/farming/catalog.json` records this origin; it does not assert a third-party
licence for the broader Brindle workshop assets.
