extends TestCase

## **The wood, and what lives in it** — the W group of `docs/DEMO_TASKS.md`.
##
## `docs/COMBAT_V2.md` §6: monsters live in the forest and never in the towns, and the
## reason they are affordable at all is that a monster is four things — hit points, a
## damage number, a reach, and one rule for its turn. Everything below is that claim
## being checked rather than believed.
##
## **These are the fast suite's**, for `test_combat.gd`'s own reason: the wild is what
## gets retuned most, and a balance change you have to remember to check is one nobody
## checks.

const SLOW: bool = false


func _duel(sim: Sim) -> Duel:
	return sim.store(&"duel") as Duel


## A fight in the open, because a wolf's whole behaviour is *closing the distance* and a
## fight begun in a doorway measures the doorway. Said in the world's terms rather than
## as a tile, so it holds on the baked map and the 2D one alike.
func _meet(against: String = "wolf", by: String = "wolf") -> Sim:
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	world.player_pos = alone_on_the_road()
	sim.submit(&"duel_began", {"opponent": against, "by": by})
	sim.advance(1)
	return sim


func _play(sim: Sim, policy: StringName, steps: int) -> void:
	var hands := DuelPlayer.new(policy)
	var duel: Duel = _duel(sim)
	for _step: int in steps:
		if not duel.on():
			return
		hands.play(sim, duel)
		sim.advance(1)


# ------------------------------------------------------------------ W1, a wolf ---

func test_a_wolf_is_four_numbers_and_nothing_else() -> void:
	# The whole of a monster, and the reason turn-based made them cheap enough to have.
	# Read off the table rather than written here, so the table stays the one place.
	assert_eq(DuelRules.hp_of(&"wolf"), 10, "hit points")
	assert_eq(DuelRules.strike_damage(), 5, "one damage number, the same for everybody")
	assert_eq(DuelRules.reach_tiles(), 1, "a reach")
	assert_false(DuelRules.spares(&"wolf"), "and it does not stop when you go down")


func test_a_wolf_dies_in_two_and_a_man_takes_three() -> void:
	# **The difference is the point.** A wolf that took as long to kill as Harry would be
	# a man in a fur coat; what makes the wood dangerous is that wolves come in more than
	# one, not that one of them is hard.
	assert_true(DuelRules.hp_of(&"wolf") < DuelRules.hp_of(&"harry"),
		"a wolf is not a man with fur")
	var blows: int = ceili(float(DuelRules.hp_of(&"wolf")) / float(DuelRules.strike_damage()))
	assert_eq(blows, 2, "two blows put one down")


func test_a_wolf_closes_and_bites_and_can_be_killed() -> void:
	var sim: Sim = _meet()
	var duel: Duel = _duel(sim)
	assert_true(duel.on(), "it is on you")
	var mine: DuelFighter = duel.me()
	var beast: DuelFighter = duel.foe()
	var apart: int = DuelRules.apart(mine.at, beast.at)
	assert_true(apart > DuelRules.reach_tiles(), "and it starts out of reach: %d" % apart)

	_play(sim, DuelPlayer.PRESS, 4000)
	assert_eq(duel.outcome, &"won", "it can be killed")
	assert_eq(beast.hp, 0, "and it is down, not merely driven off")


func test_a_wolf_kills_a_player_who_only_stands_there() -> void:
	# The other half, and it needs a bar a wolf can empty: the shipped hundred is
	# Yannick's development value — twenty turns of standing still — and this test is
	# about whether a wolf is dangerous at all, not about the balance.
	var sim: Sim = _meet()
	var world := sim.store(&"world") as WorldState
	var duel: Duel = _duel(sim)
	world.player_hp = 10
	(duel.me()).hp = 10
	_play(sim, DuelPlayer.STAND, 8000)
	assert_eq(duel.outcome, &"lost", "stand in front of a wolf and it kills you")


func test_the_same_wolf_fight_played_twice_comes_out_the_same() -> void:
	# W1's check, and the reason the design has no dice anywhere: determinism by
	# construction rather than by seeding. Two worlds on two seeds, the same hand.
	var first: Sim = _meet()
	var second: Sim = _meet()
	_play(first, DuelPlayer.PRESS, 4000)
	_play(second, DuelPlayer.PRESS, 4000)
	var one: Duel = _duel(first)
	var two: Duel = _duel(second)
	assert_eq(one.outcome, two.outcome, "the same result")
	assert_eq(one.turns_taken, two.turns_taken, "in the same number of turns")
	# **The logs, not the fighters.** A settled duel keeps nobody — `me()` and `foe()`
	# both hand back nothing once it is over — and asking one of them for a tile raised
	# a runtime error that abandoned this function silently while it still printed `ok`.
	# That is the exact failure `CLAUDE.md` warns about, and the runner caught it.
	#
	# Comparing the turns themselves is the stronger claim anyway: not merely the same
	# result in the same number of moves, but the same moves.
	var moves_of := func(sim: Sim) -> Array[String]:
		var out: Array[String] = []
		for row: SimEvent in sim.events.of_type(&"duel_turn"):
			out.append(str(row.data))
		return out
	var ours: Array[String] = moves_of.call(first)
	var theirs: Array[String] = moves_of.call(second)
	assert_true(ours.size() > 2, "there were turns to compare: %d" % ours.size())
	assert_eq(ours, theirs, "and every turn is the same turn")


func test_a_pack_is_what_makes_the_wood_dangerous() -> void:
	# Not one hard animal — several ordinary ones. The duel takes a list, which is what
	# lets *you can kill everyone* mean three people in a yard as well as three wolves on
	# a road, and it is why "no party" in the design means "no allies" rather than "two
	# fighters".
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	world.player_pos = alone_on_the_road()
	sim.submit(&"duel_began", {"opponents": ["wolf", "wolf", "wolf"], "by": "wolf"})
	sim.advance(1)
	var duel: Duel = _duel(sim)
	assert_true(duel.on(), "a pack is a fight")
	var beasts: int = 0
	for fighter: DuelFighter in duel.fighters:
		if not fighter.is_player():
			beasts += 1
	assert_eq(beasts, 3, "and there are three of them")
