# Farming village on the workshop map

The farming settlement is built into the existing 768 × 768 m graphics workshop,
around the dry valley terrace near world XZ **(-179, 39)**. Its pale stone, oak,
plaster and thatched roofs use the original [farming asset kit](Village-fermier-assets.md).
The village is an environment-art composition: it adds no people, dialogue, story
events, crop economy or production-simulation behaviour.

## Open the actual village

Run **Ouvrir-village-fermier.cmd**. This launches the real playable map with the
character beside the village square. **Tab** switches between the free camera and
the character; **V** frames the farming village while in the free camera. The
normal project launch still starts at Brindle.

`scenes/sectors/village_fermier.tscn` is instanced at `Decor/VillageFermier` in
`scenes/map_plate.tscn`. The separate `scenes/catalogue_fermier.tscn` remains an
asset browser and sample assembly; it is not the village's map scene.

## Golden morning and orchard effects

`World/FarmingAtmosphere` applies the profile in `planning/farming-lighting.json`
when the active camera visits the farm. Run **Ouvrir-ambiance-fermiere.cmd** for
an orchard close-up; Tab uses the real character, V frames the village. Existing
village and normal game launches include the same lighting automatically.

The low warm sun is balanced by cool ambient fill. Its angular size and Ultra
shadow filtering soften roof and tree shadows; local SSAO retains contact depth.
Four gently bounded fog volumes follow the actual orchard trees and terrain.
The rest of the map has no added global fog density. The profile fades across
the region boundary and when zooming out, restoring the original environment,
sun and camera clipping ranges. In an orthographic view, concentrating the camera
far plane is necessary for directional shadow precision. The lighting grade and
sun affect the active view; the mist itself is spatially confined to the orchards.

Only living farm foliage uses the three shared local leaf materials: light
transmission, restrained subsurface scattering and a centimetre-scale breeze.
Fruits, trunks, houses and source asset materials retain their original setup.
Leaf/pollen effects prepare the 26 orchard trees, activate at most ten nearby
trees, and cap simultaneous GPU particles at **110** (60 leaves, 50 dust motes).
They fade during their lives, drift with the breeze and add no collisions.
Leaving the area pauses their simulation. No external textures are required.

A private copy of the river material softens golden-hour glare inside the farm
bounds; normal water settings are restored outside the lighting region. Offline
town generation removes the atmosphere controller before baking the sector, so
these runtime overrides are not saved into the source meshes or materials.

The project uses Forward+, required for volumetric fog and leaf subsurface
scattering. The profile uses fog volume size 160 with 128 depth slices, temporal
reprojection, Ultra soft-shadow filtering and High SSS. See the official
[volumetric fog guidance](https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html)
and [fog shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/fog_shader.html).

Actual-renderer captures and an uncapped, warmed A/B timing report can be created
outside the repository with:

```sh
godot --path . --script res://tools/review_farming_atmosphere.gd -- --capture --out=/absolute/preview/folder
godot --path . --script res://tools/review_farming_atmosphere.gd -- --benchmark --out=/absolute/preview/folder
```

The timing report is machine-specific. Its disabled pass keeps the same geometry
and local leaf materials, while restoring the baseline environment and pausing
particles. `verify_farming_atmosphere.gd` independently checks region transitions,
camera switching, fog placement and exact restoration of source resources.

Measured on 2026-09-21, Godot 4.7.2 D3D12 Forward+, RTX 5080, 1440 × 900,
VSync off: two 240-frame samples for each state/view after 90 warm-up frames.
The table averages the two reported GPU medians; it is not a minimum-hardware
guarantee. Frame-time p95 with the profile enabled stayed below 5.4 ms in these
three static views. No capture or asset generation ran during these samples.

| View | Baseline GPU | Golden profile GPU | Added GPU time |
|---|---:|---:|---:|
| Orchard close view | 0.834 ms | 1.532 ms | 0.698 ms |
| Village square | 1.409 ms | 1.793 ms | 0.384 ms |
| Whole farming village | 1.589 ms | 1.933 ms | 0.344 ms |

The workshop wrapper passed in 60.82 s, including 177 lighting-transition checks
and 423 placed-village checks. The main game's fast suite retained its existing
`test_every_landmark_kind_has_art` failure (345 tests, 10,380 assertions, 19.38 s
runner time); no production simulation or main-game art mapping was changed.

## Layout and circulation

