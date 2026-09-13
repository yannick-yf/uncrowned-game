# Graphics workshops

Open [Brindle 3D](brindle_3d/README.md) for the editable 768 × 768 m landscape,
Brindle's burned village and the 2D character movement preview.

This is a separate Godot project inside the same repository. `prototypes/.gdignore`
keeps its resources out of the main game's import, script discovery and exports.
Open `brindle_3d/project.godot` explicitly to work on it. Its `res://` paths resolve
inside that project; they are not paths in the production game's root project.

The main game still opens from the repository's root `project.godot`.
