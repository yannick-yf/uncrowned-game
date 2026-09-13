extends TestCase

## Quests as predicates over the fact base.
##
## **Invariant 5 is the whole design here**, not a thing checked afterwards:
## *"quests are reactions to fact patterns, not scripts. A quest that can only start
## one way is a bug."* Because a quest is keyed on facts, and §7 requires every fact
## to have more than one source, **every quest has more than one way in for free** —
## and the test below proves it by counting the people who could open each one.


func _facts() -> FactBase:
	return FactBase.new()


func _knows(facts: FactBase, of: Array) -> void:
	for fact: Variant in of:
		facts.add_source(fact as StringName, &"test")


# --------------------------------------------------------------- the shape ---

func test_a_quest_opens_because_you_learned_something() -> void:
	var facts: FactBase = _facts()
	var quest: Dictionary = QuestRules.find(&"the_man_in_the_wood")
	assert_false(QuestRules.is_open(quest, facts), "you have not heard of him")
	_knows(facts, [&"thornwood:kell"])
	assert_true(QuestRules.is_open(quest, facts), "and now you have")


func test_a_quest_closes_because_you_found_out() -> void:
	var facts: FactBase = _facts()
	var quest: Dictionary = QuestRules.find(&"the_man_in_the_wood")
	_knows(facts, [&"thornwood:kell"])
	assert_false(QuestRules.is_done(quest, facts))
	_knows(facts, [&"met:kell"])
	assert_true(QuestRules.is_done(quest, facts), "you found him")
	assert_false(QuestRules.is_open(quest, facts), "so it is no longer a question")


func test_either_lever_answers_the_one_she_asked_for() -> void:
	# `done_any`: the wood stops going when the furnaces stop, and there are two ways
	# to stop them. A quest with one solution is a step in a script.
	for lever: StringName in [&"i_turned_the_workers", &"i_wrecked_a_furnace"]:
		var facts: FactBase = _facts()
		_knows(facts, [&"thornwood:save_us", lever])
		assert_true(QuestRules.is_done(QuestRules.find(&"the_wood_is_going"), facts),
			"%s stops the clearing" % lever)


func test_progress_counts_and_never_advises() -> void:
	var facts: FactBase = _facts()
	var quest: Dictionary = QuestRules.find(&"who_you_were")
	_knows(facts, [&"you:raised"])
	assert_eq(QuestRules.progress(quest, facts), [0, 3], "none of the three yet")
	_knows(facts, [&"brindle:the_ground", &"acres:razed_villages"])
	assert_eq(QuestRules.progress(quest, facts), [2, 3], "two of them")


# ----------------------------------------------------------- invariant 5 ---

func test_no_quest_can_only_start_one_way() -> void:
	# The invariant, counted rather than asserted. For every fact a quest needs, at
	# least two different people in the cast can teach it — or it is a fact the
	# player is given by the world rather than by a person, which cannot be closed
	# off by killing anybody.
	var cast: Cast = Cast.shared()
	var teachers: Dictionary = {}
	for id: StringName in cast.npcs.keys():
		for option: DialogueOption in cast.get_npc(id).options:
			if option.teaches == &"":
				continue
			if not teachers.has(option.teaches):
				teachers[option.teaches] = []
			(teachers[option.teaches] as Array).append(id)

	for quest: Dictionary in QuestRules.all():
		for fact: Variant in (quest["needs"] as Array):
			var name: StringName = fact as StringName
			# Two kinds of fact are exempt, and both because **no death can take them
			# away** — which is what the invariant is actually protecting.
			#
			# `met:` is produced by walking up to somebody, and the opening's seven
			# are given in the first minute by a fairy who cannot be killed and does
			# not leave until she has finished. Asked of `OpeningRules` rather than by
			# matching a `you:` prefix, so that if she gains or loses a line the
			# exemption follows her instead of going stale.
			if String(name).begins_with("met:"):
				continue
			if OpeningRules.WHAT_SHE_TELLS_YOU.has(name):
				continue
			var who: Array = teachers.get(name, []) as Array
			assert_true(who.size() >= 2,
				"%s needs '%s', which only %s can teach" % [quest["id"], name, str(who)])


func test_every_quest_can_actually_be_finished() -> void:
	# A predicate nobody can satisfy is a dead end dressed as content. Every fact a
	# quest wants has to be reachable: taught by somebody, met by walking up to them,
	# or performed as a deed.
	var cast: Cast = Cast.shared()
	var reachable: Dictionary = {}
	for id: StringName in cast.npcs.keys():
		reachable[StringName("met:%s" % id)] = true
		for option: DialogueOption in cast.get_npc(id).options:
			if option.teaches != &"":
				reachable[option.teaches] = true
	for deed: StringName in DeedRules.all_deeds():
		reachable[deed] = true
	for fact: StringName in OpeningRules.WHAT_SHE_TELLS_YOU:
		reachable[fact] = true

	for quest: Dictionary in QuestRules.all():
		var wanted: Array = (quest.get("done", []) as Array) + (quest.get("done_any", []) as Array)
		assert_false(wanted.is_empty(), "%s can be finished at all" % quest["id"])
		for fact: Variant in wanted + (quest["needs"] as Array):
			assert_true(reachable.has(fact as StringName),
				"%s wants '%s', which nothing in the world produces" % [quest["id"], fact])


func test_every_quest_has_a_name_and_a_note_in_both_languages() -> void:
	for language: String in ["en", "fr"]:
		var known: Array[String] = Text.keys_for(language)
		for quest: Dictionary in QuestRules.all():
			assert_true(known.has(String(QuestRules.name_key(quest))),
				"%s: %s" % [language, QuestRules.name_key(quest)])
			assert_true(known.has(String(QuestRules.note_key(quest))),
				"%s: %s" % [language, QuestRules.note_key(quest)])


func test_quests_need_no_store_and_survive_a_reload() -> void:
	# The reason there is no quest store: the state *is* the fact base, so a reloaded
	# save has exactly the quests its facts imply and there is nothing to migrate.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	world.player_pos = (sim.store(&"cast") as Cast).get_npc(&"maddox").centre()
	sim.submit(&"talk", {"npc": "maddox"})
	sim.advance(2)
	var before: int = QuestRules.open_ones(sim.facts).size()
	var replayed: Sim = Game.replay(sim)
	assert_eq(QuestRules.open_ones(replayed.facts).size(), before,
		"the same facts, so the same questions")
