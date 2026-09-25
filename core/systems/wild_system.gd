class_name WildSystem
extends SimSystem

## **Walking into a pack is how a fight in the wood begins** (W2).
##
## The only system that starts a duel without anybody saying a word. `DialogueSystem`
## begins one because the player chose a line and `ActSystem` because somebody stood in
## the way; this one begins one because the player walked into an animal, which is the
## whole difference between a road and a wood.
##
## **Nothing here gates anything** (`PLAYER_MODEL.md` §8, and invariant 4). A pack does
## not close a road and is not asked whether a quest is finished: it stands on a tile,
## and a player who wants that road fights or goes round. The demo's funnel is made of
## *where the wolves are* and of nothing else, which is why **W4 can take it out by
## editing one content file**.

const REACH_TILES: int = 1


func steps() -> bool:
	return true


func ticks() -> bool:
	return false


func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type != &"duel_ended":
		return
	var wild := sim.store(&"wild") as Wild
	if wild == null or wild.fighting < 0:
		return
	# **Won means gone, and anything else means they are still there.** Walking away from
	# a pack leaves it on the road, which is the answer to "what happens if I run" that
	# costs no code: the road is still the dangerous one tomorrow.
	if String(event.data.get("how", "")) == "won":
		wild.cleared[wild.fighting] = true
	wild.fighting = -1


func on_step(sim: Sim, _step: int) -> void:
	var wild := sim.store(&"wild") as Wild
	var world := sim.store(&"world") as WorldState
	var duel := sim.store(&"duel") as Duel
	if wild == null or world == null or duel == null:
		return
	# One fight at a time, and no ambush during somebody else's.
	if duel.on() or duel.settling > 0:
		return
	var region: Region = world.region()
	var standing: Dictionary = wild.standing(region)
	if standing.is_empty():
		return
	var here: Vector2i = world.player_tile()
	for tile: Vector2i in standing.keys():
		if maxi(absi(tile.x - here.x), absi(tile.y - here.y)) > REACH_TILES:
			continue
		var which: int = int(standing[tile])
		wild.fighting = which
		var pack: Array[String] = []
		for _one: int in wild.count_of(which):
			pack.append(String(wild.kind_of(which)))
		# Derived rather than submitted, for `DialogueSystem`'s reason: the player's
		# event was the step they took, and the fight is the world's answer to it. A
		# replay recomputes it from the same walk.
		sim.derive(&"duel_began", {
			"opponents": pack, "by": String(wild.kind_of(which)), "asked_by": "the_wood",
		})
		return
