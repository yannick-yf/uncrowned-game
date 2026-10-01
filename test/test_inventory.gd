extends TestCase

## What the player carries and wears (group E): the start kit, the sword by the graves,
## Wren's bow, a beaten fighter's leavings, and what armour and weight do in a fight.
## Every gain and every change of clothes is an event, so a replay carries the same bag.

const SLOW: bool = false


func _made() -> Sim:
	return Game.begin_run(TraitRules.at_the_floor())


func _bag(sim: Sim) -> Inventory:
	return sim.store(&"inventory") as Inventory


func _sword_tile(sim: Sim) -> Vector2i:
	for find: Dictionary in Places.shared().finds():
		if find["id"] == &"graves_sword":
			return (sim.store(&"world") as WorldState).region().resolve(find["anchor"] as Dictionary)
	return Vector2i(-1, -1)


func _gained(sim: Sim, item: String) -> bool:
	for event: SimEvent in sim.events.all():
		if event.type == &"item_gained" and String(event.data.get("item", "")) == item:
			return true
	return false


func test_a_made_character_wears_the_start_kit_and_carries_no_weapon() -> void:
	var bag: Inventory = _bag(_made())
	assert_true(bag.made, "made at creation")
	for item: StringName in ItemRules.start_kit():
		assert_true(bag.has(item), "he has his %s" % item)
		assert_eq(bag.in_slot(ItemRules.slot_of(item)), item, "and wears it")
	assert_eq(bag.in_slot(ItemRules.WEAPON), &"", "nothing in his hand")
	assert_eq(bag.weapon_in_hand(), DuelRules.FISTS, "so he strikes with his fists")
	assert_eq(DuelRules.damage_of(DuelRules.PLAYER, DuelRules.FISTS), DuelRules.fists_damage(), "for less")
	assert_true(DuelRules.fists_damage() < DuelRules.strike_damage(), "less than a sword")


func test_a_run_never_made_is_as_he_was_before_the_inventory() -> void:
	# The suite's bare runs and a photograph's: a sword in the hand, no armour.
	var bag: Inventory = _bag(Game.build())
	assert_false(bag.made, "never made")
	assert_eq(bag.weapon_in_hand(), DuelRules.SWORD, "the sword he always had")
	assert_eq(bag.protection(), 0, "and nothing on him that turns a blow")


func test_the_sword_by_the_graves_is_picked_up_from_beside_it_once() -> void:
	var sim: Sim = _made()
	var world := sim.store(&"world") as WorldState
	var at: Vector2i = _sword_tile(sim)
	assert_true(world.region().is_passable(at), "the sword lies on ground one can stand on: %s" % at)
	assert_true(Vector2(at).distance_to(world.region().start_centre()) <= 8.0,
		"just past where he wakes: %.1f tiles" % Vector2(at).distance_to(world.region().start_centre()))
	# From where he wakes it is too far to reach down for.
	world.player_pos = world.region().start_centre() + Vector2(0.0, 3.0)
	sim.submit(&"pick_up", {"find": "graves_sword"})
	sim.advance(1)
	assert_false(_bag(sim).has(&"short_sword"), "not from over there")
	world.player_pos = Vector2(at) + Vector2(0.5, 1.5)
	sim.submit(&"pick_up", {"find": "graves_sword"})
	sim.advance(1)
	assert_true(_bag(sim).has(&"short_sword"), "picked up from beside it")
	assert_eq(_bag(sim).in_slot(ItemRules.WEAPON), &"short_sword", "and in his hand at once")
	assert_eq(_bag(sim).weapon_in_hand(), DuelRules.SWORD, "he strikes with it")
	assert_true(sim.facts.has(&"found:graves_sword"), "and it is no longer lying there")
	var before: int = _bag(sim).owned.size()
	sim.submit(&"pick_up", {"find": "graves_sword"})
	sim.advance(1)
	assert_eq(_bag(sim).owned.size(), before, "once")


func test_wren_s_bow_is_an_item_on_the_back() -> void:
	var sim: Sim = _made()
	assert_false(_bag(sim).has_bow(), "no bow at the start")
	sim.facts.add_source(DuelRules.THE_BOW, &"witnessed")
	sim.submit(&"tick_noop", {})
	sim.advance(1)
	assert_true(_bag(sim).has(&"hunting_bow"), "the line that gives it gives the item")
	assert_true(_bag(sim).has_bow(), "and it is on his back")
	assert_true(_gained(sim, "hunting_bow"), "said aloud")


