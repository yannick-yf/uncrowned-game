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
	var player := sim.store(&"player") as PlayerState
	if player == null:
		return
	if event.type == &"deed_witnessed":
		_deed(sim, player, event)
		return
	if event.type != &"move_purse":
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


## **A deed moves the town it happened in, and no other** (J2).
##
## It listens for `deed_witnessed` rather than reaching into `Deeds.perform`, and that
## is the design rather than plumbing: **witnessing is what makes a deed count** (§3),
## `Deeds` already decides who saw it, and a deed nobody saw derives one of the
## `*_unseen` events instead — which this never hears. So stealing stays a choice about
## where and when rather than a slider, and nothing here has to know it.
##
## No place → place propagation (§4). The story still travels — `RumourSystem` carries
## it, and the old model's `Standing.by_town` still moves as it arrives, until C3 —
## but the player's standing moves once, where the deed was done.
func _deed(sim: Sim, player: PlayerState, event: SimEvent) -> void:
	var deed: StringName = StringName(String(event.data.get("about", "")))
	var town: StringName = StringName(String(event.data.get("town", "")))
	var effect: float = PlayerRules.standing_effect(deed)
	var before: float = player.standing_in(town)
	var moved: float = player.shift_standing(town, effect)
	if moved == 0.0:
		# A place outside the system — Brindle, a ruin with nobody in it to have an
		# opinion, or the road — or a deed the model has not priced, or a town already
		# at the floor. None is an error; all are worth seeing in a log.
		sim.derive(&"standing_unmoved", {"town": String(town), "about": String(deed)})
		return
	sim.derive(&"standing_moved", {
		"town": String(town), "about": String(deed),
		"from": before, "to": player.standing_in(town), "by": moved,
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
