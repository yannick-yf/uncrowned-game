extends SceneTree

## `godot --headless --path . -s tools/play_opening.gd` — the demo's opening played
## headless by `OpeningRun`, stage by stage, with the table of what each cost. Exits 1
## if a stage stops.

func _initialize() -> void:
	var run := OpeningRun.new()
	var ok: bool = run.play()
	print("the opening, played —")
	print(run.summary())
	quit(0 if ok else 1)