func test_what_he_wears_is_changed_by_events_and_not_in_a_fight() -> void:
	var sim: Sim = _made()
	sim.submit(&"unequip", {"slot": "torso"})
	sim.advance(1)
	assert_eq(_bag(sim).in_slot(ItemRules.TORSO), &"", "the tunic off")
	sim.submit(&"equip", {"item": "cloth_tunic"})
	sim.advance(1)
	assert_eq(_bag(sim).in_slot(ItemRules.TORSO), &"cloth_tunic", "and on again")
	sim.submit(&"equip", {"item": "royal_helm"})
	sim.advance(1)
	assert_eq(_bag(sim).in_slot(ItemRules.HEAD), &"", "nothing he does not own")
	sim.submit(&"duel_began", {"opponent": "bram", "by": "player", "spar": true})
	sim.advance(1)
	assert_true((sim.store(&"duel") as Duel).on(), "a fight is on")
	sim.submit(&"unequip", {"slot": "torso"})
	sim.advance(1)
	assert_eq(_bag(sim).in_slot(ItemRules.TORSO), &"cloth_tunic", "not in a fight")


func test_a_beaten_fighter_leaves_what_he_wore() -> void:
	var sim: Sim = _made()
	sim.submit(&"duel_down", {"who": "works_guard"})
	sim.advance(1)
	assert_true(_bag(sim).has(&"leather_cap"), "the works' guard's cap")
	assert_true(_bag(sim).has(&"ochre_gambeson"), "and his gambeson")
	assert_eq(_bag(sim).in_slot(ItemRules.HEAD), &"leather_cap", "the cap on an empty head")
	assert_eq(_bag(sim).in_slot(ItemRules.TORSO), &"cloth_tunic", "the gambeson in the bag, the tunic still on")
	for seat: String in ["kings_guard", "kings_guard#2", "kings_guard#3"]:
		sim.submit(&"duel_down", {"who": seat})
		sim.advance(1)
	for item: StringName in [&"royal_helm", &"royal_breastplate", &"royal_leggings"]:
		assert_true(_bag(sim).has(item), "the three king's guards leave the set: %s" % item)
	sim.submit(&"duel_down", {"who": "wolf"})
	sim.advance(1)
	assert_eq(_bag(sim).owned.size(), ItemRules.start_kit().size() + 5, "a wolf leaves nothing to wear")


func test_armour_takes_its_share_and_weight_its_tile() -> void:
	assert_eq(ItemRules.after_armour(10, 4), 6, "protection off the blow")
	assert_eq(ItemRules.after_armour(3, 9), 1, "never below one")
	var plate: Dictionary = {ItemRules.HEAD: &"royal_helm", ItemRules.TORSO: &"royal_breastplate",
		ItemRules.LEGS: &"royal_leggings"}
	assert_eq(ItemRules.protection(plate), 5, "the royal set turns five points of every blow")
	assert_eq(ItemRules.after_armour(DuelRules.damage_of(&"kings_guard", DuelRules.SWORD), ItemRules.protection(plate)), 5,
		"a king's guard's ten is five through it, as the design says (CREATION_AND_GEAR.md section 4)")
	assert_eq(ItemRules.tiles_with(plate, DuelRules.tiles_per_turn()), DuelRules.tiles_per_turn() - 1,
		"and three heavy pieces cost a tile a turn")
	assert_eq(ItemRules.tiles_with({ItemRules.HEAD: &"royal_helm"}, DuelRules.tiles_per_turn()), DuelRules.tiles_per_turn(),
		"one does not")
	var sim: Sim = _made()
	for seat: String in ["kings_guard", "kings_guard#2", "kings_guard#3"]:
		sim.submit(&"duel_down", {"who": seat})
		sim.advance(1)
	for item: String in ["royal_breastplate", "royal_leggings"]:
		sim.submit(&"equip", {"item": item})
		sim.advance(1)
	assert_eq(DuelRules.player_tiles(_bag(sim)), DuelRules.tiles_per_turn() - 1, "the player in plate moves a tile less")


