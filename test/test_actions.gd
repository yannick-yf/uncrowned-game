extends TestCase

## **What the player can do on his turn, and to whom** (group N). The wheel and the
## targeting read `ActionRules`; these check that what it offers follows what he carries
## and knows, and that every number it shows is the one the blow then uses.

const SLOW: bool = false


func _offered(sim: Sim, round_now: int = 1) -> Array[Dictionary]:
	var me := DuelFighter.new()
	me.who = DuelRules.PLAYER
	return ActionRules.offered(sim.store(&"inventory") as Inventory, sim.facts, me, round_now)


func _entry(offered: Array[Dictionary], id: StringName) -> Dictionary:
	for entry: Dictionary in offered:
		if entry["id"] == id:
			return entry
	return {}


func test_the_wheel_has_its_categories_in_order() -> void:
	assert_eq(ActionRules.categories(), [&"melee", &"ranged", &"magic", &"items", &"wait"] as Array[StringName],
		"blade, bow, magic, items, wait — clockwise from the top")
	for category: StringName in ActionRules.categories():
		assert_true(ActionRules.icon_of(category) != &"", "%s has an icon" % category)


func test_what_is_offered_follows_what_he_carries_and_knows() -> void:
	var sim: Sim = Game.begin_run(TraitRules.at_the_floor())
	var start: Array[Dictionary] = _offered(sim)
	assert_eq(_entry(start, &"strike")["weapon"], DuelRules.FISTS, "no sword yet: his fists")
	assert_true(bool(_entry(start, &"strike")["available"]), "and he can always strike")
	assert_false(bool(_entry(start, &"shoot")["available"]), "no bow: greyed")
	assert_eq(_entry(start, &"shoot")["why"], &"action.why.no_bow", "and why")
	assert_false(bool(_entry(start, &"gift")["available"]), "no gift: greyed")
	assert_eq(_entry(start, &"gift")["why"], &"action.why.no_spell", "and why")
	assert_true(bool(_entry(start, &"wait")["available"]), "waiting is always there")
	assert_true(ActionRules.of_category(start, &"items").is_empty(), "nothing to use yet")
	# The sword, the bow and the gift.
	(sim.store(&"inventory") as Inventory).gain(&"short_sword")
	sim.facts.add_source(DuelRules.THE_BOW, &"witnessed")
	sim.facts.add_source(OpeningRules.GIFT, &"fairy")
	sim.submit(&"tick_noop", {})
	sim.advance(1)
	var armed: Array[Dictionary] = _offered(sim)
	assert_eq(_entry(armed, &"strike")["weapon"], DuelRules.SWORD, "the sword in his hand")
	assert_true(bool(_entry(armed, &"shoot")["available"]), "the bow on his back")
	assert_true(bool(_entry(armed, &"gift")["available"]), "and the gift")
	# A gift cast is resting until its round comes round.
	var me := DuelFighter.new()
	me.who = DuelRules.PLAYER
	me.ready_round = 3
	var resting: Dictionary = _entry(ActionRules.offered(sim.store(&"inventory") as Inventory, sim.facts, me, 2), &"gift")
	assert_false(bool(resting["available"]), "resting")
	assert_eq(resting["why"], &"action.why.resting", "and said so")


func _wolf(at: Vector2i, seat: String = "wolf") -> DuelFighter:
	var wolf := DuelFighter.new()
	wolf.who = StringName(seat)
	wolf.hp = 10
	wolf.max_hp = 10
	wolf.at = at
	return wolf


func test_targets_say_reach_chance_and_damage_as_the_blow_will() -> void:
	var from := Vector2i(50, 50)
	var foes: Array[DuelFighter] = [_wolf(Vector2i(55, 50), "wolf#2"), _wolf(Vector2i(51, 50))]
	var traits := Traits.new()
	var sword: Dictionary = {"id": &"strike", "kind": ActionRules.STRIKE, "weapon": DuelRules.SWORD}
	var seen: Array[Dictionary] = ActionRules.targets(sword, from, foes, traits, &"")
	assert_eq(seen.size(), 2, "both, in reach or not")
	assert_eq(seen[0]["who"], &"wolf", "the one in reach first")
	assert_true(bool(seen[0]["in_reach"]), "beside him: in a sword's reach")
	assert_false(bool(seen[1]["in_reach"]), "five tiles off: not")
	assert_eq(int(seen[0]["chance"]), DuelRules.hit_chance(DuelRules.PLAYER, &"wolf", traits, &""), "the blow's own chance")
	assert_eq(int(seen[0]["damage"]), DuelRules.damage_with(DuelRules.SWORD), "and its damage")
	var bow: Dictionary = {"id": &"shoot", "kind": ActionRules.STRIKE, "weapon": DuelRules.BOW}
	var shots: Array[Dictionary] = ActionRules.targets(bow, from, foes, traits, &"")
	assert_eq(shots[0]["who"], &"wolf#2", "a bow reaches five tiles and never the next one")
	assert_false(bool(shots[1]["in_reach"]), "so the one beside him is out of a bow's reach")
	assert_eq(int(shots[0]["damage"]), DuelRules.bow_damage(), "an arrow's damage")
	var gift: Dictionary = {"id": &"gift", "kind": ActionRules.CAST}
	var spells: Array[Dictionary] = ActionRules.targets(gift, from, foes, traits, &"")
	assert_eq(int(spells[0]["chance"]), 100, "the gift always lands")
	assert_eq(int(spells[0]["damage"]), DuelRules.spell_damage(), "for its damage")
	assert_false(bool(spells[1]["in_reach"]), "five tiles is beyond its three")
	assert_eq(int(ActionRules.targets(sword, from, foes, traits, &"sword")[0]["chance"]), 95, "95 % in a lesson")


func test_a_turn_asks_the_fight_what_the_action_is() -> void:
	assert_eq(ActionRules.turn_of({"kind": ActionRules.STRIKE, "weapon": DuelRules.BOW}),
		{"action": String(DuelRules.STRIKE), "weapon": String(DuelRules.BOW)}, "a shot is a strike with the bow")
	assert_eq(ActionRules.turn_of({"kind": ActionRules.CAST})["action"], String(DuelRules.CAST), "the gift is a cast")
	assert_eq(ActionRules.turn_of({"kind": ActionRules.WAIT})["action"], String(DuelRules.WAIT), "and waiting waits")
