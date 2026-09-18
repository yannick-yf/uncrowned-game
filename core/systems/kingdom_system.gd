class_name KingdomSystem
extends SimSystem

## The kingdom handing the food back out — **rule 6**, and the arrow that was missing.
##
## Until this existed the world only ran one way: places sent to the crown and nothing
## ever came back, so stopping a works cost the farms nothing and helping the farms did
## nothing for the works. This is the return leg, and it is what makes the star a
## machine rather than a diagram.
##
## **A point a day, and only the food.** Richesse drifts one step toward what there is
## to eat, once an in-game day — slow enough that a player watches a consequence arrive
## rather than finding it already there, fast enough to happen inside one session. The
## matériel never comes back: the crown keeps what arms it, which is exactly what the
## people at the furnaces complain about.
##
## **Two things it cannot do.** It never touches allégeance — who a place is with is the
## player's business and no one else's. And it never drifts a place below the food
## floor, so the kingdom can make a place suffer and cannot starve it to death.

func on_tick(sim: Sim, tick: int) -> void:
	# Once a day rather than every minute: a harvest is not a thing that arrives sixty
	# times a second, and an integer that moves once a day is one a player can follow.
	if tick <= 0 or tick % Game.TICKS_PER_IN_GAME_DAY != 0:
		return
	var towns := sim.store(&"towns") as TownState
	if towns == null:
		return
	var food: int = maxi(roundi(KingdomRules.kind_supply(towns, KingdomRules.VIVRES)),
		TownRules.FOOD_FLOOR)
	for place: StringName in towns.ids():
		# A place whose quest is resolved is frozen. Its story is told.
		if towns.is_settled(place):
			continue
		# **And the source is not fed by itself.** A place that grows the food does not
		# drift on the food: its wealth is its harvest, not its rations. Without this the
		# model eats its own tail — feeding the farms raises the very number that feeds
		# them, every place converges on the same figure within a week, and helping one
		# place stops reaching another. A test caught it doing exactly that.
		#
		# It also agrees with the distinction Yannick insisted on: stopping a steel works
		# makes the king poorer and worse armed, and makes nobody hungry.
		if KingdomRules.category_of(KingdomRules.sends(place)) == KingdomRules.VIVRES:
			continue
		var now: int = towns.richesse_of(place)
		if now == food:
			continue
		var direction: int = 1 if food > now else -1
		if towns.set_value(place, TownRules.RICHESSE, now + direction):
			sim.derive(&"town_fed", {"place": String(place), "to": now + direction,
				"food": food, "look": String(towns.look_of(place))})


## Nothing sixty times a second.
func steps() -> bool:
	return false


func system_name() -> StringName:
	return &"kingdom"
