# Ironworks settlement — graphics workshop

The west-bank terrace now contains 27 substantial buildings, compared with the
six ruined buildings in Brindle. The inhabited and industrial footprint occupies
approximately 100 × 104 m, extending northwest from the existing mine junction.
The settlement uses the approved stone, slate and heavy-timber ironworks kit.
No new mesh copies or additional external art packs are required.

## Spatial organization

- The existing mine feeds the two sorting halls immediately north of its bridge.
  Ore heaps, crushing slabs and roasting beds share this receiving court.
- Six charcoal bloomeries occupy a mineral working yard, with two lit furnaces.
  Two covered hammering/finishing forges stand opposite, across the retained cart
  road. The intended product here is a solid iron bloom, not poured molten steel.
- Two charcoal stores sit beside the northern sawmill approach, separate from the
  hot working yard. The loop allows supplies to arrive without using residential
  lanes. There is no charcoal-burning mound among houses.
- Finished bars go to two stores beside the southern shipping court. The weighing
  office, tool workshop, wagon shelter and stables face the main regional road.
- The northwest district has seven individually designed houses, four different
  workers' barracks and an L-shaped foreman's residence. Curved lanes converge on the well and common kitchen. The
  granary, household wood stacks, small yards and five existing birches make the
  service/residential side visually distinct from the hot yard.
- Latrines sit at the outer western and southern edges, away from the well. Cold
  slag is held behind low stone curbs on the southern industrial side; the river
  channel and the footpath to the southern crossing remain open.

Existing regional connections, the mine excavation, the five bridges and Brindle
are retained. This scene contains graphics and physical access only; it defines
no NPC, dialogue, story progression, settlement simulation or production rules.

## Editing in Godot

Open `scenes/map_plate.tscn`, or run `scenes/test_brindle.tscn`. In the free camera,
**I** frames the ironworks, **M** the mine, **P** the next bridge and **B** Brindle.
**Tab** switches between free camera and the current player's position. The usual
game preview still starts in Brindle; `Ouvrir-village-acierie.cmd` opens a separate
review directly in the new town, with the player ready near its southern square.

The saved composition is `scenes/sectors/acierie.tscn`. Expand `Decor/Acierie` and
move individual instances in Habitations, Services, Production, Dechets or Abords.
All reusable kit meshes remain shared. The sector's existing terrain alignment
script seats roots again after a terrain edit.

Each major building has a matching `Sol_<building>` pad under `ReliefGodot`.
Move that pad with its building and change its Y/footprint/blend for grading;
houses should remain upright. Broad terrace handles supply the gentle district
transitions. Water-bank protection and bridge landing grading remain active.

Paths are editable `ground_path.gd` nodes under `Acierie/Chemins`. Their points
follow terrain height. The industrial dirt/soot/stone mask is local to this town;
regional road colour blends into that mask only inside its bounds.

`planning/ironworks-town.json` records the delivered positions, bounds and access
points. `tools/build_ironworks_town.py` is the offline composition recipe (Python,
NumPy and Pillow). Running it regenerates this town scene, its paint mask and its
own terrain pads from the recipe, replacing manual changes to those town items.
It preserves unrelated relief handles. Prefer native Godot editing for subsequent
local art work, or update the recipe deliberately before rebuilding.

## Validation

`tools/check_workshop.sh` imports and checks the delivered project. The town check
samples dry, level foundations, uses a full player-sized capsule across three
lanes of local paths and local regional roads, walks the real character to all
27 exterior approaches, and traverses the four open production halls and wagon
shelter. The separate river suite retains all 84 crossing/route checks. Brindle's
existing ruin entrances, scorch mask and two smoke emitters are checked separately.

The scene is an editable first built version, not a finished population or an
interior set: closed houses remain solid exterior scenery.

## Asset coherence pass — 14 September 2026

The composition now uses 60 outside props and 27 buildings. Redundant outdoor
stocks and a duplicate workbench were removed. Spare tuyères and the grindstone
are fully under existing roofs; `sheltered_by` records their host in the manifest.
Cold slag occupies a graded, retained yard. Latrines and the southern stable were
repositioned or graded to seat their feet without creating a lip on the main road.

The shared asset scenes were corrected at source: closed timber roof infill,
appropriately sized timber shutters, side-facing house wings/woodsheds, attached
awnings below the main eaves, supported weighing counter, unobstructed doors,
connected bellows and hearth, open forge hood and bread oven mouth, supported
sieve and grindstone axle, complete storage racks, straw-filled supported mangers,
contained cart loads and parking props. The gallery barrack has an upper door, a supported
gallery and usable stairs with rail collisions. The granary has supported steps
and a continuous walking surface.

`tools/build_ironworks_assets.gd -- --used-only` rebuilds only the assets referenced
by the town manifest while retaining the remaining approved catalogue entries.
Run it with Godot's `--headless --path . --script` options, then run the town recipe
to refresh bounds and access positions. A full kit rebuild remains available by
omitting `--used-only`. These are offline tools, never runtime dependencies.

`verify_ironworks_coherence.gd`, included in `check_workshop.sh`, adds 117 checks:
mesh contact points for every placed kit instance, actual player access to the
primary and annex doors, the gallery barrack stair and upper door, forge air supply
connections, and roof coverage over dry equipment. It supplements the 192 town
checks and 84 river/bridge checks; `verify_ironworks.gd` validates all 62 kit scenes.


## One building, one design

Every one of the 27 main building instances now has its own saved scene and
structural geometry. The 12 residences were rebuilt as 8 houses (including the
foreman's house) and 4 workers' barracks. Five repeated industrial/service halls
were replaced by purpose-specific designs. The two small latrine buildings also
differ. The four superseded generic housing assets and their meshes were retired.

The roof forms, footprints, heights, wall construction, doors, porches and annexes
are individually authored in `tools/ironworks_building_designs.gd`. Common stone,
slate, timber and metal materials keep the settlement visually coherent. All
construction runs offline; saved scenes remain editable in Godot.

The town verification rejects duplicate scene paths and duplicate wall/roof
geometry after accounting for translation and quarter-turn rotations. It ignores
colour and decoration, so recolouring a duplicate cannot satisfy the check. It
also requires four barracks and preserves the usual terrain and walking checks.

| Residence position | New design | Type |
|---|---|---|
| `MaisonEntreeNord` | Logis de la porte basse | house |
| `MaisonPignon` | Maison aux deux volumes | house |
| `MaisonHaute` | Baraquement des équipes | barrack |
| `MaisonArdoise` | Logis d’angle à colombages | house |
| `MaisonCourInterieure` | Baraque décalée de la cour | barrack |
| `MaisonVirage` | Maison du virage | house |
| `MaisonVenelle` | Maison haute de la venelle | house |
| `DortoirNord` | Baraquement de la grande cour | barrack |
| `DortoirPlace` | Baraquement à galerie | barrack |
| `MaisonContremaitre` | Logis du contremaître en L | house |
| `MaisonOuest` | Maison basse des charretiers | house |
| `MaisonJardin` | Maison au toit décalé | house |
