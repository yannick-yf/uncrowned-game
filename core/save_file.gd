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
## gets slow. Not built, and now **measured** rather than guessed at (2026-09-19,
## Yannick asked whether the whole idea was worth its complexity):
##
## | played | rows in the save | to load |
## |---|---|---|
## | 1 hour | 1 | 4.2 s |
## | 2 hours | 1 | 8.6 s |
##
## Linear, as it must be: loading re-simulates every step. **The demo is thirty to sixty
## minutes, so two to four seconds** — fine, and not worth a snapshot yet. A ten-hour run
## would be forty seconds, which is not fine, and that is when this gets built.
##
## The row count is not a typo. An hour of walking is one event, because holding a key
## is one event; the log grows with what the player *does*, not with how long they do it.

const PATH: String = "user://save.json"
## 2 since O1 (2026-09-29): a won spar used to replay as a killing, and now yields.
## 3 since T5 (2026-09-29): an arrow lands when it is shot, so a fight against a bow
## replays differently.
## 4 since group V (2026-09-30): the gate's answer, where a foe is set down, and what is
## within reach of a furnace all changed, so a run through any of them replays otherwise.
## 5 since group E (2026-10-01): the player strikes with what he carries — a run that
## fought with fists, or through armour, replays otherwise.
const VERSION: int = 5
## Where the save is written. `PATH`, except under test: the suite shares `user://`
## with the game, and a test that discards its save must not discard the player's (O4).
static var path: String = PATH


## **The ground a save was written on** (O4, 2026-09-29). A run is its event log, and a
## log replayed on other ground walks into walls: a re-bake changes the ground and a
## person moved in `places.json` changes where things stand. So a save names its world
## and a hash of the two files that make it — `region.json` on the baked world, and
## `places.json` on both — and any other ground refuses it without anybody having to
## remember to bump `VERSION`. `VERSION` stays for changes to the rules.
static func world_key() -> String:
	var ground: String = FileAccess.get_sha256(Places.PATH)
	if Places.baked():
		ground = FileAccess.get_sha256(Places.BAKED_PATH) + ground
	return "%s:%s" % [Places.world_id(), ground.sha256_text().substr(0, 16)]


## Whether there is a save **for this world**. A run is its event log, and a log
## replayed on another world walks into walls, so a save from the 2D map is no save
## at all once the game plays on the baked world (M4, 2026-09-13). One written before
## worlds had names is the 2D map's.
static func exists() -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return false
	var save: Dictionary = parsed as Dictionary
	return int(save.get("version", 0)) == VERSION \
		and String(save.get("world", Places.PROCEDURAL)) == world_key()


## Write what happened. Only external events — a system's answers are recomputed,
## and storing them would replay each one twice.
static func write(sim: Sim) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({
		"version": VERSION,
		"world": world_key(),
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
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
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
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
