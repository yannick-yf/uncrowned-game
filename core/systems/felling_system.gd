class_name FellingSystem
extends SimSystem

## **What killing somebody costs, and what it leaves behind** (K3).
##
## The half the first fight design had none of. `DuelSystem` decides that somebody is
## down; this decides what that *means* — the world stops drawing them, the town it
## happened in thinks less of you for it, and their gold is on the ground.
##
## **Nothing here asks who they are.** `docs/COMBAT_V2.md` §5: anybody can be attacked,
## and a quest's key person is no more protected than a wolf. What keeps the game
## finishable is invariant 7, and it is already proved the right way: the levers that
## end the reign are *places*, and a place cannot be murdered.
##
## Three things happen and they are separate on purpose.

## The fact a death writes, so that `OpeningRules.is_gone` can read it. **A fact rather
## than a flag** — the same reason the fairy's leaving is a fact: a replay rebuilds it
## for free and nothing has to be kept in step.
const KILLED: String = "killed:%s"


func steps() -> bool:
	return false


func ticks() -> bool:
	return false


func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type != &"duel_down":
		return
	var who := StringName(String(event.data.get("who", "")))
	if who == Duel.NOBODY or who == DuelRules.PLAYER:
		return
	var duel := sim.store(&"duel") as Duel
	var world := sim.store(&"world") as WorldState
	if duel == null or world == null:
		return
	var kind: StringName = DuelRules.kind_of(who)

	# 1. **They are gone.** Written against the kind, not the seat, because it is a
	#    person the world stops drawing and `wolf#2` is not a person.
	sim.facts.add_source(StringName(KILLED % kind), &"witnessed")

	# 2. **Their gold.** A body carries what it carried, which is the answer to where
	#    the player's richesse comes from before there is anything to sell.
	var purse: int = DuelRules.purse_of(kind)
	if purse > 0:
		sim.derive(&"move_purse", {"amount": purse, "why": "taken from %s" % kind})

	# 3. **The town's opinion**, and only when there was a town and a person to lose.
	#    An animal in a wood offends nobody, which is why the wood is where the game
	#    lets you practise.
	var cast := sim.store(&"cast") as Cast
	if cast == null or cast.get_npc(kind) == null:
		return
	var here: StringName = world.region().zone_at(world.player_tile())
	if here == &"":
		return
	# **Who drew first decides which deed it is** (`PLAYER_MODEL.md` §3). The player
	# starting the fight makes it murder at −80; being set upon and finishing it makes
	# it −20. The duel already records who began, so nothing here has to guess.
	var mine: bool = duel.started_by == DuelRules.PLAYER
	var deed: StringName = PlayerRules.DEED_KILLED_INNOCENT if mine \
		else PlayerRules.DEED_KILLED_ATTACKER
	Deeds.perform(sim, deed, here, world.player_pos)
