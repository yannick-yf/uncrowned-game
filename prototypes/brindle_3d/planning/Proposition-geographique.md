# Working geography — graphics workshop

This records the **768 × 768 m layout confirmed during the graphics session on
2026-09-13**. It is the workshop's working arrangement, not a replacement for the
production map specification. Detailed construction starts with Brindle and the mine;
the other settlement locations are reserved envelopes.

The map covers 589,824 m² (about 0.59 km²), including sea and natural boundaries.
Mountains are north/east, the sea west/south, and valleys carry the water network.
The regional height grid is 385 × 385 points, currently at two-meter intervals.
This is a compact game region; enlarging it requires another travel-time and layout pass.

## Placement

The map center is `(0,0,0)`, north is **−Z**, east **+X**, height **Y**. X/Z limits are
−384 to +384 m. Coordinates and full river paths are in `geographie-v1.json`.

| Working location | X, Z (m) | Reserved width × depth | Center altitude |
|---|---|---|---|
| City and castle | −150, −180 | 200 × 180 m | 63 m |
| Farming village | −170, 40 | 120 × 100 m | 29.9 m |
| Sawmill village | 235, −125 | 90 × 90 m | 53.9 m |
| Steel village | 255, 65 | 100 × 100 m | 41.2 m |
| Brindle | 175, 255 | 70 × 60 m | about 25 m |

The castle stands on a modeled spur above the city terrace. Farming occupies the
western lowlands; the sawmill borders the northeastern woods; the steel village has
water and access to the eastern mine. Brindle is near the southeastern woodland
edge. These envelopes include open land, slopes and banks, not just buildable plots.

## Water and terrain

Two northern streams feed the lake. Its outlet becomes the main river, descending
to the southwestern sea. The steel-village tributary comes from the east and joins
the river downstream of the farming area; it does not feed the lake.

Riverbeds are carved into the terrain. The lake surface is **40 m**, its central bed
**33 m**, and the highest mountains about **233 m**. Animated water represents current
direction; there is no discharge or flood simulation. Banks and local crossings need
to remain clear when settlement plans are detailed.

Terrain masks, river channels and local pads are editable. The lake and tributaries
were checked for continuity in the terrain data and renderer during their construction.
`apercus/map-relief-ensemble.png` and `map-lac.png` record that pass.

## Current detailed areas

Brindle has five houses and a barn with individual recent-burn ruin compositions,
a winding main route, smaller accesses, a well, yards and irregular woodland edges.
Building pads vary from about **24.3 to 27.2 m**. See
[Editing Brindle](Travailler-Brindle-dans-Godot.md).

The mine entrance is near `(308,46,80)`. Its bridge crosses the tributary at Z = 62 m,
linking it to the reserved steel-village area. The steel buildings remain to be placed
around that access and the riverbanks. This workshop authors terrain and scenery;
story, NPC placement and dialogue remain outside it.
