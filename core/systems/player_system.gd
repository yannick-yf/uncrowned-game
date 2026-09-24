class_name PlayerSystem
extends SimSystem

## The only thing that writes the player's own numbers.
##
## The same discipline `TownSystem` holds for a place: one event, one move, nothing in
## the codebase reaching into the store and setting anything. That is what keeps a save
## honest — the log holds every change, so a replay arrives at the same player.
##
## It answers with `purse_moved`, carrying what the purse now holds, because the
## journal has to be able to say where the gold went and the window has to be told
## something changed without watching a number.

func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type != &"move_purse":
		return
	var player := sim.store(&"player") as PlayerState
	if player == null:
		return
	var asked: int = int(event.data.get("amount", 0))
	var why: String = String(event.data.get("why", ""))
	var before: int = player.gold
	var moved: int = player.move_gold(asked)
	if moved == 0:
		# Nothing to give and nothing to take. Not an error — a body with no purse on
		# it is a body with no purse on it — but worth being able to see in a log.
		sim.derive(&"purse_unmoved", {"asked": asked, "why": why, "gold": player.gold})
		return
	sim.derive(&"purse_moved", {
		"from": before, "to": player.gold, "by": moved, "asked": asked, "why": why,
	})


## Nothing sixty times a second.
func steps() -> bool:
	return false


## And nothing on the world's clock: a purse does not drift. Standing does not either
## (`docs/PLAYER_MODEL.md` §3: *a town remembers*), so this system has no tick at all.
func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"player"