The current authored plan has **13 buildings**, **12 cultivated or resting fields**,
**26 fruit trees in four orchard groups**, and **three timber bridges**. Eight
houses use distinct prefab designs. Two barns, a raised granary, an octagonal
grain store and the grain watermill provide the agricultural buildings.

| Area | Arrangement and purpose |
|---|---|
| `PlaceDuPuits` | Covered well, small market, benches and the main barn; paths run on both sides of the well rather than through its collision. |
| `Habitations` | Eight individual houses around the square and secondary lanes, with small gardens and door approaches. |
| `CourDesRecoltes` | Barn, raised grain storage, grain reserve, sacks, tools and a cart; storage stays beside the circulation routes. |
| `RiveDuMoulin` | Grain mill on a dry bank, loading apron and a separate water bypass on its wheel side. |
| `Cultures` | Golden wheat, vegetable plots, ploughed ground and fallow land; irregular outlines retain grass between fields, water and paths. |
| `Vergers` | Northern, eastern, southern and house-side fruit-tree groups, with open harvesting approaches. |

The main market road connects the eastern entrance to the western harvest bridge.
Secondary loops serve the houses, the grain court, the mill and the orchards. The
southern harvest route connects to the third crossing. Their visible wear is
painted onto the terrain; the hidden `Chemins` nodes retain editable route points.
The main cart road is 3.6 m wide, domestic lanes 2.2–2.3 m, and orchard/bief
footpaths 1.3–1.55 m. The old double loop around the northwestern houses has been
replaced by a smaller lane and a useful spur towards the irrigation gate. A rear
access reaches the main barn's through aisle.

Door approaches project onto the actual curved street, approach from the front
and finish perpendicular to each facade. Ground wear reaches `DoorFace`, or
the visible `StairBase` at the granary; its separate `StairFoot` marker is the
clear waiting position before the stair slope. The character's waiting position remains
outside the closed wall. Both visible store-annex doors also have short approaches.
Sacks beside the mill and granary, the mill cart and the house's integrated barrel
sit outside these access corridors. The grain-store steps use one smooth convex
collision envelope, following the visible tread noses, so the first riser no
longer stops the character.

The three bridges reuse `pont_charretier_bois_12m.tscn`, with 12 m decks and 3.4 m
clear widths. They are `PontEntreeVillage`, `PontDesMoissons` and
`PontDesVergers`. House doors are exterior scenery, while the open barn aisles,
street network and bridges provide the passages used to check character access.

## Water and ground

`RuisseauDesPres` descends from the northwestern hillside, passes west of the
inhabited terrace and continues along the southern fields. Its authored surface
falls from **35.8 m to 27.5 m**. Two connected branches share its position and
water level at their intake and return points:

| Branch | Intake | Working reach | Return |
|---|---:|---|---:|
| `BiefDuMoulin` | 30.60 m | 30.48 m through the undershot wheel and its 1.68 m clear trough | 30.10 m |
| `RigoleDesVergers` | 32.50 m | Irrigation branch around the northern and eastern edge of the dry settlement | 27.90 m |

The mill body stands on its own dry footing. The intake, wheel channel and outlet
must be adjusted together when changing the mill. Its rotating wheel is decorative
motion; the workshop does not calculate discharge, mechanical power or grain output.

`scripts/farming_terrain.gd` applies the plan's local terrace, foundation, channel
and bridge-approach adjustments to the in-memory terrain. Existing wet cells are
protected. The regional `.f32` height and water source files are not overwritten
by this farming pass. Field-specific cultivation levels create gentle prepared
terraces where the underlying hillside would otherwise be too steep.

Unlike the flat catalogue prefabs, the placed fields have private saved meshes
whose vertices follow the final terrain. Their earth triangles are subdivided to
a maximum projected edge of 0.85 m before height sampling, with a 4.5 cm soil
lift to avoid surface overlap. Crop height above ground is retained. Fields and
canopies remain traversable; fruit-tree trunks keep their simple source collisions.
Fruit trees share mesh/material MultiMesh batches within each orchard. Small
verge plants reuse the existing Brindle library and are filtered away from water,
building footprints and path clearances.

The 2026-09-21 meadow pass adds irregular grass patches beside the streams,
fences, gardens and orchard edges, sparse daisy groups and six additional
birches. `meadow_patches` in the plan controls their elliptical extents, density,
scale and deterministic seed. `meadow_clearings` preserves the village square,
loading court and mill apron. The builder also excludes cultivated field bounds,
steep slopes, water, buildings, props and paths. The grass
clumps share existing library meshes; the entire greenery group still uses nine
MultiMeshes. Small plants have no collision, and generated clumps do not add
individual scene nodes or per-frame placement work.

