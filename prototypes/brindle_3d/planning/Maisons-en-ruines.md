# Brindle — recently burned ruin variants

The five houses and barn retain the positions, pivots, footprints, foundations and
source materials of the existing buildings. Each has an authored collapse pattern,
rather than a differently seeded version of the same silhouette.

![Six compositions](../apercus/brindle-ruines-six-variantes.png)

| Building | Scene in `assets/brindle_ruins/` | Composition |
|---|---|---|
| MaisonDuHaut | `maison_du_haut.tscn` | Tall fractured rear gable; roof collapsed to the right; open front. |
| MaisonDuChemin | `maison_du_chemin.tscn` | Nearly razed; low foundations and a central pile of smoking charred timbers. |
| MaisonDesBouleaux | `maison_des_bouleaux.tscn` | Two surviving walls in an L; part of the left roof slope on its rafters. |
| MaisonBasse | `maison_basse.tscn` | Surviving facade with an empty window and burned lintel; rear annex collapsed outward. |
| MaisonDuSud | `maison_du_sud.tscn` | Isolated tall chimney; low wall stumps and a large fallen wall panel. |
| Grange | `grange.tscn` | Open timber barn; standing rear roof truss, torn cladding and a fallen side of roofing. |

## Geometry and editing

Open a variant scene to edit its destruction, or its instance under
`Decor/Brindle/Maisons` to edit placement. Wall polygons are hollow extrusions with
jagged upper edges; tiles, stones, shutters and timber reuse source mesh components.
The original solid wall blocks and habitation lights are absent.

`FondationOrigine`, `MurBrise…`, `CharpenteDebout…`, `ToitureEffondree…`,
`GravatsFrais…` and `SeuilDegage` organize the geometry. Small pieces are batched by
material; editing one tile requires changing its recipe or mesh. Walls, foundations,
main timbers and large debris have collision shapes. Small chips are decorative.
The six thresholds have walkable rubble ramps, but these are not furnished interiors.

The intact `cottage_village.tscn`, `cottage_fisher.tscn` and `storehouse.tscn` remain
in `prototype_3d/assets/library/houses/`. Reinstantiate one at the original transform
and ground offset to restore an intact building. `ruines-brindle.json` records the
source/variant mapping.

## Reconstruction

`tools/build_recent_ruins.gd` assembles and saves all six scenes offline. `_recipe()`
holds the wall height profiles, roof selection, chimney height, door layout, timber
count and debris center/spread. Seeded randomness only chips edges and distributes
small debris. The actual source roof pitch is measured so retained tiles meet their
rafters and fallen sheets meet the rubble.

After Godot has imported this project, run from the repository root:

```sh
godot --headless --path prototypes/brindle_3d --script res://tools/build_recent_ruins.gd
```

The recipe overwrites generated variants: preserve manual changes first. It reapplies
the burned materials and smoke. The organic village recipe uses these ruined
variants when present; it does not silently restore intact houses.

## Fire, smoke and ground

Burned materials are separate resources in `assets/brindle_ruins/burned_materials/`.
`shaders/burned_surface.gdshader` adds char, soot and ash to the Brindle material
family; **Burn Amount** controls intensity. Source material resources stay intact.

`scenes/effects/fumee_ruine.tscn` is instanced as `FumeeResiduelle` in MaisonDuChemin
and MaisonBasse, with 18 CPU particles each. The emitters rise slowly from the debris,
expand, drift and fade. Their source heights match the lower rubble piles.
Edit **Amount**, **Lifetime**, **Scale Amount** and **Color Ramp** to adjust the effect.
`shaders/ruin_smoke.gdshader` supplies the soft billboard rendering.

`assets/landscape/brindle_scorch_mask.png` uses the same bounds and resolution as
Brindle's ground mask. Red is burned ground, green ash, blue the dry transition.
It affects both terrain and low vegetation around the building foundations.

After moving buildings, run `tools/apply_ruin_fire.gd -- --mask-only` in this project
to regenerate the scorch mask and smoke scene. Let Godot reimport the PNG, then run
the same script without arguments to apply the finish to houses and vegetation.
These steps also overwrite generated resources; preserve manual edits first.

The current geometry was rendered from six angles and inspected in Godot. The
actual character crossed all six entrances; route collision checks remained clear.
Two smoke emitters and the burned ground were retained.
