class_name SaveFile
extends RefCounted

## A saved run, which is its event log and nothing else.
##
## This is what the architecture was for. Everything in the world — where the army
## stands, what six towns think of you, which furnaces are cold, what is in your
## hands — is derived from the events, so a save is the list of things the player
## did and loading is replaying them. There is no snapshot of the world here and
## nothing that can drift out of step with it.
##
## §19 row 5, settled 2026-09-12: **you save at a campfire and dying puts you back at
## the last one.** Phase 0's "respawn in Brindle keeping everything" is retired.
##
## A snapshot beside the log is the obvious optimisation when replaying a long run
## gets slow. Not built: measure first (§20).

const PATH: String = "user://save.json"
const VERSION: int = 1


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


## Write what happened. Only external events — a system's answers are recomputed,
## and storing them would replay each one twice.
static func write(sim: Sim) -> bool:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({
		"version": VERSION,
		"seed": sim.rng_seed,
		"step": sim.step,
		"events": sim.events.external_rows(),
	}))
	return true


## Rebuild the run. Returns null if there is nothing to rebuild, or if the file was
## written by a version that did not mean the same thing by it.
static func read() -> Sim:
	if not exists():
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not (parsed is Dictionary):
		return null
	var save: Dictionary = parsed as Dictionary
	if int(save.get("version", 0)) != VERSION:
		return null
	return Game.replay_rows(
		save.get("events", []) as Array, int(save.get("seed", Sim.DEFAULT_SEED)),
		int(save.get("step", 0)))


static func discard() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