## Authoritative plan and editable output

Edit **`planning/farming-town.json`** for durable layout changes. Positions use
metres in world XZ and yaw uses degrees. The plan contains building and prop
placements, primary paths, field specifications, orchard blocks, water profiles,
terraces, bridge levels, dressing, greenery and review-camera/spawn positions.
Water and graded-path profiles use **[X, Z, height-Y]**.

`tools/prepare_farming_town.py` resolves catalogue bounds, house foundation pads,
door approaches, cultivation pads and individual trees from `orchard_blocks`.
It also calls `tools/paint_farming_paths.py` to paint
`assets/farming_village/ground_wear.png`: red is soil coverage, green is wheel
wear and blue is compacted doorstep/courtyard ground. Variable-width edges, faint
wheel traces and grass returning between agricultural wheel tracks distinguish
the different uses. `ground_areas` stores the irregular public courtyards;
`door_aprons` is generated from the true threshold markers. No general brown
rectangle is painted around a house's full asset bounds. Generated `Entree_*`
paths and expanded `orchards` entries are derived output; edit their building,
primary-path or orchard-block sources instead. The mill altitude and its water
alignment are authored explicitly.

`tools/build_farming_town.gd` composes the saved sector from the prepared plan.
Its helpers build furniture, conform fields and batch orchard/verge vegetation.
The scene's existing building prefabs remain shared with `assets/farming/`;
village-specific meshes and MultiMeshes are stored in `assets/farming_village/`.
The builder refreshes sampled placement altitudes in the plan when it saves.

Small `terrain.access_pads` provide doorway landings and their approach slopes;
they join the foundation grading pass and preserve water cells. They are separate
from the village's broad terraces so a doorstep adjustment stays local.

Manual scene changes are useful for inspection, but rebuilding replaces the
generated sector and its meshes. Record lasting changes in the plan or recipe
first. Moving an orchard marker alone does not move its saved MultiMesh instances.
Regenerate after changing terrain beneath fields or trees, or after changing a
building footprint that affects foundation and access geometry.

## Rebuild and verify

Saved assets and the saved village run without Python. For regeneration, run the
following from `prototypes/brindle_3d` with Godot 4.7.2, Python, NumPy and Pillow:

```sh
python tools/prepare_farming_town.py
godot --headless --editor --path . --import --quit
godot --path . --script res://tools/build_farming_town.gd
godot --headless --editor --path . --import --quit
godot --headless --fixed-fps 60 --path . --script res://tools/verify_farming_terrain.gd
godot --headless --fixed-fps 60 --path . --script res://tools/verify_farming_town.gd
```

The **town build must run with graphics enabled** so saved MultiMesh instance
transforms are preserved. Do not add `--headless` to that command. A global
`build_landscape.py` run is not required for a local farming-plan change. If the
prefab designs themselves change, first rebuild the library using the commands
in the [asset-kit guide](Village-fermier-assets.md), then run the town sequence.

For a change limited to `greenery`, `meadow_patches` or `meadow_clearings`, replace
only the vegetation in the saved town, retaining the buildings, fields and water:

```sh
godot --path . --script res://tools/build_farming_town.gd -- --greenery-only
godot --headless --fixed-fps 60 --path . --script res://tools/verify_farming_town.gd
```

This shortcut still requires graphics. Terrain, road and building changes require
the complete rebuild above so the seating and conformed fields stay in sync.

The terrain verifier checks deterministic local changes, protected source water,
unmodified regional source files, branch connections and mill water levels. The
town verifier checks the integrated scene, dry and seated buildings, routes,
door approaches, crops, tree collisions and well sightlines. It moves the actual
preview character around the well, across each bridge, along all thirteen main
door approaches and both annex approaches, and up the grain-store stair. It also
checks that the soil mask reaches the native doorway markers. These checks are
separate from visual inspection and production-game simulation tests.

To open the review or save actual-renderer captures outside the repository:

```sh
godot --path . --script res://tools/review_farming_town.gd
godot --path . --script res://tools/review_farming_town.gd -- --capture --out=/absolute/preview/folder
```

The capture command produces village, square, mill, field/bridge, orchard,
overhead and three close doorway views. The broader `tools/check_workshop.sh`
wrapper includes the farming kit and placed-village checks alongside the existing
workshop regressions.
