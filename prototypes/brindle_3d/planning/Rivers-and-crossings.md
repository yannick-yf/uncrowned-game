# Rivers and crossings — graphics workshop

The earlier channels had prescribed water levels far below the adjacent plains and
occasionally above the mountain terrain. A narrow blending strip made them read as
craters or raised canals. This revision reshapes the cross-sections and adjusts the
longitudinal levels while retaining the confirmed settlement layout and drainage network.

## Layout

| Crossing | Centre X, Y, Z | Deck length / clear width | Purpose |
|---|---|---|---|
| PontRouteRoyale | 30.0, 38.10, 20.0 | 20 m / 3.8 m | Shared crossing for the castle city, farming village and ironworks; keeps the trunk route readable. |
| PontScierie | 90.0, 40.95, -69.0 | 12 m / 3.4 m | Northern link between castle city and sawmill, forming a loop with the central road. |
| PontMine | 275.0, 43.75, 62.0 | 14 m / 3.4 m | Direct working route between the ironworks terrace and the existing mine entrance. |
| PontBrindle | 150.0, 32.40, 164.0 | 12 m / 3.4 m | Connects the existing northern village path to the trunk road with a clear landmark at the river. |
| PasserelleLisiere | 220.0, 34.75, 130.0 | 8 m / 1.8 m | Secondary foot route from Brindle's eastern woodland trail to the ironworks; creates a short exploration loop. |

The central and northern crossings create a loop between the castle city, sawmill
and ironworks. Brindle's main exit joins the trunk route; the eastern woodland foot
route offers a second way toward the ironworks. The mine crossing replaces the former
34-metre wooden blockout. Roads stop at bridge connection markers and continue from
the opposite bank. No storyline, NPC placement or simulation rules change here.

## Terrain and materials

The 385 × 385 height grid still covers 768 × 768 metres. River beds are approximately
1.35–1.8 m deep, with width variation and broader floodplain transitions. The lake
remains at Y=40 m. `river-layout-v2.json` contains the centreline profiles, widths,
depths and intended crossings; `assets/landscape/landscape.json` records their generated
positions and water levels. These are authored game terrain data, not a flow simulation.

The existing Brindle water material is retained; its shore foam is broken up instead
of drawing a continuous pale rim. Path ribbons sample the terrain more densely across
their width to avoid floating corners on the mine slopes. The original Brindle ruins,
scorch mask, smoke and house pads remain intact.

Only four selected local bridge models and their dependencies were imported from the
locally authored bridge kit: 20 m stone, 14 m stone, 12 m cart bridge and 8 m footbridge.
The standalone catalogue, other bridge models and its preview water/terrain were not
imported. `planning/river-bridge-assets.json` lists the selected resource files.
Buried footing extensions in the sector reach the actual river bed below the default
supports. Five bridge instances reuse these four models.

## Edit

1. Edit `planning/river-layout-v2.json` for river profiles, widths, depths or bridge
   anchors. Then run `python tools/build_landscape.py` (NumPy required).
2. Keep path endpoints in `planning/river-routes-v2.json` aligned with the generated
   `entry_xyz` / `exit_xyz` markers, with a straight tangent approaching each deck.
3. Run `tools/build_river_crossings.gd` with Godot's graphics renderer. It saves the
   crossing sector and removes vegetation newly occupying water or paths. As this
   removes conflicting saved instances, preserve a forest scene before large route
   experiments. Unaffected trees are retained.
4. The terrain applies the original artistic stamps, then bridge landing pads, so
   the older mine terraces cannot create steps at the deck entrances. `CourMine`,
   `RampeMine` and `ApprocheMine` blend into the shorter, angled mine access.
5. Inspect `map_plate.tscn`, or press Tab in the playable preview, then P to cycle
   through crossings. Use B for Brindle, M for the mine, F for the lake and R for the
   whole map. Scene instances can be moved in Godot, but their data anchors and the
   terrain pads must be moved together before rebuilding.

The 2 m regional terrain sampling is unchanged. Bridge landing widths include enough
buried overlap to cover sampling seams and keep the player from hitting an artificial
step. Local, finer terrain work can follow when settlement blocks are developed.

## Validation

- `python tools/verify_river_data.py`: every sampled river centreline, the lake and
  sea share one wet component; level profiles descend; settlement centres stay dry.
- `tools/verify_river_crossings.gd`: the actual workshop player crosses all five
  bridges from approach to approach in both directions and three lanes; probes check
  open water, dry routes, obstructions and walkable slopes (84 checks).
- `tools/check_workshop.sh`: existing ruin entrances, paths, terrain, player spawn
  and residual smoke still pass.

Rendered overviews and close views are stored locally with the delivery report; no
large screenshot catalogue is required by the map. Commit and push are separate steps.
