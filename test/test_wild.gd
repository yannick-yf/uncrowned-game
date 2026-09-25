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


# --------------------------------------------- W2, where the wood is dangerous ---

func test_no_pack_ever_stands_in_a_town() -> void:
	if not Places.baked():
		debt("the packs are anchored to his map; the 2D one stands nothing there")
		return
	# **`docs/COMBAT_V2.md` §6: in the forest, never in the towns.** Checked against the
	# resolved tile rather than against the anchor's name, because a name proves nothing:
	# `road_last_stop` sounds like open road and lands inside Cairnwell, which is how the
	# first draft of this put a wolf pack in the capital.
	var region: Region = Region.build_overworld()
	var wild := Wild.new()
	var packs: Array[Dictionary] = Wild.packs()
	assert_true(packs.size() >= 2, "there are packs at all: %d" % packs.size())
	for which: int in packs.size():
		var tile: Vector2i = wild.at(region, which)
		assert_eq(String(region.zone_at(tile)), "",
			"pack %d stands at %s, which is in a town" % [which, str(tile)])
		assert_true(region.is_passable(tile),
			"and on ground somebody could walk to: %s" % str(tile))


func test_a_pack_closes_no_road() -> void:
	if not Places.baked():
		debt("the packs are anchored to his map; the 2D one stands nothing there")
		return
	# **Invariant 4, and `PLAYER_MODEL.md` §8.** The demo funnels by where the danger is
	# and never by a check. A pack stands *on* a tile and does not make it impassable:
	# whoever wants that road fights or walks round, and Blackcairn stays reachable in
	# minute one, which is Pillar 1 and not negotiable.
	var region: Region = Region.build_overworld()
	var wild := Wild.new()
	for tile: Vector2i in wild.standing(region).keys():
		assert_true(region.is_passable(tile),
			"a wolf is not a wall: %s" % str(tile))


func test_walking_into_a_pack_is_what_starts_the_fight() -> void:
	if not Places.baked():
		debt("the packs are anchored to his map; the 2D one stands nothing there")
		return
	# The only way into a fight that nobody speaks first, and the whole difference
	# between a road and a wood.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var wild := sim.store(&"wild") as Wild
	var duel := sim.store(&"duel") as Duel
	var region: Region = world.region()
	var standing: Dictionary = wild.standing(region)
	assert_false(standing.is_empty(), "a pack is standing somewhere")
	if standing.is_empty():
		return
	var tile: Vector2i = standing.keys()[0] as Vector2i
	assert_false(duel.on(), "nothing is happening yet")

	world.player_pos = Vector2(tile) + Vector2(0.5, 0.5)
	sim.advance(2)
	assert_true(duel.on(), "walking into them is a fight")
	assert_eq(duel.asked_by, &"the_wood", "and the wood is what asked for it")
	var beasts: int = 0
	for fighter: DuelFighter in duel.fighters:
		if not fighter.is_player():
			beasts += 1
	assert_eq(beasts, wild.count_of(int(standing[tile])), "the whole pack, not one of them")


func test_a_pack_you_beat_is_gone_and_one_you_walk_away_from_is_not() -> void:
	if not Places.baked():
		debt("the packs are anchored to his map; the 2D one stands nothing there")
		return
	# Read off `duel_ended`, which the log already holds, so a replay rebuilds which
	# roads are clear without a second thing to keep in step.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	var wild := sim.store(&"wild") as Wild
	var region: Region = world.region()
	var before: int = wild.standing(region).size()
	assert_true(before > 0, "there is a pack to beat")
	# **The demo's pack, which is the first in the content file and the smallest.** Not
	# an arbitrary one: the first draft took whichever the dictionary handed back, drew
	# the pack of three, and the player lost — which is true of the wood and says nothing
	# about the mechanism this test is for. That the three win is asserted below, on
	# purpose.
	var tile := Vector2i(-1, -1)
	for spot: Vector2i in wild.standing(region).keys():
		if int(wild.standing(region)[spot]) == 0:
			tile = spot
	assert_true(tile.x >= 0, "the demo's pack is standing")
	world.player_pos = Vector2(tile) + Vector2(0.5, 0.5)
	sim.advance(2)

	var duel := sim.store(&"duel") as Duel
	var hands := DuelPlayer.new(DuelPlayer.PRESS)
	for _step: int in 12000:
		if not duel.on():
			break
		hands.play(sim, duel)
		sim.advance(1)
	assert_eq(duel.outcome, &"won", "the pack is beaten")
	sim.advance(2)
	assert_eq(wild.standing(region).size(), before - 1, "and that road is clear now")