func test_a_blow_on_the_player_goes_through_his_armour() -> void:
	# In the fight itself, not only in the rules: a spar with Bram, the royal set on.
	var sim: Sim = _made()
	for seat: String in ["kings_guard", "kings_guard#2", "kings_guard#3"]:
		sim.submit(&"duel_down", {"who": seat})
		sim.advance(1)
	for item: String in ["royal_breastplate", "royal_leggings"]:
		sim.submit(&"equip", {"item": item})
		sim.advance(1)
	var armour: int = _bag(sim).protection()
	assert_eq(armour, 5, "helm, breastplate and leggings")
	sim.submit(&"duel_began", {"opponent": "harry", "by": "harry"})
	sim.advance(1)
	var landed: Array[int] = []
	for _step: int in 600:
		sim.advance(1)
		for event: SimEvent in sim.events.all():
			if event.type == &"blow_landed" and String(event.data.get("target", "")) == String(DuelRules.PLAYER) \
					and int(event.data.get("damage", 0)) > 0 and landed.size() < 1:
				landed.append(int(event.data.get("damage", 0)))
		if not landed.is_empty():
			break
	assert_false(landed.is_empty(), "Harry lands a blow")
	if not landed.is_empty():
		assert_eq(landed[0], ItemRules.after_armour(DuelRules.damage_of(&"harry", DuelRules.SWORD), armour),
			"for his blow less the armour")


func test_the_bag_replays() -> void:
	var sim: Sim = _made()
	sim.submit(&"duel_down", {"who": "works_guard"})
	sim.advance(1)
	sim.submit(&"equip", {"item": "ochre_gambeson"})
	sim.advance(1)
	var again: Sim = Game.replay(sim)
	assert_eq(_bag(again).fingerprint(), _bag(sim).fingerprint(), "the same bag, the same clothes")


func _talk_to_bram(sim: Sim) -> String:
	var world := sim.store(&"world") as WorldState
	if world.in_dialogue():
		sim.submit(&"end_talk")
		sim.advance(1)
	world.player_pos = (sim.store(&"cast") as Cast).get_npc(&"bram").centre()
	sim.submit(&"talk", {"npc": "bram"})
	sim.advance(1)
	return world.current_line


func test_bram_says_where_the_sword_lies_to_somebody_without_one() -> void:
	# E6, the design's promise (CREATION_AND_GEAR.md section 4): a player who walked past
	# the sword is told where it lies, and is weaker rather than stuck.
	var bram: Npc = Cast.shared().get_npc(&"bram")
	var sim: Sim = _made()
	var unarmed: String = bram.alt_greeting_for({&"unarmed": true})
	assert_true(unarmed != "" and unarmed != bram.greeting, "he has a line for it")
	assert_eq(_talk_to_bram(sim), unarmed, "empty-handed, he says where the sword lies")
	# At the hail, the hail's own words and the sword in one.
	var hail := sim.store(&"hail") as Hail
	sim.submit(&"end_talk")
	sim.advance(1)
	hail.who = &"bram"
	hail.phase = Hail.ARRIVED
	assert_eq(_talk_to_bram(sim), bram.alt_greeting_for({&"called_out_unarmed": true}), "called out, the same in his shout")
	assert_ne(bram.alt_greeting_for({&"called_out_unarmed": true}), bram.alt_greeting_for({&"called_out": true}),
		"which is not the hail's line for an armed man")
	hail.phase = Hail.IDLE
	hail.who = &""
	# With it, his everyday greeting again — even put away in the bag.
	(sim.store(&"world") as WorldState).player_pos = Vector2(_sword_tile(sim)) + Vector2(0.5, 1.5)
	sim.submit(&"end_talk")
	sim.advance(1)
	sim.submit(&"pick_up", {"find": "graves_sword"})
	sim.advance(1)
	assert_true(_bag(sim).owns_a_weapon(), "the sword picked up")
	assert_ne(_talk_to_bram(sim), unarmed, "armed, nothing about it")
	sim.submit(&"end_talk")
	sim.advance(1)
	sim.submit(&"unequip", {"slot": "weapon"})
	sim.advance(1)
	assert_ne(_talk_to_bram(sim), unarmed, "a sword in the bag is not lying on a grave")
	# A run never made has the sword it always had, and he never mentions one.
	assert_ne(_talk_to_bram(Game.build()), unarmed, "a bare run is armed")


