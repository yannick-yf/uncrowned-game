# Brindle 3D graphics workshop

The graphics branch now carries the Brindle map work in
[`prototypes/brindle_3d`](../prototypes/brindle_3d/README.md). Open that folder's
`project.godot` in Godot 4.7.2 to review the 768 × 768 m landscape, burned village,
forests, water, mine and 2D character movement preview.

This imports the independently developed art workshop into version control.
`prototypes/.gdignore` isolates it from the production project, so the root launch,
simulation, cast, dialogue, save format and current asset validator remain intact.
The root `core/`, `view/`, `content/` and production `project.godot` match `main`.

The session explicitly chose the Brindle sources, a 3D environment with a 2D character,
and individual recently burned ruins. The workshop records that visual direction for
review; it does not amend `SPECS.md` §13's production asset policy or the simulation's
map. The geometry and controls are not yet wired into `Sim.advance()`, place states,
event replay or production navigation. That integration needs its own change.

The [workshop README](../prototypes/brindle_3d/README.md) documents opening, controls,
reconstruction, provenance and limitations. Its planning guides identify the editable
scenes and six collapse recipes. The smoke/scorch finish is separate from the intact
source resources, making further art iterations reversible.

CI runs the production suite and the independent workshop import/collision check.
Rendering was reviewed locally in Godot; headless checks cannot validate appearance.