func test_his_brother_has_drawn_no_beast() -> void:
	# **A DEBT and not a failure** (`CLAUDE.md`: a debt names something a person has to
	# settle). There is no animal anywhere in his library, so a wolf is a plain block in
	# his own rock paint — what is missing is *visibly* missing rather than quietly
	# borrowed from his traveller, which would have put a man on the road and called it
	# a wolf. `docs/POUR_SLOSINIO.md` asks him for one.
	var found: PackedStringArray = PackedStringArray()
	for folder: String in ["assets", "prototype_3d/assets/library"]:
		var at: String = "res://view3d/workshop/%s" % folder
		if DirAccess.dir_exists_absolute(at):
			for name: String in _under(at):
				if name.to_lower().contains("wolf") or name.to_lower().contains("beast"):
					found.append(name)
	if found.is_empty():
		debt("his brother has drawn no animal: a wolf stands as a block in his rock paint")
		return
	assert_true(false, "he has drawn one — delete the block: %s" % ", ".join(found))


func _under(path: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var listing: DirAccess = DirAccess.open(path)
	if listing == null:
		return out
	listing.list_dir_begin()
	var name: String = listing.get_next()
	while name != "":
		if listing.current_is_dir():
			out.append_array(_under(path.path_join(name)))
		else:
			out.append(name)
		name = listing.get_next()
	listing.list_dir_end()
	return out


func test_a_bigger_pack_is_a_longer_fight() -> void:
	# **This test was written the other way round and it was measuring a bug.** It said
	# three wolves beat a player who only presses, and they did — because a fight held
	# its fighters by the name of their kind, so every blow aimed at the second wolf was
	# resolved against the first, which was already dead. Seventeen blows into a corpse
	# while the other stood untouched. Fighters carry a seat now (`wolf`, `wolf#2`), and
	# the measurement changed completely: 4 turns, 5 turns, 8 turns, all won.
	#
	# So what is true is the shape rather than the outcome: **more of them is longer**.
	# Nothing here is dangerous at the hundred hit points Yannick set for development —
	# that is the point of the hundred, and the shipped number is open (S4).
	var turns: Array[int] = []
	for many: int in [1, 3]:
		var sim: Sim = Game.build()
		var world := sim.store(&"world") as WorldState
		world.player_pos = alone_on_the_road()
		var pack: Array[String] = []
		for _one: int in many:
			pack.append("wolf")
		sim.submit(&"duel_began", {"opponents": pack, "by": "wolf"})
		sim.advance(1)
		var duel: Duel = _duel(sim)
		_play(sim, DuelPlayer.PRESS, 12000)
		assert_eq(duel.outcome, &"won", "%d of them are beatable" % many)
		turns.append(duel.turns_taken)
	assert_true(turns[1] > turns[0],
		"and three take longer than one: %d against %d" % [turns[1], turns[0]])


func test_every_beast_in_a_pack_is_its_own_fighter() -> void:
	# The bug above, pinned so it cannot come back: three wolves are three seats, three
	# sets of hit points, and three things to kill.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	world.player_pos = alone_on_the_road()
	sim.submit(&"duel_began", {"opponents": ["wolf", "wolf", "wolf"], "by": "wolf"})
	sim.advance(1)
	var duel: Duel = _duel(sim)
	var names: Dictionary = {}
	for fighter: DuelFighter in duel.fighters:
		if fighter.is_player():
			continue
		assert_false(names.has(fighter.who), "no two share a name: %s" % fighter.who)
		names[fighter.who] = true
		assert_eq(DuelRules.kind_of(fighter.who), &"wolf", "and each is still a wolf")
		assert_eq(fighter.hp, DuelRules.hp_of(&"wolf"), "with a wolf's own health")
	assert_eq(names.size(), 3, "three of them")