func test_a_lesson_s_end_speaks_before_the_sword() -> void:
	# Fists pass the sword drill too; what he says after it is the lesson's, not the grave's.
	var bram: Npc = Cast.shared().get_npc(&"bram")
	var conditions: Dictionary = {&"unarmed": true, &"just_passed_sword": true}
	assert_eq(bram.alt_greeting_for(conditions), bram.alt_greeting_for({&"just_passed_sword": true}), "the lesson first")


# ------------------------------------------------------------ the review of group E ---

func test_loot_taken_in_a_fight_goes_on_when_it_is_over() -> void:
	# The review: felling the swordsman put his cap on the player while the archers still
	# shot — protection changed mid-fight, which equipping is refused for.
	var sim: Sim = _made()
	sim.submit(&"duel_began", {"opponents": ["works_guard", "works_archer"], "by": "works_guard"})
	sim.advance(1)
	sim.submit(&"duel_down", {"who": "works_guard"})
	sim.advance(1)
	assert_true(_bag(sim).has(&"leather_cap"), "the cap taken")
	assert_eq(_bag(sim).in_slot(ItemRules.HEAD), &"", "but not on while the fight goes on")
	assert_eq(_bag(sim).protection(), 0, "nor counted")
	sim.submit(&"duel_ended", {"how": "won"})
	sim.advance(1)
	assert_eq(_bag(sim).in_slot(ItemRules.HEAD), &"leather_cap", "on, once it is over")
	assert_eq(_bag(sim).in_slot(ItemRules.TORSO), &"cloth_tunic", "the gambeson stays in the bag over the tunic")
	assert_true(_bag(sim).waiting.is_empty(), "nothing left waiting")
	assert_eq(_bag(Game.replay(sim)).fingerprint(), _bag(sim).fingerprint(), "and it replays")


func test_the_gatekeeper_leaves_what_he_wore() -> void:
	# The review: he wears the works' guards' look and left nothing, read by his placing.
	var sim: Sim = _made()
	sim.submit(&"duel_down", {"who": "gatekeeper@1"})
	sim.advance(1)
	assert_true(_bag(sim).has(&"leather_cap"), "his cap")
	assert_true(_bag(sim).has(&"ochre_gambeson"), "and his gambeson")


func test_the_bow_lesson_puts_a_bow_taken_off_back_in_its_place() -> void:
	# The review: a bow taken off before trying the lesson again could never be shot.
	var sim: Sim = _made()
	sim.facts.add_source(DuelRules.THE_BOW, &"witnessed")
	sim.submit(&"tick_noop", {})
	sim.advance(1)
	sim.submit(&"unequip", {"slot": "bow"})
	sim.advance(1)
	assert_false(_bag(sim).has_bow(), "taken off")
	sim.submit(&"duel_began", {"opponent": "bram", "by": "bram", "spar": true, "drill": "bow"})
	sim.advance(1)
	assert_true(_bag(sim).has_bow(), "the lesson puts it back on")


func test_every_lesson_passes_with_the_start_kit() -> void:
	# The design: a player who walked past the sword is weaker, not stuck. Every drill
	# test elsewhere runs on a bare run, which has the sword; this one has fists.
	for drill: String in ["sword", "bow", "magic"]:
		var sim: Sim = _made()
		assert_eq(_bag(sim).weapon_in_hand(), DuelRules.FISTS, "%s: fists" % drill)
		if drill == "magic":
			sim.facts.add_source(OpeningRules.GIFT, &"fairy")
		if drill == "bow":
			sim.facts.add_source(DuelRules.THE_BOW, &"witnessed")
		var master: StringName = DuelRules.drill_master(StringName(drill))
		var world := sim.store(&"world") as WorldState
		world.player_pos = (sim.store(&"cast") as Cast).get_npc(master).centre() + Vector2(0.0, 2.0)
		sim.submit(&"duel_began", {"opponent": String(DuelRules.drill_first(StringName(drill))),
			"by": String(DuelRules.drill_first(StringName(drill))), "spar": true, "drill": drill})
		sim.advance(1)
		var hands := DuelPlayer.new(DuelPlayer.CAST if drill == "magic" else (DuelPlayer.BOW if drill == "bow" else DuelPlayer.PRESS))
		var duel := sim.store(&"duel") as Duel
		for _step: int in 30000:
			if not duel.on():
				break
			hands.play(sim, duel)
			sim.advance(1)
		# The lesson's end is written the step after the fight goes off.
		sim.advance(5)
		assert_true(sim.facts.has(StringName("drilled:%s" % drill)), "%s: passed with the start kit" % drill)
